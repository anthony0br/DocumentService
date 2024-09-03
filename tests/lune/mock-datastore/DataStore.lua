if not _G.IS_ROBLOX then
	task = require("@lune/task")
	DateTime = require("@lune/datetime")
end

local Constants = require("./Constants")
local DataStoreKeyInfo = require("./DataStoreKeyInfo")
local validateString = require("./validateString")

local function copyDeep(value)
	if typeof(value) ~= "table" then
		return value
	end

	local copy = {}

	for a, b in value do
		copy[a] = copyDeep(b)
	end

	return copy
end

local function copyDataStoreKeyInfo(keyInfo)
	return DataStoreKeyInfo.new(
		keyInfo.CreatedTime,
		keyInfo.UpdatedTime,
		keyInfo.Version,
		keyInfo.userIds,
		keyInfo.metadata
	)
end

local DataStore = {}
DataStore.__index = DataStore

function DataStore.new(budget, errors, yield)
	return setmetatable({
		data = {},
		keyInfos = {},
		getCache = {},
		budget = budget,
		errors = errors,
		yield = yield,
	}, DataStore)
end

function DataStore:write(key, data, userIds, metadata)
	local now = if _G.IS_ROBLOX then DateTime.now().UnixTimestampMillis else DateTime.now().unixTimestampMillis

	local keyInfo = self.keyInfos[key]

	if keyInfo ~= nil then
		local version = tostring(tonumber(keyInfo.Version) + 1)

		self.keyInfos[key] = DataStoreKeyInfo.new(keyInfo.CreatedTime, now, version, userIds, metadata)
	else
		self.keyInfos[key] = DataStoreKeyInfo.new(now, now, "0", userIds, metadata)
	end

	-- Data is written after key info because DataStoreKeyInfo.new can throw an error.
	self.data[key] = copyDeep(data)
end

function DataStore:GetAsync(key: string, options: DataStoreGetOptions?)
	validateString("key", key, Constants.MAX_KEY_LENGTH)

	if self.errors ~= nil then
		self.errors:simulateError("GetAsync")
	end

	if (options == nil or options.UseCache) and self.getCache[key] ~= nil and os.clock() < self.getCache[key] then
		local data = self.data[key]
		local keyInfo = self.keyInfos[key]

		if data == nil then
			return nil, nil
		end

		return copyDeep(data), copyDataStoreKeyInfo(keyInfo)
	end

	self.budget:yieldForBudget({ Enum.DataStoreRequestType.GetAsync })

	self.getCache[key] = os.clock() + Constants.GET_CACHE_DURATION

	self.yield:yield()

	local data = self.data[key]
	local keyInfo = self.keyInfos[key]

	if data == nil then
		return nil, nil
	end

	return copyDeep(data), copyDataStoreKeyInfo(keyInfo)
end

function DataStore:UpdateAsync(key: string, transform)
	validateString("key", key, Constants.MAX_KEY_LENGTH)

	if typeof(transform) ~= "function" then
		error("`transform` must be a function")
	end

	if self.errors ~= nil then
		self.errors:simulateError("UpdateAsync")
	end

	local usingGetCache = self.getCache[key] ~= nil and os.clock() < self.getCache[key]

	local requestsTypes = if usingGetCache
		then { Enum.DataStoreRequestType.SetIncrementAsync }
		else { Enum.DataStoreRequestType.GetAsync, Enum.DataStoreRequestType.SetIncrementAsync }

	self.budget:yieldForBudget(requestsTypes)
	self.yield:yield()

	local oldValue = copyDeep(self.data[key])
	local oldKeyInfo = if oldValue ~= nil then copyDataStoreKeyInfo(self.keyInfos[key]) else nil

	local ok, transformed, userIds, metadata = pcall(transform, oldValue, oldKeyInfo)

	if not ok then
		task.spawn(error, transformed)
		return nil
	end

	if transformed == nil then
		return nil
	end

	-- TODO: Make sure transformed data is savable.

	self:write(key, transformed, userIds, metadata)

	self.getCache[key] = os.clock() + Constants.GET_CACHE_DURATION

	return copyDeep(transformed), copyDataStoreKeyInfo(self.keyInfos[key])
end

function DataStore:RemoveAsync(key: string)
	validateString("key", key, Constants.MAX_KEY_LENGTH)

	if self.errors ~= nil then
		self.errors:simulateError("RemoveAsync")
	end

	self.budget:yieldForBudget({ Enum.DataStoreRequestType.SetIncrementAsync })
	self.yield:yield()

	local oldValue = self.data[key]
	local keyInfo = self.keyInfos[key]

	if oldValue == nil then
		return nil, nil
	end

	self:write(key)

	return copyDeep(oldValue), copyDataStoreKeyInfo(keyInfo)
end

return DataStore
