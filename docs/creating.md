---
sidebar_position: 3
---

# Creating a DocumentStore

You need a `DocumentStore` to get documents to work with!

Here's an example of creating one:

 ```lua
type DataSchema = {
    coins: number,
}

local DataInterface = {
    coins = Guard.Integer,
}

local function dataCheck(value: unknown): DataSchema
    assert(type(value) == "table", "Data must be a table")
    local Value: any = value

    return {
        coins = DataInterface.coins(Value.coins),
    }
end

local store = DocumentStore.new({
    dataStore = DataStoreService:GetDataStore("Test") :: any,
    -- For mockDataStores use below!
    --dataStore = MockDataStore:GetDataStore("Mock"),
    check = Guard.Check(dataCheck),
    default = {
        coins = 100,
    },
    migrations = {},
    lockSessions = true,
})
```

This example uses [Guard](https://util.redblox.dev/guard.html).

You need to cast `DataStore` to `any` currently - while this library does dependency inversion
properly - Roblox's Luau types don't work well with it!

Remember it is important not to create duplicate DocumentStores - they will
be treated like separate sessions! If you need to access a DocumentStore from
multiple scripts, make sure to create and return it from a module.
