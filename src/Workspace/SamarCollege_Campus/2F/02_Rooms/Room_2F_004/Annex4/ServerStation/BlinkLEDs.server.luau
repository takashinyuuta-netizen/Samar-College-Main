-- Blinks every part in this station that has the attribute Blink = true (network + drive activity lights).
local leds = {}
for _, d in ipairs(script.Parent:GetDescendants()) do
	if d:IsA("BasePart") and d:GetAttribute("Blink") then table.insert(leds, d) end
end
while true do
	for _, l in ipairs(leds) do
		l.Transparency = (math.random() < 0.35) and 0.85 or 0
	end
	task.wait(0.18)
end
