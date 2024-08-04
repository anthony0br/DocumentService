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
		_saveOnCloseConn: RBXScriptConnection?,
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

local function runMigrations<T>(self: Document<T>, initialData: unknown, initialVersion: number): (boolean, T, number)
	local data = initialData
	local version = initialVersion

	for i, func in ipairs(self._migrations) do
		if i > initialVersion then
			data = func(data)
			version += 1
		end
	end

	local success, latestData = self._check(data)

	return success, latestData, version
end

local function latestDataFormatVersion<T>(self: Document<T>)
	return #self._migrations
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
		_default = default,
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
		_migrations = migrations,
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
	Validates the document if one exists, or creates a default document if no document exists.

	You must call this method before reading or writing to a Document.

	Can fail for the following reasons: RobloxAPIFail or SessionLocked.
	
	These should usually be handled by kicking the player.

	@return result

	@yields
]=]
function Document.Open<T>(self: Document<T>): Result<T>
	assert(not self._open, "Document already open")

	runHooks(self._preHooks.Open)

	local getOk, getValue = Util.getAsync(self._dataStore, self._key)

	if not getOk then
		return {
			success = false,
			failReason = "RobloxAPIFail",
			errorMessage = getValue :: string,
		}
	end

	local isValidDocumentService = false
	local keyData
	if typeof(getValue) == "table" then
		local tableValue = getValue :: { [unknown]: unknown }

		-- If the value does not contain documentServiceFormatVersion,
		-- we assume we are migrating from no library to DocumentService
		if tableValue.documentServiceFormatVersion then
			if tableValue.documentServiceFormatVersion == "1" then
				-- The validity assignment should only happen for the latest version
				keyData = tableValue :: KeyData<unknown>
				isValidDocumentService = true
				-- Insert migrations here
				-- e.g. insert new values for version 2, set version to 2
			end
			-- Insert migrations here
			-- e.g. if tableValue.documentServiceFormatVersion == "2"
		end
	end

	-- Create a new key, or check an existing one
	local finalData
	if not getValue then
		local updateOk, result = Util.updateAsync(self._dataStore, self._key, function(): KeyData<T>
			return {
				data = self._default,
				-- The default should always be the latest version
				dataFormatVersion = latestDataFormatVersion(self),
				documentServiceFormatVersion = FORMAT_VERSION,
				sessionLockId = "",
				lockTimestamp = 0,
				isLocked = false,
			}
		end)

		if not updateOk then
			return {
				success = false,
				failReason = "RobloxAPIFail",
				errorMessage = result :: string,
			}
		end

		finalData = self._default
	else
		-- If we have keyData, look for session locks, otherwise 'make' keyData by migrating from 'no library'
		if isValidDocumentService and keyData then
			local locked = keyData.isLocked and (keyData.lockTimestamp - os.time() < SESSION_EXPIRE_TIME)

			if locked and (keyData.sessionLockId ~= self._sessionId) then
				return {
					success = false,
					failReason = "SessionLocked",
					errorMessage = "An active session lock exists.",
				}
			end
		else
			keyData = {
				data = if typeof(getValue) == "table" then getValue :: { any } else { getValue },
				dataFormatVersion = 0,
				documentServiceFormatVersion = FORMAT_VERSION,
				sessionLockId = "",
				lockTimestamp = 0,
				isLocked = false,
			}
		end

		local checkOk, checkedData = self._check(keyData.data)
		local isLatestDataFormat = keyData.dataFormatVersion == latestDataFormatVersion(self)

		if checkOk and isLatestDataFormat then
			finalData = checkedData
		else
			local migrationOk, migratedData, version = runMigrations(self, keyData.data, keyData.dataFormatVersion)

			if not migrationOk then
				return {
					success = false,
					failReason = "MigrationFailed",
					errorMessage = "Failed to migrate data",
				}
			end

			local updateOk, err = Util.updateAsync(self._dataStore, self._key, function(old): KeyData<T>
				return {
					data = migratedData,
					dataFormatVersion = version,
					documentServiceFormatVersion = FORMAT_VERSION,
					sessionLockId = old.sessionLockId,
					lockTimestamp = 0,
					isLocked = false,
				}
			end)

			if not updateOk then
				return {
					success = false,
					failReason = "RobloxAPIFail",
					errorMessage = err :: string,
				}
			end

			-- Since updateOk is true, the migratedData has been set
			finalData = migratedData
		end
	end

	self._open = true

	return runHooks(self._postHooks.Open, {
		success = true,
		data = finalData,
	}) :: Result<T>
end

--[=[
	Adds a session lock and enables auto-saves.

	This is a separate method for DX, however unlocking is combined with saving to avoid hitting limits during server shutdowns.

	@return result

	@yields
]=]
function Document.Lock<T>(self: Document<T>): Result<nil>
	assert(self._open, "Document not open")
	assert(not self._lockedByUs, "Document already locked")

	local alreadyLocked
	local success, updatedData = Util.updateAsync(self._dataStore, self._key, function(keyData: KeyData<T>): KeyData<T>?
		-- Reset error flags in case callback runs multiple times
		alreadyLocked = false

		self:SetCache(keyData.data)

		local locked = keyData.isLocked and (keyData.lockTimestamp - os.time() < SESSION_EXPIRE_TIME)

		if locked then
			alreadyLocked = true
			return
		end

		return {
			documentServiceFormatVersion = FORMAT_VERSION,
			sessionLockId = self._sessionId,
			lockTimestamp = os.time(),
			isLocked = true,
			data = keyData.data,
			dataFormatVersion = keyData.dataFormatVersion,
		}
	end)

	if not success then
		return {
			success = false,
			failReason = "RobloxAPIFail",
			errorMessage = updatedData :: any,
		}
	end

	if alreadyLocked then
		return {
			success = false,
			failReason = "SessionLocked",
			errorMessage = "Document is already locked",
		}
	end

	self._lockedByUs = true

	-- Autosave
	task.defer(function()
		while self._lockedByUs do
			task.wait(AUTOSAVE_PERIOD)
			self:Save()
		end
	end)

	return {
		success = true,
	}
end

--[=[
	Destroys the document instance.

	If session locked, will save the document and remove the lock first.

	@return result

	@yields
]=]
function Document.Close<T>(self: Document<T>): Result<nil>
	assert(self._open, "Document not open")

	runHooks(self._preHooks.Close)

	if self._lockedByUs then
		self:SaveAndUnlock()
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
	Overrides the cache. If you are using session locking, you should only read once.
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
	@param shouldUnlock -- Should this update also remove the session lock? This reduces budget usage by combining updates and unlocks.
	@return result -- Result containing the new data.

	@yields
]=]
function Document.Update<T>(self: Document<T>, transform: Transform<T>, shouldUnlock: boolean?): Result<T>
	assert(self._open, "Document not open")

	runHooks(self._preHooks.Update, transform)

	local lockedByOther: boolean
	local transformInvalid: boolean
	local notStorable: boolean
	local notStorableErr: string

	local success, updatedKeyData = Util.updateAsync(
		self._dataStore,
		self._key,
		function(keyData: KeyData<T>): KeyData<T>?
			-- Reset error flags in case callback runs multiple times
			lockedByOther = false
			transformInvalid = false
			notStorable = false
			notStorableErr = ""

			-- Check if lock has been stolen
			local locked = keyData.isLocked and (keyData.lockTimestamp - os.time() < SESSION_EXPIRE_TIME)
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
				-- We do not call the invalid data handler, since this is for migrating old data and not fixing programmer mistakes.
				transformInvalid = true
				return
			end

			if not shouldUnlock then
				return {
					documentServiceFormatVersion = FORMAT_VERSION,
					sessionLockId = keyData.sessionLockId,
					lockTimestamp = os.time(),
					isLocked = keyData.isLocked,
					data = newData,
					dataFormatVersion = keyData.dataFormatVersion,
				}
			else
				return {
					documentServiceFormatVersion = FORMAT_VERSION,
					sessionLockId = "",
					lockTimestamp = 0,
					isLocked = false,
					data = newData,
					dataFormatVersion = keyData.dataFormatVersion,
				}
			end
		end
	)

	-- This should be a LOUD error! The developer is doing something wrong.
	if transformInvalid then
		error("Invalid transform function")
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

	-- Cast to KeyData<T> since the new data has already passed self._check and the update succeeded
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
	Saves a Document's cache to its DataStore. Equivalent to calling Update without transforming the data.

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
	Saves a Document's cache to its DataStore and removes the session lock.

	For session-locked data only.

	@yields
]=]
function Document.SaveAndUnlock<T>(self: Document<T>)
	assert(self._open, "Document not open")
	assert(self._lockedByUs, "Must be session locked to access cache")

	return self:Update(function(cache)
		return cache
	end, true)
end

--[=[
	Wipes all data associated with the key and closes the document

	Satisfies compliance with GDPR right of erasure.

	@yields
]=]
function Document.Erase<T>(self: Document<T>)
	assert(self._open, "Document not open")

	-- Set lockedByUs to false so we don't try to remove the lock
	self._lockedByUs = false
	self:Close()

	Util.setAsync(self._dataStore, self._key, nil)
end

--[=[
	Returns whether we hold a session lock on the document and can access caching methods
]=]
function Document.IsLockedByUs<T>(self: Document<T>): boolean
	return self._lockedByUs
end

--[=[
	Attaches a hook which occurs before the event.

	Note that if a hook yields, it will yield all methods that call it. Hooks are called in the order
	they are added.

	Explicitly annotate the transform type with DocumentService.Transform to avoid luau typechecking limitations.

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

	Note that if a hook yields, it will yield all methods that call it. Hooks are called in the order
	they are added.

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
