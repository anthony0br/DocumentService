
---
sidebar_position: 6
---
# What are Migrations?
Migrations are a simple way to mutate values in the data schema to add, remove, change the data structure's format, or fix inconsistencies in data.
The migrations are stored in a table, where each migration contains a table with a boolean for backwards compatibility and a migrate function.

# Migrating to a new data version
To add and remove values from your data schema, you must use migrations.
Here is an example migrating to a data version with the Time value.
This example uses [Sift.](https://github.com/cxmeel/sift?tab=readme-ov-file#sift) You may use any other module that can merge dictionaries or implement a method to merge the two dictionaries yourself.
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
	{
		backwardsCompatible = false, -- If a player joins an old server with an outdated data version, DocumentService will throw an error and kick the player
		migrate = function(old)
			return Sift.Dictionary.merge(old, {
				Time = 0,
			})
		end,
	},
	{
		backwardsCompatible = true, -- If a player joins an old server with an outdated data version, DocumentService will load the previous data version
		migrate = function(old)
			return Sift.Dictionary.merge(old, {
				test = 999,
			})
		end,
	},
	{
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
# Backwards Compatibility
As seen in the code example, you may set the backwards compatibility in a migration to true in order to utilize backwards compatibility. It works by rolling the player's data back to the previous data version if the server they are in is outdated.
If backwards compatibility is disabled in a data version, any player will be kicked upon joining a server with an outdated data version. 
Instead of using backwards compability, you can always use the `Migrate to Latest Update` function for a game every time you migrate data to a new version.
