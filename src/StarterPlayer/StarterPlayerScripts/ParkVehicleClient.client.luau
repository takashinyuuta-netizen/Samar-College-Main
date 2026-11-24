--[[ ParkVehicleClient — driving the parking-lot Car / Motorcycle (ParkVehicleServer seats you).
  DRIVER: W / S or the thumbstick = gas / brake + reverse, A / D = steer, Space / Jump = get out.
          No on-screen driving panel (players discover the horn on H themselves).
  While you sit in a vehicle its own E prompts are hidden for you (no "Backride" over your own bike).
  Getting out puts you beside the door right away; the vehicle stays exactly where / how you left it.
  EVERYONE sees every vehicle animate: wheels roll, front wheels + steering wheel / handlebar turn,
  the engine sound follows the speed, and the motorcycle rider holds the handlebar. ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local remote = RS:WaitForChild("ParkVehicleRemote")
local folder = workspace:WaitForChild("SanRoqueStreet"):WaitForChild("StreetEndParking"):WaitForChild("DriveVehicles")
local TOUCH = UIS.TouchEnabled and not UIS.KeyboardEnabled

---------------------------------------------------------------- UI: short toasts only (no driving panel)
local gui = Instance.new("ScreenGui")
gui.Name = "VehicleHUD" gui.ResetOnSpawn = false gui.DisplayOrder = 6 gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local toastLbl = Instance.new("TextLabel")
toastLbl.AnchorPoint = Vector2.new(0.5, 0) toastLbl.Position = UDim2.new(0.5, 0, 0, 56) toastLbl.Size = UDim2.fromOffset(400, 34)
toastLbl.BackgroundColor3 = Color3.fromRGB(18, 22, 28) toastLbl.BackgroundTransparency = 1 toastLbl.TextTransparency = 1
toastLbl.Font = Enum.Font.GothamBold toastLbl.TextSize = 15 toastLbl.TextColor3 = Color3.new(1, 1, 1) toastLbl.TextWrapped = true
toastLbl.Parent = gui
Instance.new("UICorner", toastLbl).CornerRadius = UDim.new(0, 10)
local tstroke = Instance.new("UIStroke", toastLbl) tstroke.Color = Color3.fromRGB(0, 170, 100) tstroke.Thickness = 2 tstroke.Transparency = 1
Instance.new("UISizeConstraint", toastLbl).MaxSize = Vector2.new(420, 60)
local toastToken = 0
local function toast(msg)
	toastToken += 1 local my = toastToken
	toastLbl.Text = msg toastLbl.BackgroundTransparency = 0.12 toastLbl.TextTransparency = 0 tstroke.Transparency = 0
	task.delay(3, function()
		if my ~= toastToken then return end
		TweenService:Create(toastLbl, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		TweenService:Create(tstroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
	end)
end
remote.OnClientEvent:Connect(function(kind, a) if kind == "toast" then toast(a) end end)


---------------------------------------------------------------- my driving state
local myCar, mySeat, speed, yaw, steerS = nil, nil, 0, 0, 0
local stuckTime, sentBrake, sentRev = 0, nil, nil
local function vehicleOfSeat(seat)
	local m = seat and seat.Parent
	if m and m:IsA("Model") and m:GetAttribute("ParkVehicle") and m.Parent == folder then return m end
end
local function horn() if myCar then remote:FireServer("horn") end end
UIS.InputBegan:Connect(function(input, gp)
	if gp or not myCar then return end
	if input.KeyCode == Enum.KeyCode.H then horn() end
end)

local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude
local function groundY(pos, ignore)
	rp.FilterDescendantsInstances = ignore
	local r = workspace:Raycast(pos + Vector3.new(0, 2.5, 0), Vector3.new(0, -9, 0), rp)
	return r and r.Position.Y
end

local function startDriving(m, seat)
	myCar, mySeat = m, seat
	yaw = select(2, m.PrimaryPart.CFrame:ToEulerAnglesYXZ())
	speed, stuckTime, steerS, sentBrake, sentRev = 0, 0, 0, nil, nil
end
local function stopDriving()
	myCar, mySeat = nil, nil
end

-- step out beside the door the moment you leave a seat (you never land on the roof / seat)
local lastSeat, lastVehicle = nil, nil
local function stepOut(char, seat, m)
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local root = m and m.PrimaryPart
	if not (hrp and root and seat) then return end
	local _, yawV = root.CFrame:ToEulerAnglesYXZ()
	local off = seat:GetAttribute("ExitOffset") or Vector3.new(-3, 0, 0)
	local spot = (CFrame.new(root.Position) * CFrame.Angles(0, yawV, 0) * CFrame.new(off.X, 0, off.Z)).Position
	local gy = groundY(spot + Vector3.new(0, 4, 0), { m, char })
	gy = gy or (root.Position.Y - 1)
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = CFrame.new(spot.X, gy + 3.1, spot.Z) * CFrame.Angles(0, yawV, 0)
end

-- hide a vehicle's own E prompts from the people sitting in it
-- prompts are cached (rebuilt only when a vehicle respawns / streams in) instead of scanning every time
local promptCache
local function rebuildPrompts()
	promptCache = {}
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("ProximityPrompt") then table.insert(promptCache, d) end
	end
end
folder.DescendantAdded:Connect(function(d) if d:IsA("ProximityPrompt") then promptCache = nil end end)
folder.DescendantRemoving:Connect(function(d) if d:IsA("ProximityPrompt") then promptCache = nil end end)
local function updatePrompts(inVehicle)
	if not promptCache then rebuildPrompts() end
	for _, d in ipairs(promptCache) do
		if d.Parent then
			local want = d:GetAttribute("Avail") ~= false and inVehicle == nil
			if d.Enabled ~= want then d.Enabled = want end
		end
	end
end
local promptTick, promptFor = 0, false

RunService.Heartbeat:Connect(function(dt)
	local ch = player.Character
	local hm = ch and ch:FindFirstChildOfClass("Humanoid")
	local sp = hm and hm.SeatPart
	local inV = sp and vehicleOfSeat(sp)
	if inV then
		lastSeat, lastVehicle = sp, inV
	elseif lastSeat then
		local s, v = lastSeat, lastVehicle
		lastSeat, lastVehicle = nil, nil
		if hm and hm.Health > 0 then stepOut(ch, s, v) end
	end
	promptTick += dt
	if promptTick > 0.2 or (inV or false) ~= promptFor then
		promptTick, promptFor = 0, inV or false
		updatePrompts(inV)
	end
	local m = sp and sp.Name == "DriveSeat" and vehicleOfSeat(sp)
	if m then
		if myCar ~= m then startDriving(m, sp) end
	elseif myCar then
		stopDriving()
	end
	if not (myCar and myCar.Parent and mySeat and mySeat.Parent) then return end
	local root = myCar.PrimaryPart
	local drive, upright = root and root:FindFirstChild("Drive"), root and root:FindFirstChild("Upright")
	if not (drive and upright) or root.Anchored then return end

	local MAX = myCar:GetAttribute("MaxSpeed") or 40
	local REV = myCar:GetAttribute("Reverse") or 10
	local ACC = myCar:GetAttribute("Accel") or 14
	local BRK = myCar:GetAttribute("Brake") or 40
	local COAST = myCar:GetAttribute("Coast") or 6
	local WB = myCar:GetAttribute("Wheelbase") or 6
	local STEER = math.rad(myCar:GetAttribute("MaxSteer") or 30)
	local moto = myCar:GetAttribute("ParkVehicle") == "Moto"

	local throttle, steer = mySeat.ThrottleFloat, mySeat.SteerFloat
	local braking = false
	if throttle > 0.05 then
		if speed < -0.5 then speed = math.min(0, speed + BRK * dt) braking = true
		else speed = math.min(MAX * throttle, speed + ACC * dt * (1 - 0.45 * speed / MAX)) end
	elseif throttle < -0.05 then
		if speed > 0.5 then speed = math.max(0, speed - BRK * dt) braking = true
		else speed = math.max(-REV, speed - ACC * 0.6 * dt) end
	else
		if speed > 0 then speed = math.max(0, speed - COAST * dt) else speed = math.min(0, speed + COAST * dt) end
	end
	-- hit something: lose speed
	local fwd = CFrame.Angles(0, yaw, 0).LookVector
	local actual = root.AssemblyLinearVelocity:Dot(fwd)
	if math.abs(speed) > 6 and math.abs(actual) < math.abs(speed) * 0.3 then
		stuckTime += dt
		if stuckTime > 0.25 then speed *= 0.3 stuckTime = 0 end
	else stuckTime = 0 end
	-- steering: real turning circle (wheelbase), less lock at high speed
	steerS += (steer - steerS) * math.min(1, dt * 8)
	local lock = STEER * (1 - 0.55 * math.clamp(math.abs(speed) / MAX, 0, 1))
	local yawRate = speed * math.tan(steerS * lock) / WB
	yaw -= yawRate * dt
	fwd = CFrame.Angles(0, yaw, 0).LookVector
	-- follow the ground: pitch from front/back, roll from left/right (car) or lean into turns (moto)
	local ign = { myCar, ch }
	local p = root.Position
	local right = CFrame.Angles(0, yaw, 0).RightVector
	local yf, yr = groundY(p + fwd * (WB / 2), ign), groundY(p - fwd * (WB / 2), ign)
	local pitch, roll = 0, 0
	if yf and yr then pitch = math.clamp(math.atan2(yf - yr, WB), -0.5, 0.5) end
	if moto then
		roll = -steerS * math.clamp(math.abs(speed) / MAX, 0, 1) * math.rad(20)
	else
		local yl, yrr = groundY(p - right * 2.4, ign), groundY(p + right * 2.4, ign)
		if yl and yrr then roll = math.clamp(math.atan2(yl - yrr, 4.8), -0.35, 0.35) end
	end
	upright.CFrame = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, roll)
	drive.PlaneVelocity = Vector2.new(fwd.X * speed, fwd.Z * speed)

	-- lights (only tell the server when they change)
	local rev = speed < -0.3
	if braking ~= sentBrake or rev ~= sentRev then
		sentBrake, sentRev = braking, rev
		remote:FireServer("lights", braking, rev)
	end
	-- the vehicle's own dashboard gauge (in the 3D model, not on screen)
	local kmh = math.floor(math.abs(speed) + 0.5)
	for _, n in ipairs({ "Gauge", "Speedo" }) do
		local g = myCar:FindFirstChild(n)
		local lbl = g and g:FindFirstChild("Speed", true)
		if lbl then lbl.Text = tostring(kmh) end
	end
end)

---------------------------------------------------------------- visuals for every vehicle on this screen
local state = {}
local function motorsOf(char)
	local mt = {}
	for _, n in ipairs({ "LeftHip", "RightHip", "LeftKnee", "RightKnee", "LeftShoulder", "RightShoulder", "LeftElbow", "RightElbow" }) do
		local j = char:FindFirstChild(n, true)
		if j and j:IsA("Motor6D") then mt[n] = j end
	end
	local torso = char:FindFirstChild("Torso")
	if torso then
		mt.R6 = true
		mt.LeftHip = torso:FindFirstChild("Left Hip") mt.RightHip = torso:FindFirstChild("Right Hip")
		mt.LeftShoulder = torso:FindFirstChild("Left Shoulder") mt.RightShoulder = torso:FindFirstChild("Right Shoulder")
	end
	return mt
end

RunService.Stepped:Connect(function(_, dt)
	for _, m in ipairs(folder:GetChildren()) do
		local root = m.PrimaryPart
		if not root then continue end
		local s = state[m]
		if not s then
			s = { spin = 0, steer = 0, motors = {} }
			for _, d in ipairs(root:GetChildren()) do
				if d:IsA("Motor6D") then s.motors[d.Name] = { d, d.C0 } end
			end
			local bars = m:FindFirstChild("BarsHub")
			if bars then
				for _, d in ipairs(bars:GetChildren()) do if d:IsA("Motor6D") then s.motors[d.Name] = { d, d.C0 } end end
			end
			state[m] = s
			m.AncestryChanged:Connect(function() if not m.Parent then state[m] = nil end end)
		end
		local moto = m:GetAttribute("ParkVehicle") == "Moto"
		local R = m:GetAttribute("WheelR") or 1.2
		local MAX = m:GetAttribute("MaxSpeed") or 40
		local fspeed = m:GetAttribute("Parked") and 0 or root.AssemblyLinearVelocity:Dot(root.CFrame.LookVector)
		s.spin = (s.spin - fspeed / R * dt) % (math.pi * 2)
		local seat = m:FindFirstChild("DriveSeat")
		local want = (m == myCar) and steerS or (seat and seat.Occupant and seat.SteerFloat or 0)
		s.steer += (want - s.steer) * math.min(1, dt * 10)
		local lock = math.rad(m:GetAttribute("MaxSteer") or 30) * (1 - 0.55 * math.clamp(math.abs(fspeed) / MAX, 0, 1))
		for name, pair in pairs(s.motors) do
			local mo, base = pair[1], pair[2]
			if name == "WheelFLMotor" or name == "WheelFRMotor" then
				mo.C0 = base * CFrame.Angles(0, -s.steer * lock, 0) * CFrame.Angles(s.spin, 0, 0)
			elseif name == "WheelRLMotor" or name == "WheelRRMotor" or name == "WheelFMotor" or name == "WheelRMotor" then
				mo.C0 = base * CFrame.Angles(s.spin, 0, 0)
			elseif name == "SteerMotor" then
				mo.C0 = base * CFrame.Angles(0, 0, s.steer * 2.4)
			elseif name == "BarsMotor" then
				mo.C0 = base * CFrame.Angles(0, -s.steer * lock, 0)
			end
		end
		-- engine note follows the speed
		local eng = root:FindFirstChild("Engine")
		if eng then eng.PlaybackSpeed = 0.75 + math.clamp(math.abs(fspeed) / MAX, 0, 1) * 0.85 end
		-- motorcycle rider: hands on the bars, feet on the pegs
		local occ = moto and seat and seat.Occupant
		if occ and occ.Parent then
			local char = occ.Parent
			if s.rigChar ~= char then s.rig = motorsOf(char) s.rigChar = char end
			local mt = s.rig
			if mt.R6 then
				if mt.RightHip then mt.RightHip.Transform = CFrame.Angles(0, 0, 1.3) end
				if mt.LeftHip then mt.LeftHip.Transform = CFrame.Angles(0, 0, -1.3) end
				if mt.RightShoulder then mt.RightShoulder.Transform = CFrame.Angles(0, 0, 1.2) end
				if mt.LeftShoulder then mt.LeftShoulder.Transform = CFrame.Angles(0, 0, -1.2) end
			else
				for _, side in ipairs({ "Left", "Right" }) do
					local hip, knee = mt[side .. "Hip"], mt[side .. "Knee"]
					if hip then hip.Transform = CFrame.Angles(1.25, 0, side == "Left" and -0.12 or 0.12) end
					if knee then knee.Transform = CFrame.Angles(-1.35, 0, 0) end
					local sh, el = mt[side .. "Shoulder"], mt[side .. "Elbow"]
					if sh then sh.Transform = CFrame.Angles(1.15, 0, side == "Left" and -0.18 or 0.18) end
					if el then el.Transform = CFrame.Angles(0.4, 0, 0) end
				end
			end
		end
	end
end)
