local Lighting = game:GetService("Lighting")
local model = script.Parent
local bulbs = {}
for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") and d.Name == "Bulb" then table.insert(bulbs, d) end end
local last
local function update()
	local t = Lighting.ClockTime
	local on = (t >= 18 or t < 6)
	if on == last then return end
	last = on
	for _, b in ipairs(bulbs) do
		b.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
		for _, l in ipairs(b:GetChildren()) do if l:IsA("Light") then l.Enabled = on end end
	end
end
update()
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(update)
