----------------------------------------------------------------------
-- Eggwars by wilkgr with additional code by shivajiva              --
-- Licensed under the AGPL v3                                       --
-- You MUST make any changes you make open source                   --
-- even if you just run it on your server without publishing it     --
-- Supports a maximum of 8 players per instance and 8 concurrent    --
-- instances for a max of 64 players                                --
----------------------------------------------------------------------

local cs = {
	{"Blue", "#0000FFFF"},
	{"Green", "#00FF00FF"},
	{"Red", "#FF0000FF"},
	{"Purple", "#7800FFFF"},
	{"Yellow", "#FFFF00FF"},
	{"Cyan", "#00FFFFFF"},
	{"Orange", "#FF9600FF"},
	{"Pink", "#FF00FFFF"}
}

------------------------
-- on_timer functions --
------------------------

local function goldspawner(pos, elapsed)
	local sp = vector.new(pos.x, pos.y + 3, pos.z)
	minetest.add_item(sp, "default:gold_ingot")
	return true
end

local function rubyspawner(pos, elapsed)
	local sp = vector.new(pos.x, pos.y + 3, pos.z)
	minetest.add_item(sp, "eggwars:ruby")
	return true
end

local function diamondspawner(pos, elapsed)
	local sp = vector.new(pos.x, pos.y + 3, pos.z)
	minetest.add_item(sp, "default:diamond")
	return true
end

-----------------
-- craft items --
-----------------

minetest.register_craftitem("eggwars:ruby", {
	description = "Ruby",
	inventory_image = "eggwars_ruby.png",
})

------------------------
-- node registrations --
------------------------

for i=1,8 do

	minetest.register_node("eggwars:egg" .. i, {
		description = cs[i][1] .. " egg",
		tiles = {"^[colorize:" .. cs[i][2]},
		drawtype = "mesh",
		mesh = "eggwars_egg.obj",
		groups = {crumbly = 3},
		paramtype = "light",
		paramtype2 = "facedir",
		selection_box = {
			type = "fixed",
			fixed = {-0.35, -0.5, -0.35, 0.35, 0.45, 0.35} -- right, bottom, back, left, top, front
		},
		collision_box = {
			type = "fixed",
			fixed = {-0.35, -0.5, -0.35, 0.35, 0.45, 0.35}
		},
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
		
		end,
		can_dig = function(pos, player)
			local meta = minetest.get_meta(pos)
			local name = meta:get_string("owner")
			if name == "" or not name == player:get_player_name() then
				return true
			end
		end
	})

end

minetest.register_node("eggwars:gold_spawner", {
	description = "Gold ingot spawner",
	tiles = {"default_gold_block.png"},
	on_timer = goldspawner
})

minetest.register_node("eggwars:ruby_spawner", {
	description = "Ruby gemstone spawner",
	tiles = {"default_diamond_block.png"},
	on_timer = rubyspawner
})

minetest.register_node("eggwars:diamond_spawner", {
	description = "Diamond gemstone spawner",
	tiles = {"default_diamond_block.png"},
	on_timer = diamondspawner
})
