--!strict
-- Tests for DocumentService

local DocumentService = require("../src/init")
local Guard = require("./Guard")
local DataStoreService = require("../mock-datastore/init").new()

-- Test retry, assuming datastore access is off
local test = DataStoreService:GetDataStore("test1")
local Retry = require("../src/Retry")
print(Retry(3, 2, test.UpdateAsync, test, "testkey", "testdata"))

-- Test: Creating a Document Interface
local check = Guard.Check(function(value)
	return {
		test = Guard.String(value),
	}
end)

local DocumentStore =
	DocumentService.DocumentStore.new(DataStoreService:GetDataStore("name"), check, { test = "default" })

local Document = DocumentStore:GetDocument("Sublivion")
Document:Open()

Document:PreHook("Update", function(transform)
	print(transform)
end)

-- This type checks!
local result = Document:Read()
if result.success then
	print(result.data)
else
	print(result.failReason :: string, result.errorMessage)
end

-- Test: methods should fail if document not open

-- Test: document open and closing

-- Test: Data in datastore does not match interface should run invalid data handler

-- Test: Data in datastore does not match interface should error if invalid data handler is unsuccessful

-- Test: locking

-- Test: Steal mode

-- Test: Await mode

-- Test: Data matches interface

-- Test: Data reads correctly

-- Test: Session lock functions

-- Test: Transactions

-- Test: hooks

-- Test: If session lock expired, a new session lock should be created

-- Test: Transactions should fail if session stolen

-- Test: Session locks should stay open
