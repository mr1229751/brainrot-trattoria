-- Celebrations.server.luau — a little juice. Whenever a brainrot lands on a
-- pedestal, a burst of neon confetti pops above it for a second: buying,
-- stealing home and rebirth restores all deserve a sparkle.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local World = require(script.Parent.World)
local Registry = require(script.Parent.Registry)

local Celebrations = {}

local CONFETTI_COLORS = {
	Color3.fromRGB(255, 220, 60),
	Color3.fromRGB(255, 90, 130),
	Color3.fromRGB(80, 220, 255),
	Color3.fromRGB(140, 255, 60),
	Color3.fromRGB(200, 100, 255),
}

local function burstAt(position)
	local folder = Instance.new("Folder")
	folder.Name = "ConfettiBurst"
	folder.Parent = Workspace
	for i = 1, 24 do
		local bit = Instance.new("Part")
		bit.Name = "Confetti" .. i
		bit.Size = Vector3.new(0.4, 0.4, 0.1)
		bit.Color = CONFETTI_COLORS[(i % #CONFETTI_COLORS) + 1]
		bit.Material = Enum.Material.Neon
		bit.Anchored = true
		bit.CanCollide = false
		bit.CFrame = CFrame.new(position) * CFrame.Angles(math.random() * math.pi, math.random() * math.pi, 0)
		bit.Parent = folder
	end
	task.spawn(function()
		local start = os.clock()
		while os.clock() - start < 1 do
			local elapsed = os.clock() - start
			for _, bit in ipairs(folder:GetChildren()) do
				local angle = elapsed * 6 + bit.Name:len()
				bit.CFrame = CFrame.new(position + Vector3.new(math.cos(angle) * elapsed * 4, elapsed * 3, math.sin(angle) * elapsed * 4))
					* CFrame.Angles(elapsed * 8, elapsed * 5, 0)
			end
			task.wait(0.03)
		end
		folder:Destroy()
	end)
end

Registry.Events.PedestalPlaced.Event:Connect(function(player, slot, model)
	local state = PlayerData.get(player)
	if state == nil or state.BaseIndex == 0 then
		return
	end
	local top = World.getPedestalTopPosition(state.BaseIndex, slot)
	if top ~= nil then
		burstAt(top + Vector3.new(0, 3, 0))
	end
end)

Registry.register("Celebrations", Celebrations)
print("[Brainrot Trattoria] Celebrations system online: pedestal arrivals pop confetti.")
