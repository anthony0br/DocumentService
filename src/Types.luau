--!strict

--[=[
	@type PreHookEvent "Open" | "Close" | "Update" | "Read"

	Runs before the operation, transforming parameters.

	:::info
	Update hooks will run on any operation that saves the datastore e.g. :Save()
	:::

	@within DocumentService
]=]
export type PreHookEvent = "Open" | "Close" | "Update" | "Read"

--[=[
	@type PostHookEvent "Open" | "Close" | "Update" | "Read"

	Runs after the operation, transforming the return value.

	:::info
	Update hooks will run on any operation that saves the datastore e.g. :Save()
	:::

	@within DocumentService
]=]
export type PostHookEvent = "Open" | "Close" | "Update" | "Read"

--[=[
	@type FailReason "RobloxAPIFail" | "SessionLocked" | "CheckFailed" | "NotBackwardsCompatible"

	A reason an operation failed, but didn't throw an error. These are typically reasons that may
	not be your fault and you should check for and handle them.
	
	@within DocumentService
]=]
export type FailReason = "RobloxAPIFail" | "SessionLocked" | "CheckFailed" | "NotBackwardsCompatible"

--[=[
	@type Result<T> ({ success: true, data: T } | { success: false, failReason: FailReason, errorMessage: string, data: nil })

	The result of a yielding operation.
	
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
	@type Migrations<T> { { backwardsCompatible: boolean, migrate: (data: any) -> any, } }

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

--[=[
	@type Transform<T> (data: T) -> T

	Takes data and returns an updated version of it.
	Ideally this should be a pure function.
	
	@within DocumentService
]=]
export type Transform<T> = (data: T) -> T

return {}
