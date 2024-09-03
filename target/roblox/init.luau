--!strict
-- Author: Anthony O'Brien

local Document = require(script:FindFirstChild('Document'))
local DocumentStore = require(script:FindFirstChild('DocumentStore'))
local Types = require(script:FindFirstChild('Types'))
local SaveUtil = require(script:FindFirstChild('SaveUtil'))

export type HookEvent = Types.HookEvent
export type Document<T> = Document.Document<T>
export type Result<T, E> = Types.Result<T, E>
export type Err<T> = Types.Err<T>
export type Ok<T> = Types.Ok<T>
export type Transform<T> = Types.Transform<T>
export type DataStoreInterface = Types.DataStoreInterface
export type Migrations = Types.Migrations

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
