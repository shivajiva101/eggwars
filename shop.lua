minetest.register_on_player_receive_fields( function(player, formname, fields)
	  -- minetest.chat_send_all("Player "..player:get_player_name().." submitted fields "..dump(fields));
    if fields.upgradejump then
      local inv = minetest.get_inventory({type="player", name=player:get_player_name()})
      if inv:contains_item("main", "default:diamond") then
        inv:remove_item("main","default:diamond 20")
        eggwars.player_properties[player:get_player_name()].jump = eggwars.player_properties[player:get_player_name()].jump * 1.25
        player:set_physics_override(eggwars.player_properties[player:get_player_name()])
      end
    elseif fields.upgradespeed then
      local inv = minetest.get_inventory({type="player", name=player:get_player_name()})
      if inv:contains_item("main", "default:diamond") then
        inv:remove_item("main","default:diamond 20")
        eggwars.player_properties[player:get_player_name()].speed = eggwars.player_properties[player:get_player_name()].speed * 1.25
        minetest.chat_send_all("New speed: " .. eggwars.player_properties[player:get_player_name()].speed)
        player:set_physics_override(eggwars.player_properties[player:get_player_name()])
      end
    end
  player:set_inventory_formspec(eggwars.inventory_form)
end)