----------------------------------------------------------------------
-- Eggwars by wilkgr                                                --
-- Licensed under the AGPL v3                                       --
-- You MUST make any changes you make open source                   --
-- even if you just run it on your server without publishing it     --
-- Supports a maximum of 8 players currently                        --
----------------------------------------------------------------------

eggwars = {}
eggwars.MP = minetest.get_modpath("eggwars")

dofile(eggwars.MP.."/register_nodes.lua")

-------------------------
-- SECION: Coordinates --
-------------------------
eggwars.waiting_area = {x=0,y=1000,z=0};
local centre = {x=0,y=100,z=0}
eggwars.islands = {
    {x=50,y=100,z=0},
    {x=-50,y=100,z=0},
    {x=0,y=100,z=50},
    {x=0,y=100,z=-50},
    {x=35,y=100,z=-35},
    {x=-35,y=100,z=35},
    {x=35,y=100,z=35},
    {x=-35,y=100,z=-35}
}

-------------------------------
-- Please don't modify these --
-------------------------------
local i = 1;
eggwars.registered_players = {};
local players_waiting = {};
local player_i = {}; -- A table with the player names and their island.
local players_alive = {};
local player_colours = {};
local match_running = false;

------------------------------------------------
-- Allowed colours for nametags, chat and HUD --
------------------------------------------------
local allowed_colours = {
  {r = 0, g = 0, b = 255},
  {r = 0, g = 255, b = 0},
  {r = 255, g = 0, b = 0},
  {r = 200, g = 0, b = 200},
  {r = 255, g = 255, b = 0},
  {r = 0, g = 255, b = 255},
  {r = 255, g = 165, b = 0},
  {r = 0, g = 0, b = 0}
}

function StartsWith (String, Start)
    return string.sub (String, 1, string.len (Start)) == Start
end

function EndsWith (String, End)
    return End == '' or string.sub (String, -string.len (End)) == End
end

-- This function will remove all dropped items from the playing area
removeDrops = function ()
  local pos  = {x=0,y=100,z=0}
  local ent  = nil
  local tnob = minetest.get_objects_inside_radius (pos, 60)
  local nnob = table.getn(tnob)

  if (nnob > 0) then
    for foo,obj in ipairs (tnob) do
      ent = obj:get_luaentity()
      if ent ~= nil and ent.name ~= nil then
        if StartsWith (ent.name, "__builtin:item") then
          obj:remove()
        end
      end
    end
  end
end

-- WIP reset function to restart game
reset = function ()
  removeDrops();
  minetest.delete_area({x=-80, y=50, z=-80}, {x=80,y=150, z=80})
  players_alive = {};
  centrespawn();
  for m=1,#players_alive do
    if(m < #islands) then
      islandspawn(m)
    end
  end
end

-- Function to spawn centre island
centrespawn = function ()
  local centre_transformed = table.copy(centre)
  centre_transformed.y = centre_transformed.y - 1
  centre_transformed.x = centre_transformed.x - 10
  centre_transformed.z = centre_transformed.z - 10
  local schempath = minetest.get_modpath("eggwars").."/schems";
  local name = "centre"
    minetest.debug("centrespawn: " .. minetest.pos_to_string(centre_transformed))
  minetest.place_schematic(centre_transformed, schempath.."/"..name..".mts")
end

-- Function to spawn the nth island
islandspawn = function (n)
  --minetest.set_node(eggwars.islands[n],{name = "eggwars:egg"})
  local schem_l = table.copy(eggwars.islands[n]);
  schem_l.y = schem_l.y - 6
  schem_l.x = schem_l.x -7
  schem_l.z = schem_l.z -7
  local schempath = minetest.get_modpath("eggwars").."/schems";
  local name = "island"
  minetest.debug("spawn island: " .. minetest.pos_to_string(schem_l))
  minetest.place_schematic(schem_l, schempath.."/"..name..".mts")
  return eggwars.islands[n] -- Return spawn point
end



minetest.register_on_dieplayer(function(player)
  --minetest.chat_send_all(minetest.pos_to_string(player_i[player:get_player_name()]))
  --minetest.chat_send_all(minetest.get_node(player_i[player:get_player_name()]).name)
  -- Check if egg exists
  if minetest.get_node(player_i[player:get_player_name()]).name ~= "eggwars:egg" then
    minetest.chat_send_all("*** "..player:get_player_name().." is " .. minetest.colorize('red','OUT')) -- if not, remove from game
    minetest.set_player_privs(player:get_player_name(),{fly=true,fast=true,noclip=true}) -- and give player fly, fast and noclip.
    player:set_nametag_attributes({color = {a = 255, r = 0, g = 0, b = 0}}) --Make nametag invisible
    player:set_properties({visual_size={x=0, y=0}}) --Make player invisible
    for j=1,#players_alive do
      if players_alive[j] == player:get_player_name() then
        table.remove(players_alive[j])
      end
    end
    if #players_alive == 1 then
      minetest.chat_send_all(minetest.colorize("green", "*** " .. players_alive[1] .. " has won!"))
      reset();
    end
  else
    minetest.chat_send_all("*** "..player:get_player_name().." paid Hades a visit but was revived by their egg.")
    --player:set_player_privs({interact=true,shout=true})
  end
end)

-- Upon respawning, move players back to their island.
minetest.register_on_respawnplayer(function(player)
  local respawn_pos = table.copy(player_i[player:get_player_name()])
  respawn_pos.y = respawn_pos.y + 2
  minetest.after(0.1,function () player:setpos(respawn_pos) end) -- Wait until they have actually respawned before moving
end)

minetest.register_chatcommand("register", {
	params = "",
	description = "Join match",
	func = function(name, param)
		if #eggwars.registered_players < 8 then
	    if match_running == false then
        local contd = true;
        for p=1,#eggwars.registered_players do
          if eggwars.registered_players[p] == name then
            contd = false;
            minetest.chat_send_player(name,"You have already registered")
          end
        end
        if contd then
          eggwars.registered_players[#eggwars.registered_players+1] = name;
        end
	      if #eggwars.registered_players == 8 then
	        begin_match();
	      else
					minetest.chat_send_all(#eggwars.registered_players .. "/8 players have registered! Use /register to join.");
				end
	    else
				minetest.chat_send_player(name,"Sorry. A match is already running. Please use /start once their match has finished.");
			end
		else
			minetest.chat_send_player(name,"Sorry. 8 players have already registered. Try registering after their game has begun.")
		end
	end,
})

begin_match = function ()
  for k=1,#eggwars.registered_players do
    local player = minetest.get_player_by_name(eggwars.registered_players[k]);
    local player_n = eggwars.registered_players[k];
    minetest.set_player_privs(player_n, {interact=true,shout=true});
    player:set_nametag_attributes({color = allowed_colours[k]})
    islandspawn(k);
    player:setpos(eggwars.islands[k])
    player_i[player_n] = eggwars.islands[k];
    players_alive[i] = player_n;
  end
	centrespawn();
	match_running = true;
  eggwars.registered_players = {}; -- Reset list of registered players
end

minetest.register_on_joinplayer(function(player)
  minetest.set_node(eggwars.waiting_area, {name = "default:dirt_with_grass"})
  player:setpos(eggwars.waiting_area)
end)

local shop_fs = [[
size[10,3]
button[0,0;10,1;upgradespeed;Upgrade speed (cost: 20 diamonds)]
button[0,1;10,1;upgradejump;Upgrade jump (cost: 20 diamonds)]
button[0,2;10,1;thug;Order execution (cost: 99 diamonds)]
]]

minetest.register_chatcommand("shop", {
	params = "",
	description = "Open shop",
	func = function(name, param)
    minetest.show_formspec(name, "eggwars:shop", shop_fs)
		return true
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "eggwars:shop" then -- Replace this with your form name
    minetest.chat_send_all("Player "..player:get_player_name().." submitted fields "..dump(fields));
    if fields.thug then
      minetest.chat_send_all("THUG")
    elseif fields.upgradespeed then
      local inv = minetest.get_inventory({type="player", name=player:get_player_name()})
      if inv:contains_item("main", "default:diamond") then
        minetest.chat_send_all("yes, diamonds")
      end
	end
end)

minetest.set_mapgen_params({mgname = "singlenode"})
minetest.debug('[LOADED] Eggwars')