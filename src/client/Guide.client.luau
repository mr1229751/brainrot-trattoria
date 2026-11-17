-- Guide.client.luau — the Brainrotpedia. A toggle button opens a scrolling
-- guide listing all twelve characters with their rarity colour, price and
-- $/s, plus the three mutations and what they multiply. Players learn the
-- ladder without leaving the game; the list is built from the shared Roster
-- data, so it can never drift from the real cast.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roster = require(ReplicatedStorage.Shared.Roster)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotGuide"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function addStroke(instance, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or 2
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Parent = instance
	return stroke
end

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "GuideToggle"
toggleButton.AnchorPoint = Vector2.new(1, 0)
toggleButton.Position = UDim2.new(1, -16, 0, 64)
toggleButton.Size = UDim2.fromOffset(150, 48)
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
toggleButton.Text = "GUIDE"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 22
toggleButton.Font = Enum.Font.GothamBlack
toggleButton.Parent = gui
addStroke(toggleButton, 2)
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 10)
toggleCorner.Parent = toggleButton

local panel = Instance.new("Frame")
panel.Name = "GuidePanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Size = UDim2.fromOffset(520, 560)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
panel.BackgroundTransparency = 0.1
panel.Visible = false
panel.Parent = gui
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel
addStroke(panel, 2)

local title = Instance.new("TextLabel")
title.Name = "GuideTitle"
title.Size = UDim2.new(1, 0, 0, 48)
title.BackgroundTransparency = 1
title.Text = "BRAINROTPEDIA"
title.TextColor3 = Color3.fromRGB(255, 220, 60)
title.TextSize = 30
title.Font = Enum.Font.GothamBlack
title.Parent = panel
addStroke(title, 2)

local closeButton = Instance.new("TextButton")
closeButton.Name = "GuideClose"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -8, 0, 8)
closeButton.Size = UDim2.fromOffset(36, 36)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 22
closeButton.Font = Enum.Font.GothamBlack
closeButton.Parent = panel
addStroke(closeButton, 2)

local scroller = Instance.new("ScrollingFrame")
scroller.Name = "GuideList"
scroller.Position = UDim2.new(0, 10, 0, 56)
scroller.Size = UDim2.new(1, -20, 1, -66)
scroller.BackgroundTransparency = 1
scroller.ScrollBarThickness = 6
scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroller.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = scroller

local function addRow(name, detail, color)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 44)
	row.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
	row.Parent = scroller
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 10, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = color
	nameLabel.TextSize = 19
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row
	addStroke(nameLabel, 1)
	local detailLabel = Instance.new("TextLabel")
	detailLabel.Size = UDim2.new(0.45, -10, 1, 0)
	detailLabel.Position = UDim2.new(0.55, 0, 0, 0)
	detailLabel.BackgroundTransparency = 1
	detailLabel.Text = detail
	detailLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	detailLabel.TextSize = 18
	detailLabel.Font = Enum.Font.GothamBold
	detailLabel.TextXAlignment = Enum.TextXAlignment.Right
	detailLabel.Parent = row
	addStroke(detailLabel, 1)
	return row
end

for _, def in ipairs(Roster.CHARACTERS) do
	addRow(def.Name, Roster.formatMoney(def.Price) .. "  |  " .. Roster.formatMoney(def.Rate) .. "/s", Roster.RARITY_COLORS[def.Rarity])
end

addRow("--- MUTATIONS ---", "", Color3.fromRGB(255, 255, 255))
for _, key in ipairs({ "radioactive", "dorato", "void" }) do
	local mut = Roster.MUTATIONS[key]
	addRow(mut.Name, mut.Multiplier .. "x income", mut.Color)
end

addRow("Rebirth: +100% income, +10% speed, x1.5 luck", "from $25M", Color3.fromRGB(255, 215, 0))
addRow("Tsunami every 3 min: run home!", "or get swept", Color3.fromRGB(140, 210, 255))
addRow("Lock your base for 60s", "nobody can steal", Color3.fromRGB(255, 80, 80))

local function setOpen(open)
	panel.Visible = open
	toggleButton.Text = open and "CLOSE" or "GUIDE"
end

toggleButton.MouseButton1Click:Connect(function()
	setOpen(not panel.Visible)
end)
closeButton.MouseButton1Click:Connect(function()
	setOpen(false)
end)
