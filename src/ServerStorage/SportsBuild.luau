-- SportsBuild: helpers used in Studio to build sports courts (not used at runtime).
local B = {}
local SMOOTH = Enum.SurfaceType.Smooth
B.DECO = { CanCollide = false, CastShadow = false, CanQuery = false, CanTouch = false }
function B.P(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part") p.Name = name p.Size = size p.CFrame = cf p.Color = color or Color3.new(1, 1, 1)
	p.Material = mat or Enum.Material.SmoothPlastic p.Anchored = true p.TopSurface = SMOOTH p.BottomSurface = SMOOTH p.CanTouch = false
	if props then for k, v in pairs(props) do p[k] = v end end
	p.Parent = parent return p
end
function B.cyl(parent, name, len, d, cf, color, mat, props) -- along local X
	local p = B.P(parent, name, Vector3.new(len, d, d), cf, color, mat, props) p.Shape = Enum.PartType.Cylinder return p
end
function B.vcyl(parent, name, h, d, cf, color, mat, props)
	return B.cyl(parent, name, h, d, cf * CFrame.Angles(0, 0, math.rad(90)), color, mat, props)
end
function B.sign(p, face, text, bg, fg, font, ppS)
	local g = Instance.new("SurfaceGui") g.Name = "Sign_" .. face.Name g.Face = face g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = ppS or 40 g.LightInfluence = 0.2 g.MaxDistance = 140 g.Parent = p
	local t = Instance.new("TextLabel") t.Name = "Text" t.Size = UDim2.fromScale(1, 1) t.BackgroundColor3 = bg or Color3.new(0, 0, 0)
	t.BackgroundTransparency = bg and 0 or 1 t.TextColor3 = fg or Color3.new(1, 1, 1) t.Font = font or Enum.Font.GothamBlack t.TextScaled = true t.Text = text t.Parent = g
	return g, t
end
-- painted line on a floor (cf = floor-top centre frame)
function B.line(parent, cf, x1, z1, x2, z2, w, color)
	local a, b = Vector3.new(x1, 0, z1), Vector3.new(x2, 0, z2)
	local len = (b - a).Magnitude
	local mid = (a + b) / 2
	local horiz = math.abs(x2 - x1) > math.abs(z2 - z1)
	return B.P(parent, "Line", horiz and Vector3.new(len + w, 0.04, w) or Vector3.new(w, 0.04, len + w), cf * CFrame.new(mid.X, 0.02, mid.Z), color or Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, B.DECO)
end
-- bleachers: rows of benches with real Seats facing the court. cf: front-bottom centre, -Z looks at the court
function B.bleachers(parent, cf, length, tiers, courtId, color)
	local m = Instance.new("Model") m.Name = "Bleachers" m.Parent = parent
	for t = 0, tiers - 1 do
		local z, y = t * 2.4, t * 1.3
		B.P(m, "Step", Vector3.new(length, 1.3 + y, 2.4), cf * CFrame.new(0, (1.3 + y) / 2, z + 1.2), Color3.fromRGB(150, 155, 165), Enum.Material.Concrete)
		B.P(m, "Bench", Vector3.new(length - 0.6, 0.35, 1.3), cf * CFrame.new(0, 1.3 + y + 1.15, z + 1.5), color or Color3.fromRGB(40, 110, 200), Enum.Material.SmoothPlastic)
		for _, lx in ipairs({ -length / 2 + 1, 0, length / 2 - 1 }) do B.P(m, "BenchLeg", Vector3.new(0.3, 0.9, 1), cf * CFrame.new(lx, 1.3 + y + 0.5, z + 1.5), Color3.fromRGB(70, 70, 75), Enum.Material.Metal) end
		local n = math.floor((length - 1) / 2.3)
		for k = 0, n - 1 do
			local s = Instance.new("Seat") s.Name = "CourtSeat" s.Size = Vector3.new(1.6, 0.2, 1.2) s.Anchored = true s.CanCollide = false s.Transparency = 1
			s.CFrame = cf * CFrame.new(-length / 2 + 1.4 + k * 2.3, 1.3 + y + 1.4, z + 1.5) s:SetAttribute("CourtId", courtId) s.Parent = m
		end
	end
	B.P(m, "BackRail", Vector3.new(length, 0.25, 0.25), cf * CFrame.new(0, tiers * 1.3 + 3.2, tiers * 2.4 - 0.1), Color3.fromRGB(200, 200, 205), Enum.Material.Metal, B.DECO)
	return m
end
-- invisible marker
function B.marker(parent, name, cf)
	return B.P(parent, name, Vector3.new(1, 1, 1), cf, Color3.new(1, 0, 0), Enum.Material.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, CastShadow = false })
end
-- a floating island: rock underside + grass top + trees + little floating rocks.
-- returns the CFrame of the grass top centre (y = walking height)
function B.island(parent, center, radius, seed)
	local r = Random.new(seed or 7)
	local m = Instance.new("Model") m.Name = "Island" m.Parent = parent
	local function disc(name, dia, h, y, color, mat, props)
		local p = B.P(m, name, Vector3.new(h, dia, dia), CFrame.new(center + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.rad(90)), color, mat, props)
		p.Shape = Enum.PartType.Cylinder return p
	end
	disc("Grass", radius * 2, 2, -1, Color3.fromRGB(90, 160, 70), Enum.Material.Grass)
	disc("GrassEdge", radius * 2 + 1.2, 1.4, -1.6, Color3.fromRGB(70, 130, 55), Enum.Material.Grass)
	disc("Dirt", radius * 2 - 1, 5, -4.7, Color3.fromRGB(120, 85, 55), Enum.Material.Ground)
	local layers = { { 0.92, 8, -11 }, { 0.75, 9, -19 }, { 0.55, 10, -28 }, { 0.34, 10, -37 }, { 0.15, 9, -45 } }
	for i, L in ipairs(layers) do disc("Rock" .. i, radius * 2 * L[1], L[2], L[3], Color3.fromRGB(110 - i * 6, 100 - i * 6, 95 - i * 6), Enum.Material.Slate) end
	-- boulders on the rock sides
	for k = 1, 14 do
		local a = r:NextNumber(0, math.pi * 2)
		local d = radius * r:NextNumber(0.55, 0.85)
		local y = -r:NextNumber(8, 30)
		local sz = r:NextNumber(6, 13)
		B.P(m, "Boulder", Vector3.new(sz, sz * 0.8, sz), CFrame.new(center + Vector3.new(math.cos(a) * d * (1 + y / 60), y, math.sin(a) * d * (1 + y / 60))) * CFrame.Angles(r:NextNumber(0, 3), r:NextNumber(0, 3), r:NextNumber(0, 3)),
			Color3.fromRGB(105, 98, 92), Enum.Material.Slate, B.DECO)
	end
	-- hanging vines / roots
	for k = 1, 10 do
		local a = r:NextNumber(0, math.pi * 2)
		local d = radius * r:NextNumber(0.85, 0.98)
		local len = r:NextNumber(6, 16)
		B.P(m, "Vine", Vector3.new(0.4, len, 0.4), CFrame.new(center + Vector3.new(math.cos(a) * d, -2 - len / 2, math.sin(a) * d)), Color3.fromRGB(60, 120, 50), Enum.Material.Grass, B.DECO)
	end
	-- trees around the edge
	for k = 1, 8 do
		local a = (k / 8) * math.pi * 2 + r:NextNumber(-0.2, 0.2)
		local d = radius * r:NextNumber(0.82, 0.92)
		local base = center + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		local h = r:NextNumber(9, 14)
		B.vcyl(m, "Trunk", h, 1.2, CFrame.new(base + Vector3.new(0, h / 2, 0)), Color3.fromRGB(110, 75, 45), Enum.Material.Wood)
		for j = 1, 3 do
			local leaf = B.P(m, "Leaves", Vector3.one * r:NextNumber(5, 7.5), CFrame.new(base + Vector3.new(r:NextNumber(-1.6, 1.6), h + r:NextNumber(-0.5, 2), r:NextNumber(-1.6, 1.6))), Color3.fromRGB(60 + r:NextInteger(0, 30), 140 + r:NextInteger(0, 30), 60), Enum.Material.Grass, B.DECO)
			leaf.Shape = Enum.PartType.Ball
		end
	end
	-- small floating rocks around
	for k = 1, 6 do
		local a = r:NextNumber(0, math.pi * 2)
		local d = radius * r:NextNumber(1.25, 1.6)
		local sz = r:NextNumber(4, 9)
		local rock = B.P(m, "FloatRock", Vector3.new(sz, sz * 0.7, sz), CFrame.new(center + Vector3.new(math.cos(a) * d, r:NextNumber(-20, 6), math.sin(a) * d)) * CFrame.Angles(r:NextNumber(0, 3), r:NextNumber(0, 3), 0), Color3.fromRGB(110, 100, 95), Enum.Material.Slate)
		local top = B.P(m, "FloatGrass", Vector3.new(sz * 0.9, 0.5, sz * 0.9), CFrame.new(rock.Position + Vector3.new(0, sz * 0.36, 0)), Color3.fromRGB(90, 160, 70), Enum.Material.Grass, B.DECO)
	end
	return CFrame.new(center)
end

-- a glowing return/teleport pad (attribute TeleportTo = Vector3) with a prompt
function B.portal(parent, cf, label, target, color)
	local m = Instance.new("Model") m.Name = "Portal" m.Parent = parent
	local pad = B.cyl(m, "Pad", 0.6, 7, cf * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 40, 50), Enum.Material.Metal)
	local glow = B.cyl(m, "Glow", 0.12, 6, cf * CFrame.new(0, 0.66, 0) * CFrame.Angles(0, 0, math.rad(90)), color or Color3.fromRGB(80, 200, 255), Enum.Material.Neon, B.DECO)
	local arch = { -3.2, 3.2 }
	for _, x in ipairs(arch) do B.P(m, "ArchPost", Vector3.new(0.6, 8, 0.6), cf * CFrame.new(x, 4, 0), Color3.fromRGB(230, 230, 235), Enum.Material.Metal) end
	local top = B.P(m, "ArchTop", Vector3.new(7.6, 1.6, 0.6), cf * CFrame.new(0, 8.4, 0), color or Color3.fromRGB(80, 200, 255), Enum.Material.Neon)
	B.sign(top, Enum.NormalId.Front, label, nil, Color3.new(1, 1, 1), Enum.Font.GothamBlack, 40)
	B.sign(top, Enum.NormalId.Back, label, nil, Color3.new(1, 1, 1), Enum.Font.GothamBlack, 40)
	local pp = Instance.new("ProximityPrompt") pp.Name = "PortalPrompt" pp.ActionText = "Teleport" pp.ObjectText = label pp.HoldDuration = 0.3
	pp.MaxActivationDistance = 9 pp.RequiresLineOfSight = false pp.Parent = pad
	pad:SetAttribute("TeleportTo", target)
	return m
end

-- straight painted segment between two local points on a floor frame (any angle)
function B.seg(parent, cf, x1, z1, x2, z2, w, color)
	local a, b = Vector3.new(x1, 0, z1), Vector3.new(x2, 0, z2)
	local len = (b - a).Magnitude
	if len < 0.01 then return end
	local mid = (a + b) / 2
	local p = B.P(parent, "Line", Vector3.new(w, 0.04, len + w * 0.6), cf * CFrame.lookAt(mid + Vector3.new(0, 0.02, 0), b + Vector3.new(0, 0.02, 0)), color or Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, B.DECO)
	return p
end
-- painted arc: centre (cx, cz), radius r, from angle a1 to a2 (radians, 0 = +X, pi/2 = +Z)
function B.arc(parent, cf, cx, cz, r, a1, a2, w, color, steps)
	steps = steps or math.max(6, math.floor(math.abs(a2 - a1) * r / 1.6))
	for i = 0, steps - 1 do
		local t1, t2 = a1 + (a2 - a1) * i / steps, a1 + (a2 - a1) * (i + 1) / steps
		B.seg(parent, cf, cx + math.cos(t1) * r, cz + math.sin(t1) * r, cx + math.cos(t2) * r, cz + math.sin(t2) * r, w, color)
	end
end
-- basketball hoop. base = floor frame at the baseline centre, -Z of base points INTO the court.
-- returns the rim marker CFrame (rim centre, LookVector into the court)
function B.hoop(parent, base, rimH, teamColor)
	local m = Instance.new("Model") m.Name = "Hoop" m.Parent = parent
	local WHITE = Color3.fromRGB(245, 245, 245)
	local ORANGE = Color3.fromRGB(235, 100, 30)
	-- padded pole 3 studs behind the baseline + arm over the court
	B.P(m, "PoleBase", Vector3.new(3, 1.2, 3.5), base * CFrame.new(0, 0.6, 4.2), Color3.fromRGB(40, 45, 55), Enum.Material.Metal)
	B.vcyl(m, "Pole", rimH + 3, 0.9, base * CFrame.new(0, (rimH + 3) / 2, 4.2), Color3.fromRGB(70, 75, 85), Enum.Material.Metal)
	B.P(m, "PolePad", Vector3.new(1.6, 6, 1.6), base * CFrame.new(0, 3.2, 4.2), teamColor or Color3.fromRGB(30, 80, 170), Enum.Material.Fabric)
	B.P(m, "Arm", Vector3.new(0.6, 0.6, 4.6), base * CFrame.new(0, rimH + 2.2, 2), Color3.fromRGB(70, 75, 85), Enum.Material.Metal)
	-- glass backboard with frame + target square
	local bz = -0.2
	B.P(m, "Backboard", Vector3.new(6.6, 3.9, 0.15), base * CFrame.new(0, rimH + 1.5, bz), Color3.fromRGB(220, 235, 245), Enum.Material.Glass, { Transparency = 0.55 })
	for _, e in ipairs({ { 0, 1.95, 6.8, 0.2 }, { 0, -1.95, 6.8, 0.2 }, { 3.3, 0, 0.2, 4.1 }, { -3.3, 0, 0.2, 4.1 } }) do
		B.P(m, "BoardFrame", Vector3.new(e[3], e[4], 0.2), base * CFrame.new(e[1], rimH + 1.5 + e[2], bz), Color3.fromRGB(30, 30, 35), Enum.Material.Metal, B.DECO)
	end
	for _, e in ipairs({ { 0, 1.15, 2.4, 0.12 }, { 0, -0.05, 2.4, 0.12 }, { 1.2, 0.55, 0.12, 1.3 }, { -1.2, 0.55, 0.12, 1.3 } }) do
		B.P(m, "Target", Vector3.new(e[3], e[4], 0.17), base * CFrame.new(e[1], rimH + 0.25 + e[2], bz - 0.01), WHITE, Enum.Material.SmoothPlastic, B.DECO)
	end
	-- rim (ring) + bracket
	local rimC = base * CFrame.new(0, rimH, -1.15)
	B.P(m, "RimBracket", Vector3.new(0.4, 0.25, 0.5), base * CFrame.new(0, rimH, -0.45), ORANGE, Enum.Material.Metal, B.DECO)
	for k = 0, 13 do
		local a = k / 14 * math.pi * 2
		B.P(m, "Rim", Vector3.new(0.12, 0.12, 0.42), rimC * CFrame.new(math.cos(a) * 0.85, 0, math.sin(a) * 0.85) * CFrame.Angles(0, -a, 0), ORANGE, Enum.Material.Metal, B.DECO)
	end
	-- net: strings tapering down
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local top = (rimC * CFrame.new(math.cos(a) * 0.8, -0.05, math.sin(a) * 0.8)).Position
		local bot = (rimC * CFrame.new(math.cos(a) * 0.45, -1.5, math.sin(a) * 0.45)).Position
		local s = B.P(m, "NetString", Vector3.new(0.05, 0.05, (top - bot).Magnitude), CFrame.lookAt((top + bot) / 2, bot), WHITE, Enum.Material.Fabric, B.DECO)
	end
	for _, h in ipairs({ { -0.55, 0.68 }, { -1.05, 0.55 } }) do
		for k = 0, 9 do
			local a = (k + 0.5) / 10 * math.pi * 2
			B.P(m, "NetRing", Vector3.new(0.04, 0.04, 0.45), rimC * CFrame.new(math.cos(a) * h[2], h[1], math.sin(a) * h[2]) * CFrame.Angles(0, -a, 0), WHITE, Enum.Material.Fabric, B.DECO)
		end
	end
	return CFrame.lookAt(rimC.Position, rimC.Position + (base.LookVector * Vector3.new(1, 0, 1)).Unit)
end
-- rack of spare balls
function B.ballRack(parent, cf, color)
	local m = Instance.new("Model") m.Name = "BallRack" m.Parent = parent
	for _, x in ipairs({ -1.6, 1.6 }) do B.P(m, "RackSide", Vector3.new(0.2, 2.8, 1.4), cf * CFrame.new(x, 1.4, 0), Color3.fromRGB(60, 60, 65), Enum.Material.Metal) end
	for _, y in ipairs({ 1, 2.2 }) do
		B.P(m, "RackBar", Vector3.new(3.2, 0.12, 0.12), cf * CFrame.new(0, y, -0.45), Color3.fromRGB(150, 150, 160), Enum.Material.Metal, B.DECO)
		B.P(m, "RackBar", Vector3.new(3.2, 0.12, 0.12), cf * CFrame.new(0, y, 0.45), Color3.fromRGB(150, 150, 160), Enum.Material.Metal, B.DECO)
		for k = -1, 1 do
			local b = B.P(m, "Ball", Vector3.one * 0.95, cf * CFrame.new(k * 1, y + 0.45, 0), color or Color3.fromRGB(225, 105, 35), Enum.Material.SmoothPlastic, B.DECO)
			b.Shape = Enum.PartType.Ball
		end
	end
	return m
end
return B
