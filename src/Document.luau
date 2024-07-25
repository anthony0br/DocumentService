--!strict
-- Author: Anthony O'Brien

local Types = require("./Types")
local Retry = require("./Retry")

local SESSION_EXPIRE_TIME = 20 * 60
-- Fails after 32 seconds
local RETRY = {
	ATTEMPTS = 4,
	INITIAL_WAIT = 2,
}

--[=[
	@class Document
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
		_preHooks: {
			Open: { () -> () },
			Close: { () -> () },
			Read: { () -> () },
			Update: { (transform: (data: T) -> T) -> () },
		},
		_postHooks: {
			Open: { (Result<T>) -> () },
			Close: { (Result<T>) -> () },
			Read: { (Result<T>) -> () },
			Update: { (Result<T>) -> () },
		},
		_lockedHandler: (lockId: string?, lastUpdated: number) -> Types.LockedResponse,
		_invalidDataHandler: (invalidData: unknown) -> Result<T>,
	},
	Document
))

export type Result<T> = {
	success: true,
	data: T,
} | {
	success: false,
	failReason: Types.FailReason,
	errorMessage: string,
	data: unknown?,
}

type KeyData<T> = {
	documentServiceVersion: number,
	sessionLock: string,
	data: T,
}

local function runHooks<T...>(hooks: { (T...) -> () }, ...: T...)
	for _, hook in ipairs(hooks) do
		hook(...)
	end
end

local function updateAsync<T>(self: Document<T>, key, transform)
	return Retry(RETRY.ATTEMPTS, RETRY.INITIAL_WAIT, function(): (unknown, DataStoreKeyInfo)
		-- This is necessary to ensure UpdateAsyncs happen in the correct order
		-- For example if autosaves happen in the wrong order data could be lost
		if _G.IS_ROBLOX then
			local budget = game:GetService("DataStoreService")
				:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)
			assert(budget > 0, "Ran out of budget")
		end

		return self._dataStore:UpdateAsync(key, transform)
	end)
end

local function getAsync<T>(self: Document<T>, key)
	return Retry(RETRY.ATTEMPTS, RETRY.INITIAL_WAIT, function(): (unknown, DataStoreKeyInfo)
		local options
		if _G.IS_ROBLOX then
			local budget = game:GetService("DataStoreService")
				:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)
			assert(budget > 0, "Ran out of budget")

			options = Instance.new("DataStoreGetOptions")
			options.UseCache = false
		end

		return self._dataStore:GetAsync(key, options)
	end)
end

--[=[
	Creates a new Document class

	@param key -- 
	@param check -- a function that take and returns a value, errors if the value provided does not match the type of data we expect
]=]
function Document.new<T>(key: string, dataStore: DataStore, check: (unknown) -> (boolean, T), default: T): Document<T>
	return setmetatable({
		_key = key,
		_dataStore = dataStore,
		_check = check,
		_default = default,
		_open = false,
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
		_lockedHandler = function(_lockId: string?, lastUpdated: number): Types.LockedResponse
			if os.time() - lastUpdated > SESSION_EXPIRE_TIME then
				return "Steal"
			end

			return "Await"
		end,
		_invalidDataHandler = function(invalidData: unknown): Result<T>
			return {
				success = false,
				failReason = "InvalidDataNotHandled",
				errorMessage = "Data check function failed and no handler set",
				data = invalidData,
			}
		end,
	}, Document)
end

--[=[
	Validates and session locks the document, making it ready for use

	This can heavily yield due to re-tries

	@return result

	@yields
]=]
function Document.Open<T>(self: Document<T>): Result<T>
	assert(not self._open, "Document already open")

	-- Check for DocumentService data format version 1. If not, then migrate to it.

	local success, result = self._check()
	if not success then
		local handlerResult = self._invalidDataHandler(result)
		if not handlerResult.success then
			return handlerResult
		end
	end

	return {
		success = true,
		data = self._default,
	}
end

--[=[
	Adds a session lock

	@return result

	@yields
]=]
function Document.Lock<T>(self: Document<T>): Result<nil>
	assert(self._open, "Document not open")

	return {
		success = true,
	}
end

--[=[
	Removes a session lock

	@return result

	@yields
]=]
function Document.Unlock<T>(self: Document<T>): Result<nil>
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
function Document.Update<T>(self: Document<T>, transform: (data: T) -> T): Result<T>
	assert(self._open, "Document not open")

	runHooks(self._preHooks.Update, transform)

	local result: Result<T> = {
		success = true,
		data = self._default,
	}

	runHooks(self._postHooks.Update, result)

	return result
end

--[=[
	Attaches a hook which occurs before the event.

	Note that if a hook yields, it will yield all methods that call it. Hooks are called in the order
	they are added.

	@param event -- the operation to call the hook before
	@param hook -- a hook function that receives the arguments passed in to the operation
]=]
function Document.PreHook<T, S...>(self: Document<T>, event: Types.PreHookEvent, hook: (S...) -> ())
	table.insert(self._preHooks[event], hook)
end

--[=[
	Attaches a hook which occurs after the event, before the method returns.

	Note that if a hook yields, it will yield all methods that call it. Hooks are called in the order
	they are added.

	@param event -- the operation to call the hook after
	@param hook -- a hook function that receives the arguments passed in to the operation
]=]
function Document.PostHook<T>(self: Document<T>, event: Types.PostHookEvent, hook: (Result<T>) -> ())
	table.insert(self._postHooks[event], hook)
end

--[=[
	Sets the function which determines how to respond to a session lock while opening a Document.

	@param handler
]=]
function Document.SetLockedHandler<T>(
	self: Document<T>,
	handler: (lockId: string?, timestamp: number) -> Types.LockedResponse
)
	self._lockedHandler = handler
end

--[=[
	Sets the function which responds to invalid data while opening a Document.

	This can migrate data (by returning a successful result with new data), or fail.

	@param handler
]=]
function Document.SetInvalidDataHandler<T>(self: Document<T>, handler: (invalidData: unknown) -> Result<T>)
	self._invalidDataHandler = handler
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
