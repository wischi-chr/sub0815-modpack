local foundation_stone_released = {}
local release_pos_to_name = {}
local founcation_release_time = 10

-- should be detected automatically
local biome_tops = {
	["default:dirt"] = true,
	["default:sand"] = true,
	["default:gravel"] = true,
	["default:cobble"] = true,
	["default:snowblock"] = true,
	["default:mossycobble"] = true,
	["default:desert_sand"] = true,
	["default:desert_stone"] = true,
	["default:dirt_with_grass"] = true
}

minetest.register_on_node_changed(function(pos,new,old)
	local pos_str = minetest.pos_to_string(pos)
	local name = release_pos_to_name[pos_str]
	if not name then return end
	print("force-close: "..pos_str.." by "..tostring(name).." "..new.name.." -> "..old.name)
	local old_val = foundation_stone_released[name]
	close_foundation_place(old_val.pos,name,old_val.ticket)
end)

local close_foundation_place = function(pos,name,ticket)
	local old_val = foundation_stone_released[name]
	if not old_val then return end 							-- nothing to close
	if ticket ~= old_val.ticket then return end				
	if not table.equal(old_val.pos, pos) then return end	-- no longer relevant 
	
	local pos_str = minetest.pos_to_string(pos)
	print("close: "..pos_str.." by "..tostring(name))
	
	minetest.set_node(old_val.pos, old_val.node)
	foundation_stone_released[name] = nil
	release_pos_to_name[pos_str] = nil
end


property.free_foundation_place = function(pos,name)
	local pos_str = minetest.pos_to_string(pos)
	if release_pos_to_name[pos_str] then return end			-- skip double release
	local node = minetest.get_node(pos)
	if not biome_tops[node.name] then return end			-- skip non allowed blocks
	
	
	print("release: "..pos_str.." by "..name)
	local old_val = foundation_stone_released[name]
	if old_val then
		-- restore original
		minetest.set_node(old_val.pos, old_val.node)
	end
	local ticket = math.random()
	foundation_stone_released[name] = {pos = pos, node = minetest.get_node(pos), ticket = ticket}
	release_pos_to_name[pos_str] = name
	minetest.remove_node(pos)
	minetest.after(founcation_release_time,close_foundation_place,pos,name,ticket)
end



-- can player interact in open space (without area)
property.can_global_interact = function(playername)
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



