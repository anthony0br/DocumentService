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
		print(`Test {Results.total} "{name}" passed.\n`)
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
	{}
)

Test("Opens document with no simulated errors", function()
	local document = DocumentStore:GetDocument("1")
	local result = document:Open()
	assert(result.success == true)
	assert(result.data)
	check(result.data)
	print(result.data)
end)

Test("Can close document retrieved by string", function()
	local document = DocumentStore:GetDocument("1")
	print(tostring(document))
	local result = document:Close()
	assert(result.success == true)
end)

Test("Can reopen document after closed, retrieved by string", function()
	local document = DocumentStore:GetDocument("1")
	local result = document:Open()
	assert(result.success == true)
	assert(result.data)
	check(result.data)
end)

Test("Opens document with simulated error", function()
	mockDataStore.errors:addSimulatedErrors(1)
	local document = DocumentStore:GetDocument("2")
	local result = document:Open()
	assert(result.success == true)
	assert(result.data)
	check(result.data)
	document:Close()
end)

Test("Opens document with 4 simulated errors", function()
	mockDataStore.errors:addSimulatedErrors(4)
	local document = DocumentStore:GetDocument("2")
	local result = document:Open()
	assert(result.success == true)
	assert(result.data)
	check(result.data)
	document:Close()
end)

-- Now that all operations only use a single datastore API request, we only need
-- to test up to 5 simulated errors
Test("Fails to open document with 5 simulated errors", function()
	mockDataStore.errors:addSimulatedErrors(5)
	local document = DocumentStore:GetDocument("3")
	local result = document:Open()
	assert(result.success == false)
	print(result)
end)

-- Test: Migrate from 'flat data' to DocumentService

-- Test: DocumentStores are independent

-- Test: Corrupt key data

-- Test: out of datastore budget with _G.NO_BUDGET

-- Test: methods should fail if document not open

-- Test: Data in datastore does not match interface should run invalid data handler

-- Test: Data in datastore does not match interface should error if invalid data handler is unsuccessful

-- Test: locking

-- Test: Data matches interface

-- Test: Data reads correctly

-- Test: Session lock functions

-- Test: Transactions

-- Test: hooks

-- Test: If session lock expired, a new session lock should be created

-- Test: Transactions should fail if session stolen

-- Test: Session locks should stay open

-- No budget tests

print(`Tests complete. {Results.passed} passed, {Results.failed} failed`)
