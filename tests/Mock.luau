--!strict
-- Tests for DocumentService

local DocumentService = require("../src/init")
local Guard = require("./Guard")
local DataStoreService = require("../mock-datastore/init").new()

local Results = {
	passed = 0,
	failed = 0,
	total = 0,
}

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
	test = Guard.String,
}

local function check(value: unknown)
	assert(type(value) == "table")
	local Value: any = value

	return {
		test = CheckInterface.test(Value.test),
	}
end

local DocumentStore =
	DocumentService.DocumentStore.new(DataStoreService:GetDataStore("name"), Guard.Check(check), { test = "default" })

Test("Opens document no simulated errors", function()
	local Document = DocumentStore:GetDocument("Sublivion")
	local result = Document:Open()
	print(result)
	assert(result.success == true)
	assert(result.data)
	check(result.data)
end)

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

print(`Tests complete. {Results.passed} passed, {Results.failed} failed`)
