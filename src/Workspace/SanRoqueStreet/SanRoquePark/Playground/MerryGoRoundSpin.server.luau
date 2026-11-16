local RunService = game:GetService("RunService")
local pg = script.Parent
local parts = {}
for _, p in ipairs(pg:GetChildren()) do
	if p:IsA("BasePart") and (p.Name == "MerryBase" or p.Name == "MerryHub" or p.Name == "MerryBar") then table.insert(parts, p) end
end
if #parts == 0 then return end
local centre = pg.MerryHub.Position
local base = {}
for _, p in ipairs(parts) do base[p] = CFrame.new(centre):ToObjectSpace(p.CFrame) end
local angle = 0
RunService.Heartbeat:Connect(function(dt)
	angle += dt * 0.6
	local rot = CFrame.new(centre) * CFrame.Angles(0, angle, 0)
	for p, rel in pairs(base) do p.CFrame = rot * rel end
end)
