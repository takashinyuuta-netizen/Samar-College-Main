-- TapCurtains: tap a curtain to open / close it. The folds bunch to the sides like real curtains.
-- A curtain is a Model tagged "TapCurtain". Each fold part inside it has:
--   attribute OpenCF   (CFrame)  -> where that fold sits when the curtain is open
--   attribute OpenSize (Vector3) -> its size when open (narrower = bunched up)
-- Optional model attribute StartOpen = true opens it when the server starts.
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local INFO = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local RANGE = 14

local function setup(m)
	if not m:IsA("Model") or m:FindFirstChild("TapDetector") then return end
	local folds = {}
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") and typeof(p:GetAttribute("OpenCF")) == "CFrame" then
			table.insert(folds, { p = p, closedCF = p.CFrame, closedSize = p.Size,
				openCF = p:GetAttribute("OpenCF"), openSize = p:GetAttribute("OpenSize") or p.Size })
		end
	end
	if #folds == 0 then return end
	local cd = Instance.new("ClickDetector")
	cd.Name = "TapDetector"
	cd.MaxActivationDistance = RANGE
	cd.Parent = m
	local busy = false
	local function apply(open, instant)
		for _, f in ipairs(folds) do
			local goal = { CFrame = open and f.openCF or f.closedCF, Size = open and f.openSize or f.closedSize }
			if instant then f.p.CFrame = goal.CFrame f.p.Size = goal.Size
			else TweenService:Create(f.p, INFO, goal):Play() end
		end
	end
	cd.MouseClick:Connect(function(player)
		if busy then return end
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp or (hrp.Position - m:GetPivot().Position).Magnitude > RANGE + 8 then return end
		busy = true
		local open = not m:GetAttribute("Open")
		m:SetAttribute("Open", open)
		apply(open)
		task.wait(INFO.Time)
		busy = false
	end)
	m:GetAttributeChangedSignal("Open"):Connect(function() if not busy then apply(m:GetAttribute("Open") == true) end end)
	if m:GetAttribute("StartOpen") then m:SetAttribute("Open", true) apply(true, true) end
end

for _, m in ipairs(CS:GetTagged("TapCurtain")) do task.spawn(setup, m) end
CS:GetInstanceAddedSignal("TapCurtain"):Connect(setup)
