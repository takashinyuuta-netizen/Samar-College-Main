--[[ BoatClient — drive a rowboat (no UI).
  Sit in the back seat (walk into it). W / thumbstick up = row forward, S = back, A/D = turn, Jump = get off.
  BoatServer gives this device control of the boat while you're the driver. ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local MAX_SPEED, REVERSE = 16, 7
local ACCEL, DRAG = 10, 4
local TURN_RATE = 1.3 -- radians / s at speed

-- small tip at the bottom while you sit in a boat
local tipGui = Instance.new("ScreenGui") tipGui.Name = "BoatTip" tipGui.ResetOnSpawn = false tipGui.DisplayOrder = 6 tipGui.Enabled = false
tipGui.Parent = player:WaitForChild("PlayerGui")
local tip = Instance.new("TextLabel") tip.AnchorPoint = Vector2.new(0.5, 1) tip.Position = UDim2.new(0.5, 0, 1, -122) tip.Size = UDim2.fromOffset(440, 34)
tip.BackgroundColor3 = Color3.fromRGB(20, 40, 60) tip.BackgroundTransparency = 0.15 tip.TextColor3 = Color3.new(1, 1, 1) tip.Font = Enum.Font.GothamBold tip.TextSize = 15 tip.Parent = tipGui
Instance.new("UICorner", tip).CornerRadius = UDim.new(0, 12)
local tipStroke = Instance.new("UIStroke") tipStroke.Color = Color3.fromRGB(120, 200, 255) tipStroke.Thickness = 1.5 tipStroke.Parent = tip
local UIS = game:GetService("UserInputService")
local function setTip(kind)
	if kind == "driver" then
		tip.Text = UIS.TouchEnabled and not UIS.KeyboardEnabled and "🚣 Joystick up = row  •  left/right = turn  •  Jump = get off" or "🚣 W / S = row  •  A / D = turn  •  Space = get off"
		tipGui.Enabled = true
	elseif kind == "passenger" then
		tip.Text = "🚣 Passenger seat — sit in the BACK seat to row the boat"
		tipGui.Enabled = true
	else tipGui.Enabled = false end
end
local tipFor = nil
local hideAt = 0

local seat, root, lv, ao
local speed, heading, bowYaw, floatY = 0, 0, 0, 0
local stuck = 0

local function yawOf(v) return math.atan2(-v.X, -v.Z) end

local function start(s)
	local boat = s:FindFirstAncestorWhichIsA("Model")
	while boat and not boat.PrimaryPart and boat.Parent do boat = boat.Parent:FindFirstAncestorWhichIsA("Model") end
	local r = boat and boat.PrimaryPart
	if not r then return end
	local bowLocal = r:GetAttribute("BowLocal")
	if typeof(bowLocal) ~= "Vector3" then return end
	seat, root = s, r
	lv, ao = r:FindFirstChild("BoatMove"), r:FindFirstChild("BoatTurn")
	floatY = r:GetAttribute("FloatY") or r.Position.Y
	bowYaw = yawOf(bowLocal)
	local bowWorld = r.CFrame:VectorToWorldSpace(bowLocal)
	heading = yawOf(Vector3.new(bowWorld.X, 0, bowWorld.Z))
	speed, stuck = 0, 0
end
local function stop()
	seat, root, lv, ao = nil, nil, nil, nil
end

RunService.Heartbeat:Connect(function(dt)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local sp = hum and hum.SeatPart
	-- tip: shows for 8 s after you sit down (driver or passenger), then hides
	if sp ~= tipFor then
		tipFor = sp
		local boatModel = sp and sp:FindFirstAncestorWhichIsA("Model")
		local isBoat = boatModel and (game:GetService("CollectionService"):HasTag(boatModel, "SC_Boat") or (boatModel.Parent and game:GetService("CollectionService"):HasTag(boatModel.Parent, "SC_Boat")))
		if sp and sp:GetAttribute("SC_BoatSeat") then setTip("driver") hideAt = os.clock() + 8
		elseif sp and isBoat then setTip("passenger") hideAt = os.clock() + 8
		else setTip(nil) end
	end
	if tipGui.Enabled and os.clock() > hideAt then setTip(nil) end
	if sp and sp:IsA("VehicleSeat") and sp:GetAttribute("SC_BoatSeat") then
		if sp ~= seat then start(sp) end
	elseif seat then
		stop()
	end
	if not (seat and root and root.Parent and lv and ao) then return end
	if root.Anchored then return end -- server hasn't handed it over yet

	local throttle, steer = seat.ThrottleFloat, seat.SteerFloat
	if throttle > 0.05 then
		speed = math.min(MAX_SPEED * throttle, speed + ACCEL * dt * (speed < 0 and 2 or 1))
	elseif throttle < -0.05 then
		speed = math.max(-REVERSE, speed - ACCEL * dt * (speed > 0 and 2 or 1))
	else
		if speed > 0 then speed = math.max(0, speed - DRAG * dt) else speed = math.min(0, speed + DRAG * dt) end
	end
	-- turning: a rowboat can turn slowly on the spot and faster when moving
	local turn = TURN_RATE * math.clamp(math.abs(speed) / 6, 0.75, 1) * (speed >= -0.1 and 1 or -1)
	heading -= steer * turn * dt
	local dir = CFrame.Angles(0, heading, 0).LookVector

	-- bumped into the bank / pier: lose speed instead of grinding
	local actual = root.AssemblyLinearVelocity:Dot(dir)
	if math.abs(speed) > 3 and math.abs(actual) < math.abs(speed) * 0.25 then
		stuck += dt
		if stuck > 0.3 then speed *= 0.35 stuck = 0 end
	else stuck = 0 end

	-- float on the water line with a gentle bob, lean a little into turns
	local t = os.clock()
	local bob = math.sin(t * 1.7) * 0.1
	local vy = math.clamp((floatY + bob - root.Position.Y) * 5, -12, 12)
	lv.VectorVelocity = dir * speed + Vector3.new(0, vy, 0)
	local roll = -steer * math.clamp(math.abs(speed) / MAX_SPEED, 0, 1) * math.rad(5)
	local pitch = math.sin(t * 1.3) * math.rad(1.2) + math.clamp(speed / MAX_SPEED, -1, 1) * math.rad(-1.5)
	ao.CFrame = CFrame.Angles(0, heading - bowYaw, 0) * CFrame.Angles(pitch, 0, roll)
end)
