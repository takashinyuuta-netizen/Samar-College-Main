-- SwingDoors: simple hinged doors (screen doors, gates, cabinet doors) that swing on E.
-- A door is a Model tagged "SwingDoor" with:
--   a part named "HingePin" (the pivot line, vertical)
--   attribute OpenAngle (degrees, + or -)  default 95
--   attribute ObjectText (prompt label)
--   attribute StartOpen = true to begin open
-- All parts stay anchored; the whole model rotates around the pin.
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local INFO = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function setup(m)
	if not m:IsA("Model") or m:FindFirstChild("SwingPrompt", true) then return end
	local pin = m:FindFirstChild("HingePin", true)
	if not pin then return end
	local closedPivot = m:GetPivot()
	local pinCF = CFrame.new(pin.Position)
	local rel = pinCF:ToObjectSpace(closedPivot)
	local angle = math.rad(m:GetAttribute("OpenAngle") or 95)
	local value = Instance.new("NumberValue")
	value.Changed:Connect(function(a) m:PivotTo(pinCF * CFrame.Angles(0, a, 0) * rel) end)
	local holder = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SwingPrompt"
	prompt.ObjectText = m:GetAttribute("ObjectText") or "Door"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Parent = holder
	local function apply(open, instant)
		prompt.ActionText = open and "Close" or "Open"
		if instant then value.Value = open and angle or 0 return end
		TweenService:Create(value, INFO, { Value = open and angle or 0 }):Play()
	end
	local busy = false
	prompt.Triggered:Connect(function()
		if busy then return end
		busy = true
		local open = not m:GetAttribute("Open")
		m:SetAttribute("Open", open)
		apply(open)
		task.wait(INFO.Time)
		busy = false
	end)
	if m:GetAttribute("StartOpen") then m:SetAttribute("Open", true) apply(true, true) else apply(false, true) end
end

for _, m in ipairs(CS:GetTagged("SwingDoor")) do task.spawn(setup, m) end
CS:GetInstanceAddedSignal("SwingDoor"):Connect(setup)
