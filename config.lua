
--[[ A global variable to store all configuration values in ]]--
config = {
	DistanceBetweenSpawns = 500, --The distance in tiles between each players spawn point
	ResourcesToSpawn = { -- Contains what resources to spawn in a player's spawn point
		{
			name = "iron-ore", --The name of the resource
			type = "resource", --The type of resource. Supported values are: "resource" and "tile"
			minRadius = 10, --The minimum radius of the resource area
			maxRadius = 20, --The maximum radius of the resource area
			minAmount = 100, --The minimum amount of resource on each tile (Not available on tile type resources)
			maxAmount = 5000, --The max amount of resource on each tile (Not available on tile type resources)
			generateAmount = 2, --Amount of resource areas to generate in a player's spawn area
			generateType = nil --The type of area generator to use. Supported values are: nil or "spot"
		},
		{
			name = "copper-ore",
			type = "resource",
			minRadius = 10,
			maxRadius = 20,
			minAmount = 100,
			maxAmount = 5000,
			generateAmount = 2
		},
		{
			name = "stone",
			type = "resource",
			minRadius = 10,
			maxRadius = 20,
			minAmount = 100,
			maxAmount = 1000
		},
		{
			name = "coal",
			type = "resource",
			minRadius = 10,
			maxRadius = 20,
			minAmount = 100,
			maxAmount = 5000,
			generateAmount = 2
		},
		{
			name = "crude-oil",
			type = "resource",
			generateType = "spot",
			minRadius = 2,
			maxRadius = 5,
			minAmount = 1500,
			maxAmount = 20000
		},
		{
			name = "water",
			type = "tile",
			minRadius = 10,
			maxRadius = 20,
			generateAmount = 3
		}
	}
}