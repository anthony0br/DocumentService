--!strict
-- Author: Anthony O'Brien

local Document = require("./Document")
local Types = require("./Types")

--[=[
	@class DocumentStore

	A struct that holds information about all Documents within a DataStore and provides a less
	repetitive way of instantiating documents. This can be seen as an abstraction over a DataStore.
]=]
local DocumentStore = {}
DocumentStore.__index = DocumentStore

export type DocumentStore<T> = typeof(setmetatable(
	{} :: {
		_dataStore: DataStore,
		_check: (unknown) -> (boolean, T),
		_default: T,
		_migrations: Types.Migrations<T>,
		_documents: { [string]: Document.Document<any> },
	},
	DocumentStore
))

--[=[
	Creates a new DocumentStore

	@param dataStore -- The object returned by DataStoreService:GetDataStore()
	@param check -- A type check function for your data, errors if types are invalid
	@param default -- Default values, which are set if keys are empty
	@param migrations -- Fixes invalid data e.g. through migrations. Unfixable data should be reset.

	@return DocumentStore
]=]
function DocumentStore.new<T>(
	dataStore: DataStore,
	check: (unknown) -> (boolean, T),
	default: T,
	migrations: Types.Migrations<T>
): DocumentStore<T>
	return setmetatable({
		_dataStore = dataStore,
		_check = check,
		_default = default,
		_migrations = migrations,
		_documents = {},
	}, DocumentStore)
end

--[=[
	Gets the document for the key given, or creates one if it does not exist.

	@param key 

	@return Document
]=]
function DocumentStore.GetDocument<T>(self: DocumentStore<T>, key: string): Document.Document<T>
	if self._documents[key] then
		return self._documents[key]
	end

	local document = Document.new(key, self._dataStore, self._check, self._default, self._migrations)

	document:HookAfter("Close", function(result: Types.Result<T>)
		if result.success then
			self._documents[key] = nil
		end

		return result
	end)

	self._documents[key] = document

	return document
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
