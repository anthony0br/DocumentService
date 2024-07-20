--!strict
-- Tests for DocumentService
local DocumentService = require(game.ServerScriptService.DocumentService)

-- Test: Creating a Document Interface
local DocumentStore = DocumentService:GetDocumentStore("test")

-- Test: Data in datastore does not match interface

-- Test: Data matches interface

-- Test: Data reads correctly

-- Test: Session lock functions

-- Test: Transactions
