sfinv.register_page("eggwars:shop", {
    title = "Shop",
    get = function(self, player, context)
      -- local name = player:get_player_name()
      local fs = {
        "formspec_version[3]",
        "size[8,9]",
        "position[0.5,0.5]",
        "bgcolor[#080808BB;true]",
        "background[5,5;1,1;gui_formbg.png;true]",
        "button[0.375,0.25;7.25,1;upgradespeed;Upgrade speed (cost: 20 diamonds)]",
        "button[0.375,1.25;7.25,1;upgradejump;Upgrade jump (cost: 20 diamonds)]",
        "button[0.375,2.25;7.25,1;buycobble;Buy 5 Cobblestone (cost: 1 steel ingot)]",
        "image_button[0.375,3.25;1,1;default_stone.png;buycobble2;Buy stuff]"
      }
      return sfinv.make_formspec(player, context,
      table.concat(fs, ""), true)
  end
})

minetest.register_on_player_receive_fields( function(player, formname, fields)
	  minetest.chat_send_all("Player "..player:get_player_name().." submitted fields "..dump(fields));
    if fields.upgradejump then
      local inv = minetest.get_inventory({type="player", name=player:get_player_name()})
      if inv:contains_item("main", "default:diamond") then
        inv:remove_item("main","default:diamond 20")
        local player_physics = player:get_physics_override()
        player_physics.jump = player_physics.jump * 1.25
        player:set_physics_override(player_physics)
      end
    elseif fields.upgradespeed then
      local inv = minetest.get_inventory({type="player", name=player:get_player_name()})
      if inv:contains_item("main", "default:diamond") then
        inv:remove_item("main","default:diamond 20")
        local player_physics = player:get_physics_override()
        player_physics.speed = player_physics.speed * 1.25
        player:set_physics_override(player_physics)
      end
    elseif fields.buycobble then
      local inv = minetest.get_inventory({type="player", name=player:get_player_name()})
      if inv:contains_item("main", "default:steel_ingot") then
        inv:remove_item("main","default:steel_ingot")
        inv:add_item("main","default:cobble 5")
      end
    end
end)