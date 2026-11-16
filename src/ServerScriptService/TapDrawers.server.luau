-- TapDrawers: tap / click a drawer to slide it open, tap again to close it.
-- A drawer is a Model tagged "TapDrawer" with:
--   attribute PullDir  (Vector3) -> direction it slides out
--   attribute PullDist (number)  -> how far it slides (studs)
-- All parts stay anchored; the whole model is moved with PivotTo.
-- Optional attribute UseEPrompt = true (for doors): use an E ProximityPrompt instead of tap/click.
--   ObjectText attribute sets the prompt's label.
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local RANGE = 12
local INFO = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function closeEnough(player, m)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	return hrp and (hrp.Position - m:GetPivot().Position).Magnitude <= RANGE + 4
end

local function setup(m)
	if not m:IsA("Model") or m:FindFirstChild("TapDetector") then return end
	local dir = m:GetAttribute("PullDir")
	if typeof(dir) ~= "Vector3" then return end
	local dist = m:GetAttribute("PullDist") or 1
	local closed = m:GetPivot()
	local opened = closed + dir.Unit * dist

	local useE = m:GetAttribute("UseEPrompt") == true
	local cd, prompt
	if useE then
		if m:FindFirstChild("DoorPrompt", true) then return end
		local holder = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "DoorPrompt"
		prompt.ActionText = "Open"
		prompt.ObjectText = m:GetAttribute("ObjectText") or "Door"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 6
		prompt.RequiresLineOfSight = false
		prompt.Parent = holder
	else
		cd = Instance.new("ClickDetector")
		cd.Name = "TapDetector"
		cd.MaxActivationDistance = RANGE
		cd.Parent = m
	end

	local value = Instance.new("CFrameValue")
	value.Value = closed
	value.Changed:Connect(function(cf) m:PivotTo(cf) end)

	local busy = false
	local function toggle(player)
		if busy or not closeEnough(player, m) then return end
		busy = true
		local open = not m:GetAttribute("Open")
		m:SetAttribute("Open", open)
		if prompt then prompt.ActionText = open and "Close" or "Open" end
		local tw = TweenService:Create(value, INFO, { Value = open and opened or closed })
		tw:Play()
		tw.Completed:Wait()
		busy = false
	end
	if prompt then prompt.Triggered:Connect(toggle) else cd.MouseClick:Connect(toggle) end
end

for _, m in ipairs(CS:GetTagged("TapDrawer")) do task.spawn(setup, m) end
CS:GetInstanceAddedSignal("TapDrawer"):Connect(setup)
