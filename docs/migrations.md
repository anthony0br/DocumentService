
---
sidebar_position: 6
---

# Migrating to a new data version
To add and remove values from your database, you must use migrations.
Here is an example migrating to a data version with the Time value.
This example uses [Sift.](https://github.com/cxmeel/sift?tab=readme-ov-file#sift)
```lua
-- Migrations take data from the version one less than their index in the table, and update the data to the next version
type DataSchema = {
	Coins: number,
	XP: number,
	Time: number,
	-- Add test value on data version 2
	-- Remove test value on data version 3
}

local DataInterface = {
	Coins = Guard.Integer,
	XP = Guard.Integer,
	Time = Guard.Integer,
	-- Add test value on data version 2
	-- Remove test value on data version 3
}

local function dataCheck(value: unknown): DataSchema
	assert(type(value) == "table", "Data must be a table")
	local Value: any = value

	return {
		Coins = DataInterface.Coins(Value.Coins),
		XP = DataInterface.XP(Value.XP),
		Time = DataInterface.Time(Value.Time),
		-- Add test value on data version 2
		-- Remove test value on data version 3
	}
end

local migrations: {{backwardsCompatible: boolean,migrate: (any) -> any,}} = {
	[1] = {
		backwardsCompatible = false, -- If a player joins an old server with an outdated data version, DocumentService will throw an error and kick the player
		migrate = function(old)
			return Sift.Dictionary.merge(old, {
				Time = 0,
			})
		end,
	},
	[2] = {
		backwardsCompatible = true, -- If a player joins an old server with an outdated data version, DocumentService will load the previous data version
		migrate = function(old)
			return Sift.Dictionary.merge(old, {
				test = 999,
			})
		end,
	},
	[3] = {
		backwardsCompatible = false, 
		migrate = function(old)
			old.test = nil
			return old
		end,
	}
}

local PlayerDataStore = DocumentService.DocumentStore.new({
	dataStore = DataStoreService:GetDataStore("Test"),
	check = Guard.Check(dataCheck),
	default = {
		Coins = 0,
		XP = 0,
		Time = 0,
		-- Add test value on data version 2
		-- Remove test value on data version 3
	},
	migrations = migrations,
	lockSessions = true,
})
```
Another option to fix data version overlap is to use `Migrate to Latest Update` every time you migrate data to a new version.
