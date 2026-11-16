-- HUDServer.lua
-- Handles Map teleports (only to places listed in HUDConfig) and the
-- Elementary / Junior High+ server switch from the Settings panel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local config = require(ReplicatedStorage:WaitForChild("HUDConfig"))
local remotes = ReplicatedStorage:WaitForChild("HUDRemotes")
local mapTeleport = remotes:WaitForChild("MapTeleport")
local switchServer = remotes:WaitForChild("SwitchServer")

local placesById = {}
for _, place in ipairs(config.Places) do
	placesById[place.Id] = place
end

local lastTeleport = {}

mapTeleport.OnServerEvent:Connect(function(player, placeId)
	if typeof(placeId) ~= "string" then return end
	local place = placesById[placeId]
	if not place then return end
	if place.Intramurals and not workspace:GetAttribute("IntramuralsActive") then
		mapTeleport:FireClient(player, "🏆 That place only opens during the Intramurals event")
		return
	end

	local now = os.clock()
	if lastTeleport[player] and now - lastTeleport[player] < (config.TeleportCooldown or 3) then
		mapTeleport:FireClient(player, "Wait a moment before teleporting again")
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	lastTeleport[player] = now
	humanoid.Sit = false
	local pos = place.Position + Vector3.new(0, 0.5, 0)
	if place.LookAt then
		character:PivotTo(CFrame.lookAt(pos, Vector3.new(place.LookAt.X, pos.Y, place.LookAt.Z)))
	else
		character:PivotTo(CFrame.new(pos))
	end
	mapTeleport:FireClient(player, "Teleported to " .. place.Name)
end)

local Switch = require(script.Parent:WaitForChild("ServerSwitch"))
switchServer.OnServerEvent:Connect(function(player, target)
	-- "Elementary" = Kid server, anything else = Main server
	local want = (target == "Elementary" or target == "Kid") and "Kid" or "Main"
	local res = Switch.switch(player, want)
	if res.stay then switchServer:FireClient(player, "You're already on the " .. want .. " server")
	elseif res.teleporting then switchServer:FireClient(player, "Teleporting to the " .. want .. " server...")
	else switchServer:FireClient(player, res.msg or "Couldn't switch servers. Try again.") end
end)

Players.PlayerRemoving:Connect(function(player)
	lastTeleport[player] = nil
end)
