--[[ SkyClimbBuilder — builds "PATAAS! Sky Climb" (an Only-Up style climb) from copies of
  Samar College / San Roque objects (ServerStorage.SkyClimbProps).
  Run once from the command bar / plugin:  require(ServerStorage.SkyClimbBuilder).build()
  Every jump is checked with raycasts against default Roblox jump physics
  (WalkSpeed 16, JumpPower 50, gravity 196.2) and pulled closer until it is possible. ]]
local SS = game:GetService("ServerStorage")
local CS = game:GetService("CollectionService")
local M = {}

M.CENTER = Vector3.new(60, 400, 1700) -- island centre (top of the grass)
M.RADIUS = 62                         -- spiral radius of the climb
local LIB = SS:WaitForChild("SkyClimbProps")

-- jump physics
local WALK, JUMP, G = 16, 50, 196.2
local function airTime(rise) local d = JUMP * JUMP - 2 * G * rise if d < 0 then return nil end return (JUMP + math.sqrt(d)) / G end
local function reach(rise) local t = airTime(rise) return t and WALK * t or 0 end -- centre-to-centre horizontal travel

-- prop settings: scale, optional lay-flat axis
local PROPS = {
	Tricycle = { s = 2.2 }, SnackCart = { s = 2.0 }, CoveredCart = { s = 2.6 }, BusStop = { s = 1.2 }, ParkBench = { s = 2.3 },
	Bldg_PinkRamen = { s = 1 }, Bldg_BlueRefill = { s = 1 }, Bldg_YellowWindows = { s = 1 }, Bldg_GreenWhite = { s = 0.8 },
	ArmchairDesk = { s = 3 }, OfficeTable = { s = 1.8 }, Whiteboard = { s = 1.6 }, Lockers = { s = 1.5 }, FilingCabinet = { s = 3 },
	CRT_TV = { s = 2.5 }, Bookshelf = { s = 3 }, GlassDoor = { s = 1.6, lay = "z" }, Window = { s = 1, lay = "x" }, Globe = { s = 7 },
	StackedChairs = { s = 2.5 }, BookStacks = { s = 1 }, Bookcase = { s = 2.5 }, PCCarrels = { s = 1 }, Monitor = { s = 5 },
	Printer = { s = 4 }, Computer = { s = 5 }, Books = { s = 7 }, TrophyShelf = { s = 2 },
	WhiteTable = { s = 2 }, RedTableBench = { s = 2.5 }, MetalTable = { s = 2 }, VendingMachines = { s = 1.5 }, FoodDisplay = { s = 2 },
	StoreShelf_Food = { s = 1.4 }, RiceCooker = { s = 8 },
	PrincipalDesk = { s = 1.2 }, SofaSet = { s = 1.3 }, Bed = { s = 2 }, Sofa3 = { s = 2.5 }, Bench = { s = 2.2 },
	MainGate = { s = 1.5 }, ILoveSC = { s = 3 }, Trophy = { s = 8 },
}

-- zones: name, props (cycled in random order), rest platform, gap range, rise range, vanishing steps
M.ZONES = {
	{ id = 1, name = "KALYE SAN ROQUE", sub = "Street", color = Color3.fromRGB(240, 170, 60), rest = "Bldg_PinkRamen",
		props = { "Tricycle", "SnackCart", "ParkBench", "CoveredCart", "BusStop", "Bench", "Tricycle", "SnackCart" },
		mid = "Bldg_BlueRefill", gap = { 3, 5 }, rise = { 0.5, 3 }, steps = 12 },
	{ id = 2, name = "SILID-ARALAN", sub = "Classroom", color = Color3.fromRGB(80, 160, 230), rest = "Bldg_YellowWindows",
		props = { "ArmchairDesk", "OfficeTable", "Lockers", "FilingCabinet", "CRT_TV", "StackedChairs", "Window", "GlassDoor", "Whiteboard", "Globe" },
		mid = "OfficeTable", gap = { 3.5, 6 }, rise = { 0.5, 3.5 }, steps = 13 },
	{ id = 3, name = "AKLATAN & COMPUTER LAB", sub = "Library", color = Color3.fromRGB(150, 100, 210), rest = "BookStacks",
		props = { "Bookcase", "Bookshelf", "PCCarrels", "Monitor", "Computer", "Printer", "Books", "Bookcase", "Books" },
		mid = "BookStacks", gap = { 4, 6.5 }, rise = { 1, 3.8 }, steps = 13, vanish = { Books = true } },
	{ id = 4, name = "KANTINA", sub = "Canteen", color = Color3.fromRGB(230, 90, 70), rest = "WhiteTable",
		props = { "RedTableBench", "MetalTable", "VendingMachines", "FoodDisplay", "StoreShelf_Food", "RiceCooker", "SnackCart", "WhiteTable" },
		mid = "MetalTable", gap = { 4.5, 7 }, rise = { 1, 4 }, steps = 13 },
	{ id = 5, name = "OPISINA & KLINIKA", sub = "Offices & Clinic", color = Color3.fromRGB(60, 180, 140), rest = "PrincipalDesk",
		props = { "SofaSet", "Bed", "Sofa3", "TrophyShelf", "FilingCabinet", "Bench", "Books", "Bed" },
		mid = "SofaSet", gap = { 5, 7.5 }, rise = { 1, 4.2 }, steps = 13, vanish = { Books = true } },
	{ id = 6, name = "KAMPUS SA ULAP", sub = "Campus in the Clouds", color = Color3.fromRGB(245, 200, 60), rest = "Bldg_GreenWhite",
		props = { "Whiteboard", "Globe", "Trophy", "ILoveSC", "MainGate", "Books", "Globe", "Trophy" },
		mid = "MainGate", gap = { 5.5, 8 }, rise = { 1, 4.4 }, steps = 13, vanish = { Books = true } },
}

---------------------------------------------------------------- helpers
local rng
local function lerp(a, b, t) return a + (b - a) * t end
local function rand(a, b) return lerp(a, b, rng:NextNumber()) end
local function part(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part") p.Name = name p.Size = size p.CFrame = cf p.Color = color p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = parent return p
end
local function sign(p, face, text, bg, fg, ppS)
	local g = Instance.new("SurfaceGui") g.Face = face g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = ppS or 30 g.LightInfluence = 0.2 g.Parent = p
	local t = Instance.new("TextLabel") t.Name = "Text" t.Size = UDim2.fromScale(1, 1) t.BackgroundColor3 = bg or Color3.new(0, 0, 0) t.BackgroundTransparency = bg and 0 or 1
	t.TextColor3 = fg or Color3.new(1, 1, 1) t.Font = Enum.Font.GothamBlack t.TextScaled = true t.TextWrapped = true t.Text = text t.Parent = g
	return t
end
local function billboard(parent, text, color, size, offset, dist)
	local b = Instance.new("BillboardGui") b.Size = size or UDim2.fromOffset(300, 60) b.StudsOffset = offset or Vector3.new(0, 6, 0) b.MaxDistance = dist or 160 b.LightInfluence = 0 b.Parent = parent
	local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.Font = Enum.Font.GothamBlack t.TextScaled = true
	t.TextColor3 = color or Color3.new(1, 1, 1) t.TextStrokeTransparency = 0.25 t.Text = text t.Parent = b
	return t
end

-- clone + scale + orient a prop; returns model
local function spawnProp(key, parent)
	local src = LIB:FindFirstChild(key)
	assert(src, "missing prop " .. key)
	local m = src:Clone()
	local cfg = PROPS[key] or { s = 1 }
	if cfg.s ~= 1 then m:ScaleTo(cfg.s) end
	-- lay flat: turn the thin axis upward
	if cfg.lay == "x" then m:PivotTo(m:GetPivot() * CFrame.Angles(0, 0, math.rad(90)))
	elseif cfg.lay == "z" then m:PivotTo(m:GetPivot() * CFrame.Angles(math.rad(90), 0, 0)) end
	-- re-centre pivot on the bounding box, axis aligned
	local cf = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(cf.Position)
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true d.CanTouch = false end end
	m.Parent = parent
	return m
end

-- world AABB of a model
local function aabb(m)
	local mn, mx = Vector3.new(math.huge, math.huge, math.huge), -Vector3.new(math.huge, math.huge, math.huge)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			local cf, s = d.CFrame, d.Size / 2
			local rx, ry, rz = cf.RightVector * s.X, cf.UpVector * s.Y, cf.LookVector * s.Z
			local e = Vector3.new(math.abs(rx.X) + math.abs(ry.X) + math.abs(rz.X), math.abs(rx.Y) + math.abs(ry.Y) + math.abs(rz.Y), math.abs(rx.Z) + math.abs(ry.Z) + math.abs(rz.Z))
			mn = mn:Min(cf.Position - e) mx = mx:Max(cf.Position + e)
		end
	end
	return mn, mx
end

-- standable points on top of a model (raycast grid, needs 5 studs of headroom)
local function standables(m, step)
	step = step or 1.25
	local mn, mx = aabb(m)
	local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Include rp.FilterDescendantsInstances = { m } rp.RespectCanCollide = true
	local pts = {}
	for x = mn.X + 0.4, mx.X - 0.4, step do
		for z = mn.Z + 0.4, mx.Z - 0.4, step do
			local hit = workspace:Raycast(Vector3.new(x, mx.Y + 2, z), Vector3.new(0, -(mx.Y - mn.Y) - 4, 0), rp)
			if hit and hit.Normal.Y > 0.7 then
				local up = workspace:Raycast(hit.Position + Vector3.new(0, 0.2, 0), Vector3.new(0, 5.2, 0), rp)
				if not up then table.insert(pts, hit.Position) end
			end
		end
	end
	return pts
end

-- best (easiest) jump between two point sets; returns slack ratio (<1 = possible) + the pair
local function bestJump(A, B, margin)
	local best, ba, bb = math.huge, nil, nil
	for _, a in ipairs(A) do
		for _, b in ipairs(B) do
			local rise = b.Y - a.Y
			if rise <= 5.2 then
				local r = reach(math.max(rise, -30)) + 1.6 -- +1.6: the body overhangs the edges
				local d = Vector2.new(b.X - a.X, b.Z - a.Z).Magnitude
				local ratio = d / (r * margin)
				if ratio < best then best, ba, bb = ratio, a, b end
			end
		end
	end
	return best, ba, bb
end

local function centroid(pts) local s = Vector3.zero for _, p in ipairs(pts) do s += p end return #pts > 0 and s / #pts or nil end
local function mostCentral(pts) local c = centroid(pts) if not c then return nil end local best, bp = math.huge, nil for _, p in ipairs(pts) do local d = (p - c).Magnitude if d < best then best, bp = d, p end end return bp end

-- overlap test between a new prop and everything already placed (keeps 1.5 studs clear)
local function overlaps(m, placed)
	local mn, mx = aabb(m)
	for _, o in ipairs(placed) do
		if o.circle then
			-- the round island: nearest point of the box to the island centre
			local nx, nz = math.clamp(o.c.X, mn.X, mx.X), math.clamp(o.c.Z, mn.Z, mx.Z)
			if Vector2.new(nx - o.c.X, nz - o.c.Z).Magnitude < o.r and mx.Y > o.y0 and mn.Y < o.y1 then return true end
		elseif mn.X < o.mx.X + 1.5 and mx.X > o.mn.X - 1.5 and mn.Y < o.mx.Y + 1.5 and mx.Y > o.mn.Y - 1.5 and mn.Z < o.mx.Z + 1.5 and mx.Z > o.mn.Z - 1.5 then return true end
	end
	return false
end

---------------------------------------------------------------- island
local function buildIsland(root)
	local C = M.CENTER
	local isl = Instance.new("Model") isl.Name = "StartIsland" isl.Parent = root
	local GRASS, DIRT, ROCK = Color3.fromRGB(86, 160, 72), Color3.fromRGB(120, 86, 56), Color3.fromRGB(110, 104, 98)
	part(isl, "Grass", Vector3.new(3, 96, 96), CFrame.new(C - Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), GRASS, Enum.Material.Grass, { Shape = Enum.PartType.Cylinder })
	part(isl, "Dirt", Vector3.new(8, 92, 92), CFrame.new(C - Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(90)), DIRT, Enum.Material.Ground, { Shape = Enum.PartType.Cylinder })
	for i = 1, 4 do
		local r = 44 - i * 9
		part(isl, "Rock" .. i, Vector3.new(r * 2, 14, r * 2), CFrame.new(C - Vector3.new(0, 10 + i * 12, 0)), ROCK, Enum.Material.Slate, { Shape = Enum.PartType.Ball, CanCollide = false })
	end
	for k = 1, 14 do
		local a = k / 14 * math.pi * 2
		part(isl, "Boulder", Vector3.new(9, 9, 9), CFrame.new(C + Vector3.new(math.cos(a) * 43, -9, math.sin(a) * 43)), ROCK, Enum.Material.Slate, { Shape = Enum.PartType.Ball, CanCollide = false })
	end
	-- bushes around the rim
	for k = 1, 22 do
		local a = k / 22 * math.pi * 2 + 0.1
		part(isl, "Bush", Vector3.new(4, 3.4, 4), CFrame.new(C + Vector3.new(math.cos(a) * 45, 1.2, math.sin(a) * 45)), Color3.fromRGB(60, 130 + (k % 3) * 15, 60), Enum.Material.Grass, { Shape = Enum.PartType.Ball, CanCollide = false })
	end
	-- the San Roque park fountain in the middle
	local f = spawnProp("Fountain", isl)
	local mn = aabb(f)
	f:PivotTo(f:GetPivot() + (C - Vector3.new(f:GetPivot().X, mn.Y, f:GetPivot().Z)) + Vector3.new(-14, 0, 0))
	-- welcome sign
	local board = part(isl, "WelcomeBoard", Vector3.new(1, 10, 22), CFrame.new(C + Vector3.new(-36, 7, 0)), Color3.fromRGB(25, 35, 30), Enum.Material.SmoothPlastic)
	sign(board, Enum.NormalId.Right, "⛰️ PATAAS!\nSKY CLIMB\nClimb the floating campus to the clouds", Color3.fromRGB(25, 60, 40), Color3.fromRGB(245, 200, 60))
	for _, dz in ipairs({ -10, 10 }) do part(isl, "BoardLeg", Vector3.new(0.8, 4, 0.8), CFrame.new(C + Vector3.new(-36, 0, dz)), Color3.fromRGB(60, 60, 60), Enum.Material.Metal) end
	-- mode kiosks
	local function kiosk(name, pos, color, title, text, mode)
		local k = Instance.new("Model") k.Name = name k.Parent = isl
		part(k, "Pad", Vector3.new(10, 0.6, 10), CFrame.new(pos + Vector3.new(0, 0.3, 0)), color, Enum.Material.Neon, { Transparency = 0.35 })
		local post = part(k, "Post", Vector3.new(1.2, 7, 6), CFrame.new(pos + Vector3.new(4, 3.5, 0)), Color3.fromRGB(30, 34, 40), Enum.Material.SmoothPlastic)
		sign(post, Enum.NormalId.Left, title .. "\n" .. text, color, Color3.new(1, 1, 1), 26)
		local anchor = part(k, "PromptAnchor", Vector3.new(1, 1, 1), CFrame.new(pos + Vector3.new(0, 2.5, 0)), Color3.new(1, 1, 1), nil, { Transparency = 1, CanCollide = false })
		local pp = Instance.new("ProximityPrompt") pp.ActionText = "Start " .. mode pp.ObjectText = "⛰️ Sky Climb" pp.HoldDuration = 0.3 pp.MaxActivationDistance = 10 pp.RequiresLineOfSight = false pp.Parent = anchor
		k:SetAttribute("Mode", mode)
		CS:AddTag(k, "SkyClimbKiosk")
		billboard(post, title, color, UDim2.fromOffset(220, 40), Vector3.new(0, 6, 0), 90)
	end
	kiosk("EasyKiosk", C + Vector3.new(-22, 0, -18), Color3.fromRGB(60, 190, 90), "🟢 EASY MODE", "Checkpoints save your progress", "Easy")
	kiosk("HardKiosk", C + Vector3.new(-22, 0, 18), Color3.fromRGB(220, 60, 60), "🔴 HARD MODE", "No checkpoints!\nFall = back to the bottom", "Hard")
	-- leaderboard
	local lb = part(isl, "Leaderboard", Vector3.new(1, 16, 26), CFrame.new(C + Vector3.new(-44, 10, -30)) * CFrame.Angles(0, math.rad(35), 0), Color3.fromRGB(20, 24, 30), Enum.Material.SmoothPlastic)
	lb.Name = "Leaderboard" CS:AddTag(lb, "SkyClimbBoard")
	-- portal back to campus
	local portal = Instance.new("Model") portal.Name = "ReturnPortal" portal.Parent = isl
	local pc = C + Vector3.new(-30, 0, 34)
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2
		part(portal, "Ring", Vector3.new(1.2, 1.2, 1.2), CFrame.new(pc + Vector3.new(0, 6 + math.sin(a) * 5.5, math.cos(a) * 5.5)), Color3.fromRGB(120, 200, 255), Enum.Material.Neon, { Shape = Enum.PartType.Ball, CanCollide = false })
	end
	local pf = part(portal, "PortalField", Vector3.new(0.3, 10, 10), CFrame.new(pc + Vector3.new(0, 6, 0)), Color3.fromRGB(150, 220, 255), Enum.Material.ForceField, { CanCollide = false, Transparency = 0.2, Shape = Enum.PartType.Cylinder })
	pf.CFrame = CFrame.new(pc + Vector3.new(0, 6, 0)) * CFrame.Angles(0, 0, 0)
	local pp = Instance.new("ProximityPrompt") pp.ActionText = "Back to campus" pp.ObjectText = "🏫 Samar College" pp.HoldDuration = 0.3 pp.MaxActivationDistance = 10 pp.RequiresLineOfSight = false pp.Parent = pf
	CS:AddTag(pf, "SkyClimbReturn")
	billboard(pf, "🏫 BACK TO CAMPUS", Color3.fromRGB(150, 220, 255), UDim2.fromOffset(220, 40), Vector3.new(0, 8, 0), 90)
	-- arrival point
	local arrive = part(isl, "Arrival", Vector3.new(6, 1, 6), CFrame.new(C + Vector3.new(-30, 0.5, 0)), Color3.new(1, 1, 1), nil, { Transparency = 1, CanCollide = false })
	arrive.Name = "Arrival"
	return isl
end

---------------------------------------------------------------- checkpoint + zone sign
local function checkpoint(root, index, zone, pos, label)
	local cp = Instance.new("Model") cp.Name = ("Checkpoint_%02d"):format(index) cp.Parent = root
	local pad = part(cp, "Pad", Vector3.new(0.4, 7, 7), CFrame.new(pos + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(120, 230, 140), Enum.Material.Neon, { Shape = Enum.PartType.Cylinder, CanCollide = false, Transparency = 0.45 })
	pad.CanTouch = true
	local trig = part(cp, "Trigger", Vector3.new(8, 8, 8), CFrame.new(pos + Vector3.new(0, 4, 0)), Color3.new(1, 1, 1), nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	trig.CanTouch = true
	trig:SetAttribute("Index", index) trig:SetAttribute("Zone", zone)
	CS:AddTag(trig, "SkyClimbCheckpoint")
	local flag = spawnProp("SchoolFlag", cp)
	local mn = aabb(flag)
	flag:PivotTo(flag:GetPivot() + (pos + Vector3.new(2.8, 0, 2.8)) - Vector3.new(flag:GetPivot().X, mn.Y, flag:GetPivot().Z))
	billboard(pad, label or ("🚩 CHECKPOINT " .. index), Color3.fromRGB(140, 240, 160), UDim2.fromOffset(200, 34), Vector3.new(0, 7, 0), 55)
	return trig
end

---------------------------------------------------------------- the climb
function M.build(seed)
	rng = Random.new(seed or 7707)
	local old = workspace:FindFirstChild("SkyClimb")
	if old then old:Destroy() end
	local root = Instance.new("Folder") root.Name = "SkyClimb" root.Parent = workspace
	root:SetAttribute("BaseY", M.CENTER.Y)
	local island = buildIsland(root)
	local course = Instance.new("Folder") course.Name = "Course" course.Parent = root
	local cps = Instance.new("Folder") cps.Name = "Checkpoints" cps.Parent = root
	local C = M.CENTER

	-- start: standable points on the island rim near the start angle
	local placed = {}
	local angle = math.rad(-20)
	local prevPts = {}
	local startEdge = C + Vector3.new(math.cos(angle) * 46, 0.1, math.sin(angle) * 46)
	for da = -0.05, 0.05, 0.025 do for _, r in ipairs({ 43, 44.5, 46, 47.2 }) do table.insert(prevPts, C + Vector3.new(math.cos(angle + da) * r, 0.1, math.sin(angle + da) * r)) end end
	table.insert(placed, { circle = true, c = C, r = 48.6, y0 = C.Y - 3, y1 = C.Y + 4 })
	local start = Instance.new("Part") start.Name = "StartLine" start.Anchored = true start.CanCollide = false start.Transparency = 1 start.Size = Vector3.new(10, 10, 10) start.CFrame = CFrame.new(startEdge + Vector3.new(0, 4, 0)) start.Parent = root
	billboard(start, "⛰️ START — jump onto the street!", Color3.fromRGB(245, 200, 60), UDim2.fromOffset(260, 40), Vector3.new(0, 6, 0), 120)

	local stepIndex, cpIndex = 0, 0
	local report = {}
	local function dirAt(p)
		local rel = Vector3.new(p.X - C.X, 0, p.Z - C.Z)
		local r = rel.Magnitude
		local radial = r > 0.1 and rel.Unit or Vector3.new(1, 0, 0)
		local tangent = Vector3.new(-radial.Z, 0, radial.X) -- counter-clockwise
		local corr = math.clamp((M.RADIUS - r) / 25, -0.6, 0.6)
		return (tangent + radial * corr).Unit
	end

	local SCRATCH = Vector3.new(0, 3000, 0)
	local function exitInfo()
		local fromC = centroid(prevPts)
		local dir = dirAt(fromC)
		local exit, bestAlong = prevPts[1], -math.huge
		for _, p in ipairs(prevPts) do
			local side = math.abs((p - fromC):Dot(Vector3.new(-dir.Z, 0, dir.X)))
			local al = (p - fromC):Dot(dir) - side * 0.35 -- furthest forward, but near the middle line
			if al > bestAlong then bestAlong, exit = al, p end
		end
		return exit, dir
	end
	-- try one prop at one yaw; returns pts or nil
	local function tryPlace(m, zone, exit, dir, yaw, gapWant, rise, margin)
		m:PivotTo(CFrame.new(SCRATCH) * CFrame.Angles(0, yaw, 0))
		local rel = standables(m)
		if #rel < 4 then return nil end
		local piv = m:GetPivot().Position
		-- the standable point nearest to us (smallest projection on dir), close to the path line
		local side = Vector3.new(-dir.Z, 0, dir.X)
		local minAl = math.huge
		for _, p in ipairs(rel) do minAl = math.min(minAl, (p - piv):Dot(dir)) end
		local near, bestSide = nil, math.huge
		for _, p in ipairs(rel) do
			if (p - piv):Dot(dir) <= minAl + 1.3 then
				local sd = math.abs((p - piv):Dot(side))
				if sd < bestSide then bestSide, near = sd, p end
			end
		end
		local maxGap = (reach(rise) + 1.6) * margin
		local gap = math.min(gapWant, maxGap * 0.97)
		local target = exit + dir * gap + Vector3.new(0, rise, 0)
		local shift = target - near
		m:PivotTo(m:GetPivot() + shift)
		if overlaps(m, placed) then return nil end
		-- nothing of the new prop may hang over the take-off spot (head bump)
		local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Include rp.FilterDescendantsInstances = { m } rp.RespectCanCollide = true
		for _, o in ipairs({ Vector3.zero, dir * 2, dir * 4 }) do
			if workspace:Raycast(exit + o + Vector3.new(0, 0.5, 0), Vector3.new(0, 8, 0), rp) then return nil end
		end
		local pts = {}
		for _, p in ipairs(rel) do table.insert(pts, p + shift) end
		local ratio = bestJump(prevPts, pts, margin)
		if ratio > 1.001 then return nil end
		return pts, ratio
	end
	local function placeStep(zone, key, opts)
		opts = opts or {}
		local exit, dir = exitInfo()
		local margin = opts.margin or (zone.id <= 2 and 0.78 or 0.88)
		local candidates = { key }
		if key ~= "Books" then
			for _, k in ipairs(zone.props) do if k ~= key and not table.find(candidates, k) then table.insert(candidates, k) end end
		end
		table.insert(candidates, "Books")
		for ci, k in ipairs(candidates) do
			local m = spawnProp(k, course)
			local size = m:GetExtentsSize()
			local baseYaw = math.atan2(-dir.X, -dir.Z) + (size.X > size.Z and math.rad(90) or 0)
			for attempt = 1, 6 do
				local yaw = baseYaw + math.rad(({ 0, 90, 180, 270, 45, 135 })[attempt]) + math.rad(rand(-15, 15))
				local gap = opts.gap or rand(zone.gap[1], zone.gap[2])
				local rise = opts.rise or rand(zone.rise[1], zone.rise[2])
				for push = 0, 3 do
					local pts, ratio = tryPlace(m, zone, exit, dir, yaw, gap + push * 2, rise, margin)
					if pts then
						local mn2, mx2 = aabb(m)
						table.insert(placed, { mn = mn2, mx = mx2 })
						stepIndex += 1
						m.Name = ("Z%d_%02d_%s"):format(zone.id, stepIndex, k)
						m:SetAttribute("Step", stepIndex) m:SetAttribute("Zone", zone.id)
						if zone.vanish and zone.vanish[k] and not opts.solid then CS:AddTag(m, "SkyClimbVanish") end
						prevPts = pts
						table.insert(report, ("%s jump=%.2f%s"):format(m.Name, ratio, ci > 1 and (" (instead of " .. key .. ")") or ""))
						return m, pts
					end
				end
			end
			m:Destroy()
		end
		error("could not place a step after " .. stepIndex .. "\n" .. table.concat(report, "\n"))
	end

	for _, zone in ipairs(M.ZONES) do
		-- rest platform (zone start) with checkpoint + zone sign
		local restM, restPts = placeStep(zone, zone.rest, { gap = zone.id == 1 and 4 or 4.5, rise = 2.5, solid = true })
		cpIndex += 1
		local cpPos = mostCentral(restPts)
		checkpoint(cps, cpIndex, zone.id, cpPos, ("🚩 ZONE %d • %s"):format(zone.id, zone.name))
		local zs = Instance.new("Part") zs.Name = "ZoneSign" zs.Anchored = true zs.CanCollide = false zs.Transparency = 1 zs.Size = Vector3.new(1, 1, 1) zs.CFrame = CFrame.new(cpPos + Vector3.new(0, 9, 0)) zs.Parent = restM
		billboard(zs, ("ZONE %d\n%s\n(%s)"):format(zone.id, zone.name, zone.sub), zone.color, UDim2.fromOffset(320, 90), Vector3.zero, 110)
		restM:SetAttribute("ZoneStart", zone.id)
		root:SetAttribute("Zone" .. zone.id .. "Y", cpPos.Y)
		root:SetAttribute("Zone" .. zone.id .. "Name", zone.name)
		local order = table.clone(zone.props)
		for i = #order, 2, -1 do local j = rng:NextInteger(1, i) order[i], order[j] = order[j], order[i] end
		for s = 1, zone.steps do
			local key = order[(s - 1) % #order + 1]
			if s == math.ceil(zone.steps / 2) then key = zone.mid end
			local m, pts = placeStep(zone, key, s == math.ceil(zone.steps / 2) and { solid = true } or nil)
			if s == math.ceil(zone.steps / 2) and pts then
				cpIndex += 1
				checkpoint(cps, cpIndex, zone.id, mostCentral(pts))
			end
			if s % 4 == 0 then task.wait() end
		end
	end

	-- finish: a small floating campus with the I ♥ SC statue, giant trophy and the flag
	local fin = Instance.new("Model") fin.Name = "Finish" fin.Parent = root
	-- summit: its edge 5 studs past the furthest point of the last prop, 2 studs higher
	local exit, dir = exitInfo()
	local fc = exit + dir * (5 + 20) + Vector3.new(0, 2, 0)
	part(fin, "Summit", Vector3.new(3, 40, 40), CFrame.new(fc - Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(240, 240, 235), Enum.Material.Marble, { Shape = Enum.PartType.Cylinder })
	part(fin, "SummitGold", Vector3.new(1, 42, 42), CFrame.new(fc - Vector3.new(0, 3.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(245, 200, 60), Enum.Material.Foil, { Shape = Enum.PartType.Cylinder })
	for k = 1, 8 do local a = k / 8 * math.pi * 2 part(fin, "Cloud", Vector3.new(16, 8, 12), CFrame.new(fc + Vector3.new(math.cos(a) * 20, -6, math.sin(a) * 20)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball, CanCollide = false, Transparency = 0.15 }) end
	local function plant(key, offset)
		local m = spawnProp(key, fin)
		local pmn = aabb(m)
		m:PivotTo(m:GetPivot() + (fc + offset) - Vector3.new(m:GetPivot().X, pmn.Y, m:GetPivot().Z))
		return m
	end
	local side = Vector3.new(-dir.Z, 0, dir.X)
	plant("ILoveSC", dir * 12)
	plant("Trophy", dir * 6 + side * 9)
	plant("Flag", dir * 6 - side * 10)
	local goal = part(fin, "FinishTrigger", Vector3.new(30, 10, 30), CFrame.new(fc + Vector3.new(0, 5, 0)), Color3.new(1, 1, 1), nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	goal.CanTouch = true
	CS:AddTag(goal, "SkyClimbFinish")
	billboard(goal, "🏆 SUMMIT — YOU MADE IT!", Color3.fromRGB(245, 200, 60), UDim2.fromOffset(320, 50), Vector3.new(0, 14, 0), 300)
	local back = part(fin, "SummitPortal", Vector3.new(0.4, 9, 9), CFrame.new(fc + Vector3.new(14, 5, -6)) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(150, 220, 255), Enum.Material.ForceField, { CanCollide = false, Shape = Enum.PartType.Cylinder })
	local pp = Instance.new("ProximityPrompt") pp.ActionText = "Back to start island" pp.ObjectText = "⛰️ Sky Climb" pp.HoldDuration = 0.3 pp.RequiresLineOfSight = false pp.MaxActivationDistance = 10 pp.Parent = back
	CS:AddTag(back, "SkyClimbToStart")
	root:SetAttribute("TopY", fc.Y)
	root:SetAttribute("Steps", stepIndex)
	root:SetAttribute("Checkpoints", cpIndex)
	for _, m in ipairs(course:GetChildren()) do for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.CanTouch = CS:HasTag(m, "SkyClimbVanish") end end end
	return ("steps=%d checkpoints=%d topY=%.0f height=%.0f\n%s"):format(stepIndex, cpIndex, fc.Y, fc.Y - C.Y, table.concat(report, "\n"))
end

return M
