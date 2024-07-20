--!strict
-- Author: Anthony O'Brien

local DocumentService = {}

export type LockedResponse = "Repeat" | "Cancel" | "ForceLoad" | "Steal"

local DocumentStore = {}
DocumentStore.__index = DocumentStore

export type DocumentStore<T> = typeof(setmetatable(
	{} :: {
		_key: string,
		_check: (unknown) -> T,
		_defaults: T,
		_lockedHandler: (number, number) -> LockedResponse,
		_invalidDataHandler: (data: unknown) -> T?,
	},
	DocumentStore
))

function DocumentService.GetDocumentStore<T>(
	key: string,
	lockedHandler: (number, number) -> LockedResponse,
	invalidDataHandler: (data: unknown) -> T?
): DocumentStore<T>
	local self = setmetatable({
		_key = key,
		_lockedHandler = lockedHandler,
		_invalidDataHandler = invalidDataHandler,
	}, DocumentStore)

	return self
end

return DocumentService
