----------------------------------------------------------------------
-- Eggwars by wilkgr with additional code by shivajiva              --
-- Licensed under the AGPL v3                                       --
-- You MUST make any changes you make open source                   --
-- even if you just run it on your server without publishing it     --
-- Supports a maximum of 8 players per instance and 8 concurrent    --
-- instances for a max of 64 players                                --
----------------------------------------------------------------------
local context = {}
local traders = {
	"Johann",
	"Celery55",
	"mOuLDy Coder",
	"Wilkgr",
	"Rick O Shae",
	"Bernie Towndown",
	"Warden Ruby",
	"Bin Dinkin"
}

local trade_list = {
	{'default:wooden_planks 20', 'default:gold_ingot 5'}
}

local function form(self)
	local fs = "size[6,8]" .. default.gui_bg_img
			.. "label[0.5, 0.1;Trader " .. self.game_name .. "]"
	return fs
end

local function trader(self, clicker)

	if not self.game_name then
		-- add a random trader name
		self.game_name = traders[math.random(8)]
		self.nametag = ("Trader %s"):format(self.game_name)
		self.object:set_properties({
			nametag = self.nametag,
			nametag_color = "#00FF00"
		})
	end

	local pname = clicker:get_player_name()
	minetest.show_formspec(pname, "eggwars:trade", form(self))
end

minetest.register_entity("eggwars:trader", {
	hp_max = 1,
	physical = true,
	collisionbox = {-0.35,-1.0,-0.35, 0.35,0.8,0.35},
	visual = "mesh",
	mesh = "character.b3d",
	textures = {
		{"eggwars_trader.png"},
		{"eggwars_trader2.png"},
		{"eggwars_trader3.png"},
	},
	view_range = 15,
	drops = {},
	drawtype = "front",
	type = "npc",
	follow = false,

	on_rightclick = function(self, clicker)
		trader(self, clicker)
	end,
})

minetest.register_on_player_receive_fields( function(player, formname, fields)

  if not formname == "eggwars:trade" then return end

end)
