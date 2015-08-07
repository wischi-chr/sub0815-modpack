local foundationstone_name = "property:foundation_stone"
local foundation_top_clearance = 2
local open_nodes = {}

-- should be detected automatically
local biome_tops = {
	"default:dirt_with_grass",
	"default:dirt",
	"default:snowblock",
	"default:sand",
	"default:gravel",
	"default:cobble",
	"default:mossycobble",
	"default:stone_with_coal",
	"default:stone_with_iron",
	"default:mese",
	"default:desert_sand",
	"default:desert_stone"
}

local function close_pos(pos,name)
	local old_val = open_nodes[name]
	if not old_val then return end 							-- nothing to close
	if not table.equal(old_val.pos, pos) then return end	-- no longer relevant 
	print("close: "..minetest.pos_to_string(pos).." by "..tostring(name))
	
	
	
	minetest.set_node(old_val.pos, old_val.node)
	open_nodes[name] = nil
end

local function release_pos(pos,name)
	print("release: "..minetest.pos_to_string(pos).." by "..name)
	local old_val = open_nodes[name]
	if old_val then
		if table.equal(pos,old_val.pos) then return end 			-- skip double release
		minetest.set_node(old_val.pos, old_val.node)
	end
	open_nodes[name] = {pos = pos, node = minetest.get_node(pos)}
	minetest.remove_node(pos)
	minetest.after(5,function()
		close_pos(pos,name)
	end)
end

local function is_open_space(pos)
	local a = areas:getAreasAtPos(pos)
	local cnt = 0
	for _,_ in pairs(a) do
		cnt = cnt + 1
	end
	return cnt == 0
end

local orig_isproteced = minetest.is_protected
function minetest.is_protected(pos,name)

	-- protect foundation_stone reserved place
	for i = 1,foundation_top_clearance do
		local p = {x = pos.x, y = pos.y - i, z = pos.z}
		if minetest.get_node(p).name == foundationstone_name then return true end
	end
	
	-- protect open space (with little exceptions)
	if is_open_space(pos) and not property.can_global_interact(name) then
		if not open_nodes[name] or not table.equal(pos,open_nodes[name].pos) then
			return true
		end
	end
	
	return orig_isproteced(pos,name)
end

local function clear_foundationstone_space(pos)
	print("clear")
	for i = 1,foundation_top_clearance do
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

local function place2(itemstack, placer, pointed_thing)
	--minetest.show_formspec(
	minetest.chat_send_all("foundation use")
	release_pos(pointed_thing.under,placer:get_player_name())
end

local function place_foundation_stone(itemstack, placer, pointed_thing)
	local pos = pointed_thing.above
	local node = minetest.get_node_or_nil(pos)
	
	if minetest.is_protected(pos, placer:get_player_name()) then
		minetest.record_protection_violation(pos, placer:get_player_name())
		return
	end
	
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
	on_use = place2,
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
		for i = 1,foundation_top_clearance do
			local p = {x = pos.x, y = pos.y - i, z = pos.z}
			local n = minetest.get_node(p)
			if n.name == foundationstone_name then return true end
		end
	end)
end

minetest.register_on_node_changed(function(pos,new,old)
	--minetest.chat_send_all(minetest.pos_to_string(pos)..": "..old.name.." -> "..new.name)
	for i = 1,foundation_top_clearance do
		local p = {x = pos.x, y = pos.y - i, z = pos.z}
		local n = minetest.get_node(p)
		if n.name == foundationstone_name then
			minetest.after(0.1, clear_foundationstone_space, p)
		end
	end
end)