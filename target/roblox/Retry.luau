--!strict
-- An implementation of pcall with automatic retries
-- Author: Anthony O'Brien
-- 21 July 2024

--[[
	pcalls a function a number of times, returning the first success if any

	@yields
	
	@param maxAttempts -- maximum attempts
	@param initialWait -- waits (initialWait)^lastAttempt between attempts
	@param func -- function to pcall

	@return { success, returnValues } -- if successful, the return values of func, otherwise an error string
]]
local function Retry<T...>(
	maxAttempts: number,
	initialWait: number,
	func: (T...) -> any,
	...: T...
): { success: boolean, returnValues: { any } }
	local result: { any }

	for i = 1, maxAttempts do
		result = { pcall(func, ...) }

		if result[1] == true then
			break
		end

		warn(`[DocumentService Retry] Attempt {i} failed: {result[2]} {debug.traceback("\nat", 1)}`)

		if i < maxAttempts then
			task.wait(initialWait * (2 ^ (i - 1)))
		end
	end

	local success = result[1]
	table.remove(result, 1)

	return {
		success = success,
		returnValues = result,
	}
end

return Retry
