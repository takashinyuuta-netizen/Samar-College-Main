-- FallRescue: the campus is a floating island now. Anyone who falls off the edge is brought back
-- (players → the spawn, campus NPCs → the main gate) instead of falling forever.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RESCUE_BELOW = -70 -- studs (the island's grass is at y = 0)

local function spawnPoint()
	local sp = workspace:FindFirstChildOfClass("SpawnLocation") or workspace:FindFirstChild("SpawnLocation", true)
	return sp and (sp.Position + Vector3.new(0, 4, 0)) or Vector3.new(0, 6, 0)
end
local function gatePoint()
	local gate = workspace:FindFirstChild("SamarCollege_Campus") and workspace.SamarCollege_Campus:FindFirstChild("MainGate")
	local a = gate and gate:FindFirstChild("PromptAnchor_Inside")
	return a and (a.Position + Vector3.new(10, 1, 0)) or spawnPoint()
end
local toast
task.spawn(function()
	local ev = RS:WaitForChild("Events", 30)
	local rem = ev and ev:WaitForChild("EventRemotes", 30)
	toast = rem and rem:FindFirstChild("EventToast")
end)

while true do
	task.wait(0.5)
	for _, p in ipairs(Players:GetPlayers()) do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < RESCUE_BELOW and not p:GetAttribute("InSkyClimb") then
			root.AssemblyLinearVelocity = Vector3.zero
			p.Character:PivotTo(CFrame.new(spawnPoint()))
			if toast then toast:FireClient(p, "☁️ Whoa! You fell off the floating island — welcome back!") end
		end
	end
	local npcs = workspace:FindFirstChild("SamarCollege_Campus") and workspace.SamarCollege_Campus:FindFirstChild("CampusNPCs")
	if npcs then
		for _, d in ipairs(npcs:GetDescendants()) do
			if d:IsA("Humanoid") then
				local r = d.Parent:FindFirstChild("HumanoidRootPart")
				if r and r.Position.Y < RESCUE_BELOW then d.Parent:PivotTo(CFrame.new(gatePoint())) end
			end
		end
	end
end
