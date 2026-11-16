--[[ AutoLights (client)
  Every lamp tagged "SC_AutoLight" turns on/off by itself — no switches.
  It follows the time of day THIS player sees, so it respects the player's Day & Night setting
  (Live cycle, Frozen time, or a fixed Dawn / Day / Dusk / Night chosen in Settings):
    • on from 5:45 PM until 6:15 AM
    • also on during dark storms (rain / thunderstorm / typhoon)
  Lamps switch in a gentle wave (not all at once), lights fade in, and fountain lights slowly shift colour. ]]
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local TAG = "SC_AutoLight"
local ON_AT, OFF_AT = 17.75, 6.25
local fixtures = {} -- [part] = { lights = {...}, delay = n }

local function isStormy()
	local w = tostring(player:GetAttribute("Weather_Showing") or "")
	w = w:lower()
	return w:find("storm") or w:find("thunder") or w:find("typhoon") or w:find("heavy")
end
-- the time of day THIS player sees (same rules as WeatherClient's Day & Night setting)
local FIXED_TIMES = { Dawn = 6.05, Day = 12.0, Dusk = 18.05, Night = 22.0 }
local function seenClock()
	local mode = player:GetAttribute("Setting_TimeMode") or "Live"
	if FIXED_TIMES[mode] then return FIXED_TIMES[mode] end
	if mode == "Frozen" then
		local f = tonumber(player:GetAttribute("Setting_FrozenTime"))
		if f then return f end
	end
	return Lighting:GetAttribute("SchoolClock") or Lighting.ClockTime
end
local function wantOn()
	local t = seenClock()
	if t >= ON_AT or t < OFF_AT then return true end
	if isStormy() then return true end
	return false
end

local function register(part)
	if not part:IsA("BasePart") or fixtures[part] then return end
	local lights = {}
	for _, d in ipairs(part:GetChildren()) do if d:IsA("Light") then table.insert(lights, d) end end
	local p = part.Position
	fixtures[part] = { lights = lights, delay = ((p.X * 0.013 + p.Z * 0.007) % 1) * 1.4, state = nil }
end
for _, p in ipairs(CollectionService:GetTagged(TAG)) do register(p) end
CollectionService:GetInstanceAddedSignal(TAG):Connect(register)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(p) fixtures[p] = nil end)

local function apply(part, info, on, instant)
	if info.state == on then return end
	info.state = on
	local function go()
		if not part.Parent then return end
		local onColor = part:GetAttribute("OnColor") or Color3.fromRGB(255, 236, 190)
		local offColor = part:GetAttribute("OffColor") or part.Color
		local offMat = Enum.Material[part:GetAttribute("OffMaterial") or "Glass"] or Enum.Material.Glass
		part.Material = on and Enum.Material.Neon or offMat
		part.Color = on and onColor or offColor
		for _, l in ipairs(info.lights) do
			local target = l:GetAttribute("OnBrightness") or 1
			if on then
				l.Enabled = true
				if instant then l.Brightness = target else
					l.Brightness = 0
					TweenService:Create(l, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { Brightness = target }):Play()
				end
			else
				l.Enabled = false
			end
		end
	end
	if instant then go() else task.delay(info.delay, go) end
end

local current = nil
local function update(instant)
	local on = wantOn()
	if on == current and not instant then return end
	current = on
	for part, info in pairs(fixtures) do
		if instant then info.state = nil end
		apply(part, info, on, instant)
	end
end
-- newly streamed-in lamps match the current state
CollectionService:GetInstanceAddedSignal(TAG):Connect(function(p)
	task.defer(function() local info = fixtures[p] if info and current ~= nil then info.state = nil apply(p, info, current, true) end end)
end)

update(true)
task.spawn(function()
	while true do
		task.wait(0.5)
		update(false)
	end
end)

-- fountain lights gently cycle through water colours at night
local palette = { Color3.fromRGB(80, 170, 255), Color3.fromRGB(150, 110, 255), Color3.fromRGB(70, 220, 200), Color3.fromRGB(110, 200, 255) }
local t0 = 0
RunService.Heartbeat:Connect(function(dt)
	if not current then return end
	t0 += dt
	if t0 < 0.1 then return end
	local clock = os.clock()
	t0 = 0
	for part, info in pairs(fixtures) do
		if info.state and part:GetAttribute("Kind") == "fountain" then
			local i = (clock * 0.25 + info.delay) % #palette
			local a, b = palette[math.floor(i) + 1], palette[(math.floor(i) + 1) % #palette + 1]
			local c = a:Lerp(b, i - math.floor(i))
			part.Color = c
			for _, l in ipairs(info.lights) do l.Color = c end
		end
	end
end)
