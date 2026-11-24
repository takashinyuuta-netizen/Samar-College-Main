-- AutoPerformance: low-end device detection.
-- Roblox does not tell a game the exact phone or PC model, so this script uses what it can know:
--   • the device type (phone, tablet, console or PC) from the input and screen size
--   • the real frame rate (FPS) measured on this player's device
-- When the device is weak (low FPS), it turns on the low-end settings for this visit:
--   Improve FPS = on, Disable Effects = on, Shadows = off,
--   moving day & night cycle = off (the sky stays at Day), live weather = off (stays Sunny),
--   season details = off
-- Phones, tablets and consoles get this right away; PCs only when the measured FPS is low.
-- A setting the player chose in Settings (now or on an earlier visit) is NEVER changed.
-- Auto choices are not saved, so a better device is checked again next time.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local FIRST_CHECK_FPS = 30   -- average FPS after loading below this -> low mode
local LATER_CHECK_FPS = 22   -- later 15-second windows below this -> low mode
local LOW = {
	Setting_ImproveFPS = true, Setting_DisableEffects = true, Setting_Shadows = false,
	Setting_Grass = false,                    -- grass blades OFF (flat green ground)
	Setting_TimeMode = "Day",                 -- live day & night cycle OFF: the sky stays at noon
	Setting_Weather = "Sunny",                -- live weather OFF: no rain / storms / fog / lightning
	Setting_GroundCover = false,              -- season details OFF: snow / leaves / petals on the ground
	Setting_SeasonSteps = false,              --   season footsteps & footprints
	Setting_SeasonCritters = false,           --   butterflies & frosty breath
}

local function deviceType()
	if GuiService:IsTenFootInterface() then return "Console" end
	if UIS.TouchEnabled and not UIS.KeyboardEnabled then
		local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 400)
		return math.min(v.X, v.Y) < 600 and "Phone" or "Tablet"
	end
	return "PC"
end
player:SetAttribute("SC_DeviceType", deviceType())

local savedKeys
local function userChose(k)
	if player:GetAttribute("SC_UserSet_" .. k) then return true end
	if savedKeys == nil then
		savedKeys = {}
		local raw = player:GetAttribute("SavedSettings")
		if type(raw) == "string" then
			local ok, t = pcall(HttpService.JSONDecode, HttpService, raw)
			if ok and type(t) == "table" then savedKeys = t end
		end
	end
	return savedKeys[k] ~= nil
end

local function notify(text)
	for _ = 1, 5 do
		local ok = pcall(function()
			StarterGui:SetCore("SendNotification", { Title = "⚡ Low-end mode on", Text = text, Duration = 8 })
		end)
		if ok then return end
		task.wait(1)
	end
end

-- Weather & Season page choices are not saved between visits, so watch for the player changing them
-- here (a change from one value to another = the player's own choice).
local applying = false
local prev = {}
for k in pairs(LOW) do
	prev[k] = player:GetAttribute(k)
	player:GetAttributeChangedSignal(k):Connect(function()
		local v = player:GetAttribute(k)
		if not applying and prev[k] ~= nil and v ~= prev[k] and not k:find("ImproveFPS") and not k:find("DisableEffects") and not k:find("Shadows") and not k:find("Grass") then
			player:SetAttribute("SC_UserSet_" .. k, true)
		end
		prev[k] = v
	end)
end

local applied = false
local function applyLow(reason)
	if applied then return end
	local changed = 0
	applying = true
	for k, v in pairs(LOW) do
		if not userChose(k) and player:GetAttribute(k) ~= v then player:SetAttribute(k, v) changed += 1 end
	end
	applying = false
	applied = true
	if changed > 0 then
		player:SetAttribute("SC_AutoLowMode", reason)
		notify((reason:find("device") and "Low-end mode is on for your device" or "Your device was running slow, so low-end mode is on")
			.. ": shadows, grass, effects, live weather, the day & night cycle and season details are off. Turn them back on in Settings.")
	end
end

-- When the game window is minimized / in the background (or the phone app is switched away),
-- Roblox draws very few frames on purpose. Those samples are not the device's real speed, so
-- they are thrown away and measured again.
local focused = true
UIS.WindowFocused:Connect(function() focused = true end)
UIS.WindowFocusReleased:Connect(function() focused = false end)

-- average FPS over a time window (nil = not a fair sample)
local function measure(seconds)
	local frames, t0, lostFocus = 0, os.clock(), not focused
	local conn = RunService.RenderStepped:Connect(function() frames += 1 end)
	local fc = UIS.WindowFocusReleased:Connect(function() lostFocus = true end)
	task.wait(seconds)
	conn:Disconnect() fc:Disconnect()
	local fps = frames / math.max(os.clock() - t0, 0.001)
	if lostFocus or not focused or fps < 5 then return nil end -- background / hidden window
	return fps
end

-- wait until the Settings toggles have loaded and the player is in the campus
local t0 = os.clock()
while player:GetAttribute("Setting_ImproveFPS") == nil and os.clock() - t0 < 30 do task.wait(0.5) end
if not player.Character then player.CharacterAdded:Wait() end
-- phones, tablets and consoles: low-end mode right away (no need to measure)
local dev = player:GetAttribute("SC_DeviceType")
if dev ~= "PC" then applyLow("low-end device: " .. tostring(dev)) end
task.wait(6) -- let the campus finish streaming in

-- STEP 1 for PCs: sun shadows are the biggest cost in the campus (about 2/3 of the drawing work),
-- so a slow PC first only loses the sun shadows. Everything else stays nice.
-- If it is still slow after that, STEP 2 = the full low-end mode.
local shadowStep = false
local function tryShadowStep(fpsNow)
	if shadowStep or applied or dev ~= "PC" or userChose("Setting_Shadows") then return false end
	if player:GetAttribute("Setting_Shadows") == false then return false end
	shadowStep = true
	applying = true
	player:SetAttribute("Setting_Shadows", false)
	applying = false
	player:SetAttribute("SC_AutoLowMode", ("shadows only: %d FPS"):format(math.floor(fpsNow)))
	pcall(function()
		StarterGui:SetCore("SendNotification", { Title = "⚡ Smoother mode", Text = "Sun shadows were turned off to make the game smoother. Turn them back on in Settings.", Duration = 8 })
	end)
	return true
end

local fps
for _ = 1, 6 do -- try until we get a fair sample
	fps = measure(8)
	if fps then break end
	task.wait(5)
end
if fps then
	player:SetAttribute("SC_MeasuredFPS", math.floor(fps + 0.5))
	if fps < FIRST_CHECK_FPS then
		if tryShadowStep(fps) then
			task.wait(4)
			local again
			for _ = 1, 4 do again = measure(8) if again then break end task.wait(4) end
			if again then player:SetAttribute("SC_MeasuredFPS", math.floor(again + 0.5)) end
			if again and again < LATER_CHECK_FPS then applyLow(("first check: %d FPS"):format(math.floor(again))) end
		else
			applyLow(("first check: %d FPS"):format(math.floor(fps)))
		end
	end
end

-- keep watching (e.g. a crowded event or a long play session on a weak device)
while not applied do
	task.wait(15)
	fps = measure(15)
	if fps then player:SetAttribute("SC_MeasuredFPS", math.floor(fps + 0.5)) end
	if fps and fps < LATER_CHECK_FPS then
		if not tryShadowStep(fps) then applyLow(("later check: %d FPS"):format(math.floor(fps))) end
	end
end
