----------------------------------------------------------------------
-- Eggwars by wilkgr																								--
-- with additional code by shivajiva101@hotmail.com		              --
-- Licensed under the AGPL v3                                       --
-- You MUST make any changes you make open source                   --
-- even if you just run it on your server without publishing it     --
-- Supports a maximum of 8 players per instance and 8 concurrent    --
-- instances for a max of 64 players                                --
----------------------------------------------------------------------

local TF = 'eggwars:trade'
local BF = 'eggwars:bot'

eggwars.shop_items = {}

eggwars.register_shop_item = function(def)
	def.entry = #eggwars.shop_items + 1
	eggwars.shop_items[def.entry] = def
end

local function build_formspec_items(name, items)
	local fsi = {}
	local y = 0.5
	for i, item in ipairs(items) do
		local fs = {
			'image[0,',
			y,
			';1,1;',
			item.image,
			']',
			'tooltip[0,',
			y,
			';1,1;',
			item.name.count,
			' ',
			item.description,
			']',
			'label[1.1,',
			y + 0.7,
			';',
			item.name.count,
			']',
			'item_image_button[2.5,',
			y,
			';1,1;',
			item.cost.name,
			';btn_',
			i,
			';]',
			'label[3.6,',
			y + 0.7,
			';',
			item.cost.count,
			']'
		}
		table.insert(fsi, table.concat(fs))
		y = y + 1.1
	end
	return table.concat(fsi)
end

local function build_form(name, items)
	local frm = {
		"formspec_version[3]",
		"size[6,5.5]",
		"image_button[5,0.5;0.5,0.5;eggwars_up.png;up;]",
		"image_button[5,4.4;0.5,0.5;eggwars_down.png;down;]",
		"container[0.5,",
		context[name].y,
		"]",
	}
	-- nasty hack to window the container!
	local fse = {
		"container_end[]",
		'box[0.05,0.0;5.9,0.5;#343434FF]',
		'box[0.05,4.9;5.9,0.6;#343434FF]',
	}
	local fstbl = build_formspec_items(name, items)
	return table.concat(frm) .. fstbl .. table.concat(fse)
end

local function trader_form_handler(clicker)

	local name = clicker:get_player_name()
	local key = eggwars.player[name]
	local def = eggwars.match[key].player[name]

	context[name] = {y=0, val=0}

	minetest.show_formspec(name, TF, build_form(name, def.shop_items))
end

local function bot_form_handler(clicker)
	local name = clicker:get_player_name()
	local key = eggwars.player[name]
	local def = eggwars.match[key]
	if def.player[name].rate == 1 then return end
	local level = 5 - def.player[name].rate
	local cost = (level + 1)
	local fs = {}
	fs[#fs+1] = 'size[2,2]'
	fs[#fs+1] = 'label[0.3,0;Level ' .. level + 1 .. ']'
	fs[#fs+1] = 'image_button_exit[0.5,0.6;1.0,1.0;eggwars_ruby.png;btn;]'
	fs[#fs+1] = 'label[0.5,1.6;x '.. cost .. ']'
	minetest.show_formspec(name, BF, table.concat(fs))
end

context = {}
minetest.register_on_player_receive_fields(function(player, formname, fields)

	-- Only handle this mods forms!
	if formname ~= TF and formname ~= BF then return end

	local name = player:get_player_name()

	-- Only match players have access to these forms!
	if not eggwars.player[name] then return end

	local key = eggwars.player[name]
	local def = eggwars.match[key].player[name]
	local pinv = player:get_inventory()

	-- Trader form
	if formname == TF then
		-- buttons
		for item, _ in pairs(fields) do
			if string.find(item, 'btn_') then
				local i = tonumber(string.sub(item, 5))
				local row, goods, cost
				row = def.shop_items[i]
				goods = row.name
				cost = row.cost
				if pinv:contains_item('main', cost) then
					if pinv:room_for_item('main', goods) then
						pinv:remove_item('main', cost)
						pinv:add_item('main', goods)
					else
						minetest.chat_send_player(name, 'insufficient room in your inventory!')
					end
				else
					minetest.chat_send_player(name, 'insufficient funds in your inventory!')
				end
				return
			end
		end
		-- scroll
		if formname == TF then
			local y = context[name].y
			local limit = -4.4 * 5 -- height * number of pages
			if fields.up and y ~= 0 then
				y = y + 4.4
				context[name].y = y
			elseif fields.down and y > limit then
				y = y - 4.4
				context[name].y = y
			end
			minetest.show_formspec(name, TF, build_form(name, def.shop_items))
		end

	elseif formname == BF and fields.btn then

		if def.rate <= 1 then return end -- limit reached
		local qty = (5 - def.rate + 1)
		local upd = def.rate - 1
		local cost = ItemStack('eggwars:ruby ' .. qty)

		if pinv:contains_item('main', cost) then
			pinv:remove_item('main', cost)
			eggwars.match[key].player[name].rate = upd
			minetest.get_node_timer(def.spawner):start(upd)
		else
			minetest.chat_send_player(name, 'insufficient funds in your inventory!')
		end

	end
end)

minetest.register_entity("eggwars:trader", {
	initial_properties = {
		physical = false,
		collisionbox = {-0.35,-1.0,-0.35, 0.35,0.8,0.35},
		visual = "mesh",
		mesh = "eggwars_character.b3d",
		textures = {"eggwars_trader7.png"},
		is_visible = true,
	},
	on_activate = function(self, staticdata)
		local data = minetest.deserialize(staticdata)
		self.owner = data.owner
		self.nametag = data.nametag
		self.tmr = data.tmr or 0
		self.uid = data.uid
		self.object:set_armor_groups({immortal = 1})
		self.object:set_properties({
			nametag = self.nametag,
			nametag_color = "#FFFF1F",
		})
	end,
	on_rightclick = function(self, clicker)
		trader_form_handler(clicker)
	end,
	on_step = function(self, dtime, ...)
		self.tmr = self.tmr + dtime
		if self.tmr < 0.25 then return end
		self.tmr = 0
		local key = eggwars.player[self.owner]
		if not key then
			self.object:remove()
		else
			local match = eggwars.match[key]
			if match.uid ~= self.uid then
				self.object:remove()
			end
		end
	end,
	get_staticdata = function(self)
		return minetest.serialize({
			owner = self.owner,
			tmr = self.tmr,
			uid = self.uid,
			nametag = self.nametag
		})
	end
})

minetest.register_entity("eggwars:bot", {
	initial_properties = {
		physical = false,
		collisionbox = {-0.25,-0.4,-0.25, 0.25,0.5,0.25},
		visual = "mesh",
		mesh = "eggwars_character.b3d",
		textures = {"eggwars_trader1.png"},
		is_visible = true,
		visual_size = {x=0.5, y=0.5}
	},
	on_activate = function(self, staticdata)
		local data = minetest.deserialize(staticdata)
		self.tmr = data.tmr or 0
		self.uid = data.uid
		self.owner = data.owner
		self.object:set_armor_groups({immortal = 1})
	end,
	on_rightclick = function(self, clicker)
		bot_form_handler(clicker)
	end,
	on_step = function(self, dtime, ...)
		self.tmr = self.tmr + dtime
		if self.tmr < 0.25 then return end
		self.tmr = 0
		local key = eggwars.player[self.owner]
		if not key then
			self.object:remove()
		else
			local match = eggwars.match[key]
			if match.uid ~= self.uid then
				self.object:remove()
			end
		end
	end,
	get_staticdata = function(self)
		return minetest.serialize({
			owner = self.owner,
			tmr = self.tmr,
			uid = self.uid
		})
	end
})

-- wooden log
eggwars.register_shop_item({
	name = {name="eggwars:log", count=20, wear=0, metadata=""},
	description = 'Wood Log',
	image = 'default_tree.png',
	cost = {name="default:gold_ingot", count=10, wear=0, metadata=""},
})
-- obsidian block
eggwars.register_shop_item({
	name = {name="default:obsidian_block", count=20, wear=0, metadata=""},
	description = 'Obsidian Block',
	image = 'default_obsidian_block.png',
	cost = {name="eggwars:ruby", count=5, wear=0, metadata=""},
})
-- binoculars
eggwars.register_shop_item({
	name = {name="binoculars:binoculars", count=1, wear=0, metadata=""},
	description = 'Binoculars',
	image = 'binoculars_binoculars.png',
	cost = {name="default:gold_ingot", count=5, wear=0, metadata=""},
})
-- Steel sword
eggwars.register_shop_item({
	name = {name="default:sword_steel", count=1, wear=0, metadata=""},
	description = 'Stone Sword',
	image = 'default_tool_steelsword.png',
	cost = {name="default:gold_ingot", count=15, wear=0, metadata=""},
})
-- Steel axe
eggwars.register_shop_item({
	name = {name="default:axe_steel", count=1, wear=0, metadata=""},
	description = 'Steel Axe',
	image = 'default_tool_steelaxe.png',
	cost = {name="default:gold_ingot", count=15, wear=0, metadata=""},
})
-- Diamond sword
eggwars.register_shop_item({
	name = {name="default:sword_diamond", count=1, wear=0, metadata=""},
	description = 'Diamond Sword',
	image = 'default_tool_diamondsword.png',
	cost = {name="default:diamond", count=5, wear=0, metadata=""},
})
-- Diamond pick
eggwars.register_shop_item({
	name = {name="default:pick_diamond", count=1, wear=0, metadata=""},
	description = 'Diamond Pick',
	image = 'default_tool_diamondpick.png',
	cost = {name="default:diamond", count=10, wear=0, metadata=""},
})

if eggwars.armor then

	-- wood
	eggwars.register_shop_item({
		name = {name="3d_armor:helmet_wood", count=1, wear=0, metadata=""},
		description = 'Wooden Helmet',
		image = "3d_armor_inv_helmet_wood.png",
		cost = {name="default:gold_ingot", count=10, wear=0, metadata=""},
	})

	eggwars.register_shop_item({
		name = {name="3d_armor:chestplate_wood", count=1, wear=0, metadata=""},
		description = 'Wooden Chestplate',
		image = "3d_armor_inv_chestplate_wood.png",
		cost = {name="default:gold_ingot", count=10, wear=0, metadata=""},
	})

	eggwars.register_shop_item({
		name = {name="3d_armor:leggings_wood", count=1, wear=0, metadata=""},
		description = 'Wooden Leggings',
		image = "3d_armor_inv_leggings_wood.png",
		cost = {name="default:gold_ingot", count=10, wear=0, metadata=""},
	})

	eggwars.register_shop_item({
		name = {name="3d_armor:boots_wood", count=1, wear=0, metadata=""},
		description = 'Wooden Boots',
		image = "3d_armor_inv_boots_wood.png",
		cost = {name="default:gold_ingot", count=10, wear=0, metadata=""},
	})

	--diamond
	eggwars.register_shop_item({
		name = {name="3d_armor:helmet_diamond", count=1, wear=0, metadata=""},
		description = 'Diamond Helmet',
		image = "3d_armor_inv_helmet_diamond.png",
		cost = {name="default:diamond", count=10, wear=0, metadata=""},
	})

	eggwars.register_shop_item({
		name = {name="3d_armor:chestplate_diamond", count=1, wear=0, metadata=""},
		description = 'Diamond Chestplate',
		image = "3d_armor_inv_chestplate_diamond.png",
		cost = {name="default:diamond", count=10, wear=0, metadata=""},
	})

	eggwars.register_shop_item({
		name = {name="3d_armor:leggings_diamond", count=1, wear=0, metadata=""},
		description = 'Diamond Leggings',
		image = "3d_armor_inv_leggings_diamond.png",
		cost = {name="default:diamond", count=10, wear=0, metadata=""},
	})

	eggwars.register_shop_item({
		name = {name="3d_armor:boots_diamond", count=1, wear=0, metadata=""},
		description = 'Diamond Boots',
		image = "3d_armor_inv_boots_diamond.png",
		cost = {name="default:diamond", count=10, wear=0, metadata=""},
	})

end

if eggwars.bows then

	-- Bows
	eggwars.register_shop_item({
		name = {name="bows:bow_wood", count=1, wear=0, metadata=""},
		description = 'Wooden Bow',
		image = 'bows_bow.png',
		cost = {name="default:gold_ingot", count=50, wear=0, metadata=""},
	})

	eggwars.register_shop_item({
		name = {name="bows:bow_steel", count=1, wear=0, metadata=""},
		description = 'Steel Bow',
		image = 'bows_bow_steel.png',
		cost = {name="eggwars:ruby", count=25, wear=0, metadata=""},
	})

	eggwars.register_shop_item({
		name = {name="bows:bow_bowie", count=1, wear=0, metadata=""},
		description = 'Bowie Bow',
		image = 'bows_bow_bowie.png',
		cost = {name="default:diamond", count=35, wear=0, metadata=""},
	})

	bows.register_arrow("arrow_tp",{
		description = "Teleport arrow",
		texture = "bows_arrow_wood.png^[colorize:#0000FFcc",
		damage = 0,
		craft_count = 0,
		drop_chance = 99,
		on_hit_node = function(self, pos, user, arrow_pos)
			if arrow_pos.y > 0 then
				user:set_pos(arrow_pos)
			end
		end,
	})
	-- Arrows
	eggwars.register_shop_item({
		name = {name="bows:arrow", count=5, wear=0, metadata=""},
		description = 'Wooden Arrow',
		image = 'bows_arrow_wood.png',
		cost = {name="default:gold_ingot", count=10, wear=0, metadata=""},
	})

	eggwars.register_shop_item({
		name = {name="bows:arrow_steel", count=10, wear=0, metadata=""},
		description = 'Steel Arrow',
		image = 'eggwars_arrow_steel.png',
		cost = {name="eggwars:ruby", count=20, wear=0, metadata=""},
	})

	eggwars.register_shop_item({
		name = {name="bows:arrow_diamond", count=10, wear=0, metadata=""},
		description = 'Diamond Arrow',
		image = 'eggwars_arrow_diamond.png',
		cost = {name="default:diamond", count=20, wear=0, metadata=""},
	})

	eggwars.register_shop_item({
		name = {name="bows:arrow_tp", count=5, wear=0, metadata=""},
		description = 'Teleport Arrow',
		image = 'bows_arrow_wood.png',
		cost = {name="default:gold_ingot", count=10, wear=0, metadata=""},
	})

end
