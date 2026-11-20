-- Rebirth.server.luau — the golden shrine at the south end. Pay 25,000,000 x
-- 8^rebirths to reset your cash and pedestals and gain a permanent +100%
-- income per rebirth, +10% WalkSpeed and x1.5 mutation luck. Works from the
-- shrine's ProximityPrompt and from the HUD's Rebirth button. A player who
-- cannot afford it gets a banner naming the price instead of silence.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local Roster = require(ReplicatedStorage.Shared.Roster)
local World = require(script.Parent.World)
local Registry = require(script.Parent.Registry)

local Rebirth = {}

-- Tell one player why their rebirth did not go through (same per-player
-- banner the conveyor's purchase failures use, via Announcements).
local function notifyPlayer(player, text)
	local announcements = Registry.get("Announcements")
	if announcements ~= nil and announcements.notifyPlayer ~= nil then
		announcements.notifyPlayer(player, text, Color3.fromRGB(255, 120, 90))
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

-- Returns true when the rebirth went through.
function Rebirth.attemptRebirth(player)
	local state = PlayerData.get(player)
	if state == nil then
		return false
	end
	local bases = Registry.waitFor("Bases", 5)
	local economy = Registry.waitFor("Economy", 5)
	if bases == nil or economy == nil then
		return false
	end
	local cost = Config.getRebirthCost(state.Rebirths)
	if state.Cash < cost then
		notifyPlayer(player, "Not enough cash - rebirth costs " .. Roster.formatMoney(cost) .. "!")
		return false
	end
	economy.setCash(player, 0)
	state.Uncollected = 0
	bases.clearAllPedestals(player)
	state.Rebirths += 1
	applyWalkSpeed(player)
	economy.setCash(player, 0)
	local announcements = Registry.get("Announcements")
	if announcements ~= nil then
		announcements.announceRebirth(player, state.Rebirths)
	end
	print("[Brainrot Trattoria] " .. player.Name .. " rebirthed to level " .. state.Rebirths .. " (cost " .. cost .. ").")
	return true
end

World.ShrinePrompt.Triggered:Connect(function(player)
	Rebirth.attemptRebirth(player)
end)

Registry.Remotes.RebirthEvent.OnServerEvent:Connect(function(player)
	Rebirth.attemptRebirth(player)
end)

Registry.register("Rebirth", Rebirth)
print("[Brainrot Trattoria] Rebirth system online: shrine sells rebirths from " .. Config.REBIRTH_BASE_COST .. ".")
