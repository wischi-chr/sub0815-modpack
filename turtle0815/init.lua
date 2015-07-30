
local turtle = {
	physical = true,
	--collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
	visual = "cube",
	textures = {	
					"default_wood.png","default_wood.png",
					"default_wood.png","default_wood.png",
					"default_wood.png","default_wood.png"
				}
}

local spawn_turtle = function(pos)
	local p = {x=math.round(pos.x),y=math.round(pos.y),z=math.round(pos.z)}
	minetest.add_entity(p,"turtle0815:turtle")
end

minetest.register_entity("turtle0815:turtle", turtle)

minetest.register_chatcommand("turtle", {
	params = "",
	description = "",
	func = function(name,param)
		local player = minetest.get_player_by_name(name)
		local p = player:getpos()
		spawn_turtle(p)
	end
})