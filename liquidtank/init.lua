
local defs = {
	{
		code = "water",
		fill = "liquidtank_fill_water.png",
		max_lvl = 32,
		description = "Water",
		item_store = "bucket:bucket_water",
		item_leftover = "bucket:bucket_empty"
	},
	{
		code = "lava",
		fill = "liquidtank_fill_lava.png",
		max_lvl = 32,
		description = "Lava",
		item_store = "bucket:bucket_lava",
		item_leftover = "bucket:bucket_empty"
	},
}

local frame_bottom_margin = 3
local frame_height = 10

local get_liquid_texture = function(percent,fill)
	local p = math.floor((frame_height*percent)+frame_bottom_margin)/16*100
	return "liquidtank_fill_empty.png^[lowpart:"..tostring(p)..":"..fill.."^liquidtank_frame.png"
end

local top = "liquidtank_top.png"
local side_empty = get_liquid_texture(0,"#0000")

local refresh_meta_info = function(pos,def_id,lvl)
	local meta = minetest.get_meta(pos)
	if lvl ~= 0 then
		meta:set_string("infotext","Liquid Tank (" .. defs[def_id].description .. ": "  .. lvl .. "/" .. defs[def_id].max_lvl .. ")")
	else
		meta:set_string("infotext","Liquid Tank (empty)")
	end
end


function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end


local force_add_item = function(player, inv, item)
	local overflow = inv:add_item("main",item)
	if overflow:get_count() then
		local pp = player:getpos()
		minetest.item_drop(overflow,player,pp)
	end
end

local take_give = function(take_item, give_item, player, itemstack)
	if itemstack:get_name() ~= take_item then return end
    itemstack:take_item()
	local isStackable = ItemStack(give_item):get_stack_max() > 1
	local inv = player:get_inventory()
	
	if itemstack:get_count() == 0 then
		if isStackable and inv:contains_item("main", give_item) and inv:room_for_item("main", give_item) then
			force_add_item(player, inv, give_item)
			return itemstack
		end
		return give_item
	else
		force_add_item(player, inv, give_item)
		return itemstack
	end
end

local function set_can_wear(itemstack, level, max_level)
	local temp
	if level == 0 then
		temp = 0
	else
		temp = 65536 - math.floor(level / max_level * 65535)
		if temp > 65535 then temp = 65535 end
		if temp < 1 then temp = 1 end
	end
	itemstack:set_wear(temp)
end

local function set_can_level(itemstack,charge,cap)
	itemstack:set_metadata(tostring(charge))
	set_can_wear(itemstack, charge, cap)
end

local function get_can_level(itemstack)
	if itemstack:get_metadata() == "" then
		return 0
	else
		return tonumber(itemstack:get_metadata())
	end
end


local get_fill = function(max_can_lvl,can_lvl,container_lvl,max_container_lvl)
	if can_lvl >= max_can_lvl and container_lvl >= max_container_lvl then return 0 end
	if can_lvl <= 0 and container_lvl <= 0 then return 0 end
	
	if container_lvl < max_container_lvl and can_lvl > 0 then
		return math.min(max_container_lvl-container_lvl,can_lvl)
	elseif container_lvl > 0 and can_lvl <= 0 then
		return -math.min(container_lvl,max_can_lvl)
	elseif can_lvl > 0 and container_lvl >= max_container_lvl then
		return -(max_can_lvl-can_lvl)
	end
end

local process_fill = function(fill,current_container_lvl,can_lvl,code,itemstack,pos,max_can_lvl,def_id)
	set_can_level(itemstack,can_lvl-fill,max_can_lvl)
	local nlvl = current_container_lvl+fill
	if nlvl == 0 then
		minetest.swap_node(pos, {name = "liquidtank:tank_empty"})
	else
		minetest.swap_node(pos, {name = "liquidtank:tank_"..code.."_"..nlvl})
	end
	refresh_meta_info(pos,def_id,nlvl)
end

local process_can_click = function(pos, node, player, itemstack, pointed_thing, i, lvl)
	local name = itemstack:get_name()
	local is_water = name == "technic:water_can"
	local is_lava = name == "technic:lava_can"
	
	if not is_water and not is_lava then return false end
	if not (node.name == "liquidtank:tank_empty") then
		if is_water and not string.find(node.name,"liquidtank:tank_water") then return false end
		if is_lava and not string.find(node.name,"liquidtank:tank_lava") then return false end
	end
	
	local max_can = 0
	local code = ""
	if is_water then
		max_can = 16
		code = "water"
		i = 1
	elseif is_lava then
		max_can = 8
		code = "lava"
		i = 2
	end
	local can_lvl = get_can_level(itemstack)
	
	if i == 0 then
		if can_lvl <= 0 then return false end
		process_fill(can_lvl,lvl,can_lvl,code,itemstack,pos,max_can,i)
		return true
	end
	
	local fill = get_fill(max_can,can_lvl,lvl,defs[i].max_lvl)
	process_fill(fill,lvl,can_lvl,code,itemstack,pos,max_can,i)
	return true
end

local process_right_click = function(pos, node, player, itemstack, pointed_thing, def_id, lvl)
	--check fill
	if itemstack:get_count() and itemstack:get_name() == defs[def_id].item_store and lvl < defs[def_id].max_lvl then
		minetest.swap_node(pos, {name = "liquidtank:tank_"..defs[def_id].code.."_"..(lvl+1)})
		refresh_meta_info(pos,def_id,lvl+1)
		return take_give(defs[def_id].item_store,defs[def_id].item_leftover,player,itemstack)
	elseif itemstack:get_count() and itemstack:get_name() == defs[def_id].item_leftover and lvl > 0 then
		local nlvl = lvl - 1

		if nlvl >= 1 then
			minetest.swap_node(pos, {name = "liquidtank:tank_"..defs[def_id].code.."_"..nlvl})
		else
			minetest.swap_node(pos, {name = "liquidtank:tank_empty"})
			nlvl = 0
		end
		refresh_meta_info(pos,def_id,nlvl)
		
		return take_give(defs[def_id].item_leftover,defs[def_id].item_store,player,itemstack)
	end
end


local item2def = {}


for i = 1,#defs do
	local max_lvl = defs[i].max_lvl
	item2def[defs[i].item_store] = i
	
	for lvl = 1,max_lvl do
		local side = get_liquid_texture(lvl/max_lvl,defs[i].fill)
		minetest.register_node("liquidtank:tank_"..defs[i].code.."_"..lvl,
		{
			description = "Liquid Tank (" .. defs[i].description .. ": "  .. lvl .. "/" .. max_lvl .. ")",
			tiles = {
				top, top,
				side,side,
				side,side
			},
			groups = {cracky = 2, not_in_creative_inventory = 1},
			sounds = default.node_sound_stone_defaults(),
			on_rightclick = function(pos, node, player, itemstack, pointed_thing)
				if process_can_click(pos, node, player, itemstack, pointed_thing, i, lvl) then return itemstack end
				return process_right_click(pos, node, player, itemstack, pointed_thing, i, lvl)
			end,
			on_construct = function(pos)
				refresh_meta_info(pos,i,lvl)
			end
		})
	end
end

minetest.register_node("liquidtank:tank_empty",
{
	description = "Liquid Tank (empty)",
	tiles = {
		top, top,
		side_empty,side_empty,
		side_empty,side_empty
	},
	groups = {cracky = 2},
	sounds = default.node_sound_stone_defaults(),
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		if process_can_click(pos, node, player, itemstack, pointed_thing,0,0) then return itemstack end
		local def = item2def[itemstack:get_name()]
		if def then
			return process_right_click(pos, node, player, itemstack, pointed_thing, def, 0)
		end
	end,
	on_construct = function(pos)
		refresh_meta_info(pos,0,0)
	end
})


local glass_item = "default:glass"
if minetest.get_modpath("xpanes") then glass_item = "xpanes:pane" end

minetest.register_craft({
	output = "liquidtank:tank_empty",
	recipe = {
		{"default:steel_ingot",glass_item,"default:steel_ingot"},
		{glass_item,"bucket:bucket_empty",glass_item},
		{"default:steel_ingot",glass_item,"default:steel_ingot"},
	}
})