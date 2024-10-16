---
sidebar_position: 4
---
 
# Setting Up Player Data

This page covers setting up player data for your game, as well as a modulescript to handle everything.

## Setup

Get the required services and libraries.
```lua
local DataStoreService = game:GetService("DataStoreService")

local DocumentService = require(path.to.DocumentService)
local Guard = require(path.to.Guard)
```
- `Guard`: Used to validate data types.

## Player Data Structure

You need to define a structure for your data - this is called a schema.

**Define a type**:
It is useful to define your schema as a type.
```lua
type DataSchema = {
	Coins: number,
	XP: number,
}
```
You can add more fields as needed.

**Check function**:

The check function takes an unknown value (the value from Data Stores) and
verifies that it meets the correct format by returning a boolean. The second return type must match the
type of your default - however, this is only to help you prevent mistakes.

A good way to create a check function is to use [Guard](https://util.redblox.dev/guard.html). Create a standard interface check in Guard, and then wrap it with Guard.Check so it returns a boolean.

Note that, while it is recommended that you use a check function, you can of course write one
that always returns true if you are confident data won't be mistakenly corrupted!

```lua
local DataInterface = {
	Coins = Guard.Integer,
	XP = Guard.Integer,
}

local function dataCheck(value: unknown): DataSchema
	assert(type(value) == "table", "Data must be a table")
	local Value: any = value

	return {
		Coins = DataInterface.Coins(Value.Coins),
		XP = DataInterface.XP(Value.XP),
	}
end
```

## Creating the DocumentStore

**DocumentStore**:
Set up the [DocumentStore](https://anthony0br.github.io/DocumentService/api/DocumentStore/) for player data.
```lua
local PlayerDocumentStore = DocumentService.DocumentStore.new({
	dataStore = DataStoreService:GetDataStore("PlayerData"),
	check = Guard.Check(dataCheck),
	default = {
		Coins = 0,
		XP = 0,
	},
	migrations = {
		backwardsCompatible = false, 
	},
	-- This is an important feature of player data. It locks editing to one server
	-- at a time, allowing us to safely cache player data and save batches of updates.
	-- We do this through additional methods that session locking unlocks, such as
	-- `SetCache` and `GetCache`.
	lockSessions = true,
})
```
- `BackwardsCompatible`: If `False`, players can only join up-to-date servers.
- `LockSessions`: Prevents multiple devices from accessing the same player's data simultaneously.

## Managing Player Data

**GetDocument**:
Fetch a player's document:
```lua
function PlayerData:GetDocument(player: Player)
	return PlayerDocumentStore:GetDocument(`{player.UserId}`)
end
```

**CloseDocument**:
Save the player's data when they exit:
```lua
function PlayerData:CloseDocument(player: Player)
	local document = PlayerDocumentStore:GetDocument(`{player.Name}_{player.UserId}`)

	if not document:IsOpen() and document:IsOpenAvailable() then
		document:Open()
	end

	if document and document:IsOpen() then
		local successfulClose, closeResult = pcall(function()
			return document:Close()
		end)

		if not successfulClose then
			warn("Failed to close document for player:", player.Name, "Error:", closeResult)
		end
	else
		warn("Failed to retrieve document for player:", player.Name)
	end
end
```

## Best Practices

**Strict Mode:** Always write your scripts in strict mode to benefit from the type-checking features of DocumentService.

**Seperation:** Put your `DataSchema`, `DataInterface`, and `dataCheck` in a separate ModuleScript for better maintainability.

## Editing Player Data

To modify the player's data on the **Server**:
Note that this assumes the player is in the server!
```lua
local document = YourPlayerDataModule:GetDocument(player)

if not document:IsOpen() then
	-- See "Waiting for a Document to Open" page if you need to wait for the document to be open
end

-- We need to clone the table and any sub-tables we intend to edit, since
-- DocumentService freezes tables on SetCache.
-- This forces immutable updates and helps you avoid creating bugs!
local documentClone = table.clone(document:GetCache())

documentClone.Coins = 99
documentClone.XP = 99
document:SetCache(documentClone)
```
- `document:SetCache()`: Updates the player's data cache, which is saved when the document is closed.

## Accessing Data from the Client

Access the player's data from the **Client**:
```lua
-- Server
GetPlayerData_Remote:Connect(function(player)
	local playerDocument = PlayerData:GetDocument(player)

	return playerDocument:GetCache()
end)

-- Client
local playerDocument = GetPlayerData_Remote:Invoke()

print(playerDocument.XP) -- 99
print(playerDocument.Coins) -- 99
```
- `playerDocument:Read()`: Returns the player's data