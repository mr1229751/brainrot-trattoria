-- Conveyor.server.luau — the belt down the middle of the island. Rolls a new
-- brainrot onto it every few seconds (weighted so Commons dominate), carries
-- each one from the north end to the south, and lets any player buy it with a
-- ProximityPrompt when they have the cash and a free pedestal. A bought
-- brainrot rides across to its pedestal. Frozen models (the Showcase parade)
-- sit still on the belt instead of moving.
--
-- Purchase contract: a failed buy always tells the buyer why (no base, base
-- full, not enough cash) instead of failing silently, and once cash is taken
-- the purchase either lands on a pedestal or the cash is refunded in full —
-- a buyer never pays for a brainrot that vanishes mid-delivery.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local Roster = require(ReplicatedStorage.Shared.Roster)
local Registry = require(script.Parent.Registry)

local Conveyor = {}

local beltFolder = nil
local belt = {} -- {Model, CharId, Mutation, Price, Phase, Sold, Claimed, Prompt}

local function removeFromBelt(entry)
	for i, item in ipairs(belt) do
		if item == entry then
			table.remove(belt, i)
			return
		end
	end
end

-- Tell one buyer why a purchase did not go through (the HUD shows the same
-- banner the global announcements use, but only on that player's screen).
local function notifyBuyer(player, text)
	local announcements = Registry.get("Announcements")
	if announcements ~= nil and announcements.notifyPlayer ~= nil then
		announcements.notifyPlayer(player, text, Color3.fromRGB(255, 120, 90))
	end
end

-- Undo a purchase whose delivery failed after the cash was taken: refund in
-- full and destroy the orphaned model so it cannot linger in the world
-- unowned, unsold and still prompting.
local function refundPurchase(player, entry, economy)
	economy.addCash(player, entry.Price)
	if entry.Model ~= nil and entry.Model.Parent ~= nil then
		entry.Model:Destroy()
	end
	notifyBuyer(player, "Purchase failed - refunded " .. Roster.formatMoney(entry.Price))
end

local function attachBuyPrompt(entry)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy " .. Roster.formatMoney(entry.Price)
	prompt.ObjectText = Roster.getCharacter(entry.CharId).Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = entry.Model.PrimaryPart
	entry.Prompt = prompt
	prompt.Triggered:Connect(function(player)
		-- Claim the entry synchronously, before the handler's first yield:
		-- two triggers in the same frame (two buyers, or a double-tap) would
		-- otherwise both pass the Sold check while waitFor yields, and both
		-- get charged for the same brainrot. Any pre-payment failure below
		-- releases the claim so the brainrot stays buyable.
		if entry.Sold or entry.Claimed then
			return
		end
		entry.Claimed = true
		local bases = Registry.waitFor("Bases", 5)
		local economy = Registry.waitFor("Economy", 5)
		if bases == nil or economy == nil then
			entry.Claimed = false
			notifyBuyer(player, "Shop is not ready yet - try again in a moment!")
			return
		end
		if entry.Model.Parent == nil then
			return
		end
		local state = PlayerData.get(player)
		if state == nil or state.BaseIndex == 0 then
			entry.Claimed = false
			notifyBuyer(player, "You need a base before you can buy!")
			return
		end
		if PlayerData.findFreePedestalSlot(state) == nil then
			entry.Claimed = false
			notifyBuyer(player, "Your base is full - no free pedestal!")
			return
		end
		if not economy.spendCash(player, entry.Price) then
			entry.Claimed = false
			notifyBuyer(player, "Not enough cash - this costs " .. Roster.formatMoney(entry.Price) .. "!")
			return
		end
		-- Cash is taken: from here the purchase must land or be refunded.
		entry.Sold = true
		if entry.Prompt ~= nil then
			entry.Prompt:Destroy()
			entry.Prompt = nil
		end
		removeFromBelt(entry)
		local targetSlot = PlayerData.findFreePedestalSlot(state)
		if targetSlot == nil then
			refundPurchase(player, entry, economy)
			return
		end
		local basesModule = bases
		task.spawn(function()
			local world = require(script.Parent.World)
			local top = world.getPedestalTopPosition(state.BaseIndex, targetSlot)
			if top == nil then
				refundPurchase(player, entry, economy)
				return
			end
			local start = entry.Model:GetPivot()
			local finish = CFrame.new(top)
			local steps = 24
			for i = 1, steps do
				if entry.Model.Parent == nil then
					refundPurchase(player, entry, economy)
					return
				end
				local alpha = i / steps
				local arc = math.sin(alpha * math.pi) * 6
				entry.Model:PivotTo(start:Lerp(finish, alpha) * CFrame.new(0, arc, 0))
				task.wait(0.03)
			end
			if entry.Model.Parent == nil then
				refundPurchase(player, entry, economy)
				return
			end
			local placedSlot = basesModule.placeOnPedestal(player, entry.CharId, entry.Mutation, entry.Model)
			if placedSlot == nil then
				refundPurchase(player, entry, economy)
				return
			end
		end)
	end)
end

local function spawnBrainrot(charId, mutationId, z, frozen)
	local def = Roster.getCharacter(charId)
	if def == nil then
		return nil
	end
	local model = Roster.buildCharacter(charId, mutationId)
	model.Parent = beltFolder
	model:PivotTo(CFrame.new(0, 2, z))
	if frozen then
		model:SetAttribute("Frozen", true)
	end
	local entry = {
		Model = model,
		CharId = charId,
		Mutation = mutationId,
		Price = def.Price,
		Phase = math.random() * math.pi * 2,
		Sold = false,
		Claimed = false,
		Prompt = nil,
	}
	table.insert(belt, entry)
	attachBuyPrompt(entry)
	-- Rare and mutated arrivals get a banner for the whole island.
	local announcements = Registry.get("Announcements")
	if announcements ~= nil then
		announcements.announceSpawn(def, mutationId)
	end
	return entry
end

-- A frozen parade model for the Showcase (does not ride the belt).
function Conveyor.spawnParade(charId, mutationId, z)
	return spawnBrainrot(charId, mutationId, z, true)
end

-- Wash every unpurchased brainrot off the belt (the tsunami calls this).
function Conveyor.clearBelt()
	for _, entry in ipairs(belt) do
		if entry.Model ~= nil then
			entry.Model:Destroy()
		end
	end
	table.clear(belt)
end

function Conveyor.getBeltCount()
	return #belt
end

beltFolder = Instance.new("Folder")
beltFolder.Name = "ConveyorBrainrots"
beltFolder.Parent = Workspace

-- Spawn loop: keep the belt stocked, Commons most of all.
task.spawn(function()
	while true do
		task.wait(Config.CONVEYOR_SPAWN_INTERVAL)
		if #belt < Config.CONVEYOR_MAX_ON_BELT then
			local charId = Roster.rollCharacterId()
			local mutationId = Roster.rollMutation(1)
			spawnBrainrot(charId, mutationId, Config.CONVEYOR_START_Z, false)
		end
	end
end)

-- Movement loop: ride south, bob gently, despawn at the end.
RunService.Heartbeat:Connect(function(dt)
	local t = os.clock()
	for i = #belt, 1, -1 do
		local entry = belt[i]
		local model = entry.Model
		if model == nil or model.Parent == nil then
			table.remove(belt, i)
		else
			local pivot = model:GetPivot()
			local z = pivot.Position.Z
			if not model:GetAttribute("Frozen") then
				z += Config.CONVEYOR_SPEED * dt
				if z >= Config.CONVEYOR_END_Z then
					model:Destroy()
					table.remove(belt, i)
				else
					local bob = math.sin(t * 3 + entry.Phase) * 0.12
					model:PivotTo(CFrame.new(0, 2 + bob, z))
					Roster.animateModel(model, t)
				end
			else
				Roster.animateModel(model, t)
			end
		end
	end
end)

Registry.register("Conveyor", Conveyor)
print("[Brainrot Trattoria] Conveyor system online: brainrots ride the belt.")
