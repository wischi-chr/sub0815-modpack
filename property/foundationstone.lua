local foundationstone_name = "property:foundation_stone"
property.foundationstone_name = foundationstone_name
property.foundation_top_clearance = 2

-- should be detected automatically
local biome_tops = {
	["default:dirt"] = true,
	["default:sand"] = true,
	["default:stone"] = true,
	["default:gravel"] = true,
	["default:cobble"] = true,
	["default:snowblock"] = true,
	["default:mossycobble"] = true,
	["default:desert_sand"] = true,
	["default:desert_stone"] = true,
	["default:dirt_with_grass"] = true
}

local function clear_foundationstone_space(pos)
	for i = 1,property.foundation_top_clearance do
		local p = {x = pos.x, y = pos.y + i, z = pos.z}
		local n = minetest.get_node(p)
		if n.name ~= "air" or n.name ~= "ignore" then
			minetest.remove_node(p)
		end
	end
end

local function can_build_foundationstone(pos,node)
	if not pos then return false end
	if not node then return false end
	
	-- Verify if node can be placed
	if not biome_tops[node.name] then return false end
	
	-- Verify tow block height clearance
	for i = 1,property.foundation_top_clearance do
		local p = {x = pos.x, y = pos.y + i, z = pos.z}
		if minetest.get_node(p).name ~= "air" then
			return false, "Foundation Stone can't be placed. Provide "..property.foundation_top_clearance.." blocks clearance above"
		end
	end
	
	return true
end

local function place2(itemstack, placer, pointed_thing)
	--minetest.show_formspec(
	--minetest.chat_send_all("foundation use")
	if not pointed_thing.under then return end
	property.free_foundation_place(pointed_thing.under,placer:get_player_name())
end

local function dig_foundation_stone(pos, oldnode, digger)
	return false
end

local function place_foundation_stone(itemstack, placer, pointed_thing)
	local pos = pointed_thing.under
		
	-- test if pos is protected
	if minetest.is_protected(pos, placer:get_player_name()) then
		minetest.record_protection_violation(pos, placer:get_player_name())
		return
	end
	
	local node = minetest.get_node_or_nil(pos)
	local can_build, reason = can_build_foundationstone(pos,node)
	
	if not can_build then
		if reason then minetest.chat_send_player(placer:get_player_name(), tostring(reason)) end
		return itemstack
	end

	minetest.set_node(pos,{name = foundationstone_name})
	
	-- Call game-wide callbacks
	local take_item = true
	local _,callback
	for _, callback in ipairs(minetest.registered_on_placenodes) do
		-- Copy pos and node because callback can modify them
		local pos_copy = {x=pos.x, y=pos.y, z=pos.z}
		local newnode_copy = {name=foundationstone_name, param1=0, param2=0}
		local oldnode_copy = {name=node.name, param1=0, param2=0}
		if callback(pos_copy, newnode_copy, placer, oldnode_copy, itemstack) then
			take_item = false
		end
	end
	
	if take_item then
		itemstack:take_item()
	end
	
	return itemstack
end

minetest.register_node(foundationstone_name,{
	description = "Foundation Stone",
	drawtype = "normal",
	tiles = {
				"property_foundationstone_top.png" , "property_foundationstone_bottom.png",
				"property_foundationstone_side.png", "property_foundationstone_side.png"  , 
				"property_foundationstone_side.png", "property_foundationstone_side.png"  , 
			},
	groups = {cracky=1, stone=1},
	sounds = default.node_sound_stone_defaults(),
	on_place = place_foundation_stone,
	--on_use = place2,
	on_dig = dig_foundation_stone,
})

minetest.register_abm({
	nodenames = {foundationstone_name},
	interval = 30.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		minetest.after(0.1, clear_foundationstone_space, pos)
	end,
})

if property.mvps_path then
	mesecon.register_mvps_stopper(foundationstone_name)
	mesecon.register_mvps_stopper(nil,function(node, pushdir, stack, stackid)
		if stackid ~= 1 then return end
		local pos = vector.add(stack[#stack].pos,pushdir)
		for i = 1,property.foundation_top_clearance do
			local p = {x = pos.x, y = pos.y - i, z = pos.z}
			local n = minetest.get_node(p)
			if n.name == foundationstone_name then return true end
		end
	end)
end

minetest.register_on_node_changed(function(pos,new,old)
	--minetest.chat_send_all(minetest.pos_to_string(pos)..": "..old.name.." -> "..new.name)
	for i = 1,property.foundation_top_clearance do
		local p = {x = pos.x, y = pos.y - i, z = pos.z}
		local n = minetest.get_node(p)
		if n.name == foundationstone_name then
			minetest.after(0.1, clear_foundationstone_space, p)
		end
	end
end)

minetest.register_craft({
	output = foundationstone_name,
	recipe = {
		{"default:stone", "default:stone", "default:stone"},
		{"default:stone", "default:sign_wall", "default:stone"},
		{"default:stone", "default:stone", "default:stone"}
	}
})