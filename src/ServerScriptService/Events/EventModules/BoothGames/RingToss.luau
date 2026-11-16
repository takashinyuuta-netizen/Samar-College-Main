-- ⭕ RING TOSS: 3 rings. Stop the moving marker in the green zone to ring a bottle (+2 tickets each).
-- Everyone around sees the ring fly from the player's hand and land on (or bounce off) a bottle.
local Meter = require(script.Parent:WaitForChild("_Meter"))
local G = { Name = "Ring Toss", Icon = "⭕", Color = Color3.fromRGB(230, 90, 80),
	Description = "Stop the marker in the green zone to ring a bottle! 3 rings, +2 🎟️ per ringer." }
local HALF, SHOTS, PER_HIT = 0.09, 3, 2
local COLS = { Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 160, 255), Color3.fromRGB(255, 220, 60), Color3.fromRGB(120, 220, 120), Color3.fromRGB(230, 120, 255) }

local function makeRing(fx, color)
	local m = Instance.new("Model") m.Name = "TossRing"
	local c = fx.part(m, "Center", Vector3.new(0.1, 0.1, 0.1), CFrame.new(), color) c.Transparency = 1
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		fx.part(m, "Seg", Vector3.new(0.27, 0.09, 0.11), CFrame.new(math.cos(a) * 0.45, 0, math.sin(a) * 0.45) * CFrame.Angles(0, -a + math.pi / 2, 0), color)
	end
	m.PrimaryPart = c
	return m
end

function G.HandProp(fx) local r = makeRing(fx, COLS[fx.rand:NextInteger(1, #COLS)]) return r end

function G.Bind(ctx, B, fx)
	B.bottles = {}
	for _, b in ipairs(B.game:GetChildren()) do
		if b.Name == "Bottle" and b:FindFirstChild("Lip") then table.insert(B.bottles, { lip = b.Lip.Position, neck = b.Neck.Position }) end
	end
end

function G.Start(ctx, player, s, B, fx)
	s.start = os.clock() s.center = Meter.newCenter() s.shots = SHOTS s.last = 0
	fx.say(B, "⭕ 3 rings • 🎟️ 0")
	return { kind = "meter", zones = { { center = s.center, half = HALF, label = "+2" } }, shots = s.shots, speed = Meter.SPEED, verb = "TOSS" }
end

local function throw(B, fx, hit)
	fx.anim(B, "throw")
	task.wait(0.28)
	local ring = fx.temp(B, makeRing(fx, COLS[fx.rand:NextInteger(1, #COLS)]))
	local bottle = B.bottles[fx.rand:NextInteger(1, #B.bottles)]
	local from = fx.hand(B)
	ring:PivotTo(from)
	fx.sound(B, "Swoosh", 0.5, 1.1)
	if hit then
		fx.fly(ring, CFrame.new(from.Position), CFrame.new(bottle.lip + Vector3.new(0, 0.35, 0)), 3, 0.65, 0)
		fx.move(ring, CFrame.new(bottle.neck - Vector3.new(0, 0.2, 0)), 0.18, Enum.EasingStyle.Bounce)
		fx.sound(B, "Ping", 0.6, 1.5)
		fx.burst(bottle.lip, Color3.fromRGB(255, 230, 120), 25, 8)
	else
		local side = (fx.rand:NextNumber() < 0.5) and -1 or 1
		local clang = bottle.lip + B.cf.RightVector * 0.35 * side + Vector3.new(0, 0.1, 0)
		fx.fly(ring, CFrame.new(from.Position), CFrame.new(clang) * CFrame.Angles(math.rad(30), 0, 0), 3, 0.65, 0)
		fx.sound(B, "Clang", 0.4, 1.4)
		local land = bottle.neck + B.cf.RightVector * (0.9 * side) - Vector3.new(0, 1.15, 0)
		fx.fly(ring, ring:GetPivot(), CFrame.new(land) * CFrame.Angles(0, fx.rand:NextNumber(0, 6), 0), 0.8, 0.35, 0)
	end
end

function G.Action(ctx, player, s, data, B, fx)
	if data.op ~= "shoot" or s.shots <= 0 or os.clock() - s.last < 0.35 then return { ok = false } end
	s.last = os.clock()
	local pos = Meter.position(s.start)
	local hit = math.abs(pos - s.center) <= HALF
	s.shots -= 1
	task.spawn(throw, B, fx, hit)
	fx.say(B, ("⭕ %d left • 🎟️ %d"):format(s.shots, (s.tickets or 0) + (hit and PER_HIT or 0)))
	local res = { ok = true, pos = pos, hit = hit, tickets = hit and PER_HIT or 0, shots = s.shots,
		msg = hit and "⭕ Ringer! +2 🎟️" or "Clink! It bounced off…" }
	if s.shots <= 0 then res.done = true else s.center = Meter.newCenter() s.start = os.clock() res.zones = { { center = s.center, half = HALF, label = "+2" } } end
	return res
end

return G
