-- 🎯 DART THROW: 3 darts. Bullseye = 3 tickets, inner ring = 2, outer ring = 1.
-- The dart really flies to the board and sticks where it landed (everyone can see it).
local Meter = require(script.Parent:WaitForChild("_Meter"))
local G = { Name = "Dart Throw", Icon = "🎯", Color = Color3.fromRGB(70, 130, 220),
	Description = "Throw darts at the board — bullseye +3, inner +2, outer +1!" }
local SHOTS = 3
local FLIGHT = { Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 200, 255), Color3.fromRGB(255, 220, 60) }

local function makeDart(fx, color)
	local m = Instance.new("Model") m.Name = "Dart"
	local axis = CFrame.Angles(0, math.rad(90), 0) -- cylinders along local Z (the tip points to -Z = forward)
	-- invisible root with NO rotation = the model's pivot, so PivotTo(CFrame.lookAt(a, b)) aims the tip at b
	local root = fx.part(m, "Root", Vector3.new(0.1, 0.1, 0.1), CFrame.new(), Color3.new(1, 1, 1)) root.Transparency = 1
	local shaft = fx.part(m, "Shaft", Vector3.new(0.85, 0.08, 0.08), CFrame.new(0, 0, 0) * axis, Color3.fromRGB(205, 205, 210), Enum.Material.Metal, Enum.PartType.Cylinder)
	fx.part(m, "Tip", Vector3.new(0.3, 0.04, 0.04), CFrame.new(0, 0, -0.55) * axis, Color3.fromRGB(150, 150, 155), Enum.Material.Metal, Enum.PartType.Cylinder)
	fx.part(m, "Barrel", Vector3.new(0.3, 0.12, 0.12), CFrame.new(0, 0, -0.25) * axis, Color3.fromRGB(60, 60, 70), Enum.Material.Metal, Enum.PartType.Cylinder)
	fx.part(m, "FlightA", Vector3.new(0.02, 0.3, 0.3), CFrame.new(0, 0, 0.45), color)
	fx.part(m, "FlightB", Vector3.new(0.3, 0.02, 0.3), CFrame.new(0, 0, 0.45), color)
	m.PrimaryPart = root
	return m
end
G.makeDart = makeDart

function G.HandProp(fx) return makeDart(fx, FLIGHT[fx.rand:NextInteger(1, 3)]) end

local function zones(c) return { { center = c, half = 0.2, label = "+1" }, { center = c, half = 0.11, label = "+2" }, { center = c, half = 0.045, label = "+3" } } end

function G.Start(ctx, player, s, B, fx)
	s.start = os.clock() s.center = Meter.newCenter() s.shots = SHOTS s.last = 0
	fx.say(B, "🎯 3 darts • 🎟️ 0")
	return { kind = "meter", zones = zones(s.center), shots = s.shots, speed = Meter.SPEED, verb = "THROW" }
end

local function throw(B, fx, t)
	fx.anim(B, "throw")
	task.wait(0.25)
	local center = B.game.BoardCenter.Position
	local r = t == 3 and fx.rand:NextNumber(0, 0.2) or (t == 2 and fx.rand:NextNumber(0.6, 1.0) or (t == 1 and fx.rand:NextNumber(1.2, 1.8) or fx.rand:NextNumber(2.35, 3.2)))
	local a = fx.rand:NextNumber(0, math.pi * 2)
	local hitPos = center + B.cf.RightVector * math.cos(a) * r + B.cf.UpVector * math.sin(a) * r
	local inward = B.cf.LookVector * -1 -- toward the back wall
	local dart = fx.temp(B, makeDart(fx, FLIGHT[fx.rand:NextInteger(1, 3)]))
	local from = fx.hand(B)
	local finalCF = CFrame.lookAt(hitPos - inward * 0.35, hitPos + inward)
	dart:PivotTo(CFrame.lookAt(from.Position, hitPos))
	fx.sound(B, "Swoosh", 0.45, 1.4)
	fx.fly(dart, CFrame.lookAt(from.Position, hitPos), finalCF, 0.6, 0.42)
	fx.sound(B, "Ping", t > 0 and 0.5 or 0.3, t == 3 and 1.8 or 0.9)
	if t > 0 then fx.burst(hitPos - inward * 0.2, t == 3 and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 230, 120), 10 + t * 8, 6) end
	if t == 3 then fx.confetti(B) end
end

function G.Action(ctx, player, s, data, B, fx)
	if data.op ~= "shoot" or s.shots <= 0 or os.clock() - s.last < 0.35 then return { ok = false } end
	s.last = os.clock()
	local pos = Meter.position(s.start)
	local d = math.abs(pos - s.center)
	local t = d <= 0.045 and 3 or (d <= 0.11 and 2 or (d <= 0.2 and 1 or 0))
	s.shots -= 1
	task.spawn(throw, B, fx, t)
	fx.say(B, ("🎯 %d left • 🎟️ %d"):format(s.shots, (s.tickets or 0) + t))
	local res = { ok = true, pos = pos, hit = t > 0, tickets = t, shots = s.shots,
		msg = t == 3 and "🎯 BULLSEYE! +3 🎟️" or (t > 0 and ("Hit! +" .. t .. " 🎟️") or "Missed the target!") }
	if s.shots <= 0 then res.done = true else s.center = Meter.newCenter() s.start = os.clock() res.zones = zones(s.center) end
	return res
end

return G
