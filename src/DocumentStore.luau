--!strict
-- Author: Anthony O'Brien

local Document = require("./Document")
local Types = require("./Types")
local Util = require("./SaveUtil")
local deepFreeze = require("./DeepFreeze")

local CLOSE_PASS_INTERVAL = 1

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

export type DocumentStoreProps<T> = {
	dataStore: DataStoreInterface,
	check: (unknown) -> (boolean, T),
	default: T & {},
	migrations: Migrations,
	lockSessions: boolean,
	bindToClose: boolean?,
}

export type DocumentStore<T> = typeof(setmetatable(
	{} :: {
		_dataStore: DataStoreInterface,
		_check: (unknown) -> (boolean, T),
		_default: T & {},
		_migrations: Types.Migrations,
		_documents: typeof(setmetatable({} :: { [string]: Document<T> }, { { __mode = "v" } })),
		-- Ideally, we could avoid this boolean option, but this is better
		-- than trying to do inheritance in Luau
		_lockSessions: boolean,
		_openingDocuments: number,
		_documentsToClose: number,
	},
	DocumentStore
))

local gameClosing = false

type Document<T> = Document.Document<T>

type Migrations = Types.Migrations

type DataStoreInterface = Types.DataStoreInterface

--[=[
	@interface DocumentStoreProps
	@within DocumentStore
	.dataStore DataStore -- The object returned by DataStoreService:GetDataStore()
	.check (unknown) -> (boolean, T) -- A type check function for your data, errors if types are invalid
	.default T & {} -- Default values, which are set if keys are empty
	.migrations Migrations -- Migrations
	.lockSessions boolean -- Should the documents be session locked?
	.bindToClose boolean? -- Should the DocumentStore close all documents on BindToClose? [default=true] (This should always be true in production)
]=]
--[=[
	Creates a new DocumentStore.

	:::warning
	This should only be called once per server for each DataStore in a live game.
	If there are multiple instances of a DocumentStore for one key, any Documents
	will be treated as if they are from different sessions. This is useful for
	unit testing but can lead to weird bugs in production. DocumentStores should
	persist through an entire server's lifespan and are not garbage collected.
	:::

	@param props DocumentStoreProps

	@return DocumentStore<T>
]=]
function DocumentStore.new<T>(props: DocumentStoreProps<T>): DocumentStore<T>
	local self = setmetatable({
		_dataStore = props.dataStore,
		_check = props.check,
		_default = deepFreeze(props.default),
		_migrations = deepFreeze(props.migrations),
		_documents = setmetatable({}, { __mode = "v" }),
		_lockSessions = props.lockSessions,
		_openingDocuments = 0,
		_documentsToClose = 0,
	}, DocumentStore)

	-- Save and close all documents as fast as possible on BindToClose
	-- Yielding on BindToClose in studio can cause studio to take a very long
	-- time to stop play test sessions, so we give the user the option to
	-- disable this behavior.
	if _G.IS_ROBLOX and props.bindToClose ~= false then
		game:BindToClose(function()
			gameClosing = true

			self:CloseAllDocuments()
		end)
	end

	return self
end

--[=[
	Gets the document for the key given, or creates one if it does not exist.

	:::info
	Documents are cached in a weak table, so once they are closed, they will
	be marked for garbage collection if you have no references to them. Be
	careful of references created by closures.

	Documents that are not session locked will be garbage collected once there
	are no other references to them.
	:::

	@param key

	@return Document<T>
	@return boolean -- whether a new document was created
]=]
function DocumentStore.GetDocument<T>(self: DocumentStore<T>, key: string): (Document<T>, boolean)
	assert(not gameClosing, "Cannot retrieve document, game closing")

	if self._documents[key] then
		return self._documents[key], false
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

	document:HookFail("Open", function()
		self._openingDocuments -= 1
	end)

	document:HookAfter("Open", function()
		self._openingDocuments -= 1
		self._documentsToClose += 1
	end)

	document:HookAfter("Close", function()
		self._documentsToClose -= 1
	end)

	self._documents[key] = document

	return document, true
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

	local complete = self._documentsToClose == 0 and self._openingDocuments == 0

	-- This while loop exists for two reasons:
	-- 1. if budget is limited, we can wait for
	-- more to be available before spawning future threads, so documents
	-- are closed as quickly as possilbe by minimising retries
	-- 2. ensures documents that are opening and not yet opened when
	-- this is called are closed.
	while not complete do
		-- In each pass, we close the number of open documents recorded at the
		-- start of the pass, or the size of the budget - whichever is smaller.
		local budget = Util.getUpdateBudget()
		local documentsToClose = math.min(self._documentsToClose, budget)
		local requestCount = 0

		for _, v: Document<T> in pairs(self._documents) do
			if not v:IsOpen() then
				continue
			end

			if requestCount >= budget then
				break
			end

			requestCount += 1

			task.spawn(function()
				if v:IsOpen() and not v:IsClosing() then
					v:Close()
				end

				if v:IsClosing() then
					repeat
						task.wait()
					until not v:IsClosing()
				end

				-- We decrement this even if the .Close failed so the pass
				-- doesn't hang forever
				documentsToClose -= 1

				if documentsToClose == 0 then
					if coroutine.status(thread) ~= "suspended" then
						return
					end
					-- Defer so that the coroutine.yield() always runs first
					task.defer(thread)
				end
			end)
		end

		-- We need to yield the thread inside the while loop, otherwise we
		-- will try to close the same documents lots of times, which would
		-- waste request budget.
		if documentsToClose > 0 then
			coroutine.yield()
		end

		complete = self._documentsToClose == 0 and self._openingDocuments == 0

		if not complete then
			task.wait(CLOSE_PASS_INTERVAL)
		end
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
