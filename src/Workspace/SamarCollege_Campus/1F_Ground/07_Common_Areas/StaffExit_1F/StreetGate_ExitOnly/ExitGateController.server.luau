-- ExitGateController: the street gate at the end of the staff exit passage is EXIT ONLY.
-- Holding E on it takes the player out of the campus to the front of the school
-- (near the spawn). Nobody can come in this way: the gate itself never opens.
local gate = script.Parent
local prompt = gate:WaitForChild("ExitPromptPart"):WaitForChild("ExitPrompt")

-- where people end up: just outside the main entrance, facing the campus
local OUTSIDE = CFrame.lookAt(Vector3.new(-18, 3.5, 16.3), Vector3.new(0, 3.5, 16.3))
local COOLDOWN = 2
local last = {}

prompt.Triggered:Connect(function(player)
	local now = os.clock()
	if last[player] and now - last[player] < COOLDOWN then return end
	last[player] = now
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	-- spread players out a little so they don't stack
	local offset = Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
	char:PivotTo(OUTSIDE + offset)
end)

game:GetService("Players").PlayerRemoving:Connect(function(p) last[p] = nil end)
