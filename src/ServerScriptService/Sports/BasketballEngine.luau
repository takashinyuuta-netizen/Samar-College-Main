--[[ BasketballEngine — 3v3 (half court) and 5v5 (full court) basketball for SportsServer.
  Timing-based, like the other sports:
    • You have the ball → pick 🏀 Layup / 🎯 Jumper (2) / 🔥 3PT / 🤝 Pass and HIT inside the green zone
      (each move has its own zone: a layup is easy, a three is hard). Miss the zone = brick / bad pass.
    • Shot clock: hold the ball too long and it's a turnover.
    • Defense: when the other team shoots, a human defender gets a quick 🛡️ BLOCK meter.
    • Misses go to a rebound (offense or defense), makes = 2 or 3 points and the other team gets the ball.
    • Game clock: when time is up the leader wins; tied = next basket wins.
  Everyone sees it: players run to their spots, the ball is in the handler's hand, passes and shots fly,
  shooters jump, the scoreboard updates. Missing spots are 🤖 CPUs (teammates AND opponents).
]]
local TweenService = game:GetService("TweenService")
local BB = {}
local A -- api from SportsServer
local rand = Random.new()

function BB.init(api) A = api end

local function other(s) return s == "A" and "B" or "A" end
local function alive(court, seq)
	local bb = court.bb
	return bb and court.state == "Playing" and court.token == bb.token and (seq == nil or seq == bb.seq)
end
local function viewers(court, msg) A.toastCourt(court, msg) end

---------------------------------------------------------------- geometry
-- the hoop the given side is attacking (half court: both attack the same hoop)
local function hoopOf(court, side)
	local h = court.hoops
	if #h == 1 then return h[1] end
	return side == "A" and h[2] or h[1]
end
local OFF = {
	[3] = { { 21, 0 }, { 13, -10 }, { 13, 10 } },
	[5] = { { 21, 0 }, { 14, -11 }, { 14, 11 }, { 4, -13 }, { 6, 5 } },
}
local function spot(court, side, i, offense, attackSide)
	local H = hoopOf(court, attackSide)
	local out = (H.LookVector * Vector3.new(1, 0, 1)).Unit
	local right = out:Cross(Vector3.yAxis)
	local list = OFF[court.cfg.PerSide] or OFF[5]
	local o = list[((i - 1) % #list) + 1]
	local floor = Vector3.new(H.X, court.cf.Y, H.Z)
	local pos
	if offense then pos = floor + out * o[1] + right * o[2]
	else pos = floor + out * (o[1] * 0.72 + 0.5) + right * (o[2] * 0.82) end
	return pos, floor
end
local function root(e) return e.char and e.char:FindFirstChild("HumanoidRootPart") end
local function lift(e)
	local r = root(e)
	local hum = e.char and e.char:FindFirstChildOfClass("Humanoid")
	if not r or not hum then return 3 end
	return hum.RigType == Enum.HumanoidRigType.R15 and (hum.HipHeight + r.Size.Y / 2) or 3
end
local function runTo(e, pos, lookAt, t)
	local r = root(e)
	if not r then return end
	local p = Vector3.new(pos.X, pos.Y + lift(e), pos.Z)
	local l = Vector3.new(lookAt.X, p.Y, lookAt.Z)
	if (l - p).Magnitude < 0.1 then l = p + Vector3.new(0, 0, 1) end
	e.home = CFrame.lookAt(p, l)
	TweenService:Create(r, TweenInfo.new(t or 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = e.home }):Play()
end
local function hop(e, up, t)
	local r = root(e)
	if not r then return end
	local base = e.home or r.CFrame
	TweenService:Create(r, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = base + Vector3.new(0, up, 0) }):Play()
	task.delay(t, function() if r.Parent then TweenService:Create(r, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = base }):Play() end end)
end

-- line everybody up for a possession: `side` attacks
local function formation(court, side, t)
	local H = hoopOf(court, side)
	local hoopFloor = Vector3.new(H.X, court.cf.Y, H.Z)
	for i, e in ipairs(court.sides[side]) do
		local p = spot(court, side, i, true, side)
		runTo(e, p, hoopFloor, t)
	end
	for i, e in ipairs(court.sides[other(side)]) do
		local p = spot(court, other(side), i, false, side)
		local man = court.sides[side][i] and spot(court, side, i, true, side) or hoopFloor + (H.LookVector * Vector3.new(1, 0, 1)).Unit * 20
		runTo(e, p, man, t)
	end
end

---------------------------------------------------------------- the ball
local function ballPart(court)
	local b = court.bbBall
	if b and b.Parent then return b end
	b = Instance.new("Part") b.Name = "GameBall" b.Shape = Enum.PartType.Ball b.Size = Vector3.one * 1.05
	b.Color = court.cfg.BallColor or Color3.fromRGB(225, 105, 35) b.Material = Enum.Material.SmoothPlastic
	b.CanCollide = false b.CanQuery = false b.CanTouch = false b.Massless = true b.Anchored = true b.Transparency = 1
	b.Parent = court.model
	court.bbBall = b
	return b
end
local function release(court)
	local b = court.bbBall
	if court.bbWeld then court.bbWeld:Destroy() court.bbWeld = nil end
	if b and b.Parent then b.Anchored = true b.Transparency = 1 end
end
local function hold(court, e)
	release(court)
	local ch = e and e.char
	local hand = ch and (ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm"))
	if not hand then return end
	local b = ballPart(court)
	b.CFrame = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2 - 0.45, -0.2)
	b.Anchored = false b.Transparency = 0
	local w = Instance.new("WeldConstraint") w.Part0 = hand w.Part1 = b w.Parent = b
	court.bbWeld = w
end
local function fly(court, from, to, time, height, kind, bounceTo)
	local d = { t = "shot", court = court.id, from = from, to = to, time = time, height = height, shot = kind, count = 0,
		ball = "Ball", ballColor = court.cfg.BallColor, ballSize = 1.05, bounceTo = bounceTo }
	A.Event:FireAllClients(d)
end

---------------------------------------------------------------- flow
local possession, giveTurn, shoot

local function zonesFor(cfg)
	local z = {}
	for k, s in pairs(cfg.Shots) do z[k] = s.zone / 2 end
	return z
end

local function clockCheck(court)
	-- returns true if the game ended
	local bb = court.bb
	if os.clock() < bb.ends then return false end
	local a, b = court.score.A, court.score.B
	if a ~= b then A.endMatch(court, a > b and "A" or "B", "time") return true end
	if not bb.overtime then bb.overtime = true viewers(court, "⏱ Time! It's tied — NEXT BASKET WINS!") end
	return false
end

local function teamPick(list, notE)
	local pool = {}
	for _, e in ipairs(list) do if e ~= notE then table.insert(pool, e) end end
	if #pool == 0 then return nil end
	return pool[rand:NextInteger(1, #pool)]
end

function possession(court, side, handler, reason)
	local bb = court.bb
	if not alive(court) then return end
	if clockCheck(court) then return end
	bb.seq += 1
	local seq = bb.seq
	bb.poss = side court.serve = side
	bb.passes = 0
	bb.turn, bb.block = nil, nil
	handler = handler or teamPick(court.sides[side])
	if not handler then return A.forfeitCheck(court) end
	formation(court, side, 0.9)
	hold(court, handler)
	if reason then viewers(court, reason) end
	A.broadcast(court)
	task.delay(1.0, function() if alive(court, seq) then giveTurn(court, handler) end end)
end

local function turnover(court, side, why, to)
	local bb = court.bb
	bb.seq += 1
	local seq = bb.seq
	local stealer = to or teamPick(court.sides[other(side)])
	viewers(court, why)
	task.delay(0.9, function() if alive(court, seq) then possession(court, other(side), stealer) end end)
end

local function pass(court, from, to)
	local bb = court.bb
	bb.seq += 1
	local seq = bb.seq
	bb.turn = nil
	A.play(from, "swing", 1.4)
	release(court)
	fly(court, A.handPos(from), A.handPos(to), 0.45, 1.2, "pass")
	bb.passes += 1
	task.delay(0.45, function()
		if not alive(court, seq) then return end
		hold(court, to)
		giveTurn(court, to)
	end)
end

function giveTurn(court, e)
	local bb = court.bb
	if not alive(court) then return end
	if not e or not (e.cpu or (e.player and e.player.Parent)) then
		return turnover(court, bb.poss, "🏀 Loose ball!")
	end
	bb.seq += 1
	local seq = bb.seq
	local cfg = court.cfg
	local side = bb.poss
	local speed = cfg.MeterSpeed or 1
	local turn = { handler = e, side = side, start = os.clock(), seq = seq, center = rand:NextNumber(0.25, 0.75) }
	bb.turn = turn
	A.broadcast(court)
	if e.player then
		A.Event:FireClient(e.player, { t = "incoming", court = court.id, time = cfg.ShotClock, center = turn.center, half = cfg.Shots.mid.zone / 2,
			speed = speed, zones = zonesFor(cfg), label = "Your ball", hint = "🏀 YOUR BALL! Pick a move, then HIT in the green" })
		task.delay(cfg.ShotClock + 0.25, function()
			if alive(court, seq) and bb.turn == turn then
				bb.turn = nil
				turnover(court, side, ("⏱ Shot clock! %s held the ball too long — turnover"):format(e.name))
			end
		end)
	else
		-- 🤖 CPU decides
		task.delay(rand:NextNumber(0.9, 2.0), function()
			if not alive(court, seq) or bb.turn ~= turn then return end
			bb.turn = nil
			local mates = court.sides[side]
			if #mates > 1 and bb.passes < 3 and rand:NextNumber() < (bb.passes == 0 and 0.6 or 0.35) then
				local to = teamPick(mates, e)
				if rand:NextNumber() < cfg.CpuStealChance then
					local st = teamPick(court.sides[other(side)])
					release(court)
					if st then fly(court, A.handPos(e), A.handPos(st), 0.4, 1, "pass") end
					return turnover(court, side, ("🥷 STEAL! %s picks off the pass"):format(st and st.name or "Defense"), st)
				end
				return pass(court, e, to)
			end
			local roll = rand:NextNumber()
			local kind = roll < 0.38 and "layup" or (roll < 0.72 and "mid" or "three")
			shoot(court, e, kind, rand:NextNumber() < cfg.Shots[kind].cpu)
		end)
	end
end

local function rebound(court, shooterSide, spotPos)
	local bb = court.bb
	bb.seq += 1
	local seq = bb.seq
	local offensive = rand:NextNumber() < court.cfg.OffRebound
	local side = offensive and shooterSide or other(shooterSide)
	local reb = teamPick(court.sides[side])
	if not reb then return end
	runTo(reb, Vector3.new(spotPos.X, court.cf.Y, spotPos.Z), Vector3.new(court.cf.X, court.cf.Y, court.cf.Z), 0.5)
	task.delay(0.55, function()
		if not alive(court, seq) then return end
		if offensive then
			viewers(court, ("💪 Offensive rebound — %s!"):format(reb.name))
			hold(court, reb)
			bb.passes = 0
			task.delay(0.5, function() if alive(court) then giveTurn(court, reb) end end)
		else
			possession(court, side, reb, ("🧱 Defensive rebound — %s"):format(reb.name))
		end
	end)
end

-- finish a shot (after a possible block window)
local function resolveShot(court, sh, blockedBy)
	local bb = court.bb
	if not alive(court, sh.seq) then return end
	bb.block = nil
	bb.seq += 1
	local seq = bb.seq
	local H = hoopOf(court, sh.side)
	local rim = H.Position
	local from = A.handPos(sh.e) + Vector3.new(0, 1, 0)
	local cfgShot = court.cfg.Shots[sh.kind]
	if blockedBy then
		local out = (H.LookVector * Vector3.new(1, 0, 1)).Unit
		local land = from + out * 6 + Vector3.new(0, -3, 0)
		fly(court, from, land, 0.5, 2, "block")
		A.play(blockedBy, "swing", 1.5) hop(blockedBy, 2.6, 0.25)
		A.Event:FireAllClients({ t = "point", court = court.id, side = other(sh.side), reason = ("🛡️ REJECTED! %s blocks %s"):format(blockedBy.name, sh.e.name), landing = land, score = { A = court.score.A, B = court.score.B } })
		task.delay(0.9, function() if alive(court, seq) then possession(court, other(sh.side), blockedBy) end end)
		return
	end
	local t, h = cfgShot.time, cfgShot.height
	if sh.made then
		fly(court, from, rim + Vector3.new(0, 0.6, 0), t, h, sh.kind, rim + Vector3.new(0, -3.2, 0))
	else
		local out = (H.LookVector * Vector3.new(1, 0, 1)).Unit
		local right = out:Cross(Vector3.yAxis)
		local reb = Vector3.new(rim.X, court.cf.Y + 3, rim.Z) + out * rand:NextNumber(4, 9) + right * rand:NextNumber(-6, 6)
		fly(court, from, rim + Vector3.new(rand:NextNumber(-0.6, 0.6), 0.4, 0), t, h, sh.kind, reb)
		sh.reb = reb
	end
	task.delay(t + 0.15, function()
		if not alive(court, seq) then return end
		if sh.made then
			local pts = cfgShot.points
			court.score[sh.side] += pts
			local what = sh.kind == "three" and "drains a THREE 🔥" or (sh.kind == "layup" and "lays it in" or "hits the jumper")
			A.Event:FireAllClients({ t = "point", court = court.id, side = sh.side, reason = ("🏀 %s %s! +%d"):format(sh.e.name, what, pts), landing = rim, score = { A = court.score.A, B = court.score.B } })
			for _, x in ipairs(court.sides[sh.side]) do A.play(x, "cheer") end
			local a, b = court.score.A, court.score.B
			if math.max(a, b) >= court.cfg.WinScore or court.bb.overtime then
				A.broadcast(court)
				A.endMatch(court, a > b and "A" or "B", "score")
				return
			end
			A.broadcast(court)
			task.delay(1.2, function() if alive(court, seq) then possession(court, other(sh.side), nil) end end)
		else
			viewers(court, ("🧱 %s misses the %s"):format(sh.e.name, cfgShot.short))
			rebound(court, sh.side, sh.reb)
		end
	end)
end

function shoot(court, e, kind, made)
	local bb = court.bb
	bb.turn = nil
	bb.seq += 1
	local seq = bb.seq
	local side = bb.poss
	local H = hoopOf(court, side)
	local out = (H.LookVector * Vector3.new(1, 0, 1)).Unit
	local hoopFloor = Vector3.new(H.X, court.cf.Y, H.Z)
	local windup = 0.45
	if kind == "layup" then
		-- drive to the basket first
		runTo(e, hoopFloor + out * 3.2, hoopFloor, 0.55)
		windup = 0.75
	elseif kind == "three" then
		local r = root(e)
		if r then
			local flat = Vector3.new(r.Position.X, court.cf.Y, r.Position.Z)
			local d = (flat - hoopFloor)
			if d.Magnitude < 16 then runTo(e, hoopFloor + (d.Magnitude > 0.1 and d.Unit or out) * 16.5, hoopFloor, 0.4) end
		end
	end
	task.delay(windup - 0.3, function()
		if not alive(court, seq) then return end
		A.play(e, "swing", 1.2)
		hop(e, kind == "layup" and 2.8 or 1.8, 0.3)
	end)
	local sh = { e = e, kind = kind, made = made, side = side, seq = seq }
	-- block window: a human defender gets a quick meter, otherwise a CPU defender may block
	local humans = {}
	for _, d in ipairs(court.sides[other(side)]) do if d.player and d.player.Parent then table.insert(humans, d) end end
	if #humans > 0 then
		local d = humans[rand:NextInteger(1, #humans)]
		local win = court.cfg.BlockWindow
		bb.block = { defender = d, start = os.clock(), center = rand:NextNumber(0.3, 0.7), half = court.cfg.BlockZone / 2, shot = sh, done = false, time = win }
		A.Event:FireClient(d.player, { t = "incoming", court = court.id, time = win, center = bb.block.center, half = bb.block.half, speed = court.cfg.MeterSpeed or 1,
			fast = true, label = "BLOCK", hint = ("🛡️ %s is shooting — HIT to BLOCK!"):format(e.name) })
		local blk = bb.block
		task.delay(win + 0.05, function()
			if bb.block == blk and not blk.done then blk.done = true resolveShot(court, sh, nil) end
		end)
	else
		local blocked = nil
		if #court.sides[other(side)] > 0 and rand:NextNumber() < (kind == "layup" and court.cfg.CpuBlockChance * 1.5 or court.cfg.CpuBlockChance) then
			blocked = teamPick(court.sides[other(side)])
		end
		task.delay(windup, function() resolveShot(court, sh, blocked) end)
	end
end

---------------------------------------------------------------- API used by SportsServer
function BB.start(court, token)
	if court.state ~= "Playing" or court.token ~= token then return end
	local mk = court.markers
	court.hoops = {}
	for i = 1, 2 do local h = mk:FindFirstChild("Hoop" .. i) if h then table.insert(court.hoops, h.CFrame) end end
	court.bb = { token = court.token, seq = 0, ends = os.clock() + court.cfg.GameTime, passes = 0 }
	local side = court.serve or "A"
	viewers(court, ("🏀 Tip-off! Team %s wins the jump ball"):format(side))
	possession(court, side, nil)
end

function BB.hit(court, player, data)
	local bb = court.bb
	if not bb or court.state ~= "Playing" then return { ok = false } end
	local cfg = court.cfg
	local speed = cfg.MeterSpeed or 1
	-- 🛡️ block attempt
	local blk = bb.block
	if blk and not blk.done and blk.defender.player == player then
		blk.done = true
		local t = A.pressedAt({ start = blk.start }, data.t)
		local pos = A.meterAt(t, speed)
		local ok = math.abs(pos - blk.center) <= blk.half and t <= blk.time + 0.1
		resolveShot(court, blk.shot, ok and blk.defender or nil)
		return { ok = true, hit = ok, msg = ok and "🛡️ BLOCKED!" or "❌ Missed the block" }
	end
	-- 🏀 offense move
	local turn = bb.turn
	if not turn or turn.handler.player ~= player then return { ok = false } end
	bb.turn = nil
	local kind = cfg.Shots[data.shot] and data.shot or "mid"
	local t = A.pressedAt({ start = turn.start }, data.t)
	local pos = A.meterAt(t, speed)
	local inZone = math.abs(pos - turn.center) <= cfg.Shots[kind].zone / 2
	if kind == "pass" then
		local to = teamPick(court.sides[turn.side], turn.handler)
		if not to then bb.turn = turn return { ok = false, msg = "No teammate to pass to" } end
		if inZone then pass(court, turn.handler, to) return { ok = true, hit = true, msg = "🤝 Pass to " .. to.name } end
		local st = teamPick(court.sides[other(turn.side)])
		release(court)
		if st then fly(court, A.handPos(turn.handler), A.handPos(st), 0.4, 1, "pass") end
		turnover(court, turn.side, ("🥷 Bad pass — %s steals it!"):format(st and st.name or "Defense"), st)
		return { ok = true, hit = false, msg = "❌ Bad pass — stolen!" }
	end
	local made = rand:NextNumber() < (inZone and cfg.Shots[kind].good or cfg.Shots[kind].bad)
	shoot(court, turn.handler, kind, made)
	return { ok = true, hit = inZone, msg = inZone and ("✅ Good release — " .. cfg.Shots[kind].short .. "!") or "😬 Off-rhythm shot…" }
end

function BB.stop(court)
	release(court)
	if court.bbBall then court.bbBall:Destroy() court.bbBall = nil end
	court.bb = nil
end

function BB.clock(court)
	local bb = court.bb
	return bb and math.max(0, bb.ends - os.clock()) or nil
end

return BB
