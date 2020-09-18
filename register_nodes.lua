----------------------------------------------------------------------
-- Eggwars by wilkgr												--
-- with additional code by shivajiva101@hotmail.com		            --
-- Licensed under the AGPL v3                                       --
-- You MUST make any changes you make open source                   --
-- even if you just run it on your server without publishing it     --
-- Supports a maximum of 8 players per instance and 8 concurrent    --
-- instances for a max of 64 players                                --
----------------------------------------------------------------------

eggwars = eggwars

--- Displays message for items that cannot be dropped
-- @return nothing
eggwars.drop_msg = function(itemstack, player)
	local name = player:get_player_name()
	minetest.chat_send_player(name, "Don't be silly, you can't drop that!")
end

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

-- Arena eggs
for i, v in ipairs(eggwars.arena[1].cs) do

	minetest.register_node("eggwars:egg" .. i, {
		description = eggwars.arena[1].cs[i][1] .. " egg",
		tiles = {"eggwars_shell.png^[colorize:" .. eggwars.arena[1].cs[i][2]},
		drawtype = "mesh",
		mesh = "eggwars_egg.obj",
		groups = {crumbly = 3, not_in_creative_inventory = 1},
		paramtype = "light",
		--light_source = 14,
		selection_box = {
			type = "fixed",
			fixed = {-0.35, -0.5, -0.35, 0.35, 0.45, 0.35} -- right, bottom, back, left, top, front
		},
		collision_box = {
			type = "fixed",
			fixed = {-0.35, -0.5, -0.35, 0.35, 0.45, 0.35}
		},
		drop = {},
		on_drop = eggwars.drop_msg,
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			local victim, attacker, msg, key, match, eggs
			victim = oldmetadata.fields.owner
			attacker = digger:get_player_name()
			key = eggwars.player[victim]
			match = eggwars.match[key]
			match.player[victim].egg = false
			eggs = match.player[attacker].eggs + 1
			match.player[attacker].eggs = eggs
			msg = victim .. "'s egg was destroyed by " .. attacker
			eggwars.add_tmp_image(victim, 'eggwars_destroyed.png', 5)
			eggwars.chat_send_match(key, msg)
			eggwars.update_hud(key, match.player[victim].id)
			eggwars.match[key] = match
		end,
		can_dig = function(pos, player)
			local meta = minetest.get_meta(pos)
			local name = meta:get_string("owner")
			local pname = player:get_player_name()
			if name == pname then
				return false
			else
				return true
			end
		end
	})

end

-- Spawners
minetest.register_node("eggwars:gold_spawner", {
	description = "Gold ingot spawner",
	tiles = {"default_stone.png^default_mineral_gold.png"},
	groups = {unbreakable = 1, not_in_creative_inventory = 1},
	on_timer = goldspawner
})

minetest.register_node("eggwars:ruby_spawner", {
	description = "Ruby gemstone spawner",
	tiles = {"default_stone.png^eggwars_mineral_ruby.png"},
	groups = {unbreakable = 1, not_in_creative_inventory = 1},
	on_timer = rubyspawner
})

minetest.register_node("eggwars:diamond_spawner", {
	description = "Diamond gemstone spawner",
	tiles = {"default_stone.png^default_mineral_diamond.png"},
	groups = {unbreakable = 1, not_in_creative_inventory = 1},
	on_timer = diamondspawner
})

-- Misc
minetest.register_node("eggwars:kill", {
	description = "Kill Block",
	range = 12,
	stack_max = 10000,
	inventory_image = "default_steel_block.png^dye_black.png",
	drawtype = "airlike",
	walkable = false,
	pointable = false,
	damage_per_second = 20,
	paramtype = "light",
	sunlight_propagates = true,
	drop = "",
	groups = {unbreakable = 1, not_in_creative_inventory = 1},
})

minetest.register_node("eggwars:playerclip", {
	description = "Player Clip",
	range = 12,
	stack_max = 10000,
	inventory_image = "default_steel_block.png^dye_green.png",
	drawtype = "airlike",
	paramtype = "light",
	pointable = false,
	sunlight_propagates = true,
	drop = "",
	groups = {unbreakable = 1, not_in_creative_inventory = 1},
})
