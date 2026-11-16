-- BuildKit_SanRoque: helpers used to build the 409 San Roque Street block (display only).
local K = {}
function K.P(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part") p.Name = name p.Size = size p.CFrame = cf p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = parent return p
end
function K.W(parent, name, size, cf, color, mat, props)
	local p = Instance.new("WedgePart") p.Name = name p.Size = size p.CFrame = cf p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic p.Anchored = true
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = parent return p
end
function K.cyl(parent, name, length, diameter, cf, color, mat, props)
	-- cylinder whose length runs along cf's X axis
	local pr = props or {} pr.Shape = Enum.PartType.Cylinder
	return K.P(parent, name, Vector3.new(length, diameter, diameter), cf, color, mat, pr)
end
function K.ball(parent, name, d, cf, color, mat, props)
	local pr = props or {} pr.Shape = Enum.PartType.Ball
	return K.P(parent, name, Vector3.new(d, d, d), cf, color, mat, pr)
end
-- local frame: x = along the facade, y = up, d = depth into the building (negative = in front)
function K.frame(origin, alongDir)
	local right = alongDir.Unit
	local cf = CFrame.fromMatrix(origin, right, Vector3.new(0, 1, 0))
	return function(x, y, d) return cf * CFrame.new(x, y, -d) end, cf
end
function K.sign(part, face, text, bg, fg, font, ppS, opts)
	opts = opts or {}
	local g = Instance.new("SurfaceGui") g.Face = face g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = ppS or 30 g.LightInfluence = opts.light or 0.4 g.Parent = part
	local t = Instance.new("TextLabel") t.Name = "Text" t.Size = UDim2.fromScale(1, 1) t.BackgroundColor3 = bg or Color3.new(0, 0, 0) t.BackgroundTransparency = bg and 0 or 1
	t.TextColor3 = fg or Color3.new(1, 1, 1) t.Font = font or Enum.Font.GothamBlack t.TextScaled = true t.TextWrapped = true t.Text = text t.Parent = g
	if opts.stroke then t.TextStrokeColor3 = opts.stroke t.TextStrokeTransparency = 0 end
	if opts.xa then t.TextXAlignment = opts.xa end
	return t, g
end
-- framed window: frame, glass, mullions, sill
function K.window(parent, at, x, y, w, h, opts)
	opts = opts or {}
	local fc = opts.frame or Color3.fromRGB(40, 42, 46)
	local gc = opts.glass or Color3.fromRGB(70, 110, 120)
	local d = opts.d or 0
	K.P(parent, "Glass", Vector3.new(w, h, 0.2), at(x + w / 2, y + h / 2, d + 0.15), gc, Enum.Material.Glass, { Transparency = opts.trans or 0.25, Reflectance = 0.15 })
	for _, s in ipairs({ { 0, h / 2, 0.25, h }, { w, h / 2, 0.25, h } }) do K.P(parent, "Frame", Vector3.new(s[3], s[4], 0.35), at(x + s[1], y + s[2], d), fc) end
	for _, yy in ipairs({ 0, h }) do K.P(parent, "Frame", Vector3.new(w + 0.25, 0.25, 0.35), at(x + w / 2, y + yy, d), fc) end
	local cols = opts.cols or 2
	for k = 1, cols - 1 do K.P(parent, "Mullion", Vector3.new(0.15, h, 0.3), at(x + w * k / cols, y + h / 2, d), fc) end
	if opts.transom then K.P(parent, "Transom", Vector3.new(w, 0.15, 0.3), at(x + w / 2, y + h * opts.transom, d), fc) end
	if opts.sill ~= false then K.P(parent, "Sill", Vector3.new(w + 0.6, 0.3, 0.6), at(x + w / 2, y - 0.15, d - 0.3), opts.sillColor or Color3.fromRGB(235, 235, 230)) end
	if opts.grille then
		for k = 1, math.floor(w / 0.8) do K.P(parent, "Grille", Vector3.new(0.08, h, 0.08), at(x + k * 0.8, y + h / 2, d - 0.25), Color3.fromRGB(30, 30, 32), Enum.Material.Metal) end
	end
end
-- ornate wrought-iron railing (posts, rails, balusters, scroll rings)
function K.ironRailing(parent, at, x0, x1, y, d, h)
	h = h or 3.2
	local c = Color3.fromRGB(28, 30, 32)
	local len = x1 - x0
	K.P(parent, "RailTop", Vector3.new(len, 0.2, 0.25), at(x0 + len / 2, y + h, d), c, Enum.Material.Metal)
	K.P(parent, "RailMid", Vector3.new(len, 0.12, 0.15), at(x0 + len / 2, y + h * 0.82, d), c, Enum.Material.Metal)
	K.P(parent, "RailBottom", Vector3.new(len, 0.15, 0.2), at(x0 + len / 2, y + 0.25, d), c, Enum.Material.Metal)
	local n = math.max(2, math.floor(len / 0.6))
	for k = 0, n do
		local x = x0 + len * k / n
		local thick = (k % 6 == 0)
		K.P(parent, thick and "RailPost" or "Baluster", Vector3.new(thick and 0.22 or 0.08, h, thick and 0.22 or 0.08), at(x, y + h / 2, d), c, Enum.Material.Metal)
		if k % 2 == 1 and k < n then
			local ring = K.cyl(parent, "Scroll", 0.06, 0.45, at(x + len / n / 2, y + h * 0.66, d) * CFrame.Angles(0, math.rad(90), 0), c, Enum.Material.Metal)
		end
	end
end
function K.glassRailing(parent, at, x0, x1, y, d, h)
	h = h or 3.2
	local len = x1 - x0
	K.P(parent, "GlassPanel", Vector3.new(len, h - 0.3, 0.12), at(x0 + len / 2, y + (h - 0.3) / 2, d), Color3.fromRGB(170, 210, 220), Enum.Material.Glass, { Transparency = 0.55 })
	K.P(parent, "Handrail", Vector3.new(len, 0.2, 0.3), at(x0 + len / 2, y + h, d), Color3.fromRGB(190, 192, 195), Enum.Material.Metal)
	for k = 0, math.floor(len / 4) do K.P(parent, "Post", Vector3.new(0.2, h, 0.2), at(x0 + math.min(len, k * 4), y + h / 2, d), Color3.fromRGB(190, 192, 195), Enum.Material.Metal) end
end
-- wall air-conditioner unit
function K.aircon(parent, at, x, y, d)
	K.P(parent, "ACBody", Vector3.new(2.6, 1.8, 2), at(x, y, d - 1), Color3.fromRGB(235, 235, 230))
	for k = 1, 6 do K.P(parent, "ACGrille", Vector3.new(2.3, 0.08, 0.05), at(x, y - 0.75 + k * 0.22, d - 2.02), Color3.fromRGB(150, 150, 150)) end
	K.P(parent, "ACBracket", Vector3.new(2.6, 0.15, 2), at(x, y - 1, d - 1), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
end
-- outdoor AC condenser (fan box)
function K.condenser(parent, cf)
	K.P(parent, "Condenser", Vector3.new(2.6, 2, 1.1), cf, Color3.fromRGB(230, 230, 225))
	K.cyl(parent, "Fan", 0.1, 1.5, cf * CFrame.new(-0.3, 0, -0.56) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(60, 60, 64), Enum.Material.Metal)
end
-- rolled steel shutter
function K.shutter(parent, at, x, y, w, h, d)
	K.P(parent, "ShutterBox", Vector3.new(w + 0.4, 0.9, 0.9), at(x + w / 2, y + h + 0.45, d), Color3.fromRGB(110, 112, 115), Enum.Material.Metal)
	for k = 0, math.floor(h / 0.35) do K.P(parent, "ShutterSlat", Vector3.new(w, 0.3, 0.15), at(x + w / 2, y + k * 0.35 + 0.15, d + 0.1), (k % 2 == 0) and Color3.fromRGB(125, 128, 132) or Color3.fromRGB(110, 113, 117), Enum.Material.Metal) end
end
-- cardboard appliance box with a printed label
function K.box(parent, cf, size, label)
	local b = K.P(parent, "ApplianceBox", size, cf, Color3.fromRGB(196, 160, 110), Enum.Material.Cardboard or Enum.Material.SmoothPlastic)
	K.P(parent, "BoxTape", Vector3.new(size.X + 0.02, 0.25, size.Z * 0.3), cf * CFrame.new(0, size.Y / 2 - 0.12, 0), Color3.fromRGB(200, 175, 130))
	if label then K.sign(b, Enum.NormalId.Front, label, Color3.fromRGB(230, 225, 215), Color3.fromRGB(40, 70, 140), Enum.Font.GothamBold, 25) end
	return b
end
-- wheel: tire + rim + hub (axle along cf X)
function K.wheel(parent, cf, d, w, rimColor)
	K.cyl(parent, "Tire", w, d, cf, Color3.fromRGB(28, 28, 30), Enum.Material.SmoothPlastic)
	K.cyl(parent, "Rim", w + 0.04, d * 0.58, cf, rimColor or Color3.fromRGB(190, 192, 196), Enum.Material.Metal)
	K.cyl(parent, "Hub", w + 0.08, d * 0.2, cf, Color3.fromRGB(90, 92, 96), Enum.Material.Metal)
	for k = 0, 4 do
		K.P(parent, "Spoke", Vector3.new(w + 0.06, d * 0.05, d * 0.42), cf * CFrame.Angles(math.rad(k * 72), 0, 0) * CFrame.new(0, 0, d * 0.11), Color3.fromRGB(160, 162, 166), Enum.Material.Metal)
	end
end
return K
