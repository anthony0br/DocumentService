--!strict
-- Author: Anthony O'Brien

--[=[
	@class FakeStore

	A mock data store
]=]
local FakeStore = {}
FakeStore.__index = FakeStore

export type FakeStore = typeof(setmetatable(
	{} :: {
		_data: any,
	},
	FakeStore
))

function FakeStore.new(): FakeStore
	return setmetatable({
		_data = nil,
		_thread,
	}, FakeStore)
end

function FakeStore.GetAsync(self: FakeStore) end

function FakeStore.UpdateAsync(self: FakeStore) end

function FakeStore.Succeed() end

function FakeStore.Fail() end

return FakeStore
