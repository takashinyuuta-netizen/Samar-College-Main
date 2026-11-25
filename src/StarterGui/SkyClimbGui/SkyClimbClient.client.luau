--[[ SkyClimbClient — HUD for "PATAAS! Parkour"
  • Top card: mode, live timer, current zone, checkpoints / falls
  • Right side: height meter with the 6 zones and your position
  • Buttons: pick Easy/Hard (on the island) · checkpoint · restart · leave · back to campus
  • Pop-ups: checkpoint saved, new zone, fell, and the summit card with time + rewards
  Places itself around the HUD (rail, event banner, coins, music, hotbar, jump button). ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = script.Parent
local Remote = RS:WaitForChild("SkyClimb"):WaitForChild("Remote")

local GREEN, GOLD, BG, CARD, TEXT, DIM = Color3.fromRGB(30, 110, 60), Color3.fromRGB(245, 200, 60), Color3.fromRGB(18, 22, 28), Color3.fromRGB(30, 36, 44), Color3.fromRGB(240, 242, 245), Color3.fromRGB(150, 160, 170)
local EASY, HARD = Color3.fromRGB(60, 190, 90), Color3.fromRGB(220, 60, 60)
local ZONES = {
	{ name = "KALYE SAN ROQUE", sub = "Street", color = Color3.fromRGB(240, 170, 60) },
	{ name = "SILID-ARALAN", sub = "Classroom", color = Color3.fromRGB(80, 160, 230) },
	{ name = "AKLATAN & COMPUTER LAB", sub = "Library", color = Color3.fromRGB(150, 100, 210) },
	{ name = "KANTINA", sub = "Canteen", color = Color3.fromRGB(230, 90, 70) },
	{ name = "OPISINA & KLINIKA", sub = "Offices & Clinic", color = Color3.fromRGB(60, 180, 140) },
	{ name = "KAMPUS SA ULAP", sub = "Campus in the Clouds", color = Color3.fromRGB(245, 200, 60) },
}

local function new(cls, props, parent) local o = Instance.new(cls) for k, v in pairs(props or {}) do o[k] = v end o.Parent = parent return o end
local function corner(p, r) return new("UICorner", { CornerRadius = r or UDim.new(0, 12) }, p) end
local function stroke(p, c, t) return new("UIStroke", { Color = c or GOLD, Thickness = t or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
local function label(parent, props)
	local t = new("TextLabel", { BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextColor3 = TEXT, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, parent)
	for k, v in pairs(props) do t[k] = v end return t
end
local function button(parent, text, color, props)
	local b = new("TextButton", { Text = text, BackgroundColor3 = color or GREEN, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 14, AutoButtonColor = true }, parent)
	corner(b, UDim.new(0, 10))
	for k, v in pairs(props or {}) do b[k] = v end return b
end
local function tw(o, t, props) local x = TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props) x:Play() return x end
local function fmt(sec) sec = math.max(0, sec or 0) return ("%d:%05.2f"):format(sec // 60, sec % 60) end

---------------------------------------------------------------- holder that scales with the screen
local root = new("Frame", { Name = "SkyClimbUI", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false }, gui)
local scale = new("UIScale", {}, root)
local eff = 1
local layout
local function rescale()
	local v = gui.AbsoluteSize
	if v.Y < 2 then return end
	eff = math.clamp(math.min(v.X / 1100, v.Y / 640), 0.5, 1)
	scale.Scale = eff
	root.Size = UDim2.fromScale(1 / eff, 1 / eff)
	if layout then layout() end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)

---------------------------------------------------------------- top card
local card = new("Frame", { Name = "ClimbCard", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(470, 70), BackgroundColor3 = BG, BackgroundTransparency = 0.08 }, root)
corner(card, UDim.new(0, 16)) stroke(card, GOLD, 1.6)
local modePill = label(card, { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(96, 24), BackgroundTransparency = 0, BackgroundColor3 = EASY, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextSize = 13, Text = "EASY" })
corner(modePill, UDim.new(1, 0))
local title = label(card, { Position = UDim2.fromOffset(114, 8), Size = UDim2.new(1, -230, 0, 26), Font = Enum.Font.GothamBlack, TextSize = 17, TextColor3 = GOLD, TextTruncate = Enum.TextTruncate.AtEnd, Text = "⛰️ PATAAS! PARKOUR" })
local zoneLbl = label(card, { Position = UDim2.fromOffset(12, 40), Size = UDim2.new(1, -196, 0, 22), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(200, 230, 210), TextTruncate = Enum.TextTruncate.AtEnd, Text = "" })
local timer = label(card, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(120, 32), Font = Enum.Font.GothamBlack, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Right, Text = "0:00.00" })
local info = label(card, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 40), Size = UDim2.fromOffset(176, 22), TextTruncate = Enum.TextTruncate.AtEnd, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Right, Text = "" })

-- buttons under the card
local row = new("Frame", { Name = "ClimbButtons", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 86), Size = UDim2.fromOffset(470, 38), BackgroundTransparency = 1 }, root)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8) }, row)
local bEasy = button(row, "🟢 Start EASY", EASY, { Size = UDim2.fromOffset(140, 36), LayoutOrder = 1 })
local bHard = button(row, "🔴 Start HARD", HARD, { Size = UDim2.fromOffset(140, 36), LayoutOrder = 2 })
local bCampus = button(row, "🏫 Campus", CARD, { Size = UDim2.fromOffset(120, 36), LayoutOrder = 3 })
local bCheck = button(row, "🚩 Checkpoint", Color3.fromRGB(40, 140, 80), { Size = UDim2.fromOffset(130, 36), LayoutOrder = 4 })
local bRestart = button(row, "🔄 Restart", Color3.fromRGB(40, 90, 190), { Size = UDim2.fromOffset(110, 36), LayoutOrder = 5 })
local bLeave = button(row, "🏝️ Quit climb", CARD, { Size = UDim2.fromOffset(130, 36), LayoutOrder = 6 })

---------------------------------------------------------------- minimize / expand (tap-sized for phones)
-- Collapsed = a slim pill with just the mode + live timer; the buttons and height meter hide.
local collapsed = false
local minBtn = button(card, "–", Color3.fromRGB(55, 62, 78), { Name = "Minimize", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 8, 0.5, 0), Size = UDim2.fromOffset(34, 34), TextSize = 20 })
stroke(minBtn, GOLD, 1.2)
local meter -- (made below)
local function applyCollapse()
	title.Visible = not collapsed
	zoneLbl.Visible = not collapsed
	info.Visible = not collapsed
	row.Visible = not collapsed
	if meter then meter.Visible = not collapsed end
	card.Size = collapsed and UDim2.fromOffset(250, 44) or UDim2.fromOffset(470, 70)
	modePill.Position = collapsed and UDim2.fromOffset(10, 10) or UDim2.fromOffset(10, 10)
	timer.Position = collapsed and UDim2.new(1, -12, 0, 6) or UDim2.new(1, -12, 0, 6)
	minBtn.Text = collapsed and "+" or "–"
end
minBtn.Activated:Connect(function() collapsed = not collapsed applyCollapse() end)

---------------------------------------------------------------- height meter (right side)
meter = new("Frame", { Name = "HeightMeter", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 120), Size = UDim2.fromOffset(64, 300), BackgroundTransparency = 1 }, root)
local bar = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0, 10, 1, 0), BackgroundColor3 = Color3.fromRGB(40, 46, 56), BorderSizePixel = 0 }, meter)
corner(bar, UDim.new(1, 0)) stroke(bar, Color3.fromRGB(20, 24, 30), 1.5)
local fill = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), BackgroundColor3 = GOLD, BorderSizePixel = 0 }, bar)
corner(fill, UDim.new(1, 0))
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(245, 200, 60), Color3.fromRGB(60, 190, 90)) }, fill)
label(meter, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 0, -2), Size = UDim2.fromOffset(64, 18), TextSize = 14, Text = "🏆", TextXAlignment = Enum.TextXAlignment.Left })
local me = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 14, 1, 0), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = BG, ZIndex = 3 }, meter)
corner(me, UDim.new(1, 0)) stroke(me, GOLD, 2)
task.spawn(function()
	local ok, img = pcall(function() return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
	if ok then me.Image = img end
end)
local pct = label(meter, { Position = UDim2.new(0, 0, 1, 6), Size = UDim2.fromOffset(64, 18), TextSize = 12, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, Text = "0%" })
local zoneTicks = {}

---------------------------------------------------------------- toasts / pop-ups
local function popup(text, color, dur)
	local t = label(root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(560, 54), BackgroundTransparency = 0.12, BackgroundColor3 = BG,
		TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = color or GOLD, Text = text, ZIndex = 20, TextWrapped = true })
	corner(t, UDim.new(0, 14)) stroke(t, color or GOLD, 2)
	t.Size = UDim2.fromOffset(420, 44) tw(t, 0.2, { Size = UDim2.fromOffset(560, 54) })
	task.delay(dur or 2.4, function() tw(t, 0.35, { TextTransparency = 1, BackgroundTransparency = 1 }) task.wait(0.4) t:Destroy() end)
end

---------------------------------------------------------------- state
local S = { inside = false, running = false, mode = nil, start = 0, cp = 0, falls = 0, baseY = 400, topY = 600, bestEasy = 0, bestHard = 0, checkpoints = 12, zone = 0, finished = nil }
local zoneY = {}
local function readZones()
	local sc = workspace:FindFirstChild("SkyClimb")
	if not sc then return end
	for i = 1, 6 do zoneY[i] = sc:GetAttribute("Zone" .. i .. "Y") end
	for _, t in ipairs(zoneTicks) do t:Destroy() end
	zoneTicks = {}
	for i = 1, 6 do
		if zoneY[i] then
			local f = math.clamp((zoneY[i] - S.baseY) / math.max(1, S.topY - S.baseY), 0, 1)
			local tick = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 22, 1 - f, 0), Size = UDim2.fromOffset(40, 16), BackgroundTransparency = 1 }, meter)
			new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -12, 0.5, 0), Size = UDim2.fromOffset(10, 3), BackgroundColor3 = ZONES[i].color, BorderSizePixel = 0 }, tick)
			label(tick, { Size = UDim2.fromScale(1, 1), TextSize = 11, Font = Enum.Font.GothamBlack, TextColor3 = ZONES[i].color, TextStrokeTransparency = 0.4, Text = "Z" .. i })
			table.insert(zoneTicks, tick)
		end
	end
end
local function currentZone(y)
	local z = 0
	for i = 1, 6 do if zoneY[i] and y >= zoneY[i] - 3 then z = i end end
	return z
end

local function refresh()
	root.Visible = S.inside
	applyCollapse()
	local running = S.running
	bEasy.Visible = S.inside and not running
	bHard.Visible = S.inside and not running
	bCampus.Visible = S.inside and not running
	bCheck.Visible = running
	bCheck.Text = (S.mode == "Easy" and S.cp > 0) and "🚩 Checkpoint" or "⬇️ To start"
	bRestart.Visible = running
	bLeave.Visible = running
	if running then
		modePill.Text = S.mode == "Easy" and "🟢 EASY" or "🔴 HARD"
		modePill.BackgroundColor3 = S.mode == "Easy" and EASY or HARD
		info.Text = S.mode == "Easy" and ("🚩 %d / %d"):format(S.cp, S.checkpoints or 12) or ("💀 Falls: %d"):format(S.falls)
	else
		modePill.Text = "🏝️ ISLAND"
		modePill.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
		info.Text = ("Best E %s / H %s"):format(S.bestEasy > 0 and fmt(S.bestEasy) or "—", S.bestHard > 0 and fmt(S.bestHard) or "—")
		zoneLbl.Text = "Pick 🟢 EASY or 🔴 HARD to start"
		zoneLbl.TextColor3 = Color3.fromRGB(200, 230, 210)
		if not S.finished then timer.Text = "0:00.00" end
	end
	if layout then layout() end
end

---------------------------------------------------------------- layout around the HUD
local pg = player:WaitForChild("PlayerGui")
local function shown(o)
	while o and o:IsA("GuiObject") do if not o.Visible then return false end o = o.Parent end
	return not (o and o:IsA("LayerCollector")) or o.Enabled
end
local function rel(o) return (o.AbsolutePosition - root.AbsolutePosition) / eff, o.AbsoluteSize / eff end
local function obstacles()
	local out = {}
	local function add(g, deep)
		if not (g and g.Enabled) then return end
		for _, c in ipairs(deep and g:GetDescendants() or g:GetChildren()) do
			if c:IsA("GuiObject") and c.AbsoluteSize.X > 10 and c.AbsoluteSize.X < gui.AbsoluteSize.X * 0.6 and shown(c) and (not deep or c:IsA("GuiButton")) then table.insert(out, c) end
		end
	end
	local eg = pg:FindFirstChild("EventGui")
	local banner = eg and eg:FindFirstChild("Banner")
	if banner and shown(banner) then table.insert(out, banner) end
	add(pg:FindFirstChild("MainHUD"), true)
	add(pg:FindFirstChild("CoinsGui"))
	add(pg:FindFirstChild("AdminPanelGui"))
	local mg = pg:FindFirstChild("MusicGui")
	local mini = mg and mg.Enabled and mg:FindFirstChild("Mini")
	if mini and shown(mini) then table.insert(out, mini) end
	return out
end
layout = function()
	local W, H = gui.AbsoluteSize.X / eff, gui.AbsoluteSize.Y / eff
	if W < 10 then return end
	local obs = {}
	for _, o in ipairs(obstacles()) do local p, s = rel(o) table.insert(obs, { p = p, s = s }) end
	local function below(x0, x1, limit)
		local y = 10
		for _, o in ipairs(obs) do if o.p.Y < limit and o.p.X < x1 and o.p.X + o.s.X > x0 then y = math.max(y, o.p.Y + o.s.Y + 8) end end
		return y
	end
	local top = below(W / 2 - 245, W / 2 + 245, H * 0.35)
	card.Position = UDim2.new(0.5, 0, 0, top)
	row.Position = UDim2.new(0.5, 0, 0, top + 78)
	-- meter: right edge, under the top-right items, above the jump button / hotbar
	local mTop = below(W - 90, W, H * 0.4) + 24
	local mBottom = UIS.TouchEnabled and H * 0.6 or H - 150
	meter.Position = UDim2.new(1, -14, 0, mTop)
	meter.Size = UDim2.fromOffset(64, math.max(120, mBottom - mTop))
end

---------------------------------------------------------------- finish card
local function finishCard(d)
	local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(460, 300), BackgroundColor3 = Color3.fromRGB(40, 30, 8), ZIndex = 30 }, root)
	corner(f, UDim.new(0, 20)) stroke(f, GOLD, 3)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(110, 80, 20), Color3.fromRGB(30, 20, 5)) }, f)
	label(f, { Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 34), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextSize = 28, TextColor3 = GOLD, ZIndex = 31, Text = "🏆 YOU REACHED THE TOP!" })
	label(f, { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = d.mode == "Easy" and EASY or HARD, ZIndex = 31, Text = (d.mode == "Easy" and "🟢 EASY MODE" or "🔴 HARD MODE") .. ("  •  falls: %d"):format(d.falls or 0) })
	label(f, { Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 56), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextSize = 50, ZIndex = 31, Text = fmt(d.time) })
	label(f, { Position = UDim2.fromOffset(0, 140), Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = d.newBest and GOLD or DIM, ZIndex = 31,
		Text = d.newBest and "⭐ NEW PERSONAL BEST!" or ("Personal best: " .. fmt(d.best or 0)) })
	local rew = (d.coins or 0) > 0 and ("💰 +%d coins    ⭐ +%d XP"):format(d.coins, d.xp or 0) or "Climb a bit slower to earn rewards 😉"
	label(f, { Position = UDim2.fromOffset(0, 176), Size = UDim2.new(1, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextSize = 20, ZIndex = 31, Text = rew })
	if d.first then label(f, { Position = UDim2.fromOffset(0, 206), Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = GOLD, ZIndex = 31, Text = d.mode == "Easy" and "⛰️ Achievement: Parkour Climber (first climb bonus!)" or "🦅 Achievement: Parkour Legend (first climb bonus!)" }) end
	local ok = button(f, "OK", GREEN, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(160, 40), ZIndex = 31, TextSize = 18 })
	ok.MouseButton1Click:Connect(function() f:Destroy() end)
	for k = 1, 60 do
		local c = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.2), Size = UDim2.fromOffset(8, 12), Rotation = math.random(0, 360), BorderSizePixel = 0, ZIndex = 32,
			BackgroundColor3 = ({ GOLD, Color3.new(1, 1, 1), EASY, HARD, Color3.fromRGB(80, 160, 230) })[k % 5 + 1] }, f)
		local a = math.rad(math.random(0, 360))
		tw(c, 2, { Position = UDim2.new(0.5, math.cos(a) * math.random(120, 320), 0.2, math.sin(a) * 160 + 240), BackgroundTransparency = 1, Rotation = c.Rotation + 400 })
		task.delay(2.1, function() c:Destroy() end)
	end
	f.Size = UDim2.fromOffset(200, 130) tw(f, 0.35, { Size = UDim2.fromOffset(460, 300) })
	task.delay(12, function() if f.Parent then f:Destroy() end end)
end

---------------------------------------------------------------- travel: "Teleport?" dialog + loading screen
local TRAVEL = pg:FindFirstChild("SkyTravelGui")
if TRAVEL then TRAVEL:Destroy() end
TRAVEL = new("ScreenGui", { Name = "SkyTravelGui", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 950, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, pg)
local DEST = {
	island = { icon = "⛰️", title = "PATAAS! PARKOUR", ask = "Teleport to PATAAS! Parkour?", sub = "A floating island high above the campus. Climb to the top!" },
	campus = { icon = "🏫", title = "SAMAR COLLEGE CAMPUS", ask = "Go back to the campus?", sub = "You will leave the PATAAS! island and return to the portal." },
}
local function fitScale(obj, w, h)
	local sc = new("UIScale", {}, obj)
	local function upd() local v = TRAVEL.AbsoluteSize if v.X > 1 then sc.Scale = math.clamp(math.min((v.X - 20) / w, (v.Y - 20) / h), 0.55, 1) end end
	TRAVEL:GetPropertyChangedSignal("AbsoluteSize"):Connect(upd) upd()
end
-- dialog
local ask = new("Frame", { Name = "AskTeleport", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(400, 210), BackgroundColor3 = BG, Visible = false, ZIndex = 40 }, TRAVEL)
corner(ask, UDim.new(0, 18)) stroke(ask, GOLD, 2) fitScale(ask, 400, 210)
local askIcon = label(ask, { Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 0, 40), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 34, ZIndex = 41, Text = "⛰️" })
local askTitle = label(ask, { Position = UDim2.fromOffset(16, 56), Size = UDim2.new(1, -32, 0, 28), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextSize = 21, TextColor3 = GOLD, ZIndex = 41, Text = "" })
local askSub = label(ask, { Position = UDim2.fromOffset(20, 86), Size = UDim2.new(1, -40, 0, 40), TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true, TextSize = 14, TextColor3 = DIM, ZIndex = 41, Text = "" })
local yes = button(ask, "✅ Yes, teleport", GREEN, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(0.5, -6, 1, -16), Size = UDim2.fromOffset(170, 48), TextSize = 17, ZIndex = 41 })
local no = button(ask, "✖ Not now", CARD, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0.5, 6, 1, -16), Size = UDim2.fromOffset(170, 48), TextSize = 17, ZIndex = 41 })
stroke(no, DIM, 1)
local askDest
local function showAsk(dest)
	local d = DEST[dest] if not d then return end
	askDest = dest
	askIcon.Text, askTitle.Text, askSub.Text = d.icon, d.ask, d.sub
	ask.Visible = true
	ask.Size = UDim2.fromOffset(300, 160) tw(ask, 0.18, { Size = UDim2.fromOffset(400, 210) })
end
yes.Activated:Connect(function()
	if not ask.Visible then return end
	ask.Visible = false
	Remote:FireServer(askDest == "island" and "enter" or "campus")
end)
no.Activated:Connect(function()
	ask.Visible = false
	if askDest == "island" then Remote:FireServer("decline") end
end)
-- loading screen
local load = new("Frame", { Name = "TravelLoading", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Visible = false, ZIndex = 60 }, TRAVEL)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(20, 60, 40), Color3.fromRGB(8, 12, 18)) }, load)
local box = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(520, 250), BackgroundTransparency = 1, ZIndex = 61 }, load)
fitScale(box, 520, 250)
local lIcon = label(box, { Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 70), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 60, ZIndex = 62, Text = "⛰️" })
local lTitle = label(box, { Position = UDim2.fromOffset(0, 78), Size = UDim2.new(1, 0, 0, 38), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextSize = 32, TextColor3 = GOLD, ZIndex = 62, Text = "" })
local lStatus = label(box, { Position = UDim2.fromOffset(0, 122), Size = UDim2.new(1, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 16, TextColor3 = TEXT, ZIndex = 62, Text = "Loading the area…" })
local barBg = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 160), Size = UDim2.fromOffset(380, 14), BackgroundColor3 = Color3.fromRGB(40, 46, 56), ZIndex = 62 }, box)
corner(barBg, UDim.new(1, 0))
local barFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, ZIndex = 63 }, barBg)
corner(barFill, UDim.new(1, 0))
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(60, 190, 90), Color3.fromRGB(245, 200, 60)) }, barFill)
local lTip = label(box, { Position = UDim2.fromOffset(0, 190), Size = UDim2.new(1, 0, 0, 40), TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true, TextSize = 13, TextColor3 = DIM, ZIndex = 62, Text = "" })
local TIPS = { "Tip: EASY mode saves your progress at every checkpoint 🚩", "Tip: HARD mode has no checkpoints — fall and you start over 💀", "Tip: crumbling book stacks vanish a moment after you land on them 📚", "Tip: tap 🏫 Campus on the island to go back to school" }
local loading, loadToken = false, 0
local controls
local function getControls()
	if not controls then pcall(function() local pm = player.PlayerScripts:FindFirstChild("PlayerModule") if pm then controls = require(pm):GetControls() end end) end
	return controls
end
local function hideLoading()
	loading = false
	if getControls() then pcall(function() controls:Enable() end) end
	if load.Visible then
		tw(load, 0.4, { BackgroundTransparency = 1 })
		for _, o in ipairs(load:GetDescendants()) do
			if o:IsA("TextLabel") then tw(o, 0.4, { TextTransparency = 1 }) elseif o:IsA("Frame") and o ~= box then tw(o, 0.4, { BackgroundTransparency = 1 }) end
		end
		task.delay(0.42, function() if not loading then load.Visible = false end end)
	end
end
local function showLoading(dest)
	local d = DEST[dest] or DEST.island
	ask.Visible = false
	loading = true
	loadToken += 1
	local my = loadToken
	lIcon.Text, lTitle.Text = d.icon, d.title
	lStatus.Text = "Loading the area… please wait"
	lTip.Text = TIPS[math.random(#TIPS)]
	load.BackgroundTransparency = 1
	for _, o in ipairs(load:GetDescendants()) do
		if o:IsA("TextLabel") then o.TextTransparency = 0 elseif o:IsA("Frame") and o ~= box then o.BackgroundTransparency = 0 end
	end
	load.Visible = true
	tw(load, 0.3, { BackgroundTransparency = 0 })
	barFill.Size = UDim2.fromScale(0, 1)
	TweenService:Create(barFill, TweenInfo.new(4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.fromScale(0.85, 1) }):Play()
	if getControls() then pcall(function() controls:Disable() end) end
	-- dots animation
	task.spawn(function()
		local n = 0
		while loading and loadToken == my do
			n = n % 3 + 1
			if lStatus.Text:find("Loading") then lStatus.Text = "Loading the area, please wait" .. string.rep(".", n) end
			task.wait(0.4)
		end
	end)
	task.delay(25, function() if loading and loadToken == my then hideLoading() end end) -- safety
end
local function finishLoading(dest)
	local my = loadToken
	task.spawn(function()
		local t0 = os.clock()
		local params = RaycastParams.new() params.FilterType = Enum.RaycastFilterType.Exclude
		while os.clock() - t0 < 10 do
			task.wait(0.15)
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				params.FilterDescendantsInstances = { char }
				local ground = workspace:Raycast(hrp.Position, Vector3.new(0, -30, 0), params)
				local okArea = dest ~= "island" or (workspace:FindFirstChild("SkyClimb") and workspace.SkyClimb:FindFirstChild("StartIsland") ~= nil)
				if ground and okArea and os.clock() - t0 > 0.6 then break end
			end
		end
		if loadToken ~= my then return end
		lStatus.Text = "✅ Ready!"
		tw(barFill, 0.3, { Size = UDim2.fromScale(1, 1) })
		task.wait(0.5)
		if loadToken == my then hideLoading() end
	end)
end

---------------------------------------------------------------- server messages
Remote.OnClientEvent:Connect(function(d)
	if type(d) ~= "table" then return end
	if d.type == "state" then
		S.inside, S.running, S.mode, S.start = d.inside, d.running, d.mode, d.start or 0
		S.cp, S.falls = d.cp or 0, d.falls or 0
		S.baseY, S.topY = d.baseY or S.baseY, d.topY or S.topY
		S.bestEasy, S.bestHard, S.checkpoints = d.bestEasy or 0, d.bestHard or 0, d.checkpoints or 12
		if d.running then S.finished = nil end
		readZones()
		refresh()
	elseif d.type == "ask" then showAsk(d.dest)
	elseif d.type == "loading" then showLoading(d.dest)
	elseif d.type == "arrived" then finishLoading(d.dest)
	elseif d.type == "loadDone" then hideLoading()
	elseif d.type == "enter" then popup("⛰️ Welcome to PATAAS! Parkour", GOLD, 3)
	elseif d.type == "start" then S.zone = 0 popup(d.mode == "Easy" and "🟢 EASY — checkpoints are ON. GO!" or "🔴 HARD — no checkpoints. GO!", d.mode == "Easy" and EASY or HARD)
	elseif d.type == "checkpoint" then popup(("🚩 Checkpoint saved! (Zone %d)"):format(d.zone or 0), EASY, 1.8)
	elseif d.type == "fell" then
		S.falls = d.falls or S.falls
		popup(d.to == "checkpoint" and "💨 You fell! Back to your checkpoint" or "💀 You fell all the way down! Back to the start", HARD, 2)
		refresh()
	elseif d.type == "finish" then
		S.finished = d
		timer.Text = fmt(d.time)
		finishCard(d)
	end
end)

---------------------------------------------------------------- buttons
bEasy.MouseButton1Click:Connect(function() Remote:FireServer("start", "Easy") end)
bHard.MouseButton1Click:Connect(function() Remote:FireServer("start", "Hard") end)
bCampus.MouseButton1Click:Connect(function() Remote:FireServer("campus") end)
bCheck.MouseButton1Click:Connect(function() Remote:FireServer("checkpoint") end)
bRestart.MouseButton1Click:Connect(function() Remote:FireServer("restart") end)
bLeave.MouseButton1Click:Connect(function() Remote:FireServer("leave") end)

---------------------------------------------------------------- every frame: timer, height, zone
RunService.RenderStepped:Connect(function()
	if not S.inside then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if S.running and S.start > 0 then timer.Text = fmt(workspace:GetServerTimeNow() - S.start) end
	if hrp then
		local f = math.clamp((hrp.Position.Y - 3 - S.baseY) / math.max(1, S.topY - S.baseY), 0, 1)
		fill.Size = UDim2.fromScale(1, f)
		me.Position = UDim2.new(0, 14, 1 - f, 0)
		pct.Text = ("%d%%"):format(math.floor(f * 100 + 0.5))
		if S.running then
			local z = currentZone(hrp.Position.Y - 3)
			if z > 0 then
				zoneLbl.Text = ("Zone %d • %s (%s)"):format(z, ZONES[z].name, ZONES[z].sub)
				zoneLbl.TextColor3 = ZONES[z].color
				if z > S.zone then
					S.zone = z
					if z > 1 then popup(("ZONE %d • %s"):format(z, ZONES[z].name), ZONES[z].color, 2.2) end
				end
			else
				zoneLbl.Text = "Jump onto the street to begin!"
				zoneLbl.TextColor3 = Color3.fromRGB(200, 230, 210)
			end
		end
	end
end)

---------------------------------------------------------------- start
player:GetAttributeChangedSignal("InSkyClimb"):Connect(function()
	S.inside = player:GetAttribute("InSkyClimb") == true
	refresh()
end)
task.spawn(function() while true do task.wait(1) if root.Visible then layout() end end end)
rescale()
refresh()
Remote:FireServer("state")
