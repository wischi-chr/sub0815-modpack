
--------------------
-- math functions --
--------------------


-- source: http://lua-users.org/wiki/SimpleRound
-- The following function rounds a number to the given number of decimal places.
math.round = function(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end






---------------------
-- table functions --
---------------------


-- source: mesecons util.lua
-- creates a deep copy of the table
table.clone = function(table) 
	if type(table) ~= "table" then return table end -- no need to copy
	local newtable = {}

	for idx, item in pairs(table) do
		if type(item) == "table" then
			newtable[idx] = table.clone(item)
		else
			newtable[idx] = item
		end
	end

	return newtable
end



-- source: mesecons util.lua
-- compares two tables
table.equal = function(t1, t2)
	if type(t1) ~= type(t2) then return false end
	if type(t1) ~= "table" and type(t2) ~= "table" then return t1 == t2 end

	for i, e in pairs(t1) do
		if not table.equal(e, t2[i]) then return false end
	end

	return true
end