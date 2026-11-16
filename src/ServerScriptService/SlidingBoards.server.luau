-- SlidingBoards: sliding whiteboard panels that hide / show something behind them (e.g. a TV).
-- A set is a Model tagged "SlidingBoardSet". Each child Model with a Vector3 attribute "OpenOffset"
-- is a panel. Tap / click any panel and every panel in the set slides open (by its OpenOffset)
-- or back closed. The set's "Open" attribute holds the state, so other scripts can open it too.
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local INFO = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local RANGE = 14
local sets = {}

local function setup(set)
	if not set:IsA("Model") or sets[set] then return end
	local panels = {}
	for _, p in ipairs(set:GetChildren()) do
		local off = p:GetAttribute("OpenOffset")
		if p:IsA("Model") and typeof(off) == "Vector3" then
			local closed = p:GetPivot()
			local v = Instance.new("CFrameValue")
			v.Value = closed
			v.Changed:Connect(function(cf) p:PivotTo(cf) end)
			table.insert(panels, { m = p, closed = closed, open = closed + off, v = v })
		end
	end
	if #panels == 0 then return end
	sets[set] = true

	local busyUntil = 0
	local function apply()
		local open = set:GetAttribute("Open") == true
		busyUntil = os.clock() + INFO.Time
		for _, pn in ipairs(panels) do
			TweenService:Create(pn.v, INFO, { Value = open and pn.open or pn.closed }):Play()
		end
	end
	set:GetAttributeChangedSignal("Open"):Connect(apply)

	for _, pn in ipairs(panels) do
		local cd = Instance.new("ClickDetector")
		cd.Name = "TapDetector"
		cd.MaxActivationDistance = RANGE
		cd.Parent = pn.m
		cd.MouseClick:Connect(function(player)
			if os.clock() < busyUntil then return end
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not hrp or (hrp.Position - pn.m:GetPivot().Position).Magnitude > RANGE + 6 then return end
			set:SetAttribute("Open", not set:GetAttribute("Open"))
		end)
	end
	if set:GetAttribute("Open") then apply() end
end

for _, s in ipairs(CS:GetTagged("SlidingBoardSet")) do task.spawn(setup, s) end
CS:GetInstanceAddedSignal("SlidingBoardSet"):Connect(setup)
