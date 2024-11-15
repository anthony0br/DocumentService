--!strict
-- Tests for DocumentService

local DocumentService = require("../../src/init")
local Guard = require("./Guard")
local MockDataStoreService = require("./mock-datastore/init")

local Results = {
	passed = 0,
	failed = 0,
	failedStack = {} :: { string },
	total = 0,
}

local function shouldFail(func: (...any) -> ())
	local success, err = pcall(func :: any)
	if success then
		error(debug.traceback("Should fail", 2))
	else
		print(`shouldFail passed with {err}`)
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
		table.insert(Results.failedStack, name)
	end
end

function tableEquals(table1, table2): boolean
	for i, v in table1 do
		if type(v) == "table" and type(table2[i]) == "table" then
			return tableEquals(table2[i], v)
		end

		if table2[i] ~= v then
			return false
		end
	end

	for i, v in table2 do
		if type(v) == "table" and type(table1[i]) == "table" then
			return tableEquals(table1[i], v)
		end

		if table1[i] ~= v then
			return false
		end
	end

	return true
end

type TestData = {
	Document: string,
	Service: number,
}

local TestDataInterface = {
	Document = Guard.String,
	Service = Guard.Number,
}

local function testDataCheck(value: unknown): TestData
	assert(type(value) == "table")
	local Value: any = value

	return {
		Document = TestDataInterface.Document(Value.Document),
		Service = TestDataInterface.Service(Value.Service),
	}
end

--[=[
	Creates a unique DocumentStore on a unique DataStore in a standard format for testing
]=]
local function createTestDocumentStore()
	local datastore = MockDataStoreService.new():GetDataStore("1")

	return DocumentService.DocumentStore.new({
		dataStore = datastore,
		check = Guard.Check(testDataCheck),
		default = {
			Document = "Document",
			Service = 3,
		},
		migrations = {},
		lockSessions = true,
	}),
		datastore
end

local function createTestDocumentStoreNotLocked()
	local datastore = MockDataStoreService.new():GetDataStore("1")

	return DocumentService.DocumentStore.new({
		dataStore = datastore,
		check = Guard.Check(testDataCheck),
		default = {
			Document = "Document",
			Service = 3,
		},
		migrations = {},
		lockSessions = false,
	}),
		datastore
end

-- Verify tableEquals works!
assert(tableEquals({ test1 = { "test" }, test2 = 3 }, { test1 = { "test" }, test2 = 3 }))
assert(not tableEquals({ test1 = { "test" }, test2 = 3 }, { test1 = { "test" }, test2 = 4 }))
assert(not tableEquals({ test1 = { "test" } }, { test1 = { "test1" } }))
assert(not tableEquals({ test1 = { "test" } }, { test1 = { "test", "test2" } }))

Test("Opens document with no simulated errors and valid is valid", function()
	local document = createTestDocumentStore():GetDocument("1")
	local result = document:Open()
	assert(result.success == true)
	assert(result.data)
	testDataCheck(result.data)
end)

Test("Can close document", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local result = document:Open()
	assert(result.success == true)
	local result2 = document:Close()
	assert(result2.success == true)
end)

Test("Can reopen document after closed with session locking", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local result = document:Open()
	assert(result.success == true)
	local result2 = document:Close()
	assert(result2.success == true)

	local result3 = document:Open()
	if not result3.success then
		error(result3.reason)
	end
	assert(result3.data)
	testDataCheck(result3.data)
end)

Test("isDocumentStore returns the correct boolean", function()
	local documentStore = createTestDocumentStore()
	assert(documentStore.isDocumentStore(documentStore))
	assert(not documentStore.isDocumentStore(MockDataStoreService.new():GetDataStore("1")))
end)

Test("isDocument returns the correct boolean", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	assert(document.isDocument(document))
	assert(not document.isDocument(documentStore))
end)

Test("Can retrieve the same document by string", function()
	local documentStore = createTestDocumentStore()
	local document1 = documentStore:GetDocument("1")
	local document1_2 = documentStore:GetDocument("1")
	assert(document1 == document1_2, "Documents not equal")
end)

Test("Can retrieve the same document if reference exists even if closed", function()
	local documentStore = createTestDocumentStore()
	local document1 = documentStore:GetDocument("1")
	document1:Open()
	document1:Close()
	local document1_2 = documentStore:GetDocument("1")
	assert(document1 == document1_2, "Documents not equal")
end)

Test("GetDocument returns a new document after an old document is closed", function()
	local documentStore = createTestDocumentStore()
	do
		local document = documentStore:GetDocument("1")
		local result = document:Open()
		assert(result.success)
		testDataCheck(result.data)
		document:Close()
		assert(result.success)
	end
	do
		local document = documentStore:GetDocument("1")

		local result = document:Open()
		assert(result.success)
		testDataCheck(result.data)
		document:Close()
		assert(result.success)
	end
end)

Test("Opens document with simulated error", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	mockDataStore.errors:addSimulatedErrors(1)
	local document = documentStore:GetDocument("2")
	local result = document:Open()
	assert(result.success == true)
	assert(result.data)
	testDataCheck(result.data)
	document:Close()
end)

Test("Opens document with 4 simulated errors", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	mockDataStore.errors:addSimulatedErrors(4)
	local document = documentStore:GetDocument("2")
	local result = document:Open()
	assert(result.success == true)
	assert(result.data)
	testDataCheck(result.data)
	document:Close()
end)

-- Now that all operations only use a single datastore API request, we only need
-- to test up to 5 simulated errors
Test("Fails to open document with 5 simulated errors", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	mockDataStore.errors:addSimulatedErrors(5)
	local document = documentStore:GetDocument("3")
	local result = document:Open()
	assert(result.success == false)
end)

Test("Open fails with CheckError if data corrupted", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	document:Open()
	document:Close()

	mockDataStore:UpdateAsync("1", function(value)
		value.data = {
			Document = "Document",
			Service = "NotANumber",
		}
		return value
	end)

	local result = document:Open()
	assert(not result.success, "Open didn't fail")
	assert(result.reason == "CheckError")
end)

Test("Update fails if not open", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	shouldFail(function()
		document:Update(function(data: TestData)
			data.Document = "newString"
			return data
		end)
	end)
end)

Test("Update fails with invalid transform", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")

	document:Open()

	shouldFail(function()
		document:Update(function(data)
			return {} :: any
		end)
	end)
end)

Test("Update fails with unsavable data", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")

	document:Open()

	shouldFail(function()
		document:Update(function(data: TestData)
			return { Document = "test", Service = 3, 5 }
		end)
	end)
end)

Test("GetCache fails if not open", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	shouldFail(function()
		document:GetCache()
	end)
end)

Test("SetCache fails if not open", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	shouldFail(function()
		document:SetCache({
			Document = "test",
			Service = 2,
		})
	end)
end)

Test("Save fails if not open", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	shouldFail(function()
		document:Save()
	end)
end)

Test("GetCache fails if not session locked", function()
	local documentStore = createTestDocumentStoreNotLocked()
	local document = documentStore:GetDocument("1")
	shouldFail(function()
		document:SetCache({
			Document = "test",
			Service = 2,
		})
	end)
end)

Test("SetCache fails if not session locked", function()
	local documentStore = createTestDocumentStoreNotLocked()
	local document = documentStore:GetDocument("1")
	shouldFail(function()
		document:GetCache()
	end)
end)

Test("Save fails if not session locked", function()
	local documentStore = createTestDocumentStoreNotLocked()
	local document = documentStore:GetDocument("1")
	shouldFail(function()
		document:Save()
	end)
end)

Test("IsOpen returns correctly", function()
	local documentStore = createTestDocumentStoreNotLocked()
	local document = documentStore:GetDocument("1")
	assert(document:IsOpen() == false)
	document:Open()
	assert(document:IsOpen() == true)
end)

Test("Session locking affects IsOpenAvailable correctly", function()
	local mockDataStore = MockDataStoreService.new():GetDataStore("1")

	local session1 = DocumentService.DocumentStore.new({
		dataStore = mockDataStore,
		check = Guard.Check(testDataCheck),
		default = {
			Document = "Document",
			Service = 3,
		},
		migrations = {},
		lockSessions = true,
	})
	local session2 = DocumentService.DocumentStore.new({
		dataStore = mockDataStore,
		check = Guard.Check(testDataCheck),
		default = {
			Document = "Document",
			Service = 3,
		},
		migrations = {},
		lockSessions = true,
	})
	do
		local document = session1:GetDocument("sessionLockTest1")
		local openAvailable = document:IsOpenAvailable()
		local result = document:Open()
		assert(result.success == true)
		assert(openAvailable.success == true)
		assert(openAvailable.data == true)
	end
	do
		local document = session2:GetDocument("sessionLockTest1")
		local result = document:IsOpenAvailable()
		assert(result.success == true)
		assert(result.data == false)
	end
end)

Test("Data mutations with :Update persist with no migrations", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("6")
	local result = document:Open()
	if not result.success then
		error(result.reason)
	end

	document:Update(function(data: TestData)
		data = table.clone(data)
		data.Service = 10000
		data.Document = "hi!"

		return data
	end)

	document:Close()
	local result2 = document:Open()
	if not result2.success then
		error(result2.reason)
	end

	assert(result2.data.Service == 10000)
	assert(result2.data.Document == "hi!")

	document:Update(function(data: TestData)
		data = table.clone(data)
		data.Service = data.Service + 10000
		data.Document = data.Document .. "... hi!"

		return data
	end)

	document:Close()
	local result3 = document:Open()
	if not result3.success then
		error(result3.reason)
	end
	assert(result3.data.Service == 20000)
	assert(result3.data.Document == "hi!... hi!")
end)

Test("Update succeeds with less than 4 API fails", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")

	local result = document:Open()

	if not result.success then
		error(result.reason)
	end

	mockDataStore.errors:addSimulatedErrors(4)

	local updateResult = document:Update(function(data: TestData)
		data = table.clone(data)
		data.Service = -100
		data.Document = "hi!"

		return data
	end)
	assert(updateResult.success)
	assert(updateResult.data.Service == -100)
end)

Test("Update fails with RobloxAPIFail for 5 or more API fails", function()
	local documentStore, mockDataStore = createTestDocumentStore()

	local document = documentStore:GetDocument("1")

	local result = document:Open()
	if not result.success then
		error(result.reason)
	end

	mockDataStore.errors:addSimulatedErrors(5)

	local updateResult = document:Update(function(data: TestData)
		data = table.clone(data)
		data.Service = 10000
		data.Document = "hi!"

		return data
	end)
	assert(not updateResult.success)
	assert(updateResult.reason == "RobloxAPIError")
end)

Test("Migrate from an invalid data with no migration should fail with CheckFailed", function()
	local mockDataStore = MockDataStoreService.new():GetDataStore("1")
	local store = DocumentService.DocumentStore.new({
		dataStore = mockDataStore,
		check = Guard.Check(testDataCheck),
		default = {
			Document = "Document",
			Service = 3,
		},
		migrations = {},
		lockSessions = true,
	})

	mockDataStore:UpdateAsync("nolibrary2", function()
		return {
			testString = "this is from a raw UpdateAsync",
			rogueData = 3,
		}
	end)

	local document = store:GetDocument("nolibrary2")
	local result = document:Open()
	assert(result.success == false)
	assert(result.reason == "CheckError")
end)

Test("Close fails if not open", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	shouldFail(function()
		document:Close()
	end)
end)

Test("When migrating from from no library with a migration, the migration runs exactly once", function()
	local mockDataStore = MockDataStoreService.new():GetDataStore("1")

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

	local migrationRunCount = 0

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

				migrationRunCount += 1

				return data
			end,
		},
	}

	local store = DocumentService.DocumentStore.new({
		dataStore = mockDataStore,
		check = Guard.Check(check2),
		default = {
			testString = "string",
			testNumber = 0,
		},
		migrations = migrations,
		lockSessions = true,
	})

	mockDataStore:UpdateAsync("1", function()
		return {
			testString = "this is from a raw UpdateAsync",
			rogueData = "ROGUE!!!",
		}
	end)

	local document = store:GetDocument("1")
	local result = document:Open()
	assert(result.success)
	check2(result.data)
	assert((result.data :: any).rogueData)

	document:Close()
	document = store:GetDocument("1")
	local result2 = document:Open()
	assert(result2.success)
	check2(result2.data)

	assert(migrationRunCount == 1, "Migration ran more than once or not at all")
end)

Test("Migrating from version 0 runs all migrations exactly once", function()
	local mockDataStore = MockDataStoreService.new():GetDataStore("1")

	local migrationRunCount = 0

	do
		local CheckInterface = {
			testString = Guard.String,
			testNumber = Guard.Number,
		}

		local function check(value: unknown)
			assert(type(value) == "table")
			local Value: any = value

			return {
				testString = CheckInterface.testString(Value.testString),
				testNumber = CheckInterface.testNumber(Value.testNumber),
			}
		end

		local store = DocumentService.DocumentStore.new({
			dataStore = mockDataStore,
			check = Guard.Check(check),
			default = {
				testString = "string",
				testNumber = 0,
			},
			migrations = {},
			lockSessions = true,
		})

		local document = store:GetDocument("1")
		local result = document:Open()
		assert(result.success)
		check(result.data)
		document:Close()
	end

	-- Imagine now we update the game and add a migration

	do
		local CheckInterface = {
			testString = Guard.String,
			testNumber = Guard.Number,
			newField = Guard.String,
		}

		local function check(value: unknown)
			assert(type(value) == "table")
			local Value: any = value

			return {
				testString = CheckInterface.testString(Value.testString),
				testNumber = CheckInterface.testNumber(Value.testNumber),
				newField = CheckInterface.newField(Value.newField),
			}
		end

		local store = DocumentService.DocumentStore.new({
			dataStore = mockDataStore,
			check = Guard.Check(check),
			default = {
				testString = "bad string",
				testNumber = 10000,
				newField = "new field default",
			},
			migrations = {
				{
					backwardsCompatible = true,
					migrate = function(data)
						data.newField = "new field migrated"
						migrationRunCount += 1

						return data
					end,
				},
			},
			lockSessions = true,
		})

		local document = store:GetDocument("1")
		document:Open()
		document:Close()
		document = store:GetDocument("1")
		local result = document:Open()
		assert(result.success)
		check(result.data)
		assert(result.data.newField == "new field migrated")
		assert(result.data.testString == "string")
		assert(result.data.testNumber == 0)
		document:Close()
	end

	assert(migrationRunCount == 1, "Migration ran " .. migrationRunCount .. " times, it should run once")
end)

Test("Using default data never runs migrations", function()
	local mockDataStore = MockDataStoreService.new():GetDataStore("1")

	local CheckInterface = {
		testString = Guard.String,
		testNumber = Guard.Number,
	}

	local function check(value: unknown)
		assert(type(value) == "table")
		local Value: any = value

		return {
			testString = CheckInterface.testString(Value.testString),
			testNumber = CheckInterface.testNumber(Value.testNumber),
		}
	end

	local store = DocumentService.DocumentStore.new({
		dataStore = mockDataStore,
		check = Guard.Check(check),
		default = {
			testString = "string",
			testNumber = 0,
		},
		-- We assume an earlier version exis
		migrations = {
			{
				backwardsCompatible = true,
				migrate = function(data)
					data.testNumber = -1
					error("First migration ran")

					return data
				end,
			},
		},
		lockSessions = true,
	})

	-- Opening from the first time should use default
	do
		local document = store:GetDocument("1")
		local result = document:Open()
		assert(result.success)
		check(result.data)
		assert(result.data.testNumber == 0)
		document:Close()
	end

	-- Re-open the document to make sure the version is set/checked correctly
	do
		local document = store:GetDocument("1")
		local result = document:Open()
		assert(result.success)
		check(result.data)
		assert(result.data.testNumber == 0)
		document:Close()
	end
end)

Test("Migrating from a non-zero version does not run old migrations", function()
	local mockDataStore = MockDataStoreService.new():GetDataStore("1")

	local migrationRunCount = 0

	do
		local CheckInterface = {
			testString = Guard.String,
			testNumber = Guard.Number,
		}

		local function check(value: unknown)
			assert(type(value) == "table")
			local Value: any = value

			return {
				testString = CheckInterface.testString(Value.testString),
				testNumber = CheckInterface.testNumber(Value.testNumber),
			}
		end

		local store = DocumentService.DocumentStore.new({
			dataStore = mockDataStore,
			check = Guard.Check(check),
			default = {
				testString = "string",
				testNumber = 0,
			},
			migrations = {
				{
					backwardsCompatible = true,
					migrate = function(data)
						data.testNumber = -1
						error("First migration ran")

						return data
					end,
				},
			},
			lockSessions = true,
		})

		local document = store:GetDocument("1")
		-- Opening from the first time should use default
		local result = document:Open()
		assert(result.success)
		check(result.data)
		assert(result.data.testNumber == 0)
		document:Close()
	end

	-- Imagine now we update the game and add a migration

	do
		local CheckInterface = {
			testString = Guard.String,
			testNumber = Guard.Number,
			newField = Guard.String,
		}

		local function check(value: unknown)
			assert(type(value) == "table")
			local Value: any = value

			return {
				testString = CheckInterface.testString(Value.testString),
				testNumber = CheckInterface.testNumber(Value.testNumber),
				newField = CheckInterface.newField(Value.newField),
			}
		end

		local store = DocumentService.DocumentStore.new({
			dataStore = mockDataStore,
			check = Guard.Check(check),
			default = {
				testString = "bad string",
				testNumber = 10000,
				newField = "new field default",
			},
			migrations = {
				{
					backwardsCompatible = true,
					migrate = function(data)
						data.testNumber = -1
						error("First migration ran")

						return data
					end,
				},
				{
					backwardsCompatible = true,
					migrate = function(data)
						data.newField = "new field migrated"
						migrationRunCount += 1

						return data
					end,
				},
			},
			lockSessions = true,
		})

		local document = store:GetDocument("1")
		document:Open()
		document:Close()
		document = store:GetDocument("1")
		local result = document:Open()
		assert(result.success)
		check(result.data)
		assert(result.data.newField == "new field migrated")
		assert(result.data.testString == "string")
		assert(result.data.testNumber == 0)
		document:Close()
	end

	assert(migrationRunCount == 1, "Migration ran " .. migrationRunCount .. " times, it should run once")
end)

Test("Backwards incompatible schemas fail with BackwardsCompatibilityError", function()
	local mockDataStore = MockDataStoreService.new():GetDataStore("1")

	-- We join a new server
	do
		local CheckInterface = {
			testString = Guard.String,
			testNumber = Guard.Number,
			newField = Guard.String,
		}

		local function check(value: unknown)
			assert(type(value) == "table")
			local Value: any = value

			return {
				testString = CheckInterface.testString(Value.testString),
				testNumber = CheckInterface.testNumber(Value.testNumber),
				newField = CheckInterface.newField(Value.newField),
			}
		end

		local store = DocumentService.DocumentStore.new({
			dataStore = mockDataStore,
			check = Guard.Check(check),
			default = {
				testString = "data from first server",
				testNumber = 10000,
				newField = "new field default",
			},
			migrations = {
				{
					backwardsCompatible = false,
					migrate = function(data)
						data.newField = "new field migrated"

						return data
					end,
				},
			},
			lockSessions = true,
		})

		local document = store:GetDocument("1")
		local result = document:Open()
		assert(result.success)
		check(result.data)
		document:Close()
	end

	-- We join an old server
	do
		local CheckInterface = {
			testString = Guard.String,
			testNumber = Guard.Number,
		}

		local function check(value: unknown)
			assert(type(value) == "table")
			local Value: any = value

			return {
				testString = CheckInterface.testString(Value.testString),
				testNumber = CheckInterface.testNumber(Value.testNumber),
			}
		end

		local store = DocumentService.DocumentStore.new({
			dataStore = mockDataStore,
			check = Guard.Check(check),
			default = {
				testString = "string",
				testNumber = 0,
			},
			migrations = {},
			lockSessions = true,
		})

		local document = store:GetDocument("1")
		local result = document:Open()
		assert(result.success == false)
		assert(result.reason == "BackwardsCompatibilityError")
	end
end)

Test("Backwards compatible schemas do not fail to open and preserve additional fields", function()
	local mockDataStore = MockDataStoreService.new():GetDataStore("1")

	-- We join a new server
	do
		local CheckInterface = {
			testString = Guard.String,
			testNumber = Guard.Number,
			newField = Guard.String,
		}

		local function check(value: unknown)
			assert(type(value) == "table")
			local Value: any = value

			return {
				testString = CheckInterface.testString(Value.testString),
				testNumber = CheckInterface.testNumber(Value.testNumber),
				newField = CheckInterface.newField(Value.newField),
			}
		end

		local store = DocumentService.DocumentStore.new({
			dataStore = mockDataStore,
			check = Guard.Check(check),
			default = {
				testString = "data from first server",
				testNumber = 10000,
				newField = "new field default",
			},
			migrations = {
				{
					backwardsCompatible = true,
					migrate = function(data)
						data.newField = "new field migrated"

						return data
					end,
				},
			},
			lockSessions = true,
		})

		local document = store:GetDocument("1")
		local result = document:Open()
		assert(result.success)
		check(result.data)
		document:Close()
	end

	-- We join an old server
	do
		local CheckInterface = {
			testString = Guard.String,
			testNumber = Guard.Number,
		}

		local function check(value: unknown)
			assert(type(value) == "table")
			local Value: any = value

			return {
				testString = CheckInterface.testString(Value.testString),
				testNumber = CheckInterface.testNumber(Value.testNumber),
			}
		end

		local store = DocumentService.DocumentStore.new({
			dataStore = mockDataStore,
			check = Guard.Check(check),
			default = {
				testString = "string",
				testNumber = 0,
			},
			migrations = {},
			lockSessions = true,
		})

		local document = store:GetDocument("1")
		local result = document:Open()
		assert(result.success == true)
		check(result.data)
		assert((result.data :: any).newField == "new field default")
		document:Close()
	end
end)

Test("Migrations do not re-run after going from latest -> outdated -> latest session", function()
	local mockDataStore = MockDataStoreService.new():GetDataStore("1")

	-- We join a new server
	do
		local CheckInterface = {
			testString = Guard.String,
			testNumber = Guard.Number,
			newField = Guard.String,
		}

		local function check(value: unknown)
			assert(type(value) == "table")
			local Value: any = value

			return {
				testString = CheckInterface.testString(Value.testString),
				testNumber = CheckInterface.testNumber(Value.testNumber),
				newField = CheckInterface.newField(Value.newField),
			}
		end

		local store = DocumentService.DocumentStore.new({
			dataStore = mockDataStore,
			check = Guard.Check(check),
			default = {
				testString = "data from first server",
				testNumber = 10000,
				newField = "new field default",
			},
			migrations = {
				{
					backwardsCompatible = true,
					migrate = function(data)
						data.newField = "new field migrated"

						return data
					end,
				},
			},
			lockSessions = true,
		})

		local document = store:GetDocument("1")
		local result = document:Open()
		assert(result.success)
		check(result.data)
		document:Close()
	end

	-- We join an old server
	do
		local CheckInterface = {
			testString = Guard.String,
			testNumber = Guard.Number,
		}

		local function check(value: unknown)
			assert(type(value) == "table")
			local Value: any = value

			return {
				testString = CheckInterface.testString(Value.testString),
				testNumber = CheckInterface.testNumber(Value.testNumber),
			}
		end

		local store = DocumentService.DocumentStore.new({
			dataStore = mockDataStore,
			check = Guard.Check(check),
			default = {
				testString = "string",
				testNumber = 0,
			},
			migrations = {},
			lockSessions = true,
		})

		local document = store:GetDocument("1")
		local result = document:Open()
		assert(result.success)
		check(result.data)
		document:Close()
	end

	-- We now join a new server
	do
		local CheckInterface = {
			testString = Guard.String,
			testNumber = Guard.Number,
			newField = Guard.String,
		}

		local function check(value: unknown)
			assert(type(value) == "table")
			local Value: any = value

			return {
				testString = CheckInterface.testString(Value.testString),
				testNumber = CheckInterface.testNumber(Value.testNumber),
				newField = CheckInterface.newField(Value.newField),
			}
		end

		local store = DocumentService.DocumentStore.new({
			dataStore = mockDataStore,
			check = Guard.Check(check),
			default = {
				testString = "bad string",
				testNumber = 10000,
				newField = "new field default",
			},
			migrations = {
				{
					backwardsCompatible = true,
					migrate = function(data)
						data.newField = "new field migrated"
						error("This migration shouldn't run")

						return data
					end,
				},
			},
			lockSessions = true,
		})

		local document = store:GetDocument("1")
		local result1 = document:Open()
		assert(result1.success, if not result1.success then result1.reason else "")
		document:Close()
		document = store:GetDocument("1")
		local result = document:Open()
		assert(result.success)
		check(result.data)
		document:Close()
	end
end)

Test("DocumentStore:CloseAllDocuments yields until all documents are closed", function()
	local mockDataStore = MockDataStoreService.new():GetDataStore("1")

	-- We join a new server
	local CheckInterface = {
		testString = Guard.String,
		testNumber = Guard.Number,
	}

	local function check(value: unknown)
		assert(type(value) == "table")
		local Value: any = value

		return {
			testString = CheckInterface.testString(Value.testString),
			testNumber = CheckInterface.testNumber(Value.testNumber),
		}
	end

	local store = DocumentService.DocumentStore.new({
		dataStore = mockDataStore,
		check = Guard.Check(check),
		default = {
			testString = "data from first server",
			testNumber = 10000,
		},
		migrations = {
			{
				backwardsCompatible = true,
				migrate = function(data)
					data.newField = "new field migrated"

					return data
				end,
			},
		},
		lockSessions = true,
	})

	do
		local document = store:GetDocument("1")
		local result = document:Open()
		assert(result.success)
	end
	do
		local document = store:GetDocument("2")
		local result = document:Open()
		assert(result.success)
	end
	do
		local document = store:GetDocument("3")
		local result = document:Open()
	end
	do
		local document = store:GetDocument("4")
		local result = document:Open()
		document:Close()
	end
	do
		local document = store:GetDocument("5")
	end

	-- We should be able to call it sequentially as many times as we like
	task.spawn(function()
		mockDataStore.yield:startYield()
		task.wait()
		mockDataStore.yield:stopYield()
	end)
	assert(store:GetDocument("1"):IsOpen() == true)
	assert(store:GetDocument("2"):IsOpen() == true)
	assert(store:GetDocument("3"):IsOpen() == true)
	assert(store:GetDocument("4"):IsOpen() == false)
	assert(store:GetDocument("5"):IsOpen() == false)
	store:CloseAllDocuments()
	assert(store:GetDocument("1"):IsOpen() == false)
	assert(store:GetDocument("2"):IsOpen() == false)
	assert(store:GetDocument("3"):IsOpen() == false)
	assert(store:GetDocument("4"):IsOpen() == false)
	assert(store:GetDocument("5"):IsOpen() == false)
end)

Test("Erase method sets the key to nil", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local result = document:Open()
	assert(result.success)
	assert(mockDataStore:GetAsync("1") ~= nil)
	document:Close()
	document = documentStore:GetDocument("1")
	document:Erase()
	assert(mockDataStore:GetAsync("1") == nil)
end)

Test("Read fails with SchemaError if key not initialised", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local result = document:Read()
	assert(not result.success, "Read didn't fail")
	assert(result.reason == "SchemaError")
end)

Test("Read correctly reads data set properly", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local openResult = document:Open()
	assert(openResult.success)
	local result = document:Read()
	assert(result.success)
	assert(tableEquals(openResult.data, result.data))
end)

Test("Read fails with SchemaError if key corrupted", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local openResult = document:Open()
	assert(openResult.success)
	mockDataStore:write("1", {})
	local result = document:Read()
	assert(not result.success, "Read didn't fail")
	assert(result.reason == "SchemaError")
end)

Test("Read fails with CheckError if data corrupted", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local openResult = document:Open()
	assert(openResult.success)
	mockDataStore:UpdateAsync("1", function(value)
		value.data = {
			Document = "Document",
			Service = "NotANumber",
		}
		return value
	end)
	local result = document:Read()
	assert(not result.success, "Read didn't fail")
	assert(result.reason == "CheckError")
end)

Test("Read runs migrations correctly", function()
	local mockDataStore = MockDataStoreService.new():GetDataStore("1")

	local CheckInterface1 = {
		testString = Guard.String,
	}

	local function check1(value: unknown)
		assert(type(value) == "table")
		local Value: any = value

		return {
			testString = CheckInterface1.testString(Value.testString),
		}
	end

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

	local migrationRunCount = 0

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

				migrationRunCount += 1

				return data
			end,
		},
	}

	local storeVersion1 = DocumentService.DocumentStore.new({
		dataStore = mockDataStore,
		check = Guard.Check(check2),
		default = {
			testString = "string",
			testNumber = 0,
		},
		migrations = migrations,
		lockSessions = true,
	})

	local storeVersion0 = DocumentService.DocumentStore.new({
		dataStore = mockDataStore,
		check = Guard.Check(check1),
		default = {
			testString = "string",
		},
		migrations = {},
		lockSessions = true,
	})

	do
		local document = storeVersion0:GetDocument("1")
		document:Open()
		document:Close()
	end
	do
		local document = storeVersion1:GetDocument("1")
		local result = document:Read()
		assert(result.success)
		check2(result.data)
		local result2 = document:Read()
		assert(result2.success)
		check2(result2.data)
		local result3 = document:Open()
		assert(result3.success)
		check2(result3.data)
		local result4 = document:Read()
		assert(result4.success)
		check2(result4.data)
		document:Close()
	end

	assert(migrationRunCount == 3, "Migration should run 3 times")
end)

Test("Update fails with SchemaError if key corrupted", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local openResult = document:Open()
	assert(openResult.success)
	mockDataStore:write("1", {})
	local result = document:Update(function(value)
		return value
	end)
	assert(not result.success, "Update didn't fail")
	assert(result.reason == "SchemaError")
end)

Test("Update fails with a luau error if it corrupts the data", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local openResult = document:Open()
	assert(openResult.success)
	shouldFail(function()
		document:Update(function()
			return {
				data = "This isn't right!",
			} :: any
		end)
	end)
	shouldFail(function()
		document:Update(function()
			return nil :: any
		end)
	end)
end)

Test(":Steal will correctly steal a sesion", function()
	-- Session 1
	do
		local documentStore = createTestDocumentStore()
		local document = documentStore:GetDocument("1")
		local openResult = document:Open()
		assert(openResult.success)
	end

	-- Session 2
	do
		local documentStore = createTestDocumentStore()
		local document = documentStore:GetDocument("1")
		document:Steal()
		local openResult = document:Open()
		assert(openResult.success)
	end
end)

Test("If the lock is stolen, Update, Save, Close return SessionLockedError", function()
	local mockDataStore = MockDataStoreService.new():GetDataStore("1")

	local session1 = DocumentService.DocumentStore.new({
		dataStore = mockDataStore,
		check = Guard.Check(testDataCheck),
		default = {
			Document = "Document",
			Service = 3,
		},
		migrations = {},
		lockSessions = true,
	})
	local session2 = DocumentService.DocumentStore.new({
		dataStore = mockDataStore,
		check = Guard.Check(testDataCheck),
		default = {
			Document = "Document",
			Service = 3,
		},
		migrations = {},
		lockSessions = true,
	})

	local document = session1:GetDocument("1")
	local openResult = document:Open()
	assert(openResult.success)

	-- Session 2 steals the lock
	do
		local document2 = session2:GetDocument("1")
		document2:Steal()
		local result = document2:Open()
		assert(result.success)
	end

	-- Test Update
	do
		local result = document:Update(function(value)
			return value
		end)

		assert(not result.success)
		assert(result.reason == "SessionLockedError")
	end

	-- Test Save
	do
		local result = document:Save()

		assert(not result.success)
		assert(result.reason == "SessionLockedError")
	end

	-- Test Close
	do
		local result = document:Close()

		assert(not result.success)
		assert(result.reason == "SessionLockedError")
	end
end)

Test("Opening a locked document returns SessionLockedError", function()
	local mockDataStore = MockDataStoreService.new():GetDataStore("1")

	local session1 = DocumentService.DocumentStore.new({
		dataStore = mockDataStore,
		check = Guard.Check(testDataCheck),
		default = {
			Document = "Document",
			Service = 3,
		},
		migrations = {},
		lockSessions = true,
	})

	local session2 = DocumentService.DocumentStore.new({
		dataStore = mockDataStore,
		check = Guard.Check(testDataCheck),
		default = {
			Document = "Document",
			Service = 3,
		},
		migrations = {},
		lockSessions = true,
	})

	do
		local document = session1:GetDocument("1")
		local openResult = document:Open()
		assert(openResult.success)
	end

	-- Session 2
	do
		local document = session2:GetDocument("1")
		local result = document:Open()
		assert(not result.success)
		assert(result.reason == "SessionLockedError")
	end
end)

Test("Opening a locked document will retry if session locked", function()
	local mockDataStore = MockDataStoreService.new():GetDataStore("1")

	local session1 = DocumentService.DocumentStore.new({
		dataStore = mockDataStore,
		check = Guard.Check(testDataCheck),
		default = {
			Document = "Document",
			Service = 3,
		},
		migrations = {},
		lockSessions = true,
	})
	local session2 = DocumentService.DocumentStore.new({
		dataStore = mockDataStore,
		check = Guard.Check(testDataCheck),
		default = {
			Document = "Document",
			Service = 3,
		},
		migrations = {},
		lockSessions = true,
	})

	local document1 = session1:GetDocument("1")
	local openResult = document1:Open()
	assert(openResult.success)

	-- Session 2
	local thread = coroutine.running()
	local result
	task.spawn(function()
		local document2 = session2:GetDocument("1")
		-- This should initially fail, and then retry and succeed
		result = document2:Open()

		task.defer(thread)
	end)
	task.spawn(function()
		task.wait()
		document1:Close()
	end)

	coroutine.yield()

	-- This will only pass if Open is tried again
	assert(result.success)
end)

Test("Cache is set correctly opening a document", function()
	local documentStore = createTestDocumentStore()

	local document = documentStore:GetDocument("1")
	local openResult = document:Open()
	assert(openResult.success)

	assert(tableEquals(document:GetCache(), openResult.data))
end)

Test("Cache is set correctly updating a document", function()
	local documentStore = createTestDocumentStore()

	local document = documentStore:GetDocument("1")
	local openResult = document:Open()
	assert(openResult.success)

	local result = document:Update(function(data: TestData)
		local newData = table.clone(data)
		newData.Document = "Updated data!"

		return newData
	end)

	assert(result.success)

	assert(tableEquals(document:GetCache(), result.data))
end)

Test("Error if cache is mutated", function()
	local documentStore = createTestDocumentStore()

	local document = documentStore:GetDocument("1")
	local openResult = document:Open()
	assert(openResult.success)

	do
		local success
		document:Update(function(data: TestData)
			success = pcall(function()
				data.Document = "Updated data!"
			end)

			return data
		end)
		assert(not success)
	end

	shouldFail(function()
		local newCache = {
			Document = "Set Cache",
			Service = 4,
		}
		document:SetCache(newCache)
		newCache.Document = "Mutated cache"
	end)

	shouldFail(function()
		local cache = document:GetCache()
		cache.Document = "Mutated Cache"
	end)
end)

Test(":SetCache, :GetCache work correctly in the same session", function()
	local documentStore = createTestDocumentStore()

	local document = documentStore:GetDocument("1")
	local openResult = document:Open()
	assert(openResult.success)

	local newCache = {
		Document = "Set Cache",
		Service = 4,
	}
	document:SetCache(newCache)

	assert(tableEquals(document:GetCache(), newCache))
end)

Test("Cache updates persist between sessions (are saved on close)", function()
	local documentStore = createTestDocumentStore()

	local newCache = {
		Document = "Set Cache",
		Service = 4,
	}

	do
		local document = documentStore:GetDocument("1")
		local openResult = document:Open()
		assert(openResult.success)

		document:SetCache(newCache)
		assert(document:Close().success)
	end
	do
		local document = documentStore:GetDocument("1")
		local openResult = document:Open()
		assert(openResult.success)
		assert(tableEquals(openResult.data, newCache))
		assert(document:Close().success)
	end
end)

Test("Open Hooks run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local hook1Ran = false
	local hook2Ran = false
	local failRan = false

	document:HookBefore("Open", function()
		assert(not document:IsOpen(), "Hook ran too late")
		hook1Ran = true
	end)

	document:HookAfter("Open", function()
		assert(document:IsOpen(), "Hook ran early")
		assert(hook1Ran)
		hook2Ran = true
	end)

	document:HookFail("Open", function()
		failRan = true
	end)

	local result = document:Open()
	assert(hook2Ran, "Hook didn't run")
	assert(result.success, "Open failed")
	document:Close()

	assert(not failRan)
	mockDataStore.errors:addSimulatedErrors(5)
	local openResult = document:Open()
	assert(not openResult.success, "Open succeeded")
	assert(failRan)
end)

Test("Open Hooks cleanup run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local hook1CleanupRan = false
	local hook2CleanupRan = false
	local failRan = false

	local cleanup1 = document:HookBefore("Open", function()
		assert(not document:IsOpen(), "Hook ran too late")
	end)
	hook1CleanupRan = pcall(cleanup1)

	local cleanup2 = document:HookAfter("Open", function()
		assert(document:IsOpen(), "Hook ran early")
		assert(hook1CleanupRan)
	end)
	hook2CleanupRan = pcall(cleanup2)

	local cleanupFail
	cleanupFail = document:HookFail("Open", function()
		failRan = pcall(cleanupFail)
	end)

	local result = document:Open()
	assert(hook2CleanupRan, "Hook didn't run")
	assert(result.success, "Open failed")
	document:Close()

	assert(not failRan)
	mockDataStore.errors:addSimulatedErrors(5)
	local openResult = document:Open()
	assert(not openResult.success, "Open succeeded")
	assert(failRan)
end)

Test("Open Hooks run even if cleaned up while executing hooks", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local firstBeforeRan = false
	local secondBeforeRan = false
	local firstAfterRan = false
	local secondAfterRan = false
	local firstFailRan = false
	local secondFailRan = false

	local cleanupBefore1
	cleanupBefore1 = document:HookBefore("Open", function()
		cleanupBefore1()
		firstBeforeRan = true
	end)
	local cleanupBefore2
	cleanupBefore2 = document:HookBefore("Open", function()
		cleanupBefore2()
		secondBeforeRan = true
	end)

	local cleanupAfter1
	cleanupAfter1 = document:HookAfter("Open", function()
		cleanupAfter1()
		firstAfterRan = true
	end)
	local cleanupAfter2
	cleanupAfter2 = document:HookAfter("Open", function()
		cleanupAfter2()
		secondAfterRan = true
	end)

	local cleanupFail1
	cleanupFail1 = document:HookFail("Open", function()
		cleanupFail1()
		firstFailRan = true
	end)
	local cleanupFail2
	cleanupFail2 = document:HookFail("Open", function()
		cleanupFail2()
		secondFailRan = true
	end)

	local result = document:Open()
	assert(result.success, "Open failed")
	assert(firstBeforeRan)
	assert(secondBeforeRan)
	assert(firstAfterRan)
	assert(secondAfterRan)
	local resultClose = document:Close()
	assert(resultClose.success, "Close failed")
	assert(not firstFailRan)
	assert(not secondFailRan)

	mockDataStore.errors:addSimulatedErrors(5)
	result = document:Open()
	assert(not result.success, "Open succeeded")
	assert(firstFailRan)
	assert(secondFailRan)
end)

Test("Close Hooks run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local hook1Ran = false
	local hook2Ran = false
	local failRan = false

	document:HookBefore("Close", function()
		assert(document:IsOpen(), "Document closed too early")
		hook1Ran = true
	end)
	document:HookAfter("Close", function()
		assert(not document:IsOpen(), "Document not closed")
		assert(hook1Ran)
		hook2Ran = true
	end)
	document:HookFail("Close", function()
		failRan = true
	end)

	local result = document:Open()
	local resultClose = document:Close()
	assert(hook2Ran, "Hook didn't run")
	assert(result.success, "Open failed")
	assert(resultClose.success, "Close failed")

	document:Open()
	assert(not failRan)
	mockDataStore.errors:addSimulatedErrors(5)
	local closeResult = document:Close()
	assert(not closeResult.success, "Close succeeded")
	assert(failRan)

	document:Close()
end)

Test("Close Hooks cleanup run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local hook1CleanupRan = false
	local hook2CleanupRan = false
	local failRan = false

	local cleanup1 = document:HookBefore("Close", function()
		assert(not document:IsOpen(), "Hook ran too late")
	end)
	hook1CleanupRan = pcall(cleanup1)

	local cleanup2 = document:HookAfter("Close", function()
		assert(document:IsOpen(), "Hook ran early")
		assert(hook1CleanupRan)
	end)
	hook2CleanupRan = pcall(cleanup2)

	local cleanupFail
	cleanupFail = document:HookFail("Close", function()
		failRan = pcall(cleanupFail)
	end)

	local result = document:Open()
	local resultClose = document:Close()
	assert(hook2CleanupRan, "Hook didn't run")
	assert(result.success, "Open failed")
	assert(resultClose.success, "Close failed")

	document:Open()
	assert(not failRan)
	mockDataStore.errors:addSimulatedErrors(5)
	local closeResult = document:Close()
	assert(not closeResult.success, "Close succeeded")
	assert(failRan)

	document:Close()
end)

Test("Close Hooks run even if cleaned up while executing hooks", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local firstBeforeRan = false
	local secondBeforeRan = false
	local firstAfterRan = false
	local secondAfterRan = false
	local firstFailRan = false
	local secondFailRan = false

	local cleanupBefore1
	cleanupBefore1 = document:HookBefore("Close", function()
		cleanupBefore1()
		firstBeforeRan = true
	end)
	local cleanupBefore2
	cleanupBefore2 = document:HookBefore("Close", function()
		cleanupBefore2()
		secondBeforeRan = true
	end)

	local cleanupAfter1
	cleanupAfter1 = document:HookAfter("Close", function()
		cleanupAfter1()
		firstAfterRan = true
	end)
	local cleanupAfter2
	cleanupAfter2 = document:HookAfter("Close", function()
		cleanupAfter2()
		secondAfterRan = true
	end)

	local cleanupFail1
	cleanupFail1 = document:HookFail("Close", function()
		cleanupFail1()
		firstFailRan = true
	end)
	local cleanupFail2
	cleanupFail2 = document:HookFail("Close", function()
		cleanupFail2()
		secondFailRan = true
	end)

	local result = document:Open()
	local resultClose = document:Close()
	assert(result.success, "Open failed")
	assert(resultClose.success, "Close failed")
	assert(firstBeforeRan)
	assert(secondBeforeRan)
	assert(firstAfterRan)
	assert(secondAfterRan)
	assert(not firstFailRan)
	assert(not secondFailRan)

	document:Open()
	mockDataStore.errors:addSimulatedErrors(5)
	resultClose = document:Close()
	assert(not resultClose.success, "Close succeeded")
	assert(firstFailRan)
	assert(secondFailRan)
end)

Test("Before Update Hooks run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStoreNotLocked()
	local document = documentStore:GetDocument("1")
	local hookRan = false

	document:HookBefore("Update", function()
		assert(mockDataStore:GetAsync("1").data.Document ~= "Updated")
		hookRan = true
	end)

	local result = document:Open()

	assert(result.success, "Open failed")

	local updateResult = document:Update(function(data: TestData)
		local newData = table.clone(data)
		newData.Document = "Updated"

		return newData
	end)

	assert(hookRan, "Hook didn't run")
	assert(updateResult.success)

	document:Close()
end)

Test("Before Update Hooks cleanup run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStoreNotLocked()
	local document = documentStore:GetDocument("1")
	local hookRan = false

	local cleanup = document:HookBefore("Update", function()
		assert(mockDataStore:GetAsync("1").data.Document ~= "Updated")
	end)
	hookRan = pcall(cleanup)

	local result = document:Open()

	assert(result.success, "Open failed")

	local updateResult = document:Update(function(data: TestData)
		local newData = table.clone(data)
		newData.Document = "Updated"

		return newData
	end)

	assert(hookRan, "Hook didn't run")
	assert(updateResult.success)

	document:Close()
end)

Test("After Update Hooks run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStoreNotLocked()
	local document = documentStore:GetDocument("1")
	local hookRan = false

	document:HookAfter("Update", function()
		assert(mockDataStore:GetAsync("1").data.Document == "Updated")
		hookRan = true
	end)

	local result = document:Open()
	assert(result.success, "Open failed")

	document:Update(function(data: TestData)
		local newData = table.clone(data)
		newData.Document = "Updated"

		return newData
	end)

	assert(hookRan, "Hook didn't run")

	document:Close()
end)

Test("After Update Hooks cleanup run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStoreNotLocked()
	local document = documentStore:GetDocument("1")
	local hookRan = false

	local cleanup = document:HookAfter("Update", function()
		assert(mockDataStore:GetAsync("1").data.Document == "Updated")
		hookRan = true
	end)
	hookRan = pcall(cleanup)

	local result = document:Open()
	assert(result.success, "Open failed")

	document:Update(function(data: TestData)
		local newData = table.clone(data)
		newData.Document = "Updated"

		return newData
	end)

	assert(hookRan, "Hook didn't run")

	document:Close()
end)

Test("Fail Update Hooks run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local failRan = false

	document:HookFail("Update", function()
		failRan = true
	end)

	assert(not failRan)
	document:Open()
	mockDataStore.errors:addSimulatedErrors(5)

	local result = document:Update(function(data: TestData)
		local newData = table.clone(data)
		newData.Document = "Updated"

		return newData
	end)

	assert(not result.success, "Update succeeded")
	assert(failRan)

	document:Close()
end)

Test("Fail Update Hooks cleanup run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local failRan = false

	local cleanup
	cleanup = document:HookFail("Update", function()
		failRan = pcall(cleanup)
	end)

	assert(not failRan)
	document:Open()
	mockDataStore.errors:addSimulatedErrors(5)

	local result = document:Update(function(data: TestData)
		local newData = table.clone(data)
		newData.Document = "Updated"

		return newData
	end)

	assert(not result.success, "Update succeeded")
	assert(failRan)

	document:Close()
end)

Test("Update Hooks run even if cleaned up while executing hooks", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local firstBeforeRan = false
	local secondBeforeRan = false
	local firstAfterRan = false
	local secondAfterRan = false
	local firstFailRan = false
	local secondFailRan = false

	local cleanupBefore1
	cleanupBefore1 = document:HookBefore("Update", function()
		cleanupBefore1()
		firstBeforeRan = true
	end)
	local cleanupBefore2
	cleanupBefore2 = document:HookBefore("Update", function()
		cleanupBefore2()
		secondBeforeRan = true
	end)

	local cleanupAfter1
	cleanupAfter1 = document:HookAfter("Update", function()
		cleanupAfter1()
		firstAfterRan = true
	end)
	local cleanupAfter2
	cleanupAfter2 = document:HookAfter("Update", function()
		cleanupAfter2()
		secondAfterRan = true
	end)

	local cleanupFail1
	cleanupFail1 = document:HookFail("Update", function()
		cleanupFail1()
		firstFailRan = true
	end)
	local cleanupFail2
	cleanupFail2 = document:HookFail("Update", function()
		cleanupFail2()
		secondFailRan = true
	end)

	local result = document:Open()

	assert(result.success, "Open failed")

	local updateResult = document:Update(function(data: TestData)
		-- We don't really need to test for changes made here if the previous tests pass
		return table.clone(data)
	end)

	assert(firstBeforeRan)
	assert(secondBeforeRan)
	assert(firstAfterRan)
	assert(secondAfterRan)
	assert(not firstFailRan)
	assert(not secondFailRan)
	assert(updateResult.success)

	mockDataStore.errors:addSimulatedErrors(5)

	document:Update(function(data: TestData)
		return table.clone(data)
	end)

	assert(firstFailRan)
	assert(secondFailRan)

	document:Close()
end)

Test("Read Hooks cleanup run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local firstCleanupRan = false
	local secondCleanupRan = false
	local failRan = false

	local cleanupFirst = document:HookBefore("Read", function() end)
	firstCleanupRan = pcall(cleanupFirst)

	local cleanupSecond = document:HookAfter("Read", function()
		assert(firstCleanupRan, "Before hook didn't run")
	end)
	secondCleanupRan = pcall(cleanupSecond)

	local cleanup
	cleanup = document:HookFail("Read", function()
		failRan = pcall(cleanup)
	end)

	-- Open the document first so we don't get SchemaError
	local result = document:Open()
	local resultRead = document:Read()
	assert(resultRead.success, "Read failed")
	assert(secondCleanupRan, "After hook didn't run")
	assert(result.success, "Open failed")

	assert(not failRan)
	mockDataStore.errors:addSimulatedErrors(5)
	resultRead = document:Read()
	assert(not resultRead.success, "Read succeeded")
	assert(failRan)

	document:Close()
end)

Test("Read Hooks run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local firstRan = false
	local secondRan = false
	local failRan = false

	document:HookBefore("Read", function()
		firstRan = true
	end)

	document:HookAfter("Read", function()
		assert(firstRan, "Before hook didn't run")
		secondRan = true
	end)

	document:HookFail("Read", function()
		failRan = true
	end)

	-- Open the document first so we don't get SchemaError
	local result = document:Open()
	local resultRead = document:Read()
	assert(resultRead.success, "Read failed")
	assert(secondRan, "After hook didn't run")
	assert(result.success, "Open failed")

	assert(not failRan)
	mockDataStore.errors:addSimulatedErrors(5)
	resultRead = document:Read()
	assert(not resultRead.success, "Read succeeded")
	assert(failRan)

	document:Close()
end)

-- Sleitnick Signal is well-established and tested, so we do not need
-- to test Once functionality etc
Test("Read signals fire correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local secondRan = false
	local failRan = false

	document:GetReadSignal():Connect(function(result)
		if result.success then
			secondRan = true
		else
			failRan = true
		end
	end)

	-- Open the document first so we don't get SchemaError
	local result = document:Open()
	local resultRead = document:Read()
	assert(resultRead.success, "Read failed")
	assert(secondRan, "Success signal didn't run")
	assert(result.success, "Open failed")

	assert(not failRan)
	mockDataStore.errors:addSimulatedErrors(5)
	resultRead = document:Read()
	assert(not resultRead.success, "Read succeeded")
	assert(failRan)

	document:Close()
end)

-- This test relies on the fact that `:Save` calls Update
-- to avoid very repetitive unit tests
Test("Update signals fire correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local secondRan = false
	local failRan = false

	document:GetUpdatedSignal():Connect(function(result)
		if result.success then
			secondRan = true
		else
			failRan = true
		end
	end)

	-- Open the document first so we don't get SchemaError
	local result = document:Open()
	local saveResult = document:Save()
	assert(saveResult.success, "Save failed")
	assert(secondRan, "Success signal didn't run")
	assert(result.success, "Open failed")

	assert(not failRan)
	mockDataStore.errors:addSimulatedErrors(5)
	saveResult = document:Save()
	assert(not saveResult.success, "Save succeeded")
	assert(failRan)

	document:Close()
end)

Test("Closed signals fire correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local secondRan = false
	local failRan = false

	document:GetClosedSignal():Connect(function(result)
		if result.success then
			secondRan = true
		else
			failRan = true
		end
	end)

	-- Open the document first so we don't get SchemaError
	local result = document:Open()
	local closeResult = document:Close()
	assert(closeResult.success, "Close failed")
	assert(secondRan, "Success signal didn't run")
	assert(result.success, "Open failed")

	assert(not failRan)
	document:Open()
	mockDataStore.errors:addSimulatedErrors(5)
	closeResult = document:Close()
	assert(not closeResult.success, "Close succeeded")
	assert(failRan)

	document:Close()
end)

Test("Open signals fire correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local secondRan = false
	local failRan = false

	document:GetOpenedSignal():Connect(function(result)
		if result.success then
			secondRan = true
		else
			failRan = true
		end
	end)

	local result = document:Open()
	assert(secondRan, "Hook didn't run")
	assert(result.success, "Open failed")
	document:Close()

	assert(not failRan)
	mockDataStore.errors:addSimulatedErrors(5)
	local openResult = document:Open()
	assert(not openResult.success, "Open succeeded")
	assert(failRan)
end)

Test("Read Hooks run even if cleaned up while executing hooks", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local firstBeforeRan = false
	local secondBeforeRan = false
	local firstAfterRan = false
	local secondAfterRan = false
	local firstFailRan = false
	local secondFailRan = false

	local cleanupBefore1
	cleanupBefore1 = document:HookBefore("Read", function()
		cleanupBefore1()
		firstBeforeRan = true
	end)
	local cleanupBefore2
	cleanupBefore2 = document:HookBefore("Read", function()
		cleanupBefore2()
		secondBeforeRan = true
	end)

	local cleanupAfter1
	cleanupAfter1 = document:HookAfter("Read", function()
		cleanupAfter1()
		firstAfterRan = true
	end)
	local cleanupAfter2
	cleanupAfter2 = document:HookAfter("Read", function()
		cleanupAfter2()
		secondAfterRan = true
	end)

	local cleanupFail1
	cleanupFail1 = document:HookFail("Read", function()
		cleanupFail1()
		firstFailRan = true
	end)
	local cleanupFail2
	cleanupFail2 = document:HookFail("Read", function()
		cleanupFail2()
		secondFailRan = true
	end)

	local result = document:Open()
	local resultRead = document:Read()
	assert(result.success, "Open failed")
	assert(resultRead.success, "Read failed")
	assert(firstBeforeRan)
	assert(secondBeforeRan)
	assert(firstAfterRan)
	assert(secondAfterRan)
	assert(not firstFailRan)
	assert(not secondFailRan)

	mockDataStore.errors:addSimulatedErrors(5)
	resultRead = document:Read()
	assert(not resultRead.success, "Read succeeded")
	assert(firstFailRan)
	assert(secondFailRan)
end)

Test("Open Once Hooks run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local hook1Ran = false
	local hook2Ran = false
	local failRan = false

	document:OnceBefore("Open", function()
		assert(not hook1Ran)
		assert(not document:IsOpen(), "Hook ran too late")
		hook1Ran = true
	end)

	document:OnceAfter("Open", function()
		assert(not hook2Ran)
		assert(document:IsOpen(), "Hook ran early")
		assert(hook1Ran)
		hook2Ran = true
	end)

	document:OnceFail("Open", function()
		assert(not failRan)
		failRan = true
	end)

	for _ = 1, 2 do
		local result = document:Open()
		assert(hook2Ran, "Hook didn't run")
		assert(result.success, "Open failed")
		document:Close()

		mockDataStore.errors:addSimulatedErrors(5)
		local openResult = document:Open()
		assert(not openResult.success, "Open succeeded")
		assert(failRan)
	end
end)

Test("Close Once Hooks run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local hook1Ran = false
	local hook2Ran = false
	local failRan = false

	document:OnceBefore("Close", function()
		print("Before close running!")
		assert(not hook1Ran, "Hook re-ran")
		assert(document:IsOpen(), "Document closed too early")
		hook1Ran = true
	end)

	document:OnceAfter("Close", function()
		print("After hook running")
		assert(not hook2Ran, "Hook re-ran")
		assert(not document:IsOpen(), "Document not closed")
		assert(hook1Ran, "Hook before didn't run")
		hook2Ran = true
	end)

	document:OnceFail("Close", function()
		assert(not failRan)
		failRan = true
	end)

	for _ = 1, 2 do
		local result = document:Open()
		local resultClose = document:Close()
		assert(hook2Ran, "Hook didn't run")
		assert(result.success, "Open failed")
		assert(resultClose.success, "Close failed")

		document:Open()
		mockDataStore.errors:addSimulatedErrors(5)
		local closeResult = document:Close()
		assert(not closeResult.success, "Close succeeded")
		assert(failRan)

		document:Close()
	end
end)

Test("Update Once Before Hooks run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStoreNotLocked()
	local document = documentStore:GetDocument("1")
	local hookRan = false

	document:OnceBefore("Update", function()
		assert(not hookRan)
		assert(mockDataStore:GetAsync("1").data.Document ~= "Updated")
		hookRan = true
	end)

	local result = document:Open()

	assert(result.success, "Open failed")

	for _ = 1, 2 do
		local updateResult = document:Update(function(data: TestData)
			local newData = table.clone(data)
			newData.Document = "Updated"

			return newData
		end)

		assert(hookRan, "Hook didn't run")
		assert(updateResult.success)
	end

	document:Close()
end)

Test("Update Once After Hooks run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStoreNotLocked()
	local document = documentStore:GetDocument("1")
	local hookRan = false

	document:OnceAfter("Update", function()
		assert(not hookRan)
		assert(mockDataStore:GetAsync("1").data.Document == "Updated")
		hookRan = true
	end)

	local result = document:Open()
	assert(result.success, "Open failed")

	for _ = 1, 2 do
		document:Update(function(data: TestData)
			local newData = table.clone(data)
			newData.Document = "Updated"

			return newData
		end)

		assert(hookRan, "Hook didn't run")
	end

	document:Close()
end)

Test("Fail Update Hooks run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local failRan = false

	document:OnceFail("Update", function()
		assert(not failRan)
		failRan = true
	end)

	assert(not failRan)
	document:Open()

	for _ = 1, 2 do
		mockDataStore.errors:addSimulatedErrors(5)
		local result = document:Update(function(data: TestData)
			local newData = table.clone(data)
			newData.Document = "Updated"

			return newData
		end)

		assert(not result.success, "Update succeeded")
		assert(failRan)
	end

	document:Close()
end)

Test("Read Once Hooks run correctly", function()
	local documentStore, mockDataStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local firstRan = false
	local secondRan = false
	local failRan = false

	document:OnceBefore("Read", function()
		assert(not firstRan)
		firstRan = true
	end)

	document:OnceAfter("Read", function()
		assert(not secondRan)
		assert(firstRan, "Before hook didn't run")
		secondRan = true
	end)

	document:OnceFail("Read", function()
		assert(not failRan)
		failRan = true
	end)

	-- Open the document first so we don't get SchemaError
	local result = document:Open()

	for _ = 1, 2 do
		local resultRead = document:Read()
		assert(resultRead.success, "Read failed")
		assert(secondRan, "After hook didn't run")
		assert(result.success, "Open failed")

		mockDataStore.errors:addSimulatedErrors(5)
		resultRead = document:Read()
		assert(not resultRead.success, "Read succeeded")
		assert(failRan)
	end

	document:Close()
end)

Test("Open documents are not garbage collected", function()
	local documentStore = createTestDocumentStore()
	do
		local document = documentStore:GetDocument("1")
		assert(document:Open().success)
	end
	local _ = (collectgarbage :: any)("collect")
	local _document, newlyCreated = documentStore:GetDocument("1")
	assert(not newlyCreated)
end)

Test("Documents are garbage collected if closed", function()
	local documentStore = createTestDocumentStore()
	local upvalue = 0
	do
		local document = documentStore:GetDocument("1")

		document:HookAfter("Open", function()
			document:GetCache()
			upvalue += 1
		end)

		document:Open()
		document:Close()
	end
	local _ = (collectgarbage :: any)("collect")
	local _document, newlyCreated = documentStore:GetDocument("1")
	assert(newlyCreated)
end)

Test("OpenAndUpdate fails with invalid transform", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")

	shouldFail(function()
		document:OpenAndUpdate(function(data)
			return {} :: any
		end)
	end)
end)

Test("OpenAndUpdate fails with unsavable data", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")

	shouldFail(function()
		document:OpenAndUpdate(function(data: TestData)
			return { Document = "test", Service = 3, 5 }
		end)
	end)
end)

Test("OpenAndUpdate mutates data correctly", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")

	document:OpenAndUpdate(function(data: TestData)
		data = table.clone(data)
		data.Service = 10000
		data.Document = "hi!"

		return data
	end)

	document:Close()
	local result2 = document:Open()
	if not result2.success then
		error(result2.reason)
	end

	assert(result2.data.Service == 10000)
	assert(result2.data.Document == "hi!")
end)

print(`Tests complete. {Results.passed} passed, {Results.failed} failed`)
if Results.failed > 0 then
	print("These tests failed:")
	for _, name in ipairs(Results.failedStack) do
		print(name)
	end
end
