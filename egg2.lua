-- GENERATED CODE
-- Node Box Editor, version 0.8.1 - Glass
-- Namespace: test

minetest.register_node("eggwars:egg2", {
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

