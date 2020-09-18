local players = {}

minetest.register_globalstep(function(dtime)
	for _,player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		players[name] = true
		local control = player:get_player_control()
		local sprint = control.aux1 and control.up
		if sprint and players[name] then
			player:set_physics_override({speed = 1.3})
			player:set_fov(1.2, true, 0.1)
		else
			player:set_physics_override({speed = 1})
			player:set_fov(1, true, 0.1)
			players[name] = nil
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	players[name] = nil
end)
