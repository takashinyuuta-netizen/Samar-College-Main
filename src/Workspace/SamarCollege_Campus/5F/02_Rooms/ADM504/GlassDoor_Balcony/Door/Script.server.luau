local TweenService = game:GetService("TweenService")
local hinge = script.Parent.Doorframe.Hinge
local prompt = script.Parent.Base.ProximityPrompt
local closed = hinge.CFrame
local open = hinge.CFrame * CFrame.Angles(0, math.rad(-95), 0)
local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
prompt.Triggered:Connect(function()
	if prompt.ActionText == "Close" then
		TweenService:Create(hinge, info, {CFrame = closed}):Play()
		prompt.ActionText = "Open"
	else
		TweenService:Create(hinge, info, {CFrame = open}):Play()
		prompt.ActionText = "Close"
	end
end)
