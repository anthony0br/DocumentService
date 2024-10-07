---
sidebar_position: 4
---
 
# Setting Up Player Data

This page covers setting up player data for your game, as well as a modulescript to handle everything.

## Setup

We'll need to start with getting services and the required modules
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local DocumentService = require(ReplicatedStorage.Shared.ThirdParty.DocumentService)
local Guard = require(ReplicatedStorage.Shared.Utils.Guard)
```
- `Guard`: Validates data types.

## Player Data Structure

**DataSchema**:
Defines the player's data:
```lua
type DataSchema = {
	-- This can be extended if needed
	Coins: number,
	XP: number,
}
```

**DataInterface**:
Ensuring the data types are correct:
```lua
local DataInterface = {
	-- We expect 'Coins' and 'XP' to be an Integers
	Coins = Guard.Integer,
	XP = Guard.Integer,
}
```

**DataCheck**:
To validate the player's data:
```lua
local function dataCheck(value: unknown): DataSchema
	assert(type(value) == "table", "Data must be a table")
	local Value: any = value

	return {
		Coins = DataInterface.Coins(Value.Coins),
		XP = DataInterface.XP(Value.XP),
	}
end
```

## Creating the Document Store

**DocumentStore**:
Setting up the `DocumentStore` to manage the player's data:
```lua
local PlayerDataStore = DocumentService.DocumentStore.new({
	dataStore = DataStoreService:GetDataStore("PlayerData"),
	check = Guard.Check(dataCheck),
	default = {
		Coins = 0,
		XP = 0,
	},
	migrations = {
		backwardsCompatible = false, 
	},
	lockSessions = true,
})
```
- `BackwardsCompatible`: If `False`, players can only join up-to-date servers.
- `LockSessions`: Prevents the player's data from being accessed to more than one device.

## Managing Player Data

Let's define two functions: `GetDocument` and `CloseDocument`

**GetDocument**:
To fetch a player's document:
```lua
function PlayerData:GetDocument(player: Player)
	return PlayerDataStore:GetDocument(`{player.UserId}`)
end
```

**CloseDocument**:
Close and Save the player's data on exit:
```lua
function PlayerData:CloseDocument(player: Player)
	local document = PlayerDataStore:GetDocument(`{player.Name}_{player.UserId}`)

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

**Strict Mode:** Write your scripts in strict mode. This is essential to make use of the benefits of DocumentService's type-checking

**Seperation:** Put your `DataSchema`, `DataInterface`, and `dataCheck` in a separate ModuleScripts for better maintainability in the long run.

## Editing Player Data

To modify the player's data:
```lua
-- Server
local document = YourPlayerDataModule:GetDocument(player)

if not document:IsOpen() and document:IsOpenAvailable() then
	document:Open()
end

local documentClone = table.clone(document:GetCache())

documentClone.Coins = 99
documentClone.XP = 99
document:SetCache(documentClone)
```
- `document:SetCache()`: This lets us cache player data and save it later with `document:Close()` or `PlayerDataModule:CloseDocument(player)`

## Accessing Data from the Client

To access the player's data from the client:
```lua
-- Server
GetPlayerData_Remote:Connect(function(player)
	local playerDocument = PlayerData:GetDocument(player)

	if playerDocument then
		return playerDocument:Read()
	end

	return {}
end)

-- Client
local playerDocument = GetPlayerData_Remote:Invoke()

print(playerDocument.XP) -- 99
print(playerDocument.Coins) -- 99
```
- `playerDocument:Read()`: Returns the player's data