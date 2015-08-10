

-- can player interact in open space (without area)
property.can_global_interact = function(playername)
	if playername == "wischi" then return true end
	return false
end


-- FIX DOUBLE IS_PROTECTION OVERWRITE


local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
	if not areas:canInteract(pos, name) then
		return true
	end
	return old_is_protected(pos, name)
end

minetest.register_on_protection_violation(function(pos, name)
	if not areas:canInteract(pos, name) then
		local owners = areas:getNodeOwners(pos)
		minetest.chat_send_player(name,
			("%s is protected by %s."):format(
				minetest.pos_to_string(pos),
				table.concat(owners, ", ")))
	end
end)


local orig_isproteced = minetest.is_protected
function minetest.is_protected(pos,name)

	-- protect foundation_stone reserved place
	for i = 1,property.foundation_top_clearance do
		local p = {x = pos.x, y = pos.y - i, z = pos.z}
		if minetest.get_node(p).name == foundationstone_name then return true end
	end
	
	-- protect open space (with little exceptions)
	if property.is_open_space(pos) and not property.can_global_interact(name) then
		if not foundation_stone_released[name] or not table.equal(pos,foundation_stone_released[name].pos) then
			return true
		end
	end
	
	return orig_isproteced(pos,name)
end



