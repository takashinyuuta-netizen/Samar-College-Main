--[[ EquipLock — turns ALL Equipment (bike, spring boots, running shoes, flashlight, gravity/speed coil, magic carpet...)
  OFF while a player takes part in something, and gives it back when they're done.
  Reasons (player attributes set by the systems themselves):
    Lock_Event   — EventManager: joined an event (Tower, Escape, Quiz Bee, Booth games, Guess the Drawing, ...)
    Lock_Court   — SportsServer: in a sports game / chess (lobby or playing)
    SC_Performing— TalentShowServer: dancing / singing on the Talent Stage
  Result: player attribute EquipLocked = true (ShopServer removes the tools + boosts, BikeServer puts the bike away,
  the hotbar shows 🔒). Cosmetics and consumables are not affected. ]]
local Players = game:GetService("Players")

local REASONS = { "Lock_Event", "Lock_Court", "SC_Performing" }

local function update(player)
	local locked = false
	for _, r in ipairs(REASONS) do if player:GetAttribute(r) then locked = true break end end
	if (player:GetAttribute("EquipLocked") == true) ~= locked then
		player:SetAttribute("EquipLocked", locked or nil)
	end
end

local function hook(player)
	for _, r in ipairs(REASONS) do
		player:GetAttributeChangedSignal(r):Connect(function() update(player) end)
	end
	update(player)
end
Players.PlayerAdded:Connect(hook)
for _, p in ipairs(Players:GetPlayers()) do hook(p) end
