----------------------------------------------------------------------
-- Eggwars by wilkgr																								--
-- with additional code by shivajiva101@hotmail.com		              --
-- Licensed under the AGPL v3                                       --
-- You MUST make any changes you make open source                   --
-- even if you just run it on your server without publishing it     --
-- Supports a maximum of 8 players per instance and 8 concurrent    --
-- instances for a max of 64 players                                --
----------------------------------------------------------------------

-- default arena definition template, all fields reqd
local default_arena = {
	blocked_recipes = {
		-- Recipes removed from world for gameplay so player MUST purchase items
		{output = 'default:stick'}, -- tools
		{output = '3d_armor:boots_wood'},
		{output = '3d_armor:helmet_wood'},
		{output = '3d_armor:leggings_wood'},
		{output = '3d_armor:chestplate_wood'},
		{output = '3d_armor:boots_diamond'},
		{output = '3d_armor:helmet_diamond'},
		{output = '3d_armor:leggings_diamond'},
		{output = '3d_armor:chestplate_diamond'},
	},
	bot = {
		-- spawner upgrade bot
		offset = {
			{x=-2, y=0, z=-4}, -- relative to island origin
			{x=2, y=0, z=4},
			{x=-2, y=0, z=-4},
			{x=2, y=0, z=4},
			{x=-4, y=0, z=2},
			{x=-4, y=0, z=2},
			{x=4, y=0, z=-2},
			{x=4, y=0, z=-2}
		},
		yaw = {90,270,90,270,0,0,180,180} -- facing
	},
  colour = {
		-- rgb colour tables
    {r = 0, g = 0, b = 255}, -- Blue
    {r = 0, g = 255, b = 0}, -- Green
    {r = 255, g = 0, b = 0}, -- Red
    {r = 108, g = 0, b = 255}, -- Purple
    {r = 255, g = 255, b = 0}, -- Yellow
    {r = 0, g = 255, b = 255}, -- Cyan
    {r = 255, g = 150, b = 0}, -- Orange
    {r = 255, g = 0, b = 255} -- Pink
  },
	cs = {
		-- colour strings used by mod
		{"Blue", "#0000FFBF", "blue", "0x0000FF"},
		{"Green", "#00FF00BF", "green", "0x00FF00"},
		{"Red", "#FF0000BF", "red", "0xFF0000"},
		{"Violet", "#7800FFBF", "violet", "0x7800FF"},
		{"Yellow", "#FFFF00BF", "yellow", "0xFFFF00"},
		{"Cyan", "#00FFFFBF", "cyan", "0x00FFFF"},
		{"Orange", "#FF9600BF", "orange", "0xFF9600"},
		{"Pink", "#FF00FFBF", "pink", "0xFF00FF"}
	},
	description = 'default arena by shivajiva',
  egg_offset = {
    {x=-5, y=0, z=0}, -- relative to island origin
    {x=5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0},
    {x=-5, y=0, z=0}
  },
	exempt_nodes = {
		-- exempt nodes you want breakable within the world
		-- partial strings allowed
		'eggwars:',
		'wool:', -- bridging block
		'default:obsidian_block' -- requires pick
	},
  hub = {
		-- arena hub def
    offset = {x=-30, y=-18, z=-30}, -- pos1 for place
		schem = 'hub_1.mts'
  },
  island = {
		-- Confined to 90 degree rotations the current schema
	  -- places 2 islands per side of a square, giving us 8
	  -- islands max per instance. Each island is displaced
	  -- equally from the arena centre position using the
	  -- island vector table
    {x=85, y=0, z=-40}, -- BL
    {x=-85, y=0, z=-40}, -- TL
    {x=85, y=0, z=40}, -- BR
    {x=-85, y=0, z=40}, -- TR
    {x=40, y=0, z=-85}, -- LB
    {x=-40, y=0, z=-85}, -- LT
    {x=40, y=0, z=85}, -- RB
    {x=-40, y=0, z=85}, -- RT
    offset = {x=-11, y=-20, z=-10},
		rotate = {"0", "180", "0", "180", "90", "90", "270", "270"},
		schem = 'island_1.mts'
  },
	name = 'default', -- arena name
  region = {
		-- arena region relative to origin
    p1 = {x=-120, y=-30, z=-120},
    p2 = {x=120, y=100, z=120}
  },
	register_nodes = {
		-- add any arena specific custom nodes here, generally
		-- these are the nodes the player can use in the arenas
		-- and should contain nodes not previously registered by
		-- other arenas.
		-- name = {normal node def}
		['log'] = {
			description = "Log",
			tiles = {"default_tree_top.png", "default_tree_top.png", "default_tree.png"},
			paramtype2 = "facedir",
			is_ground_content = false,
			groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
			sounds = default.node_sound_wood_defaults(),
			on_place = minetest.rotate_node
		},
	},
	satellite = {
		-- satellite ruby spawner island positions relative to origin
		offset = {x=-5, y=-13, z=-5},
		pos = {
			{x=-65, y=0, z=0}, -- N
			{x=0, y=0, z=65}, -- E
			{x=65, y=0, z=0}, -- S
			{x=0, y=0, z=-65} -- W
		},
		schem = 'island_small_1.mts'
	},
  spawners = {
		-- centre
    diamond = {
			{x=9, y=4, z=-9}, -- relative to arena origin
			{x=-9, y=4, z=9},
			{x=-9, y=4, z=-9},
			{x=9, y=4, z=9},
			rate = 30
		},
		-- player island
    gold = {
      {x=-3, y=-1, z=-4}, -- relative to island origin
      {x=3, y=-1, z=4},
      {x=-3, y=-1, z=-4},
      {x=3, y=-1, z=4},
      {x=-4, y=-1, z=3},
      {x=-4, y=-1, z=3},
      {x=4, y=-1, z=-3},
      {x=4, y=-1, z=-3},
			rate = 5 -- starting rate in seconds
    },
		-- satellites
    ruby = {
			{x=65, y=0.5, z=0}, -- relative to arena origin
			{x=0, y=0, z=65},
			{x=-65, y=0, z=0},
			{x=0, y=0, z=-65},
			rate = 15
		},
  },
	timer = {
		max_time = 1800, -- seconds
		suddendeath = 1200 -- seconds
	},
  trader = {
		names = {
			"Johann",
			"Celery55",
			"Moldy Coder",
			"Wilkgr",
			"Rick O Shae",
			"Bernie Towndown",
			"Warden Ruby",
			"Bom Shiva"
		},
		offset = {
			{x=2, y=0.5, z=0}, -- relative to island origin
	    {x=-2, y=0.5, z=0},
	    {x=2, y=0.5, z=0},
	    {x=-2, y=0.5, z=0},
	    {x=0, y=0.5, z=2},
	    {x=0, y=0.5, z=2},
	    {x=0, y=0.5, z=-2},
	    {x=0, y=0.5, z=-2}
		},
		yaw = {90,270,90,270,0,0,180,180} -- facing
  },
}

eggwars.register_arena = function(def)
	table.insert(eggwars.arena, def)
	for k,v in pairs(def.register_nodes) do
		minetest.register_node('eggwars:' .. k, v)
	end
end

-- Register the sample default arena
eggwars.register_arena(default_arena)
