--!strict
-- Author: Anthony O'Brien

local Document = require("./Document")
local DocumentStore = require("./DocumentStore")
local Types = require("./Types")
local Util = require("./Util")

if (game and not _G.IS_ROBLOX) or (not game and _G.IS_ROBLOX) then
	error("Impossible runtime")
end

export type LockedResponse = Types.LockedResponse
export type PreHookEvent = Types.PreHookEvent
export type PostHookEvent = Types.PostHookEvent
export type Document<T> = Document.Document<T>
export type Result<T> = Types.Result<T>
export type Transform<T> = Document.Transform<T>

return {
	DocumentStore = DocumentStore,
	Util = Util,
}
