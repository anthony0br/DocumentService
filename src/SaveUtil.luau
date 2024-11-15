--!strict
-- Contains utility functions for DataStores
-- Author: Anthony O'Brien

local DataStoreService
if _G.IS_ROBLOX then
	DataStoreService = game:GetService("DataStoreService")
end

local Retry = require("./Retry")
local Types = require("./Types")

type DataStoreInterface = Types.DataStoreInterface

--[=[
	@class SaveUtil

	A collection of utility functions for handling datastores.

	If you need to access any datastores directly while using DocumentService,
	it is recommended you use these functions or similar implementations.

]=]
local SaveUtil = {}

-- Fails after 15 seconds + request time
local RETRY = {
	ATTEMPTS = 5,
	INITIAL_WAIT = 1,
}

-- Written this way to be removed by darklua
if not _G.IS_ROBLOX then
	RETRY = {
		ATTEMPTS = 5,
		INITIAL_WAIT = 0,
	}
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
		Functions
		Metatables
		Threads
		Vectors

	@param data
]=]
function SaveUtil.assertStorable(data: unknown, fieldName: string?)
	local indexDataType = nil

	if not fieldName then
		fieldName = "Data"
	end

	-- Check for NaN, inf, -inf
	assert(data == data, `NaN is not storable. Field: {fieldName}`)

	local dataType = type(data)

	assert(dataType ~= "userdata", `Userdata is not storable in DataStores. Field: {fieldName}`)

	assert(dataType ~= "thread", `Threads are not storable in DataStores. Field: {fieldName}`)

	assert(dataType ~= "function", `Functions are not storable in DataStores. Field: {fieldName}`)

	if dataType == "string" then
		local len = utf8.len(data :: string)
		assert(len, `Strings with invalid UTF-8 codepoints are not storable in Datastores. Field: {fieldName}`)
	end

	if dataType == "table" then
		assert(getmetatable(data :: any) == nil, `Metatables are not storable in DataStores. Field: {fieldName}`)

		local last
		for i, v in data :: {} do
			if not indexDataType then
				indexDataType = type(i)

				if not (indexDataType == "string" or indexDataType == "number") then
					error(`Table indexes must be strings or numbers to be storable. Field: {fieldName}`)
				end
			end

			if indexDataType and type(i) ~= indexDataType then
				error(`Tables must only have on type of index to be storable. Field: {fieldName}`)
			end

			if type(i) == "number" and last then
				if i - last ~= 1 then
					error(`Tables with number indexes must be sequential. Field: {fieldName}`)
				end

				last = i
			end

			if v == data then
				error(`Tables cannot be cyclic. Field: {fieldName}`)
			end

			SaveUtil.assertStorable(v, tostring(i))
		end
	end
end

function SaveUtil.getUpdateBudget()
	if _G.IS_ROBLOX then
		return DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)
	else
		return 60
	end
end

function SaveUtil.getSetBudget()
	if _G.IS_ROBLOX then
		return game:GetService("DataStoreService")
			:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementAsync)
	else
		return 60
	end
end

function SaveUtil.getGetBudget()
	if _G.IS_ROBLOX then
		return game:GetService("DataStoreService"):GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)
	else
		return 60
	end
end

--[=[
	Luau uuid implementation.

	Based off of https://gist.github.com/jrus/3197011
]=]
function SaveUtil.uuid(): string
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

	-- Store in uuid string.format returns two values and we only want the first
	local uuid = string.gsub(template, "[xy]", function(match)
		local v = if match == "x" then math.random(0, 0xf) else math.random(8, 0xb)

		return string.format("%x", v)
	end)

	return uuid
end

--[=[
	A wrapper for UpdateAsync that retries with exponential backoff, prevents
	use of the throttle 'queue', and allows retries to be aborted.

	@yields
]=]
function SaveUtil.updateAsync<T>(
	transform: ((err: string) -> (), unknown, DataStoreKeyInfo) -> (any, { number }?, {}?),
	dataStore: DataStoreInterface,
	key: string
): (boolean, any, DataStoreKeyInfo)
	local result = Retry(RETRY.ATTEMPTS, RETRY.INITIAL_WAIT, function(): (any, DataStoreKeyInfo)
		-- This exists because for some reason, the behaviour of errors in the
		-- UpdateAsync transform is to return nil and error on a new thread
		local shouldAbort = false
		local abortError: string
		local function abortAttempt(err: string)
			shouldAbort = true
			abortError = err
		end

		-- This is necessary to ensure autosaves happen in the correct order and saves have predictable timeouts
		-- since Retry will give up long before the next autosave and the throttle 'queue' does not respect FIFO
		assert(SaveUtil.getUpdateBudget() > 0, "Ran out of budget")

		local resultData, resultKeyInfo = dataStore:UpdateAsync(key, function(data: any, keyInfo: DataStoreKeyInfo)
			local transformResult = transform(abortAttempt, data, keyInfo)

			if shouldAbort then
				return data
			else
				return transformResult
			end
		end)

		if shouldAbort then
			error(abortError)
		end

		return resultData, resultKeyInfo
	end)

	return result.success, result.returnValues[1], result.returnValues[2]
end

--[=[
	A wrapper for GetAsync that retries with exponential backoff and prevents
	use of the throttle 'queue'.

	@yields
]=]
function SaveUtil.getAsync<T>(dataStore: DataStoreInterface, key: string): (boolean, any, DataStoreKeyInfo)
	local result = Retry(RETRY.ATTEMPTS, RETRY.INITIAL_WAIT, function(): (any, DataStoreKeyInfo)
		local options

		if _G.IS_ROBLOX then
			options = Instance.new("DataStoreGetOptions")
			options.UseCache = false
		end

		assert(SaveUtil.getGetBudget() > 0, "Ran out of budget")

		local resultData, resultKeyInfo = dataStore:GetAsync(key, options)

		return resultData, resultKeyInfo
	end)

	return result.success, result.returnValues[1], result.returnValues[2]
end

--[=[
	A wrapper for RemoveAsync

	@yields
]=]
function SaveUtil.removeAsync<T>(dataStore: DataStoreInterface, key: string): boolean
	local result = Retry(RETRY.ATTEMPTS, RETRY.INITIAL_WAIT, function()
		assert(SaveUtil.getSetBudget() > 0, "Ran out of budget")

		return dataStore:RemoveAsync(key)
	end)

	return result.success
end

return SaveUtil
