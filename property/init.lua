local property_path = minetest.get_modpath("property")

dofile(property_path.."/foundationstone.lua")


local mvps_p = minetest.get_modpath("mesecons_mvps")

if mvps_p then
	mesecon.register_mvps_stopper(nil,function(node, pushdir, stack, stackid)
		if stackid ~= 1 then return end --only check once
		
		for k,v in ipairs(stack) do
			print(dump(v.pos))
		end
		
	end)
end


