local led = script.Parent:WaitForChild("LED")
while true do
	led.Material = Enum.Material.Neon; led.Color = Color3.fromRGB(255, 30, 30)
	task.wait(0.8)
	led.Material = Enum.Material.SmoothPlastic; led.Color = Color3.fromRGB(70, 0, 0)
	task.wait(0.8)
end
