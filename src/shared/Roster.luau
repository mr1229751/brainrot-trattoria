-- Roster.luau — the whole brainrot cast. Twelve original Italian-food characters,
-- each a builder function that assembles a Model from Roblox primitives only
-- (balls, blocks, cylinders, wedges). No decals, no external assets: faces are
-- small primitive eyes and mouths. Also owns rarity data, spawn weights,
-- mutations, the floating name/rarity/$-per-second tag, and the per-model
-- animation registry (Lasagna layer undulation, Dorato orbiting stars).

local Roster = {}

-- Rarity colours, as the tag and the world show them.
Roster.RARITY_COLORS = {
	Common = Color3.fromRGB(170, 170, 170),
	Uncommon = Color3.fromRGB(80, 220, 90),
	Rare = Color3.fromRGB(80, 160, 255),
	Epic = Color3.fromRGB(190, 90, 255),
	Legendary = Color3.fromRGB(255, 200, 40),
	Mythic = Color3.fromRGB(255, 90, 130),
	Secret = Color3.fromRGB(140, 60, 255),
}

Roster.MUTATIONS = {
	radioactive = { Id = "radioactive", Name = "Radioactive Ragu", Multiplier = 3, Chance = 0.10, Color = Color3.fromRGB(140, 255, 60) },
	dorato = { Id = "dorato", Name = "24K Dorato", Multiplier = 8, Chance = 0.02, Color = Color3.fromRGB(255, 215, 0) },
	void = { Id = "void", Name = "Vuoto Astrale", Multiplier = 25, Chance = 0.002, Color = Color3.fromRGB(180, 60, 255) },
}

-- One primitive part inside a character model. `cf` is relative to the model's
-- origin (feet at Y = 0, facing +Z).
local function part(model, name, shape, size, color, cf, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.CFrame = cf
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Parent = model
	return p
end

local function ball(model, name, size, color, cf, material)
	return part(model, name, Enum.PartType.Ball, size, color, cf, material)
end

local function block(model, name, size, color, cf, material)
	return part(model, name, Enum.PartType.Block, size, color, cf, material)
end

local function wedge(model, name, size, color, cf, material)
	return part(model, name, Enum.PartType.Wedge, size, color, cf, material)
end

-- A vertical cylinder (Roblox cylinders run along X, so rotate Z by 90 degrees).
local function vCylinder(model, name, height, diameter, color, cf, material)
	local p = part(model, name, Enum.PartType.Cylinder, Vector3.new(height, diameter, diameter), color, cf * CFrame.Angles(0, 0, math.rad(90)), material)
	return p
end

-- A horizontal cylinder pointing along Z (rotate Y by 90 degrees).
local function hCylinder(model, name, length, diameter, color, cf, material)
	return part(model, name, Enum.PartType.Cylinder, Vector3.new(length, diameter, diameter), color, cf * CFrame.Angles(0, math.rad(90), 0), material)
end

-- Two black ball eyes and a small black mouth on the front (+Z) of a body.
-- `front` is the CFrame of the face plane; eyes sit on it, mouth below them.
local function addFace(model, front, eyeSpread, eyeHeight, mouthHeight, angry)
	local leftEye = ball(model, "EyeLeft", Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(20, 20, 20), front * CFrame.new(-eyeSpread, eyeHeight, 0.1))
	local rightEye = ball(model, "EyeRight", Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(20, 20, 20), front * CFrame.new(eyeSpread, eyeHeight, 0.1))
	if angry then
		leftEye.CFrame = front * CFrame.new(-eyeSpread, eyeHeight, 0.1) * CFrame.Angles(0, 0, math.rad(-25))
		rightEye.CFrame = front * CFrame.new(eyeSpread, eyeHeight, 0.1) * CFrame.Angles(0, 0, math.rad(25))
	end
	block(model, "Mouth", Vector3.new(0.7, 0.18, 0.2), Color3.fromRGB(20, 20, 20), front * CFrame.new(0, mouthHeight, 0.1) * CFrame.Angles(0, 0, math.rad(12)))
end

-- 1. Gnocchi Guapo — Common — yellow cylinder torso, ball feet, tilted chef hat.
local function buildGnocchi(model)
	local torso = vCylinder(model, "Torso", 3.2, 3.0, Color3.fromRGB(255, 220, 80), CFrame.new(0, 2.0, 0))
	ball(model, "FootLeft", Vector3.new(0.9, 0.9, 0.9), Color3.fromRGB(255, 240, 160), CFrame.new(-0.8, 0.45, 0.3))
	ball(model, "FootRight", Vector3.new(0.9, 0.9, 0.9), Color3.fromRGB(255, 240, 160), CFrame.new(0.8, 0.45, 0.3))
	local hat = vCylinder(model, "ChefHat", 1.6, 2.2, Color3.fromRGB(245, 245, 245), CFrame.new(0.3, 4.1, 0) * CFrame.Angles(0, 0, math.rad(-14)))
	hat.Material = Enum.Material.Fabric
	ball(model, "HatPuff", Vector3.new(1.2, 1.2, 1.2), Color3.fromRGB(255, 255, 255), CFrame.new(0.3, 5.0, 0))
	block(model, "Mustache", Vector3.new(1.2, 0.25, 0.25), Color3.fromRGB(60, 40, 20), CFrame.new(0, 1.55, 1.55))
	hCylinder(model, "Spoon", 1.8, 0.25, Color3.fromRGB(200, 200, 210), CFrame.new(1.7, 2.0, 0.6) * CFrame.Angles(math.rad(20), 0, math.rad(30)), Enum.Material.Metal)
	ball(model, "SpoonBowl", Vector3.new(0.6, 0.6, 0.3), Color3.fromRGB(200, 200, 210), CFrame.new(2.2, 2.6, 0.8), Enum.Material.Metal)
	addFace(model, CFrame.new(0, 2.0, 1.5), 0.6, 0.7, -0.1, false)
	return torso
end

-- 2. Tostada Tartaruga — Common — flat tan shell, green head and limbs, tomato balls.
local function buildTostada(model)
	local shell = vCylinder(model, "Shell", 1.2, 4.4, Color3.fromRGB(210, 160, 90), CFrame.new(0, 1.6, 0))
	shell.Material = Enum.Material.Wood
	block(model, "Head", Vector3.new(1.6, 1.2, 1.4), Color3.fromRGB(90, 200, 90), CFrame.new(0, 1.7, 2.6))
	ball(model, "Tomato1", Vector3.new(0.9, 0.9, 0.9), Color3.fromRGB(230, 50, 50), CFrame.new(-1.0, 2.4, -0.8))
	ball(model, "Tomato2", Vector3.new(0.9, 0.9, 0.9), Color3.fromRGB(230, 50, 50), CFrame.new(1.0, 2.4, 0.6))
	ball(model, "Tomato3", Vector3.new(0.8, 0.8, 0.8), Color3.fromRGB(230, 50, 50), CFrame.new(0.1, 2.4, -1.4))
	wedge(model, "LettuceLeaf", Vector3.new(1.6, 0.4, 2.2), Color3.fromRGB(90, 220, 90), CFrame.new(0, 2.3, 0.8) * CFrame.Angles(math.rad(-12), 0, 0))
	block(model, "LegFL", Vector3.new(0.7, 0.8, 0.7), Color3.fromRGB(90, 200, 90), CFrame.new(-1.6, 0.4, 1.6))
	block(model, "LegFR", Vector3.new(0.7, 0.8, 0.7), Color3.fromRGB(90, 200, 90), CFrame.new(1.6, 0.4, 1.6))
	block(model, "LegBL", Vector3.new(0.7, 0.8, 0.7), Color3.fromRGB(90, 200, 90), CFrame.new(-1.6, 0.4, -1.6))
	block(model, "LegBR", Vector3.new(0.7, 0.8, 0.7), Color3.fromRGB(90, 200, 90), CFrame.new(1.6, 0.4, -1.6))
	addFace(model, CFrame.new(0, 1.7, 3.3), 0.35, 0.25, -0.3, false)
	return shell
end

-- 3. Baguette Babbuino — Uncommon — long tan body, pink rear, eyes on the crust.
local function buildBaguette(model)
	local body = hCylinder(model, "Body", 5.2, 2.2, Color3.fromRGB(215, 165, 95), CFrame.new(0, 2.2, 0))
	body.Material = Enum.Material.Wood
	ball(model, "Rear", Vector3.new(2.0, 2.0, 2.0), Color3.fromRGB(255, 150, 170), CFrame.new(0, 2.2, -2.6))
	block(model, "ArmLeft", Vector3.new(0.6, 1.6, 0.6), Color3.fromRGB(120, 80, 50), CFrame.new(-1.3, 1.4, 1.2))
	block(model, "ArmRight", Vector3.new(0.6, 1.6, 0.6), Color3.fromRGB(120, 80, 50), CFrame.new(1.3, 1.4, 1.2))
	block(model, "LegLeft", Vector3.new(0.7, 1.0, 0.7), Color3.fromRGB(120, 80, 50), CFrame.new(-0.8, 0.5, -1.6))
	block(model, "LegRight", Vector3.new(0.7, 1.0, 0.7), Color3.fromRGB(120, 80, 50), CFrame.new(0.8, 0.5, -1.6))
	ball(model, "EyeLeft", Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(20, 20, 20), CFrame.new(-0.5, 3.4, 1.6))
	ball(model, "EyeRight", Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(20, 20, 20), CFrame.new(0.5, 3.4, 1.6))
	block(model, "Mouth", Vector3.new(0.8, 0.18, 0.2), Color3.fromRGB(20, 20, 20), CFrame.new(0, 2.9, 2.0))
	return body
end

-- 4. Limoncello Lama — Uncommon — yellow ball belly, tall neck, leaf ears, sunglasses.
local function buildLimoncello(model)
	local belly = ball(model, "Belly", Vector3.new(3.2, 3.2, 3.2), Color3.fromRGB(255, 235, 90), CFrame.new(0, 1.8, 0))
	vCylinder(model, "Neck", 2.6, 1.0, Color3.fromRGB(255, 235, 90), CFrame.new(0, 4.4, 0))
	ball(model, "Head", Vector3.new(1.6, 1.4, 1.6), Color3.fromRGB(255, 235, 90), CFrame.new(0, 6.0, 0))
	wedge(model, "EarLeft", Vector3.new(0.7, 1.4, 0.4), Color3.fromRGB(80, 200, 90), CFrame.new(-0.7, 6.9, 0) * CFrame.Angles(0, 0, math.rad(20)))
	wedge(model, "EarRight", Vector3.new(0.7, 1.4, 0.4), Color3.fromRGB(80, 200, 90), CFrame.new(0.7, 6.9, 0) * CFrame.Angles(0, 0, math.rad(-20)))
	block(model, "Glasses", Vector3.new(1.5, 0.5, 0.3), Color3.fromRGB(250, 250, 250), CFrame.new(0, 6.1, 0.8), Enum.Material.Glass)
	block(model, "LegLeft", Vector3.new(0.6, 1.0, 0.6), Color3.fromRGB(240, 210, 60), CFrame.new(-0.9, 0.5, 0.6))
	block(model, "LegRight", Vector3.new(0.6, 1.0, 0.6), Color3.fromRGB(240, 210, 60), CFrame.new(0.9, 0.5, 0.6))
	return belly
end

-- 5. Cannoli Caimano — Rare — beige tube, cream ends, green snout, white teeth.
local function buildCannoli(model)
	local body = hCylinder(model, "Body", 4.6, 2.4, Color3.fromRGB(220, 185, 130), CFrame.new(0, 2.0, 0))
	body.Material = Enum.Material.Wood
	ball(model, "CreamFront", Vector3.new(1.8, 1.8, 1.8), Color3.fromRGB(255, 250, 235), CFrame.new(0, 2.0, 2.3))
	ball(model, "CreamBack", Vector3.new(1.8, 1.8, 1.8), Color3.fromRGB(255, 250, 235), CFrame.new(0, 2.0, -2.3))
	block(model, "Snout", Vector3.new(1.8, 0.9, 1.2), Color3.fromRGB(90, 180, 90), CFrame.new(0, 1.7, 3.4))
	wedge(model, "ToothLeft", Vector3.new(0.35, 0.5, 0.3), Color3.fromRGB(255, 255, 255), CFrame.new(-0.5, 1.35, 3.9))
	wedge(model, "ToothRight", Vector3.new(0.35, 0.5, 0.3), Color3.fromRGB(255, 255, 255), CFrame.new(0.5, 1.35, 3.9))
	ball(model, "EyeLeft", Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(20, 20, 20), CFrame.new(-0.6, 2.9, 1.9))
	ball(model, "EyeRight", Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(20, 20, 20), CFrame.new(0.6, 2.9, 1.9))
	block(model, "Tail", Vector3.new(0.9, 0.6, 1.8), Color3.fromRGB(90, 180, 90), CFrame.new(0, 1.6, -3.4))
	return body
end

-- 6. Vespa Vombato — Rare — brown wombat block on a red wedge scooter.
local function buildVespa(model)
	local scooter = wedge(model, "Scooter", Vector3.new(2.2, 1.0, 4.6), Color3.fromRGB(220, 40, 40), CFrame.new(0, 1.0, 0))
	scooter.Material = Enum.Material.Metal
	vCylinder(model, "WheelFront", 0.5, 1.2, Color3.fromRGB(25, 25, 25), CFrame.new(0, 0.6, 2.2) * CFrame.Angles(math.rad(90), 0, 0))
	vCylinder(model, "WheelBack", 0.5, 1.2, Color3.fromRGB(25, 25, 25), CFrame.new(0, 0.6, -2.2) * CFrame.Angles(math.rad(90), 0, 0))
	local bars = hCylinder(model, "Handlebars", 1.8, 0.25, Color3.fromRGB(200, 200, 210), CFrame.new(0, 2.6, 2.0) * CFrame.Angles(0, 0, math.rad(90)))
	bars.Material = Enum.Material.Metal
	block(model, "Wombat", Vector3.new(1.8, 1.6, 2.2), Color3.fromRGB(140, 95, 60), CFrame.new(0, 2.3, -0.4))
	ball(model, "WombatHead", Vector3.new(1.4, 1.4, 1.4), Color3.fromRGB(150, 105, 70), CFrame.new(0, 3.2, 0.9))
	ball(model, "Nose", Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(20, 20, 20), CFrame.new(0, 3.1, 1.65))
	ball(model, "EyeLeft", Vector3.new(0.35, 0.35, 0.35), Color3.fromRGB(20, 20, 20), CFrame.new(-0.4, 3.5, 1.5))
	ball(model, "EyeRight", Vector3.new(0.35, 0.35, 0.35), Color3.fromRGB(20, 20, 20), CFrame.new(0.4, 3.5, 1.5))
	return scooter
end

-- 7. Espresso Elefante — Epic — white cup body, trunk pouring a neon coffee stream.
local function buildEspresso(model)
	local cup = vCylinder(model, "Cup", 2.8, 3.4, Color3.fromRGB(245, 245, 240), CFrame.new(0, 1.9, 0))
	cup.Material = Enum.Material.SmoothPlastic
	vCylinder(model, "SaucerHat", 0.5, 4.0, Color3.fromRGB(255, 215, 0), CFrame.new(0, 3.6, 0))
	ball(model, "Head", Vector3.new(1.8, 1.8, 1.8), Color3.fromRGB(235, 235, 230), CFrame.new(0, 4.4, 0))
	hCylinder(model, "Trunk", 2.4, 0.7, Color3.fromRGB(235, 235, 230), CFrame.new(0, 4.0, 1.6) * CFrame.Angles(math.rad(55), 0, 0))
	part(model, "CoffeeStream", Enum.PartType.Cylinder, Vector3.new(1.6, 0.5, 0.5), Color3.fromRGB(120, 60, 20), CFrame.new(0, 2.9, 2.6) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Neon)
	ball(model, "EarLeft", Vector3.new(1.2, 1.6, 0.5), Color3.fromRGB(230, 230, 225), CFrame.new(-1.6, 4.5, 0))
	ball(model, "EarRight", Vector3.new(1.2, 1.6, 0.5), Color3.fromRGB(230, 230, 225), CFrame.new(1.6, 4.5, 0))
	addFace(model, CFrame.new(0, 4.4, 0.9), 0.35, 0.25, -0.35, false)
	return cup
end

-- 8. Lasagna Leviatano — Epic — stacked pasta layers, angry eyes on top.
local function buildLasagna(model)
	local layerColors = {
		Color3.fromRGB(220, 60, 40),
		Color3.fromRGB(255, 210, 90),
		Color3.fromRGB(240, 220, 180),
		Color3.fromRGB(220, 60, 40),
		Color3.fromRGB(255, 210, 90),
	}
	local topLayer = nil
	for i, color in ipairs(layerColors) do
		local layer = block(model, "Layer" .. i, Vector3.new(4.2 - i * 0.15, 0.7, 3.0), color, CFrame.new(0, 0.35 + (i - 1) * 0.7, 0))
		layer:SetAttribute("LayerIndex", i)
		topLayer = layer
	end
	block(model, "CheeseTop", Vector3.new(3.4, 0.4, 2.4), Color3.fromRGB(255, 230, 140), CFrame.new(0, 3.9, 0))
	ball(model, "EyeLeft", Vector3.new(0.6, 0.6, 0.6), Color3.fromRGB(20, 20, 20), CFrame.new(-0.8, 4.3, 1.3))
	ball(model, "EyeRight", Vector3.new(0.6, 0.6, 0.6), Color3.fromRGB(20, 20, 20), CFrame.new(0.8, 4.3, 1.3))
	block(model, "BrowLeft", Vector3.new(0.9, 0.2, 0.2), Color3.fromRGB(20, 20, 20), CFrame.new(-0.8, 4.75, 1.35) * CFrame.Angles(0, 0, math.rad(25)))
	block(model, "BrowRight", Vector3.new(0.9, 0.2, 0.2), Color3.fromRGB(20, 20, 20), CFrame.new(0.8, 4.75, 1.35) * CFrame.Angles(0, 0, math.rad(-25)))
	return topLayer
end

-- 9. Prosciutto Pegaso — Legendary — pink body, white wedge wings, gold hooves.
local function buildProsciutto(model)
	local body = block(model, "Body", Vector3.new(2.2, 2.0, 3.6), Color3.fromRGB(255, 150, 170), CFrame.new(0, 2.2, 0))
	wedge(model, "WingLeft", Vector3.new(0.4, 2.4, 3.0), Color3.fromRGB(250, 250, 250), CFrame.new(-1.6, 3.2, -0.4) * CFrame.Angles(0, 0, math.rad(35)))
	wedge(model, "WingRight", Vector3.new(0.4, 2.4, 3.0), Color3.fromRGB(250, 250, 250), CFrame.new(1.6, 3.2, -0.4) * CFrame.Angles(0, 0, math.rad(-35)))
	ball(model, "Head", Vector3.new(1.6, 1.6, 1.6), Color3.fromRGB(255, 170, 185), CFrame.new(0, 3.4, 1.8))
	vCylinder(model, "LegFL", 1.4, 0.5, Color3.fromRGB(255, 215, 0), CFrame.new(-0.8, 0.7, 1.4), Enum.Material.Metal)
	vCylinder(model, "LegFR", 1.4, 0.5, Color3.fromRGB(255, 215, 0), CFrame.new(0.8, 0.7, 1.4), Enum.Material.Metal)
	vCylinder(model, "LegBL", 1.4, 0.5, Color3.fromRGB(255, 215, 0), CFrame.new(-0.8, 0.7, -1.4), Enum.Material.Metal)
	vCylinder(model, "LegBR", 1.4, 0.5, Color3.fromRGB(255, 215, 0), CFrame.new(0.8, 0.7, -1.4), Enum.Material.Metal)
	block(model, "Mane", Vector3.new(0.8, 1.6, 2.4), Color3.fromRGB(255, 255, 255), CFrame.new(0, 4.0, 0.6))
	addFace(model, CFrame.new(0, 3.4, 2.6), 0.35, 0.25, -0.35, false)
	return body
end

-- 10. Moka Mammut — Legendary — silver octagonal torso, white tusks, steam.
local function buildMoka(model)
	local torso = vCylinder(model, "Torso", 3.0, 3.6, Color3.fromRGB(190, 195, 205), CFrame.new(0, 2.2, 0), Enum.Material.Metal)
	ball(model, "Head", Vector3.new(2.2, 2.2, 2.2), Color3.fromRGB(200, 205, 215), CFrame.new(0, 4.2, 0.6))
	wedge(model, "TuskLeft", Vector3.new(0.4, 2.2, 0.4), Color3.fromRGB(250, 250, 245), CFrame.new(-1.0, 3.6, 1.8) * CFrame.Angles(math.rad(-35), 0, math.rad(15)))
	wedge(model, "TuskRight", Vector3.new(0.4, 2.2, 0.4), Color3.fromRGB(250, 250, 245), CFrame.new(1.0, 3.6, 1.8) * CFrame.Angles(math.rad(-35), 0, math.rad(-15)))
	hCylinder(model, "Trunk", 2.0, 0.7, Color3.fromRGB(190, 195, 205), CFrame.new(0, 3.8, 2.0) * CFrame.Angles(math.rad(50), 0, 0), Enum.Material.Metal)
	local steam = Instance.new("ParticleEmitter")
	steam.Name = "Steam"
	steam.Color = ColorSequence.new(Color3.fromRGB(240, 240, 240))
	steam.Size = NumberSequence.new(0.8)
	steam.Rate = 12
	steam.Lifetime = NumberRange.new(0.8, 1.4)
	steam.Speed = NumberRange.new(2, 3)
	steam.SpreadAngle = Vector2.new(20, 20)
	steam.Parent = torso
	ball(model, "EyeLeft", Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(20, 20, 20), CFrame.new(-0.5, 4.5, 1.65))
	ball(model, "EyeRight", Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(20, 20, 20), CFrame.new(0.5, 4.5, 1.65))
	return torso
end

-- 11. Tiramisu Tirannosauro — Mythic — tiered blocks, cocoa head, fork in tiny arms.
local function buildTiramisu(model)
	block(model, "TierBottom", Vector3.new(4.0, 1.2, 3.0), Color3.fromRGB(200, 160, 110), CFrame.new(0, 0.6, 0))
	block(model, "TierMiddle", Vector3.new(3.2, 1.2, 2.4), Color3.fromRGB(120, 75, 40), CFrame.new(0, 1.8, 0))
	block(model, "TierTop", Vector3.new(2.4, 1.2, 1.8), Color3.fromRGB(200, 160, 110), CFrame.new(0, 3.0, 0))
	local head = ball(model, "Head", Vector3.new(2.0, 1.8, 2.0), Color3.fromRGB(90, 55, 30), CFrame.new(0, 4.4, 0.4))
	block(model, "Jaw", Vector3.new(1.6, 0.5, 1.4), Color3.fromRGB(200, 160, 110), CFrame.new(0, 3.7, 1.2))
	wedge(model, "Tooth1", Vector3.new(0.3, 0.5, 0.3), Color3.fromRGB(255, 255, 255), CFrame.new(-0.5, 4.0, 1.8))
	wedge(model, "Tooth2", Vector3.new(0.3, 0.5, 0.3), Color3.fromRGB(255, 255, 255), CFrame.new(0.5, 4.0, 1.8))
	block(model, "ArmLeft", Vector3.new(0.4, 1.2, 0.4), Color3.fromRGB(200, 160, 110), CFrame.new(-1.4, 2.6, 1.0))
	block(model, "ArmRight", Vector3.new(0.4, 1.2, 0.4), Color3.fromRGB(200, 160, 110), CFrame.new(1.4, 2.6, 1.0))
	local fork = block(model, "Fork", Vector3.new(0.15, 1.6, 0.5), Color3.fromRGB(210, 210, 220), CFrame.new(1.4, 3.4, 1.2), Enum.Material.Metal)
	fork.Name = "Fork"
	ball(model, "EyeLeft", Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(255, 255, 255), CFrame.new(-0.45, 4.7, 1.35))
	ball(model, "EyeRight", Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(255, 255, 255), CFrame.new(0.45, 4.7, 1.35))
	return head
end

-- 12. Gorgonzola Galassia — Secret — floating neon cheese wheel, orbiting balls.
local function buildGorgonzola(model)
	local wheel = wedge(model, "CheeseWheel", Vector3.new(4.4, 1.6, 4.4), Color3.fromRGB(70, 40, 180), CFrame.new(0, 2.6, 0), Enum.Material.Neon)
	ball(model, "Core", Vector3.new(2.0, 2.0, 2.0), Color3.fromRGB(120, 80, 255), CFrame.new(0, 2.6, 0), Enum.Material.Neon)
	ball(model, "MoldSpot1", Vector3.new(0.9, 0.9, 0.9), Color3.fromRGB(60, 255, 120), CFrame.new(1.4, 3.3, 0.8), Enum.Material.Neon)
	ball(model, "MoldSpot2", Vector3.new(0.7, 0.7, 0.7), Color3.fromRGB(60, 255, 120), CFrame.new(-1.2, 3.2, -0.9), Enum.Material.Neon)
	ball(model, "EyeLeft", Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(255, 255, 255), CFrame.new(-0.6, 2.9, 2.2), Enum.Material.Neon)
	ball(model, "EyeRight", Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(255, 255, 255), CFrame.new(0.6, 2.9, 2.2), Enum.Material.Neon)
	local aura = Instance.new("PointLight")
	aura.Color = Color3.fromRGB(140, 80, 255)
	aura.Range = 12
	aura.Brightness = 2
	aura.Parent = wheel
	for i = 0, 2 do
		local orb = ball(model, "OrbitBall" .. i, Vector3.new(0.7, 0.7, 0.7), Color3.fromRGB(60, 255, 120), CFrame.new(3, 4.5, 0), Enum.Material.Neon)
		orb:SetAttribute("IsOrbitStar", true)
		orb:SetAttribute("OrbitIndex", i)
	end
	return wheel
end

Roster.CHARACTERS = {
	{ Id = "gnocchi", Name = "Gnocchi Guapo", Rarity = "Common", Price = 25, Rate = 2, Weight = 40, Build = buildGnocchi },
	{ Id = "tostada", Name = "Tostada Tartaruga", Rarity = "Common", Price = 80, Rate = 5, Weight = 25, Build = buildTostada },
	{ Id = "baguette", Name = "Baguette Babbuino", Rarity = "Uncommon", Price = 300, Rate = 18, Weight = 14, Build = buildBaguette },
	{ Id = "limoncello", Name = "Limoncello Lama", Rarity = "Uncommon", Price = 900, Rate = 50, Weight = 9, Build = buildLimoncello },
	{ Id = "cannoli", Name = "Cannoli Caimano", Rarity = "Rare", Price = 3500, Rate = 180, Weight = 5, Build = buildCannoli },
	{ Id = "vespa", Name = "Vespa Vombato", Rarity = "Rare", Price = 12000, Rate = 600, Weight = 3, Build = buildVespa },
	{ Id = "espresso", Name = "Espresso Elefante", Rarity = "Epic", Price = 50000, Rate = 2200, Weight = 1.8, Build = buildEspresso },
	{ Id = "lasagna", Name = "Lasagna Leviatano", Rarity = "Epic", Price = 200000, Rate = 8500, Weight = 1.2, Build = buildLasagna },
	{ Id = "prosciutto", Name = "Prosciutto Pegaso", Rarity = "Legendary", Price = 1000000, Rate = 40000, Weight = 0.5, Build = buildProsciutto },
	{ Id = "moka", Name = "Moka Mammut", Rarity = "Legendary", Price = 5000000, Rate = 185000, Weight = 0.3, Build = buildMoka },
	{ Id = "tiramisu", Name = "Tiramisu Tirannosauro", Rarity = "Mythic", Price = 28000000, Rate = 1000000, Weight = 0.15, Build = buildTiramisu },
	{ Id = "gorgonzola", Name = "Gorgonzola Galassia", Rarity = "Secret", Price = 150000000, Rate = 6500000, Weight = 0.05, Build = buildGorgonzola },
}

function Roster.getCharacter(charId)
	for _, def in ipairs(Roster.CHARACTERS) do
		if def.Id == charId then
			return def
		end
	end
	return nil
end

-- Weighted roll: Commons dominate, the Secret is a whisper.
function Roster.rollCharacterId()
	local total = 0
	for _, def in ipairs(Roster.CHARACTERS) do
		total += def.Weight
	end
	local roll = math.random() * total
	for _, def in ipairs(Roster.CHARACTERS) do
		roll -= def.Weight
		if roll <= 0 then
			return def.Id
		end
	end
	return "gnocchi"
end

-- Mutation roll; `luck` multiplies every chance (rebirths raise it).
function Roster.rollMutation(luck)
	luck = luck or 1
	local pVoid = Roster.MUTATIONS.void.Chance * luck
	local pDorato = Roster.MUTATIONS.dorato.Chance * luck
	local pRadio = Roster.MUTATIONS.radioactive.Chance * luck
	local roll = math.random()
	if roll < pVoid then
		return "void"
	elseif roll < pVoid + pDorato then
		return "dorato"
	elseif roll < pVoid + pDorato + pRadio then
		return "radioactive"
	end
	return nil
end

function Roster.formatMoney(amount)
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return string.format("$%d", math.floor(amount + 0.5))
	end
end

-- Floating tag: name, rarity in its colour, $/s, and a mutation badge.
local function makeNameTag(model, def, mutationId, rate)
	local primary = model.PrimaryPart
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotTag"
	gui.Size = UDim2.fromOffset(260, 110)
	gui.ExtentsOffsetWorldSpace = Vector3.new(0, 5.2, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = primary

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.36, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 24
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.Parent = gui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.Position = UDim2.new(0, 0, 0.36, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = string.upper(def.Rarity)
	rarityLabel.TextColor3 = Roster.RARITY_COLORS[def.Rarity]
	rarityLabel.TextSize = 20
	rarityLabel.Font = Enum.Font.GothamBlack
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rarityLabel.Parent = gui

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rateLabel.Position = UDim2.new(0, 0, 0.66, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = Roster.formatMoney(rate) .. "/s"
	rateLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
	rateLabel.TextSize = 22
	rateLabel.Font = Enum.Font.GothamBlack
	rateLabel.TextStrokeTransparency = 0
	rateLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rateLabel.Parent = gui

	if mutationId ~= nil then
		local mut = Roster.MUTATIONS[mutationId]
		local badge = Instance.new("TextLabel")
		badge.Name = "MutationBadge"
		badge.Size = UDim2.new(1, 0, 0.28, 0)
		badge.Position = UDim2.new(0, 0, 0.94, 0)
		badge.BackgroundTransparency = 0.3
		badge.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		badge.Text = string.upper(mut.Name) .. " " .. mut.Multiplier .. "x"
		badge.TextColor3 = mut.Color
		badge.TextSize = 16
		badge.Font = Enum.Font.GothamBlack
		badge.TextStrokeTransparency = 0
		badge.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		badge.Parent = gui
	end
end

-- Mutation dressing applied on top of a finished model.
function Roster.applyMutation(model, mutationId)
	local mut = Roster.MUTATIONS[mutationId]
	if mut == nil then
		return
	end
	if mutationId == "radioactive" then
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.Name ~= "EyeLeft" and descendant.Name ~= "EyeRight" then
				descendant.Color = Color3.fromRGB(140, 255, 60)
				descendant.Material = Enum.Material.Neon
			end
		end
		local bubbles = Instance.new("ParticleEmitter")
		bubbles.Name = "MutationBubbles"
		bubbles.Color = ColorSequence.new(Color3.fromRGB(140, 255, 60))
		bubbles.Size = NumberSequence.new(0.6)
		bubbles.Rate = 10
		bubbles.Lifetime = NumberRange.new(0.7, 1.2)
		bubbles.Speed = NumberRange.new(2, 4)
		bubbles.SpreadAngle = Vector2.new(40, 40)
		bubbles.Parent = model.PrimaryPart
		local glow = Instance.new("Highlight")
		glow.FillColor = Color3.fromRGB(60, 255, 60)
		glow.OutlineColor = Color3.fromRGB(140, 255, 60)
		glow.FillTransparency = 0.75
		glow.Parent = model
	elseif mutationId == "dorato" then
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Color = Color3.fromRGB(255, 215, 0)
				descendant.Material = Enum.Material.Foil
			end
		end
		for i = 0, 2 do
			local star = ball(model, "DoratoStar" .. i, Vector3.new(0.7, 0.7, 0.7), Color3.fromRGB(255, 240, 120), CFrame.new(3, 4.5, 0), Enum.Material.Neon)
			star:SetAttribute("IsOrbitStar", true)
			star:SetAttribute("OrbitIndex", i)
		end
	elseif mutationId == "void" then
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Color = Color3.fromRGB(12, 12, 18)
				descendant.Material = Enum.Material.ForceField
			end
		end
		ball(model, "VoidCore", Vector3.new(1.6, 1.6, 1.6), Color3.fromRGB(160, 60, 255), CFrame.new(0, 2.4, 0), Enum.Material.Neon)
		local attachTop = Instance.new("Attachment")
		attachTop.Position = Vector3.new(0, 1.5, 0)
		attachTop.Parent = model.PrimaryPart
		local attachBottom = Instance.new("Attachment")
		attachBottom.Position = Vector3.new(0, -1.5, 0)
		attachBottom.Parent = model.PrimaryPart
		local trail = Instance.new("Trail")
		trail.Color = ColorSequence.new(Color3.fromRGB(255, 60, 220))
		trail.Lifetime = 0.6
		trail.Attachment0 = attachTop
		trail.Attachment1 = attachBottom
		trail.Parent = model.PrimaryPart
	end
end

-- Animation registry: only Lasagna layers and orbiting stars need per-frame work.
local animatedModels = {}

local function registerAnimated(model)
	local entries = {}
	local pivot = model:GetPivot()
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if descendant:GetAttribute("IsOrbitStar") then
				table.insert(entries, { Part = descendant, Kind = "orbit", Index = descendant:GetAttribute("OrbitIndex") or 0 })
			elseif descendant:GetAttribute("LayerIndex") ~= nil then
				table.insert(entries, { Part = descendant, Kind = "layer", Index = descendant:GetAttribute("LayerIndex"), Offset = pivot:Inverse() * descendant.CFrame })
			end
		end
	end
	if #entries > 0 then
		animatedModels[model] = entries
		model.Destroying:Connect(function()
			animatedModels[model] = nil
		end)
	end
end

-- Called every frame by the belt, pedestal and stealing loops. `t` is elapsed time.
function Roster.animateModel(model, t)
	local entries = animatedModels[model]
	if entries == nil then
		return
	end
	local pivot = model:GetPivot()
	for _, entry in ipairs(entries) do
		if entry.Kind == "orbit" then
			local angle = t * 1.5 + entry.Index * 2.094
			entry.Part.CFrame = pivot * CFrame.new(math.cos(angle) * 3.2, 2.2, math.sin(angle) * 3.2)
		elseif entry.Kind == "layer" then
			entry.Part.CFrame = pivot * entry.Offset * CFrame.new(0, math.sin(t * 3 + entry.Index * 0.9) * 0.18, 0)
		end
	end
end

-- Build a full character model, mutated and tagged, ready to place.
function Roster.buildCharacter(charId, mutationId)
	local def = Roster.getCharacter(charId)
	assert(def ~= nil, "Roster.buildCharacter: unknown character " .. tostring(charId))
	local model = Instance.new("Model")
	model.Name = def.Name
	local primary = def.Build(model)
	model.PrimaryPart = primary
	model:SetAttribute("Brainrot", true)
	model:SetAttribute("CharId", charId)
	model:SetAttribute("Mutation", mutationId or "")
	local rate = def.Rate
	if mutationId ~= nil then
		rate = rate * Roster.MUTATIONS[mutationId].Multiplier
		Roster.applyMutation(model, mutationId)
	end
	model:SetAttribute("Rate", rate)
	model:SetAttribute("Price", def.Price)
	makeNameTag(model, def, mutationId, rate)
	registerAnimated(model)
	return model
end

return Roster
