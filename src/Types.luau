--!strict

local Signal = require("./Signal")

-- Simple documents do not hold sessions or state.
-- Example usage: a group or "clan" of players.

-- type of a static api for getting simpledocument objcts
export type GetSimpleDocument<T> = ({
	key: string,
	dataStore: DataStoreInterface,
	migrationList: MigrationList<T>,
}) -> SimpleDocument<T>

export type SimpleDocument<T> = {
	-- Private
	_key: string,
	_data_store: DataStoreInterface,
	_migrations: MigrationList<T>,
	-- Public
	read readAsync: () -> SimpleResult<T?>,
	-- updateAsync will always migrate before passing data
	read updateAsync: (transform: (T?) -> T) -> SimpleResult<T>,
	read updatedSignal: Signal.Signal<SimpleResult<T>>
}

-- We'll use slightly different language to the typical session locking theory
-- to improve clarity across the most important states.
-- Live means owned by this session.
-- In Inactive, the document may be unlocked or locked by another session. This
-- is the initial state of a Document.
-- Every unique Document object has its own session, with a globally
-- unique session_id.
export type DocState = "Live" | "Releasing"

-- update will be wrapped in a noYield to prevent possible rollbacks.
-- data passed into update will always be a deep copy of what is stored in _data
-- thus allowing us to edit it like it's mutable if we choose / type allow
-- the new 'read' type makes gradual to full immutable edits possible so library
-- enforcement would be redundant and tedious.

-- Increasingly in favour of keeping session locking state local. Update it
-- instantly, then call a save. That way any saves that occur during the yield
-- won't overwrite the lock.

export type Document<T> = {
	-- Private
	read _key: string,
	read _data_store: DataStoreInterface,
	read _session_id: string,
	-- instead of both is_locked and an expiry, why not just set session_expiry to 0?
	_session_expiry: number,
	read _migrations: MigrationList<T>,
	read _default: T,
	_state: DocState,
	_data: T,
	-- Public
	read getState: () -> DocState,
	read savedSignal: () -> WriteResult<T>,
	read releasedSignal: () -> WriteResult<T>,
	read read: () -> T,
	read update: ((T) -> T) -> (),
	read saveAsync: () -> WriteResult<nil>, -- if releasing, just wait for the release
	-- and return the release result. we could probably also deduce if releasing by
	-- if the local expiry time is set to 0.
	read releaseAsync: () -> WriteResult<nil>,
	read releaseToMemoryAsync: () -> WriteResult<nil> -- For fast teleportation.
	-- Don't force the user to use DataStore as a backup, but they can easily manually
	-- implement DataStore as a backup.
}

-- the use of a signal for each async method allows us to treat them like promises,
-- but without the heavyweight and poor type compatibility of luau promise packages

export type DocumentStore<T> = {
	read _key: string,
	read _dataStore: DataStoreInterface,
	read _migrationList: MigrationList<T>,
	read _openingKeys: { string },
	-- this proposal would remove the weak table, but also remove the need for
	-- dynamic state checks. the idea of an unclaimed document, claimed document
	-- closing document all having the same type is not great.
	-- the alternative is the library user will be forced to collect player
	-- documents in a table. that table will be typed, and thus, they will need
	-- to check if the value exists to refine the type from Document? to Document.
	-- Using a weak table and the old IsOpen() makes it impossible to statically check
	-- that you've actually checked the document has been claimed first!
	read claimAsync: (key: string, stealAfterSeconds: number?) -> ClaimResult<Document<T>>,
	read claimFromMemoryAsync: (key: string) -> Result<Document<T>, "BackwardsCompatibilityError" | "RobloxAPIError" | "NotInMemoryStore">
}

export type Ok<T> = {
	ok: true,
	data: T,
}
export type Fail<Reason> = {
	ok: false,
	reason: Reason,
}
export type Result<T, Reason> = Ok<T> | Fail<Reason>
export type RobloxAPIError = "RobloxAPIError"
export type SessionNotOwned = "SessionNotOwned"
export type Locked = "Locked" -- Session not owned and locked are different!
export type CheckError = "CheckError"
export type BackwardsCompatibilityError = "BackwardsCompatibilityError"
export type CorruptionError = "CorruptionError"
export type NotInMemoryStore = "NotInMemoryStore"

-- Each migration returns the transformed data in the new schema, as well as
-- a backwards compatibility boolean. If the second value is true, then the migration
-- is treated as backwards compatible. Note this means backwards compatibility
-- can depend on a user's data.
export type MigrationList<T> = {
	legacy: {(data: any) -> (any, boolean)}?,
	latest: (data: {}) -> (T, boolean)
}

export type SimpleResult<T> = Result<T, RobloxAPIError | BackwardsCompatibilityError | CorruptionError>
export type ClaimResult<T> = Result<T, RobloxAPIError | BackwardsCompatibilityError | Locked>
export type WriteResult<T> = Result<T, RobloxAPIError | SessionNotOwned | CorruptionError>
export type ReadResult<T> = Result<T, RobloxAPIError | CorruptionError | BackwardsCompatibilityError>

export type DataStoreInterface = {
	UpdateAsync: (
		DataStoreInterface,
		key: string,
		(any, DataStoreKeyInfo) -> (any, { number }?, any?)
	) -> (any, DataStoreKeyInfo),
	GetAsync: (DataStoreInterface, key: string, options: DataStoreGetOptions) -> (any, DataStoreKeyInfo),
	RemoveAsync: (DataStoreInterface, key: string) -> (any, DataStoreKeyInfo),
}

export type HookEvent = "Open" | "Close" | "Update" | "Read"

return nil
