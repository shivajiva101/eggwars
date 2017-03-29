----------------------------------------------------
-- Eggwars by wilkgr
-- Licensed under the AGPL v3
-- You MUST make any changes you make open source
-- even if you just run it on your server without publishing it
-- Supports a maximum of 8 players currently
----------------------------------------------------

minetest.set_mapgen_params({mgname = "singlenode"})
local i = 1;
local players_waiting = {};
local waiting_area = {x=0,y=150,z=0};
local islands = {{x=50,y=100,z=0},{x=-50,y=100,z=0},{x=0,y=100,z=50},{x=50,y=100,z=50},{x=-50,y=100,z=50},{x=-50,y=100,z=-50},{x=0,y=100,z=-50},{x=50,y=100,z=-50}}
local islands2 = islands;
local player_i = {};

--[[
chestrefill = function ()
  for i=1, #islands do
    local items = {"default:diamond","default:wood","default:wood","default:stick","default:wood","default:wood","default:mesecrystal","default:sword_diamond","default:sword_stone","default:sword_stone","default:sword_stone","default:sword_stone"}
    minetest.set_node(islands[i],{name = "default:chest"})
    math.randomseed(os.clock()*100000000000)
    math.random()
    local item_no = math.random(1, 4)
    local n = 0
    while n < item_no do
      math.randomseed(os.clock()*100000000000)
      math.random()
      local item = math.random(1, #items)
      local inv = minetest.get_inventory({type="node", pos=islands[i]})
      inv:add_item("main",items[item])
      n = n + 1;
    end
  end
end
]]


-- MTS place: y-7, z-7, x-7
islandspawn = function (n)
  minetest.set_node(islands[n],{name = "eggwars:egg"})
  local schem_l = islands[n];
  schem_l.y = schem_l.y - 6
  schem_l.x = schem_l.x -7
  schem_l.z = schem_l.z -7
  local schempath = minetest.get_modpath("eggwars").."/schems";
  local name = "island"
  if  minetest.place_schematic(schem_l, schempath.."/"..name..".mts") == nil then
    minetest.debug(minetest.pos_to_string(schem_l))
  end
  --minetest.place_schematic(schem_l,minetest.get_modpath("eggwars").."/schems/island.mts")
  return true;
end

minetest.register_node("eggwars:egg", {
	tiles = {
		"default_stone.png",
		"default_stone.png",
		"default_stone.png",
		"default_stone.png",
		"default_stone.png",
		"default_stone.png"
	},
  groups = {crumbly = 3},
	drawtype = "nodebox",
	paramtype = "light",
  sounds = default.node_sound_stone_defaults(),
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, 0, -0.5, 0.5, 0.125, 0.5}, -- NodeBox1
			{-0.375, -0.125, -0.375, 0.375, 0.25, 0.375}, -- NodeBox2
			{-0.25, -0.1875, -0.25, 0.25, 0.375, 0.25}, -- NodeBox5
			{-0.125, -0.1875, -0.125, 0.125, 0.5, 0.0625}, -- NodeBox6
		}
	}
})

minetest.register_node("eggwars:goldspawn1", {
  tiles = {"default_gold_block.png"},
  groups = {crumbly = 3} --Temporary, should be unbreakable
})

minetest.register_node("eggwars:diamondspawn", {
  tiles = {"default_diamond_block.png"},
  groups = {crumbly = 3} --Temporary, should be unbreakable
})

minetest.register_node("eggwars:steelspawn1", { --Slower spawn rate; for player islands
  tiles = {"default_steel_block.png"},
  groups = {crumbly = 3} --Temporary, should be unbreakable
})

minetest.register_node("eggwars:steelspawn2", { --Faster spawn rate; for center island(s)
  tiles = {"default_diamond_block.png"},
  groups = {crumbly = 3} --Temporary, should be unbreakable
})

minetest.register_node("eggwars:cobblespawn", {
  tiles = {"default_cobble.png"},
  groups = {crumbly = 3} --Temporary, should be unbreakable
})

minetest.register_abm({
	nodenames = {"eggwars:diamondspawn"},
	interval = 8,
	chance = 1,
	action = function(pos)
		pos.y = pos.y + 1
		minetest.add_item(pos,"default:diamond")
	end,
})

minetest.register_abm({
	nodenames = {"eggwars:cobblespawn"},
	interval = 5,
	chance = 1,
	action = function(pos)
		pos.y = pos.y + 1
		minetest.add_item(pos,"default:cobble")
	end,
})

minetest.register_abm({
	nodenames = {"eggwars:steelspawn1"},
	interval = 10,
	chance = 1,
	action = function(pos)
		pos.y = pos.y + 1
		minetest.add_item(pos,"default:steel_ingot")
	end,
})

minetest.register_abm({
	nodenames = {"eggwars:steelspawn2"},
	interval = 5,
	chance = 1,
	action = function(pos)
		pos.y = pos.y + 1
		minetest.add_item(pos,"default:steel_ingot")
	end,
})

minetest.register_on_dieplayer(function(player)
  local block = minetest.get_node(player_i[player:get_player_name()]).name
  minetest.chat_send_all(minetest.pos_to_string(player_i[player:get_player_name()]))
  minetest.chat_send_all(minetest.get_node(player_i[player:get_player_name()]).name)

  if minetest.get_node(player_i[player:get_player_name()]).name ~= "eggwars:egg" then
    minetest.chat_send_all("***"..player:get_player_name().." is " .. minetest.colorize('red','OUT')..'.')
    --minetest.set_player_privs(player:get_player_name(),{fly=true,fast=true,noclip=true}) --Give player fly, fast and noclip. Revokes other privs.
    player:set_nametag_attributes({color = {a = 255, r = 0, g = 0, b = 0}}) --Make nametag invisible
    player:set_properties({visual_size={x=0, y=0}}) --Make player invisible
  else
    minetest.chat_send_all("***"..player:get_player_name().." paid Hades a visit.")
    player:set_player_privs({interact=true,shout=true})
    local respawn_pos = player_i[player:get_player_name()]
    respawn_pos.y = respawn_pos.y + 2
    player:setpos(respawn_pos)
  end
end)

--[[
minetest.register_abm({
	nodenames = {"eggwars:goldspawn1"},
	interval = 10,
	chance = 1,
	action = function(pos)
		pos.y = pos.y + 1
		minetest.add_item(pos,"default:gold_ingot")
	end,
})
]]

minetest.register_on_joinplayer(function(player)

  local player_n = player:get_player_name()
  local privs = minetest.get_player_privs(player_n)
  privs.fly = true
  minetest.set_player_privs(player_n, privs)
  if i >= 8 then
    minetest.set_node(waiting_area, {name = "default:dirt_with_grass"})
    player:setpos(waiting_area)
  else
    player:setpos(islands[i])
    player_i[player_n] = islands[i];
    islandspawn(i)
    i = i + 1;
  end
end)
