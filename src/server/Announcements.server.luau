-- Announcements.server.luau — the town crier. Rare brainrots rolling onto the
-- conveyor, mutations, rebirths and the tsunami warning all get a big banner
-- on every player's screen, so the island always feels alive. The HUD listens
-- on the AnnounceEvent remote and shows each message for a few seconds.

local Registry = require(script.Parent.Registry)

local Announcements = {}

-- Send a banner to every player. `color` tints the banner text.
function Announcements.announceAll(text, color)
	local remotes = Registry.Remotes
	if remotes ~= nil and remotes.AnnounceEvent ~= nil then
		remotes.AnnounceEvent:FireAllClients(text, color)
	end
end

-- Send a banner to one player only (e.g. why their purchase failed). The HUD
-- renders FireClient on the same remote exactly like a global announcement.
function Announcements.notifyPlayer(player, text, color)
	local remotes = Registry.Remotes
	if remotes ~= nil and remotes.AnnounceEvent ~= nil then
		remotes.AnnounceEvent:FireClient(player, text, color)
	end
end

-- A brainrot worth shouting about just rolled onto the belt.
function Announcements.announceSpawn(charDef, mutationId)
	if charDef == nil then
		return
	end
	local rarity = charDef.Rarity
	if rarity == "Rare" or rarity == "Epic" or rarity == "Legendary" or rarity == "Mythic" or rarity == "Secret" then
		local text = "A " .. string.upper(rarity) .. " " .. charDef.Name .. " rolled onto the conveyor!"
		local color = Color3.fromRGB(255, 220, 60)
		if rarity == "Secret" then
			color = Color3.fromRGB(180, 100, 255)
			text = "SECRET ALERT: " .. charDef.Name .. " is on the conveyor!"
		end
		Announcements.announceAll(text, color)
	elseif mutationId ~= nil then
		Announcements.announceAll("A MUTATED " .. charDef.Name .. " appeared on the conveyor!", Color3.fromRGB(140, 255, 60))
	end
end

function Announcements.announceRebirth(player, level)
	Announcements.announceAll(player.DisplayName .. " REBIRTHED to level " .. level .. "!", Color3.fromRGB(255, 215, 0))
end

function Announcements.announceSteal(thief, owner, charName)
	Announcements.announceAll(thief.DisplayName .. " stole " .. charName .. " from " .. owner.DisplayName .. "!", Color3.fromRGB(255, 80, 80))
end

Registry.register("Announcements", Announcements)
print("[Brainrot Trattoria] Announcements system online: rare spawns get a banner.")
