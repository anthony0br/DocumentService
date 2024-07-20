--!strict
-- Author: Anthony O'Brien

local Types = require(script.Parent.Types)

local Document = {}
Document.__index = Document

export type Document<T> = typeof(setmetatable(
	{} :: {
		_key: string,
		_dataStore: DataStore,
		_check: (unknown) -> T,
		_default: T,
		_lockedHandler: (number, number) -> Types.LockedResponse,
		_open: boolean,
		_hooks: {},
		Hook: HookMethod<T>,
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
	data: unknown,
}

type HookMethod<T> =
	((self: Document<T>, event: "Update", hook: (Result<T>) -> ()) -> ())
	& ((self: Document<T>, event: "Open", hook: (Result<T>) -> ()) -> ())
	& ((self: Document<T>, event: "Close", hook: (Result<T>) -> ()) -> ())

--[=[
    Creates a new Document class

	TO DO: Replace arguments with a table

    @param check --a function that take and returns a value, errors if the value provided does not match the type of data we expect
]=]
function Document.new<T>(
	key: string,
	dataStore: DataStore,
	check: (value: unknown) -> T,
	default: T,
	lockedHandler: (number, number) -> Types.LockedResponse
): Document<T>
	local hookMethod: HookMethod<T> = Document.Hook

	return setmetatable({
		_key = key,
		_dataStore = dataStore,
		_check = check,
		_default = default,
		_lockedHandler = lockedHandler,
		_open = false,
		_hooks = {},
		Hook = hookMethod,
	}, Document)
end

--[=[
    Validates and session locks the document, making it ready for use

    @returns the initial data found, if successful

    @yields
]=]
function Document.Open<T>(self: Document<T>): Result<T>
	assert(not self._open, "Document already open")

	local success, result: unknown = pcall(function()
		self._check()
	end)
	if not success then
		return {
			success = false,
			failReason = "TypeCheckFailed",
			errorMessage = result :: string,
		}
	end
	self._check()

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

    @returns success --true if no errors that we cannot control occur (i.e. datastore errors)
    @returns error --the error that occurred
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

function Document.Hook<T>(self: Document<T>, event: Types.HookEvent, hook: unknown) end

function Document.Close<T>(self: Document<T>): Result<T>
	assert(self._open, "Document not open")

	return {
		success = true,
		data = self._default,
	}
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
