--!strict
-- Author: Anthony O'Brien

local Document = require("./Document")
local Types = require("./Types")
local Util = require("./Util")

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
		_default: T & {},
		_migrations: Types.Migrations<T>,
		_documents: { [string]: Document<T> },
		_sessionLock: boolean,
	},
	DocumentStore
))

export type Document<T> = Document.Document<T>

export type Migrations<T> = Types.Migrations<T>

--[=[
	@interface DocumentStoreProps
	.dataStore DataStore -- The object returned by DataStoreService:GetDataStore()
	.check (unknown) -> (boolean, T) -- A type check function for your data, errors if types are invalid
	.default T & {} -- Default values, which are set if keys are empty
	.migrations Migrations<T> -- Migrations
	.sessionLock boolean -- Should the documents be session locked?
]=]
--[=[
	Creates a new DocumentStore

	:::warning
	This should only be called once per server for each DataStore in a live game.
	If there are multiple instances of a DocumentStore for one key, any Documents
	will be treated as if they are from different sessions. This is useful for
	unit testing but can lead to weird bugs in production.
	:::

	@param props DocumentStoreProps

	@return DocumentStore
]=]
function DocumentStore.new<T>(props: {
	dataStore: DataStore,
	check: (unknown) -> (boolean, T),
	default: T & {},
	migrations: Migrations<T>,
	sessionLock: boolean,
}): DocumentStore<T>
	local self = setmetatable({
		_dataStore = props.dataStore,
		_check = props.check,
		_default = Util.deepFreeze(props.default),
		_migrations = Util.deepFreeze(props.migrations),
		_documents = {},
		_sessionLock = props.sessionLock,
	}, DocumentStore)

	-- Save and close all documents as fast as possible on BindToClose
	-- Yielding on BindToClose in studio can cause studio to take a very long
	-- time to stop play test sessions, so we check :IsStudio()
	if _G.IS_ROBLOX and not game:GetService("RunService"):IsStudio() then
		game:BindToClose(function()
			self:CloseAllDocuments()
		end)
	end

	return self
end

--[=[
	Gets the document for the key given, or creates one if it does not exist.

	@param key 

	@return Document
]=]
function DocumentStore.GetDocument<T>(self: DocumentStore<T>, key: string): Document<T>
	if self._documents[key] then
		return self._documents[key]
	end

	local document = Document.new({
		key = key,
		dataStore = self._dataStore,
		check = self._check,
		default = self._default,
		migrations = self._migrations,
		sessionLock = self._sessionLock,
	})

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
	Closes all documents as fast as possible. This runs on BindToClose already.
]=]
function DocumentStore.CloseAllDocuments<T>(self: DocumentStore<T>)
	local open = true
	while open do
		local budget = Util.getUpdateBudget()
		local count = 0
		open = false
		for _, v: Document<T> in pairs(self._documents) do
			open = true
			if count >= budget then
				break
			end
			if self._sessionLock then
				count += 1
			end
			task.spawn(function()
				v:Close()
			end)
		end
		task.wait()
	end
end

--[=[
	Checks if a metatable passed is a DocumentStore.

	@param instance metatable
	@return isDocumentStore -- is it a DocumentStore
]=]
function DocumentStore.isDocumentStore(instance): boolean
	return getmetatable(instance).__index == DocumentStore
end

return DocumentStore
