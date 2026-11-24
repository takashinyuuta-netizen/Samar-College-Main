--[[ SettingsServer — remembers each player's Settings page choices between visits.
  Saved: Improve FPS, Disable Effects, Shadows, Show FPS, Grass, Event Alerts, Leaderboard Updates, Music and SFX volume.
  • On join the saved table is put on the player as attribute "SavedSettings" (JSON) and "SettingsLoaded" = true;
    HUDClient reads it to set the toggles / sliders (and PerformanceSettings applies them right away).
  • The client sends changes with ReplicatedStorage.SettingsRemote (validated here), saved a few seconds
    later and again when the player leaves. ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local remote = RS:FindFirstChild("SettingsRemote") or Instance.new("RemoteEvent")
remote.Name = "SettingsRemote" remote.Parent = RS

local store
pcall(function() store = DataStoreService:GetDataStore("SC_Settings_v1") end)

-- allowed settings and their type
local SCHEMA = {
	Setting_ImproveFPS = "boolean",
	Setting_DisableEffects = "boolean",
	Setting_Shadows = "boolean",
	Setting_ShowFPS = "boolean",
	Setting_Grass = "boolean",
	Setting_EventAlerts = "boolean",
	Setting_LeaderboardUpdates = "boolean",
	Setting_MusicVolume = "number",
	Setting_SFXVolume = "number",
}

local data, dirty, lastMsg = {}, {}, {}

local function publish(p)
	local ok, json = pcall(HttpService.JSONEncode, HttpService, data[p] or {})
	p:SetAttribute("SavedSettings", ok and json or "{}")
	p:SetAttribute("SettingsLoaded", true)
end

local function save(p)
	if not (store and dirty[p] and data[p]) then return end
	dirty[p] = nil
	local copy = table.clone(data[p])
	pcall(function() store:SetAsync("u" .. p.UserId, copy) end)
end

Players.PlayerAdded:Connect(function(p)
	local saved = {}
	if store then
		local ok, res = pcall(function() return store:GetAsync("u" .. p.UserId) end)
		if ok and type(res) == "table" then
			for k, v in pairs(res) do if SCHEMA[k] and type(v) == SCHEMA[k] then saved[k] = v end end
		end
	end
	if not p.Parent then return end
	data[p] = saved
	publish(p)
end)
-- players already in (Studio test start)
for _, p in ipairs(Players:GetPlayers()) do if not data[p] then data[p] = {} publish(p) end end

remote.OnServerEvent:Connect(function(p, key, value)
	if type(key) ~= "string" or not SCHEMA[key] or type(value) ~= SCHEMA[key] then return end
	if SCHEMA[key] == "number" then
		if value ~= value then return end -- NaN
		value = math.clamp(math.floor(value * 100 + 0.5) / 100, 0, 1)
	end
	-- light rate limit (sliders send while dragging)
	local now = os.clock()
	lastMsg[p] = lastMsg[p] or { t = now, n = 0 }
	if now - lastMsg[p].t > 1 then lastMsg[p] = { t = now, n = 0 } end
	lastMsg[p].n += 1
	if lastMsg[p].n > 30 then return end
	data[p] = data[p] or {}
	if data[p][key] == value then return end
	data[p][key] = value
	publish(p)
	if not dirty[p] then
		dirty[p] = true
		task.delay(8, function() if p.Parent then save(p) end end)
	end
end)

Players.PlayerRemoving:Connect(function(p)
	save(p)
	data[p] = nil dirty[p] = nil lastMsg[p] = nil
end)
game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do save(p) end
end)
