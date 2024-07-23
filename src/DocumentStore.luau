--!strict
-- Author: Anthony O'Brien

local Document = require(script.Parent.Document)

--[=[
	@class DocumentStore

	A struct that holds information about all Documents within a DataStore and provides a less
	repetitive way of instantiating documents.
]=]
local DocumentStore = {}
DocumentStore.__index = DocumentStore

export type DocumentStore<T> = typeof(setmetatable(
	{} :: {
		_dataStore: DataStore,
		_check: (unknown) -> T,
		_default: T,
	},
	DocumentStore
))

--[=[
	Creates a new DocumentStore

	@param dataStore -- The object returned by DataStoreService:GetDataStore()
	@param check -- A type check function for your data, errors if types are invalid
	@param default -- Default values, which are set if keys are empty

	@return DocumentStore
]=]
function DocumentStore.new<T>(dataStore: DataStore, check: (unknown) -> T, default: T): DocumentStore<T>
	return setmetatable({
		_dataStore = dataStore,
		_check = check,
		_default = default,
	}, DocumentStore)
end

--[=[
	Creates and returns a new Document based on 

	@param key 

	@return Document document created
]=]
function DocumentStore.GetDocument<T>(self: DocumentStore<T>, key: string): Document.Document<T>
	return Document.new(key, self._dataStore, self._check, self._default)
end

--[=[
	Checks whether a metatable passed is a DocumentStore

	@param instance metatable
	@return isDocumentStore -- is it a DocumentStore
]=]
function DocumentStore.isDocumentStore(instance): boolean
	return getmetatable(instance).__index == DocumentStore
end

return DocumentStore
