----------------------------------------------------------------------
-- Eggwars by wilkgr																								--
-- with additional code by shivajiva101@hotmail.com		              --
-- Licensed under the AGPL v3                                       --
-- You MUST make any changes you make open source                   --
-- even if you just run it on your server without publishing it     --
-- Supports a maximum of 8 players per instance and 8 concurrent    --
-- instances for a max of 64 players                                --
----------------------------------------------------------------------

-- Parts of the code in this file are modified or copied
-- from worldedit by Uberi https://github.com/Uberi/Minetest-WorldEdit

local HEADER = 5 .. ":"
local jit_available = jit ~= nil

--- Copies and modifies positions `pos1` and `pos2` so that each component of
-- `pos1` is less than or equal to the corresponding component of `pos2`.
-- @return the new positions.
local function sort_pos(pos1, pos2)
	pos1 = {x=pos1.x, y=pos1.y, z=pos1.z}
	pos2 = {x=pos2.x, y=pos2.y, z=pos2.z}
	if pos1.x > pos2.x then
		pos2.x, pos1.x = pos1.x, pos2.x
	end
	if pos1.y > pos2.y then
		pos2.y, pos1.y = pos1.y, pos2.y
	end
	if pos1.z > pos2.z then
		pos2.z, pos1.z = pos1.z, pos2.z
	end
	return pos1, pos2
end

--- Keeps a region of map chunks loaded
local function keep_loaded(pos1, pos2)
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)
end

--- Reads the header of serialized data.
-- @param value Serialized data.
-- @return The version as a positive natural number, or 0 for unknown versions.
-- @return Extra header fields as a list of strings, or nil if not supported.
-- @return Content (data after header).
local function read_header(value)
	if value:find("^[0-9]+[%-:]") then
		local header_end = value:find(":", 1, true)
		local header = value:sub(1, header_end - 1):split(",")
		local version = tonumber(header[1])
		table.remove(header, 1)
		local content = value:sub(header_end + 1)
		return version, header, content
	end
	return nil
end

--- Loads the schematic in `value` into a node list in the latest format.
-- Contains code based on [table.save/table.load](http://lua-users.org/wiki/SaveTableToFile)
-- by ChillCode, available under the MIT license.
-- @return A node list in the latest format, or nil on failure.
local function load_schematic(value)
	local version, _, content = read_header(value)
	local nodes = {}
	if version == 5 then -- correct format
		if not jit_available then
			-- This is broken for larger tables in the current version of LuaJIT
			nodes = minetest.deserialize(content)
		else
			-- XXX: This is a filthy hack that works surprisingly well - in LuaJIT, `minetest.deserialize` will fail due to the register limit
			content = content:gsub("return%s*{", "", 1):gsub("}%s*$", "", 1) -- remove the starting and ending values to leave only the node data
			local escaped = content:gsub("\\\\", "@@"):gsub("\\\"", "@@"):gsub("(\"[^\"]*\")", function(s) return string.rep("@", #s) end)
			local startpos, startpos1, endpos = 1, 1
			while true do -- go through each individual node entry (except the last)
				startpos, endpos = escaped:find("},%s*{", startpos)
				if not startpos then
					break
				end
				local current = content:sub(startpos1, startpos)
				local entry = minetest.deserialize("return " .. current)
				table.insert(nodes, entry)
				startpos, startpos1 = endpos, endpos
			end
			local entry = minetest.deserialize("return " .. content:sub(startpos1)) -- process the last entry
			table.insert(nodes, entry)
		end
	else
		return nil
	end
	return nodes
end

local function allocate_with_nodes(origin_pos, nodes)
	local huge = math.huge
	local pos1x, pos1y, pos1z = huge, huge, huge
	local pos2x, pos2y, pos2z = -huge, -huge, -huge
	local origin_x, origin_y, origin_z = origin_pos.x, origin_pos.y, origin_pos.z
	for i, entry in ipairs(nodes) do
		local x, y, z = origin_x + entry.x, origin_y + entry.y, origin_z + entry.z
		if x < pos1x then pos1x = x end
		if y < pos1y then pos1y = y end
		if z < pos1z then pos1z = z end
		if x > pos2x then pos2x = x end
		if y > pos2y then pos2y = y end
		if z > pos2z then pos2z = z end
	end
	local pos1 = {x=pos1x, y=pos1y, z=pos1z}
	local pos2 = {x=pos2x, y=pos2y, z=pos2z}
	return pos1, pos2, #nodes
end

--- Return volume in nodes of a region
-- @param pos1 - starting point vector table
-- @param pos2 - ending point vector table
-- @return number of nodes as an integer?
local function volume(pos1, pos2)
	local p1, p2 = sort_pos(pos1, pos2)
	return (p2.x - p1.x + 1) *
		(p2.y - p1.y + 1) *
		(p2.z - p1.z + 1)
end

--- Slice a region along the midpoint of an axis
-- @param pos1 - vector passed as a table
-- @param pos2 - vector passed as a table
-- @param axis - axis passed as a string
-- @return ipair table containing 2 regions
local function region_slicer(pos1, pos2, axis)
	local len = vector.subtract(pos2, pos1)
	local mid = vector.new(
		pos2.x + (len.x / 2),
		pos1.y + (len.y / 2),
		pos1.z + (len.z / 2)
	)
	local r = {}
	if axis == 'y' then
		r = {
			{
				p1 = pos1,
				p2 = vector.new(pos2.x, mid.y, pos2.z)
			},
			{
				p1 = vector.new(pos1.x, mid.y + 1, pos1.z),
				p2 = pos2
			}
		}
	elseif axis == 'x' then
		r = {
			{
				p1 = pos1,
				p2 = vector.new(mid.x, pos2.y, pos2.z)
			},
			{
				p1 = vector.new(mid.x - 1, pos1.y, pos1.z),
				p2 = pos2
			}
		}
	elseif axis == 'z' then
		r = {
			{
				p1 = pos1,
				p2 = vector.new(pos2.x, pos2.y, mid.z)
			},
			{
				p1 = vector.new(pos1.x, pos1.y, mid.z + 1),
				p2 = pos2
			}
		}
	end
	return r
end

--- Create a table of ignore for the volume of the area
-- @param area pair table
-- @return ipair table
local function get_empty_data(area)
	local data = {}
	local c_ignore = minetest.get_content_id("ignore")
	for i = 1, volume(area.MinEdge, area.MaxEdge) do
		data[i] = c_ignore
	end
	return data
end

--- Create and return a voxel manip and it's area
-- @param pos1 - starting point vector table
-- @param pos2 - ending point vector table
-- @return voxel manip
-- @return area vector table
local function init(pos1, pos2)
	local manip = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})
	return manip, area
end

-- Adds a hollow cube of playerclip double lined with kill
-- designed for games created in the air
-- @param pos: base vector of cube (x=,y=,z=)
-- @param vol: volume (x=,y=,z=)
-- @param remove: replace shield with air (bool)
-- @return number of nodes added
local function shield(pos, vol, remove)

	local manip, area = init(pos, vector.add(pos, vol))
	local data = get_empty_data(area)
	local node_1, node_2, msg
	if remove == true then
		node_1 = minetest.get_content_id("air")
		node_2 = node_1
		msg = "Warning: Area unprotected!"
	else
		node_1 = minetest.get_content_id("eggwars:playerclip")
		node_2 = minetest.get_content_id("eggwars:kill")
		msg = "Warning: Area now shielded"
	end
	local stride = {x=1, y=area.ystride, z=area.zstride}
	local offset = vector.subtract(pos, area.MinEdge)
	local count = 0

	-- add the nodes
	for z = 0, vol.z-1 do
		local index_z = (offset.z + z) * stride.z + 1
		for y = 0, vol.y-1 do
			local index_y = index_z + (offset.y + y) * stride.y
			for x = 0, vol.x-1 do
				local is_clip = z == 0 or z == vol.z-1
					or y == 0 or y == vol.y-1
					or x == 0 or x == vol.x-1
				local is_kill = z == 1 or z == vol.z-2	or z == vol.z-3
				or y == 1 or y == 2 or y == vol.y-2 or y == vol.y-3
				or x == 1 or x == 2 or x == vol.x-2 or x == vol.x-3
				if is_clip then
					local i = index_y + (offset.x + x)
					data[i] = node_1
					count = count + 1
				elseif is_kill then
					local i = index_y + (offset.x + x)
					data[i] = node_2
					count = count + 1
				end
			end
		end
	end

	manip:set_data(data)
	manip:write_to_map()

	return count, msg
end

function eggwars.metasave(pos1, pos2, filename)
	local file, err = io.open(filename, "wb")
	if err then return 0 end
	local data, count = eggwars.serialize_meta(pos1, pos2)
	file:write(data)
	file:close()
	return count
end

function eggwars.metaload(originpos, filename)
	filename = minetest.get_worldpath() .. "/schems/" .. filename .. ".ewm"
	local file, err = io.open(filename, "wb")
	if err then return 0 end
	local data = file:read("*a")
	file:close()
	return eggwars.deserialize_meta(originpos, data)
end

--- Fixes lighting within a region
-- @param pos1 start vector
-- @param pos2 end vector
-- @return nothing
function eggwars.fixlight(pos1, pos2)
	local vmanip = minetest.get_voxel_manip(pos1, pos2)
	vmanip:write_to_map()
end

--- Clears all objects in a region.
-- @return The number of objects cleared.
function eggwars.clear_objects(pos1, pos2)
	pos1, pos2 = sort_pos(pos1, pos2)

	keep_loaded(pos1, pos2)

	-- Offset positions to include full nodes (positions are in the center of nodes)
	local pos1x, pos1y, pos1z = pos1.x - 0.5, pos1.y - 0.5, pos1.z - 0.5
	local pos2x, pos2y, pos2z = pos2.x + 0.5, pos2.y + 0.5, pos2.z + 0.5

	-- Center of region
	local center = {
		x = pos1x + ((pos2x - pos1x) / 2),
		y = pos1y + ((pos2y - pos1y) / 2),
		z = pos1z + ((pos2z - pos1z) / 2)
	}
	-- Bounding sphere radius
	local radius = math.sqrt(
			(center.x - pos1x) ^ 2 +
			(center.y - pos1y) ^ 2 +
			(center.z - pos1z) ^ 2)
	local count = 0
	for _, obj in pairs(minetest.get_objects_inside_radius(center, radius)) do
		-- Avoid players
		if not obj:is_player() then
			local pos = obj:getpos()
			if pos.x >= pos1x and pos.x <= pos2x and
					pos.y >= pos1y and pos.y <= pos2y and
					pos.z >= pos1z and pos.z <= pos2z then
				-- Inside region
				obj:remove()
				count = count + 1
			end
		end
	end
	return count
end

--- Clears specific nodes in a region.
-- @return The number of nodes cleared.
function eggwars.clear_nodes(pos1, pos2)
	pos1, pos2 = sort_pos(pos1, pos2)

	keep_loaded(pos1, pos2)

	-- Offset positions to include full nodes (positions are in the center of nodes)
	local nodenames = {
		"group:choppy",
		"group:cracky",
		"group:crumbly",
		"group:oddly_breakable_by_hand"
	}
	local slices = region_slicer(pos1, pos2, 'y')
	local n = 0

	for _, slice in ipairs(slices) do
		local found = minetest.find_nodes_in_area(slice.p1, slice.p2, nodenames)
		for _,v in ipairs(found) do
			minetest.set_node(v, {name="air"})
		end
		n = n + #found
	end
	return n
end

--- Sets a region to `air`.
-- @param pos1
-- @param pos2
-- @return The number of nodes set.
function eggwars.delete_area(pos1, pos2)
	pos1, pos2 = sort_pos(pos1, pos2)

	local manip, area = init(pos1, pos2)
	local data = get_empty_data(area)

	local node_id = minetest.get_content_id('air')
	-- Fill area with node
	for i in area:iterp(pos1, pos2) do
		data[i] = node_id
	end

	manip:set_data(data)
	manip:write_to_map()

	return volume(pos1, pos2)
end

--- Loads the nodes represented by string `value` at position `origin_pos`.
-- @return The number of nodes deserialized.
function eggwars.deserialize_meta(origin_pos, value)
	local nodes = load_schematic(value)
	if not nodes then return nil end

	local pos1, pos2 = allocate_with_nodes(origin_pos, nodes)
	keep_loaded(pos1, pos2)

	local origin_x, origin_y, origin_z = origin_pos.x, origin_pos.y, origin_pos.z
	local add_node, get_meta = minetest.add_node, minetest.get_meta
	for i, entry in ipairs(nodes) do
		entry.x, entry.y, entry.z = origin_x + entry.x, origin_y + entry.y, origin_z + entry.z
		-- Entry acts as both position and node
		add_node(entry, entry)
		if entry.meta then
			get_meta(entry):from_table(entry.meta)
		end
	end
	return #nodes
end

-- Serialise any meta nodes within a volume
-- @param pos1: first vector
-- @param pos2: second vector
-- @return serialised string, node count
function eggwars.serialize_meta(pos1, pos2)

	pos1, pos2 = sort_pos(pos1, pos2)
	keep_loaded(pos1, pos2)

	local pos = {x=pos1.x, y=0, z=0}
	local count = 0
	local result = {}
	local get_node, get_meta = minetest.get_node, minetest.get_meta
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node = get_node(pos)
				if node.name ~= "air" and node.name ~= "ignore" then

					local meta = get_meta(pos):to_table()
					local meta_content

					-- Convert metadata item stacks to item strings
					for name, inventory in pairs(meta.inventory) do
						for index, stack in ipairs(inventory) do
							meta_content = true
							inventory[index] = stack.to_string and stack:to_string() or stack
						end
					end

					for name, field in pairs(meta.fields) do
						meta_content = true
					end

					for k in pairs(meta) do
						if k ~= "inventory" and k ~= "fields" then
							meta_content = true
							break
						end
					end

					if meta_content then
						count = count + 1
						result[count] = {
							x = pos.x - pos1.x,
							y = pos.y - pos1.y,
							z = pos.z - pos1.z,
							name = node.name,
							param1 = node.param1 ~= 0 and node.param1 or nil,
							param2 = node.param2 ~= 0 and node.param2 or nil,
							meta = meta_content and meta or nil,
						}

					end
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	-- Serialise entries
	return HEADER .. minetest.serialize(result), count
end

-- Adds a protective shield to a volume
-- @param vol: position vectors
-- @param remover: replace shield with air (bool)
-- @return number of nodes added
eggwars.protect = function(pos1, pos2, remove)

	local p1, p2, dims
	-- using vectors
	p1 = pos1
	p2 = pos2

	-- sort if reqd
	if p1.y > p2.y then
		p2, p1 = p1, p2
	end

	-- volume vect
	dims = {
		x = p2.x - p1.x,
		y = p2.y - p1.y,
		z = p2.z - p1.z
	}

	-- unsign if reqd
	for k,v in pairs(dims) do
		if v < 0 then
			dims[k] = (v*v)^0.5
		end
	end

	-- execute, returning node count
	return shield(p1, dims, remove)
end

-- Clear a players inventory
-- @param player; minetest player object
-- @return nothing
eggwars.clear_inventory = function(player)

	local player_inv = player:get_inventory()

	player_inv:set_list("main", {}) -- clear
	player_inv:set_list("craft", {}) -- clear

end

if eggwars.armor then
	-- Clear a players armour
	-- @param player; minetest player object
	-- @return nothing
	eggwars.clear_armor = function(player)
		local name, armor_inv = armor:get_valid_player(player, "[clear_armor]")
		if not name then
			return
		end
		for i=1, armor_inv:get_size("armor") do
			local stack = armor_inv:get_stack("armor", i)
			if stack:get_count() > 0 then
				armor:run_callbacks("on_unequip", player, i, stack)
				armor_inv:set_stack("armor", i, nil)
			end
		end
		armor:save_armor_inventory(player)
		armor:set_player_armor(player)
	end
end
