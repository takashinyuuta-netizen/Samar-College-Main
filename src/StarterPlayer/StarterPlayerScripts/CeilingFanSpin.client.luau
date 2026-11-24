-- Spins every fan (Model with attribute Spin=true and a "Blades" model) on the client.
-- The blades turn around the Blades model's pivot Y axis (orbit fans: the motor axis).
-- A fan stops when it, or the model it sits in, has the attribute On = false.
-- Orbit fans: a child model "Head" (with the Blades inside it) also turns slowly all the way
-- round (360°) around the Head pivot's Y axis (the ceiling rod) while the fan is on.
-- Performance: only fans near the camera are animated; "Improve FPS" (player attribute
-- Setting_ImproveFPS) shortens that range and updates less often.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local SPEED = math.rad(420)      -- blade speed
local ORBIT_SPEED = math.rad(24) -- orbit: one full turn every 15 seconds
local fans, known = {}, {}

local function isOn(m)
	local x = m
	while x and x ~= workspace do
		local v = x:GetAttribute("On")
		if v ~= nil then return v end
		x = x.Parent
	end
	return true
end
local function add(m)
	if known[m] or not (m:IsA("Model") and m:GetAttribute("Spin")) then return end
	local blades = m:FindFirstChild("Blades", true)
	-- wall fans (Thermoloth): attribute SpinPart names the model that turns (its pivot Y = the motor axis)
	if not blades and m:GetAttribute("SpinPart") then blades = m:FindFirstChild(m:GetAttribute("SpinPart")) end
	if not (blades and blades:IsA("Model")) then return end
	known[m] = true
	local head = m:FindFirstChild("Head")
	if head and not head:IsA("Model") then head = nil end
	local f = { fan = m, model = blades, base = blades:GetPivot(), angle = 0 }
	if head then
		f.head = head
		f.headBase = head:GetPivot()
		f.bladeOffset = f.headBase:ToObjectSpace(f.base)
		f.orbit = 0
	end
	table.insert(fans, f)
end
for _, d in ipairs(workspace:GetDescendants()) do add(d) end
workspace.DescendantAdded:Connect(function(d)
	add(d)
	if d:IsA("Model") and d.Name == "Blades" then
		local x = d.Parent
		while x and x ~= workspace do
			if x:IsA("Model") and x:GetAttribute("Spin") then task.defer(add, x) break end
			x = x.Parent
		end
	end
end)

local acc = 0
RunService.RenderStepped:Connect(function(dt)
	local fpsMode = player:GetAttribute("Setting_ImproveFPS") == true
	local range = fpsMode and 45 or 90
	if fpsMode then
		acc += dt
		if acc < 1 / 30 then return end -- animate at 30 fps in performance mode
		dt, acc = acc, 0
	end
	local cam = workspace.CurrentCamera
	local cpos = cam and cam.CFrame.Position or Vector3.zero
	for _, f in ipairs(fans) do
		if f.model.Parent and isOn(f.fan) then
			local p = f.base.Position
			if (p - cpos).Magnitude < range then
				f.angle = (f.angle + SPEED * dt) % (math.pi * 2)
				if f.head and f.head.Parent then
					f.orbit = (f.orbit + ORBIT_SPEED * dt) % (math.pi * 2)
					local headCF = f.headBase * CFrame.Angles(0, f.orbit, 0)
					f.head:PivotTo(headCF)
					f.model:PivotTo(headCF * f.bladeOffset * CFrame.Angles(0, f.angle, 0))
				else
					f.model:PivotTo(f.base * CFrame.Angles(0, f.angle, 0))
				end
			end
		end
	end
end)
