-- SchoolFairBuild: helper used (in Studio) to build ServerStorage.SchoolFairKit. Not used at runtime.
local L = {}
local SMOOTH = Enum.SurfaceType.Smooth
function L.P(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part") p.Name = name p.Size = size p.CFrame = cf p.Color = color or Color3.new(1,1,1)
	p.Material = mat or Enum.Material.SmoothPlastic p.Anchored = true p.TopSurface = SMOOTH p.BottomSurface = SMOOTH
	if props then for k, v in pairs(props) do p[k] = v end end
	p.Parent = parent return p
end
-- cylinder standing up (height along Y)
function L.vcyl(parent, name, h, d, cf, color, mat, props)
	local p = L.P(parent, name, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.rad(90)), color, mat, props)
	p.Shape = Enum.PartType.Cylinder return p
end
-- disc facing local Z (thickness along Z)
function L.zdisc(parent, name, t, d, cf, color, mat, props)
	local p = L.P(parent, name, Vector3.new(t, d, d), cf * CFrame.Angles(0, math.rad(90), 0), color, mat, props)
	p.Shape = Enum.PartType.Cylinder return p
end
-- cylinder lying along local X
function L.xcyl(parent, name, len, d, cf, color, mat, props)
	local p = L.P(parent, name, Vector3.new(len, d, d), cf, color, mat, props) p.Shape = Enum.PartType.Cylinder return p
end
function L.ball(parent, name, d, cf, color, mat, props)
	local p = L.P(parent, name, Vector3.new(d, d, d), cf, color, mat, props) p.Shape = Enum.PartType.Ball return p
end
function L.sign(p, face, text, bg, fg, font, ppS)
	local g = Instance.new("SurfaceGui") g.Name = "Sign_" .. face.Name g.Face = face g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = ppS or 50 g.LightInfluence = 0.3 g.Parent = p
	local t = Instance.new("TextLabel") t.Name = "Text" t.Size = UDim2.fromScale(1, 1) t.BackgroundColor3 = bg or Color3.new(0,0,0)
	t.BackgroundTransparency = bg and 0 or 1 t.TextColor3 = fg or Color3.new(1,1,1) t.Font = font or Enum.Font.GothamBlack
	t.TextScaled = true t.Text = text t.Parent = g
	local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0.04, 0) pad.PaddingRight = UDim.new(0.04, 0) pad.PaddingTop = UDim.new(0.08, 0) pad.PaddingBottom = UDim.new(0.08, 0) pad.Parent = t
	return g, t
end
L.DECO = { CanCollide = false, CastShadow = false, CanQuery = false, CanTouch = false }
L.BULB_COLORS = { Color3.fromRGB(255, 236, 170), Color3.fromRGB(255, 120, 110), Color3.fromRGB(120, 200, 255), Color3.fromRGB(150, 240, 150), Color3.fromRGB(255, 210, 90) }
-- a row of little light bulbs from a to b (world CFrames positions)
function L.bulbs(parent, a, b, n, sag, colors, size)
	colors = colors or L.BULB_COLORS
	for i = 0, n - 1 do
		local t = n == 1 and 0.5 or i / (n - 1)
		local pos = a:Lerp(b, t) - Vector3.new(0, (sag or 0) * 4 * t * (1 - t), 0)
		L.ball(parent, "Bulb", size or 0.28, CFrame.new(pos), colors[i % #colors + 1], Enum.Material.Neon, L.DECO)
	end
end
-- a wire between points (thin cylinder)
function L.wire(parent, a, b, color)
	local mid, len = (a + b) / 2, (b - a).Magnitude
	local p = L.P(parent, "Wire", Vector3.new(len, 0.06, 0.06), CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0), color or Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic, L.DECO)
	p.Shape = Enum.PartType.Cylinder
	return p
end
-- a little teddy bear plush (sitting), cf = where it sits
function L.bear(parent, cf, color, scale)
	local s = scale or 1
	local m = Instance.new("Model") m.Name = "PrizePlush" m.Parent = parent
	local d = L.DECO
	L.ball(m, "Body", 0.9 * s, cf * CFrame.new(0, 0.45 * s, 0), color, Enum.Material.Fabric, d)
	L.ball(m, "Belly", 0.55 * s, cf * CFrame.new(0, 0.42 * s, -0.22 * s), color:Lerp(Color3.new(1,1,1), 0.45), Enum.Material.Fabric, d)
	L.ball(m, "Head", 0.7 * s, cf * CFrame.new(0, 1.12 * s, 0), color, Enum.Material.Fabric, d)
	for _, x in ipairs({ -0.27, 0.27 }) do
		L.ball(m, "Ear", 0.28 * s, cf * CFrame.new(x * s, 1.42 * s, 0), color, Enum.Material.Fabric, d)
		L.ball(m, "Arm", 0.32 * s, cf * CFrame.new(x * 1.55 * s, 0.6 * s, -0.12 * s), color, Enum.Material.Fabric, d)
		L.ball(m, "Leg", 0.34 * s, cf * CFrame.new(x * 1.1 * s, 0.15 * s, -0.3 * s), color, Enum.Material.Fabric, d)
		L.ball(m, "Eye", 0.09 * s, cf * CFrame.new(x * 0.45 * s, 1.2 * s, -0.31 * s), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, d)
	end
	L.ball(m, "Snout", 0.28 * s, cf * CFrame.new(0, 1.03 * s, -0.3 * s), color:Lerp(Color3.new(1,1,1), 0.5), Enum.Material.Fabric, d)
	L.ball(m, "Nose", 0.1 * s, cf * CFrame.new(0, 1.07 * s, -0.43 * s), Color3.fromRGB(30, 20, 20), Enum.Material.SmoothPlastic, d)
	return m
end
-- the common stall. cf: floor-top centre, local -Z faces the aisle. Returns model, at(), theme
function L.stall(parent, name, cf, theme, title)
	local m = Instance.new("Model") m.Name = name m.Parent = parent
	local at = function(x, y, z) return cf * CFrame.new(x, y, z) end
	local C, C2 = theme.Main, theme.Accent
	local WHITE, WOOD, WOOD_DK = Color3.fromRGB(250, 248, 240), Color3.fromRGB(190, 140, 90), Color3.fromRGB(110, 70, 45)
	local D = L.DECO
	local S = Instance.new("Model") S.Name = "Stall" S.Parent = m
	-- platform + trim
	L.P(S, "Platform", Vector3.new(12.4, 0.4, 8.4), at(0, 0.2, 0), WOOD, Enum.Material.WoodPlanks)
	L.P(S, "PlatformTrim", Vector3.new(12.5, 0.18, 0.2), at(0, 0.32, -4.25), C, Enum.Material.SmoothPlastic, D)
	-- back wall with vertical stripes
	L.P(S, "BackWall", Vector3.new(12, 9.2, 0.35), at(0, 0.4 + 4.6, 3.95), WHITE, Enum.Material.SmoothPlastic)
	for i = -5, 5, 2 do L.P(S, "BackStripe", Vector3.new(1, 9.2, 0.05), at(i, 0.4 + 4.6, 3.75), C2, Enum.Material.SmoothPlastic, D) end
	L.P(S, "BackCap", Vector3.new(12.2, 0.3, 0.6), at(0, 9.75, 3.95), C, Enum.Material.SmoothPlastic, D)
	-- side walls: solid lower half + lattice upper half
	for _, sx in ipairs({ -6, 6 }) do
		L.P(S, "SideLower", Vector3.new(0.3, 3.6, 7.6), at(sx, 0.4 + 1.8, 0.1), C, Enum.Material.SmoothPlastic)
		L.P(S, "SideRail", Vector3.new(0.4, 0.25, 7.6), at(sx, 4.15, 0.1), WHITE, Enum.Material.SmoothPlastic, D)
		L.P(S, "SideTopRail", Vector3.new(0.4, 0.25, 7.6), at(sx, 8.4, 0.1), WHITE, Enum.Material.SmoothPlastic, D)
		for k = 0, 4 do
			local z = -3.2 + k * 1.6
			L.P(S, "Lattice", Vector3.new(0.12, 4.6, 0.15), at(sx, 6.25, z + 0.8) * CFrame.Angles(math.rad(35), 0, 0), WHITE, Enum.Material.SmoothPlastic, D)
			L.P(S, "Lattice", Vector3.new(0.12, 4.6, 0.15), at(sx, 6.25, z + 0.8) * CFrame.Angles(math.rad(-35), 0, 0), WHITE, Enum.Material.SmoothPlastic, D)
		end
	end
	-- corner posts with candy stripes on the front two
	for _, sx in ipairs({ -6, 6 }) do
		L.P(S, "PostBack", Vector3.new(0.6, 9.6, 0.6), at(sx, 0.4 + 4.8, 3.8), WHITE)
		L.P(S, "PostFront", Vector3.new(0.6, 9.2, 0.6), at(sx, 0.4 + 4.6, -3.8), WHITE)
		for k = 0, 8 do L.P(S, "PostStripe", Vector3.new(0.64, 0.35, 0.64), at(sx, 0.9 + k, -3.8) * CFrame.Angles(0, 0, math.rad(20)), C, Enum.Material.SmoothPlastic, D) end
		L.ball(S, "PostKnob", 0.8, at(sx, 9.95, -3.8), C2, Enum.Material.SmoothPlastic, D)
	end
	-- counter
	local counter = L.P(S, "Counter", Vector3.new(11.2, 3.3, 1.3), at(0, 0.4 + 1.65, -2.9), WOOD, Enum.Material.Wood)
	L.P(S, "CounterTop", Vector3.new(11.8, 0.25, 1.9), at(0, 0.4 + 3.42, -2.95), WOOD_DK, Enum.Material.Wood)
	for _, x in ipairs({ -3.6, 0, 3.6 }) do
		L.P(S, "CounterPanel", Vector3.new(3.1, 2.2, 0.08), at(x, 0.4 + 1.6, -3.58), C, Enum.Material.SmoothPlastic, D)
		L.P(S, "CounterPanelInset", Vector3.new(2.5, 1.6, 0.08), at(x, 0.4 + 1.6, -3.63), WHITE, Enum.Material.SmoothPlastic, D)
		L.zdisc(S, "CounterStar", 0.06, 0.9, at(x, 0.4 + 1.6, -3.69), C2, Enum.Material.Neon, D)
	end
	L.bulbs(S, at(-5.6, 0.4 + 3.25, -3.92).Position, at(5.6, 0.4 + 3.25, -3.92).Position, 15, 0, { Color3.fromRGB(255, 236, 170), Color3.fromRGB(255, 200, 80) }, 0.24)
	-- awning: sloped stripes + scalloped valance
	for i = 0, 11 do
		local x = -5.5 + i
		L.P(S, "Awning", Vector3.new(1.02, 0.2, 9.4), at(x, 9.65, -0.2) * CFrame.Angles(math.rad(-9), 0, 0), (i % 2 == 0) and C or WHITE, Enum.Material.Fabric)
		local sc = L.zdisc(S, "Scallop", 0.12, 1.02, at(x, 8.75, -4.85), (i % 2 == 0) and C or WHITE, Enum.Material.Fabric, D)
	end
	L.P(S, "Valance", Vector3.new(12.2, 0.6, 0.14), at(0, 9.05, -4.85), C, Enum.Material.Fabric, D)
	-- marquee sign on top (with bulb border)
	local board = L.P(S, "SignBoard", Vector3.new(9, 1.9, 0.3), at(0, 11, -4.5), Color3.fromRGB(30, 34, 46))
	L.sign(board, Enum.NormalId.Front, title, nil, Color3.fromRGB(255, 226, 120), Enum.Font.FredokaOne, 60)
	L.P(S, "SignFrame", Vector3.new(9.4, 2.3, 0.2), at(0, 11, -4.38), C, Enum.Material.SmoothPlastic, D)
	L.bulbs(S, at(-4.5, 12.05, -4.68).Position, at(4.5, 12.05, -4.68).Position, 13, 0, nil, 0.22)
	L.bulbs(S, at(-4.5, 9.95, -4.68).Position, at(4.5, 9.95, -4.68).Position, 13, 0, nil, 0.22)
	L.P(S, "SignLeg", Vector3.new(0.25, 1.2, 0.25), at(-3.5, 10.0, -4.35), WHITE, Enum.Material.Metal, D)
	L.P(S, "SignLeg", Vector3.new(0.25, 1.2, 0.25), at(3.5, 10.0, -4.35), WHITE, Enum.Material.Metal, D)
	-- string lights under the awning
	L.bulbs(S, at(-5.6, 8.5, -3.5).Position, at(5.6, 8.5, -3.5).Position, 11, 0.5, nil, 0.26)
	L.wire(S, at(-5.6, 8.5, -3.5).Position, at(5.6, 8.5, -3.5).Position)
	-- inside light (down only, so it doesn't light the floor above)
	local lamp = L.P(S, "CanopyLight", Vector3.new(8, 0.15, 0.4), at(0, 8.9, 0), Color3.fromRGB(255, 244, 220), Enum.Material.Neon, D)
	local sl = Instance.new("SurfaceLight") sl.Face = Enum.NormalId.Bottom sl.Brightness = 0.8 sl.Range = 10 sl.Angle = 110 sl.Color = Color3.fromRGB(255, 236, 210) sl.Parent = lamp
	-- prize shelves on both inner side walls with plushies
	local plushColors = { Color3.fromRGB(240, 170, 190), Color3.fromRGB(160, 120, 80), Color3.fromRGB(150, 200, 250), Color3.fromRGB(250, 220, 120), Color3.fromRGB(170, 230, 170), Color3.fromRGB(220, 170, 240) }
	for side, sx in ipairs({ -5.3, 5.3 }) do
		for row, y in ipairs({ 5.0, 7.0 }) do
			L.P(S, "PrizeShelf", Vector3.new(1.2, 0.15, 5.6), at(sx, y, 0.6), WOOD_DK, Enum.Material.Wood)
			for k = 0, 2 do
				local look = at(sx, y + 0.08, -1.4 + k * 2) * CFrame.Angles(0, (sx < 0) and math.rad(-90) or math.rad(90), 0)
				L.bear(S, look, plushColors[(side * 3 + row * 2 + k) % #plushColors + 1], 0.75)
			end
		end
	end
	-- status lamp (green = open, red = occupied) on the front-left post + billboard anchor
	local status = L.ball(m, "StatusLamp", 0.9, at(-6, 10.6, -3.8), Color3.fromRGB(80, 230, 110), Enum.Material.Neon, D)
	local pl = Instance.new("PointLight") pl.Name = "Glow" pl.Range = 6 pl.Brightness = 1.2 pl.Color = status.Color pl.Parent = status
	local anchor = L.P(m, "StatusAnchor", Vector3.new(0.2, 0.2, 0.2), at(0, 12.6, -4.5), WHITE, Enum.Material.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	-- where the player stands to play + floor mat
	L.P(m, "PlayerSpot", Vector3.new(2, 0.2, 2), at(0, 0.1, -6.2), WHITE, Enum.Material.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local mat = L.P(m, "PlayMat", Vector3.new(0.08, 3.4, 3.4), at(0, 0.04, -6.2) * CFrame.Angles(0, 0, math.rad(90)), C, Enum.Material.Fabric, D)
	mat.Shape = Enum.PartType.Cylinder
	local matTop = L.P(m, "PlayMatLabel", Vector3.new(2.6, 0.02, 2.6), at(0, 0.09, -6.2) * CFrame.Angles(0, math.rad(90), 0), WHITE, Enum.Material.SmoothPlastic, { Transparency = 1, CanCollide = false, CastShadow = false, CanQuery = false })
	L.sign(matTop, Enum.NormalId.Top, "▲ PLAY HERE", nil, Color3.new(1,1,1), Enum.Font.GothamBlack, 40)
	-- A-frame info sign beside the stall
	local aSign = L.P(S, "InfoBoard", Vector3.new(2.2, 2.8, 0.15), at(7.4, 1.6, -4.8) * CFrame.Angles(math.rad(-12), math.rad(-15), 0), WHITE, Enum.Material.SmoothPlastic)
	L.P(S, "InfoLeg", Vector3.new(2.2, 2.8, 0.1), at(7.4, 1.6, -4.1) * CFrame.Angles(math.rad(12), math.rad(-15), 0), WOOD_DK, Enum.Material.Wood, D)
	local _, infoText = L.sign(aSign, Enum.NormalId.Front, title .. "\n\n" .. (theme.Info or "Win tickets!"), C, Color3.new(1,1,1), Enum.Font.GothamBold, 60)
	infoText.TextYAlignment = Enum.TextYAlignment.Top
	return m, at, S
end
return L
