-- HUDServer.lua
-- Handles Map teleports (only to places listed in HUDConfig) and the
-- Elementary / Junior High+ server switch from the Settings panel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local config = require(ReplicatedStorage:WaitForChild("HUDConfig"))
local remotes = ReplicatedStorage:WaitForChild("HUDRemotes")
local mapTeleport = remotes:WaitForChild("MapTeleport")

local placesById = {}
for _, place in ipairs(config.Places) do
	placesById[place.Id] = place
end

local lastTeleport = {}
local lastPreload = {}

-- stream the destination to this player's device BEFORE moving them (no "loading" freeze on arrival)
local function preload(player, pos, timeout)
	pcall(function() player:RequestStreamAroundAsync(pos, timeout or 4) end)
end

mapTeleport.OnServerEvent:Connect(function(player, placeId, mode)
	if typeof(placeId) ~= "string" then return end
	local place = placesById[placeId]
	if not place then return end
	if mode == "preload" then
		-- first tap on a map pin: load that place in the background while the player decides
		if lastPreload[player] and os.clock() - lastPreload[player] < 0.8 then return end
		lastPreload[player] = os.clock()
		if place.Position then task.spawn(preload, player, place.Position, 6) end
		return
	end
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
	local pos = place.Position + Vector3.new(0, 0.5, 0)
	preload(player, pos, 4) -- usually instant: the pin tap already loaded it
	if not character.Parent or humanoid.Health <= 0 then return end
	humanoid.Sit = false
	if place.LookAt then
		character:PivotTo(CFrame.lookAt(pos, Vector3.new(place.LookAt.X, pos.Y, place.LookAt.Z)))
	else
		character:PivotTo(CFrame.new(pos))
	end
	mapTeleport:FireClient(player, "Teleported to " .. place.Name)
end)


Players.PlayerRemoving:Connect(function(player)
	lastTeleport[player] = nil
	lastPreload[player] = nil
end)
