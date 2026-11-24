-- Performance settings (client only, each player's own choice):
--   Setting_ImproveFPS     : no shadows, simple materials, no repeating textures, signs drawn only nearby,
--                            far lights off, no water reflections, simple sky lighting,
--                            and small details (bolts, cups, books, plants...) drawn only near you
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
local allLights = {}               -- every light (for Improve FPS light culling)
local function registerLight(d)
	if d:IsA("Light") then allLights[d] = true end
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

-- LIGHT CULLING (Improve FPS): the campus has ~2,400 lights. Lights far from your camera are
-- switched off for you only (Range 0) and come back when you get near. Server scripts that turn
-- lights on/off still work, because Enabled is never touched.
local LIGHT_RANGE = IS_MOBILE and 60 or 90
-- ALWAYS ON (even with Improve FPS off): lights further than this are off for you. Their glow is too far to
-- matter, but every light the camera can see costs the device time each frame.
local LIGHT_RANGE_NORMAL = IS_MOBILE and 85 or 140
local culled = {}                  -- light -> its real Range
local function updateCull()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local pos = cam.CFrame.Position
	for l in pairs(allLights) do
		local par = l.Parent
		if not par then allLights[l] = nil culled[l] = nil
		else
			local part = par:IsA("BasePart") and par or (par:IsA("Attachment") and par.Parent) or nil
			local far = part ~= nil and part:IsA("BasePart") and (part.Position - pos).Magnitude > (fpsOn and LIGHT_RANGE or LIGHT_RANGE_NORMAL)
			if far and culled[l] == nil then culled[l] = l.Range l.Range = 0
			elseif not far and culled[l] ~= nil then l.Range = culled[l] culled[l] = nil end
		end
	end
end
task.spawn(function()
	while true do
		updateCull()
		task.wait(0.75)
	end
end)
-- SMALL DETAIL CULLING (Improve FPS): the campus has ~90,000 tiny parts (bolts, cups, books, leaves...).
-- Far away they are only a few pixels, but each one still costs the device time to draw. In Improve FPS
-- mode they are hidden for you only (LocalTransparencyModifier) when they are far from the camera,
-- and come back as you walk closer. Nothing changes for other players or the server.
local DETAIL_SIZE = 2                         -- parts smaller than this (studs, longest side) count as details
local DETAIL_RANGE = IS_MOBILE and 55 or 75   -- details further than this are hidden (Improve FPS)
-- ALWAYS ON: tiny details far away are only a pixel or two — hide them for everyone past this distance
local DETAIL_RANGE_NORMAL = IS_MOBILE and 85 or 130
local CELL = 32
local detailCells = {}                        -- "x,z" -> { parts = {}, hidden = false, c = Vector3 }
local detailSeen = setmetatable({}, { __mode = "k" })
local function registerDetail(d)
	if not d:IsA("BasePart") or detailSeen[d] or d:IsA("Terrain") then return end
	local s = d.Size
	if math.max(s.X, s.Y, s.Z) >= DETAIL_SIZE or not d.Anchored or d.Transparency >= 1 then return end
	if d:FindFirstChildWhichIsA("ProximityPrompt") or d:FindFirstChildWhichIsA("ClickDetector") then return end
	local m = d:FindFirstAncestorWhichIsA("Model")
	if m and m:FindFirstChildOfClass("Humanoid") then return end -- characters / NPCs stay as they are
	detailSeen[d] = true
	local p = d.Position
	local cx, cz = math.floor(p.X / CELL), math.floor(p.Z / CELL)
	local key = cx .. "," .. cz
	local cell = detailCells[key]
	if not cell then
		cell = { parts = {}, hidden = false, c = Vector3.new((cx + 0.5) * CELL, p.Y, (cz + 0.5) * CELL) }
		detailCells[key] = cell
	end
	table.insert(cell.parts, d)
	if cell.hidden then d.LocalTransparencyModifier = 1 end
end
-- details are only collected once Improve FPS is turned on (collecting ~90,000 parts costs time while you travel)
local detailsRegistered = false
local function registerAllDetails()
	if detailsRegistered then return end
	detailsRegistered = true
	for i, d in ipairs(workspace:GetDescendants()) do
		registerDetail(d)
		if i % 4000 == 0 then RunService.Heartbeat:Wait() end
	end
end
local function setCell(cell, hide)
	cell.hidden = hide
	local v = hide and 1 or 0
	local keep, n = {}, 0
	for _, part in ipairs(cell.parts) do
		if part.Parent then
			part.LocalTransparencyModifier = v
			table.insert(keep, part)
			n += 1
			if n % 1500 == 0 then RunService.Heartbeat:Wait() end
		end
	end
	cell.parts = keep
end
local function updateDetails()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local pos = cam.CFrame.Position
	local flat = Vector3.new(pos.X, 0, pos.Z)
	local changed = 0
	for _, cell in pairs(detailCells) do
		local c = cell.c
		-- Improve FPS only: flipping thousands of parts visible at once (e.g. right after a teleport) makes the
		-- renderer rebuild and HITCH, so normal mode leaves details alone (far buildings use SLIM LOD instead)
		local hide = fpsOn and (Vector3.new(c.X, 0, c.Z) - flat).Magnitude > DETAIL_RANGE + CELL * 0.71
		if hide ~= cell.hidden then
			setCell(cell, hide)
			changed += 1
			if changed % 40 == 0 then RunService.Heartbeat:Wait() end
		end
	end
end
local detailsOut = false
task.spawn(function()
	while true do
		if fpsOn then registerAllDetails() updateDetails() detailsOut = true
		elseif detailsOut then updateDetails() detailsOut = false end -- Improve FPS turned off: show everything again
		task.wait(0.5)
	end
end)

-- simple sky lighting (Improve FPS): no environment light / reflections from the sky
local envSaved
local function setEnv(low)
	if low and not envSaved then
		envSaved = { Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale }
		pcall(function() Lighting.EnvironmentDiffuseScale = 0 Lighting.EnvironmentSpecularScale = 0 end)
	elseif not low and envSaved then
		pcall(function() Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = envSaved[1], envSaved[2] end)
		envSaved = nil
	end
end

-- water: no reflections or waves in Improve FPS mode
local terrain = workspace.Terrain
local waterSaved
local function setWater(low)
	if low and not waterSaved then
		waterSaved = { terrain.WaterReflectance, terrain.WaterWaveSize, terrain.WaterWaveSpeed }
		pcall(function() terrain.WaterReflectance = 0 terrain.WaterWaveSize = 0 terrain.WaterWaveSpeed = 0 end)
	elseif not low and waterSaved then
		pcall(function() terrain.WaterReflectance, terrain.WaterWaveSize, terrain.WaterWaveSpeed = waterSaved[1], waterSaved[2], waterSaved[3] end)
		waterSaved = nil
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
	if detailsRegistered then registerDetail(d) end -- small details that stream in join the detail culling
	if fxOn then fxApply(d) end
end)

local function sync()
	setFPS(player:GetAttribute("Setting_ImproveFPS") == true)
	setWater(player:GetAttribute("Setting_ImproveFPS") == true)
	setEnv(player:GetAttribute("Setting_ImproveFPS") == true)
	setShadows(player:GetAttribute("Setting_ImproveFPS") == true or player:GetAttribute("Setting_Shadows") == false)
	setFX(player:GetAttribute("Setting_DisableEffects") == true)
end
player:GetAttributeChangedSignal("Setting_ImproveFPS"):Connect(sync)
player:GetAttributeChangedSignal("Setting_DisableEffects"):Connect(sync)
player:GetAttributeChangedSignal("Setting_Shadows"):Connect(sync)
sync()
