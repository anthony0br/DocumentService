--!strict
-- Author: Anthony O'Brien

local DataStoreService = game:GetService("DataStoreService")

local Types = require(script.Types)
local Document = require(script.Document)

local DocumentService = {}

local DocumentStore = {}
DocumentStore.__index = DocumentStore

export type DocumentStore<T> = typeof(setmetatable(
	{} :: {
		_name: string,
		_dataStore: DataStore,
		_check: (unknown) -> T,
		_default: T,
		_lockedHandler: (number, number) -> Types.LockedResponse,
	},
	DocumentStore
))

function DocumentService.GetDocumentStore<T>(
	name: string,
	check: (unknown) -> T,
	default: T,
	lockedHandler: (number, number) -> Types.LockedResponse
): DocumentStore<T>
	local dataStore = DataStoreService:GetDataStore(name)

	return setmetatable({
		_name = name,
		_dataStore = dataStore,
		_check = check,
		_default = default,
		_lockedHandler = lockedHandler,
	}, DocumentStore)
end

function DocumentStore.GetDocument<T>(self: DocumentStore<T>, key: string): Document.Document<T>
	local document = Document.new(key, self._dataStore, self._check, self._default, self._lockedHandler)

	return document
end

function DocumentStore.__tostring<T>(self: DocumentStore<T>)
	return `DocumentStore {self._name}`
end

function DocumentStore.isDocumentStore(instance)
	return getmetatable(instance).__index == DocumentStore
end

export type LockedResponse = Types.LockedResponse
export type HookEvent = Types.HookEvent
export type Result<T> = Document.Result<T>

return DocumentService
