local foundationstone_name = "property:foundation_stone"
local foundation_top_clearance = 2

local orig_isproteced = minetest.is_protected
function minetest.is_protected(pos,name)
	-- test for foundation
	for i = 1,foundation_top_clearance do
		local p = {x = pos.x, y = pos.y - i, z = pos.z}
		if minetest.get_node(p).name == foundationstone_name then
			minetest.chat_send_player(name,"This area is protected by a Foundation Stone")
			return true
		end
	end
	return orig_isproteced(pos,name)
end


local function can_build_foundationstone(pos,node)
	if not pos then return false end
	if not node then return false end
	
	-- Verify if node can be placed
	if node.name ~= "air" and not minetest.registered_nodes[node.name].buildable_to then return itemstack end
	
	-- Verify tow block height clearance
	for i = 1,foundation_top_clearance do
		local p = {x = pos.x, y = pos.y + i, z = pos.z}
		if minetest.get_node(p).name ~= "air" then
			return false, "Foundation Stone can't be placed. Provide "..foundation_top_clearance.." blocks clearance above"
		end
	end
	
	return true
end


local function place_foundation_stone(itemstack, placer, pointed_thing)
	local pos = pointed_thing.above
	local node = minetest.get_node_or_nil(pos)
	local can_build, reason = can_build_foundationstone(pos,node)
	
	if not can_build then
		if reason then minetest.chat_send_player(placer:get_player_name(), tostring(reason)) end
		return itemstack
	end

	minetest.set_node(pos,{name = foundationstone_name})
	
	-- Call game-wide callbacks
	local takeitem = true
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
	
	if takeitem then
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
})
