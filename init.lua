--[[
----------------------------------------------------------------------
-- Eggwars by wilkgr                                                --
-- Licensed under the AGPL v3                                       --
-- You MUST make any changes you make open source                   --
-- even if you just run it on your server without publishing it     --
----------------------------------------------------------------------
-- Modified by lennyhans                                            --
----------------------------------------------------------------------
--]]

-- Supports a maximum of 8 players currently
-- TODO: Make always day to comfortable fight

eggwars = {}
ew = {}
eggwars.MP = minetest.get_modpath("eggwars")
-- TODO: Implement API to separate concerns (MVC)

dofile(eggwars.MP.."/register_nodes.lua")
dofile(eggwars.MP.."/shop.lua")
local register_chat_handler = dofile(eggwars.MP.."/register_commands.lua")
-------------------------
-- SECION: Coordinates --
-------------------------
local base_y_layer = 1000 + 100;
eggwars.waiting_area = {x=0,y=1002,z=0};
local centre = {x=0,y=base_y_layer,z=0}
eggwars.islands = {
    {x=50,y=base_y_layer,z=0},
    {x=-50,y=base_y_layer,z=0},
    {x=0,y=base_y_layer,z=50},
    {x=0,y=base_y_layer,z=-50},
    {x=35,y=base_y_layer,z=-35},
    {x=-35,y=base_y_layer,z=35},
    {x=35,y=base_y_layer,z=35},
    {x=-35,y=base_y_layer,z=-35}
}

 ---------------------------------
-- Please don't modify these ;-;  --
 ---------------------------------
-- local i = 1;
eggwars.registered_players = {}; -- index playernames
local players_waiting = {};
local player_i = {}; -- A table with the player names and their island.
local players_alive = {}; -- Table with player names alive
local player_colours = {};
local match_running = false;
eggwars.player_properties = {};

local registry_book = {};
local ewplayer = {
	in_lobby = false,
	in_game = false,
	is_alive = false,
	is_specting = false,
	points = 0
};

 ------------------------------------------------
-- Allowed colours for nametags, chat and HUD   --
 ------------------------------------------------
local allowed_colours = {
  {r = 0, g = 0, b = 255}, -- Blue
  {r = 0, g = 255, b = 0}, -- Green
  {r = 255, g = 0, b = 0}, -- Red
  {r = 200, g = 0, b = 200}, -- Purple/pink
  {r = 255, g = 255, b = 0}, -- Yellow
  {r = 0, g = 255, b = 255}, -- Aqua
  {r = 255, g = 165, b = 0},
  {r = 0, g = 0, b = 0} -- Black
}

local default_hang_block = {name = "default:glass"};

--
--	Boundaries
local min_y_unregistered_user = eggwars.waiting_area.y -50;
local min_y_registered_waiting_user = eggwars.waiting_area.y -50;
local min_y_registered_playing_user = centre.y - 50;
local default_name_tag_color = { r = 255, g = 255, b = 255}
local respawn_time = 4
local void_damage = 5
local set_position_delay = 0.05

function StartsWith (String, Start)
  return string.sub (String, 1, string.len (Start)) == Start
end

function EndsWith (String, End)
  return End == '' or string.sub (String, -string.len (End)) == End
end

ew.debug = function(msg)
  if msg == nil then
    msg = "Test print"
  end
  minetest.debug("[EW] " .. msg)
end

-- Force load arena & waiting pos when started.
for i=1,#eggwars.islands do
  minetest.forceload_block(eggwars.islands[i], true)
end
minetest.forceload_block(eggwars.waiting_area, true)
minetest.forceload_block(centre, true)


minetest.set_node(eggwars.waiting_area, default_hang_block)

-- This function will remove all dropped items from the playing area
removeDrops = function ()
  local pos  = {x=0,y=base_y_layer,z=0}
  local ent
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
  minetest.delete_area(eggwars.islands[1], eggwars.islands[#eggwars.islands])
  players_alive = {};
  match_running = false;
  centrespawn();
  --for m=1,#players_alive do
  --  if(m < #islands) then
  --    islandspawn(m)
  --  end
  --end{x=80,y=150, z=80}{x=80,y=15{x=80,y=150, z=80}0, z=80}
end

-- Function to spawn centre island
centrespawn = function ()
	local y_up = base_y_layer + 155;
	local y_down = base_y_layer + 5;
  minetest.delete_area({x=-80, y=y_down, z=-80}, {x=80,y=y_up, z=80})
  local centre_transformed = table.copy(centre)
  centre_transformed.y = centre_transformed.y - 1
  centre_transformed.x = centre_transformed.x - 10
  centre_transformed.z = centre_transformed.z - 10
  local schempath = eggwars.MP.."/schems";
  local name = "centre"
  ew.debug("centrespawn: " .. minetest.pos_to_string(centre_transformed))
  minetest.place_schematic(centre_transformed, schempath.."/"..name..".mts", 0)
end

-- Function to spawn the Nth island
islandspawn = function (n)
  -- Get a copy of the table, so we can modify it to place the schematic properly
  local schem_l = table.copy(eggwars.islands[n])
  schem_l.y = schem_l.y - 6
  schem_l.x = schem_l.x -7
  schem_l.z = schem_l.z -7
  local schempath = eggwars.MP.."/schems";
  local name = "island"
  ew.debug("spawn island: " .. minetest.pos_to_string(schem_l))
  minetest.place_schematic(schem_l, schempath.."/"..name..".mts", 0, nil, true) -- Force place schematic
  return eggwars.islands[n] -- Return spawn point
end

-- Return index on table of registered player, null of not
-- @param player name
is_player_registered = function(player)
  if(player == nil) then
    ew.debug("Unable to find null player on is_player_registered")
    return
  end
  if type(player) ~= "string" then
    ew.debug("is_player_registered required a string player name, skiping")
    return
  end
  ew.debug("Looking for player "..player);
  print(table.concat(eggwars.registered_players, ", "))
	for i=1, #eggwars.registered_players do
    if eggwars.registered_players[i] == player then
      ew.debug(player.." is registered O:");
			return i;
		end
	end
	return nil;
end

ew.player_to_position = function(player_name, position, delay)
  if delay == nil or type(delay) ~= type(1) then
    delay = set_position_delay
  end
  if player_name == nil or type(player_name) ~= "string" then
    ew.debug("Unable to move player")
    return false
  end

  if position == nil then
    return false
  end
  if type(position) ~= type({}) then
    ew.debug("Invalid position provided to transport player")
    return false
  end
  if position.x == nil or position.y == nil or position.z == nil then
    ew.debug("Position provided has not X Y Z coords")
    return false
  end
  local player_ent = minetest.get_player_by_name(player_name);

  minetest.after(delay, function()
    player_ent:set_pos(position);
  end)
end

local go_lobby = function(playerName)
  local has_moved = false
	if is_player_registered(playerName) == nil then
		ew.debug(playerName.." is not registered");
		return has_moved;
	end
	if minetest.get_node_or_nil(eggwars.waiting_area) == nil then
		minetest.set_node(eggwars.waiting_area, default_hang_block)
	end
  local wal = table.copy(eggwars.waiting_area);
  wal.y = wal.y + 2
  ew.debug("Moving "..playerName.." to "..minetest.pos_to_string(wal))
  local player = minetest.get_player_by_name(playerName)
  if( player ~= nil) then
    ew.player_to_position(playerName, wal, set_position_delay)
    has_moved = true
  end
  return has_moved
end;

-- @param Minetest player object
ew.set_spectator_mode = function(playerEnt)
  -- and give player fly, fast and noclip.
  local player_name = playerEnt:get_player_name()
  minetest.set_player_privs(player_name,{fly=true,fast=true,noclip=true})
  --Make nametag invisible
  playerEnt:set_nametag_attributes({color = {a = 255, r = 0, g = 0, b = 0}})
  --Make player invisible
  playerEnt:set_properties({visual_size={x=0, y=0}})
  minetest.chat_send_player(player_name, "You will respawn on ".. respawn_time)
end

-- @param Minetest player object
ew.set_player_mode = function(playerEnt)
  if playerEnt == nil then
    ew.debug("Unable to set player mode on null player")
    return
  end
  local player_name = playerEnt:get_player_name()
  if player_name == nil then
    ew.debug("Unable to get player name at ew.set_player_mode")
  end
  local player_index = is_player_registered(player_name)
  if player_index == nil then
    ew.debug("Unable to locate :" ..player_name )
  end
  local player_color = player_colours[player_index]
  minetest.set_player_privs(player_name, {interact=true,shout=true})
  --Make nametag visible again
  if player_color == nil then
    player_color = default_name_tag_color
  end
  playerEnt:set_nametag_attributes({color = player_color})
  --Make player visible again
  playerEnt:set_properties({visual_size={x=1, y=1}})
end

ew.process_player_death = function(player)
  --minetest.chat_send_all(minetest.pos_to_string(player_i[player:get_player_name()]))
  --minetest.chat_send_all(minetest.get_node(player_i[player:get_player_name()]).name)
  -- Check if egg exists
  local player_name = player:get_player_name()
  -- Unable to process player
  if player_name == nil then
    ew.debug("Unable to process death of null player")
    return
  end
  local player_island = player_i[player_name]
  if player_island then
    if minetest.get_node(player_island).name ~= "eggwars:egg" then
       -- if not, remove from game
      minetest.chat_send_all("*** "..player_name.." is " .. minetest.colorize('red','OUT'))
      ew.set_spectator_mode(player)
      for j=1,#players_alive do
        if players_alive[j] == player_name then
          table.remove(players_alive,j)
        end
      end
      if #players_alive == 1 then
        minetest.chat_send_all(minetest.colorize("green", "*** " .. players_alive[1] .. " has won!"))
        reset();
      elseif #players_alive == 0 then
        minetest.chat_send_all(minetest.colorize("green", "*** " .. player_name .. " has won!"))
        reset();
      end
    else
      minetest.chat_send_all("*** "..player_name.." paid Hades a visit but was revived by their egg.")
      ew.set_player_mode(player)
      --ew.move_player_to_island(player)
    end
  end
end

ew.get_player_island = function(player_name)
	local player_index = is_player_registered(player_name)
  if player_index == nil then
    return nil
  end
  if player_i[player_name] == nil then
    return nil
  end
  local respawn_pos = table.copy(player_i[player_name])
  respawn_pos.y = respawn_pos.y + 2
  return respawn_pos
end

-- Receives the Minetest Player entity and try to move it to his island
ew.move_player_to_island = function(player_ent)
  local player_name = player_ent:get_player_name()
  ew.debug("Moving " .. player_name)
  local player_index = is_player_registered(player_name)
  if player_index == nil then
    ew.debug("Player is not found at ew.move_player_to_island")
    return nil
  end
  local player_moved
  local island_position = ew.get_player_island(player_name)
  if island_position ~= nil then
    -- Wait until they have actually respawned before moving
    ew.debug("Moving player to his island")
    ew.player_to_position(player_name, island_position, set_position_delay)
    player_moved = true
  else
    ew.debug("Player has no island, moving to lobby")
    player_moved = go_lobby(player_name)
  end
  -- Prevent default spawn on respawn
  return player_moved
end

function unregister_player(name)
	local i_name = is_player_registered(name);
	if i_name == nil then
		ew.debug("Player not registered")
		return;
	end
	eggwars.registered_players.remove(i_name);
	ew.debug("The player was registered")
end;

ew.begin_match = function ()
	if #eggwars.registered_players < 1 then -- Can't have a match on their own!
		minetest.chat_send_all("Unable to start the game with "..#eggwars.registered_players.." Players");
      return;
    end
    minetest.chat_send_all("Starting match with "..#eggwars.registered_players.." Players");
	centrespawn();
  for k=1,#eggwars.registered_players do
    local player = minetest.get_player_by_name(eggwars.registered_players[k]);
    local player_n = eggwars.registered_players[k];
    player_colours[player_n] = allowed_colours[k]
    ew.set_player_mode(player)
    islandspawn(k);
    local current_island_spawn = table.copy(eggwars.islands[k]);
    current_island_spawn.y = current_island_spawn.y + 10
    player:set_pos(eggwars.islands[k])
    player_i[player_n] = eggwars.islands[k];
    players_alive[k] = player_n;
  end
	match_running = true;
  --eggwars.registered_players = {}; -- Reset list of registered players
end

--minetest.register_on_newplayer(function(player))
--end)

-- Let's colour the chat!

minetest.register_on_chat_message(function(name, message)
  local found = false;
  for i=1,#players_alive do
    if players_alive[i] == name then
      found = true;
    end
  end
  if found == true then
    -- local colour = "#" .. string.format('%x', player_colours[name].r) .. string.format('%x', player_colours[name].g)
    --.. string.format('%x', player_colours[name].b)

    -- Let's check if the hex version has one or more chars
    local red = string.format('%x', player_colours[name].r)
    if red:len() == 1 then
      red = 0 .. red
    end
    local green = string.format('%x', player_colours[name].g)
    if green:len() == 1 then
      green = 0 .. green
    end
    local blue = string.format('%x', player_colours[name].b)
    if blue:len() == 1 then
      blue = 0 .. blue
    end
    -- And now concatenate it too
    local colour = "#" .. red .. green .. blue
    minetest.chat_send_all(minetest.colorize(colour, "<" .. name .. "> ") .. message)
  else
    minetest.chat_send_all("<" .. name .. "> " .. message)
  end
  return true;
end)

-- Kill the player if they fall under a y=50
kill_on_exceed_boundaries = function()
	local cur_player;
	for i=1, #eggwars.registered_players do
		cur_player = minetest.get_player_by_name(eggwars.registered_players[i]);
		if cur_player ~= nil and cur_player:getpos().y < min_y_registered_waiting_user then
			-- cur_player:set_pos(eggwars.waiting_area);
			do_void_damage_to_player(eggwars.registered_players[i]);
		end
	end
  for i=1,#players_alive do
    if players_alive[i] ~= nil then
      local curr_player = minetest.get_player_by_name(players_alive[i])
      if curr_player ~= nil and curr_player:getpos().y < min_y_registered_playing_user then
        do_void_damage_to_player(players_alive[i]);
      end
    end
  end
  minetest.after(.75, kill_on_exceed_boundaries)
end

do_void_damage_to_player = function(Username)
	local player = minetest.get_player_by_name(Username);
  if player then
    local current_hp = player:get_hp()
    if(current_hp > 0) then
      ew.debug("Player ".. Username.." is in "..player:getpos().y )
      ew.debug("Damage of the void to this guy " ..Username);
      player:set_hp(current_hp - void_damage)
    end
	end
end

ew.simulateStart = function()
	centrespawn();
  for k=1,#eggwars.islands do
    if eggwars.registered_players[k] ~= nil then
      local player = minetest.get_player_by_name(eggwars.registered_players[k]);
      local player_n = eggwars.registered_players[k];
      --minetest.set_player_privs(player_n, {interact=true,shout=true});
      player:set_nametag_attributes({color = allowed_colours[k]})
      player_colours[player_n] = allowed_colours[k]

      islandspawn(k);
      local current_island_spawn = table.copy(eggwars.islands[k]);
      current_island_spawn.y = current_island_spawn.y + 10;
      ew.debug("Setting spawn to player "..minetest.pos_to_string(eggwars.islands[k]));
      player:set_pos(eggwars.islands[k])
      player_i[player_n] = eggwars.islands[k];
      players_alive[k] = player_n;
    end
  end
	match_running = true;
  eggwars.registered_players = {}; -- Reset list of registered players
end

--simulateStart();


 --- end testing

ew.register_player = function(name, param)
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
        ew.begin_match();
      else
				minetest.chat_send_all(#eggwars.registered_players .. "/8 players have registered! Use /register to join.");
			end
    else
      minetest.chat_send_player(name,
        "Sorry. A match is already running. Please use /start once their match has finished.");
		end
	else
    minetest.chat_send_player(name,
      "Sorry. 8 players have already registered. Try registering after their game has begun.")
	end
	go_lobby(name);

end;

ew.who_is_online = function(name, param)
	local text = "Players in match: "
	for i=1,#players_alive do
	  local red = string.format('%x', player_colours[players_alive[i]].r)
	  if red:len() == 1 then
		red = 0 .. red
	  end
	  local green = string.format('%x', player_colours[players_alive[i]].g)
	  if green:len() == 1 then
		green = 0 .. green
	  end
	  local blue = string.format('%x', player_colours[players_alive[i]].b)
	  if blue:len() == 1 then
		blue = 0 .. blue
	  end
	  -- And now concatenate it too
	  local colour = "#" .. red .. green .. blue
	  text = text .. minetest.colorize(colour,players_alive[i])
	end
	minetest.chat_send_player(name,text)
end

--- MINETEST Listeners
minetest.after(0.1, kill_on_exceed_boundaries)

minetest.register_on_joinplayer(function (player)
	go_lobby(player:get_player_name());
end)

minetest.register_on_leaveplayer(unregister_player);
-- Upon respawning, move players back to their island.
minetest.register_on_respawnplayer( function(player)
  return ew.move_player_to_island(player)
end
)

minetest.register_on_dieplayer(ew.process_player_death)



-- CHAT COMMANDS
--
local register_chat_init_result =  register_chat_handler._init(ew)
if ( register_chat_init_result.status ~= 0) then
  ew.debug(register_chat_init_result.message)
end

for i=1,#ew.commands do
  local cmd = ew.commands[i]
  minetest.register_chatcommand(cmd.cli, cmd.body);
end

--minetest.set_mapgen_setting("singlenode",1)
ew.debug('Eggwars loaded')
