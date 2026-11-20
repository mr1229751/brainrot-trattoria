-- Tsunami.server.luau — the wave. Every ~180 seconds a red warning banner and
-- a top countdown bar give players 10 seconds to run home; then a 60-stud
-- translucent blue wave with white foam sweeps down the conveyor from the
-- north wall. Anyone caught outside their own base when the wave front
-- reaches them is swept back to spawn and drops whatever they were carrying;
-- unpurchased brainrots on the belt wash away. Each player is evaluated
-- exactly once per wave, at the moment the wall reaches their position, so
-- nobody is re-teleported over and over while the wave crosses. The HUD
-- reads the countdown from the ReplicatedStorage values here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local World = require(script.Parent.World)
local Registry = require(script.Parent.Registry)

local Tsunami = {}

local statusValue = Instance.new("StringValue")
statusValue.Name = "TsunamiStatus"
statusValue.Value = "Next wave in 3:00"
statusValue.Parent = ReplicatedStorage

local countdownValue = Instance.new("IntValue")
countdownValue.Name = "TsunamiCountdown"
countdownValue.Value = Config.TSUNAMI_PERIOD_SECONDS
countdownValue.Parent = ReplicatedStorage

local showcaseRequested = false

local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", minutes, secs)
end

-- Sweep one player back to spawn if they are outside their own base.
local function sweepPlayer(player, state, root)
	local safe = false
	if state.BaseIndex > 0 then
		safe = World.isInsideBase(state.BaseIndex, root.Position)
	end
	if not safe then
		local stealing = Registry.waitFor("Stealing", 2)
		if stealing ~= nil then
			stealing.dropCarried(player)
		end
		local spawn = World.SpawnLocations[1]
		if spawn ~= nil then
			local character = player.Character
			if character ~= nil then
				character:PivotTo(spawn.CFrame + Vector3.new(0, 3, 0))
			end
		end
	end
end

-- Evaluate every player the wave front has just reached. `swept` is the
-- per-wave set of players already evaluated on this wave: once a player is
-- in it they are never swept (or re-checked) again until the next wave, so
-- a player caught outside is teleported exactly once instead of being
-- pinned to spawn ~20 times a second for the whole crossing.
local function sweepPlayersAt(waveZ, swept)
	PlayerData.forEach(function(player, state)
		if swept[player] then
			return
		end
		local character = player.Character
		if character == nil then
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root == nil then
			return
		end
		if waveZ >= root.Position.Z then
			swept[player] = true
			sweepPlayer(player, state, root)
		end
	end)
end

local function runWave()
	-- The belt's unpurchased brainrots wash away with the wave.
	local conveyor = Registry.waitFor("Conveyor", 5)
	if conveyor ~= nil then
		conveyor.clearBelt()
	end
	local waveFolder = Instance.new("Folder")
	waveFolder.Name = "TsunamiWave"
	waveFolder.Parent = Workspace
	local wall = Instance.new("Part")
	wall.Name = "WaveWall"
	wall.Size = Vector3.new(60, 12, 4)
	wall.Color = Color3.fromRGB(60, 140, 255)
	wall.Material = Enum.Material.Neon
	wall.Transparency = 0.35
	wall.Anchored = true
	wall.CanCollide = false
	wall.Parent = waveFolder
	local foams = {}
	for i = -2, 2 do
		local foam = Instance.new("Part")
		foam.Name = "WaveFoam" .. i
		foam.Shape = Enum.PartType.Cylinder
		foam.Size = Vector3.new(4, 3, 3)
		foam.Color = Color3.fromRGB(255, 255, 255)
		foam.Material = Enum.Material.Neon
		foam.Transparency = 0.2
		foam.Anchored = true
		foam.CanCollide = false
		foam.Parent = waveFolder
		table.insert(foams, { Part = foam, OffsetX = i * 12 })
	end
	local swept = {}
	local z = -104
	while z <= 106 do
		wall.CFrame = CFrame.new(0, 6, z)
		for _, foamEntry in ipairs(foams) do
			foamEntry.Part.CFrame = wall.CFrame * CFrame.new(foamEntry.OffsetX, 6, 0)
		end
		-- The wall is 4 studs thick, so its leading face is 2 studs ahead of
		-- its centre: a player is swept when the face they can see reaches
		-- them, not when the centre line catches up half a step later.
		sweepPlayersAt(z + wall.Size.Z / 2, swept)
		task.wait(0.05)
		z += Config.TSUNAMI_WAVE_SPEED * 0.05
	end
	waveFolder:Destroy()
end

-- One full cycle: warning banner, then the wave. `warningSeconds` is 10 in
-- the live game and shorter when the Showcase stages it.
function Tsunami.runCycle(warningSeconds)
	statusValue.Value = "TSUNAMI INCOMING!"
	countdownValue.Value = warningSeconds
	for remaining = warningSeconds, 1, -1 do
		countdownValue.Value = remaining
		task.wait(1)
	end
	runWave()
end

-- The Showcase asks for an extra cycle between the scheduled ones.
function Tsunami.requestShowcaseCycle()
	showcaseRequested = true
end

task.spawn(function()
	local nextWaveIn = Config.TSUNAMI_PERIOD_SECONDS
	while true do
		task.wait(1)
		if showcaseRequested then
			showcaseRequested = false
			Tsunami.runCycle(5)
			nextWaveIn = Config.TSUNAMI_PERIOD_SECONDS
		else
			nextWaveIn -= 1
			statusValue.Value = "Next wave in " .. formatTime(nextWaveIn)
			countdownValue.Value = nextWaveIn
			if nextWaveIn <= 0 then
				Tsunami.runCycle(Config.TSUNAMI_WARNING_SECONDS)
				nextWaveIn = Config.TSUNAMI_PERIOD_SECONDS
			end
		end
	end
end)

Registry.register("Tsunami", Tsunami)
print("[Brainrot Trattoria] Tsunami system online: a wave every " .. Config.TSUNAMI_PERIOD_SECONDS .. "s.")
