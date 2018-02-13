sfinv.register_page("sfinv:shop", {
    title = "Shop",
    get = function(self, player, context)
      -- local name = player:get_player_name()
      return sfinv.make_formspec(player, context, "size[8,9] bgcolor[#080808BB;true] background[5,5;1,1;gui_formbg.png;true] button[0.1,0.1;4,1;upgradespeed;Upgrade speed (cost: 20 diamonds)] button[4,0.1;4,1;upgradejump;Upgrade jump (cost: 20 diamonds)]", true)
  end
})

minetest.register_on_player_receive_fields( function(player, formname, fields)
	  minetest.chat_send_all("Player "..player:get_player_name().." submitted fields "..dump(fields));
    if fields.upgradejump then
      local inv = minetest.get_inventory({type="player", name=player:get_player_name()})
      if inv:contains_item("main", "default:diamond") then
        inv:remove_item("main","default:diamond 20")
        player_physics = player:get_physics_override()
        player_physics.jump = player_physics.jump * 1.25
        player:set_physics_override(player_physics)
      end
    elseif fields.upgradespeed then
      local inv = minetest.get_inventory({type="player", name=player:get_player_name()})
      if inv:contains_item("main", "default:diamond") then
        inv:remove_item("main","default:diamond 20")
        lplayer_physics = player:get_physics_override()
        player_physics.speed = player_physics.speed * 1.25
        player:set_physics_override(player_physics)
      end
    end
  -- player:set_inventory_formspec(eggwars.inventory_form)
end)