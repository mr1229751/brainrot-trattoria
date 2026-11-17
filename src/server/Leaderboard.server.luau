-- Leaderboard.server.luau — a physical richest-players board by the east spawn,
-- built from primitives with a SurfaceGui, refreshed every 5 seconds from the
-- live player state. A little public glory for the island's richest tycoon.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local Registry = require(script.Parent.Registry)

local Leaderboard = {}

local boardFolder = Instance.new("Folder")
boardFolder.Name = "Leaderboard"
boardFolder.Parent = Workspace

local board = Instance.new("Part")
board.Name = "LeaderboardBoard"
board.Size = Vector3.new(12, 9, 1)
board.CFrame = CFrame.new(75, 5.5, -30) * CFrame.Angles(0, math.rad(-90), 0)
board.Color = Color3.fromRGB(40, 40, 55)
board.Material = Enum.Material.SmoothPlastic
board.Anchored = true
board.Parent = boardFolder

local postLeft = Instance.new("Part")
postLeft.Name = "LeaderboardPostLeft"
postLeft.Size = Vector3.new(1, 5, 1)
postLeft.CFrame = CFrame.new(75, 2.5, -35.5)
postLeft.Color = Color3.fromRGB(120, 80, 40)
postLeft.Material = Enum.Material.Wood
postLeft.Anchored = true
postLeft.Parent = boardFolder

local postRight = Instance.new("Part")
postRight.Name = "LeaderboardPostRight"
postRight.Size = Vector3.new(1, 5, 1)
postRight.CFrame = CFrame.new(75, 2.5, -24.5)
postRight.Color = Color3.fromRGB(120, 80, 40)
postRight.Material = Enum.Material.Wood
postRight.Anchored = true
postRight.Parent = boardFolder

local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front
gui.AlwaysOnTop = true
gui.Parent = board

local title = Instance.new("TextLabel")
title.Name = "BoardTitle"
title.Size = UDim2.new(1, 0, 0.2, 0)
title.BackgroundTransparency = 1
title.Text = "RICHEST TYCOONS"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextSize = 32
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.Parent = gui

local rowLabels = {}
local medals = { "1st", "2nd", "3rd" }
for i = 1, 3 do
	local row = Instance.new("TextLabel")
	row.Name = "BoardRow" .. i
	row.Size = UDim2.new(1, 0, 0.22, 0)
	row.Position = UDim2.new(0, 0, 0.2 + (i - 1) * 0.24, 0)
	row.BackgroundTransparency = 1
	row.Text = medals[i] .. "  ---"
	row.TextColor3 = Color3.fromRGB(255, 255, 255)
	row.TextSize = 28
	row.Font = Enum.Font.GothamBlack
	row.TextScaled = true
	row.Parent = gui
	rowLabels[i] = row
end

local function formatMoney(amount)
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. tostring(math.floor(amount))
	end
end

local function refreshBoard()
	local ranked = {}
	PlayerData.forEach(function(player, state)
		table.insert(ranked, { Name = player.DisplayName, Wealth = state.Cash + state.Uncollected })
	end)
	table.sort(ranked, function(a, b)
		return a.Wealth > b.Wealth
	end)
	for i = 1, 3 do
		local entry = ranked[i]
		if entry ~= nil then
			rowLabels[i].Text = medals[i] .. "  " .. entry.Name .. "  " .. formatMoney(entry.Wealth)
		else
			rowLabels[i].Text = medals[i] .. "  ---"
		end
	end
end

task.spawn(function()
	while true do
		task.wait(5)
		refreshBoard()
	end
end)

Registry.register("Leaderboard", Leaderboard)
print("[Brainrot Trattoria] Leaderboard system online: richest tycoons on the board.")
