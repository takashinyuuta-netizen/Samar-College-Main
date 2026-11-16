-- SR_BuildLib: helpers used to build the San Roque Street east-lot buildings.
-- Local frame per building: u = along the street (+Z), y = up from the sidewalk, w = depth from the front wall (+X, into the lot;
-- negative w = toward the street). Boxes are given by their MIN corner + size.
local L = {}

L.C = {
	white = Color3.fromRGB(228, 226, 216), dirtyWhite = Color3.fromRGB(205, 203, 192), cream = Color3.fromRGB(226, 214, 186),
	grime = Color3.fromRGB(110, 112, 100), grey = Color3.fromRGB(150, 150, 146), block = Color3.fromRGB(128, 128, 124),
	darkGrey = Color3.fromRGB(70, 72, 74), black = Color3.fromRGB(28, 28, 30), wood = Color3.fromRGB(110, 74, 46),
	darkWood = Color3.fromRGB(66, 44, 30), rust = Color3.fromRGB(150, 82, 52), zinc = Color3.fromRGB(176, 182, 184),
	blueRoof = Color3.fromRGB(40, 90, 200), green = Color3.fromRGB(56, 140, 70), teal = Color3.fromRGB(40, 170, 150),
	yellow = Color3.fromRGB(236, 196, 70), red = Color3.fromRGB(196, 40, 40), pink = Color3.fromRGB(226, 90, 150),
	glass = Color3.fromRGB(120, 160, 180), leaf = Color3.fromRGB(70, 140, 50), leaf2 = Color3.fromRGB(100, 170, 60),
	terracotta = Color3.fromRGB(176, 92, 60), steel = Color3.fromRGB(90, 96, 104),
}
local M = Enum.Material

local B = {}
B.__index = B

function L.new(parent, name, z0, fx, y0)
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
	local m = Instance.new("Model") m.Name = name m.Parent = parent
	return setmetatable({ model = m, z0 = z0, fx = fx or 21, y0 = y0 or 1.5, groups = {}, rng = Random.new(#name * 7919) }, B)
end

function B:group(name)
	local g = self.groups[name]
	if g then return g end
	g = Instance.new("Model") g.Name = name g.Parent = self.model
	self.groups[name] = g
	return g
end

function B:world(u, y, w) return Vector3.new(self.fx + w, self.y0 + y, self.z0 + u) end

local function finish(p, color, mat, props)
	p.Anchored = true p.Color = color p.Material = mat or M.Concrete
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	if props then for k, v in pairs(props) do p[k] = v end end
end

-- axis-aligned box by min corner
function B:box(group, name, u, y, w, su, sy, sw, color, mat, props)
	local p = Instance.new("Part") p.Name = name
	p.Size = Vector3.new(math.max(sw, 0.05), math.max(sy, 0.05), math.max(su, 0.05))
	p.CFrame = CFrame.new(self.fx + w + sw / 2, self.y0 + y + sy / 2, self.z0 + u + su / 2)
	finish(p, color, mat, props)
	p.Parent = self:group(group)
	return p
end
-- decoration box: no collision, no shadow, no queries
function B:deco(group, name, u, y, w, su, sy, sw, color, mat, props)
	local p = self:box(group, name, u, y, w, su, sy, sw, color, mat, props)
	p.CanCollide = false p.CastShadow = false p.CanQuery = false p.CanTouch = false
	return p
end

-- sloped slab from the outer edge (wOut,yOut) up to the inner edge (wIn,yIn), spanning u..u+su
function B:slope(group, name, u, su, wOut, yOut, wIn, yIn, th, color, mat, props)
	local dx, dy = wIn - wOut, yIn - yOut
	local p = Instance.new("Part") p.Name = name
	p.Size = Vector3.new(math.sqrt(dx * dx + dy * dy), th, su)
	p.CFrame = CFrame.new(self.fx + (wOut + wIn) / 2, self.y0 + (yOut + yIn) / 2, self.z0 + u + su / 2) * CFrame.Angles(0, 0, math.atan2(dy, dx))
	finish(p, color, mat, props)
	p.Parent = self:group(group)
	return p
end

-- corrugated sheet roof / awning (sheet + ribs); rustStreaks adds rust patches
function B:corrugated(group, u, su, wOut, yOut, wIn, yIn, color, mat, opts)
	opts = opts or {}
	self:slope(group, "Sheet", u, su, wOut, yOut, wIn, yIn, 0.2, color, mat or M.Metal)
	local step = opts.rib or 1.4
	local ribColor = opts.ribColor or color:Lerp(Color3.new(1, 1, 1), 0.12)
	for k = u + step / 2, u + su - 0.1, step do
		local r = self:slope(group, "Rib", k, 0.25, wOut, yOut + 0.12, wIn, yIn + 0.12, 0.12, ribColor, mat or M.Metal)
		r.CanCollide = false r.CastShadow = false
	end
	if opts.rust then
		for _ = 1, opts.rust do
			local a = self.rng:NextNumber(0, su - 3)
			local f = self.rng:NextNumber(0.1, 0.7)
			local wa, ya = wOut + (wIn - wOut) * f, yOut + (yIn - yOut) * f
			local wb, yb = wOut + (wIn - wOut) * math.min(1, f + 0.3), yOut + (yIn - yOut) * math.min(1, f + 0.3)
			local r = self:slope(group, "Rust", u + a, self.rng:NextNumber(1.5, 3.5), wa, ya + 0.15, wb, yb + 0.15, 0.05, L.C.rust, M.CorrodedMetal)
			r.CanCollide = false r.CastShadow = false
		end
	end
	-- support brackets
	if opts.brackets then
		for k = u + 0.5, u + su, opts.brackets do
			local br = self:slope(group, "Bracket", k, 0.25, wOut + 0.6, yOut - 0.35, wIn, yIn - 0.35, 0.3, opts.bracketColor or L.C.steel, M.Metal)
			br.CanCollide = false
		end
	end
end

-- window on the FRONT face (w = 0 plane), frame + glass + optional grille / sill / curtain
function B:window(group, u, y, su, sy, opts)
	opts = opts or {}
	local fc = opts.frame or L.C.white
	local t = opts.ft or 0.3
	local w0 = opts.w or 0
	self:deco(group, "Glass", u, y, w0 - 0.15, su, sy, 0.1, opts.glass or L.C.glass, M.Glass, { Transparency = opts.clear and 0.55 or 0.25, Reflectance = 0.08 })
	if opts.curtain then self:deco(group, "Curtain", u + 0.2, y + 0.4, w0 + 0.05, su * 0.45, sy - 0.6, 0.08, opts.curtain, M.Fabric) end
	self:deco(group, "FrameT", u - t, y + sy, w0 - 0.3, su + 2 * t, t, 0.4, fc, M.SmoothPlastic)
	self:deco(group, "FrameB", u - t, y - t, w0 - 0.3, su + 2 * t, t, 0.4, fc, M.SmoothPlastic)
	self:deco(group, "FrameL", u - t, y, w0 - 0.3, t, sy, 0.4, fc, M.SmoothPlastic)
	self:deco(group, "FrameR", u + su, y, w0 - 0.3, t, sy, 0.4, fc, M.SmoothPlastic)
	if opts.mullion ~= false and su > 2.5 then self:deco(group, "Mullion", u + su / 2 - 0.1, y, w0 - 0.25, 0.2, sy, 0.25, fc, M.SmoothPlastic) end
	if opts.sill then self:deco(group, "Sill", u - t - 0.2, y - t - 0.3, w0 - 0.8, su + 2 * t + 0.4, 0.3, 0.9, opts.sill, M.Concrete) end
	if opts.grille then
		local gc = opts.grilleColor or L.C.white
		for k = u + 0.4, u + su - 0.2, opts.grilleStep or 0.7 do self:deco(group, "Grille", k, y, w0 - 0.55, 0.1, sy, 0.1, gc, M.Metal) end
		for k = y + 0.8, y + sy - 0.2, 1.6 do self:deco(group, "GrilleH", u, k, w0 - 0.55, su, 0.1, 0.1, gc, M.Metal) end
	end
	if opts.aircon then
		self:deco(group, "AirconBody", u + su / 2 - 1.1, y - 1.9, w0 - 1.6, 2.2, 1.6, 1.6, Color3.fromRGB(225, 225, 220), M.SmoothPlastic)
		self:deco(group, "AirconGrill", u + su / 2 - 0.9, y - 1.7, w0 - 1.65, 1.8, 1.2, 0.05, Color3.fromRGB(150, 150, 150), M.DiamondPlate)
	end
end

-- vertical bars (grille fences, gates, railings) along u
function B:bars(group, u, y, w, su, sy, step, color, thick)
	thick = thick or 0.15
	for k = u, u + su + 0.001, step do self:deco(group, "Bar", k, y, w, thick, sy, thick, color, M.Metal) end
	self:deco(group, "RailTop", u, y + sy - 0.15, w - 0.05, su + thick, 0.2, thick + 0.1, color, M.Metal)
	self:deco(group, "RailMid", u, y + sy * 0.45, w - 0.05, su + thick, 0.15, thick + 0.1, color, M.Metal)
end
-- same but running along w (side fences)
function B:barsW(group, u, y, w, sw, sy, step, color, thick)
	thick = thick or 0.15
	for k = w, w + sw + 0.001, step do self:deco(group, "Bar", u, y, k, thick, sy, thick, color, M.Metal) end
	self:deco(group, "RailTop", u - 0.05, y + sy - 0.15, w, thick + 0.1, 0.2, sw + thick, color, M.Metal)
end

-- potted plant / leafy cluster; size ~ overall height
function B:plant(group, u, y, w, size, opts)
	opts = opts or {}
	local r = self.rng
	if opts.pot ~= false then
		local pot = self:deco(group, "Pot", u - size * 0.22, y, w - size * 0.22, size * 0.44, size * 0.35, size * 0.44, opts.potColor or L.C.terracotta, M.Concrete)
		pot.Shape = Enum.PartType.Block
	end
	local n = opts.n or 3
	for _ = 1, n do
		local s = size * r:NextNumber(0.45, 0.75)
		local ball = self:deco(group, "Leaves", u - s / 2 + r:NextNumber(-0.3, 0.3) * size, y + size * 0.3 + r:NextNumber(0, 0.4) * size, w - s / 2 + r:NextNumber(-0.3, 0.3) * size, s, s, s,
			(r:NextNumber() < 0.5) and L.C.leaf or L.C.leaf2, M.Grass)
		ball.Shape = Enum.PartType.Ball
	end
	if opts.flower then
		for _ = 1, 3 do
			local f = self:deco(group, "Flower", u + r:NextNumber(-0.4, 0.4) * size, y + size * 0.7 + r:NextNumber(0, 0.2) * size, w + r:NextNumber(-0.4, 0.4) * size, 0.35, 0.35, 0.35, opts.flower, M.SmoothPlastic)
			f.Shape = Enum.PartType.Ball
		end
	end
end
-- tall spiky plant (snake plant / palm-ish)
function B:spiky(group, u, y, w, h, color)
	for i = 1, 5 do
		local p = self:deco(group, "Blade", u + (i - 3) * 0.18, y, w + ((i % 2) - 0.5) * 0.3, 0.12, h * self.rng:NextNumber(0.6, 1), 0.4, color or Color3.fromRGB(70, 130, 60), M.Grass)
		p.CFrame = p.CFrame * CFrame.Angles(self.rng:NextNumber(-0.25, 0.25), 0, self.rng:NextNumber(-0.25, 0.25))
	end
end

-- sign on the front with SurfaceGui text lines { {text, colorText, font, weight} }
function B:sign(group, name, u, y, w, su, sy, bg, lines, opts)
	opts = opts or {}
	local p = self:box(group, name, u, y, w, su, sy, opts.thick or 0.3, bg, opts.mat or M.SmoothPlastic)
	p.CanCollide = false
	local g = Instance.new("SurfaceGui") g.Face = Enum.NormalId.Left g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = 30
	g.LightInfluence = 0.6 g.MaxDistance = 250 g.Parent = p
	local frame = Instance.new("Frame") frame.Size = UDim2.fromScale(1, 1) frame.BackgroundTransparency = 1 frame.Parent = g
	local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0.03, 0) pad.PaddingRight = UDim.new(0.03, 0) pad.PaddingTop = UDim.new(0.05, 0) pad.PaddingBottom = UDim.new(0.05, 0) pad.Parent = frame
	local total = 0 for _, l in ipairs(lines) do total += (l[4] or 1) end
	local yy = 0
	for _, l in ipairs(lines) do
		local h = (l[4] or 1) / total
		local t = Instance.new("TextLabel") t.BackgroundTransparency = 1 t.Size = UDim2.fromScale(1, h) t.Position = UDim2.fromScale(0, yy)
		t.Text = l[1] t.TextColor3 = l[2] or Color3.new(1, 1, 1) t.Font = l[3] or Enum.Font.GothamBlack t.TextScaled = true
		t.TextXAlignment = opts.align or Enum.TextXAlignment.Center t.Parent = frame
		if l[5] then local s = Instance.new("UIStroke") s.Color = l[5] s.Thickness = 2 s.Parent = t end
		yy += h
	end
	return p
end

-- shop shelf with lots of little colored goods (sari-sari style)
function B:shelf(group, u, y, w, su, sy, sw, rows)
	local r = self.rng
	local frameC = Color3.fromRGB(150, 150, 150)
	self:deco(group, "ShelfBack", u, y, w + sw - 0.1, su, sy, 0.1, Color3.fromRGB(200, 196, 186), M.SmoothPlastic)
	for i = 0, rows do
		local yy = y + i * (sy / rows)
		self:deco(group, "Board", u, yy, w, su, 0.12, sw, frameC, M.Metal)
		if i < rows then
			local k = u + 0.15
			while k < u + su - 0.4 do
				local gw = r:NextNumber(0.25, 0.6)
				local gh = r:NextNumber(0.3, (sy / rows) * 0.8)
				local col = Color3.fromHSV(r:NextNumber(), r:NextNumber(0.5, 0.9), r:NextNumber(0.6, 1))
				self:deco(group, "Goods", k, yy + 0.12, w + r:NextNumber(0.1, 0.4), gw, gh, sw * r:NextNumber(0.4, 0.75), col, M.SmoothPlastic)
				k += gw + 0.05
			end
		end
	end
	for _, k in ipairs({ u, u + su - 0.12 }) do self:deco(group, "Post", k, y, w, 0.12, sy, sw, frameC, M.Metal) end
end

-- hanging goods (snack strips / sachets) on a wire across the opening
function B:hangers(group, u, y, w, su)
	local r = self.rng
	self:deco(group, "HangWire", u, y, w, su, 0.06, 0.06, L.C.black, M.Metal)
	for k = u + 0.3, u + su - 0.3, 0.45 do
		local len = r:NextNumber(1.2, 2.6)
		self:deco(group, "Sachets", k, y - len, w, 0.35, len, 0.05, Color3.fromHSV(r:NextNumber(), 0.75, 0.95), M.SmoothPlastic)
	end
end

-- laundry on a line
function B:laundry(group, u, y, w, su, along)
	local r = self.rng
	self:deco(group, "Clothesline", u, y, w, su, 0.05, 0.05, Color3.fromRGB(230, 230, 230), M.SmoothPlastic)
	local k = u + 0.3
	while k < u + su - 1 do
		local cw = r:NextNumber(0.9, 1.8)
		local ch = r:NextNumber(1.2, 2.6)
		local col = ({ Color3.fromRGB(30, 40, 90), Color3.fromRGB(230, 230, 235), Color3.fromRGB(40, 40, 45), Color3.fromRGB(200, 60, 60), Color3.fromRGB(80, 120, 200), Color3.fromRGB(240, 210, 90), Color3.fromRGB(60, 140, 90) })[r:NextInteger(1, 7)]
		self:deco(group, "Clothes", k, y - ch, w - 0.05, cw, ch, 0.12, col, M.Fabric)
		k += cw + r:NextNumber(0.1, 0.5)
	end
end

-- grime streaks under slabs / on walls (front face)
function B:grime(group, u, y, su, sy, n, w)
	local r = self.rng
	for _ = 1, n do
		local sw = r:NextNumber(0.4, 1.4)
		local sh = r:NextNumber(sy * 0.3, sy)
		self:deco(group, "Grime", u + r:NextNumber(0, su - sw), y + sy - sh, (w or 0) - 0.06, sw, sh, 0.05, L.C.grime, M.Concrete, { Transparency = r:NextNumber(0.55, 0.8) })
	end
end

-- wall facing the street (plane at depth w, thickness t) from u0..u1, y..y+h, with openings { {ua, ub, ya, yb}, ... } (y relative to wall base)
function B:wallU(group, name, w, t, u0, u1, y, h, color, mat, openings)
	openings = openings or {}
	table.sort(openings, function(a, b) return a[1] < b[1] end)
	local cur = u0
	for _, o in ipairs(openings) do
		if o[1] > cur then self:box(group, name, cur, y, w, o[1] - cur, h, t, color, mat) end
		if o[3] > 0 then self:box(group, name, o[1], y, w, o[2] - o[1], o[3], t, color, mat) end
		if o[4] < h then self:box(group, name, o[1], y + o[4], w, o[2] - o[1], h - o[4], t, color, mat) end
		cur = o[2]
	end
	if cur < u1 then self:box(group, name, cur, y, w, u1 - cur, h, t, color, mat) end
end
-- slab sloping along u (gable roofs whose ridge runs along w): from (uLow,yLow) up to (uHigh,yHigh), spanning w..w+sw
function B:slopeU(group, name, w, sw, uLow, yLow, uHigh, yHigh, th, color, mat)
	local du, dy = uHigh - uLow, yHigh - yLow
	local p = Instance.new("Part") p.Name = name
	p.Size = Vector3.new(sw, th, math.sqrt(du * du + dy * dy))
	p.CFrame = CFrame.new(self.fx + w + sw / 2, self.y0 + (yLow + yHigh) / 2, self.z0 + (uLow + uHigh) / 2) * CFrame.Angles(-math.atan2(dy, du), 0, 0)
	finish(p, color, mat or M.Metal)
	p.Parent = self:group(group)
	return p
end

-- concrete pole + cables helper (world points)
function L.wire(parent, a, b, thick, color)
	local d = b - a
	local p = Instance.new("Part") p.Name = "Wire" p.Anchored = true p.CanCollide = false p.CastShadow = false p.CanQuery = false p.CanTouch = false
	p.Size = Vector3.new(thick or 0.12, thick or 0.12, d.Magnitude) p.CFrame = CFrame.lookAt(a + d / 2, b)
	p.Color = color or Color3.fromRGB(25, 25, 25) p.Material = M.SmoothPlastic
	p.Parent = parent
	return p
end

-- clone a prop model (ServerStorage.SkyClimbProps) to a world position, scaled
function L.prop(parent, name, pos, scale, yaw)
	local src = game.ServerStorage:FindFirstChild("SkyClimbProps") and game.ServerStorage.SkyClimbProps:FindFirstChild(name)
	if not src then return nil end
	local m = src:Clone()
	if scale and scale ~= 1 then m:ScaleTo(scale) end
	local cf, size = m:GetBoundingBox()
	local bottom = cf.Position - Vector3.new(0, size.Y / 2, 0)
	-- move the bounding box's bottom-centre to pos, turning around it
	m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, yaw or 0, 0) * CFrame.new(-bottom) * m:GetPivot())
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
	m.Parent = parent
	return m
end

return L
