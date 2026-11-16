--[[ BoatServer — the lake rowboats can be driven. No UI.
  • Walk into the back seat (stern) to drive: W/S or thumbstick = row forward / back, A/D = turn. Jump = get off.
    The middle seat is for a passenger.
  • The driver's device moves the boat (smooth), the server only hands out control and keeps it safe.
  • Respawns at its dock when it falls into the void / goes far away, or when nobody has used it for IDLE_RESPAWN s.
  Boats: every Model tagged "SC_Boat" (Rowboat1 / Rowboat2 in IslandExpansion.RiverLake are tagged at start).
  BoatClient (StarterPlayerScripts) does the driving. ]]
local Players = game:GetService("Players")
local CS = game:GetService("CollectionService")

local IDLE_RESPAWN = 45      -- seconds with nobody aboard before a moved boat goes back to its dock
local VOID_DROP = 25         -- this far under the water line = fell into the void
local MAX_DISTANCE = 400     -- this far from the dock = gone too far (also catches a boat dragged off by a teleported rider)

local lake = workspace:WaitForChild("IslandExpansion"):WaitForChild("RiverLake")
for _, n in ipairs({ "Rowboat1", "Rowboat2" }) do
	local b = lake:FindFirstChild(n)
	if b then CS:AddTag(b, "SC_Boat") end
end

local boats = {} -- model -> state

local function flat(v) return Vector3.new(v.X, 0, v.Z) end

local function occupantsOf(S)
	local list = {}
	for _, s in ipairs(S.seats) do if s.Parent and s.Occupant then table.insert(list, s.Occupant) end end
	return list
end

local function park(S)
	-- stop where it is, sitting level on the water line
	local r = S.root
	local pos = r.Position
	local look = flat(r.CFrame.LookVector)
	if look.Magnitude < 0.1 then look = Vector3.new(0, 0, -1) end
	r.AssemblyLinearVelocity = Vector3.zero
	r.AssemblyAngularVelocity = Vector3.zero
	r.Anchored = true
	local target = CFrame.lookAt(Vector3.new(pos.X, S.floatY, pos.Z), Vector3.new(pos.X, S.floatY, pos.Z) + look.Unit)
	S.model:PivotTo(target * r.CFrame:Inverse() * S.model:GetPivot())
end

local function respawn(S, why)
	for _, hum in ipairs(occupantsOf(S)) do hum.Sit = false end
	local r = S.root
	r.Anchored = true
	r.AssemblyLinearVelocity = Vector3.zero
	r.AssemblyAngularVelocity = Vector3.zero
	S.model:PivotTo(S.home)
	S.lastUsed = os.clock()
	S.model:SetAttribute("Driver", nil)
end

local function setup(model)
	if boats[model] then return end
	local root = model.PrimaryPart
	local stern = model:FindFirstChild("SternSeat", true)
	if not (root and stern) then warn("[Boats] " .. model.Name .. " needs a PrimaryPart and a SternSeat") return end

	-- the stern seat becomes the driver's seat (same look, VehicleSeat, no speed display)
	local drive = stern
	if not stern:IsA("VehicleSeat") then
		drive = Instance.new("VehicleSeat")
		for _, prop in ipairs({ "Size", "CFrame", "Color", "Material", "Transparency", "Reflectance", "CastShadow" }) do drive[prop] = stern[prop] end
		drive.TopSurface = Enum.SurfaceType.Smooth drive.BottomSurface = Enum.SurfaceType.Smooth
		for _, c in ipairs(stern:GetChildren()) do c.Parent = drive end
		drive.Name = "SternSeat"
		drive.Parent = stern.Parent
		stern:Destroy()
	end
	drive.HeadsUpDisplay = false
	drive.MaxSpeed = 0 drive.Torque = 0 drive.TurnSpeed = 0
	drive.Disabled = false
	CS:RemoveTag(drive, "PromptSeat")

	-- the bow points away from the stern
	local bowWorld = flat(root.Position - drive.Position)
	if bowWorld.Magnitude < 0.1 then bowWorld = flat(root.CFrame.LookVector) end
	bowWorld = bowWorld.Unit
	root:SetAttribute("BowLocal", root.CFrame:VectorToObjectSpace(bowWorld))
	root:SetAttribute("FloatY", root.Position.Y)
	root:SetAttribute("HomeYaw", math.atan2(-bowWorld.X, -bowWorld.Z))
	drive:SetAttribute("SC_BoatSeat", true)

	-- one rigid boat: weld everything to the keel, only the keel has mass
	local seats = { drive }
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root then
			local w = Instance.new("WeldConstraint") w.Part0 = root w.Part1 = d w.Parent = d
			d.Massless = true
			d.CanCollide = false -- the bumper below does the bumping, so the hull never snags on the lake floor
			d.Anchored = false
			if d:IsA("Seat") and d ~= drive then table.insert(seats, d) end
		end
	end
	-- invisible bumper at the water line: stops at banks, the pier and rocks (not the lake floor)
	local cf, size = model:GetBoundingBox()
	local hullLen = math.max(size.X, size.Z)
	local bumper = Instance.new("Part")
	bumper.Name = "Bumper" bumper.Transparency = 1 bumper.CanQuery = false bumper.CastShadow = false
	bumper.Massless = true
	bumper.Size = Vector3.new(3.4, 1.2, math.min(hullLen, 10.2) - 0.6)
	bumper.CFrame = CFrame.lookAt(Vector3.new(root.Position.X, root.Position.Y + 0.7, root.Position.Z), Vector3.new(root.Position.X, root.Position.Y + 0.7, root.Position.Z) + bowWorld)
	bumper.Anchored = false
	local bw = Instance.new("WeldConstraint") bw.Part0 = root bw.Part1 = bumper bw.Parent = bumper
	bumper.Parent = model
	root.CanCollide = false
	root.Massless = false

	-- the movers (driven by the driver's BoatClient)
	local att = root:FindFirstChild("BoatAtt") or Instance.new("Attachment")
	att.Name = "BoatAtt" att.Parent = root
	local lv = Instance.new("LinearVelocity")
	lv.Name = "BoatMove" lv.Attachment0 = att lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector lv.MaxForce = 1e6 lv.VectorVelocity = Vector3.zero
	lv.Parent = root
	local ao = Instance.new("AlignOrientation")
	ao.Name = "BoatTurn" ao.Mode = Enum.OrientationAlignmentMode.OneAttachment ao.Attachment0 = att
	ao.RigidityEnabled = true ao.CFrame = root.CFrame.Rotation -- rigid: never tips over, even when it bumps the bank or the pier
	ao.Parent = root
	root.Anchored = true

	local S = { model = model, root = root, drive = drive, seats = seats, home = model:GetPivot(), floatY = root.Position.Y, lastUsed = os.clock() }
	boats[model] = S

	local function onSeatChanged()
		local occ = drive.Occupant
		local p = occ and Players:GetPlayerFromCharacter(occ.Parent)
		if p then
			S.lastUsed = os.clock()
			ao.CFrame = root.CFrame.Rotation
			lv.VectorVelocity = Vector3.zero
			root.Anchored = false
			pcall(function() root:SetNetworkOwner(p) end)
			model:SetAttribute("Driver", p.UserId)
		else
			model:SetAttribute("Driver", nil)
			S.lastUsed = os.clock()
			if not root.Anchored then
				pcall(function() root:SetNetworkOwner(nil) end)
				lv.VectorVelocity = Vector3.zero
				task.delay(0.6, function() if not drive.Occupant and boats[model] then park(S) end end)
			end
		end
	end
	drive:GetPropertyChangedSignal("Occupant"):Connect(onSeatChanged)
	for _, s in ipairs(seats) do
		if s ~= drive then s:GetPropertyChangedSignal("Occupant"):Connect(function() S.lastUsed = os.clock() end) end
	end
end

for _, m in ipairs(CS:GetTagged("SC_Boat")) do task.spawn(setup, m) end
CS:GetInstanceAddedSignal("SC_Boat"):Connect(setup)

-- void / too far / left alone → back to the dock
task.spawn(function()
	while true do
		task.wait(1)
		for model, S in pairs(boats) do
			if not model.Parent then boats[model] = nil continue end
			local r = S.root
			local pos = r.Position
			if pos.Y < S.floatY - VOID_DROP or flat(pos - S.home.Position).Magnitude > MAX_DISTANCE then
				respawn(S, "void")
			elseif #occupantsOf(S) > 0 then
				S.lastUsed = os.clock()
			elseif os.clock() - S.lastUsed > IDLE_RESPAWN then
				local moved = flat(pos - S.home.Position).Magnitude > 2 or r.CFrame.LookVector:Dot(S.home.LookVector) < 0.99
				if moved then respawn(S, "idle") end
				S.lastUsed = os.clock()
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(p)
	for _, S in pairs(boats) do
		if S.model:GetAttribute("Driver") == p.UserId then S.model:SetAttribute("Driver", nil) end
	end
end)
