minetest.register_node("eggwars:egg", {
	description = "Egg",
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
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1875, -0.5, -0.1875, 0.1875, 0.5, 0.1875}, -- NodeBox1
			{-0.25, -0.4375, -0.25, 0.25, 0.4375, 0.25}, -- NodeBox2
			{-0.3125, -0.375, -0.3125, 0.3125, 0.3125, 0.3125}, -- NodeBox3
			{-0.375, -0.3125, -0.375, 0.375, 0.1875, 0.375}, -- NodeBox4
			{-0.4375, -0.25, -0.4375, 0.4375, 0.0625, 0.4375}, -- NodeBox5
			{-0.5, -0.125, -0.5, 0.5, -0.0625, 0.5}, -- NodeBox6
		}
	}
})

minetest.register_node("eggwars:dirt", {
	description = "Unbreakable Dirt",
	range = 12,
	stack_max = 99,
	tiles = {"default_dirt.png"},
	drop = "",
	groups = {unbreakable = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("eggwars:grass", {
	description = "Unbreakable Dirt With Grass",
	range = 12,
	stack_max = 10000,
	tiles = {"default_grass.png", "default_dirt.png", "default_dirt.png^default_grass_side.png"},
	paramtype2 = "facedir",
	drop = "",
	groups = {unbreakable = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain = 0.4},
	}),
})

minetest.register_node("eggwars:stone_block", {
	description = "Unbreakable Stone Block",
	range = 12,
	tiles = {"default_stone_block.png"},
	is_ground_content = false,
	drop = "",
	groups = {unbreakable = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("eggwars:aspen_wood", {
	description = "Unbreakable Aspen Planks",
	range = 12,
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_aspen_wood.png"},
	drop = "",
	is_ground_content = false,
	groups = {unbreakable = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("eggwars:acacia_wood", {
	description = "Acacia Wood Planks",
	range = 12,
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_acacia_wood.png"},
	drop = "",
	is_ground_content = false,
	groups = {unbreakable = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("eggwars:ladder_wood", {
	description = "Wooden Ladder",
	drawtype = "signlike",
	tiles = {"default_ladder_wood.png"},
	inventory_image = "default_ladder_wood.png",
	wield_image = "default_ladder_wood.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	climbable = true,
	is_ground_content = false,
	selection_box = {
		type = "wallmounted",
	},
    drop = "",
	groups = {unbreakable = 1, not_in_creative_inventory = 1},
	legacy_wallmounted = true,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("eggwars:goldspawn1", {
  tiles = {"default_gold_block.png"}
})

minetest.register_node("eggwars:stickspawn", {
  tiles = {"default_aspen_wood.png"}
})

minetest.register_node("eggwars:diamondspawn", {
  tiles = {"default_diamond_block.png"}
})

minetest.register_node("eggwars:steelspawn1", { --Slower spawn rate; for player islands
  tiles = {"default_steel_block.png"}
})

minetest.register_node("eggwars:steelspawn2", { --Faster spawn rate; for center island(s)
  tiles = {"default_diamond_block.png"}
})

minetest.register_node("eggwars:cobblespawn", {
  tiles = {"default_cobble.png"}
})

-- Register ABMs

-- Diamond spawn. Only for centre island(s)
minetest.register_abm({
	nodenames = {"eggwars:diamondspawn"},
	interval = 8,
	chance = 1,
	action = function(pos)
		pos.y = pos.y + 1
		minetest.add_item(pos,"default:diamond")
	end,
})

-- Cobble is the building material
minetest.register_abm({
	nodenames = {"eggwars:cobblespawn"},
	interval = 5,
	chance = 1,
	action = function(pos)
		pos.y = pos.y + 1
		minetest.add_item(pos,"default:cobble")
	end,
})

-- Steelspawn1 is slower, ideal for player islands
minetest.register_abm({
	nodenames = {"eggwars:steelspawn1"},
	interval = 10,
	chance = 1,
	action = function(pos)
		pos.y = pos.y + 1
		minetest.add_item(pos,"default:steel_ingot")
	end,
})

-- Steelspawn2 is faster, ideal for centre island
minetest.register_abm({
	nodenames = {"eggwars:steelspawn2"},
	interval = 5,
	chance = 1,
	action = function(pos)
		pos.y = pos.y + 1
		minetest.add_item(pos,"default:steel_ingot")
	end,
})

-- Stick spawner, for allowing players to craft tools
minetest.register_abm({
	nodenames = {"eggwars:stickspawn"},
	interval = 8,
	chance = 1,
	action = function(pos)
		pos.y = pos.y + 1
		minetest.add_item(pos,"default:stick")
	end,
})

-- Goldspawn1 is slower, ideal for player islands
minetest.register_abm({
	nodenames = {"eggwars:goldspawn1"},
	interval = 10,
	chance = 1,
	action = function(pos)
		pos.y = pos.y + 1
		minetest.add_item(pos,"default:gold_ingot")
	end,
})