--!strict
-- Author: Anthony O'Brien

local Document = require(script.Document)
local DocumentStore = require(script.DocumentStore)
local Types = require(script.Types)

export type LockedResponse = Types.LockedResponse
export type PreHookEvent = Types.PreHookEvent
export type PostHookEvent = Types.PostHookEvent
export type Document<T> = Document.Document<T>
export type Result<T> = Document.Result<T>

return {
	DocumentStore = DocumentStore,
	Document = Document,
}
