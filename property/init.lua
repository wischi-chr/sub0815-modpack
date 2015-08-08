property = {}
property.mod_path = minetest.get_modpath("property")
property.mvps_path = minetest.get_modpath("mesecons_mvps")

-- load modules
dofile(property.mod_path.."/api.lua")
dofile(property.mod_path.."/protection.lua")
dofile(property.mod_path.."/foundationstone.lua")


-- demo mvps_handler
if property.mvps_path then
	mesecon.register_mvps_stopper(nil,function(node, pushdir, stack, stackid)
		if stackid ~= 1 then return end --only check once
		
		for k,v in ipairs(stack) do
			print(dump(v.pos))
		end
		
	end)
end


