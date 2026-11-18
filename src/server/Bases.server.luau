-- Bases.server.luau — owns the eight player bases: assignment on join, pedestal
-- placement, the 60-second laser lock (button in the world + HUD button), the
-- gate countdown signs, and the gentle pedestal bobbing that keeps placed
-- brainrots alive on screen. Registers its public functions in Registry so the
-- Conveyor, Stealing, Rebirth and Persistence systems can call it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local Roster = require(ReplicatedStorage.Shared.Roster)
local World = require(script.Parent.World)
local Registry = require(script.Parent.Registry)

local Bases = {}

local placedFolder = nil
local takenBases = {} -- [baseIndex] = player

local function formatCountdown(secondsLeft)
	local seconds = math.max(0, math.ceil(secondsLeft))
	return string.format("LOCKED 0:%02d", seconds)
end

function Bases.assignBase(player)
	local state = PlayerData.get(player)
	if state == nil then
		return nil
	end
	for index = 1, Config.BASE_COUNT do
		if takenBases[index] == nil then
			takenBases[index] = player
			state.BaseIndex = index
			local base = World.Bases[index]
			if base ~= nil and base.OwnerLabel ~= nil then
				base.OwnerLabel.Text = string.upper(player.DisplayName) .. "'S BASE"
			end
			return index
		end
	end
	return nil
end

function Bases.releaseBase(player)
	local state = PlayerData.get(player)
	if state == nil then
		return
	end
	local index = state.BaseIndex
	if index > 0 and takenBases[index] == player then
		takenBases[index] = nil
		local base = World.Bases[index]
		if base ~= nil and base.OwnerLabel ~= nil then
			base.OwnerLabel.Text = "EMPTY BASE"
		end
	end
	state.BaseIndex = 0
end

function Bases.isLocked(player)
	local state = PlayerData.get(player)
	if state == nil then
		return false
	end
	return os.clock() < state.LockUntil
end

function Bases.getLockSecondsLeft(player)
	local state = PlayerData.get(player)
	if state == nil then
		return 0
	end
	return math.max(0, state.LockUntil - os.clock())
end

function Bases.lockBase(player)
	local state = PlayerData.get(player)
	if state == nil or state.BaseIndex == 0 then
		return false
	end
	state.LockUntil = os.clock() + Config.LOCK_DURATION_SECONDS
	return true
end

-- Put a brainrot model on the player's first free pedestal. Returns the slot.
function Bases.placeOnPedestal(player, charId, mutationId, model)
	local state = PlayerData.get(player)
	if state == nil or state.BaseIndex == 0 then
		return nil
	end
	local slot = PlayerData.findFreePedestalSlot(state)
	if slot == nil then
		return nil
	end
	local def = Roster.getCharacter(charId)
	if def == nil then
		return nil
	end
	local rate = def.Rate
	if mutationId ~= nil then
		rate = rate * Roster.MUTATIONS[mutationId].Multiplier
	end
	local top = World.getPedestalTopPosition(state.BaseIndex, slot)
	if top == nil then
		return nil
	end
	model.Parent = placedFolder
	model:PivotTo(CFrame.new(top))
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("Slot", slot)
	state.Pedestals[slot] = { CharId = charId, Mutation = mutationId, Model = model, Rate = rate }
	Registry.Events.PedestalPlaced:Fire(player, slot, model)
	return slot
end

-- Build a saved brainrot and put it back on a pedestal (used by Persistence).
function Bases.restorePedestal(player, charId, mutationId)
	local model = Roster.buildCharacter(charId, mutationId)
	return Bases.placeOnPedestal(player, charId, mutationId, model)
end

-- Take a brainrot off a pedestal without destroying it (stealing lifts it out).
function Bases.liftFromPedestal(player, slot)
	local state = PlayerData.get(player)
	if state == nil then
		return nil
	end
	local entry = state.Pedestals[slot]
	if entry == nil then
		return nil
	end
	state.Pedestals[slot] = nil
	Registry.Events.PedestalCleared:Fire(player, slot, entry.Model)
	return entry
end

function Bases.clearPedestalSlot(player, slot)
	local entry = Bases.liftFromPedestal(player, slot)
	if entry ~= nil and entry.Model ~= nil then
		entry.Model:Destroy()
	end
end

function Bases.clearAllPedestals(player)
	local state = PlayerData.get(player)
	if state == nil then
		return
	end
	for slot = 1, Config.PEDESTALS_PER_BASE do
		Bases.clearPedestalSlot(player, slot)
	end
end

local function applyWalkSpeed(player)
	local state = PlayerData.get(player)
	if state == nil then
		return
	end
	local character = player.Character
	if character == nil then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		humanoid.WalkSpeed = 16 * Config.getRebirthSpeedMultiplier(state.Rebirths)
	end
end

local function onPlayerAdded(player)
	PlayerData.newPlayer(player)
	Bases.assignBase(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		applyWalkSpeed(player)
	end)
end

local function onPlayerRemoving(player)
	Bases.clearAllPedestals(player)
	Bases.releaseBase(player)
	PlayerData.remove(player)
end

-- Start-up: folder, gate buttons, HUD lock remote, join/leave, live loop.
placedFolder = Instance.new("Folder")
placedFolder.Name = "PlacedBrainrots"
placedFolder.Parent = Workspace

for _, base in ipairs(World.Bases) do
	local button = base.LockButton
	local detector = button:FindFirstChildOfClass("ClickDetector")
	if detector ~= nil then
		detector.MouseClick:Connect(function(player)
			local state = PlayerData.get(player)
			if state ~= nil and state.BaseIndex > 0 and World.Bases[state.BaseIndex].LockButton == button then
				Bases.lockBase(player)
			end
		end)
	end
end

Registry.Remotes.LockBaseEvent.OnServerEvent:Connect(function(player)
	Bases.lockBase(player)
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Gate signs, laser visibility and pedestal bobbing.
local lastBob = 0
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	PlayerData.forEach(function(player, state)
		if state.BaseIndex > 0 then
			local base = World.Bases[state.BaseIndex]
			if base ~= nil then
				local locked = now < state.LockUntil
				base.GateLaser.Transparency = locked and 0.35 or 1
				if locked then
					base.GateSignLabel.Text = formatCountdown(state.LockUntil - now)
					base.GateSignLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				else
					base.GateSignLabel.Text = "UNLOCKED"
					base.GateSignLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
				end
			end
		end
	end)
	if now - lastBob >= 0.12 then
		lastBob = now
		local t = now
		PlayerData.forEach(function(player, state)
			if state.BaseIndex == 0 then
				return
			end
			for slot = 1, Config.PEDESTALS_PER_BASE do
				local entry = state.Pedestals[slot]
				if entry ~= nil and entry.Model ~= nil and entry.Model.Parent ~= nil then
					local top = World.getPedestalTopPosition(state.BaseIndex, slot)
					if top ~= nil then
						local bob = math.sin(t * 2 + slot * 0.7) * 0.15
						entry.Model:PivotTo(CFrame.new(top + Vector3.new(0, bob, 0)))
						Roster.animateModel(entry.Model, t)
					end
				end
			end
		end)
	end
end)

Registry.register("Bases", Bases)
print("[Brainrot Trattoria] Bases system online: 8 bases, 12 pedestals each.")
