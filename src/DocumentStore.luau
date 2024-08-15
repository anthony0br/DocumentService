--!strict
-- Author: Anthony O'Brien

local RunService
if _G.IS_ROBLOX then
	RunService = game:GetService("RunService")
end

local Document = require("./Document")
local Types = require("./Types")
local Util = require("./SaveUtil")
local deepFreeze = require("./DeepFreeze")

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
		_lockSessions: boolean,
		_openingDocuments: number,
		_openDocuments: number,
	},
	DocumentStore
))

local gameClosing = false

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
	lockSessions: boolean,
}): DocumentStore<T>
	local self = setmetatable({
		_dataStore = props.dataStore,
		_check = props.check,
		_default = deepFreeze(props.default),
		_migrations = deepFreeze(props.migrations),
		_documents = {},
		_lockSessions = props.lockSessions,
		_openingDocuments = 0,
		_openDocuments = 0,
	}, DocumentStore)

	-- Save and close all documents as fast as possible on BindToClose
	-- Yielding on BindToClose in studio can cause studio to take a very long
	-- time to stop play test sessions, so we check :IsStudio()
	if _G.IS_ROBLOX then
		game:BindToClose(function()
			gameClosing = true

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
	assert(not gameClosing, "Cannot retrieve document, game closing")

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

	document:HookBefore("Open", function()
		self._openingDocuments += 1
	end)

	document:HookAfter("Open", function()
		self._openingDocuments -= 1
		self._openDocuments += 1
	end)

	document:HookAfter("Close", function()
		self._openDocuments -= 1
		self._documents[key] = nil
	end)

	self._documents[key] = document

	return document
end

--[=[
	Closes all open documents as fast as possible. This runs on BindToClose already.

	Will also wait for any documents that are opening to open, and then close them.

	:::warning
	Yields until all documents are closed. If there is a systematic error
	in your :Close, for example a hook errors, this could infinitely yield.
	:::

	Closes documents asynchronously when request budget allows, and yields
	all open documents are closed.

	@yields
]=]
function DocumentStore.CloseAllDocuments<T>(self: DocumentStore<T>)
	local thread = coroutine.running()

	-- This while loop exists for two reasons:
	-- 1. if budget is limited, we can wait for
	-- more to be available before spawning future threads, so documents
	-- are closed as quickly as possilbe by minimising retries
	-- 2. ensures documents that are opening and not yet opened when
	-- this is called are closed
	while self._openDocuments > 0 or self._openingDocuments > 0 do
		-- In each pass, we close the number of open documents recorded at the
		-- start of the pass, or the size of the budget - whichever is smaller
		local budget = Util.getUpdateBudget()
		local documentsToClose = math.min(self._openDocuments, budget)
		local requestCount = 0

		for _, v: Document<T> in pairs(self._documents) do
			if not v:IsOpen() then
				continue
			end

			if requestCount >= budget then
				break
			end

			if self._lockSessions then
				requestCount += 1
			end

			task.spawn(function()
				-- If Close fails, the After hook won't run and it will be
				-- attempted again in the next while iteration
				v:Close()
				documentsToClose -= 1

				if documentsToClose == 0 then
					-- Defer so that the coroutine.yield() always runs first
					task.defer(thread)
				end
			end)
		end

		-- We need to yield the thread inside the while loop, otherwise we
		-- will try to close the same documents lots of times
		if self._openDocuments > 0 then
			coroutine.yield()
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
