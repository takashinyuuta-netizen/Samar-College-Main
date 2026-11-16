-- Outside the ROTC office: Q / tap "Request permission" -> the cadet's line shows at the door,
-- and everyone inside the office gets a notice.
local Players = game:GetService("Players")
local camp = workspace:WaitForChild("SamarCollege_Campus")
local out = camp:WaitForChild("1F_Ground"):WaitForChild("07_Common_Areas"):WaitForChild("Offices_Outside_StageSide_West")
local rp = out:WaitForChild("PermissionPrompt")
local prompt = rp:WaitForChild("PermissionPrompt")
local bubble = rp:WaitForChild("Bubble")
local RS = game:GetService("ReplicatedStorage")
local notice = RS:FindFirstChild("FacultyKnockNotice") or Instance.new("RemoteEvent")
notice.Name = "FacultyKnockNotice" notice.Parent = RS
local AREA = {x1 = 273.2, x2 = 294.2, z1 = 24.7, z2 = 39.2, y1 = 0, y2 = 15}
local busy = false
prompt.Triggered:Connect(function(pl)
	if busy then return end
	busy = true
	local name = pl.DisplayName
	bubble.Text.Text = "Ma'am/Sir! Cadet " .. name .. " requests permission to enter the office, Ma'am/Sir!"
	bubble.Enabled = true
	for _, other in ipairs(Players:GetPlayers()) do
		local r = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if r and other ~= pl then
			local p = r.Position
			if p.X > AREA.x1 and p.X < AREA.x2 and p.Z > AREA.z1 and p.Z < AREA.z2 and p.Y > AREA.y1 and p.Y < AREA.y2 then
				notice:FireClient(other, "Cadet " .. name .. " (requesting permission)")
			end
		end
	end
	task.wait(4)
	bubble.Enabled = false
	busy = false
end)
