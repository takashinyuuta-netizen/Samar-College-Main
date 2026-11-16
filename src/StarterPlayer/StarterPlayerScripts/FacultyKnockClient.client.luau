local Players = game:GetService("Players")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("FacultyKnockNotice")
remote.OnClientEvent:Connect(function(who)
	local g = Instance.new("ScreenGui") g.Name = "KnockNotice" g.ResetOnSpawn = false
	local f = Instance.new("TextLabel") f.AnchorPoint = Vector2.new(0.5, 0) f.Position = UDim2.new(0.5, 0, 0, 70) f.Size = UDim2.fromOffset(340, 44)
	f.BackgroundColor3 = Color3.fromRGB(40, 120, 70) f.TextColor3 = Color3.new(1, 1, 1) f.Font = Enum.Font.GothamBold f.TextScaled = true
	f.Text = "✊ " .. tostring(who) .. " is knocking at the door" f.Parent = g
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
	g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	task.delay(3.5, function() g:Destroy() end)
end)
