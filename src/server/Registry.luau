-- Registry.luau — server-only wiring. The systems are Scripts (their file names
-- end in .server.luau, as the brief lists them), and Roblox only lets a script
-- require ModuleScripts — so each system registers its public functions here
-- at start-up, and the others reach them through Registry.get / waitFor at
-- runtime. This module also creates the shared BindableEvents and RemoteEvents
-- once, so no system depends on another system's start order.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Registry = {}

local systems = {}

function Registry.register(name, api)
	systems[name] = api
end

function Registry.get(name)
	return systems[name]
end

-- Wait up to `timeout` seconds for a system to register (start-up ordering).
function Registry.waitFor(name, timeout)
	timeout = timeout or 10
	local waited = 0
	while systems[name] == nil and waited < timeout do
		task.wait(0.1)
		waited += 0.1
	end
	return systems[name]
end

-- Server-side events between systems.
local eventsFolder = Instance.new("Folder")
eventsFolder.Name = "BrainrotEvents"
eventsFolder.Parent = ServerStorage
local pedestalPlaced = Instance.new("BindableEvent")
pedestalPlaced.Name = "PedestalPlaced"
pedestalPlaced.Parent = eventsFolder
local pedestalCleared = Instance.new("BindableEvent")
pedestalCleared.Name = "PedestalCleared"
pedestalCleared.Parent = eventsFolder
Registry.Events = {
	PedestalPlaced = pedestalPlaced,
	PedestalCleared = pedestalCleared,
}

-- Client-to-server remotes (created once, here, so the HUD can find them).
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "BrainrotRemotes"
remotesFolder.Parent = ReplicatedStorage
local lockBaseEvent = Instance.new("RemoteEvent")
lockBaseEvent.Name = "LockBaseEvent"
lockBaseEvent.Parent = remotesFolder
local rebirthEvent = Instance.new("RemoteEvent")
rebirthEvent.Name = "RebirthEvent"
rebirthEvent.Parent = remotesFolder
local announceEvent = Instance.new("RemoteEvent")
announceEvent.Name = "AnnounceEvent"
announceEvent.Parent = remotesFolder
Registry.Remotes = {
	LockBaseEvent = lockBaseEvent,
	RebirthEvent = rebirthEvent,
	AnnounceEvent = announceEvent,
}

return Registry
