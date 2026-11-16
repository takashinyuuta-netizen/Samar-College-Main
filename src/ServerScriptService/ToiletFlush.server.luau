-- ToiletFlush: E at a toilet to flush it.
-- A toilet is a Model tagged "Toilet" with:
--   ProximityPrompt "FlushPrompt"
--   part "FlushLever" (dips while flushing)
--   part "Water" with a ParticleEmitter "Swirl" (swirls while flushing)
-- The water level drops and refills; the prompt is disabled until the tank refills.
-- Optional attribute TapFlush = true on the toilet Model: tap / click the toilet to flush instead of E
-- (the E prompt is hidden).
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local FLUSH_TIME = 1.6
local REFILL_TIME = 2.0

local function setup(m)
	if not m:IsA("Model") then return end
	local prompt = m:FindFirstChild("FlushPrompt", true)
	local water = m:FindFirstChild("Water", true)
	local lever = m:FindFirstChild("FlushLever", true)
	if not prompt or not water then return end
	prompt.ActionText = "Flush"
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton

	local swirl = water:FindFirstChildOfClass("ParticleEmitter")
	local waterHome = water.CFrame
	local waterSize = water.Size
	local leverHome = lever and lever.CFrame
	local busy = false

	local tap = m:GetAttribute("TapFlush") == true
	if tap then prompt.MaxActivationDistance = 0 end

	local function flush()
		if busy then return end
		busy = true
		prompt.Enabled = false
		if lever then
			TweenService:Create(lever, TweenInfo.new(0.15), { CFrame = leverHome * CFrame.Angles(0, 0, math.rad(-25)) }):Play()
		end
		if swirl then swirl.Enabled = true end
		-- water spins and drains
		TweenService:Create(water, TweenInfo.new(FLUSH_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			CFrame = waterHome * CFrame.new(-0.25, 0, 0) * CFrame.Angles(math.rad(720), 0, 0),
			Size = waterSize * Vector3.new(1, 0.6, 0.6),
		}):Play()
		task.wait(0.3)
		if lever then TweenService:Create(lever, TweenInfo.new(0.2), { CFrame = leverHome }):Play() end
		task.wait(FLUSH_TIME - 0.3)
		if swirl then swirl.Enabled = false end
		-- refill
		TweenService:Create(water, TweenInfo.new(REFILL_TIME), { CFrame = waterHome, Size = waterSize }):Play()
		task.wait(REFILL_TIME)
		water.CFrame = waterHome
		water.Size = waterSize
		prompt.Enabled = true
		busy = false
	end

	prompt.Triggered:Connect(flush)
	if tap and not m:FindFirstChild("FlushTap") then
		local cd = Instance.new("ClickDetector")
		cd.Name = "FlushTap"
		cd.MaxActivationDistance = 10
		cd.Parent = m
		cd.MouseClick:Connect(function(player)
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - m:GetPivot().Position).Magnitude <= 14 then flush() end
		end)
	end
end

for _, m in ipairs(CS:GetTagged("Toilet")) do task.spawn(setup, m) end
CS:GetInstanceAddedSignal("Toilet"):Connect(setup)
