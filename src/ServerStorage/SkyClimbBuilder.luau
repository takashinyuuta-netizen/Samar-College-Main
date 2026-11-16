--[[ SkyClimbBuilder v2 — "PATAAS! Parkour" (Only-Up style)
  A wandering, random climb made of Samar College / San Roque objects (ServerStorage.SkyClimbProps):
    • RUN      – ordinary jumps that drift left and right
    • ZIGZAG   – steep switchbacks that gain height fast
    • BEAM     – long balance beams (whiteboards, carrels, lockers, shelves…)
    • DROP     – a leap down onto something lower, then climb again
    • GIANT    – an oversized landmark (building, main gate, globe, fountain…) to rest on
  Pieces get random tilts, and floating campus junk + clouds drift around the course.
  Every jump is checked with raycasts against Roblox jump physics (WalkSpeed 16, JumpPower 50).
  build(seed) — same seed = same course (leaderboards stay fair); a new seed = a new random course. ]]
local SS = game:GetService("ServerStorage")
local CS = game:GetService("CollectionService")
local M = {}

M.CENTER = Vector3.new(60, 400, 1700) -- island centre (top of the grass)
M.ISLAND_R = 112
M.WANDER_R = 235                      -- the climb stays within this distance of the island centre
local LIB = SS:WaitForChild("SkyClimbProps")

local WALK, JUMP, G = 16, 50, 196.2
local function airTime(rise) local d = JUMP * JUMP - 2 * G * rise if d < 0 then return nil end return (JUMP + math.sqrt(d)) / G end
local function reach(rise) local t = airTime(rise) return t and WALK * t or 0 end

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
	MainGate = { s = 1.5 }, ILoveSC = { s = 3 }, Trophy = { s = 8 }, Fountain = { s = 1 },
}
-- oversized landmarks (key, scale)
local GIANTS = {
	{ "Bldg_GreenWhite", 1.05 }, { "Bldg_YellowWindows", 1.25 }, { "Bldg_PinkRamen", 1.3 }, { "Bldg_BlueRefill", 1.3 },
	{ "MainGate", 3 }, { "Fountain", 2.2 }, { "Globe", 15 }, { "BookStacks", 2.2 }, { "VendingMachines", 4 },
	{ "PrincipalDesk", 3 }, { "Bed", 5 }, { "WhiteTable", 5 }, { "SofaSet", 3.2 }, { "ILoveSC", 6 },
}
local BEAMS = { "Whiteboard", "PCCarrels", "Lockers", "StoreShelf_Food", "Window", "Bench", "OfficeTable", "Bookshelf", "MetalTable" }
local JUNK = { "Books", "Globe", "Monitor", "Computer", "CRT_TV", "Printer", "RiceCooker", "ArmchairDesk", "FilingCabinet", "Tricycle", "SnackCart", "ParkBench", "StackedChairs", "Trophy", "RedTableBench", "GlassDoor", "CoveredCart" }

M.ZONES = {
	{ id = 1, name = "KALYE SAN ROQUE", sub = "Street", color = Color3.fromRGB(240, 170, 60), giant = { "Bldg_PinkRamen", 1.3 },
		props = { "Tricycle", "SnackCart", "ParkBench", "CoveredCart", "BusStop", "Bench" }, gap = { 3, 5 }, rise = { 1, 3.2 }, steps = 20, margin = 0.8 },
	{ id = 2, name = "SILID-ARALAN", sub = "Classroom", color = Color3.fromRGB(80, 160, 230), giant = { "Bldg_YellowWindows", 1.25 },
		props = { "ArmchairDesk", "OfficeTable", "Lockers", "FilingCabinet", "StackedChairs", "Window", "GlassDoor", "Whiteboard", "Globe" }, gap = { 3.5, 6 }, rise = { 1, 3.6 }, steps = 22, margin = 0.82 },
	{ id = 3, name = "AKLATAN & COMPUTER LAB", sub = "Library", color = Color3.fromRGB(150, 100, 210), giant = { "BookStacks", 2.2 },
		props = { "Bookcase", "Bookshelf", "PCCarrels", "Printer", "Books", "Bookcase" }, gap = { 4, 6.5 }, rise = { 1, 3.9 }, steps = 22, margin = 0.88, vanish = { Books = true } },
	{ id = 4, name = "KANTINA", sub = "Canteen", color = Color3.fromRGB(230, 90, 70), giant = { "VendingMachines", 4 },
		props = { "RedTableBench", "MetalTable", "VendingMachines", "FoodDisplay", "StoreShelf_Food", "RiceCooker", "SnackCart", "WhiteTable" }, gap = { 4.5, 7 }, rise = { 1, 4 }, steps = 22, margin = 0.9 },
	{ id = 5, name = "OPISINA & KLINIKA", sub = "Offices & Clinic", color = Color3.fromRGB(60, 180, 140), giant = { "Bed", 5 },
		props = { "SofaSet", "Bed", "Sofa3", "TrophyShelf", "FilingCabinet", "Bench", "Books" }, gap = { 5, 7.5 }, rise = { 1, 4.2 }, steps = 22, margin = 0.92, vanish = { Books = true } },
	{ id = 6, name = "KAMPUS SA ULAP", sub = "Campus in the Clouds", color = Color3.fromRGB(245, 200, 60), giant = { "MainGate", 3 },
		props = { "Whiteboard", "Globe", "ILoveSC", "MainGate", "Books", "Globe" }, gap = { 5.5, 8 }, rise = { 1, 4.4 }, steps = 22, margin = 0.94, vanish = { Books = true } },
}

---------------------------------------------------------------- helpers
local rng
local function rand(a, b) return a + (b - a) * rng:NextNumber() end
local function pick(t) return t[rng:NextInteger(1, #t)] end
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
local function spawnProp(key, parent, scaleOverride)
	local src = LIB:FindFirstChild(key)
	assert(src, "missing prop " .. key)
	local m = src:Clone()
	local cfg = PROPS[key] or { s = 1 }
	local s = scaleOverride or cfg.s
	if s ~= 1 then m:ScaleTo(s) end
	if cfg.lay == "x" then m:PivotTo(m:GetPivot() * CFrame.Angles(0, 0, math.rad(90)))
	elseif cfg.lay == "z" then m:PivotTo(m:GetPivot() * CFrame.Angles(math.rad(90), 0, 0)) end
	local cf = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(cf.Position)
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true d.CanTouch = false end end
	m.Parent = parent
	return m
end
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
local function standables(m, step)
	step = step or 1.25
	local mn, mx = aabb(m)
	if (mx.X - mn.X) * (mx.Z - mn.Z) > 900 then step = 2 end
	local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Include rp.FilterDescendantsInstances = { m } rp.RespectCanCollide = true
	local pts = {}
	for x = mn.X + 0.4, mx.X - 0.4, step do
		for z = mn.Z + 0.4, mx.Z - 0.4, step do
			local hit = workspace:Raycast(Vector3.new(x, mx.Y + 2, z), Vector3.new(0, -(mx.Y - mn.Y) - 4, 0), rp)
			if hit and hit.Normal.Y > 0.72 then
				local up = workspace:Raycast(hit.Position + Vector3.new(0, 0.2, 0), Vector3.new(0, 5.2, 0), rp)
				if not up then table.insert(pts, hit.Position) end
			end
		end
	end
	return pts
end
local function bestJump(A, B, margin)
	local best = math.huge
	for _, a in ipairs(A) do
		for _, b in ipairs(B) do
			local rise = b.Y - a.Y
			if rise <= 5.2 then
				local r = reach(math.max(rise, -40)) + 1.6
				local d = Vector2.new(b.X - a.X, b.Z - a.Z).Magnitude
				local ratio = d / (r * margin)
				if ratio < best then best = ratio end
			end
		end
	end
	return best
end
local function centroid(pts) local s = Vector3.zero for _, p in ipairs(pts) do s += p end return #pts > 0 and s / #pts or nil end
local function mostCentral(pts) local c = centroid(pts) if not c then return nil end local best, bp = math.huge, nil for _, p in ipairs(pts) do local d = (p - c).Magnitude if d < best then best, bp = d, p end end return bp end
-- overlap test; every placed piece keeps 7 studs of headroom above it
local function overlaps(m, placed, pad, skipLast)
	pad = pad or 1.5
	local mn, mx = aabb(m)
	mx += Vector3.new(0, 7, 0)
	for i, o in ipairs(placed) do
		if skipLast and i == #placed and o.model then continue end
		if o.circle then
			local nx, nz = math.clamp(o.c.X, mn.X, mx.X), math.clamp(o.c.Z, mn.Z, mx.Z)
			if Vector2.new(nx - o.c.X, nz - o.c.Z).Magnitude < o.r + pad and mx.Y > o.y0 and mn.Y < o.y1 then return true end
		elseif mn.X < o.mx.X + pad and mx.X > o.mn.X - pad and mn.Y < o.mx.Y + pad and mx.Y > o.mn.Y - pad and mn.Z < o.mx.Z + pad and mx.Z > o.mn.Z - pad then return true end
	end
	return false
end
local function plantOnGround(key, parent, pos, yaw, scale)
	local m = spawnProp(key, parent, scale)
	m:PivotTo(CFrame.new(m:GetPivot().Position) * CFrame.Angles(0, yaw or 0, 0))
	local mn = aabb(m)
	m:PivotTo(m:GetPivot() + (pos - Vector3.new(m:GetPivot().X, mn.Y, m:GetPivot().Z)))
	return m
end

---------------------------------------------------------------- the big island
local function buildIsland(root, startAngle)
	local C, R = M.CENTER, M.ISLAND_R
	local isl = Instance.new("Model") isl.Name = "StartIsland" isl.Parent = root
	local deco = Instance.new("Model") deco.Name = "Scenery" deco.Parent = isl
	local GRASS, DIRT, ROCK, STONE = Color3.fromRGB(86, 160, 72), Color3.fromRGB(120, 86, 56), Color3.fromRGB(110, 104, 98), Color3.fromRGB(196, 190, 178)
	local disc = function(name, d, h, y, color, mat, coll)
		return part(isl, name, Vector3.new(h, d, d), CFrame.new(C + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.rad(90)), color, mat, { Shape = Enum.PartType.Cylinder, CanCollide = coll ~= false })
	end
	disc("Grass", R * 2, 3, -1.5, GRASS, Enum.Material.Grass)
	disc("Dirt", R * 2 - 6, 12, -9, DIRT, Enum.Material.Ground, false)
	-- rocky underside (a rough upside-down mountain)
	for i = 1, 7 do
		local r = R - i * 14
		if r > 6 then
			for k = 1, 5 do
				local a = k / 5 * math.pi * 2 + i
				local off = Vector3.new(math.cos(a) * r * 0.25, 0, math.sin(a) * r * 0.25)
				part(deco, "Rock", Vector3.new(r * 1.5, 18, r * 1.5), CFrame.new(C + off - Vector3.new(0, 10 + i * 13, 0)), ROCK:Lerp(DIRT, (i % 3) / 4), Enum.Material.Slate, { Shape = Enum.PartType.Ball, CanCollide = false })
			end
		end
	end
	for k = 1, 34 do
		local a = k / 34 * math.pi * 2
		part(deco, "Boulder", Vector3.new(14, 12, 14) * rand(0.7, 1.3), CFrame.new(C + Vector3.new(math.cos(a) * (R - 4), -10 + rand(-4, 2), math.sin(a) * (R - 4))), ROCK, Enum.Material.Slate, { Shape = Enum.PartType.Ball, CanCollide = false })
	end
	-- gentle hills
	for k = 1, 6 do
		local a = k / 6 * math.pi * 2 + 0.4
		local r = rand(55, 85)
		part(isl, "Hill", Vector3.new(rand(28, 40), rand(8, 13), rand(28, 40)), CFrame.new(C + Vector3.new(math.cos(a) * r, -2, math.sin(a) * r)), GRASS:Lerp(Color3.fromRGB(110, 180, 80), rand(0, 0.5)), Enum.Material.Grass, { Shape = Enum.PartType.Ball })
	end
	-- stone paths: arrival (west) → centre → start (course side) and → kiosks
	local arrival = C + Vector3.new(-78, 0, 0)
	local startEdge = C + Vector3.new(math.cos(startAngle) * (R - 2), 0, math.sin(startAngle) * (R - 2))
	local function path(a, b, w)
		local mid = (a + b) / 2
		local len = (Vector3.new(b.X, 0, b.Z) - Vector3.new(a.X, 0, a.Z)).Magnitude
		part(isl, "StonePath", Vector3.new(w or 8, 0.3, len + (w or 8)), CFrame.lookAt(Vector3.new(mid.X, C.Y + 0.15, mid.Z), Vector3.new(b.X, C.Y + 0.15, b.Z)), STONE, Enum.Material.Cobblestone, { CanCollide = false })
	end
	path(arrival, C, 9) path(C, startEdge, 9)
	path(C + Vector3.new(-48, 0, 0), C + Vector3.new(-48, 0, -32), 7) path(C + Vector3.new(-48, 0, 0), C + Vector3.new(-48, 0, 32), 7)
	-- plaza with the San Roque fountain
	disc("Plaza", 46, 0.4, 0.2, STONE, Enum.Material.Cobblestone, false)
	plantOnGround("Fountain", isl, C, 0, 1.4)
	-- koi pond + stream + waterfall off the north edge
	local pondPos = C + Vector3.new(10, 0, 62)
	plantOnGround("KoiPond", deco, pondPos, math.rad(90), 1.6)
	local fallAngle = math.rad(95)
	local edge = C + Vector3.new(math.cos(fallAngle) * R, 0, math.sin(fallAngle) * R)
	local streamMid = (pondPos + edge) / 2
	part(deco, "Stream", Vector3.new(6, 0.4, (edge - pondPos).Magnitude), CFrame.lookAt(Vector3.new(streamMid.X, C.Y + 0.25, streamMid.Z), Vector3.new(edge.X, C.Y + 0.25, edge.Z)), Color3.fromRGB(70, 150, 220), Enum.Material.Glass, { Transparency = 0.25, CanCollide = false })
	local fall = part(deco, "Waterfall", Vector3.new(6, 90, 1.2), CFrame.new(edge + Vector3.new(0, -45, 0) + (edge - C).Unit * 2) * CFrame.Angles(0, -fallAngle + math.rad(90), 0), Color3.fromRGB(120, 190, 240), Enum.Material.Glass, { Transparency = 0.3, CanCollide = false })
	local mist = Instance.new("ParticleEmitter") mist.Rate = 30 mist.Lifetime = NumberRange.new(2, 3.5) mist.Speed = NumberRange.new(4, 8) mist.EmissionDirection = Enum.NormalId.Bottom
	mist.Size = NumberSequence.new(2, 5) mist.Transparency = NumberSequence.new(0.5, 1) mist.Color = ColorSequence.new(Color3.new(1, 1, 1)) mist.Parent = fall
	-- trees, lamps, benches, flowers (kept away from paths and key spots)
	local keep = { { p = C, r = 26 }, { p = arrival, r = 14 }, { p = startEdge, r = 18 }, { p = C + Vector3.new(-48, 0, -32), r = 12 }, { p = C + Vector3.new(-48, 0, 32), r = 12 },
		{ p = C + Vector3.new(-92, 0, -46), r = 16 }, { p = C + Vector3.new(-92, 0, 46), r = 14 }, { p = C + Vector3.new(-100, 0, 0), r = 14 }, { p = pondPos, r = 16 } }
	local function free(pos, r)
		if (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(C.X, 0, C.Z)).Magnitude > R - 10 then return false end
		for _, k in ipairs(keep) do if (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(k.p.X, 0, k.p.Z)).Magnitude < k.r + r then return false end end
		local function segDist(a, b) local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z) local t = math.clamp(Vector3.new(pos.X - a.X, 0, pos.Z - a.Z):Dot(ab) / ab:Dot(ab), 0, 1) return (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(a.X + ab.X * t, 0, a.Z + ab.Z * t)).Magnitude end
		if segDist(arrival, C) < r + 6 or segDist(C, startEdge) < r + 6 then return false end
		return true
	end
	local TREES = { "BigTree", "MangoTree", "NarraTree", "CoconutTree", "Palm", "BigTree", "MangoTree" }
	local placedT = 0
	for _ = 1, 160 do
		if placedT >= 18 then break end
		local a, r = rand(0, math.pi * 2), rand(30, R - 14)
		local pos = C + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		if free(pos, 9) then placedT += 1 table.insert(keep, { p = pos, r = 9 }) plantOnGround(pick(TREES), deco, pos, rand(0, 6.28), rand(0.85, 1.15)) end
	end
	for k = 1, 10 do
		local t = k / 11
		local p1 = arrival:Lerp(C, t) + Vector3.new(0, 0, 7)
		if k % 2 == 0 then plantOnGround("ParkLamp", deco, p1, 0) end
		local p2 = C:Lerp(startEdge, t) + (Vector3.new(-(startEdge - C).Z, 0, (startEdge - C).X).Unit * 7)
		if k % 2 == 1 then plantOnGround("ParkLamp", deco, p2, 0) end
	end
	for _ = 1, 60 do
		local a, r = rand(0, math.pi * 2), rand(28, R - 12)
		local pos = C + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		if free(pos, 4) then table.insert(keep, { p = pos, r = 4 }) plantOnGround(rng:NextNumber() < 0.5 and "Flowers" or "ParkBench", deco, pos, rand(0, 6.28), rng:NextNumber() < 0.5 and 1.6 or 1.2) end
	end
	-- welcome board, kiosks, leaderboard, return portal (west side, near the arrival point)
	local board = part(isl, "WelcomeBoard", Vector3.new(1, 12, 26), CFrame.new(C + Vector3.new(-100, 8, 0)), Color3.fromRGB(25, 35, 30), Enum.Material.SmoothPlastic)
	sign(board, Enum.NormalId.Right, "⛰️ PATAAS!\nPARKOUR\nClimb the floating campus to the clouds", Color3.fromRGB(25, 60, 40), Color3.fromRGB(245, 200, 60))
	for _, dz in ipairs({ -12, 12 }) do part(isl, "BoardLeg", Vector3.new(0.8, 4, 0.8), CFrame.new(C + Vector3.new(-100, 0, dz)), Color3.fromRGB(60, 60, 60), Enum.Material.Metal) end
	local function kiosk(name, pos, color, title, text, mode)
		local k = Instance.new("Model") k.Name = name k.Parent = isl
		part(k, "Pad", Vector3.new(12, 0.6, 12), CFrame.new(pos + Vector3.new(0, 0.3, 0)), color, Enum.Material.Neon, { Transparency = 0.35 })
		local post = part(k, "Post", Vector3.new(1.2, 8, 7), CFrame.new(pos + Vector3.new(-5, 4, 0)), Color3.fromRGB(30, 34, 40), Enum.Material.SmoothPlastic)
		sign(post, Enum.NormalId.Right, title .. "\n" .. text, color, Color3.new(1, 1, 1), 26)
		local anchor = part(k, "PromptAnchor", Vector3.new(1, 1, 1), CFrame.new(pos + Vector3.new(0, 2.5, 0)), Color3.new(1, 1, 1), nil, { Transparency = 1, CanCollide = false })
		local pp = Instance.new("ProximityPrompt") pp.ActionText = "Start " .. mode pp.ObjectText = "⛰️ Parkour" pp.HoldDuration = 0.3 pp.MaxActivationDistance = 10 pp.RequiresLineOfSight = false pp.Parent = anchor
		k:SetAttribute("Mode", mode)
		CS:AddTag(k, "SkyClimbKiosk")
		billboard(post, title, color, UDim2.fromOffset(220, 40), Vector3.new(0, 7, 0), 90)
	end
	kiosk("EasyKiosk", C + Vector3.new(-48, 0, -32), Color3.fromRGB(60, 190, 90), "🟢 EASY MODE", "Checkpoints save your progress", "Easy")
	kiosk("HardKiosk", C + Vector3.new(-48, 0, 32), Color3.fromRGB(220, 60, 60), "🔴 HARD MODE", "No checkpoints!\nFall = back to the bottom", "Hard")
	local lb = part(isl, "Leaderboard", Vector3.new(1, 16, 26), CFrame.new(C + Vector3.new(-92, 10, -46)) * CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(20, 24, 30), Enum.Material.SmoothPlastic)
	CS:AddTag(lb, "SkyClimbBoard")
	local portal = Instance.new("Model") portal.Name = "ReturnPortal" portal.Parent = isl
	local pc = C + Vector3.new(-92, 0, 46)
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2
		part(portal, "Ring", Vector3.new(1.2, 1.2, 1.2), CFrame.new(pc + Vector3.new(0, 6 + math.sin(a) * 5.5, math.cos(a) * 5.5)), Color3.fromRGB(120, 200, 255), Enum.Material.Neon, { Shape = Enum.PartType.Ball, CanCollide = false })
	end
	local pf = part(portal, "PortalField", Vector3.new(0.3, 10, 10), CFrame.new(pc + Vector3.new(0, 6, 0)), Color3.fromRGB(150, 220, 255), Enum.Material.ForceField, { CanCollide = false, Transparency = 0.2, Shape = Enum.PartType.Cylinder })
	local pp = Instance.new("ProximityPrompt") pp.ActionText = "Back to campus" pp.ObjectText = "🏫 Samar College" pp.HoldDuration = 0.3 pp.MaxActivationDistance = 10 pp.RequiresLineOfSight = false pp.Parent = pf
	CS:AddTag(pf, "SkyClimbReturn")
	billboard(pf, "🏫 BACK TO CAMPUS", Color3.fromRGB(150, 220, 255), UDim2.fromOffset(220, 40), Vector3.new(0, 8, 0), 90)
	part(isl, "Arrival", Vector3.new(6, 1, 6), CFrame.new(arrival + Vector3.new(0, 0.5, 0)), Color3.new(1, 1, 1), nil, { Transparency = 1, CanCollide = false })
	-- small floating islets around the big one
	for k = 1, 6 do
		local a = k / 6 * math.pi * 2 + 0.6
		if math.abs(math.atan2(math.sin(a - startAngle), math.cos(a - startAngle))) > 0.7 then
			local r = rand(150, 185)
			local pos = C + Vector3.new(math.cos(a) * r, rand(-25, 15), math.sin(a) * r)
			local s = rand(10, 18)
			local ist = Instance.new("Model") ist.Name = "Islet" ist.Parent = deco
			part(ist, "Grass", Vector3.new(2, s * 2, s * 2), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), GRASS, Enum.Material.Grass, { Shape = Enum.PartType.Cylinder })
			part(ist, "Rock", Vector3.new(s * 1.6, s * 1.4, s * 1.6), CFrame.new(pos - Vector3.new(0, s * 0.6, 0)), ROCK, Enum.Material.Slate, { Shape = Enum.PartType.Ball, CanCollide = false })
			plantOnGround(pick(TREES), ist, pos + Vector3.new(0, 1, 0), rand(0, 6.28), 0.8)
		end
	end
	return isl, arrival, startEdge
end

local function checkpoint(root, index, zone, pos, label)
	local cp = Instance.new("Model") cp.Name = ("Checkpoint_%02d"):format(index) cp.Parent = root
	local pad = part(cp, "Pad", Vector3.new(0.4, 7, 7), CFrame.new(pos + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(120, 230, 140), Enum.Material.Neon, { Shape = Enum.PartType.Cylinder, CanCollide = false, Transparency = 0.45 })
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
	seed = seed or os.time()
	rng = Random.new(seed)
	local old = workspace:FindFirstChild("SkyClimb")
	if old then old:Destroy() end
	local root = Instance.new("Folder") root.Name = "SkyClimb" root.Parent = workspace
	root:SetAttribute("BaseY", M.CENTER.Y)
	root:SetAttribute("Seed", seed)
	local C = M.CENTER
	local startAngle = math.rad(-20)
	local island, arrival, startEdge = buildIsland(root, startAngle)
	local course = Instance.new("Folder") course.Name = "Course" course.Parent = root
	local cps = Instance.new("Folder") cps.Name = "Checkpoints" cps.Parent = root
	local placed = { { circle = true, c = C, r = M.ISLAND_R - 6, y0 = C.Y - 3, y1 = C.Y + 32 } }
	local prevPts = {}
	for da = -0.03, 0.03, 0.015 do for _, r in ipairs({ M.ISLAND_R - 7, M.ISLAND_R - 5, M.ISLAND_R - 3 }) do table.insert(prevPts, C + Vector3.new(math.cos(startAngle + da) * r, 0.1, math.sin(startAngle + da) * r)) end end
	local start = part(root, "StartLine", Vector3.new(10, 10, 10), CFrame.new(startEdge + Vector3.new(0, 4, 0)), Color3.new(1, 1, 1), nil, { Transparency = 1, CanCollide = false })
	billboard(start, "⛰️ START — jump onto the street!", Color3.fromRGB(245, 200, 60), UDim2.fromOffset(260, 40), Vector3.new(0, 6, 0), 120)

	local heading = startAngle -- leave the island straight outward
	local stepIndex, cpIndex = 0, 0
	local report, counts = {}, { run = 0, zigzag = 0, beam = 0, drop = 0, giant = 0 }
	local SCRATCH = Vector3.new(0, 3000, 0)
	local lastKey, lastKey2
	local fails = { stand = 0, overlap = 0, bump = 0, ratio = 0 }

	local function exitFor(dir)
		local fromC = centroid(prevPts)
		local side = Vector3.new(-dir.Z, 0, dir.X)
		local exit, best = prevPts[1], -math.huge
		for _, p in ipairs(prevPts) do
			local al = (p - fromC):Dot(dir) - math.abs((p - fromC):Dot(side)) * 0.35
			if al > best then best, exit = al, p end
		end
		return exit
	end
	local function tryPlace(m, exit, dir, yaw, tilt, gapWant, rise, margin)
		m:PivotTo(CFrame.new(SCRATCH) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(tilt.X, 0, tilt.Z))
		local rel = standables(m)
		if #rel < 4 then fails.stand += 1 return nil end
		local piv = m:GetPivot().Position
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
		local shift = (exit + dir * gap + Vector3.new(0, rise, 0)) - near
		m:PivotTo(m:GetPivot() + shift)
		if overlaps(m, placed, nil, true) then fails.overlap += 1 return nil end
		local last = placed[#placed]
		if last and last.model then
			local op = OverlapParams.new() op.FilterType = Enum.RaycastFilterType.Include op.FilterDescendantsInstances = { last.model } op.RespectCanCollide = true
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") and d.CanCollide and #workspace:GetPartsInPart(d, op) > 0 then fails.overlap += 1 return nil end
			end
		end
		local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Include rp.FilterDescendantsInstances = { m } rp.RespectCanCollide = true
		for _, o in ipairs({ Vector3.zero, dir * 2, dir * 4, dir * gap * 0.5 }) do
			if workspace:Raycast(exit + o + Vector3.new(0, 0.5, 0), Vector3.new(0, 8, 0), rp) then fails.bump += 1 return nil end
		end
		local pts = {}
		for _, p in ipairs(rel) do table.insert(pts, p + shift) end
		local ratio = bestJump(prevPts, pts, margin)
		if ratio > 1.001 then fails.ratio += 1 return nil end
		return pts, ratio
	end

	-- steer the heading: random drift, stay inside the wander circle, don't cross low over the island
	local function steer(kind)
		local cur = centroid(prevPts)
		local rel = Vector3.new(cur.X - C.X, 0, cur.Z - C.Z)
		local d = rel.Magnitude
		local drift = kind == "beam" and 0.12 or 0.42
		heading += rand(-drift, drift)
		local toward = math.atan2(-rel.Z, -rel.X)
		local away = math.atan2(rel.Z, rel.X)
		local function turnTo(target, k)
			local diff = math.atan2(math.sin(target - heading), math.cos(target - heading))
			heading += diff * k
		end
		if d > M.WANDER_R * 0.8 then turnTo(toward, math.clamp((d - M.WANDER_R * 0.8) / (M.WANDER_R * 0.2), 0.2, 0.7)) end
		if d < M.ISLAND_R + 30 and cur.Y < C.Y + 45 then turnTo(away, 0.5) end
	end

	local function placeStep(zone, kind, opts)
		opts = opts or {}
		local margin = opts.margin or zone.margin
		local keys
		if opts.keys then keys = table.clone(opts.keys)
		elseif kind == "beam" then keys = table.clone(BEAMS)
		else keys = table.clone(zone.props) end
		for i = #keys, 2, -1 do local j = rng:NextInteger(1, i) keys[i], keys[j] = keys[j], keys[i] end
		-- variety: the object used in the last two steps goes to the back of the list
		for _, lk in ipairs({ lastKey2, lastKey }) do
			local i = lk and table.find(keys, lk)
			if i and #keys > 2 then table.remove(keys, i) table.insert(keys, lk) end
		end
		if kind == "giant" then for _, gg in ipairs(GIANTS) do if not table.find(keys, gg[1]) then table.insert(keys, gg[1]) end end end
		table.insert(keys, "Books")
		local baseHeading = heading
		for _, hOff in ipairs({ 0, 0.7, -0.7, 1.4, -1.4, 2.2, -2.2 }) do
			local h = baseHeading + hOff + (opts.turn or 0)
			local dir = Vector3.new(math.cos(h), 0, math.sin(h))
			local exit = exitFor(dir)
			for _, k in ipairs(keys) do
				local sc = opts.scale
				if kind == "giant" and opts.keys and k ~= opts.keys[1] then sc = nil for _, gg in ipairs(GIANTS) do if gg[1] == k then sc = gg[2] end end end
				local m = spawnProp(k, course, k ~= "Books" and sc or nil)
				local size = m:GetExtentsSize()
				local alongYaw = math.atan2(-dir.X, -dir.Z) + (size.X > size.Z and math.rad(90) or 0)
				for attempt = 1, 4 do
					local yaw = alongYaw + math.rad(({ 0, 180, 90, 270 })[attempt]) + math.rad(rand(-20, 20))
					local tmax = (kind == "giant" or kind == "beam") and 3 or 9
					local tilt = Vector3.new(math.rad(rand(-tmax, tmax)), 0, math.rad(rand(-tmax, tmax)))
					local gap = opts.gap or rand(zone.gap[1], zone.gap[2])
					local rise = opts.rise or rand(zone.rise[1], zone.rise[2])
					local pts, ratio = tryPlace(m, exit, dir, yaw, tilt, gap, rise, margin)
					if pts then
						local mn2, mx2 = aabb(m)
						table.insert(placed, { mn = mn2, mx = mx2 + Vector3.new(0, 7, 0), model = m })
						stepIndex += 1
						counts[kind] += 1
						m.Name = ("Z%d_%03d_%s_%s"):format(zone.id, stepIndex, kind, k)
						m:SetAttribute("Step", stepIndex) m:SetAttribute("Zone", zone.id) m:SetAttribute("Kind", kind)
						if zone.vanish and zone.vanish[k] and not opts.solid then CS:AddTag(m, "SkyClimbVanish") end
						prevPts = pts
						lastKey2, lastKey = lastKey, k
						if opts.turn == nil then heading = h end
						table.insert(report, ("%s jump=%.2f"):format(m.Name, ratio))
						return m, pts
					end
				end
				m:Destroy()
			end
		end
		error(("could not place step %d (%s) fails stand=%d overlap=%d bump=%d ratio=%d at %s\n"):format(stepIndex + 1, kind, fails.stand, fails.overlap, fails.bump, fails.ratio, tostring(centroid(prevPts))) .. table.concat(report, "\n", math.max(1, #report - 10)))
	end

	for _, zone in ipairs(M.ZONES) do
		-- zone start: an oversized landmark with checkpoint + sign
		steer("giant")
		local g = zone.giant
		local restM, restPts = placeStep(zone, "giant", { keys = { g[1] }, scale = g[2], gap = zone.id == 1 and 6.5 or 4.5, rise = 2.5, solid = true })
		cpIndex += 1
		local cpPos = mostCentral(restPts)
		checkpoint(cps, cpIndex, zone.id, cpPos, ("🚩 ZONE %d • %s"):format(zone.id, zone.name))
		local zs = part(restM, "ZoneSign", Vector3.new(1, 1, 1), CFrame.new(cpPos + Vector3.new(0, 9, 0)), Color3.new(1, 1, 1), nil, { Transparency = 1, CanCollide = false })
		billboard(zs, ("ZONE %d\n%s\n(%s)"):format(zone.id, zone.name, zone.sub), zone.color, UDim2.fromOffset(320, 90), Vector3.zero, 110)
		restM:SetAttribute("ZoneStart", zone.id)
		root:SetAttribute("Zone" .. zone.id .. "Y", cpPos.Y)
		root:SetAttribute("Zone" .. zone.id .. "Name", zone.name)
		local done, midDone = 0, false
		local lastKind = "giant"
		while done < zone.steps do
			local r = rng:NextNumber()
			local kind
			if r < 0.42 then kind = "run" elseif r < 0.64 then kind = "zigzag" elseif r < 0.82 then kind = "beam" elseif r < 0.92 then kind = "drop" else kind = "giant" end
			if kind == lastKind and (kind == "drop" or kind == "giant") then kind = "run" end
			local cur = centroid(prevPts)
			if kind == "drop" and cur.Y < C.Y + 45 then kind = "zigzag" end
			local len = ({ run = rng:NextInteger(4, 6), zigzag = rng:NextInteger(4, 6), beam = rng:NextInteger(3, 4), drop = 1, giant = 1 })[kind]
			local side = rng:NextNumber() < 0.5 and 1 or -1
			for i = 1, len do
				if done >= zone.steps then break end
				local opts = {}
				local wantMid = not midDone and done >= math.floor(zone.steps / 2)
				if wantMid then opts.solid = true end
				if kind == "run" then steer("run")
				elseif kind == "zigzag" then
					steer("zigzag")
					opts.turn = side * math.rad(rand(55, 75)) side = -side
					opts.rise = rand(3.4, 4.6) opts.gap = rand(2.5, 4.2)
				elseif kind == "beam" then
					steer("beam")
					opts.gap = rand(2, 3.5) opts.rise = rand(-0.5, 1.2)
				elseif kind == "drop" then
					steer("run")
					opts.rise = -rand(6, 11) opts.gap = rand(4, 7)
				elseif kind == "giant" then
					steer("giant")
					local gg = pick(GIANTS)
					opts.keys = { gg[1] } opts.scale = gg[2] opts.gap = rand(4, 6) opts.rise = rand(1.5, 3) opts.solid = true
				end
				local m, pts = placeStep(zone, kind, opts)
				done += 1
				if wantMid then
					midDone = true
					cpIndex += 1
					checkpoint(cps, cpIndex, zone.id, mostCentral(pts))
				end
			end
			lastKind = kind
			task.wait()
		end
	end

	-- summit
	local fin = Instance.new("Model") fin.Name = "Finish" fin.Parent = root
	steer("run")
	local dir, exit, fc
	for _, hOff in ipairs({ 0, 0.6, -0.6, 1.2, -1.2, 1.9, -1.9, 2.6, -2.6, 3.14 }) do
		dir = Vector3.new(math.cos(heading + hOff), 0, math.sin(heading + hOff))
		exit = exitFor(dir)
		fc = exit + dir * (5 + 26) + Vector3.new(0, 2, 0)
		local bmn, bmx = fc - Vector3.new(27, 5, 27), fc + Vector3.new(27, 32, 27)
		local clear = true
		for _, o in ipairs(placed) do
			if not o.circle and bmn.X < o.mx.X and bmx.X > o.mn.X and bmn.Y < o.mx.Y and bmx.Y > o.mn.Y and bmn.Z < o.mx.Z and bmx.Z > o.mn.Z then
				-- the last step itself always touches the summit's box; ignore it
				if not (o == placed[#placed]) then clear = false break end
			end
		end
		if clear then break end
	end
	part(fin, "Summit", Vector3.new(3, 52, 52), CFrame.new(fc - Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(240, 240, 235), Enum.Material.Marble, { Shape = Enum.PartType.Cylinder })
	part(fin, "SummitGold", Vector3.new(1, 54, 54), CFrame.new(fc - Vector3.new(0, 3.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(245, 200, 60), Enum.Material.Foil, { Shape = Enum.PartType.Cylinder })
	for k = 1, 10 do local a = k / 10 * math.pi * 2 part(fin, "Cloud", Vector3.new(20, 9, 14), CFrame.new(fc + Vector3.new(math.cos(a) * 26, -7, math.sin(a) * 26)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball, CanCollide = false, Transparency = 0.15 }) end
	local sideV = Vector3.new(-dir.Z, 0, dir.X)
	plantOnGround("ILoveSC", fin, fc + dir * 16, math.atan2(-sideV.X, -sideV.Z), 3)
	plantOnGround("Trophy", fin, fc + dir * 8 + sideV * 12, 0, 8)
	plantOnGround("Flag", fin, fc + dir * 8 - sideV * 13, 0, 1)
	local goal = part(fin, "FinishTrigger", Vector3.new(36, 10, 36), CFrame.new(fc + Vector3.new(0, 5, 0)), Color3.new(1, 1, 1), nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	goal.CanTouch = true
	CS:AddTag(goal, "SkyClimbFinish")
	billboard(goal, "🏆 SUMMIT — YOU MADE IT!", Color3.fromRGB(245, 200, 60), UDim2.fromOffset(320, 50), Vector3.new(0, 14, 0), 300)
	local back = part(fin, "SummitPortal", Vector3.new(0.4, 9, 9), CFrame.new(fc - dir * 14 + Vector3.new(0, 5, 0) + sideV * 10) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(150, 220, 255), Enum.Material.ForceField, { CanCollide = false, Shape = Enum.PartType.Cylinder })
	local pp = Instance.new("ProximityPrompt") pp.ActionText = "Back to start island" pp.ObjectText = "⛰️ Parkour" pp.HoldDuration = 0.3 pp.RequiresLineOfSight = false pp.MaxActivationDistance = 10 pp.Parent = back
	CS:AddTag(back, "SkyClimbToStart")
	local fmn, fmx = aabb(fin)
	table.insert(placed, { mn = fmn, mx = fmx + Vector3.new(0, 10, 0) })

	-- floating junk + clouds around the course (decoration, Only-Up style chaos)
	local junk = Instance.new("Folder") junk.Name = "FloatingJunk" junk.Parent = root
	local cmn, cmx = Vector3.new(math.huge, math.huge, math.huge), -Vector3.new(math.huge, math.huge, math.huge)
	for _, m in ipairs(course:GetChildren()) do local a, b = aabb(m) cmn = cmn:Min(a) cmx = cmx:Max(b) end
	local nJunk = 0
	for _ = 1, 420 do
		if nJunk >= 150 then break end
		local p = Vector3.new(rand(cmn.X - 40, cmx.X + 40), rand(C.Y + 30, cmx.Y + 30), rand(cmn.Z - 40, cmx.Z + 40))
		local k = pick(JUNK)
		local m = spawnProp(k, junk, (PROPS[k] and PROPS[k].s or 1) * rand(0.6, 1.5))
		m:PivotTo(CFrame.new(p) * CFrame.Angles(rand(0, 6.28), rand(0, 6.28), rand(0, 6.28)))
		if overlaps(m, placed, 9) then m:Destroy() else
			nJunk += 1
			local jmn, jmx = aabb(m)
			table.insert(placed, { mn = jmn, mx = jmx })
		end
		if nJunk % 25 == 0 then task.wait() end
	end
	for _ = 1, 45 do
		local p = Vector3.new(rand(cmn.X - 80, cmx.X + 80), rand(C.Y - 30, cmx.Y + 60), rand(cmn.Z - 80, cmx.Z + 80))
		local cl = Instance.new("Model") cl.Name = "Cloud" cl.Parent = junk
		for _ = 1, rng:NextInteger(3, 6) do
			part(cl, "Puff", Vector3.new(rand(14, 26), rand(8, 13), rand(12, 20)), CFrame.new(p + Vector3.new(rand(-14, 14), rand(-3, 3), rand(-8, 8))), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball, CanCollide = false, CanQuery = false, Transparency = 0.12, CastShadow = false })
		end
	end

	root:SetAttribute("TopY", fc.Y)
	root:SetAttribute("Steps", stepIndex)
	root:SetAttribute("Checkpoints", cpIndex)
	for _, m in ipairs(course:GetChildren()) do for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.CanTouch = CS:HasTag(m, "SkyClimbVanish") end end end
	return ("seed=%d steps=%d checkpoints=%d topY=%.0f height=%.0f junk=%d\nsegments: run %d · zigzag %d · beam %d · drop %d · giant %d\n%s"):format(seed, stepIndex, cpIndex, fc.Y, fc.Y - C.Y, nJunk,
		counts.run, counts.zigzag, counts.beam, counts.drop, counts.giant, table.concat(report, "\n", math.max(1, #report - 25)))
end

return M
