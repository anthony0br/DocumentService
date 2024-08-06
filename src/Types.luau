--!strict

--[=[
	@type PreHookEvent "Open" | "Close" | "Update" | "Read"

	Note that Update will run on any operation that saves the datastore e.g. :Save()

	@within DocumentService
]=]
export type PreHookEvent = "Open" | "Close" | "Update" | "Read"

--[=[
	@type PostHookEvent "Open" | "Close" | "Update" | "Read"

	Note that Update will run on any operation that saves the datastore e.g. :Save()

	@within DocumentService
]=]
export type PostHookEvent = "Open" | "Close" | "Update" | "Read"

--[=[
	@type FailReason "RobloxAPIFail" | "InvalidDataNotHandled" | "SessionLocked" | "MigrationFailed"
	
	@within DocumentService
]=]
export type FailReason = "RobloxAPIFail" | "SessionLocked" | "CheckFailed" | "NotBackwardsCompatible"

--[=[
	@type Result<T> ({ success: true, data: T } | { success: false, failReason: FailReason, errorMessage: string, data: nil })
	
	@within DocumentService
]=]
export type Result<T> = {
	success: true,
	data: T,
} | {
	success: false,
	failReason: FailReason,
	errorMessage: string,
	data: nil,
}

--[=[
	@type Migrations<T> { { backwardsCompatible: boolean, migrate: (data: unknown) -> unknown, } }

	Data format versions start at 0. The first migration should migrate from 0 to 1.

	If you have data existing in the key before you open a Document, this will be considered version 0 and migrations will run.

	If backwardsCompatible is false, loading this version and later versions in an older server without this migration defined will fail.

	The current version is defined by the length of this array.

	@within DocumentService

]=]
export type Migrations<T> = {
	{
		backwardsCompatible: boolean,
		migrate: (data: any) -> any,
	}
}

return {}
