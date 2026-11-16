--[[ GearServer — what the Roblox gear tools do while you HOLD them (bought in the shop, equipped from the Bag/hotbar).
  ⚡ Speed Coil    : +12 walk speed (player attribute GearSpeed, ShopServer adds it up) + coil sound + speed trail
  🌀 Gravity Coil  : coil sound + soft glow; the low gravity itself is done by GearClient (your own character's physics)
  🌈 Magic Carpet  : you sit on a big rainbow carpet everyone can see (with a rainbow trail + sparkles);
                    flying is done by GearClient. The gear's Handle is hidden while riding.
  The tools themselves are Roblox's real gear models (ReplicatedStorage.Tools) with their old scripts removed. ]]
local Players = game:GetService("Players")

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)), ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 160, 40)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 240, 60)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 220, 90)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(60, 140, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 80, 230)),
})

local function trail(parent, a0pos, a1pos, life, width)
	local a0 = Instance.new("Attachment") a0.Name = "TrailA" a0.Position = a0pos a0.Parent = parent
	local a1 = Instance.new("Attachment") a1.Name = "TrailB" a1.Position = a1pos a1.Parent = parent
	local t = Instance.new("Trail") t.Name = "GearTrail" t.Attachment0 = a0 t.Attachment1 = a1 t.Color = RAINBOW t.Lifetime = life
	t.LightEmission = 0.6 t.FaceCamera = true t.WidthScale = NumberSequence.new(width or 1)
	t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }) t.Parent = parent
	return { a0, a1, t }
end

local active = {} -- [tool] = { cleanup objects }
local function cleanup(tool)
	for _, o in ipairs(active[tool] or {}) do if typeof(o) == "Instance" and o.Parent then o:Destroy() end end
	active[tool] = nil
end

local function onEquipped(player, character, tool)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local handle = tool:FindFirstChild("Handle")
	if not hrp or not handle then return end
	local made = {}
	if tool.Name == "SpeedCoil" then
		player:SetAttribute("GearSpeed", 12)
		local snd = handle:FindFirstChild("CoilSound") if snd then snd:Play() end
		for _, o in ipairs(trail(hrp, Vector3.new(0, 1.2, 0), Vector3.new(0, -2.2, 0), 0.35, 1)) do table.insert(made, o) end
	elseif tool.Name == "GravityCoil" then
		local snd = handle:FindFirstChild("CoilSound") if snd then snd:Play() end
		local glow = Instance.new("PointLight") glow.Name = "CoilGlow" glow.Color = Color3.fromRGB(120, 180, 255) glow.Range = 8 glow.Brightness = 1.5 glow.Parent = handle
		table.insert(made, glow)
	elseif tool.Name == "MagicCarpet" then
		-- the carpet you ride: a copy of the gear's carpet under your feet
		handle.Transparency = 1
		local ride = handle:Clone()
		ride.Name = "CarpetRide"
		for _, d in ipairs(ride:GetChildren()) do if not d:IsA("SpecialMesh") then d:Destroy() end end
		ride.Transparency = 0 ride.CanCollide = false ride.Massless = true ride.Anchored = false
		local mesh = ride:FindFirstChildOfClass("SpecialMesh")
		if mesh then mesh.Scale = mesh.Scale * 1.6 end
		ride.Size = ride.Size * 1.6
		local hum = character:FindFirstChildOfClass("Humanoid")
		local down = (hum and hum.RigType == Enum.HumanoidRigType.R15) and (hum.HipHeight + hrp.Size.Y / 2 - 0.3) or 2.7
		local w = Instance.new("Weld") w.Part0 = hrp w.Part1 = ride w.C0 = CFrame.new(0, -down, 0) * CFrame.Angles(0, math.rad(90), 0) w.Parent = ride
		ride.Parent = character
		table.insert(made, ride)
		for _, o in ipairs(trail(ride, Vector3.new(0, 0.1, 1.8), Vector3.new(0, 0.1, -1.8), 0.9, 1)) do table.insert(made, o) end
		local sp = Instance.new("Sparkles") sp.SparkleColor = Color3.fromRGB(255, 220, 120) sp.Parent = ride
		local light = Instance.new("PointLight") light.Color = Color3.fromRGB(255, 200, 255) light.Range = 10 light.Brightness = 1.2 light.Parent = ride
		local whoosh = Instance.new("Sound") whoosh.SoundId = "rbxassetid://12222084" whoosh.Volume = 0.4 whoosh.PlaybackSpeed = 1.6 whoosh.Parent = ride whoosh:Play()
		character:SetAttribute("OnCarpet", true)
	end
	active[tool] = made
end

local function onUnequipped(player, character, tool)
	cleanup(tool)
	if tool.Name == "SpeedCoil" then player:SetAttribute("GearSpeed", nil) end
	if tool.Name == "MagicCarpet" then
		local handle = tool:FindFirstChild("Handle")
		if handle then handle.Transparency = 0 end
		if character then character:SetAttribute("OnCarpet", nil) end
	end
end

local GEAR = { SpeedCoil = true, GravityCoil = true, MagicCarpet = true }
local function watchCharacter(player, character)
	character.ChildAdded:Connect(function(c)
		if c:IsA("Tool") and GEAR[c.Name] then onEquipped(player, character, c) end
	end)
	character.ChildRemoved:Connect(function(c)
		if c:IsA("Tool") and GEAR[c.Name] then onUnequipped(player, character, c) end
	end)
	player:SetAttribute("GearSpeed", nil)
end
local function onPlayer(player)
	player.CharacterAdded:Connect(function(ch) watchCharacter(player, ch) end)
	if player.Character then watchCharacter(player, player.Character) end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
