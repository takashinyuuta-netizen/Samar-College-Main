--[[ FoundationClient — Founding Anniversary (Foundation Day) screens
  • Program card: the whole Schedule of Activities with ✓ done / ▶ now / upcoming, and a timer for the current one
  • Now-on-stage ticker + context buttons: 👑 Join Pageant · 🗳️ Vote · 👏 Cheer
  • Pageant registration (Mr. / Ms.), voting (Best in Talent / Mr. / Ms.), crowning reveal
  • Photo Booth polaroid, sack-race countdown, parlor-game banner, fireworks alert, anniversary music ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local Remotes = RS:WaitForChild("Events"):WaitForChild("EventRemotes")
local Config = require(RS.Events:WaitForChild("EventConfig"))
local FD = Config.FoundationDay
local gui = script.Parent

local GREEN, GREEN2, GOLD = Color3.fromRGB(26, 104, 58), Color3.fromRGB(14, 60, 36), Color3.fromRGB(245, 200, 70)
local BG, CARD, TEXT, DIM = Color3.fromRGB(20, 24, 30), Color3.fromRGB(32, 38, 46), Color3.fromRGB(240, 242, 245), Color3.fromRGB(150, 160, 170)

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
local function call(action, data)
	local ok, res = pcall(function() return Remotes.EventAction:InvokeServer(action, data) end)
	return ok and type(res) == "table" and res or { ok = false }
end
local function headshot(userId)
	local ok, img = pcall(function() return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
	return ok and img or ""
end

-- everything sits in one holder that scales with the screen (phones / tablets / PC)
local root = new("Frame", { Name = "FoundationUI", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, gui)
local scale = new("UIScale", {}, root)
local layout -- places every panel around the HUD; defined once the panels exist
local effScale = 1 -- the real on-screen scale of this UI
-- EventGui may already carry a screen-wide UIScale (UIResponsive's ResponsiveScale); compensate so we don't shrink twice
local function guiScale()
	local f = 1
	for _, c in ipairs(gui:GetChildren()) do if c:IsA("UIScale") then f *= c.Scale end end
	return math.max(f, 0.01)
end
local function rescale()
	local v = gui.AbsoluteSize
	if v.Y > 2 then
		effScale = math.clamp(math.min(v.X / 1100, v.Y / 640), 0.5, 1)
		scale.Scale = effScale / guiScale()
		-- UIScale also shrinks the holder itself, so grow it back to cover the whole screen
		root.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)
	end
	if layout then layout() end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)
gui.ChildAdded:Connect(function(c) if c:IsA("UIScale") then c:GetPropertyChangedSignal("Scale"):Connect(rescale) task.defer(rescale) end end)
for _, c in ipairs(gui:GetChildren()) do if c:IsA("UIScale") then c:GetPropertyChangedSignal("Scale"):Connect(rescale) end end
rescale()

---------------------------------------------------------------- music
local music = new("Sound", { Name = "Foundation_Music", SoundId = FD.Music, Looped = true, Volume = 0 }, SoundService)
local function musicOn(v)
	if v and not music.IsPlaying then music:Play() end
	tw(music, 1.2, { Volume = v and 0.3 or 0 })
end

---------------------------------------------------------------- NOW ticker (top centre)
local ticker = new("Frame", { Name = "FoundationTicker", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96), Size = UDim2.fromOffset(520, 58), BackgroundColor3 = GREEN }, root)
corner(ticker, UDim.new(0, 16)) stroke(ticker, GOLD, 2)
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(34, 130, 72), GREEN2) }, ticker)
local tNow = label(ticker, { Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -140, 0, 26), Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = GOLD, TextTruncate = Enum.TextTruncate.AtEnd, Text = "" })
local tDesc = label(ticker, { Position = UDim2.fromOffset(14, 31), Size = UDim2.new(1, -140, 0, 20), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(220, 240, 225), TextTruncate = Enum.TextTruncate.AtEnd, Text = "" })
local tTime = label(ticker, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -46, 0.5, 0), Size = UDim2.fromOffset(84, 36), Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Right, Text = "" })

-- minimize: the ticker shrinks to a small pill (icon + timer) and the buttons hide
local tMinBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = GREEN2, TextColor3 = GOLD, Font = Enum.Font.GothamBlack, TextSize = 18, Text = "–", AutoButtonColor = true }, ticker)
corner(tMinBtn, UDim.new(1, 0)) stroke(tMinBtn, GOLD, 1)
local tickerMin = false
local function tickerSize(big) if tickerMin then return UDim2.fromOffset(big and 250 or 230, big and 46 or 42) end return UDim2.fromOffset(big and 560 or 520, big and 64 or 58) end
local applyTickerMin -- set below (needs the action bar)

-- context buttons under the ticker
local actions = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 160), Size = UDim2.fromOffset(520, 40), BackgroundTransparency = 1 }, root)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8) }, actions)
local bProgram = button(actions, "📋 Program", CARD, { Size = UDim2.fromOffset(120, 36), LayoutOrder = 1 })
local bRegister = button(actions, "👑 Join Pageant", Color3.fromRGB(170, 20, 40), { Size = UDim2.fromOffset(150, 36), LayoutOrder = 2, Visible = false })
local bVote = button(actions, "🗳️ Vote", Color3.fromRGB(40, 90, 190), { Size = UDim2.fromOffset(110, 36), LayoutOrder = 3, Visible = false })
local bCheer = button(actions, "👏 Cheer", Color3.fromRGB(230, 120, 30), { Size = UDim2.fromOffset(110, 36), LayoutOrder = 4, Visible = false })
local tNowFull = ""
applyTickerMin = function()
	tw(ticker, 0.2, { Size = tickerSize(false) })
	if layout then layout() end
	tDesc.Visible = not tickerMin
	actions.Visible = not tickerMin
	tMinBtn.Text = tickerMin and "+" or "–"
	tNow.TextSize = tickerMin and 15 or 18
	tNow.Position = tickerMin and UDim2.fromOffset(14, 8) or UDim2.fromOffset(14, 6)
	tNow.Size = tickerMin and UDim2.new(1, -140, 1, -16) or UDim2.new(1, -140, 0, 26)
	tTime.TextSize = tickerMin and 18 or 22
end
tMinBtn.MouseButton1Click:Connect(function() tickerMin = not tickerMin applyTickerMin() end)

-- big game banner (parlor games) + countdown
local gameBanner = label(root, { Name = "GameBanner", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 206), Size = UDim2.fromOffset(560, 34), BackgroundTransparency = 0.15, BackgroundColor3 = Color3.fromRGB(150, 40, 60), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextSize = 16, TextColor3 = GOLD, Visible = false, Text = "" })
corner(gameBanner)
local countdown = label(root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(500, 140), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextSize = 110, TextColor3 = GOLD, TextStrokeTransparency = 0.2, Visible = false, Text = "" })

---------------------------------------------------------------- PROGRAM card (left)
local programCard = new("Frame", { Name = "ProgramCard", AnchorPoint = Vector2.zero, Position = UDim2.fromOffset(96, 120), Size = UDim2.fromOffset(330, 470), BackgroundColor3 = BG, Visible = false }, root)
corner(programCard, UDim.new(0, 16)) stroke(programCard, GOLD, 1.6)
local ph = new("Frame", { Size = UDim2.new(1, 0, 0, 74), BackgroundColor3 = GREEN }, programCard) corner(ph, UDim.new(0, 16))
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(34, 130, 72), GREEN2) }, ph)
label(ph, { Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -98, 0, 18), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(200, 235, 210), TextTruncate = Enum.TextTruncate.AtEnd, Text = "SAMAR COLLEGE • CAMPUS CELEBRATION" })
label(ph, { Position = UDim2.fromOffset(14, 26), Size = UDim2.new(1, -98, 0, 24), Font = Enum.Font.GothamBlack, TextSize = 18, TextScaled = true, TextColor3 = GOLD, Text = "FOUNDING ANNIVERSARY" })
label(ph, { Position = UDim2.fromOffset(14, 50), Size = UDim2.new(1, -98, 0, 18), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), Text = "📋 SCHEDULE OF ACTIVITIES" })
local pClose = button(ph, "X", GREEN2, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(32, 32) })
local pMin = button(ph, "–", GREEN2, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -48, 0, 10), Size = UDim2.fromOffset(32, 32), TextSize = 18, TextColor3 = GOLD })
local grip = label(ph, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -4), Size = UDim2.fromOffset(80, 16), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.fromRGB(190, 225, 200), Text = "✥ drag to move" })
local list = new("ScrollingFrame", { Position = UDim2.fromOffset(10, 82), Size = UDim2.new(1, -20, 1, -92), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, programCard)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
local rows = {}
local function buildProgram(program, allDay)
	for _, r in ipairs(rows) do r.frame:Destroy() end
	rows = {}
	for i, s in ipairs(program) do
		local f = new("Frame", { Size = UDim2.new(1, -4, 0, 54), BackgroundColor3 = CARD, LayoutOrder = i }, list) corner(f, UDim.new(0, 10))
		local st = stroke(f, CARD, 1.4)
		local mark = label(f, { Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(26, 54), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 16, Text = tostring(i) })
		local name = label(f, { Position = UDim2.fromOffset(36, 6), Size = UDim2.new(1, -44, 0, 20), TextSize = 13, Font = Enum.Font.GothamBlack, TextTruncate = Enum.TextTruncate.AtEnd, Text = s.Icon .. " " .. s.Name })
		local desc = label(f, { Position = UDim2.fromOffset(36, 26), Size = UDim2.new(1, -44, 0, 24), TextSize = 10, Font = Enum.Font.Gotham, TextColor3 = DIM, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Text = s.Desc })
		rows[i] = { frame = f, stroke = st, mark = mark, name = name, desc = desc }
	end
	local hdr = label(list, { Size = UDim2.new(1, -4, 0, 22), LayoutOrder = 100, TextColor3 = GOLD, TextSize = 12, Text = "ALL DAY" })
	table.insert(rows, { frame = hdr })
	for k, a in ipairs(allDay or {}) do
		local f = new("Frame", { Size = UDim2.new(1, -4, 0, 44), BackgroundColor3 = CARD, LayoutOrder = 100 + k }, list) corner(f, UDim.new(0, 10))
		label(f, { Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 18), TextSize = 13, Font = Enum.Font.GothamBlack, Text = a.Icon .. " " .. a.Name })
		label(f, { Position = UDim2.fromOffset(10, 22), Size = UDim2.new(1, -20, 0, 18), TextSize = 10, Font = Enum.Font.Gotham, TextColor3 = DIM, TextWrapped = true, Text = a.Desc })
		table.insert(rows, { frame = f })
	end
end
buildProgram(FD.Program, FD.AllDay)
local function markProgram(seg)
	for i, r in ipairs(rows) do
		if r.mark then
			if i < seg then r.mark.Text = "✓" r.mark.TextColor3 = Color3.fromRGB(110, 220, 130) r.frame.BackgroundColor3 = Color3.fromRGB(26, 32, 38) r.name.TextColor3 = DIM r.stroke.Color = CARD
			elseif i == seg then r.mark.Text = "▶" r.mark.TextColor3 = GOLD r.frame.BackgroundColor3 = Color3.fromRGB(28, 70, 46) r.name.TextColor3 = GOLD r.stroke.Color = GOLD
			else r.mark.Text = tostring(i) r.mark.TextColor3 = TEXT r.frame.BackgroundColor3 = CARD r.name.TextColor3 = TEXT r.stroke.Color = CARD end
		end
	end
end
bProgram.MouseButton1Click:Connect(function() programCard.Visible = not programCard.Visible end)
pClose.MouseButton1Click:Connect(function() programCard.Visible = false end)

-- minimize the program card to its header
local CARD_W, HEAD_H = 330, 74
local cardH = 470         -- shrinks on short screens (phones in landscape)
local progMin = false
local cardMoved = false   -- once the player drags it, we keep their spot
local layoutLeft = 20     -- first free x to the right of the HUD rail
local layoutBottom = 170  -- first free space above the hotbar (from the bottom edge)
pMin.MouseButton1Click:Connect(function()
	progMin = not progMin
	pMin.Text = progMin and "+" or "–"
	list.Visible = not progMin
	tw(programCard, 0.2, { Size = UDim2.fromOffset(CARD_W, progMin and HEAD_H or cardH) })
end)

-- all positions below are in the holder's (unscaled) units
local function unscaledScreen() local s = math.max(effScale, 0.01) return gui.AbsoluteSize / s, s end
local function clampCard(x, y)
	local scr = unscaledScreen()
	return math.clamp(x, 0, math.max(0, scr.X - CARD_W)), math.clamp(y, 0, math.max(0, scr.Y - HEAD_H))
end

-- what is already on screen (HUD rail buttons, the event banner) so nothing overlaps
local pg = player:WaitForChild("PlayerGui")
local function shown(o)
	while o and o:IsA("GuiObject") do if not o.Visible then return false end o = o.Parent end
	return not (o and o:IsA("LayerCollector")) or o.Enabled
end
local function relRect(o)
	local _, s = unscaledScreen()
	return (o.AbsolutePosition - root.AbsolutePosition) / s, o.AbsoluteSize / s
end
local function obstacles()
	local out = {}
	local banner = gui:FindFirstChild("Banner")
	if banner and banner:IsA("GuiObject") and shown(banner) then table.insert(out, banner) end
	local hud = pg:FindFirstChild("MainHUD")
	if hud and hud.Enabled then
		for _, c in ipairs(hud:GetDescendants()) do if c:IsA("GuiButton") and c.AbsoluteSize.X > 10 and shown(c) then table.insert(out, c) end end
	end
	local admin = pg:FindFirstChild("AdminPanelGui") -- admin dock beside the rail (admins only)
	if admin and admin.Enabled then
		for _, c in ipairs(admin:GetChildren()) do if c:IsA("GuiObject") and shown(c) and c.AbsoluteSize.X > 10 and c.AbsoluteSize.X < gui.AbsoluteSize.X * 0.5 then table.insert(out, c) end end
	end
	local coins = pg:FindFirstChild("CoinsGui")
	if coins and coins.Enabled then
		for _, c in ipairs(coins:GetChildren()) do if c:IsA("GuiObject") and shown(c) and c.AbsoluteSize.X > 10 then table.insert(out, c) end end
	end
	return out
end

layout = function()
	local scr = unscaledScreen()
	local W, H = scr.X, scr.Y
	if W < 10 then return end
	local obs = {}
	for _, o in ipairs(obstacles()) do local p, sz = relRect(o) table.insert(obs, { p = p, sz = sz }) end
	-- lowest point of anything in the top area that overlaps a column
	local function below(c0, c1)
		local y = 10
		for _, o in ipairs(obs) do
			if o.p.Y < H * 0.35 and o.p.X < c1 and o.p.X + o.sz.X > c0 then y = math.max(y, o.p.Y + o.sz.Y + 8) end
		end
		return y
	end
	-- a vertical rail on the left (PC) pushes the card / spotlight to its right
	local left = 12
	for _, o in ipairs(obs) do
		if o.p.X < W * 0.12 and o.p.Y + o.sz.Y > H * 0.3 and o.p.Y < H * 0.85 then left = math.max(left, o.p.X + o.sz.X + 12) end
	end
	layoutLeft = left
	-- bottom: stay above the hotbar (and its title) so toasts never cover it
	local bottom = 24
	local hotRects = {}
	local hot = pg:FindFirstChild("HotbarGui")
	if hot and hot.Enabled then
		for _, c in ipairs(hot:GetDescendants()) do
			if c:IsA("GuiObject") and c.AbsoluteSize.X > 10 and shown(c) then
				local p, sz = relRect(c)
				if p.Y > H * 0.5 then bottom = math.max(bottom, H - p.Y + 12) table.insert(hotRects, { p = p, sz = sz }) end
			end
		end
	end
	if UIS.TouchEnabled then bottom = math.max(bottom, 150) end -- thumbstick / jump button zone
	layoutBottom = bottom
	-- NOW ticker, buttons and game banner: centred, under the event banner / top buttons
	local tW = tickerMin and 250 or 560
	local top = below(W / 2 - tW / 2 - 8, W / 2 + tW / 2 + 8)
	local tH = tickerMin and 42 or 58
	ticker.Position = UDim2.new(0.5, 0, 0, top)
	actions.Position = UDim2.new(0.5, 0, 0, top + tH + 6)
	local rowBottom = top + tH + (tickerMin and 6 or 52)
	gameBanner.Position = UDim2.new(0.5, 0, 0, rowBottom)
	if gameBanner.Visible then rowBottom += 40 end
	-- program card: right of the rail, under the top items; below the ticker row if they would touch
	local cardTop = below(left, left + CARD_W)
	if left + CARD_W > W / 2 - 290 then cardTop = math.max(cardTop, rowBottom + 8) end
	-- never cover the hotbar, and on phones keep clear of the thumbstick (lower-left)
	local limit = H - 14
	for _, r in ipairs(hotRects) do
		if r.p.X < left + CARD_W and r.p.X + r.sz.X > left and r.p.Y > cardTop then limit = math.min(limit, r.p.Y - 10) end
	end
	if UIS.TouchEnabled then limit = math.min(limit, H * 0.64) end
	cardH = math.clamp(limit - cardTop, 150, 470)
	if not progMin then programCard.Size = UDim2.fromOffset(CARD_W, cardH) end
	if not cardMoved then
		programCard.Position = UDim2.fromOffset(clampCard(left, cardTop))
	else
		programCard.Position = UDim2.fromOffset(clampCard(programCard.Position.X.Offset, programCard.Position.Y.Offset))
	end
end

-- drag the program card by its header (mouse + touch); it always stays on screen
local dragInput, dragStart, startPos
ph.Active = true
ph.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragInput, dragStart, startPos = input, input.Position, programCard.Position
		input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End and dragInput == input then dragInput = nil end end)
	end
end)
UIS.InputChanged:Connect(function(input)
	if not dragInput then return end
	if input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement then
		local _, s = unscaledScreen()
		local d = (input.Position - dragStart) / s
		if d.Magnitude > 3 then cardMoved = true end
		programCard.Position = UDim2.fromOffset(clampCard(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y))
	end
end)
UIS.InputEnded:Connect(function(input) if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then dragInput = nil end end)
programCard:GetPropertyChangedSignal("Visible"):Connect(function() if programCard.Visible then layout() end end)
gameBanner:GetPropertyChangedSignal("Visible"):Connect(function() layout() end)
-- the event banner / HUD can appear or move at any time: re-check every second while shown
task.spawn(function() while true do task.wait(1) if root.Visible then layout() end end end)
rescale()

---------------------------------------------------------------- modal helper
local function modal(title, sub, w, h)
	local dim = new("TextButton", { Size = UDim2.new(1, 800, 1, 800), Position = UDim2.fromOffset(-400, -400), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false, ZIndex = 40 }, root)
	local card = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(w, h), BackgroundColor3 = BG, ZIndex = 41 }, root)
	corner(card, UDim.new(0, 18)) stroke(card, GOLD, 2)
	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = Color3.fromRGB(150, 20, 40), ZIndex = 41 }, card) corner(head, UDim.new(0, 18))
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(180, 30, 50), Color3.fromRGB(100, 10, 25)) }, head)
	label(head, { Position = UDim2.fromOffset(18, 8), Size = UDim2.new(1, -70, 0, 30), Font = Enum.Font.GothamBlack, TextSize = 20, TextColor3 = GOLD, Text = title, ZIndex = 42 })
	label(head, { Position = UDim2.fromOffset(18, 38), Size = UDim2.new(1, -70, 0, 22), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(255, 225, 225), Text = sub or "", ZIndex = 42, TextTruncate = Enum.TextTruncate.AtEnd })
	local x = button(head, "X", Color3.fromRGB(100, 10, 25), { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(34, 34), ZIndex = 43 })
	local function close() dim:Destroy() card:Destroy() end
	x.MouseButton1Click:Connect(close) dim.MouseButton1Click:Connect(close)
	card.Size = UDim2.fromOffset(w * 0.9, h * 0.9) tw(card, 0.18, { Size = UDim2.fromOffset(w, h) })
	return card, close
end
local function toast(msg)
	local t = label(root, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -layoutBottom), Size = UDim2.fromOffset(460, 36), BackgroundTransparency = 0.1, BackgroundColor3 = BG, TextXAlignment = Enum.TextXAlignment.Center, TextSize = 14, Text = msg, ZIndex = 60 })
	corner(t) stroke(t, GOLD, 1)
	task.delay(2.6, function() tw(t, 0.3, { TextTransparency = 1, BackgroundTransparency = 1 }) task.wait(0.35) t:Destroy() end)
end

---------------------------------------------------------------- STATE
local S = { seg = 0, endsAt = 0, candidates = {}, registrationOpen = false, votingTalent = false, votingCrown = false, active = false }
local function myCandidate() for _, c in ipairs(S.candidates) do if c.userId == player.UserId then return c end end end
local function segId() local s = FD.Program[S.seg] return s and s.Id end
local function refreshButtons()
	bRegister.Visible = S.active and S.registrationOpen and myCandidate() == nil
	bVote.Visible = S.active and (S.votingTalent or S.votingCrown) and #S.candidates > 0
	bCheer.Visible = S.active and segId() == "SCTalents"
end
local function applyState(st)
	if type(st) ~= "table" then return end
	S.seg = st.seg or S.seg
	S.endsAt = st.segEndsAt or S.endsAt
	S.candidates = st.candidates or S.candidates
	S.registrationOpen = st.registrationOpen
	S.votingTalent = st.votingTalent
	S.votingCrown = st.votingCrown
	local s = FD.Program[S.seg]
	if s then tNow.Text = s.Icon .. "  NOW: " .. s.Name tDesc.Text = s.Desc end
	if st.decoTotal and segId() == "Opening" then tDesc.Text = ("✨ Decorations hung: %d / %d  •  press E at the ✨ crates"):format(st.decorated or 0, st.decoTotal) end
	markProgram(S.seg)
	refreshButtons()
end

---------------------------------------------------------------- REGISTRATION
local function openRegister()
	if myCandidate() then return toast("🎗️ You are already a candidate!") end
	local card, close = modal("👑 " .. FD.Pageant, FD.PageantSub, 520, 330)
	label(card, { Position = UDim2.fromOffset(20, 82), Size = UDim2.new(1, -40, 0, 50), TextWrapped = true, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = DIM, ZIndex = 42,
		Text = "Become an official candidate! You get a sash, walk the runway at the Presentation, perform in the Talent Competition, and the crowd votes at the Coronation Night." })
	local counts = { Mr = 0, Ms = 0 }
	for _, c in ipairs(S.candidates) do counts[c.title] += 1 end
	for i, t in ipairs({ { "Mr", "🤵 Mr. Samar College", Color3.fromRGB(40, 90, 190) }, { "Ms", "👗 Ms. Samar College", Color3.fromRGB(190, 40, 110) } }) do
		local b = button(card, t[2] .. "\n" .. counts[t[1]] .. " / " .. (FD.MaxCandidates or 6) .. " candidates", t[3], { Position = UDim2.new((i - 1) * 0.5, i == 1 and 20 or 8, 0, 146), Size = UDim2.new(0.5, -28, 0, 92), TextSize = 16, ZIndex = 42, TextWrapped = true })
		b.MouseButton1Click:Connect(function()
			local res = call("fd_register", { title = t[1] })
			toast(res.msg or (res.ok and "Registered!" or "Could not register"))
			if res.ok then close() end
		end)
	end
	label(card, { Position = UDim2.fromOffset(20, 252), Size = UDim2.new(1, -40, 0, 54), TextWrapped = true, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = DIM, ZIndex = 42,
		Text = "Pick the title you want to run for. Be kind and respectful to every candidate — have fun! 🎗️" })
end
bRegister.MouseButton1Click:Connect(openRegister)

---------------------------------------------------------------- VOTING
local myVotes = { talent = nil, Mr = nil, Ms = nil }
local function openVote()
	local cats = {}
	if S.votingTalent then table.insert(cats, { kind = "talent", label = "🎤 Best in Talent", filter = nil }) end
	if S.votingCrown then
		table.insert(cats, { kind = "crown", title = "Ms", label = "👗 Ms. Samar College", filter = "Ms" })
		table.insert(cats, { kind = "crown", title = "Mr", label = "🤵 Mr. Samar College", filter = "Mr" })
	end
	if #cats == 0 then return toast("🗳️ Voting is closed right now") end
	local card = modal("🗳️ VOTE", "Tap a candidate to vote. You can change your vote until voting closes.", 640, 470)
	local tabs = new("Frame", { Position = UDim2.fromOffset(16, 80), Size = UDim2.new(1, -32, 0, 36), BackgroundTransparency = 1, ZIndex = 42 }, card)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, tabs)
	local grid = new("ScrollingFrame", { Position = UDim2.fromOffset(16, 126), Size = UDim2.new(1, -32, 1, -140), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 42 }, card)
	new("UIGridLayout", { CellSize = UDim2.fromOffset(140, 170), CellPadding = UDim2.fromOffset(10, 10) }, grid)
	local function show(cat)
		for _, c in ipairs(grid:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		local key = cat.kind == "talent" and "talent" or cat.title
		for _, c in ipairs(S.candidates) do
			if not cat.filter or c.title == cat.filter then
				local mine = c.userId == player.UserId
				local chosen = myVotes[key] == c.userId
				local b = new("TextButton", { Text = "", BackgroundColor3 = chosen and Color3.fromRGB(40, 110, 60) or CARD, AutoButtonColor = not mine, ZIndex = 43 }, grid)
				corner(b) stroke(b, chosen and GOLD or Color3.fromRGB(60, 66, 76), chosen and 2.5 or 1)
				local img = new("ImageLabel", { Position = UDim2.fromOffset(25, 10), Size = UDim2.fromOffset(90, 90), BackgroundColor3 = GREEN2, Image = "", ZIndex = 44 }, b)
				corner(img, UDim.new(1, 0))
				task.spawn(function() img.Image = headshot(c.userId) end)
				label(b, { Position = UDim2.fromOffset(6, 104), Size = UDim2.new(1, -12, 0, 20), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Text = c.name, ZIndex = 44 })
				label(b, { Position = UDim2.fromOffset(6, 124), Size = UDim2.new(1, -12, 0, 18), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = GOLD, Text = c.title .. ". Candidate #" .. c.number, ZIndex = 44 })
				label(b, { Position = UDim2.fromOffset(6, 144), Size = UDim2.new(1, -12, 0, 18), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = chosen and Color3.fromRGB(140, 240, 150) or DIM, Text = mine and "That's you!" or (chosen and "✓ YOUR VOTE" or "Tap to vote"), ZIndex = 44 })
				if not mine then
					b.MouseButton1Click:Connect(function()
						local res = call("fd_vote", { kind = cat.kind, target = c.userId, title = cat.title })
						if res.ok then myVotes[key] = c.userId show(cat) end
						toast(res.msg or "")
					end)
				end
			end
		end
	end
	for i, cat in ipairs(cats) do
		local t = button(tabs, cat.label, i == 1 and Color3.fromRGB(170, 20, 40) or CARD, { Size = UDim2.fromOffset(190, 34), TextSize = 13, ZIndex = 43 })
		t.MouseButton1Click:Connect(function()
			for _, o in ipairs(tabs:GetChildren()) do if o:IsA("TextButton") then o.BackgroundColor3 = CARD end end
			t.BackgroundColor3 = Color3.fromRGB(170, 20, 40) show(cat)
		end)
	end
	show(cats[1])
end
bVote.MouseButton1Click:Connect(openVote)
bCheer.MouseButton1Click:Connect(function()
	local res = call("fd_cheer")
	if res.msg then toast(res.msg) end
end)

---------------------------------------------------------------- CORONATION reveal
local function coronation(results)
	-- same reveal order as the server: Ms first, then Mr; 2nd runner-up → 1st runner-up → winner (4 s each)
	task.spawn(function()
		for _, title in ipairs({ "Ms", "Mr" }) do
			local entry = results[title]
			for _, pl in ipairs(entry and entry.places or {}) do
				task.wait(4)
				local win = pl.place == 1
				local card = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(420, 300), BackgroundColor3 = win and Color3.fromRGB(60, 40, 8) or BG, ZIndex = 70 }, root)
				corner(card, UDim.new(0, 20)) stroke(card, GOLD, win and 4 or 2)
				if win then new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(120, 85, 20), Color3.fromRGB(40, 25, 5)) }, card) end
				label(card, { Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextSize = win and 22 or 18, TextColor3 = GOLD, ZIndex = 71,
					Text = win and ("👑 " .. title:upper() .. ". SAMAR COLLEGE 2026") or ((pl.place == 2 and "1st" or "2nd") .. " RUNNER-UP • " .. title .. ".") })
				local img = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 52), Size = UDim2.fromOffset(140, 140), BackgroundColor3 = GREEN2, ZIndex = 71 }, card)
				corner(img, UDim.new(1, 0)) stroke(img, GOLD, 3)
				task.spawn(function() img.Image = headshot(pl.userId) end)
				label(card, { Position = UDim2.fromOffset(0, 200), Size = UDim2.new(1, 0, 0, 34), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextSize = 26, ZIndex = 71, Text = pl.name })
				label(card, { Position = UDim2.fromOffset(0, 236), Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.fromRGB(230, 220, 190), ZIndex = 71, Text = ("Candidate #%d • %d vote%s"):format(pl.number, pl.votes, pl.votes == 1 and "" or "s") })
				if win then
					label(card, { Position = UDim2.fromOffset(0, 260), Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = GOLD, ZIndex = 71, Text = FD.PageantSub })
					for k = 1, 40 do
						local c = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromOffset(8, 12), Rotation = math.random(0, 360), BorderSizePixel = 0, ZIndex = 72,
							BackgroundColor3 = ({ GOLD, Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 60, 80), Color3.fromRGB(60, 160, 90) })[k % 4 + 1] }, card)
						local a = math.rad(math.random(0, 360))
						tw(c, 1.8, { Position = UDim2.new(0.5, math.cos(a) * math.random(150, 320), 0.3, math.sin(a) * 200 + 220), BackgroundTransparency = 1, Rotation = c.Rotation + 360 })
					end
				end
				card.Size = UDim2.fromOffset(200, 140) tw(card, 0.35, { Size = UDim2.fromOffset(420, 300) })
				task.delay(3.6, function() tw(card, 0.3, { BackgroundTransparency = 1 }) task.wait(0.32) card:Destroy() end)
			end
		end
	end)
end

---------------------------------------------------------------- PHOTO BOOTH polaroid
local function photo()
	local flash = new("Frame", { Size = UDim2.new(1, 800, 1, 800), Position = UDim2.fromOffset(-400, -400), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 80 }, root)
	tw(flash, 0.6, { BackgroundTransparency = 1 })
	task.delay(0.7, function() flash:Destroy() end)
	local pol = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.78, 0.44), Size = UDim2.fromOffset(250, 300), BackgroundColor3 = Color3.fromRGB(250, 248, 240), Rotation = -4, ZIndex = 75 }, root)
	stroke(pol, Color3.fromRGB(200, 200, 190), 1)
	local pic = new("ImageLabel", { Position = UDim2.fromOffset(15, 15), Size = UDim2.fromOffset(220, 210), BackgroundColor3 = GREEN, ZIndex = 76 }, pol)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(40, 140, 80), GREEN2) }, pic)
	local face = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(190, 190), BackgroundTransparency = 1, ZIndex = 77 }, pic)
	task.spawn(function()
		local ok, img = pcall(function() return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420) end)
		if ok then face.Image = img end
	end)
	label(pic, { Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -12, 0, 18), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBlack, TextSize = 13, TextColor3 = GOLD, Text = "SAMAR COLLEGE", ZIndex = 78 })
	label(pol, { Position = UDim2.fromOffset(10, 232), Size = UDim2.new(1, -20, 0, 26), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.Garamond, TextSize = 22, TextColor3 = Color3.fromRGB(40, 40, 40), Text = "Founding Anniversary", ZIndex = 76 })
	label(pol, { Position = UDim2.fromOffset(10, 262), Size = UDim2.new(1, -20, 0, 20), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.fromRGB(90, 90, 90), Text = player.DisplayName .. "  •  #SamarCollege", ZIndex = 76 })
	pol.Size = UDim2.fromOffset(60, 70) tw(pol, 0.4, { Size = UDim2.fromOffset(250, 300) })
	task.delay(5, function() tw(pol, 0.4, { Position = UDim2.fromScale(1.3, 0.5) }) task.wait(0.45) pol:Destroy() end)
end

---------------------------------------------------------------- spotlight card (presentation)
local function spotlight(d)
	local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -(layoutBottom + 46)), Size = UDim2.fromOffset(330, 92), BackgroundColor3 = BG, ZIndex = 65 }, root)
	corner(f, UDim.new(0, 14)) stroke(f, GOLD, 2)
	local img = new("ImageLabel", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(72, 72), BackgroundColor3 = GREEN2, ZIndex = 66 }, f) corner(img, UDim.new(1, 0))
	task.spawn(function() img.Image = headshot(d.userId) end)
	label(f, { Position = UDim2.fromOffset(94, 12), Size = UDim2.new(1, -104, 0, 20), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = GOLD, Text = "🎗️ NOW ON THE RUNWAY", ZIndex = 66 })
	label(f, { Position = UDim2.fromOffset(94, 34), Size = UDim2.new(1, -104, 0, 26), Font = Enum.Font.GothamBlack, TextSize = 20, TextTruncate = Enum.TextTruncate.AtEnd, Text = d.name, ZIndex = 66 })
	label(f, { Position = UDim2.fromOffset(94, 62), Size = UDim2.new(1, -104, 0, 18), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = DIM, Text = d.title .. ". Samar College • Candidate #" .. d.number, ZIndex = 66 })
	task.delay(7, function() if f.Parent then f:Destroy() end end)
end

---------------------------------------------------------------- events from the server
local function setActive(on)
	S.active = on
	root.Visible = on
	musicOn(on)
	if not on then programCard.Visible = false gameBanner.Visible = false countdown.Visible = false end
	refreshButtons()
end
Remotes.EventData.OnClientEvent:Connect(function(d)
	if type(d) ~= "table" or d.event ~= "FoundationDay" then return end
	if d.type == "hide" then setActive(false)
	elseif d.type == "state" then applyState(d)
	elseif d.type == "segment" then
		S.seg = d.seg S.endsAt = d.endsAt applyState({ seg = d.seg, segEndsAt = d.endsAt, candidates = S.candidates, registrationOpen = S.registrationOpen, votingTalent = S.votingTalent, votingCrown = S.votingCrown })
		tw(ticker, 0.15, { Size = tickerSize(true) }).Completed:Connect(function() tw(ticker, 0.2, { Size = tickerSize(false) }) end)
		if segId() == "Opening" then programCard.Visible = true end
	elseif d.type == "openRegister" then openRegister()
	elseif d.type == "coronation" then coronation(d.results)
	elseif d.type == "photo" then photo()
	elseif d.type == "spotlight" then spotlight(d)
	elseif d.type == "game" then gameBanner.Text = d.text or "" gameBanner.Visible = (d.text or "") ~= ""
	elseif d.type == "countdown" then
		countdown.Text = d.text countdown.Visible = true countdown.TextTransparency = 0 countdown.TextSize = 140
		tw(countdown, 0.8, { TextSize = 100, TextTransparency = 0.3 })
		task.delay(0.9, function() if countdown.Text == d.text then countdown.Visible = false end end)
	elseif d.type == "cheer" then
		local c = label(root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.25 + math.random() * 0.5, 0, 0.75, 0), Size = UDim2.fromOffset(200, 30), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 18, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextStrokeTransparency = 0.3, Text = "👏 " .. (d.name or "") })
		tw(c, 1.4, { Position = c.Position - UDim2.fromOffset(0, 120), TextTransparency = 1, TextStrokeTransparency = 1 })
		task.delay(1.5, function() c:Destroy() end)
	elseif d.type == "fireworks" then tNow.Text = "🎆 FIREWORKS FINALE — LOOK UP!" end
end)
local function onState(s)
	if type(s) ~= "table" then return end
	if s.active and s.id == "FoundationDay" and s.phase == "Active" then
		if not S.active then
			setActive(true)
			task.spawn(function() local res = call("fd_state") if res.ok then applyState(res.state) end end)
		end
	elseif S.active and (not s.active or s.id ~= "FoundationDay" or s.phase == "Results") then setActive(false) end
end
Remotes.EventState.OnClientEvent:Connect(onState)
-- joined (or respawned) while the celebration is already running: ask the server where it is
task.spawn(function()
	local ok, res = pcall(function() return Remotes.EventAction:InvokeServer("sync") end)
	if ok and type(res) == "table" and type(res.state) == "table" then onState(res.state) end
end)
-- timer
task.spawn(function()
	while true do
		task.wait(0.5)
		if S.active and S.endsAt > 0 then
			local left = math.max(0, S.endsAt - os.time())
			tTime.Text = string.format("%d:%02d", left // 60, left % 60)
		end
	end
end)
