--[[ GuessTheDrawing (Common event, open to all levels) ──────────────────────
  • Held in a RANDOM CLASSROOM that has a whiteboard (WhiteboardTV). The classroom's whiteboard
    becomes the game board: big drawing canvas in the middle, "who's drawing" + hint/timer panels
    beside it, a live GUESSES feed on the right board and a LEADERBOARD on the left board.
    Students sit at the class desks to play. (Falls back to the old open-area board if no room.)
  • EVERYONE can watch: the board in the room updates for all, and players who didn't join get a
    small "📺 Watch" viewer on screen (drawing + hint + guesses, no guessing).
  • Rounds: one participant draws a secret word (only the drawer receives it), the
    others type guesses. The drawer rotates every round.
  • Strokes: drawer → server (validated + rate limited) → EVERY player (the public board
    shows the drawing to spectators too). Points are normalized 0..1 on the canvas.
  • Guesses: checked on the server; wrong guesses are filtered with TextService before
    anyone else sees them. Correct = GuessPoints + time bonus; drawer gets DrawerPoints
    for each correct guesser. Words come from ServerScriptService.Events.DrawingWords.
  • SAFETY (drawings are not checked by Roblox, so the game is 16+):
      🚫 Hide vote — any player who isn't drawing can vote; 2 votes (or 1 if only one other player
         is here) clear the board at once, end the round and stop that player from drawing again in
         this server. An automatic report ("Inappropriate drawing") goes to the admins.
      🧹 Admins can clear the board from the admin panel (M.AdminClear).
  • SOLO / few players: if fewer than MinPlayers join (e.g. only you), the 🤖 Art Bot draws real pictures
    (DrawingBotArt) stroke by stroke and you guess them; extra letters are revealed over time. Works in the
    live game, not only in Studio.
───────────────────────────────────────────────────────────────────────────]]
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local Words = require(script.Parent.Parent:WaitForChild("DrawingWords"))
local BotArt = require(script.Parent.Parent:WaitForChild("DrawingBotArt"))
local SOLO_ROUNDS = 4

local M = {}
M.DrawBanned = {} -- [UserId] = true: can't draw again in this server (drawing was hidden)
M.Active = nil    -- ctx of the running Guess the Drawing (for the admin panel)
local HIDE_VOTES = 2
local function reports()
	local ok, mod = pcall(function() return require(game:GetService("ServerScriptService"):WaitForChild("PlayerReports", 5)) end)
	return ok and mod or nil
end
local FALLBACK = { pos = Vector3.new(125, 3.4, 15), name = "Courtyard" }
local PALETTE = 8 -- number of colors the client offers (validated here)

local function pickArea()
	local valid = {}
	for _, s in ipairs(CollectionService:GetTagged("EventOpenArea")) do if s:IsA("BasePart") and s:IsDescendantOf(workspace) then table.insert(valid, s) end end
	if #valid == 0 then return FALLBACK.pos, FALLBACK.name end
	local s = valid[math.random(#valid)]
	return s.Position, s:GetAttribute("AreaName") or s.Name
end

local function part(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part") p.Name = name p.Size = size p.CFrame = cf p.Color = color p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = parent return p
end

local function normalize(s) return (string.lower(s):gsub("[^%a]", "")) end

-- one letter different / missing = "close"
local function isClose(a, b)
	if math.abs(#a - #b) > 1 or #a < 3 then return false end
	local i, j, diff = 1, 1, 0
	while i <= #a and j <= #b do
		if a:sub(i, i) ~= b:sub(j, j) then
			diff += 1
			if diff > 1 then return false end
			if #a > #b then i += 1 elseif #b > #a then j += 1 else i += 1 j += 1 end
		else i += 1 j += 1 end
	end
	return diff + (#a - i + 1) + (#b - j + 1) <= 1
end

local function filtered(text, player)
	local ok, res = pcall(function()
		local f = TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat)
		return f:GetNonChatStringForBroadcastAsync()
	end)
	return ok and res or nil -- if filtering fails the guess is simply not shown
end

---------------------------------------------------------------- classroom whiteboard
-- rooms with a WhiteboardTV (classroom front board): { room model, label, whiteboard model, inside position }
local function classroomBoards()
	local list = {}
	for _, a in ipairs(CollectionService:GetTagged("QuizBeeRoom")) do
		local r = a:FindFirstChild("Room") and a.Room.Value
		local inside = a:GetAttribute("Inside")
		if r and inside and r:IsDescendantOf(workspace) and not r:GetAttribute("HostedBy") then -- skip rooms players are hosting
			for _, d in ipairs(r:GetDescendants()) do
				if d:IsA("Model") and d.Name == "WhiteboardTV" and d:FindFirstChild("TV") and d.TV:FindFirstChild("Body") then
					local label = (a:GetAttribute("RoomName") or r.Name):match("^(.-) –") or a:GetAttribute("RoomName") or r.Name
					table.insert(list, { room = r, label = label, wb = d, inside = inside, door = a.Position })
					break
				end
			end
		end
	end
	return list
end

local function sgui(p, ppS)
	local g = Instance.new("SurfaceGui") g.Face = Enum.NormalId.Front g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = ppS or 40 g.LightInfluence = 0 g.MaxDistance = 140 g.Parent = p
	return g
end
local function tlabel(parent, name, size, pos, text, color, font, align)
	local t = Instance.new("TextLabel") t.Name = name t.Size = size t.Position = pos t.BackgroundTransparency = 1 t.Text = text or ""
	t.TextColor3 = color or Color3.new(1, 1, 1) t.Font = font or Enum.Font.GothamBold t.TextScaled = true t.TextWrapped = true
	t.TextXAlignment = align or Enum.TextXAlignment.Center t.Parent = parent
	return t
end

-- turns the classroom's whiteboard into the game board. Returns the board refs.
local function buildClassroomBoard(ctx, B)
	local body = B.wb.TV.Body
	-- the side of the board that faces the room
	local toRoom = B.inside - body.Position
	local n = body.CFrame.LookVector
	if toRoom:Dot(n) < 0 then n = -n end
	n = Vector3.new(n.X, 0, n.Z).Unit
	local up = Vector3.yAxis
	local right = up:Cross(-n) -- (+x = the students' LEFT side of the board)
	local y = body.Position.Y - 0.2
	local base = Vector3.new(body.Position.X, y, body.Position.Z) + n * 0.45
	local function at(x, yy) return CFrame.fromMatrix(base + right * x + up * yy, right, up, -n) end -- Front face looks at the room
	local f = ctx.Folder
	local DECO = { CanCollide = false, CastShadow = false, CanQuery = false, CanTouch = false }
	-- canvas (square) in the middle
	local frameP = part(f, "CanvasFrame", Vector3.new(8.3, 8.3, 0.12), at(0, 0) * CFrame.new(0, 0, 0.06), Color3.fromRGB(230, 110, 180), Enum.Material.SmoothPlastic, DECO)
	local canvas = part(f, "Canvas", Vector3.new(7.8, 7.8, 0.1), at(0, 0) * CFrame.new(0, 0, -0.02), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, DECO)
	local cg = sgui(canvas, 40) cg.Name = "CanvasGui"
	local strokes = Instance.new("Frame") strokes.Name = "Strokes" strokes.Size = UDim2.fromScale(1, 1) strokes.BackgroundTransparency = 1 strokes.ClipsDescendants = true strokes.Parent = cg
	-- left of canvas: who's drawing
	local lp = part(f, "DrawerPanel", Vector3.new(2.9, 7.8, 0.1), at(5.5, 0), Color3.fromRGB(28, 32, 44), Enum.Material.SmoothPlastic, DECO)
	local lg = sgui(lp, 50)
	tlabel(lg, "Title", UDim2.fromScale(0.9, 0.12), UDim2.fromScale(0.05, 0.03), "🎨 GUESS\nTHE DRAWING", Color3.fromRGB(255, 150, 210), Enum.Font.FredokaOne)
	local drawerName = tlabel(lg, "Drawer", UDim2.fromScale(0.9, 0.3), UDim2.fromScale(0.05, 0.2), "Waiting for\nplayers…", Color3.new(1, 1, 1), Enum.Font.GothamBlack)
	local roundLbl = tlabel(lg, "Round", UDim2.fromScale(0.9, 0.08), UDim2.fromScale(0.05, 0.54), "", Color3.fromRGB(255, 220, 120))
	tlabel(lg, "How", UDim2.fromScale(0.9, 0.3), UDim2.fromScale(0.05, 0.66), "Join from the\nevent banner\nto guess!\n\n📺 Everyone\ncan watch", Color3.fromRGB(190, 200, 215), Enum.Font.Gotham)
	-- right of canvas: hint + timer
	local rp = part(f, "HintPanel", Vector3.new(2.9, 7.8, 0.1), at(-5.5, 0), Color3.fromRGB(28, 32, 44), Enum.Material.SmoothPlastic, DECO)
	local rg = sgui(rp, 50)
	tlabel(rg, "HintTitle", UDim2.fromScale(0.9, 0.07), UDim2.fromScale(0.05, 0.04), "THE WORD", Color3.fromRGB(150, 220, 255))
	local hintLbl = tlabel(rg, "Hint", UDim2.fromScale(0.9, 0.22), UDim2.fromScale(0.05, 0.12), "", Color3.new(1, 1, 1), Enum.Font.Arcade)
	tlabel(rg, "TimeTitle", UDim2.fromScale(0.9, 0.07), UDim2.fromScale(0.05, 0.4), "TIME", Color3.fromRGB(255, 210, 90))
	local timeLbl = tlabel(rg, "Timer", UDim2.fromScale(0.9, 0.2), UDim2.fromScale(0.05, 0.48), "--", Color3.fromRGB(255, 210, 90), Enum.Font.Arcade)
	local guessedLbl = tlabel(rg, "Guessed", UDim2.fromScale(0.9, 0.18), UDim2.fromScale(0.05, 0.74), "", Color3.fromRGB(120, 230, 150))
	-- far right board: live guesses feed
	local feedP = part(f, "FeedBoard", Vector3.new(6.6, 7.6, 0.1), at(-10.5, 0), Color3.fromRGB(250, 250, 245), Enum.Material.SmoothPlastic, DECO)
	local fg = sgui(feedP, 40)
	tlabel(fg, "Title", UDim2.fromScale(0.94, 0.1), UDim2.fromScale(0.03, 0.02), "💬 GUESSES", Color3.fromRGB(200, 70, 140), Enum.Font.FredokaOne)
	local feedLines = {}
	for i = 1, 9 do
		local l = tlabel(fg, "Line" .. i, UDim2.fromScale(0.92, 0.088), UDim2.fromScale(0.04, 0.13 + (i - 1) * 0.096), "", Color3.fromRGB(40, 45, 60), Enum.Font.GothamBold, Enum.TextXAlignment.Left)
		feedLines[i] = l
	end
	-- far left board: leaderboard
	local lbP = part(f, "LeaderBoard", Vector3.new(6.6, 7.6, 0.1), at(10.5, 0), Color3.fromRGB(250, 250, 245), Enum.Material.SmoothPlastic, DECO)
	local bg = sgui(lbP, 40)
	tlabel(bg, "Title", UDim2.fromScale(0.94, 0.1), UDim2.fromScale(0.03, 0.02), "🏆 TOP ARTISTS", Color3.fromRGB(60, 120, 200), Enum.Font.FredokaOne)
	local lbLines = {}
	for i = 1, 8 do
		lbLines[i] = tlabel(bg, "Row" .. i, UDim2.fromScale(0.92, 0.095), UDim2.fromScale(0.04, 0.14 + (i - 1) * 0.105), "", Color3.fromRGB(40, 45, 60), Enum.Font.GothamBold, Enum.TextXAlignment.Left)
	end
	-- banner above the board + little paint cups on the tray
	local top = part(f, "Banner", Vector3.new(16, 1.2, 0.1), at(0, 4.75), Color3.fromRGB(230, 110, 180), Enum.Material.Fabric, DECO)
	tlabel(sgui(top, 40), "T", UDim2.fromScale(1, 1), UDim2.new(), "🎨 GUESS THE DRAWING — LIVE! 🎨", Color3.new(1, 1, 1), Enum.Font.FredokaOne)
	local cols = { Color3.fromRGB(220, 60, 60), Color3.fromRGB(60, 110, 220), Color3.fromRGB(60, 170, 90), Color3.fromRGB(250, 205, 50) }
	for k, c in ipairs(cols) do
		local cup = part(f, "PaintCup", Vector3.new(0.5, 0.36, 0.36), at(-1.6 + k * 0.8, -4.05) * CFrame.new(0, 0, -0.25) * CFrame.Angles(0, 0, math.rad(90)), c, Enum.Material.SmoothPlastic, DECO)
		cup.Shape = Enum.PartType.Cylinder
	end
	return { canvas = canvas, info = nil, drawer = drawerName, round = roundLbl, hint = hintLbl, timer = timeLbl, guessed = guessedLbl,
		feed = feedLines, lb = lbLines, front = base + n * 0.3, n = n }
end

---------------------------------------------------------------- build
function M.Setup(ctx)
	M.Active = ctx
	ctx.Data.order, ctx.Data.drew, ctx.Data.guessedAny = {}, {}, {}
	ctx.Data.lastGuess, ctx.Data.strokeLog, ctx.Data.feed = {}, {}, {}
	local rooms = classroomBoards()
	if #rooms > 0 then
		local B = rooms[math.random(#rooms)]
		ctx.Data.board = buildClassroomBoard(ctx, B)
		ctx.Data.roomLabel = B.label
		ctx:SetLocation(B.inside, B.label)
		ctx.GotoPosition = B.inside + Vector3.new(0, 3, 0)
		ctx.ScoreLabel = "Drawing points"
		ctx.JoinMode = "button"
		return
	end
	-- fallback: the old outdoor board
	local pos, name = pickArea()
	local ground = pos - Vector3.new(0, 2.9, 0)
	-- board faces south (-Z) toward the benches
	local boardCF = CFrame.new(ground + Vector3.new(0, 7, 6)) -- Front face looks south (-Z) at the benches
	local frame = part(ctx.Folder, "BoardFrame", Vector3.new(15, 11, 0.6), boardCF * CFrame.new(0, 0, 0.2), Color3.fromRGB(120, 80, 50), Enum.Material.Wood)
	local canvas = part(ctx.Folder, "Canvas", Vector3.new(10, 10, 0.2), boardCF * CFrame.new(0, 0, -0.15), Color3.fromRGB(255, 255, 255))
	local info = part(ctx.Folder, "InfoPanel", Vector3.new(4.2, 10, 0.2), boardCF * CFrame.new(5.3, 0, -0.15), Color3.fromRGB(35, 40, 50))
	for _, x in ipairs({ -6.5, 6.5 }) do part(ctx.Folder, "BoardLeg", Vector3.new(0.6, 7.5, 0.6), CFrame.new((boardCF * CFrame.new(x, -6, 0.2)).Position), Color3.fromRGB(110, 75, 45), Enum.Material.Wood) end
	local cg = Instance.new("SurfaceGui") cg.Name = "CanvasGui" cg.Face = Enum.NormalId.Front cg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud cg.PixelsPerStud = 40 cg.Parent = canvas
	local strokes = Instance.new("Frame") strokes.Name = "Strokes" strokes.Size = UDim2.fromScale(1, 1) strokes.BackgroundTransparency = 1 strokes.ClipsDescendants = true strokes.Parent = cg
	local ig = Instance.new("SurfaceGui") ig.Name = "InfoGui" ig.Face = Enum.NormalId.Front ig.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud ig.PixelsPerStud = 40 ig.Parent = info
	local il = Instance.new("TextLabel") il.Name = "Info" il.Size = UDim2.fromScale(1, 1) il.BackgroundTransparency = 1 il.TextColor3 = Color3.new(1, 1, 1)
	il.Font = Enum.Font.GothamBlack il.TextScaled = true il.Text = "🎨\nGUESS\nTHE\nDRAWING\n\nJoin from\nthe banner!" il.Parent = ig
	local top = part(ctx.Folder, "TitleBoard", Vector3.new(15, 1.6, 0.3), boardCF * CFrame.new(0, 6.3, 0), Color3.fromRGB(200, 90, 160))
	local tg = Instance.new("SurfaceGui") tg.Face = Enum.NormalId.Front tg.Parent = top
	local tl = Instance.new("TextLabel") tl.Size = UDim2.fromScale(1, 1) tl.BackgroundTransparency = 1 tl.Font = Enum.Font.GothamBlack tl.TextScaled = true
	tl.TextColor3 = Color3.new(1, 1, 1) tl.Text = "🎨 GUESS THE DRAWING" tl.Parent = tg
	-- benches with working seats (PromptSeat tag = the existing sit system)
	for row = 0, 1 do
		for _, x in ipairs({ -3.2, 3.2 }) do
			local z = -2 - row * 3.5
			local benchCF = CFrame.new(ground + Vector3.new(x, 0, z))
			part(ctx.Folder, "BenchTop", Vector3.new(5.2, 0.35, 1.4), benchCF * CFrame.new(0, 1.6, 0), Color3.fromRGB(170, 120, 75), Enum.Material.Wood)
			for _, lx in ipairs({ -2.2, 2.2 }) do part(ctx.Folder, "BenchLeg", Vector3.new(0.3, 1.5, 1.2), benchCF * CFrame.new(lx, 0.75, 0), Color3.fromRGB(90, 90, 95), Enum.Material.Metal) end
			for _, sx in ipairs({ -1.5, 0, 1.5 }) do
				local s = Instance.new("Seat") s.Name = "BenchSeat" s.Size = Vector3.new(1.4, 0.2, 1.2)
				s.CFrame = benchCF * CFrame.new(sx, 1.85, 0) * CFrame.Angles(0, math.pi, 0) -- face the board
				s.Transparency = 1 s.Anchored = true s.CanCollide = false s:SetAttribute("SeatName", "Bench") s.Parent = ctx.Folder
				CollectionService:AddTag(s, "PromptSeat")
			end
		end
	end
	ctx.Data.board = { canvas = canvas, info = il }
	ctx:SetLocation(ground, name)
	ctx.GotoPosition = ground + Vector3.new(0, 3, -9)
	ctx.ScoreLabel = "Drawing points"
	ctx.JoinMode = "button"
end

---------------------------------------------------------------- rounds
local function boardInfo(ctx, text) if ctx.Data.board.info then ctx.Data.board.info.Text = text end end
local function bset(ctx, key, text) local b = ctx.Data.board if b and b[key] then b[key].Text = text end end
-- live guesses feed on the right board (last 9 lines)
local function boardFeed(ctx, text, good)
	local b = ctx.Data.board
	table.insert(ctx.Data.feed, { text = text, good = good })
	while #ctx.Data.feed > 9 do table.remove(ctx.Data.feed, 1) end
	if not b or not b.feed then return end
	for i = 1, 9 do
		local e = ctx.Data.feed[i]
		b.feed[i].Text = e and e.text or ""
		b.feed[i].TextColor3 = (e and e.good) and Color3.fromRGB(30, 150, 70) or Color3.fromRGB(40, 45, 60)
	end
end
local function boardLeaders(ctx)
	local b = ctx.Data.board
	if not b or not b.lb then return end
	local list = {}
	for p, sc in pairs(ctx.Scores or {}) do if p.Parent then table.insert(list, { p = p, s = sc }) end end
	table.sort(list, function(a, c) return a.s > c.s end)
	local medals = { "🥇", "🥈", "🥉" }
	for i = 1, 8 do
		local e = list[i]
		b.lb[i].Text = e and (("%s %s — %d"):format(medals[i] or (i .. "."), e.p.DisplayName, e.s)) or ""
	end
end
-- spectators (players who did not join) get the same round info, without the word
local function toSpectators(ctx, payload)
	for _, p in ipairs(Players:GetPlayers()) do
		if not ctx.Participants[p] then
			local copy = table.clone(payload) copy.spectator = true
			ctx:Send(p, copy)
		end
	end
end

local function chooseDrawer(ctx)
	local list = {}
	for p in pairs(ctx.Participants) do if p.Parent and not ctx.Data.drew[p] and not M.DrawBanned[p.UserId] then table.insert(list, p) end end
	if #list == 0 then return nil end
	return list[math.random(#list)]
end

local function hint(word, revealed)
	local out = {}
	for i = 1, #word do
		local c = word:sub(i, i)
		table.insert(out, (c == " " and "  ") or (revealed[i] and c:upper()) or "_")
	end
	return table.concat(out, " ")
end

local function runRound(ctx, drawer, word, isBot)
	local cfg = ctx.Config.GuessTheDrawing
	local round = { drawer = drawer, word = word, norm = normalize(word), revealed = {}, correct = {}, points = 0,
		ends = os.clock() + cfg.RoundTime, started = os.clock(), isBot = isBot }
	round.history = {}
	ctx.Data.round = round
	ctx:Broadcast({ type = "clear" })
	local drawerName = isBot and "🤖 Art Bot" or drawer.DisplayName
	round.drawerName = drawerName
	boardInfo(ctx, ("✏️\n%s\nis drawing\n\n%d letters"):format(drawerName, #word))
	bset(ctx, "drawer", "✏️\n" .. drawerName .. "\nis drawing")
	bset(ctx, "round", ("Round %d / %d"):format(ctx.Data.roundNo or 1, ctx.Data.maxRounds or 1))
	bset(ctx, "hint", hint(word, round.revealed))
	bset(ctx, "guessed", "")
	boardFeed(ctx, ("— Round %d: %s draws —"):format(ctx.Data.roundNo or 1, drawerName), true)
	boardLeaders(ctx)
	toSpectators(ctx, { type = "round", drawer = drawerName, hint = hint(word, round.revealed), time = cfg.RoundTime, round = ctx.Data.roundNo, rounds = ctx.Data.maxRounds })
	for p in pairs(ctx.Participants) do
		if p.Parent then
			ctx:Send(p, { type = "round", drawer = drawerName, isDrawer = (p == drawer and not isBot), word = (p == drawer and not isBot) and word or nil,
				hint = hint(word, round.revealed), time = cfg.RoundTime, round = ctx.Data.roundNo, rounds = ctx.Data.maxRounds })
		end
	end
	if isBot then
		-- the Art Bot draws the real picture for its word, a few points at a time, like a person drawing
		task.spawn(function()
			task.wait(1.5)
			local strokes = BotArt.strokes(word) or {}
			for _, s in ipairs(strokes) do
				local pts = s.pts
				local i = 1
				while i < #pts - 1 do
					if ctx.Data.round ~= round then return end
					-- send this stroke in short pieces (3 segments each) so it appears gradually
					local piece = {}
					for j = i, math.min(i + 7, #pts) do table.insert(piece, math.floor(math.clamp(pts[j], 0, 1) * 1000) / 1000) end
					local msg = { type = "stroke", c = s.c, w = s.w, pts = piece }
					table.insert(round.history, msg)
					ctx:Broadcast(msg)
					i += 6
					task.wait(0.12)
				end
				task.wait(0.35)
			end
		end)
	end
	local hinted = false
	local botHints = isBot and { 0.6, 0.35 } or {} -- solo: reveal another letter at 60% and 35% time left
	while ctx.Phase == "Active" and os.clock() < round.ends do
		-- everyone except the drawer guessed?
		local need, got = 0, 0
		for p in pairs(ctx.Participants) do if p.Parent and p ~= drawer then need += 1 if round.correct[p] then got += 1 end end end
		bset(ctx, "timer", tostring(math.max(0, math.ceil(round.ends - os.clock()))))
		bset(ctx, "guessed", need > 0 and ("✅ %d / %d\nguessed it"):format(got, need) or "")
		if need > 0 and got >= need then break end
		if drawer and not isBot and (not drawer.Parent or not ctx:IsIn(drawer)) then break end -- the drawer left the game / the event
		for k, at in ipairs(botHints) do
			if at and (round.ends - os.clock()) <= cfg.RoundTime * at and #word > 2 then
				botHints[k] = false
				local hidden = {}
				for i = 1, #word do if not round.revealed[i] and word:sub(i, i) ~= " " then table.insert(hidden, i) end end
				if #hidden > 1 then
					round.revealed[hidden[math.random(#hidden)]] = true
					ctx:Broadcast({ type = "hint", hint = hint(word, round.revealed) })
					bset(ctx, "hint", hint(word, round.revealed))
					boardFeed(ctx, "💡 A letter was revealed!", false)
				end
			end
		end
		if not hinted and (round.ends - os.clock()) <= cfg.RoundTime * cfg.HintAt and #word > 3 then
			hinted = true
			local idx = math.random(#word)
			round.revealed[idx] = true
			ctx:Broadcast({ type = "hint", hint = hint(word, round.revealed) })
			bset(ctx, "hint", hint(word, round.revealed))
			boardFeed(ctx, "💡 A letter was revealed!", false)
		end
		task.wait(0.25)
	end
	ctx.Data.round = nil
	if ctx.Phase ~= "Active" then return end
	ctx:Broadcast({ type = "roundEnd", word = word, drawer = drawerName })
	boardInfo(ctx, ("The word was\n\n%s"):format(word:upper()))
	bset(ctx, "hint", word:upper())
	bset(ctx, "timer", "0")
	boardFeed(ctx, ("🎨 The word was %s"):format(word:upper()), true)
	boardLeaders(ctx)
	task.wait(cfg.BetweenRounds)
end

function M.Start(ctx)
	local cfg = ctx.Config.GuessTheDrawing
	local count = 0 for p in pairs(ctx.Participants) do if p.Parent then count += 1 end end
	if count == 0 then
		ctx:ToastAll("🎨 Nobody joined Guess the Drawing this time")
		boardInfo(ctx, "Nobody joined 😢")
		task.delay(2, function() ctx:End("done") end)
		return
	end
	-- not enough people to take turns drawing (e.g. only you): the 🤖 Art Bot draws and everyone guesses
	local solo = count < cfg.MinPlayers
	if solo then ctx:ToastAll("🤖 The Art Bot will draw — guess what it is!") end
	ctx.Data.maxRounds = solo and SOLO_ROUNDS or math.min(cfg.MaxRounds, count)
	task.spawn(function()
		local pool = table.clone(Words)
		local botPool = BotArt.words()
		for r = 1, ctx.Data.maxRounds do
			if ctx.Phase ~= "Active" then return end
			ctx.Data.roundNo = r
			if solo then
				local word = table.remove(botPool, math.random(#botPool))
				runRound(ctx, nil, word, true)
			else
				local word = table.remove(pool, math.random(#pool))
				local drawer = chooseDrawer(ctx)
				if not drawer then break end
				ctx.Data.drew[drawer] = true
				ctx.Data.guessedAny[drawer] = true
				runRound(ctx, drawer, word, false)
			end
		end
		if ctx.Phase == "Active" then ctx:End("done") end
	end)
end

---------------------------------------------------------------- 🚫 hide a bad drawing
-- clears the board for everyone, ends the round, stops the drawer from drawing again, reports them
local function hideDrawing(ctx, round, by, why)
	if not round or round.hidden then return false end
	round.hidden = true
	round.history = {}
	round.points = math.huge -- no more strokes this round
	ctx:Broadcast({ type = "clear" })
	ctx:Broadcast({ type = "hidden", text = "🚫 The drawing was hidden (" .. why .. ")" })
	boardFeed(ctx, "🚫 Drawing hidden (" .. why .. ")", false)
	local d = round.drawer
	if d and not round.isBot then
		M.DrawBanned[d.UserId] = true
		if d.Parent then ctx:Toast(d, "🚫 Your drawing was hidden. You can't draw again in this server.") end
		local R = reports()
		if R and by then
			task.spawn(function()
				pcall(R.create, { u = by.UserId, n = by.Name, d = by.DisplayName }, { u = d.UserId, n = d.Name, d = d.DisplayName },
					"Drawing", ("[Automatic] Guess the Drawing: drawing hidden (%s). Word was '%s'."):format(why, tostring(round.word)))
			end)
		end
	end
	round.ends = os.clock() -- end the round now (the word is shown, next drawer goes)
	return true
end

-- 🧹 admin panel: clear the board (and stop that player from drawing again)
function M.AdminClear(admin)
	local ctx = M.Active
	local round = ctx and ctx.Phase == "Active" and ctx.Data.round
	if not round then return false, "No Guess the Drawing round is running right now" end
	if round.isBot then return false, "The Art Bot is drawing — nothing to clear" end
	if round.hidden then return false, "This drawing was already cleared" end
	local who = round.drawerName
	hideDrawing(ctx, round, admin, "by an admin")
	return true, "🧹 Board cleared — " .. tostring(who) .. " can't draw again in this server"
end

---------------------------------------------------------------- actions (strokes, clear, guesses)
function M.OnAction(ctx, player, action, data)
	local round = ctx.Data.round
	local cfg = ctx.Config.GuessTheDrawing
	if action == "hideVote" then
		-- anyone in the server who isn't drawing (players watching too)
		if not round or round.isBot or round.hidden then return { ok = false, msg = "Nothing to hide right now" } end
		if player == round.drawer then return { ok = false } end
		round.votes = round.votes or {}
		if round.votes[player] then return { ok = false, msg = "You already voted to hide this drawing" } end
		round.votes[player] = true
		local others, n = 0, 0
		for _, p in ipairs(Players:GetPlayers()) do if p ~= round.drawer then others += 1 end end
		for p in pairs(round.votes) do if p.Parent then n += 1 end end
		local need = math.max(1, math.min(HIDE_VOTES, others))
		if n >= need then
			hideDrawing(ctx, round, player, "players voted")
			return { ok = true, msg = "🚫 Drawing hidden. Thanks for keeping the game safe!" }
		end
		ctx:Broadcast({ type = "feed", text = ("🚫 %d / %d votes to hide this drawing"):format(n, need) })
		return { ok = true, msg = ("🚫 Vote counted (%d / %d)"):format(n, need) }
	end
	if action == "drawSync" then
		-- anyone (spectators too) can ask for the drawing so far (e.g. the board just streamed in)
		local now = os.clock()
		ctx.Data.syncAt = ctx.Data.syncAt or {}
		if ctx.Data.syncAt[player] and now - ctx.Data.syncAt[player] < 2 then return { ok = false } end
		ctx.Data.syncAt[player] = now
		if not round then return { ok = true, strokes = {} } end
		local out = {}
		for _, m in ipairs(round.history) do table.insert(out, { c = m.c, w = m.w, pts = m.pts }) end
		return { ok = true, strokes = out, drawer = round.drawerName, hint = hint(round.word, round.revealed), timeLeft = math.max(0, round.ends - now),
			round = ctx.Data.roundNo, rounds = ctx.Data.maxRounds, joined = ctx:IsIn(player) }
	end
	if not ctx:IsIn(player) or not round then return { ok = false } end

	if action == "stroke" then
		if player ~= round.drawer or round.hidden or M.DrawBanned[player.UserId] or type(data) ~= "table" or type(data.pts) ~= "table" then return { ok = false } end
		-- rate limit: 20 stroke messages per second
		local log = ctx.Data.strokeLog[player]
		local now = os.clock()
		if not log or now - log.t > 1 then log = { t = now, n = 0 } ctx.Data.strokeLog[player] = log end
		log.n += 1
		if log.n > 20 then return { ok = false } end
		local pts = data.pts
		if #pts < 2 or #pts > 60 or #pts % 2 ~= 0 then return { ok = false } end
		round.points += #pts / 2
		if round.points > cfg.MaxStrokePoints then return { ok = false, msg = "Canvas is full" } end
		local clean = {}
		for i, v in ipairs(pts) do
			if type(v) ~= "number" or v ~= v then return { ok = false } end
			clean[i] = math.floor(math.clamp(v, 0, 1) * 1000) / 1000
		end
		local c = math.clamp(math.floor(tonumber(data.c) or 1), 1, PALETTE)
		local w = math.clamp(math.floor(tonumber(data.w) or 2), 1, 4)
		local msg = { type = "stroke", c = c, w = w, pts = clean }
		table.insert(round.history, msg)
		ctx:Broadcast(msg)
		return { ok = true }
	elseif action == "clear" then
		if player ~= round.drawer or round.hidden then return { ok = false } end
		round.points = 0
		round.history = {}
		ctx:Broadcast({ type = "clear" })
		return { ok = true }
	elseif action == "guess" then
		if player == round.drawer or round.correct[player] then return { ok = false } end
		if type(data) ~= "table" or type(data.text) ~= "string" then return { ok = false } end
		local now = os.clock()
		if ctx.Data.lastGuess[player] and now - ctx.Data.lastGuess[player] < cfg.GuessCooldown then return { ok = false, msg = "Slow down!" } end
		ctx.Data.lastGuess[player] = now
		local text = data.text:sub(1, 30)
		if #text:gsub("%s", "") == 0 then return { ok = false } end
		ctx.Data.guessedAny[player] = true
		if normalize(text) == round.norm then
			round.correct[player] = true
			local left = math.clamp((round.ends - now) / cfg.RoundTime, 0, 1)
			local pts = cfg.GuessPoints + math.floor(cfg.TimeBonus * left)
			ctx:AddScore(player, pts)
			if round.drawer and round.drawer.Parent then ctx:AddScore(round.drawer, cfg.DrawerPoints) end
			ctx:Broadcast({ type = "feed", text = ("✅ %s guessed the word!"):format(player.DisplayName), good = true })
			boardFeed(ctx, ("✅ %s guessed it! +%d"):format(player.DisplayName, pts), true)
			boardLeaders(ctx)
			return { ok = true, correct = true, msg = ("🎉 Correct! +%d"):format(pts), word = round.word }
		end
		if isClose(normalize(text), round.norm) then ctx:Toast(player, "🔥 So close!") end
		local safe = filtered(text, player)
		if safe then
			ctx:Broadcast({ type = "feed", text = player.DisplayName .. ": " .. safe })
			boardFeed(ctx, player.DisplayName .. ": " .. safe, false)
		end
		return { ok = true, correct = false }
	end
	return { ok = false }
end

function M.OnPlayerLeft(ctx, player)
	ctx.Data.strokeLog[player] = nil
	ctx.Data.lastGuess[player] = nil
	if player.Parent then ctx:Send(player, { type = "left" }) end -- close the drawing / guessing panel (they can still watch)
end

function M.Finish(ctx)
	ctx.Data.round = nil
	ctx.RewardEligible = {}
	for p in pairs(ctx.Data.guessedAny) do ctx.RewardEligible[p] = true end
	for p in pairs(ctx.Data.drew) do ctx.RewardEligible[p] = true end
	ctx:Broadcast({ type = "clear" })
end

function M.Cleanup(ctx)
	if M.Active == ctx then M.Active = nil end
	ctx:Broadcast({ type = "clear", hide = true })
end

return M
