--[[ EventClient ─────────────────────────────────────────────────────────────
  Shows the event system on screen (all data comes from the server):
  • Banner  – rarity, name, description, location, countdown, [Go there] [Join]
              (hidden when Settings → Event Alerts is OFF; a small pill stays instead)
  • Pill    – compact name + timer; tap to open the banner again
  • Scoreboard – top 5 + your score (needs Settings → Leaderboard Updates ON,
                 or always while you are a participant)
  • Results – podium + your reward
  • Toasts  – short messages from the server
  • Map pin – a 🎪 pin on the Map page (MainHUD) at the event location
  The UI is built in code below so it's easy to restyle in one place.
───────────────────────────────────────────────────────────────────────────]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local gui = script.Parent

local Shared = RS:WaitForChild("Events")
local Config = require(Shared:WaitForChild("EventConfig"))
local Remotes = Shared:WaitForChild("EventRemotes")
local okHud, HUDConfig = pcall(function() return require(RS:WaitForChild("HUDConfig", 5)) end)

---------------------------------------------------------------- tiny UI helpers
local FONT, FONT_B = Enum.Font.Gotham, Enum.Font.GothamBold
local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = p return c end
local function stroke(p, col, t) local s = Instance.new("UIStroke") s.Color = col or Color3.new(1,1,1) s.Transparency = t or 0.7 s.Thickness = 1.5 s.Parent = p return s end
local function frame(parent, name, size, pos, col, tr)
	local f = Instance.new("Frame") f.Name = name f.Size = size f.Position = pos or UDim2.new() f.BackgroundColor3 = col or Color3.fromRGB(25, 30, 38)
	f.BackgroundTransparency = tr or 0.08 f.BorderSizePixel = 0 f.Parent = parent return f
end
local function label(parent, name, text, size, pos, font, color, xAlign)
	local t = Instance.new("TextLabel") t.Name = name t.Text = text or "" t.Size = size t.Position = pos or UDim2.new() t.BackgroundTransparency = 1
	t.Font = font or FONT t.TextColor3 = color or Color3.new(1,1,1) t.TextScaled = true t.TextWrapped = true
	t.TextXAlignment = xAlign or Enum.TextXAlignment.Left t.Parent = parent
	local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = 22 c.Parent = t
	return t
end
local function button(parent, name, text, size, pos, col)
	local b = Instance.new("TextButton") b.Name = name b.Text = text b.Size = size b.Position = pos b.BackgroundColor3 = col or Color3.fromRGB(60, 140, 90)
	b.Font = FONT_B b.TextColor3 = Color3.new(1,1,1) b.TextScaled = true b.AutoButtonColor = true b.BorderSizePixel = 0 b.Parent = parent corner(b, 8)
	local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = 18 c.Parent = b
	local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 6) pad.PaddingRight = UDim.new(0, 6) pad.PaddingTop = UDim.new(0, 4) pad.PaddingBottom = UDim.new(0, 4) pad.Parent = b
	return b
end
local function fmtTime2(s) return ("%d:%04.1f"):format(s // 60, s % 60) end
local function fmtTime(s) s = math.max(0, math.floor(s)) return ("%d:%02d"):format(s // 60, s % 60) end

---------------------------------------------------------------- banner
local banner = frame(gui, "Banner", UDim2.new(0, 440, 0, 128), UDim2.new(0.5, -220, 0, 12)) -- coins moved to the bottom, so the banner sits at the top
corner(banner, 14) stroke(banner, Color3.new(1,1,1), 0.75) banner.Visible = false
local sizeLimit = Instance.new("UISizeConstraint") sizeLimit.MaxSize = Vector2.new(440, 128) sizeLimit.Parent = banner
local strip = frame(banner, "RarityStrip", UDim2.new(0, 6, 1, -16), UDim2.new(0, 8, 0, 8), Color3.fromRGB(70,170,110), 0) corner(strip, 3)
local rarityTag = label(banner, "Rarity", "COMMON EVENT", UDim2.new(0.5, 0, 0, 18), UDim2.new(0, 22, 0, 4), FONT_B, Color3.fromRGB(140, 230, 170))
local title = label(banner, "Title", "Event", UDim2.new(1, -60, 0, 26), UDim2.new(0, 22, 0, 22), FONT_B)
local desc = label(banner, "Description", "", UDim2.new(1, -34, 0, 30), UDim2.new(0, 22, 0, 49), FONT, Color3.fromRGB(215, 222, 230))
local where = label(banner, "Location", "", UDim2.new(0.55, 0, 0, 18), UDim2.new(0, 22, 0, 82), FONT, Color3.fromRGB(255, 220, 120))
local timer = label(banner, "Countdown", "", UDim2.new(0.55, 0, 0, 18), UDim2.new(0, 22, 0, 102), FONT_B, Color3.new(1,1,1))
local goBtn = button(banner, "GoButton", "📍 Go there", UDim2.new(0, 110, 0, 30), UDim2.new(1, -236, 1, -40), Color3.fromRGB(60, 110, 190))
local joinBtn = button(banner, "JoinButton", "✋ Join", UDim2.new(0, 110, 0, 30), UDim2.new(1, -120, 1, -40))
local closeBtn = button(banner, "Close", "X", UDim2.new(0, 26, 0, 26), UDim2.new(1, -34, 0, 8), Color3.fromRGB(70, 75, 85))
-- TEXT-ONLY BANNER: just the event name + timer (+ small text buttons). No card, no long description,
-- so it stays short on phones. (Description / location / rarity labels are kept but hidden.)
do
	banner.BackgroundColor3 = Color3.fromRGB(18, 22, 28) banner.BackgroundTransparency = 0.12 -- dark card with a border
	for _, d in ipairs(banner:GetChildren()) do if d:IsA("UIStroke") then d.Enabled = true d.Color = Color3.fromRGB(0, 170, 100) d.Transparency = 0.1 d.Thickness = 2 end end
	banner.Size = UDim2.new(0, 320, 0, 74)
	banner.Position = UDim2.new(0.5, -160, 0, 8)
	sizeLimit.MaxSize = Vector2.new(320, 74)
	strip.Visible = false rarityTag.Visible = false desc.Visible = false where.Visible = false
	local function outline(t, size, color)
		t.TextScaled = false t.TextSize = size t.TextWrapped = false
		t.TextTruncate = Enum.TextTruncate.AtEnd
		t.TextXAlignment = Enum.TextXAlignment.Center
		t.TextStrokeTransparency = 0.2 t.TextStrokeColor3 = Color3.new(0, 0, 0)
		if color then t.TextColor3 = color end
	end
	outline(title, 22) title.Size = UDim2.new(1, -30, 0, 26) title.Position = UDim2.new(0, 15, 0, 0)
	outline(timer, 16) timer.Size = UDim2.new(1, 0, 0, 18) timer.Position = UDim2.new(0, 0, 0, 26)
	for _, btn in ipairs({ goBtn, joinBtn, closeBtn }) do
		btn.BackgroundTransparency = 1 btn.AutoButtonColor = false
		for _, d in ipairs(btn:GetChildren()) do if d:IsA("UIPadding") then d:Destroy() end end
		outline(btn, 16)
	end
	goBtn.TextColor3 = Color3.fromRGB(140, 200, 255)
	joinBtn.TextColor3 = Color3.fromRGB(140, 235, 165)
	closeBtn.TextColor3 = Color3.fromRGB(220, 220, 220) closeBtn.TextSize = 18 closeBtn.Text = "X" -- the X glyph shows as a box in this font
	closeBtn.Size = UDim2.new(0, 24, 0, 24) closeBtn.Position = UDim2.new(1, -22, 0, 1)
	goBtn.Size = UDim2.new(0, 100, 0, 24) joinBtn.Size = UDim2.new(0, 80, 0, 24)
	local function layoutButtons()
		if goBtn.Visible and joinBtn.Visible then
			goBtn.Position = UDim2.new(0.5, -100, 0, 46) joinBtn.Position = UDim2.new(0.5, 10, 0, 46)
		else
			goBtn.Position = UDim2.new(0.5, -50, 0, 46) joinBtn.Position = UDim2.new(0.5, -40, 0, 46)
		end
	end
	goBtn:GetPropertyChangedSignal("Visible"):Connect(layoutButtons)
	joinBtn:GetPropertyChangedSignal("Visible"):Connect(layoutButtons)
	layoutButtons()
end

---------------------------------------------------------------- pill
local pill = Instance.new("TextButton") pill.Name = "Pill" pill.Size = UDim2.new(0, 230, 0, 30) pill.Position = UDim2.new(0.5, -115, 0, 12)
pill.BackgroundColor3 = Color3.fromRGB(25, 30, 38) pill.BackgroundTransparency = 0.1 pill.Font = FONT_B pill.TextColor3 = Color3.new(1,1,1)
pill.TextScaled = true pill.Visible = false pill.AutoButtonColor = true pill.Parent = gui corner(pill, 15) stroke(pill, Color3.new(1,1,1), 0.75)
do local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = 16 c.Parent = pill local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 10) pad.PaddingRight = UDim.new(0, 10) pad.Parent = pill end

---------------------------------------------------------------- 🚪 Leave (always on screen while you're in an event)
-- The banner's Leave button tucks away with the banner, so joined players also get this small button at the
-- top of the screen. Leave any time, whatever your progress: your equipment unlocks right away.
local leaveMini = Instance.new("TextButton") leaveMini.Name = "LeaveEvent" leaveMini.AnchorPoint = Vector2.new(0.5, 0)
leaveMini.Position = UDim2.new(0.5, 0, 0, 12) leaveMini.Size = UDim2.fromOffset(150, 34) leaveMini.Visible = false
leaveMini.BackgroundColor3 = Color3.fromRGB(150, 45, 45) leaveMini.BackgroundTransparency = 0.05 leaveMini.Font = FONT_B leaveMini.TextScaled = true
leaveMini.TextColor3 = Color3.new(1, 1, 1) leaveMini.Text = "🚪 Leave event" leaveMini.AutoButtonColor = true leaveMini.ZIndex = 20 leaveMini.Parent = gui
corner(leaveMini, 17) stroke(leaveMini, Color3.fromRGB(255, 170, 170), 0.35)
do local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = 17 c.Parent = leaveMini local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 10) pad.PaddingRight = UDim.new(0, 10) pad.PaddingTop = UDim.new(0, 5) pad.PaddingBottom = UDim.new(0, 5) pad.Parent = leaveMini end

---------------------------------------------------------------- scoreboard
local board = frame(gui, "Scoreboard", UDim2.new(0, 210, 0, 190), UDim2.new(1, -222, 0, 64)) -- top-right, clear of the mobile jump button
corner(board, 12) stroke(board) board.Visible = false
local boardTitle = label(board, "Title", "🏁 Leaderboard", UDim2.new(1, -52, 0, 22), UDim2.new(0, 10, 0, 6), FONT_B, Color3.fromRGB(255, 220, 120))
local rows = {}
for i = 1, 5 do rows[i] = label(board, "Row" .. i, "", UDim2.new(1, -16, 0, 20), UDim2.new(0, 10, 0, 30 + (i - 1) * 22), FONT) end
local mine = label(board, "MyScore", "", UDim2.new(1, -16, 0, 20), UDim2.new(0, 10, 1, -28), FONT_B, Color3.fromRGB(140, 230, 170))
-- minimize / expand (tap-sized for phones); the board also shrinks to fit how many names it shows
local boardCollapsed = false
local boardMin = Instance.new("TextButton") boardMin.Name = "Minimize" boardMin.AnchorPoint = Vector2.new(1, 0)
boardMin.Position = UDim2.new(1, -5, 0, 4) boardMin.Size = UDim2.fromOffset(32, 26) boardMin.BackgroundColor3 = Color3.fromRGB(55, 62, 78)
boardMin.Text = "–" boardMin.Font = Enum.Font.GothamBlack boardMin.TextSize = 20 boardMin.TextColor3 = Color3.new(1, 1, 1) boardMin.ZIndex = 5
boardMin.Parent = board corner(boardMin, 8)
local boardRows = 5
local function boardLayout()
	for i = 1, 5 do rows[i].Visible = not boardCollapsed and i <= boardRows end
	mine.Visible = not boardCollapsed
	local h = boardCollapsed and 34 or (34 + boardRows * 22 + (mine.Text ~= "" and 26 or 4))
	board.Size = UDim2.new(0, 210, 0, h)
	boardMin.Text = boardCollapsed and "+" or "–"
end
boardMin.Activated:Connect(function() boardCollapsed = not boardCollapsed boardLayout() end)

---------------------------------------------------------------- results
local results = frame(gui, "Results", UDim2.new(0, 340, 0, 250), UDim2.new(0.5, -170, 0, 50)) -- top area: never over the Inventory hotbar
corner(results, 16) stroke(results, Color3.fromRGB(255, 220, 120), 0.4) results.Visible = false
local resTitle = label(results, "Title", "", UDim2.new(1, -24, 0, 30), UDim2.new(0, 12, 0, 10), FONT_B, Color3.new(1,1,1), Enum.TextXAlignment.Center)
local resPodium = label(results, "Podium", "", UDim2.new(1, -24, 0, 70), UDim2.new(0, 12, 0, 46), FONT, Color3.fromRGB(230, 235, 240), Enum.TextXAlignment.Center)
local resMine = label(results, "Mine", "", UDim2.new(1, -24, 0, 70), UDim2.new(0, 12, 0, 122), FONT_B, Color3.fromRGB(140, 230, 170), Enum.TextXAlignment.Center)
local resClose = button(results, "Close", "Nice!", UDim2.new(0, 120, 0, 32), UDim2.new(0.5, -60, 1, -44))
resClose.MouseButton1Click:Connect(function() results.Visible = false end)

---------------------------------------------------------------- toasts
local toastHolder = frame(gui, "Toasts", UDim2.new(0, 420, 0, 220), UDim2.new(0.5, -210, 0, 48), nil, 1)
local list = Instance.new("UIListLayout") list.VerticalAlignment = Enum.VerticalAlignment.Top list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.Padding = UDim.new(0, 6) list.SortOrder = Enum.SortOrder.LayoutOrder list.Parent = toastHolder
-- the event pill (current event / "Next event in …") sits BESIDE the coins at the bottom:
--  • PC: to the right of the coins, as a 2-line card (event name / timer)
--  • phones / tablets (or no room on the right): to the left of the coins, one line
local SEP = "  •  "
-- no background / border: just the text (outlined so it stays readable on any background)
pill.BackgroundTransparency = 1
for _, d in ipairs(pill:GetChildren()) do if d:IsA("UIStroke") then d.Enabled = false end end
pill.ChildAdded:Connect(function(d) if d:IsA("UIStroke") then d.Enabled = false end end)
pill.TextStrokeTransparency = 0.25
pill.TextStrokeColor3 = Color3.new(0, 0, 0)
pill.AutoButtonColor = false
pill.TextXAlignment = Enum.TextXAlignment.Left
local sideMode = "right"
pill:GetPropertyChangedSignal("Text"):Connect(function()
	if sideMode == "right" and pill.Text:find(SEP, 1, true) then pill.Text = pill.Text:gsub(SEP, "\n", 1) end
end)
task.spawn(function()
	while true do
		local s = gui:GetAttribute("UIScaleFactor") or 1
		local vp = workspace.CurrentCamera.ViewportSize
		local vw = vp.X / s
		local vh = (vp.Y - game:GetService("GuiService"):GetGuiInset().Y) / s
		local cg = player.PlayerGui:FindFirstChild("CoinsGui")
		local coins = cg and cg:FindFirstChild("CoinBar")
		if coins and coins.AbsoluteSize.X > 0 then
			local cx, cy = coins.AbsolutePosition.X / s, coins.AbsolutePosition.Y / s
			local cw, ch = coins.AbsoluteSize.X / s, coins.AbsoluteSize.Y / s
			local roomRight = vw - (cx + cw) - 20
			if cy < vh * 0.5 then
				-- coins at the TOP-RIGHT: event line right under them, right-aligned
				sideMode = "left"
				if pill.Text:find("\n", 1, true) then pill.Text = pill.Text:gsub("\n", SEP, 1) end
				pill.TextWrapped = false
				pill.TextXAlignment = Enum.TextXAlignment.Right
				pill.AutomaticSize = Enum.AutomaticSize.X
				pill.Size = UDim2.new(0, 0, 0, 26)
				pill.AnchorPoint = Vector2.new(1, 0)
				pill.Position = UDim2.fromOffset(math.floor(cx + cw), math.floor(cy + ch + 2))
				-- leaderboard goes under the coins + event line
				board.Position = UDim2.new(1, -222, 0, math.floor(cy + ch + 34))
			elseif roomRight >= 120 and ch > 50 then
				-- right of the stacked coins, same height
				sideMode = "right"
				pill.AutomaticSize = Enum.AutomaticSize.None
				pill.TextWrapped = true
				pill.Size = UDim2.fromOffset(math.min(170, roomRight), math.floor(ch))
				pill.AnchorPoint = Vector2.new(0, 1)
				pill.Position = UDim2.fromOffset(math.floor(cx + cw + 8), math.floor(cy + ch))
				if pill.Text:find(SEP, 1, true) then pill.Text = pill.Text:gsub(SEP, "\n", 1) end
			else
				-- left of the coins, one line, same row
				sideMode = "left"
				if pill.Text:find("\n", 1, true) then pill.Text = pill.Text:gsub("\n", SEP, 1) end
				pill.TextWrapped = false
				pill.AutomaticSize = Enum.AutomaticSize.X
				pill.Size = UDim2.new(0, 0, 0, math.floor(math.min(ch, 34)))
				pill.AnchorPoint = Vector2.new(1, 1)
				pill.Position = UDim2.fromOffset(math.floor(cx - 8), math.floor(cy + ch))
			end
		else
			pill.AnchorPoint = Vector2.new(1, 1)
			pill.Position = UDim2.fromOffset(math.floor(vw - 12), math.floor(vh - 12))
		end
		pill.BackgroundTransparency = 1
		task.wait(0.5)
	end
end)

-- keep the toasts above the Inventory hotbar on every device
task.spawn(function()
	while true do
		local hb = player.PlayerGui:FindFirstChild("HotbarGui")
		local bar = hb and hb:FindFirstChild("Hotbar")
		local s = gui:GetAttribute("UIScaleFactor") or 1
		local vh = (workspace.CurrentCamera.ViewportSize.Y - game:GetService("GuiService"):GetGuiInset().Y) / s
		local bottom = vh - 30
		if bar and bar.Visible and hb.Enabled then bottom = math.min(bottom, bar.AbsolutePosition.Y / s - 30) end
		local cg = player.PlayerGui:FindFirstChild("CoinsGui")
		local coins = cg and cg:FindFirstChild("CoinBar")
		if coins and coins.AbsolutePosition.X < workspace.CurrentCamera.ViewportSize.X * 0.5 + 220 * s then
			bottom = math.min(bottom, coins.AbsolutePosition.Y / s - 8) -- coins sit above the hotbar on phones
		end -- 30 = clear of the INVENTORY title above the hotbar
		if pill.Visible and pill.AbsoluteSize.X > 0 then
			local px = pill.AbsolutePosition.X / s
			local vw = workspace.CurrentCamera.ViewportSize.X / s
			if px < vw / 2 + 210 then bottom = math.min(bottom, pill.AbsolutePosition.Y / s - 6) end
		end
		-- toasts now sit at the TOP: just under the event banner when it is open, otherwise under the top edge
		local topY = 48
		if banner.Visible and banner.AbsoluteSize.Y > 0 then topY = math.floor((banner.AbsolutePosition.Y + banner.AbsoluteSize.Y) / s) + 8 end
		local vw = workspace.CurrentCamera.ViewportSize.X / s
		local w = math.min(420, vw - 24)
		-- keep the toasts clear of the top-right coins / event line
		if coins and coins.AbsoluteSize.X > 0 and coins.AbsolutePosition.Y / s < 200 then
			local left = coins.AbsolutePosition.X / s
			if pill.Visible and pill.AbsoluteSize.X > 0 then left = math.min(left, pill.AbsolutePosition.X / s) end
			local maxW = 2 * (left - vw / 2) - 16
			if maxW >= 260 then
				w = math.min(w, maxW)
			else
				local low = coins.AbsolutePosition.Y + coins.AbsoluteSize.Y
				if pill.Visible and pill.AbsoluteSize.Y > 0 then low = math.max(low, pill.AbsolutePosition.Y + pill.AbsoluteSize.Y) end
				if vw / 2 + w / 2 > left then topY = math.max(topY, math.floor(low / s) + 8) end
			end
		end
		toastHolder.Size = UDim2.new(0, w, 0, 220)
		toastHolder.Position = UDim2.new(0.5, -w / 2, 0, topY)
		task.wait(1)
	end
end)
local toastOrder, recentToasts = 0, {}
local MAX_TOASTS = 3
local function toast(msg)
	msg = tostring(msg)
	-- the same message twice within 2.5 s is shown once
	if recentToasts[msg] and os.clock() - recentToasts[msg] < 2.5 then return end
	recentToasts[msg] = os.clock()
	-- keep at most MAX_TOASTS on screen (the oldest one goes)
	local live = {}
	for _, c in ipairs(toastHolder:GetChildren()) do if c:IsA("Frame") then table.insert(live, c) end end
	table.sort(live, function(x, y) return x.LayoutOrder < y.LayoutOrder end)
	while #live >= MAX_TOASTS do table.remove(live, 1):Destroy() end
	toastOrder += 1
	local t = Instance.new("Frame") t.Name = "Toast" t.LayoutOrder = toastOrder t.Size = UDim2.new(1, 0, 0, 0) t.AutomaticSize = Enum.AutomaticSize.Y
	t.BackgroundColor3 = Color3.fromRGB(18, 22, 28) t.BackgroundTransparency = 0.08 t.Parent = toastHolder
	corner(t, 10)
	local tb = Instance.new("UIStroke") tb.Color = Color3.fromRGB(0, 170, 100) tb.Thickness = 2 tb.Transparency = 0.1 tb.ApplyStrokeMode = Enum.ApplyStrokeMode.Border tb.Parent = t
	local pad = Instance.new("UIPadding") pad.PaddingTop = UDim.new(0, 7) pad.PaddingBottom = UDim.new(0, 7) pad.PaddingLeft = UDim.new(0, 12) pad.PaddingRight = UDim.new(0, 12) pad.Parent = t
	local l = Instance.new("TextLabel") l.Name = "Text" l.BackgroundTransparency = 1 l.Size = UDim2.new(1, 0, 0, 0) l.AutomaticSize = Enum.AutomaticSize.Y
	l.Font = FONT_B l.TextSize = 17 l.TextScaled = false l.TextWrapped = true l.TextColor3 = Color3.new(1, 1, 1) l.Text = msg l.Parent = t
	task.delay(4.5, function()
		if not t.Parent then return end
		TweenService:Create(t, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		local tb2 = t:FindFirstChildOfClass("UIStroke") if tb2 then TweenService:Create(tb2, TweenInfo.new(0.4), { Transparency = 1 }):Play() end
		task.wait(0.45) t:Destroy()
	end)
end

---------------------------------------------------------------- map pin (MainHUD Map page)
local mapPin
local function setMapPin(loc, text)
	if mapPin then mapPin:Destroy() mapPin = nil end
	if not loc or not okHud or not HUDConfig.MapWorld then return end
	local hud = player:WaitForChild("PlayerGui"):FindFirstChild("MainHUD")
	local mapImage = hud and hud:FindFirstChild("MapImage", true)
	if not mapImage then return end
	-- same projection as the map photo (screen up = +X, screen right = +Z); sits on the zoomable canvas
	local W = HUDConfig.MapWorld
	local u = math.clamp((loc[3] - W.Left) / (W.Right - W.Left), 0.01, 0.99)
	local v = math.clamp((W.Top - loc[1]) / (W.Top - W.Bottom), 0.01, 0.99)
	mapImage = mapImage:FindFirstChild("Canvas") or mapImage
	mapPin = Instance.new("TextLabel")
	mapPin.Name = "EventPin" mapPin.Size = UDim2.fromOffset(34, 34) mapPin.AnchorPoint = Vector2.new(0.5, 0.5)
	mapPin.Position = UDim2.fromScale(u, v) mapPin.BackgroundColor3 = Color3.fromRGB(255, 200, 60) mapPin.ZIndex = 20
	mapPin.Text = text or "🎪" mapPin.TextScaled = true mapPin.Font = FONT_B corner(mapPin, 17) stroke(mapPin, Color3.new(1,1,1), 0)
	mapPin.Parent = mapImage
	TweenService:Create(mapPin, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = UDim2.fromOffset(42, 42) }):Play()
end

---------------------------------------------------------------- state handling
local state = { active = false }
local dismissed = false   -- player closed the banner for this event
local autoTucked = false  -- banner already tucked away for this event
local lastKey = nil

local function alertsOn() return player:GetAttribute("Setting_EventAlerts") ~= false end
local function boardOn() return player:GetAttribute("Setting_LeaderboardUpdates") ~= false end

local function phaseText()
	local left = (state.endsAt or os.time()) - os.time()
	if state.phase == "Announce" then return "⏳ Starts in " .. fmtTime(left) end
	if state.phase == "Active" then return "🔥 Ends in " .. fmtTime(left) end
	if state.phase == "Results" then return "🏁 Finished" end
	return ""
end

local function render()
	if not state.active then
		banner.Visible = false board.Visible = false
		setMapPin(nil)
		-- countdown to the next rotation event
		if state.nextAt then
			pill.Visible = true
			pill.Text = "🎪 Next event in " .. fmtTime((state.nextAt or os.time()) - os.time())
		else
			pill.Visible = false
		end
		return
	end
	local r = Config.Rarity[state.rarity or "Common"] or Config.Rarity.Common
	strip.BackgroundColor3 = r.Color
	rarityTag.Text = r.Label rarityTag.TextColor3 = r.Color:Lerp(Color3.new(1,1,1), 0.35)
	title.Text = (state.icon or "🎪") .. "  " .. (state.name or "Event")
	desc.Text = state.requirement and (state.description .. "  •  " .. state.requirement) or (state.description or "")
	where.Text = "📍 " .. (state.locationName or "Campus") .. ("   👥 %d"):format(state.players or 0)
	timer.Text = phaseText()
	local canJoin = state.phase ~= "Results" and not state.joined
	local canLeave = state.phase ~= "Results" and state.joined == true
	if not canLeave then joinBtn:SetAttribute("Armed", nil) end
	joinBtn.Visible = (canJoin and state.joinMode ~= "zone") or canLeave
	if canLeave then
		joinBtn.Text = joinBtn:GetAttribute("Armed") and "Sure? Tap" or "🚪 Leave"
		joinBtn.TextColor3 = Color3.fromRGB(255, 140, 140)
	else
		joinBtn.Text = "✋ Join"
		joinBtn.TextColor3 = Color3.fromRGB(140, 235, 165)
	end
	goBtn.Visible = state.phase ~= "Results" and state.location ~= nil
	-- once you joined and the event is running, tuck the banner away (1 s on phones/tablets, 3 s on PC; the pill stays)
	if state.joined and state.phase == "Active" and not autoTucked then
		autoTucked = true
		local touch = game:GetService("UserInputService").TouchEnabled
		task.delay(touch and 1 or 3, function() dismissed = true render() end)
	end
	banner.Visible = (alertsOn() or state.joined == true) and not dismissed and state.phase ~= "Results" -- joined players always get their banner (with Leave)
	pill.Visible = not banner.Visible and state.phase ~= "Results"
	-- 🚪 small Leave button whenever you're in the event and the banner (with its own Leave) is tucked away
	if not canLeave then leaveMini:SetAttribute("Armed", nil) end
	leaveMini.Visible = canLeave and not banner.Visible
	leaveMini.Text = leaveMini:GetAttribute("Armed") and "Tap again to leave" or "🚪 Leave event"
	leaveMini.Size = UDim2.fromOffset(leaveMini:GetAttribute("Armed") and 190 or 150, 34)
	pill.Text = (state.icon or "🎪") .. " " .. (state.name or "") .. "  •  " .. phaseText()
	-- scoreboard: during Active, if you joined or leaderboard updates are on
	-- (Intramurals uses this board too now: 🏆 Intramural points, earned by playing any sports game)
	local showBoard = state.phase == "Active" and state.id ~= "EscapeSchool" and (state.joined or boardOn()) and #(state.top or {}) > 0
	board.Visible = showBoard
	if showBoard then
		boardTitle.Text = "🏁 " .. (state.scoreLabel or "Score")
		for i = 1, 5 do
			local e = state.top[i]
			rows[i].Text = e and (("%d. %s — %s"):format(i, e.name, state.scoreFormat == "time" and fmtTime2(e.score) or tostring(e.score))) or ""
		end
		mine.Text = state.joined and ("You: " .. (state.scoreFormat == "time" and ((state.myScore or 0) > 0 and fmtTime2(state.myScore) or "—") or tostring(state.myScore or 0))) or ""
		boardRows = math.clamp(#state.top, 1, 5)
		boardLayout()
	end
	setMapPin(state.phase ~= "Results" and state.location or nil, state.icon)
end

Remotes.EventState.OnClientEvent:Connect(function(st)
	local key = st.active and (st.id .. tostring(st.phase == "Announce")) or nil
	if st.active and st.id ~= (state.id) then dismissed = false autoTucked = false end
	-- new event announced: chime + toast
	if st.active and st.phase == "Announce" and key ~= lastKey and alertsOn() then
		toast(("%s %s is starting at %s!"):format(st.icon or "🎪", st.name, st.locationName or "campus"))
	end
	lastKey = key
	state = st
	render()
end)

Remotes.EventToast.OnClientEvent:Connect(toast)

Remotes.EventResults.OnClientEvent:Connect(function(r)
	if not r.joined and not alertsOn() then return end
	resTitle.Text = (r.icon or "🏁") .. " " .. r.name .. (r.reason == "stopped" and " stopped" or " — Results")
	local lines = {}
	for i, p in ipairs(r.podium or {}) do table.insert(lines, ({ "🥇", "🥈", "🥉" })[i] .. " " .. p.name .. " (" .. p.score .. ")") end
	if r.teamWinner then table.insert(lines, 1, r.teamWinner) end
	resPodium.Text = #lines > 0 and table.concat(lines, "\n") or "No winners this time"
	if r.joined and r.amount and r.amount > 0 then
		resMine.Text = ("You earned +%d %s\n%s"):format(r.amount, r.currency or "Tokens", table.concat(r.lines or {}, " • "))
	elseif r.joined then
		resMine.Text = "Thanks for joining!"
	else
		resMine.Text = "Join the next event to earn tokens!"
	end
	results.Visible = true
	task.delay(10, function() results.Visible = false end)
end)

---------------------------------------------------------------- buttons
local function act(action)
	local ok, res = pcall(function() return Remotes.EventAction:InvokeServer(action) end)
	if ok and res and res.msg then toast(res.msg) end
	return ok and res
end
joinBtn.MouseButton1Click:Connect(function()
	if state.joined then
		-- leaving needs a second tap within 3 seconds (so nobody leaves by accident)
		if joinBtn:GetAttribute("Armed") then
			joinBtn:SetAttribute("Armed", nil)
			act("leave")
		else
			joinBtn:SetAttribute("Armed", true)
			render()
			task.delay(3, function() if joinBtn:GetAttribute("Armed") then joinBtn:SetAttribute("Armed", nil) render() end end)
		end
		return
	end
	act("join")
end)
goBtn.MouseButton1Click:Connect(function() act("goto") end)
-- same two-tap confirm as the banner's Leave
leaveMini.MouseButton1Click:Connect(function()
	if not state.joined then return end
	if leaveMini:GetAttribute("Armed") then
		leaveMini:SetAttribute("Armed", nil)
		act("leave")
		render()
	else
		leaveMini:SetAttribute("Armed", true)
		render()
		task.delay(3, function() if leaveMini:GetAttribute("Armed") then leaveMini:SetAttribute("Armed", nil) render() end end)
	end
end)
closeBtn.MouseButton1Click:Connect(function() dismissed = true render() end)
pill.MouseButton1Click:Connect(function() dismissed = false
	if not alertsOn() then toast("Turn on Event Alerts in Settings to see the full banner") end render() end)
player:GetAttributeChangedSignal("Setting_EventAlerts"):Connect(render)
player:GetAttributeChangedSignal("Setting_LeaderboardUpdates"):Connect(render)

-- countdown tick
task.spawn(function()
	while true do
		task.wait(1)
		if state.active then
			timer.Text = phaseText()
			if pill.Visible then pill.Text = (state.icon or "🎪") .. " " .. (state.name or "") .. "  •  " .. phaseText() end
		elseif state.nextAt and pill.Visible then
			local left = state.nextAt - os.time()
			pill.Text = left > 0 and ("🎪 Next event in " .. fmtTime(left)) or "🎪 An event is starting soon…"
		end
	end
end)

-- first sync (in case we joined mid-event)
task.spawn(function()
	local ok, res = pcall(function() return Remotes.EventAction:InvokeServer("sync") end)
	if ok and res and res.state then state = res.state render() end
end)
