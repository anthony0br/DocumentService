--!strict
-- Author: Anthony O'Brien
-- Contributor: kineticwallet

local Types = require(script.Parent:FindFirstChild("Types"))
local SaveUtil = require(script.Parent:FindFirstChild("SaveUtil"))
local deepFreeze = require(script.Parent:FindFirstChild("DeepFreeze"))
local Signal = require(script.Parent:FindFirstChild("Signal"))

local SESSION_EXPIRE_TIME = 600
local AUTOSAVE_INTERVAL = 150

--[=[
	@class Document

	An abstraction over keys in a DataStore.

	Documents are designed to contain information about an entity in a schema.
	This schema is enforced by your check function, and should be changed
	through migrations. You may, of course, decide to not use a schema by
	defining an empty check function, but this generally isn't recommended.

	:::tip
	Session locking prevents your data from being edited by mutliple servers,
	and ensures one server is finished with it before it is opened by another.

	In DocumentService, session locking enables the use of the caching methods
	`SetCache` and `GetCache`.

	This is ideal for player data, or any data that needs frequent updates
	and does not need multi-server editing.
	:::

	:::warning
	You are free to edit the contents of the table in the .data field with
	a tool like DataStore Editor, but manually changing other fields could cause
	data loss and errors.
	:::

	:::warning
	Types for your data are provided under the assumption that once a document
	is opened, the underlying data held in Data Stores is not updated
	externally in a way that changes its type.
	:::
]=]
local Document = {}
Document.__index = Document

type DataStoreInterface = Types.DataStoreInterface

export type Document<T> = typeof(setmetatable(
	{} :: {
		_key: string,
		_dataStore: DataStoreInterface,
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
		-- Post & fail hooks are deprectaed.
		_postHooks: {
			Open: { () -> () },
			Close: { () -> () },
			Read: { () -> () },
			Update: { () -> () },
		},
		_failHooks: {
			Open: { () -> () },
			Close: { () -> () },
			Read: { () -> () },
			Update: { () -> () },
		},
		-- We get a recursive type error if we use Signal.Signal<OpenResult<T>> etc
		_actionSignals: {
			Open: Signal.Signal<any>,
			Close: Signal.Signal<any>,
			Read: Signal.Signal<any>,
			Update: Signal.Signal<any>,
			Cache: Signal.Signal<any>,
		},
		_migrations: Migrations,
		_cache: T,
		_isClosing: boolean,
		_lockSessions: boolean,
		_autoSaveThread: thread?,
		_shouldSteal: boolean,
		_onOpenTransform: Transform<T>?,
	},
	Document
))

export type Migrations = Types.Migrations

export type HookEvent = Types.HookEvent

export type Transform<T> = Types.Transform<T>

type Result<T, E> = Types.Result<T, E>

--[=[
	@type OpenResult<T> Result<T, RobloxAPIError | BackwardsCompatibilityError | CheckError | SessionLockedError>

	@within Document
]=]
type OpenResult<T> = Result<T, RobloxAPIError | BackwardsCompatibilityError | CheckError | SessionLockedError>

--[=[
	@type WriteResult<T> Result<T, RobloxAPIError | SessionLockedError | SchemaError>

	@within Document
]=]
type WriteResult<T> = Result<T, RobloxAPIError | SessionLockedError | SchemaError>

type ReadResult<T> = Result<T, RobloxAPIError | SchemaError | CheckError | BackwardsCompatibilityError>

type KeyData<T> = {
	documentServiceSchemaVersion: number,
	sessionLockId: string,
	lockTimestamp: number,
	isLocked: boolean,
	dataSchemaVersion: number,
	lastCompatibleVersion: number,
	data: T,
}

type RobloxAPIError = Types.RobloxAPIError
type SessionLockedError = Types.SessionLockedError
type CheckError = Types.CheckError
type BackwardsCompatibilityError = Types.BackwardsCompatibilityError
type SchemaError = Types.SchemaError

local INTERNAL_SCHEMA_VERSION = 0

local function runHooks(hooks: { () -> () })
	-- Clone the table instead of iterating backwards, so hooks are executed in the
	-- order they were added
	for _, hook in table.clone(hooks) do
		hook()
	end
end

-- Based off of Lapis by nezuo's backwards compatibility checking
local function getLastCompatibleVersion<T>(migrations: Migrations): number
	for version = #migrations, 1, -1 do
		local migration = migrations[version]

		if not migration.backwardsCompatible then
			return version
		end
	end

	return 0
end

local function runMigrations(migrations: Migrations, initialData: unknown, initialVersion: number): unknown
	local data = initialData
	local dataVersion = initialVersion

	for i, migration in ipairs(migrations) do
		local fromVersion = i - 1
		local targetVersion = i

		if fromVersion == dataVersion then
			data = migration.migrate(data)
			dataVersion = targetVersion
		end

		if not data then
			warn("Migration did not return a value - did you forget to return one?")
		end
	end

	return data
end

local function isLocked(keyData: KeyData<any>): boolean
	return keyData.isLocked and (os.time() - keyData.lockTimestamp < SESSION_EXPIRE_TIME)
end

local function checkKeyData(value: any): KeyData<any>?
	if type(value) ~= "table" then
		return
	end

	if not value.documentServiceSchemaVersion then
		return
	end

	-- Insert internal migrations here, noting each version a property
	-- is introduced and when INTERNAL_SCHEMA_VERSION is incremented
	-- Migrations should start at == 0 and progress to FORMAT_VERSION

	if value.documentServiceSchemaVersion ~= INTERNAL_SCHEMA_VERSION then
		warn("documentServiceSchemaVersion mutated")
		return
	end

	if type(value.sessionLockId) ~= "string" then
		warn(".isSessionLocked invalid")
		return
	end
	if type(value.isLocked) ~= "boolean" then
		warn(".isLocked invalid")
		return
	end
	if type(value.lockTimestamp) ~= "number" then
		warn(".lockTimestamp invalid")
		return
	end
	if type(value.data) ~= "table" then
		warn(".data invalid")
		return
	end
	if type(value.lastCompatibleVersion) ~= "number" then
		warn(".lastCompatibleVersion invalid")
		return
	end
	if type(value.dataSchemaVersion) ~= "number" then
		warn(".dataSchemaVersion invalid")
		return
	end

	return value :: KeyData<any>
end

--[=[
	@interface DocumentProps
	@within Document
	.key string -- The datastore key
	.dataStore DataStoreInterface -- The object returned by DataStoreService:GetDataStore()
	.check (unknown) -> (boolean, T) -- A pure function that verifies your data schema
	.default T -- Default values, which are set if keys are empty
	.migrations Types.Migrations -- Migrations
	.lockSessions boolean -- Should the document be session locked?

	:::info
	Your check function should return true if the provided table contains all of
	the correctly typed fields from T (the type of your data schema).

	The check function should accept tables with additional properties, and
	should not mutate the table in any way. The second return value exists to
	assist you by typechecking the interfaces you write, but is not currently
	used, to ensure data is not lost when loaded by an old server.

	For example, with [Guard](https://util.redblox.dev/guard.html)
	```
		local TestDataInterface = {
			Document = Guard.String,
			Service = Guard.Number,
		}

		local function testDataCheck(value: unknown): TestData
			assert(type(value) == "table")
			local Value: any = value

			return {
				Document = TestDataInterface.Document(Value.Document),
				Service = TestDataInterface.Service(Value.Service),
			}
		end
	```

	If you do not wish to dynamically check your data, write a placeholder with typecasting.
	:::

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
	dataStore: DataStoreInterface,
	check: (unknown) -> (boolean, T),
	default: T,
	migrations: Types.Migrations,
	lockSessions: boolean,
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
		_failHooks = {
			Open = {},
			Close = {},
			Update = {},
			Read = {},
		},
		_actionSignals = {
			Open = Signal.new(),
			Close = Signal.new(),
			Update = Signal.new(),
			Read = Signal.new(),
			Cache = Signal.new(),
		},
		_migrations = deepFreeze(props.migrations),
		_isClosing = false,
		_cache = props.default,
		_lockSessions = props.lockSessions,
		_shouldSteal = false,
	}, Document)

	return self
end

--[=[
	Validates the document if one exists, creates a default document if no
	document exists, or creates a document with the data that is in the given
	key if the key hasn't been used with DocumentService before.

	Opening a session-locked document will enable periodic autosaves until it is
	closed.

	You must open a document before reading or writing to it.

	:::info
	If the document is locked by another session, this method will wait and
	retry up to 5 times, and yields until the retries are exhausted or the lock
	is removed. Therefore, you should not use this method to check if the
	Document is being used by another session.
	:::

	:::warning
	You should check the value of `success`, and handle failures by checking
	the value of `reason`. The possible `reason`s for each method are defined in
	the return type.
	:::

	@return OpenResult<T>

	@yields
]=]
function Document.Open<T>(self: Document<T>): OpenResult<T>
	assert(not self._open, `{self} already open`)
	assert(not self._isClosing, `{self} is closing, cannot open`)

	-- Error flags
	local lockedByOther: boolean
	local incompatibleVersion: boolean
	local failedCheck: boolean
	local notStorable: boolean
	local notStorableErr: string
	local transformInvalid: boolean

	runHooks(self._preHooks.Open)

	local updateOk, updatedKeyData = SaveUtil.updateAsync(function(abortAttempt, getValue): KeyData<T>?
		-- Reset error flags in case function re-runs
		lockedByOther = false
		incompatibleVersion = false
		failedCheck = false

		local dataToMigrate: unknown
		local keyData: KeyData<unknown>?

		if getValue then
			keyData = checkKeyData(getValue)

			-- If we have a valid document service format, use the data field
			-- Otherwise, asssume we want to use the whole data stored at that
			-- key as the data field for migrating from 'no library'
			if keyData then
				dataToMigrate = keyData.data
			else
				print("Key non-empty but does not contain valid keyData, using value as data field")
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
			savedVersion = keyData.dataSchemaVersion
		end

		local migratedData = runMigrations(self._migrations, dataToMigrate, savedVersion)

		-- If keyData exists, the data could be in a future version, or the data
		-- could be session locked
		if keyData then
			-- This is for the case where a player joins a new server, their
			-- data is migrated, then they rejoin an old server
			if #self._migrations < keyData.lastCompatibleVersion then
				incompatibleVersion = true

				return
			end

			local locked = isLocked(keyData)
			local lockedByUs = locked and (keyData.sessionLockId == self._sessionId)

			if locked and not lockedByUs and not self._shouldSteal then
				lockedByOther = true
				abortAttempt(`Session lock held by another session for {self}.`)

				return
			end
		end

		local checkOk = self._check(migratedData)

		if not checkOk then
			failedCheck = true

			return
		end

		-- By this point, we know the data is valid because the function would've
		-- exited if it wasn't.
		-- We also know that we can safely mutate it because it is a compatible
		-- version and unlocked.
		local data = migratedData :: T

		if self._onOpenTransform then
			data = self._onOpenTransform(data)
		end

		local newDataIsValid = self._check(data)
		newDataIsValid = newDataIsValid and typeof(data) == "table"

		local isStorable, err = pcall(function()
			SaveUtil.assertStorable(data)
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

		self._cache = deepFreeze(data)

		return {
			documentServiceSchemaVersion = INTERNAL_SCHEMA_VERSION,
			sessionLockId = self._sessionId,
			lockTimestamp = os.time(),
			isLocked = self._lockSessions,
			-- If we are in an old server and the data is of a future version
			-- that is backwards compatible, keep the version number so that
			-- migrations do not run more than once
			dataSchemaVersion = math.max(#self._migrations, savedVersion),
			lastCompatibleVersion = getLastCompatibleVersion(self._migrations),
			data = data,
		}
	end, self._dataStore, self._key)

	local failResult: OpenResult<T>?

	if not updateOk then
		failResult = {
			success = false,
			reason = "RobloxAPIError",
		}
	end

	-- We need to check this after updateOk, since updateOk will be false in
	-- the case of a SessionLockedError
	if lockedByOther then
		failResult = {
			success = false,
			reason = "SessionLockedError",
		}
	end

	-- If it isn't a backwards compatibility problem and check doesn't pass
	-- we should report CheckError.
	if failedCheck then
		failResult = {
			success = false,
			reason = "CheckError",
		}
	end

	-- Highest priority.
	if incompatibleVersion then
		failResult = {
			success = false,
			reason = "BackwardsCompatibilityError",
		}
	end

	if failResult then
		runHooks(self._failHooks.Open)

		self._actionSignals.Open:Fire(failResult)

		return failResult
	end

	if transformInvalid then
		error("Invalid transform function - must return a table that passes the check function.")
	end

	if notStorable then
		error("Not storable: " .. notStorableErr)
	end

	self._open = true

	-- Reset shouldSteal in case Document is re-opened in the future
	self._shouldSteal = false

	-- This also creates a closure preventing garbage collection while a
	-- document is open and locked
	self._autoSaveThread = task.defer(function()
		while self._lockSessions and self._open do
			task.wait(AUTOSAVE_INTERVAL)

			local result = self:Save()

			if not result.success then
				warn(`Auto Save for key {self._key} failed due to a {result.reason}`)
			end
		end
	end)

	runHooks(self._postHooks.Open)

	local result: OpenResult<T> = {
		success = true,
		data = (updatedKeyData :: KeyData<T>).data,
	}

	self._actionSignals.Open:Fire(result)

	return result
end

--[=[
	Opens, and also runs a transform function on the data. Useful for
	non-session-locked data for shared entities, where one-off updates might
	be needed.

	Will throw a Luau error if the transform produces invalid or unsavable data.

	Runs both Open and Update hooks and signals, including fail hooks.

	@return OpenResult<T>

	@yields
]=]
function Document.OpenAndUpdate<T>(self: Document<T>, transform: Transform<T>): OpenResult<T>
	assert(not self._open, `{self} already open`)
	assert(not self._isClosing, `{self} is closing, cannot open`)

	runHooks(self._preHooks.Update)

	self._onOpenTransform = transform

	local result = self:Open()

	self._onOpenTransform = nil

	self._actionSignals.Update:Fire(result)

	if result.success then
		runHooks(self._postHooks.Update)

		return result
	else
		runHooks(self._failHooks.Update)

		return result
	end
end

--[=[
	Marks the lock as stolen. The next `:Open` call will ignore any existing
	locks.

	:::info
	Generally, it is recommended to call `:Steal` and then `:Open` in the case
	that the initial `:Open` fails due to `SessionLockedError`.
	:::

	:::warning
	Do not use this unless you are very sure the previous session is dead, or
	you could cause data loss. Only usable on session-locked Documents.
	:::

	@yields
]=]
function Document.Steal<T>(self: Document<T>)
	assert(not self._isClosing, "Document is closing")
	assert(self._lockSessions, "Stealing locks is only applicable to session-locked Documents")

	self._shouldSteal = true
end

--[=[
	Retrieves a signal that is fired when the document is opened. Note that this will
	be fired on completion of any `:Open`, even if it failed.
	
	@return Signal<OpenResult<T>>

	@yields
]=]
function Document.GetOpenedSignal<T>(self: Document<T>): Signal.Signal<OpenResult<T>>
	return self._actionSignals.Open
end

--[=[
	Retrieves a signal that is fired when the document is closed. Note that this will
	be fired on completion of any `:Close`, even if it failed.
	
	@return Signal<WriteResult<T?>

	@yields
]=]
function Document.GetClosedSignal<T>(self: Document<T>): Signal.Signal<WriteResult<T?>>
	return self._actionSignals.Close
end

--[=[
	Retrieves a signal that is fired when the document is updated.
	For example, this will be fired after an autosave or after you call :`Save()`.
	Note that this will be fired on completion of any `:Update`, even if it failed.
	
	@return Signal<WriteResult<T>>

	@yields
]=]
function Document.GetUpdatedSignal<T>(self: Document<T>): Signal.Signal<WriteResult<T>>
	return self._actionSignals.Update
end

--[=[
	Retrieves a signal that is fired when the document is read. Note that this will
	be fired on completion of any `:Read`, even if it failed.
	
	@return Signal<ReadResult<T>>

	@yields
]=]
function Document.GetReadSignal<T>(self: Document<T>): Signal.Signal<ReadResult<T>>
	return self._actionSignals.Read
end

--[=[
	Retrieves a signal that is fired when the document's cache is set.
	
	@return Signal<T>

	@yields
]=]
function Document.GetCacheChangedSignal<T>(self: Document<T>): Signal.Signal<T>
	return self._actionSignals.Cache
end

--[=[
	Returns a false Result if Document is either:
	i. Currently open in this server
	ii. Currently locked by another session
	
	Otherwise returns a true Result.

	If props.lockSessions is false, this will always return a true Result.

	:::tip
	You can use this to check if a player is active to avoid data loss while
	editing data from another server.
	:::

	@yields

	@return Result<boolean, RobloxAPIError>
]=]
function Document.IsOpenAvailable<T>(self: Document<T>): Result<boolean, RobloxAPIError>
	assert(not self._isClosing, "Document is closing")

	if self._open then
		return {
			success = true,
			data = false,
		}
	end

	if not self._lockSessions then
		return {
			success = true,
			data = true,
		}
	end

	local success, getValue: any = SaveUtil.getAsync(self._dataStore, self._key)

	if not success then
		return {
			success = false,
			reason = "RobloxAPIError",
		}
	end

	local keyData = checkKeyData(getValue)

	-- Since the behaviour of Open in this case is to put the existing value
	-- in the key into keyData.data, return a true Result.
	if not keyData then
		return {
			success = true,
			data = true,
		}
	end

	local locked = isLocked(keyData)
	local lockedByUs = locked and (keyData.sessionLockId == self._sessionId)

	return {
		success = true,
		data = (not locked) or lockedByUs,
	}
end

--[=[
	Returns whether the document is open or not

	@return boolean
]=]
function Document.IsOpen<T>(self: Document<T>): boolean
	return self._open
end

--[=[
	Closes the document, so it cannot be edited.

	The document must be open before using this method.

	If session locked, will save the document, remove the lock, and
	cancel autosaves first. If this fails, the document will not be closed.

	If the Close performs a Save, Result.data will be the data saved.

	@return WriteResult<T?>

	@yields
]=]
function Document.Close<T>(self: Document<T>): WriteResult<T?>
	assert(self._open, "Document not open")

	runHooks(self._preHooks.Close)

	-- This causes :Save to also remove the session lock
	self._isClosing = true

	local saveResult: WriteResult<T>

	if self._lockSessions then
		saveResult = self:Save()

		-- Abort the closure if the save failed
		if not saveResult.success then
			self._isClosing = false

			runHooks(self._failHooks.Close)
			self._actionSignals.Close:Fire(saveResult)

			return saveResult
		end
	end

	if self._autoSaveThread then
		task.cancel(self._autoSaveThread)
	end

	self._open = false
	self._isClosing = false

	runHooks(self._postHooks.Close)

	local result: WriteResult<T?> = {
		success = true,
	}

	-- If we saved then return the data saved in the result
	if self._lockSessions then
		result = saveResult
	end

	self._actionSignals.Close:Fire(result)

	return result
end

--[=[
	Returns true if `:Close` has been called and is incomplete.

	@return boolean
]=]
function Document.IsClosing<T>(self: Document<T>): boolean
	return self._isClosing
end

--[=[
	Sets the cache.

	The document must be open before using this method. You can only use cache for session-locked data.

	:::warning
	Your cache should always pass your check function, otherwise autosaves
	may error.
	:::

	:::info
	You must use immutable operations on cache, i.e. clone any table you intend to edit.
	:::

	@param newCache
	@return T
]=]
function Document.SetCache<T>(self: Document<T>, newCache: T): T
	assert(self._open, "Document not open")
	assert(self._lockSessions, "Cache is only supported for session locked data")

	self._cache = deepFreeze(newCache)

	self._actionSignals.Cache:Fire(newCache)

	return self._cache
end

--[=[
	Retrieves the cache.

	The document must be open before using this method. You can only use cache for session-locked data.

	:::info
	You must use immutable operations on cache, i.e. clone any table you intend to edit.
	:::

	@return T
]=]
function Document.GetCache<T>(self: Document<T>): T
	assert(self._open, "Document not open")
	assert(self._lockSessions, "Cache is only supported for session locked data")

	return self._cache
end

--[=[
	Performs an atomic transaction on the Document, writing to the DataStore.

	The document must be open before using this method.

	If using session locking, passing a transform is equvialent to calling
	`SetCache` with the transformed data and then `Save`.
	It is recommended you do this instead and reserver the transform
	function for non-session-locked data.
	If the Save fails, the cache will still be updated.

	Throws if data is not storable or the transform return value is invalid.

	:::tip
	Due to Luau limitations with the old solver, you will get the
	best experience if you manually annotate the type of the transform parameter.
	:::

	:::warning
	The transform function must not yield, and shouldn't rely on any data
	from outside. It must follow the rules of what is storable in Data Stores.
	:::

	:::warning
	Assumes the data that is already in Data Stores is valid since the last
	`:Open`. If it isn't, and this is not corrected by the transform, this
	method will throw a luau error.
	:::

	:::warning
	If you are using session locking, your transform needs to use immutable
	operations (in the same way updating cache does).
	:::

	:::warning
	If your transform errors, the update will be aborted and the error
	will be thrown in a new thread (this is Roblox behaviour).
	:::

	:::info
	Unlike `Open`, this method will not retry if the lock is stolen, and will
	instead return a `SessionLockedError` after the first attempt.
	:::

	@param transform -- Transform function for the transaction.
	@return WriteResult<T>

	@yields
]=]
function Document.Update<T>(self: Document<T>, transform: Transform<T>): WriteResult<T>
	assert(self._open, "Document not open")

	runHooks(self._preHooks.Update)

	local lockedByOther: boolean
	local transformInvalid: boolean
	local notStorable: boolean
	local schemaError: boolean
	local notStorableErr: string

	-- We need to do this here since the updateAsync transform could run
	-- multiple times.
	if self._lockSessions then
		-- It is important we set the cache straight away with no yield,
		-- otherwise we could accidentally revert updates.
		local updatedData = transform(self._cache)
		if updatedData ~= self._cache then
			self:SetCache(updatedData)
		end
	end

	local success, updatedKeyData = SaveUtil.updateAsync(function(_abortAttempt, value: unknown): KeyData<T>?
		-- Reset error flags in case callback runs multiple times
		lockedByOther = false
		transformInvalid = false
		notStorable = false
		notStorableErr = ""

		local keyData = checkKeyData(value)

		if not keyData then
			schemaError = true

			return
		end

		-- Check if lock has been stolen
		local locked = isLocked(keyData)
		local lockedByUs = locked and (keyData.sessionLockId == self._sessionId)

		if locked and not lockedByUs then
			lockedByOther = true

			return
		end

		local newData
		if self._lockSessions then
			newData = self._cache
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
			documentServiceSchemaVersion = INTERNAL_SCHEMA_VERSION,
			sessionLockId = keyData.sessionLockId,
			lockTimestamp = os.time(),
			-- If the Document is closing, it is our last save and we remove the lock
			isLocked = if self._isClosing then false else lockedByUs,
			data = newData,
			dataSchemaVersion = keyData.dataSchemaVersion,
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

	local failResult: WriteResult<T>?

	if not success then
		failResult = {
			success = false,
			reason = "RobloxAPIError",
		}
	end

	if lockedByOther then
		failResult = {
			success = false,
			reason = "SessionLockedError",
		}
	end

	if schemaError then
		failResult = {
			success = false,
			reason = "SchemaError",
		}
	end

	if failResult then
		runHooks(self._failHooks.Update)

		self._actionSignals.Update:Fire(failResult)

		return failResult
	end

	-- Cast to KeyData<T> since the new data has already passed self._check and
	-- the update succeeded.
	local updatedData: T = (updatedKeyData :: KeyData<T>).data

	runHooks(self._postHooks.Update)

	local result: WriteResult<T> = {
		success = true,
		data = updatedData,
	}

	self._actionSignals.Update:Fire(result)

	return result
end

--[=[
	Saves a Document's cache to its DataStore. Equivalent to calling Update
	without transforming the data.

	The document must be open and locked to use this method.

	Returns a WriteResult with the data field being the data saved to Data Stores.

	@return WriteResult<T>

	@yields
]=]
function Document.Save<T>(self: Document<T>): WriteResult<T>
	assert(self._open, "Document not open")
	assert(self._lockSessions, "Must be session locked to access cache")

	return self:Update(function(cache)
		return cache
	end)
end

--[=[
	Erases all data associated with the key.

	The document must not be open. It is up to you to check if the document
	is open elsewhere, e.g. via `IsOpenAvailable`.

	Satisfies compliance with GDPR right of erasure.

	Does not run hooks.

	@return Result<nil, RobloxAPIError>

	@yields
]=]
function Document.Erase<T>(self: Document<T>): Result<nil, RobloxAPIError>
	assert(not self._open, "Cannot erase an open document")

	local success = SaveUtil.removeAsync(self._dataStore, self._key)

	if not success then
		return {
			success = false,
			reason = "RobloxAPIError",
		}
	end

	return {
		success = true,
	}
end

--[=[
	Reads the latest data stored in Data Stores.

	Runs migrations and the check function, but does not save changes.

	This may be called while the document is not open.

	:::warning
	A `SchemaError` will be returned if document has never been opened before,
	so it is strongly recommended to handle this case, and Open the document
	before reading it if possible. This includes when migrating from no library.
	:::

	Runs Read hooks.

	@return Result<any, RobloxAPIError | SchemaError | CheckError | BackwardsCompatibilityError>

	@yields
]=]
function Document.Read<T>(self: Document<T>): ReadResult<T>
	runHooks(self._preHooks.Read)

	local success, getValue: any = SaveUtil.getAsync(self._dataStore, self._key)

	if not success then
		runHooks(self._failHooks.Read)

		local result: ReadResult<T> = {
			success = false,
			reason = "RobloxAPIError",
		}

		self._actionSignals.Read:Fire(result)

		return result
	end

	local keyData = checkKeyData(getValue)

	if not keyData then
		runHooks(self._failHooks.Read)

		local result: ReadResult<T> = {
			success = false,
			reason = "SchemaError",
		}

		self._actionSignals.Read:Fire(result)

		return result
	end

	local migratedData = runMigrations(self._migrations, keyData.data, keyData.dataSchemaVersion)

	local checkOk = self._check(migratedData)

	if not checkOk then
		runHooks(self._failHooks.Read)

		local result: ReadResult<T> = {
			success = false,
			reason = "CheckError",
		}

		self._actionSignals.Read:Fire(result)

		return result
	end

	local data = migratedData :: T

	if #self._migrations < keyData.lastCompatibleVersion then
		runHooks(self._failHooks.Read)

		local result: ReadResult<T> = {
			success = false,
			reason = "BackwardsCompatibilityError",
		}

		self._actionSignals.Read:Fire(result)

		return result
	end

	runHooks(self._postHooks.Read)

	local result: ReadResult<T> = {
		success = true,
		data = data,
	}

	self._actionSignals.Read:Fire(result)

	return result
end

local function cleanupHook(hooks: { () -> () }, hook: () -> ())
	local index = table.find(hooks, hook)

	if not index then
		error(`Failed to cleanup "{hook}" hook, not found in the given "{hooks}" hooks event registry!`)
	end

	table.remove(hooks, index)
end

--[=[
	Attaches a hook which occurs before the event.

	Note that if a hook yields, it will yield all methods that call it. Hooks
	are called in the order they are added.

	Hooks cannot currently mutate arguments.

	@param event -- the operation to call the hook before
	@param hook -- a hook function that receives the arguments passed in to the operation
	@return cleanup -- a callback that removes the hook from the given hook event registry
]=]
function Document.HookBefore<T, S...>(self: Document<T>, event: HookEvent, hook: () -> ()): () -> ()
	local hooks = self._preHooks[event]
	table.insert(hooks, hook)

	return function()
		cleanupHook(hooks, hook)
	end
end

--[=[
	Attaches a hook which occurs after the event, before the method returns.

	@deprecated v1.2.0 -- use signals

	Note that if a hook yields, it will yield all methods that call it. Hooks
	are called in the order they are added.

	Hooks added with HookAfter only run if the operation is successful, and
	cannot mutate the result.

	@param event -- the operation to call the hook after
	@param hook -- a hook function that receives the arguments passed in to the operation
	@return cleanup -- a callback that removes the hook from the given hook event registry
]=]
function Document.HookAfter<T>(self: Document<T>, event: HookEvent, hook: () -> ()): () -> ()
	local hooks = self._postHooks[event]
	table.insert(hooks, hook)

	return function()
		cleanupHook(hooks, hook)
	end
end

--[=[
	Attaches a hook which occurs after an event fails.

	@deprecated v1.2.0 -- use signals

	Note that fail hooks only run when a method returns an Err<E> type. They
	will not run if the method throws a Luau error due to incorrect usage.

	@param event -- the operation to call the hook after
	@param hook -- a hook function that receives the arguments passed in to the operation
	@return cleanup -- a callback that removes the hook from the given hook event registry
]=]
function Document.HookFail<T>(self: Document<T>, event: HookEvent, hook: () -> ()): () -> ()
	local hooks = self._failHooks[event]
	table.insert(hooks, hook)

	return function()
		cleanupHook(hooks, hook)
	end
end

--[=[
	Attaches a single-use hook which occurs before the event.

	@param event -- the operation to call the hook before
	@param hook -- a hook function that receives the arguments passed in to the operation
]=]
function Document.OnceBefore<T, S...>(self: Document<T>, event: HookEvent, hook: () -> ())
	local cleanup

	cleanup = Document.HookBefore(self, event, function()
		cleanup()
		hook()
	end)
end

--[=[
	Attaches a single-use hook which occurs after the event, before the method returns.

	@deprecated v1.2.0 -- use signals

	@param event -- the operation to call the hook after
	@param hook -- a hook function that receives the arguments passed in to the operation
]=]
function Document.OnceAfter<T>(self: Document<T>, event: HookEvent, hook: () -> ())
	local cleanup

	cleanup = Document.HookAfter(self, event, function()
		cleanup()
		hook()
	end)
end

--[=[
	Attaches a single-use hook which occurs after an event fails.

	@deprecated v1.2.0 -- use signals

	@param event -- the operation to call the hook after
	@param hook -- a hook function that receives the arguments passed in to the operation
]=]
function Document.OnceFail<T>(self: Document<T>, event: HookEvent, hook: () -> ())
	local cleanup

	cleanup = Document.HookFail(self, event, function()
		cleanup()
		hook()
	end)
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
	@return boolean
]=]
function Document.isDocument(instance: any): boolean
	return getmetatable(instance).__index == Document
end

return Document
