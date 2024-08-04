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
export type FailReason = "RobloxAPIFail" | "InvalidDataNotHandled" | "SessionLocked" | "MigrationFailed"

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

-- Data version starts at 0
-- [1] migrates 0 to 1
--[=[
	@type Migrations<T> { [number]: (data: unknown) -> unknown }

	@within DocumentService

	This should be a sequential array starting at 1

	Data format version start at 0, and the current version is the length of this array.
	For example, [1] migrates data at format version 0 to format version 1.
]=]
export type Migrations<T> = { [number]: (data: unknown) -> unknown }

return {}
