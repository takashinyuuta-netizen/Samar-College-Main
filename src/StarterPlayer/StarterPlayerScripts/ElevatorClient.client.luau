-- Elevator ride screen: a short fade with the destination floor.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("ElevatorRide")
local player = Players.LocalPlayer
remote.OnClientEvent:Connect(function(action, target, arrow)
	if action ~= "ride" then return end
	local gui = Instance.new("ScreenGui") gui.Name = "ElevatorRide" gui.IgnoreGuiInset = true gui.ResetOnSpawn = false gui.DisplayOrder = 50
	local f = Instance.new("Frame") f.Size = UDim2.fromScale(1, 1) f.BackgroundColor3 = Color3.fromRGB(12, 14, 16) f.BackgroundTransparency = 1 f.Parent = gui
	local t = Instance.new("TextLabel") t.BackgroundTransparency = 1 t.AnchorPoint = Vector2.new(0.5, 0.5) t.Position = UDim2.fromScale(0.5, 0.5)
	t.Size = UDim2.fromScale(0.8, 0.14) t.TextScaled = true t.Font = Enum.Font.GothamBlack t.TextColor3 = Color3.fromRGB(255, 120, 90) t.TextTransparency = 1
	t.Text = arrow .. "  Going to " .. tostring(target) .. "F…" t.Parent = f
	gui.Parent = player:WaitForChild("PlayerGui")
	TweenService:Create(f, TweenInfo.new(0.4), {BackgroundTransparency = 0.05}):Play()
	TweenService:Create(t, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
	task.wait(2.2)
	t.Text = "Now at " .. tostring(target) .. "F"
	task.wait(0.5)
	TweenService:Create(f, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	TweenService:Create(t, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	task.wait(0.6)
	gui:Destroy()
end)
