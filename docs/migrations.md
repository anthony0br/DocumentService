---
sidebar_position: 6
---

# Migrations

## What are Migrations?

Migrations allow you to safely evolve your data schema over time. They let you add new fields, remove old ones, rename properties, or transform data structure without losing player data. Each migration transforms data from one schema version to the next.

Migrations in DocumentService are stored as a table of migration objects, where each migration specifies whether it supports backwards compatibility and provides a function to transform the data.

### Type Definition

```lua
type Migrations = {{
	backwardsCompatible: boolean,
	migrate: (data: any) -> any,
}}
```

### How Versioning Works

- Data format versions start at **0**. Any existing data in the key before you open a Document is considered version 0.
- The **first migration** should migrate data from version 0 to version 1.
- The **current version** is defined by the length of the migrations array.
- If you have 3 migrations, the current version is 3.
- Each migration transforms data from `version - 1` to `version`.

## Why Use Migrations?

As your game evolves, your player data schema will change. Rather than forcing all players to reset or manually updating everyone's data, migrations automate this process:

- **Add new fields** with default values when you introduce new systems
- **Remove obsolete fields** when features are no longer needed  
- **Transform existing data** to fix inconsistencies or restructure values
- **Handle version mismatches** gracefully with backwards compatibility

## Creating Migrations

Here's a complete example showing how to set up and use migrations:

```lua
type DataSchema = {
	Coins: number,
	XP: number,
	Time: number,
}

local DataInterface = {
	Coins = Guard.Integer,
	XP = Guard.Integer,
	Time = Guard.Integer,
}

local function dataCheck(value: unknown): DataSchema
	assert(type(value) == "table", "Data must be a table")
	local Value: any = value

	return {
		Coins = DataInterface.Coins(Value.Coins),
		XP = DataInterface.XP(Value.XP),
		Time = DataInterface.Time(Value.Time),
	}
end

local migrations: {{backwardsCompatible: boolean, migrate: (any) -> any}} = {
	{
		backwardsCompatible = false,
		migrate = function(old)
			old.Time = 0
			return old
		end,
	},
	{
		backwardsCompatible = true,
		migrate = function(old)
			old.Playtime = 0
			return old
		end,
	},
}

local PlayerDataStore = DocumentService.DocumentStore.new({
	dataStore = DataStoreService:GetDataStore("PlayerData"),
	check = Guard.Check(dataCheck),
	default = {
		Coins = 0,
		XP = 0,
		Time = 0,
	},
	migrations = migrations,
	lockSessions = true,
})
```

## Understanding Backwards Compatibility

Each migration has a `backwardsCompatible` flag that controls how older servers handle newer player data:

### `backwardsCompatible = false`
When a player with newer data joins an old server, they are kicked with a `BackwardsCompatibilityError`. Use this when:
- The new data structure is required for the server to function properly
- You want to force players to play on updated servers
- The old code cannot safely interpret the new data format

**⚠️ WARNING:** If you make a not-backwards-compatible migration on non-session-locked Documents, you must shut down all servers, or old servers will break.

### `backwardsCompatible = true`
When a player with newer data joins an old server, DocumentService automatically rolls back their data to the previous version. Use this when:
- The new field is optional and old code can work without it
- You're adding new fields that don't affect core gameplay
- You want servers to be updated gradually without forcing players out

See the [opening documents guide](./opening.md) for error handling examples when players encounter backwards compatibility issues.

## Tips & Best Practices

**Keep migrations simple:** Modify the table directly or create a new table with your transformed fields. No external libraries needed.

**Keep migrations small and focused:** Each migration should do one thing. If you're restructuring data heavily, consider multiple smaller migrations.

**Test data transformations:** Always test migrations with real player data scenarios. Use mock data stores to verify the migration path works correctly.

**Document the schema change:** In a comment above each migration, explain what schema change it implements. This helps future maintainers understand the evolution.

**Never modify old migrations:** Once deployed, migrations are permanent. If you need to fix a migration, create a new one that corrects the issue.

**Use meaningful field names:** Rename fields only if it significantly improves clarity. Field renames require data transformation migrations and can add complexity.

**Handle edge cases:** Consider players with very old data. If a player's data is missing expected fields, migrations should gracefully initialize them.