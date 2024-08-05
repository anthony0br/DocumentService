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
	@type Migrations<T> { { fromVersion: number, toVersion: number, backwardsCompatible: boolean, migrate: (data: unknown) -> unknown, } }

	Data version starts at 0

	E.g. the first element should migrate from 0 to 1.

	@within DocumentService

]=]
export type Migrations<T> = {
	{
		fromVersion: number,
		toVersion: number,
		backwardsCompatible: boolean,
		migrate: (data: unknown) -> unknown,
	}
}

return {}
