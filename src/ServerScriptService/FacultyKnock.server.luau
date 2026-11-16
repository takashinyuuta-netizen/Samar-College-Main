-- Knock on the Faculty Room door: bubble at the door, visitor lamp flashes inside, notice to everyone inside.
local Players = game:GetService("Players")
local room = workspace:WaitForChild("SamarCollege_Campus"):WaitForChild("2F"):WaitForChild("02_Rooms"):WaitForChild("CollegeFacultyRoom")
local kp = room:WaitForChild("Outside"):WaitForChild("KnockPrompt")
local prompt = kp:WaitForChild("KnockPrompt")
local bubble = kp:WaitForChild("KnockBubble")
local lamp = room:WaitForChild("VisitorLamp")
local RS = game:GetService("ReplicatedStorage")
local notice = RS:FindFirstChild("FacultyKnockNotice") or Instance.new("RemoteEvent")
notice.Name = "FacultyKnockNotice" notice.Parent = RS
local AREA = {x1 = 192.3, x2 = 233.9, z1 = -142.3, z2 = -125.8, y1 = 14, y2 = 30}
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
	for i = 1, 6 do
		lamp.Color = (i % 2 == 1) and Color3.fromRGB(255, 70, 60) or Color3.fromRGB(120, 40, 40)
		lamp.Material = (i % 2 == 1) and Enum.Material.Neon or Enum.Material.SmoothPlastic
		task.wait(0.35)
	end
	bubble.Enabled = false
	busy = false
end)
