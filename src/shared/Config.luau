-- Config.luau — every tuning number for Brainrot Trattoria lives here, so the
-- whole game's balance can be read (and rebalanced) from one module.

local Config = {}

-- Economy
Config.STARTING_CASH = 50
Config.INCOME_TICK_SECONDS = 1

-- Bases and locking
Config.BASE_COUNT = 8
Config.PEDESTALS_PER_BASE = 12
Config.LOCK_DURATION_SECONDS = 60
Config.BASE_COLORS = {
	Color3.fromRGB(232, 118, 112), -- terracotta coral
	Color3.fromRGB(112, 172, 232), -- capri blue
	Color3.fromRGB(118, 206, 138), -- pistachio green
	Color3.fromRGB(240, 198, 92), -- amalfi lemon
	Color3.fromRGB(182, 136, 228), -- wisteria lavender
	Color3.fromRGB(238, 154, 102), -- apricot peach
	Color3.fromRGB(106, 200, 198), -- adriatic seafoam
	Color3.fromRGB(236, 138, 182), -- gelato rose
}

-- Conveyor
Config.CONVEYOR_SPEED = 6 -- studs per second
Config.CONVEYOR_SPAWN_INTERVAL = 4 -- seconds between spawn attempts
Config.CONVEYOR_MAX_ON_BELT = 8
Config.CONVEYOR_START_Z = -88
Config.CONVEYOR_END_Z = 88

-- Stealing
Config.STEAL_SLOW_MULTIPLIER = 0.75 -- thief walks 25% slower while carrying
Config.STEAL_HOLD_DURATION = 0.5 -- seconds on the steal prompt

-- Tsunami
Config.TSUNAMI_PERIOD_SECONDS = 180
Config.TSUNAMI_WARNING_SECONDS = 10
Config.TSUNAMI_WAVE_SPEED = 22 -- studs per second along the conveyor

-- Rebirth
Config.REBIRTH_BASE_COST = 25000000
Config.REBIRTH_COST_MULTIPLIER = 8 -- cost = base * 8 ^ rebirths
Config.REBIRTH_INCOME_BONUS_PER = 1.0 -- +100% income per rebirth
Config.REBIRTH_SPEED_BONUS_PER = 0.10 -- +10% WalkSpeed per rebirth
Config.REBIRTH_LUCK_MULTIPLIER_PER = 1.5 -- x1.5 mutation luck per rebirth

-- Showcase (Studio only)
Config.SHOWCASE_CASH = 10000000
Config.SHOWCASE_TSUNAMI_LOOP_SECONDS = 45

-- World layout
Config.ISLAND_SIZE = 220
Config.BASE_PLOT_SIZE = 40
Config.BASE_CENTERS = {
	Vector3.new(35, 0, -67.5),
	Vector3.new(-35, 0, -67.5),
	Vector3.new(35, 0, -22.5),
	Vector3.new(-35, 0, -22.5),
	Vector3.new(35, 0, 22.5),
	Vector3.new(-35, 0, 22.5),
	Vector3.new(35, 0, 67.5),
	Vector3.new(-35, 0, 67.5),
}

-- Rebirth cost for a player who already has `rebirths` rebirths.
function Config.getRebirthCost(rebirths)
	return Config.REBIRTH_BASE_COST * (Config.REBIRTH_COST_MULTIPLIER ^ rebirths)
end

-- Income multiplier from rebirths: +100% per rebirth.
function Config.getRebirthIncomeMultiplier(rebirths)
	return 1 + rebirths * Config.REBIRTH_INCOME_BONUS_PER
end

-- WalkSpeed multiplier from rebirths: +10% per rebirth.
function Config.getRebirthSpeedMultiplier(rebirths)
	return 1 + rebirths * Config.REBIRTH_SPEED_BONUS_PER
end

-- Mutation luck multiplier from rebirths: x1.5 per rebirth.
function Config.getRebirthLuckMultiplier(rebirths)
	return Config.REBIRTH_LUCK_MULTIPLIER_PER ^ rebirths
end

return Config
