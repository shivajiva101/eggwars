local shop_fs = [[
size[10,2]
button[0,0;10,1;upgradespeed;Upgrade speed (cost: 20 diamonds)]
button[0,1;10,1;upgradejump;Upgrade jump (cost: 20 diamonds)]
]]

minetest.register_chatcommand("shop", {
	params = "",
	description = "Open shop",
	func = function(name, param)
    minetest.show_formspec(name, "eggwars:shop", shop_fs)
		return true
	end,
})

minetest.register_on_player_receive_fields( function(player, formname, fields)
	if formname == "eggwars:shop" then -- Replace this with your form name
    minetest.chat_send_all("Player "..player:get_player_name().." submitted fields "..dump(fields));
    if fields.upgradejump then
      local inv = minetest.get_inventory({type="player", name=player:get_player_name()})
      if inv:contains_item("main", "default:diamond") then
        inv:remove_item("main","default:diamond 20")
        eggwars.player_properties[player:get_player_name()].jump = eggwars.player_properties[player:get_player_name()].jump * 1.25
        player:set_physics_override(eggwars.player_properties[player:get_player_name()])
    elseif fields.upgradespeed then
      local inv = minetest.get_inventory({type="player", name=player:get_player_name()})
      if inv:contains_item("main", "default:diamond") then
        inv:remove_item("main","default:diamond 20")
        eggwars.player_properties[player:get_player_name()].speed = eggwars.player_properties[player:get_player_name()].speed * 1.25
        minetest.chat_send_all("New speed: " .. eggwars.player_properties[player:get_player_name()].speed)
        player:set_physics_override(eggwars.player_properties[player:get_player_name()])
      end
    end
	end
end)