--!strict
-- Tests for DocumentService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Guard = require(ReplicatedStorage.DevPackages.Guard)
local Future = require(ReplicatedStorage.DevPackages.Future)
local DocumentService = require(game.ServerScriptService.DocumentService)

-- Test: Creating a Document Interface
local function check(value)
	return {
		test = Guard.String(value),
	}
end

local DocumentStore = DocumentService.GetDocumentStore("test", check, { test = "default" })

local Document = DocumentStore:GetDocument("Sublivion")
Document:Open()

-- This type checks!
local result = Document:Read()
if result.success then
	print(result.data.test)
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
