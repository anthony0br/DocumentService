--!strict
-- Author: Anthony O'Brien

local Types = require(script.Parent.Types)

local SESSION_EXPIRE_TIME = 20 * 60
local RETRY_OPEN_TIME = 5

--[=[
	@class Document
]=]
local Document = {}
Document.__index = Document

export type Document<T> = typeof(setmetatable(
	{} :: {
		_key: string,
		_dataStore: DataStore,
		_check: (unknown) -> T,
		_default: T,
		_open: boolean,
		_hooks: {
			open: { (Result<T>) -> () },
			close: { (Result<T>) -> () },
			update: { (Result<T>) -> () },
			read: { (Result<T>) -> () },
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

local function addHook<T>(self: Document<T>, event: Types.HookEvent, hook: (...unknown) -> ...unknown) end

--[=[
	Creates a new Document class

	@param check -- a function that take and returns a value, errors if the value provided does not match the type of data we expect
]=]
function Document.new<T>(key: string, dataStore: DataStore, check: (value: unknown) -> T, default: T): Document<T>
	return setmetatable({
		_key = key,
		_dataStore = dataStore,
		_check = check,
		_default = default,
		_open = false,
		_hooks = {
			open = {},
			close = {},
			update = {},
			read = {},
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

	@return the initial data found, if successful

	@yields
]=]
function Document.Open<T>(self: Document<T>): Result<T>
	assert(not self._open, "Document already open")

	local success, result: unknown = pcall(function()
		self._check()
	end)
	if not success then
		self._invalidDataHandler()
	end
	self._check()

	return {
		success = true,
		data = self._default,
	}
end

function Document.Lock<T>(self: Document<T>): Result<nil>
	assert(self._open, "Document not open")

	return {
		success = true,
	}
end

function Document.Unlock<T>(self: Document<T>): Result<nil>
	assert(self._open, "Document not open")

	return {
		success = true,
	}
end

function Document.Close<T>(self: Document<T>): Result<T>
	assert(self._open, "Document not open")

	return {
		success = true,
		data = self._default,
	}
end

function Document.Read<T>(self: Document<T>): Result<T>
	return {
		success = true,
		data = self._default,
	}
end

--[=[
    Performs a single atomic transaction on the Document
]=]
function Document.Update<T>(self: Document<T>, transform: (data: T) -> T): Result<T>
	assert(self._open, "Document not open")

	return {
		success = true,
		data = self._default,
	}
end

--[=[
    A joint atomic transaction involving this document, and another document.

    If either update fails, both keys will be restored to their oirginal state.

    @return success -- true if no errors that we cannot control occur (i.e. datastore errors)
    @return error -- the error that occurred
]=]
function Document.UpdateWith<T, S>(
	self: Document<T>,
	otherDocument: Document<S>,
	transform: (data: T, otherData: S) -> (T, S)
): Result<T>
	return {
		success = true,
		data = self._default,
	}
end

function Document.OnRead<T>(self: Document<T>, hook: (Result<T>) -> ()) end

function Document.OnOpen<T>(self: Document<T>, hook: (Result<T>) -> ()) end

function Document.OnClose<T>(self: Document<T>, hook: (Result<T>) -> ()) end

function Document.OnUpdate<T>(self: Document<T>, hook: (Result<T>) -> ()) end

function Document.SetLockedHandler<T>(
	self: Document<T>,
	handler: (lockId: string?, timestamp: number) -> Types.LockedResponse
)
	self._lockedHandler = handler
end

function Document.SetInvalidDataHandler<T>(self: Document<T>, handler: (invalidData: unknown) -> Result<T>)
	self._invalidDataHandler = handler
end

function Document.Destroy<T>(self: Document<T>)
	if self._open then
		self:Close()
	end
	setmetatable(self :: any, nil)
	table.clear(self :: any)
end

function Document.__tostring<T>(self: Document<T>)
	return `Document: {self._key}`
end

function Document.isDocument(instance)
	return getmetatable(instance).__index == Document
end

return Document
