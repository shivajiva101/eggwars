local players = {}

minetest.register_globalstep(function(dtime)
	for _,player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		players[name] = true
		local control = player:get_player_control()
		local sprint = control.aux1 and control.up
		if sprint and players[name] then
			player:set_physics_override({speed = 1.2})
		else
			player:set_physics_override({speed = 1})
			players[name] = nil
		end
	end
end)
