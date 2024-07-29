--!strict
-- Contains util functions, such useful hooks, reconciling, migrations
-- Author: Anthony O'Brien

local Types = require("./Types")
local Retry = require("./Retry")

--[=[
	@class Util

	A collection of utility functions for DocumentService.

]=]
local Util = {}

-- Fails after 15 seconds + request time
local RETRY = {
	ATTEMPTS = 5,
	INITIAL_WAIT = 1,
}

-- Written this way to be removed by darklua
if not _G.IS_ROBLOX then
	RETRY = {
		ATTEMPTS = 5,
		INITIAL_WAIT = 1 / 30,
	}
end

local function getUpdateBudget()
	if _G.IS_ROBLOX then
		return game:GetService("DataStoreService"):GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)
	else
		return _G.NO_BUDGET or 60
	end
end

local function getGetBudget()
	if _G.IS_ROBLOX then
		return game:GetService("DataStoreService"):GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)
	else
		return _G.NO_BUDGET or 60
	end
end

--[=[
	Luau uuid implementation

	Based off of https://gist.github.com/jrus/3197011
]=]
function Util.uuid(): (string, number)
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

	return string.gsub(template, "[xy]", function(match)
		local v = if match == "x" then math.random(0, 0xf) else math.random(8, 0xb)

		return string.format("%x", v)
	end)
end

--[=[
	A wrapper for UpdateAsync that retries with exponential backoff and prevents use of the throttle 'queue'
]=]
function Util.updateAsync<T>(
	dataStore: DataStore,
	key: string,
	transform: (any, DataStoreKeyInfo) -> (any, { number }?, {}?)
): (boolean, unknown, DataStoreKeyInfo)
	return Retry(RETRY.ATTEMPTS, RETRY.INITIAL_WAIT, function(): (unknown, DataStoreKeyInfo)
		-- This is necessary to ensure UpdateAsyncs happen in the correct order
		-- since the throttle 'queue' does not respect FILO
		-- If autosaves happen in the wrong order data could be lost
		assert(getUpdateBudget() > 0, "Ran out of budget")

		return dataStore:UpdateAsync(key, transform)
	end)
end

--[=[
	A wrapper for GetAsync that retries with exponential backoff and prevents use of the throttle 'queue'
]=]
function Util.getAsync<T>(dataStore: DataStore, key: string): (boolean, unknown, DataStoreKeyInfo)
	return Retry(RETRY.ATTEMPTS, RETRY.INITIAL_WAIT, function(): (unknown, DataStoreKeyInfo)
		local options

		if _G.IS_ROBLOX then
			options = Instance.new("DataStoreGetOptions")
			options.UseCache = false
		end

		assert(getGetBudget() > 0, "Ran out of budget")

		return dataStore:GetAsync(key, options)
	end)
end

--[=[
	Deeply freezes a table (not entering metatables)

	@param table -- table to freeze
	@return frozenTable
]=]
function Util.deepFreeze<T>(object: T): T
	if typeof(object) ~= "table" then
		return object
	end

	if getmetatable(object) ~= nil then
		return object
	end

	if table.isfrozen(object) then
		return object
	end

	table.freeze(object)

	for _, value in object do
		Util.deepFreeze(value)
	end

	return object
end

return Util
