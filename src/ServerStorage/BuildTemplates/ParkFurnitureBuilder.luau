--[[ ParkFurnitureBuilder — detailed park bench (build tool).
    local B = require(game.ServerStorage.BuildTemplates.ParkFurnitureBuilder)
    B.bench(groundCF) -> Model "Bench"
  groundCF = a CFrame ON THE GROUND at the middle of the bench; the bench FACES that CFrame's +Z
  (the backrest is toward -Z, same as the old park benches). Classic cast-iron park bench: ornate iron side
  frames with scroll armrests and decorative curls, 5 curved-edge wooden seat slats, a reclined 4-slat
  backrest with a rounded top rail, a centre support, foot pads that sit ON the ground, a small brass plaque.
  Two invisible Seat parts keep the bench sittable (left / right). ]]
local M = {}
local IRON = Color3.fromRGB(28, 62, 46)
local IRON_D = Color3.fromRGB(20, 44, 33)
local BRASS = Color3.fromRGB(196, 160, 82)
local WOOD1, WOOD2 = Color3.fromRGB(150, 96, 56), Color3.fromRGB(132, 82, 46)

local O, model
local function mk(name, size, lcf, color, mat, opt)
	opt = opt or {}
	local p = Instance.new(opt.class or "Part")
	if opt.shape then p.Shape = opt.shape end
	p.Name = name p.Size = size p.CFrame = O * lcf p.Color = color p.Material = mat
	p.Anchored = true p.CanCollide = opt.collide ~= false p.CanTouch = opt.touch == true
	p.CastShadow = size.Magnitude > 1.5
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	if opt.transp then p.Transparency = opt.transp end
	p.Parent = model
	return p
end
local CYL, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball
local function V(x, y, z) return Vector3.new(x, y, z) end
local function C(x, y, z) return CFrame.new(x, y, z) end
local function bar(name, a, b, w, h, color, mat, opt)
	return mk(name, V(w, h, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), color, mat, opt)
end
local function rod(name, a, b, dia, color, mat, opt)
	opt = opt or {} opt.shape = CYL
	return mk(name, V((b - a).Magnitude, dia, dia), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0), color, mat, opt)
end

function M.bench(groundCF)
	O = groundCF
	model = Instance.new("Model")
	model.Name = "Bench"
	local SEAT_Y, HALF = 1.62, 2.95
	-- IRON SIDE FRAMES (left / right)
	for _, s in ipairs({ -1, 1 }) do
		local x = s * HALF
		-- front leg with a little outward curve at the foot
		bar("FrontLeg", V(x, 0.12, 0.62), V(x, SEAT_Y - 0.05, 0.5), 0.22, 0.26, IRON, Enum.Material.Metal)
		mk("FootPad", V(0.34, 0.12, 0.5), C(x, 0.06, 0.66), IRON_D, Enum.Material.Metal)
		-- rear leg that continues up into the reclined back upright
		bar("RearLeg", V(x, 0.12, -0.78), V(x, SEAT_Y - 0.05, -0.55), 0.22, 0.26, IRON, Enum.Material.Metal)
		mk("FootPad", V(0.34, 0.12, 0.5), C(x, 0.06, -0.8), IRON_D, Enum.Material.Metal)
		bar("BackUpright", V(x, SEAT_Y - 0.1, -0.58), V(x, 3.55, -1.12), 0.22, 0.26, IRON, Enum.Material.Metal)
		-- seat bearer + lower stretcher between the legs
		mk("SeatBearer", V(0.22, 0.2, 1.45), C(x, SEAT_Y - 0.15, -0.02), IRON, Enum.Material.Metal)
		mk("LegTie", V(0.18, 0.14, 1.3), C(x, 0.45, -0.08), IRON, Enum.Material.Metal)
		-- decorative cast-iron curl between the legs
		mk("Curl", V(0.12, 0.62, 0.62), C(x, 0.95, -0.05) * CFrame.Angles(0, 0, 0), IRON_D, Enum.Material.Metal, { shape = CYL })
		mk("CurlCenter", V(0.16, 0.28, 0.28), C(x, 0.95, -0.05), BRASS, Enum.Material.Metal, { shape = CYL })
		-- armrest: support post, flat rest, scroll at the front
		bar("ArmPost", V(x, SEAT_Y, 0.48), V(x, 2.45, 0.42), 0.18, 0.2, IRON, Enum.Material.Metal)
		bar("Armrest", V(x, 2.5, 0.55), V(x, 2.6, -0.75), 0.3, 0.14, IRON, Enum.Material.Metal)
		mk("ArmScroll", V(0.32, 0.36, 0.36), C(x, 2.46, 0.6), IRON_D, Enum.Material.Metal, { shape = CYL })
		mk("ArmScrollCap", V(0.34, 0.16, 0.16), C(x, 2.46, 0.6), BRASS, Enum.Material.Metal, { shape = CYL })
	end
	-- centre support under the seat and behind the back
	bar("CentreLeg", V(0, 0.1, -0.1), V(0, SEAT_Y - 0.15, -0.05), 0.2, 0.2, IRON, Enum.Material.Metal)
	mk("CentreFoot", V(0.4, 0.1, 0.4), C(0, 0.05, -0.1), IRON_D, Enum.Material.Metal)
	mk("CentreBearer", V(0.2, 0.18, 1.35), C(0, SEAT_Y - 0.15, -0.02), IRON, Enum.Material.Metal)
	bar("CentreBack", V(0, SEAT_Y + 0.05, -0.62), V(0, 3.35, -1.08), 0.16, 0.18, IRON, Enum.Material.Metal)
	rod("Stretcher", V(-HALF, 0.45, -0.08), V(HALF, 0.45, -0.08), 0.12, IRON, Enum.Material.Metal)
	-- WOODEN SEAT: 5 slats, rounded front edge
	for i = 0, 4 do
		local z = 0.55 - i * 0.29
		mk("SeatSlat", V(HALF * 2 + 0.25, 0.13, 0.25), C(0, SEAT_Y, z), i % 2 == 0 and WOOD1 or WOOD2, Enum.Material.WoodPlanks)
	end
	mk("SeatNose", V(HALF * 2 + 0.25, 0.17, 0.17), C(0, SEAT_Y - 0.01, 0.69), WOOD1, Enum.Material.WoodPlanks, { shape = CYL })
	-- RECLINED BACKREST: 4 slats along the back uprights, rounded top rail
	local b0, b1 = V(0, SEAT_Y + 0.35, -0.66), V(0, 3.4, -1.1)
	local up = (b1 - b0).Unit
	for i = 0, 3 do
		local p = b0 + up * (0.25 + i * 0.42)
		mk("BackSlat", V(HALF * 2 + 0.1, 0.3, 0.1), CFrame.fromMatrix(p + V(0, 0, 0.1), V(1, 0, 0), up), i % 2 == 0 and WOOD2 or WOOD1, Enum.Material.WoodPlanks)
	end
	mk("TopRail", V(HALF * 2 + 0.3, 0.22, 0.22), C(0, 3.5, -1.08), WOOD1, Enum.Material.WoodPlanks, { shape = CYL })
	mk("Plaque", V(0.8, 0.2, 0.03), CFrame.fromMatrix(b0 + up * 1.5 + V(0, 0, 0.16), V(1, 0, 0), up), BRASS, Enum.Material.Metal, { collide = false })
	-- two invisible seats so players can sit on the left and right
	for _, s in ipairs({ -1, 1 }) do
		local st = mk("Seat", V(2.6, 0.2, 1.1), C(s * 1.45, SEAT_Y + 0.08, 0.0), WOOD1, Enum.Material.SmoothPlastic, { class = "Seat", transp = 1, touch = true })
		st.CastShadow = false
	end
	model.PrimaryPart = model:FindFirstChild("CentreBearer")
	return model
end

return M
