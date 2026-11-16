-- Performance settings (client only, each player's own choice):
--   Setting_ImproveFPS     : no shadows, simple materials, no repeating textures, signs drawn only nearby
--   Setting_DisableEffects : particles / beams / trails / fire / smoke off, post effects (bloom, blur, sun rays...) off
--   Setting_Shadows        : false = no sun shadows and no light shadows (true by default)
-- Toggled from the HUD Settings page. Everything is restored when switched off.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local saved = { mat = setmetatable({}, {__mode = "k"}), shadow = setmetatable({}, {__mode = "k"}), gui = setmetatable({}, {__mode = "k"}), tex = setmetatable({}, {__mode = "k"}), fx = setmetatable({}, {__mode = "k"}) }
local fpsOn, fxOn = false, false
local globalShadows = Lighting.GlobalShadows
local KEEP = { [Enum.Material.SmoothPlastic] = true, [Enum.Material.Plastic] = true, [Enum.Material.Neon] = true, [Enum.Material.Glass] = true, [Enum.Material.ForceField] = true }
local FX = { ParticleEmitter = true, Beam = true, Trail = true, Smoke = true, Fire = true, Sparkles = true }
local POST = { BloomEffect = true, BlurEffect = true, SunRaysEffect = true, DepthOfFieldEffect = true, ColorCorrectionEffect = true }

local function fpsApply(d)
	if d:IsA("BasePart") then
		if not KEEP[d.Material] and not d:IsA("Terrain") and saved.mat[d] == nil then saved.mat[d] = d.Material d.Material = Enum.Material.SmoothPlastic end
	elseif d:IsA("SurfaceGui") then
		if saved.gui[d] == nil then saved.gui[d] = d.MaxDistance if d.MaxDistance == 0 or d.MaxDistance > 70 then d.MaxDistance = 70 end end
	elseif d:IsA("Texture") then
		if saved.tex[d] == nil then saved.tex[d] = d.Transparency d.Transparency = 1 end
	end
end
local function fxApply(d)
	if FX[d.ClassName] and saved.fx[d] == nil then saved.fx[d] = d.Enabled d.Enabled = false end
end

local function runChunked(list, fn)
	for i, d in ipairs(list) do
		fn(d)
		if i % 3000 == 0 then RunService.Heartbeat:Wait() end
	end
end

-- SHADOW BUDGET (the big FPS fix):
-- ~1,400 campus lights can cast shadows, and drawing all of them at once is what made the game slow.
-- Now only the lights closest to your camera (MAX_SHADOW_LIGHTS, within SHADOW_RANGE studs) cast
-- shadows. You still see your shadow under the lights around you; far-away lights skip shadows.
-- Shadows switch OFF or Improve FPS ON = no shadows at all (sun + lights).
local UIS = game:GetService("UserInputService")
local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled
-- phones / tablets: fewer light shadows (they are the most expensive thing for a phone GPU)
local MAX_SHADOW_LIGHTS = IS_MOBILE and 3 or 8
local SHADOW_RANGE = IS_MOBILE and 36 or 50
local shadowLights = {}            -- every light that is allowed to cast shadows
local litNow = {}                  -- lights casting shadows right now
local shadowsOff = false
local function registerLight(d)
	if d:IsA("Light") and (d.Shadows or d:GetAttribute("SC_CanShadow")) and not shadowLights[d] then
		d:SetAttribute("SC_CanShadow", true)
		shadowLights[d] = true
		d.Shadows = false
	end
end
local function shadowApply(d) registerLight(d) end
for i, d in ipairs(workspace:GetDescendants()) do registerLight(d) if i % 4000 == 0 then RunService.Heartbeat:Wait() end end
local function updateShadowLights()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local want = {}
	if not shadowsOff then
		local camPos = cam.CFrame.Position
		local near = {}
		for l in pairs(shadowLights) do
			local p = l.Parent
			if p and p:IsA("BasePart") and l.Enabled then
				local dist = (p.Position - camPos).Magnitude
				if dist < SHADOW_RANGE then table.insert(near, { l = l, d = dist }) end
			elseif not p then shadowLights[l] = nil end
		end
		table.sort(near, function(a, b) return a.d < b.d end)
		for k = 1, math.min(MAX_SHADOW_LIGHTS, #near) do want[near[k].l] = true end
	end
	for l in pairs(litNow) do if not want[l] then if l.Parent then l.Shadows = false end litNow[l] = nil end end
	for l in pairs(want) do if not litNow[l] then l.Shadows = true litNow[l] = true end end
end
task.spawn(function() while true do updateShadowLights() task.wait(0.4) end end)
local function setShadows(off)
	if off == shadowsOff then return end
	shadowsOff = off
	Lighting.GlobalShadows = (not off) and globalShadows
	updateShadowLights()
end

local function setFPS(on)
	if on == fpsOn then return end
	fpsOn = on
	if on then
		task.spawn(runChunked, workspace:GetDescendants(), function(d) if fpsOn then fpsApply(d) end end)
	else
		for p, m in pairs(saved.mat) do if p.Parent then p.Material = m end end
		for g, dist in pairs(saved.gui) do if g.Parent then g.MaxDistance = dist end end
		for t, tr in pairs(saved.tex) do if t.Parent then t.Transparency = tr end end
		saved.mat, saved.gui, saved.tex = setmetatable({}, {__mode = "k"}), setmetatable({}, {__mode = "k"}), setmetatable({}, {__mode = "k"})
	end
end

local post = {}
local function setFX(on)
	if on == fxOn then return end
	fxOn = on
	if on then
		for _, e in ipairs(Lighting:GetDescendants()) do
			if POST[e.ClassName] then post[e] = e.Enabled e.Enabled = false
			elseif e:IsA("Clouds") then post[e] = e.Enabled e.Enabled = false
			elseif e:IsA("Atmosphere") then post[e] = e.Density e.Density = 0 end
		end
		task.spawn(runChunked, workspace:GetDescendants(), function(d) if fxOn then fxApply(d) end end)
	else
		for e, v in pairs(post) do if e.Parent then if e:IsA("Atmosphere") then e.Density = v else e.Enabled = v end end end
		post = {}
		for d, v in pairs(saved.fx) do if d.Parent then d.Enabled = v end end
		saved.fx = setmetatable({}, {__mode = "k"})
	end
end

-- PHONES: signs / posters / screens (SurfaceGuis, ~6,500 on campus) are only drawn when close.
-- Text further than this is unreadable on a small screen anyway, and each one costs the phone time.
local MOBILE_SIGN_DIST = 80
local function mobileSign(d)
	if IS_MOBILE and d:IsA("SurfaceGui") and (d.MaxDistance == 0 or d.MaxDistance > MOBILE_SIGN_DIST) then
		local part = d.Adornee or d.Parent
		local big = part and part:IsA("BasePart") and math.max(part.Size.X, part.Size.Y, part.Size.Z) > 30
		if not big then d.MaxDistance = MOBILE_SIGN_DIST end
	end
end
if IS_MOBILE then task.spawn(runChunked, workspace:GetDescendants(), mobileSign) end

-- things that stream in later follow the current settings
workspace.DescendantAdded:Connect(function(d)
	if IS_MOBILE then mobileSign(d) end
	if fpsOn then fpsApply(d) end
	registerLight(d) -- every light that streams in joins the shadow budget (only the nearest cast shadows)
	if fxOn then fxApply(d) end
end)

local function sync()
	setFPS(player:GetAttribute("Setting_ImproveFPS") == true)
	setShadows(player:GetAttribute("Setting_ImproveFPS") == true or player:GetAttribute("Setting_Shadows") == false)
	setFX(player:GetAttribute("Setting_DisableEffects") == true)
end
player:GetAttributeChangedSignal("Setting_ImproveFPS"):Connect(sync)
player:GetAttributeChangedSignal("Setting_DisableEffects"):Connect(sync)
player:GetAttributeChangedSignal("Setting_Shadows"):Connect(sync)
sync()
