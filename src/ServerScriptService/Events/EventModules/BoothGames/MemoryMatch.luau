-- 🃏 MEMORY MATCH: 16 face-down cards in a 4 x 4 grid (8 pairs). Match them all in 75 seconds; fewer moves = more tickets.
-- The big cards on the stall wall flip over for everyone to see. Faces stay on the server until flipped.
local G = { Name = "Memory Match", Icon = "🃏", Color = Color3.fromRGB(60, 170, 160),
	Description = "4 x 4 cards! Flip two at a time and find all 8 school-supply pairs. Fewer moves = more 🎟️." }
local SYMBOLS = { "📚", "✏️", "🎒", "📐", "🔬", "🖍️", "📏", "🧮" }
local LIMIT = 75
local PAIRS = 8
local FACE_BG, MATCH_BG = Color3.fromRGB(255, 252, 240), Color3.fromRGB(190, 245, 200)

function G.Bind(ctx, B, fx)
	B.cards = {}
	for _, c in ipairs(B.game:GetChildren()) do
		local i = c:GetAttribute("Index")
		if i and c.Name:find("^Card_") then
			B.cards[i] = { part = c, base = c.CFrame, face = c.FaceGui.Text }
		end
	end
end

local function flip(B, fx, i, up)
	local c = B.cards[i]
	if not c then return end
	fx.move(c.part, up and (c.base * CFrame.Angles(0, math.pi, 0)) or c.base, 0.28, Enum.EasingStyle.Back)
end
local function resetCards(B)
	for _, c in pairs(B.cards) do c.part.CFrame = c.base c.face.Text = "" c.face.BackgroundColor3 = FACE_BG end
end

function G.Start(ctx, player, s, B, fx)
	local pool = table.clone(SYMBOLS)
	for i = #pool, 2, -1 do local j = math.random(i) pool[i], pool[j] = pool[j], pool[i] end
	local cards = {}
	for i = 1, PAIRS do table.insert(cards, pool[i]) table.insert(cards, pool[i]) end
	for i = #cards, 2, -1 do local j = math.random(i) cards[i], cards[j] = cards[j], cards[i] end
	s.cards, s.matched, s.first, s.moves, s.pairs, s.ends = cards, {}, nil, 0, 0, os.clock() + LIMIT
	resetCards(B)
	fx.say(B, "🃏 0 pairs • 0 moves")
	return { kind = "memory", count = #cards, seconds = LIMIT }
end

function G.Action(ctx, player, s, data, B, fx)
	local i = tonumber(data.flip)
	if data.op ~= "flip" or not i or not s.cards[i] or s.matched[i] or i == s.first or s.busy then return { ok = false } end
	if os.clock() > s.ends then return { ok = true, done = true, tickets = s.pairs, msg = ("⏰ Time's up! %d pairs (+%d 🎟️)"):format(s.pairs, s.pairs) } end
	local face = s.cards[i]
	fx.anim(B, "point")
	B.cards[i].face.Text = face
	flip(B, fx, i, true)
	fx.sound(B, "Click", 0.35, 1.4)
	if not s.first then s.first = i return { ok = true, flip = i, face = face } end
	local a = s.first
	s.first = nil
	s.moves += 1
	if s.cards[a] == face then
		s.matched[a], s.matched[i] = true, true
		s.pairs += 1
		task.delay(0.3, function()
			for _, k in ipairs({ a, i }) do B.cards[k].face.BackgroundColor3 = MATCH_BG fx.burst(B.cards[k].part.Position, Color3.fromRGB(120, 255, 150), 14, 6) end
			fx.sound(B, "Ping", 0.5, 1.4)
		end)
		fx.say(B, ("🃏 %d pairs • %d moves"):format(s.pairs, s.moves))
		if s.pairs == PAIRS then
			local t = math.max(3, 16 - math.floor((s.moves - PAIRS) / 2)) -- perfect game (8 moves) = 16 tickets
			task.delay(0.5, function() fx.confetti(B) fx.anim(B, "cheer") end)
			return { ok = true, flip = i, face = face, match = { a, i }, done = true, tickets = t, msg = ("🃏 All pairs in %d moves! +%d 🎟️"):format(s.moves, t) }
		end
		return { ok = true, flip = i, face = face, match = { a, i } }
	end
	s.busy = true
	task.delay(1.0, function()
		for _, k in ipairs({ a, i }) do flip(B, fx, k, false) end
		task.wait(0.3)
		for _, k in ipairs({ a, i }) do if not s.matched[k] then B.cards[k].face.Text = "" end end
		s.busy = false
	end)
	fx.say(B, ("🃏 %d pairs • %d moves"):format(s.pairs, s.moves))
	return { ok = true, flip = i, face = face, miss = { a, i } }
end

function G.Stop(ctx, player, s, B, fx)
	task.delay(2.5, function() if not B.session then resetCards(B) end end)
end

return G
