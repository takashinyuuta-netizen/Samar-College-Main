-- Knock at the Principal's Office (Elementary): bubble at the door + notice to anyone inside.
local Players = game:GetService("Players")
local room = workspace:WaitForChild("SamarCollege_Campus"):WaitForChild("1F_Ground"):WaitForChild("02_Rooms"):WaitForChild("PrincipalOffice_Elementary")
local kp = room:WaitForChild("Outside"):WaitForChild("KnockPrompt")
local prompt = kp:WaitForChild("KnockPrompt")
local bubble = kp:WaitForChild("KnockBubble")
local RS = game:GetService("ReplicatedStorage")
local notice = RS:FindFirstChild("FacultyKnockNotice") or Instance.new("RemoteEvent")
notice.Name = "FacultyKnockNotice" notice.Parent = RS
local AREA = {x1 = 271.6, x2 = 294.2, z1 = 76.3, z2 = 93.9, y1 = 0, y2 = 14}
local busy = false
prompt.Triggered:Connect(function(knocker)
	if busy then return end
	busy = true
	bubble.Enabled = true
	for _, pl in ipairs(Players:GetPlayers()) do
		local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
		if r and pl ~= knocker then
			local p = r.Position
			if p.X > AREA.x1 and p.X < AREA.x2 and p.Z > AREA.z1 and p.Z < AREA.z2 and p.Y > AREA.y1 and p.Y < AREA.y2 then
				notice:FireClient(pl, knocker.DisplayName)
			end
		end
	end
	task.wait(2.5)
	bubble.Enabled = false
	busy = false
end)
