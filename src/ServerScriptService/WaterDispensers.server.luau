-- WaterDispensers: E at a water dispenser to fill a paper cup.
-- A dispenser is a Model tagged "WaterDispenser" with:
--   ProximityPrompt "WaterPrompt"
--   part "CupSpot"   -> invisible; the cup stands on its centre (bottom of the cup)
--   optional part "TapLight" -> lights up while water is running
-- The cup fills, stays for a few seconds and then disappears. One cup at a time per dispenser.
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local CUP_H, CUP_D = 0.45, 0.32

local function setup(m)
	if not m:IsA("Model") then return end
	local prompt = m:FindFirstChild("WaterPrompt", true)
	local spot = m:FindFirstChild("CupSpot", true)
	if not prompt or not spot then return end
	local light = m:FindFirstChild("TapLight", true)
	prompt.ActionText = "Get a cup of water"
	prompt.ObjectText = m:GetAttribute("ObjectText") or "Water dispenser"
	prompt.HoldDuration = 0.3
	prompt.RequiresLineOfSight = false
	local busy = false
	prompt.Triggered:Connect(function()
		if busy then return end
		busy = true
		prompt.Enabled = false
		local base = spot.CFrame * CFrame.Angles(0, 0, math.rad(90)) -- cylinder axis = up
		local cup = Instance.new("Part")
		cup.Name = "PaperCup"
		cup.Shape = Enum.PartType.Cylinder
		cup.Size = Vector3.new(CUP_H, CUP_D, CUP_D)
		cup.CFrame = base + Vector3.new(0, CUP_H / 2, 0)
		cup.Color = Color3.fromRGB(245, 245, 245)
		cup.Material = Enum.Material.SmoothPlastic
		cup.Transparency = 0.35
		cup.Anchored = true
		cup.CanCollide = false
		cup.Parent = m
		local water = Instance.new("Part")
		water.Name = "Water"
		water.Shape = Enum.PartType.Cylinder
		water.Size = Vector3.new(0.02, CUP_D - 0.04, CUP_D - 0.04)
		water.CFrame = base + Vector3.new(0, 0.02, 0)
		water.Color = Color3.fromRGB(150, 200, 235)
		water.Material = Enum.Material.Glass
		water.Transparency = 0.3
		water.Anchored = true
		water.CanCollide = false
		water.Parent = m
		if light then light.Material = Enum.Material.Neon end
		local h = CUP_H - 0.08
		local t = TweenService:Create(water, TweenInfo.new(1.6, Enum.EasingStyle.Linear), {
			Size = Vector3.new(h, CUP_D - 0.04, CUP_D - 0.04),
			CFrame = base + Vector3.new(0, h / 2 + 0.02, 0),
		})
		t:Play()
		t.Completed:Wait()
		if light then light.Material = Enum.Material.SmoothPlastic end
		task.wait(4)
		local fade = TweenInfo.new(0.5)
		TweenService:Create(cup, fade, { Transparency = 1 }):Play()
		TweenService:Create(water, fade, { Transparency = 1 }):Play()
		task.wait(0.6)
		cup:Destroy()
		water:Destroy()
		prompt.Enabled = true
		busy = false
	end)
end

for _, m in ipairs(CS:GetTagged("WaterDispenser")) do task.spawn(setup, m) end
CS:GetInstanceAddedSignal("WaterDispenser"):Connect(setup)
