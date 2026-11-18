-- World.luau — builds the whole 3D island from primitives at server start:
-- turquoise checkerboard island, the central conveyor with hazard stripes, eight
-- colour-coded player bases with pedestals, collect pads and laser gates, the
-- golden Rebirth Shrine, spawn points and decorations (palms, rainbow arch,
-- lamp posts, floating signs). Also sets the bright midday lighting.
-- Returns a table of handles the other systems use.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local World = {}

World.Bases = {} -- [index] = {Center, Plot, Pedestals={parts}, Gate, GateLaser, GateSign, GateSignLabel, CollectPad, LockButton, OwnerSign, OwnerLabel}
World.Conveyor = nil
World.Shrine = nil
World.ShrinePrompt = nil
World.SpawnLocations = {}

local function newPart(parent, name, size, color, cf, material, anchored)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.CFrame = cf
	p.Material = material or Enum.Material.Plastic
	p.Anchored = anchored ~= false
	p.CanCollide = true
	p.Parent = parent
	return p
end

local function makeSign(parent, name, size, cf, text, textSize, textColor)
	local signPart = newPart(parent, name, size, Color3.fromRGB(40, 40, 55), cf, Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.AlwaysOnTop = true
	gui.Parent = signPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize or 48
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
	return signPart, label
end

local function buildIsland(workspaceFolder)
	-- Checkerboard: two turquoise shades, 11-stud tiles across the 220-stud island.
	local tileSize = 11
	local half = Config.ISLAND_SIZE / 2
	local colorA = Color3.fromRGB(64, 224, 208)
	local colorB = Color3.fromRGB(40, 190, 185)
	local row = 0
	for x = -half, half - tileSize, tileSize do
		row += 1
		local col = 0
		for z = -half, half - tileSize, tileSize do
			col += 1
			local color = colorA
			if (row + col) % 2 == 0 then
				color = colorB
			end
			newPart(workspaceFolder, "IslandTile", Vector3.new(tileSize, 1, tileSize), color, CFrame.new(x + tileSize / 2, -0.5, z + tileSize / 2), Enum.Material.Plastic)
		end
	end
	-- Deep water skirt below the island edge.
	newPart(workspaceFolder, "Water", Vector3.new(400, 1, 400), Color3.fromRGB(20, 110, 190), CFrame.new(0, -2.5, 0), Enum.Material.SmoothPlastic)
end

local function buildConveyor(workspaceFolder)
	local belt = newPart(workspaceFolder, "ConveyorBelt", Vector3.new(12, 2, 182), Color3.fromRGB(60, 60, 70), CFrame.new(0, 1, 0), Enum.Material.SmoothPlastic)
	belt.CanCollide = true
	-- Neon-yellow hazard stripes along both edges.
	for z = -88, 88, 6 do
		newPart(workspaceFolder, "HazardStripeL", Vector3.new(1.2, 0.2, 3), Color3.fromRGB(255, 235, 0), CFrame.new(-5.4, 2.05, z), Enum.Material.Neon)
		newPart(workspaceFolder, "HazardStripeR", Vector3.new(1.2, 0.2, 3), Color3.fromRGB(255, 235, 0), CFrame.new(5.4, 2.05, z), Enum.Material.Neon)
	end
	-- End walls so the belt reads as a machine, not a road.
	newPart(workspaceFolder, "ConveyorEndNorth", Vector3.new(14, 4, 1), Color3.fromRGB(45, 45, 55), CFrame.new(0, 2, -91), Enum.Material.SmoothPlastic)
	newPart(workspaceFolder, "ConveyorEndSouth", Vector3.new(14, 4, 1), Color3.fromRGB(45, 45, 55), CFrame.new(0, 2, 91), Enum.Material.SmoothPlastic)
	World.Conveyor = belt
end

-- Pedestal grid inside a plot, in plot-local coordinates (plot faces the
-- conveyor, so local -X points at the belt for +X-side bases and +X for -X).
local PEDESTAL_COLS = { -12, -4, 4, 12 }
local PEDESTAL_ROWS = { -13, 0, 13 }

local function buildBase(workspaceFolder, index, center)
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. index
	folder.Parent = workspaceFolder
	local color = Config.BASE_COLORS[index]
	local side = 1
	if center.X < 0 then
		side = -1
	end
	-- Plot floor.
	newPart(folder, "PlotFloor", Vector3.new(Config.BASE_PLOT_SIZE, 1, Config.BASE_PLOT_SIZE), Color3.fromRGB(245, 245, 240), CFrame.new(center.X, 0.5, center.Z), Enum.Material.SmoothPlastic)
	-- Neon border walls (low, so players step over them; the gate is the door).
	local halfPlot = Config.BASE_PLOT_SIZE / 2
	newPart(folder, "BorderNorth", Vector3.new(Config.BASE_PLOT_SIZE, 1.5, 1), color, CFrame.new(center.X, 0.75, center.Z - halfPlot), Enum.Material.Neon)
	newPart(folder, "BorderSouth", Vector3.new(Config.BASE_PLOT_SIZE, 1.5, 1), color, CFrame.new(center.X, 0.75, center.Z + halfPlot), Enum.Material.Neon)
	newPart(folder, "BorderOuter", Vector3.new(1, 1.5, Config.BASE_PLOT_SIZE), color, CFrame.new(center.X + side * halfPlot, 0.75, center.Z), Enum.Material.Neon)
	-- Inner edge: two short walls leaving an 8-stud gate opening at local Z 0.
	newPart(folder, "BorderInnerA", Vector3.new(1, 1.5, 16), color, CFrame.new(center.X - side * halfPlot, 0.75, center.Z - 12), Enum.Material.Neon)
	newPart(folder, "BorderInnerB", Vector3.new(1, 1.5, 16), color, CFrame.new(center.X - side * halfPlot, 0.75, center.Z + 12), Enum.Material.Neon)

	local base = { Center = center, Side = side, Pedestals = {} }
	-- 12 glowing pedestals.
	local slot = 0
	for _, rowZ in ipairs(PEDESTAL_ROWS) do
		for _, colX in ipairs(PEDESTAL_COLS) do
			slot += 1
			local px = center.X + side * colX
			local pz = center.Z + rowZ
			local pedestal = Instance.new("Part")
			pedestal.Name = "Pedestal" .. slot
			pedestal.Shape = Enum.PartType.Cylinder
			pedestal.Size = Vector3.new(1.5, 3.6, 3.6)
			pedestal.CFrame = CFrame.new(px, 0.75, pz) * CFrame.Angles(0, 0, math.rad(90))
			pedestal.Color = Color3.fromRGB(230, 230, 240)
			pedestal.Material = Enum.Material.SmoothPlastic
			pedestal.Anchored = true
			pedestal.CanCollide = true
			pedestal:SetAttribute("BaseIndex", index)
			pedestal:SetAttribute("Slot", slot)
			pedestal.Parent = folder
			local glowRing = Instance.new("Part")
			glowRing.Name = "PedestalGlow" .. slot
			glowRing.Shape = Enum.PartType.Cylinder
			glowRing.Size = Vector3.new(0.3, 4.0, 4.0)
			glowRing.CFrame = CFrame.new(px, 1.55, pz) * CFrame.Angles(0, 0, math.rad(90))
			glowRing.Color = color
			glowRing.Material = Enum.Material.Neon
			glowRing.Anchored = true
			glowRing.CanCollide = false
			glowRing.Parent = folder
			base.Pedestals[slot] = pedestal
		end
	end
	-- Collect pad in the far corner.
	local collectPad = newPart(folder, "CollectPad", Vector3.new(6, 1, 6), Color3.fromRGB(255, 215, 0), CFrame.new(center.X + side * 15, 0.5, center.Z + 15), Enum.Material.Neon)
	collectPad:SetAttribute("BaseIndex", index)
	base.CollectPad = collectPad
	makeSign(folder, "CollectSign", Vector3.new(6, 2.5, 0.5), CFrame.new(center.X + side * 15, 4.5, center.Z + 15) * CFrame.Angles(0, math.rad(180), 0), "COLLECT $$", 32, Color3.fromRGB(255, 215, 0))

	-- Laser gate: two posts, a top beam, and the laser wall itself (hidden until locked).
	local gateX = center.X - side * halfPlot
	local postA = newPart(folder, "GatePostA", Vector3.new(1, 7, 1), Color3.fromRGB(200, 200, 210), CFrame.new(gateX, 3.5, center.Z - 4.5), Enum.Material.Metal)
	newPart(folder, "GatePostB", Vector3.new(1, 7, 1), Color3.fromRGB(200, 200, 210), CFrame.new(gateX, 3.5, center.Z + 4.5), Enum.Material.Metal)
	newPart(folder, "GateBeam", Vector3.new(1, 1, 10), Color3.fromRGB(200, 200, 210), CFrame.new(gateX, 7.5, center.Z), Enum.Material.Metal)
	local laser = newPart(folder, "GateLaser", Vector3.new(0.5, 6, 8), Color3.fromRGB(255, 40, 40), CFrame.new(gateX, 3.5, center.Z), Enum.Material.Neon)
	laser.Transparency = 0.35
	laser.CanCollide = false
	laser.Transparency = 1
	base.Gate = postA
	base.GateLaser = laser
	-- Gate countdown sign above the beam.
	local _, gateLabel = makeSign(folder, "GateSign", Vector3.new(9, 3, 0.5), CFrame.new(gateX - side * 1, 9.5, center.Z), "UNLOCKED", 40, Color3.fromRGB(120, 255, 120))
	base.GateSignLabel = gateLabel
	-- Big Lock button beside the gate.
	local lockButton = newPart(folder, "LockButton", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(255, 60, 60), CFrame.new(gateX - side * 2, 1.25, center.Z + 7.5), Enum.Material.Neon)
	lockButton:SetAttribute("BaseIndex", index)
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 14
	click.Parent = lockButton
	base.LockButton = lockButton
	makeSign(folder, "LockLabel", Vector3.new(3, 1.5, 0.5), CFrame.new(gateX - side * 2, 3.2, center.Z + 7.5), "LOCK", 32, Color3.fromRGB(255, 255, 255))
	-- Floating owner sign above the gate.
	local _, ownerLabel = makeSign(folder, "OwnerSign", Vector3.new(14, 3, 0.5), CFrame.new(gateX - side * 1, 12.5, center.Z), "EMPTY BASE", 40, Color3.fromRGB(255, 255, 255))
	base.OwnerLabel = ownerLabel
	World.Bases[index] = base
end

local function buildShrine(workspaceFolder)
	local folder = Instance.new("Folder")
	folder.Name = "RebirthShrine"
	folder.Parent = workspaceFolder
	local platform = Instance.new("Part")
	platform.Name = "ShrinePlatform"
	platform.Shape = Enum.PartType.Cylinder
	platform.Size = Vector3.new(2, 18, 18)
	platform.CFrame = CFrame.new(0, 1, 102) * CFrame.Angles(0, 0, math.rad(90))
	platform.Color = Color3.fromRGB(255, 215, 0)
	platform.Material = Enum.Material.Foil
	platform.Anchored = true
	platform.Parent = folder
	-- Glowing ring of gold orbs around the platform.
	for i = 0, 11 do
		local angle = i * math.rad(30)
		local orb = Instance.new("Part")
		orb.Name = "ShrineOrb" .. i
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(1.2, 1.2, 1.2)
		orb.CFrame = CFrame.new(math.cos(angle) * 11, 1.5, 102 + math.sin(angle) * 11)
		orb.Color = Color3.fromRGB(255, 220, 80)
		orb.Material = Enum.Material.Neon
		orb.Anchored = true
		orb.CanCollide = false
		orb.Parent = folder
	end
	local pillar = newPart(folder, "ShrinePillar", Vector3.new(3, 8, 3), Color3.fromRGB(255, 240, 180), CFrame.new(0, 4, 102), Enum.Material.Foil)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Rebirth"
	prompt.ObjectText = "Rebirth Shrine"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.Parent = pillar
	World.ShrinePrompt = prompt
	makeSign(folder, "ShrineSign", Vector3.new(20, 5, 0.5), CFrame.new(0, 11, 102), "REBIRTH SHRINE", 44, Color3.fromRGB(255, 215, 0))
	World.Shrine = folder
end

local function buildDecorations(workspaceFolder)
	local folder = Instance.new("Folder")
	folder.Name = "Decorations"
	folder.Parent = workspaceFolder
	-- Palm trees flanking the island.
	local palmSpots = {
		Vector3.new(-70, 0, -80), Vector3.new(70, 0, -80),
		Vector3.new(-70, 0, 80), Vector3.new(70, 0, 80),
		Vector3.new(-95, 0, -20), Vector3.new(95, 0, -20),
		Vector3.new(-95, 0, 20), Vector3.new(95, 0, 20),
	}
	for i, spot in ipairs(palmSpots) do
		local trunk = Instance.new("Part")
		trunk.Name = "PalmTrunk" .. i
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(9, 1.4, 1.4)
		trunk.CFrame = CFrame.new(spot.X, 4.5, spot.Z) * CFrame.Angles(0, 0, math.rad(90))
		trunk.Color = Color3.fromRGB(140, 95, 50)
		trunk.Material = Enum.Material.Wood
		trunk.Anchored = true
		trunk.Parent = folder
		for leaf = 0, 4 do
			local angle = leaf * math.rad(72)
			local leafPart = Instance.new("Part")
			leafPart.Name = "PalmLeaf" .. i .. "_" .. leaf
			leafPart.Shape = Enum.PartType.Wedge
			leafPart.Size = Vector3.new(0.5, 1.2, 4.5)
			leafPart.CFrame = CFrame.new(spot.X + math.cos(angle) * 2.2, 9.2, spot.Z + math.sin(angle) * 2.2) * CFrame.Angles(math.rad(-25), -angle, 0)
			leafPart.Color = Color3.fromRGB(60, 200, 80)
			leafPart.Material = Enum.Material.SmoothPlastic
			leafPart.Anchored = true
			leafPart.Parent = folder
		end
		local coconut = Instance.new("Part")
		coconut.Name = "Coconut" .. i
		coconut.Shape = Enum.PartType.Ball
		coconut.Size = Vector3.new(1, 1, 1)
		coconut.CFrame = CFrame.new(spot.X + 0.8, 8.6, spot.Z)
		coconut.Color = Color3.fromRGB(110, 70, 30)
		coconut.Material = Enum.Material.SmoothPlastic
		coconut.Anchored = true
		coconut.Parent = folder
	end
	-- Rainbow arch over the conveyor's north start.
	local archColors = {
		Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 150, 40), Color3.fromRGB(255, 235, 0),
		Color3.fromRGB(80, 220, 90), Color3.fromRGB(80, 160, 255), Color3.fromRGB(150, 80, 255),
	}
	for band = 0, 5 do
		for step = 0, 10 do
			local t = step / 10 * math.pi
			local radius = 13 + band * 1.1
			local x = math.cos(t) * radius
			local y = 2 + math.sin(t) * radius
			local seg = Instance.new("Part")
			seg.Name = "RainbowSeg" .. band .. "_" .. step
			seg.Size = Vector3.new(1.2, 1.2, 1.2)
			seg.CFrame = CFrame.new(x, y, -90) * CFrame.Angles(0, 0, -t)
			seg.Color = archColors[band + 1]
			seg.Material = Enum.Material.Neon
			seg.Anchored = true
			seg.CanCollide = false
			seg.Parent = folder
		end
	end
	-- Second rainbow arch over the shrine approach at the south end.
	for band = 0, 5 do
		for step = 0, 10 do
			local t = step / 10 * math.pi
			local radius = 13 + band * 1.1
			local x = math.cos(t) * radius
			local y = 2 + math.sin(t) * radius
			local seg = Instance.new("Part")
			seg.Name = "RainbowSouthSeg" .. band .. "_" .. step
			seg.Size = Vector3.new(1.2, 1.2, 1.2)
			seg.CFrame = CFrame.new(x, y, 90) * CFrame.Angles(0, 0, -t)
			seg.Color = archColors[band + 1]
			seg.Material = Enum.Material.Neon
			seg.Anchored = true
			seg.CanCollide = false
			seg.Parent = folder
		end
	end
	-- Lamp posts along the conveyor.
	for _, z in ipairs({ -60, -30, 0, 30, 60 }) do
		for _, x in ipairs({ -9, 9 }) do
			newPart(folder, "LampPole", Vector3.new(0.6, 7, 0.6), Color3.fromRGB(50, 50, 60), CFrame.new(x, 3.5, z), Enum.Material.Metal)
			local lamp = Instance.new("Part")
			lamp.Name = "LampBulb"
			lamp.Shape = Enum.PartType.Ball
			lamp.Size = Vector3.new(1.4, 1.4, 1.4)
			lamp.CFrame = CFrame.new(x, 7.4, z)
			lamp.Color = Color3.fromRGB(255, 240, 150)
			lamp.Material = Enum.Material.Neon
			lamp.Anchored = true
			lamp.CanCollide = false
			lamp.Parent = folder
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 240, 150)
			light.Range = 14
			light.Brightness = 1.5
			light.Parent = lamp
		end
	end
	-- Floating title sign over the island centre.
	makeSign(folder, "TitleSign", Vector3.new(40, 7, 0.5), CFrame.new(0, 16, -60), "BRAINROT TRATTORIA", 44, Color3.fromRGB(255, 220, 60))
	-- Food stalls on the outer walkways: counter, striped awning, sign.
	local stallSpots = {
		{ Pos = Vector3.new(-65, 0, -40), Color = Color3.fromRGB(255, 80, 80), Sign = "GNOCCHI BAR" },
		{ Pos = Vector3.new(65, 0, 0), Color = Color3.fromRGB(80, 200, 90), Sign = "LIMONCELLO STAND" },
		{ Pos = Vector3.new(-65, 0, 40), Color = Color3.fromRGB(255, 200, 40), Sign = "CANNOLI CART" },
	}
	for i, stall in ipairs(stallSpots) do
		local basePos = stall.Pos
		newPart(folder, "StallCounter" .. i, Vector3.new(8, 3, 4), Color3.fromRGB(150, 100, 60), CFrame.new(basePos.X, 1.5, basePos.Z), Enum.Material.Wood)
		for stripe = 0, 3 do
			local stripeColor = stall.Color
			if stripe % 2 == 1 then
				stripeColor = Color3.fromRGB(255, 255, 255)
			end
			newPart(folder, "StallAwning" .. i .. "_" .. stripe, Vector3.new(2, 0.4, 5), stripeColor, CFrame.new(basePos.X - 3 + stripe * 2, 5.2, basePos.Z), Enum.Material.SmoothPlastic)
		end
		newPart(folder, "StallPoleL" .. i, Vector3.new(0.5, 5, 0.5), Color3.fromRGB(90, 60, 30), CFrame.new(basePos.X - 3.8, 2.5, basePos.Z - 2), Enum.Material.Wood)
		newPart(folder, "StallPoleR" .. i, Vector3.new(0.5, 5, 0.5), Color3.fromRGB(90, 60, 30), CFrame.new(basePos.X + 3.8, 2.5, basePos.Z - 2), Enum.Material.Wood)
		makeSign(folder, "StallSign" .. i, Vector3.new(9, 2, 0.5), CFrame.new(basePos.X, 7, basePos.Z), stall.Sign, 28, Color3.fromRGB(255, 255, 255))
	end
	-- Puffy clouds drifting over the island edges.
	local cloudSpots = {
		Vector3.new(-80, 34, -60), Vector3.new(60, 38, -70), Vector3.new(85, 32, 30),
		Vector3.new(-60, 36, 70), Vector3.new(20, 40, 85), Vector3.new(-90, 33, 10),
	}
	for i, spot in ipairs(cloudSpots) do
		for j, offset in ipairs({ Vector3.new(0, 0, 0), Vector3.new(3, 0.5, 0.5), Vector3.new(-3, 0.3, -0.5), Vector3.new(1.5, 1.2, 0) }) do
			local puff = Instance.new("Part")
			puff.Name = "Cloud" .. i .. "_" .. j
			puff.Shape = Enum.PartType.Ball
			puff.Size = Vector3.new(7, 4, 5)
			puff.CFrame = CFrame.new(spot + offset)
			puff.Color = Color3.fromRGB(255, 255, 255)
			puff.Material = Enum.Material.SmoothPlastic
			puff.Transparency = 0.15
			puff.Anchored = true
			puff.CanCollide = false
			puff.Parent = folder
		end
	end
	-- Tsunami source wall at the north end.
	local wall = newPart(workspaceFolder, "TsunamiWall", Vector3.new(220, 14, 2), Color3.fromRGB(30, 90, 160), CFrame.new(0, 7, -104), Enum.Material.SmoothPlastic)
	wall.Transparency = 0.25
	makeSign(workspaceFolder, "TsunamiSign", Vector3.new(30, 5, 0.5), CFrame.new(0, 16, -102), "TSUNAMI COMES FROM HERE", 36, Color3.fromRGB(120, 200, 255))
end

function World.buildWorld()
	local workspaceService = game:GetService("Workspace")
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotWorld"
	folder.Parent = workspaceService

	-- Bright midday light, saturated, no fog washout.
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 14
	lighting.Brightness = 2
	lighting.Ambient = Color3.fromRGB(180, 180, 180)
	lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
	lighting.GlobalShadows = true
	lighting.FogStart = 100000
	lighting.FogEnd = 100000

	buildIsland(folder)
	buildConveyor(folder)
	for index, center in ipairs(Config.BASE_CENTERS) do
		buildBase(folder, index, center)
	end
	buildShrine(folder)
	buildDecorations(folder)

	-- Spawn points on the outer walkways, one per side.
	for _, x in ipairs({ -75, 75 }) do
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "SpawnPoint"
		spawn.Size = Vector3.new(8, 1, 8)
		spawn.CFrame = CFrame.new(x, 0.5, 0)
		spawn.Color = Color3.fromRGB(120, 255, 120)
		spawn.Material = Enum.Material.Neon
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Anchored = true
		spawn.Parent = folder
		table.insert(World.SpawnLocations, spawn)
	end

	return World
end

-- World position of the top of a pedestal, where a brainrot stands.
function World.getPedestalTopPosition(baseIndex, slot)
	local base = World.Bases[baseIndex]
	if base == nil then
		return nil
	end
	local pedestal = base.Pedestals[slot]
	if pedestal == nil then
		return nil
	end
	return pedestal.Position + Vector3.new(0, 1.55, 0)
end

-- Is a world position inside a base's plot?
function World.isInsideBase(baseIndex, position)
	local base = World.Bases[baseIndex]
	if base == nil then
		return false
	end
	local half = Config.BASE_PLOT_SIZE / 2
	return math.abs(position.X - base.Center.X) <= half and math.abs(position.Z - base.Center.Z) <= half
end

-- Build the island as soon as any server system first requires this module,
-- so no system depends on another script's start order.
World.buildWorld()

return World
