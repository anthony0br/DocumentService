--!strict
-- Tests for DocumentService

local DocumentService = require("../src/init")
local Guard = require("./Guard")
local DataStoreService = require("../mock-datastore/init").new()

local mockDataStore = DataStoreService:GetDataStore("name")

local Results = {
	passed = 0,
	failed = 0,
	total = 0,
}

local function shouldFail(func: (...any) -> ())
	local success = pcall(func)
	if success then
		error(debug.traceback("Should fail", 2))
	end
end

local function Test(name, test)
	Results.total += 1

	print(`Running test {Results.total}`)

	local success, result = pcall(test)

	if success then
		print(`Test {Results.total} "{name}" passed with {result}\n`)
		Results.passed += 1
	else
		warn(`Test {Results.total} "{name}" failed with {result}\n`)
		Results.failed += 1
	end
end

local CheckInterface = {
	Document = Guard.String,
	Service = Guard.Number,
}

local function check(value: unknown)
	assert(type(value) == "table")
	local Value: any = value

	return {
		Document = CheckInterface.Document(Value.Document),
		Service = CheckInterface.Service(Value.Service),
	}
end

local DocumentStore = DocumentService.DocumentStore.new(
	mockDataStore,
	Guard.Check(check),
	{ Document = "", Service = 2 },
	function()
		return {
			Document = "",
			Service = 3,
		}
	end
)

Test("Opens document no simulated errors", function()
	local Document = DocumentStore:GetDocument("Sublivion")
	local result = Document:Open()
	assert(result.success == true)
	assert(result.data)
	check(result.data)
end)

Test("Cannot reopen same document retrieved by string", function()
	local Document = DocumentStore:GetDocument("Sublivion")
	shouldFail(function()
		Document:Open()
	end)
end)

Test("Can close document", function()
	local Document = DocumentStore:GetDocument("Sublivion")
	Document:Close()
end)

Test("Can reopen document after closed, retrieved by string", function()
	local Document = DocumentStore:GetDocument("Sublivion")
	Document:Open()
end)

do
	local Document = DocumentStore:GetDocument("Sublivion")
	Document:Close()

	Test("Can reopen document after closed, retrieved by reference", function()
		Document:Open()
	end)
end

Test("Opens document with simulated error", function()
	mockDataStore.errors:addSimulatedErrors(1)
	local Document = DocumentStore:GetDocument("Sublivion1")
	local result = Document:Open()
	assert(result.success == true)
	assert(result.data)
	check(result.data)
end)

Test("Opens document with 5 simulated errors", function()
	mockDataStore.errors:addSimulatedErrors(5)
	local Document = DocumentStore:GetDocument("Sublivion2")
	local result = Document:Open()
	assert(result.success == false)
end)

-- Test: Migrate from 'flat data' to DocumentService

-- Test: DocumentStores are independent

-- Test: Corrupt key data

-- Test: out of datastore budget with _G.NO_BUDGET

-- Test: methods should fail if document not open

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

print(`Tests complete. {Results.passed} passed, {Results.failed} failed`)
