-- TapInteract: tap / click things instead of pressing E.
--   Tag a PowerToggle or LightSwitch MODEL with "TapToUse": tapping anywhere on it toggles it on/off.
--   Tag a SEAT with "TapToUse": tapping its chair seats the player.
-- The E prompts on tagged things are hidden (range 0); PowerToggles / LightSwitches / PromptSeats
-- still do the actual work (they react to the "On" attribute / seat occupant).
local CS = game:GetService("CollectionService")
local RANGE = 14

local function hidePrompt(p)
	if p:IsA("ProximityPrompt") then
		p.MaxActivationDistance = 0
		p:GetPropertyChangedSignal("MaxActivationDistance"):Connect(function()
			if p.MaxActivationDistance ~= 0 then p.MaxActivationDistance = 0 end
		end)
	end
end
local function hideAll(root)
	for _, d in ipairs(root:GetDescendants()) do hidePrompt(d) end
	root.DescendantAdded:Connect(function(d) task.defer(hidePrompt, d) end)
end
local function closeEnough(player, root)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local pos = root:IsA("Model") and root:GetPivot().Position or root.Position
	return (hrp.Position - pos).Magnitude <= RANGE + 6
end

local function isOpener(m)
	return CS:HasTag(m, "SlidingCurtain") or CS:HasTag(m, "SlidingWindow") or CS:HasTag(m, "AwningWindow")
end

local function setupDevice(m)
	if m:FindFirstChild("TapDetector") then return end
	local cd = Instance.new("ClickDetector")
	cd.Name = "TapDetector"
	cd.MaxActivationDistance = RANGE
	cd.Parent = m
	hideAll(m)
	local busy = false
	cd.MouseClick:Connect(function(player)
		if busy or not closeEnough(player, m) then return end
		busy = true
		if isOpener(m) then
			m:SetAttribute("RequestOpen", not m:GetAttribute("Open"))
		else
			local cur = m:GetAttribute("On")
			if cur == nil then cur = CS:HasTag(m, "LightSwitch") end -- switches start on
			m:SetAttribute("On", not cur)
		end
		task.delay(0.25, function() busy = false end)
	end)
end

local function setupSeat(seat)
	local holder = seat.Parent
	if not holder or holder:FindFirstChild("TapDetector") then return end
	local cd = Instance.new("ClickDetector")
	cd.Name = "TapDetector"
	cd.MaxActivationDistance = RANGE
	cd.Parent = holder
	hideAll(seat)
	cd.MouseClick:Connect(function(player)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 or hum.Sit or seat.Occupant then return end
		if not closeEnough(player, seat) then return end
		seat.Disabled = false
		seat:Sit(hum)
	end)
end

local function setup(inst)
	if inst:IsA("Seat") then setupSeat(inst)
	elseif inst:IsA("Model") then setupDevice(inst) end
end
for _, inst in ipairs(CS:GetTagged("TapToUse")) do task.spawn(setup, inst) end
CS:GetInstanceAddedSignal("TapToUse"):Connect(setup)
