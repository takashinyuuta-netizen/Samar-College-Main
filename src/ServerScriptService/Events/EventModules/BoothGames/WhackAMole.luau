-- 🔨 WHACK-A-MOLE: 20 seconds. Moles pop out of the 9 holes in the cabinet — click/tap them!
-- +1 ticket per mole, golden moles +3. The player swings a real mallet and the moles really pop up and
-- get bonked, so everyone watching sees the game. Whacks are checked on the server.
local G = { Name = "Whack-a-Mole", Icon = "🔨", Color = Color3.fromRGB(60, 170, 80),
	Description = "Click/tap the moles before they hide! +1 🎟️ each, golden moles +3." }
local ROUND = 20
G.Camera = { pos = Vector3.new(2.0, 9.8, -8.6), look = Vector3.new(0, 4.4, 0.6) } -- look down into the mole cabinet
local HAT, GOLD = Color3.fromRGB(250, 205, 50), Color3.fromRGB(255, 215, 0)

function G.HandProp(fx)
	local m = Instance.new("Model") m.Name = "Mallet"
	local h = fx.part(m, "Handle", Vector3.new(0.18, 1.8, 0.18), CFrame.new(0, -0.6, 0), Color3.fromRGB(150, 100, 60), Enum.Material.Wood)
	fx.part(m, "Head", Vector3.new(1.0, 0.65, 0.65), CFrame.new(0, -1.55, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(230, 60, 60), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	m.PrimaryPart = h
	return m
end

local function setScreen(B, text) local scr = B.game:FindFirstChild("ScoreScreen") if scr then scr.Sign_Front.Text.Text = text end end

function G.Bind(ctx, B, fx)
	B.moles = {}
	for _, m in ipairs(B.game:GetChildren()) do
		if m.Name == "Mole" then
			local down = m:GetAttribute("DownCF")
			local rec = { model = m, down = down, up = down + B.cf.UpVector * 1.05, hat = m.Hat }
			m:PivotTo(down)
			table.insert(B.moles, rec)
			for _, partName in ipairs({ "Head", "Body" }) do
				local cd = Instance.new("ClickDetector") cd.MaxActivationDistance = 28 cd.Parent = m[partName]
				local function onClick(player)
					local s = B.session
					if not s or B.occupant ~= player or os.clock() > s.ends or not rec.isUp then return end
					rec.isUp = false
					local pts = rec.golden and 3 or 1
					s.whacks += 1
					fx.give(ctx, player, s, pts)
					setScreen(B, "SCORE " .. (s.tickets or 0))
					fx.say(B, ("🔨 %d whacks • 🎟️ %d"):format(s.whacks, s.tickets or 0))
					fx.anim(B, "throw", 1.8)
					local head = m.Head.Position
					fx.burst(head + Vector3.new(0, 0.4, 0), rec.golden and GOLD or Color3.fromRGB(255, 240, 120), rec.golden and 30 or 14, 8, 0.5)
					fx.sound(B, "Bonk", 0.55, rec.golden and 1.6 or 0.55)
					fx.move(m, rec.down, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					rec.golden = false rec.hat.Color = HAT rec.hat.Material = Enum.Material.SmoothPlastic
				end
				ctx:Connect(cd.MouseClick, onClick)
				if partName == "Head" then B.debugClicks = B.debugClicks or {} table.insert(B.debugClicks, onClick) end
			end
		end
	end
end

local function lowerAll(B) for _, r in ipairs(B.moles) do r.isUp = false r.golden = false r.hat.Color = HAT r.hat.Material = Enum.Material.SmoothPlastic r.model:PivotTo(r.down) end end

function G.Start(ctx, player, s, B, fx)
	s.ends = os.clock() + ROUND
	s.whacks = 0
	lowerAll(B)
	setScreen(B, "SCORE 0")
	fx.say(B, "🔨 GO! • 🎟️ 0")
	-- the mole spawner
	task.spawn(function()
		task.wait(0.6)
		while B.session == s and os.clock() < s.ends do
			local upCount = 0 for _, r in ipairs(B.moles) do if r.isUp then upCount += 1 end end
			if upCount < 3 then
				local free = {}
				for _, r in ipairs(B.moles) do if not r.isUp then table.insert(free, r) end end
				local r = free[fx.rand:NextInteger(1, #free)]
				if r then
					r.isUp = true
					r.golden = fx.rand:NextNumber() < 0.12
					if r.golden then r.hat.Color = GOLD r.hat.Material = Enum.Material.Neon end
					fx.move(r.model, r.up, 0.12, Enum.EasingStyle.Back)
					local stay = fx.rand:NextNumber(1.9, 2.4) - math.min(0.3, (ROUND - (s.ends - os.clock())) * 0.015) -- ~2 s to whack it
					task.delay(stay, function()
						if r.isUp then r.isUp = false fx.move(r.model, r.down, 0.15) r.golden = false r.hat.Color = HAT r.hat.Material = Enum.Material.SmoothPlastic end
					end)
				end
			end
			task.wait(fx.rand:NextNumber(0.45, 0.85))
		end
		if B.session == s then
			for _, r in ipairs(B.moles) do if r.isUp then r.isUp = false fx.move(r.model, r.down, 0.15) end end
			ctx:Send(player, { type = "boothResult", game = "WhackAMole", msg = ("🔨 Time! %d whacks (+%d 🎟️)"):format(s.whacks, s.tickets or 0), done = true })
			if s.whacks >= 10 then fx.confetti(B) fx.anim(B, "cheer") end
			task.wait(1.5)
			if s.finish then s.finish() end
		end
	end)
	return { kind = "info", text = "🔨 GO! Click or tap the moles!", seconds = ROUND, keepOpen = true }
end

function G.Action(ctx, player, s, data, B, fx) return { ok = false } end

function G.Stop(ctx, player, s, B, fx) lowerAll(B) end

return G
