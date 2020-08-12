## Eggwars API

Welcome to the API documentation

The structure of the mod hinges around the arena definitions registered to the mod.
There is a default arena definition which you can use as a template for your own arenas.
It's structure is a table of key pairs holding all the information required to insert
an arena at any location on the map, position vectors used in the definition MUST
be relative to x=0, y=0, z=0 of the arena unless stated otherwise.

### Arena Definition Structure

	{
		blocked_recipes = {
			{input or output recipe},
			...
		}
		colour = {
			{ rgb table },
			...
		},
		cs = {
			{'colour', 'hex string', 'formatted'},
			...
		}
		description = "short description",
		egg_offset = { -- island relative
			{vector},
			...
		}
		exempt_nodes = {
			['full or partial node name'] = true,
			...
		}
		hub = {
			insert_offset = {vector},
			schem = 'filename'
		},
		island = {
			{vector},
			...,
			insert_offset = {vector},
			schem = 'filename'
		},
		name = 'arena name',
		region = {
			p1 = {vector},
			p2 = {vector}
		},
		satellite = {
			offset = {vector},
			pos = {
				{vector},
				...
			}
		},
		spawners = {
			diamond = {
				{vector},
				...,
				rate = number of seconds
			},
			gold = { -- island relative
				{vector},
				...,
				rate = number of seconds
			},
			ruby = {
				{vector},
				...,
				rate = number of seconds
			}
			bot = { -- island relative
				offset = {
					{vector},
					...,
					yaw = {degrees, ...}
				}
			}
		}
		timer = {
			max_time = number of seconds,
			suddendeath = number of seconds
		},
		trader = {
			names = {
				"name",
				...,
			},
			offset = { -- island relative
				{vector},
				...,
			},
			yaw = {degrees, ...}
		}
	}

### Functions
	eggwars.register_arena(arena_def)
Registers an arena definition to eggwars.
