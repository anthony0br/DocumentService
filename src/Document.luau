--!strict
-- Author: Anthony O'Brien

local Types = require("./Types")
local Util = require("./Util")

local SESSION_EXPIRE_TIME = 15 * 60
local AUTOSAVE_PERIOD = 180

--[=[
	@class Document

	An abstraction over key, value pairs in a DataStore.
]=]
local Document = {}
Document.__index = Document

export type Document<T> = typeof(setmetatable(
	{} :: {
		_key: string,
		_dataStore: DataStore,
		_check: (unknown) -> (boolean, T),
		_default: T,
		_open: boolean,
		_lockedByUs: boolean,
		_sessionId: string,
		_preHooks: {
			Open: { () -> () },
			Close: { () -> () },
			Read: { () -> () },
			Update: { (transform: (data: T) -> T) -> (data: T) -> T },
		},
		_postHooks: {
			Open: { (Result<T>) -> Result<T> },
			Close: { (Result<T>) -> Result<T> },
			Read: { (Result<T>) -> Result<T> },
			Update: { (Result<T>) -> Result<T> },
		},
		_migrations: Migrations<T>,
		_cache: T?,
		_isClosing: boolean,
	},
	Document
))

export type Migrations<T> = Types.Migrations<T>

export type PreHookEvent = Types.PreHookEvent

export type PostHookEvent = Types.PostHookEvent

export type Transform<T> = (data: T) -> T

type Result<T> = Types.Result<T>

type KeyData<T> = {
	documentServiceFormatVersion: number,
	sessionLockId: string,
	lockTimestamp: number,
	isLocked: boolean,
	dataFormatVersion: number,
	lastCompatibleVersion: number,
	data: T,
}

local FORMAT_VERSION = 0

local function runHooks<T...>(hooks: { (T...) -> T... }, ...)
	local result = { ... }

	for _, hook in ipairs(hooks) do
		local len = #result
		result = { hook(table.unpack(result)) }
		assert(#result == len, "Hooks must return all arguments")
	end

	return table.unpack(result)
end

-- Based off of Lapis by nezuo's backwards compatibility checking
local function getLastCompatibleVersion<T>(migrations: Migrations<T>): number
	for version = #migrations, 1, -1 do
		local migration = migrations[version]

		if not migration.backwardsCompatible then
			return version
		end
	end

	return 0
end

local function runMigrations<T>(
	migrations: Migrations<T>,
	initialData: unknown,
	initialVersion: number
): {
	data: unknown,
	version: number,
	lastCompatibleVersion: number,
}
	local data = initialData
	local dataVersion = initialVersion

	for i, migration in ipairs(migrations) do
		local fromVersion = i - 1
		local targetVersion = i
		if fromVersion == dataVersion then
			data = migration.migrate(data)
			dataVersion = targetVersion
		end
	end

	return {
		data = data,
		version = dataVersion,
		lastCompatibleVersion = getLastCompatibleVersion(migrations),
	}
end

local function isLocked(keyData: KeyData<any>): boolean
	return keyData.isLocked and (os.time() - keyData.lockTimestamp < SESSION_EXPIRE_TIME)
end

--[=[
	Creates a new Document class

	Don't create more than one Document for the same key, they will be considered different sessions.

	@param key -- The datastore key
	@param dataStore -- The object returned by DataStoreService:GetDataStore()
	@param check -- A type check function for your data, errors if types are invalid
	@param default -- Default values, which are set if keys are empty
	@param migrations -- Fixes invalid data e.g. through migrations. Unfixable data should be reset.

	@private
]=]
function Document.new<T>(
	key: string,
	dataStore: DataStore,
	check: (unknown) -> (boolean, T),
	default: T,
	migrations: Types.Migrations<T>
): Document<T>
	assert(check(default), "Default must pass type check")
	assert(typeof(default) == "table", "Non-table values are not supported - group your data.")

	Util.assertStorable(default)

	local self = setmetatable({
		_key = key,
		_dataStore = dataStore,
		_check = check,
		_default = Util.deepFreeze(default),
		_open = false,
		_lockedByUs = false,
		_sessionId = Util.uuid(),
		_preHooks = {
			Open = {},
			Close = {},
			Update = {},
			Read = {},
		},
		_postHooks = {
			Open = {},
			Close = {},
			Update = {},
			Read = {},
		},
		_migrations = Util.deepFreeze(migrations),
		_isClosing = false,
	}, Document)

	return self
end

--[=[
	Reads the data of a potentially locked or unopened Document.

	Does not update the cache.

	If the data is not a table or not in the DocumentService format (see KeyData<T>),
	the data will be nil.

	@yields
]=]
function Document.Peek<T>(self: Document<T>): Result<any>
	assert(not self._open, "Document open - use Read instead")

	local success, getData: any = Util.getAsync(self._dataStore, self._key)

	local data
	if type(getData) == "table" then
		data = getData.data
	end

	if success then
		return {
			success = true,
			data = data,
		}
	end

	return {
		success = false,
		failReason = "RobloxAPIFail",
		errorMessage = getData :: string,
	}
end

--[=[
	Validates the document if one exists, or creates a default document if no
	document exists.

	If shouldLock is true, Open will session lock the document. While this does
	violate the single responsibility principle, it is far more efficient and
	safer to do multiple things within one UpdateAsync!

	You must call this method before reading or writing to a Document.

	Can fail for the following reasons: RobloxAPIFail, NotBackwardsCompatible,
	FailedCheck.

	NotBackwardsCompatible indicates the data has been migrated to a version on
	a newer server that isn't compatible with this server's latest version.

	FailedCheck indicates the migrations failed to convert the data to a form
	that passes the check function and matches the expected type interface.
	
	These should usually be handled by kicking the player.

	@param shouldLock
	@return result

	@yields
]=]
function Document.Open<T>(self: Document<T>, shouldLock: boolean?): Result<T>
	assert(not self._open, "Already open")
	assert(not self._isClosing, "Document is closing")

	-- Error flags
	local locked: boolean
	local incompatibleVersion: boolean
	local failedCheck: boolean

	runHooks(self._preHooks.Open)

	local updateOk, updatedKeyData = Util.updateAsync(function(getValue: unknown): KeyData<T>?
		-- Reset error flags in case function re-runs
		locked = false
		incompatibleVersion = false
		failedCheck = false

		local dataToCheck: unknown
		local keyData

		if not getValue then
			dataToCheck = self._default
		else
			-- If we have a valid document service format, use the data field
			-- Otherwise, asssume we want to use the whole data stored at that
			-- key as the data field for migrating from 'no library'
			if typeof(getValue) == "table" then
				local tableValue = getValue :: { [unknown]: unknown }

				-- Structured this way to facilitate migrations within
				-- DocumentService itself
				if tableValue.documentServiceFormatVersion then
					if tableValue.documentServiceFormatVersion == "1" then
						keyData = tableValue :: KeyData<unknown>
					end
				end
			end

			if keyData then
				dataToCheck = keyData.data
			else
				dataToCheck = if typeof(getValue) == "table" then getValue else { getValue }
			end
		end

		local migrationResult =
			runMigrations(self._migrations, dataToCheck, if keyData then keyData.dataFormatVersion else 0)

		-- If keyData exists, the data could be in a future version, or the data
		-- could be session locked
		if keyData then
			-- This is for the case where a player joins a new server, their
			-- data is migrated, then they rejoin an old server
			if migrationResult.version < keyData.lastCompatibleVersion then
				incompatibleVersion = true
				return
			end

			locked = isLocked(keyData)
			if locked then
				return
			end
		end

		local ok, checkedData = self._check(migrationResult.data)

		if not ok then
			failedCheck = true
			return
		end

		return {
			documentServiceFormatVersion = FORMAT_VERSION,
			sessionLockId = self._sessionId,
			lockTimestamp = os.time(),
			isLocked = if shouldLock then true else false,
			-- We use migrationResult.version, which could potentially downgrade
			-- the version if we are in an old server, but this is fine because
			-- we confirmed backwards compatibility
			dataFormatVersion = migrationResult.version,
			lastCompatibleVersion = migrationResult.lastCompatibleVersion,
			data = checkedData,
		}
	end, self._dataStore, self._key)

	if not updateOk then
		return {
			success = false,
			failReason = "RobloxAPIFail",
			errorMessage = updatedKeyData :: any,
		}
	end

	if incompatibleVersion then
		return {
			success = false,
			failReason = "NotBackwardsCompatible",
			errorMessage = "Data format is not backwards compatible with the latest version on this server.",
		}
	end

	if locked then
		return {
			success = false,
			failReason = "SessionLocked",
			errorMessage = "Data is reserved by another session. Try again later.",
		}
	end

	if failedCheck then
		return {
			success = false,
			failReason = "CheckFailed",
			errorMessage = "Check function failed after migrations ran.",
		}
	end

	-- At this point we can assume everything happened successfully
	if shouldLock then
		self._lockedByUs = true
	end

	-- Autosave
	task.defer(function()
		while self._lockedByUs do
			task.wait(AUTOSAVE_PERIOD)
			self:Save()
		end
	end)

	self._open = true

	return runHooks(self._postHooks.Open, {
		success = true,
		data = (updatedKeyData :: KeyData<T>).data,
	}) :: Result<T>
end

--[=[
	Destroys the document instance.

	If session locked, will save the document and remove the lock first.

	Note that after closing a Document, you will need to call 
	DocumentStore:GetDocument() to retrieve a new one if you wish to access the
	Document again.

	@return result

	@yields
]=]
function Document.Close<T>(self: Document<T>): Result<nil>
	assert(self._open, "Document not open")

	runHooks(self._preHooks.Close)

	self._isClosing = true

	if self._lockedByUs then
		self:Save()
	end

	local result = runHooks(self._postHooks.Close, {
		success = true,
	})

	setmetatable(self :: any, nil)
	table.clear(self :: any)

	return result
end

--[=[
	Sets the cache.

	Note you must use immutable operations, i.e. clone any table you intend to edit

	@param newCache
	@return newCache
]=]
function Document.SetCache<T>(self: Document<T>, newCache: T): T?
	assert(self._open, "Document not open")
	assert(self._lockedByUs, "Cache is only supported for session locked data")

	self._cache = Util.deepFreeze(newCache)

	return self._cache
end

--[=[
	Retrieves the cache.

	Note you must use immutable operations, i.e. clone any table you intend to edit

	@return cache
]=]
function Document.GetCache<T>(self: Document<T>): T?
	assert(self._open, "Document not open")
	assert(self._lockedByUs, "Cache is only supported for session locked data")

	return self._cache
end

--[=[
	Transforms the cache.

	Note you must use immutable operations, i.e. clone any table you intend to edit

	@param transform
	@return cache
]=]
function Document.UpdateCache<T>(self: Document<T>, transform: Transform<T>): T
	assert(self._open, "Document not open")
	assert(self._lockedByUs, "Cache is only supported for session locked data")
	assert(self._cache, "No existing cache to update")

	self._cache = Util.deepFreeze(transform(self._cache))

	return self._cache
end

--[=[
	Reads from the DataStore.

	:::warning
	Overwrites the cache. If you are using session locking, you should only read once.
	:::
	
	@return result -- result containing the data read

	@yields
]=]
function Document.Read<T>(self: Document<T>): Result<T>
	assert(self._open, "Document not open - open it or use Peek instead")

	runHooks(self._preHooks.Read)

	local success, getData = Util.getAsync(self._dataStore, self._key)
	-- As the Document is open we know the data is valid
	local keyData: KeyData<T> = getData :: KeyData<T>
	-- Unless it has been edited outside of the library, in which case error
	assert(keyData.data, "Key data missing")

	if success then
		self:SetCache(keyData.data)

		return {
			success = true,
			data = keyData.data,
		}
	end

	return runHooks(self._postHooks.Read, {
		success = false,
		failReason = "RobloxAPIFail",
		errorMessage = getData :: string,
	})
end

--[=[
	Performs an atomic transaction on the Document, writing to the DataStore.

	If using session locking, transforms will build on cached data.

	@param transform -- Transform function for the transaction.
	@return result -- Result containing the new data.

	@yields
]=]
function Document.Update<T>(self: Document<T>, transform: Transform<T>): Result<T>
	assert(self._open, "Document not open")

	-- If we are closing, reject any future operations
	if self._isClosing then
		self._open = false
	end

	runHooks(self._preHooks.Update, transform)

	local lockedByOther: boolean
	local transformInvalid: boolean
	local notStorable: boolean
	local notStorableErr: string

	local success, updatedKeyData = Util.updateAsync(function(keyData: KeyData<T>): KeyData<T>?
		-- Reset error flags in case callback runs multiple times
		lockedByOther = false
		transformInvalid = false
		notStorable = false
		notStorableErr = ""

		-- Check if lock has been stolen
		local locked = isLocked(keyData)
		local lockedByUs = locked and (keyData.sessionLockId == self._sessionId)

		if locked and not lockedByUs then
			lockedByOther = true
			return
		end

		local newData = keyData.data
		if lockedByUs and self._cache then
			newData = transform(self._cache)
		else
			newData = transform(keyData.data)
		end

		local newDataIsValid = self._check(newData)
		newDataIsValid = newDataIsValid and typeof(newData) == "table"

		local isStorable, err = pcall(function()
			Util.assertStorable(newData)
		end)

		if not isStorable then
			notStorable = true
			notStorableErr = err
			return
		end

		if not newDataIsValid then
			transformInvalid = true
			return
		end

		return {
			documentServiceFormatVersion = FORMAT_VERSION,
			sessionLockId = keyData.sessionLockId,
			lockTimestamp = os.time(),
			-- If the Document is closing, it is our last save and we remove the lock
			isLocked = if self._isClosing then false else keyData.isLocked,
			data = newData,
			dataFormatVersion = keyData.dataFormatVersion,
			lastCompatibleVersion = keyData.lastCompatibleVersion,
		}
	end, self._dataStore, self._key)

	-- This should be a LOUD error! The developer is doing something wrong.
	if transformInvalid then
		error("Invalid transform function - must return a table that passes the check function.")
	end

	if notStorable then
		error("Not storable: " .. notStorableErr)
	end

	if not success then
		return {
			success = false,
			failReason = "RobloxAPIFail",
			errorMessage = updatedKeyData :: any,
		}
	end

	if lockedByOther then
		return {
			success = false,
			failReason = "SessionLocked",
			errorMessage = "Document is locked by another session.",
		}
	end

	-- Cast to KeyData<T> since the new data has already passed self._check and
	-- the update succeeded.
	local updatedData: T = (updatedKeyData :: KeyData<T>).data

	if self._lockedByUs then
		self:SetCache(updatedData)
	end

	local result: Result<T> = {
		success = true,
		data = updatedData,
	}

	runHooks(self._postHooks.Update, result)

	return result
end

--[=[
	Saves a Document's cache to its DataStore. Equivalent to calling Update
	without transforming the data.

	For session-locked data only.

	@yields
]=]
function Document.Save<T>(self: Document<T>)
	assert(self._open, "Document not open")
	assert(self._lockedByUs, "Must be session locked to access cache")

	return self:Update(function(cache)
		return cache
	end)
end

--[=[
	Wipes all data associated with the key and closes the document

	Satisfies compliance with GDPR right of erasure.

	@yields
]=]
function Document.Erase<T>(self: Document<T>)
	self:Close()
	Util.removeAsync(self._dataStore, self._key)
end

--[=[
	Returns whether we hold a session lock on the document and can access caching methods
]=]
function Document.IsLockedByUs<T>(self: Document<T>): boolean
	return self._lockedByUs
end

--[=[
	Attaches a hook which occurs before the event.

	Note that if a hook yields, it will yield all methods that call it. Hooks
	are called in the order they are added.

	Explicitly annotate the transform type with DocumentService.Transform to
	avoid luau typechecking limitations.

	@param event -- the operation to call the hook before
	@param hook -- a hook function that receives the arguments passed in to the operation
]=]
function Document.HookBefore<T, S...>(
	self: Document<T>,
	event: PreHookEvent,
	hook: ((Transform<T>) -> Transform<T>) | (() -> ())
)
	table.insert(self._preHooks[event], hook)
end

--[=[
	Attaches a hook which occurs after the event, before the method returns.

	Note that if a hook yields, it will yield all methods that call it. Hooks
	are called in the order they are added.

	@param event -- the operation to call the hook after
	@param hook -- a hook function that receives the arguments passed in to the operation
]=]
function Document.HookAfter<T>(self: Document<T>, event: PostHookEvent, hook: (Result<T>) -> Result<T>)
	table.insert(self._postHooks[event], hook)
end

--[=[
	For debug printing documents
]=]
function Document.__tostring<T>(self: Document<T>)
	return `Document: {self._key}`
end

--[=[
	Checks whether a metatable passed is a Document

	@param instance metatable
	@return isDocument -- is it a Document
]=]
function Document.isDocument(instance): boolean
	return getmetatable(instance).__index == Document
end

return Document
