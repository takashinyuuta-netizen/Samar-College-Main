-- 🏀 HOOP SHOT: 3 shots. Stop the marker in the green zone to sink the basket (+3 tickets each).
-- The ball really arcs from the player's hands into the hoop (or clangs off the rim) for everyone to see.
local Meter = require(script.Parent:WaitForChild("_Meter"))
local G = { Name = "Hoop Shot", Icon = "🏀", Color = Color3.fromRGB(235, 110, 35),
	Description = "Stop the marker in the green zone to sink the shot! 3 balls, +3 🎟️ per basket." }
local HALF, SHOTS, PER = 0.075, 3, 3

local function makeBall(fx)
	local m = Instance.new("Model") m.Name = "Basketball"
	local b = fx.part(m, "Ball", Vector3.new(0.9, 0.9, 0.9), CFrame.new(), Color3.fromRGB(230, 110, 40), Enum.Material.Plastic, Enum.PartType.Ball)
	fx.part(m, "Seam", Vector3.new(0.03, 0.92, 0.92), CFrame.new(), Color3.fromRGB(30, 20, 15), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	fx.part(m, "Seam2", Vector3.new(0.03, 0.92, 0.92), CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(30, 20, 15), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	m.PrimaryPart = b
	return m
end
function G.HandProp(fx) return makeBall(fx) end

local function setScreen(B, text) local scr = B.game:FindFirstChild("ScoreScreen") if scr then scr.Sign_Front.Text.Text = text end end

function G.Start(ctx, player, s, B, fx)
	s.start = os.clock() s.center = Meter.newCenter() s.shots = SHOTS s.last = 0 s.baskets = 0
	setScreen(B, "🏀 0")
	fx.say(B, "🏀 3 shots • 🎟️ 0")
	return { kind = "meter", zones = { { center = s.center, half = HALF, label = "+3" } }, shots = s.shots, speed = Meter.SPEED, verb = "SHOOT" }
end

local function shoot(B, fx, hit, baskets)
	fx.anim(B, "throw", 0.9)
	task.wait(0.3)
	local rim = B.game.RimCenter.Position
	local ball = fx.temp(B, makeBall(fx))
	local from = fx.hand(B).Position + Vector3.new(0, 0.6, 0)
	ball:PivotTo(CFrame.new(from))
	fx.sound(B, "Swoosh", 0.4, 0.8)
	if hit then
		fx.fly(ball, CFrame.new(from), CFrame.new(rim + Vector3.new(0, 0.9, 0)), 4.5, 0.85, 8)
		fx.move(ball, CFrame.new(rim - Vector3.new(0, 1.3, 0)), 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		fx.burst(rim, Color3.fromRGB(255, 160, 60), 20, 7)
		fx.sound(B, "Ping", 0.55, 1.6)
		setScreen(B, "🏀 " .. baskets)
		task.wait(0.25)
		fx.fly(ball, ball:GetPivot(), fx.at(B, -2.5, 2.4, 0.5), 0.6, 0.35, 4)
	else
		local side = fx.rand:NextNumber() < 0.5 and -1 or 1
		local edge = rim + B.cf.RightVector * 0.85 * side + Vector3.new(0, 0.35, 0)
		fx.fly(ball, CFrame.new(from), CFrame.new(edge), 4.2, 0.85, 8)
		fx.sound(B, "Clang", 0.5, 0.9)
		fx.fly(ball, ball:GetPivot(), CFrame.new(edge + B.cf.RightVector * 1.6 * side - B.cf.LookVector * -0.4 + Vector3.new(0, -4.0, 0)), 1.6, 0.6, 6)
	end
end

function G.Action(ctx, player, s, data, B, fx)
	if data.op ~= "shoot" or s.shots <= 0 or os.clock() - s.last < 0.4 then return { ok = false } end
	s.last = os.clock()
	local pos = Meter.position(s.start)
	local hit = math.abs(pos - s.center) <= HALF
	s.shots -= 1
	if hit then s.baskets += 1 end
	task.spawn(shoot, B, fx, hit, s.baskets)
	fx.say(B, ("🏀 %d left • 🎟️ %d"):format(s.shots, (s.tickets or 0) + (hit and PER or 0)))
	local res = { ok = true, pos = pos, hit = hit, tickets = hit and PER or 0, shots = s.shots,
		msg = hit and "🏀 SWISH! +3 🎟️" or "Clang! Off the rim…" }
	if s.shots <= 0 then
		res.done = true
		if s.baskets == SHOTS then task.delay(1.4, function() fx.confetti(B) fx.anim(B, "cheer") end) end
	else s.center = Meter.newCenter() s.start = os.clock() res.zones = { { center = s.center, half = HALF, label = "+3" } } end
	return res
end

return G
