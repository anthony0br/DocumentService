--!strict
-- Tests for DocumentService

local DocumentService = require("../../src/init")
local Guard = require("./Guard")
local DataStoreService = require("./mock-datastore/init").new()

local Results = {
	passed = 0,
	failed = 0,
	total = 0,
}

local uuid = DocumentService.SaveUtil.uuid

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
	local datastore = DataStoreService:GetDataStore(uuid())

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

local function createTestDocumentStoreNotLocked()
	local datastore = DataStoreService:GetDataStore(uuid())

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

Test("Can reopen document after closed", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	local result = document:Open()
	assert(result.success == true)
	local result2 = document:Close()
	assert(result2.success == true)

	document = documentStore:GetDocument("1")
	local result3 = document:Open()
	if not result3.success then
		error(result3.reason)
	end
	assert(result3.data)
	testDataCheck(result3.data)
end)

Test("isDocumentStore works", function()
	local documentStore = createTestDocumentStore()
	assert(documentStore.isDocumentStore(documentStore))
	assert(not documentStore.isDocumentStore(DataStoreService:GetDataStore(uuid())))
end)

Test("isDocument works", function()
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

Test("UpdateCache fails if not open", function()
	local documentStore = createTestDocumentStore()
	local document = documentStore:GetDocument("1")
	shouldFail(function()
		document:UpdateCache(function(data: TestData)
			data.Document = "newString"
			return data
		end)
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

Test("UpdateCache fails if not session locked", function()
	local documentStore = createTestDocumentStoreNotLocked()
	local document = documentStore:GetDocument("1")
	shouldFail(function()
		document:UpdateCache(function(data: TestData)
			data.Document = "newString"
			return data
		end)
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
	local mockDataStore = DataStoreService:GetDataStore(uuid())

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

Test("Session locking prevents other sessions from opening", function()
	local mockDataStore = DataStoreService:GetDataStore(uuid())

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
		local result = document:Open()
		assert(result.success == true)
	end
	do
		local document = session2:GetDocument("1")
		local result = document:Open()
		assert(result.success == false)
		assert(result.reason == "SessionLockedError")
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
	document = documentStore:GetDocument("6")
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
	document = documentStore:GetDocument("6")
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
	local mockDataStore = DataStoreService:GetDataStore(uuid())
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
	local mockDataStore = DataStoreService:GetDataStore(uuid())

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

	document:Close()
	document = store:GetDocument("1")
	local result2 = document:Open()
	assert(result2.success)
	check2(result2.data)

	assert(migrationRunCount == 1, "Migration ran more than once or not at all")
end)

Test("Migrating from version 0 runs all migrations exactly once", function()
	local mockDataStore = DataStoreService:GetDataStore(uuid())

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
	local mockDataStore = DataStoreService:GetDataStore(uuid())

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
	local mockDataStore = DataStoreService:GetDataStore(uuid())

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
	local mockDataStore = DataStoreService:GetDataStore(uuid())

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
	local mockDataStore = DataStoreService:GetDataStore(uuid())

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
	local mockDataStore = DataStoreService:GetDataStore(uuid())

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
		print(result.data)
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
		print(result.data)
		document:Close()
	end
end)

Test("DocumentStore:CloseAllDocuments yields until all documents are closed", function()
	local mockDataStore = DataStoreService:GetDataStore(uuid())

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
	assert(store:GetDocument("4"):IsOpen() == true)
	assert(store:GetDocument("5"):IsOpen() == false)
	store:CloseAllDocuments()
	assert(store:GetDocument("1"):IsOpen() == false)
	assert(store:GetDocument("2"):IsOpen() == false)
	assert(store:GetDocument("3"):IsOpen() == false)
	assert(store:GetDocument("4"):IsOpen() == false)
	assert(store:GetDocument("5"):IsOpen() == false)
end)

--Test("Erase method sets the key to nil")

-- Test: update method

-- Test: read method

-- Test: peek method

-- Test: caching

-- Test: Cache is set correctly opening a document

-- Test: hooks

print(`Tests complete. {Results.passed} passed, {Results.failed} failed`)
