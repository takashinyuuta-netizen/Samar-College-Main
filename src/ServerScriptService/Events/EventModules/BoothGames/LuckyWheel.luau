-- 🎡 LUCKY WHEEL: one free spin per player per fair. The SERVER picks the prize, and the big wheel on the
-- stall really spins (with clicks) and stops on that prize for everyone to see.
local RunService = game:GetService("RunService")
local G = { Name = "Lucky Wheel", Icon = "🎡", Color = Color3.fromRGB(240, 190, 60),
	Description = "One free spin per fair — try your luck! Up to +15 🎟️." }
local PRIZES = { { t = 1, w = 30 }, { t = 2, w = 25 }, { t = 3, w = 20 }, { t = 5, w = 15 }, { t = 8, w = 7 }, { t = 15, w = 3 } }

function G.Bind(ctx, B, fx)
	local W = B.game.Wheel
	B.wheel = W
	B.pivot0 = W:GetPivot()
	B.axis = B.cf.LookVector
	B.angle = 0
	B.blades = {}
	for _, p in ipairs(W:GetChildren()) do
		if p.Name == "Segment" then table.insert(B.blades, { prize = p:GetAttribute("Prize"), off = p.Position - B.pivot0.Position }) end
	end
end

local function pivotAt(B, phi)
	local p = B.pivot0.Position
	return CFrame.new(p) * CFrame.fromAxisAngle(B.axis, phi) * CFrame.new(-p) * B.pivot0
end
-- the wheel angle that puts a blade straight up (under the pointer)
local function angleFor(B, blade)
	local best, bestDot = 0, -2
	for deg = 0, 359 do
		local v = CFrame.fromAxisAngle(B.axis, math.rad(deg)):VectorToWorldSpace(blade.off).Unit
		local d = v:Dot(B.cf.UpVector)
		if d > bestDot then best, bestDot = math.rad(deg), d end
	end
	return best
end

function G.Start(ctx, player, s, B, fx)
	ctx.Data.spun = ctx.Data.spun or {}
	if ctx.Data.spun[player] then return { kind = "info", text = "🎡 You already used your free spin this fair!", seconds = 3 } end
	local labels = {} for _, p in ipairs(PRIZES) do table.insert(labels, "+" .. p.t) end
	fx.say(B, "🎡 Ready to spin!")
	return { kind = "wheel", segments = labels }
end

local function spin(B, fx, prizeIndex, done)
	local options = {}
	for _, b in ipairs(B.blades) do if b.prize == prizeIndex then table.insert(options, b) end end
	local blade = options[fx.rand:NextInteger(1, #options)]
	local target = angleFor(B, blade)
	local from = B.angle
	local delta = (target - from) % (math.pi * 2)
	local total = math.pi * 2 * 5 + delta
	fx.anim(B, "throw")
	local t0, dur, lastTick = os.clock(), 5, 0
	while true do
		local t = math.min(1, (os.clock() - t0) / dur)
		local e = 1 - (1 - t) ^ 4
		local phi = from + total * e
		B.wheel:PivotTo(pivotAt(B, phi))
		local tick = math.floor(phi / (math.pi / 6))
		if tick ~= lastTick then lastTick = tick fx.sound(B, "Click", 0.25, 1.2) end
		if t >= 1 then B.angle = phi % (math.pi * 2) break end
		RunService.Heartbeat:Wait()
	end
	done()
end

function G.Action(ctx, player, s, data, B, fx)
	if data.op ~= "spin" or ctx.Data.spun[player] or s.spinning then return { ok = false, msg = "Only one spin per fair" } end
	ctx.Data.spun[player] = true
	s.spinning = true
	local total = 0 for _, p in ipairs(PRIZES) do total += p.w end
	local r, pick = math.random() * total, 1
	for i, p in ipairs(PRIZES) do r -= p.w if r <= 0 then pick = i break end end
	local t = PRIZES[pick].t
	fx.say(B, "🎡 Spinning…")
	task.spawn(spin, B, fx, pick, function()
		fx.say(B, ("🎡 Landed on +%d!"):format(t))
		if t >= 5 then fx.confetti(B) fx.anim(B, "cheer") else fx.sound(B, "Ping", 0.5, 1.2) end
	end)
	return { ok = true, done = true, closeDelay = 7, tickets = t, segment = pick, msg = ("🎡 The wheel lands on +%d! +%d 🎟️"):format(t, t) }
end

return G
