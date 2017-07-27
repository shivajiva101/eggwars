eggwars.waiting_area = {x=0,y=1000,z=0};
eggwars.reserved_players = {};

minetest.register_chatcommand("reserve", {
	params = "",
	description = "Join match",
	func = function(name, param)
    if !match_running
      eggwars.reserved_players[#eggwars.reserved_players+1] = name;
      if #eggwars.reserved_players == 8 then
        begin_match();
      end
    else
		return true
	end,
})

begin_match = function ()
  for k=1,#eggwars.reserved_players do
    local player = minetest.get_player_by_name(name);
    local player_n = name;
    minetest.set_player_privs(player_n, privs)
    player:set_nametag_attributes({color = allowed_colours[k]})
  end
  eggwars.reserved_players = {}; -- Reset list of reserved players 