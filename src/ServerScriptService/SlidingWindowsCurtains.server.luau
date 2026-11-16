-- SlidingWindowsCurtains: E to open / close sliding windows and curtains.
--   Models tagged "SlidingWindow": child model "SlidingSash" slides by the unit's SlideX attribute (studs on X)
--     or SlideZ (studs on Z, e.g. drawers in a counter that runs along X).
--     Optional attribute Label (default "window") names it in the prompt, e.g. "drawer".
--   Models tagged "SlidingCurtain": every "Fold" part moves between its ClosedX and OpenX attributes
--     (or ClosedZ / OpenZ for curtains on a wall that runs along Z).
--   Models tagged "AwningWindow": every child model "Sash_n" swings open around its part "Hinge"
--     (the hinge's X axis is the hinge line) by the unit's OpenAngle attribute (degrees, default -35).
--     Optional attribute Label (default "window"), e.g. "locker" for a locker door on a vertical hinge.
-- Open/closed state is stored in the "Open" attribute (also set "RequestOpen" from other scripts).
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local function partsOf(model)
	local t = {}
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then t[p] = p.CFrame end end
	return t
end

local function setupWindow(unit)
	local sash = unit:WaitForChild("SlidingSash", 5)
	local prompt = unit:FindFirstChild("WindowPrompt", true)
	if not sash or not prompt then return end
	local base = partsOf(sash)
	local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local busy = false
	local function set(open)
		if busy then return end busy = true
		local sz = unit:GetAttribute("SlideZ")
		local dx = open and (unit:GetAttribute("SlideX") or (sz and 0 or -4)) or 0
		local dz = open and (sz or 0) or 0
		local last
		for p, cf in pairs(base) do last = TweenService:Create(p, info, { CFrame = cf + Vector3.new(dx, 0, dz) }) last:Play() end
		if last then last.Completed:Wait() end
		unit:SetAttribute("Open", open)
		local label = unit:GetAttribute("Label") or "window"
		prompt.ActionText = (open and "Close " or "Open ") .. label
		busy = false
	end
	prompt.Triggered:Connect(function() set(not unit:GetAttribute("Open")) end)
	unit:GetAttributeChangedSignal("RequestOpen"):Connect(function()
		local w = unit:GetAttribute("RequestOpen")
		if w ~= nil and w ~= unit:GetAttribute("Open") then set(w) end
	end)
	unit:SetAttribute("Open", false)
	prompt.ActionText = "Open " .. (unit:GetAttribute("Label") or "window")
end

local function setupCurtain(model)
	local prompt = model:FindFirstChild("CurtainPrompt", true)
	if prompt and prompt:IsA("BasePart") then prompt = prompt:FindFirstChildOfClass("ProximityPrompt") end
	if not prompt then return end
	local folds = {}
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and (p:GetAttribute("ClosedX") or p:GetAttribute("ClosedZ")) then table.insert(folds, p) end
	end
	local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local busy = false
	local function set(open)
		if busy then return end busy = true
		local last
		for _, f in ipairs(folds) do
			local cf = f.CFrame
			local goal
			if f:GetAttribute("ClosedZ") then
				local z = open and f:GetAttribute("OpenZ") or f:GetAttribute("ClosedZ")
				goal = cf + Vector3.new(0, 0, z - cf.Position.Z)
			else
				local x = open and f:GetAttribute("OpenX") or f:GetAttribute("ClosedX")
				goal = cf + Vector3.new(x - cf.Position.X, 0, 0)
			end
			last = TweenService:Create(f, info, { CFrame = goal })
			last:Play()
		end
		if last then last.Completed:Wait() end
		model:SetAttribute("Open", open)
		prompt.ActionText = open and "Close curtains" or "Open curtains"
		busy = false
	end
	prompt.Triggered:Connect(function() set(not model:GetAttribute("Open")) end)
	model:GetAttributeChangedSignal("RequestOpen"):Connect(function()
		local w = model:GetAttribute("RequestOpen")
		if w ~= nil and w ~= model:GetAttribute("Open") then set(w) end
	end)
	model:SetAttribute("Open", false)
end

local function setupAwning(unit)
	local prompt = unit:FindFirstChild("WindowPrompt", true)
	if not prompt then return end
	local sashes = {}
	for _, s in ipairs(unit:GetChildren()) do
		local hinge = s:IsA("Model") and s.Name:match("^Sash") and s:FindFirstChild("Hinge")
		if hinge then
			local parts = {}
			for _, p in ipairs(s:GetDescendants()) do
				if p:IsA("BasePart") then parts[p] = hinge.CFrame:ToObjectSpace(p.CFrame) end
			end
			table.insert(sashes, { hinge = hinge.CFrame, parts = parts })
		end
	end
	if #sashes == 0 then return end
	local angle = Instance.new("NumberValue")
	angle.Name = "AwningAngle"
	angle.Parent = unit
	angle.Changed:Connect(function(a)
		local r = CFrame.Angles(math.rad(a), 0, 0)
		for _, s in ipairs(sashes) do
			for p, rel in pairs(s.parts) do p.CFrame = s.hinge * r * rel end
		end
	end)
	local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local busy = false
	local function set(open)
		if busy then return end busy = true
		local t = TweenService:Create(angle, info, { Value = open and (unit:GetAttribute("OpenAngle") or -35) or 0 })
		t:Play()
		t.Completed:Wait()
		unit:SetAttribute("Open", open)
		prompt.ActionText = (open and "Close " or "Open ") .. (unit:GetAttribute("Label") or "window")
		busy = false
	end
	prompt.Triggered:Connect(function() set(not unit:GetAttribute("Open")) end)
	unit:GetAttributeChangedSignal("RequestOpen"):Connect(function()
		local w = unit:GetAttribute("RequestOpen")
		if w ~= nil and w ~= unit:GetAttribute("Open") then set(w) end
	end)
	unit:SetAttribute("Open", false)
	prompt.ActionText = "Open " .. (unit:GetAttribute("Label") or "window")
end

for _, m in ipairs(CS:GetTagged("SlidingWindow")) do task.spawn(setupWindow, m) end
CS:GetInstanceAddedSignal("SlidingWindow"):Connect(setupWindow)
for _, m in ipairs(CS:GetTagged("SlidingCurtain")) do task.spawn(setupCurtain, m) end
CS:GetInstanceAddedSignal("SlidingCurtain"):Connect(setupCurtain)
for _, m in ipairs(CS:GetTagged("AwningWindow")) do task.spawn(setupAwning, m) end
CS:GetInstanceAddedSignal("AwningWindow"):Connect(setupAwning)
