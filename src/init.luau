--!strict
-- Author: Anthony O'Brien

local Document = require("./Document")
local DocumentStore = require("./DocumentStore")
local Types = require("./Types")

if game and not _G.IS_ROBLOX or (not game and _G.IS_ROBLOX) then
	error("Impossible _G.IS_ROBLOX")
end

export type LockedResponse = Types.LockedResponse
export type PreHookEvent = Types.PreHookEvent
export type PostHookEvent = Types.PostHookEvent
export type Document<T> = Document.Document<T>
export type Result<T> = Document.Result<T>

return {
	DocumentStore = DocumentStore,
	Document = Document,
}
