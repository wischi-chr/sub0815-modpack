property.is_open_space = function(pos)
	local a = areas:getAreasAtPos(pos)
	local cnt = 0
	for _,_ in pairs(a) do
		cnt = cnt + 1
	end
	return cnt == 0
end