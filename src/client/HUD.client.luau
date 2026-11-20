-- HUD.client.luau — the whole interface for Brainrot Trattoria: cash and $/s
-- ticker bottom-left with the rebirth badge, the tsunami countdown bar
-- top-center, and Lock Base / Rebirth buttons bottom-right. The TOP-LEFT
-- corner stays EMPTY: Roblox's own menu buttons overlay it. Bold
-- high-contrast text with UIStroke throughout.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function addStroke(label, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or 2
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Parent = label
	return stroke
end

local function makeLabel(parent, name, text, size, position, textColor, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	label.Text = text
	label.TextColor3 = textColor
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBlack
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	addStroke(label, 2)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	return label
end

-- Cash ticker, bottom-left.
local cashLabel = makeLabel(gui, "CashLabel", "$0", UDim2.fromOffset(280, 54), UDim2.new(0, 16, 1, -124), Color3.fromRGB(255, 220, 60), 30)
local rateLabel = makeLabel(gui, "RateLabel", "$0/s", UDim2.fromOffset(280, 34), UDim2.new(0, 16, 1, -64), Color3.fromRGB(120, 255, 120), 20)
local rebirthLabel = makeLabel(gui, "RebirthLabel", "REBIRTH x0", UDim2.fromOffset(280, 34), UDim2.new(0, 16, 1, -168), Color3.fromRGB(255, 215, 0), 20)

-- Tsunami countdown bar, top-center.
local tsunamiFrame = Instance.new("Frame")
tsunamiFrame.Name = "TsunamiBar"
tsunamiFrame.AnchorPoint = Vector2.new(0.5, 0)
tsunamiFrame.Position = UDim2.new(0.5, 0, 0, 12)
tsunamiFrame.Size = UDim2.fromOffset(460, 44)
tsunamiFrame.BackgroundTransparency = 0.35
tsunamiFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
tsunamiFrame.Parent = gui
local tsunamiCorner = Instance.new("UICorner")
tsunamiCorner.CornerRadius = UDim.new(0, 8)
tsunamiCorner.Parent = tsunamiFrame
local tsunamiLabel = Instance.new("TextLabel")
tsunamiLabel.Name = "TsunamiLabel"
tsunamiLabel.Size = UDim2.new(1, 0, 1, 0)
tsunamiLabel.BackgroundTransparency = 1
tsunamiLabel.Text = "Next wave in 3:00"
tsunamiLabel.TextColor3 = Color3.fromRGB(140, 210, 255)
tsunamiLabel.TextSize = 24
tsunamiLabel.Font = Enum.Font.GothamBlack
tsunamiLabel.Parent = tsunamiFrame
addStroke(tsunamiLabel, 2)

-- Announcement banner, under the tsunami bar.
local announceLabel = Instance.new("TextLabel")
announceLabel.Name = "AnnounceLabel"
announceLabel.AnchorPoint = Vector2.new(0.5, 0)
announceLabel.Position = UDim2.new(0.5, 0, 0, 64)
announceLabel.Size = UDim2.fromOffset(640, 40)
announceLabel.BackgroundTransparency = 0.35
announceLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
announceLabel.Text = ""
announceLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
announceLabel.TextSize = 22
announceLabel.Font = Enum.Font.GothamBlack
announceLabel.Visible = false
announceLabel.Parent = gui
addStroke(announceLabel, 2)
local announceCorner = Instance.new("UICorner")
announceCorner.CornerRadius = UDim.new(0, 8)
announceCorner.Parent = announceLabel

-- Feature strip, top-center below the announcement banner: a static
-- summary of everything in the game. Purely informational — no remotes,
-- no gameplay effect. Centered so it never covers the Roblox menu
-- buttons in the top-left corner.
local featureStripLabel = Instance.new("TextLabel")
featureStripLabel.Name = "FeatureStripLabel"
featureStripLabel.AnchorPoint = Vector2.new(0.5, 0)
featureStripLabel.Position = UDim2.new(0.5, 0, 0, 110)
featureStripLabel.Size = UDim2.fromOffset(880, 36)
featureStripLabel.BackgroundTransparency = 0.25
featureStripLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
featureStripLabel.Text = "12 BRAINROTS • 3 MUTATIONS • STEAL • LOCK • TSUNAMI • REBIRTH • INDEX"
featureStripLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
featureStripLabel.TextSize = 19
featureStripLabel.Font = Enum.Font.GothamBlack
featureStripLabel.TextXAlignment = Enum.TextXAlignment.Center
featureStripLabel.Parent = gui
addStroke(featureStripLabel, 2)
local featureStripCorner = Instance.new("UICorner")
featureStripCorner.CornerRadius = UDim.new(0, 8)
featureStripCorner.Parent = featureStripLabel

-- Buttons, bottom-right.
local function makeButton(name, text, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(190, 56)
	button.Position = position
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 24
	button.Font = Enum.Font.GothamBlack
	button.Parent = gui
	addStroke(button, 2)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	return button
end

local lockButton = makeButton("LockButton", "LOCK BASE", UDim2.new(1, -206, 1, -124), Color3.fromRGB(220, 50, 50))
local rebirthButton = makeButton("RebirthButton", "REBIRTH", UDim2.new(1, -206, 1, -64), Color3.fromRGB(200, 160, 20))

-- Help line, bottom-center.
local helpLabel = Instance.new("TextLabel")
helpLabel.Name = "HelpLabel"
helpLabel.AnchorPoint = Vector2.new(0.5, 1)
helpLabel.Position = UDim2.new(0.5, 0, 1, -8)
helpLabel.Size = UDim2.fromOffset(620, 26)
helpLabel.BackgroundTransparency = 1
helpLabel.Text = "Buy brainrots on the conveyor - collect on your gold pad - lock your base!"
helpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
helpLabel.TextSize = 16
helpLabel.Font = Enum.Font.GothamBold
helpLabel.Parent = gui
addStroke(helpLabel, 2)

-- Remotes (created by the server's Registry module).
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local lockBaseEvent = remotes:WaitForChild("LockBaseEvent")
local rebirthEvent = remotes:WaitForChild("RebirthEvent")
local announceEvent = remotes:WaitForChild("AnnounceEvent")

local announceToken = 0
announceEvent.OnClientEvent:Connect(function(text, color)
	announceToken += 1
	local token = announceToken
	announceLabel.Text = text
	if typeof(color) == "Color3" then
		announceLabel.TextColor3 = color
	end
	announceLabel.Visible = true
	task.delay(5, function()
		if token == announceToken then
			announceLabel.Visible = false
		end
	end)
end)

lockButton.MouseButton1Click:Connect(function()
	lockBaseEvent:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	rebirthEvent:FireServer()
end)

-- Live values from leaderstats and the server's tsunami values.
local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Cash")
local rateValue = leaderstats:WaitForChild("$/s")

local function formatMoney(amount)
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. tostring(amount)
	end
end

local function refreshMoney()
	cashLabel.Text = formatMoney(cashValue.Value)
	rateLabel.Text = formatMoney(rateValue.Value) .. "/s"
end
cashValue.Changed:Connect(refreshMoney)
rateValue.Changed:Connect(refreshMoney)
refreshMoney()

local function refreshRebirths()
	local rebirths = player:GetAttribute("Rebirths") or 0
	rebirthLabel.Text = "REBIRTH x" .. tostring(rebirths)
end
player:GetAttributeChangedSignal("Rebirths"):Connect(refreshRebirths)
refreshRebirths()

local tsunamiStatus = ReplicatedStorage:WaitForChild("TsunamiStatus")
local tsunamiCountdown = ReplicatedStorage:WaitForChild("TsunamiCountdown")

local function refreshTsunami()
	tsunamiLabel.Text = tsunamiStatus.Value
	if string.find(tsunamiStatus.Value, "INCOMING") ~= nil then
		tsunamiLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
		tsunamiFrame.BackgroundColor3 = Color3.fromRGB(90, 10, 10)
	else
		tsunamiLabel.TextColor3 = Color3.fromRGB(140, 210, 255)
		tsunamiFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	end
end
tsunamiStatus.Changed:Connect(refreshTsunami)
tsunamiCountdown.Changed:Connect(refreshTsunami)
refreshTsunami()
