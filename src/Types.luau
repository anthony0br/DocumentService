--!strict

export type LockedResponse = "Await" | "Steal" | "Cancel"

export type PreHookEvent = "Open" | "Close" | "Update" | "Read"

export type PostHookEvent = "Open" | "Close" | "Update" | "Read"

export type FailReason = "RobloxAPIFail" | "InvalidDataNotHandled" | "KeyFormatCorrupted" | "SessionLocked"

export type Result<T> = {
	success: true,
	data: T,
} | {
	success: false,
	failReason: FailReason,
	errorMessage: string,
	data: nil,
}

export type InvalidDataHandler<T> = (invalidData: unknown) -> T

return {}
