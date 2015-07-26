
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
	if lvl then
		meta:set_string("infotext","Liquid Tank (" .. defs[def_id].description .. ": "  .. lvl .. "/" .. defs[def_id].max_lvl .. ")")
	else
		meta:set_string("infotext","Liquid Tank (empty)")
	end
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
		local def = item2def[itemstack:get_name()]
		if def then
			return process_right_click(pos, node, player, itemstack, pointed_thing, def, 0)
		end
	end,
	on_construct = function(pos)
		refresh_meta_info(pos,i,lvl)
	end
})

minetest.register_craft({
	output = "liquidtank:tank_empty",
	recipe = {
		{"default:steel_ingot","default:glass","default:steel_ingot"},
		{"default:glass","bucket:bucket_empty","default:glass"},
		{"default:steel_ingot","default:glass","default:steel_ingot"},
	}
})