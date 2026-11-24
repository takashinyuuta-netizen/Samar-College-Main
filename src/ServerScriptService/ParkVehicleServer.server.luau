--[[ ParkVehicleServer — the drivable Car + Motorcycle parked in San Roque's StreetEndParking.
  • Anyone can use them: walk up and press E / tap "Drive" (or "Ride" / "Backride" for the passenger seats).
    Touching a vehicle never seats you. Jump = get out (you step out beside the door).
  • The driver's client drives (it owns the physics, same setup as the School Bike); the server only seats
    people, hands over network ownership, plays the horn / lights and cleans up.
  • RESPAWN: when nobody is in a vehicle for IDLE_RESPAWN (30) seconds and it is not in its parking spot, it
    disappears and a fresh copy appears in the EXACT original spot. Fell off the map = respawns right away.
  • No driving during events / games (EquipLocked): you can't get in, and you get out if an event locks you. ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")

local IDLE_RESPAWN = 30
local SETTLE_TIME = 1.5

local remote = RS:FindFirstChild("ParkVehicleRemote")
if not remote then remote = Instance.new("RemoteEvent") remote.Name = "ParkVehicleRemote" remote.Parent = RS end

local folder = workspace:WaitForChild("SanRoqueStreet"):WaitForChild("StreetEndParking"):WaitForChild("DriveVehicles")
local store = Instance.new("Folder") store.Name = "ParkVehicleTemplates" store.Parent = SS

local defs = {}          -- { template, home, model, lastActive, settleAt, driver, kind }
local lastTry, lastHorn = {}, {}

local function toast(player, msg) remote:FireClient(player, "toast", msg) end

local function setRiderGroup(char, on)
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			if on then
				if p.CollisionGroup ~= "BikeRider" then p:SetAttribute("PV_PrevGroup", p.CollisionGroup) end
				p.CollisionGroup = "BikeRider"
			else
				p.CollisionGroup = p:GetAttribute("PV_PrevGroup") or "Default"
			end
		end
	end
end

local function yawOf(cf) local _, y = cf:ToEulerAnglesYXZ() return y end
local function parkedPose(def, cf)
	-- motorcycle leans onto its side stand (left)
	if def.kind == "Moto" then return cf * CFrame.Angles(0, 0, math.rad(6)) end
	return cf
end

local function setLights(def, brake, reverse)
	local m = def.model
	if not m then return end
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			if p.Name == "BrakeLight" or p.Name == "BrakeLight3" then
				p.Material = brake and Enum.Material.Neon or Enum.Material.Glass
				p.Color = brake and Color3.fromRGB(255, 35, 35) or Color3.fromRGB(110, 10, 12)
			elseif p.Name == "ReverseLight" then
				p.Material = reverse and Enum.Material.Neon or Enum.Material.Glass
				p.Color = reverse and Color3.fromRGB(255, 255, 250) or Color3.fromRGB(200, 200, 200)
			end
		end
	end
	def.brake, def.reverse = brake, reverse
end

local function setParked(def, parked)
	local m = def.model
	local root = m and m.PrimaryPart
	if not root then return end
	m:SetAttribute("Parked", parked)
	local ks = m:FindFirstChild("Kickstand")
	if ks then ks.Transparency = parked and 0 or 1 end
	if parked then
		-- freeze EXACTLY where it is and the way it faces (no turning back to an old heading)
		root.Drive.PlaneVelocity = Vector2.zero
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.Upright.CFrame = root.CFrame.Rotation
		root.Anchored = true
		if def.kind == "Moto" then
			-- same spot + same heading, just resting on the side stand
			m:PivotTo(parkedPose(def, CFrame.new(root.Position) * CFrame.Angles(0, yawOf(root.CFrame), 0)))
		end
	else
		local yaw = yawOf(root.CFrame)
		root.Upright.CFrame = CFrame.Angles(0, yaw, 0)
		if def.kind == "Moto" then m:PivotTo(CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)) end
		root.Anchored = false
	end
end

local function seatsOf(m)
	local t = {}
	for _, d in ipairs(m:GetChildren()) do
		if d:IsA("Seat") or d:IsA("VehicleSeat") then table.insert(t, d) end
	end
	return t
end
-- the first free seat a prompt offers (driver seat first)
local function freeSeatFor(m, pr)
	for name in string.gmatch(pr:GetAttribute("Seats") or "", "[^,]+") do
		local s = m:FindFirstChild(name)
		if s and not s.Occupant then return s end
	end
end
-- keep every prompt's label right: "Drive" / "Ride" (car) or "Ride" / "Backride" (motorcycle), hidden when full
local function refreshPrompts(m)
	local moto = m:GetAttribute("ParkVehicle") == "Moto"
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			local s = freeSeatFor(m, d)
			d.Enabled = s ~= nil
			d:SetAttribute("Avail", s ~= nil) -- the client hides it from people already riding this vehicle
			if s then
				if s.Name == "DriveSeat" then d.ActionText = moto and "Ride" or "Drive"
				else d.ActionText = moto and "Backride" or "Ride" end
			end
		end
	end
end
local function anyOccupied(m)
	for _, s in ipairs(seatsOf(m)) do if s.Occupant then return true end end
	return false
end

-- the client already steps you out beside the door; this is only a fallback if you are still in / on the vehicle
local function stepOut(def, seat, char)
	task.wait(0.3)
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local m = def.model
	if not (hrp and hum and m and m.PrimaryPart) or hum.Health <= 0 or hum.Sit then return end
	if (hrp.Position - seat.Position).Magnitude > 4.5 then return end
	local root = m.PrimaryPart
	local yaw = yawOf(root.CFrame)
	local off = seat:GetAttribute("ExitOffset") or Vector3.new(-3, 0, 0)
	local spot = (CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0) * CFrame.new(off.X, 0, off.Z)).Position
	local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances = { m, char }
	local r = workspace:Raycast(spot + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), rp)
	local gy = r and r.Position.Y or (root.Position.Y - 1)
	hrp.CFrame = CFrame.new(spot.X, gy + 3.1, spot.Z) * CFrame.Angles(0, yaw, 0)
end

local setup -- forward

local function trySit(def, player, pr)
	local m = def.model
	if not (m and pr) then return end
	local seat = freeSeatFor(m, pr)
	if not seat then return end
	if lastTry[player] and os.clock() - lastTry[player] < 0.5 then return end
	lastTry[player] = os.clock()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp) or hum.Health <= 0 then return end
	if player:GetAttribute("EquipLocked") then toast(player, "🔒 No driving during events or games") return end
	if hum.Sit or hum.SeatPart then toast(player, "Get up first, then try again") return end
	if seat.Occupant then toast(player, "That seat is taken") return end
	if (hrp.Position - seat.Position).Magnitude > 14 then return end
	local isDriver = seat.Name == "DriveSeat"
	seat.Disabled = false
	hum:UnequipTools()
	if isDriver then
		setParked(def, false)
		pcall(function() m.PrimaryPart:SetNetworkOwner(player) end)
	end
	seat:Sit(hum)
	task.delay(0.8, function()
		if seat.Parent and not seat.Occupant then
			seat.Disabled = true
			if isDriver and not def.driver and def.model == m then setParked(def, true) end
		end
	end)
end

local function respawn(def)
	local old = def.model
	def.model = nil
	if old then
		for _, s in ipairs(seatsOf(old)) do if s.Occupant then s.Occupant.Sit = false end end
		old:Destroy()
	end
	local m = def.template:Clone()
	m.Parent = folder
	setup(def, m)
end

setup = function(def, m)
	def.model = m
	def.driver = nil
	def.lastActive = os.clock()
	def.settleAt = 0
	def.lightsOn = nil
	def.brake, def.reverse = nil, nil
	local root = m.PrimaryPart
	local engine, horn = root:FindFirstChild("Engine"), root:FindFirstChild("Horn")
	m:SetAttribute("Driver", nil)
	for _, s in ipairs(seatsOf(m)) do
		s.Disabled = true
		local rider -- character currently in this seat
		s:GetPropertyChangedSignal("Occupant"):Connect(function()
			if def.model ~= m then return end
			def.lastActive = os.clock()
			local occ = s.Occupant
			refreshPrompts(m)
			if occ then
				local p = Players:GetPlayerFromCharacter(occ.Parent)
				if not p or p:GetAttribute("EquipLocked") then
					task.defer(function() occ.Sit = false end)
					return
				end
				rider = occ.Parent
				setRiderGroup(rider, true)
				if s.Name == "DriveSeat" then
					def.driver = p
					m:SetAttribute("Driver", p.UserId)
					if m:GetAttribute("Parked") then setParked(def, false) end
					pcall(function() root:SetNetworkOwner(p) end)
					if engine then engine:Play() end
				end
			else
				s.Disabled = true
				local was = rider
				rider = nil
				if was and was.Parent then
					setRiderGroup(was, false)
					task.spawn(stepOut, def, s, was)
				end
				if s.Name == "DriveSeat" then
					def.driver = nil
					m:SetAttribute("Driver", nil)
					if engine then engine:Stop() end
					setLights(def, false, false)
					-- park right where the driver left it, facing the same way
					if not root.Anchored then setParked(def, true) end
				end
			end
		end)
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			d.Triggered:Connect(function(player)
				if def.model ~= m then return end
				trySit(def, player, d)
			end)
		end
	end
	-- start parked in the exact home spot
	m:PivotTo(def.home)
	setParked(def, true)
	setLights(def, false, false)
	refreshPrompts(m)
end

-- register every vehicle in the lot (their edit-time spots are their homes)
for _, m in ipairs(folder:GetChildren()) do
	if m:IsA("Model") and m:GetAttribute("ParkVehicle") and m.PrimaryPart then
		local tpl = m:Clone()
		tpl.Parent = store
		local def = { template = tpl, home = m.PrimaryPart.CFrame, kind = m:GetAttribute("ParkVehicle") }
		table.insert(defs, def)
		setup(def, m)
	end
end

local function atHome(def)
	local root = def.model.PrimaryPart
	local d = (root.Position - def.home.Position) * Vector3.new(1, 0, 1)
	local dy = math.abs(yawOf(root.CFrame) - yawOf(def.home)) % (math.pi * 2)
	dy = math.min(dy, math.pi * 2 - dy)
	return d.Magnitude < 1 and dy < math.rad(5)
end

-- the driver's controls: horn + brake / reverse lights
remote.OnServerEvent:Connect(function(player, action, a, b)
	local def
	for _, d in ipairs(defs) do if d.driver == player and d.model then def = d break end end
	if not def then return end
	if action == "horn" then
		if lastHorn[player] and os.clock() - lastHorn[player] < 0.45 then return end
		lastHorn[player] = os.clock()
		local h = def.model.PrimaryPart:FindFirstChild("Horn")
		if h then h:Play() end
	elseif action == "lights" then
		local brake, reverse = a == true, b == true
		if brake ~= def.brake or reverse ~= def.reverse then setLights(def, brake, reverse) end
	end
end)

-- events / games lock you out of vehicles
local function watchPlayer(p)
	p:GetAttributeChangedSignal("EquipLocked"):Connect(function()
		if not p:GetAttribute("EquipLocked") then return end
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		local sp = hum and hum.SeatPart
		if sp and sp:IsDescendantOf(folder) then hum.Sit = false end
	end)
end
Players.PlayerAdded:Connect(watchPlayer)
for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerRemoving:Connect(function(p) lastTry[p] = nil lastHorn[p] = nil end)

-- housekeeping: settle / park, 30 s idle respawn, fell off the map, night lights
task.spawn(function()
	while true do
		task.wait(0.5)
		local now = os.clock()
		local t = Lighting.ClockTime
		local night = (t >= 18 or t < 6)
		for _, def in ipairs(defs) do
			local m = def.model
			local root = m and m.Parent and m.PrimaryPart
			if not root or root.Position.Y < -60 then
				respawn(def)
				continue
			end
			if anyOccupied(m) then def.lastActive = now end
			-- no driver: let it roll to a stop, then park it where it is
			if not def.driver and not m:GetAttribute("Parked") and now >= def.settleAt then
				if root.AssemblyLinearVelocity.Magnitude < 2 or now >= def.settleAt + 3 then setParked(def, true) end
			end
			-- nobody used it for 30 s and it is not in its spot: fresh one back in the exact spot
			if not anyOccupied(m) and now - def.lastActive >= IDLE_RESPAWN and not atHome(def) then
				respawn(def)
				continue
			end
			-- headlights / tail lights at night while someone drives
			local on = night and def.driver ~= nil
			if on ~= def.lightsOn then
				def.lightsOn = on
				for _, d in ipairs(m:GetDescendants()) do
					if d:IsA("SpotLight") or d:IsA("SurfaceLight") then d.Enabled = on end
					if d.Name == "HeadLamp" and d:IsA("BasePart") then d.Material = on and Enum.Material.Neon or Enum.Material.Glass end
				end
			end
		end
	end
end)
