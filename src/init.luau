--!strict
-- Author: Anthony O'Brien

local Document = require("Document")
local DocumentStore = require("DocumentStore")
local Types = require("Types")

export type LockedResponse = Types.LockedResponse
export type PreHookEvent = Types.PreHookEvent
export type PostHookEvent = Types.PostHookEvent
export type Document<T> = Document.Document<T>
export type Result<T> = Document.Result<T>

return {
	DocumentStore = DocumentStore,
	Document = Document,
}
