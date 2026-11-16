-- CampusMusic: calm school background music while you are just hanging out.
-- It fades away while you take part in an event or another soundtrack (Escape / Tower) plays,
-- and follows Settings → Music volume (player attribute "Setting_MusicVolume").
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local C = require(RS:WaitForChild("CampusLife"):WaitForChild("CampusLifeConfig"))
local player = Players.LocalPlayer

local music = Instance.new("Sound") music.Name = "Campus_Hangout" music.SoundId = C.Music.Hangout music.Looped = true music.Volume = 0 music.Parent = SoundService
local inEvent = false
local ok, Remotes = pcall(function() return RS:WaitForChild("Events", 10):WaitForChild("EventRemotes", 10) end)
if ok and Remotes then
	Remotes.EventState.OnClientEvent:Connect(function(s) inEvent = s.active and s.joined and s.phase ~= "Results" end)
end
local OTHER = { "Escape_BG", "Escape_Chase", "Tower_Music", "Intramurals_Music", "Foundation_Music" }
local function otherMusic()
	for _, n in ipairs(OTHER) do local s = SoundService:FindFirstChild(n) if s and s.IsPlaying and s.Volume > 0.02 then return true end end
	return false
end
local function settingVolume()
	local v = player:GetAttribute("Setting_MusicVolume")
	if type(v) ~= "number" then return 1 end
	if v > 1 then v = v / 100 end
	return math.clamp(v, 0, 1)
end
local target = -1
while true do
	local want = (inEvent or otherMusic()) and 0 or C.Music.Volume * settingVolume()
	if math.abs(want - target) > 0.005 then
		target = want
		if want > 0 and not music.IsPlaying then music:Play() end
		TweenService:Create(music, TweenInfo.new(1.5), { Volume = want }):Play()
	end
	task.wait(0.5)
end
