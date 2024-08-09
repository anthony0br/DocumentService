--!strict
-- Author: Anthony O'Brien

local Types = require("./Types")
local SaveUtil = require("./SaveUtil")
local deepFreeze = require("./DeepFreeze")

local SESSION_EXPIRE_TIME = 600
local AUTOSAVE_PERIOD = 150

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
		_sessionId: string,
		_preHooks: {
			Open: { () -> () },
			Close: { () -> () },
			Read: { () -> () },
			Update: { () -> () },
		},
		_postHooks: {
			Open: { () -> () },
			Close: { () -> () },
			Read: { () -> () },
			Update: { () -> () },
		},
		_migrations: Migrations<T>,
		_cache: T,
		_isClosing: boolean,
		_isSessionLocked: boolean,
	},
	Document
))

export type Migrations<T> = Types.Migrations<T>

export type PreHookEvent = Types.PreHookEvent

export type PostHookEvent = Types.PostHookEvent

export type Transform<T> = Types.Transform<T>

type Result<T, E> = Types.Result<T, E>

type OpenResult<T> = Result<T, RobloxAPIError | BackwardsCompatibileError | CheckError | SessionLockedError>

type ReadWriteResult<T> = Result<T, RobloxAPIError | SessionLockedError>

type KeyData<T> = {
	documentServiceFormatVersion: number,
	sessionLockId: string,
	lockTimestamp: number,
	isLocked: boolean,
	dataFormatVersion: number,
	lastCompatibleVersion: number,
	data: T,
}

type RobloxAPIError = Types.RobloxAPIError
type SessionLockedError = Types.SessionLockedError
type CheckError = Types.CheckError
type BackwardsCompatibileError = Types.BackwardsCompatibileError

local FORMAT_VERSION = 0

local function runHooks(hooks: { () -> () })
	for _, hook in ipairs(hooks) do
		hook()
	end
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

local function getKeyData(getValue)
	local keyData

	if type(getValue) ~= "table" then
		return
	end

	local tableValue = getValue :: { [unknown]: unknown }

	if not tableValue.documentServiceFormatVersion then
		return
	end

	-- Migrations should start at == 0 and progress to FORMAT_VERSION
	if tableValue.documentServiceFormatVersion == FORMAT_VERSION then
		keyData = tableValue :: KeyData<unknown>
	end

	return keyData
end

--[=[
	@interface DocumentProps
	@within Document
	.key string -- The datastore key
	.dataStore DataStore -- The object returned by DataStoreService:GetDataStore()
	.check (unknown) -> (boolean, T) -- A type check function for your data, errors if types are invalid
	.default T -- Default values, which are set if keys are empty
	.migrations Types.Migrations<T> -- Migrations
	.sessionLock boolean -- Should the document be session locked?

	@private
]=]
--[=[
	Creates a new Document class

	Don't create more than one Document for the same key, they will be considered different sessions.

	@param props DocumentProps

	@private
]=]
function Document.new<T>(props: {
	key: string,
	dataStore: DataStore,
	check: (unknown) -> (boolean, T),
	default: T,
	migrations: Types.Migrations<T>,
	sessionLock: boolean,
}): Document<T>
	assert(props.check(props.default), "Default must pass type check")
	assert(typeof(props.default) == "table", "Non-table values are not supported - group your data.")

	SaveUtil.assertStorable(props.default)

	local self = setmetatable({
		_key = props.key,
		_dataStore = props.dataStore,
		_check = props.check,
		_default = deepFreeze(props.default),
		_open = false,
		_sessionId = SaveUtil.uuid(),
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
		_migrations = deepFreeze(props.migrations),
		_isClosing = false,
		_cache = props.default,
		_isSessionLocked = props.sessionLock,
	}, Document)

	return self
end

--[=[
	Validates the document if one exists, or creates a default document if no
	document exists.

	You must call this method before reading or writing to a Document.

	:::info
	This method looks at documentServiceFormatVersion to assume the
	type of values stored in DataStore keys - Data generated by DocumentService
	is not validated, so if you manually edit anything in keys managed by
	DocumentService, apart from data, expect errors to be thrown. If a valid
	version isn't specified, it will assume we are migrating from no library
	to DocumentService and put the existing contents of the key into the .data
	field.

	You are free to edit the contents of the table in the .data field with
	a tool like DataStore Editor, but corrupting other data could cause your
	server scripts to break.
	:::

	:::tip
	Session locking prevents your data from being edited by mutliple servers,
	and ensures one server is finished with it before it is opened by another.

	In DocumentService, session locking enables the use of the caching methods
	`SetCache`, `GetCache`, and `UpdateCache`.

	This is ideal for player data, or any data that needs frequent updates
	and does not need multi-server editing.

	You can enable session locking with the shouldLock argument.
	:::

	:::warning
	Like all methods which return Result<T>, this can fail for reasons outside
	of the programmer's control. You should check for and handle these possible
	errors (stated above). Errors that are the fault of the programmer are
	thrown directly.
	:::

	:::warning
	Once a Document is open, no more validations take place. If data is
	corrupted externally while a session is open, it may cause unexpected
	errors. Session-locked sessions may also overwrite any data you change.
	:::

	@return result

	@yields
]=]
function Document.Open<T>(self: Document<T>): OpenResult<T>
	assert(not self._open, "Already open")
	assert(not self._isClosing, "Document is closing")

	-- Error flags
	local locked: boolean
	local incompatibleVersion: boolean
	local failedCheck: boolean

	runHooks(self._preHooks.Open)

	local updateOk, updatedKeyData = SaveUtil.updateAsync(function(getValue: unknown): KeyData<T>?
		-- Reset error flags in case function re-runs
		locked = false
		incompatibleVersion = false
		failedCheck = false

		local dataToMigrate: unknown
		local keyData: KeyData<T>?

		if getValue then
			keyData = getKeyData(getValue)

			-- If we have a valid document service format, use the data field
			-- Otherwise, asssume we want to use the whole data stored at that
			-- key as the data field for migrating from 'no library'
			if keyData then
				dataToMigrate = keyData.data
			else
				dataToMigrate = if typeof(getValue) == "table" then getValue else { getValue }
			end
		else
			dataToMigrate = self._default
		end

		local savedVersion = 0
		if dataToMigrate == self._default then
			savedVersion = #self._migrations
		end
		if keyData then
			savedVersion = keyData.dataFormatVersion
		end

		local migrationResult = runMigrations(self._migrations, dataToMigrate, savedVersion)

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

		self._cache = checkedData

		return {
			documentServiceFormatVersion = FORMAT_VERSION,
			sessionLockId = self._sessionId,
			lockTimestamp = os.time(),
			isLocked = if self._isSessionLocked then true else false,
			-- If we are in an old server and the data is of a future version
			-- that is backwards compatible, keep the version number so that
			-- migrations do not run more than once
			dataFormatVersion = math.max(migrationResult.version, savedVersion),
			lastCompatibleVersion = migrationResult.lastCompatibleVersion,
			data = checkedData,
		}
	end, self._dataStore, self._key)

	if not updateOk then
		return {
			success = false,
			reason = "RobloxAPIError",
		}
	end

	if incompatibleVersion then
		return {
			success = false,
			reason = "BackwardsCompatibleError",
		}
	end

	if locked then
		return {
			success = false,
			reason = "SessionLockedError",
		}
	end

	if failedCheck then
		return {
			success = false,
			reason = "CheckError",
		}
	end

	self._open = true

	-- Autosave
	task.defer(function()
		while self._isSessionLocked and self._open do
			task.wait(AUTOSAVE_PERIOD)
			self:Save()
		end
	end)

	runHooks(self._postHooks.Open)

	return {
		success = true,
		data = (updatedKeyData :: KeyData<T>).data,
	}
end

--[=[
	Destroys the document instance.

	If session locked, will save the document and remove the lock first.

	After closing a Document, you will need to call 
	DocumentStore:GetDocument() to retrieve a new one if you wish to access the
	Document again.

	@return result

	@yields
]=]
function Document.Close<T>(self: Document<T>): ReadWriteResult<T?>
	assert(self._open, "Document not open")

	runHooks(self._preHooks.Close)

	self._isClosing = true

	local result
	if self._isSessionLocked then
		result = self:Save()
	end

	runHooks(self._postHooks.Close)

	setmetatable(self :: any, nil)
	table.clear(self :: any)

	return if result
		then result
		else {
			success = true,
		}
end

--[=[
	Sets the cache.

	:::warning
	You can only use cache for session-locked data. See `Open` for how to
	enable session locking.
	:::

	:::info
	You must use immutable operations on cache, i.e. clone any table you intend to edit.
	:::

	@param newCache
	@return newCache
]=]
function Document.SetCache<T>(self: Document<T>, newCache: T): T
	assert(self._open, "Document not open")
	assert(self._isSessionLocked, "Cache is only supported for session locked data")

	self._cache = deepFreeze(newCache)

	return self._cache
end

--[=[
	Retrieves the cache.

	:::warning
	You can only use cache for session-locked data. See `Open` for how to
	enable session locking.
	:::

	:::info
	You must use immutable operations on cache, i.e. clone any table you intend to edit.
	:::

	@return cache
]=]
function Document.GetCache<T>(self: Document<T>): T
	assert(self._open, "Document not open")
	assert(self._isSessionLocked, "Cache is only supported for session locked data")

	return self._cache
end

--[=[
	Transforms the cache.

	:::warning
	You can only use cache for session-locked data. See `Open` for how to
	enable session locking.
	:::

	:::info
	You must use immutable operations on cache, i.e. clone any table you intend to edit.
	:::

	@param transform
	@return cache
]=]
function Document.UpdateCache<T>(self: Document<T>, transform: Transform<T>): T
	assert(self._open, "Document not open")
	assert(self._isSessionLocked, "Cache is only supported for session locked data")

	self._cache = deepFreeze(transform(self._cache))

	return self._cache
end

--[=[
	Reads from the DataStore.

	Can fail due to `RobloxAPIFail`, `SessionLocked`.

	:::warning
	Overwrites the cache. If you are using session locking, you should only read once.
	:::
	
	@return result -- result containing the data read

	@yields
]=]
function Document.Read<T>(self: Document<T>): ReadWriteResult<T>
	assert(self._open, "Document not open - open it or use Peek instead")

	runHooks(self._preHooks.Read)

	local success, getData = SaveUtil.getAsync(self._dataStore, self._key)
	-- As the Document is open we know the data is valid
	local keyData: KeyData<T> = getData :: KeyData<T>
	-- Unless it has been edited outside of the library, in which case error
	assert(keyData.data, "Key data missing")

	if not success then
		return {
			success = false,
			reason = "RobloxAPIError",
		} :: ReadWriteResult<T>
	end

	-- Check if the lock is stolen
	local locked = isLocked(keyData)
	local lockedByUs = locked and (keyData.sessionLockId == self._sessionId)

	if locked and not lockedByUs then
		return {
			success = false,
			reason = "SessionLockedError",
		}
	end

	if self._isSessionLocked then
		self:SetCache(keyData.data)
	end

	runHooks(self._postHooks)

	return {
		success = true,
		data = keyData.data,
	}
end

--[=[
	Performs an atomic transaction on the Document, writing to the DataStore.

	If using session locking, transforms will build on cached data.

	Errors if data is not storable or the transform return value is invalid.

	Can fail due to `RobloxAPIFail` or `SessionLocked`.

	:::tip
	Due to Luau limitations with the old solver, you will get the
	best experience if you manually annotate the type of the transform parameter.
	:::

	:::warning
	The transform function must not yield, and shouldn't rely on any
	from outside.
	:::

	@param transform -- Transform function for the transaction.
	@return result -- Result containing the new data.

	@yields
]=]
function Document.Update<T>(self: Document<T>, transform: Transform<T>): ReadWriteResult<T>
	assert(self._open, "Document not open")

	-- If we are closing, reject any future operations
	if self._isClosing then
		self._open = false
	end

	runHooks(self._preHooks.Update)

	local lockedByOther: boolean
	local transformInvalid: boolean
	local notStorable: boolean
	local notStorableErr: string

	local success, updatedKeyData = SaveUtil.updateAsync(function(keyData: KeyData<T>): KeyData<T>?
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

		local newData
		if lockedByUs and self._cache then
			newData = transform(self._cache)
		else
			newData = transform(keyData.data)
		end

		local newDataIsValid = self._check(newData)
		newDataIsValid = newDataIsValid and typeof(newData) == "table"

		local isStorable, err = pcall(function()
			SaveUtil.assertStorable(newData)
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
			isLocked = if self._isClosing then false else lockedByUs,
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
			reason = "RobloxAPIError",
		}
	end

	if lockedByOther then
		return {
			success = false,
			reason = "SessionLockedError",
		}
	end

	-- Cast to KeyData<T> since the new data has already passed self._check and
	-- the update succeeded.
	local updatedData: T = (updatedKeyData :: KeyData<T>).data

	if self._isSessionLocked then
		self:SetCache(updatedData)
	end

	local result: ReadWriteResult<T> = {
		success = true,
		data = updatedData,
	}

	runHooks(self._postHooks.Update)

	return result
end

--[=[
	Saves a Document's cache to its DataStore. Equivalent to calling Update
	without transforming the data.

	Can fail due to `RobloxAPIFail` or `SessionLocked` (in the case the lock is stolen).

	:::warning
	You can only use cache for session-locked data. See `Open` for how to
	enable session locking.
	:::

	@yields
]=]
function Document.Save<T>(self: Document<T>): ReadWriteResult<T>
	assert(self._open, "Document not open")
	assert(self._isSessionLocked, "Must be session locked to access cache")

	return self:Update(function(cache)
		return cache
	end)
end

--[=[
	Wipes all data associated with the key and closes the document.

	Can fail due to `RobloxAPIFail`.

	Satisfies compliance with GDPR right of erasure.

	@yields
]=]
function Document.Erase<T>(self: Document<T>): Result<nil, RobloxAPIError>
	self:Close()
	local success = SaveUtil.removeAsync(self._dataStore, self._key)

	if success then
		return {
			success = true,
		}
	else
		return {
			success = false,
			reason = "RobloxAPIError",
		}
	end
end

--[=[
	Reads the data of a potentially locked or unopened Document.

	Can fail due to `RobloxAPIFail`.

	Does not update the cache.

	If the data is not a table or not in the DocumentService format (see KeyData<T>),
	the data will be nil.

	@yields
]=]
function Document.Peek<T>(self: Document<T>): Result<any, RobloxAPIError>
	assert(not self._open, "Document open - use Read instead")

	local success, getData: any = SaveUtil.getAsync(self._dataStore, self._key)

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
		reason = "RobloxAPIError",
	}
end

--[=[
	Attaches a hook which occurs before the event.

	Note that if a hook yields, it will yield all methods that call it. Hooks
	are called in the order they are added.

	Hooks cannot currently mutate arguments.

	@param event -- the operation to call the hook before
	@param hook -- a hook function that receives the arguments passed in to the operation
]=]
function Document.HookBefore<T, S...>(self: Document<T>, event: PreHookEvent, hook: () -> ())
	table.insert(self._preHooks[event], hook)
end

--[=[
	Attaches a hook which occurs after the event, before the method returns.

	Note that if a hook yields, it will yield all methods that call it. Hooks
	are called in the order they are added.

	Hooks added with HookAfter only run if the operation is successful, and
	cannot mutate the result.

	@param event -- the operation to call the hook after
	@param hook -- a hook function that receives the arguments passed in to the operation
]=]
function Document.HookAfter<T>(self: Document<T>, event: PostHookEvent, hook: () -> ())
	table.insert(self._postHooks[event], hook)
end

--[=[
	@ignore
]=]
function Document.__tostring<T>(self: Document<T>)
	return `Document: {self._key}`
end

--[=[
	Checks if a metatable passed is a Document.

	@param instance metatable
	@return isDocument -- is it a Document
]=]
function Document.isDocument(instance): boolean
	return getmetatable(instance).__index == Document
end

return Document
