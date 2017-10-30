local shop_fs = [[
size[10,3]
button[0,0;10,1;upgradespeed;Upgrade speed (cost: 20 diamonds)]
button[0,1;10,1;upgradejump;Upgrade jump (cost: 20 diamonds)]
button[0,2;10,1;thug;Order execution (cost: 99 diamonds)]
]]

minetest.register_chatcommand("shop", {
	params = "",
	description = "Open shop",
	func = function(name, param)
    minetest.show_formspec(name, "eggwars:shop", shop_fs)
		return true
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "eggwars:shop" then -- Replace this with your form name
    minetest.chat_send_all("Player "..player:get_player_name().." submitted fields "..dump(fields));
    if fields.thug then
      minetest.chat_send_all("THUG")
    elseif fields.upgradespeed then
      local inv = minetest.get_inventory({type="player", name=player:get_player_name()})
      if inv:contains_item("main", "default:diamond") then
        minetest.chat_send_all("yes, diamonds")
      end
	end
end)