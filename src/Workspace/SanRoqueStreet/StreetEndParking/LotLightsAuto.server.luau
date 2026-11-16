-- Park lamps turn on automatically in the evening (6 PM - 6 AM) and off during the day.
local Lighting = game:GetService("Lighting")
local park = script.Parent
local function lights()
	local list = {}
	for _, d in ipairs(park:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Bulb" then table.insert(list, d) end
	end
	return list
end
local bulbs = lights()
local last = nil
local function update()
	local t = Lighting.ClockTime
	local on = (t >= 18 or t < 6)
	if on == last then return end
	last = on
	for _, b in ipairs(bulbs) do
		b.Material = on and Enum.Material.Neon or Enum.Material.Glass
		b.Color = on and Color3.fromRGB(255, 240, 200) or Color3.fromRGB(225, 220, 205)
		local l = b:FindFirstChildWhichIsA("Light")
		if l then l.Enabled = on end
	end
end
update()
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(update)
