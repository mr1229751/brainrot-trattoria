-- Showcase.server.luau — STUDIO ONLY. Never runs in the live game. Stages the
-- photo scenes for Argon's screenshots with the real character builders:
-- two showcase bases filled with high-rarity brainrots (including a golden
-- Dorato Gorgonzola Galassia), a rarity parade frozen on the conveyor
-- (Common, Epic, Secret Dorato in one view), a dummy avatar mid-steal carrying
-- a glowing Lasagna Leviatano with a [STEALING!] tag beside a gate reading
-- "UNLOCKED 0:04", and the tsunami warning + wave on a repeating loop. Also
-- stages the local player's stats for the photos — REBIRTH x3 and the cash
-- those three rebirths would have cost at the shrine — written into the real
-- PlayerData state, so the HUD, the leaderstats and the $/s rate (with its
-- x4 rebirth multiplier) all show the staged numbers exactly as the live
-- game would show them for a real x3 player.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

if not RunService:IsStudio() then
	return
end

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
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

-- Fill the LOCAL PLAYER'S OWN assigned base with the staged roster, 12/12,
-- through the real placement path (Bases.placeOnPedestal registers the
-- pedestal in that player's own PlayerData state, fires PedestalPlaced so
-- Stealing attaches its prompt, and sets the $/s tag from the real rate) —
-- so the scene is also a working game state and the $/s/HUD numbers match.
-- This must target the base Bases.assignBase gave THIS player
-- (state.BaseIndex), never a fixed base index: the scenery base below is a
-- different base and filling only that one leaves the player's own base
-- empty in the photo. The old version fired one fixed-delay attempt and
-- silently dropped every placement when the base was not assigned yet or
-- Persistence had not finished loading; this version waits for assignment
-- AND load, retries whatever did not land, and is idempotent, so a second
-- call (the top-up pass) only tops up slots that are still empty.
local SHOWCASE_BASE_ROSTER = {
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

local function fillPlayerBase(player)
	local bases = Registry.waitFor("Bases", 10)
	if bases == nil then
		return
	end
	-- Wait until Bases has assigned THIS player a base and Persistence has
	-- finished loading: placing before assignment returns nil (no base), and
	-- placing before the load finishes races the restore that follows it.
	local state = PlayerData.get(player)
	local waited = 0
	while (state == nil or state.BaseIndex == 0 or not state.Loaded) and waited < 30 do
		task.wait(0.25)
		waited += 0.25
		state = PlayerData.get(player)
	end
	if state == nil or state.BaseIndex == 0 then
		warn("[Brainrot Trattoria] Showcase: no base assigned to " .. player.Name .. "; own-base staging skipped.")
		return
	end
	local placed = {}
	local deadline = os.clock() + 30
	while PlayerData.countPedestalsUsed(state) < Config.PEDESTALS_PER_BASE and os.clock() < deadline do
		local progressed = false
		for index, entry in ipairs(SHOWCASE_BASE_ROSTER) do
			if PlayerData.countPedestalsUsed(state) >= Config.PEDESTALS_PER_BASE then
				break
			end
			if not placed[index] then
				local model = Roster.buildCharacter(entry[1], entry[2])
				if bases.placeOnPedestal(player, entry[1], entry[2], model) ~= nil then
					placed[index] = true
					progressed = true
				else
					model:Destroy()
				end
			end
		end
		if not progressed then
			task.wait(0.5)
		end
	end
	print(
		"[Brainrot Trattoria] Showcase staged "
			.. PlayerData.countPedestalsUsed(state)
			.. "/"
			.. Config.PEDESTALS_PER_BASE
			.. " pedestals in "
			.. player.Name
			.. "'s OWN base #"
			.. state.BaseIndex
			.. " (Studio only)."
	)
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
	local scenerySlots = { 1, 5, 9, 2, 6, 10 }
	for i, entry in ipairs(sceneryRoster) do
		local slot = scenerySlots[i] or i
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
	local dummyPos = Vector3.new(10.5, 0, -24)
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
	lasagna:PivotTo(CFrame.new(dummyPos + Vector3.new(0, 7.2, 0)))
	table.insert(showcaseModels, lasagna)
	local gui = Instance.new("BillboardGui")
	gui.Name = "StealTag"
	gui.Size = UDim2.fromOffset(180, 40)
	gui.ExtentsOffsetWorldSpace = Vector3.new(0, 14, 0)
	gui.MaxDistance = 120
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = lasagna.PrimaryPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
	label.Text = "[STEALING!]"
	label.TextColor3 = Color3.fromRGB(255, 85, 80)
	label.TextSize = 20
	label.Font = Enum.Font.GothamBlack
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(24, 16, 16)
	label.Parent = gui
	-- The gate sign next to the scene.
	makeFloatingSign("UNLOCKED 0:04", Vector3.new(14.5, 9.5, -15), Color3.fromRGB(255, 80, 80))
end

local function stageAll()
	-- Rarity parade frozen on the conveyor: Common, Epic, Secret Dorato.
	local conveyor = Registry.waitFor("Conveyor", 10)
	if conveyor ~= nil then
		conveyor.spawnParade("gnocchi", nil, -54)
		conveyor.spawnParade("espresso", nil, -34)
		conveyor.spawnParade("gorgonzola", "dorato", -12)
	end
	fillSceneryBase(4)
	stageStealScene()
	-- Top-up pass for the local player's own base: covers a player who
	-- joined before this script connected its PlayerAdded handler, or whose
	-- first fill raced base assignment / the Persistence load. Idempotent —
	-- fillPlayerBase only places into pedestals that are still free, so the
	-- rival scenery base and any already-staged pedestals are untouched.
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(fillPlayerBase, player)
	end
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

-- Stage the photo stats in the real player state: rebirth count first, then
-- cash. Economy.setCash re-syncs the leaderstats from the state, so one call
-- updates the HUD's cash, its $/s (recomputed with the rebirth multiplier)
-- and the REBIRTH badge the HUD reads from the Rebirths attribute. Waits for
-- Persistence to finish loading first: a late load would otherwise restore
-- the saved cash/rebirths (or the new-player starting values) over the top
-- of the staging. Falls through after 10s if no load ever completes.
local function stagePlayerStats(player)
	local state = PlayerData.get(player)
	local waited = 0
	while (state == nil or not state.Loaded) and waited < 10 do
		task.wait(0.1)
		waited += 0.1
		state = PlayerData.get(player)
	end
	if state == nil then
		return
	end
	local economy = Registry.waitFor("Economy", 10)
	if economy == nil then
		return
	end
	state.Rebirths = Config.SHOWCASE_REBIRTHS
	economy.setCash(player, Config.SHOWCASE_CASH)
	-- Keep the avatar consistent with a real x3 player: Bases re-applies the
	-- rebirth WalkSpeed from the state on every respawn, but the character
	-- that is already standing in the world keeps the speed it spawned with.
	local character = player.Character
	if character ~= nil then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil then
			humanoid.WalkSpeed = 16 * Config.getRebirthSpeedMultiplier(state.Rebirths)
		end
	end
	print("[Brainrot Trattoria] Showcase stats staged for " .. player.Name .. ": REBIRTH x" .. state.Rebirths .. ", cash " .. state.Cash .. " (Studio only).")
end

Players.PlayerAdded:Connect(function(player)
	stagePlayerStats(player)
	task.spawn(function()
		task.wait(2)
		fillPlayerBase(player)
		-- Delayed top-up: if anything cleared or out-raced the first fill,
		-- restore the local player's own base to a full staged 12/12.
		task.wait(6)
		fillPlayerBase(player)
	end)
end)
for _, player in ipairs(Players:GetPlayers()) do
	stagePlayerStats(player)
	task.spawn(function()
		task.wait(2)
		fillPlayerBase(player)
		task.wait(6)
		fillPlayerBase(player)
	end)
end

task.spawn(function()
	task.wait(2)
	stageAll()
end)

Registry.register("Showcase", Showcase)
print("[Brainrot Trattoria] Showcase staging online (Studio only).")
