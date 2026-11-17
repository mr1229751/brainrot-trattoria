-- Tips.server.luau — a rotating tip on the announcement banner every minute,
-- so new players learn the loop while they play: buy, collect, lock, steal,
-- survive the wave, rebirth. Quiet by design: it never fires during a tsunami
-- warning, when the countdown owns the screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(script.Parent.Registry)

local Tips = {}

local TIPS = {
	"Tip: buy brainrots off the conveyor, then collect your earnings on the gold pad.",
	"Tip: lock your base with the red button before you go hunting.",
	"Tip: a Secret brainrot earns $6,500,000 every second. Watch the belt.",
	"Tip: mutated brainrots pay 3x, 8x or 25x. Gold means Dorato.",
	"Tip: the tsunami comes every 3 minutes. Be inside your base when it hits.",
	"Tip: stealing is faster than saving, but the owner can win it back with a touch.",
	"Tip: rebirth at the golden shrine for a permanent +100% income.",
	"Tip: press GUIDE to see every brainrot, its price and its $/s.",
	"Tip: the richest tycoons stand on the board by the east spawn.",
}

task.spawn(function()
	local index = 0
	while true do
		task.wait(60)
		local status = ReplicatedStorage:FindFirstChild("TsunamiStatus")
		if status ~= nil and string.find(status.Value, "INCOMING") == nil then
			index = (index % #TIPS) + 1
			local announcements = Registry.get("Announcements")
			if announcements ~= nil then
				announcements.announceAll(TIPS[index], Color3.fromRGB(180, 220, 255))
			end
		end
	end
end)

Registry.register("Tips", Tips)
print("[Brainrot Trattoria] Tips system online: a gameplay tip every minute.")
