--[[ FoundationDay (RARE event) — FOUNDING ANNIVERSARY ─────────────────────────────
  The anniversary "Schedule of Activities" played live in the Quadrangle, in order:
   1 🏫 Opening • Campus Decoration & Safety Prep  – hang decorations at ✨ spots (E)
   2 🛍️ Campus Booths & Trade Fair                 – 12 booths: 8 food stalls, Ring Toss, Souvenirs, Face Paint, Lucky Draw
   3 🎡 Float Parade                               – 4 department floats loop the courtyard; walk beside one
   4 🎗️ Presentation of Candidates & Sashing        – registered candidates get sashes and walk the runway
   5 🎤 Talent Competition                          – candidates perform, audience votes Best in Talent
   6 👑 Coronation Night                            – audience votes Mr. & Ms.; crowning with crowns + sashes
   7 🎭 Cultural Show – Guest Performers            – NPC dance troupe on the main stage
   8 🌟 Cultural Show – SC Talents                  – open stage, the crowd cheers
   9 🎲 Parlor Games                                – Pabitin + Sack Race heats
  10 🎆 Closing & Fireworks
  All day: 📰 press drone (Media Coverage) + 📸 Photo Booth (Documentation).
  Client UI: StarterGui.EventGui.FoundationClient. Actions arrive through EventAction (OnAction).
  Everything built here lives in ctx.Folder and is removed when the event ends.
───────────────────────────────────────────────────────────────────────────────────────]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local M = {}
local GREEN, GOLD, WHITE = Color3.fromRGB(30, 110, 60), Color3.fromRGB(245, 200, 60), Color3.fromRGB(250, 250, 245)
local FLAG = { Color3.fromRGB(30, 110, 60), Color3.fromRGB(245, 200, 60), Color3.fromRGB(250, 250, 245), Color3.fromRGB(200, 60, 60), Color3.fromRGB(60, 120, 220) }
local WOOD, DARK = Color3.fromRGB(120, 80, 50), Color3.fromRGB(25, 25, 28)

-- courtyard layout (world). The Quadrangle's raised stage: front edge x = 235.7, top y = 2.97, centred on z = 42.4
local FLOOR = 0.5
local STAGE_FRONT, STAGE_Z, STAGE_TOP = 235.7, 42.4, 2.97
local RUNWAY_X0 = 203
local ROUTE = { Vector3.new(116, FLOOR, -8), Vector3.new(168, FLOOR, -8), Vector3.new(168, FLOOR, 88), Vector3.new(116, FLOOR, 88) }

---------------------------------------------------------------- builders
local function part(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part") p.Name = name p.Size = size p.CFrame = cf p.Color = color p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = parent return p
end
local NOCOL = { CanCollide = false, CanQuery = false, CanTouch = false }
local function deco(parent, name, size, cf, color, mat, extra)
	local t = { CanCollide = false, CanQuery = false, CanTouch = false }
	for k, v in pairs(extra or {}) do t[k] = v end
	return part(parent, name, size, cf, color, mat, t)
end
local function cyl(parent, name, a, b, d, color, mat, props) -- cylinder from a to b
	local len = (b - a).Magnitude
	local t = { Shape = Enum.PartType.Cylinder, CanCollide = false, CanQuery = false, CanTouch = false }
	for k, v in pairs(props or {}) do t[k] = v end
	return part(parent, name, Vector3.new(len, d, d), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0), color, mat, t)
end
local function sign(p, face, text, bg, fg, ppS, font)
	local g = Instance.new("SurfaceGui") g.Face = face g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = ppS or 30
	g.LightInfluence = 0.3 g.Brightness = 1.3 g.Parent = p
	local t = Instance.new("TextLabel") t.Name = "Text" t.Size = UDim2.fromScale(1, 1) t.BackgroundColor3 = bg or Color3.new(0, 0, 0) t.BackgroundTransparency = bg and 0 or 1
	t.TextColor3 = fg or Color3.new(1, 1, 1) t.Font = font or Enum.Font.GothamBlack t.TextScaled = true t.TextWrapped = true t.Text = text t.Parent = g
	local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0.03, 0) pad.PaddingRight = UDim.new(0.03, 0) pad.Parent = t
	return t
end
local function facing(pos, dir) return CFrame.lookAt(pos, pos + dir) end
local function balloons(parent, at)
	for k = 1, 6 do
		local a = k / 6 * math.pi * 2
		local top = at + Vector3.new(math.cos(a) * 1.2, 9 + (k % 3), math.sin(a) * 1.2)
		deco(parent, "Balloon", Vector3.new(2, 2.4, 2), CFrame.new(top), FLAG[k % #FLAG + 1], Enum.Material.SmoothPlastic, { Reflectance = 0.15 })
		local len = (top - at).Magnitude
		deco(parent, "String", Vector3.new(0.05, 0.05, len), CFrame.lookAt((top + at) / 2, top), Color3.new(1, 1, 1))
	end
	deco(parent, "BalloonWeight", Vector3.new(1, 0.6, 1), CFrame.new(at + Vector3.new(0, 0.3, 0)), GOLD, Enum.Material.Metal)
end
local function bunting(parent, a, b, sag)
	local n = math.max(2, math.floor((b - a).Magnitude / 2.2))
	for i = 0, n do
		local t = i / n
		local p = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * (sag or 3), 0)
		deco(parent, "Pennant", Vector3.new(1.4, 1.6, 0.08), CFrame.lookAt(p, p + (b - a):Cross(Vector3.new(0, 1, 0))) * CFrame.Angles(0, 0, math.rad(45)), FLAG[i % #FLAG + 1], Enum.Material.Fabric, { CastShadow = false })
	end
end
local function prompt(parent, action, object, dist, hold)
	local pp = Instance.new("ProximityPrompt") pp.ActionText = action pp.ObjectText = object or "" pp.MaxActivationDistance = dist or 10
	pp.HoldDuration = hold or 0 pp.RequiresLineOfSight = false pp.Parent = parent
	return pp
end
local function rootOf(p) local c = p.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function torsoOf(char) return char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) end
local function weld(a, b) local w = Instance.new("WeldConstraint") w.Part0 = a w.Part1 = b w.Parent = b return w end
local function attachTo(char, base, name, size, offset, color, mat)
	local p = Instance.new("Part") p.Name = name p.Size = size p.Color = color p.Material = mat or Enum.Material.SmoothPlastic
	p.CanCollide = false p.CanQuery = false p.CanTouch = false p.Massless = true p.CastShadow = false
	p.CFrame = base.CFrame * offset p.Parent = char weld(base, p)
	return p
end

-- join automatically when someone takes part in an activity
local function ensureJoined(ctx, player)
	if ctx.Phase ~= "Active" then return false end
	if ctx:IsIn(player) then return true end
	return ctx:Join(player) == true
end

---------------------------------------------------------------- state sent to clients
local function segOf(ctx) return ctx.Data.program[ctx.Data.seg] end
local function candidateList(ctx)
	local out = {}
	for _, title in ipairs({ "Mr", "Ms" }) do
		for _, c in ipairs(ctx.Data.cands[title]) do
			if c.player.Parent then
				table.insert(out, { userId = c.player.UserId, name = c.player.DisplayName, title = title, number = c.number })
			end
		end
	end
	return out
end
local function state(ctx)
	local s = segOf(ctx)
	return {
		type = "state", seg = ctx.Data.seg, segId = s and s.Id, segEndsAt = ctx.Data.segEndsAt,
		candidates = candidateList(ctx), registrationOpen = ctx.Data.registrationOpen,
		votingTalent = ctx.Data.votingTalent, votingCrown = ctx.Data.votingCrown,
		decorated = ctx.Data.decorated, decoTotal = #ctx.Data.decoSpots,
	}
end
local function pushState(ctx) ctx:Broadcast(state(ctx)) end

---------------------------------------------------------------- SASH & CROWN
local function setSash(player, text, gold)
	local char = player.Character
	local torso = torsoOf(char)
	if not torso then return end
	for _, n in ipairs({ "FD_SashFront", "FD_SashBack" }) do local o = char:FindFirstChild(n) if o then o:Destroy() end end
	local sz = torso.Size
	local w = math.sqrt(sz.X ^ 2 + sz.Y ^ 2) * 1.02
	local col = gold and Color3.fromRGB(240, 200, 70) or Color3.fromRGB(250, 248, 240)
	local front = attachTo(char, torso, "FD_SashFront", Vector3.new(w, 0.55, 0.06), CFrame.new(0, 0, -sz.Z / 2 - 0.04) * CFrame.Angles(0, 0, math.rad(-40)), col, Enum.Material.Fabric)
	attachTo(char, torso, "FD_SashBack", Vector3.new(w, 0.55, 0.06), CFrame.new(0, 0, sz.Z / 2 + 0.04) * CFrame.Angles(0, 0, math.rad(40)), col, Enum.Material.Fabric)
	local g = Instance.new("SurfaceGui") g.Face = Enum.NormalId.Front g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = 90 g.LightInfluence = 0.5 g.Parent = front
	local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.TextScaled = true t.Font = Enum.Font.Garamond
	t.TextColor3 = gold and Color3.fromRGB(110, 60, 10) or Color3.fromRGB(20, 90, 50) t.Text = text t.Parent = g
end
local function giveCrown(player, small)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then return end
	local old = char:FindFirstChild("FD_Crown") if old then old:Destroy() end
	local model = Instance.new("Model") model.Name = "FD_Crown" model.Parent = char
	local s = (small and 0.75 or 1) * math.clamp(head.Size.X / 1.2, 0.7, 1.5)
	local top = head.CFrame * CFrame.new(0, head.Size.Y / 2 + 0.12 * s, 0)
	local band = Instance.new("Part") band.Name = "Band" band.Shape = Enum.PartType.Cylinder band.Size = Vector3.new(0.35 * s, 1.15 * s, 1.15 * s)
	band.CFrame = top * CFrame.Angles(0, 0, math.rad(90)) band.Color = GOLD band.Material = Enum.Material.Foil
	band.CanCollide = false band.CanQuery = false band.CanTouch = false band.Massless = true band.Parent = model weld(head, band)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local spike = Instance.new("WedgePart") spike.Name = "Point" spike.Size = Vector3.new(0.08 * s, (k % 2 == 0 and 0.55 or 0.38) * s, 0.28 * s)
		spike.CFrame = top * CFrame.Angles(0, -a, 0) * CFrame.new(0, (0.18 + (k % 2 == 0 and 0.27 or 0.19)) * s, -0.52 * s)
		spike.Color = GOLD spike.Material = Enum.Material.Foil spike.CanCollide = false spike.CanQuery = false spike.CanTouch = false spike.Massless = true spike.Parent = model
		weld(head, spike)
		if k % 2 == 0 then
			local gem = Instance.new("Part") gem.Name = "Gem" gem.Shape = Enum.PartType.Ball gem.Size = Vector3.new(0.14, 0.14, 0.14) * s
			gem.CFrame = top * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0.12 * s, -0.6 * s)
			gem.Color = ({ Color3.fromRGB(220, 40, 60), Color3.fromRGB(40, 120, 230), Color3.fromRGB(40, 180, 90), Color3.fromRGB(150, 60, 220) })[k / 2 + 1]
			gem.Material = Enum.Material.Neon gem.CanCollide = false gem.CanQuery = false gem.CanTouch = false gem.Massless = true gem.Parent = model weld(head, gem)
		end
	end
	local sp = Instance.new("Sparkles") sp.SparkleColor = GOLD sp.Parent = band
	Debris:AddItem(sp, 20)
end
local function clearRegalia(player, keepCrown)
	local char = player.Character
	if not char then return end
	for _, n in ipairs({ "FD_SashFront", "FD_SashBack", "FD_Sack", "FD_Held", "FD_Pin", "FD_Paint" }) do local o = char:FindFirstChild(n) if o then o:Destroy() end end
	if not keepCrown then local c = char:FindFirstChild("FD_Crown") if c then c:Destroy() end end
end

---------------------------------------------------------------- held items (food, etc.)
local function holdItem(player, build, seconds)
	local char = player.Character
	local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
	if not hand then return end
	local old = char:FindFirstChild("FD_Held") if old then old:Destroy() end
	local m = Instance.new("Model") m.Name = "FD_Held" m.Parent = char
	local base = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2 - 0.2, -0.3)
	build(m, base)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = false p.CanCollide = false p.CanQuery = false p.CanTouch = false p.Massless = true weld(hand, p) end
	end
	task.delay(seconds or 6, function() if m.Parent then m:Destroy() end end)
end
local function sfx(at, id, vol)
	local s = Instance.new("Sound") s.SoundId = id s.Volume = vol or 0.6 s.RollOffMaxDistance = 60 s.Parent = at
	local grp = game:GetService("SoundService"):FindFirstChild("SFX") if grp then s.SoundGroup = grp end
	s:Play() Debris:AddItem(s, 6)
end
local EAT_SOUND = "rbxassetid://78138340192174"
local BELL_SOUND = "rbxassetid://9126073001"

---------------------------------------------------------------- FOOD & BOOTHS
local FOODS = {
	{ id = "Barbecue", icon = "🍢", name = "Pork Barbecue", price = "₱25", color = Color3.fromRGB(150, 60, 30),
		build = function(m, cf) part(m, "Stick", Vector3.new(0.08, 0.08, 1.8), cf, Color3.fromRGB(200, 170, 120)) for i = -1, 1 do part(m, "Meat", Vector3.new(0.35, 0.3, 0.35), cf * CFrame.new(0, 0, i * 0.4 - 0.2), Color3.fromRGB(140, 55, 25), Enum.Material.Sand) end end },
	{ id = "HaloHalo", icon = "🍧", name = "Halo-Halo", price = "₱60", color = Color3.fromRGB(170, 120, 210),
		build = function(m, cf) part(m, "Glass", Vector3.new(0.7, 0.9, 0.7), cf * CFrame.new(0, 0.3, 0), Color3.fromRGB(200, 230, 255), Enum.Material.Glass, { Transparency = 0.4 }) part(m, "Ube", Vector3.new(0.55, 0.3, 0.55), cf * CFrame.new(0, 0.85, 0), Color3.fromRGB(130, 70, 170), Enum.Material.Sand, { Shape = Enum.PartType.Ball }) part(m, "Ice", Vector3.new(0.6, 0.5, 0.6), cf * CFrame.new(0, 0.55, 0), Color3.fromRGB(240, 240, 255), Enum.Material.Ice) end },
	{ id = "Buko", icon = "🥥", name = "Buko Juice", price = "₱35", color = Color3.fromRGB(120, 170, 70),
		build = function(m, cf) part(m, "Coconut", Vector3.new(0.9, 0.9, 0.9), cf * CFrame.new(0, 0.3, 0), Color3.fromRGB(110, 150, 60), Enum.Material.Wood, { Shape = Enum.PartType.Ball }) part(m, "Straw", Vector3.new(0.06, 0.7, 0.06), cf * CFrame.new(0.15, 0.9, 0), Color3.fromRGB(240, 80, 80)) end },
	{ id = "Turon", icon = "🍌", name = "Turon", price = "₱15", color = Color3.fromRGB(210, 150, 60),
		build = function(m, cf) part(m, "Turon", Vector3.new(0.35, 0.35, 1.2), cf, Color3.fromRGB(200, 130, 50), Enum.Material.Sand) part(m, "Stick", Vector3.new(0.06, 0.06, 0.6), cf * CFrame.new(0, 0, 0.8), Color3.fromRGB(200, 170, 120)) end },
	{ id = "Kakanin", icon = "🍡", name = "Kakanin (Puto & Kutsinta)", price = "₱20", color = Color3.fromRGB(230, 120, 140),
		build = function(m, cf) part(m, "Plate", Vector3.new(1, 0.08, 1), cf, Color3.fromRGB(110, 160, 80), Enum.Material.Grass) for i = 0, 2 do part(m, "Puto", Vector3.new(0.3, 0.2, 0.3), cf * CFrame.new(-0.25 + i * 0.25, 0.15, 0), (i % 2 == 0) and Color3.fromRGB(250, 245, 230) or Color3.fromRGB(150, 70, 30)) end end },
	{ id = "Fishball", icon = "🐟", name = "Fishball & Kwek-Kwek", price = "₱20", color = Color3.fromRGB(240, 140, 40),
		build = function(m, cf) part(m, "Cup", Vector3.new(0.6, 0.7, 0.6), cf * CFrame.new(0, 0.2, 0), Color3.fromRGB(250, 250, 250)) for i = 0, 2 do part(m, "Ball", Vector3.new(0.25, 0.25, 0.25), cf * CFrame.new(-0.12 + i * 0.12, 0.65, 0), (i == 1) and Color3.fromRGB(240, 120, 30) or Color3.fromRGB(220, 190, 120), Enum.Material.Sand, { Shape = Enum.PartType.Ball }) end end },
	{ id = "Corn", icon = "🌽", name = "Inihaw na Mais", price = "₱30", color = Color3.fromRGB(240, 200, 60),
		build = function(m, cf) part(m, "Corn", Vector3.new(0.4, 0.4, 1.2), cf, Color3.fromRGB(240, 200, 60), Enum.Material.Pebble) part(m, "Stick", Vector3.new(0.06, 0.06, 0.6), cf * CFrame.new(0, 0, 0.85), Color3.fromRGB(200, 170, 120)) end },
	{ id = "Taho", icon = "🥤", name = "Taho", price = "₱20", color = Color3.fromRGB(190, 140, 90),
		build = function(m, cf) part(m, "Cup", Vector3.new(0.55, 0.8, 0.55), cf * CFrame.new(0, 0.3, 0), Color3.fromRGB(240, 240, 240), Enum.Material.Glass, { Transparency = 0.3 }) part(m, "Syrup", Vector3.new(0.5, 0.25, 0.5), cf * CFrame.new(0, 0.55, 0), Color3.fromRGB(150, 90, 40), Enum.Material.Glass) end },
}
local BOOTHS = {} -- filled in Setup (food stalls + game booths)

local function buildBooth(ctx, parent, pos, faceDir, title, icon, color, props, actionText, onUse)
	local m = Instance.new("Model") m.Name = "Booth_" .. title:gsub("%W", "") m.Parent = parent
	local cf = facing(pos, faceDir)
	local function at(x, y, z) return cf * CFrame.new(x, y, z) end
	-- counter + table skirt
	part(m, "Counter", Vector3.new(9, 3.2, 3), at(0, 1.6, -1), WHITE, Enum.Material.Wood)
	deco(m, "Skirt", Vector3.new(9.1, 2.6, 0.1), at(0, 1.5, -2.55), color, Enum.Material.Fabric)
	deco(m, "CounterTop", Vector3.new(9.4, 0.25, 3.4), at(0, 3.32, -1), Color3.fromRGB(150, 105, 65), Enum.Material.WoodPlanks)
	-- tent poles + striped canopy
	for _, x in ipairs({ -4.6, 4.6 }) do for _, z in ipairs({ -2.8, 2.6 }) do deco(m, "Pole", Vector3.new(0.25, 9, 0.25), at(x, 4.5, z), Color3.fromRGB(200, 200, 205), Enum.Material.Metal) end end
	for i = 0, 5 do
		deco(m, "Canopy", Vector3.new(1.6, 0.15, 6.4), at(-4 + i * 1.6, 9.1, -0.1) * CFrame.Angles(math.rad(8), 0, 0), (i % 2 == 0) and color or WHITE, Enum.Material.Fabric)
	end
	deco(m, "Valance", Vector3.new(9.6, 0.8, 0.1), at(0, 8.6, -3.35), color, Enum.Material.Fabric)
	-- sign board
	local board = deco(m, "Sign", Vector3.new(7.5, 1.6, 0.25), at(0, 7.4, -3.2), Color3.fromRGB(30, 35, 40))
	sign(board, Enum.NormalId.Front, icon .. "  " .. title:upper(), color, Color3.new(1, 1, 1), 40)
	-- string lights along the canopy
	for i = 0, 8 do deco(m, "Bulb", Vector3.new(0.3, 0.3, 0.3), at(-4.4 + i * 1.1, 8.3, -3.3), FLAG[i % #FLAG + 1], Enum.Material.Neon, { Shape = Enum.PartType.Ball }) end
	if props then props(m, at) end
	local anchor = deco(m, "PromptAnchor", Vector3.new(1, 1, 1), at(0, 3.2, -2.6), Color3.new(1, 1, 1), nil, { Transparency = 1 })
	local pp = prompt(anchor, actionText, icon .. " " .. title, 9)
	ctx:Connect(pp.Triggered, function(player) if ensureJoined(ctx, player) then onUse(player, anchor) end end)
	return m
end

---------------------------------------------------------------- DECORATIONS (Opening)
local DECO_SPOTS = {
	{ pos = Vector3.new(108, FLOOR, -20), kind = "lantern" }, { pos = Vector3.new(108, FLOOR, 96), kind = "lantern" },
	{ pos = Vector3.new(194, FLOOR, -22), kind = "banner" }, { pos = Vector3.new(194, FLOOR, 98), kind = "banner" },
	{ pos = Vector3.new(226, FLOOR, -20), kind = "lantern" }, { pos = Vector3.new(226, FLOOR, 96), kind = "lantern" },
	{ pos = Vector3.new(207, FLOOR, -18), kind = "balloons" }, { pos = Vector3.new(207, FLOOR, 94), kind = "balloons" },
	{ pos = Vector3.new(146, FLOOR, -24), kind = "bunting" }, { pos = Vector3.new(146, FLOOR, 98), kind = "bunting" },
}
local function buildDecoration(parent, spot)
	local p = spot.pos
	if spot.kind == "lantern" then -- parol-style star lantern on a post
		deco(parent, "LanternPost", Vector3.new(0.4, 12, 0.4), CFrame.new(p + Vector3.new(0, 6, 0)), DARK, Enum.Material.Metal)
		local c = p + Vector3.new(0, 12.5, 0)
		for k = 0, 4 do deco(parent, "ParolPoint", Vector3.new(0.3, 1.8, 0.6), CFrame.new(c) * CFrame.Angles(0, 0, k / 5 * math.pi * 2) * CFrame.new(0, 1, 0), FLAG[k % #FLAG + 1], Enum.Material.Neon) end
		local core = deco(parent, "ParolCore", Vector3.new(1.2, 1.2, 0.6), CFrame.new(c), GOLD, Enum.Material.Neon, { Shape = Enum.PartType.Ball })
		local l = Instance.new("PointLight") l.Color = GOLD l.Range = 16 l.Brightness = 1.5 l.Parent = core
		for k = 1, 3 do deco(parent, "ParolTail", Vector3.new(0.15, 3, 0.05), CFrame.new(c + Vector3.new((k - 2) * 0.4, -2.4, 0)), FLAG[k], Enum.Material.Fabric) end
	elseif spot.kind == "banner" then -- big vertical anniversary banner
		deco(parent, "BannerPole", Vector3.new(0.4, 16, 0.4), CFrame.new(p + Vector3.new(-2.2, 8, 0)), DARK, Enum.Material.Metal)
		deco(parent, "BannerPole", Vector3.new(0.4, 16, 0.4), CFrame.new(p + Vector3.new(2.2, 8, 0)), DARK, Enum.Material.Metal)
		local b = deco(parent, "Banner", Vector3.new(4.2, 9, 0.12), CFrame.new(p + Vector3.new(0, 10.5, 0)), GREEN, Enum.Material.Fabric)
		for _, f in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do sign(b, f, "SAMAR\nCOLLEGE\nFOUNDING\nANNIV.", GREEN, GOLD, 30) end
	elseif spot.kind == "balloons" then
		balloons(parent, p) balloons(parent, p + Vector3.new(3, 0, 0))
	elseif spot.kind == "bunting" then
		deco(parent, "BuntingPost", Vector3.new(0.4, 14, 0.4), CFrame.new(p + Vector3.new(-12, 7, 0)), DARK, Enum.Material.Metal)
		deco(parent, "BuntingPost", Vector3.new(0.4, 14, 0.4), CFrame.new(p + Vector3.new(12, 7, 0)), DARK, Enum.Material.Metal)
		bunting(parent, p + Vector3.new(-12, 13.5, 0), p + Vector3.new(12, 13.5, 0), 2.5)
	end
end

---------------------------------------------------------------- FLOATS
local FLOAT_DEFS = {
	{ name = "COLLEGE", icon = "🎓", color = Color3.fromRGB(30, 110, 60), accent = GOLD },
	{ name = "SENIOR HIGH", icon = "📘", color = Color3.fromRGB(40, 90, 190), accent = WHITE },
	{ name = "JUNIOR HIGH", icon = "📗", color = Color3.fromRGB(210, 70, 60), accent = GOLD },
	{ name = "ELEMENTARY", icon = "🧸", color = Color3.fromRGB(240, 170, 40), accent = Color3.fromRGB(60, 160, 220) },
}
local function buildFloat(parent, def)
	local f = Instance.new("Model") f.Name = "Float_" .. def.name:gsub("%W", "")
	local base = part(f, "FloatBase", Vector3.new(9, 2.4, 15), CFrame.new(), def.color, Enum.Material.SmoothPlastic)
	f.PrimaryPart = base
	local function at(x, y, z) return base.CFrame * CFrame.new(x, y, z) end
	part(f, "Skirt", Vector3.new(9.4, 1.6, 15.4), at(0, -1.2, 0), def.accent, Enum.Material.Fabric)
	for _, x in ipairs({ -3.6, 3.6 }) do for _, z in ipairs({ -5, 5 }) do part(f, "Wheel", Vector3.new(0.8, 2.2, 2.2), at(x, -1.6, z) * CFrame.Angles(0, 0, 0), DARK, Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder }) end end
	-- flower trim
	for i = 0, 13 do for _, x in ipairs({ -4.6, 4.6 }) do part(f, "Flower", Vector3.new(0.7, 0.7, 0.7), at(x, 1.2, -6.5 + i), FLAG[(i % #FLAG) + 1], Enum.Material.Fabric, { Shape = Enum.PartType.Ball }) end end
	-- theme centrepiece
	part(f, "Platform", Vector3.new(6, 1.2, 6), at(0, 1.8, 2), WHITE, Enum.Material.Marble)
	part(f, "Pillar", Vector3.new(1.2, 6, 1.2), at(0, 5.4, 2), def.accent, Enum.Material.Marble)
	local emblem = part(f, "Emblem", Vector3.new(0.4, 4.4, 4.4), at(0, 9.4, 2) * CFrame.Angles(0, 0, math.rad(90)), def.accent, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
	local banner = part(f, "Banner", Vector3.new(0.3, 2.6, 13), at(0, 3.6, -1.5), WHITE, Enum.Material.Fabric)
	sign(banner, Enum.NormalId.Left, def.icon .. " " .. def.name .. " DEPARTMENT", WHITE, def.color, 30)
	sign(banner, Enum.NormalId.Right, def.icon .. " " .. def.name .. " DEPARTMENT", WHITE, def.color, 30)
	local eb = Instance.new("BillboardGui") eb.Size = UDim2.fromOffset(110, 110) eb.LightInfluence = 0 eb.MaxDistance = 140 eb.Parent = emblem
	local et = Instance.new("TextLabel") et.Size = UDim2.fromScale(1, 1) et.BackgroundTransparency = 1 et.TextScaled = true et.Text = def.icon et.Parent = eb
	-- arch of balloons over the float
	for i = 0, 10 do
		local a = i / 10 * math.pi
		part(f, "ArchBalloon", Vector3.new(1.3, 1.5, 1.3), at(math.cos(a) * 4.2, 3 + math.sin(a) * 6, -5.5), FLAG[i % #FLAG + 1], Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball, Reflectance = 0.15 })
	end
	-- confetti
	local pe = Instance.new("ParticleEmitter") pe.Rate = 18 pe.Lifetime = NumberRange.new(2, 3) pe.Speed = NumberRange.new(6, 10)
	pe.SpreadAngle = Vector2.new(40, 40) pe.Acceleration = Vector3.new(0, -8, 0) pe.Rotation = NumberRange.new(0, 360) pe.RotSpeed = NumberRange.new(-180, 180)
	pe.Size = NumberSequence.new(0.35) pe.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, FLAG[1]), ColorSequenceKeypoint.new(0.33, FLAG[2]), ColorSequenceKeypoint.new(0.66, FLAG[4]), ColorSequenceKeypoint.new(1, FLAG[5]) })
	pe.EmissionDirection = Enum.NormalId.Top pe.Enabled = false pe.Parent = emblem
	for _, p in ipairs(f:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false p.CanQuery = false p.CanTouch = false p.Anchored = true end end
	-- keep the relative layout: store offsets from the base, then move by PivotTo
	f.Parent = parent
	return f, pe
end

---------------------------------------------------------------- NPC guest performers
local function spawnDancer(parent, cf, colors, label)
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = colors.skin desc.LeftArmColor = colors.skin desc.RightArmColor = colors.skin
	desc.TorsoColor = colors.top desc.LeftLegColor = colors.bottom desc.RightLegColor = colors.bottom
	local ok, rig = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
	if not ok or not rig then return nil end
	rig.Name = "GuestPerformer"
	rig:PivotTo(cf)
	local hum = rig:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	rig.HumanoidRootPart.Anchored = true
	-- costume: skirt / sash pieces
	local torso = rig:FindFirstChild("UpperTorso")
	local lower = rig:FindFirstChild("LowerTorso")
	if lower then attachTo(rig, lower, "Costume", Vector3.new(2.4, 1.4, 1.6), CFrame.new(0, -0.6, 0), colors.costume, Enum.Material.Fabric) end
	if torso then attachTo(rig, torso, "Sash", Vector3.new(2.6, 0.45, 0.06), CFrame.new(0, 0, -torso.Size.Z / 2 - 0.04) * CFrame.Angles(0, 0, math.rad(-35)), colors.accent, Enum.Material.Fabric) end
	local bb = Instance.new("BillboardGui") bb.Size = UDim2.fromOffset(150, 24) bb.StudsOffset = Vector3.new(0, 3.2, 0) bb.MaxDistance = 90 bb.Parent = rig.Head
	local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.Font = Enum.Font.GothamBold t.TextScaled = true
	t.TextColor3 = GOLD t.TextStrokeTransparency = 0.3 t.Text = label t.Parent = bb
	rig.Parent = parent
	return rig
end
local function playDance(rig, animId)
	local hum = rig and rig:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	for _, t in ipairs(animator:GetPlayingAnimationTracks()) do t:Stop(0.3) end
	local a = Instance.new("Animation") a.AnimationId = animId
	local ok, track = pcall(function() return animator:LoadAnimation(a) end)
	if ok and track then track.Looped = true track:Play(0.3) end
end

---------------------------------------------------------------- fireworks
local function firework(ctx, center)
	local pos = center + Vector3.new(math.random(-50, 50), math.random(45, 75), math.random(-50, 50))
	local p = part(ctx.Folder, "Firework", Vector3.new(1, 1, 1), CFrame.new(pos), Color3.new(1, 1, 1), Enum.Material.Neon, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local pe = Instance.new("ParticleEmitter") pe.Rate = 0 pe.Speed = NumberRange.new(25, 40) pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(1, 1.6) pe.Drag = 3 pe.Acceleration = Vector3.new(0, -12, 0) pe.LightEmission = 1
	local col = FLAG[math.random(#FLAG)]
	pe.Color = ColorSequence.new(col, Color3.new(1, 1, 1)) pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) }) pe.Parent = p
	local light = Instance.new("PointLight") light.Color = col light.Range = 60 light.Brightness = 6 light.Parent = p
	pe:Emit(160)
	task.delay(0.4, function() light.Enabled = false end)
	task.delay(2.5, function() p:Destroy() end)
end

---------------------------------------------------------------- SETUP
function M.Setup(ctx)
	local cfg = ctx.Config.FoundationDay
	local D = ctx.Data
	D.cfg = cfg
	D.program = cfg.Program
	D.seg = 0
	D.segEndsAt = 0
	D.cands = { Mr = {}, Ms = {} }
	D.candByPlayer = {}
	D.talentVotes, D.crownVotes = {}, { Mr = {}, Ms = {} }
	D.registrationOpen = true
	D.votingTalent, D.votingCrown = false, false
	D.decorated = 0
	D.decoSpots = DECO_SPOTS
	D.foodsEaten = {}
	D.boothUsed = {}
	D.cheers = {}
	D.center = Vector3.new(170, FLOOR, 38)
	local folder = ctx.Folder
	local stageC = Vector3.new(STAGE_FRONT, STAGE_TOP, STAGE_Z)
	D.stageC = stageC

	---------------------------------------------------------------- general decor
	local decor = Instance.new("Model") decor.Name = "AnniversaryDecor" decor.Parent = folder
	-- welcome arch at the south end of the runway axis
	local archX = 106
	for _, dz in ipairs({ -11, 11 }) do
		part(decor, "ArchPillar", Vector3.new(1.8, 17, 1.8), CFrame.new(archX, FLOOR + 8.5, STAGE_Z + dz), GOLD, Enum.Material.Marble)
		balloons(decor, Vector3.new(archX + 2, FLOOR, STAGE_Z + dz))
	end
	local archTop = deco(decor, "ArchBanner", Vector3.new(0.6, 4, 24), CFrame.new(archX, FLOOR + 17, STAGE_Z), GREEN)
	sign(archTop, Enum.NormalId.Right, "🎉 SAMAR COLLEGE • FOUNDING ANNIVERSARY 🎉", GREEN, GOLD)
	sign(archTop, Enum.NormalId.Left, "🎉 SAMAR COLLEGE • FOUNDING ANNIVERSARY 🎉", GREEN, GOLD)
	-- bunting criss-crossing the quadrangle
	for _, x in ipairs({ 120, 145, 170, 195, 220 }) do bunting(decor, Vector3.new(x, 21, -25), Vector3.new(x, 21, 99), 3.5) end
	bunting(decor, Vector3.new(104, 22, -25), Vector3.new(232, 22, 99), 5)
	bunting(decor, Vector3.new(104, 22, 99), Vector3.new(232, 22, -25), 5)
	-- first aid & safety tent (Safety and Physical Arrangements)
	local tentC = Vector3.new(106, FLOOR, 74)
	part(decor, "AidTable", Vector3.new(5, 3, 2.5), CFrame.new(tentC + Vector3.new(0, 1.5, 0)), WHITE, Enum.Material.Wood)
	for _, dx in ipairs({ -3, 3 }) do for _, dz in ipairs({ -3, 3 }) do deco(decor, "AidPole", Vector3.new(0.25, 8, 0.25), CFrame.new(tentC + Vector3.new(dx, 4, dz)), Color3.fromRGB(200, 200, 205), Enum.Material.Metal) end end
	deco(decor, "AidRoof", Vector3.new(7, 0.3, 7), CFrame.new(tentC + Vector3.new(0, 8, 0)), WHITE, Enum.Material.Fabric)
	local aidSign = deco(decor, "AidSign", Vector3.new(0.2, 1.6, 5), CFrame.new(tentC + Vector3.new(3.5, 6.8, 0)), WHITE)
	sign(aidSign, Enum.NormalId.Right, "➕ FIRST AID & SAFETY DESK", WHITE, Color3.fromRGB(200, 40, 40))
	deco(decor, "AidKit", Vector3.new(1.2, 0.8, 0.8), CFrame.new(tentC + Vector3.new(0, 3.4, 0)), Color3.fromRGB(220, 40, 40))
	for i = 0, 2 do deco(decor, "Cone", Vector3.new(0.9, 1.4, 0.9), CFrame.new(Vector3.new(104.5, FLOOR + 0.7, 20 + i * 6)), Color3.fromRGB(250, 120, 30), Enum.Material.Plastic) end

	---------------------------------------------------------------- MAIN STAGE dressing (on the Quadrangle stage)
	local stage = Instance.new("Model") stage.Name = "MainStage" stage.Parent = folder
	local back = STAGE_FRONT + 15
	-- LED wall
	local wall = deco(stage, "LEDWall", Vector3.new(0.8, 15, 40), CFrame.new(back, STAGE_TOP + 9, STAGE_Z), Color3.fromRGB(12, 16, 24))
	local g = Instance.new("SurfaceGui") g.Face = Enum.NormalId.Left g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = 24 g.LightInfluence = 0 g.Brightness = 2 g.Parent = wall
	local screen = Instance.new("Frame") screen.Size = UDim2.fromScale(1, 1) screen.BackgroundColor3 = Color3.fromRGB(10, 40, 26) screen.Parent = g
	local grad = Instance.new("UIGradient") grad.Rotation = 90 grad.Color = ColorSequence.new(Color3.fromRGB(16, 70, 42), Color3.fromRGB(6, 18, 14)) grad.Parent = screen
	local function lbl(name, y, h, text, color, font)
		local t = Instance.new("TextLabel") t.Name = name t.BackgroundTransparency = 1 t.Position = UDim2.fromScale(0.04, y) t.Size = UDim2.fromScale(0.92, h)
		t.TextScaled = true t.Font = font or Enum.Font.GothamBlack t.TextColor3 = color t.Text = text t.Parent = screen return t
	end
	lbl("Top", 0.04, 0.12, "SAMAR COLLEGE • FOUNDING ANNIVERSARY", GOLD)
	D.screenNow = lbl("Now", 0.22, 0.24, "🎉 WELCOME!", WHITE)
	D.screenSub = lbl("Sub", 0.5, 0.2, "", Color3.fromRGB(200, 230, 210), Enum.Font.GothamBold)
	D.screenLive = lbl("Live", 0.78, 0.12, "🔴 LIVE • SC PRESS COVERAGE", Color3.fromRGB(255, 120, 120), Enum.Font.GothamBold)
	-- LED frame + side towers
	deco(stage, "LEDFrame", Vector3.new(1, 0.8, 42), CFrame.new(back, STAGE_TOP + 16.8, STAGE_Z), Color3.fromRGB(200, 200, 205), Enum.Material.DiamondPlate)
	for _, s in ipairs({ -1, 1 }) do
		local z = STAGE_Z + s * 21
		deco(stage, "TrussTower", Vector3.new(1.2, 22, 1.2), CFrame.new(STAGE_FRONT + 3, STAGE_TOP + 11, z), Color3.fromRGB(190, 190, 195), Enum.Material.DiamondPlate)
		part(stage, "Speaker", Vector3.new(3, 7, 3), CFrame.new(STAGE_FRONT + 3, STAGE_TOP + 3.5, z - s * 2.5), DARK)
		deco(stage, "SpeakerCone", Vector3.new(0.1, 2, 2), CFrame.new(STAGE_FRONT + 1.45, STAGE_TOP + 4.5, z - s * 2.5) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 60, 60), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
		-- side banners
		local sb = deco(stage, "SideBanner", Vector3.new(0.2, 12, 5), CFrame.new(back - 1, STAGE_TOP + 8, STAGE_Z + s * 23.5), GREEN, Enum.Material.Fabric)
		sign(sb, Enum.NormalId.Left, "SC", GREEN, GOLD, 30)
	end
	deco(stage, "TrussTop", Vector3.new(1.2, 1.2, 44), CFrame.new(STAGE_FRONT + 3, STAGE_TOP + 22, STAGE_Z), Color3.fromRGB(190, 190, 195), Enum.Material.DiamondPlate)
	-- moving head lights
	D.lights = {}
	for k = 1, 7 do
		local z = STAGE_Z - 18 + (k - 1) * 6
		local lamp = deco(stage, "MovingHead", Vector3.new(1.2, 1.4, 1.2), CFrame.new(STAGE_FRONT + 3, STAGE_TOP + 20.8, z), FLAG[(k % #FLAG) + 1], Enum.Material.Neon)
		local sl = Instance.new("SpotLight") sl.Face = Enum.NormalId.Bottom sl.Range = 40 sl.Angle = 30 sl.Brightness = 5 sl.Color = lamp.Color sl.Parent = lamp
		table.insert(D.lights, { part = lamp, base = lamp.CFrame, k = k })
	end
	-- follow spotlight for the pageant
	local follow = deco(stage, "FollowSpot", Vector3.new(1.6, 1.6, 2.2), CFrame.new(STAGE_FRONT + 3, STAGE_TOP + 21.6, STAGE_Z), Color3.fromRGB(240, 240, 240), Enum.Material.Neon)
	local fsl = Instance.new("SpotLight") fsl.Face = Enum.NormalId.Front fsl.Range = 60 fsl.Angle = 14 fsl.Brightness = 10 fsl.Enabled = false fsl.Parent = follow
	D.follow, D.followLight = follow, fsl
	-- podium + mic stand
	part(stage, "Podium", Vector3.new(1.8, 4, 2.6), CFrame.new(STAGE_FRONT + 5, STAGE_TOP + 2, STAGE_Z - 15), WOOD, Enum.Material.Wood)
	local seal = deco(stage, "PodiumSeal", Vector3.new(0.1, 1.6, 1.6), CFrame.new(STAGE_FRONT + 4.05, STAGE_TOP + 2.6, STAGE_Z - 15), GOLD)
	sign(seal, Enum.NormalId.Left, "SC", GREEN, GOLD)
	-- stage stairs (both sides of the runway)
	for _, s in ipairs({ -1, 1 }) do
		for k = 0, 2 do part(stage, "StageStep", Vector3.new(1.6, 1, 5), CFrame.new(STAGE_FRONT - 0.8 - (2 - k) * 1.6, FLOOR + 0.5 + k * 0.85, STAGE_Z + s * 14), Color3.fromRGB(110, 75, 45), Enum.Material.WoodPlanks) end
	end
	-- runway (catwalk) with glowing edges
	local rwLen = STAGE_FRONT - RUNWAY_X0
	local rwC = Vector3.new(RUNWAY_X0 + rwLen / 2, STAGE_TOP / 2 + FLOOR / 2, STAGE_Z)
	part(stage, "Runway", Vector3.new(rwLen, STAGE_TOP - FLOOR + 0.02, 7), CFrame.new(rwC), WHITE, Enum.Material.Marble)
	deco(stage, "RunwayCarpet", Vector3.new(rwLen, 0.05, 3.4), CFrame.new(RUNWAY_X0 + rwLen / 2, STAGE_TOP + 0.03, STAGE_Z), Color3.fromRGB(170, 20, 40), Enum.Material.Fabric)
	for _, s in ipairs({ -1, 1 }) do deco(stage, "RunwayLED", Vector3.new(rwLen, 0.15, 0.2), CFrame.new(RUNWAY_X0 + rwLen / 2, STAGE_TOP + 0.05, STAGE_Z + s * 3.45), GOLD, Enum.Material.Neon) end
	part(stage, "RunwayEnd", Vector3.new(0.4, STAGE_TOP - FLOOR, 7.4), CFrame.new(RUNWAY_X0 - 0.2, STAGE_TOP / 2 + FLOOR / 2, STAGE_Z), GOLD, Enum.Material.Foil)
	-- audience chairs (monobloc) either side of the runway
	local chairs = Instance.new("Model") chairs.Name = "AudienceChairs" chairs.Parent = folder
	for row = 0, 4 do
		for col = 0, 6 do
			for _, s in ipairs({ -1, 1 }) do
				local pos = Vector3.new(196 - row * 5, FLOOR, STAGE_Z + s * (7 + col * 3.6))
				local cf = CFrame.lookAt(pos, Vector3.new(STAGE_FRONT, FLOOR, STAGE_Z))
				local seat = Instance.new("Seat") seat.Name = "Chair" seat.Size = Vector3.new(2, 0.3, 2) seat.CFrame = cf * CFrame.new(0, 1.8, 0)
				seat.Color = ((row + col) % 2 == 0) and WHITE or Color3.fromRGB(40, 140, 80) seat.Material = Enum.Material.Plastic seat.Anchored = true seat.Parent = chairs
				deco(chairs, "ChairBack", Vector3.new(2, 2.2, 0.25), cf * CFrame.new(0, 3, 0.95), seat.Color, Enum.Material.Plastic)
				for _, lx in ipairs({ -0.85, 0.85 }) do for _, lz in ipairs({ -0.85, 0.85 }) do deco(chairs, "ChairLeg", Vector3.new(0.2, 1.7, 0.2), cf * CFrame.new(lx, 0.85, lz), seat.Color, Enum.Material.Plastic) end end
			end
		end
	end
	-- media riser (Media Coverage) with a camera on a tripod
	local riser = Vector3.new(200, FLOOR, 2)
	part(stage, "MediaRiser", Vector3.new(6, 2, 8), CFrame.new(riser + Vector3.new(0, 1, 0)), Color3.fromRGB(60, 60, 66), Enum.Material.DiamondPlate)
	for k = 0, 2 do deco(stage, "Tripod", Vector3.new(0.12, 3.4, 0.12), CFrame.new(riser + Vector3.new(0, 3.6, 0)) * CFrame.Angles(math.rad(14), k * 2.1, 0), DARK, Enum.Material.Metal) end
	deco(stage, "Camera", Vector3.new(1.6, 1, 0.9), CFrame.lookAt(riser + Vector3.new(0, 5.6, 0), stageC + Vector3.new(0, 5, 0)), DARK)
	local press = deco(stage, "PressSign", Vector3.new(0.2, 1.4, 6), CFrame.new(riser + Vector3.new(-3.1, 2.6, 0)), Color3.fromRGB(30, 30, 34))
	sign(press, Enum.NormalId.Left, "📰 SC PRESS • MEDIA", Color3.fromRGB(30, 30, 34), WHITE)
	-- press drone circling the quadrangle
	local drone = Instance.new("Model") drone.Name = "PressDrone" drone.Parent = folder
	local body = deco(drone, "Body", Vector3.new(1.6, 0.5, 1.6), CFrame.new(170, 28, 38), DARK)
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		deco(drone, "Arm", Vector3.new(0.2, 0.15, 2.4), body.CFrame * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -1.1), Color3.fromRGB(60, 60, 60))
		deco(drone, "Rotor", Vector3.new(0.1, 1.4, 1.4), body.CFrame * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.25, -2.2) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(180, 180, 180), Enum.Material.Glass, { Shape = Enum.PartType.Cylinder, Transparency = 0.5 })
	end
	local led = deco(drone, "Led", Vector3.new(0.3, 0.3, 0.3), body.CFrame * CFrame.new(0, -0.35, -0.6), Color3.fromRGB(255, 40, 40), Enum.Material.Neon)
	drone.PrimaryPart = body
	D.drone = drone

	---------------------------------------------------------------- BOOTHS & TRADE FAIR
	local fair = Instance.new("Model") fair.Name = "TradeFair" fair.Parent = folder
	local P = cfg.Points
	local function eat(player, food, anchor)
		holdItem(player, food.build, 6)
		sfx(anchor, EAT_SOUND, 0.6)
		D.foodsEaten[player] = D.foodsEaten[player] or {}
		local eaten = D.foodsEaten[player]
		if not eaten[food.id] then
			eaten[food.id] = true
			local n = 0 for _ in pairs(eaten) do n += 1 end
			ctx:AddScore(player, P.BoothFirst)
			ctx:Toast(player, ("%s %s — yum! (%d/%d foods) +%d"):format(food.icon, food.name, n, #FOODS, P.BoothFirst))
			if n == #FOODS then
				ctx:AddScore(player, P.FoodTripBonus)
				ctx:Toast(player, ("🏆 FOOD TRIP COMPLETE! You tried every stall. +%d"):format(P.FoodTripBonus))
			end
		else
			ctx:Toast(player, food.icon .. " Another " .. food.name .. "? Masarap! 😋")
		end
	end
	local booths = {}
	for _, f in ipairs(FOODS) do
		table.insert(booths, { title = f.name, icon = f.icon, color = f.color, action = "Buy " .. f.price,
			props = function(m, at) for i = 0, 3 do local cf = at(-3 + i * 2, 3.7, -1.4) f.build(m, cf) end end,
			use = function(player, anchor) eat(player, f, anchor) end })
	end
	table.insert(booths, { title = "Ring Toss", icon = "🎯", color = Color3.fromRGB(220, 60, 120), action = "Throw a ring",
		props = function(m, at) for i = 0, 5 do part(m, "Bottle", Vector3.new(0.4, 1.4, 0.4), at(-3 + i * 1.2, 4.1, -0.6), Color3.fromRGB(40, 140, 80), Enum.Material.Glass, { Transparency = 0.2 }) end end,
		use = function(player, anchor)
			local now = os.clock()
			D.boothUsed[player] = D.boothUsed[player] or {}
			if (D.boothUsed[player].ring or 0) > now then return ctx:Toast(player, "🎯 Catch your breath — try again in a moment") end
			D.boothUsed[player].ring = now + 3
			local ring = deco(ctx.Folder, "TossRing", Vector3.new(0.15, 1.3, 1.3), anchor.CFrame * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Neon, { Shape = Enum.PartType.Cylinder })
			Debris:AddItem(ring, 1.4)
			ctx:AddScore(player, P.RingTry)
			if math.random() < 0.35 then
				ctx:AddScore(player, P.RingWin)
				ctx:Toast(player, ("🎯 RINGER! You won a prize! +%d"):format(P.RingWin + P.RingTry))
				sfx(anchor, BELL_SOUND, 0.7)
			else ctx:Toast(player, "🎯 So close! Try again.") end
		end })
	table.insert(booths, { title = "Souvenirs", icon = "🎁", color = Color3.fromRGB(70, 120, 220), action = "Get a souvenir pin",
		props = function(m, at) for i = 0, 3 do part(m, "Pin", Vector3.new(0.6, 0.6, 0.1), at(-3 + i * 2, 3.8, -1.2), GOLD, Enum.Material.Foil, { Shape = Enum.PartType.Cylinder }) end end,
		use = function(player)
			local char = player.Character local torso = torsoOf(char)
			if not torso then return end
			local had = char:FindFirstChild("FD_Pin")
			if had then return ctx:Toast(player, "🎁 You already wear the anniversary pin!") end
			local pin = attachTo(char, torso, "FD_Pin", Vector3.new(0.08, 0.45, 0.45), CFrame.new(-torso.Size.X * 0.25, torso.Size.Y * 0.25, -torso.Size.Z / 2 - 0.05) * CFrame.Angles(0, math.rad(90), 0), GOLD, Enum.Material.Foil)
			pin.Shape = Enum.PartType.Cylinder
			ctx:AddScore(player, P.Souvenir)
			ctx:Toast(player, ("🎁 You got the Founding Anniversary pin! +%d"):format(P.Souvenir))
		end })
	table.insert(booths, { title = "Face Paint", icon = "🎨", color = Color3.fromRGB(240, 130, 40), action = "Paint my face",
		props = function(m, at) for i = 0, 4 do part(m, "PaintPot", Vector3.new(0.5, 0.5, 0.5), at(-3 + i * 1.5, 3.7, -1.2), FLAG[i + 1], Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder }) end end,
		use = function(player)
			local char = player.Character local head = char and char:FindFirstChild("Head")
			if not head then return end
			if char:FindFirstChild("FD_Paint") then return ctx:Toast(player, "🎨 Your face is already painted in school colors!") end
			local m = Instance.new("Model") m.Name = "FD_Paint" m.Parent = char
			for i, c in ipairs({ GREEN, GOLD }) do
				local p = Instance.new("Part") p.Size = Vector3.new(0.12, 0.35, 0.05) p.Color = c p.Material = Enum.Material.SmoothPlastic
				p.CanCollide = false p.CanQuery = false p.CanTouch = false p.Massless = true
				p.CFrame = head.CFrame * CFrame.new(0.32 + (i - 1) * 0.16, -0.05, -head.Size.Z / 2 - 0.01) p.Parent = m weld(head, p)
			end
			ctx:AddScore(player, P.FacePaint)
			ctx:Toast(player, ("🎨 Green & gold school colors — looking proud! +%d"):format(P.FacePaint))
		end })
	table.insert(booths, { title = "Lucky Draw", icon = "🎟️", color = Color3.fromRGB(150, 70, 200), action = "Draw a ticket",
		props = function(m, at) part(m, "Drum", Vector3.new(2.4, 2, 2), at(0, 4.6, -1), Color3.fromRGB(240, 200, 60), Enum.Material.Foil, { Shape = Enum.PartType.Cylinder }) end,
		use = function(player)
			D.boothUsed[player] = D.boothUsed[player] or {}
			if D.boothUsed[player].lucky then return ctx:Toast(player, "🎟️ One lucky draw per student — good luck next year!") end
			D.boothUsed[player].lucky = true
			local prizes = P.LuckyDraw
			local pts = prizes[math.random(#prizes)]
			ctx:AddScore(player, pts)
			ctx:Toast(player, ("🎟️ Lucky draw: you won %d points! %s"):format(pts, pts >= 20 and "JACKPOT! 🎉" or ""))
		end })
	-- 6 booths on each long side of the quadrangle (z = -20 faces +z, z = 94 faces -z)
	for i, b in ipairs(booths) do
		local side = (i <= 6) and -1 or 1
		local idx = (i - 1) % 6
		local x = 122 + idx * 12
		local pos = Vector3.new(x, FLOOR, side == -1 and -19 or 93)
		local dir = Vector3.new(0, 0, side == -1 and 1 or -1)
		buildBooth(ctx, fair, pos, dir, b.title, b.icon, b.color, b.props, b.action, function(player, anchor)
			if D.seg < 2 then return ctx:Toast(player, "🛍️ The trade fair opens after the Opening program!") end
			b.use(player, anchor)
		end)
	end
	-- trade fair entrance arch
	local tfa = deco(fair, "FairSign", Vector3.new(0.3, 2.6, 16), CFrame.new(110, FLOOR + 12, -12), Color3.fromRGB(150, 40, 60))
	sign(tfa, Enum.NormalId.Right, "🛍️ CAMPUS BOOTHS & TRADE FAIR", Color3.fromRGB(150, 40, 60), WHITE)
	sign(tfa, Enum.NormalId.Left, "🛍️ CAMPUS BOOTHS & TRADE FAIR", Color3.fromRGB(150, 40, 60), WHITE)

	---------------------------------------------------------------- PHOTO BOOTH (Documentation)
	local pb = Instance.new("Model") pb.Name = "PhotoBooth" pb.Parent = folder
	local pbC = Vector3.new(214, FLOOR, 88)
	local frameBack = part(pb, "Backdrop", Vector3.new(12, 10, 0.4), CFrame.new(pbC + Vector3.new(0, 5, 3)), GREEN, Enum.Material.Fabric)
	sign(frameBack, Enum.NormalId.Front, "📸 SAMAR COLLEGE\nFOUNDING ANNIVERSARY\n#SamarCollege", GREEN, GOLD, 26)
	for k = 0, 9 do deco(pb, "FrameBalloon", Vector3.new(1.2, 1.4, 1.2), CFrame.new(pbC + Vector3.new(-6 + k * 1.33, 10.3, 2.6)), FLAG[k % #FLAG + 1], Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball }) end
	local giant = deco(pb, "GiantFrame", Vector3.new(5, 6.5, 0.3), CFrame.new(pbC + Vector3.new(0, 3.4, -3)), GOLD, Enum.Material.Foil)
	deco(pb, "FrameHole", Vector3.new(4, 5.3, 0.35), giant.CFrame, Color3.new(1, 1, 1), nil, { Transparency = 1 })
	local cam = deco(pb, "BoothCamera", Vector3.new(1.4, 1, 0.9), CFrame.lookAt(pbC + Vector3.new(0, 4.5, -10), pbC + Vector3.new(0, 3, 0)), DARK)
	deco(pb, "CameraTripod", Vector3.new(0.15, 4, 0.15), CFrame.new(pbC + Vector3.new(0, 2, -10)), DARK, Enum.Material.Metal)
	local flash = deco(pb, "Flash", Vector3.new(0.8, 0.5, 0.2), cam.CFrame * CFrame.new(0, 0.75, 0), Color3.fromRGB(230, 230, 230), Enum.Material.Glass)
	local flashLight = Instance.new("PointLight") flashLight.Range = 18 flashLight.Brightness = 0 flashLight.Parent = flash
	local pbAnchor = deco(pb, "PromptAnchor", Vector3.new(1, 1, 1), CFrame.new(pbC + Vector3.new(0, 2.5, -1)), Color3.new(1, 1, 1), nil, { Transparency = 1 })
	local ppb = prompt(pbAnchor, "Take a photo", "📸 Photo Booth", 10)
	ctx:Connect(ppb.Triggered, function(player)
		if not ensureJoined(ctx, player) then return end
		D.boothUsed[player] = D.boothUsed[player] or {}
		local u = D.boothUsed[player]
		if (u.photoAt or 0) > os.clock() then return ctx:Toast(player, "📸 Hold your pose — the camera is getting ready…") end
		u.photoAt = os.clock() + 6
		flashLight.Brightness = 8 task.delay(0.15, function() flashLight.Brightness = 0 end)
		flash.Material = Enum.Material.Neon task.delay(0.2, function() flash.Material = Enum.Material.Glass end)
		ctx:Send(player, { type = "photo" })
		if not u.photo then u.photo = true ctx:AddScore(player, P.Photo) ctx:Toast(player, ("📸 Say cheese! Your anniversary photo is ready. +%d"):format(P.Photo))
		else ctx:Toast(player, "📸 Another great shot!") end
	end)

	---------------------------------------------------------------- DECORATION spots (Opening)
	local decoFolder = Instance.new("Model") decoFolder.Name = "CommitteeDecorations" decoFolder.Parent = folder
	D.decoDone = {}
	D.decoPrompts = {}
	for i, spot in ipairs(DECO_SPOTS) do
		local box = part(decoFolder, "DecorationCrate", Vector3.new(2.2, 1.6, 2.2), CFrame.new(spot.pos + Vector3.new(0, 0.8, 0)), Color3.fromRGB(170, 120, 70), Enum.Material.WoodPlanks)
		local sp = Instance.new("Sparkles") sp.SparkleColor = GOLD sp.Parent = box
		local bb = Instance.new("BillboardGui") bb.Size = UDim2.fromOffset(150, 30) bb.StudsOffset = Vector3.new(0, 2.6, 0) bb.MaxDistance = 70 bb.Parent = box
		local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.Font = Enum.Font.GothamBold t.TextScaled = true
		t.TextColor3 = GOLD t.TextStrokeTransparency = 0.3 t.Text = "✨ Hang the " .. spot.kind t.Parent = bb
		local pp = prompt(box, "Hang the " .. spot.kind, "✨ Decoration", 9, 1.2)
		D.decoPrompts[i] = { box = box, prompt = pp }
		ctx:Connect(pp.Triggered, function(player)
			if D.decoDone[i] or not ensureJoined(ctx, player) then return end
			D.decoDone[i] = true
			box:Destroy()
			buildDecoration(decoFolder, spot)
			D.decorated += 1
			ctx:AddScore(player, P.Decorate)
			ctx:Toast(player, ("✨ You hung the %s! (%d/%d decorated) +%d"):format(spot.kind, D.decorated, #DECO_SPOTS, P.Decorate))
			pushState(ctx)
		end)
	end

	---------------------------------------------------------------- PARADE FLOATS
	local parade = Instance.new("Model") parade.Name = "FloatParade" parade.Parent = folder
	D.floats = {}
	-- route length for spacing
	local total = 0
	for i = 1, #ROUTE do total += (ROUTE[i % #ROUTE + 1] - ROUTE[i]).Magnitude end
	D.routeLen = total
	for i, def in ipairs(FLOAT_DEFS) do
		local f, pe = buildFloat(parade, def)
		table.insert(D.floats, { model = f, confetti = pe, offset = (i - 1) * total / #FLOAT_DEFS })
	end
	D.paradeDist = 0
	-- park the floats at the route start, hidden until the parade
	for _, fl in ipairs(D.floats) do fl.model:PivotTo(CFrame.new(ROUTE[1] + Vector3.new(0, -40, 0))) end

	---------------------------------------------------------------- PARLOR GAMES: PABITIN
	local pg = Instance.new("Model") pg.Name = "ParlorGames" pg.Parent = folder
	local pabC = Vector3.new(130, FLOOR, 20)
	D.pabC = pabC
	for _, dx in ipairs({ -8, 8 }) do for _, dz in ipairs({ -8, 8 }) do cyl(pg, "BambooPost", pabC + Vector3.new(dx, 0, dz), pabC + Vector3.new(dx, 20, dz), 0.6, Color3.fromRGB(190, 170, 90), Enum.Material.Wood) end end
	for _, dz in ipairs({ -8, 8 }) do cyl(pg, "TopBeam", pabC + Vector3.new(-8.3, 20, dz), pabC + Vector3.new(8.3, 20, dz), 0.6, Color3.fromRGB(190, 170, 90), Enum.Material.Wood) end
	local lattice = Instance.new("Model") lattice.Name = "PabitinLattice" lattice.Parent = pg
	local latBase = part(lattice, "Frame", Vector3.new(12, 0.3, 12), CFrame.new(pabC + Vector3.new(0, 16, 0)), Color3.fromRGB(190, 170, 90), Enum.Material.Wood, { Transparency = 1, CanCollide = false })
	for k = -2, 2 do
		deco(lattice, "Slat", Vector3.new(12, 0.3, 0.3), latBase.CFrame * CFrame.new(0, 0, k * 3), Color3.fromRGB(190, 170, 90), Enum.Material.Wood)
		deco(lattice, "Slat", Vector3.new(0.3, 0.3, 12), latBase.CFrame * CFrame.new(k * 3, 0, 0), Color3.fromRGB(190, 170, 90), Enum.Material.Wood)
	end
	for _, dx in ipairs({ -6, 6 }) do for _, dz in ipairs({ -6, 6 }) do deco(lattice, "Rope", Vector3.new(0.1, 4.5, 0.1), latBase.CFrame * CFrame.new(dx, 2.25, dz), Color3.fromRGB(220, 210, 180), Enum.Material.Fabric) end end
	lattice.PrimaryPart = latBase
	D.lattice = lattice
	D.prizes = {}
	local pabSign = deco(pg, "PabitinSign", Vector3.new(0.3, 2, 10), CFrame.new(pabC + Vector3.new(-9, 3, 0)), Color3.fromRGB(150, 40, 60))
	sign(pabSign, Enum.NormalId.Left, "🎁 PABITIN — JUMP & GRAB!", Color3.fromRGB(150, 40, 60), GOLD)
	sign(pabSign, Enum.NormalId.Right, "🎁 PABITIN — JUMP & GRAB!", Color3.fromRGB(150, 40, 60), GOLD)
	---------------------------------------------------------------- PARLOR GAMES: SACK RACE (4 lanes along x)
	D.lanes = {}
	local laneX0, laneX1 = 126, 160
	D.sackX0, D.sackX1 = laneX0, laneX1
	for l = 1, 4 do
		local z = 50 + (l - 1) * 6
		deco(pg, "LaneLine", Vector3.new(laneX1 - laneX0, 0.06, 0.25), CFrame.new((laneX0 + laneX1) / 2, FLOOR + 0.03, z + 3), WHITE)
		local pad = part(pg, "StartPad", Vector3.new(3, 0.2, 4.6), CFrame.new(laneX0 - 3, FLOOR + 0.1, z), FLAG[l + 1] or GOLD, Enum.Material.Neon, { CanCollide = false })
		local lb = Instance.new("BillboardGui") lb.Size = UDim2.fromOffset(90, 26) lb.StudsOffset = Vector3.new(0, 3, 0) lb.MaxDistance = 60 lb.Parent = pad
		local lt = Instance.new("TextLabel") lt.Size = UDim2.fromScale(1, 1) lt.BackgroundTransparency = 1 lt.Font = Enum.Font.GothamBold lt.TextScaled = true lt.TextColor3 = WHITE lt.TextStrokeTransparency = 0.3 lt.Text = "LANE " .. l lt.Parent = lb
		local pp = prompt(pad, "Join sack race", "🥔 Lane " .. l, 8)
		D.lanes[l] = { z = z, pad = pad, prompt = pp, label = lt }
		ctx:Connect(pp.Triggered, function(player) M.joinSack(ctx, player, l) end)
	end
	deco(pg, "LaneLine", Vector3.new(laneX1 - laneX0, 0.06, 0.25), CFrame.new((laneX0 + laneX1) / 2, FLOOR + 0.03, 47), WHITE)
	local finish = part(pg, "FinishLine", Vector3.new(1, 6, 24), CFrame.new(laneX1, FLOOR + 3, 59), Color3.new(1, 1, 1), nil, { Transparency = 0.6, CanCollide = false })
	local fsign = deco(pg, "FinishBanner", Vector3.new(0.3, 2, 24), CFrame.new(laneX1, FLOOR + 7.5, 59), DARK)
	sign(fsign, Enum.NormalId.Left, "🏁 FINISH 🏁", DARK, WHITE) sign(fsign, Enum.NormalId.Right, "🏁 FINISH 🏁", DARK, WHITE)
	D.sackGate = part(pg, "StartGate", Vector3.new(0.5, 6, 24), CFrame.new(laneX0, FLOOR + 3, 59), Color3.fromRGB(240, 200, 60), Enum.Material.ForceField, { CanCollide = true, Transparency = 0.6 })
	D.sack = { state = "idle", racers = {}, places = {} }
	ctx:Connect(finish.Touched, function(hit)
		local mdl = hit:FindFirstAncestorOfClass("Model")
		local pl = mdl and Players:GetPlayerFromCharacter(mdl)
		if pl then M.sackFinish(ctx, pl) end
	end)

	---------------------------------------------------------------- REGISTRATION desk (pageant)
	local desk = Instance.new("Model") desk.Name = "PageantDesk" desk.Parent = folder
	local dC = Vector3.new(224, FLOOR, 8)
	part(desk, "Desk", Vector3.new(3, 3, 7), CFrame.new(dC + Vector3.new(0, 1.5, 0)), WHITE, Enum.Material.Wood)
	deco(desk, "DeskSkirt", Vector3.new(0.1, 2.6, 7), CFrame.new(dC + Vector3.new(-1.55, 1.5, 0)), Color3.fromRGB(170, 20, 40), Enum.Material.Fabric)
	for i = 0, 3 do deco(desk, "SashOnDesk", Vector3.new(1.6, 0.1, 0.5), CFrame.new(dC + Vector3.new(0, 3.06, -2.4 + i * 1.6)), WHITE, Enum.Material.Fabric) end
	local dsign = deco(desk, "DeskSign", Vector3.new(0.2, 2, 7), CFrame.new(dC + Vector3.new(0.6, 5.2, 0)), Color3.fromRGB(170, 20, 40))
	sign(dsign, Enum.NormalId.Left, "👑 MR. & MS. SAMAR COLLEGE • REGISTRATION", Color3.fromRGB(170, 20, 40), GOLD)
	local dAnchor = deco(desk, "PromptAnchor", Vector3.new(1, 1, 1), CFrame.new(dC + Vector3.new(-2, 3, 0)), Color3.new(1, 1, 1), nil, { Transparency = 1 })
	local dpp = prompt(dAnchor, "Join the pageant", "👑 Registration", 10)
	ctx:Connect(dpp.Triggered, function(player)
		if not ensureJoined(ctx, player) then return end
		if not D.registrationOpen then return ctx:Toast(player, "👑 Registration is closed — the official candidates were already presented.") end
		ctx:Send(player, { type = "openRegister" })
	end)

	---------------------------------------------------------------- location
	ctx:SetLocation(Vector3.new(190, FLOOR, STAGE_Z - 14), "Quadrangle • Founding Anniversary")
	ctx.GotoPosition = Vector3.new(186, FLOOR + 3, STAGE_Z - 4)
	ctx.ScoreLabel = "Celebration points 🎉"
	ctx.JoinMode = "button"
end

---------------------------------------------------------------- PAGEANT
local function candOf(ctx, player) return ctx.Data.candByPlayer[player] end
function M.register(ctx, player, title)
	local D = ctx.Data
	if title ~= "Mr" and title ~= "Ms" then return { ok = false } end
	if not D.registrationOpen then return { ok = false, msg = "Registration is closed" } end
	if candOf(ctx, player) then return { ok = false, msg = "You are already candidate #" .. candOf(ctx, player).number } end
	local list = D.cands[title]
	if #list >= D.cfg.MaxCandidates then return { ok = false, msg = "All " .. D.cfg.MaxCandidates .. " " .. title .. ". slots are taken" } end
	if not ensureJoined(ctx, player) then return { ok = false, msg = "Join the event first" } end
	local c = { player = player, title = title, number = #list + 1 }
	table.insert(list, c)
	D.candByPlayer[player] = c
	setSash(player, (title == "Mr" and "MR." or "MS.") .. " CANDIDATE #" .. c.number)
	ctx:AddScore(player, D.cfg.Points.Candidate)
	ctx:ToastAll(("👑 %s is %s. candidate #%d!"):format(player.DisplayName, title, c.number))
	pushState(ctx)
	return { ok = true, msg = ("You are %s. Samar College candidate #%d! 🎗️"):format(title, c.number) }
end
local function allCands(ctx)
	local out = {}
	for _, t in ipairs({ "Mr", "Ms" }) do for _, c in ipairs(ctx.Data.cands[t]) do if c.player.Parent then table.insert(out, c) end end end
	return out
end
local function bringToStage(ctx)
	local list = allCands(ctx)
	for i, c in ipairs(list) do
		local char = c.player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local z = STAGE_Z - (#list - 1) * 2.4 + (i - 1) * 4.8
			char:PivotTo(CFrame.lookAt(Vector3.new(STAGE_FRONT + 8, STAGE_TOP + 3, z), Vector3.new(STAGE_FRONT - 10, STAGE_TOP + 3, z)))
			setSash(c.player, (c.title == "Mr" and "MR." or "MS.") .. " CANDIDATE #" .. c.number)
		end
	end
end
local function onStage(player)
	local r = rootOf(player)
	if not r then return false end
	local p = r.Position
	return p.Y > STAGE_TOP + 0.5 and ((p.X > STAGE_FRONT - 1 and p.X < STAGE_FRONT + 16 and math.abs(p.Z - STAGE_Z) < 22) or (p.X > RUNWAY_X0 and p.X < STAGE_FRONT and math.abs(p.Z - STAGE_Z) < 4))
end
local function nearStage(player)
	local r = rootOf(player)
	return r and r.Position.X > 150 and r.Position.X < STAGE_FRONT + 16 and r.Position.Z > -10 and r.Position.Z < 95
end
local function tally(ctx, votes, list)
	local count = {}
	for _, target in pairs(votes) do count[target] = (count[target] or 0) + 1 end
	local ranked = {}
	for _, c in ipairs(list) do if c.player.Parent then table.insert(ranked, { c = c, v = count[c.player.UserId] or 0, t = 0 }) end end
	local tCount = {}
	for _, target in pairs(ctx.Data.talentVotes) do tCount[target] = (tCount[target] or 0) + 1 end
	for _, r in ipairs(ranked) do r.t = tCount[r.c.player.UserId] or 0 end
	table.sort(ranked, function(a, b)
		if a.v ~= b.v then return a.v > b.v end
		if a.t ~= b.t then return a.t > b.t end
		return a.c.number < b.c.number
	end)
	return ranked
end
function M.vote(ctx, player, kind, targetId, title)
	local D = ctx.Data
	if not ensureJoined(ctx, player) then return { ok = false } end
	if type(targetId) ~= "number" then return { ok = false } end
	local target
	for _, c in ipairs(allCands(ctx)) do if c.player.UserId == targetId then target = c end end
	if not target then return { ok = false, msg = "That candidate is not here" } end
	if target.player == player then return { ok = false, msg = "You can't vote for yourself 😉" } end
	if kind == "talent" then
		if not D.votingTalent then return { ok = false, msg = "Talent voting is closed" } end
		local first = D.talentVotes[player] == nil
		D.talentVotes[player] = targetId
		if first then ctx:AddScore(player, D.cfg.Points.Vote) end
		return { ok = true, msg = "🗳️ Best in Talent vote: " .. target.player.DisplayName }
	elseif kind == "crown" then
		if not D.votingCrown then return { ok = false, msg = "Coronation voting is closed" } end
		if target.title ~= title then return { ok = false } end
		local first = D.crownVotes[title][player] == nil
		D.crownVotes[title][player] = targetId
		if first then ctx:AddScore(player, D.cfg.Points.Vote) end
		return { ok = true, msg = ("🗳️ %s. Samar College vote: %s"):format(title, target.player.DisplayName) }
	end
	return { ok = false }
end
local function crowning(ctx)
	local D = ctx.Data
	local P = D.cfg.Points
	local results = {}
	for _, title in ipairs({ "Mr", "Ms" }) do
		local ranked = tally(ctx, D.crownVotes[title], D.cands[title])
		local entry = { title = title, places = {} }
		for i = math.min(3, #ranked), 1, -1 do
			local r = ranked[i]
			local name = r.c.player.DisplayName
			table.insert(entry.places, { place = i, userId = r.c.player.UserId, name = name, votes = r.v, number = r.c.number })
		end
		results[title] = entry
	end
	ctx:Broadcast({ type = "coronation", results = results })
	-- reveal order (client shows the same order): 2nd runner-up → 1st runner-up → winner for each title
	task.spawn(function()
		for _, title in ipairs({ "Ms", "Mr" }) do
			local entry = results[title]
			for _, pl in ipairs(entry.places) do
				if ctx.Phase ~= "Active" then return end
				task.wait(4)
				local player = Players:GetPlayerByUserId(pl.userId)
				if player then
					if pl.place == 1 then
						giveCrown(player)
						setSash(player, (title == "Mr" and "MR." or "MS.") .. " SAMAR COLLEGE 2026", true)
						ctx:AddScore(player, P.Crown)
						D.crowned = D.crowned or {}
						D.crowned[player] = true
						ctx:ToastAll(("👑 %s. SAMAR COLLEGE 2026: %s!"):format(title, player.DisplayName))
						local r = rootOf(player)
						if r then
							D.followTarget = player
							for _ = 1, 3 do local fx = Instance.new("Sparkles") fx.SparkleColor = GOLD fx.Parent = r Debris:AddItem(fx, 10) end
						end
					else
						setSash(player, (pl.place == 2 and "1st" or "2nd") .. " RUNNER-UP", false)
						ctx:AddScore(player, pl.place == 2 and P.FirstRunner or P.SecondRunner)
						ctx:ToastAll(("🎗️ %s. %s runner-up: %s"):format(title, pl.place == 2 and "1st" or "2nd", player.DisplayName))
					end
				end
			end
		end
	end)
end

---------------------------------------------------------------- PARLOR GAMES logic
local function spawnPrizes(ctx)
	local D = ctx.Data
	for _, p in ipairs(D.prizes) do if p.Parent then p:Destroy() end end
	D.prizes = {}
	local base = D.lattice.PrimaryPart
	for gx = -1, 2 do
		for gz = -1, 2 do
			local off = CFrame.new(-4.5 + (gx + 1) * 3, -2.8, -4.5 + (gz + 1) * 3)
			local prize = Instance.new("Part") prize.Name = "Prize" prize.Size = Vector3.new(1.2, 1.2, 1.2)
			prize.Color = FLAG[math.random(#FLAG)] prize.Material = Enum.Material.Foil prize.Anchored = true prize.CanCollide = false
			prize.CFrame = base.CFrame * off prize:SetAttribute("Off", off) prize.Parent = D.lattice
			local str = Instance.new("Part") str.Name = "PrizeString" str.Size = Vector3.new(0.06, 2.2, 0.06) str.Anchored = true str.CanCollide = false str.CanQuery = false str.CanTouch = false
			str.Color = Color3.fromRGB(230, 220, 200) str.CFrame = base.CFrame * off * CFrame.new(0, 1.7, 0) str:SetAttribute("Off", off * CFrame.new(0, 1.7, 0)) str.Parent = D.lattice
			prize:SetAttribute("String", true)
			table.insert(D.prizes, prize)
			local conn
			conn = prize.Touched:Connect(function(hit)
				if not D.pabitinLow then return end
				local mdl = hit:FindFirstAncestorOfClass("Model")
				local pl = mdl and Players:GetPlayerFromCharacter(mdl)
				if not pl or not prize.Parent or not ensureJoined(ctx, pl) then return end
				conn:Disconnect()
				prize:Destroy() str:Destroy()
				ctx:AddScore(pl, D.cfg.Points.Pabitin)
				ctx:Toast(pl, ("🎁 You grabbed a pabitin prize! +%d"):format(D.cfg.Points.Pabitin))
			end)
			table.insert(ctx.Connections, conn)
		end
	end
end
local function moveLattice(ctx, y)
	local D = ctx.Data
	local base = D.lattice.PrimaryPart
	local target = CFrame.new(D.pabC + Vector3.new(0, y, 0))
	for i = 1, 20 do
		if not base.Parent then return end
		local cf = base.CFrame:Lerp(target, i / 20)
		base.CFrame = cf
		for _, p in ipairs(D.lattice:GetChildren()) do
			if p ~= base and p:IsA("BasePart") then
				local off = p:GetAttribute("Off")
				if off then p.CFrame = cf * off end
			end
		end
		task.wait(0.05)
	end
end
-- slats and ropes keep their offsets too
local function rememberLattice(ctx)
	local base = ctx.Data.lattice.PrimaryPart
	for _, p in ipairs(ctx.Data.lattice:GetChildren()) do
		if p ~= base and p:IsA("BasePart") and not p:GetAttribute("Off") then p:SetAttribute("Off", base.CFrame:ToObjectSpace(p.CFrame)) end
	end
end
local function runPabitin(ctx, rounds)
	local D = ctx.Data
	rememberLattice(ctx)
	for r = 1, rounds do
		if ctx.Phase ~= "Active" then return end
		spawnPrizes(ctx)
		ctx:Broadcast({ type = "game", text = ("🎁 PABITIN round %d/%d — gather under the frame!"):format(r, rounds) })
		task.wait(3)
		for drop = 1, 3 do
			moveLattice(ctx, 9.6)
			D.pabitinLow = true
			ctx:Broadcast({ type = "game", text = "⬇️ JUMP! Grab the prizes!" })
			task.wait(3.5)
			D.pabitinLow = false
			moveLattice(ctx, 16)
			task.wait(1.5)
		end
	end
	ctx:Broadcast({ type = "game", text = "" })
end
function M.joinSack(ctx, player, lane)
	local D = ctx.Data
	local s = D.sack
	if s.state ~= "open" then return ctx:Toast(player, "🥔 The sack race opens during the Parlor Games!") end
	if not ensureJoined(ctx, player) then return end
	for _, r in pairs(s.racers) do if r.player == player then return ctx:Toast(player, "🥔 You are already in a lane") end end
	if s.racers[lane] then return ctx:Toast(player, "🥔 That lane is taken — pick another one") end
	s.racers[lane] = { player = player }
	D.lanes[lane].label.Text = player.DisplayName
	ctx:Toast(player, ("🥔 You're in lane %d! Hop to the finish when it says GO."):format(lane))
	ctx:AddScore(player, D.cfg.Points.SackJoin)
	-- put on the sack
	local char = player.Character
	local lower = char and (char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso"))
	if lower and not char:FindFirstChild("FD_Sack") then
		local sack = attachTo(char, lower, "FD_Sack", Vector3.new(2.4, 3.2, 1.6), CFrame.new(0, -1.4, 0), Color3.fromRGB(170, 140, 90), Enum.Material.Fabric)
		local sg = Instance.new("SurfaceGui") sg.Face = Enum.NormalId.Front sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud sg.PixelsPerStud = 40 sg.Parent = sack
		local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 0.4) t.Position = UDim2.fromScale(0, 0.1) t.BackgroundTransparency = 1 t.TextScaled = true t.Font = Enum.Font.GothamBlack t.TextColor3 = Color3.fromRGB(110, 70, 30) t.Text = "SC " .. lane t.Parent = sg
	end
	local r = rootOf(player)
	if r then char:PivotTo(CFrame.lookAt(Vector3.new(D.sackX0 - 3, FLOOR + 3, D.lanes[lane].z), Vector3.new(D.sackX1, FLOOR + 3, D.lanes[lane].z))) end
end
local function setRacerSpeed(player, on)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if on then
		if not hum:GetAttribute("FD_PrevSpeed") then hum:SetAttribute("FD_PrevSpeed", hum.WalkSpeed) hum:SetAttribute("FD_PrevJump", hum.UseJumpPower and hum.JumpPower or hum.JumpHeight) end
		hum.WalkSpeed = 10
		if hum.UseJumpPower then hum.JumpPower = 35 else hum.JumpHeight = 3.5 end
	else
		local ws, jp = hum:GetAttribute("FD_PrevSpeed"), hum:GetAttribute("FD_PrevJump")
		if ws then hum.WalkSpeed = ws end
		if jp then if hum.UseJumpPower then hum.JumpPower = jp else hum.JumpHeight = jp end end
		hum:SetAttribute("FD_PrevSpeed", nil) hum:SetAttribute("FD_PrevJump", nil)
	end
end
function M.sackFinish(ctx, player)
	local s = ctx.Data.sack
	if s.state ~= "running" then return end
	local mine
	for _, r in pairs(s.racers) do if r.player == player then mine = r end end
	if not mine or mine.done then return end
	mine.done = true
	table.insert(s.places, player)
	local place = #s.places
	local pts = ctx.Data.cfg.Points.SackPlaces[place]
	if pts then ctx:AddScore(player, pts) end
	ctx:ToastAll(("🏁 %s finished the sack race #%d%s"):format(player.DisplayName, place, pts and (" (+" .. pts .. ")") or ""))
	setRacerSpeed(player, false)
	local sack = player.Character and player.Character:FindFirstChild("FD_Sack") if sack then sack:Destroy() end
end
local function runSackHeat(ctx, heat)
	local D = ctx.Data
	local s = D.sack
	s.state = "open" s.racers = {} s.places = {}
	for l, lane in ipairs(D.lanes) do lane.label.Text = "LANE " .. l end
	D.sackGate.CanCollide = true D.sackGate.Transparency = 0.6
	ctx:Broadcast({ type = "game", text = ("🥔 SACK RACE heat %d — press E on a lane pad to join! (15 s)"):format(heat) })
	for i = 15, 1, -1 do
		if ctx.Phase ~= "Active" then return end
		task.wait(1)
	end
	local count = 0 for _ in pairs(s.racers) do count += 1 end
	if count == 0 then
		ctx:Broadcast({ type = "game", text = "🥔 No racers this heat…" }) s.state = "idle" task.wait(2) return
	end
	s.state = "ready"
	for l, r in pairs(s.racers) do
		if r.player.Parent then
			setRacerSpeed(r.player, true)
			local char = r.player.Character
			if char then char:PivotTo(CFrame.lookAt(Vector3.new(D.sackX0 - 3, FLOOR + 3, D.lanes[l].z), Vector3.new(D.sackX1, FLOOR + 3, D.lanes[l].z))) end
		end
	end
	for n = 3, 1, -1 do ctx:Broadcast({ type = "countdown", text = tostring(n) }) task.wait(1) end
	ctx:Broadcast({ type = "countdown", text = "GO! 🥔" })
	D.sackGate.CanCollide = false D.sackGate.Transparency = 1
	s.state = "running"
	local t0 = os.clock()
	while os.clock() - t0 < 30 and ctx.Phase == "Active" do
		local left = 0 for _, r in pairs(s.racers) do if not r.done and r.player.Parent then left += 1 end end
		if left == 0 then break end
		task.wait(0.5)
	end
	s.state = "idle"
	for _, r in pairs(s.racers) do
		if r.player.Parent then
			setRacerSpeed(r.player, false)
			local sack = r.player.Character and r.player.Character:FindFirstChild("FD_Sack") if sack then sack:Destroy() end
		end
	end
	D.sackGate.CanCollide = true D.sackGate.Transparency = 0.6
	task.wait(2)
end

---------------------------------------------------------------- GUEST PERFORMERS
local DANCES = {}
local function loadDances()
	if #DANCES > 0 then return end
	local ok, Emotes = pcall(function() return require(RS:WaitForChild("TalentShow"):WaitForChild("Emotes")) end)
	if ok and Emotes and Emotes.List then
		for _, e in ipairs(Emotes.List) do if e.cat == "Dance" and e.anim then table.insert(DANCES, e.anim) end end
	end
end
local function startGuestShow(ctx)
	local D = ctx.Data
	loadDances()
	D.dancers = {}
	local troupe = Instance.new("Model") troupe.Name = "GuestPerformers" troupe.Parent = ctx.Folder
	local palette = {
		{ skin = Color3.fromRGB(198, 145, 105), top = Color3.fromRGB(200, 40, 60), bottom = Color3.fromRGB(240, 240, 240), costume = Color3.fromRGB(220, 50, 70), accent = GOLD },
		{ skin = Color3.fromRGB(176, 124, 88), top = Color3.fromRGB(240, 240, 240), bottom = Color3.fromRGB(30, 90, 170), costume = Color3.fromRGB(40, 100, 190), accent = Color3.fromRGB(240, 60, 60) },
		{ skin = Color3.fromRGB(210, 160, 120), top = Color3.fromRGB(245, 200, 60), bottom = Color3.fromRGB(30, 110, 60), costume = Color3.fromRGB(30, 120, 60), accent = WHITE },
		{ skin = Color3.fromRGB(160, 110, 75), top = Color3.fromRGB(150, 60, 190), bottom = Color3.fromRGB(240, 240, 240), costume = Color3.fromRGB(160, 70, 200), accent = GOLD },
		{ skin = Color3.fromRGB(190, 140, 100), top = Color3.fromRGB(240, 120, 40), bottom = Color3.fromRGB(40, 40, 50), costume = Color3.fromRGB(240, 130, 40), accent = WHITE },
	}
	for i = 1, 5 do
		local z = STAGE_Z - 12 + (i - 1) * 6
		local cf = CFrame.lookAt(Vector3.new(STAGE_FRONT + 7, STAGE_TOP + 3, z), Vector3.new(STAGE_FRONT - 20, STAGE_TOP + 3, z))
		local rig = spawnDancer(troupe, cf, palette[i], "🎭 Guest Performer")
		if rig then table.insert(D.dancers, rig) end
	end
	task.spawn(function()
		local idx = 1
		while ctx.Phase == "Active" and D.dancers and #D.dancers > 0 and segOf(ctx) and segOf(ctx).Id == "GuestShow" do
			local anim = DANCES[(idx - 1) % math.max(#DANCES, 1) + 1]
			if anim then for _, rig in ipairs(D.dancers) do playDance(rig, anim) end end
			idx += 1
			task.wait(10)
		end
	end)
end
local function endGuestShow(ctx)
	local troupe = ctx.Folder and ctx.Folder:FindFirstChild("GuestPerformers")
	if troupe then troupe:Destroy() end
	ctx.Data.dancers = nil
end

---------------------------------------------------------------- PROGRAM segments
local function setScreen(ctx, now, sub)
	local D = ctx.Data
	if D.screenNow then D.screenNow.Text = now end
	if D.screenSub then D.screenSub.Text = sub or "" end
end
local function placeFloats(ctx, hidden)
	local D = ctx.Data
	for _, fl in ipairs(D.floats) do
		if hidden then fl.model:PivotTo(CFrame.new(ROUTE[1] + Vector3.new(0, -40, 0))) fl.confetti.Enabled = false end
	end
end
local function routePoint(d)
	local total = 0
	for i = 1, #ROUTE do
		local a, b = ROUTE[i], ROUTE[i % #ROUTE + 1]
		local len = (b - a).Magnitude
		if d <= total + len then local t = (d - total) / len return a:Lerp(b, t), (b - a).Unit end
		total += len
	end
	return ROUTE[1], (ROUTE[2] - ROUTE[1]).Unit
end
local function enterSegment(ctx, i)
	local D = ctx.Data
	local prev = D.program[D.seg]
	D.seg = i
	local s = D.program[i]
	D.segEndsAt = os.time() + s.Time
	-- leaving the previous segment
	if prev then
		if prev.Id == "Opening" then
			-- the committee finishes any decoration nobody hung
			for k, spot in ipairs(DECO_SPOTS) do
				if not D.decoDone[k] then
					D.decoDone[k] = true
					local pr = D.decoPrompts[k] if pr and pr.box.Parent then pr.box:Destroy() end
					buildDecoration(ctx.Folder:FindFirstChild("CommitteeDecorations"), spot)
				end
			end
		elseif prev.Id == "Parade" then placeFloats(ctx, true)
		elseif prev.Id == "Talent" then D.votingTalent = false
		elseif prev.Id == "GuestShow" then endGuestShow(ctx)
		elseif prev.Id == "SCTalents" then
			local best, bestN = nil, 0
			for p, n in pairs(D.cheers) do if p.Parent and n > bestN then best, bestN = p, n end end
			if best then ctx:AddScore(best, D.cfg.Points.CheerTop) ctx:ToastAll(("🌟 Crowd favorite performer: %s (%d cheers) +%d"):format(best.DisplayName, bestN, D.cfg.Points.CheerTop)) end
		end
	end
	ctx:Broadcast({ type = "segment", seg = i, endsAt = D.segEndsAt })
	ctx:ToastAll(s.Icon .. " NOW: " .. s.Name)
	setScreen(ctx, s.Icon .. " " .. s.Name:upper(), s.Desc)
	D.followTarget = nil
	if D.followLight then D.followLight.Enabled = false end
	-- entering
	if s.Id == "Parade" then
		D.paradeDist = 0
		for _, fl in ipairs(D.floats) do fl.confetti.Enabled = true end
	elseif s.Id == "Presentation" then
		D.registrationOpen = false
		local list = allCands(ctx)
		if #list == 0 then
			setScreen(ctx, "🎗️ PRESENTATION OF CANDIDATES", "No candidates registered this year — the program moves on to the cultural acts!")
		else
			bringToStage(ctx)
			task.spawn(function()
				local per = math.clamp((s.Time - 8) / #list, 5, 12)
				for _, c in ipairs(list) do
					if ctx.Phase ~= "Active" or D.seg ~= i then return end
					if c.player.Parent then
						D.followTarget = c.player
						if D.followLight then D.followLight.Enabled = true end
						setScreen(ctx, ("🎗️ %s. CANDIDATE #%d"):format(c.title, c.number), c.player.DisplayName .. " — please walk the runway!")
						ctx:Broadcast({ type = "spotlight", userId = c.player.UserId, name = c.player.DisplayName, title = c.title, number = c.number })
						ctx:AddScore(c.player, D.cfg.Points.Runway)
					end
					task.wait(per)
				end
			end)
		end
	elseif s.Id == "Talent" then
		if #allCands(ctx) > 0 then D.votingTalent = true bringToStage(ctx) end
	elseif s.Id == "Coronation" then
		if #allCands(ctx) > 0 then
			D.votingCrown = true
			bringToStage(ctx)
			task.delay(math.max(10, s.Time - 34), function()
				if ctx.Phase ~= "Active" or D.seg ~= i then return end
				D.votingCrown = false
				pushState(ctx)
				-- Best in Talent first
				local ranked = tally(ctx, D.talentVotes, allCands(ctx))
				local top = ranked[1]
				if top and top.t > 0 and top.c.player.Parent then
					ctx:AddScore(top.c.player, D.cfg.Points.BestTalent)
					ctx:ToastAll(("🎤 BEST IN TALENT: %s (%d votes)"):format(top.c.player.DisplayName, top.t))
				end
				setScreen(ctx, "👑 AND THE NEW MR. & MS. SAMAR COLLEGE ARE…", "")
				crowning(ctx)
			end)
		else
			setScreen(ctx, "👑 CORONATION NIGHT", "No candidates this year — stay for the cultural show!")
		end
	elseif s.Id == "GuestShow" then startGuestShow(ctx)
	elseif s.Id == "SCTalents" then D.cheers = {}
	elseif s.Id == "ParlorGames" then
		task.spawn(function()
			runPabitin(ctx, 2)
			local heat = 1
			while ctx.Phase == "Active" and D.seg == i and os.time() < D.segEndsAt - 20 do
				runSackHeat(ctx, heat) heat += 1
			end
			D.sack.state = "idle"
		end)
	elseif s.Id == "Closing" then
		setScreen(ctx, "🎆 THANK YOU, SAMARCOLLEGIANS!", "Happy Founding Anniversary, Samar College!")
	end
	pushState(ctx)
end

---------------------------------------------------------------- START
function M.Start(ctx)
	local D = ctx.Data
	local cfg = D.cfg
	ctx:Broadcast({ type = "program", program = cfg.Program, allDay = cfg.AllDay, pageant = cfg.Pageant, pageantSub = cfg.PageantSub })
	enterSegment(ctx, 1)
	local droneA = 0
	ctx:Connect(RunService.Heartbeat, function(dt)
		-- parade floats
		local s = segOf(ctx)
		if s and s.Id == "Parade" then
			D.paradeDist = (D.paradeDist + dt * 6) % D.routeLen
			for _, fl in ipairs(D.floats) do
				local pos, dir = routePoint((D.paradeDist + fl.offset) % D.routeLen)
				fl.model:PivotTo(CFrame.lookAt(pos + Vector3.new(0, 2.8, 0), pos + Vector3.new(0, 2.8, 0) + dir) * CFrame.new(0, math.sin(os.clock() * 3 + fl.offset) * 0.08, 0))
			end
		end
		-- stage moving heads sweep
		local t = os.clock()
		for _, l in ipairs(D.lights) do
			l.part.CFrame = l.base * CFrame.Angles(math.sin(t * 0.9 + l.k) * 0.6, 0, math.cos(t * 0.7 + l.k * 1.3) * 0.6)
		end
		-- follow spotlight aims at the current star
		local target = D.followTarget and rootOf(D.followTarget)
		if target and D.follow then D.follow.CFrame = CFrame.lookAt(D.follow.Position, target.Position) end
		-- press drone (Media Coverage) circles the quadrangle
		droneA += dt * 0.25
		if D.drone and D.drone.PrimaryPart then
			local c = Vector3.new(185 + math.cos(droneA) * 45, 30 + math.sin(droneA * 2) * 3, STAGE_Z + math.sin(droneA) * 40)
			D.drone:PivotTo(CFrame.lookAt(c, D.stageC + Vector3.new(0, 4, 0)))
		end
	end)
	-- program clock + periodic points
	task.spawn(function()
		local tick = 0
		local fireworks = false
		while ctx.Phase == "Active" do
			if os.time() >= D.segEndsAt and D.seg < #D.program then enterSegment(ctx, D.seg + 1) end
			tick += 1
			local s = segOf(ctx)
			if tick % 5 == 0 and s then
				for p in pairs(ctx.Participants) do
					local r = rootOf(p)
					if r then
						if s.Id == "Parade" then
							for _, fl in ipairs(D.floats) do
								if (r.Position - fl.model:GetPivot().Position).Magnitude < 16 then ctx:AddScore(p, cfg.Points.ParadeTick) break end
							end
						elseif s.Id == "Presentation" or s.Id == "Talent" or s.Id == "Coronation" or s.Id == "GuestShow" or s.Id == "SCTalents" or s.Id == "Closing" then
							if onStage(p) and (s.Id == "SCTalents" or (s.Id == "Talent" and candOf(ctx, p))) then
								ctx:AddScore(p, cfg.Points.PerformTick)
							elseif nearStage(p) then ctx:AddScore(p, cfg.Points.WatchTick) end
						end
					end
				end
			end
			if ctx:TimeLeft() <= cfg.FireworksAt then
				if not fireworks then fireworks = true ctx:ToastAll("🎆 FIREWORKS FINALE! Look up!") ctx:Broadcast({ type = "fireworks" }) end
				firework(ctx, D.center)
				if math.random() < 0.6 then firework(ctx, D.center) end
			end
			task.wait(1)
		end
	end)
end

---------------------------------------------------------------- client requests
function M.OnAction(ctx, player, action, data)
	local D = ctx.Data
	data = type(data) == "table" and data or {}
	if action == "fd_state" then
		return { ok = true, state = state(ctx), program = D.cfg.Program, allDay = D.cfg.AllDay, pageant = D.cfg.Pageant, pageantSub = D.cfg.PageantSub }
	elseif action == "fd_register" then
		return M.register(ctx, player, data.title)
	elseif action == "fd_vote" then
		return M.vote(ctx, player, data.kind, data.target, data.title)
	elseif action == "fd_cheer" then
		local s = segOf(ctx)
		if not (s and s.Id == "SCTalents") then return { ok = false, msg = "Cheering is for the SC Talents show" } end
		if not ensureJoined(ctx, player) then return { ok = false } end
		D.lastCheer = D.lastCheer or {}
		if (D.lastCheer[player] or 0) > os.clock() then return { ok = false } end
		D.lastCheer[player] = os.clock() + 1.5
		-- cheer goes to everyone performing on stage right now
		local any = false
		for p in pairs(ctx.Participants) do
			if p ~= player and onStage(p) then D.cheers[p] = (D.cheers[p] or 0) + 1 any = true end
		end
		ctx:Broadcast({ type = "cheer", name = player.DisplayName })
		return { ok = true, msg = any and "👏 Cheered!" or "👏 Nobody is on stage yet — go up and perform!" }
	end
	return { ok = false }
end

---------------------------------------------------------------- FINISH / CLEANUP
function M.Finish(ctx)
	local D = ctx.Data
	ctx.RewardEligible, ctx.AchievementPlayers = {}, {}
	for p in pairs(ctx.Participants) do
		ctx.RewardEligible[p] = true
		if (ctx.Scores[p] or 0) > 0 then ctx.AchievementPlayers[p] = true end
	end
	-- crowned Mr. & Ms. get their own achievement
	local ok, Rewards = pcall(function() return require(game:GetService("ServerScriptService").Events.EventRewards) end)
	if ok and Rewards and D.crowned then
		for p in pairs(D.crowned) do if p.Parent then pcall(Rewards.grantAchievement, p, "Kaanyag") end end
	end
	ctx.WinnerText = ("🎉 Happy Founding Anniversary! %d/%d decorations hung."):format(D.decorated or 0, #DECO_SPOTS)
	ctx:Broadcast({ type = "hide" })
end
function M.Cleanup(ctx)
	local D = ctx.Data
	for _, p in ipairs(Players:GetPlayers()) do
		clearRegalia(p, D.crowned and D.crowned[p]) -- winners keep their crown until they respawn
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum:GetAttribute("FD_PrevSpeed") then setRacerSpeed(p, false) end
	end
end

return M
