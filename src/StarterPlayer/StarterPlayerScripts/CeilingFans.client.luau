-- CeilingFans (client): spins every ceiling fan that is switched on.
-- A fan is a Model tagged "CeilingFan" with a part "Hub" (the blades turn around its up axis)
-- and a child model "Rotor" (the blades). The "On" attribute is set by the server (CeilingFans.server).
-- Speed ramps up and down smoothly. Done on the client so it is smooth and costs the server nothing.
-- Fans are (re)checked every second, so fans that stream in later are picked up too.
-- Orbit fans: attribute Orbit = true, a part "OrbitAxis" (turns around its up axis) and a child model
-- "Head" (motor + guard). While on, the head and blades swing a full 360 degrees around the axis.
-- Optional attribute SpinSpeed (radians per second) overrides the default speed, e.g. for roof turbine vents.
-- Optional attribute SweepAngle (degrees) on an orbit fan: instead of a full circle the head sweeps
-- back and forth +/- that many degrees, like an oscillating wall fan.
local CS = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local MAX_SPEED = 9 -- radians per second
local ORBIT_SPEED = 0.5 -- radians per second at full speed (about one full circle every 12 s)
local fans = {}

local function ready(m)
	local hub = m:FindFirstChild("Hub")
	local rotor = m:FindFirstChild("Rotor")
	if not (hub and rotor and rotor:IsA("Model")) then return nil end
	if not rotor:FindFirstChildWhichIsA("BasePart") then return nil end
	return hub, rotor
end

task.spawn(function()
	while true do
		for _, m in ipairs(CS:GetTagged("CeilingFan")) do
			if m:IsA("Model") and m:IsDescendantOf(workspace) and not fans[m] then
				local hub, rotor = ready(m)
				-- orbit fans: wait until the head has streamed in too, or it would never swing
				if hub and m:GetAttribute("Orbit") then
					local head = m:FindFirstChild("Head")
					if not (m:FindFirstChild("OrbitAxis") and head and head:FindFirstChild("Motor")) then hub = nil end
				end
				if hub then
					local f = { hub = hub.CFrame, rotor = rotor, rel = hub.CFrame:ToObjectSpace(rotor:GetPivot()), angle = 0, speed = 0 }
					local axis, head = m:FindFirstChild("OrbitAxis"), m:FindFirstChild("Head")
					if m:GetAttribute("Orbit") and axis and head and head:IsA("Model") then
						f.axis = axis.CFrame
						f.head = head
						f.head0 = head:GetPivot()
						f.orbit = 0
						f.sweep = m:GetAttribute("SweepAngle")
					end
					fans[m] = f
				end
			end
		end
		task.wait(1)
	end
end)

-- Performance: only fans near the camera are animated (153 fans spinning everywhere at once was a big
-- part of the lag). "Improve FPS" shortens the range and animates at 30 fps.
local player = game:GetService("Players").LocalPlayer
local acc = 0
RunService.RenderStepped:Connect(function(dt)
	local fpsMode = player:GetAttribute("Setting_ImproveFPS") == true
	local range = fpsMode and 45 or 80
	if fpsMode then
		acc += dt
		if acc < 1 / 30 then return end
		dt, acc = acc, 0
	end
	local cam = workspace.CurrentCamera
	local cpos = cam and cam.CFrame.Position or Vector3.zero
	for m, f in pairs(fans) do
		if not m:IsDescendantOf(workspace) or not f.rotor.Parent then
			fans[m] = nil
		elseif (f.hub.Position - cpos).Magnitude > range then
			-- far away: skip (keeps its speed so it doesn't jump when you come back)
			f.speed = m:GetAttribute("On") and (m:GetAttribute("SpinSpeed") or MAX_SPEED) or 0
		else
			local target = m:GetAttribute("On") and (m:GetAttribute("SpinSpeed") or MAX_SPEED) or 0
			f.speed += (target - f.speed) * math.min(1, dt * 1.5)
			if f.speed > 0.01 then
				f.angle = (f.angle + f.speed * dt) % (math.pi * 2)
				local hub = f.hub
				if f.head and f.head.Parent then
					local rate = f.sweep and ORBIT_SPEED * 1.6 or ORBIT_SPEED
					f.orbit = (f.orbit + rate * math.min(1, f.speed / MAX_SPEED) * dt) % (math.pi * 2)
					local yaw = f.sweep and math.rad(f.sweep) * math.sin(f.orbit) or f.orbit
					local swing = f.axis * CFrame.Angles(0, yaw, 0) * f.axis:Inverse()
					f.head:PivotTo(swing * f.head0)
					hub = swing * f.hub
				end
				f.rotor:PivotTo(hub * CFrame.Angles(0, f.angle, 0) * f.rel)
			end
		end
	end
end)
