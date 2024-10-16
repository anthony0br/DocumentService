--!strict
-- Author: Anthony O'Brien

local Document = require("./Document")
local DocumentStore = require("./DocumentStore")
local Types = require("./Types")
local SaveUtil = require("./SaveUtil")

export type HookEvent = Types.HookEvent
export type Document<T> = Document.Document<T>
export type Result<T, E> = Types.Result<T, E>
export type Err<T> = Types.Err<T>
export type Ok<T> = Types.Ok<T>
export type Transform<T> = Types.Transform<T>
export type DataStoreInterface = Types.DataStoreInterface
export type Migrations = Types.Migrations
export type DocumentStore<T> = DocumentStore.DocumentStore<T>
export type DocumentStoreProps<T> = DocumentStore.DocumentStoreProps<T>

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
	Document = Document,
	SaveUtil = SaveUtil,
}
