--[[ UtilityPoleBuilder — detailed Philippine-style concrete utility poles + connected sagging wires (Beams).
  Build tool (run from the command bar / MCP), not used by the game at runtime.
    local B = require(game.ServerStorage.BuildTemplates.UtilityPoleBuilder)
    B.buildPole(folder, basePos, roadDir, index, opts) -> pole model, attachment table
    B.wire(folder, att0, att1, kind)                    -> Beam that sags between two attachments
  Pole local frame: -Z = toward the road, X = along the street, Y = up (base at Y = 0).
  Wires are Beams pinned to Attachments on each pole, so they always connect exactly and cost almost nothing. ]]
local M = {}

local CONCRETE = Color3.fromRGB(168, 168, 162)
local CONCRETE_D = Color3.fromRGB(140, 140, 134)
local STEEL = Color3.fromRGB(120, 124, 128)
local STEEL_D = Color3.fromRGB(78, 82, 86)
local PORCELAIN = Color3.fromRGB(236, 236, 228)
local PORCELAIN_B = Color3.fromRGB(140, 90, 60)
local BLACK = Color3.fromRGB(24, 24, 26)
local YELLOW = Color3.fromRGB(245, 200, 40)
local TANK = Color3.fromRGB(150, 158, 158)

local function part(parent, name, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name p.Size = size p.CFrame = cf p.Color = color p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true p.CanCollide = false p.CanTouch = false p.CanQuery = false p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
-- vertical cylinder (Roblox cylinders run along X, so turn it up)
local UP = CFrame.Angles(0, 0, math.rad(90))
local function vcyl(parent, name, dia, h, cf, color, mat)
	return part(parent, name, Vector3.new(h, dia, dia), cf * UP, color, mat, Enum.PartType.Cylinder)
end
-- cylinder between two world points
local function rod(parent, name, a, b, dia, color, mat)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
	return part(parent, name, Vector3.new(len, dia, dia), cf, color, mat, Enum.PartType.Cylinder)
end
-- box between two world points
local function bar(parent, name, a, b, w, h, color, mat)
	local len = (b - a).Magnitude
	return part(parent, name, Vector3.new(w, h, len), CFrame.lookAt((a + b) / 2, b), color, mat)
end

-- porcelain pin insulator standing on `cf` (top of crossarm). Returns the world point where the wire sits.
local function pinInsulator(parent, cf)
	local f = Instance.new("Model") f.Name = "PinInsulator" f.Parent = parent
	vcyl(f, "Pin", 0.14, 0.45, cf * CFrame.new(0, 0.22, 0), STEEL, Enum.Material.Metal)
	vcyl(f, "Skirt1", 0.62, 0.12, cf * CFrame.new(0, 0.48, 0), PORCELAIN, Enum.Material.SmoothPlastic)
	vcyl(f, "Neck", 0.34, 0.2, cf * CFrame.new(0, 0.62, 0), PORCELAIN, Enum.Material.SmoothPlastic)
	vcyl(f, "Skirt2", 0.5, 0.1, cf * CFrame.new(0, 0.76, 0), PORCELAIN, Enum.Material.SmoothPlastic)
	vcyl(f, "Top", 0.3, 0.2, cf * CFrame.new(0, 0.9, 0), PORCELAIN, Enum.Material.SmoothPlastic)
	vcyl(f, "Tie", 0.34, 0.05, cf * CFrame.new(0, 0.86, 0), STEEL_D, Enum.Material.Metal)
	return (cf * CFrame.new(0, 0.95, 0)).Position
end
-- spool (secondary) insulator on a bracket, axis along the street. Returns the wire point.
local function spool(parent, cf)
	local f = Instance.new("Model") f.Name = "SpoolInsulator" f.Parent = parent
	part(f, "Spool", Vector3.new(0.38, 0.42, 0.42), cf, PORCELAIN, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	part(f, "Groove", Vector3.new(0.16, 0.32, 0.32), cf, Color3.fromRGB(205, 205, 196), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	part(f, "Bolt", Vector3.new(0.5, 0.08, 0.08), cf, STEEL, Enum.Material.Metal, Enum.PartType.Cylinder)
	return (cf * CFrame.new(0, 0, -0.2)).Position
end

local function att(holder, name, worldPos)
	local a = Instance.new("Attachment") a.Name = name a.Parent = holder
	a.WorldPosition = worldPos
	a.Axis = Vector3.new(0, -1, 0) a.SecondaryAxis = Vector3.new(1, 0, 0) -- beam curves bend DOWN from here
	return a
end

----------------------------------------------------------------------------------------------- one pole
-- base: world position of the foot (on the sidewalk); roadDir: +1 = road is toward +X, -1 = toward -X
-- opts: { transformer = bool, light = bool, guy = Vector3 (anchor point) or nil, label = "SR-01" }
function M.buildPole(folder, base, roadDir, index, opts)
	opts = opts or {}
	local pole = Instance.new("Model") pole.Name = ("UtilityPole_%s"):format(opts.label or index)
	local P = CFrame.lookAt(base, base + Vector3.new(roadDir, 0, 0)) -- -Z (LookVector) = toward road
	local function at(x, y, z) return P * CFrame.new(x, y, z) end
	local A = {} -- attachments by name

	-- footing + tapered concrete shaft (3 sections) + cap
	vcyl(pole, "Footing", 2.0, 0.5, at(0, 0.25, 0), CONCRETE_D, Enum.Material.Concrete)
	vcyl(pole, "Collar", 1.45, 0.4, at(0, 0.7, 0), CONCRETE_D, Enum.Material.Concrete)
	vcyl(pole, "Shaft1", 1.15, 10, at(0, 5, 0), CONCRETE, Enum.Material.Concrete)
	vcyl(pole, "Joint1", 1.2, 0.18, at(0, 10, 0), CONCRETE_D, Enum.Material.Concrete)
	vcyl(pole, "Shaft2", 1.0, 10, at(0, 15, 0), CONCRETE, Enum.Material.Concrete)
	vcyl(pole, "Joint2", 1.05, 0.18, at(0, 20, 0), CONCRETE_D, Enum.Material.Concrete)
	vcyl(pole, "Shaft3", 0.86, 10.4, at(0, 25.2, 0), CONCRETE, Enum.Material.Concrete)
	part(pole, "Cap", Vector3.new(0.86, 0.86, 0.86), at(0, 30.4, 0), CONCRETE_D, Enum.Material.Concrete, Enum.PartType.Ball)
	-- the trunk is the only solid part (you bump into the pole, not into the little bits)
	for _, n in ipairs({ "Shaft1", "Footing" }) do local s = pole:FindFirstChild(n) s.CanCollide = true s.CanQuery = true end
	-- black & yellow hazard bands (low on the pole, road side and all around)
	for k = 0, 5 do vcyl(pole, "HazardBand", 1.19, 0.38, at(0, 1.3 + k * 0.38, 0), k % 2 == 0 and YELLOW or BLACK, Enum.Material.SmoothPlastic) end
	-- pole number plate (facing the road)
	local plate = part(pole, "NumberPlate", Vector3.new(0.62, 0.9, 0.06), at(0, 6.4, -0.6), Color3.fromRGB(245, 245, 240), Enum.Material.SmoothPlastic)
	local sg = Instance.new("SurfaceGui") sg.Face = Enum.NormalId.Front sg.CanvasSize = Vector2.new(62, 90) sg.LightInfluence = 0.6 sg.MaxDistance = 60 sg.Parent = plate
	local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.Font = Enum.Font.GothamBlack t.TextScaled = true
	t.TextColor3 = BLACK t.Text = (opts.label or ("SR-" .. index)):gsub("%-", "\n") t.Parent = sg
	-- climbing step bolts (alternate sides)
	for k = 0, 11 do
		local y = 8.5 + k * 1.5
		local s = (k % 2 == 0) and 1 or -1
		part(pole, "StepBolt", Vector3.new(0.55, 0.1, 0.1), at(s * 0.68, y, 0), STEEL, Enum.Material.Metal, Enum.PartType.Cylinder)
	end

	-- PRIMARY: steel crossarm across the pole (perpendicular to the wires) + braces + 2 pin insulators + pole-top pin
	local armY = 28.6
	part(pole, "Crossarm", Vector3.new(0.34, 0.42, 6.6), at(0, armY, 0), STEEL, Enum.Material.Metal)
	part(pole, "CrossarmLip", Vector3.new(0.38, 0.06, 6.6), at(0, armY + 0.22, 0), STEEL_D, Enum.Material.Metal)
	part(pole, "ArmClamp", Vector3.new(1.0, 0.6, 1.0), at(0, armY, 0), STEEL_D, Enum.Material.DiamondPlate)
	for _, s in ipairs({ -1, 1 }) do
		bar(pole, "ArmBrace", at(0, armY - 2.2, 0.0).Position, at(0, armY - 0.2, s * 2.3).Position, 0.12, 0.2, STEEL_D, Enum.Material.Metal)
	end
	part(pole, "BraceClamp", Vector3.new(1.0, 0.25, 1.0), at(0, armY - 2.2, 0), STEEL_D, Enum.Material.Metal)
	A.P1 = pinInsulator(pole, at(0, armY + 0.21, -2.75)) -- road side
	A.P3 = pinInsulator(pole, at(0, armY + 0.21, 2.75)) -- house side
	part(pole, "TopBracket", Vector3.new(0.3, 1.2, 0.3), at(0, 30.9, 0), STEEL_D, Enum.Material.Metal)
	A.P2 = pinInsulator(pole, at(0, 31.5, 0))

	-- NEUTRAL: small bracket + spool, road side
	part(pole, "NeutralBracket", Vector3.new(0.25, 0.25, 0.7), at(0, 26.4, -0.75), STEEL_D, Enum.Material.Metal)
	A.N = spool(pole, at(0, 26.4, -1.05))

	-- SECONDARY (low voltage) rack: vertical strap with 3 spools, road side
	part(pole, "SecondaryRack", Vector3.new(0.3, 2.9, 0.12), at(0, 23.4, -0.55), STEEL_D, Enum.Material.Metal)
	for k, y in ipairs({ 24.4, 23.4, 22.4 }) do
		part(pole, "RackArm", Vector3.new(0.22, 0.12, 0.45), at(0, y, -0.75), STEEL_D, Enum.Material.Metal)
		A["S" .. k] = spool(pole, at(0, y, -1.0))
	end

	-- TELECOM: 2 cable clamps (fibre / cable TV), road side, lower
	for k, y in ipairs({ 17.6, 16.6 }) do
		part(pole, "CableClamp", Vector3.new(0.5, 0.22, 0.6), at(0, y, -0.68), BLACK, Enum.Material.Metal)
		A["T" .. k] = at(0, y - 0.05, -1.0).Position
	end
	if index % 3 == 0 then
		-- splice closure hanging on the fibre line next to the pole
		local sc = part(pole, "SpliceClosure", Vector3.new(1.5, 0.55, 0.55), at(2.4, 17.05, -1.0), BLACK, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		part(pole, "SpliceCap", Vector3.new(0.2, 0.62, 0.62), sc.CFrame * CFrame.new(0.75, 0, 0), Color3.fromRGB(40, 40, 44), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	end

	-- METER BANK (house side): backboard, 3 kWh meters with glass dials, conduit up to the secondary rack
	vcyl(pole, "MeterBand", 1.2, 0.15, at(0, 12.9, 0), STEEL_D, Enum.Material.Metal)
	part(pole, "MeterBoard", Vector3.new(1.9, 2.0, 0.1), at(0, 11.6, 0.68), Color3.fromRGB(205, 200, 185), Enum.Material.WoodPlanks)
	for k = -1, 1 do
		local mcf = at(k * 0.6, 11.6, 0.9)
		part(pole, "Meter", Vector3.new(0.5, 0.72, 0.36), mcf, Color3.fromRGB(70, 74, 78), Enum.Material.SmoothPlastic)
		part(pole, "MeterGlass", Vector3.new(0.08, 0.38, 0.38), mcf * CFrame.new(0, 0.1, 0.19) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(210, 225, 230), Enum.Material.Glass, Enum.PartType.Cylinder).Transparency = 0.3
		part(pole, "MeterDial", Vector3.new(0.3, 0.06, 0.02), mcf * CFrame.new(0, 0.1, 0.17), Color3.fromRGB(240, 240, 235), Enum.Material.SmoothPlastic)
		part(pole, "MeterSeal", Vector3.new(0.08, 0.08, 0.06), mcf * CFrame.new(0, -0.28, 0.2), Color3.fromRGB(200, 40, 40), Enum.Material.SmoothPlastic)
	end
	rod(pole, "Conduit", at(0.75, 12.6, 0.62).Position, at(0.75, 22.0, 0.62).Position, 0.18, Color3.fromRGB(110, 115, 120), Enum.Material.Metal)
	part(pole, "Weatherhead", Vector3.new(0.3, 0.3, 0.3), at(0.75, 22.1, 0.62), Color3.fromRGB(90, 94, 98), Enum.Material.Metal, Enum.PartType.Ball)
	for _, y in ipairs({ 15, 18.5 }) do part(pole, "ConduitStrap", Vector3.new(0.1, 0.12, 1.1), at(0.75, y, 0.3), STEEL_D, Enum.Material.Metal) end

	-- STREET LIGHT arm (road side)
	if opts.light then
		local a0, a1 = at(0, 20.6, -0.45).Position, at(0, 21.4, -5.2).Position
		rod(pole, "LightArm", a0, a1, 0.2, STEEL, Enum.Material.Metal)
		rod(pole, "LightArmBrace", at(0, 19.4, -0.45).Position, at(0, 21.0, -3.2).Position, 0.12, STEEL, Enum.Material.Metal)
		part(pole, "LightArmClamp", Vector3.new(0.9, 0.5, 0.9), at(0, 20.0, 0), STEEL_D, Enum.Material.Metal)
		local head = part(pole, "LampHousing", Vector3.new(0.75, 0.3, 1.7), at(0, 21.35, -5.9) * CFrame.Angles(math.rad(-6), 0, 0), Color3.fromRGB(70, 74, 80), Enum.Material.Metal)
		local bulb = part(pole, "Bulb", Vector3.new(0.55, 0.06, 1.3), head.CFrame * CFrame.new(0, -0.17, 0), Color3.fromRGB(225, 220, 205), Enum.Material.Glass)
		local sl = Instance.new("SpotLight") sl.Face = Enum.NormalId.Bottom sl.Angle = 115 sl.Range = 24 sl.Brightness = 0.6
		sl.Color = Color3.fromRGB(255, 236, 200) sl.Shadows = false sl.Enabled = false sl.Parent = bulb
		part(pole, "PhotoCell", Vector3.new(0.2, 0.14, 0.2), head.CFrame * CFrame.new(0, 0.2, 0.5), Color3.fromRGB(30, 30, 32), Enum.Material.SmoothPlastic)
	end

	-- TRANSFORMER (house side) with HV/LV bushings, fuse cutouts + lightning arrester on the crossarm
	if opts.transformer then
		local tcf = at(0, 21.4, 1.55)
		for _, y in ipairs({ 22.5, 20.6 }) do
			vcyl(pole, "TxBand", 1.05, 0.18, at(0, y, 0), STEEL_D, Enum.Material.Metal)
			part(pole, "TxHanger", Vector3.new(0.2, 0.2, 0.75), at(0, y, 0.8), STEEL_D, Enum.Material.Metal)
		end
		vcyl(pole, "TxTank", 1.55, 2.5, tcf, TANK, Enum.Material.Metal)
		vcyl(pole, "TxLid", 1.68, 0.16, tcf * CFrame.new(0, 1.32, 0), Color3.fromRGB(130, 138, 138), Enum.Material.Metal)
		vcyl(pole, "TxBase", 1.6, 0.12, tcf * CFrame.new(0, -1.28, 0), Color3.fromRGB(120, 126, 126), Enum.Material.Metal)
		for k = 0, 5 do
			local ang = math.rad(30 + k * 60)
			part(pole, "TxFin", Vector3.new(0.05, 1.9, 0.32), tcf * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0, 0.88), Color3.fromRGB(140, 148, 148), Enum.Material.Metal)
		end
		part(pole, "TxNameplate", Vector3.new(0.5, 0.36, 0.04), tcf * CFrame.new(0, 0.3, 0.78), Color3.fromRGB(220, 220, 210), Enum.Material.Metal)
		-- HV bushings on the lid (2) — wires go up to the primary
		local hv = {}
		for k, x in ipairs({ -0.35, 0.35 }) do
			local b = tcf * CFrame.new(x, 1.4, 0)
			for j = 0, 2 do vcyl(pole, "HVBushing", 0.26 - j * 0.03, 0.16, b * CFrame.new(0, 0.1 + j * 0.17, 0), PORCELAIN_B, Enum.Material.SmoothPlastic) end
			vcyl(pole, "HVTerminal", 0.08, 0.18, b * CFrame.new(0, 0.62, 0), STEEL, Enum.Material.Metal)
			hv[k] = (b * CFrame.new(0, 0.7, 0)).Position
		end
		-- LV bushings on the side facing the pole (3) — wires go to the secondary rack
		local lv = {}
		for k, x in ipairs({ -0.4, 0, 0.4 }) do
			local b = tcf * CFrame.new(x, 0.75, -0.8)
			part(pole, "LVBushing", Vector3.new(0.22, 0.2, 0.2), b * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(60, 60, 64), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
			lv[k] = (b * CFrame.new(0, 0, -0.12)).Position
		end
		-- fuse cutouts (angled) + lightning arresters on the house-side half of the crossarm
		for k, z in ipairs({ 1.3, 2.0 }) do
			local c = at(0, armY - 0.75, z) * CFrame.Angles(math.rad(18), 0, 0)
			part(pole, "CutoutBody", Vector3.new(0.22, 0.9, 0.22), c, PORCELAIN_B, Enum.Material.SmoothPlastic)
			part(pole, "FuseTube", Vector3.new(0.12, 0.8, 0.12), c * CFrame.new(0, 0, -0.18), Color3.fromRGB(60, 40, 30), Enum.Material.SmoothPlastic)
			part(pole, "CutoutBracket", Vector3.new(0.12, 0.35, 0.12), at(0, armY - 0.3, z), STEEL_D, Enum.Material.Metal)
		end
		local la = at(0, armY - 0.65, 3.05)
		for j = 0, 3 do vcyl(pole, "Arrester", 0.24, 0.2, la * CFrame.new(0, -j * 0.22, 0), Color3.fromRGB(110, 112, 110), Enum.Material.SmoothPlastic) end
		-- leads (short wires inside the pole's own attachment set)
		A.TxHV1, A.TxHV2 = hv[1], hv[2]
		A.TxLV1, A.TxLV2, A.TxLV3 = lv[1], lv[2], lv[3]
		A.Cut1 = at(0, armY - 1.2, 1.3).Position
		A.Cut2 = at(0, armY - 1.2, 2.0).Position
		A.CutTop1 = at(0, armY - 0.3, 1.3).Position
		A.CutTop2 = at(0, armY - 0.3, 2.0).Position
	end

	-- GUY wire + ground anchor (end-of-line poles)
	if opts.guy then
		A.GuyTop = at(0, 27.2, 0).Position
		local g = opts.guy
		A.GuyLow = g + Vector3.new(0, 0.6, 0)
		vcyl(pole, "GuyAnchor", 0.5, 0.6, CFrame.new(g + Vector3.new(0, 0.3, 0)), STEEL_D, Enum.Material.Metal)
		vcyl(pole, "GuyStrap", 0.95, 0.2, at(0, 27.2, 0), STEEL_D, Enum.Material.Metal)
		-- yellow guard sleeve on the bottom of the guy wire
		local dir = (A.GuyTop - A.GuyLow).Unit
		rod(pole, "GuyGuard", A.GuyLow + dir * 0.4, A.GuyLow + dir * 3.6, 0.22, YELLOW, Enum.Material.SmoothPlastic)
	end

	-- attachment holder (invisible, world-aligned so the beams sag straight down)
	local holder = part(pole, "WireAnchors", Vector3.new(0.2, 0.2, 0.2), CFrame.new(base + Vector3.new(0, 15, 0)), BLACK)
	holder.Transparency = 1
	local atts = {}
	for k, v in pairs(A) do atts[k] = att(holder, k, v) end
	pole.PrimaryPart = pole:FindFirstChild("Shaft1")
	pole:SetAttribute("Side", roadDir > 0 and "West" or "East")
	pole.Parent = folder
	return pole, atts
end

----------------------------------------------------------------------------------------------- wires
local KINDS = {
	primary   = { w = 0.08, color = Color3.fromRGB(40, 40, 44), sag = 0.045 },
	neutral   = { w = 0.07, color = Color3.fromRGB(150, 150, 154), sag = 0.05 },
	secondary = { w = 0.1, color = Color3.fromRGB(28, 28, 30), sag = 0.06 },
	telecom   = { w = 0.16, color = Color3.fromRGB(18, 18, 20), sag = 0.075 },
	lead      = { w = 0.07, color = Color3.fromRGB(30, 30, 32), sag = 0.12 },
	guy       = { w = 0.07, color = Color3.fromRGB(150, 152, 150), sag = 0 },
}
function M.wire(folder, a0, a1, kind, sagOverride)
	local k = KINDS[kind] or KINDS.secondary
	local b = Instance.new("Beam")
	b.Name = kind
	b.Attachment0, b.Attachment1 = a0, a1
	b.Width0, b.Width1 = k.w, k.w
	b.Color = ColorSequence.new(k.color)
	b.Transparency = NumberSequence.new(0)
	b.LightEmission, b.LightInfluence = 0, 1
	b.FaceCamera = true
	b.Segments = 16
	b.Texture = ""
	local len = (a1.WorldPosition - a0.WorldPosition).Magnitude
	local s = sagOverride or (len * k.sag)
	-- both attachments point DOWN: control point 0 goes down from a0, control point 1 down from a1
	b.CurveSize0, b.CurveSize1 = s, -s
	b.Parent = folder
	return b
end

return M
