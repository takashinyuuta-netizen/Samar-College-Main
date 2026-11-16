local handle = script.Parent.Interactive
local doorOpen = false
local changingState = false
local sound = script.Parent.Interactive.DrawerSound

handle.ClickDetector.MouseClick:Connect(function(player, part)
	if doorOpen == true and changingState == false then
		changingState = true
		sound:Play()
		for i = 1, 28 do
			script.Parent:SetPrimaryPartCFrame(script.Parent.PrimaryPart.CFrame * CFrame.new(0, 0, 0.08))
			wait()
		end
		changingState = false
		doorOpen = false
	elseif changingState == false then
		changingState = true
		sound:Play()
		for i = 1, 28 do
			script.Parent:SetPrimaryPartCFrame(script.Parent.PrimaryPart.CFrame * CFrame.new(0, 0, -0.08))
			wait()
		end
		changingState = false
		doorOpen = true
	end
end)