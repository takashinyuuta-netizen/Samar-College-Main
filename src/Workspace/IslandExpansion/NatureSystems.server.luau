-- NatureSystems: forest / village / lake / camp behaviour
--  • Lamps (parts named "Bulb") turn on 6 PM - 6 AM
--  • Campfire: tap the fire to light it / put it out (flickers while lit)
--  • Tents: tap a door flap to open / close the tent
--  • Fireflies appear in the forest, at the lake and the camp at night
local Lighting = game:GetService("Lighting")
local CS = game:GetService("CollectionService")
local root = script.Parent
local AREAS = { "CampSite", "Village", "RiverLake", "Forest", "DirtRoad" }

local function isNight()
	local t = Lighting.ClockTime
	return t >= 18 or t < 6
end

---------------------------------------------------------------- night lamps
local bulbs = {}
for _, a in ipairs(AREAS) do
	local f = root:FindFirstChild(a)
	if f then
		for _, d in ipairs(f:GetDescendants()) do
			if d:IsA("BasePart") and d.Name == "Bulb" then
				d:SetAttribute("OnColor", d.Color)
				table.insert(bulbs, d)
			end
		end
	end
end

---------------------------------------------------------------- fireflies
local fireflyFolder = Instance.new("Folder")
fireflyFolder.Name = "Fireflies"
fireflyFolder.Parent = root
local emitters = {}
local SPOTS = {
	-- camp
	Vector3.new(-940, 6, 80), Vector3.new(-990, 4, 100), Vector3.new(-1020, 4, 150), Vector3.new(-900, 6, -20),
	Vector3.new(-1040, 6, 40), Vector3.new(-960, 6, -40),
	-- lake shore
	Vector3.new(-690, 4, 90), Vector3.new(-620, 4, 160), Vector3.new(-500, 4, 40), Vector3.new(-470, 4, 120),
	Vector3.new(-640, 4, 15), Vector3.new(-540, 4, 165),
	-- river
	Vector3.new(-580, 3, 260), Vector3.new(-575, 3, 360), Vector3.new(-560, 3, 430),
	-- deep forest + trail
	Vector3.new(-720, 8, -200), Vector3.new(-650, 8, -260), Vector3.new(-760, 8, 0), Vector3.new(-740, 8, 200),
	Vector3.new(-680, 8, 300), Vector3.new(-460, 8, 250), Vector3.new(-470, 8, -150), Vector3.new(-700, 8, -120),
	Vector3.new(-620, 8, -60), Vector3.new(-760, 8, 380), Vector3.new(-860, 8, -300),
}
for i, p in ipairs(SPOTS) do
	local part = Instance.new("Part")
	part.Name = "FireflySpot" .. i
	part.Anchored = true part.CanCollide = false part.CanQuery = false part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(40, 6, 40)
	part.CFrame = CFrame.new(p)
	part.Parent = fireflyFolder
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "Fireflies"
	pe.Shape = Enum.ParticleEmitterShape.Box
	pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	pe.Rate = 6
	pe.Lifetime = NumberRange.new(3, 6)
	pe.Speed = NumberRange.new(0.3, 1.2)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.RotSpeed = NumberRange.new(-30, 30)
	pe.Acceleration = Vector3.new(0, 0.15, 0)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.22), NumberSequenceKeypoint.new(0.8, 0.22), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(0.75, 0), NumberSequenceKeypoint.new(1, 1) })
	pe.Color = ColorSequence.new(Color3.fromRGB(210, 255, 120), Color3.fromRGB(255, 240, 110))
	pe.LightEmission = 1
	pe.Brightness = 3
	pe.LightInfluence = 0
	pe.Enabled = false
	pe.Parent = part
	table.insert(emitters, pe)
end

local last = nil
local function updateNight()
	local on = isNight()
	if on == last then return end
	last = on
	for _, b in ipairs(bulbs) do
		if b.Parent then
			b.Material = on and Enum.Material.Neon or Enum.Material.Glass
			b.Color = on and (b:GetAttribute("OnColor") or Color3.fromRGB(255, 214, 150)) or Color3.fromRGB(226, 220, 206)
			local l = b:FindFirstChildWhichIsA("Light")
			if l then l.Enabled = on end
		end
	end
	for _, pe in ipairs(emitters) do pe.Enabled = on end
end
updateNight()
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(updateNight)

---------------------------------------------------------------- campfire (tap to light / put out)
local function setupCampfire(model)
	local em = model:FindFirstChild("FireEmitter")
	if not em then return end
	local core = model:FindFirstChild("FireCore")
	local flame = em:FindFirstChild("Flame")
	local smoke = em:FindFirstChild("Smoke")
	local embers = em:FindFirstChild("Embers")
	local light = em:FindFirstChild("FireLight")
	local cd = em:FindFirstChildWhichIsA("ClickDetector") or Instance.new("ClickDetector", em)
	cd.MaxActivationDistance = 24
	local function apply(lit)
		model:SetAttribute("Lit", lit)
		if flame then flame.Enabled = lit end
		if embers then embers.Enabled = lit end
		if light then light.Enabled = lit end
		if smoke then smoke.Opacity = lit and 0.08 or 0.15 smoke.Size = lit and 4 or 2 smoke.Enabled = true end
		if core then
			core.Material = lit and Enum.Material.Neon or Enum.Material.Slate
			core.Color = lit and Color3.fromRGB(255, 120, 40) or Color3.fromRGB(60, 56, 52)
		end
		if not lit and smoke then
			-- a little smoke after putting it out, then it fades
			task.delay(6, function()
				if model:GetAttribute("Lit") == false and smoke.Parent then smoke.Enabled = false end
			end)
		end
	end
	apply(model:GetAttribute("Lit") ~= false)
	cd.MouseClick:Connect(function()
		apply(not model:GetAttribute("Lit"))
	end)
	-- flicker
	task.spawn(function()
		while model.Parent do
			if model:GetAttribute("Lit") and light then
				light.Brightness = 1.5 + math.random() * 0.9
				light.Range = 26 + math.random() * 6
				if core then core.Transparency = math.random() * 0.25 end
			end
			task.wait(0.12 + math.random() * 0.1)
		end
	end)
end
for _, m in ipairs(CS:GetTagged("Campfire")) do setupCampfire(m) end
CS:GetInstanceAddedSignal("Campfire"):Connect(setupCampfire)

---------------------------------------------------------------- tents (tap the door flap to open / close)
local function setupTent(tent)
	local flaps, rolled = {}, {}
	for _, d in ipairs(tent:GetChildren()) do
		if d.Name == "DoorFlap" then table.insert(flaps, d) end
		if d.Name == "RolledFlap" then table.insert(rolled, d) end
	end
	local function apply(open)
		tent:SetAttribute("Open", open)
		for _, f in ipairs(flaps) do
			f.Transparency = open and 1 or 0
			f.CanCollide = not open
			f.CastShadow = not open
		end
		for _, r in ipairs(rolled) do r.Transparency = open and 0 or 1 end
	end
	apply(tent:GetAttribute("Open") == true)
	for _, f in ipairs(flaps) do
		local cd = f:FindFirstChildWhichIsA("ClickDetector") or Instance.new("ClickDetector", f)
		cd.MaxActivationDistance = 18
		cd.MouseClick:Connect(function() apply(not tent:GetAttribute("Open")) end)
	end
end
for _, t in ipairs(CS:GetTagged("Tent")) do setupTent(t) end
CS:GetInstanceAddedSignal("Tent"):Connect(setupTent)
