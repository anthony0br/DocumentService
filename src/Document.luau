--!strict
-- Author: Anthony O'Brien

local Types = require("./Types")
local Util = require("./Util")

local SESSION_EXPIRE_TIME = 15 * 60

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
			Update: { (transform: (data: T) -> T) -> (data: T) -> T },
		},
		_postHooks: {
			Open: { (Result<T>) -> Result<T> },
			Close: { (Result<T>) -> Result<T> },
			Read: { (Result<T>) -> Result<T> },
			Update: { (Result<T>) -> Result<T> },
		},
		_invalidDataHandler: Types.InvalidDataHandler<T>,
	},
	Document
))

type Result<T> = Types.Result<T>

export type Transform<T> = (data: T) -> T

type KeyData<T> = {
	documentServiceFormatVersion: string,
	sessionLockId: string,
	lockTimestamp: number,
	isLocked: boolean,
	data: T,
}

local FORMAT_VERSION = "1"

local function runHooks<T...>(hooks: { (T...) -> T... }, ...)
	local result = { ... }

	for _, hook in ipairs(hooks) do
		local len = #result
		result = { hook(table.unpack(result)) }
		assert(#result == len, "Hooks must return all arguments")
	end

	return table.unpack(result)
end

--[=[
	Creates a new Document class

	Don't create more than one Document for the same key, they will be considered different sessions.

	@param key -- The datastore key
	@param dataStore -- The object returned by DataStoreService:GetDataStore()
	@param check -- A type check function for your data, errors if types are invalid
	@param default -- Default values, which are set if keys are empty
	@param invalidDataHandler -- Fixes invalid data e.g. through migrations. Unfixable data should be reset.
]=]
function Document.new<T>(
	key: string,
	dataStore: DataStore,
	check: (unknown) -> (boolean, T),
	default: T,
	invalidDataHandler: Types.InvalidDataHandler<T>
): Document<T>
	assert(check(default), "Default must pass type check")

	return setmetatable({
		_key = key,
		_dataStore = dataStore,
		_check = check,
		_default = default,
		_open = false,
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
		_invalidDataHandler = invalidDataHandler,
	}, Document)
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
	local keyData: KeyData<unknown>?
	if typeof(getValue == "table") == "table" then
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
				data = getValue,
				documentServiceFormatVersion = FORMAT_VERSION,
				sessionLockId = "",
				lockTimestamp = 0,
				isLocked = false,
			}
		end

		local checkOk, checkedData = self._check(keyData)

		if checkOk then
			finalData = checkedData
		else
			local handlerResult = self._invalidDataHandler(checkedData)

			local updateOk, err = Util.updateAsync(self._dataStore, self._key, function(badValue): KeyData<T>
				return {
					data = handlerResult,
					documentServiceFormatVersion = FORMAT_VERSION,
					sessionLockId = badValue.sessionLockId,
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

			-- Since updateOk is true, we know result is KeyData<T>
			finalData = handlerResult
		end
	end

	self._open = true

	return table.freeze(runHooks(self._postHooks.Open, {
		success = true,
		data = finalData,
	})) :: Result<T>
end

--[=[
	Adds a session lock and enables auto-saves.

	@return result

	@yields
]=]
function Document.Lock<T>(self: Document<T>): Result<nil>
	assert(self._open, "Document not open")

	-- On bind to close: Loop adding save requests, yield until there datastore budget available

	return {
		success = true,
	}
end

--[=[
	Removes a session lock

	@return result

	@yields
]=]
function Document.RemoveLock<T>(self: Document<T>): Result<nil>
	assert(self._open, "Document not open")

	return {
		success = true,
	}
end

--[=[
	Makes the Document uneditable until it is re-opened

	@return result

	@yields
]=]
function Document.Close<T>(self: Document<T>): Result<nil>
	assert(self._open, "Document not open")

	self._open = false

	return {
		success = true,
		data = nil,
	}
end

--[=[
	Reads from the DataStore, without caching
	
	@return result -- result containing the data read

	@yields
]=]
function Document.Read<T>(self: Document<T>): Result<T>
	local success, data, keyInfo

	return {
		success = true,
		data = self._default,
	}
end

--[=[
	Performs an atomic transaction on the Document

	@param transform -- transform function for the transaction
	@return result -- result containing the new data

	@yields
]=]
function Document.Update<T>(self: Document<T>, transform: Transform<T>): Result<T>
	assert(self._open, "Document not open")

	runHooks(self._preHooks.Update, transform)

	local lockStolen
	local transformInvalid
	local success, updatedData = Util.updateAsync(self._dataStore, self._key, function(keyData: KeyData<T>): KeyData<T>?
		-- Reset error flags in case callback runs multiple times
		lockStolen = false
		transformInvalid = false

		-- Check if lock has been stolen
		local locked = keyData.isLocked and (keyData.lockTimestamp - os.time() < SESSION_EXPIRE_TIME)
		local lockedByUs = locked and (keyData.sessionLockId == self._sessionId)

		if locked and not lockedByUs then
			lockStolen = true
			return
		end

		local newDataIsValid, newData = self._check(transform(keyData.data))

		if not newDataIsValid then
			-- We do not call the invalid data handler, since this is for migrating old data and not fixing programmer mistakes.
			transformInvalid = true
			return
		end

		return {
			documentServiceFormatVersion = FORMAT_VERSION,
			sessionLockId = keyData.sessionLockId,
			lockTimestamp = if lockedByUs then os.time() else keyData.lockTimestamp,
			isLocked = keyData.isLocked,
			data = newData,
		}
	end)

	-- This should be a LOUD error! The developer is doing something wrong.
	if transformInvalid then
		error("Invalid transform function: return value did not pass the check function.")
	end

	if not success then
		return {
			success = false,
			failReason = "RobloxAPIFail",
			errorMessage = updatedData :: any,
		}
	end

	if lockStolen then
		return {
			success = false,
			failReason = "SessionLocked",
			errorMessage = "Document is locked by another session",
		}
	end

	local result: Result<T> = {
		success = true,
		-- Cast to T since updatedData has already passed self._check
		data = updatedData :: T,
	}

	runHooks(self._postHooks.Update, result)

	return result
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
	event: Types.PreHookEvent,
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
function Document.HookAfter<T>(self: Document<T>, event: Types.PostHookEvent, hook: (Result<T>) -> Result<T>)
	table.insert(self._postHooks[event], hook)
end

--[=[
	Closes and destroys the class
]=]
function Document.Destroy<T>(self: Document<T>)
	if self._open then
		self:Close()
	end
	setmetatable(self :: any, nil)
	table.clear(self :: any)
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
