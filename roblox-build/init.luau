--!strict
-- Author: Anthony O'Brien

local Document = require(script:FindFirstChild('Document'))
local DocumentStore = require(script:FindFirstChild('DocumentStore'))
local Types = require(script:FindFirstChild('Types'))
local Util = require(script:FindFirstChild('Util'))

if (game and false) or (not game and true) then
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
