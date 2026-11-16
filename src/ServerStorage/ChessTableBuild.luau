-- ChessTableBuild: builds one library chess table court (Studio tool, not used at runtime).
-- build(n, center, opts) → Workspace.SportsVenues.Court_Chess_Library<n>
--   opts.spectators = 1 / -1 (chairs on the +Z / -Z side) or nil, opts.scoreboard = 1 / -1 or nil
local M = {}
function M.build(B, n, center, opts)
	opts = opts or {}
	local V = workspace.SportsVenues
	local FLOOR = 16
	local S = 0.75
	local WOOD, DARKWOOD = Color3.fromRGB(150, 100, 60), Color3.fromRGB(85, 55, 35)
	local LIGHTSQ, DARKSQ = Color3.fromRGB(240, 217, 181), Color3.fromRGB(181, 136, 99)
	local function chair(parent, cf, color, seatName, courtId)
		local m = Instance.new("Model") m.Name = "Chair" m.Parent = parent
		B.P(m, "Seat", Vector3.new(2, 0.3, 2), cf * CFrame.new(0, 1.9, 0), color, Enum.Material.Fabric)
		B.P(m, "Back", Vector3.new(2, 2.4, 0.3), cf * CFrame.new(0, 3.2, 0.9), color, Enum.Material.Fabric)
		for _, o in ipairs({ { -0.8, -0.8 }, { 0.8, -0.8 }, { -0.8, 0.8 }, { 0.8, 0.8 } }) do B.P(m, "Leg", Vector3.new(0.2, 1.8, 0.2), cf * CFrame.new(o[1], 0.9, o[2]), Color3.fromRGB(40, 40, 45), Enum.Material.Metal) end
		if seatName then
			local s = Instance.new("Seat") s.Name = seatName s.Size = Vector3.new(1.6, 0.2, 1.6) s.Anchored = true s.CanCollide = false s.Transparency = 1
			s.CFrame = cf * CFrame.new(0, 2.15, 0) if courtId then s:SetAttribute("CourtId", courtId) end s.Parent = m
		end
		return m
	end
	local name = "Court_Chess_Library" .. n
	if V:FindFirstChild(name) then V[name]:Destroy() end
	local id = "ChessLibrary" .. n
	local m = Instance.new("Model") m.Name = name
	local O = CFrame.new(center.X, FLOOR, center.Z)
	local top = 3.0
	B.P(m, "TableTop", Vector3.new(8.2, 0.35, 8.2), O * CFrame.new(0, top - 0.175, 0), WOOD, Enum.Material.Wood)
	B.P(m, "TableEdge", Vector3.new(8.4, 0.15, 8.4), O * CFrame.new(0, top - 0.42, 0), DARKWOOD, Enum.Material.Wood, B.DECO)
	B.vcyl(m, "Pedestal", top - 0.5, 1.1, O * CFrame.new(0, (top - 0.5) / 2, 0), DARKWOOD, Enum.Material.Wood)
	B.P(m, "Foot", Vector3.new(4, 0.3, 1), O * CFrame.new(0, 0.15, 0), DARKWOOD, Enum.Material.Wood)
	B.P(m, "Foot", Vector3.new(1, 0.3, 4), O * CFrame.new(0, 0.15, 0), DARKWOOD, Enum.Material.Wood)
	local by = top + 0.06
	B.P(m, "BoardBorder", Vector3.new(8 * S + 0.7, 0.12, 8 * S + 0.7), O * CFrame.new(0, by, 0), DARKWOOD, Enum.Material.Wood)
	local sq = Instance.new("Folder") sq.Name = "Squares" sq.Parent = m
	for r = 1, 8 do for f = 1, 8 do
		B.P(sq, "Sq" .. string.char(96 + f) .. r, Vector3.new(S, 0.06, S), O * CFrame.new((r - 4.5) * S, by + 0.07, (f - 4.5) * S), (f + r) % 2 == 0 and DARKSQ or LIGHTSQ, Enum.Material.SmoothPlastic, { CanQuery = false })
	end end
	local function coord(text, x, z, rot)
		local p = B.P(m, "Coord", Vector3.new(0.3, 0.02, 0.3), O * CFrame.new(x, by + 0.07, z) * CFrame.Angles(0, rot, 0), DARKWOOD, Enum.Material.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false })
		B.sign(p, Enum.NormalId.Top, text, nil, Color3.fromRGB(245, 225, 190), Enum.Font.GothamBold, 80)
	end
	for f = 1, 8 do coord(string.char(96 + f), -4.17 * S - 0.05, (f - 4.5) * S, math.rad(-90)) end
	for r = 1, 8 do coord(tostring(r), (r - 4.5) * S, -4.17 * S - 0.05, math.rad(-90)) end
	-- table number plate
	local plate = B.P(m, "TablePlate", Vector3.new(1.4, 0.5, 0.1), O * CFrame.new(-4.15, top - 0.2, 0) * CFrame.Angles(0, math.rad(-90), 0), DARKWOOD, Enum.Material.Wood, B.DECO)
	B.sign(plate, Enum.NormalId.Front, "TABLE " .. n, nil, Color3.fromRGB(255, 225, 150), Enum.Font.GothamBlack, 60)
	local plate2 = plate:Clone() plate2.CFrame = O * CFrame.new(4.15, top - 0.2, 0) * CFrame.Angles(0, math.rad(90), 0) plate2.Parent = m
	-- chess clock
	local ck = B.P(m, "ChessClock", Vector3.new(1.6, 0.6, 0.6), O * CFrame.new(0, top + 0.3, 3.75), Color3.fromRGB(35, 35, 40), Enum.Material.SmoothPlastic)
	B.P(m, "ClockButton", Vector3.new(0.3, 0.12, 0.3), O * CFrame.new(-0.45, top + 0.66, 3.75), Color3.fromRGB(230, 230, 230), Enum.Material.Metal, B.DECO)
	B.P(m, "ClockButton", Vector3.new(0.3, 0.12, 0.3), O * CFrame.new(0.45, top + 0.66, 3.75), Color3.fromRGB(230, 230, 230), Enum.Material.Metal, B.DECO)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local g = Instance.new("SurfaceGui") g.Name = "ClockFace_" .. face.Name g.Face = face g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = 100 g.LightInfluence = 0 g.MaxDistance = 60 g.Parent = ck
		local t = Instance.new("TextLabel") t.Name = "Time" t.Size = UDim2.fromScale(1, 1) t.BackgroundColor3 = Color3.fromRGB(15, 20, 15) t.TextColor3 = Color3.fromRGB(120, 255, 140) t.Font = Enum.Font.Arcade t.TextScaled = true t.Text = "5:00 | 5:00" t.Parent = g
	end
	local mk = Instance.new("Folder") mk.Name = "Markers" mk.Parent = m
	local wcf = CFrame.lookAt((O * CFrame.new(-5.4, 0, 0)).Position, O.Position)
	local bcf = CFrame.lookAt((O * CFrame.new(5.4, 0, 0)).Position, O.Position)
	chair(m, wcf, Color3.fromRGB(235, 235, 230))
	chair(m, bcf, Color3.fromRGB(45, 45, 50))
	B.marker(mk, "A0", wcf * CFrame.new(0, 2.05, 0)) B.marker(mk, "B0", bcf * CFrame.new(0, 2.05, 0))
	B.marker(mk, "A1", wcf * CFrame.new(0, 2.05, 0)) B.marker(mk, "B1", bcf * CFrame.new(0, 2.05, 0))
	local a1 = (O * CFrame.new(-3.5 * S, by + 0.1, -3.5 * S)).Position
	B.marker(mk, "BoardA1", CFrame.lookAt(a1, a1 + Vector3.new(1, 0, 0)))
	m:SetAttribute("Square", S)
	local function cam(nm, p, l) B.marker(mk, nm, CFrame.lookAt((O * CFrame.new(p[1], p[2], p[3])).Position, (O * CFrame.new(l[1], l[2], l[3])).Position)) end
	cam("Cam1", { -0.6, top + 9, 0.01 }, { 0, top, 0 }) cam("Cam2", { -8.5, top + 5, 0 }, { 0, top, 0 }) cam("Cam3", { 8.5, top + 5, 0 }, { 0, top, 0 })
	if opts.spectators then
		local sz = opts.spectators * 5.6
		for k = -1, 1 do
			local p = (O * CFrame.new(k * 2.6 + (opts.specShiftX or 0), 0, sz)).Position
			chair(m, CFrame.lookAt(p, Vector3.new(O.X, FLOOR, O.Z)), Color3.fromRGB(70, 110, 170), "CourtSeat", id)
		end
	end
	local pp = Instance.new("ProximityPrompt") pp.Name = "SportsJoin" pp.ActionText = "Play / Watch" pp.ObjectText = "♟️ Chess Table " .. n pp.HoldDuration = 0.2 pp.MaxActivationDistance = 9 pp.RequiresLineOfSight = false pp.Parent = m.TableTop
	if opts.scoreboard then
		local sbz = opts.scoreboard * 4.1
		local sb = B.P(m, "ScoreBoard", Vector3.new(4.6, 2.4, 0.2), CFrame.lookAt((O * CFrame.new(0, 5.2, sbz)).Position, (O * CFrame.new(0, 5.2, 0)).Position), Color3.fromRGB(20, 24, 32), Enum.Material.SmoothPlastic)
		B.P(m, "ScoreBoardPost", Vector3.new(0.3, 4, 0.3), O * CFrame.new(0, 2, sbz + opts.scoreboard * 0.1), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)
	end
	m:SetAttribute("Sport", "Chess") m:SetAttribute("CourtId", id) m:SetAttribute("CourtName", "Library Chess Table " .. n) m:SetAttribute("CourtCF", O * CFrame.new(0, top, 0))
	m.Parent = V
	return m
end
return M
