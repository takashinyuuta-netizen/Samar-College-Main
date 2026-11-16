-- simple 2-phase traffic light cycle for the island's modern road junctions
local folder = script.Parent
local function set(group, state)
	for _, m in ipairs(folder:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("Group") == group then
			for _, n in ipairs({"Red", "Amber", "Green"}) do
				local p = m:FindFirstChild(n)
				if p then
					local on = (n == state)
					local c = p:GetAttribute("OnColor")
					p.Color = on and c or c:Lerp(Color3.new(0, 0, 0), 0.7)
					p.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
				end
			end
		end
	end
end
while true do
	set("A", "Green") set("B", "Red") task.wait(14)
	set("A", "Amber") task.wait(3)
	set("A", "Red") task.wait(1) set("B", "Green") task.wait(10)
	set("B", "Amber") task.wait(3)
	set("B", "Red") task.wait(1)
end
