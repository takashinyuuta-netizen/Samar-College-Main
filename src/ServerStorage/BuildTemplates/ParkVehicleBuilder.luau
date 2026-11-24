--[[ ParkVehicleBuilder — builds the drivable parking-lot vehicles (build tool, run from the command bar / MCP).
    local B = require(game.ServerStorage.BuildTemplates.ParkVehicleBuilder)
    B.buildCar(groundCF)  -> Model   (4-door sedan, 4 seats)
    B.buildMoto(groundCF) -> Model   (underbone motorcycle, rider + backride)
  groundCF = a CFrame on the ground where the vehicle stands; the vehicle's FRONT is that CFrame's -Z.
  Physics (same proven setup as the School Bike): an anchored-when-parked root "Chassis" with invisible
  frictionless ball contacts under the wheels, a LinearVelocity "Drive" (plane) and an AlignOrientation
  "Upright". Every visible part is massless + non-colliding and welded on; wheels / steering are Motor6Ds
  that the client animates. ParkVehicleServer + VehicleClient run them. ]]
local M = {}

local BLACK = Color3.fromRGB(22, 22, 24)
local DARK = Color3.fromRGB(38, 38, 42)
local CHROME = Color3.fromRGB(205, 208, 212)
local GLASS = Color3.fromRGB(28, 38, 48)
local TIRE = Color3.fromRGB(30, 30, 32)

local O, root, model -- current build frame / root part / model

local function setMat(p, mat)
	if typeof(mat) == "string" then
		local ok = pcall(function() p.Material = Enum.Material[mat] end)
		if not ok then p.Material = Enum.Material.SmoothPlastic end
	else
		p.Material = mat or Enum.Material.SmoothPlastic
	end
end

-- make a part at LOCAL cframe lcf (relative to the ground frame O), welded to `to` (default: root)
local function mk(name, size, lcf, color, mat, opt)
	opt = opt or {}
	local p = Instance.new(opt.class or "Part")
	if opt.shape then p.Shape = opt.shape end
	p.Name = name
	p.Size = size
	p.CFrame = O * lcf
	p.Color = color
	setMat(p, mat)
	p.Reflectance = opt.refl or 0
	p.Transparency = opt.transp or 0
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = opt.shadow ~= false and size.Magnitude > 1.2
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = opt.parent or model
	local to = opt.to == nil and root or opt.to
	if to then
		local w = Instance.new("WeldConstraint")
		w.Part0 = to w.Part1 = p w.Parent = p
	end
	return p
end
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local function V(x, y, z) return Vector3.new(x, y, z) end
local function C(x, y, z) return CFrame.new(x, y, z) end
local ZAXIS = CFrame.Angles(0, math.rad(90), 0)   -- cylinder axis along Z
local YAXIS = CFrame.Angles(0, 0, math.rad(90))   -- cylinder axis along Y

-- a rod (cylinder) between two LOCAL points
local function rod(name, a, b, dia, color, mat, opt)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b) * ZAXIS
	return mk(name, V(len, dia, dia), cf, color, mat, (function() opt = opt or {} opt.shape = CYL return opt end)())
end
-- a block between two LOCAL points
local function bar(name, a, b, w, h, color, mat, opt)
	return mk(name, V(w, h, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), color, mat, opt)
end
-- a ring of blocks (half or partial) in the local Z-Y plane around centre c, at side x
-- angles in degrees: 0 = toward +Z (back), 90 = up, 180 = toward -Z (front)
local function arc(name, c, rIn, rOut, a0, a1, segs, thick, color, mat, opt)
	local step = (a1 - a0) / segs
	for i = 0, segs - 1 do
		local am = math.rad(a0 + step * (i + 0.5))
		local dir = V(0, math.sin(am), math.cos(am))
		local pos = c + dir * ((rIn + rOut) / 2)
		local tang = 2 * rOut * math.tan(math.rad(step) / 2) + 0.03
		mk(name, V(thick, rOut - rIn, tang), CFrame.fromMatrix(pos, V(1, 0, 0), dir), color, mat, opt)
	end
end
local function textGui(part, face, text, color, bg, font, pxW, pxH)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face sg.CanvasSize = Vector2.new(pxW or 200, pxH or 60) sg.LightInfluence = 0.5 sg.MaxDistance = 70
	sg.Parent = part
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = bg and 0 or 1 t.BackgroundColor3 = bg or Color3.new(1, 1, 1)
	t.Font = font or Enum.Font.GothamBlack t.TextScaled = true t.TextColor3 = color t.Text = text
	t.Parent = sg
	return t
end

local function newModel(name, groundCF, kind)
	O = groundCF
	model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("ParkVehicle", kind)
end
local function makeRoot(lpos, density)
	root = Instance.new("Part")
	root.Name = "Chassis"
	root.Size = V(1, 1, 1)
	root.CFrame = O * C(lpos.X, lpos.Y, lpos.Z)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.CollisionGroup = "BikeBody"
	root.RootPriority = 127
	root.CustomPhysicalProperties = PhysicalProperties.new(density, 0, 0, 100, 1)
	root.Parent = model
	model.PrimaryPart = root
	local att = Instance.new("Attachment") att.Name = "DriveAtt" att.Parent = root
	local lv = Instance.new("LinearVelocity")
	lv.Name = "Drive" lv.Attachment0 = att
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	lv.PrimaryTangentAxis = V(1, 0, 0) lv.SecondaryTangentAxis = V(0, 0, 1)
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	lv.MaxForce = 120000
	lv.PlaneVelocity = Vector2.zero
	lv.Parent = root
	local ao = Instance.new("AlignOrientation")
	ao.Name = "Upright" ao.Mode = Enum.OrientationAlignmentMode.OneAttachment ao.Attachment0 = att
	ao.MaxTorque = 5e6 ao.Responsiveness = 22 ao.RigidityEnabled = false
	local _, yaw = O:ToEulerAnglesYXZ()
	ao.CFrame = CFrame.Angles(0, yaw, 0)
	ao.Parent = root
end
-- invisible frictionless contact ball under a wheel + collision hull pieces
local function contact(name, lpos, dia)
	local p = mk(name, V(dia, dia, dia), C(lpos.X, lpos.Y, lpos.Z), DARK, nil, { shape = BALL, transp = 1, shadow = false })
	p.CanCollide = true p.CanQuery = false p.Massless = false
	p.CollisionGroup = "BikeBody"
	p.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0, 100, 1)
	return p
end
local function hull(name, size, lcf)
	local p = mk(name, size, lcf, DARK, nil, { transp = 1, shadow = false })
	p.CanCollide = true p.CanQuery = true -- queryable so tapping the vehicle works
	p.CollisionGroup = "BikeBody"
	return p
end
-- a wheel hub (Motor6D to `parent`) + detailed wheel welded to it
local function wheel(name, lpos, r, w, side, parentPart, style)
	local hub = Instance.new("Part")
	hub.Name = name hub.Size = V(0.2, 0.2, 0.2) hub.CFrame = O * C(lpos.X, lpos.Y, lpos.Z)
	hub.Transparency = 1 hub.CanCollide = false hub.CanTouch = false hub.CanQuery = false hub.Massless = true hub.Anchored = false
	hub.Parent = model
	local m6 = Instance.new("Motor6D")
	m6.Name = name .. "Motor" m6.Part0 = parentPart m6.Part1 = hub
	m6.C0 = parentPart.CFrame:ToObjectSpace(hub.CFrame) m6.C1 = CFrame.identity
	m6.Parent = parentPart
	local function W(n, size, off, color, mat, opt)
		opt = opt or {} opt.to = hub
		return mk(n, size, C(lpos.X, lpos.Y, lpos.Z) * off, color, mat, opt)
	end
	-- tyre: body, 3 tread grooves, sidewall
	W("Tyre", V(w, r * 2, r * 2), CFrame.identity, TIRE, "Rubber", { shape = CYL })
	for _, gx in ipairs({ -0.28, 0, 0.28 }) do
		W("Tread", V(0.05, r * 2 + 0.03, r * 2 + 0.03), C(gx * w, 0, 0), Color3.fromRGB(16, 16, 17), "Rubber", { shape = CYL, shadow = false })
	end
	local rimR = r * 0.66
	local rimCol = style == "moto" and Color3.fromRGB(205, 160, 40) or Color3.fromRGB(190, 194, 200)
	-- motorcycle wheels are seen from both sides: dress both faces
	for _, fs in ipairs(style == "moto" and { -1, 1 } or { side }) do
	local side = fs
	local outer = side * (w / 2)
	-- everything on the wheel face is stacked slightly OUTSIDE the tyre face so it shows
	W("Sidewall", V(0.02, r * 1.9, r * 1.9), C(outer + side * 0.005, 0, 0), Color3.fromRGB(44, 44, 46), "Rubber", { shape = CYL, shadow = false })
	-- rim: bright lip ring, dark inner face, spokes, centre cap, lug nuts
	W("RimLip", V(0.02, rimR * 2 + 0.08, rimR * 2 + 0.08), C(outer + side * 0.02, 0, 0), CHROME, "Metal", { shape = CYL, refl = 0.25, shadow = false })
	W("RimFace", V(0.02, rimR * 1.82, rimR * 1.82), C(outer + side * 0.035, 0, 0), Color3.fromRGB(26, 26, 28), "Metal", { shape = CYL, shadow = false })
	local spokes = 5
	for i = 1, spokes do
		local a = (i / spokes) * math.pi * 2
		for _, tw in ipairs(style == "moto" and { 0 } or { -0.16, 0.16 }) do
			W("Spoke", V(0.04, 0.14, rimR * 0.92), CFrame.Angles(a + tw, 0, 0) * C(outer + side * 0.068, 0, -rimR * 0.5), rimCol, "Metal", { refl = 0.15, shadow = false })
		end
	end
	-- brake disc seen between the spokes
	W("BrakeDisc", V(0.02, rimR * 1.45, rimR * 1.45), C(outer + side * 0.042, 0, 0), Color3.fromRGB(125, 127, 131), "Metal", { shape = CYL, shadow = false })
	W("DiscHat", V(0.02, rimR * 0.8, rimR * 0.8), C(outer + side * 0.047, 0, 0), Color3.fromRGB(70, 72, 76), "Metal", { shape = CYL, shadow = false })
	W("CentreCap", V(0.06, rimR * 0.48, rimR * 0.48), C(outer + side * 0.07, 0, 0), CHROME, "Metal", { shape = CYL, refl = 0.3, shadow = false })
	W("CapLogo", V(0.02, rimR * 0.26, rimR * 0.26), C(outer + side * 0.1, 0, 0), Color3.fromRGB(0, 130, 75), "SmoothPlastic", { shape = CYL, shadow = false })
	for i = 1, 5 do
		local a = (i / 5) * math.pi * 2 + 0.3
		W("LugNut", V(0.05, 0.08, 0.08), CFrame.Angles(a, 0, 0) * C(outer + side * 0.08, 0, -rimR * 0.34), CHROME, "Metal", { shape = CYL, shadow = false })
	end
	end
	return hub, m6
end
local function caliper(lpos, r, w, side, to, color)
	local rimR = r * 0.66
	mk("BrakeCaliper", V(0.025, 0.36, 0.3), C(lpos.X + side * (w / 2 + 0.052), lpos.Y + rimR * 0.5, lpos.Z + rimR * 0.45) * CFrame.Angles(math.rad(-45), 0, 0), color or Color3.fromRGB(200, 30, 34), "SmoothPlastic", { to = to, shadow = false })
end
local function seat(cls, name, lpos, size, exitOff)
	local s = mk(name, size, C(lpos.X, lpos.Y, lpos.Z), DARK, nil, { class = cls, transp = 1, shadow = false })
	s.CanTouch = false -- seats only work through the prompt (no accidental sitting)
	s.Disabled = true
	if cls == "VehicleSeat" then s.MaxSpeed = 0 s.Torque = 0 s.TurnSpeed = 0 s.HeadsUpDisplay = false end
	s:SetAttribute("ExitOffset", exitOff)
	return s
end
-- one prompt per side: it seats you in the first FREE seat of `seatList` (driver first) and the server keeps
-- its label right ("Drive" while the driver seat is free, then "Ride")
local function prompt(attName, lpos, action, object, seatList)
	local a = Instance.new("Attachment")
	a.Name = attName
	a.Parent = root
	a.WorldPosition = (O * C(lpos.X, lpos.Y, lpos.Z)).Position
	local p = Instance.new("ProximityPrompt")
	p.Name = "EnterPrompt" p.ActionText = action p.ObjectText = object
	p.KeyboardKeyCode = Enum.KeyCode.E p.HoldDuration = 0 p.MaxActivationDistance = 7
	p.RequiresLineOfSight = false p.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	p:SetAttribute("KeepE", true)
	p:SetAttribute("Seats", seatList)
	p.Parent = a
	return p
end
local function sound(name, id, vol, looped, maxD)
	local s = Instance.new("Sound")
	s.Name = name s.SoundId = "rbxassetid://" .. id s.Volume = vol s.Looped = looped
	s.RollOffMode = Enum.RollOffMode.InverseTapered s.RollOffMinDistance = 8 s.RollOffMaxDistance = maxD or 90
	s.Parent = root
	return s
end
local function plate(name, size, lcf, text, face)
	local p = mk(name, size, lcf, Color3.fromRGB(245, 245, 240), "SmoothPlastic", { shadow = false })
	local sg = Instance.new("SurfaceGui") sg.Face = face sg.CanvasSize = Vector2.new(300, 90) sg.LightInfluence = 0.6 sg.MaxDistance = 60 sg.Parent = p
	local top = Instance.new("TextLabel") top.Size = UDim2.fromScale(1, 0.26) top.BackgroundTransparency = 1
	top.Font = Enum.Font.GothamBold top.TextScaled = true top.TextColor3 = Color3.fromRGB(0, 120, 70) top.Text = "SAMAR • PILIPINAS" top.Parent = sg
	local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 0.74) t.Position = UDim2.fromScale(0, 0.26) t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBlack t.TextScaled = true t.TextColor3 = Color3.fromRGB(20, 20, 24) t.Text = text t.Parent = sg
	local st = Instance.new("UIStroke") st.Thickness = 3 st.Color = Color3.fromRGB(20, 20, 24) st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local fr = Instance.new("Frame") fr.Size = UDim2.fromScale(1, 1) fr.BackgroundTransparency = 1 fr.Parent = sg st.Parent = fr
	return p
end

----------------------------------------------------------------------------------------------------------- CAR
-- 4-door sedan. ~12.3 long, 6 wide, 5.1 tall. Wheels R 1.25 at z = -3.75 / +3.75, x = +-2.45. LHD (driver on the left).
function M.buildCar(groundCF, opts)
	opts = opts or {}
	local PAINT = opts.paint or Color3.fromRGB(26, 64, 128)
	local PAINT_D = PAINT:Lerp(Color3.new(0, 0, 0), 0.25)
	local INT = Color3.fromRGB(44, 44, 48)
	local LEATHER = Color3.fromRGB(150, 128, 104)
	local function paint(n, size, lcf, opt) opt = opt or {} opt.refl = opt.refl or 0.06 return mk(n, size, lcf, PAINT, "SmoothPlastic", opt) end
	newModel(opts.name or "ParkCar", groundCF, "Car")
	makeRoot(V(0, 1.25, 0), 2)
	local R, AX, FZ, RZ, TX = 1.25, 1.25, -3.75, 3.75, 2.45
	model:SetAttribute("MaxSpeed", 46) model:SetAttribute("Reverse", 14) model:SetAttribute("Accel", 13)
	model:SetAttribute("Brake", 42) model:SetAttribute("Coast", 6) model:SetAttribute("Wheelbase", 7.5)
	model:SetAttribute("MaxSteer", 32) model:SetAttribute("WheelR", R) model:SetAttribute("DisplayName", "Car")

	-- physics: 4 contacts + hull
	for _, s in ipairs({ -1, 1 }) do
		contact(s < 0 and "ContactFL" or "ContactFR", V(s * TX, AX, FZ), R * 2)
		contact(s < 0 and "ContactRL" or "ContactRR", V(s * TX, AX, RZ), R * 2)
	end
	hull("Hull", V(5.9, 2.25, 12.2), C(0, 2.05, 0))
	hull("HullCabin", V(5.1, 1.75, 5.7), C(0, 4.05, 1.4))

	-- underbody / cores (hidden fill so you never look through the body)
	mk("Floorpan", V(5.5, 0.25, 11.8), C(0, 0.9, 0), DARK)
	mk("EngineBay", V(5.3, 1.9, 3.6), C(0, 2.0, -4.25), Color3.fromRGB(30, 30, 33))
	mk("TrunkCore", V(5.3, 1.95, 1.9), C(0, 2.05, 5.0), Color3.fromRGB(30, 30, 33))

	-- SIDES (both): bumper ends, wheel arches, doors, skirts, liners
	for _, s in ipairs({ -1, 1 }) do
		local x = s * 2.85
		paint("FrontQuarter", V(0.3, 2.2, 0.8), C(x, 1.95, -5.65))
		paint("RearQuarter", V(0.3, 2.2, 0.8), C(x, 1.95, 5.65))
		paint("DoorPanels", V(0.3, 2.2, 4.5), C(x, 1.95, 0))
		for _, cz in ipairs({ FZ, RZ }) do
			arc("Fender", V(x, AX, cz), 1.45, 1.8, 0, 180, 9, 0.3, PAINT, "SmoothPlastic", { refl = 0.06 })
			for _, d in ipairs({ -1, 1 }) do paint("FenderFill", V(0.3, 0.75, 0.45), C(x, 2.675, cz + d * 1.275)) end
			arc("ArchLip", V(x + s * 0.03, AX, cz), 1.42, 1.56, 0, 180, 9, 0.3, BLACK, "SmoothPlastic")
			-- wheel-well liner: only the arch ABOVE the tyre (a full disc looked like a second tyre)
			arc("WheelWell", V(s * 2.05, AX, cz), 1.32, 1.46, 0, 180, 9, 1.4, Color3.fromRGB(14, 14, 15), "SmoothPlastic", { shadow = false })
			mk("MudFlap", V(0.5, 0.55, 0.08), C(s * 2.5, 0.55, cz + 1.5), BLACK, "Rubber")
		end
		mk("SideSkirt", V(0.36, 0.22, 4.5), C(x + s * 0.02, 0.95, 0), BLACK, "SmoothPlastic")
		-- door seams + handles + beltline chrome
		for _, z in ipairs({ -2.22, 0.98, 2.22 }) do mk("DoorSeam", V(0.32, 2.05, 0.04), C(x, 2.0, z), PAINT_D, "SmoothPlastic", { shadow = false }) end
		mk("DoorSeamLow", V(0.32, 0.04, 4.5), C(x, 1.02, 0), PAINT_D, "SmoothPlastic", { shadow = false })
		for _, z in ipairs({ 0.55, 1.95 }) do
			mk("HandleRecess", V(0.02, 0.2, 0.6), C(x + s * 0.155, 2.7, z), PAINT_D, "SmoothPlastic", { shadow = false })
			mk("DoorHandle", V(0.08, 0.12, 0.5), C(x + s * 0.19, 2.7, z), CHROME, "Metal", { refl = 0.3, shadow = false })
		end
		mk("BeltChrome", V(0.12, 0.06, 7.45), C(s * 2.74, 3.08, 1.6), CHROME, "Metal", { refl = 0.3, shadow = false })
		mk("BeltCap", V(0.3, 0.05, 7.45), C(x, 3.075, 1.6), PAINT, "SmoothPlastic", { refl = 0.06, shadow = false })
		mk("BodyCrease", V(0.31, 0.05, 4.5), C(x + s * 0.005, 2.45, 0), PAINT_D, "SmoothPlastic", { shadow = false })
		-- windows: front door (rect + wedge), B-pillar, rear door, quarter glass, frame
		local gx = s * 2.62
		local g = { transp = 0.42, refl = 0.12, shadow = false }
		mk("WindowFront", V(0.08, 1.85, 1.05), C(gx, 3.975, 0.425), GLASS, "Glass", table.clone(g))
		mk("WindowFrontTri", V(0.08, 1.85, 2.05), C(gx, 3.975, -1.125), GLASS, "Glass", (function() local t = table.clone(g) t.class = "WedgePart" return t end)())
		mk("WindowRear", V(0.08, 1.85, 2.65), C(gx, 3.975, 2.475), GLASS, "Glass", table.clone(g))
		mk("WindowQuarter", V(0.08, 1.85, 1.55), C(gx, 3.975, 4.575) * CFrame.Angles(0, math.pi, 0), GLASS, "Glass", (function() local t = table.clone(g) t.class = "WedgePart" return t end)())
		mk("BPillar", V(0.16, 1.9, 0.24), C(gx, 3.98, 1.05), BLACK, "SmoothPlastic")
		mk("CPillarSplit", V(0.16, 1.9, 0.14), C(gx, 3.98, 3.8), BLACK, "SmoothPlastic")
		mk("WindowFrameTop", V(0.12, 0.08, 3.95), C(s * 2.6, 4.92, 1.85), BLACK, "SmoothPlastic", { shadow = false })
		-- door inner trim (seen through the glass)
		mk("DoorTrimInner", V(0.1, 1.95, 6.0), C(s * 2.64, 2.05, 0.9), INT, "Fabric", { shadow = false })
		mk("ArmRest", V(0.3, 0.14, 4.0), C(s * 2.5, 2.4, 1.1), LEATHER, "Leather", { shadow = false })
		-- side mirror
		mk("MirrorArm", V(0.38, 0.12, 0.26), C(s * 3.08, 3.25, -1.85), BLACK, "SmoothPlastic")
		paint("MirrorHousing", V(0.62, 0.42, 0.3), C(s * 3.42, 3.38, -1.85))
		mk("MirrorGlass", V(0.5, 0.32, 0.03), C(s * 3.42, 3.38, -1.69), Color3.fromRGB(190, 205, 215), "Glass", { refl = 0.5, shadow = false })
		mk("MirrorSignal", V(0.42, 0.05, 0.04), C(s * 3.45, 3.2, -1.99), Color3.fromRGB(255, 160, 30), "Glass", { shadow = false })
	end
	-- fuel door (right rear)
	mk("FuelDoor", V(0.02, 0.45, 0.45), C(3.01, 2.55, 5.6), PAINT_D, "SmoothPlastic", { shadow = false })

	-- HOOD + FRONT
	paint("Hood", V(5.7, 0.2, 3.95), C(0, 2.95, -4.1) * CFrame.Angles(-0.052, 0, 0))
	for _, hx in ipairs({ -1.35, 1.35 }) do mk("HoodCrease", V(0.05, 0.03, 3.7), C(hx, 3.06, -4.05) * CFrame.Angles(-0.052, 0, 0), PAINT_D, "SmoothPlastic", { shadow = false }) end
	paint("HoodNose", V(5.7, 0.24, 0.24), C(0, 2.84, -6.0), { shape = CYL })
	paint("NosePanel", V(5.95, 0.85, 0.3), C(0, 2.45, -5.95))
	paint("FrontBumper", V(5.95, 0.95, 0.42), C(0, 1.5, -5.95))
	for _, s in ipairs({ -1, 1 }) do
		paint("BumperCorner", V(1.9, 0.9, 0.9), C(s * 2.6, 1.95, -5.85) * YAXIS, { shape = CYL })
		-- headlight: chrome bezel, clear lens, projector (light source), LED DRL
		mk("HeadlightBezel", V(1.45, 0.5, 0.14), C(s * 2.0, 2.5, -6.08), Color3.fromRGB(60, 62, 66), "Metal", { refl = 0.2 })
		mk("HeadlightLens", V(1.35, 0.42, 0.06), C(s * 2.0, 2.5, -6.17), Color3.fromRGB(215, 228, 240), "Glass", { transp = 0.35, refl = 0.2, shadow = false })
		local lamp = mk("HeadLamp", V(0.34, 0.34, 0.34), C(s * 2.3, 2.52, -6.12), Color3.fromRGB(240, 240, 230), "Glass", { shape = BALL, shadow = false })
		local sl = Instance.new("SpotLight") sl.Face = Enum.NormalId.Front sl.Angle = 55 sl.Range = 40 sl.Brightness = 1.3
		sl.Color = Color3.fromRGB(255, 244, 225) sl.Shadows = false sl.Enabled = false sl.Parent = lamp
		mk("HeadLampLow", V(0.26, 0.26, 0.26), C(s * 1.75, 2.52, -6.12), Color3.fromRGB(230, 230, 222), "Glass", { shape = BALL, shadow = false })
		mk("DRL", V(1.15, 0.07, 0.05), C(s * 1.95, 2.32, -6.19), Color3.fromRGB(235, 245, 255), "Neon", { shadow = false })
		mk("TurnFront", V(0.3, 0.12, 0.05), C(s * 2.55, 2.32, -6.19), Color3.fromRGB(255, 160, 30), "Glass", { shadow = false })
		-- fog lamp
		mk("FogBezel", V(0.08, 0.42, 0.42), C(s * 2.25, 1.3, -6.17) * ZAXIS, BLACK, "SmoothPlastic", { shape = CYL, shadow = false })
		mk("FogLamp", V(0.06, 0.3, 0.3), C(s * 2.25, 1.3, -6.21) * ZAXIS, Color3.fromRGB(240, 235, 210), "Glass", { shape = CYL, shadow = false })
	end
	mk("Grille", V(2.6, 0.58, 0.12), C(0, 2.45, -6.12), BLACK, "SmoothPlastic")
	for _, y in ipairs({ 2.28, 2.42, 2.56 }) do mk("GrilleSlat", V(2.5, 0.05, 0.05), C(0, y, -6.19), CHROME, "Metal", { refl = 0.3, shadow = false }) end
	mk("GrilleSurround", V(2.7, 0.06, 0.06), C(0, 2.76, -6.17), CHROME, "Metal", { refl = 0.3, shadow = false })
	local emblem = mk("Emblem", V(0.06, 0.42, 0.42), C(0, 2.45, -6.22) * ZAXIS, CHROME, "Metal", { shape = CYL, refl = 0.3, shadow = false })
	mk("EmblemCore", V(0.06, 0.3, 0.3), C(0, 2.45, -6.24) * ZAXIS, Color3.fromRGB(0, 120, 70), "SmoothPlastic", { shape = CYL, shadow = false })
	mk("LowerIntake", V(3.3, 0.3, 0.1), C(0, 1.18, -6.17), BLACK, "SmoothPlastic", { shadow = false })
	for _, xx in ipairs({ -1.2, -0.4, 0.4, 1.2 }) do mk("IntakeFin", V(0.05, 0.3, 0.06), C(xx, 1.18, -6.21), Color3.fromRGB(60, 60, 64), "SmoothPlastic", { shadow = false }) end
	mk("FrontLip", V(5.6, 0.12, 0.5), C(0, 0.98, -5.95), BLACK, "SmoothPlastic")
	plate("PlateFront", V(1.5, 0.42, 0.05), C(0, 1.6, -6.2), "SCB 2026", Enum.NormalId.Front)
	mk("Cowl", V(5.3, 0.12, 0.35), C(0, 3.1, -2.1), BLACK, "SmoothPlastic", { shadow = false })
	for _, wx in ipairs({ -1.0, 1.1 }) do mk("Wiper", V(1.9, 0.05, 0.07), C(wx, 3.18, -2.0) * CFrame.Angles(0, math.rad(-6), 0), BLACK, "SmoothPlastic", { shadow = false }) end

	-- GLASSHOUSE: windshield, A/C pillars, roof, sunroof, antenna, rear window
	local ws0, ws1 = V(0, 3.05, -2.15), V(0, 4.92, -0.1)
	bar("Windshield", ws0, ws1, 5.05, 0.08, GLASS, "Glass", { transp = 0.4, refl = 0.15, shadow = false })
	local rw0, rw1 = V(0, 4.92, 3.8), V(0, 3.15, 5.35)
	bar("RearWindow", rw0, rw1, 5.05, 0.08, GLASS, "Glass", { transp = 0.4, refl = 0.15, shadow = false })
	for _, s in ipairs({ -1, 1 }) do
		bar("APillar", ws0 + V(s * 2.58, 0, 0), ws1 + V(s * 2.58, 0, 0), 0.2, 0.2, BLACK, "SmoothPlastic")
		bar("CPillar", rw0 + V(s * 2.56, 0, 0), rw1 + V(s * 2.56, 0, 0), 0.24, 0.24, PAINT, "SmoothPlastic", { refl = 0.06 })
	end
	paint("Roof", V(5.1, 0.18, 4.0), C(0, 5.0, 1.85))
	mk("Sunroof", V(3.2, 0.04, 2.0), C(0, 5.1, 1.6), Color3.fromRGB(12, 14, 18), "Glass", { refl = 0.25, shadow = false })
	mk("SharkFin", V(0.18, 0.3, 0.65), C(0, 5.24, 3.45), BLACK, "SmoothPlastic", { class = "WedgePart", shadow = false })
	mk("Headliner", V(4.9, 0.05, 3.9), C(0, 4.88, 1.85), Color3.fromRGB(150, 146, 140), "Fabric", { shadow = false })
	local b3 = bar("BrakeLight3", rw0 + V(0, -0.12, 0.12), rw0 + V(0, -0.16, 0.17), 1.1, 0.08, Color3.fromRGB(110, 10, 12), "Glass", { shadow = false })
	b3.Size = V(1.1, 0.07, 0.06)

	-- TRUNK + REAR
	paint("TrunkLid", V(5.6, 0.2, 0.85), C(0, 3.12, 5.72))
	paint("Spoiler", V(5.0, 0.1, 0.32), C(0, 3.27, 6.0) * CFrame.Angles(math.rad(10), 0, 0))
	paint("RearPanel", V(5.95, 0.95, 0.3), C(0, 2.55, 5.95))
	paint("RearBumper", V(5.95, 0.95, 0.42), C(0, 1.5, 5.95))
	for _, s in ipairs({ -1, 1 }) do
		paint("BumperCorner", V(1.9, 0.9, 0.9), C(s * 2.6, 1.95, 5.85) * YAXIS, { shape = CYL })
		mk("TailHousing", V(1.5, 0.48, 0.14), C(s * 2.15, 2.68, 6.1), Color3.fromRGB(70, 8, 10), "Glass", { transp = 0.1, refl = 0.15 })
		local bl = mk("BrakeLight", V(1.25, 0.18, 0.05), C(s * 2.2, 2.75, 6.17), Color3.fromRGB(110, 10, 12), "Glass", { shadow = false })
		local tl = Instance.new("SurfaceLight") tl.Face = Enum.NormalId.Back tl.Color = Color3.fromRGB(255, 40, 40) tl.Range = 8 tl.Brightness = 0.6 tl.Angle = 120 tl.Enabled = false tl.Parent = bl
		mk("ReverseLight", V(0.38, 0.14, 0.05), C(s * 1.68, 2.55, 6.17), Color3.fromRGB(200, 200, 200), "Glass", { shadow = false })
		mk("TurnRear", V(0.36, 0.12, 0.05), C(s * 2.62, 2.55, 6.17), Color3.fromRGB(255, 150, 30), "Glass", { shadow = false })
		mk("Reflector", V(0.5, 0.1, 0.05), C(s * 2.25, 1.55, 6.17), Color3.fromRGB(150, 15, 15), "Glass", { shadow = false })
	end
	mk("TrunkGarnish", V(2.5, 0.12, 0.06), C(0, 2.7, 6.12), CHROME, "Metal", { refl = 0.3, shadow = false })
	mk("EmblemRear", V(0.06, 0.34, 0.34), C(0, 2.92, 6.12) * ZAXIS, CHROME, "Metal", { shape = CYL, refl = 0.3, shadow = false })
	local badge = mk("Badge", V(0.9, 0.2, 0.02), C(1.55, 2.95, 6.11), CHROME, "Metal", { shadow = false })
	textGui(badge, Enum.NormalId.Back, "SAMAR", Color3.fromRGB(235, 238, 240), nil, Enum.Font.GothamBold, 200, 44)
	plate("PlateRear", V(1.5, 0.42, 0.05), C(0, 1.6, 6.2), "SCB 2026", Enum.NormalId.Back)
	mk("Diffuser", V(4.6, 0.28, 0.36), C(0, 1.0, 6.0), BLACK, "SmoothPlastic")
	for _, xx in ipairs({ -1.2, -0.4, 0.4, 1.2 }) do mk("DiffuserFin", V(0.05, 0.28, 0.4), C(xx, 0.9, 6.05), Color3.fromRGB(50, 50, 54), "SmoothPlastic", { shadow = false }) end
	mk("ExhaustTip", V(0.45, 0.34, 0.34), C(1.75, 0.98, 6.06) * ZAXIS, CHROME, "Metal", { shape = CYL, refl = 0.3 })
	mk("ExhaustHole", V(0.05, 0.24, 0.24), C(1.75, 0.98, 6.29) * ZAXIS, BLACK, "SmoothPlastic", { shape = CYL, shadow = false })
	rod("ExhaustPipe", V(1.75, 0.85, 5.8), V(0.9, 0.82, -1.0), 0.22, Color3.fromRGB(90, 90, 94), "Metal")

	-- INTERIOR
	mk("Carpet", V(5.2, 0.1, 5.9), C(0, 1.05, 1.0), Color3.fromRGB(30, 30, 33), "Fabric", { shadow = false })
	for _, s in ipairs({ -1, 1 }) do
		local sx = s * 1.25
		mk("SeatBase", V(1.8, 0.5, 1.8), C(sx, 1.35, 0.55), INT, "Leather")
		mk("SeatInsert", V(1.2, 0.05, 1.5), C(sx, 1.61, 0.55), LEATHER, "Leather", { shadow = false })
		for _, bx in ipairs({ -0.78, 0.78 }) do mk("Bolster", V(0.26, 0.28, 1.7), C(sx + bx, 1.68, 0.55), INT, "Leather", { shadow = false }) end
		mk("SeatBack", V(1.8, 2.2, 0.42), C(sx, 2.65, 1.6) * CFrame.Angles(0.2, 0, 0), INT, "Leather")
		mk("SeatBackInsert", V(1.2, 1.7, 0.05), C(sx, 2.6, 1.38) * CFrame.Angles(0.2, 0, 0), LEATHER, "Leather", { shadow = false })
		mk("Headrest", V(1.0, 0.55, 0.32), C(sx, 4.05, 1.93) * CFrame.Angles(0.2, 0, 0), INT, "Leather")
		mk("SunVisor", V(1.6, 0.06, 0.6), C(sx, 4.8, -0.15), Color3.fromRGB(150, 146, 140), "Fabric", { shadow = false })
	end
	mk("RearBench", V(4.7, 0.5, 1.6), C(0, 1.35, 3.25), INT, "Leather")
	mk("RearBenchInsert", V(4.2, 0.05, 1.3), C(0, 1.61, 3.25), LEATHER, "Leather", { shadow = false })
	mk("RearBack", V(4.7, 2.0, 0.42), C(0, 2.5, 4.2) * CFrame.Angles(0.26, 0, 0), INT, "Leather")
	for _, hx in ipairs({ -1.4, 1.4 }) do mk("RearHeadrest", V(0.95, 0.45, 0.3), C(hx, 3.7, 4.55) * CFrame.Angles(0.26, 0, 0), INT, "Leather") end
	mk("ParcelShelf", V(4.9, 0.08, 0.9), C(0, 3.12, 4.95), Color3.fromRGB(30, 30, 33), "Fabric", { shadow = false })
	mk("Dashboard", V(5.2, 0.85, 1.1), C(0, 2.75, -1.85), INT, "SmoothPlastic")
	mk("DashTop", V(5.2, 0.12, 1.25), C(0, 3.2, -1.85), Color3.fromRGB(30, 30, 33), "Leather", { shadow = false })
	mk("DashTrim", V(5.0, 0.08, 0.04), C(0, 2.95, -1.29), CHROME, "Metal", { refl = 0.2, shadow = false })
	mk("GaugeHood", V(1.5, 0.32, 0.55), C(-1.25, 3.36, -1.55), Color3.fromRGB(26, 26, 28), "SmoothPlastic", { shadow = false })
	local gauge = mk("Gauge", V(1.25, 0.5, 0.04), C(-1.25, 3.05, -1.3), Color3.fromRGB(8, 10, 14), "SmoothPlastic", { shadow = false })
	local gt = textGui(gauge, Enum.NormalId.Back, "0", Color3.fromRGB(120, 230, 255), Color3.fromRGB(8, 10, 14), Enum.Font.GothamBlack, 250, 100)
	gt.Name = "Speed"
	local screen = mk("InfoScreen", V(1.1, 0.65, 0.05), C(0, 3.0, -1.31), Color3.fromRGB(8, 10, 14), "SmoothPlastic", { shadow = false })
	local st = textGui(screen, Enum.NormalId.Back, "SAMAR COLLEGE\n♪ Campus FM", Color3.fromRGB(80, 220, 150), Color3.fromRGB(8, 14, 12), Enum.Font.GothamBold, 220, 130)
	st.Name = "Info"
	for _, vx in ipairs({ -2.2, -0.75, 0.75, 2.2 }) do mk("AirVent", V(0.5, 0.2, 0.05), C(vx, 2.68, -1.29), Color3.fromRGB(70, 72, 76), "Metal", { shadow = false }) end
	mk("Glovebox", V(1.6, 0.04, 0.04), C(1.25, 2.55, -1.29), Color3.fromRGB(20, 20, 22), "SmoothPlastic", { shadow = false })
	mk("Console", V(0.75, 0.62, 2.3), C(0, 1.4, 0.25), INT, "SmoothPlastic")
	mk("ConsoleStack", V(0.75, 0.9, 0.5), C(0, 2.0, -1.05), INT, "SmoothPlastic")
	rod("GearLever", V(0, 1.7, -0.2), V(0, 2.15, -0.28), 0.08, CHROME, "Metal")
	mk("GearKnob", V(0.22, 0.22, 0.22), C(0, 2.2, -0.29), Color3.fromRGB(20, 20, 22), "Leather", { shape = BALL, shadow = false })
	mk("Handbrake", V(0.14, 0.12, 0.7), C(0, 1.78, 0.5) * CFrame.Angles(0.25, 0, 0), Color3.fromRGB(20, 20, 22), "Leather", { shadow = false })
	mk("CupHolder", V(0.05, 0.26, 0.26), C(0, 1.72, 1.0) * YAXIS, BLACK, "SmoothPlastic", { shape = CYL, shadow = false })
	rod("MirrorStem", V(0, 4.88, -0.15), V(0, 4.62, -0.3), 0.06, BLACK, "SmoothPlastic")
	mk("RearViewMirror", V(0.85, 0.24, 0.07), C(0, 4.55, -0.3), BLACK, "SmoothPlastic", { shadow = false })
	mk("RearViewGlass", V(0.78, 0.18, 0.02), C(0, 4.55, -0.26), Color3.fromRGB(190, 205, 215), "Glass", { refl = 0.5, shadow = false })
	-- steering wheel on its own hub (the client turns it)
	local wc = V(-1.25, 3.05, -0.85)
	local sd = V(0, 0.42, 1).Unit
	local hubCF = CFrame.lookAt(wc, wc + sd) -- hub -Z points at the driver
	local sHub = Instance.new("Part")
	sHub.Name = "SteerHub" sHub.Size = V(0.2, 0.2, 0.2) sHub.CFrame = O * hubCF sHub.Transparency = 1
	sHub.CanCollide = false sHub.CanTouch = false sHub.CanQuery = false sHub.Massless = true sHub.Parent = model
	local sm = Instance.new("Motor6D") sm.Name = "SteerMotor" sm.Part0 = root sm.Part1 = sHub
	sm.C0 = root.CFrame:ToObjectSpace(sHub.CFrame) sm.Parent = root
	local RIM = 0.62
	for i = 0, 13 do
		local a = i / 14 * math.pi * 2
		mk("WheelRim", V(0.12, 0.3, 0.12), hubCF * CFrame.Angles(0, 0, a) * C(RIM, 0, 0), Color3.fromRGB(26, 26, 28), "Leather", { to = sHub, shadow = false })
	end
	for _, a in ipairs({ 0, math.pi, math.pi * 1.5 }) do
		mk("WheelSpoke", V(RIM, 0.12, 0.06), hubCF * CFrame.Angles(0, 0, a) * C(RIM / 2, 0, 0), Color3.fromRGB(60, 62, 66), "Metal", { to = sHub, shadow = false })
	end
	mk("WheelPad", V(0.45, 0.4, 0.14), hubCF * C(0, 0, -0.04), Color3.fromRGB(26, 26, 28), "Leather", { to = sHub, shadow = false })
	mk("WheelLogo", V(0.16, 0.16, 0.02), hubCF * C(0, 0, -0.12), Color3.fromRGB(0, 140, 80), "SmoothPlastic", { to = sHub, shadow = false })
	rod("SteerColumn", wc + sd * 0.1, wc - sd * 0.75, 0.2, Color3.fromRGB(26, 26, 28), "SmoothPlastic")

	-- WHEELS (front ones steer: the client turns the motor C0)
	local parts = {}
	for _, def in ipairs({ { "WheelFL", -1, FZ }, { "WheelFR", 1, FZ }, { "WheelRL", -1, RZ }, { "WheelRR", 1, RZ } }) do
		local lp = V(def[2] * TX, AX, def[3])
		wheel(def[1], lp, R, 0.95, def[2], root, "car")
		caliper(lp, R, 0.95, def[2], root)
	end

	-- SEATS (prompts only — touching the car never seats you)
	seat("VehicleSeat", "DriveSeat", V(-1.25, 1.7, 0.55), V(1.5, 0.2, 1.5), V(-4.3, 1.9, 0.6))
	seat("Seat", "Passenger1", V(1.25, 1.7, 0.55), V(1.5, 0.2, 1.5), V(4.3, 1.9, 0.6))
	seat("Seat", "Passenger2", V(-1.2, 1.7, 3.2), V(1.4, 0.2, 1.3), V(-4.3, 1.9, 3.2))
	seat("Seat", "Passenger3", V(1.2, 1.7, 3.2), V(1.4, 0.2, 1.3), V(4.3, 1.9, 3.2))
	prompt("DoorsLeft", V(-3.4, 2.6, 1.5), "Drive", "Car", "DriveSeat,Passenger2,Passenger1,Passenger3")
	prompt("DoorsRight", V(3.4, 2.6, 1.5), "Drive", "Car", "DriveSeat,Passenger1,Passenger3,Passenger2")

	sound("Engine", "116815666457202", 0.4, true, 90)
	sound("Horn", "127513531122725", 0.8, false, 140)
	return model
end

----------------------------------------------------------------------------------------------------- MOTORCYCLE
-- Underbone motorcycle (Philippine-street style). ~6.6 long. Wheels R 1.05 at z = -2.15 / +2.1.
function M.buildMoto(groundCF, opts)
	opts = opts or {}
	local RED = opts.paint or Color3.fromRGB(196, 28, 34)
	local SILVER = Color3.fromRGB(150, 152, 156)
	local function red(n, size, lcf, opt) opt = opt or {} opt.refl = opt.refl or 0.07 return mk(n, size, lcf, RED, "SmoothPlastic", opt) end
	newModel(opts.name or "ParkMotorcycle", groundCF, "Moto")
	makeRoot(V(0, 1.05, 0), 3)
	local R, AX, FZ, RZ = 1.05, 1.05, -2.15, 2.1
	model:SetAttribute("MaxSpeed", 42) model:SetAttribute("Reverse", 6) model:SetAttribute("Accel", 16)
	model:SetAttribute("Brake", 40) model:SetAttribute("Coast", 6) model:SetAttribute("Wheelbase", 4.25)
	model:SetAttribute("MaxSteer", 34) model:SetAttribute("WheelR", R) model:SetAttribute("DisplayName", "Motorcycle")

	contact("ContactF", V(0, AX, FZ), R * 2)
	contact("ContactR", V(0, AX, RZ), R * 2)
	hull("Hull", V(1.3, 1.5, 5.4), C(0, 2.05, 0))

	-- STEERING ASSEMBLY (BarsHub turns about the rake axis; fork, wheel, fender, headlight, bars all on it)
	local H, F = V(0, 3.3, -1.5), V(0, AX, FZ)
	local axis = (H - F).Unit
	local barsCF = CFrame.fromMatrix(H, V(1, 0, 0), axis)
	local bars = Instance.new("Part")
	bars.Name = "BarsHub" bars.Size = V(0.2, 0.2, 0.2) bars.CFrame = O * barsCF bars.Transparency = 1
	bars.CanCollide = false bars.CanTouch = false bars.CanQuery = false bars.Massless = true bars.Parent = model
	local bm = Instance.new("Motor6D") bm.Name = "BarsMotor" bm.Part0 = root bm.Part1 = bars
	bm.C0 = root.CFrame:ToObjectSpace(bars.CFrame) bm.Parent = root
	local function S(n, size, lcf, color, mat, opt) opt = opt or {} opt.to = bars return mk(n, size, lcf, color, mat, opt) end
	local function Srod(n, a, b, dia, color, mat, opt) opt = opt or {} opt.to = bars return rod(n, a, b, dia, color, mat, opt) end
	for _, s in ipairs({ -1, 1 }) do
		Srod("ForkTube", V(s * 0.3, 1.9, FZ + (1.9 - AX) / axis.Y * axis.Z), H + V(s * 0.3, -0.25, -0.25 * axis.Z / axis.Y), 0.16, CHROME, "Metal", { refl = 0.3 })
		Srod("ForkLower", F + V(s * 0.3, 0, 0), V(s * 0.3, 1.95, FZ + (1.95 - AX) / axis.Y * axis.Z), 0.24, Color3.fromRGB(30, 30, 32), "Metal")
		S("AxleNut", V(0.1, 0.18, 0.18), C(s * 0.36, AX, FZ), CHROME, "Metal", { shape = CYL, shadow = false })
		-- handlebar grips, levers, mirrors, turn signals
		Srod("Handlebar", V(s * 0.15, 3.62, -1.3), V(s * 0.75, 3.66, -1.2), 0.1, BLACK, "Metal")
		Srod("Grip", V(s * 0.72, 3.66, -1.2), V(s * 1.02, 3.68, -1.16), 0.17, Color3.fromRGB(20, 20, 22), "Rubber")
		S("BarEnd", V(0.06, 0.17, 0.17), C(s * 1.05, 3.68, -1.16), CHROME, "Metal", { shape = CYL, shadow = false })
		Srod("Lever", V(s * 0.62, 3.64, -1.32), V(s * 0.98, 3.62, -1.38), 0.05, CHROME, "Metal")
		S("SwitchBox", V(0.16, 0.16, 0.18), C(s * 0.62, 3.66, -1.2), Color3.fromRGB(28, 28, 30), "SmoothPlastic", { shadow = false })
		Srod("MirrorStalk", V(s * 0.5, 3.68, -1.24), V(s * 0.72, 4.3, -1.18), 0.06, BLACK, "Metal")
		S("Mirror", V(0.08, 0.42, 0.42), C(s * 0.76, 4.4, -1.18) * ZAXIS, BLACK, "SmoothPlastic", { shape = CYL, shadow = false })
		S("MirrorGlass", V(0.03, 0.36, 0.36), C(s * 0.76, 4.4, -1.13) * ZAXIS, Color3.fromRGB(190, 205, 215), "Glass", { shape = CYL, refl = 0.5, shadow = false })
		Srod("SignalStalk", V(s * 0.38, 3.05, -1.85), V(s * 0.62, 3.05, -1.85), 0.06, BLACK, "Metal")
		S("TurnFront", V(0.2, 0.15, 0.24), C(s * 0.7, 3.05, -1.86), Color3.fromRGB(255, 160, 30), "Glass", { shadow = false })
	end
	S("TopClamp", V(0.8, 0.12, 0.42), barsCF * C(0, 0.05, 0), CHROME, "Metal", { refl = 0.3 })
	S("BarClamp", V(0.36, 0.14, 0.2), C(0, 3.58, -1.3), CHROME, "Metal", { refl = 0.3, shadow = false })
	-- headlight cowl
	local cowl = S("HeadCowl", V(0.95, 0.7, 0.6), C(0, 3.25, -1.85) * CFrame.Angles(0.15, 0, 0), RED, "SmoothPlastic", { refl = 0.07 })
	S("CowlVisor", V(0.85, 0.08, 0.5), C(0, 3.62, -1.8) * CFrame.Angles(0.35, 0, 0), Color3.fromRGB(50, 60, 70), "Glass", { transp = 0.4, shadow = false })
	S("HeadlightRing", V(0.06, 0.6, 0.6), C(0, 3.22, -2.16) * ZAXIS, CHROME, "Metal", { shape = CYL, refl = 0.3, shadow = false })
	S("HeadlightLens", V(0.06, 0.52, 0.52), C(0, 3.22, -2.19) * ZAXIS, Color3.fromRGB(220, 230, 240), "Glass", { shape = CYL, transp = 0.3, refl = 0.2, shadow = false })
	local lamp = S("HeadLamp", V(0.28, 0.28, 0.28), C(0, 3.22, -2.12), Color3.fromRGB(240, 240, 230), "Glass", { shape = BALL, shadow = false })
	local sl = Instance.new("SpotLight") sl.Face = Enum.NormalId.Front sl.Angle = 50 sl.Range = 34 sl.Brightness = 1.2
	sl.Color = Color3.fromRGB(255, 244, 225) sl.Shadows = false sl.Enabled = false sl.Parent = lamp
	S("DRL", V(0.5, 0.06, 0.04), C(0, 2.9, -2.13), Color3.fromRGB(235, 245, 255), "Neon", { shadow = false })
	local dash = S("Speedo", V(0.55, 0.32, 0.22), C(0, 3.78, -1.42) * CFrame.Angles(-0.5, 0, 0), Color3.fromRGB(20, 20, 22), "SmoothPlastic", { shadow = false })
	local gt = textGui(dash, Enum.NormalId.Top, "0", Color3.fromRGB(120, 230, 255), Color3.fromRGB(8, 10, 14), Enum.Font.GothamBlack, 160, 90)
	gt.Name = "Speed"
	-- front fender (turns with the fork)
	arc("FrontFender", F, R + 0.12, R + 0.22, 25, 165, 8, 0.5, RED, "SmoothPlastic", { refl = 0.07, to = bars })
	-- front wheel spins on the steering hub
	wheel("WheelF", F, R, 0.45, 1, bars, "moto")
	caliper(F, R, 0.45, 1, bars, Color3.fromRGB(200, 160, 40))

	-- FRAME + BODY
	rod("Backbone", V(0, 3.15, -1.4), V(0, 1.7, -0.55), 0.28, BLACK, "Metal")
	rod("FrameRear", V(0, 1.7, -0.55), V(0, 2.45, 1.0), 0.24, BLACK, "Metal")
	for _, s in ipairs({ -1, 1 }) do rod("SubFrame", V(s * 0.3, 2.45, 0.6), V(s * 0.3, 2.75, 2.5), 0.12, BLACK, "Metal") end
	red("LegShield", V(1.55, 1.75, 0.16), C(0, 2.45, -1.12) * CFrame.Angles(-0.28, 0, 0))
	mk("LegShieldInner", V(1.35, 1.5, 0.08), C(0, 2.4, -1.0) * CFrame.Angles(-0.28, 0, 0), BLACK, "SmoothPlastic", { shadow = false })
	red("FrontCover", V(0.85, 0.8, 0.55), C(0, 2.85, -1.42) * CFrame.Angles(-0.28, 0, 0))
	local stripeL = mk("Stripe", V(1.57, 0.12, 0.02), C(0, 2.2, -1.22) * CFrame.Angles(-0.28, 0, 0), Color3.fromRGB(245, 245, 245), "SmoothPlastic", { shadow = false })
	mk("Floorboard", V(1.0, 0.14, 1.0), C(0, 1.62, -0.25), BLACK, "Rubber")
	-- engine
	mk("Crankcase", V(0.85, 0.8, 1.1), C(0, 1.15, 0.0), SILVER, "Metal", { refl = 0.1 })
	mk("Cylinder", V(0.55, 0.55, 0.85), C(0, 1.42, -0.8) * CFrame.Angles(0.35, 0, 0), SILVER, "Metal", { refl = 0.1 })
	for i = 0, 5 do mk("CoolingFin", V(0.78, 0.78, 0.05), C(0, 1.42 - i * 0.04, -0.55 - i * 0.11) * CFrame.Angles(0.35, 0, 0), Color3.fromRGB(120, 122, 126), "Metal", { shadow = false }) end
	mk("PlugCap", V(0.14, 0.14, 0.3), C(0, 1.9, -0.95) * CFrame.Angles(0.8, 0, 0), BLACK, "Rubber", { shadow = false })
	mk("ClutchCover", V(0.14, 0.7, 0.7), C(0.47, 1.15, 0.05), Color3.fromRGB(175, 178, 182), "Metal", { shape = CYL, refl = 0.2 })
	mk("StatorCover", V(0.14, 0.6, 0.6), C(-0.47, 1.15, 0.1), Color3.fromRGB(28, 28, 30), "Metal", { shape = CYL })
	mk("Carburetor", V(0.3, 0.3, 0.35), C(0.1, 1.8, -0.35), SILVER, "Metal", { shadow = false })
	mk("AirFilter", V(0.5, 0.5, 0.6), C(0, 2.0, 0.2), BLACK, "SmoothPlastic", { shadow = false })
	-- exhaust (right side)
	rod("Header", V(0.05, 1.25, -1.15), V(0.22, 0.72, -0.95), 0.16, CHROME, "Metal", { refl = 0.3 })
	rod("HeaderRun", V(0.22, 0.72, -0.95), V(0.45, 0.78, 0.6), 0.16, CHROME, "Metal", { refl = 0.3 })
	rod("Muffler", V(0.48, 0.85, 0.55), V(0.52, 1.25, 2.2), 0.42, Color3.fromRGB(26, 26, 28), "Metal")
	rod("HeatShield", V(0.66, 0.92, 0.7), V(0.7, 1.22, 1.8), 0.22, CHROME, "Metal", { refl = 0.3 })
	rod("MufflerTip", V(0.52, 1.25, 2.2), V(0.53, 1.31, 2.45), 0.26, CHROME, "Metal", { refl = 0.3 })
	-- swingarm, shocks, chain
	for _, s in ipairs({ -1, 1 }) do
		bar("Swingarm", V(s * 0.3, 1.25, 0.5), V(s * 0.3, AX, RZ), 0.12, 0.2, BLACK, "Metal")
		rod("ShockRod", V(s * 0.38, 1.2, RZ - 0.3), V(s * 0.38, 2.55, RZ - 0.75), 0.1, CHROME, "Metal", { refl = 0.3 })
		rod("ShockSpring", V(s * 0.38, 1.5, RZ - 0.4), V(s * 0.38, 2.35, RZ - 0.68), 0.24, Color3.fromRGB(230, 190, 30), "Metal")
		mk("FootPeg", V(0.4, 0.1, 0.1), C(s * 0.62, 1.35, 0.3), BLACK, "Rubber", { shadow = false })
		mk("PillionPeg", V(0.32, 0.08, 0.08), C(s * 0.58, 1.6, 1.25), BLACK, "Rubber", { shadow = false })
	end
	rod("ChainTop", V(-0.42, 1.3, 0.3), V(-0.42, 1.47, RZ), 0.07, Color3.fromRGB(40, 40, 42), "Metal")
	rod("ChainBottom", V(-0.42, 1.0, 0.3), V(-0.42, 0.63, RZ), 0.07, Color3.fromRGB(40, 40, 42), "Metal")
	mk("ChainGuard", V(0.06, 0.25, 1.5), C(-0.5, 1.55, 1.2) * CFrame.Angles(-0.05, 0, 0), BLACK, "SmoothPlastic", { shadow = false })
	rod("Shifter", V(-0.5, 1.4, -0.1), V(-0.55, 1.45, -0.55), 0.06, BLACK, "Metal")
	rod("BrakePedal", V(0.5, 1.3, 0.3), V(0.6, 1.25, -0.25), 0.06, BLACK, "Metal")
	-- side stand (shown only while parked)
	local ks = rod("Kickstand", V(-0.4, 1.05, 0.2), V(-0.95, 0.06, 0.5), 0.1, BLACK, "Metal")
	-- body side covers, seat, tail
	red("SideCover", V(1.0, 0.75, 1.45), C(0, 2.25, 0.9))
	for _, s in ipairs({ -1, 1 }) do
		local d = mk("Decal" .. (s < 0 and "L" or "R"), V(0.02, 0.4, 1.1), C(s * 0.51, 2.25, 0.85), RED, "SmoothPlastic", { refl = 0.07, shadow = false })
		local t = textGui(d, s < 0 and Enum.NormalId.Left or Enum.NormalId.Right, "SC 150", Color3.fromRGB(250, 250, 250), nil, Enum.Font.GothamBlack, 220, 80)
		t.Rotation = 0
		mk("DecalStripe", V(0.02, 0.06, 1.3), C(s * 0.51, 1.98, 0.9), Color3.fromRGB(250, 250, 250), "SmoothPlastic", { shadow = false })
	end
	mk("UnderSeat", V(0.9, 0.3, 2.2), C(0, 2.48, 1.1), BLACK, "SmoothPlastic")
	red("TailCowl", V(0.85, 0.5, 1.15), C(0, 2.72, 2.2) * CFrame.Angles(-0.18, 0, 0))
	mk("SeatRider", V(0.95, 0.3, 1.4), C(0, 2.82, 0.45), Color3.fromRGB(26, 26, 28), "Leather")
	mk("SeatPillion", V(0.85, 0.3, 1.15), C(0, 2.98, 1.65), Color3.fromRGB(26, 26, 28), "Leather")
	mk("SeatStitch", V(0.97, 0.04, 0.04), C(0, 2.98, 1.1), Color3.fromRGB(200, 30, 34), "Fabric", { shadow = false })
	for _, s in ipairs({ -1, 1 }) do rod("GrabRail", V(s * 0.48, 2.95, 1.3), V(s * 0.45, 3.02, 2.35), 0.1, CHROME, "Metal", { refl = 0.3 }) end
	rod("GrabRailBack", V(-0.45, 3.02, 2.35), V(0.45, 3.02, 2.35), 0.1, CHROME, "Metal", { refl = 0.3 })
	mk("TailHousing", V(0.55, 0.26, 0.14), C(0, 2.8, 2.78), Color3.fromRGB(70, 8, 10), "Glass", { transp = 0.1, refl = 0.15 })
	local bl = mk("BrakeLight", V(0.45, 0.16, 0.05), C(0, 2.8, 2.86), Color3.fromRGB(110, 10, 12), "Glass", { shadow = false })
	local tl = Instance.new("SurfaceLight") tl.Face = Enum.NormalId.Back tl.Color = Color3.fromRGB(255, 40, 40) tl.Range = 7 tl.Brightness = 0.6 tl.Angle = 120 tl.Enabled = false tl.Parent = bl
	for _, s in ipairs({ -1, 1 }) do
		rod("RearSignalStalk", V(s * 0.2, 2.45, 2.75), V(s * 0.5, 2.45, 2.75), 0.06, BLACK, "Metal")
		mk("TurnRear", V(0.2, 0.15, 0.22), C(s * 0.58, 2.45, 2.76), Color3.fromRGB(255, 150, 30), "Glass", { shadow = false })
	end
	arc("RearHugger", V(0, AX, RZ), R + 0.1, R + 0.17, 40, 150, 6, 0.45, BLACK, "SmoothPlastic")
	bar("PlateBracket", V(0, 2.5, 2.7), V(0, 2.1, 2.95), 0.5, 0.06, BLACK, "SmoothPlastic")
	plate("Plate", V(0.9, 0.5, 0.04), C(0, 2.12, 2.98) * CFrame.Angles(0.25, 0, 0), "1234 SC", Enum.NormalId.Back)
	mk("Reflector", V(0.3, 0.1, 0.04), C(0, 2.36, 2.98), Color3.fromRGB(150, 15, 15), "Glass", { shadow = false })

	-- rear wheel + sprocket (spins) + caliper
	local rh = wheel("WheelR", V(0, AX, RZ), R, 0.5, 1, root, "moto")
	mk("Sprocket", V(0.05, 0.85, 0.85), C(-0.42, AX, RZ), Color3.fromRGB(60, 60, 64), "Metal", { shape = CYL, to = rh, shadow = false })
	for i = 1, 6 do mk("SprocketHole", V(0.07, 0.12, 0.12), C(-0.43, AX, RZ) * CFrame.Angles(i / 6 * math.pi * 2, 0, 0) * C(0, 0, -0.25), BLACK, "SmoothPlastic", { shape = CYL, to = rh, shadow = false }) end
	caliper(V(0, AX, RZ), R, 0.5, 1, root, Color3.fromRGB(200, 160, 40))

	-- SEATS + prompts
	seat("VehicleSeat", "DriveSeat", V(0, 3.0, 0.35), V(0.9, 0.2, 1.0), V(-2.4, 1.9, 0.35))
	seat("Seat", "Passenger1", V(0, 3.15, 1.6), V(0.8, 0.2, 0.9), V(-2.4, 1.9, 1.7))
	prompt("RideLeft", V(-1.6, 2.6, 0.8), "Ride", "Motorcycle", "DriveSeat,Passenger1")
	prompt("RideRight", V(1.6, 2.6, 0.8), "Ride", "Motorcycle", "DriveSeat,Passenger1")

	sound("Engine", "105286499430569", 0.4, true, 80)
	local h = sound("Horn", "127513531122725", 0.7, false, 120)
	h.PlaybackSpeed = 1.35
	return model
end

return M
