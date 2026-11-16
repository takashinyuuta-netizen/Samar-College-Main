--[[ FlashlightServer — the flashlight is switched ON THE SERVER, so every player sees it.
  • Click / tap / F (client asks) → server turns on the spotlight, bulb glow, lit lens and a soft light beam.
  • Battery: lasts ~6 minutes on, recharges in ~1.5 minutes when off. Flickers when low, turns off when empty.
  • Aim: the holder's camera pitch tilts their right arm, so others see the light point up/down.
  • Works for R15 and R6 avatars. ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local remote = RS:WaitForChild("FlashlightRemote")

local DRAIN = 100 / 360   -- % per second while on
local RECHARGE = 100 / 90 -- % per second while off
local LOW = 15
local LENS_OFF = Color3.fromRGB(190, 190, 180)
local LENS_ON = Color3.fromRGB(255, 244, 205)

local function isFlashlight(t) return typeof(t) == "Instance" and t:IsA("Tool") and t.Name == "Flashlight" and t:FindFirstChild("Handle") ~= nil end

local function apply(tool, on, power)
	power = power or 1
	local h = tool.Handle
	local sp, glow, beam = h:FindFirstChild("SpotLight"), h:FindFirstChild("Glow"), h:FindFirstChild("LightBeam")
	local lens = tool:FindFirstChild("Lens")
	if sp then sp.Enabled = on sp.Brightness = 5 * power end
	if glow then glow.Enabled = on glow.Brightness = 1.2 * power end
	if beam then beam.Enabled = on and power > 0.25 end
	if lens then
		lens.Material = on and Enum.Material.Neon or Enum.Material.Glass
		lens.Color = on and LENS_OFF:Lerp(LENS_ON, math.clamp(power, 0, 1)) or LENS_OFF
	end
end

local function setOn(tool, on)
	tool:SetAttribute("On", on)
	apply(tool, on, 1)
	local snd = tool.Handle:FindFirstChild("Sound")
	if snd then snd:Play() end
end

---------------------------------------------------------------- aim (tilts the flashlight in the hand via Tool.Grip — replicates to everyone, works with every avatar type)
local aim = {} -- [player] = tool currently tilted
local baseGrip = setmetatable({}, { __mode = "k" }) -- [tool] = original Grip
local function gripBase(tool)
	if not baseGrip[tool] then baseGrip[tool] = tool.Grip end
	return baseGrip[tool]
end
local function restore(player)
	local t = aim[player]
	if t and baseGrip[t] then t.Grip = baseGrip[t] end
	aim[player] = nil
end
local function setAim(player, tool, pitch)
	pitch = math.clamp(pitch, math.rad(-60), math.rad(65))
	-- the held flashlight naturally points ~7° down, so add that back; negative X angle tilts it up
	tool.Grip = gripBase(tool) * CFrame.Angles(-(pitch + 0.13), 0, 0)
	aim[player] = tool
end

---------------------------------------------------------------- requests
local lastToggle = {}
remote.OnServerEvent:Connect(function(player, action, tool, pitch)
	if not isFlashlight(tool) then return end
	local char = player.Character
	if not (char and tool.Parent == char) then return end -- must be holding it
	if action == "toggle" then
		local now = os.clock()
		if lastToggle[player] and now - lastToggle[player] < 0.25 then return end
		lastToggle[player] = now
		local on = tool:GetAttribute("On") == true
		if not on and (tool:GetAttribute("Battery") or 100) <= 0 then
			local snd = tool.Handle:FindFirstChild("Sound") if snd then snd:Play() end -- click, but no power
			return
		end
		setOn(tool, not on)
	elseif action == "aim" and type(pitch) == "number" and pitch == pitch then
		setAim(player, tool, pitch)
	end
end)

---------------------------------------------------------------- battery + flicker loop
task.spawn(function()
	local dt = 0.25
	while true do
		task.wait(dt)
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local held
			local tools = {}
			if char then for _, t in ipairs(char:GetChildren()) do if isFlashlight(t) then held = t table.insert(tools, t) end end end
			local bp = player:FindFirstChildOfClass("Backpack")
			if bp then for _, t in ipairs(bp:GetChildren()) do if isFlashlight(t) then table.insert(tools, t) end end end
			for _, t in ipairs(tools) do
				local b = t:GetAttribute("Battery") or 100
				local on = t:GetAttribute("On") == true
				if t == held and on then
					b = math.max(0, b - DRAIN * dt)
					if b <= 0 then setOn(t, false)
					elseif b < LOW then
						local p = (math.random() < 0.18) and 0.15 or (0.55 + b / LOW * 0.45) -- low battery flicker
						apply(t, true, p)
					else apply(t, true, 1) end
				elseif not on then
					b = math.min(100, b + RECHARGE * dt)
				end
				local r = math.floor(b * 10 + 0.5) / 10
				if t:GetAttribute("Battery") ~= r then t:SetAttribute("Battery", r) end
			end
			if not held and aim[player] then restore(player) end
		end
	end
end)

Players.PlayerRemoving:Connect(function(p) aim[p] = nil lastToggle[p] = nil end)
