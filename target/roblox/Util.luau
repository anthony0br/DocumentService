--!strict
-- Contains util functions, such useful hooks, reconciling, migrations
-- Author: Anthony O'Brien

local Retry = require("./Retry")

--[=[
	@class Util

	A collection of utility functions for handling datastores.

	If you need to access any datastores directly while using DocumentService, it is recommended you use these
	functions or similar implementations.

]=]
local Util = {}

-- Fails after 15 seconds + request time
local RETRY = {
	ATTEMPTS = 5,
	INITIAL_WAIT = 1,
}









function Util.getUpdateBudget()
do		
return game:GetService("DataStoreService"):GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)
end


end

function Util.getSetBudget()
do		
return game:GetService("DataStoreService")
			:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementAsync)
end


end

function Util.getGetBudget()
do		
return game:GetService("DataStoreService"):GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)
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

	@yields
]=]
function Util.updateAsync<T>(
	dataStore: GlobalDataStore,
	key: string,
	transform: (any, DataStoreKeyInfo) -> (any, { number }?, {}?)
): (boolean, unknown, DataStoreKeyInfo)
	return Retry(RETRY.ATTEMPTS, RETRY.INITIAL_WAIT, function(): (unknown, DataStoreKeyInfo)
		-- This is necessary to ensure UpdateAsyncs happen in the correct order
		-- since the throttle 'queue' does not respect FILO
		-- If autosaves happen in the wrong order data could be lost
		assert(Util.getUpdateBudget() > 0, "Ran out of budget")

		return dataStore:UpdateAsync(key, transform)
	end)
end

--[=[
	A wrapper for GetAsync that retries with exponential backoff and prevents use of the throttle 'queue'

	@yields
]=]
function Util.getAsync<T>(dataStore: GlobalDataStore, key: string): (boolean, unknown, DataStoreKeyInfo)
	return Retry(RETRY.ATTEMPTS, RETRY.INITIAL_WAIT, function(): (unknown, DataStoreKeyInfo)
		local options
do			

options = Instance.new("DataStoreGetOptions")
			options.UseCache = false
end
		
assert(Util.getGetBudget() > 0, "Ran out of budget")

		return dataStore:GetAsync(key, options)
	end)
end

--[=[
	A wrapper for SetAsync that retries with exponential backoff and prevents use of the throttle 'queue'.

	I recommend you only use this for edge cases like erasing data.

	@yields
]=]
function Util.setAsync<T>(dataStore: GlobalDataStore, key: string, value: any)
	return Retry(RETRY.ATTEMPTS, RETRY.INITIAL_WAIT, function()
		-- This is necessary to ensure UpdateAsyncs happen in the correct order
		-- since the throttle 'queue' does not respect FILO
		-- If autosaves happen in the wrong order data could be lost
		assert(Util.getSetBudget() > 0, "Ran out of budget")

		return dataStore:SetAsync(key, value)
	end)
end

--[=[
	Deeply freezes a table (not entering metatables)

	@param object -- table to freeze
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

--[=[
	Errors if the data passed is not storable in JSON

	Rejects:
		NaN (all numbers must equal themselves)
		Mixed table index types
		Non sequential tables indexed by numbers
		Non-string or number table indexes
		Cyclic tables
		type(value) == "userdata"

	@param data
]=]
function Util.assertStorable(data: unknown)
	local indexDataType 
	-- Check for NaN, inf, -inf
	
assert(data == data, "NaN is not storable")

	assert(type(data) ~= "userdata", "userdata is not storable")

	if type(data) == "table" then
		local last
		for i, v in data :: {} do
			if not indexDataType then
				indexDataType = type(i)

				if not (indexDataType == "string" or indexDataType == "number") then
					error("Table indexes must be strings or numbers")
				end
			end

			if indexDataType and type(i) ~= indexDataType then
				error("Tables with multiple index types are not storable")
			end

			if type(i) == "number" and last then
				if i - last ~= 1 then
					error("Tables with number indexes must be sequential")
				end

				last = i
			end

			if v == data then
				error("Tables cannot be cyclic")
			end

			Util.assertStorable(v)
		end
	end
end

return Util
