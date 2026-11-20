-- PlayerData.luau — the one place player state lives. Every server system reads
-- and writes through this module: cash, uncollected earnings, rebirths, the
-- assigned base, the 12 pedestal slots and the lock timer. Nothing here touches
-- the network; it is plain tables keyed by Player.

local PlayerData = {}

local states = {}

function PlayerData.newPlayer(player)
	local state = {
		Player = player,
		Cash = 0,
		Uncollected = 0,
		Rebirths = 0,
		BaseIndex = 0, -- 0 = not assigned yet
		Pedestals = {}, -- [slot 1..12] = {CharId, Mutation, Model, Rate} or nil
		LockUntil = 0, -- os.clock() timestamp; locked while now < LockUntil
		Carrying = nil, -- model currently carried while stealing, or nil
		CarryingFrom = nil, -- {Owner, Slot} the carried brainrot was stolen from
		Loaded = false, -- true once Persistence has restored saved data
	}
	for slot = 1, 12 do
		state.Pedestals[slot] = nil
	end
	states[player] = state
	return state
end

function PlayerData.get(player)
	return states[player]
end

function PlayerData.remove(player)
	states[player] = nil
end

function PlayerData.forEach(callback)
	for player, state in pairs(states) do
		callback(player, state)
	end
end

-- Total $/s the player's pedestals earn before the rebirth multiplier.
-- Pedestals is a sparse table (a stolen slot leaves a nil hole), so this
-- must scan every slot numerically: ipairs would stop at the first hole
-- and silently drop the income of every pedestal after it.
function PlayerData.getBaseIncomePerSecond(state)
	local total = 0
	for slot = 1, 12 do
		local entry = state.Pedestals[slot]
		if entry ~= nil then
			total += entry.Rate
		end
	end
	return total
end

-- First empty pedestal slot (1..12), or nil when the base is full.
function PlayerData.findFreePedestalSlot(state)
	for slot = 1, 12 do
		if state.Pedestals[slot] == nil then
			return slot
		end
	end
	return nil
end

function PlayerData.countPedestalsUsed(state)
	local count = 0
	for slot = 1, 12 do
		if state.Pedestals[slot] ~= nil then
			count += 1
		end
	end
	return count
end

return PlayerData
