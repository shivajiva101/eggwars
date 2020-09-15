----------------------------------------------------------------------
-- Eggwars by wilkgr												--
-- with additional code by shivajiva101@hotmail.com		            --
-- Licensed under the AGPL v3                                       --
-- You MUST make any changes you make open source                   --
-- even if you just run it on your server without publishing it     --
-- Supports a maximum of 8 players per instance and 8 concurrent    --
-- instances for a max of 64 players                                --
----------------------------------------------------------------------

minetest.set_mapgen_params({mgname = "singlenode"})
math.randomseed(os.time())

eggwars = {}
eggwars.arena = {}
eggwars.armor = minetest.get_modpath("3d_armor") ~= nil
eggwars.bows = minetest.get_modpath("bows") ~= nil
eggwars.match = {}
eggwars.player = {}

---------------------
-- Local Variables --
---------------------

local mod_data = minetest.get_mod_storage() -- mod storage

local arena_pos = {
	{x = 0, y = 0, z = 0},
	{x = 1000, y = 0, z = 0},
	{x = 0, y = 0, z = 1000},
	{x = 1000, y = 0, z = 1000},
	{x = -1000, y = 0, z = 0},
	{x = 0, y = 0, z = -1000},
	{x = -1000, y = 0, z = -1000},
	{x = -2000, y = 0, z = 0}
}
local loaded = minetest.deserialize(mod_data:get_string('loaded')) or {arena = {}}
local lobby = {
	insert_offset = {x = -42, y = -14, z = -30},
	pos = {x = 0, y = 1000, z = 0},
	region = {
		p1 = {x = -83, y = 980, z = -83},
		p2 = {x = 83, y = 1030, z = 83}
	}
}
local min_match_players = 4 -- min players needed for a match (default = 4)
local owner = minetest.settings:get('name')
local MP = minetest.get_modpath("eggwars")
local WP = minetest.get_worldpath()
local registered_players = {} -- temp prematch buffer
local schempath = MP.."/schems/"
local stats = minetest.deserialize(mod_data:get_string('statistics')) or {}
local reload = mod_data:get_string('dirty') == "true"
local tmp_tbl, tmp_hud = {}, {}
local r_rate = 5

stats.rankings = stats.rankings or {}

if reload then loaded = {
	arena = {}
	}
end

dofile(MP .. "/register_arena.lua")
dofile(MP.."/register_nodes.lua")
dofile(MP.."/shop.lua")
dofile(MP .. "/extender.lua")
dofile(MP .. "/tools.lua")

----------------------
-- Helper Functions --
----------------------

--- Sets server conf settings
-- @return nothing
local function set_settings()
	minetest.settings:set('player_transfer_distance', 1)
	minetest.settings:set('time_speed', 0)
	minetest.settings:write()
	minetest.set_timeofday(0.5) -- noon
end

--- Remove objects and replace region with air
-- @param pos1 - vector table
-- @param pos2 - vector table
-- @return nothing
local function clean(pos1, pos2)
	eggwars.clear_nodes(pos1, pos2)
	eggwars.fixlight(pos1, pos2)
	eggwars.clear_objects(pos1, pos2)
end

--- Remove objects and replace region with air
-- @param pos - vector table
-- @param region - vector pair table
-- @return nothing
-- local function clear(pos, region)
-- 	local p1 = vector.add(pos, region.p1)
-- 	local p2 = vector.add(pos, region.p2)
-- 	clean(p1, p2)
-- end

--- Save persistant data
-- @return nothing
local function save_persistant()
	mod_data:set_string('statistics', minetest.serialize(stats))
	mod_data:set_string('dirty', reload)
	mod_data:set_string('loaded', minetest.serialize(loaded))
end

--- Create and return a unique integer
-- @param tbl temp table
-- @param from - start integer
-- @param to - end integer
-- @return random unique integer between from & to
local function my_random(tbl, from, to)
	local num = math.random (from, to)
	if tbl[num] then num = my_random(tbl, from, to) end
	tbl[num] = num
	return num
end

--- Generate a random unique list for the trader name order
-- @return table of unique random integers
local function gen_trader_order()
	local tbl = {}
	for i = 1, 8 do
		tbl[#tbl + 1] = my_random(tmp_tbl, 1, 8)
	end
	tmp_tbl = {}
	return tbl
end

--- Finds first unused arena index
-- @return integer index or nil if all arenas are in use!
local function next_index()
	for i, _ in ipairs(arena_pos) do
		local used
		for _, v in pairs(eggwars.match) do
			if v.id == i then
				used = true
				break -- jump to the outer loop
			end
		end
		if not used then return i end
	end
end

-- Check path for correct file presence
-- @param path: folder to check
-- @param name: filename without extension
-- @return truth table including count
local function check_files(path, name)

	local extension, file, err
	local list = {}
	list.n = 0
	extension = {"mts", "ewm"}

	for _, entry in ipairs(extension) do
		local filename = path .. name .. "." .. entry
		file, err = io.open(filename, "rb")
		if err then
			list[entry] = false
		else
			file:close()
			list[entry] = true
			list.n = list.n + 1
		end
	end

	return list

end

--- Inserts & protects the lobby in a new instance
-- @return nothing
local function add_lobby()
	-- calculate insertion pos, place schema, protect & save to settings
	local pos = vector.add(lobby.pos, lobby.insert_offset)
	minetest.place_schematic(pos, schempath.."lobby.mts")
	eggwars.protect(lobby.region.p1, lobby.region.p2, false)
	loaded.lobby = true
	save_persistant()
end

-- lobby loading
if not loaded.lobby then
	minetest.after(0, add_lobby)
end

--- Add match status flags to players HUD
-- @param key - match key string
-- @return nothing
local function gen_match_hud(key)

	local match = eggwars.match[key]
	local pos = - (0.5 * (#match.player * 20) - 2)
	local result = {}
	for _, def in pairs(match.hud_img) do
		local ndef = {
			hud_elem_type = 'image',
			position = {x = 0.5, y = 1},
			scale = {x = 1, y = 1},
			text = def[1],
			alignment = {x = 0, y = 0}, -- table reqd
			offset = {x = pos, y = -100}
		}
		table.insert(result, ndef)
		pos = pos + 20
	end

	for k, def in pairs(match.player) do
		local player = minetest.get_player_by_name(k)
		for i, v in ipairs(result) do
			def.hud_id[i] = player:hud_add(v)
		end
		-- Add Lozenge
		def.pil = player:hud_add({
			hud_elem_type = 'image',
			position = {x = 0, y = 1},
			scale = {x = 1, y = 0.5},
			text = 'eggwars_pil.png',
			alignment = {x = 0, y = 0}, -- table reqd
			offset = {x = 70, y = -20}
		})
		-- Add match time element
		def.remaining = player:hud_add({
			hud_elem_type = 'text',
			position = {x = 0, y = 1},
			scale = {x = 128, y = 64},
			text = 'Remaining: ' .. match.hud_time .. 'm',
			number = '0x00FF00',
			alignment = {x = 0, y = 0}, -- table reqd
			offset = {x = 70, y = -20}
		})
	end
end

--- Remove player hud match elements
-- @param name - players name string
-- @param key - match key string
-- @return nothing
local function remove_player_hud(name)
	local obj = minetest.get_player_by_name(name)
	if not obj then return end
	local key = eggwars.player[name]
	local def = eggwars.match[key].player[name]
	for _, v in ipairs(def.hud_id) do
		obj:hud_remove(v)
	end
	obj:hud_remove(def.remaining)
	obj:hud_remove(def.pil)
end

--- Remove match status flags from players HUD
-- @param key - arena key string
-- @return nothing
local function remove_match_hud(key)
	for k, _ in pairs(eggwars.match[key].player) do
		remove_player_hud(k)
	end
end

--- Add an image to a players HUD that removes itself
-- @param player - object
-- @param image_string - filename of image
-- @param timer - time in seconds it displays
-- @return nothing
local function add_tmp_image(player, image_string, timer)
	local name = player:get_player_name()
	tmp_hud[name] = player:hud_add({
		hud_elem_type = 'image',
		position = {x = 0.5, y = 0.5},
		scale = {x = 1, y = 1},
		text = image_string,
		alignment = {x = 0, y = 0}, -- table reqd
		offset = {x = 0, y = 0}
	})
	minetest.after(timer, function(pname)
		eggwars.remove_tmp_image(pname)
	end, name)
end

--- Remove recipes blocked in arena defs
-- NOTE: this function MUST NOT be run with minetest.after it will
-- cause a SIGSEGV error on server shutdown!!!
-- @return nothing
local function modify_recipes()
	for i, arena in ipairs(eggwars.arena) do
		for j, v in ipairs(arena.blocked_recipes) do
			minetest.clear_craft(v)
		end
	end
end
modify_recipes()

--- Make non expempt nodes unbreakable
-- @return nothing
local function modify_game()
	-- create a list of exempt nodes from the registered arenas
	local exempt_node = {}
	for _, arena in ipairs(eggwars.arena) do
		for _, v in ipairs(arena.exempt_nodes) do
			table.insert(exempt_node, v)
		end
	end
	-- parse registered nodes
	for item, def in pairs(minetest.registered_nodes) do
		local modify = true
		for i, v in ipairs(exempt_node) do
			if string.find(item, v) then
				modify = false
				break
			end
		end
		if modify then
			minetest.override_item(item, {groups = {unbreakable = 1}, })
		end
	end
end

--- Provides match events based on time
-- @return nothing
local function match_timer()
	-- process each match
	for key, def in pairs(eggwars.match) do
		def.tmr = def.tmr + r_rate
		if not def.sd and def.tmr >= def.suddendeath then
			def.sd = true
			for k, v in pairs(def.player) do
				-- remove remaining eggs
				if v.egg then
					minetest.remove_node(v.eggpos)
					v.egg = false
					minetest.sound_play("eggwars_out", {
						to_player = k,
						gain = 1.0,
					})
					eggwars.update_hud(key, v.id)
				end
				minetest.sound_play("eggwars_sudden", {
					to_player = k,
					gain = 1.0,
				})
				add_tmp_image(
					minetest.get_player_by_name(k),
					'eggwars_suddendeath.png', 5
				)
			end
		end
		if def.sd and def.tmr >= def.max_time then
			for k, v in pairs(def.player) do
				minetest.sound_play("eggwars_time_over", {
					to_player = k,
					gain = 1.0,
				})
				add_tmp_image(
					minetest.get_player_by_name(k),
					'eggwars_timeover.png', 5
				)
			end
			eggwars.end_match(key)
		end
		for k, v in pairs(def.player) do
			local player = minetest.get_player_by_name(k)
			local hp = player:get_hp()
			if hp > 0 and v.alive then
				local res = hp + 1
				local max = player:get_properties().hp_max
				if res > max then
					res = max
				end
				if hp ~= res then
					player:set_hp(res)
				end
			end
		end
	end
	-- finally retrigger
	minetest.after(r_rate, match_timer)
end

--- Initialises stats for a new player
-- @param name - players name string
-- @return nothing
local function initialise_stats(name)
	stats.player = stats.player or {}
	if not stats.player[name] then
		stats.player[name] = {
			damage = 0,
			eggs = 0,
			falls = 0,
			kills = 0,
			pb = {
				time = 0, -- utc
				kills = 0,
				falls = 0,
				damage = 0
			},
			plays = 0,
			rank = 0,
			wins = 0,
		}
	end
end

--- Displays match results as a formspec
-- @param match_rank - table of ranked match players
-- @param arena_id - integer index of arena
-- @return nothing
local function display_match_results(match_rank, arena_id)
	local get_player_by_name = minetest.get_player_by_name
	local fs = {
		'size[8,6]',
		'label[0,0;Rank]',
		'label[1,0;Name]',
		'label[4,0;Kills]',
		'label[5,0;Points]',
		'label[6.1,0;Eggs]',
		'label[7,0;Falls]'
	}
	for i, v in ipairs(match_rank) do
		local c = eggwars.arena[arena_id].colour[v.id]
		fs[#fs + 1] = 'label[0,'..(0.5 * i)..';'..eggwars.colorize(c, i)..']'
		fs[#fs + 1] = 'label[1,'..(0.5 * i)..';'..eggwars.colorize(c, v.name)..']'
		fs[#fs + 1] = 'label[4,'..(0.5 * i)..';'..eggwars.colorize(c, v.kills)..']'
		fs[#fs + 1] = 'label[5,'..(0.5 * i)..';'..eggwars.colorize(c, v.damage)..']'
		fs[#fs + 1] = 'label[6.1,'..(0.5 * i)..';'..eggwars.colorize(c, v.eggs)..']'
		fs[#fs + 1] = 'label[7,'..(0.5 * i)..';'..eggwars.colorize(c, v.falls)..']'
	end
	fs[#fs + 1] = 'button_exit[3,5;2,1;btn_e;OK]'
	local res = table.concat(fs)
	for i, v in ipairs(match_rank) do
		local player = get_player_by_name(v.name)
		if player then
			minetest.show_formspec(v.name, '', res)
		end
	end
end

--- Displays stats as a formspec
-- @param name - name of player requesting info
-- @return nothing
local function display_stats(name)
	local fs = {
		'size[9,7]',
		'label[0,0;Rank]',
		'label[1,0;Name]',
		'label[4,0;Wins]',
		'label[5,0;Kills]',
		'label[6,0;Points]',
		'label[7.1,0;Eggs]',
		'label[8,0;Falls]'
	}
	for i,v in ipairs(stats.rankings) do
		local c = 'lime'
		fs[#fs + 1] = 'label[0,'..(0.5 * i)..';'.. minetest.colorize(c, i) ..']'
		fs[#fs + 1] = 'label[1,'..(0.5 * i)..';'.. minetest.colorize(c, v.name) ..']'
		fs[#fs + 1] = 'label[4,'..(0.5 * i)..';'.. minetest.colorize(c, v.wins) ..']'
		fs[#fs + 1] = 'label[5,'..(0.5 * i)..';'.. minetest.colorize(c, v.kills) ..']'
		fs[#fs + 1] = 'label[6,'..(0.5 * i)..';'.. minetest.colorize(c, v.damage) ..']'
		fs[#fs + 1] = 'label[7.1,'..(0.5 * i)..';'.. minetest.colorize(c, v.eggs) ..']'
		fs[#fs + 1] = 'label[8,'..(0.5 * i)..';'.. minetest.colorize(c, v.falls) ..']'
		if i == 10 then break end
	end
	fs[#fs + 1] = 'button_exit[3.5,6;2,1;btn_e;OK]'
	local res = table.concat(fs)
	local player = minetest.get_player_by_name(name)
	if player then
		minetest.show_formspec(name, '', res)
	end
end

--- Updates match players game time hud display every minute
-- @return nothing
local function update_hud_time()
	for key, match in pairs(eggwars.match) do
		match.hud_time = match.hud_time - 1
		eggwars.update_hud(key)
	end
	minetest.after(60, update_hud_time)
end

--- Spawns a player in the first pair of vertical air nodes above minp
-- @return vector
local function safe_spawn(minp)
	local maxp = vector.new(minp.x, minp.y + 20, minp.z)
	local pos = minetest.find_nodes_in_area(minp, maxp, 'air')
	local res = minp
	for i, v in ipairs(pos) do
		if i > 1 and res.y == v.y - 1 then
			return res -- 2 vertical air nodes
		else
			res = v
		end
	end
	return minp -- failed search
end

--- Removes a player from a match
-- @param name - player name strings
-- @return nothing
local function remove_match_player(name)
	if eggwars.player[name] then
		local key, match, player, count
		key = eggwars.player[name]
		match = eggwars.match[key]
		player = match.player[name]
		if match.alive == 1 then
			eggwars.end_match(key)
		else
			if player.egg then
				minetest.remove_node(player.eggpos)
			end
			remove_player_hud(name)
			count = match.alive - 1
			match.alive = count
			match.player[name].alive = false
			match.player[name].egg = false
			eggwars.match[key] = match
			eggwars.player[name] = nil
			player = minetest.get_player_by_name(name)
			player:set_pos(lobby.pos)
			local msg = name .. " quit the match!"
			eggwars.chat_send_match(key, msg)
		end
	end
end

--- Return length of a keypair table
-- @param list - keypair table
-- @return integer
local function list_count(list)
	local count = 0
	for k, _ in pairs(list) do
		count = count + 1
	end
	return count
end

-------------------
-- API Functions --
-------------------

--- Removes a temp player hud image
-- @param name - players name
-- @return nothing
eggwars.remove_tmp_image = function(name)
	if tmp_hud[name] then
		local player = minetest.get_player_by_name(name)
		player:hud_remove(tmp_hud[name])
		tmp_hud[name] = nil
	end
end

--- Update match status in players HUD
-- @param key - arena key string
-- @param id - hud element index, if omitted time is updated
-- @return nothing
eggwars.update_hud = function(key, id)
	local match = eggwars.match[key]
	for k, def in pairs(match.player) do
		local obj = minetest.get_player_by_name(k)
		if not id then
			obj:hud_change(def.remaining, 'text', 'Remaining: ' ..
			eggwars.match[key].hud_time .. 'm')
		else
			obj:hud_change(def.hud_id[id], 'text', match.hud_img[id][2])
		end
	end
end

--- Reset arena by index
-- @param arena integer index of registered arena
-- @param n integer index of arena instance
-- @return nothing
eggwars.reset = function(arena, n)
	local def = eggwars.arena[arena]
	local pos = arena_pos[n]
	local p1 = vector.add(pos, def.region.p1)
	local p2 = vector.add(pos, def.region.p2)
	clean(p1, p2)
end

--- Spawn hub islands for an arena instance
-- @param arena integer index of registered arena
-- @param n integer index of arena
-- @return nothing
eggwars.centrespawn = function(id, n)
	local def = eggwars.arena[id]
	local spwn = arena_pos[n]
	local p1 = vector.add(spwn, def.hub.offset)
	minetest.place_schematic(p1, schempath .. def.hub.schem)
	-- place satellites
	for i, v in ipairs(def.satellite.pos) do
		p1 = vector.add(vector.add(spwn, v), def.satellite.offset)
		minetest.place_schematic(p1, schempath ..
		def.satellite.schem)
	end
end

--- Spawn island at pos, indexed by n
-- @param arena integer index of registered arena
-- @param pos vector table
-- @param n integer index of island coords
-- @return spawn vector
eggwars.islandspawn = function(arena, pos, n)
	local def = eggwars.arena[arena].island
	local p1 = vector.add(pos, def.offset)
	minetest.place_schematic(p1, schempath .. def.schem, def.rotate[n])
	return pos
end

--- Creates & protects an arena type in the world
-- @param id - arena index
-- @param n - arena position indexeggwars.match[key]
-- @return nothing
eggwars.create_arena = function(id, n)
	local def = eggwars.arena[id]
	local pos = arena_pos[n]
	eggwars.centrespawn(id, n)
	for i = 1, #def.island do
		local sp = vector.add(pos, def.island[i])
		eggwars.islandspawn(id, sp, i)
	end
	local v = {
		p1 = vector.add(pos, def.region.p1),
		p2 = vector.add(pos, def.region.p2)
	}
	eggwars.protect(v.p1, v.p2, false)
end

--- Deletes an arena from the world
-- @param id - arena index
-- @param n - arena position index
-- @return nothing
eggwars.delete_arena = function(arena, n)
	local def = eggwars.arena[arena]
	local pos = arena_pos[n]
	local v = {
		p1 = vector.add(pos, def.region.p1),
		p2 = vector.add(pos, def.region.p2)
	}
	eggwars.reset(arena, n)
	eggwars.delete_area(v.p1, v.p2)
end

--- Creates a match instance from registered_players table
-- @return nothing
eggwars.begin_match = function ()
	-- A match consists of an instance of a registered arena between 4-8 players
	-- match.alive - players alive count
	-- match.arena - registered arena index
	-- match.hud_img - egg images table
	-- match.hud_time - remaining time in minutes
	-- match.id - arena instance index
	-- match.player[name]
	--		alive = bool status
	--		color = {r,g,b}
	--		damage = hp damage
	--		egg = bool - false if dug
	--		eggpos = pos of players egg
	--		eggs = eggs destroyed count
	--		falls = fall count
	--		hud_id = hud element ref table
	--		id = integer - player index in the instance
	--		kills = kill count
	--		rate = gold spawner rate in seconds
	--		shop_items = table of available items
	--		spawn = spawn point
	--		spawner = pos of gold spawner
	--		trader = entity obj
	--
	-- match.spawners - diamond and ruby spawner positions
	-- match.stats - match statistics
	-- match.tmr - match timer
	-- match.uid - match id


	local match = {}
	local n = next_index() -- arena pos index
	local pos = arena_pos[n] -- base vector
	local arena, def, rnd_list, key, spwnr, adj, hud_img, uid

	uid = os.time()

	-- Load nonexistant arena into the map or use saved type
	if not loaded.arena[n] then
		arena = math.random(1, #eggwars.arena)
		def = {
			arena = arena,
			pos = pos,
			id = n
		}
		eggwars.create_arena(arena, n)
		loaded.arena[n] = def
	else
		arena = loaded.arena[n].arena
	end

	def = eggwars.arena[arena]
	rnd_list = gen_trader_order()
	key = 'm' .. n

	match.alive = #registered_players
	match.arena = arena
	match.id = n
	match.player = {}
	match.spawners = {}
	match.uid = uid
	match.hud_img = {}

	for id, name in ipairs(registered_players) do

		local player = minetest.get_player_by_name(name)
		local sp = vector.add(pos, def.island[id])
		local colour = def.colour[id]

		adj = sp
		spwnr = def.spawners.gold.rate
		eggwars.player[name] = key

		hud_img = {}
		hud_img[1] = ('eggwars_%s.png'):format(def.cs[id][3])
		hud_img[2] = ('eggwars_out_%s.png'):format(def.cs[id][3])
		table.insert(match.hud_img, hud_img)

		match.player[name] = {}
		match.player[name].alive = true
		match.player[name].color = colour
		match.player[name].damage = 0
		match.player[name].egg = true
		match.player[name].eggs = 0
		match.player[name].falls = 0
		match.player[name].hud_id = {}
		match.player[name].id = id
		match.player[name].kills = 0
		match.player[name].rate = spwnr
		match.player[name].shop_items = {}
		match.player[name].spawn = sp

		initialise_stats(name)

		player:set_nametag_attributes({color = colour})
		adj.y = adj.y + 2

		player:set_pos(adj) -- set player position first

		-- Add gold spawner and initialise node timer
		adj = vector.add(sp, def.spawners.gold[id])
		minetest.set_node(adj, {name = 'eggwars:gold_spawner'})
		minetest.get_node_timer(adj):start(spwnr)
		match.player[name].spawner = adj

		-- Add spawner bot
		adj = vector.add(sp, def.bot.offset[id])
		local staticdata = minetest.serialize({uid = uid, owner = name})
		local obj = minetest.add_entity(adj, 'eggwars:bot', staticdata)
		local yaw = ((math.pi * def.bot.yaw[id]) / 180)
		obj:set_yaw(yaw)

		-- Add egg
		adj = vector.add(sp, def.egg_offset[id])
		minetest.set_node(adj, {name = 'eggwars:egg' .. id})
		match.player[name].eggpos = adj

		-- set egg metadata
		local meta = minetest.get_meta(adj)
		meta:set_string('owner', name)
		meta:set_string('infotext', name .. "'s egg")

		-- Add trader
		local trader_name = 'Trader '.. def.trader.names[rnd_list[id]]
		staticdata = minetest.serialize({owner = name, nametag = trader_name, uid = uid})
		adj = vector.add(sp, def.trader.offset[id])
		obj = minetest.add_entity(adj, 'eggwars:trader', staticdata)
		yaw = ((math.pi * def.trader.yaw[id]) / 180)
		obj:set_yaw(yaw)

		-- Create players shop items table
		match.player[name].shop_items = {
			-- Add players wool colour
			{
				name = {
					name = "wool:" .. def.cs[id][3],
					count = 20,
					wear = 0,
					metadata = ""
				},
				description = def.cs[id][1] .. " Wool",
				image = 'wool_' .. def.cs[id][3] .. '.png',
				cost = {name = "default:gold_ingot", count = 5, wear = 0, metadata = ""},
				entry = 0,
			}
		}
		-- Add the registered shop items
		for j = 1, #eggwars.shop_items do -- add the rest
			table.insert(match.player[name].shop_items, eggwars.shop_items[j])
		end

		-- Give arena privs
		minetest.set_player_privs(name, {interact = true, shout = true})

	end

	-- Diamond spawners
	spwnr = def.spawners.diamond.rate
	for idx, v in ipairs(def.spawners.diamond) do
		adj = vector.add(pos, v)
		minetest.set_node(adj, {name = 'eggwars:diamond_spawner'})
		minetest.get_node_timer(adj):start(spwnr)
		table.insert(match.spawners, adj)
	end

	-- Ruby spawners
	spwnr = def.spawners.ruby.rate
	for idx, v in ipairs(def.spawners.ruby) do
		adj = vector.add(pos, v)
		minetest.set_node(adj, {name = 'eggwars:ruby_spawner'})
		minetest.get_node_timer(adj):start(spwnr)
		table.insert(match.spawners, adj)
	end

	-- initialise match timer vars
	match.tmr = 0
	match.max_time = def.timer.max_time
	match.hud_time = match.max_time / 60 -- minutes
	match.suddendeath = def.timer.suddendeath

	-- store match
	eggwars.match[key] = match

	-- Add hud to match players
	gen_match_hud(key)

	-- persist dirty state in case of crash
	reload = true
	save_persistant()

	registered_players = {} -- reset
end

--- Ends and cleans up a match instance
-- @param key - match key string
-- @return nothing
eggwars.end_match = function(key)

	local def = eggwars.match[key]
	local match_rank = {}
	local windex

	remove_match_hud(key)
	eggwars.match[key].uid = 0

	for _, pos in ipairs(def.spawners) do
		minetest.get_node_timer(pos):stop()
		local w = minetest.get_objects_inside_radius(pos, 2)
		for _, obj in ipairs(w) do
			if not obj:is_player() then
				obj:remove()
			end
		end
		minetest.remove_node(pos)
	end

	for name, pdef in pairs(def.player) do
		--stop island spawner
		minetest.get_node_timer(pdef.spawner):stop()
		-- remove objects on gold spawner
		local w = minetest.get_objects_inside_radius(pdef.spawner, 2)
		for _, obj in ipairs(w) do
			if not obj:is_player() then
				obj:remove()
			end
		end
		-- remove spawner node
		minetest.remove_node(pdef.spawner)
		-- Update stats
		local s = stats.player[name]
		s.kills = s.kills + pdef.kills
		s.falls = s.falls + pdef.falls
		s.damage = s.damage + pdef.damage
		s.plays = s.plays + 1

		if pdef.win then
			s.wins = s.wins + 1
		end

		-- rank match player
		local res = {
			damage = pdef.damage,
			eggs = pdef.eggs,
			falls = pdef.falls,
			id = pdef.id, -- colour ref
			kills = pdef.kills,
			name = name,
			win = pdef.win or false
		}
		local idx = #match_rank + 1

		for i, v in ipairs(match_rank) do
			if v.win then windex = i end
			if res.kills > v.kills then
				idx = i
				break
			end
		end
		table.insert(match_rank, idx, res)

		local player = minetest.get_player_by_name(name)
		if player then
			-- reset spectator
			if not pdef.alive then
				minetest.sound_play("eggwars_game_over", {
					to_player = name,
					gain = 0.5
				})
				player:set_nametag_attributes({
				color = {a = 255, r = 255, g = 255, b = 255}}) --Make nametag visible
				player:set_properties({visual_size = {x = 1, y = 1, z = 1}}) --Make player visible
			else
				-- reset player
				if eggwars.armor then eggwars.clear_armor(player) end
				eggwars.clear_inventory(player)
				if pdef.win then
					minetest.chat_send_all(minetest.colorize(
						"green", "*** " .. name .. " won their match!")
					)
					add_tmp_image(player, 'eggwars_winner.png', 5)
					minetest.sound_play("eggwars_winner", {
						to_player = pdef.name,
						gain = 0.5
					})
				end
			end
			minetest.set_player_privs(name, {shout = true}) -- set lobby privs
			player:set_pos(lobby.pos) -- move player
		end
		stats.player[name] = s
		eggwars.player[name] = nil
	end

	-- rank winner
	local tmp

	if windex then
		tmp = match_rank[windex]
		table.remove(match_rank, windex)
		table.insert(match_rank, 1, tmp)
	else
		tmp = match_rank[1]
	end

	local rank = {
		damage = tmp.damage,
		eggs = tmp.eggs,
		falls = tmp.falls,
		kills = tmp.kills,
		name = tmp.name,
		wins = stats.player[tmp.name].wins
	}
	table.insert(stats.rankings, rank)
	if #stats.rankings > 1 then
		table.sort(stats.rankings, function(a, b) return a.wins > b.wins end)
		if #stats.rankings > 20 then
			table.remove(stats.rankings, #stats.rankings)
		end
	end

	eggwars.reset(def.arena, def.id)

	-- remove match
	eggwars.match[key] = nil
	-- check if this is the last match
	if list_count(eggwars.match) == 0 then reload = false end
	-- store data
	save_persistant()
	-- finally
	display_match_results(match_rank, def.arena)
end

--- Colour a message string using rgb
-- @param rgb - rgb table
-- @param msg - string to colour
-- @return a minetest colorized string
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

--- Broadcast match chat
-- @return nothing
eggwars.chat_send_match = function(key, msg)
	local def = eggwars.match[key].player
	for name, _ in pairs(def) do
		minetest.chat_send_player(name, msg)
	end
end

-----------------------------------------
-- Registered chat commands   --
-----------------------------------------
minetest.register_chatcommand('admin', {
description = 'gamehub management tool',
params = '{load|save} [name]',
func = function(name, param)
	-- secure access
	if not minetest.get_player_privs(name).server and name == owner then
		return false, "Insufficient privs!"
	end

	local cmd, fn, pos1, pos2, helper, list, player

	helper = [[Usage:
		/admin load <filename>
		/admin save <filename> <pos1> <pos2>
		]]

	list = {}
	player = minetest.get_player_by_name(name)

	if not player then
		return false, "You need to be playing to use this command!"
	end

	for word in param:gmatch("%S+") do
		list[#list + 1] = word
	end
	local qty = #list
	if qty < 2 or qty == 3 or qty > 4 then
		return false
	elseif qty == 4 then
		pos1 = minetest.string_to_pos(list[3])
		pos2 = minetest.string_to_pos(list[4])
	end

	cmd = list[1]
	fn = list[2]

	if cmd == 'load' then

		-- last entry takes precedence
		local folders = {
			MP .. "/schems/", -- read-only
			WP .. "/schems/"
		}

		local path, folder, file, err, msg

		msg = {}

		for i, v in ipairs(folders) do

			local check = check_files(v, fn)

			if check.n > 0 then

				folder = v
				msg[#msg + 1] = "file(s) found in " .. v

			elseif check.n == 0 then
				msg[#msg + 1] = "no match found in " .. v
			end

			minetest.chat_send_player(name, table.concat(msg, "\n"))

			check.n = nil -- reset

		end

		if not folder then return end

		path = folder .. fn .. ".mts"

		-- add mts using player current pos
		local pos = vector.round(player:get_pos())

		err = minetest.place_schematic(pos, path, nil, nil, true)

		if err == nil then
			minetest.chat_send_player(name, "could not open file " .. path)
			return
		end

		-- add nodes with metadata
		path = folder .. fn .. ".ewm"
		file, err = io.open(path, "rb")

		if err then
			minetest.chat_send_player(name, "could not open meta file "
			.. fn .. ".ewm")
			return
		end

		local value = file:read("*a")
		file:close()

		local count = eggwars.deserialize(pos, value)

		minetest.chat_send_player(name, "replaced " .. count ..
		" nodes...")

	elseif cmd == 'save' then

		-- serialize metadata
		local result, count = eggwars.serialize_meta(pos1, pos2)
		local path = WP .. "/schems"
		local filename = path .. "/" .. fn .. ".ewm"

		if count > 0 then

			local file, err = io.open(filename, "wb")

			if err ~= nil then
				minetest.log(name, "Could not save file to \"" .. filename .. "\"")
				return
			end

			file:write(result)
			file:flush()
			file:close()

			minetest.chat_send_player(name, "Saved " .. count ..
			" nodes to \"" .. filename .. "\"")
		end

		-- create schematic
		filename = path .. "/" .. fn .. ".mts"
		minetest.create_schematic(pos1, pos2, nil, filename)

		minetest.chat_send_player(name, "Saved \"" .. filename .. "\"")

	else
		return true, helper
	end
end
})

-- register for a match
minetest.register_chatcommand("r", {
params = "",
description = "Join match",
func = function(name, param)
	if #registered_players < 8 then -- max 8 players in a match
		if #eggwars.match < 8 then -- max 8 matches on the server
			for i, v in ipairs(registered_players) do
				if registered_players[i] == name then
					return true, "You have already registered"
				end
			end
			eggwars.remove_tmp_image(name)
			registered_players[#registered_players + 1] = name

			if #registered_players == 8 then
				eggwars.begin_match();
			else
				minetest.chat_send_all(#registered_players ..
				"/8 players have registered! Use /register to join.");
			end
		else
			return true, "Sorry the max number of games are running." ..
			"Please use /start once a match finishes."
		end
	else
		return true, "Sorry. 8 players have already registered." ..
		"Try registering after their game has begun."
	end
end,
})

-- start match
minetest.register_chatcommand("s", {
params = "",
description = "Starts match if min match players is satisfied",
func = function(name, param)
	if #registered_players >= min_match_players or name == owner then
		eggwars.begin_match()
	end
end
})

-- quit match
minetest.register_chatcommand("q", {
params = "",
description = "Quit the match you are playing",
func = function(name, param)
	-- queued?
	if #registered_players > 0 then
		local idx
		for i, v in ipairs(registered_players) do
			if v.name == name then
				idx = i
				break
			end
		end
		table.remove(registered_players, idx)
		return true, "you have been removed from the queue!"
	end
	remove_match_player(name)
end
})

-- show stats formspec
minetest.register_chatcommand("stats", {
params = "",
description = "Shows server game statistics",
func = function(name, param)
	display_stats(name)
end
})

-- end match - development
minetest.register_chatcommand("e", {
params = "",
description = "End the game",
func = function(name, param)
	if name == owner then
		local key = eggwars.player[name]
		if key then
			eggwars.end_match(key)
		end
	end
end
})

-- list players
minetest.register_chatcommand("who", {
params = "",
description = "List players in matches",
func = function(name, param)
	local text = {}
	for k, v in pairs(eggwars.match) do
		text[#text + 1] = "Players in match: " .. k .. " "
		for key, def in pairs(v.player) do
			text[#text + 1] = eggwars.colorize(def.color, key)
		end
		text[#text + 1] = '\n'
	end
	return true, table.concat(text)
end
})

-------------------------------------
-- Registered callbacks   --
-------------------------------------

minetest.register_on_dieplayer(function(player, reason)

	local name = player:get_player_name()
	local key = eggwars.player[name]
	local def = eggwars.match[key]

	if def then
		if def.player[name].alive and not def.player[name].egg then
			minetest.chat_send_all("*** "..name.." is " ..
			minetest.colorize('red', 'OUT'))

			-- set privs for spectating
			minetest.set_player_privs(name, {fly = true, fast = true, shout = true})
			add_tmp_image(player, 'eggwars_out.png', 5)

			-- record the kill
			local killer
			if reason.object then
				killer = reason.object:get_player_name()
				local upd = def.player[killer].kills + 1
				def.player[killer].kills = upd
			end

			-- Make nametag invisible
			player:set_nametag_attributes({color = {a = 0, r = 0, g = 0, b = 0}})
			player:set_properties({visual_size = {x = 0, y = 0}}) --Make player invisible

			if eggwars.armor then eggwars.clear_armor(player) end
			def.player[name].alive = false
			def.alive = def.alive - 1

			eggwars.clear_inventory(player)

			eggwars.match[key] = def

			eggwars.update_hud(key, def.player[name].id)

			-- Are we down to 1 player alive yet?
			if def.alive == 1 then
				def.player[killer].win = true
				eggwars.end_match(key)
			end
		else
			-- Clean inventory & announce
			eggwars.clear_inventory(player)
			minetest.chat_send_all("*** " ..
			name.." paid Hades a visit and was revived by their egg.")
		end
	end
end)

minetest.register_on_respawnplayer(function(player)
	local name = player:get_player_name()
	local pos = lobby.pos -- initialise with lobby vector
	-- match override
	if eggwars.player[name] then
		local key = eggwars.player[name]
		local match = eggwars.match[key]
		pos = match.player[name].spawn
	end
	player:set_pos(safe_spawn(pos))
	return true
	-- Wait for respawn before moving
	--minetest.after(0.1, function () player:set_pos(pos) end)
end)

minetest.register_on_joinplayer(function(player)
	-- handle the player - no items or interact in the hub
	if eggwars.armor then eggwars.clear_armor(player) end
	eggwars.clear_inventory(player)
	local name = player:get_player_name()
	minetest.set_player_privs(name, {shout = true}) --
	player:set_pos(lobby.pos)
	add_tmp_image(player, 'eggwars_welcome.png', 10)
end)

minetest.register_on_leaveplayer(function(player)
	-- Handle players exiting during a match
	local name = player:get_player_name()
	remove_match_player(name)
	if tmp_hud[name] then tmp_hud[name] = nil end
end)

minetest.register_on_chat_message(function(name, message)
	-- Let's colour the chat!
	local txt = "<" .. name .. "> " .. message
	if eggwars.player[name] then
		local key = eggwars.player[name]
		local def = eggwars.match[key]
		txt = eggwars.colorize(def.player[name].color, message)
		eggwars.chat_send_match(key, txt)
	else
		-- player in lobby
		minetest.chat_send_all(txt) -- broadcast
	end
	return true -- return as handled!
end)

minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if player then
		local name = player:get_player_name()
		local key = eggwars.player[name]
		local match = eggwars.match[key]
		if eggwars.player[name] and reason.object then
			local pname = reason.object:get_player_name()
			local damage = match.player[pname].damage - hp_change
			eggwars.match[key].player[pname].damage = damage
		elseif eggwars.player[name] and reason.type == 'fall' then
			local falls = match.player[name].falls + 1
			eggwars.match[key].player[name].falls = falls
		end
	end
end, false)

-- run functions after all mods are loaded!
minetest.after(0, modify_game)
minetest.after(0, set_settings)
minetest.after(0, match_timer)
minetest.after(0, update_hud_time)

minetest.log('action', '[LOADED] Eggwars mod')
