--[[ TowerGame – SAMAR SUMMIT TOWER v3 (Common event, original "tower climb" design) ─────
  A HUGE tower (EventConfig.TowerGame: 14 floors × 28 studs ≈ 400 studs, 52 studs wide)
  appears in the courtyard for the whole event.
  • Floors are picked in random order from EventModules.TowerSections (fresh every event).
  • RED blocks / lava / lasers / spinners HURT (EventConfig.TowerGame.Damage).
    Avoid red for a moment and you slowly heal. At 0 HP you are knocked back to your last
    CHECKPOINT (every CheckpointEvery floors) — or to the start lobby if you have none.
  • The run timer starts when you walk in and stops on the 🏆 SUMMIT pad.
    Floors must be climbed one by one (teleport skips cancel the run).
  • Saved forever: TowerWins + TowerBestTime (PlayerData) and the global leaderboards.
───────────────────────────────────────────────────────────────────────────]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")
local Rewards = require(script.Parent.Parent:WaitForChild("EventRewards"))
local SectionFolder = script.Parent:WaitForChild("TowerSections")

local M = {}

---------------------------------------------------------------- saved leaderboards (global)
local okBest, BestStore = pcall(function() return DataStoreService:GetOrderedDataStore("SC_TowerBestTime_v1") end)
local okWins, WinsStore = pcall(function() return DataStoreService:GetOrderedDataStore("SC_TowerWins_v1") end)
local session = { best = {}, wins = {} }
local nameCache = {}
local function nameOf(userId)
	if nameCache[userId] then return nameCache[userId] end
	local p = Players:GetPlayerByUserId(userId)
	if p then nameCache[userId] = p.DisplayName return p.DisplayName end
	local ok, n = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	nameCache[userId] = ok and n or ("#" .. userId)
	return nameCache[userId]
end
local function fmt(sec) sec = math.max(0, sec or 0) return ("%d:%05.2f"):format(sec // 60, sec % 60) end
local function saveGlobal(player, time)
	local ms = math.floor(time * 1000)
	if okBest and BestStore then pcall(function() BestStore:UpdateAsync(tostring(player.UserId), function(old) if old == nil or ms < old then return ms end return nil end) end) end
	if okWins and WinsStore then pcall(function() WinsStore:IncrementAsync(tostring(player.UserId), 1) end) end
end

---------------------------------------------------------------- builders
local function part(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part") p.Name = name p.Size = size p.CFrame = cf p.Color = color p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = parent return p
end
local function sign(p, face, text, bg, fg, ppS)
	local g = Instance.new("SurfaceGui") g.Face = face g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = ppS or 40 g.Parent = p
	local t = Instance.new("TextLabel") t.Name = "Text" t.Size = UDim2.fromScale(1, 1) t.BackgroundColor3 = bg or Color3.new(0, 0, 0) t.BackgroundTransparency = bg and 0 or 1
	t.TextColor3 = fg or Color3.new(1, 1, 1) t.Font = Enum.Font.GothamBlack t.TextScaled = true t.TextWrapped = true t.Text = text t.Parent = g
	return t
end
local function playerFrom(hit)
	local m = hit:FindFirstAncestorOfClass("Model")
	return m and Players:GetPlayerFromCharacter(m)
end

---------------------------------------------------------------- run handling
local function lobbySpawn(ctx) return ctx.Data.lobby + Vector3.new(math.random(-4, 4), 3, math.random(-2, 2)) end

local function hud(ctx, p, extra)
	local r = ctx.Data.runs[p]
	local msg = { type = "tower", floors = ctx.Data.floors, cps = ctx.Data.cpFloors,
		best = p:GetAttribute("TowerBestTime") or 0, wins = p:GetAttribute("TowerWins") or 0 }
	if r then msg.state = "running" msg.floor = r.floor msg.elapsed = os.clock() - r.start msg.cp = r.cp else msg.state = "idle" end
	for k, v in pairs(extra or {}) do msg[k] = v end
	ctx:Send(p, msg)
end

local function teleport(ctx, p, pos)
	local char = p.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.Sit = false end
	char:PivotTo(CFrame.new(pos))
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then root.AssemblyLinearVelocity = Vector3.zero end
end

local function resetRun(ctx, p, why, toLobby)
	ctx.Data.runs[p] = nil
	if toLobby then teleport(ctx, p, lobbySpawn(ctx)) ctx.Data.cooldown[p] = os.clock() + 1.5 end
	if why then ctx:Toast(p, why) end
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then hum.Health = hum.MaxHealth end
	hud(ctx, p, { reset = true })
end

-- damage from red blocks; 0 HP → back to the last checkpoint (or the start)
local function hurt(ctx, p, amount)
	local r = ctx.Data.runs[p]
	if not r or ctx.Phase ~= "Active" then return end
	local now = os.clock()
	if r.lastHit and now - r.lastHit < ctx.Config.TowerGame.HitCooldown then return end
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	r.lastHit = now
	if hum.Health - amount > 0 then
		hum.Health -= amount
		hud(ctx, p, { hurt = amount })
		return
	end
	-- knocked out: no real death, back to the checkpoint with full HP
	hum.Health = hum.MaxHealth
	if r.cp and r.cpPos then
		teleport(ctx, p, r.cpPos)
		r.floor = r.cp
		r.lastHit = now + 1
		hud(ctx, p, { knocked = true })
		ctx:Toast(p, ("💫 Knocked out! Back to the checkpoint on floor %d"):format(r.cp))
	else
		resetRun(ctx, p, "💫 Knocked out! Back to the start (reach a checkpoint to save your climb)", true)
		hud(ctx, p, { knocked = true })
	end
end

local function win(ctx, p)
	local r = ctx.Data.runs[p]
	if not r or ctx.Phase ~= "Active" then return end
	if r.floor < ctx.Data.floors then return end
	local time = os.clock() - r.start
	ctx.Data.runs[p] = nil
	ctx.Data.cooldown[p] = os.clock() + ctx.Config.TowerGame.ReturnDelay + 2
	local wins = (tonumber(p:GetAttribute("TowerWins")) or 0) + 1
	p:SetAttribute("TowerWins", wins)
	local best = tonumber(p:GetAttribute("TowerBestTime")) or 0
	local newBest = best <= 0 or time < best
	if newBest then p:SetAttribute("TowerBestTime", math.floor(time * 100) / 100) end
	Rewards.saveSoon(p)
	task.spawn(saveGlobal, p, time)
	ctx.Data.roundWins[p] = (ctx.Data.roundWins[p] or 0) + 1
	if not ctx.Data.roundBest[p] or time < ctx.Data.roundBest[p] then ctx.Data.roundBest[p] = time end
	ctx:SetScore(p, ctx.Data.roundWins[p])
	session.wins[p.UserId] = (session.wins[p.UserId] or 0) + 1
	if not session.best[p.UserId] or time < session.best[p.UserId] then session.best[p.UserId] = time end
	nameCache[p.UserId] = p.DisplayName
	ctx:ToastAll(("🏆 %s reached the SUMMIT in %s!%s"):format(p.DisplayName, fmt(time), newBest and " ⭐ New personal best!" or ""))
	hud(ctx, p, { won = true, time = time, newBest = newBest })
	M.refreshBoard(ctx)
	local pad = ctx.Data.summitPad
	if pad and pad.Parent then
		local pe = Instance.new("ParticleEmitter") pe.Rate = 90 pe.Lifetime = NumberRange.new(1.5, 2.5) pe.Speed = NumberRange.new(16, 26) pe.SpreadAngle = Vector2.new(45, 45)
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(90, 200, 255)) pe.Size = NumberSequence.new(0.4) pe.Parent = pad
		task.delay(2.5, function() if pe.Parent then pe.Enabled = false task.delay(3, function() pe:Destroy() end) end end)
	end
	ctx:Toast(p, "🌅 Enjoy the view! Take the ⬇️ elevator when you want to climb again.")
end

---------------------------------------------------------------- leaderboard board
function M.refreshBoard(ctx)
	local board = ctx.Data.boardText
	if not board then return end
	local fastest, most = {}, {}
	local okA = okBest and pcall(function()
		for _, e in ipairs(BestStore:GetSortedAsync(true, 10):GetCurrentPage()) do table.insert(fastest, { id = tonumber(e.key), v = e.value / 1000 }) end
	end)
	local okB = okWins and pcall(function()
		for _, e in ipairs(WinsStore:GetSortedAsync(false, 10):GetCurrentPage()) do table.insert(most, { id = tonumber(e.key), v = e.value }) end
	end)
	if not okA or #fastest == 0 then fastest = {} for id, v in pairs(session.best) do table.insert(fastest, { id = id, v = v }) end table.sort(fastest, function(a, b) return a.v < b.v end) end
	if not okB or #most == 0 then most = {} for id, v in pairs(session.wins) do table.insert(most, { id = id, v = v }) end table.sort(most, function(a, b) return a.v > b.v end) end
	local function lines(list, f)
		local out = {}
		for i = 1, math.min(8, #list) do table.insert(out, ("%d. %s — %s"):format(i, nameOf(list[i].id), f(list[i].v))) end
		if #out == 0 then table.insert(out, "Be the first to reach the summit!") end
		return table.concat(out, "\n")
	end
	board.fast.Text = lines(fastest, fmt)
	board.wins.Text = lines(most, function(v) return tostring(v) .. " 🏆" end)
	board.note.Text = (okA and okB) and "All-time • every server" or "This server (saving is off in Studio)"
end

---------------------------------------------------------------- floor api (what TowerSections modules use)
local function makeApi(ctx, folder, SF, color, G)
	local api = { color = color, H = G.FH - 1, EXIT_TOP = G.EXIT_TOP, HALF = G.HALF, ENTRY = G.ENTRY, EXIT = G.EXITC }
	local K = (G.HALF - 4) / 16 -- paths are designed for a 40-wide floor and scaled to the real size
	local dmg = ctx.Config.TowerGame.Damage
	function api.at(x, y, z) return SF * CFrame.new(x, y, z) end
	function api.part(name, size, cf, col, mat, props) return part(folder, name, size, cf, col or color, mat, props) end
	function api.rawPart(name, size, cf, col, mat, props) return part(folder, name, size, cf, col or color, mat, props) end
	-- a RED danger part: touching it costs HP
	function api.danger(p, amount)
		p:SetAttribute("Danger", amount or dmg.Brick)
		ctx:Connect(p.Touched, function(hit)
			local pl = playerFrom(hit)
			if pl then hurt(ctx, pl, amount or dmg.Brick) end
		end)
		return p
	end
	api.kill = api.danger -- old name, still works
	function api.ghost(p, delayTime, back)
		local busy = false
		ctx:Connect(p.Touched, function(hit)
			if busy or not playerFrom(hit) then return end
			busy = true
			p.Color = p.Color:Lerp(Color3.fromRGB(255, 120, 120), 0.5)
			task.delay(delayTime or ctx.Config.TowerGame.VanishDelay or 2, function()
				if not p.Parent then return end
				p.Transparency = 0.85 p.CanCollide = false
				task.delay(back or 2.6, function() if p.Parent then p.Transparency = 0 p.CanCollide = true p.Color = color busy = false end end)
			end)
		end)
	end
	function api.mover(p, offset, time)
		local tw = TweenService:Create(p, TweenInfo.new(time or 2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { CFrame = p.CFrame + offset })
		tw:Play()
		table.insert(ctx.Data.tweens, tw)
		return tw
	end
	function api.spinner(y, length, speed)
		local bars = {}
		for k = 0, 1 do
			local b = part(folder, "SpinnerBar", Vector3.new(length or (G.S - 4), 0.8, 0.8), api.at(0, y, 0), Color3.fromRGB(255, 60, 40), Enum.Material.Neon)
			api.danger(b, dmg.Spinner)
			table.insert(bars, { part = b, offset = k * math.pi / 2 })
		end
		local base = api.at(0, y, 0)
		table.insert(ctx.Data.animators, function(dt, t)
			for _, b in ipairs(bars) do b.part.CFrame = base * CFrame.Angles(0, t * speed + b.offset, 0) end
		end)
	end
	-- pendulum: hangs from a pivot and swings left/right across the path
	function api.swing(pivotLocal, length, yaw, speed, phase)
		local pivot = SF * CFrame.new(pivotLocal) * CFrame.Angles(0, yaw or 0, 0)
		part(folder, "SwingPivot", Vector3.new(1.2, 1.2, 1.2), pivot, Color3.fromRGB(60, 60, 66), Enum.Material.Metal, { CanCollide = false })
		local bar = part(folder, "SwingBar", Vector3.new(1, length, 1), pivot, Color3.fromRGB(255, 70, 50), Enum.Material.Neon, { CanCollide = false })
		local ball = part(folder, "SwingBall", Vector3.new(3, 3, 3), pivot, Color3.fromRGB(255, 70, 50), Enum.Material.Neon, { Shape = Enum.PartType.Ball, CanCollide = false })
		api.danger(bar, dmg.Swing) api.danger(ball, dmg.Swing)
		table.insert(ctx.Data.animators, function(dt, t)
			local a = math.sin(t * (speed or 1.6) + (phase or 0)) * math.rad(62)
			local cf = pivot * CFrame.Angles(0, 0, a)
			bar.CFrame = cf * CFrame.new(0, -length / 2, 0)
			ball.CFrame = cf * CFrame.new(0, -length, 0)
		end)
	end
	-- a laser wall that slides up and down across the whole floor
	function api.laser(yLow, yHigh, z, time, alongX)
		local w = G.S - 0.5
		local cf0 = api.at(alongX and 0 or z, yLow, alongX and z or 0) * (alongX and CFrame.new() or CFrame.Angles(0, math.rad(90), 0))
		local beam = part(folder, "Laser", Vector3.new(w, 0.35, 0.35), cf0, Color3.fromRGB(255, 40, 40), Enum.Material.Neon, { CanCollide = false })
		api.danger(beam, dmg.Laser)
		api.mover(beam, Vector3.new(0, yHigh - yLow, 0), time or 2.2)
	end
	function api.conveyor(p, dir, speed)
		p.AssemblyLinearVelocity = dir * speed
		p.Color = Color3.fromRGB(60, 60, 70) p.Material = Enum.Material.DiamondPlate
	end
	function api.lavaFloor()
		local L = Color3.fromRGB(255, 80, 40)
		local safe = G.HALF - 10 -- the arrival corner stays safe
		api.danger(part(folder, "LavaFloor", Vector3.new(G.S - 10, 0.4, G.S), api.at(5, 0.2, 0), L, Enum.Material.Neon, { CanCollide = false, Transparency = 0.45 }), dmg.Lava)
		api.danger(part(folder, "LavaFloor", Vector3.new(10, 0.4, G.S - 10), api.at(-G.HALF + 5, 0.2, 5), L, Enum.Material.Neon, { CanCollide = false, Transparency = 0.45 }), dmg.Lava)
	end
	function api.truss(cf, height)
		local tr = Instance.new("TrussPart") tr.Name = "Truss" tr.Size = Vector3.new(2, height, 2) tr.CFrame = cf tr.Anchored = true tr.Color = Color3.fromRGB(80, 80, 88) tr.Parent = folder
		return tr
	end
	function api.beam(a, b, width, isLocal)
		if isLocal then a = SF:PointToWorldSpace(a) b = SF:PointToWorldSpace(b) end
		local len = (b - a).Magnitude
		return part(folder, "Beam", Vector3.new(width, 0.6, len), CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, -0.3, 0), color)
	end
	local function scaled(list) local out = {} for i, v in ipairs(list) do out[i] = v * K end return out end
	api.paths = {}
	function api.paths.diagonal() return scaled({ Vector2.new(-16, -16), Vector2.new(15, 15) }) end
	function api.paths.perimeter() return scaled({ Vector2.new(-16, -16), Vector2.new(16, -16), Vector2.new(15, 15) }) end
	function api.paths.zigzag() return scaled({ Vector2.new(-16, -16), Vector2.new(16, -11), Vector2.new(-16, -4), Vector2.new(16, 3), Vector2.new(-14, 10), Vector2.new(15, 15) }) end
	function api.paths.snake() return scaled({ Vector2.new(-16, -16), Vector2.new(-16, 16), Vector2.new(-6, 16), Vector2.new(-6, -16), Vector2.new(4, -16), Vector2.new(4, 16), Vector2.new(15, 15) }) end
	function api.paths.spiral()
		local pts = {}
		for k = 0, 40 do
			local t = k / 40
			local a = math.rad(225 + 540 * t)
			local r = 12 + 8 * math.abs(2 * t - 1)
			table.insert(pts, Vector2.new(math.clamp(math.cos(a) * r, -16, 16), math.clamp(math.sin(a) * r, -16, 16)))
		end
		pts[1] = Vector2.new(-16, -16) pts[#pts] = Vector2.new(15, 15)
		return scaled(pts)
	end
	function api.steps(points, opts)
		opts = opts or {}
		local size = opts.size or Vector3.new(3.2, 1, 3.2)
		local spacing = opts.spacing or 5.2
		local fromY, toY = opts.fromY or 1.5, opts.toY or G.EXIT_TOP
		local segs, total = {}, 0
		for i = 1, #points - 1 do local l = (points[i + 1] - points[i]).Magnitude table.insert(segs, l) total += l end
		local n = math.max(7, math.ceil(total / spacing))
		local function pointAt(d)
			for i, l in ipairs(segs) do
				if d <= l or i == #segs then return points[i]:Lerp(points[i + 1], math.clamp(d / math.max(l, 0.001), 0, 1)), (points[i + 1] - points[i]).Unit end
				d -= l
			end
		end
		local lim = G.HALF - math.max(size.X, size.Z) / 2 - 0.3
		local out = {}
		for k = 1, n do
			local t = k / (n + 1)
			local p2, dir = pointAt(total * t)
			local top = fromY + (toY - fromY) * t
			local x, z = math.clamp(p2.X, -lim, lim), math.clamp(p2.Y, -lim, lim)
			local col = (k % 2 == 0) and color or color:Lerp(Color3.new(1, 1, 1), 0.35)
			local p = part(folder, "Step_" .. k, size, api.at(x, top - size.Y / 2, z), col)
			if opts.kind == "ghost" then p.Material = Enum.Material.Glass api.ghost(p)
			elseif opts.kind == "crumble" then p.Material = Enum.Material.Slate api.ghost(p, ctx.Config.TowerGame.VanishDelay or 2, 3)
			elseif opts.kind == "move" then
				api.mover(p, SF:VectorToWorldSpace(Vector3.new(-dir.Y, 0, dir.X)) * 2.8, 2.4 + (k % 3) * 0.4)
			end
			if opts.pillar then part(folder, "Pillar", Vector3.new(size.X * 0.6, top - size.Y, size.Z * 0.6), api.at(x, (top - size.Y) / 2, z), color:Lerp(Color3.new(0, 0, 0), 0.35)) end
			table.insert(out, p)
		end
		return out
	end
	return api
end

---------------------------------------------------------------- summit deck: a chill place to enjoy the view
local CollectionService = game:GetService("CollectionService")
local function seat(parent, name, cf)
	local s = Instance.new("Seat") s.Name = name s.Size = Vector3.new(2, 0.4, 2) s.CFrame = cf s.Anchored = true
	s.Color = Color3.fromRGB(170, 120, 75) s.Material = Enum.Material.Wood s.TopSurface = Enum.SurfaceType.Smooth s.Parent = parent
	s:SetAttribute("SeatName", name)
	CollectionService:AddTag(s, "PromptSeat") -- uses the existing PromptSeats sit system
	return s
end
function M.buildDeck(ctx, folder, base, G)
	local deck = Instance.new("Model") deck.Name = "SummitDeck" deck.Parent = folder
	local H = G.HALF
	local wood, dark = Color3.fromRGB(170, 120, 75), Color3.fromRGB(60, 62, 68)
	local function at(x, y, z) return base + Vector3.new(x, y, z) end
	-- wooden deck tiles under the lounge corners (decoration only)
	for _, q in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 } }) do
		part(deck, "DeckFloor", Vector3.new(H - 12, 0.15, H - 12), CFrame.new(at(q[1] * (H / 2 + 3), 0.08, q[2] * (H / 2 + 3))), Color3.fromRGB(190, 140, 90), Enum.Material.WoodPlanks, { CanCollide = false })
	end
	-- benches facing OUT over the view (3 seats each)
	local benches = { { 0, 1, -10 }, { 0, 1, 10 }, { 0, -1, 10 }, { 1, 0, -12 }, { 1, 0, 12 }, { -1, 0, 12 } } -- {dirX, dirZ, along}
	for i, b in ipairs(benches) do
		local out = Vector3.new(b[1], 0, b[2])
		local side = Vector3.new(-b[2], 0, b[1])
		local p0 = at(0, 0, 0) + out * (H - 4) + side * b[3]
		local cf = CFrame.lookAt(p0, p0 + out)
		part(deck, "BenchBase", Vector3.new(7, 1.2, 2.2), cf * CFrame.new(0, 0.6, 0), dark, Enum.Material.Metal)
		part(deck, "BenchBack", Vector3.new(7, 2.2, 0.4), cf * CFrame.new(0, 2, 1.1), wood, Enum.Material.Wood)
		for k = -1, 1 do seat(deck, "Bench", cf * CFrame.new(k * 2.2, 1.4, 0)) end
	end
	-- café tables with chairs and umbrellas
	for i, tpos in ipairs({ { 15, -15 }, { -15, 15 }, { 15, 15 }, { 4, 20 } }) do
		local c = at(tpos[1], 0, tpos[2])
		part(deck, "TableLeg", Vector3.new(0.5, 3, 0.5), CFrame.new(c + Vector3.new(0, 1.5, 0)), dark, Enum.Material.Metal)
		part(deck, "TableTop", Vector3.new(0.3, 4, 4), CFrame.new(c + Vector3.new(0, 3.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(250, 248, 240), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
		part(deck, "UmbrellaPole", Vector3.new(0.25, 7, 0.25), CFrame.new(c + Vector3.new(0, 6.5, 0)), Color3.fromRGB(230, 230, 230), Enum.Material.Metal, { CanCollide = false })
		part(deck, "Umbrella", Vector3.new(0.5, 9, 9), CFrame.new(c + Vector3.new(0, 9.6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			({ Color3.fromRGB(230, 80, 80), Color3.fromRGB(60, 150, 90), Color3.fromRGB(250, 200, 60), Color3.fromRGB(70, 140, 220) })[i], Enum.Material.Fabric, { Shape = Enum.PartType.Cylinder, CanCollide = false })
		for k = 0, 1 do
			local a = k * math.pi
			local cp = c + Vector3.new(math.cos(a) * 3.2, 0, math.sin(a) * 3.2)
			local cf = CFrame.lookAt(cp, Vector3.new(c.X, cp.Y, c.Z))
			part(deck, "ChairBase", Vector3.new(2, 1.2, 2), cf * CFrame.new(0, 0.6, 0), wood, Enum.Material.Wood)
			part(deck, "ChairBack", Vector3.new(2, 2.2, 0.3), cf * CFrame.new(0, 2.1, 0.9), wood, Enum.Material.Wood)
			seat(deck, "Chair", cf * CFrame.new(0, 1.4, 0))
		end
		part(deck, "Cup", Vector3.new(0.4, 0.5, 0.4), CFrame.new(c + Vector3.new(0.8, 3.5, 0.4)), Color3.fromRGB(255, 255, 255))
	end
	-- plants and lamp posts
	for _, q in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 } }) do
		local c = at(q[1] * (H - 3), 0, q[2] * (H - 3))
		part(deck, "Pot", Vector3.new(2.6, 2, 2.6), CFrame.new(c + Vector3.new(0, 1, 0)), Color3.fromRGB(200, 120, 80), Enum.Material.Concrete)
		part(deck, "Bush", Vector3.new(3.6, 3.6, 3.6), CFrame.new(c + Vector3.new(0, 3.6, 0)), Color3.fromRGB(70, 150, 80), Enum.Material.Grass, { Shape = Enum.PartType.Ball, CanCollide = false })
	end
	for _, q in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
		local c = at(q[1] * (H - 10), 0, q[2] * (H - 10))
		part(deck, "LampPost", Vector3.new(0.5, 9, 0.5), CFrame.new(c + Vector3.new(0, 4.5, 0)), dark, Enum.Material.Metal)
		local bulb = part(deck, "LampGlobe", Vector3.new(1.4, 1.4, 1.4), CFrame.new(c + Vector3.new(0, 9.4, 0)), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, { Shape = Enum.PartType.Ball, CanCollide = false })
		local l = Instance.new("PointLight") l.Range = 18 l.Brightness = 1.2 l.Color = Color3.fromRGB(255, 225, 170) l.Parent = bulb
	end
	-- binocular viewers at the railing
	for _, v in ipairs({ { 0, 1 }, { 1, 0 }, { -1, 0 } }) do
		local out = Vector3.new(v[1], 0, v[2])
		local c = at(0, 0, 0) + out * (H - 2.2) + Vector3.new(v[2] * 6, 0, v[1] * 6)
		local cf = CFrame.lookAt(c, c + out)
		part(deck, "ViewerStand", Vector3.new(0.5, 3.6, 0.5), cf * CFrame.new(0, 1.8, 0), dark, Enum.Material.Metal)
		part(deck, "Binoculars", Vector3.new(1.6, 0.9, 1.4), cf * CFrame.new(0, 4, 0), Color3.fromRGB(40, 120, 200), Enum.Material.Metal)
		part(deck, "Lens", Vector3.new(0.5, 0.5, 0.3), cf * CFrame.new(-0.4, 4, -0.75), Color3.fromRGB(20, 20, 24), Enum.Material.Glass)
		part(deck, "Lens", Vector3.new(0.5, 0.5, 0.3), cf * CFrame.new(0.4, 4, -0.75), Color3.fromRGB(20, 20, 24), Enum.Material.Glass)
	end
	-- Summit Café stand
	local cafe = at(-(H - 6), 0, 2)
	part(deck, "CafeCounter", Vector3.new(3, 3.4, 9), CFrame.new(cafe + Vector3.new(0, 1.7, 0)), Color3.fromRGB(150, 100, 60), Enum.Material.Wood)
	part(deck, "CafeRoof", Vector3.new(5, 0.4, 11), CFrame.new(cafe + Vector3.new(-0.5, 7.2, 0)), Color3.fromRGB(30, 110, 60))
	for _, z in ipairs({ -4.5, 4.5 }) do part(deck, "CafePost", Vector3.new(0.4, 7, 0.4), CFrame.new(cafe + Vector3.new(1.2, 3.5, z)), Color3.fromRGB(240, 240, 235), Enum.Material.Metal) end
	local cs = part(deck, "CafeSign", Vector3.new(0.3, 1.4, 8), CFrame.new(cafe + Vector3.new(1.6, 6.2, 0)), Color3.fromRGB(30, 110, 60))
	sign(cs, Enum.NormalId.Right, "☕ SUMMIT CAFÉ", Color3.fromRGB(30, 110, 60), Color3.fromRGB(255, 225, 120))
	for k = -1, 1 do part(deck, "Cup", Vector3.new(0.4, 0.5, 0.4), CFrame.new(cafe + Vector3.new(0.6, 3.65, k * 2)), Color3.fromRGB(255, 255, 255)) end
	-- ⬇️ elevator back down (climb again whenever you want)
	local e = at(H - 8, 0, -(H - 8))
	local pad = part(deck, "ElevatorPad", Vector3.new(6, 0.4, 6), CFrame.new(e + Vector3.new(0, 0.2, 0)), Color3.fromRGB(80, 160, 255), Enum.Material.Neon)
	local es = part(deck, "ElevatorSign", Vector3.new(6, 1.6, 0.3), CFrame.new(e + Vector3.new(0, 5.5, 3.2)), Color3.fromRGB(25, 30, 38))
	sign(es, Enum.NormalId.Front, "⬇️ ELEVATOR DOWN", Color3.fromRGB(25, 30, 38), Color3.fromRGB(150, 210, 255))
	sign(es, Enum.NormalId.Back, "⬇️ ELEVATOR DOWN", Color3.fromRGB(25, 30, 38), Color3.fromRGB(150, 210, 255))
	local pp = Instance.new("ProximityPrompt") pp.ActionText = "Ride down" pp.ObjectText = "Elevator" pp.HoldDuration = 0.5 pp.MaxActivationDistance = 8 pp.RequiresLineOfSight = false pp.Parent = pad
	ctx:Connect(pp.Triggered, function(player)
		if ctx.Data.runs[player] then return end
		teleport(ctx, player, lobbySpawn(ctx))
		ctx.Data.cooldown[player] = os.clock() + 1.5
		ctx:Toast(player, "⬇️ Back at the bottom — climb again to beat your time!")
		hud(ctx, player)
	end)
end

---------------------------------------------------------------- build the tower
function M.Setup(ctx)
	local cfg = ctx.Config.TowerGame
	local C, FH, F = cfg.Center, cfg.FloorHeight, cfg.Floors
	local S = cfg.Size
	local G = { S = S, HALF = S / 2, FH = FH, EXIT_TOP = FH - 7.5 }
	G.ENTRY = -(G.HALF - 4) G.EXITC = G.HALF - 5
	local HOLE, TRUSS = G.HALF - 3.5, G.HALF - 2.5
	ctx.Data.G = G
	ctx.Data.runs, ctx.Data.cooldown, ctx.Data.started = {}, {}, {}
	ctx.Data.roundWins, ctx.Data.roundBest = {}, {}
	ctx.Data.tweens, ctx.Data.animators = {}, {}
	ctx.Data.C, ctx.Data.FH, ctx.Data.floors = C, FH, F
	ctx.Data.cpFloors, ctx.Data.cpSpot = {}, {}

	local pool = {}
	for _, m in ipairs(SectionFolder:GetChildren()) do
		if m:IsA("ModuleScript") then local ok, sec = pcall(require, m) if ok and type(sec) == "table" and sec.Build then table.insert(pool, sec) end end
	end
	if #pool == 0 then ctx.CancelReason = "no tower floor modules" return false end
	for i = #pool, 2, -1 do local j = math.random(i) pool[i], pool[j] = pool[j], pool[i] end
	-- the last EasyTopFloors floors use easy designs (Difficulty = 1) so the finish is friendlier
	local easy, rest = {}, {}
	for _, sec in ipairs(pool) do if (sec.Difficulty or 2) <= 1 then table.insert(easy, sec) else table.insert(rest, sec) end end
	if #rest == 0 then rest = pool end
	if #easy == 0 then easy = pool end
	local nEasy = math.min(cfg.EasyTopFloors or 0, F)
	local chosen = {}
	for i = 1, F - nEasy do chosen[i] = rest[(i - 1) % #rest + 1] end
	for k = 1, nEasy do chosen[F - nEasy + k] = easy[(k - 1) % #easy + 1] end

	local tower = Instance.new("Model") tower.Name = "SummitTower" tower.Parent = ctx.Folder
	local top = C.Y + F * FH
	for _, sx in ipairs({ -1, 1 }) do for _, sz in ipairs({ -1, 1 }) do
		part(tower, "CornerPillar", Vector3.new(3, top - C.Y + 8, 3), CFrame.new(C + Vector3.new(sx * (G.HALF + 1.5), (top - C.Y + 8) / 2, sz * (G.HALF + 1.5))), Color3.fromRGB(30, 110, 60), Enum.Material.Concrete)
	end end
	part(tower, "GroundPlate", Vector3.new(S + 2, 0.2, S + 2), CFrame.new(C + Vector3.new(0, 0.1, 0)), Color3.fromRGB(200, 205, 210), Enum.Material.Concrete)

	for i = 1, F + 1 do
		local base = C + Vector3.new(0, (i - 1) * FH, 0)
		local SF = CFrame.new(base) * CFrame.Angles(0, (i % 2 == 0) and math.pi or 0, 0)
		local sec = chosen[i]
		local color = sec and sec.Color or Color3.fromRGB(250, 210, 70)
		local folder = Instance.new("Model") folder.Name = sec and ("Floor%02d_%s"):format(i, sec.Name:gsub("%s", "")) or "Summit" folder.Parent = tower
		if i > 1 and i <= F then
			-- NO floor slab (you can see all the way up): just a landing platform beside the arriving truss
			local lc = -(G.HALF - 9) -- landing center (local), clear of the truss column in the corner
			part(folder, "Landing", Vector3.new(10, 1, 10), SF * CFrame.new(lc, -0.5, lc), Color3.fromRGB(70, 75, 85), Enum.Material.Concrete)
			part(folder, "LandingEdge", Vector3.new(10.2, 0.25, 10.2), SF * CFrame.new(lc, 0.12, lc), color, Enum.Material.Neon, { CanCollide = false, Transparency = 0.55 })
		elseif i == F + 1 then
			-- summit roof: solid, with the hole for the last truss
			part(folder, "Slab", Vector3.new(S - 7, 1, S), SF * CFrame.new(3.5, -0.5, 0), Color3.fromRGB(240, 200, 60), Enum.Material.SmoothPlastic)
			part(folder, "Slab", Vector3.new(7, 1, S - 7), SF * CFrame.new(-HOLE, -0.5, 3.5), Color3.fromRGB(240, 200, 60), Enum.Material.SmoothPlastic)
		end
		if sec then
			local h = FH
			local W = G.HALF + 0.5
			local wallProps = { Transparency = 0.55 }
			for _, w in ipairs({ { 0, -W, S + 2, 1 }, { 0, W, S + 2, 1 }, { -W, 0, 1, S }, { W, 0, 1, S } }) do
				if i == 1 and w[2] == -W then
					-- doorway at world x = -(HALF-6) … -(HALF-12)
					local d0, d1 = -(G.HALF - 6), -(G.HALF - 12)
					part(folder, "Wall", Vector3.new(d0 + G.HALF + 1, h, 1), CFrame.new(base + Vector3.new((-G.HALF - 1 + d0) / 2, h / 2, -W)), color, Enum.Material.Glass, wallProps)
					part(folder, "Wall", Vector3.new(G.HALF + 1 - d1, h, 1), CFrame.new(base + Vector3.new((d1 + G.HALF + 1) / 2, h / 2, -W)), color, Enum.Material.Glass, wallProps)
					part(folder, "Wall", Vector3.new(d1 - d0, h - 10, 1), CFrame.new(base + Vector3.new((d0 + d1) / 2, 10 + (h - 10) / 2, -W)), color, Enum.Material.Glass, wallProps)
					ctx.Data.doorX = (d0 + d1) / 2
				else
					part(folder, "Wall", Vector3.new(w[3], h, w[4]), CFrame.new(base + Vector3.new(w[1], h / 2, w[2])), color, Enum.Material.Glass, wallProps)
				end
			end
			-- coloured trim ring around the OUTSIDE of the walls (no sheet across the middle, so you can see up)
			for _, b in ipairs({ { 0, -(G.HALF + 1.25), S + 4, 1.5 }, { 0, G.HALF + 1.25, S + 4, 1.5 }, { -(G.HALF + 1.25), 0, 1.5, S + 1 }, { G.HALF + 1.25, 0, 1.5, S + 1 } }) do
				part(folder, "FloorBand", Vector3.new(b[3], 1, b[4]), CFrame.new(base + Vector3.new(b[1], FH - 0.5, b[2])), color, Enum.Material.SmoothPlastic, { CanCollide = false })
			end
			local lbl = part(folder, "FloorSign", Vector3.new(16, 2.6, 0.2), SF * CFrame.new(0, FH - 4, -G.HALF + 0.15), Color3.fromRGB(25, 30, 38))
			sign(lbl, Enum.NormalId.Back, ("FLOOR %d / %d  •  %s"):format(i, F, string.upper(sec.Name)), Color3.fromRGB(25, 30, 38), color)
			part(folder, "ExitPlatform", Vector3.new(6, 1, 6), SF * CFrame.new(G.EXITC, G.EXIT_TOP - 0.5, G.EXITC), Color3.fromRGB(255, 220, 90))
			local tr = Instance.new("TrussPart") tr.Name = "ExitTruss" tr.Size = Vector3.new(2, 10, 2) tr.CFrame = SF * CFrame.new(TRUSS, G.EXIT_TOP + 5, TRUSS)
			tr.Anchored = true tr.Color = Color3.fromRGB(255, 210, 60) tr.Parent = folder
			-- CHECKPOINT on floors 4, 7, 10 … (on the arrival side of the floor)
			if i > 1 and (i - 1) % cfg.CheckpointEvery == 0 then
				local cpCF = SF * CFrame.new(-(G.HALF - 10), 0.2, -(G.HALF - 10)) -- on the landing platform
				local pad = part(folder, "CheckpointPad", Vector3.new(6, 0.4, 6), cpCF, Color3.fromRGB(80, 230, 130), Enum.Material.Neon, { CanCollide = false, Transparency = 0.15 })
				part(folder, "CheckpointPole", Vector3.new(0.3, 7, 0.3), cpCF * CFrame.new(2.6, 3.5, 2.6), Color3.fromRGB(230, 230, 235), Enum.Material.Metal)
				part(folder, "CheckpointFlag", Vector3.new(0.12, 1.6, 2.4), cpCF * CFrame.new(2.6, 6.2, 1.3), Color3.fromRGB(80, 230, 130), Enum.Material.Fabric, { CanCollide = false })
				local bb = Instance.new("BillboardGui") bb.Size = UDim2.fromOffset(200, 40) bb.StudsOffset = Vector3.new(0, 4.5, 0) bb.MaxDistance = 60 bb.Parent = pad
				local tl = Instance.new("TextLabel") tl.Size = UDim2.fromScale(1, 1) tl.BackgroundTransparency = 1 tl.TextScaled = true tl.Font = Enum.Font.GothamBlack
				tl.TextColor3 = Color3.fromRGB(150, 255, 190) tl.TextStrokeTransparency = 0.2 tl.Text = ("🚩 CHECKPOINT • FLOOR %d"):format(i) tl.Parent = bb
				local snd = Instance.new("Sound") snd.Name = "Chime" snd.SoundId = cfg.Music.Checkpoint snd.PlaybackSpeed = 1.25 snd.Volume = 0.8 snd.Parent = pad
				table.insert(ctx.Data.cpFloors, i)
				ctx.Data.cpSpot[i] = cpCF.Position + Vector3.new(0, 3.2, 0)
				ctx:Connect(pad.Touched, function(hit)
					local pl = playerFrom(hit)
					local r = pl and ctx.Data.runs[pl]
					if not r or ctx.Phase ~= "Active" or (r.cp or 0) >= i or r.floor < i - 1 then return end
					r.cp, r.cpPos = i, ctx.Data.cpSpot[i]
					snd:Play()
					local pe = Instance.new("ParticleEmitter") pe.Rate = 0 pe.Speed = NumberRange.new(8, 14) pe.SpreadAngle = Vector2.new(60, 60) pe.Lifetime = NumberRange.new(0.8, 1.2)
					pe.Color = ColorSequence.new(Color3.fromRGB(120, 255, 170)) pe.LightEmission = 1 pe.Size = NumberSequence.new(0.4, 0) pe.Parent = pad pe:Emit(40)
					task.delay(1.5, function() pe:Destroy() end)
					hud(ctx, pl, { checkpoint = i })
				end)
			end
			local ok, err = pcall(sec.Build, makeApi(ctx, folder, SF, color, G))
			if not ok then warn("[TowerGame] floor " .. sec.Name .. " failed: " .. tostring(err)) end
		else
			ctx.Data.summitY = base.Y
			-- see-through glass railing so you can enjoy the view
			for _, w in ipairs({ { 0, -(G.HALF + 0.5), S + 2, 1 }, { 0, G.HALF + 0.5, S + 2, 1 }, { -(G.HALF + 0.5), 0, 1, S }, { G.HALF + 0.5, 0, 1, S } }) do
				part(folder, "GlassRailing", Vector3.new(w[3], 4, w[4]), CFrame.new(base + Vector3.new(w[1], 2, w[2])), Color3.fromRGB(200, 230, 255), Enum.Material.Glass, { Transparency = 0.7 })
				part(folder, "RailTop", Vector3.new(math.max(w[3], 1.4), 0.4, math.max(w[4], 1.4)), CFrame.new(base + Vector3.new(w[1], 4.2, w[2])), Color3.fromRGB(240, 200, 60), Enum.Material.Metal)
			end
			M.buildDeck(ctx, folder, base, G)
			local pad = part(folder, "SummitPad", Vector3.new(14, 0.4, 14), CFrame.new(base + Vector3.new(0, 0.2, 0)), Color3.fromRGB(255, 225, 90), Enum.Material.Neon)
			ctx.Data.summitPad = pad
			local bb = Instance.new("BillboardGui") bb.Size = UDim2.fromOffset(280, 70) bb.StudsOffset = Vector3.new(0, 8, 0) bb.MaxDistance = 600 bb.Parent = pad
			local tl = Instance.new("TextLabel") tl.Size = UDim2.fromScale(1, 1) tl.BackgroundTransparency = 1 tl.TextScaled = true tl.Font = Enum.Font.GothamBlack
			tl.TextColor3 = Color3.new(1, 1, 1) tl.TextStrokeTransparency = 0.2 tl.Text = "🏆 SUMMIT" tl.Parent = bb
			local beacon = part(folder, "Beacon", Vector3.new(1.5, 60, 1.5), CFrame.new(base + Vector3.new(0, 34, 0)), Color3.fromRGB(255, 230, 120), Enum.Material.Neon, { CanCollide = false, Transparency = 0.5 })
			for _, sx in ipairs({ -1, 1 }) do
				part(folder, "FlagPole", Vector3.new(0.4, 14, 0.4), CFrame.new(base + Vector3.new(sx * (G.HALF - 3), 7, G.HALF - 3)), Color3.fromRGB(220, 220, 225), Enum.Material.Metal)
				part(folder, "Flag", Vector3.new(0.2, 3.5, 6), CFrame.new(base + Vector3.new(sx * (G.HALF - 3), 12, G.HALF - 6)), Color3.fromRGB(30, 110, 60), Enum.Material.Fabric)
			end
			ctx:Connect(pad.Touched, function(hit) local pl = playerFrom(hit) if pl then win(ctx, pl) end end)
		end
	end

	-- entrance + lobby + leaderboard
	local doorX = ctx.Data.doorX or -17
	local title = part(tower, "TowerTitle", Vector3.new(30, 4.5, 0.4), CFrame.new(C + Vector3.new(0, FH + 5, -(G.HALF + 1.3))), Color3.fromRGB(30, 110, 60))
	sign(title, Enum.NormalId.Front, "🗼 SAMAR SUMMIT TOWER", Color3.fromRGB(30, 110, 60), Color3.fromRGB(255, 225, 120))
	ctx.Data.lobby = C + Vector3.new(doorX, 0, -(G.HALF + 9))
	part(tower, "StartLobby", Vector3.new(34, 0.3, 14), CFrame.new(C + Vector3.new(doorX + 10, 0.15, -(G.HALF + 9))), Color3.fromRGB(70, 160, 110))
	part(tower, "DoorMat", Vector3.new(6, 0.32, 8), CFrame.new(C + Vector3.new(doorX, 0.16, -(G.HALF + 4.5))), Color3.fromRGB(255, 210, 60), Enum.Material.Neon, { CanCollide = false, Transparency = 0.3 })
	local startSign = part(tower, "StartSign", Vector3.new(12, 3.4, 0.3), CFrame.new(C + Vector3.new(doorX, 13, -(G.HALF + 1.1))), Color3.fromRGB(25, 30, 38))
	sign(startSign, Enum.NormalId.Front, "⏱ Timer starts when you walk in!\n🟥 Red = damage • 🚩 checkpoints every 3 floors", Color3.fromRGB(25, 30, 38), Color3.new(1, 1, 1))
	local board = part(tower, "Leaderboard", Vector3.new(18, 12, 0.6), CFrame.new(C + Vector3.new(16, 7, -(G.HALF + 13))) * CFrame.Angles(0, math.rad(20), 0), Color3.fromRGB(25, 30, 38))
	for _, x in ipairs({ -7, 7 }) do part(tower, "BoardLeg", Vector3.new(0.6, 7, 0.6), board.CFrame * CFrame.new(x, -9, 0), Color3.fromRGB(60, 60, 66), Enum.Material.Metal) end
	local g = Instance.new("SurfaceGui") g.Face = Enum.NormalId.Front g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = 30 g.Parent = board
	local function lab(text, pos, size, font, col, align)
		local l = Instance.new("TextLabel") l.Text = text l.Position = pos l.Size = size l.BackgroundTransparency = 1 l.Font = font l.TextColor3 = col
		l.TextScaled = true l.TextXAlignment = align or Enum.TextXAlignment.Center l.TextYAlignment = Enum.TextYAlignment.Top l.Parent = g return l
	end
	lab("🗼 SUMMIT LEADERBOARD", UDim2.fromScale(0.03, 0.02), UDim2.fromScale(0.94, 0.12), Enum.Font.GothamBlack, Color3.fromRGB(255, 220, 110))
	lab("⏱ FASTEST CLIMBERS", UDim2.fromScale(0.03, 0.16), UDim2.fromScale(0.45, 0.07), Enum.Font.GothamBold, Color3.fromRGB(140, 220, 255))
	lab("🏆 MOST WINS", UDim2.fromScale(0.52, 0.16), UDim2.fromScale(0.45, 0.07), Enum.Font.GothamBold, Color3.fromRGB(140, 230, 160))
	ctx.Data.boardText = {
		fast = lab("", UDim2.fromScale(0.03, 0.25), UDim2.fromScale(0.45, 0.66), Enum.Font.Gotham, Color3.new(1, 1, 1), Enum.TextXAlignment.Left),
		wins = lab("", UDim2.fromScale(0.52, 0.25), UDim2.fromScale(0.45, 0.66), Enum.Font.Gotham, Color3.new(1, 1, 1), Enum.TextXAlignment.Left),
		note = lab("", UDim2.fromScale(0.03, 0.92), UDim2.fromScale(0.94, 0.06), Enum.Font.Gotham, Color3.fromRGB(170, 175, 185)),
	}
	task.spawn(M.refreshBoard, ctx)
	ctx:SetLocation(C, "Courtyard • Summit Tower")
	ctx.GotoPosition = ctx.Data.lobby + Vector3.new(0, 3, 0)
	ctx.ScoreLabel = "Summits this tower 🏆"
	ctx.JoinMode = "button"
end

---------------------------------------------------------------- lifecycle
function M.Start(ctx)
	local cfg = ctx.Config.TowerGame
	local C, FH, F, HALF = ctx.Data.C, ctx.Data.FH, ctx.Data.floors, ctx.Data.G.HALF
	ctx:ToastAll("🗼 The Summit Tower is OPEN! Walk in to start your timer.")
	-- spinners / pendulums
	local t0 = os.clock()
	ctx:Connect(RunService.Heartbeat, function(dt)
		local t = os.clock() - t0
		for _, f in ipairs(ctx.Data.animators) do f(dt, t) end
	end)
	task.spawn(function()
		local refresh = 0
		while ctx.Phase == "Active" do
			for _, p in ipairs(Players:GetPlayers()) do
				local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
				if root and hum and hum.Health > 0 then
					local rel = root.Position - C
					local inside = math.abs(rel.X) < HALF + 0.3 and math.abs(rel.Z) < HALF + 0.3 and rel.Y > -2 and rel.Y < F * FH + 14
					local r = ctx.Data.runs[p]
					if inside and not r and (not ctx.Data.cooldown[p] or os.clock() > ctx.Data.cooldown[p]) and rel.Y < 8 then
						if ctx:IsIn(p) or ctx:Join(p) then
							ctx.Data.runs[p] = { start = os.clock(), floor = 1 }
							ctx.Data.started[p] = true
							hum.Health = hum.MaxHealth
							hud(ctx, p, { started = true, music = true })
						end
					elseif r then
						if not inside and rel.Y < FH then
							resetRun(ctx, p, "🚪 You left the tower — run cancelled")
						else
							local fl = math.clamp(math.floor(rel.Y / FH) + 1, 1, F + 1)
							if r.cp and rel.Y < (r.cp - 1) * FH - 4 then
								-- fell below the checkpoint (there are no floors to catch you any more)
								teleport(ctx, p, r.cpPos)
								r.floor = r.cp
								r.lastHit = os.clock()
								ctx:Toast(p, ("⬇️ You fell! Back to the checkpoint on floor %d"):format(r.cp))
								hud(ctx, p, { fell = true })
							elseif not r.cp and r.floor >= 2 and rel.Y < 5 then -- standing on the ground floor
								-- no checkpoint yet: you are back at the bottom, climb again (timer keeps running)
								r.floor = 1
								ctx:Toast(p, "⬇️ You fell to the bottom! Reach a 🚩 checkpoint to save your climb")
								hud(ctx, p, { fell = true })
							elseif fl > r.floor + 1 then
								resetRun(ctx, p, "⚠️ Run cancelled — floors must be climbed one by one", true)
							elseif fl > r.floor then
								r.floor = math.min(fl, F)
								hud(ctx, p)
							end
							-- slow healing while you stay away from red blocks
							if hum.Health < hum.MaxHealth and (not r.lastHit or os.clock() - r.lastHit > cfg.RegenDelay) then
								hum.Health = math.min(hum.MaxHealth, hum.Health + cfg.RegenPerSecond * 0.2)
							end
						end
					end
				elseif ctx.Data.runs[p] then
					resetRun(ctx, p, nil)
				end
			end
			refresh += 0.2
			if refresh >= cfg.LeaderboardRefresh then refresh = 0 task.spawn(M.refreshBoard, ctx) end
			task.wait(0.2)
		end
	end)
end

function M.OnPlayerLeft(ctx, p) ctx.Data.runs[p] = nil end

function M.Finish(ctx)
	local list = {}
	for p, t in pairs(ctx.Data.roundBest) do if p.Parent then table.insert(list, { p = p, t = t }) end end
	table.sort(list, function(a, b) return a.t < b.t end)
	ctx.Ranking = {}
	for _, e in ipairs(list) do table.insert(ctx.Ranking, e.p) end
	ctx.RewardEligible = {}
	for p in pairs(ctx.Data.started) do ctx.RewardEligible[p] = true end
	local rw = ctx.Def.Rewards or {}
	ctx.ExtraRewards = {}
	for p, w in pairs(ctx.Data.roundWins) do
		ctx.ExtraRewards[p] = { amount = math.min(w, rw.MaxWinBonus or 5) * (rw.PerWin or 10), label = ("🏆 %d summit(s)"):format(w) }
	end
	if list[1] then ctx.WinnerText = ("⏱ Fastest climb: %s in %s"):format(list[1].p.DisplayName, fmt(list[1].t)) end
	for p in pairs(ctx.Participants) do if p.Parent then ctx:Send(p, { type = "tower", hide = true }) end end
end

function M.Cleanup(ctx)
	for _, tw in ipairs(ctx.Data.tweens or {}) do pcall(function() tw:Cancel() end) end
	local C, G = ctx.Data.C, ctx.Data.G
	for _, p in ipairs(Players:GetPlayers()) do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if root and C and G and (root.Position - C).Y > 6 and math.abs(root.Position.X - C.X) < G.HALF + 4 and math.abs(root.Position.Z - C.Z) < G.HALF + 4 then
			p.Character:PivotTo(CFrame.new(ctx.Data.lobby + Vector3.new(0, 3, 0)))
		end
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then hum.Health = hum.MaxHealth end
	end
end

return M
