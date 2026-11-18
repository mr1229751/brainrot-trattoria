-- World.luau — builds the whole 3D island from primitives at server start:
-- warm sand/cream two-tone plaza island, the central conveyor, eight pastel
-- colour-coded player bases with pedestals, collect pads and laser gates, the
-- golden Rebirth Shrine, spawn points and decorations (palms, pastel arches,
-- lamp posts, floating signs). Also sets the warm midday lighting.
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
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = anchored ~= false
	p.CanCollide = true
	p.Parent = parent
	return p
end

local function makeSign(parent, name, size, cf, text, textSize, textColor)
	local signPart = newPart(parent, name, size, Color3.fromRGB(82, 58, 46), cf, Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.AlwaysOnTop = true
	gui.Parent = signPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 248, 236)
	label.TextSize = textSize or 48
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextStrokeTransparency = 0.25
	label.TextStrokeColor3 = Color3.fromRGB(32, 20, 14)
	label.Parent = gui
	return signPart, label
end

local function buildIsland(workspaceFolder)
	-- Warm sand/cream two-tone plaza tiles: 11-stud tiles across the 220-stud island.
	local tileSize = 11
	local half = Config.ISLAND_SIZE / 2
	local colorA = Color3.fromRGB(238, 224, 198)
	local colorB = Color3.fromRGB(220, 203, 174)
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
			newPart(workspaceFolder, "IslandTile", Vector3.new(tileSize, 1, tileSize), color, CFrame.new(x + tileSize / 2, -0.5, z + tileSize / 2), Enum.Material.SmoothPlastic)
		end
	end
	-- Warm terracotta-stone edge trim framing the plaza terrace.
	local curbColor = Color3.fromRGB(196, 158, 126)
	newPart(workspaceFolder, "IslandCurbNorth", Vector3.new(Config.ISLAND_SIZE + 4, 1.4, 2), curbColor, CFrame.new(0, -0.3, -half - 1), Enum.Material.SmoothPlastic)
	newPart(workspaceFolder, "IslandCurbSouth", Vector3.new(Config.ISLAND_SIZE + 4, 1.4, 2), curbColor, CFrame.new(0, -0.3, half + 1), Enum.Material.SmoothPlastic)
	newPart(workspaceFolder, "IslandCurbWest", Vector3.new(2, 1.4, Config.ISLAND_SIZE), curbColor, CFrame.new(-half - 1, -0.3, 0), Enum.Material.SmoothPlastic)
	newPart(workspaceFolder, "IslandCurbEast", Vector3.new(2, 1.4, Config.ISLAND_SIZE), curbColor, CFrame.new(half + 1, -0.3, 0), Enum.Material.SmoothPlastic)
	-- Calm coastal-blue water skirt below the island edge.
	newPart(workspaceFolder, "Water", Vector3.new(520, 1, 520), Color3.fromRGB(92, 166, 214), CFrame.new(0, -2.5, 0), Enum.Material.SmoothPlastic)
end

local function buildConveyor(workspaceFolder)
	local belt = newPart(workspaceFolder, "ConveyorBelt", Vector3.new(12, 2, 182), Color3.fromRGB(92, 78, 68), CFrame.new(0, 1, 0), Enum.Material.SmoothPlastic)
	belt.CanCollide = true
	-- Warm saffron-brass trim stripes along both edges.
	for z = -88, 88, 6 do
		newPart(workspaceFolder, "HazardStripeL", Vector3.new(1.2, 0.2, 3), Color3.fromRGB(236, 196, 104), CFrame.new(-5.4, 2.05, z), Enum.Material.SmoothPlastic)
		newPart(workspaceFolder, "HazardStripeR", Vector3.new(1.2, 0.2, 3), Color3.fromRGB(236, 196, 104), CFrame.new(5.4, 2.05, z), Enum.Material.SmoothPlastic)
	end
	-- End walls so the belt reads as a machine, not a road.
	newPart(workspaceFolder, "ConveyorEndNorth", Vector3.new(14, 4, 1), Color3.fromRGB(138, 98, 76), CFrame.new(0, 2, -91), Enum.Material.SmoothPlastic)
	newPart(workspaceFolder, "ConveyorEndSouth", Vector3.new(14, 4, 1), Color3.fromRGB(138, 98, 76), CFrame.new(0, 2, 91), Enum.Material.SmoothPlastic)
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
	local plotColor = Color3.fromRGB(246, 239, 226):Lerp(color, 0.38)
	local side = 1
	if center.X < 0 then
		side = -1
	end
	-- Pastel-tinted plot floor.
	newPart(folder, "PlotFloor", Vector3.new(Config.BASE_PLOT_SIZE, 1, Config.BASE_PLOT_SIZE), plotColor, CFrame.new(center.X, 0.5, center.Z), Enum.Material.SmoothPlastic)
	-- Coordinated border curbs (low, so players step over them; the gate is the door).
	local halfPlot = Config.BASE_PLOT_SIZE / 2
	newPart(folder, "BorderNorth", Vector3.new(Config.BASE_PLOT_SIZE, 1.5, 1), color, CFrame.new(center.X, 0.75, center.Z - halfPlot), Enum.Material.SmoothPlastic)
	newPart(folder, "BorderSouth", Vector3.new(Config.BASE_PLOT_SIZE, 1.5, 1), color, CFrame.new(center.X, 0.75, center.Z + halfPlot), Enum.Material.SmoothPlastic)
	newPart(folder, "BorderOuter", Vector3.new(1, 1.5, Config.BASE_PLOT_SIZE), color, CFrame.new(center.X + side * halfPlot, 0.75, center.Z), Enum.Material.SmoothPlastic)
	-- Inner edge: two short walls leaving an 8-stud gate opening at local Z 0.
	newPart(folder, "BorderInnerA", Vector3.new(1, 1.5, 16), color, CFrame.new(center.X - side * halfPlot, 0.75, center.Z - 12), Enum.Material.SmoothPlastic)
	newPart(folder, "BorderInnerB", Vector3.new(1, 1.5, 16), color, CFrame.new(center.X - side * halfPlot, 0.75, center.Z + 12), Enum.Material.SmoothPlastic)

	local base = { Center = center, Side = side, Pedestals = {} }
	-- 12 pedestals with glowing colour-coded rings.
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
			pedestal.Color = Color3.fromRGB(244, 236, 222)
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
	local collectPad = newPart(folder, "CollectPad", Vector3.new(6, 1, 6), Color3.fromRGB(244, 200, 68), CFrame.new(center.X + side * 15, 0.5, center.Z + 15), Enum.Material.Foil)
	collectPad:SetAttribute("BaseIndex", index)
	base.CollectPad = collectPad
	makeSign(folder, "CollectSign", Vector3.new(6, 2.5, 0.5), CFrame.new(center.X + side * 15, 4.5, center.Z + 15) * CFrame.Angles(0, math.rad(180), 0), "COLLECT $$", 32, Color3.fromRGB(255, 224, 115))

	-- Laser gate: two warm stone posts, a top beam, and the laser wall itself (hidden until locked).
	local gateX = center.X - side * halfPlot
	local postA = newPart(folder, "GatePostA", Vector3.new(1, 7, 1), Color3.fromRGB(218, 204, 184), CFrame.new(gateX, 3.5, center.Z - 4.5), Enum.Material.SmoothPlastic)
	newPart(folder, "GatePostB", Vector3.new(1, 7, 1), Color3.fromRGB(218, 204, 184), CFrame.new(gateX, 3.5, center.Z + 4.5), Enum.Material.SmoothPlastic)
	newPart(folder, "GateBeam", Vector3.new(1, 1, 10), Color3.fromRGB(218, 204, 184), CFrame.new(gateX, 7.5, center.Z), Enum.Material.SmoothPlastic)
	local laser = newPart(folder, "GateLaser", Vector3.new(0.5, 6, 8), Color3.fromRGB(240, 75, 75), CFrame.new(gateX, 3.5, center.Z), Enum.Material.Neon)
	laser.CanCollide = false
	laser.Transparency = 1
	base.Gate = postA
	base.GateLaser = laser
	-- Gate countdown sign above the beam.
	local _, gateLabel = makeSign(folder, "GateSign", Vector3.new(9, 3, 0.5), CFrame.new(gateX - side * 1, 9.5, center.Z), "UNLOCKED", 40, Color3.fromRGB(152, 238, 162))
	base.GateSignLabel = gateLabel
	-- Big Lock button beside the gate.
	local lockButton = newPart(folder, "LockButton", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(228, 78, 72), CFrame.new(gateX - side * 2, 1.25, center.Z + 7.5), Enum.Material.SmoothPlastic)
	lockButton:SetAttribute("BaseIndex", index)
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 14
	click.Parent = lockButton
	base.LockButton = lockButton
	makeSign(folder, "LockLabel", Vector3.new(3, 1.5, 0.5), CFrame.new(gateX - side * 2, 3.2, center.Z + 7.5), "LOCK", 32, Color3.fromRGB(255, 248, 236))
	-- Floating owner sign above the gate.
	local _, ownerLabel = makeSign(folder, "OwnerSign", Vector3.new(14, 3, 0.5), CFrame.new(gateX - side * 1, 12.5, center.Z), "EMPTY BASE", 40, Color3.fromRGB(255, 248, 236))
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
	platform.Color = Color3.fromRGB(244, 202, 72)
	platform.Material = Enum.Material.Foil
	platform.Anchored = true
	platform.Parent = folder
	-- Glowing ring of warm gold orbs around the platform.
	for i = 0, 11 do
		local angle = i * math.rad(30)
		local orb = Instance.new("Part")
		orb.Name = "ShrineOrb" .. i
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(1.2, 1.2, 1.2)
		orb.CFrame = CFrame.new(math.cos(angle) * 11, 1.5, 102 + math.sin(angle) * 11)
		orb.Color = Color3.fromRGB(255, 226, 120)
		orb.Material = Enum.Material.Neon
		orb.Anchored = true
		orb.CanCollide = false
		orb.Parent = folder
	end
	local pillar = newPart(folder, "ShrinePillar", Vector3.new(3, 8, 3), Color3.fromRGB(250, 234, 182), CFrame.new(0, 4, 102), Enum.Material.Foil)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Rebirth"
	prompt.ObjectText = "Rebirth Shrine"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.Parent = pillar
	World.ShrinePrompt = prompt
	makeSign(folder, "ShrineSign", Vector3.new(20, 5, 0.5), CFrame.new(0, 11, 102), "REBIRTH SHRINE", 44, Color3.fromRGB(255, 226, 120))
	World.Shrine = folder
end

local function buildDecorations(workspaceFolder)
	local folder = Instance.new("Folder")
	folder.Name = "Decorations"
	folder.Parent = workspaceFolder
	-- Palm trees flanking the island and plaza edges.
	local palmSpots = {
		Vector3.new(-70, 0, -80), Vector3.new(70, 0, -80),
		Vector3.new(-70, 0, 80), Vector3.new(70, 0, 80),
		Vector3.new(-95, 0, -20), Vector3.new(95, 0, -20),
		Vector3.new(-95, 0, 20), Vector3.new(95, 0, 20),
		Vector3.new(-88, 0, -58), Vector3.new(88, 0, -58),
		Vector3.new(-88, 0, 58), Vector3.new(88, 0, 58),
		Vector3.new(-36, 0, 98), Vector3.new(36, 0, 98),
	}
	for i, spot in ipairs(palmSpots) do
		local trunk = Instance.new("Part")
		trunk.Name = "PalmTrunk" .. i
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(9, 1.4, 1.4)
		trunk.CFrame = CFrame.new(spot.X, 4.5, spot.Z) * CFrame.Angles(0, 0, math.rad(90))
		trunk.Color = Color3.fromRGB(158, 112, 70)
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
			leafPart.Color = Color3.fromRGB(98, 186, 98)
			leafPart.Material = Enum.Material.SmoothPlastic
			leafPart.Anchored = true
			leafPart.Parent = folder
		end
		local coconut = Instance.new("Part")
		coconut.Name = "Coconut" .. i
		coconut.Shape = Enum.PartType.Ball
		coconut.Size = Vector3.new(1, 1, 1)
		coconut.CFrame = CFrame.new(spot.X + 0.8, 8.6, spot.Z)
		coconut.Color = Color3.fromRGB(122, 82, 46)
		coconut.Material = Enum.Material.SmoothPlastic
		coconut.Anchored = true
		coconut.Parent = folder
	end
	-- Pastel Italian festival arch over the conveyor's north start.
	local archColors = {
		Color3.fromRGB(238, 140, 126), Color3.fromRGB(246, 184, 136), Color3.fromRGB(250, 226, 150),
		Color3.fromRGB(162, 216, 166), Color3.fromRGB(154, 200, 238), Color3.fromRGB(204, 170, 230),
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
			seg.Material = Enum.Material.SmoothPlastic
			seg.Anchored = true
			seg.CanCollide = false
			seg.Parent = folder
		end
	end
	-- Matching pastel arch over the shrine approach at the south end.
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
			seg.Material = Enum.Material.SmoothPlastic
			seg.Anchored = true
			seg.CanCollide = false
			seg.Parent = folder
		end
	end
	-- Warm wrought-iron lamp posts along the conveyor and outer plaza edges.
	local lampSpots = {
		Vector3.new(-9, 0, -60), Vector3.new(9, 0, -60),
		Vector3.new(-9, 0, -30), Vector3.new(9, 0, -30),
		Vector3.new(-9, 0, 0), Vector3.new(9, 0, 0),
		Vector3.new(-9, 0, 30), Vector3.new(9, 0, 30),
		Vector3.new(-9, 0, 60), Vector3.new(9, 0, 60),
		Vector3.new(-62, 0, -75), Vector3.new(62, 0, -75),
		Vector3.new(-62, 0, -15), Vector3.new(62, 0, -15),
		Vector3.new(-62, 0, 15), Vector3.new(62, 0, 15),
		Vector3.new(-62, 0, 75), Vector3.new(62, 0, 75),
		Vector3.new(-22, 0, 96), Vector3.new(22, 0, 96),
	}
	for _, spot in ipairs(lampSpots) do
		newPart(folder, "LampPole", Vector3.new(0.6, 7, 0.6), Color3.fromRGB(76, 66, 58), CFrame.new(spot.X, 3.5, spot.Z), Enum.Material.Metal)
		local lamp = Instance.new("Part")
		lamp.Name = "LampBulb"
		lamp.Shape = Enum.PartType.Ball
		lamp.Size = Vector3.new(1.4, 1.4, 1.4)
		lamp.CFrame = CFrame.new(spot.X, 7.4, spot.Z)
		lamp.Color = Color3.fromRGB(255, 236, 178)
		lamp.Material = Enum.Material.Neon
		lamp.Anchored = true
		lamp.CanCollide = false
		lamp.Parent = folder
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 230, 170)
		light.Range = 14
		light.Brightness = 1.1
		light.Parent = lamp
	end
	-- Floating title sign over the island centre.
	makeSign(folder, "TitleSign", Vector3.new(34, 5.5, 0.5), CFrame.new(0, 19.5, -56), "BRAINROT TRATTORIA", 42, Color3.fromRGB(255, 232, 142))
	-- Food stalls on the outer walkways: counter, pastel-striped awning, sign.
	local stallSpots = {
		{ Pos = Vector3.new(-65, 0, -40), Color = Color3.fromRGB(226, 112, 100), Sign = "GNOCCHI BAR" },
		{ Pos = Vector3.new(65, 0, 0), Color = Color3.fromRGB(118, 192, 126), Sign = "LIMONCELLO STAND" },
		{ Pos = Vector3.new(-65, 0, 40), Color = Color3.fromRGB(238, 190, 92), Sign = "CANNOLI CART" },
	}
	for i, stall in ipairs(stallSpots) do
		local basePos = stall.Pos
		newPart(folder, "StallCounter" .. i, Vector3.new(8, 3, 4), Color3.fromRGB(172, 124, 82), CFrame.new(basePos.X, 1.5, basePos.Z), Enum.Material.Wood)
		for stripe = 0, 3 do
			local stripeColor = stall.Color
			if stripe % 2 == 1 then
				stripeColor = Color3.fromRGB(252, 246, 234)
			end
			newPart(folder, "StallAwning" .. i .. "_" .. stripe, Vector3.new(2, 0.4, 5), stripeColor, CFrame.new(basePos.X - 3 + stripe * 2, 5.2, basePos.Z), Enum.Material.SmoothPlastic)
		end
		newPart(folder, "StallPoleL" .. i, Vector3.new(0.5, 5, 0.5), Color3.fromRGB(112, 78, 50), CFrame.new(basePos.X - 3.8, 2.5, basePos.Z - 2), Enum.Material.Wood)
		newPart(folder, "StallPoleR" .. i, Vector3.new(0.5, 5, 0.5), Color3.fromRGB(112, 78, 50), CFrame.new(basePos.X + 3.8, 2.5, basePos.Z - 2), Enum.Material.Wood)
		makeSign(folder, "StallSign" .. i, Vector3.new(9, 2, 0.5), CFrame.new(basePos.X, 7, basePos.Z), stall.Sign, 28, Color3.fromRGB(255, 248, 236))
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
			puff.Color = Color3.fromRGB(255, 252, 246)
			puff.Material = Enum.Material.SmoothPlastic
			puff.Transparency = 0.18
			puff.Anchored = true
			puff.CanCollide = false
			puff.Parent = folder
		end
	end
	-- Tsunami source wall at the north end.
	local wall = newPart(workspaceFolder, "TsunamiWall", Vector3.new(220, 14, 2), Color3.fromRGB(88, 158, 210), CFrame.new(0, 7, -104), Enum.Material.SmoothPlastic)
	wall.Transparency = 0.4
	makeSign(workspaceFolder, "TsunamiSign", Vector3.new(30, 5, 0.5), CFrame.new(0, 16, -102), "TSUNAMI COMES FROM HERE", 36, Color3.fromRGB(205, 236, 255))
end

function World.buildWorld()
	local workspaceService = game:GetService("Workspace")
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotWorld"
	folder.Parent = workspaceService

	-- Gentle warm midday light, sunny plaza feel, no fog changes.
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 14
	lighting.Brightness = 2
	lighting.Ambient = Color3.fromRGB(196, 182, 160)
	lighting.OutdoorAmbient = Color3.fromRGB(202, 188, 166)
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
		spawn.Color = Color3.fromRGB(228, 212, 186)
		spawn.Material = Enum.Material.SmoothPlastic
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
