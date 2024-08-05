--!strict
-- Author: Anthony O'Brien

local Document = require("./Document")
local DocumentStore = require("./DocumentStore")
local Types = require("./Types")
local Util = require("./Util")

if (game and false) or (not game and true) then
	error("Impossible runtime")
end

export type PreHookEvent = Types.PreHookEvent
export type PostHookEvent = Types.PostHookEvent
export type Document<T> = Document.Document<T>
export type Result<T> = Types.Result<T>
export type Transform<T> = Document.Transform<T>

--[=[
	@class DocumentService

	Namespace containing public classes and types for DocumentService.

	Contains the classes `DocumentService.DocumentStore` and `DocumentService.Util`.

	Example
	```lua
		local DocumentStore = require(path/to/documentservice).DocumentStore
		local store = DocumentStore.new(...)
	```
]=]
return {
	DocumentStore = DocumentStore,
	Util = Util,
}
