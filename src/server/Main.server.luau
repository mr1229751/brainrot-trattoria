-- Main.server.luau — wires all systems. The world builds itself the first time
-- any system requires World; each system registers in Registry at start-up.
-- Main waits for every core system, then prints the ready banner. If a system
-- never registers, the warning names it instead of failing silently.

local Registry = require(script.Parent.Registry)

local CORE_SYSTEMS = { "Bases", "Economy", "Conveyor", "Stealing", "Tsunami", "Rebirth", "Persistence", "Announcements", "Leaderboard", "Celebrations", "Tips" }

task.spawn(function()
	task.wait(1)
	local missing = {}
	for _, name in ipairs(CORE_SYSTEMS) do
		if Registry.waitFor(name, 10) == nil then
			table.insert(missing, name)
		end
	end
	if #missing > 0 then
		warn("[Brainrot Trattoria] MISSING systems: " .. table.concat(missing, ", "))
	else
		print("[Brainrot Trattoria] All systems online. Welcome to the Trattoria!")
	end
end)
