--[[ ChessEngine — the rules of chess + a CPU player.
  Board: array of 64 strings, index = (rank-1)*8 + file (a1 = 1, h1 = 8, a8 = 57, h8 = 64).
  "P N B R Q K" = white, "p n b r q k" = black, "." = empty.
  State: { board, turn = "w"/"b", castle = {K,Q,k,q}, ep = square or nil, half, full }
  Legal moves include castling, en passant and promotion. Detects check, checkmate, stalemate,
  the 50-move rule and insufficient material. The CPU uses alpha-beta search. ]]
local E = {}
local FILES = "abcdefgh"
local function idx(f, r) return (r - 1) * 8 + f end
local function fr(i) return (i - 1) % 8 + 1, (i - 1) // 8 + 1 end
local function colorOf(p) if p == "." then return nil end return p == p:upper() and "w" or "b" end
local function inb(f, r) return f >= 1 and f <= 8 and r >= 1 and r <= 8 end
E.idx, E.fr, E.colorOf = idx, fr, colorOf

E.START = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
function E.sq(name) return idx(FILES:find(name:sub(1, 1), 1, true), tonumber(name:sub(2, 2))) end
function E.name(i) local f, r = fr(i) return FILES:sub(f, f) .. r end

function E.fromFEN(fen)
	local place, turn, castle, ep, half, full = fen:match("^(%S+) (%S) (%S+) (%S+) (%d+) (%d+)")
	local b = table.create(64, ".")
	local r, f = 8, 1
	for ch in place:gmatch(".") do
		if ch == "/" then r -= 1 f = 1
		elseif tonumber(ch) then f += tonumber(ch)
		else b[idx(f, r)] = ch f += 1 end
	end
	return { board = b, turn = turn, castle = { K = castle:find("K") ~= nil, Q = castle:find("Q") ~= nil, k = castle:find("k") ~= nil, q = castle:find("q") ~= nil },
		ep = ep ~= "-" and E.sq(ep) or nil, half = tonumber(half), full = tonumber(full) }
end

local KN = { { 1, 2 }, { 2, 1 }, { 2, -1 }, { 1, -2 }, { -1, -2 }, { -2, -1 }, { -2, 1 }, { -1, 2 } }
local KG = { { 1, 0 }, { 1, 1 }, { 0, 1 }, { -1, 1 }, { -1, 0 }, { -1, -1 }, { 0, -1 }, { 1, -1 } }
local ORTH = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
local DIAG = { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }

-- is square `sq` attacked by color `by`?
function E.attacked(b, sq, by)
	local f, r = fr(sq)
	local w = by == "w"
	local pr = w and r - 1 or r + 1
	local pawn = w and "P" or "p"
	if pr >= 1 and pr <= 8 then
		if f > 1 and b[idx(f - 1, pr)] == pawn then return true end
		if f < 8 and b[idx(f + 1, pr)] == pawn then return true end
	end
	local n, k = w and "N" or "n", w and "K" or "k"
	for _, d in ipairs(KN) do local ff, rr = f + d[1], r + d[2] if inb(ff, rr) and b[idx(ff, rr)] == n then return true end end
	for _, d in ipairs(KG) do local ff, rr = f + d[1], r + d[2] if inb(ff, rr) and b[idx(ff, rr)] == k then return true end end
	local R, B, Q = w and "R" or "r", w and "B" or "b", w and "Q" or "q"
	for _, d in ipairs(ORTH) do
		local ff, rr = f + d[1], r + d[2]
		while inb(ff, rr) do
			local p = b[idx(ff, rr)]
			if p ~= "." then if p == R or p == Q then return true end break end
			ff += d[1] rr += d[2]
		end
	end
	for _, d in ipairs(DIAG) do
		local ff, rr = f + d[1], r + d[2]
		while inb(ff, rr) do
			local p = b[idx(ff, rr)]
			if p ~= "." then if p == B or p == Q then return true end break end
			ff += d[1] rr += d[2]
		end
	end
	return false
end

function E.kingSq(b, color)
	local k = color == "w" and "K" or "k"
	for i = 1, 64 do if b[i] == k then return i end end
end
local function other(c) return c == "w" and "b" or "w" end
E.other = other

function E.inCheck(s)
	local k = E.kingSq(s.board, s.turn)
	return k ~= nil and E.attacked(s.board, k, other(s.turn))
end

local PROMOS = { "Q", "R", "B", "N" }
function E.pseudo(s)
	local b, us = s.board, s.turn
	local them = other(us)
	local moves = {}
	local function add(from, to, flag, promo) moves[#moves + 1] = { from = from, to = to, flag = flag, promo = promo } end
	for i = 1, 64 do
		local p = b[i]
		if p ~= "." and colorOf(p) == us then
			local f, r = fr(i)
			local t = p:upper()
			if t == "P" then
				local dir = us == "w" and 1 or -1
				local start, last = us == "w" and 2 or 7, us == "w" and 8 or 1
				local r1 = r + dir
				if inb(f, r1) and b[idx(f, r1)] == "." then
					if r1 == last then for _, pr in ipairs(PROMOS) do add(i, idx(f, r1), "promo", pr) end else add(i, idx(f, r1)) end
					if r == start and b[idx(f, r + 2 * dir)] == "." then add(i, idx(f, r + 2 * dir), "double") end
				end
				for _, df in ipairs({ -1, 1 }) do
					local ff = f + df
					if inb(ff, r1) then
						local to = idx(ff, r1)
						local q = b[to]
						if q ~= "." and colorOf(q) == them then
							if r1 == last then for _, pr in ipairs(PROMOS) do add(i, to, "promo", pr) end else add(i, to) end
						elseif s.ep == to then add(i, to, "ep") end
					end
				end
			elseif t == "N" or t == "K" then
				for _, d in ipairs(t == "N" and KN or KG) do
					local ff, rr = f + d[1], r + d[2]
					if inb(ff, rr) then local q = b[idx(ff, rr)] if q == "." or colorOf(q) == them then add(i, idx(ff, rr)) end end
				end
				if t == "K" then
					local c = s.castle
					if us == "w" and i == 5 then
						if c.K and b[6] == "." and b[7] == "." and b[8] == "R" and not E.attacked(b, 5, them) and not E.attacked(b, 6, them) and not E.attacked(b, 7, them) then add(5, 7, "castleK") end
						if c.Q and b[4] == "." and b[3] == "." and b[2] == "." and b[1] == "R" and not E.attacked(b, 5, them) and not E.attacked(b, 4, them) and not E.attacked(b, 3, them) then add(5, 3, "castleQ") end
					elseif us == "b" and i == 61 then
						if c.k and b[62] == "." and b[63] == "." and b[64] == "r" and not E.attacked(b, 61, them) and not E.attacked(b, 62, them) and not E.attacked(b, 63, them) then add(61, 63, "castleK") end
						if c.q and b[60] == "." and b[59] == "." and b[58] == "." and b[57] == "r" and not E.attacked(b, 61, them) and not E.attacked(b, 60, them) and not E.attacked(b, 59, them) then add(61, 59, "castleQ") end
					end
				end
			else
				local dirs = t == "R" and ORTH or (t == "B" and DIAG or nil)
				local function slide(list)
					for _, d in ipairs(list) do
						local ff, rr = f + d[1], r + d[2]
						while inb(ff, rr) do
							local q = b[idx(ff, rr)]
							if q == "." then add(i, idx(ff, rr))
							else if colorOf(q) == them then add(i, idx(ff, rr)) end break end
							ff += d[1] rr += d[2]
						end
					end
				end
				if dirs then slide(dirs) else slide(ORTH) slide(DIAG) end
			end
		end
	end
	return moves
end

function E.make(s, m)
	local b = table.clone(s.board)
	local us = s.turn
	local p = b[m.from]
	local cap = b[m.to]
	b[m.to] = p b[m.from] = "."
	if m.flag == "ep" then
		local f = fr(m.to)
		local _, r = fr(m.from)
		cap = b[idx(f, r)] b[idx(f, r)] = "."
	elseif m.flag == "promo" then
		b[m.to] = us == "w" and m.promo or m.promo:lower()
	elseif m.flag == "castleK" then
		if us == "w" then b[8] = "." b[6] = "R" else b[64] = "." b[62] = "r" end
	elseif m.flag == "castleQ" then
		if us == "w" then b[1] = "." b[4] = "R" else b[57] = "." b[60] = "r" end
	end
	local c = { K = s.castle.K, Q = s.castle.Q, k = s.castle.k, q = s.castle.q }
	if p == "K" then c.K = false c.Q = false elseif p == "k" then c.k = false c.q = false end
	if m.from == 1 or m.to == 1 then c.Q = false end
	if m.from == 8 or m.to == 8 then c.K = false end
	if m.from == 57 or m.to == 57 then c.q = false end
	if m.from == 64 or m.to == 64 then c.k = false end
	return { board = b, turn = other(us), castle = c, ep = m.flag == "double" and (m.from + m.to) // 2 or nil,
		half = (p:upper() == "P" or cap ~= ".") and 0 or s.half + 1, full = s.full + (us == "b" and 1 or 0) }, cap
end

function E.legal(s)
	local out = {}
	local us, them = s.turn, other(s.turn)
	for _, m in ipairs(E.pseudo(s)) do
		local ns, cap = E.make(s, m)
		local k = E.kingSq(ns.board, us)
		if k and not E.attacked(ns.board, k, them) then m.cap = cap out[#out + 1] = m end
	end
	return out
end

function E.insufficient(b)
	local minors, other_ = 0, 0
	for i = 1, 64 do
		local t = b[i]:upper()
		if t == "N" or t == "B" then minors += 1 elseif t ~= "." and t ~= "K" then other_ += 1 end
	end
	return other_ == 0 and minors <= 1
end

-- short algebraic-ish notation for the move log
function E.notation(s, m)
	if m.flag == "castleK" then return "O-O" end
	if m.flag == "castleQ" then return "O-O-O" end
	local p = s.board[m.from]:upper()
	local cap = s.board[m.to] ~= "." or m.flag == "ep"
	local txt
	if p == "P" then txt = (cap and (E.name(m.from):sub(1, 1) .. "x") or "") .. E.name(m.to)
	else txt = p .. (cap and "x" or "") .. E.name(m.to) end
	if m.flag == "promo" then txt ..= "=" .. m.promo end
	local ns = E.make(s, m)
	if E.inCheck(ns) then txt ..= (#E.legal(ns) == 0 and "#" or "+") end
	return txt
end

---------------------------------------------------------------- CPU
local VAL = { P = 100, N = 320, B = 330, R = 500, Q = 900, K = 0 }
E.VAL = VAL
local function evaluate(b)
	local score = 0
	for i = 1, 64 do
		local p = b[i]
		if p ~= "." then
			local f, r = fr(i)
			local t = p:upper()
			local white = p == t
			local rr = white and r or 9 - r
			local cd = math.abs(4.5 - f) + math.abs(4.5 - rr)
			local v = VAL[t]
			if t == "P" then v += (rr - 2) * 7 + ((f >= 3 and f <= 6 and rr >= 4) and 12 or 0)
			elseif t == "N" then v += (5 - cd) * 9
			elseif t == "B" then v += (5 - cd) * 4 + (rr > 1 and 8 or 0)
			elseif t == "R" then v += (rr == 7 and 15 or 0)
			elseif t == "Q" then v += (5 - cd) * 2
			elseif t == "K" then v += (rr == 1 and (f <= 3 or f >= 7) and 20 or (rr == 1 and 0 or -20)) end
			score += white and v or -v
		end
	end
	return score
end
E.evaluate = evaluate

local MATE = 100000
local nodes = 0
local function order(moves)
	for _, m in ipairs(moves) do
		local v = 0
		if m.cap and m.cap ~= "." then v = 10 * VAL[m.cap:upper()] + 50 end
		if m.flag == "promo" then v += VAL[m.promo] end
		m.ord = v
	end
	table.sort(moves, function(a, b) return a.ord > b.ord end)
end
local function search(s, depth, alpha, beta, ply)
	nodes += 1
	if nodes % 2500 == 0 then task.wait() end
	if depth == 0 then
		local e = evaluate(s.board)
		return s.turn == "w" and e or -e
	end
	local moves = E.legal(s)
	if #moves == 0 then return E.inCheck(s) and (-MATE + ply) or 0 end
	order(moves)
	local best = -math.huge
	for _, m in ipairs(moves) do
		local v = -search((E.make(s, m)), depth - 1, -beta, -alpha, ply + 1)
		if v > best then best = v end
		if v > alpha then alpha = v end
		if alpha >= beta then break end
	end
	return best
end

-- best move for the side to move. `depth` 1..3, `noise` adds a bit of personality
function E.bestMove(s, depth, noise)
	nodes = 0
	local moves = E.legal(s)
	if #moves == 0 then return nil end
	order(moves)
	local best, bestV = moves[1], -math.huge
	local rng = Random.new()
	for _, m in ipairs(moves) do
		local v = -search((E.make(s, m)), depth - 1, -math.huge, -bestV + (noise or 0), 1) + rng:NextNumber(0, noise or 0)
		if v > bestV then bestV, best = v, m end
	end
	return best
end

function E.key(s)
	return table.concat(s.board) .. s.turn .. (s.castle.K and "K" or "") .. (s.castle.Q and "Q" or "") .. (s.castle.k and "k" or "") .. (s.castle.q and "q" or "") .. tostring(s.ep)
end

return E
