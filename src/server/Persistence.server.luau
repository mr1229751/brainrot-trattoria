-- Persistence.server.luau — saves cash, pedestal brainrots (character id +
-- mutation) and rebirths to a DataStore, and restores them on join. Every
-- DataStore call is wrapped in pcall, and the whole module no-ops when the
-- service is unavailable, so Studio runs without API access never error.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local Roster = require(ReplicatedStorage.Shared.Roster)
local Registry = require(script.Parent.Registry)

local Persistence = {}

local STORE_NAME = "BrainrotTrattoria_v1"
local store = nil

local storeOk, gotStore = pcall(function()
	return DataStoreService:GetDataStore(STORE_NAME)
end)
if storeOk then
	store = gotStore
else
	warn("[Brainrot Trattoria] DataStore unavailable; progress will not save this session.")
end

local function waitForState(player, timeout)
	local waited = 0
	while PlayerData.get(player) == nil and waited < timeout do
		task.wait(0.1)
		waited += 0.1
	end
	return PlayerData.get(player)
end

local function loadPlayer(player)
	local state = waitForState(player, 5)
	if state == nil then
		return
	end
	-- Wait until Bases has assigned a plot, so pedestals have somewhere to go.
	local waited = 0
	while state.BaseIndex == 0 and waited < 5 do
		task.wait(0.1)
		waited += 0.1
	end
	local economy = Registry.waitFor("Economy", 5)
	local bases = Registry.waitFor("Bases", 5)
	if store == nil then
		state.Cash = Config.STARTING_CASH
		state.Loaded = true
		if economy ~= nil then
			economy.setCash(player, state.Cash)
		end
		return
	end
	local ok, data = pcall(function()
		return store:GetAsync("player_" .. player.UserId)
	end)
	if not ok or type(data) ~= "table" then
		state.Cash = Config.STARTING_CASH
		state.Loaded = true
		if economy ~= nil then
			economy.setCash(player, state.Cash)
		end
		return
	end
	state.Cash = tonumber(data.Cash) or Config.STARTING_CASH
	state.Rebirths = tonumber(data.Rebirths) or 0
	if economy ~= nil then
		economy.setCash(player, state.Cash)
	end
	if type(data.Pedestals) == "table" and bases ~= nil then
		for _, saved in ipairs(data.Pedestals) do
			if type(saved) == "table" and Roster.getCharacter(saved.CharId) ~= nil then
				bases.restorePedestal(player, saved.CharId, saved.Mutation)
			end
		end
	end
	state.Loaded = true
	print("[Brainrot Trattoria] Loaded save for " .. player.Name .. " (" .. state.Rebirths .. " rebirths).")
end

local function savePlayer(player)
	local state = PlayerData.get(player)
	if state == nil or store == nil then
		return
	end
	local pedestals = {}
	-- Pedestals is sparse (nil holes where brainrots were stolen): scan all
	-- 12 slots numerically, because ipairs stops at the first hole and would
	-- silently leave every later pedestal out of the save.
	for slot = 1, Config.PEDESTALS_PER_BASE do
		local entry = state.Pedestals[slot]
		if entry ~= nil then
			table.insert(pedestals, { CharId = entry.CharId, Mutation = entry.Mutation })
		end
	end
	local data = {
		Cash = math.floor(state.Cash),
		Rebirths = state.Rebirths,
		Pedestals = pedestals,
	}
	local ok, err = pcall(function()
		store:SetAsync("player_" .. player.UserId, data)
	end)
	if not ok then
		warn("[Brainrot Trattoria] Save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(loadPlayer, player)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayer(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayer(player)
	end
end)

-- Autosave once a minute.
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayer(player)
		end
	end
end)

Registry.register("Persistence", Persistence)
print("[Brainrot Trattoria] Persistence system online (DataStore " .. STORE_NAME .. ").")
