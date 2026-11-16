--[[ ChessPieces — builds a Staunton-style chess piece out of parts.
  Used by the server (3D board in the library) and by the client (piece pictures on the 2D board).
  build(kind, white, scale) → Model whose PrimaryPart "Root" sits at the bottom centre (anchored, others welded).
  kind = "P" "N" "B" "R" "Q" "K" ]]
local M = {}
M.WHITE = Color3.fromRGB(242, 234, 216)
M.BLACK = Color3.fromRGB(40, 38, 44)
M.NAMES = { P = "Pawn", N = "Knight", B = "Bishop", R = "Rook", Q = "Queen", K = "King" }

function M.build(kind, white, scale, forViewport)
	scale = scale or 1
	local color = white and M.WHITE or M.BLACK
	local accent = white and Color3.fromRGB(205, 170, 95) or Color3.fromRGB(150, 120, 60)
	local mat = white and Enum.Material.Marble or Enum.Material.SmoothPlastic
	local m = Instance.new("Model") m.Name = (white and "White" or "Black") .. (M.NAMES[kind] or kind)
	local root = Instance.new("Part") root.Name = "Root" root.Size = Vector3.one * 0.05 * scale root.Transparency = 1
	root.Anchored = true root.CanCollide = false root.CanQuery = false root.CanTouch = false root.CastShadow = false root.Parent = m
	m.PrimaryPart = root
	local function part(name, size, cf, shape, col, material)
		local p = Instance.new("Part") p.Name = name p.Size = size * scale p.Color = col or color
		p.Material = material or mat p.CanCollide = false p.CanQuery = false p.CanTouch = false p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.CFrame = CFrame.new(cf.Position * scale) * cf.Rotation
		if forViewport then p.Anchored = true else
			p.Anchored = false
			local w = Instance.new("WeldConstraint") w.Part0 = root w.Part1 = p w.Parent = p
		end
		p.Parent = m
		return p
	end
	local CYL = Enum.PartType.Cylinder
	local BALL = Enum.PartType.Ball
	local up = CFrame.Angles(0, 0, math.rad(90)) -- cylinders stand upright
	local function disc(name, d, h, y, col) return part(name, Vector3.new(h, d, d), CFrame.new(0, y, 0) * up, CYL, col) end
	-- every piece: wide base + ring
	local baseD = kind == "P" and 0.62 or 0.74
	disc("Base", baseD, 0.14, 0.07)
	disc("BaseRing", baseD * 0.84, 0.08, 0.18, accent)
	if kind == "P" then
		disc("Body", 0.36, 0.38, 0.4)
		disc("Collar", 0.44, 0.07, 0.62)
		part("Head", Vector3.one * 0.38, CFrame.new(0, 0.82, 0), BALL)
	elseif kind == "R" then
		disc("Body", 0.5, 0.72, 0.56)
		disc("Top", 0.62, 0.18, 0.98)
		for k = 0, 3 do
			local a = k * math.pi / 2 + math.pi / 4
			part("Merlon", Vector3.new(0.2, 0.18, 0.2), CFrame.new(math.cos(a) * 0.22, 1.16, math.sin(a) * 0.22) * CFrame.Angles(0, -a, 0))
		end
	elseif kind == "N" then
		disc("Body", 0.5, 0.36, 0.38)
		-- horse head: neck + muzzle + mane + ears
		part("Neck", Vector3.new(0.34, 0.7, 0.42), CFrame.new(0, 0.82, 0.05) * CFrame.Angles(math.rad(-12), 0, 0))
		part("Muzzle", Vector3.new(0.3, 0.26, 0.5), CFrame.new(0, 1.06, -0.2) * CFrame.Angles(math.rad(25), 0, 0))
		part("Mane", Vector3.new(0.12, 0.62, 0.14), CFrame.new(0, 0.95, 0.24) * CFrame.Angles(math.rad(-12), 0, 0), nil, accent)
		part("EarL", Vector3.new(0.08, 0.16, 0.08), CFrame.new(-0.09, 1.25, 0.08))
		part("EarR", Vector3.new(0.08, 0.16, 0.08), CFrame.new(0.09, 1.25, 0.08))
		part("EyeL", Vector3.one * 0.06, CFrame.new(-0.155, 1.1, -0.12), BALL, white and Color3.new(0, 0, 0) or Color3.new(1, 1, 1))
		part("EyeR", Vector3.one * 0.06, CFrame.new(0.155, 1.1, -0.12), BALL, white and Color3.new(0, 0, 0) or Color3.new(1, 1, 1))
	elseif kind == "B" then
		disc("Body", 0.4, 0.62, 0.5)
		disc("Collar", 0.48, 0.07, 0.83)
		part("Mitre", Vector3.new(0.38, 0.5, 0.38), CFrame.new(0, 1.08, 0), BALL)
		part("Slit", Vector3.new(0.06, 0.26, 0.4), CFrame.new(0.05, 1.14, 0) * CFrame.Angles(0, 0, math.rad(-30)), nil, accent)
		part("Knob", Vector3.one * 0.13, CFrame.new(0, 1.38, 0), BALL)
	elseif kind == "Q" then
		disc("Body", 0.46, 0.86, 0.62)
		disc("Collar", 0.56, 0.08, 1.06)
		disc("Crown", 0.5, 0.2, 1.2)
		for k = 0, 7 do
			local a = k * math.pi / 4
			part("Point", Vector3.one * 0.1, CFrame.new(math.cos(a) * 0.23, 1.34, math.sin(a) * 0.23), BALL, accent)
		end
		part("Top", Vector3.one * 0.18, CFrame.new(0, 1.42, 0), BALL)
	elseif kind == "K" then
		disc("Body", 0.5, 0.96, 0.67)
		disc("Collar", 0.6, 0.08, 1.16)
		disc("Crown", 0.52, 0.22, 1.3)
		part("CrossV", Vector3.new(0.1, 0.42, 0.1), CFrame.new(0, 1.62, 0), nil, accent)
		part("CrossH", Vector3.new(0.3, 0.1, 0.1), CFrame.new(0, 1.66, 0), nil, accent)
	end
	return m
end

return M
