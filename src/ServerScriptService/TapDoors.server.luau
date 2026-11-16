-- TapDoors: hinged doors you tap / click to open (no E prompt).
-- A door is a Model tagged "TapDoor" with:
--   a part named "HingePin" (vertical pivot line)
--   attribute OpenAngle (degrees, + or -) default 95
--   attribute AutoClose (seconds, 0 = stays open) default 7
--   optional Sound named "DoorSound" anywhere inside
-- Parts stay anchored; the whole model rotates around the pin.
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local INFO = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RANGE = 14

local function setup(m)
	if not m:IsA("Model") or m:FindFirstChild("TapDetector") then return end
	local pin = m:FindFirstChild("HingePin", true)
	if not pin then return end
	local closedPivot = m:GetPivot()
	local pinCF = CFrame.new(pin.Position)
	local rel = pinCF:ToObjectSpace(closedPivot)
	local angle = math.rad(m:GetAttribute("OpenAngle") or 95)
	local value = Instance.new("NumberValue")
	value.Changed:Connect(function(a) m:PivotTo(pinCF * CFrame.Angles(0, a, 0) * rel) end)
	local sound = m:FindFirstChild("DoorSound", true)
	-- anti-stuck: the leaf only blocks while it is fully closed, and never closes on a player
	local leafParts = {}
	local reach = 0
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			if p.CanCollide then table.insert(leafParts, p) end
			reach = math.max(reach, (p.Position - pin.Position).Magnitude + math.max(p.Size.X, p.Size.Y, p.Size.Z) / 2)
		end
	end
	reach = math.min(reach, 7)
	local function setSolid(on)
		for _, p in ipairs(leafParts) do p.CanCollide = on end
	end
	local function someoneInSwing()
		for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local d = hrp.Position - pin.Position
				if Vector3.new(d.X, 0, d.Z).Magnitude < reach + 1.2 and math.abs(d.Y) < 6 then return true end
			end
		end
		return false
	end

	local cd = Instance.new("ClickDetector")
	cd.Name = "TapDetector"
	cd.MaxActivationDistance = RANGE
	cd.Parent = m

	local token = 0
	local function setOpen(open)
		m:SetAttribute("Open", open)
		if sound then sound:Play() end
		setSolid(false) -- never shove or trap anyone while it swings
		local tw = TweenService:Create(value, INFO, { Value = open and angle or 0 })
		token += 1
		local my = token
		tw.Completed:Connect(function()
			if token ~= my or open then return end
			-- only turn solid again once no player is standing inside the closed leaf
			task.spawn(function()
				local op = OverlapParams.new()
				op.FilterType = Enum.RaycastFilterType.Include
				while token == my do
					local chars = {}
					for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do if plr.Character then table.insert(chars, plr.Character) end end
					op.FilterDescendantsInstances = chars
					local blocked = false
					for _, p in ipairs(leafParts) do
						if #workspace:GetPartsInPart(p, op) > 0 then blocked = true break end
					end
					if not blocked then setSolid(true) return end
					task.wait(0.3)
				end
			end)
		end)
		tw:Play()
		local auto = m:GetAttribute("AutoClose") or 7
		if open and auto > 0 then
			task.delay(auto, function()
				-- wait until nobody is standing in the doorway / swing area
				while token == my and m:GetAttribute("Open") and someoneInSwing() do task.wait(1) end
				if token == my and m:GetAttribute("Open") then setOpen(false) end
			end)
		end
	end

	local busy = false
	cd.MouseClick:Connect(function(player)
		if busy then return end
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp or (hrp.Position - pin.Position).Magnitude > RANGE + 4 then return end
		busy = true
		setOpen(not m:GetAttribute("Open"))
		task.wait(INFO.Time)
		busy = false
	end)
	m:SetAttribute("Open", false)
end

for _, m in ipairs(CS:GetTagged("TapDoor")) do task.spawn(setup, m) end
CS:GetInstanceAddedSignal("TapDoor"):Connect(setup)
