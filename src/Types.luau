--!strict

export type LockedResponse = "Await" | "Steal" | "Cancel"

export type PreHookEvent = "Open" | "Close" | "Update" | "Read"

export type PostHookEvent = "Open" | "Close" | "Update" | "Read"

export type FailReason = "RobloxAPIFail" | "InvalidDataNotHandled" | "SessionLocked" | "MigrationFailed"

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
export type Migrations<T> = { [number]: (data: unknown) -> unknown }

return {}
