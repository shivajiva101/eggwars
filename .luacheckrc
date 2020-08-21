unused_args = false
allow_defined_top = true
max_line_length = 999

globals = {
	"eggwars",
}

read_globals = {
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn"}},

	"minetest", "vector",
	"bows", "armor", "default",

	"ItemStack", "areas", "VoxelArea",
	"ie",
}

ignore = {
	"id", "k",
}
