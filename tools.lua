----------------------------------------------------------------------
-- Eggwars by wilkgr																								--
-- with additional code by shivajiva101@hotmail.com		              --
-- Licensed under the AGPL v3                                       --
-- You MUST make any changes you make open source                   --
-- even if you just run it on your server without publishing it     --
-- Supports a maximum of 8 players per instance and 8 concurrent    --
-- instances for a max of 64 players                                --
----------------------------------------------------------------------

minetest.register_tool("eggwars:pick_rainbow", {
	description = "Rainbow Pickaxe",
	range = 20,
	inventory_image = "eggwars_rainbowpick.png",
	groups = {not_in_creative_inventory = 1},
	tool_capabilities = {
		full_punch_interval = 0.1,
		max_drop_level = 3,
		groupcaps = {
			unbreakable = {times = {[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
			fleshy = {times = {[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
			choppy = {times = {[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
			bendy = {times = {[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
			cracky = {times = {[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
			crumbly = {times = {[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
			snappy = {times = {[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
		},
		damage_groups = {fleshy = 1000},
	},
	on_drop = eggwars.drop_msg,
})

minetest.register_alias('pick', 'eggwars:pick_rainbow')
