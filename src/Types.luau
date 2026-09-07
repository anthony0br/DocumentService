--!strict

local Signal = require("./Signal")

-- Simple documents do not hold sessions or state.
-- Example usage: a group or "clan" of players.

export type SimpleDocumentConstructor<T> = ({
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
-- For example, the lock needs to be owned by our session for us to change the document
-- Rather than 'Open', or 'Locked', 'OwnedBySession' clarifies this.
-- In Unauthorised, the document may be unlocked or locked by another session. This
-- is the initial state of a Document.
-- Every unique Document object has its own session, with a globally
-- unique session_id.
export type DocState = "Unauthorised" | "OwnedBySession" | "Claiming" | "Releasing" | "Steal"

-- Typical usage: create a document (which creates a session) on player join
-- add to a collection once document is claimed.
export type DocumentConstructor<T> = ({
	key: string,
	dataStore: DataStoreInterface,
	migrationList: MigrationList<T>,
	default: T,
}) -> Document<T>

export type Document<T> = {
	-- Private
	read _key: string,
	read _data_store: DataStoreInterface,
	read _session_id: string,
	read _migrations: MigrationList<T>,
	read _default: T,
	_cache: T,
	_state: DocState,
	-- Public
	read claimAsync: () -> (),
	read claimedSignal: () -> Signal.Signal<ClaimResult<T>>,
	read steal: () -> (), -- transition to steal state to steal on next claim
	read read: () -> T,
	read update: (T) -> T,
	read saveAsync: () -> WriteResult<T>, -- typically used for purchases to determine return type
	read savedSignal: () -> WriteResult<T>,
	read releaseAsync: () -> WriteResult<T>,
	read releasedSignal: () -> WriteResult<T>,
}
-- the use of a signal for each async method allows us to treat them like promises,
-- but without the heavyweight and poor type compatibility of luau promise packages

-- without weak tables and GetDocument, we can remove:
-- pre-hooks.
-- IsOpen checks -- the user can track this themselves e.g. add the document to a central table
-- unit test / concerns of memory leakage

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
export type CheckError = "CheckError"
export type BackwardsCompatibilityError = "BackwardsCompatibilityError"
export type CorruptionError = "CorruptionError"

-- Each migration returns the transformed data in the new schema, as well as
-- a backwards compatibility boolean. If the second value is true, then the migration
-- is treated as backwards compatible. Note this means backwards compatibility
-- can depend on a user's data.
export type MigrationList<T> = {
	legacy: {(data: any) -> (any, boolean)}?,
	latest: (data: {}) -> (T, boolean)
}

export type SimpleResult<T> = Result<T, RobloxAPIError | BackwardsCompatibilityError | CorruptionError>
export type ClaimResult<T> = Result<T, RobloxAPIError | BackwardsCompatibilityError | SessionNotOwned>
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
