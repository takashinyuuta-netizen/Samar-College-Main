--[[ BikeClient — riding the School Bike.
  RIDER (only on your own bike):  W / thumbstick up = pedal, S = brake / reverse, A D = steer, Shift = pedal hard,
  B = bell, Space / jump = get off. Walk into your parked bike to ride again. NO on-screen riding panel.
  The bike leans into turns and tilts with hills.
  EVERYONE sees every bike animate: wheels and pedals turn with the speed, the rider pedals with hands on the
  handlebar, dust kicks up from the back wheel. ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local remote = RS:WaitForChild("BikeRemote")
local bikesFolder = workspace:WaitForChild("Bikes")

local MAX_SPEED, BOOST_SPEED, REVERSE = 26, 36, 7
local ACCEL, BRAKE, COAST = 15, 38, 7
local WHEEL_R, WHEELBASE = 1.3, 3.6

---------------------------------------------------------------- messages (short toasts only; no riding panel)
local toastLbl = Instance.new("TextLabel")
toastLbl.AnchorPoint = Vector2.new(0.5, 0) toastLbl.Position = UDim2.new(0.5, 0, 0, 56) toastLbl.Size = UDim2.fromOffset(420, 34)
toastLbl.BackgroundColor3 = Color3.fromRGB(18, 22, 28) toastLbl.BackgroundTransparency = 1 toastLbl.TextTransparency = 1
toastLbl.Font = Enum.Font.GothamBold toastLbl.TextSize = 15 toastLbl.TextColor3 = Color3.new(1, 1, 1) toastLbl.TextWrapped = true
local toastGui = Instance.new("ScreenGui") toastGui.Name = "BikeToast" toastGui.ResetOnSpawn = false toastGui.DisplayOrder = 6 toastGui.Parent = player.PlayerGui
toastLbl.Parent = toastGui
Instance.new("UICorner", toastLbl).CornerRadius = UDim.new(0, 10)
local ts = Instance.new("UIStroke", toastLbl) ts.Color = Color3.fromRGB(0, 170, 100) ts.Thickness = 2 ts.Transparency = 1
Instance.new("UISizeConstraint", toastLbl).MaxSize = Vector2.new(440, 60)
local toastToken = 0
local function toast(msg)
	toastToken += 1 local my = toastToken
	toastLbl.Text = msg toastLbl.BackgroundTransparency = 0.12 toastLbl.TextTransparency = 0 ts.Transparency = 0
	task.delay(3.2, function()
		if my ~= toastToken then return end
		TweenService:Create(toastLbl, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		TweenService:Create(ts, TweenInfo.new(0.4), { Transparency = 1 }):Play()
	end)
end
remote.OnClientEvent:Connect(function(kind, a)
	if kind == "toast" then toast(a) end
end)

---------------------------------------------------------------- my riding state
local myBike, mySeat, speed, yaw = nil, nil, 0, 0
local stuckTime = 0
local function ring() remote:FireServer("bell") end
UIS.InputBegan:Connect(function(input, gp)
	if gp or not myBike then return end
	if input.KeyCode == Enum.KeyCode.B then ring() end
end)

local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude
local function groundY(pos, ignore)
	rp.FilterDescendantsInstances = ignore
	local r = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -8, 0), rp)
	return r and r.Position.Y
end

local function startRiding(bike, seat)
	myBike, mySeat = bike, seat
	local _, y = bike.PrimaryPart.CFrame:ToEulerAnglesYXZ()
	yaw, speed, stuckTime = y, 0, 0
end
local function stopRiding()
	myBike, mySeat = nil, nil
end

local function hookCharacter(char)
	local hum = char:WaitForChild("Humanoid")
	hum.Seated:Connect(function(active, seat)
		if active and seat and seat.Name == "BikeSeat" and seat.Parent and seat.Parent:GetAttribute("OwnerId") == player.UserId then
			startRiding(seat.Parent, seat)
		else
			stopRiding()
		end
	end)
	hum.Died:Connect(stopRiding)
end
if player.Character then task.spawn(hookCharacter, player.Character) end
player.CharacterAdded:Connect(hookCharacter)

RunService.Heartbeat:Connect(function(dt)
	-- keep riding state in sync with the real seat (Seated can fire before attributes replicate)
	local ch = player.Character
	local hm = ch and ch:FindFirstChildOfClass("Humanoid")
	local sp = hm and hm.SeatPart
	if sp and sp.Name == "BikeSeat" and sp.Parent and sp.Parent:GetAttribute("OwnerId") == player.UserId then
		if myBike ~= sp.Parent then startRiding(sp.Parent, sp) end
	elseif myBike then
		stopRiding()
	end
	if not (myBike and myBike.Parent and mySeat and mySeat.Parent) then if myBike then stopRiding() end return end
	local root = myBike.PrimaryPart
	local drive, upright = root:FindFirstChild("Drive"), root:FindFirstChild("Upright")
	if not (drive and upright) then return end
	local throttle, steer = mySeat.ThrottleFloat, mySeat.SteerFloat
	local boosting = UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
	local top = boosting and BOOST_SPEED or MAX_SPEED
	if throttle > 0.05 then
		speed = math.min(top * throttle, speed + ACCEL * dt * (speed < 0 and 2.5 or 1))
		if speed > top then speed = math.max(top, speed - COAST * dt) end
	elseif throttle < -0.05 then
		if speed > 0.5 then speed = math.max(0, speed - BRAKE * dt) else speed = math.max(-REVERSE, speed - ACCEL * 0.6 * dt) end
	else
		if speed > 0 then speed = math.max(0, speed - COAST * dt) else speed = math.min(0, speed + COAST * dt) end
	end
	-- bumped into something: lose speed
	local fwd = CFrame.Angles(0, yaw, 0).LookVector
	local actual = root.AssemblyLinearVelocity:Dot(fwd)
	if math.abs(speed) > 6 and math.abs(actual) < math.abs(speed) * 0.25 then
		stuckTime += dt
		if stuckTime > 0.25 then speed *= 0.3 stuckTime = 0 end
	else stuckTime = 0 end
	-- steering (faster turning at low speed, reversed when going backward)
	local turn = 2.3 * math.clamp(math.abs(speed) / 9, 0.35, 1) * (speed >= -0.1 and 1 or -1)
	yaw -= steer * turn * dt
	fwd = CFrame.Angles(0, yaw, 0).LookVector
	-- tilt with the ground (front vs back wheel) and lean into turns
	local ign = { myBike, player.Character }
	local p = root.Position
	local yf = groundY(p + fwd * (WHEELBASE / 2), ign)
	local yr = groundY(p - fwd * (WHEELBASE / 2), ign)
	local pitch = 0
	if yf and yr then pitch = math.clamp(math.atan2(yf - yr, WHEELBASE), -0.6, 0.6) end
	local lean = -steer * math.clamp(math.abs(speed) / MAX_SPEED, 0, 1) * math.rad(16)
	upright.CFrame = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, lean)
	drive.PlaneVelocity = Vector2.new(fwd.X * speed, fwd.Z * speed)
end)

---------------------------------------------------------------- visuals for every bike on this screen
local state = {} -- bike -> { wheel=angle, crank=angle, c0 = {} }
local function motorsOf(char)
	local m = {}
	for _, n in ipairs({ "LeftHip", "RightHip", "LeftKnee", "RightKnee", "LeftShoulder", "RightShoulder", "LeftElbow", "RightElbow" }) do
		local j = char:FindFirstChild(n, true)
		if j and j:IsA("Motor6D") then m[n] = j end
	end
	local torso = char:FindFirstChild("Torso")
	if torso then -- R6
		m.R6 = true
		m["LeftHip"] = torso:FindFirstChild("Left Hip") m["RightHip"] = torso:FindFirstChild("Right Hip")
		m["LeftShoulder"] = torso:FindFirstChild("Left Shoulder") m["RightShoulder"] = torso:FindFirstChild("Right Shoulder")
	end
	return m
end

RunService.Stepped:Connect(function(_, dt)
	for _, bike in ipairs(bikesFolder:GetChildren()) do
		local root = bike.PrimaryPart
		if not root then continue end
		local s = state[bike]
		if not s then
			s = { wheel = 0, crank = 0, motors = {} }
			for _, n in ipairs({ "WheelFMotor", "WheelRMotor", "CrankMotor" }) do
				local m = root:FindFirstChild(n) if m then s.motors[n] = { m, m.C0 } end
			end
			state[bike] = s
			bike.AncestryChanged:Connect(function() if not bike.Parent then state[bike] = nil end end)
		end
		local v = root.AssemblyLinearVelocity
		local fspeed = v:Dot(root.CFrame.LookVector)
		if bike:GetAttribute("Parked") then fspeed = 0 end
		s.wheel -= fspeed / WHEEL_R * dt
		local pedaling = math.abs(fspeed) > 0.6
		if pedaling then s.crank -= fspeed / 3.2 * dt end
		for n, pair in pairs(s.motors) do
			local ang = (n == "CrankMotor") and s.crank or s.wheel
			pair[1].C0 = pair[2] * CFrame.Angles(ang, 0, 0)
		end
		-- dust & rolling sound
		local dust = bike:FindFirstChild("ContactR") and bike.ContactR:FindFirstChild("Dust")
		if dust then dust.Rate = math.abs(fspeed) > 14 and (math.abs(fspeed) - 12) * 1.5 or 0 end
		local roll = root:FindFirstChild("RollSound")
		if roll then
			local want = math.clamp(math.abs(fspeed) / 30, 0, 0.35)
			roll.Volume = want roll.PlaybackSpeed = 0.7 + math.abs(fspeed) / 40
			if want > 0.02 and not roll.IsPlaying then roll:Play() elseif want <= 0.02 and roll.IsPlaying then roll:Stop() end
		end
		-- rider pose: pedal with the crank, hands on the handlebar
		local seat = bike:FindFirstChild("BikeSeat")
		local occ = seat and seat.Occupant
		if occ and occ.Parent then
			local char = occ.Parent
			s.rig = (s.rigChar == char) and s.rig or motorsOf(char)
			s.rigChar = char
			local m = s.rig
			local c = s.crank
			if m.R6 then
				if m.RightHip then m.RightHip.Transform = CFrame.Angles(0, 0, 1.25 + 0.35 * math.sin(c)) end
				if m.LeftHip then m.LeftHip.Transform = CFrame.Angles(0, 0, -(1.25 + 0.35 * math.sin(c + math.pi))) end
				if m.RightShoulder then m.RightShoulder.Transform = CFrame.Angles(0, 0, 1.15) end
				if m.LeftShoulder then m.LeftShoulder.Transform = CFrame.Angles(0, 0, -1.15) end
			else
				local function legs(side, ph)
					local hip, knee = m[side .. "Hip"], m[side .. "Knee"]
					if hip then hip.Transform = CFrame.Angles(1.15 + 0.32 * math.sin(ph), 0, 0) end
					if knee then knee.Transform = CFrame.Angles(-(0.75 + 0.55 * math.cos(ph)), 0, 0) end
				end
				legs("Right", c) legs("Left", c + math.pi)
				for _, side in ipairs({ "Left", "Right" }) do
					local sh, el = m[side .. "Shoulder"], m[side .. "Elbow"]
					if sh then sh.Transform = CFrame.Angles(1.2, 0, side == "Left" and -0.12 or 0.12) end
					if el then el.Transform = CFrame.Angles(0.35, 0, 0) end
				end
			end
		end
	end
end)
