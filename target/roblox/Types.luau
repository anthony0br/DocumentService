--!strict

--[=[
	@type HookEvent "Open" | "Close" | "Update" | "Read"

	Update hooks will run on any operation that writes to Data Stores e.g. :Save().

	Read hooks will run on any operation that reads from Data Stores e.g. :Peek()

	@within DocumentService
]=]
export type HookEvent = "Open" | "Close" | "Update" | "Read"

--[=[
	@type Ok<T> { success: true, data: T }

	Subtype of Result. A success.
	
	@within DocumentService
]=]
export type Ok<T> = {
	success: true,
	data: T
}

--[=[
	@type Err<E> { success: false, reason: E }

	Subtype of Result. An error.
	
	@within DocumentService
]=]
export type Err<E> = {
	success: false,
	reason: E
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

	In the case of a SchemaError during opening, a new
	Document will be created, enclosing the existing value at the key.
	
	@within DocumentService
]=]
export type SchemaError = "SchemaError"

--[=[
	@type Migrations { { backwardsCompatible: boolean, migrate: (data: any) -> any, } }

	Data format versions start at 0. The first migration should migrate from 0 to 1.

	If you have data existing in the key before you open a Document, this will be considered version 0 and migrations will run.

	If backwardsCompatible is false, loading this version and later versions in an older server without this migration defined will fail.

	The current version is defined by the length of this array.

	:::warning
	If you make a not-backwards-compatible migration on not-session-locked
	Documents, you must shut down all servers, or old servers will break.
	:::

	@within DocumentService

]=]
export type Migrations = {
	{
		backwardsCompatible: boolean,
		migrate: (data: any) -> any	
}
}

--[=[
	@type Transform<T> (data: T) -> T

	Takes data and returns an updated version of it.
	Ideally this should be a pure function.
	
	@within DocumentService
]=]
export type Transform<T> = (data: T) -> T

--[=[
	@type DataStoreInterface { UpdateAsync: (DataStoreInterface, key: string, (any, DataStoreKeyInfo) -> (any, { number }?, any?)) -> (any, DataStoreKeyInfo), GetAsync: (DataStoreInterface, key: string, options: DataStoreGetOptions) -> (any, DataStoreKeyInfo), RemoveAsync: (DataStoreInterface, key: string) -> (any, DataStoreKeyInfo)}

	An interface, implemented by DataStore in Roblox, to allow dependency injection
	(e.g. MockDataStores).

	There is currently an issue where passing `DataStore` will result in a type
	error, even though `DataStore` currently implements `DataStoreInterface`.
	You can typecast to to any (:: any) as a workaround.

	@within DocumentService
]=]
export type DataStoreInterface = {
	UpdateAsync: (
		DataStoreInterface,
		key: string,
		(any, DataStoreKeyInfo) -> (any, { number }?, any?)
	) -> (any, DataStoreKeyInfo),
	GetAsync: (DataStoreInterface, key: string, options: DataStoreGetOptions) -> (any, DataStoreKeyInfo),
	RemoveAsync: (DataStoreInterface, key: string) -> (any, DataStoreKeyInfo)
}

return {}
