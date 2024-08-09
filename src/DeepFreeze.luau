--!strict

--[[
	Deeply freezes a table (not entering metatables)

	@param object -- table to freeze
	@return frozenTable
]]
function deepFreeze<T>(object: T): T
	if typeof(object) ~= "table" then
		return object
	end

	if getmetatable(object) ~= nil then
		return object
	end

	if table.isfrozen(object) then
		return object
	end

	table.freeze(object)

	for _, value in object do
		deepFreeze(value)
	end

	return object
end

return deepFreeze
