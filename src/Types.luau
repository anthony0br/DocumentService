--!strict

--[=[
	@type PreHookEvent "Open" | "Close" | "Update" | "Read"

	Runs before the operation.

	Update hooks will run on any operation that saves the datastore e.g. :Save().

	@within DocumentService
]=]
export type PreHookEvent = "Open" | "Close" | "Update" | "Read"

--[=[
	@type PostHookEvent "Open" | "Close" | "Update" | "Read"

	Runs after the operation.

	Update hooks will run on any operation that saves the datastore e.g. :Save().

	@within DocumentService
]=]
export type PostHookEvent = "Open" | "Close" | "Update" | "Read"

--[=[
	@type Ok<T> { success: true, data: T }

	Subtype of Result. A success.
	
	@within DocumentService
]=]
export type Ok<T> = {
	success: true,
	data: T,
}

--[=[
	@type Err<E> { success: false, reason: E }

	Subtype of Result. An error.
	
	@within DocumentService
]=]
export type Err<E> = {
	success: false,
	reason: E,
}

--[=[
	@type Result<T,E> Ok<T> | Err<E>

	The result of a yielding operation that could error. You should always write
	error handling for all types of errors that can be returned.
	
	@within DocumentService
]=]
export type Result<T, E> = Ok<T> | Err<E>

--[=[
	@type RobloxAPIError "RobloxAPIError"

	Indicates the Roblox API failed, e.g. too many requests
	
	@within DocumentService
]=]
export type RobloxAPIError = "RobloxAPIError"

--[=[
	@type SessionLockedError "SessionLockedError"

	Indicates the document was locked by some other session.
	
	@within DocumentService
]=]
export type SessionLockedError = "SessionLockedError"

--[=[
	@type CheckError "CheckError"

	Indicates the document's check function failed.
	
	@within DocumentService
]=]
export type CheckError = "CheckError"

--[=[
	@type BackwardsCompatibilityError "BackwardsCompatibleError"

	Attempted to load data that has been migrated ahead to a version that isn't
	backwards compatible with the latest version our session has.
	
	@within DocumentService
]=]
export type BackwardsCompatibilityError = "BackwardsCompatibilityError"

--[=[
	@type SchemaError "SchemaError"

	This indicates the key provided is not managed by DocumentService, or has
	been corrupted.

	This is for DataStore-requesting methods that can be called before the
	Document is opened. In the case of a SchemaError during opening, a new
	Document will be created, enclosing the existing value at the key.
	
	@within DocumentService
]=]
export type SchemaError = "SchemaError"

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
