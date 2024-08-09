--!strict
-- Author: Anthony O'Brien

local Document = require("./Document")
local DocumentStore = require("./DocumentStore")
local Types = require("./Types")
local SaveUtil = require("./SaveUtil")

if (game and not _G.IS_ROBLOX) or (not game and _G.IS_ROBLOX) then
	error("Impossible runtime")
end

export type PreHookEvent = Types.PreHookEvent
export type PostHookEvent = Types.PostHookEvent
export type Document<T> = Document.Document<T>
export type Result<T, E> = Types.Result<T, E>
export type Transform<T> = Types.Transform<T>

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
