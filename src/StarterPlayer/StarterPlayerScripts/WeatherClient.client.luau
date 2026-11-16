--[[ WeatherClient — draws the weather on THIS player's screen.
  Shows the live campus weather (ReplicatedStorage.Weather "Current") or the player's own pick
  (player attribute "Setting_Weather" = "Auto" or a WeatherConfig id, set in Settings → 🌦️ Weather & Season).
  Blends smoothly between looks: sky light, fog/atmosphere, clouds, colour grading, sun rays, wind,
  rain (+ splashes), snow, haze, falling leaves / petals, lightning + thunder, rainbow, and sounds.
  No rain/snow falls inside buildings (and sounds get muffled indoors).
  Respects Settings: Improve FPS = fewer particles, Disable effects = no particles. ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer
local folder = RS:WaitForChild("Weather")
local C = require(folder:WaitForChild("WeatherConfig"))
local camera = workspace.CurrentCamera
local rand = Random.new()

---------------------------------------------------------------- the place's normal look (weather multiplies this)
local BASE_BRIGHT = Lighting.Brightness
local BASE_EXPOSURE = Lighting.ExposureCompensation
local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds", workspace.Terrain)
local cc = Lighting:FindFirstChild("WeatherColor") or Instance.new("ColorCorrectionEffect")
cc.Name = "WeatherColor" cc.Parent = Lighting
local rays = Lighting:FindFirstChild("WeatherSunRays") or Instance.new("SunRaysEffect")
rays.Name = "WeatherSunRays" rays.Spread = 0.6 rays.Intensity = 0 rays.Parent = Lighting

---------------------------------------------------------------- TIME OF DAY (realistic sunrise / day / golden hour / dusk / night)
-- The server's DayNightCycle moves Lighting.ClockTime (synced with the school schedule).
-- Here each hour gets its own light: brightness, ambient, the colour the sun paints on things,
-- sky / haze colour, cloud colour, colour grade, sun rays and bloom. Weather is layered on top.
local C3 = Color3.fromRGB
local TOD_KEYS = {
	-- hour, bright, exposure, ambient (indoor fill), outdoor ambient, sun colour (ColorShift_Top), haze tint, haze decay tint, cloud tint, grade tint, saturation, sun rays, bloom, bloom threshold
	{ h = 0.0,  b = 0.55, e = 0.05, amb = C3(28, 30, 42), out = C3(38, 48, 78), sun = C3(120, 145, 210), at = C3(45, 55, 85), dt = C3(25, 30, 55), cl = C3(70, 78, 100), gt = C3(205, 218, 255), s = -0.18, r = 0.0, bl = 1.0, th = 1.15 },
	{ h = 4.8,  b = 0.55, e = 0.05, amb = C3(28, 30, 42), out = C3(38, 48, 78), sun = C3(120, 145, 210), at = C3(45, 55, 85), dt = C3(25, 30, 55), cl = C3(70, 78, 100), gt = C3(205, 218, 255), s = -0.18, r = 0.0, bl = 1.0, th = 1.15 },
	{ h = 5.7,  b = 1.1,  e = 0.15, amb = C3(55, 50, 62), out = C3(95, 85, 110), sun = C3(255, 150, 120), at = C3(235, 160, 150), dt = C3(150, 90, 110), cl = C3(255, 175, 160), gt = C3(255, 228, 225), s = 0.02, r = 0.10, bl = 0.8, th = 1.35 },
	{ h = 6.5,  b = 2.0,  e = 0.15, amb = C3(80, 74, 70), out = C3(135, 120, 110), sun = C3(255, 190, 120), at = C3(250, 200, 160), dt = C3(200, 130, 100), cl = C3(255, 215, 180), gt = C3(255, 238, 220), s = 0.08, r = 0.30, bl = 0.65, th = 1.5 },
	{ h = 8.0,  b = 2.8,  e = 0.05, amb = C3(92, 92, 96), out = C3(108, 110, 122), sun = C3(255, 236, 205), at = C3(255, 255, 255), dt = C3(255, 255, 255), cl = C3(255, 255, 255), gt = C3(255, 250, 244), s = 0.06, r = 1.0, bl = 0.55, th = 1.6 },
	{ h = 12.0, b = 3.2,  e = 0.0,  amb = C3(96, 96, 100), out = C3(110, 112, 124), sun = C3(255, 248, 232), at = C3(255, 255, 255), dt = C3(255, 255, 255), cl = C3(255, 255, 255), gt = C3(255, 255, 255), s = 0.06, r = 1.0, bl = 0.55, th = 1.7 },
	{ h = 15.5, b = 3.0,  e = 0.0,  amb = C3(94, 92, 92), out = C3(112, 110, 116), sun = C3(255, 240, 215), at = C3(255, 255, 255), dt = C3(255, 255, 255), cl = C3(255, 255, 255), gt = C3(255, 250, 242), s = 0.06, r = 1.0, bl = 0.55, th = 1.65 },
	{ h = 17.2, b = 2.2,  e = 0.12, amb = C3(90, 76, 66), out = C3(150, 118, 95), sun = C3(255, 170, 90), at = C3(255, 200, 150), dt = C3(255, 150, 80), cl = C3(255, 195, 150), gt = C3(255, 230, 205), s = 0.12, r = 1.3, bl = 0.75, th = 1.4 },
	{ h = 18.0, b = 1.3,  e = 0.15, amb = C3(70, 56, 66), out = C3(120, 90, 110), sun = C3(255, 125, 80), at = C3(250, 165, 130), dt = C3(220, 100, 70), cl = C3(240, 140, 140), gt = C3(255, 220, 220), s = 0.08, r = 0.6, bl = 0.9, th = 1.3 },
	{ h = 18.8, b = 0.75, e = 0.1,  amb = C3(40, 38, 55), out = C3(60, 62, 100), sun = C3(140, 140, 220), at = C3(80, 80, 125), dt = C3(45, 40, 80), cl = C3(110, 105, 140), gt = C3(215, 220, 255), s = -0.08, r = 0.0, bl = 1.0, th = 1.15 },
	{ h = 19.6, b = 0.55, e = 0.05, amb = C3(28, 30, 42), out = C3(38, 48, 78), sun = C3(120, 145, 210), at = C3(45, 55, 85), dt = C3(25, 30, 55), cl = C3(70, 78, 100), gt = C3(205, 218, 255), s = -0.18, r = 0.0, bl = 1.0, th = 1.15 },
	{ h = 24.0, b = 0.55, e = 0.05, amb = C3(28, 30, 42), out = C3(38, 48, 78), sun = C3(120, 145, 210), at = C3(45, 55, 85), dt = C3(25, 30, 55), cl = C3(70, 78, 100), gt = C3(205, 218, 255), s = -0.18, r = 0.0, bl = 1.0, th = 1.15 },
}
local function todAt(hour)
	local a, b = TOD_KEYS[1], TOD_KEYS[2]
	for i = 1, #TOD_KEYS - 1 do
		if hour >= TOD_KEYS[i].h and hour <= TOD_KEYS[i + 1].h then a, b = TOD_KEYS[i], TOD_KEYS[i + 1] break end
	end
	local span = b.h - a.h
	local t = span > 0 and (hour - a.h) / span or 0
	t = t * t * (3 - 2 * t) -- smooth
	local o = {}
	for k, v in pairs(a) do
		if k ~= "h" then
			if type(v) == "number" then o[k] = v + (b[k] - v) * t else o[k] = v:Lerp(b[k], t) end
		end
	end
	return o
end
local function mul(c, t) return Color3.new(c.R * t.R, c.G * t.G, c.B * t.B) end

---------------------------------------------------------------- MY SKY CLOCK (Settings → Weather & Season → Day & Night)
-- Player attribute "Setting_TimeMode":
--   "Live"   = follow the school clock (default)
--   "Frozen" = the day/night cycle is OFF: stays at "Setting_FrozenTime" (the moment it was switched off)
--   "Dawn" / "Day" / "Dusk" / "Night" = a fixed time of day
-- Only this player's screen changes. NPC schedules keep using the real school clock.
local FIXED_TIMES = { Dawn = 6.05, Day = 12.0, Dusk = 18.05, Night = 22.0 }
local function schoolClock() return Lighting:GetAttribute("SchoolClock") or Lighting.ClockTime end
local function wantedClock()
	local mode = player:GetAttribute("Setting_TimeMode") or "Live"
	if FIXED_TIMES[mode] then return FIXED_TIMES[mode], mode end
	if mode == "Frozen" then return tonumber(player:GetAttribute("Setting_FrozenTime")) or schoolClock(), mode end
	return schoolClock(), "Live"
end
local shownClock = nil
local function circDiff(from, to)
	local d = (to - from) % 24
	if d > 12 then d -= 24 end
	return d
end
local function updateSkyClock(dt)
	local want, mode = wantedClock()
	if not shownClock then shownClock = want end
	local d = circDiff(shownClock, want)
	if mode == "Live" and math.abs(d) < 0.02 then
		-- caught up: let the server's clock run the sky directly
		shownClock = Lighting.ClockTime
		return
	end
	-- smooth time-lapse to the picked time (about 2.5 seconds, any distance)
	local step = d * math.min(1, dt * 2.2)
	if math.abs(step) < 0.002 then step = d end
	shownClock = (shownClock + step) % 24
	Lighting.ClockTime = shownClock
end
player:SetAttribute("SkyClockReady", true)
local bloomFx = Lighting:FindFirstChild("SC_Bloom")

---------------------------------------------------------------- targets
local function targetOf(w)
	local s = w.sound or {}
	return {
		bright = w.bright or 1, exposure = w.exposure or 0, rays = w.sunrays or 0,
		aDensity = w.atmo.density, aHaze = w.atmo.haze, aGlare = w.atmo.glare, aColor = w.atmo.color, aDecay = w.atmo.decay,
		cCover = w.clouds.cover, cDensity = w.clouds.density, cColor = w.clouds.color,
		ccTint = w.cc.tint, ccSat = w.cc.sat, ccContrast = w.cc.contrast, ccBright = w.cc.bright,
		wind = w.wind or Vector3.zero, rain = w.rain or 0, snow = w.snow or 0, leaves = w.leaves or 0, petals = w.petals or 0,
		dust = w.dust or 0, rainbow = w.rainbow and 1 or 0,
		vRain = s.rain or 0, vStorm = s.storm or 0, vWind = s.wind or 0,
	}
end
local function lerp(a, b, t)
	if type(a) == "number" then return a + (b - a) * t end
	return a:Lerp(b, t)
end

-- When the player taps "TAP TO CONTINUE" they get a random weather / season of their own ("welcome roll").
-- It stays until the campus weather changes next, then Auto follows the campus again.
local sessionPick = nil
local function chosenId()
	local pick = player:GetAttribute("Setting_Weather")
	if pick and pick ~= "Auto" and C.ById[pick] then return pick end
	if sessionPick then return sessionPick end
	return C.ById[folder:GetAttribute("Current") or ""] and folder:GetAttribute("Current") or "Sunny"
end
local currentId = chosenId()
local target = targetOf(C.ById[currentId])
local cur = table.clone(target)

---------------------------------------------------------------- effects rig (lives under the camera, only this client sees it)
local fx = camera:FindFirstChild("WeatherFX") or Instance.new("Folder")
fx.Name = "WeatherFX" fx.Parent = camera
local function rigPart(name, size)
	local p = Instance.new("Part") p.Name = name p.Size = size p.Transparency = 1 p.Anchored = true
	p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false p.Parent = fx
	return p
end
local sky = rigPart("SkyEmitter", Vector3.new(70, 1, 70))
local near = rigPart("NearEmitter", Vector3.new(34, 1, 34)) -- dense drops right around you
local ground = rigPart("GroundEmitter", Vector3.new(60, 0.2, 60))
local air = rigPart("AirEmitter", Vector3.new(90, 30, 90))

local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local DROP = "rbxasset://textures/whiteCircle.png" -- stretched into thin rain streaks
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local NS, NR = NumberSequence.new, NumberRange.new

local rain = Instance.new("ParticleEmitter")
rain.Name = "Rain" rain.Texture = DROP rain.Orientation = Enum.ParticleOrientation.VelocityParallel
rain.Size = NS(0.14) rain.Squash = NS(-3) rain.Transparency = NS(0.3)
rain.Color = ColorSequence.new(Color3.fromRGB(215, 228, 245)) rain.LightEmission = 0.3 rain.LightInfluence = 0.7
rain.Speed = NR(95, 115) rain.Lifetime = NR(0.55, 0.75) rain.EmissionDirection = Enum.NormalId.Bottom
rain.SpreadAngle = Vector2.new(4, 4) rain.Rate = 0 rain.Parent = sky
local rainNear = rain:Clone() rainNear.Name = "RainNear" rainNear.Lifetime = NR(0.3, 0.42) rainNear.Transparency = NS(0.4) rainNear.Parent = near

local splash = Instance.new("ParticleEmitter")
splash.Name = "Splash" splash.Texture = SPARK splash.Size = NS({ NumberSequenceKeypoint.new(0, 0.28), NumberSequenceKeypoint.new(1, 0) })
splash.Transparency = NS(0.35) splash.Color = ColorSequence.new(Color3.fromRGB(215, 228, 245)) splash.LightEmission = 0.2
splash.Speed = NR(2, 5) splash.Lifetime = NR(0.12, 0.22) splash.EmissionDirection = Enum.NormalId.Top
splash.SpreadAngle = Vector2.new(55, 55) splash.Acceleration = Vector3.new(0, -30, 0) splash.Rate = 0 splash.Parent = ground

local snow = Instance.new("ParticleEmitter")
snow.Name = "Snow" snow.Texture = SPARK
snow.Size = NS({ NumberSequenceKeypoint.new(0, 0.32, 0.12), NumberSequenceKeypoint.new(1, 0.28, 0.1) })
snow.Transparency = NS({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.08, 0.1), NumberSequenceKeypoint.new(0.9, 0.15), NumberSequenceKeypoint.new(1, 1) })
snow.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)) snow.LightEmission = 0.3
snow.Speed = NR(5, 9) snow.Lifetime = NR(7, 9) snow.Rotation = NR(0, 360) snow.RotSpeed = NR(-90, 90)
snow.EmissionDirection = Enum.NormalId.Bottom snow.SpreadAngle = Vector2.new(25, 25) snow.Rate = 0 snow.Parent = sky

local dust = Instance.new("ParticleEmitter")
dust.Name = "Haze" dust.Texture = SMOKE dust.Size = NS({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 3.5) })
dust.Transparency = NS({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.86), NumberSequenceKeypoint.new(1, 1) })
dust.Speed = NR(0.5, 2) dust.Lifetime = NR(5, 8) dust.Rotation = NR(0, 360) dust.RotSpeed = NR(-10, 10) dust.Rate = 0 dust.Parent = air

-- falling leaves / petals: real little parts that flutter in the wind
local LEAF_COLORS = { Color3.fromRGB(214, 120, 40), Color3.fromRGB(190, 70, 35), Color3.fromRGB(230, 170, 50), Color3.fromRGB(140, 95, 50), Color3.fromRGB(110, 150, 60) }
local PETAL_COLORS = { Color3.fromRGB(255, 190, 210), Color3.fromRGB(255, 215, 230), Color3.fromRGB(250, 240, 245), Color3.fromRGB(240, 160, 190) }
local flyers = {}
local MAX_FLYERS = 60
for i = 1, MAX_FLYERS do
	local p = rigPart("Flyer", Vector3.new(0.6, 0.05, 0.4))
	p.Material = Enum.Material.SmoothPlastic
	flyers[i] = { part = p, pos = Vector3.zero, phase = rand:NextNumber(0, 10), spin = Vector3.new(rand:NextNumber(-3, 3), rand:NextNumber(-3, 3), rand:NextNumber(-3, 3)), fall = rand:NextNumber(2, 4), alive = false }
end

-- rainbow (built the first time it's needed): a huge arc beyond the campus
local rainbowParts
local function buildRainbow()
	rainbowParts = {}
	local colors = { Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 150, 40), Color3.fromRGB(255, 235, 60), Color3.fromRGB(70, 210, 90), Color3.fromRGB(60, 140, 255), Color3.fromRGB(90, 70, 220), Color3.fromRGB(170, 80, 220) }
	local center = Vector3.new(160, -80, -950)
	local segs = 36
	for b, col in ipairs(colors) do
		local r = 560 - (b - 1) * 9
		for k = 0, segs - 1 do
			local a1, a2 = math.pi * k / segs, math.pi * (k + 1) / segs
			local p1 = center + Vector3.new(math.cos(a1) * r, math.sin(a1) * r, 0)
			local p2 = center + Vector3.new(math.cos(a2) * r, math.sin(a2) * r, 0)
			local p = rigPart("Rainbow", Vector3.new(9.5, 1, (p2 - p1).Magnitude + 1))
			p.Material = Enum.Material.Neon p.Color = col
			p.CFrame = CFrame.lookAt((p1 + p2) / 2, p2, Vector3.zAxis)
			table.insert(rainbowParts, p)
		end
	end
end

---------------------------------------------------------------- sounds
local sfxGroup = SoundService:FindFirstChild("SFX")
local function loop(name, id)
	local s = Instance.new("Sound") s.Name = "Weather_" .. name s.SoundId = id s.Looped = true s.Volume = 0
	if sfxGroup then s.SoundGroup = sfxGroup end
	local eq = Instance.new("EqualizerSoundEffect") eq.Name = "Muffle" eq.LowGain = 0 eq.MidGain = 0 eq.HighGain = 0 eq.Parent = s
	s.Parent = SoundService s:Play()
	return s
end
local sRain, sStorm, sWind = loop("Rain", C.Sounds.rain), loop("Storm", C.Sounds.storm), loop("Wind", C.Sounds.wind)
sStorm.PlaybackSpeed = 0.78 -- a deeper, heavier rain layer for storms
sStorm.TimePosition = 20

---------------------------------------------------------------- lightning
local flash = 0
local nextStrike = os.clock() + 4
local function rumble(delay, strength)
	task.delay(delay, function()
		local s = Instance.new("Sound") s.SoundId = C.Sounds.wind s.PlaybackSpeed = 0.28 + rand:NextNumber(0, 0.06)
		s.Volume = 1.6 * strength s.TimePosition = rand:NextNumber(0, 40)
		if sfxGroup then s.SoundGroup = sfxGroup end
		local d = Instance.new("DistortionSoundEffect") d.Level = 0.35 d.Parent = s
		s.Parent = SoundService s:Play()
		TweenService:Create(s, TweenInfo.new(3.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Volume = 0 }):Play()
		game:GetService("Debris"):AddItem(s, 3.5)
	end)
end
local function bolt()
	local camPos = camera.CFrame.Position
	local ang = rand:NextNumber(0, math.pi * 2)
	local dist = rand:NextNumber(160, 480)
	local groundPt = Vector3.new(camPos.X + math.cos(ang) * dist, 0, camPos.Z + math.sin(ang) * dist)
	local top = groundPt + Vector3.new(rand:NextNumber(-40, 40), 260, rand:NextNumber(-40, 40))
	local parts = {}
	local function zig(a, b, n, width)
		local prev = a
		for i = 1, n do
			local t = i / n
			local p = a:Lerp(b, t) + (i < n and Vector3.new(rand:NextNumber(-14, 14), 0, rand:NextNumber(-14, 14)) or Vector3.zero)
			local seg = rigPart("Bolt", Vector3.new(width, width, (p - prev).Magnitude))
			seg.Transparency = 0 seg.Material = Enum.Material.Neon seg.Color = Color3.fromRGB(215, 228, 255)
			seg.CFrame = CFrame.lookAt((prev + p) / 2, p)
			table.insert(parts, seg)
			if i == math.floor(n / 2) and width > 1 and rand:NextNumber() < 0.8 then
				zig(p, p + Vector3.new(rand:NextNumber(-60, 60), -rand:NextNumber(60, 110), rand:NextNumber(-60, 60)), 5, width * 0.5)
			end
			prev = p
		end
	end
	zig(top, groundPt, 12, 1.6)
	local light = Instance.new("PointLight") light.Range = 60 light.Brightness = 6 light.Color = Color3.fromRGB(200, 215, 255) light.Parent = parts[#parts]
	for _, p in ipairs(parts) do TweenService:Create(p, TweenInfo.new(0.45), { Transparency = 1 }):Play() game:GetService("Debris"):AddItem(p, 0.5) end
	flash = 1
	task.delay(0.12, function() flash = math.max(flash, 0.7) end)
	rumble(math.clamp(dist / 340, 0.3, 1.6), math.clamp(1.4 - dist / 600, 0.5, 1.2))
end

---------------------------------------------------------------- indoors? (roof above the camera)
local indoor, indoorBlend = false, 0
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function checkIndoor()
	local ignore = { fx }
	if player.Character then table.insert(ignore, player.Character) end
	rayParams.FilterDescendantsInstances = ignore
	local pos = camera.CFrame.Position
	indoor = workspace:Raycast(pos, Vector3.new(0, 150, 0), rayParams) ~= nil
end

---------------------------------------------------------------- quality from Settings
-- phones / tablets get lighter weather automatically (fewer rain drops, snow flakes, leaves)
local UIS = game:GetService("UserInputService")
local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled
local function quality()
	if player:GetAttribute("Setting_DisableEffects") == true then return 0 end
	if player:GetAttribute("Setting_ImproveFPS") == true then return IS_MOBILE and 0.25 or 0.4 end
	return IS_MOBILE and 0.5 or 1
end

---------------------------------------------------------------- write only what changed (PERFORMANCE)
-- Setting a Lighting / Atmosphere / Clouds property makes the engine redo work even when the value is the
-- same, so every write goes through put(): it skips values that barely moved.
local written = setmetatable({}, { __mode = "k" })
local function put(obj, prop, v, eps)
	local c = written[obj]
	if not c then c = {} written[obj] = c end
	local old = c[prop]
	if old ~= nil then
		local ty = typeof(v)
		if ty == "number" then
			if math.abs(v - old) < (eps or 0.002) then return end
		elseif ty == "Color3" then
			local e = eps or 0.004
			if math.abs(v.R - old.R) < e and math.abs(v.G - old.G) < e and math.abs(v.B - old.B) < e then return end
		elseif ty == "Vector3" then
			if (v - old).Magnitude < (eps or 0.05) then return end
		elseif v == old then
			return
		end
	end
	c[prop] = v
	obj[prop] = v
end

---------------------------------------------------------------- weather changes
local toastGui
local function toast(text)
	local pg = player:FindFirstChild("PlayerGui")
	if not pg then return end
	if not toastGui or not toastGui.Parent then
		toastGui = Instance.new("ScreenGui") toastGui.Name = "WeatherToast" toastGui.ResetOnSpawn = false toastGui.DisplayOrder = 15 toastGui.Parent = pg
	end
	local f = Instance.new("Frame") f.AnchorPoint = Vector2.new(0.5, 0) f.Position = UDim2.new(0.5, 0, 0, -60) f.Size = UDim2.fromOffset(420, 40)
	f.BackgroundColor3 = Color3.fromRGB(22, 27, 36) f.BackgroundTransparency = 0.15 f.Parent = toastGui
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
	local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(120, 190, 255) st.Thickness = 1.5 st.Transparency = 0.3 st.Parent = f
	local t = Instance.new("TextLabel") t.BackgroundTransparency = 1 t.Size = UDim2.new(1, -20, 1, 0) t.Position = UDim2.fromOffset(10, 0)
	t.Font = Enum.Font.GothamBold t.TextScaled = true t.TextColor3 = Color3.new(1, 1, 1) t.Text = text t.Parent = f
	local cons = Instance.new("UITextSizeConstraint") cons.MaxTextSize = 17 cons.Parent = t
	TweenService:Create(f, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 62) }):Play()
	task.delay(4.5, function()
		local tw = TweenService:Create(f, TweenInfo.new(0.35), { Position = UDim2.new(0.5, 0, 0, -60) }) tw:Play()
		tw.Completed:Wait() f:Destroy()
	end)
end

local function refresh(fromServer)
	local id = chosenId()
	if id == currentId then return end
	currentId = id
	target = targetOf(C.ById[id])
	player:SetAttribute("Weather_Showing", id)
	if fromServer and (player:GetAttribute("Setting_Weather") or "Auto") == "Auto" and C.Announce[id] then toast(C.Announce[id]) end
end
player:SetAttribute("Weather_Showing", currentId)
folder:GetAttributeChangedSignal("Current"):Connect(function()
	sessionPick = nil -- campus weather moved on: follow it again
	refresh(true)
end)
task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	local t0 = os.clock()
	while not player:GetAttribute("SC_Continued") do
		if os.clock() - t0 > 8 and not pg:FindFirstChild("SC_LoadingScreen") then break end
		task.wait(0.25)
	end
	if (player:GetAttribute("Setting_Weather") or "Auto") ~= "Auto" then return end
	local pool = {}
	for _, w in ipairs(C.List) do if w.id ~= "Typhoon" and w.id ~= "Rainbow" then table.insert(pool, w.id) end end
	sessionPick = pool[rand:NextInteger(1, #pool)]
	if sessionPick == currentId then return end
	currentId = sessionPick
	target = targetOf(C.ById[sessionPick])
	cur = table.clone(target) -- start right in it (no slow fade while you load in)
	player:SetAttribute("Weather_Showing", sessionPick)
	task.delay(2.5, function() if C.Announce[sessionPick] then toast(C.Announce[sessionPick]) end end)
end)
player:GetAttributeChangedSignal("Setting_Weather"):Connect(function() refresh(false) end)

---------------------------------------------------------------- every frame
local clock = 0
local lastIndoorCheck = 0
local lightAcc, windAcc, splashAcc = 1, 1, 1
local todClock, tod = nil, nil
local LIGHT_HZ = IS_MOBILE and 8 or 15 -- how often the sky / light is recalculated (smooth fades still look smooth)
RunService.RenderStepped:Connect(function(dt)
	clock += dt
	local k = math.clamp(dt * 3 / C.Transition, 0, 1)
	for key, v in pairs(target) do cur[key] = lerp(cur[key], v, k) end
	if os.clock() - lastIndoorCheck > 0.25 then lastIndoorCheck = os.clock() checkIndoor() end
	indoorBlend = lerp(indoorBlend, indoor and 1 or 0, math.clamp(dt * 4, 0, 1))
	flash = math.max(0, flash - dt * 6)
	local q = quality()
	local out = 1 - indoorBlend

	-- sky & light = time of day x weather (recalculated LIGHT_HZ times a second, every frame only during lightning)
	updateSkyClock(dt)
	lightAcc += dt
	if lightAcc >= 1 / LIGHT_HZ or flash > 0 then
	lightAcc = 0
	local ct = Lighting.ClockTime
	if not todClock or math.abs(ct - todClock) > 0.0015 then todClock = ct tod = todAt(ct) end
	-- shadows: sharp under a high sun, longer & softer at golden hour, faint and very soft by moonlight,
	-- and soft when clouds cover the sun
	local sunStrength = math.clamp((tod.b - 0.55) / 2.65, 0, 1)
	put(Lighting, "ShadowSoftness", math.clamp(0.34 - 0.27 * sunStrength + math.clamp(1 - cur.bright, 0, 0.6) * 0.45, 0.06, 0.6), 0.01)
	local dim = math.clamp(cur.bright, 0.3, 1.2) -- cloudy / stormy weather also dims the ambient light
	put(Lighting, "Brightness", tod.b * cur.bright + flash * 2.5, 0.01)
	put(Lighting, "ExposureCompensation", tod.e + cur.exposure + flash * 1.6 + indoorBlend * 0.12, 0.005)
	put(Lighting, "Ambient", tod.amb)
	put(Lighting, "OutdoorAmbient", tod.out:Lerp(Color3.new(tod.out.R * dim, tod.out.G * dim, tod.out.B * dim), 0.5))
	put(Lighting, "ColorShift_Top", tod.sun:Lerp(Color3.fromRGB(150, 155, 165), math.clamp(1 - cur.bright, 0, 0.7)))
	put(atmo, "Density", cur.aDensity, 0.003) put(atmo, "Haze", cur.aHaze, 0.02) put(atmo, "Glare", cur.aGlare * math.clamp(tod.r, 0.2, 1.3), 0.02)
	put(atmo, "Color", mul(cur.aColor, tod.at)) put(atmo, "Decay", mul(cur.aDecay, tod.dt))
	-- living sky: cover & thickness slowly breathe (clouds form and thin out over a few minutes)
	local breathe = math.sin(clock / 97) * 0.6 + math.sin(clock / 41 + 1.3) * 0.4
	put(clouds, "Cover", math.clamp(cur.cCover + breathe * 0.07 * (1 - cur.cCover * 0.6), 0, 1), 0.004)
	put(clouds, "Density", math.clamp(cur.cDensity + math.sin(clock / 63 + 0.7) * 0.06, 0, 1), 0.004)
	put(clouds, "Color", mul(cur.cColor, tod.cl))
	put(cc, "TintColor", mul(cur.ccTint, tod.gt)) put(cc, "Saturation", cur.ccSat + tod.s, 0.004) put(cc, "Contrast", cur.ccContrast, 0.004) put(cc, "Brightness", cur.ccBright + flash * 0.25, 0.003)
	put(rays, "Intensity", cur.rays * tod.r, 0.005)
	if bloomFx then put(bloomFx, "Intensity", tod.bl, 0.01) put(bloomFx, "Threshold", tod.th, 0.01) end
	end
	-- clouds drift with GlobalWind: keep at least a gentle breeze so the sky always moves,
	-- and let the breeze slowly swing a little in direction like real upper winds (4x a second is plenty)
	windAcc += dt
	if windAcc >= 0.25 then
		windAcc = 0
		local w = cur.wind
		local flat = Vector3.new(w.X, 0, w.Z)
		local dir = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0.94, 0, 0.34)
		local swing = math.rad(math.sin(clock / 120) * 18)
		dir = Vector3.new(dir.X * math.cos(swing) - dir.Z * math.sin(swing), 0, dir.X * math.sin(swing) + dir.Z * math.cos(swing))
		local speed = math.max(flat.Magnitude, 14) + math.sin(clock / 23) * 2.5 -- gusts
		put(workspace, "GlobalWind", dir * speed + Vector3.new(0, w.Y, 0), 0.2)
	end

	-- particles follow the camera (upwind, so slanted rain still covers the view)
	local cp = camera.CFrame.Position
	local wind = cur.wind
	sky.CFrame = CFrame.new(cp + Vector3.new(0, 38, 0) - Vector3.new(wind.X, 0, wind.Z) * 0.45)
	near.CFrame = CFrame.new(cp + Vector3.new(0, 16, 0) - Vector3.new(wind.X, 0, wind.Z) * 0.2)
	air.CFrame = CFrame.new(cp)
	put(rain, "Acceleration", Vector3.new(wind.X, 0, wind.Z) * 1.4, 0.2)
	put(rain, "Rate", math.floor(2400 * cur.rain * q * out), 4)
	put(rainNear, "Acceleration", Vector3.new(wind.X, 0, wind.Z) * 1.4, 0.2)
	put(rainNear, "Rate", math.floor(1100 * cur.rain * q * out), 4)
	put(snow, "Acceleration", Vector3.new(wind.X, -1, wind.Z) * 0.35, 0.1)
	put(snow, "Rate", math.floor(520 * cur.snow * q * out), 2)
	put(dust, "Acceleration", Vector3.new(wind.X, 0, wind.Z) * 0.08, 0.05)
	if lightAcc == 0 then
		local dc = cur.aColor
		local old = written[dust] and written[dust].__col
		if not old or math.abs(old.R - dc.R) + math.abs(old.G - dc.G) + math.abs(old.B - dc.B) > 0.02 then
			dust.Color = ColorSequence.new(dc)
			written[dust] = written[dust] or {} written[dust].__col = dc
		end
	end
	put(dust, "Rate", cur.dust * 6 * q, 0.1)
	-- splashes on the ground under you (the ground height is checked 10x a second)
	if cur.rain > 0.05 and q > 0 and out > 0.5 then
		splashAcc += dt
		if splashAcc >= 0.1 then
			splashAcc = 0
			local hit = workspace:Raycast(cp, Vector3.new(0, -80, 0), rayParams)
			ground.CFrame = CFrame.new(Vector3.new(cp.X, hit and hit.Position.Y + 0.15 or cp.Y - 6, cp.Z))
		end
		put(splash, "Rate", math.floor(520 * cur.rain * q * out), 4)
	else
		put(splash, "Rate", 0)
	end

	-- leaves / petals (moved together in one BulkMoveTo call)
	local want = math.floor((cur.leaves + cur.petals) * q * out + 0.5)
	local petalMode = cur.petals > cur.leaves
	local moveParts, moveCFs = {}, {}
	for i, f in ipairs(flyers) do
		local p = f.part
		if i <= want then
			if not f.alive or (f.pos - cp).Magnitude > 38 or f.pos.Y < cp.Y - 14 then
				local up = (wind.Magnitude > 0.1) and -Vector3.new(wind.X, 0, wind.Z).Unit * rand:NextNumber(4, 16) or Vector3.zero
				-- mostly in front of the camera so you actually see them drift past
				local look = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
				local ahead = look.Magnitude > 0.01 and look.Unit * rand:NextNumber(4, 18) or Vector3.zero
				f.pos = cp + up + ahead + Vector3.new(rand:NextNumber(-18, 18), rand:NextNumber(1, 11), rand:NextNumber(-18, 18))
				f.alive = true
				if petalMode then
					p.Size = Vector3.new(0.5, 0.04, 0.4) p.Color = PETAL_COLORS[rand:NextInteger(1, #PETAL_COLORS)]
				else
					p.Size = Vector3.new(0.95, 0.05, 0.62) p.Color = LEAF_COLORS[rand:NextInteger(1, #LEAF_COLORS)]
				end
				p.Transparency = 0
			end
			local flutter = Vector3.new(math.sin(clock * 2.1 + f.phase) * 1.6, math.sin(clock * 3 + f.phase) * 0.6, math.cos(clock * 1.7 + f.phase) * 1.6)
			f.pos += (Vector3.new(wind.X, 0, wind.Z) * 0.42 + Vector3.new(0, -f.fall * (petalMode and 0.6 or 1), 0) + flutter) * dt
			table.insert(moveParts, p)
			table.insert(moveCFs, CFrame.new(f.pos) * CFrame.Angles(clock * f.spin.X, clock * f.spin.Y, clock * f.spin.Z))
		elseif f.alive then
			f.alive = false p.Transparency = 1
		end
	end
	if #moveParts > 0 then workspace:BulkMoveTo(moveParts, moveCFs, Enum.BulkMoveMode.FireCFrameChanged) end

	-- rainbow
	if cur.rainbow > 0.02 and q > 0 then
		if not rainbowParts then buildRainbow() end
		local tr = 1 - 0.55 * cur.rainbow
		for _, p in ipairs(rainbowParts) do p.Transparency = tr end
	elseif rainbowParts and rainbowParts[1].Transparency < 1 then
		for _, p in ipairs(rainbowParts) do p.Transparency = 1 end
	end

	-- lightning
	local w = C.ById[currentId]
	if w.lightning and os.clock() >= nextStrike then
		nextStrike = os.clock() + rand:NextNumber(w.lightning[1], w.lightning[2])
		if cur.rain > 0.5 then bolt() end
	elseif not w.lightning then
		nextStrike = math.max(nextStrike, os.clock() + 3)
	end

	-- sounds (muffled indoors)
	local muffle = indoorBlend
	put(sRain, "Volume", cur.vRain * (1 - 0.6 * muffle), 0.005)
	put(sStorm, "Volume", cur.vStorm * (1 - 0.5 * muffle), 0.005)
	put(sWind, "Volume", cur.vWind * (1 - 0.65 * muffle), 0.005)
	for _, s in ipairs({ sRain, sStorm, sWind }) do put(s.Muffle, "HighGain", -28 * muffle, 0.3) put(s.Muffle, "MidGain", -8 * muffle, 0.3) end
end)
