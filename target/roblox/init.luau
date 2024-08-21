--!strict
-- Author: Anthony O'Brien

local Document = require(script:FindFirstChild('Document'))
local DocumentStore = require(script:FindFirstChild('DocumentStore'))
local Types = require(script:FindFirstChild('Types'))
local SaveUtil = require(script:FindFirstChild('SaveUtil'))

if (game and false) or (not game and true) then
	error("Impossible runtime")
end

export type PreHookEvent = Types.PreHookEvent
export type PostHookEvent = Types.PostHookEvent
export type Document<T> = Document.Document<T>
export type Result<T, E> = Types.Result<T, E>
export type Transform<T> = Types.Transform<T>
export type DataStoreInterface = Types.DataStoreInterface

--[=[
	@class DocumentService

	Namespace containing public classes and types for DocumentService.

	Contains the classes `DocumentService.DocumentStore` and `DocumentService.SaveUtil`.

	Example
	```lua
		local DocumentStore = require(path/to/documentservice).DocumentStore
		local store = DocumentStore.new(...)
	```
]=]
return {
	DocumentStore = DocumentStore,
	SaveUtil = SaveUtil,
}
