sfinv.register_page("sfinv:shop", {
    title = "Shop",
    get = function(self, player, context)
      -- local name = player:get_player_name()
      local size_def = "size[8,9] "
      local bgcolor_def = "bgcolor[#080808BB;true] "
      local bg_def = "background[5,5;1,1;gui_formbg.png;true] "
      local btn1_def = "button[0.1,0.1;4,1;upgradespeed;Upgrade speed (cost: 20 diamonds)] "
      local btn2_def = "button[4,0.1;4,1;upgradejump;Upgrade jump (cost: 20 diamonds)]"
      return sfinv.make_formspec(player, context,
      size_def..bgcolor_def..bg_def..btn1_def..btn2_def, true)
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
    end
end)