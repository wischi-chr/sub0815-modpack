
-- disable for now
do return end

usergroups = {}

usergroups.modpath = minetest.get_modpath("usergroups")
dofile(usergroups.modpath.."/settings.lua")

local function verify_defaults()
	if type(usergroups.data) ~= "table" then usergroups.data = {} end
	if type(usergroups.data.users) ~= "table" then usergroups.data.users = {} end
	if type(usergroups.data.groups) ~= "table" then usergroups.data.groups = {} end
	if type(usergroups.data.groups["default"]) ~= "table" then usergroups.data.groups["default"] = {} end
	if type(usergroups.data.groups["default"].privs) ~= "table" then usergroups.data.groups["default"].privs = {  } end
end

usergroups.load = function()
	local file, err = io.open(usergroups.settings.savefile, "r")
	if err then
		verify_defaults()
		return err
	end
	usergroups.data = minetest.deserialize(file:read("*a"))
	verify_defaults()
	file:close()
end

usergroups.save = function()
	local datastr = minetest.serialize(usergroups.data)
	if not datastr then
		minetest.log("error", "[usergroups] Failed to serialize users data!")
		return
	end
	local file, err = io.open(usergroups.settings.savefile, "w")
	if err then
		return err
	end
	file:write(datastr)
	file:close()
end

usergroups.load()

minetest.register_on_chat_message(function(name, message)
	print(debug.traceback())
	return true
end)

minetest.register_on_prejoinplayer(function(name, ip)
	local privs = usergroups.data.groups["default"].privs
	minetest.set_player_privs(name,privs)
	print(dump(privs))
end)

