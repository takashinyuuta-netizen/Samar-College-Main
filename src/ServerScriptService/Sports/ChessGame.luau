--[[ ChessGame — ♟️ chess tables in the 2F library, run by SportsServer (Kind = "Chess").
  • Team A = White, Team B = Black (1 player each; a 🤖 CPU joins after 10 s if nobody comes).
  • Players sit at the table; the 3D pieces on the board move for everyone (slide + hop, captured pieces fade).
  • Players move on a 2D board on screen (ChessClient); the server checks every move (ChessEngine).
  • Chess clock (minutes + increment), checkmate / stalemate / 50-move / repetition / material draws,
    resign, running out of time. Spectators sit on the blue chairs or press Watch for TV cameras. ]]
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local E = require(script.Parent:WaitForChild("ChessEngine"))
local P = require(RS:WaitForChild("Sports"):WaitForChild("ChessPieces"))
local G = {}
local A
local games = {} -- court -> true while a game runs
local rand = Random.new()
local SIT = { R15 = 2506281703, R6 = 178130996 }

function G.init(api) A = api end

---------------------------------------------------------------- 3D board
local function sqCF(court, i)
	local f, r = E.fr(i)
	local S = court.model:GetAttribute("Square")
	return court.markers.BoardA1.CFrame * CFrame.new((f - 1) * S, 0, -(r - 1) * S)
end
local function folder(court)
	local f = court.model:FindFirstChild("ChessPieces")
	if not f then f = Instance.new("Folder") f.Name = "ChessPieces" f.Parent = court.model end
	return f
end
local function pieceCF(court, i, p)
	local cf = sqCF(court, i)
	return E.colorOf(p) == "w" and cf or cf * CFrame.Angles(0, math.pi, 0)
end
local function makePiece(court, i, p)
	local S = court.model:GetAttribute("Square")
	local m = P.build(p:upper(), E.colorOf(p) == "w", S * 0.95)
	m:PivotTo(pieceCF(court, i, p))
	m.Parent = folder(court)
	return { model = m, p = p }
end
local function fadeOut(model)
	for _, x in ipairs(model:GetDescendants()) do
		if x:IsA("BasePart") and x.Name ~= "Root" then TweenService:Create(x, TweenInfo.new(0.35), { Transparency = 1 }):Play() end
	end
	local r = model.PrimaryPart
	if r then TweenService:Create(r, TweenInfo.new(0.35), { CFrame = r.CFrame + Vector3.new(0, 1.2, 0) }):Play() end
	game:GetService("Debris"):AddItem(model, 0.4)
end
-- make the 3D pieces match a board (only touches squares that changed)
local function sync(court, board)
	court.cp = court.cp or {}
	for i = 1, 64 do
		local want, have = board[i], court.cp[i]
		if have and (have.p ~= want or not have.model.Parent) then if have.model.Parent then have.model:Destroy() end court.cp[i] = nil have = nil end
		if want ~= "." and not have then court.cp[i] = makePiece(court, i, want) end
	end
end
local function slide(court, from, to, p)
	local c = court.cp[from]
	if not c then return end
	court.cp[from] = nil
	local victim = court.cp[to]
	if victim then fadeOut(victim.model) end
	court.cp[to] = c
	local root = c.model.PrimaryPart
	local target = pieceCF(court, to, p)
	local S = court.model:GetAttribute("Square")
	local lift = (p:upper() == "N") and S * 1.4 or S * 0.5
	local t1 = TweenService:Create(root, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { CFrame = root.CFrame + Vector3.new(0, lift, 0) })
	t1:Play()
	t1.Completed:Once(function()
		local t2 = TweenService:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Sine), { CFrame = target + Vector3.new(0, lift, 0) })
		t2:Play()
		t2.Completed:Once(function() TweenService:Create(root, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = target }):Play() end)
	end)
end
local function animate(court, before, m)
	local p = before[m.from]
	if m.flag == "ep" then
		local f = E.fr(m.to)
		local _, r = E.fr(m.from)
		local v = court.cp[E.idx(f, r)]
		if v then fadeOut(v.model) court.cp[E.idx(f, r)] = nil end
	end
	slide(court, m.from, m.to, p)
	if m.flag == "castleK" or m.flag == "castleQ" then
		local w = E.colorOf(p) == "w"
		local rf, rt
		if m.flag == "castleK" then rf, rt = w and 8 or 64, w and 6 or 62 else rf, rt = w and 1 or 57, w and 4 or 60 end
		task.delay(0.15, function() slide(court, rf, rt, before[rf]) end)
	end
end

-- clock prop on the table
local function fmt(t) t = math.max(0, math.ceil(t)) return ("%d:%02d"):format(t // 60, t % 60) end
local function clockFace(court)
	local ck = court.model:FindFirstChild("ChessClock", true)
	if not ck then return end
	local g = court.chess
	local txt = "5:00 | 5:00"
	if g then
		local w, b = g.clock.w, g.clock.b
		if g.s.turn == "w" then w -= os.clock() - g.turnStart else b -= os.clock() - g.turnStart end
		txt = fmt(w) .. " | " .. fmt(b)
	end
	for _, l in ipairs(ck:GetDescendants()) do if l:IsA("TextLabel") then l.Text = txt end end
end

---------------------------------------------------------------- seating
local function seat(court, e, markerName)
	local ch = e.char
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local mk = court.markers:FindFirstChild(markerName)
	if not root or not hum or not mk then return end
	local r15 = hum.RigType == Enum.HumanoidRigType.R15
	local up = r15 and (hum.HipHeight * 0.55 + root.Size.Y / 2 - 0.15) or 1.5
	root.Anchored = true
	e.home = mk.CFrame * CFrame.new(0, up, 0)
	ch:PivotTo(e.home)
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local a = Instance.new("Animation") a.AnimationId = "rbxassetid://" .. (r15 and SIT.R15 or SIT.R6)
	local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
	if ok and tr then tr.Priority = Enum.AnimationPriority.Action4 tr.Looped = true tr:Play(0.2) e.sitTrack = tr end
end
local function unseat(e)
	if e and e.sitTrack then pcall(function() e.sitTrack:Stop(0.2) end) e.sitTrack = nil end
end

---------------------------------------------------------------- state to clients
local function who(e) return e and { name = e.name, userId = e.player and e.player.UserId or 0, cpu = e.cpu == true } or nil end
local function payload(court, extra)
	local g = court.chess
	if not g then
		local d = { t = "chess", court = court.id, over = true }
		if extra then for k, v in pairs(extra) do d[k] = v end end
		return d
	end
	local s = g.s
	local legal = {}
	if not g.over then
		for _, m in ipairs(E.legal(s)) do
			local key = m.from .. "-" .. m.to
			if m.flag == "promo" then key ..= "-" .. m.promo end
			legal[#legal + 1] = key
		end
	end
	local w, b = g.clock.w, g.clock.b
	if not g.over then if s.turn == "w" then w -= os.clock() - g.turnStart else b -= os.clock() - g.turnStart end end
	local log = {}
	for i = math.max(1, #g.log - 11), #g.log do log[#log + 1] = g.log[i] end
	local d = { t = "chess", court = court.id, name = court.name, board = table.concat(s.board), turn = s.turn, legal = legal,
		last = g.last, check = (not g.over) and E.inCheck(s) or false, checkSq = E.inCheck(s) and E.kingSq(s.board, s.turn) or nil,
		clock = { w = math.max(0, w), b = math.max(0, b) }, white = who(g.white), black = who(g.black), log = log, moveNo = s.full,
		captured = g.captured, over = g.over, status = g.status }
	if extra then for k, v in pairs(extra) do d[k] = v end end
	return d
end
local function push(court, extra) A.Event:FireAllClients(payload(court, extra)) end
G.push = push

---------------------------------------------------------------- game flow
local function finish(court, winColor, why, text)
	local g = court.chess
	if not g or g.over then return end
	g.over = true
	g.status = text
	clockFace(court)
	A.toastCourt(court, text)
	push(court)
	local side = winColor == "w" and "A" or (winColor == "b" and "B" or nil)
	task.delay(1.5, function()
		if court.chess == g and court.state == "Playing" then A.endMatch(court, side, side and why or "draw") end
	end)
end

local cpuMove
local function apply(court, m)
	local g = court.chess
	local s = g.s
	local us = s.turn
	-- clock
	local spent = os.clock() - g.turnStart
	g.clock[us] = g.clock[us] - spent + court.cfg.Increment
	local note = E.notation(s, m)
	local before = s.board
	local ns, cap = E.make(s, m)
	g.s = ns
	g.turnStart = os.clock()
	g.last = { from = m.from, to = m.to }
	g.log[#g.log + 1] = (us == "w" and (s.full .. ". ") or "") .. note
	if cap and cap ~= "." then
		table.insert(g.captured[us], cap)
		local side = us == "w" and "A" or "B"
		court.score[side] += (E.VAL[cap:upper()] or 0) // 100
	end
	animate(court, before, m)
	task.delay(0.65, function() if court.chess == g then sync(court, g.s.board) end end)
	local key = E.key(ns)
	g.keys[key] = (g.keys[key] or 0) + 1
	A.broadcast(court)
	-- game over?
	local moves = E.legal(ns)
	local mover = us == "w" and g.white or g.black
	if #moves == 0 then
		if E.inCheck(ns) then return finish(court, us, "checkmate", ("♟️ CHECKMATE! %s wins with %s"):format(mover.name, note)) end
		return finish(court, nil, "draw", "🤝 Stalemate — it's a draw!")
	end
	if ns.half >= 100 then return finish(court, nil, "draw", "🤝 50 moves without a capture — draw") end
	if g.keys[key] >= 3 then return finish(court, nil, "draw", "🤝 Same position 3 times — draw") end
	if E.insufficient(ns.board) then return finish(court, nil, "draw", "🤝 Not enough pieces to checkmate — draw") end
	if E.inCheck(ns) then A.toastCourt(court, ("⚠️ CHECK! (%s)"):format(note)) end
	push(court, { moved = note, cap = cap ~= "." and cap or nil })
	local nextE = ns.turn == "w" and g.white or g.black
	if nextE and nextE.cpu then cpuMove(court) end
end

function cpuMove(court)
	local g = court.chess
	local token = g.token
	local turnAt = #g.log
	task.delay(rand:NextNumber(0.7, 1.6), function()
		if court.chess ~= g or g.over or #g.log ~= turnAt then return end
		local m = E.bestMove(g.s, court.cfg.CpuDepth, court.cfg.CpuNoise)
		if court.chess ~= g or g.over or #g.log ~= turnAt or not m then return end
		apply(court, m)
	end)
end

---------------------------------------------------------------- API used by SportsServer
function G.setupIdle(court)
	court.chess = nil
	sync(court, E.fromFEN(E.START).board)
	clockFace(court)
end

function G.start(court, token)
	if court.state ~= "Playing" or court.token ~= token then return end
	local white, black = court.sides.A[1], court.sides.B[1]
	if not white or not black then return end
	local s = E.fromFEN(E.START)
	court.chess = { s = s, white = white, black = black, clock = { w = court.cfg.ClockSeconds, b = court.cfg.ClockSeconds },
		turnStart = os.clock(), keys = { [E.key(s)] = 1 }, log = {}, captured = { w = {}, b = {} }, token = token, over = false }
	games[court] = true
	sync(court, s.board)
	seat(court, white, "A0") seat(court, black, "B0")
	A.toastCourt(court, ("♟️ %s (White) vs %s (Black) — %d min + %d s. White moves first!"):format(white.name, black.name, court.cfg.ClockSeconds // 60, court.cfg.Increment))
	push(court)
	A.broadcast(court)
	if white.cpu then cpuMove(court) end
end

function G.move(court, player, data)
	local g = court.chess
	if not g or g.over or court.state ~= "Playing" then return { ok = false, msg = "No game running" } end
	local mine = (g.s.turn == "w" and g.white or g.black)
	if not mine or mine.player ~= player then return { ok = false, msg = "It's not your turn" } end
	local from, to = tonumber(data.from), tonumber(data.to)
	local promo = type(data.promo) == "string" and data.promo:upper() or "Q"
	for _, m in ipairs(E.legal(g.s)) do
		if m.from == from and m.to == to and (m.flag ~= "promo" or m.promo == promo) then
			apply(court, m)
			return { ok = true }
		end
	end
	return { ok = false, msg = "That move isn't allowed" }
end

function G.resign(court, player)
	local g = court.chess
	if not g or g.over then return { ok = false } end
	local color = (g.white and g.white.player == player) and "w" or ((g.black and g.black.player == player) and "b" or nil)
	if not color then return { ok = false } end
	local winner = color == "w" and g.black or g.white
	finish(court, E.other(color), "resign", ("🏳️ %s resigned — %s wins!"):format(player.DisplayName, winner and winner.name or "opponent"))
	return { ok = true }
end

function G.stop(court)
	local g = court.chess
	if g then g.over = true unseat(g.white) unseat(g.black) end
	games[court] = nil
	push(court)
end

function G.reset(court)
	games[court] = nil
	court.chess = nil
	sync(court, E.fromFEN(E.START).board)
	clockFace(court)
	push(court, { over = true, reset = true })
end

-- chess clocks: tick the table clocks and flag players who run out of time
task.spawn(function()
	while true do
		task.wait(0.25)
		for court in pairs(games) do
			local g = court.chess
			if g and not g.over then
				clockFace(court)
				local us = g.s.turn
				if g.clock[us] - (os.clock() - g.turnStart) <= 0 then
					g.clock[us] = 0
					local loser = us == "w" and g.white or g.black
					local winner = us == "w" and g.black or g.white
					finish(court, E.other(us), "time", ("⏱ %s ran out of time — %s wins!"):format(loser.name, winner.name))
				end
			end
		end
	end
end)

return G
