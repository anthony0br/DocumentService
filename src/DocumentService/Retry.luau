--!strict
-- An implementation of pcall with automatic retries
-- Author: Anthony O'Brien
-- 21 July 2024

--[=[
	@class Retry
]=]

--[=[
	pcalls a function a number of times, returning the first success if any
	
	@within Retry

	@yields
	
	@param maxAttempts -- maximum attempts
	@param cooldown -- time to wait between attempts
	@param func -- function to pcall

	@return success
	@return ... -- if successful, the return values of func, otherwise an error string
]=]
local function Retry<T..., S...>(maxAttempts: number, cooldown: number, func: (T...) -> S..., ...: T...): (boolean, S...)
	local result

	for i = 1, maxAttempts do
		result = { pcall(func, ...) }
		if result[1] == true then
			break
		end
		warn(`[Retry] Attempt {i} failed: {result[2]} {debug.traceback("\nat", 2)}`)
		task.wait(cooldown)
	end

	return table.unpack(result) :: any
end

return Retry
