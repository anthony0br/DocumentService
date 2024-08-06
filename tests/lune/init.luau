--!strict
-- Tests for DocumentService

local DocumentService = require("../../src/init")
local Guard = require("./Guard")
local DataStoreService = require("./mock-datastore/init").new()

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

type TestData = {
	Document: string,
	Service: number,
}

local CheckInterface = {
	Document = Guard.String,
	Service = Guard.Number,
}

local function check(value: unknown): TestData
	assert(type(value) == "table")
	local Value: any = value

	return {
		Document = CheckInterface.Document(Value.Document),
		Service = CheckInterface.Service(Value.Service),
	}
end

local documentStore = DocumentService.DocumentStore.new(
	mockDataStore,
	Guard.Check(check),
	{ Document = "", Service = 2 },
	{}
)

Test("Opens document with no simulated errors", function()
	local document = documentStore:GetDocument("1")
	local result = document:Open()
	assert(result.success == true)
	assert(result.data)
	check(result.data)
	print(result.data)
end)

Test("Can close document retrieved by string", function()
	local document = documentStore:GetDocument("1")
	print(tostring(document))
	local result = document:Close()
	assert(result.success == true)
end)

Test("Can reopen document after closed, retrieved by string", function()
	local document = documentStore:GetDocument("1")
	local result = document:Open()
	assert(result.success == true)
	assert(result.data)
	check(result.data)
end)

Test("Opens document with simulated error", function()
	mockDataStore.errors:addSimulatedErrors(1)
	local document = documentStore:GetDocument("2")
	local result = document:Open()
	assert(result.success == true)
	assert(result.data)
	check(result.data)
	document:Close()
end)

Test("Opens document with 4 simulated errors", function()
	mockDataStore.errors:addSimulatedErrors(4)
	local document = documentStore:GetDocument("2")
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
	local document = documentStore:GetDocument("3")
	local result = document:Open()
	assert(result.success == false)
	print(result)
end)

Test("Migrate from 'no library' with a migration, and re-open migrated data", function()
	local CheckInterface2 = {
		testString = Guard.String,
		testNumber = Guard.Number,
	}

	local function check2(value: unknown)
		assert(type(value) == "table")
		local Value: any = value

		return {
			testString = CheckInterface2.testString(Value.testString),
			testNumber = CheckInterface2.testNumber(Value.testNumber),
		}
	end

	local migrations = {
		{
			backwardsCompatible = true,
			migrate = function(data)
				if not data.testString and type(data.testNumber) ~= "string" then
					data.testString = "test"
				end

				if not data.testNumber and type(data.testNumber) ~= "number" then
					data.testNumber = 2
				end

				return data
			end,
		},
	}

	local store = DocumentService.DocumentStore.new(
		mockDataStore,
		Guard.Check(check2),
		{ testString = "test", testNumber = 2 },
		migrations
	)

	mockDataStore:UpdateAsync("nolibrary", function()
		return {
			testString = "this is from a raw UpdateAsync",
			rogueData = 3,
		}
	end)

	local document = store:GetDocument("nolibrary")
	local result = document:Open()
	print(result)
	check2(result.data)

	document:Close()
	document = store:GetDocument("nolibrary")
	local result2 = document:Open()
	print(result2)
	check2(result2.data)
end)

Test("Migrate from 'no library' with no migration - should fail with CheckFailed", function()
	local CheckInterface2 = {
		testString = Guard.String,
		testNumber = Guard.Number,
	}

	local function check2(value: unknown)
		assert(type(value) == "table")
		local Value: any = value

		return {
			testString = CheckInterface2.testString(Value.testString),
			testNumber = CheckInterface2.testNumber(Value.testNumber),
		}
	end

	local migrations = {}

	local store = DocumentService.DocumentStore.new(
		mockDataStore,
		Guard.Check(check2),
		{ testString = "test", testNumber = 2 },
		migrations
	)

	mockDataStore:UpdateAsync("nolibrary2", function()
		return {
			testString = "this is from a raw UpdateAsync",
			rogueData = 3,
		}
	end)

	local document = store:GetDocument("nolibrary2")
	local result = document:Open()
	assert(result.success == false)
	assert(result.failReason == "CheckFailed")
end)

Test("Methods should fail if document not open", function()
	local document = documentStore:GetDocument("5")
	shouldFail(function()
		document:Close()
	end)
	shouldFail(function()
		document:Update(function(data: TestData)
			data.Document = "newString"
			return data
		end)
	end)
end)

Test("Session locking prevents other sessions from opening", function()
	local session1 = DocumentService.DocumentStore.new(
		mockDataStore,
		Guard.Check(check),
		{ Document = "", Service = 2 },
		{}
	)
	local session2 = DocumentService.DocumentStore.new(
		mockDataStore,
		Guard.Check(check),
		{ Document = "", Service = 2 },
		{}
	)
	do
		local document = session1:GetDocument("test")
		local result = document:Open()
		assert(result.success == true)
	end
	do
		local document = session2:GetDocument("test")
		local result = document:Open()
		assert(result.success == false)
		assert(result.failReason == "SessionLocked")
	end
end)

-- Test: update method

-- Test: read method

-- Test: peek method

-- Test: caching

-- Test: hooks

print(`Tests complete. {Results.passed} passed, {Results.failed} failed`)
