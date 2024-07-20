--!strict
-- Tests for DocumentService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Guard = require(ReplicatedStorage.DevPackages.Guard)
local DocumentService = require(game.ServerScriptService.DocumentService)

-- Test: Creating a Document Interface
local function check(value)
	return {
		test = Guard.String(value),
	}
end

local DocumentStore = DocumentService.GetDocumentStore("test", check, { test = "default" }, function(lock1, lock2)
	return "Cancel"
end)

local Document = DocumentStore:GetDocument("Sublivion")
Document:Open()
Document:Hook("Update", function(result: DocumentService.Result<typeof({ test = "default" })>)
	if result.success then
		print(result.data)
	end
end)

-- This type checks!
local result = Document:Read()
if result.success then
	print(result.data.test)
else
	print(result.failReason :: string, result.errorMessage)
end

-- Test: methods should fail if document not open

-- Test: document open and closing

-- Test: Data in datastore does not match interface

-- Test: Data matches interface

-- Test: Data reads correctly

-- Test: Session lock functions

-- Test: Transactions

-- Test: hooks
