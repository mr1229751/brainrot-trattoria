-- Stealing.server.luau — the heist. Every brainrot placed on a pedestal gets a
-- Steal prompt. A rival who triggers it at an UNLOCKED base lifts the brainrot
-- overhead (big red [STEALING!] tag, 25% slower) and must reach their own base
-- to claim it. If the owner touches the carried brainrot, it drops straight
-- back onto the owner's pedestal. Locked bases cannot be stolen from at all.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local World = require(script.Parent.World)
local Registry = require(script.Parent.Registry)

local Stealing = {}

local function refreshWalkSpeed(player, carrying)
	local state = PlayerData.get(player)
	if state == nil then
		return
	end
	local character = player.Character
	if character == nil then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return
	end
	local speed = 16 * Config.getRebirthSpeedMultiplier(state.Rebirths)
	if carrying then
		speed *= Config.STEAL_SLOW_MULTIPLIER
	end
	humanoid.WalkSpeed = speed
end

local function addStealTag(model)
	local old = model.PrimaryPart:FindFirstChild("StealTag")
	if old ~= nil then
		old:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "StealTag"
	gui.Size = UDim2.fromOffset(260, 60)
	gui.ExtentsOffsetWorldSpace = Vector3.new(0, 7.2, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = model.PrimaryPart
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
end

local function removeStealTag(model)
	if model.PrimaryPart ~= nil then
		local tag = model.PrimaryPart:FindFirstChild("StealTag")
		if tag ~= nil then
			tag:Destroy()
		end
	end
end

-- Return the carried brainrot to its owner's pedestal (or the floor at their
-- base when every pedestal is full). Called on owner touch, thief death,
-- leaving, and the tsunami sweep.
function Stealing.dropCarried(player)
	local state = PlayerData.get(player)
	if state == nil or state.Carrying == nil then
		return
	end
	local carried = state.Carrying
	state.Carrying = nil
	state.CarryingFrom = nil
	removeStealTag(carried.Model)
	refreshWalkSpeed(player, false)
	local bases = Registry.waitFor("Bases", 5)
	if bases == nil then
		return
	end
	local owner = carried.FromOwner
	local placed = bases.placeOnPedestal(owner, carried.CharId, carried.Mutation, carried.Model)
	if placed == nil then
		-- Owner's base is full: set the brainrot down at the owner's feet.
		local ownerState = PlayerData.get(owner)
		if ownerState ~= nil and ownerState.BaseIndex > 0 then
			local base = World.Bases[ownerState.BaseIndex]
			if base ~= nil then
				carried.Model:PivotTo(CFrame.new(base.Center.X, 1, base.Center.Z))
			end
		end
	end
end

local function startCarrying(thief, owner, slot, entry)
	local thiefState = PlayerData.get(thief)
	if thiefState == nil or thiefState.Carrying ~= nil then
		return false
	end
	thiefState.Carrying = {
		Model = entry.Model,
		CharId = entry.CharId,
		Mutation = entry.Mutation,
		FromOwner = owner,
		FromSlot = slot,
	}
	thiefState.CarryingFrom = { Owner = owner, Slot = slot }
	addStealTag(entry.Model)
	refreshWalkSpeed(thief, true)
	-- The owner can win it back with a touch.
	local primary = entry.Model.PrimaryPart
	primary.Touched:Connect(function(hit)
		local character = hit.Parent
		if character == nil then
			return
		end
		local toucher = Players:GetPlayerFromCharacter(character)
		if toucher == owner and PlayerData.get(thief) ~= nil and PlayerData.get(thief).Carrying ~= nil then
			Stealing.dropCarried(thief)
		end
	end)
	return true
end

local function attachStealPrompt(owner, slot, model)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Steal Brainrot"
	prompt.ObjectText = model.Name
	prompt.HoldDuration = Config.STEAL_HOLD_DURATION
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(thief)
		if thief == owner then
			return
		end
		local bases = Registry.waitFor("Bases", 5)
		if bases == nil then
			return
		end
		if bases.isLocked(owner) then
			return
		end
		local ownerState = PlayerData.get(owner)
		if ownerState == nil then
			return
		end
		local entry = ownerState.Pedestals[slot]
		if entry == nil or entry.Model ~= model then
			return
		end
		local thiefState = PlayerData.get(thief)
		if thiefState == nil or thiefState.Carrying ~= nil or thiefState.BaseIndex == 0 then
			return
		end
	local lifted = bases.liftFromPedestal(owner, slot)
		if lifted == nil then
			return
		end
		if startCarrying(thief, owner, slot, lifted) then
			local announcements = Registry.get("Announcements")
			if announcements ~= nil then
				announcements.announceSteal(thief, owner, lifted.Model.Name)
			end
		end
	end)
end

-- Every placed brainrot gets its steal prompt.
Registry.Events.PedestalPlaced.Event:Connect(function(owner, slot, model)
	attachStealPrompt(owner, slot, model)
end)

-- Carry loop: hold the loot overhead, claim it on reaching your own base.
RunService.Heartbeat:Connect(function()
	local t = os.clock()
	PlayerData.forEach(function(player, state)
		local carried = state.Carrying
		if carried == nil or carried.Model == nil or carried.Model.Parent == nil then
			return
		end
		local character = player.Character
		if character == nil then
			return
		end
		local head = character:FindFirstChild("Head")
		local root = character:FindFirstChild("HumanoidRootPart")
		if head == nil or root == nil then
			return
		end
		carried.Model:PivotTo(CFrame.new(head.Position + Vector3.new(0, 4.5, 0)))
		local roster = require(ReplicatedStorage.Shared.Roster)
		roster.animateModel(carried.Model, t)
		-- Home safe: claim it onto your own first free pedestal.
		if state.BaseIndex > 0 and World.isInsideBase(state.BaseIndex, root.Position) then
			local bases = Registry.waitFor("Bases", 2)
			if bases ~= nil then
				local slot = PlayerData.findFreePedestalSlot(state)
				if slot ~= nil then
					state.Carrying = nil
					state.CarryingFrom = nil
					removeStealTag(carried.Model)
					refreshWalkSpeed(player, false)
					bases.placeOnPedestal(player, carried.CharId, carried.Mutation, carried.Model)
				end
			end
		end
	end)
end)

-- A thief who dies or leaves drops the loot.
Players.PlayerRemoving:Connect(function(player)
	Stealing.dropCarried(player)
end)
local function watchCharacter(player)
	player.CharacterRemoving:Connect(function()
		Stealing.dropCarried(player)
	end)
end
Players.PlayerAdded:Connect(watchCharacter)
for _, player in ipairs(Players:GetPlayers()) do
	watchCharacter(player)
end

Registry.register("Stealing", Stealing)
print("[Brainrot Trattoria] Stealing system online: rivals can lift brainrots from unlocked bases.")
