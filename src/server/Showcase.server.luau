-- Showcase.server.luau — STUDIO ONLY. Never runs in the live game. Stages the
-- photo scenes for Argon's screenshots with the real character builders:
-- two showcase bases filled with high-rarity brainrots (including a golden
-- Dorato Gorgonzola Galassia), a rarity parade frozen on the conveyor
-- (Common, Epic, Secret Dorato in one view), a dummy avatar mid-steal carrying
-- a glowing Lasagna Leviatano with a [STEALING!] tag beside a gate reading
-- "UNLOCKED 0:04", and the tsunami warning + wave on a repeating loop. Also
-- grants the local player showcase cash so every system can be exercised.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

if not RunService:IsStudio() then
	return
end

local Config = require(ReplicatedStorage.Shared.Config)
local Roster = require(ReplicatedStorage.Shared.Roster)
local World = require(script.Parent.World)
local Registry = require(script.Parent.Registry)

local Showcase = {}

local showcaseModels = {}

local function makeFloatingSign(text, position, textColor)
	local signPart = Instance.new("Part")
	signPart.Name = "ShowcaseSign"
	signPart.Size = Vector3.new(12, 3.5, 0.5)
	signPart.CFrame = CFrame.new(position)
	signPart.Color = Color3.fromRGB(40, 40, 55)
	signPart.Material = Enum.Material.SmoothPlastic
	signPart.Anchored = true
	signPart.Parent = Workspace
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.AlwaysOnTop = true
	gui.Parent = signPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextSize = 40
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
	return signPart
end

-- Fill the local player's own base with high-rarity brainrots through the
-- real placement path, so the scene is also a working game state.
local function fillPlayerBase(player)
	local bases = Registry.waitFor("Bases", 10)
	if bases == nil then
		return
	end
	local showcaseRoster = {
		{ "gorgonzola", "dorato" },
		{ "tiramisu", nil },
		{ "moka", "radioactive" },
		{ "prosciutto", nil },
		{ "lasagna", "void" },
		{ "espresso", nil },
		{ "vespa", "dorato" },
		{ "cannoli", nil },
		{ "lasagna", nil },
		{ "espresso", "radioactive" },
		{ "prosciutto", nil },
		{ "tiramisu", nil },
	}
	for _, entry in ipairs(showcaseRoster) do
		local model = Roster.buildCharacter(entry[1], entry[2])
		bases.placeOnPedestal(player, entry[1], entry[2], model)
	end
end

-- Fill a second base as pure scenery (no owner), for the wide base shot.
local function fillSceneryBase(baseIndex)
	local sceneryRoster = {
		{ "gorgonzola", nil },
		{ "tiramisu", "radioactive" },
		{ "moka", nil },
		{ "prosciutto", "dorato" },
		{ "lasagna", nil },
		{ "espresso", nil },
	}
	for i, entry in ipairs(sceneryRoster) do
		local slot = i
		local top = World.getPedestalTopPosition(baseIndex, slot)
		if top ~= nil then
			local model = Roster.buildCharacter(entry[1], entry[2])
			model.Parent = Workspace
			model:PivotTo(CFrame.new(top))
			table.insert(showcaseModels, model)
		end
	end
end

-- A dummy avatar mid-steal: blocky thief, glowing Lasagna overhead, red tag.
local function stageStealScene()
	local base = World.Bases[3]
	if base == nil then
		return
	end
	local thiefFolder = Instance.new("Folder")
	thiefFolder.Name = "ShowcaseThief"
	thiefFolder.Parent = Workspace
	local dummyPos = Vector3.new(11, 0, -20)
	local function dummyPart(name, size, color, offset)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.CFrame = CFrame.new(dummyPos + offset)
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.Parent = thiefFolder
		return p
	end
	dummyPart("Torso", Vector3.new(2, 2, 1), Color3.fromRGB(40, 120, 255), Vector3.new(0, 3, 0))
	local head = dummyPart("Head", Vector3.new(1.4, 1.4, 1.4), Color3.fromRGB(255, 210, 160), Vector3.new(0, 4.7, 0))
	head.Shape = Enum.PartType.Ball
	dummyPart("LegLeft", Vector3.new(0.8, 2, 0.8), Color3.fromRGB(40, 40, 60), Vector3.new(-0.6, 1, 0))
	dummyPart("LegRight", Vector3.new(0.8, 2, 0.8), Color3.fromRGB(40, 40, 60), Vector3.new(0.6, 1, 0))
	dummyPart("ArmLeft", Vector3.new(0.8, 2, 0.8), Color3.fromRGB(40, 120, 255), Vector3.new(-1.5, 3, 0))
	dummyPart("ArmRight", Vector3.new(0.8, 2, 0.8), Color3.fromRGB(40, 120, 255), Vector3.new(1.5, 3, 0))
	-- The stolen Lasagna, glowing, overhead.
	local lasagna = Roster.buildCharacter("lasagna", nil)
	lasagna.Parent = Workspace
	lasagna:PivotTo(CFrame.new(dummyPos + Vector3.new(0, 7.5, 0)))
	table.insert(showcaseModels, lasagna)
	local gui = Instance.new("BillboardGui")
	gui.Name = "StealTag"
	gui.Size = UDim2.fromOffset(260, 60)
	gui.ExtentsOffsetWorldSpace = Vector3.new(0, 7.2, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = lasagna.PrimaryPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
	label.Text = "[STEALING!]"
	label.TextColor3 = Color3.fromRGB(255, 60, 60)
	label.TextSize = 28
	label.Font = Enum.Font.GothamBlack
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = gui
	-- The gate sign next to the scene.
	makeFloatingSign("UNLOCKED 0:04", Vector3.new(15, 10, -16), Color3.fromRGB(255, 80, 80))
end

local function stageAll()
	-- Rarity parade frozen on the conveyor: Common, Epic, Secret Dorato.
	local conveyor = Registry.waitFor("Conveyor", 10)
	if conveyor ~= nil then
		conveyor.spawnParade("gnocchi", nil, -40)
		conveyor.spawnParade("espresso", nil, -20)
		conveyor.spawnParade("gorgonzola", "dorato", 0)
	end
	fillSceneryBase(2)
	stageStealScene()
	-- Gentle bobbing for the scenery models.
	task.spawn(function()
		while true do
			local t = os.clock()
			for _, model in ipairs(showcaseModels) do
				if model.Parent ~= nil then
					Roster.animateModel(model, t)
				end
			end
			task.wait(0.12)
		end
	end)
	-- Tsunami warning + wave on a repeating loop for the capture.
	task.spawn(function()
		while true do
			task.wait(Config.SHOWCASE_TSUNAMI_LOOP_SECONDS)
			local tsunami = Registry.waitFor("Tsunami", 5)
			if tsunami ~= nil then
				tsunami.requestShowcaseCycle()
			end
		end
	end)
end

local function grantShowcaseCash(player)
	task.wait(1)
	local economy = Registry.waitFor("Economy", 10)
	if economy ~= nil then
		economy.setCash(player, Config.SHOWCASE_CASH)
	end
end

Players.PlayerAdded:Connect(function(player)
	grantShowcaseCash(player)
	task.spawn(function()
		task.wait(2)
		fillPlayerBase(player)
	end)
end)
for _, player in ipairs(Players:GetPlayers()) do
	grantShowcaseCash(player)
	task.spawn(function()
		task.wait(2)
		fillPlayerBase(player)
	end)
end

task.spawn(function()
	task.wait(2)
	stageAll()
end)

Registry.register("Showcase", Showcase)
print("[Brainrot Trattoria] Showcase staging online (Studio only).")
