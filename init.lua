----------------------------------------------------------------------
-- Eggwars by wilkgr with additional code by shivajiva              --
-- Licensed under the AGPL v3                                       --
-- You MUST make any changes you make open source                   --
-- even if you just run it on your server without publishing it     --
-- Supports a maximum of 8 players per instance and 8 concurrent    --
-- instances for a max of 64 players                                --
----------------------------------------------------------------------

minetest.set_mapgen_params({mgname = "singlenode"})

eggwars = {}

eggwars.arena = {
  colour = {
    {r = 0, g = 0, b = 255}, -- Blue
    {r = 0, g = 255, b = 0}, -- Green
    {r = 255, g = 0, b = 0}, -- Red
    {r = 108, g = 0, b = 255}, -- Purple
    {r = 255, g = 255, b = 0}, -- Yellow
    {r = 0, g = 255, b = 255}, -- Aqua
    {r = 255, g = 165, b = 0}, -- Orange
    {r = 255, g = 0, b = 255} -- Pink
  },
  egg = {
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0}
  },
  hub = {
    insert_offset = {x=-30, y=-16, z=-30},
    region = {
      p1 = {x=-30, y=-20, z=-30},
      p2 = {x=30, y=30, z=30}
    }
  },
  -- Confined to 90 degree rotations the current schema
  -- places 2 islands per side of a square, giving us 8
  -- islands max per instance. Each island is displaced
  -- equally from the arena centre position using the
  -- island vector table
  island = {
    {x=100, y=0, z=-25}, -- BL
    {x=-100, y=0, z=-25}, -- TL
    {x=100, y=0, z=25}, -- BR
    {x=-100, y=0, z=25}, -- TR
    {x=25, y=0, z=-100}, -- LB
    {x=-25, y=0, z=-100}, -- LT
    {x=25, y=0, z=100}, -- RB
    {x=-25, y=0, z=100}, -- RT
    insert_offset = {x=-11, y=-23, z=-10}
  },
  nodes = {
    -- node timer position offsets
    diamond = {}, -- relative to arena pos
    gold = {
      {x=-4, y=-1, z=-2}, -- indexed relative to island
      {x=4, y=-1, z=2},
      {x=-4, y=-1, z=-2},
      {x=-4, y=-1, z=-2},
      {x=-4, y=-1, z=-2},
      {x=-4, y=-1, z=-2},
      {x=-4, y=-1, z=-2},
      {x=-4, y=-1, z=-2}
    },
    ruby = {} -- relative to arena pos
  },
  pos = {
    {x=0, y=0, z=0},
    {x=200, y=0, z=200},
    {x=400, y=0, z=400},
    {x=600, y=0, z=600},
    {x=800, y=0, z=800},
    {x=1000, y=0, z=1000},
    {x=1200, y=0, z=1200},
    {x=1400, y=0, z=1400}
  },
  region = {
    p1 = {x=-120, y=-30, z=-120},
    p2 = {x=120, y=100, z=120}
  },
  rotate = {"0", "180", "270", "90", "0", "180", "270", "90"},
  trader = {
    {x=-5, y=0, z=0}, -- indexed relative to island
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0}
  }
}
eggwars.armor = minetest.get_modpath("armor") ~= nil
eggwars.maptools = minetest.get_modpath("maptools") ~= nil
eggwars.match = {}
eggwars.nodetimer = {}
eggwars.nodetimer.diamond = {}
eggwars.nodetimer.gold = {}
eggwars.nodetimer.ruby = {}
eggwars.player = {}

---------------------
-- Local Variables --
---------------------

local load_lobby = mod_data:get_int('lobby') -- returns 0 if missing!
local lobby = {
  insert_offset = {x=-42, y=-14, z=-30},
  pos = {x=0, y=1000, z=0},
  region = {
    p1 = {x=-83, y=980, z=-83},
    p2 = {x=83, y=1030, z=83}
  }
}
local min_match_players = 0 -- min players needed for a match (default = 4)
local mod_data = minetest.get_mod_storage() -- mod storage
local MP = minetest.get_modpath("eggwars")
local registered_players = {} -- temp prematch buffer
local schempath = MP.."/schems"

-- local sdata = minetest.deserialize(mod_data:get_string('data')) or {}

dofile(MP.."/register_nodes.lua")
dofile(MP.."/shop.lua")
dofile(MP .. "/extender.lua")

----------------------
-- Helper Functions --
----------------------

--- Remove objects and replace region with air correctly
-- @return nothing
local function clean(pos1, pos2)
  eggwars.clear_objects(pos1, pos2)
  eggwars.delete_area(pos1, pos2)
  eggwars.fixlight(pos1, pos2)
end

--- Finds first unused arena index
-- @return integer index or nil if all arenas are in use!
local function next_index()

  for i, _ in ipairs(eggwars.arena.pos) do
    local used
    for _, v in ipairs(eggwars.match) do
      if v.index == i then
        used = true
        break -- jump to the outer loop
      end
    end
    if not used then return i end
  end
end

--- Inserts lobby in world and protects it
-- @return nothing
local function add_lobby()
  -- calculate insertion pos, place schema, protect & save to settings
  local pos = vector.add(lobby.pos, lobby.insert_offset)
  minetest.place_schematic(pos, schempath.."/hub.mts", nil, true)
  eggwars.protect(lobby.region.p1, lobby.region.p2, false)
  load_lobby = 1
  mod_data:set_int("lobby", load_lobby)
end

-------------------
-- API Functions --
-------------------

--- Reset arena by index
-- @param n integer index of arena
-- @return nothing
eggwars.reset = function(n)
  local pos = eggwars.arena.pos[n]
  local p1 = vector.add(pos, eggwars.arena.region.p1)
  local p2 = vector.add(pos, eggwars.arena.region.p2)
  clean(p1, p2)
end

-- lobby hub islands for an arena instance
-- @param n integer index of arena
-- @return nothing
eggwars.centrespawn = function(n)
  local sp = eggwars.arena.pos[n]
  local p1 = vector.add(sp, eggwars.arena.hub.region.p1)
  local p2 = vector.add(sp, eggwars.arena.hub.region.p2)
  local p3 = vector.add(sp, eggwars.arena.hub.insert_offset)
  clean(p1, p2)
  minetest.place_schematic(p3, schempath.."/centre.mts", nil, true)
end

--- Spawn island at pos, indexed by n
-- @param pos vector table
-- @param n integer index of island coords
-- @return spawn vector
eggwars.islandspawn = function(pos, n)
  local p1 = vector.subtract(pos, 15)
  local p2 = vector.add(pos, 15)
  local p3 = vector.add(pos, eggwars.arena.island.insert_offset)
  clean(p1, p2)
  minetest.place_schematic(p3, schempath.."/island_u.mts", eggwars.arena.rotate[n])
  return pos
end

--- Creates a match instance from registered_players table
-- @return nothing
eggwars.begin_match = function ()
  -- A match consists of an instance of an arena and between 4-8 players
  --
  -- match.index - arena index
  -- match.alive - players alive
  local match = {}
  local n = next_index() -- arena index
  local pos = eggwars.arena.pos[n] -- base vector
  eggwars.reset(n)
  -- spawn players and their islands
  for i, name in ipairs(registered_players) do
    local player = minetest.get_player_by_name(name)
    local sp = vector.add(pos, eggwars.arena.island[n])
    local colour = eggwars.arena.colour[i]
    local adj = sp
    eggwars.player[name] = {}
    eggwars.player[name].color = colour
    eggwars.player[name].match = n
    eggwars.player[name].alive = true
    eggwars.player[name].rate = 5
    eggwars.player[name].id = i
    minetest.set_player_privs(name, {interact=true, shout=true})
    player:set_nametag_attributes({color = colour})
    adj.y = adj.y + 2
    player:set_pos(adj) -- player first!
    eggwars.player[name].spawn = eggwars.islandspawn(sp, i) -- island

    -- Add spawners and initialise node timers
    adj = vector.add(sp, eggwars.arena.nodes.gold[i])
    minetest.set_node(adj, {name='eggwars:gold_spawner'})
    minetest.get_node_timer(adj):start(5)
    eggwars.nodetimer.gold[name] = adj

    -- Add egg!
    adj = vector.add(sp, eggwars.arena.egg[i])
    minetest.set_node(adj, {name='eggwars:egg'..i})
    local meta = minetest.get_meta(adj)
    meta:set_string('owner', name)
    meta:set_string('infotext', name .. "'s egg")

    -- TODO Add trader and upgrade bot entities

  end

  eggwars.centrespawn(n)

  --TODO Add spawners and initialise node timers

  -- Contain & kill player at boundary
  local v = {
    p1 = vector.add(pos, eggwars.arena.region.p1),
    p2 = vector.add(pos, eggwars.arena.region.p2)
  }
  eggwars.protect(v.p1, v.p2, false)
  -- initialise match
  match.index = n
  match.alive = #registered_players
  table.insert(eggwars.match, match)
  -- Reset registered players table
  registered_players = {};
end

--- Broadcast match chat
-- @return nothing
eggwars.chat_send_match = function(index, msg)
  for k,v in pairs(eggwars.player) do
    if v.match == index then
      minetest.chat_send_player(k, msg)
    end
  end
end

-------------------------------------
-- Registered callbacks   --
-------------------------------------

minetest.register_on_dieplayer(function(player)

  local name = player:get_player_name()
  local pos, game, i

  if eggwars.player[name] then
    i = eggwars.player[name].id
    pos = vector.add(eggwars.player[name].spawn, eggwars.arena.egg[i])
    game = eggwars.player[name].match
  end

  if pos then

    if minetest.get_node(pos).name ~= "eggwars:egg" .. i then

      minetest.chat_send_all("*** "..name.." is " .. minetest.colorize('red','OUT'))

      minetest.set_player_privs(name, {fly=true,fast=true,shout=true}) -- and give player fly, fast and noclip.

      player:set_nametag_attributes({color = {a = 0, r = 0, g = 0, b = 0}}) --Make nametag invisible
      player:set_properties({visual_size={x=0, y=0}}) --Make player invisible

      if eggwars.armor then eggwars.clear_armor(player) end

      eggwars.clear_inventory(player)
      eggwars.player[name].alive = false
      eggwars.match[game].alive = eggwars.match[game].alive - 1

      if eggwars.match[game].alive == 1 then

        minetest.chat_send_all(minetest.colorize("green", "*** " ..
          name .. " won their match!"))

        -- TODO add fanfare

        eggwars.reset(game); -- clean up before any remaining players leaves!

        for k, v in pairs(eggwars.players) do

          -- handle match players
          if v.match == game then

            local obj = minetest.get_player_by_name(k)

            if obj then
              -- reset spectator nametag and visual size
              if not v.alive then
                obj:set_nametag_attributes({
                  color = {a = 255, r = 255, g = 255, b = 255}}) --Make nametag visible
                obj:set_properties({visual_size={x=1, y=1, z=1}}) --Make player visible
              else
                -- reset the winner
                if eggwars.armor then eggwars.clear_armor(obj) end
                eggwars.clear_inventory(obj "Players in match: ")
              end
              minetest.set_player_privs(k, {shout=true}) -- set lobby privs
              obj:set_pos(lobby.pos) -- move player
            end

            eggwars.player[name] = nil -- remove
          end
        end

        eggwars.match[game] = nil -- remove from match table
      end
    else
      -- Clean inventory & announce
      eggwars.clear_inventory(player)
      minetest.chat_send_all("*** " ..
        name.." paid Hades a visit and was revived by their egg.")

    end
  end
end)

-- Upon respawning, move players back to the lobby
-- or their island if in a match.
minetest.register_on_respawnplayer(function(player)
  local name = player:get_player_name()
  local pos = lobby.pos -- initialise with lobby vector
  -- match override
  if eggwars.player[name] then
    pos = vector.new(eggwars.player[name].spawn)
    pos.y = pos.y + 2
  end
  minetest.after(0.1, function () player:set_pos(pos) end) -- Wait for respawn before moving
end)

minetest.register_on_joinplayer(function(player)
  -- handle the player - no items or interact in the hub
  if eggwars.armor then eggwars.clear_armor(player) end
  eggwars.clear_inventory(player)
  minetest.set_player_privs(player:get_player_name(), {shout=true}) --
  player:set_pos(lobby.pos)
  -- handle the lobby
  if load_lobby == 0 then
    add_lobby()
  end
end)

minetest.register_on_leaveplayer(function(player)
end)

eggwars.colorize = function(rgb, msg)
  local red = string.format('%x', rgb.r)
  local green = string.format('%x', rgb.g)
  local blue = string.format('%x', rgb.b)
  -- modify if reqd
  if red:len() == 1 then red = 0 .. red end
  if green:len() == 1 then green = 0 .. green end
  if blue:len() == 1 then blue = 0 .. blue end
  -- And now concatenate it too
  local colour = "#" .. red .. green .. blue
  return minetest.colorize(colour, msg)
end

-- Let's colour the chat!
minetest.register_on_chat_message(function(name, message)
  local txt = "<" .. name .. "> " .. message
  if eggwars.player[name] then
    txt = eggwars.colorize(eggwars.player[name].colour, message)
    eggwars.chat_send_match(eggwars.player[name].match, txt)
  else
    -- player in lobby
    minetest.chat_send_all(txt) -- broadcast
  end
  return true -- return as handled!arena.island
end)

-----------------------------------------
-- Registered chat commands   --
-----------------------------------------

-- register for a match
minetest.register_chatcommand("register", {
	params = "",
	description = "Join match",
	func = function(name, param)
		if #registered_players < 8 then -- max 8 players in a match
	    if #eggwars.match < #eggwars.arena.pos then -- max matches
        for i, v in ipairs(registered_players) do
          if registered_players[v] == name then
            minetest.chat_send_player(name,"You have already registered")
            return
          end
        end
        registered_players[#registered_players+1] = name;
	      if #registered_players == 8 then
	        eggwars.begin_match();
	      else
					minetest.chat_send_all(#registered_players .. "/8 players have registered! Use /register to join.");
				end
	    else
				minetest.chat_send_player(name,"Sorry the max number of games are running. Please use /start once a match has finished.");
			end
		else
			minetest.chat_send_player(name,"Sorry. 8 players have already registered. Try registering after their game has begun.")
		end
	end,
})

-- start match
minetest.register_chatcommand("start", {
	params = "",
	description = "Starts the game",
	func = function(name, param)
    if #registered_players >= min_match_players then
      eggwars.begin_match()
    end
  end
})

minetest.register_chatcommand("add", {
	params = "",
	description = "Starts the game",
	func = function(name, param)
    if #registered_players >= min_match_players then
      eggwars.begin_match()
    end
  end
})

-- list players
minetest.register_chatcommand("who", {
	params = "<index>",
	description = "List players in match <index>",
	func = function(name, param)
    if not param then return "missing param!" end
    if param < 1 or param > #eggwars.match then
      return "param out of bounds!"
    end
    local text = {}
    text[#text+1] =  "Players in match: " .. param .. " "
    for k, v in pairs(eggwars.player) do
      if v.match == param then
        text[#text+1] = eggwars.colorize(v.color, k)
      end
    end
    minetest.chat_send_player(name, table.concat(text))
  end
})

minetest.log('info', '[LOADED] Eggwars')
