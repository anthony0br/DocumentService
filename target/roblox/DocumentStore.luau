--!strict
-- Author: Anthony O'Brien

local RunService
do	
RunService = game:GetService("RunService")
end

local Document = require(script.Parent:FindFirstChild('Document'))
local Types = require(script.Parent:FindFirstChild('Types'))
local Util = require(script.Parent:FindFirstChild('SaveUtil'))
local deepFreeze = require(script.Parent:FindFirstChild('DeepFreeze'))
--[=[
	@class DocumentStore

	Represents a collection of Documents, analagous to a DataStore.

	:::warning
	Multiple DocumentStores can be created for the same DataStore. You should
	avoid this, as they will return different Document objects in different
	sessions. If you need to access the same DocumentStore in multiple scripts,
	create a module and require that module. Do not use DocumentService
	with Actors or Parallel Luau.
	:::
]=]

local DocumentStore = {}
DocumentStore.__index = DocumentStore

export type DocumentStore<T> = typeof(setmetatable(
	{} :: {
		_dataStore: DataStoreInterface,
		_check: (unknown) -> (boolean, T),
		_default: T & {},
		_migrations: Types.Migrations<T>,
		_documents: { [string]: Document<T> },
		-- Ideally, we could avoid this boolean option, but this is better
		-- than trying to do inheritance in Luau
		_lockSessions: boolean	
},
	DocumentStore
))

type Document<T> = Document.Document<T>

type Migrations<T> = Types.Migrations<T>

type DataStoreInterface = Types.DataStoreInterface

--[=[
	@interface DocumentStoreProps
	@within DocumentStore
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

	@return DocumentStore<T>
]=]
function DocumentStore.new<T>(props: {
	dataStore: DataStoreInterface,
	check: (unknown) -> (boolean, T),
	default: T & {},
	migrations: Migrations<T>,
	lockSessions: boolean
}): DocumentStore<T>
	local self = setmetatable({
		_dataStore = props.dataStore,
		_check = props.check,
		_default = deepFreeze(props.default),
		_migrations = deepFreeze(props.migrations),
		_documents = {},
		_lockSessions = props.lockSessions,
	}, DocumentStore)

	-- Save and close all documents as fast as possible on BindToClose
	-- Yielding on BindToClose in studio can cause studio to take a very long
	-- time to stop play test sessions, so we check :IsStudio()
	if not RunService:IsStudio() then
		game:BindToClose(function()
			self:CloseAllDocuments()
		end)
	end

	return self
end

--[=[
	Gets the document for the key given, or creates one if it does not exist.

	@param key 

	@return Document<T>
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
		lockSessions = self._lockSessions,
	})

	document:HookAfter("Close", function()
		self._documents[key] = nil
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
			if self._lockSessions then
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
	@return boolean
]=]
function DocumentStore.isDocumentStore(instance: any): boolean
	return getmetatable(instance).__index == DocumentStore
end

return DocumentStore
