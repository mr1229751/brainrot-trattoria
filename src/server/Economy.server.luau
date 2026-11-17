-- Economy.server.luau — the money. Every second each pedestal's $/s (times its
-- mutation, times the owner's rebirth multiplier) flows into the player's
-- uncollected earnings; stepping on their base's gold collect pad banks it as
-- cash. Owns leaderstats (Cash and $/s) and the cash helpers every other
-- system spends through. Initial cash comes from Persistence (saved cash, or
-- the starting amount for a new player).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local World = require(script.Parent.World)
local Registry = require(script.Parent.Registry)

local Economy = {}

local collectDebounce = {} -- [player] = os.clock() of last collect

local function getLeaderstats(player)
	local stats = player:FindFirstChild("leaderstats")
	if stats == nil then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player
		local cash = Instance.new("IntValue")
		cash.Name = "Cash"
		cash.Value = 0
		cash.Parent = stats
		local perSecond = Instance.new("IntValue")
		perSecond.Name = "$/s"
		perSecond.Value = 0
		perSecond.Parent = stats
	end
	return stats
end

local function syncLeaderstats(player, state)
	local stats = getLeaderstats(player)
	stats.Cash.Value = math.floor(state.Cash)
	local rate = PlayerData.getBaseIncomePerSecond(state) * Config.getRebirthIncomeMultiplier(state.Rebirths)
	stats["$/s"].Value = math.floor(rate)
	player:SetAttribute("Rebirths", state.Rebirths)
	player:SetAttribute("Uncollected", math.floor(state.Uncollected))
end

function Economy.getCash(player)
	local state = PlayerData.get(player)
	if state == nil then
		return 0
	end
	return state.Cash
end

function Economy.setCash(player, amount)
	local state = PlayerData.get(player)
	if state == nil then
		return
	end
	state.Cash = math.max(0, math.floor(amount))
	syncLeaderstats(player, state)
end

function Economy.addCash(player, amount)
	local state = PlayerData.get(player)
	if state == nil then
		return
	end
	state.Cash += amount
	syncLeaderstats(player, state)
end

-- Returns true and deducts when the player can afford it.
function Economy.spendCash(player, amount)
	local state = PlayerData.get(player)
	if state == nil or state.Cash < amount then
		return false
	end
	state.Cash -= amount
	syncLeaderstats(player, state)
	return true
end

function Economy.getIncomeRate(player)
	local state = PlayerData.get(player)
	if state == nil then
		return 0
	end
	return PlayerData.getBaseIncomePerSecond(state) * Config.getRebirthIncomeMultiplier(state.Rebirths)
end

-- Bank everything the pedestals earned since the last collect.
function Economy.collectUncollected(player)
	local state = PlayerData.get(player)
	if state == nil or state.Uncollected <= 0 then
		return 0
	end
	local amount = math.floor(state.Uncollected)
	state.Uncollected -= amount
	state.Cash += amount
	syncLeaderstats(player, state)
	return amount
end

local function onPlayerAdded(player)
	getLeaderstats(player)
	local state = PlayerData.get(player)
	if state ~= nil then
		syncLeaderstats(player, state)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Collect pads: step on your own gold pad to bank uncollected earnings.
for _, base in ipairs(World.Bases) do
	local pad = base.CollectPad
	pad.Touched:Connect(function(hit)
		local character = hit.Parent
		if character == nil then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		if player == nil then
			return
		end
		local state = PlayerData.get(player)
		if state == nil or state.BaseIndex == 0 then
			return
		end
		if pad:GetAttribute("BaseIndex") ~= state.BaseIndex then
			return
		end
		local now = os.clock()
		if collectDebounce[player] ~= nil and now - collectDebounce[player] < 1 then
			return
		end
		collectDebounce[player] = now
		Economy.collectUncollected(player)
	end)
end

-- The 1-second income tick.
task.spawn(function()
	while true do
		task.wait(Config.INCOME_TICK_SECONDS)
		PlayerData.forEach(function(player, state)
			local rate = Economy.getIncomeRate(player)
			if rate > 0 then
				state.Uncollected += rate * Config.INCOME_TICK_SECONDS
			end
			syncLeaderstats(player, state)
		end)
	end
end)

Registry.register("Economy", Economy)
print("[Brainrot Trattoria] Economy system online: 1s income tick, collect pads live.")
