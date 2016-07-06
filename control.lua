require("config")
require("util")
local consolePrint = print

--[[ Calculate distance between two positions ]]--
local function DistBetween(pos1, pos2)
	return math.sqrt((pos2.x - pos1.x)^2 + (pos2.y - pos1.y)^2)
end

--[[ Check if a position is a valid spawn point. Is valid if the position is not too near another players spawn point. ]]--
local function IsValidSpawnPoint(player, position)

	for index, playerData in pairs(global.players) do
		if player.index ~= index and DistBetween(position, playerData.spawnPosition) < config.DistanceBetweenSpawns then
			return false
		end
	end
	
	return true
end

--[[ Check if a position is inside a players spawn area. Returns a player if it is or nil ]]--
local function IsInSpawnArea(position)
	for index, playerData in pairs(global.players) do
		if playerData.position ~= nil and DistBetween(position, playerData.position) < config.DistanceBetweenSpawns then
			return game.players[index]
		end
	end
	
	return nil
end

--[[ Returns a new valid spawn position (TODO: Make it completely random) ]]--
local function GetNewSpawnLocation(player)
	if #global.players == 0 then
		return game.forces.player.get_spawn_position("nauvis") --The first players spawn will be the normal spawn position of the player force
	else
		for index, playerData in pairs(global.players) do
			for _, dirData in ipairs(util.SpawnDirections) do
				local x = playerData.spawnPosition.x + (dirData.x * config.DistanceBetweenSpawns)
				local y = playerData.spawnPosition.y + (dirData.y * config.DistanceBetweenSpawns)
				
				if IsValidSpawnPoint(player, {x = x, y = y}) then
					return {x = x, y = y}
				end				
			end
		end
	end
	
	return nil
end

--[[ Remove all biters in a square around a position ]]--
local function ClearEnemiesInArea(position, radius)
	--local enemies = game.surfaces.nauvis.find_enemy_units(position, config.DistanceBetweenSpawns + 50, game.forces.enemy)
	local enemies = game.surfaces.nauvis.find_entities_filtered({
		area = { { position.x - radius , position.y - radius }, { position.x + radius , position.y + radius } },
		force = "enemy"
	})
	
	for _, enemy in pairs(enemies) do
		enemy.destroy()
	end
end

--[[ Create resources at a players spawn ]]--
local function CreateResourcesAtSpawn(player, position)
	local dist = math.ceil(config.DistanceBetweenSpawns / 2)
	local surface = game.surfaces.nauvis
	local spawnTiles = {}
	
	for x = position.x - dist, position.x + dist, 32 do
		for y = position.y - dist, position.y + dist, 32 do
			if x >= position.x - dist and x <= position.x + dist and y >= position.y - dist and y <= position.y + dist then
				table.insert(spawnTiles, {x = x, y = y})
			end		
		end
	end
	
	local takenTiles = {}
	
	for resIndex, resData in pairs(config.ResourcesToSpawn) do
		
		if resData.generateAmount == nil then
			resData.generateAmount = 1
		end
		
		for times = 1, resData.generateAmount do
			local spawnPos = nil
			while spawnPos == nil do
				spawnPos = math.random(#spawnTiles)
				if takenTiles[spawnPos] ~= nil then
					spawnPos = nil
				else
					spawnPos = spawnTiles[spawnPos]
				end
			end
			
			local radius = math.random(resData.minRadius, resData.maxRadius)
			
			if resData.type == "resource" then
				
				for x = spawnPos.x - radius, spawnPos.x + radius, 1 do
					for y = spawnPos.y - radius, spawnPos.y + radius, 1 do
						local amount = math.random(resData.minAmount, resData.maxAmount)
						if resData.generateType == "spot" then
							if math.random(0, 100) >= 80 then
								surface.create_entity({name = resData.name, position = {x, y}, force = game.forces.neutral, amount = amount})
							end
						else
							local dx = math.abs(x - spawnPos.x)
							local dy = math.abs(y - spawnPos.y)
							
							if (dx^2 + dy^2) <= radius^2 then
								surface.create_entity({name = resData.name, position = {x, y}, force = game.forces.neutral, amount = amount})
							end
						end
					end
				end
				
			elseif resData.type == "tile" then
				local waterTiles = {}
				for x = spawnPos.x - radius, spawnPos.x + radius, 1 do
					for y = spawnPos.y - radius, spawnPos.y + radius, 1 do
					
						if resData.generateType == "spot" then
							if math.random(0, 100) >= 80 then
								table.insert(waterTiles, {name = resData.name, position = { x = x, y = y }})
							end
						else
							local dx = math.abs(x - spawnPos.x)
							local dy = math.abs(y - spawnPos.y)
							
							if (dx^2 + dy^2) <= radius^2 then
								table.insert(waterTiles, {name = resData.name, position = { x = x, y = y }})
							end
						end
					end
				end
				
				surface.set_tiles(waterTiles)
			end
			
			player.print("Created " .. resData.name .. " around {" .. spawnPos.x .. ", " .. spawnPos.y .. "}, radius: " .. radius)
			
			takenTiles[spawnPos] = resData
			
			if #takenTiles == #spawnTiles then
				player.print("takenTiles == spawnTiles")
				break
			end
		end
	end
end

--[[ Prepare an area for a player spawn ]]--
local function PrepareSpawn(player, centerPosition)
	player.print("Preparing Spawn Area")
	local dist = math.ceil(config.DistanceBetweenSpawns / 2)
	
	ClearEnemiesInArea(centerPosition, config.DistanceBetweenSpawns)
	
	local tiles = {}
	for x = centerPosition.x - dist, centerPosition.x + dist, 1 do
		for y = centerPosition.y - dist, centerPosition.y + dist, 1 do
			table.insert(tiles, {name = "grass", position = {x = x, y = y}})
		end
	end
	
	game.surfaces.nauvis.set_tiles(tiles)
	
	local entities = game.surfaces.nauvis.find_entities({ { centerPosition.x - (config.DistanceBetweenSpawns + 100) , centerPosition.y - (config.DistanceBetweenSpawns + 100) }, { centerPosition.x + (config.DistanceBetweenSpawns + 100) , centerPosition.y + (config.DistanceBetweenSpawns + 100) } })
	for _, ent in ipairs(entities) do
		if ent.force.name == "enemy" or ent.force.name == "neutral" then
			ent.destroy()
		end
	end
	
	CreateResourcesAtSpawn(player, centerPosition)
end

--[[ Main function to both setup and teleport a player to a /random/ spawn ]]--
function SetupPlayerSpawn(player)
	local spawnPos = GetNewSpawnLocation(player)
	if spawnPos ~= nil then
		global.players[player.index] = {
			spawnPosition = spawnPos
		}
		
		game.create_force(player.name .. "_force")
		player.force = game.forces[player.name .. "_force"]
		game.forces[player.name .. "_force"].set_spawn_position(spawnPos, "nauvis")
		PrepareSpawn(player, spawnPos)
		player.teleport(spawnPos, "nauvis")
		game.forces[player.name .. "_force"].clear_chart()
		game.forces[player.name .. "_force"].chart("nauvis", { {x = spawnPos.x - math.ceil(config.DistanceBetweenSpawns / 2), y = spawnPos.y - math.ceil(config.DistanceBetweenSpawns / 2)}, { x = spawnPos.x + math.ceil(config.DistanceBetweenSpawns / 2), y = spawnPos.y + math.ceil(config.DistanceBetweenSpawns / 2) } })
		
		player.print("You spawned at {" .. spawnPos.x .. ", " .. spawnPos.y .. "}")
	end
end

--[[ Helper function to print a test to all players ]]--
function xPrint(text)
	for _, player in pairs(game.players) do
		player.print(text)
	end
	consolePrint(text)
end

--[[ on_init event handler ]]--
function on_init()
	if global.players == nil then
		global.players = {}
	end
end

--[[ on_configuration_changed event handler ]]--
function on_configuration_changed()
	if global.players == nil then
		global.players = {}
	end
end

--[[ on_player_joined_game event handler ]]--
function on_player_joined_game(event)
	local player = game.players[event.player_index]
	
	if global.players[player.index] == nil then
		SetupPlayerSpawn(player)
	end
end

--[[ on_chunk_generated event handler ]]--
function on_chunk_generated(event)
	local lt = event.area.left_top
	local rb = event.area.right_bottom
	
	if IsInSpawnArea(lt) or IsInSpawnArea(rb) then
		ClearEnemiesInArea(lt, 16)
		ClearEnemiesInArea(rb, 16)
		xPrint("Cleared {" .. lt.x .. ", " .. lt.y .. "} - {" .. rb.x .. ", " .. rb.y .. "}")
	end
end


--[[ Area to setup event handlers ]]--
script.on_init(on_init)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
script.on_event(defines.events.on_chunk_generated, on_chunk_generated)