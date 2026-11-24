-- SprintServer: the 🏃 Run button / Shift key (SprintClient) asks to sprint on or off.
-- The server only sets player attribute "Sprinting"; ShopServer adds the sprint speed to the
-- normal walk speed (so shoes, Speed Coil and drinks still stack) and never overrides an event
-- that is controlling the player's speed.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local remote = RS:FindFirstChild("SprintRemote") or Instance.new("RemoteEvent")
remote.Name = "SprintRemote"
remote.Parent = RS

local last = {}
remote.OnServerEvent:Connect(function(player, on)
	if type(on) ~= "boolean" then return end
	local now = os.clock()
	if last[player] and now - last[player] < 0.1 then return end -- light spam guard
	last[player] = now
	player:SetAttribute("Sprinting", on)
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function() player:SetAttribute("Sprinting", false) end)
end)
for _, p in ipairs(Players:GetPlayers()) do
	p.CharacterAdded:Connect(function() p:SetAttribute("Sprinting", false) end)
end
Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
