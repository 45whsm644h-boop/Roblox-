--[[
	MapGenerator
	Bygger banen (grunn, sti, spawn/base-punkter og dekorasjoner) for
	balloon-tower-defense-brettet. Kjør scriptet på nytt for å regenerere
	kartet fra bunnen av (den gamle "GeneratedMap"-mappen slettes først).
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local MAP_FOLDER_NAME = "GeneratedMap"

-- Layout-konfig ------------------------------------------------------------

local PATH_WIDTH = 12
local PATH_Y = 0.5
local GROUND_SIZE = Vector2.new(260, 260)

-- Slangesti fra spawn (første punkt) til base (siste punkt)
local WAYPOINTS = {
	Vector3.new(-100, PATH_Y, -80),
	Vector3.new(70, PATH_Y, -80),
	Vector3.new(70, PATH_Y, -25),
	Vector3.new(-70, PATH_Y, -25),
	Vector3.new(-70, PATH_Y, 30),
	Vector3.new(80, PATH_Y, 30),
	Vector3.new(80, PATH_Y, 90),
}

local COLORS = {
	Grass = Color3.fromRGB(70, 140, 60),
	GrassDark = Color3.fromRGB(58, 120, 50),
	Path = Color3.fromRGB(150, 120, 90),
	Spawn = Color3.fromRGB(70, 200, 100),
	Base = Color3.fromRGB(200, 60, 60),
	Wood = Color3.fromRGB(94, 62, 40),
	Rock = Color3.fromRGB(120, 120, 125),
}

-- Hjelpefunksjoner -----------------------------------------------------------

local function distanceToSegment2D(px, pz, ax, az, bx, bz)
	local abx, abz = bx - ax, bz - az
	local apx, apz = px - ax, pz - az
	local abLenSq = abx * abx + abz * abz
	local t = 0
	if abLenSq > 0 then
		t = math.clamp((apx * abx + apz * abz) / abLenSq, 0, 1)
	end
	local closestX, closestZ = ax + abx * t, az + abz * t
	local dx, dz = px - closestX, pz - closestZ
	return math.sqrt(dx * dx + dz * dz)
end

local function isFarFromPath(point, margin)
	for i = 1, #WAYPOINTS - 1 do
		local a, b = WAYPOINTS[i], WAYPOINTS[i + 1]
		if distanceToSegment2D(point.X, point.Z, a.X, a.Z, b.X, b.Z) < margin then
			return false
		end
	end
	return true
end

-- Bygging --------------------------------------------------------------------

local function buildGround(parent)
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Anchored = true
	ground.Size = Vector3.new(GROUND_SIZE.X, 4, GROUND_SIZE.Y)
	ground.CFrame = CFrame.new(0, -2, 0)
	ground.Color = COLORS.Grass
	ground.Material = Enum.Material.Grass
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.Parent = parent
end

local function buildPathSegment(a, b, parent, index)
	local distance = (b - a).Magnitude
	local midpoint = a:Lerp(b, 0.5)

	local segment = Instance.new("Part")
	segment.Name = ("PathSegment_%02d"):format(index)
	segment.Anchored = true
	segment.Size = Vector3.new(PATH_WIDTH, 0.6, distance + PATH_WIDTH * 0.5)
	segment.CFrame = CFrame.lookAt(midpoint, b)
	segment.Color = COLORS.Path
	segment.Material = Enum.Material.Ground
	segment.TopSurface = Enum.SurfaceType.Smooth
	segment.Parent = parent
end

local function buildPathCorner(point, parent, index)
	local corner = Instance.new("Part")
	corner.Name = ("PathCorner_%02d"):format(index)
	corner.Anchored = true
	corner.Size = Vector3.new(PATH_WIDTH, 0.6, PATH_WIDTH)
	corner.CFrame = CFrame.new(point)
	corner.Color = COLORS.Path
	corner.Material = Enum.Material.Ground
	corner.TopSurface = Enum.SurfaceType.Smooth
	corner.Parent = parent
end

-- Lager selve stien pluss usynlige Waypoint-markører som senere
-- ballong-bevegelses-scriptet kan følge (Path.Waypoint01, Waypoint02, ...).
local function buildPath(parent)
	local pathFolder = Instance.new("Folder")
	pathFolder.Name = "Path"
	pathFolder.Parent = parent

	for i, point in ipairs(WAYPOINTS) do
		local marker = Instance.new("Part")
		marker.Name = ("Waypoint%02d"):format(i)
		marker.Anchored = true
		marker.CanCollide = false
		marker.Transparency = 1
		marker.Size = Vector3.new(1, 1, 1)
		marker.CFrame = CFrame.new(point)
		marker.Parent = pathFolder

		if i < #WAYPOINTS then
			buildPathSegment(point, WAYPOINTS[i + 1], pathFolder, i)
		end
		if i > 1 and i < #WAYPOINTS then
			buildPathCorner(point, pathFolder, i)
		end
	end

	return pathFolder
end

local function buildSpawnAndBase(parent)
	local spawnPad = Instance.new("Part")
	spawnPad.Name = "BalloonSpawn"
	spawnPad.Anchored = true
	spawnPad.CanCollide = false
	spawnPad.Size = Vector3.new(PATH_WIDTH + 4, 0.4, PATH_WIDTH + 4)
	spawnPad.CFrame = CFrame.new(WAYPOINTS[1] + Vector3.new(0, 0.3, 0))
	spawnPad.Color = COLORS.Spawn
	spawnPad.Material = Enum.Material.Neon
	spawnPad.Parent = parent

	local basePad = Instance.new("Part")
	basePad.Name = "BrainrotBase"
	basePad.Anchored = true
	basePad.CanCollide = false
	basePad.Size = Vector3.new(PATH_WIDTH + 6, 0.4, PATH_WIDTH + 6)
	basePad.CFrame = CFrame.new(WAYPOINTS[#WAYPOINTS] + Vector3.new(0, 0.3, 0))
	basePad.Color = COLORS.Base
	basePad.Material = Enum.Material.Neon
	basePad.Parent = parent
end

local function buildTree(position, rng)
	local model = Instance.new("Model")
	model.Name = "Tree"

	local trunkHeight = rng:NextNumber(4, 6)
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Anchored = true
	trunk.Material = Enum.Material.Wood
	trunk.Color = COLORS.Wood
	trunk.Size = Vector3.new(trunkHeight, 1.4, 1.4)
	trunk.CFrame = CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Parent = model

	local leafSize = rng:NextNumber(5, 7)
	local leaves = Instance.new("Part")
	leaves.Name = "Leaves"
	leaves.Shape = Enum.PartType.Ball
	leaves.Anchored = true
	leaves.Material = Enum.Material.Grass
	leaves.Color = COLORS.GrassDark
	leaves.Size = Vector3.new(leafSize, leafSize, leafSize)
	leaves.CFrame = CFrame.new(position + Vector3.new(0, trunkHeight + leafSize / 2.2, 0))
	leaves.Parent = model

	model.PrimaryPart = trunk
	return model
end

local function buildRock(position, rng)
	local rock = Instance.new("Part")
	rock.Name = "Rock"
	rock.Anchored = true
	rock.Material = Enum.Material.Slate
	rock.Color = COLORS.Rock
	local size = rng:NextNumber(2, 4)
	rock.Size = Vector3.new(size, size * rng:NextNumber(0.6, 0.9), size * rng:NextNumber(0.8, 1.1))
	rock.CFrame = CFrame.new(position + Vector3.new(0, rock.Size.Y / 2, 0))
		* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	return rock
end

local function scatterDecorations(parent, treeCount, rockCount)
	local rng = Random.new()
	local decorFolder = Instance.new("Folder")
	decorFolder.Name = "Decorations"
	decorFolder.Parent = parent

	local function place(count, factory)
		local placed, attempts = 0, 0
		while placed < count and attempts < count * 15 do
			attempts += 1
			local x = rng:NextNumber(-GROUND_SIZE.X / 2 + 8, GROUND_SIZE.X / 2 - 8)
			local z = rng:NextNumber(-GROUND_SIZE.Y / 2 + 8, GROUND_SIZE.Y / 2 - 8)
			local point = Vector3.new(x, PATH_Y, z)
			if isFarFromPath(point, PATH_WIDTH) then
				local instance = factory(point, rng)
				instance.Parent = decorFolder
				placed += 1
			end
		end
	end

	place(treeCount, buildTree)
	place(rockCount, buildRock)
end

local function setupAtmosphere()
	Lighting.Ambient = Color3.fromRGB(110, 110, 110)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 150, 130)
	Lighting.Brightness = 3
	Lighting.ClockTime = 14
	Lighting.FogColor = Color3.fromRGB(180, 210, 190)
	Lighting.FogEnd = 700
end

-- Kjøring ----------------------------------------------------------------------

-- Fjerner malens standard "Baseplate"-del. Den ligger på nøyaktig samme
-- høyde som vår egen bakke, noe som gir z-fighting (flimrende/glitchende
-- gress) hvis begge får stå.
local function removeDefaultBaseplate()
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate:Destroy()
	end
end

local function generateMap()
	local existing = Workspace:FindFirstChild(MAP_FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
	removeDefaultBaseplate()

	local mapFolder = Instance.new("Folder")
	mapFolder.Name = MAP_FOLDER_NAME
	mapFolder.Parent = Workspace

	buildGround(mapFolder)
	buildPath(mapFolder)
	buildSpawnAndBase(mapFolder)
	scatterDecorations(mapFolder, 26, 14)
	setupAtmosphere()
end

print("MapGenerator: scriptet kjører, bygger kartet...")

local ok, errorMessage = pcall(generateMap)

if ok then
	print("MapGenerator: ferdig! Se Workspace.GeneratedMap i Explorer.")
else
	warn("MapGenerator feilet: " .. tostring(errorMessage))
end
