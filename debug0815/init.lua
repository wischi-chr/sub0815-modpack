goto skip_file

local table_insert_new = function(t,item)
	for i = 1,#t do
		if t[i] == item then return end
	end
	table.insert(t,item)
end

minetest.after(0, function()
	local num = 0
	local craft_recipes = {}
	
	for name, def in pairs(minetest.registered_items) do
		--
		if def.description ~= "" and not string.find(name,"moreblocks") then
			local recipes = minetest.get_all_craft_recipes(name)
			if recipes then
				--print(name)
				for _, recipe in ipairs(recipes) do
					num = num + 1
					local hash = "Type: " .. recipe.type .. "\n" .. "Width: " .. tostring(recipe.width) .. "\n" .. dump(recipe.items)

					if craft_recipes[hash] then
						table_insert_new(craft_recipes[hash],recipe.output)
					else
						craft_recipes[hash] = {recipe.output}
					end
				end
			end
		end
	end
	
	for hash, recipe in pairs(craft_recipes) do
		if #recipe > 1 then
			print("========== CRAFTING RECIPE DUPLICATE ==============")
			print("Ingredients:")
			print(hash)
			print("Outputs:")
			print(dump(recipe))
			print("")
		end
	end
	
	print("Crafting Rec: " .. num)
end)


::skip_file::
