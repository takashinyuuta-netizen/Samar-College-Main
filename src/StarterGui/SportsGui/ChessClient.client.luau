--[[ ChessClient — the ♟️ chess board on screen for the library chess tables.
  Players: tap one of your pieces → legal squares light up → tap a square to move (the server checks it).
  Shows both chess clocks, captured pieces, the move list, check, promotion picker and Resign.
  Spectators (sitting on a blue chair or pressing Watch) see the same board, read-only. ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local Sports = RS:WaitForChild("Sports")
local Action = Sports:WaitForChild("SportsAction")
local Event = Sports:WaitForChild("SportsEvent")
local Pieces = require(Sports:WaitForChild("ChessPieces"))
local gui = script.Parent

local DARK, GOLD, WHITE = Color3.fromRGB(22, 27, 36), Color3.fromRGB(255, 210, 90), Color3.new(1, 1, 1)
local LIGHTSQ, DARKSQ = Color3.fromRGB(240, 217, 181), Color3.fromRGB(181, 136, 99)
local function new(class, props, parent) local o = Instance.new(class) for k, v in pairs(props or {}) do o[k] = v end o.Parent = parent return o end
local function corner(p, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, p) end
local function label(parent, props)
	local t = new("TextLabel", { BackgroundTransparency = 1, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextScaled = true }, parent)
	for k, v in pairs(props) do if k ~= "MaxSize" then t[k] = v end end
	new("UITextSizeConstraint", { MaxTextSize = props.MaxSize or 18 }, t)
	return t
end
local function button(parent, text, size, pos, color)
	local b = new("TextButton", { Text = text, Size = size, Position = pos, BackgroundColor3 = color, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextScaled = true }, parent)
	corner(b, 8) new("UITextSizeConstraint", { MaxTextSize = 15 }, b)
	return b
end
local function call(action, data)
	local ok, res = pcall(function() return Action:InvokeServer(action, data) end)
	return ok and res or { ok = false }
end
local function sfx(id, vol, pitch)
	local s = new("Sound", { SoundId = id, Volume = vol or 0.5, PlaybackSpeed = pitch or 1 }, gui)
	s:Play() game:GetService("Debris"):AddItem(s, 3)
end

---------------------------------------------------------------- layout
local SQ = 44
local panel = new("Frame", { Name = "ChessPanel", Size = UDim2.fromOffset(SQ * 8 + 24, SQ * 8 + 170), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 10),
	BackgroundColor3 = DARK, BackgroundTransparency = 0.05, Visible = false }, gui)
corner(panel, 14) new("UIStroke", { Color = GOLD, Thickness = 2, Transparency = 0.4 }, panel)
local title = label(panel, { Size = UDim2.new(1, -60, 0, 20), Position = UDim2.fromOffset(12, 6), TextColor3 = GOLD, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, MaxSize = 16 })
local hideBtn = button(panel, "—", UDim2.fromOffset(34, 22), UDim2.new(1, -44, 0, 5), Color3.fromRGB(70, 75, 90))

local function playerBar(y)
	local f = new("Frame", { Size = UDim2.new(1, -24, 0, 34), Position = UDim2.fromOffset(12, y), BackgroundColor3 = Color3.fromRGB(34, 40, 52) }, panel)
	corner(f, 8)
	local dot = new("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(8, 9), BackgroundColor3 = WHITE }, f) corner(dot, 8)
	local name = label(f, { Size = UDim2.new(1, -140, 0, 16), Position = UDim2.fromOffset(30, 3), TextXAlignment = Enum.TextXAlignment.Left, MaxSize = 15 })
	local caps = label(f, { Size = UDim2.new(1, -140, 0, 12), Position = UDim2.fromOffset(30, 19), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(170, 180, 195), MaxSize = 12 })
	local clockBg = new("Frame", { Size = UDim2.fromOffset(96, 28), Position = UDim2.new(1, -100, 0, 3), BackgroundColor3 = Color3.fromRGB(50, 56, 70) }, f) corner(clockBg, 6)
	local clock = label(clockBg, { Size = UDim2.fromScale(1, 1), Font = Enum.Font.Arcade, TextColor3 = WHITE, MaxSize = 22, Text = "5:00" })
	return { frame = f, dot = dot, name = name, caps = caps, clock = clock, clockBg = clockBg }
end
local topBar = playerBar(30)
local boardFrame = new("Frame", { Size = UDim2.fromOffset(SQ * 8, SQ * 8), Position = UDim2.fromOffset(12, 70), BackgroundColor3 = Color3.fromRGB(90, 60, 40) }, panel)
local bottomBar = playerBar(70 + SQ * 8 + 6)
local status = label(panel, { Size = UDim2.new(1, -24, 0, 18), Position = UDim2.fromOffset(12, 70 + SQ * 8 + 44), MaxSize = 15, Text = "" })
local logL = label(panel, { Size = UDim2.new(1, -120, 0, 30), Position = UDim2.fromOffset(12, 70 + SQ * 8 + 64), Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(175, 185, 200), MaxSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top })
local resignBtn = button(panel, "🏳️ Resign", UDim2.fromOffset(96, 28), UDim2.new(1, -108, 0, 70 + SQ * 8 + 64), Color3.fromRGB(150, 60, 60))

-- reopen button when hidden
local reopen = button(gui, "♟️ Board", UDim2.fromOffset(100, 34), UDim2.new(1, -114, 0.5, -17), Color3.fromRGB(70, 90, 150))
reopen.Name = "ChessReopen" reopen.Visible = false

-- squares
local squares = {} -- display slot (row, col) -> { btn, vp, dot, ring, piece }
for row = 0, 7 do
	for col = 0, 7 do
		local b = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(SQ, SQ), Position = UDim2.fromOffset(col * SQ, row * SQ), BorderSizePixel = 0 }, boardFrame)
		local vp = new("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(165, 160, 150), LightColor = Color3.fromRGB(255, 250, 240), LightDirection = Vector3.new(-0.6, -1, -0.8), ZIndex = 2 }, b)
		local cam = new("Camera", { FieldOfView = 26 }, vp)
		cam.CFrame = CFrame.lookAt(Vector3.new(0, 2.6, 3.6), Vector3.new(0, 0.72, 0))
		vp.CurrentCamera = cam
		local dot = new("Frame", { Size = UDim2.fromScale(0.3, 0.3), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(30, 30, 30), BackgroundTransparency = 0.55, Visible = false, ZIndex = 3 }, b) corner(dot, 99)
		local ring = new("Frame", { Size = UDim2.fromScale(0.92, 0.92), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false, ZIndex = 3 }, b)
		corner(ring, 99) new("UIStroke", { Color = Color3.fromRGB(30, 30, 30), Thickness = 4, Transparency = 0.45 }, ring)
		local coordL
		if col == 0 then coordL = label(b, { Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(2, 1), MaxSize = 11, ZIndex = 4, TextColor3 = Color3.fromRGB(90, 60, 40) }) end
		local fileL
		if row == 7 then fileL = label(b, { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -12, 1, -13), MaxSize = 11, ZIndex = 4, TextColor3 = Color3.fromRGB(90, 60, 40) }) end
		squares[row * 8 + col] = { btn = b, vp = vp, dot = dot, ring = ring, piece = ".", rankL = coordL, fileL = fileL }
	end
end

-- promotion picker
local promo = new("Frame", { Size = UDim2.fromOffset(SQ * 4 + 30, SQ + 40), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = DARK, Visible = false, ZIndex = 10 }, boardFrame)
corner(promo, 10) new("UIStroke", { Color = GOLD, Thickness = 2 }, promo)
label(promo, { Text = "Promote to:", Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 4), MaxSize = 15, ZIndex = 11 })
local promoButtons = {}

---------------------------------------------------------------- state
local st = nil           -- last chess payload for the board I'm looking at
local courtId = nil
local myColor = nil      -- "w" / "b" / nil (spectator)
local hidden = false
local selected = nil
local legalFrom = {}
local clockAt = 0
local resignArmed = false

local function slotToIdx(row, col)
	if myColor == "b" then return row * 8 + (8 - col) end         -- black at the bottom
	return (7 - row) * 8 + col + 1                                -- white at the bottom
end
local function idxToSlot(i)
	local f, r = (i - 1) % 8 + 1, (i - 1) // 8 + 1
	if myColor == "b" then return (r - 1) * 8 + (8 - f) end
	return (8 - r) * 8 + (f - 1)
end

local function setPiece(sq, p)
	if sq.piece == p then return end
	sq.piece = p
	for _, c in ipairs(sq.vp:GetChildren()) do if c:IsA("Model") then c:Destroy() end end
	if p == "." then return end
	local white = p == p:upper()
	local m = Pieces.build(p:upper(), white, 1, true)
	m:PivotTo(CFrame.Angles(0, math.rad(white and 90 or -90), 0))
	m.Parent = sq.vp
end

local function fmt(t) t = math.max(0, math.ceil(t)) return ("%d:%02d"):format(t // 60, t % 60) end
local VALUE = { P = 1, N = 3, B = 3, R = 5, Q = 9 }
local function capsText(list)
	local icons = { P = "♟", N = "♞", B = "♝", R = "♜", Q = "♛" }
	local pts, n = 0, {}
	for _, c in ipairs(list or {}) do local t = c:upper() pts += VALUE[t] or 0 n[t] = (n[t] or 0) + 1 end
	local parts = {}
	for _, t in ipairs({ "Q", "R", "B", "N", "P" }) do if n[t] then table.insert(parts, ({ Q = "Queen", R = "Rook", B = "Bishop", N = "Knight", P = "Pawn" })[t] .. (n[t] > 1 and (" x" .. n[t]) or "")) end end
	return #parts > 0 and ("Took: " .. table.concat(parts, ", ") .. "  (+" .. pts .. ")") or "No captures yet"
end

local function paint()
	if not st then return end
	local board = st.board
	for slot, sq in pairs(squares) do
		local row, col = slot // 8, slot % 8
		local i = slotToIdx(row, col)
		local f, r = (i - 1) % 8 + 1, (i - 1) // 8 + 1
		local base = (f + r) % 2 == 0 and DARKSQ or LIGHTSQ
		if st.last and (st.last.from == i or st.last.to == i) then base = base:Lerp(Color3.fromRGB(235, 225, 80), 0.45) end
		if selected == i then base = Color3.fromRGB(120, 190, 110) end
		if st.check and st.checkSq == i then base = Color3.fromRGB(230, 80, 70) end
		sq.btn.BackgroundColor3 = base
		setPiece(sq, board:sub(i, i))
		local target = selected and legalFrom[selected] and legalFrom[selected][i]
		sq.dot.Visible = target ~= nil and board:sub(i, i) == "."
		sq.ring.Visible = target ~= nil and board:sub(i, i) ~= "."
		if sq.rankL then sq.rankL.Text = tostring(r) end
		if sq.fileL then sq.fileL.Text = string.char(96 + f) end
	end
end

local function bars()
	if not st then return end
	local bottomColor = myColor or "w"
	local function fill(bar, color)
		local who = color == "w" and st.white or st.black
		bar.dot.BackgroundColor3 = color == "w" and Color3.fromRGB(245, 240, 230) or Color3.fromRGB(35, 35, 40)
		bar.name.Text = (who and who.name or "—") .. (who and who.userId == player.UserId and "  (you)" or "")
		bar.caps.Text = capsText(st.captured and st.captured[color])
		local running = not st.over and st.turn == color
		bar.clockBg.BackgroundColor3 = running and Color3.fromRGB(60, 140, 80) or Color3.fromRGB(50, 56, 70)
	end
	fill(bottomBar, bottomColor)
	fill(topBar, bottomColor == "w" and "b" or "w")
end

local function setStatus()
	if not st then return end
	if st.over then status.Text = st.status or "Game over" status.TextColor3 = GOLD return end
	local myTurn = myColor and st.turn == myColor
	if st.check then status.Text = myTurn and "⚠️ CHECK! Save your king" or "⚠️ Check!" status.TextColor3 = Color3.fromRGB(255, 120, 110)
	elseif myColor then status.Text = myTurn and "✅ Your move" or "… Opponent is thinking" status.TextColor3 = myTurn and Color3.fromRGB(130, 230, 150) or Color3.fromRGB(200, 210, 220)
	else status.Text = (st.turn == "w" and "⚪ White" or "⚫ Black") .. " to move" status.TextColor3 = WHITE end
end

local function render()
	if not st then panel.Visible = false reopen.Visible = false return end
	title.Text = (myColor and "♟️ " or "📺 Watching • ♟️ ") .. (st.name or "Chess")
	legalFrom = {}
	if myColor and st.turn == myColor and not st.over then
		for _, k in ipairs(st.legal or {}) do
			local a, b, pr = k:match("^(%d+)%-(%d+)%-?(%a?)$")
			a, b = tonumber(a), tonumber(b)
			legalFrom[a] = legalFrom[a] or {}
			legalFrom[a][b] = legalFrom[a][b] or {}
			if pr ~= "" then table.insert(legalFrom[a][b], pr) end
		end
	end
	if selected and not legalFrom[selected] then selected = nil end
	resignBtn.Visible = myColor ~= nil and not st.over
	logL.Text = table.concat(st.log or {}, "  ")
	paint() bars() setStatus()
	panel.Visible = not hidden
	reopen.Visible = hidden
end

local function sendMove(from, to, pr)
	selected = nil promo.Visible = false
	local res = call("move", { court = courtId, from = from, to = to, promo = pr })
	if not res.ok and res.msg then status.Text = res.msg status.TextColor3 = Color3.fromRGB(255, 160, 120) end
	paint()
end

local function showPromo(from, to, options)
	for _, b in ipairs(promoButtons) do b:Destroy() end
	promoButtons = {}
	for k, pr in ipairs({ "Q", "R", "B", "N" }) do
		local b = new("TextButton", { Text = "", Size = UDim2.fromOffset(SQ, SQ), Position = UDim2.fromOffset(15 + (k - 1) * SQ, 30), BackgroundColor3 = k % 2 == 0 and DARKSQ or LIGHTSQ, ZIndex = 11 }, promo)
		corner(b, 6)
		local vp = new("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(165, 160, 150), ZIndex = 12 }, b)
		local cam = new("Camera", { FieldOfView = 26, CFrame = CFrame.lookAt(Vector3.new(0, 2.6, 3.6), Vector3.new(0, 0.72, 0)) }, vp) vp.CurrentCamera = cam
		local m = Pieces.build(pr, myColor == "w", 1, true) m:PivotTo(CFrame.Angles(0, math.rad(myColor == "w" and 90 or -90), 0)) m.Parent = vp
		b.MouseButton1Click:Connect(function() sendMove(from, to, pr) end)
		table.insert(promoButtons, b)
	end
	promo.Visible = true
end

for slot, sq in pairs(squares) do
	sq.btn.MouseButton1Click:Connect(function()
		if not st or st.over or not myColor or st.turn ~= myColor then return end
		local i = slotToIdx(slot // 8, slot % 8)
		if selected and legalFrom[selected] and legalFrom[selected][i] then
			local promos = legalFrom[selected][i]
			if #promos > 0 then showPromo(selected, i, promos) return end
			return sendMove(selected, i)
		end
		if legalFrom[i] then selected = i sfx("rbxasset://sounds/clickfast.wav", 0.3, 1.6) else selected = nil end
		promo.Visible = false
		paint()
	end)
end

hideBtn.MouseButton1Click:Connect(function() hidden = true render() end)
reopen.MouseButton1Click:Connect(function() hidden = false render() end)
resignBtn.MouseButton1Click:Connect(function()
	if not resignArmed then
		resignArmed = true resignBtn.Text = "Sure? Tap again"
		task.delay(3, function() resignArmed = false resignBtn.Text = "🏳️ Resign" end)
		return
	end
	resignArmed = false resignBtn.Text = "🏳️ Resign"
	call("resign", { court = courtId })
end)

-- clocks tick locally between server updates
task.spawn(function()
	while true do
		task.wait(0.2)
		if st and panel.Visible and st.clock then
			local el = os.clock() - clockAt
			local w, b = st.clock.w, st.clock.b
			if not st.over then if st.turn == "w" then w -= el else b -= el end end
			local bottomColor = myColor or "w"
			bottomBar.clock.Text = fmt(bottomColor == "w" and w or b)
			topBar.clock.Text = fmt(bottomColor == "w" and b or w)
			local mine = myColor == "w" and w or (myColor == "b" and b or 999)
			bottomBar.clock.TextColor3 = (myColor and mine < 30) and Color3.fromRGB(255, 110, 100) or WHITE
		end
	end
end)

---------------------------------------------------------------- server updates
local function watchingId() return player:GetAttribute("SC_Watching") end
Event.OnClientEvent:Connect(function(d)
	if type(d) ~= "table" or d.t ~= "chess" then return end
	local me = player.UserId
	local amPlayer = (d.white and d.white.userId == me) or (d.black and d.black.userId == me)
	local relevant = amPlayer or watchingId() == d.court or courtId == d.court
	if not relevant then return end
	if d.reset or (not d.board) then
		if courtId == d.court then st = nil courtId = nil myColor = nil selected = nil render() end
		return
	end
	if amPlayer and courtId ~= d.court then hidden = false end
	courtId = d.court
	myColor = amPlayer and ((d.white and d.white.userId == me) and "w" or "b") or nil
	local prevMoves = st and st.log and #st.log or 0
	st = d
	clockAt = os.clock()
	if d.moved then sfx(d.cap and "rbxasset://sounds/swordslash.wav" or "rbxasset://sounds/clickfast.wav", d.cap and 0.35 or 0.6, d.cap and 1.6 or 0.9) end
	if d.check and not d.over then sfx("rbxasset://sounds/electronicpingshort.wav", 0.4, 1.2) end
	render()
	if d.over then
		task.delay(8, function() if st == d then st = nil courtId = nil myColor = nil render() end end)
	end
end)

-- started watching a chess table: ask for the current position
player:GetAttributeChangedSignal("SC_Watching"):Connect(function()
	local id = watchingId()
	if id and tostring(id):find("^Chess") then
		call("chess", { court = id })
	elseif not myColor and courtId then
		st = nil courtId = nil render()
	end
end)
