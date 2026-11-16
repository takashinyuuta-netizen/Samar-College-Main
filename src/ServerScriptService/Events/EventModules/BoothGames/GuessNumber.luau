-- 🔮 GUESS THE NUMBER: the fortune-teller booth thinks of 1–50. Fewer guesses = more tickets (max 6).
-- Every guess shows on the big LED board (with HIGHER / LOWER) so the crowd can help!
local TweenService = game:GetService("TweenService")
local G = { Name = "Guess the Number", Icon = "🔮", Color = Color3.fromRGB(150, 100, 210),
	Description = "I'm thinking of a number from 1 to 50. Guess it in as few tries as you can!" }
local MAX = 6

local function board(B) return B.game.LEDBoard.BoardGui end
local function idle(B)
	local g = board(B)
	g.Big.Text = "??" g.Big.TextColor3 = Color3.fromRGB(255, 230, 90)
	g.Hint.Text = "" g.History.Text = "" g.Tries.Text = "TRIES " .. MAX
end
local function glow(B, color)
	local orb = B.game:FindFirstChild("CrystalBall")
	local l = orb and orb:FindFirstChildOfClass("PointLight")
	if l then
		l.Color = color
		l.Brightness = 5
		TweenService:Create(l, TweenInfo.new(0.8), { Brightness = 1.5 }):Play()
	end
end

function G.Bind(ctx, B, fx) idle(B) end

function G.Start(ctx, player, s, B, fx)
	s.secret = math.random(1, 50) s.tries = 0 s.history = {}
	idle(B)
	board(B).Hint.Text = "🔮 THINKING…"
	glow(B, Color3.fromRGB(170, 110, 255))
	fx.anim(B, "wave")
	fx.say(B, "🔮 6 tries left")
	return { kind = "guess", min = 1, max = 50, tries = MAX }
end

function G.Action(ctx, player, s, data, B, fx)
	local n = tonumber(data.guess)
	if data.op ~= "guess" or not n or n ~= math.floor(n) or n < 1 or n > 50 then return { ok = false, msg = "Type a whole number from 1 to 50" } end
	s.tries += 1
	local g = board(B)
	g.Big.Text = tostring(n)
	g.Tries.Text = "TRIES " .. (MAX - s.tries)
	fx.anim(B, "point")
	if n == s.secret then
		local t = math.max(1, 7 - s.tries)
		g.Hint.Text = "🎉 CORRECT!" g.Hint.TextColor3 = Color3.fromRGB(120, 255, 140) g.Big.TextColor3 = Color3.fromRGB(120, 255, 140)
		glow(B, Color3.fromRGB(120, 255, 140))
		fx.confetti(B) fx.anim(B, "cheer")
		fx.say(B, ("🔮 Got it in %d! • 🎟️ +%d"):format(s.tries, t))
		return { ok = true, done = true, tickets = t, msg = ("🎉 %d is right! Found it in %d tries: +%d 🎟️"):format(n, s.tries, t) }
	end
	local higher = n < s.secret
	table.insert(s.history, n .. (higher and "↑" or "↓"))
	g.History.Text = table.concat(s.history, "  ")
	g.Hint.Text = higher and "⬆ HIGHER" or "⬇ LOWER"
	g.Hint.TextColor3 = higher and Color3.fromRGB(120, 220, 255) or Color3.fromRGB(255, 140, 120)
	glow(B, higher and Color3.fromRGB(120, 220, 255) or Color3.fromRGB(255, 140, 120))
	fx.sound(B, "Ping", 0.35, higher and 1.3 or 0.8)
	if s.tries >= MAX then
		g.Hint.Text = "IT WAS " .. s.secret g.Hint.TextColor3 = Color3.fromRGB(255, 200, 120)
		fx.say(B, "🔮 Out of tries!")
		return { ok = true, done = true, tickets = 0, msg = ("Out of tries! The number was %d."):format(s.secret) }
	end
	fx.say(B, ("🔮 %d tries left"):format(MAX - s.tries))
	return { ok = true, tickets = 0, hint = higher and "⬆️ Higher!" or "⬇️ Lower!", triesLeft = MAX - s.tries }
end

function G.Stop(ctx, player, s, B, fx)
	task.delay(4, function() if not B.session then idle(B) end end)
end

return G
