--[[ SportsServer — Intramurals sports courts (framework + rally sports).
  Every court is a model in Workspace.SportsVenues (attributes Sport, CourtId, CourtName) with:
    Markers/A0,B0 (singles spots) A1,A2,B1,B2 (doubles spots) Cam1..3 (watch cameras)
    ProximityPrompts named "SportsJoin" (open the court panel), Seats named "CourtSeat" (spectators),
    a part named "ScoreBoard" (live score on its Front face).
  States: Idle → Lobby (anyone joins a team — no divisions, everyone plays together; countdown / Start)
          → Playing → Finished (winner shown) → Idle.
  Rally sports (Badminton, later Table Tennis / Pickleball / Volleyball):
    the receiver gets a timing meter; HIT inside the green zone returns the shot (choose Clear / Drop /
    Smash — a faster shot gives the opponent a smaller zone). Miss or no hit = point. Rally scoring.
    The SERVER decides every hit (it knows where the meter is); clients only animate.
  Everyone sees the match: the shuttle flies on all screens, players swing their rackets, the
  scoreboard updates. Spectators sit on the bleachers or press "Watch" for TV cameras.
  Vote-kick (every game): anyone on the court or watching it can start a vote to remove a player;
  the player is only removed if the majority votes YES.
]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SS = game:GetService("ServerScriptService")

local SportsFolder = RS:WaitForChild("Sports")
local C = require(SportsFolder:WaitForChild("SportsConfig"))
local Action = SportsFolder:WaitForChild("SportsAction")
local Event = SportsFolder:WaitForChild("SportsEvent")
local okR, Rewards = pcall(function() return require(SS:WaitForChild("Events"):WaitForChild("EventRewards")) end)
local BB = require(script.Parent:WaitForChild("BasketballEngine")) -- 🏀 3v3 / 5v5
local Chess = require(script.Parent:WaitForChild("ChessGame")) -- ♟️ library chess tables

local rand = Random.new()
-- link to the Intramurals event (EventModules.Intramurals sets Active while the event runs)
local ServerStorage = game:GetService("ServerStorage")
local signals = ServerStorage:FindFirstChild("SportsSignals") or Instance.new("Folder")
signals.Name = "SportsSignals" signals.Parent = ServerStorage
local intraActive = signals:FindFirstChild("IntramuralsActive") or Instance.new("BoolValue", signals) intraActive.Name = "IntramuralsActive"
local activity = signals:FindFirstChild("SportsActivity") or Instance.new("BindableEvent", signals) activity.Name = "SportsActivity"
local AUTO_FILL = 10 -- seconds: if nobody else joins, 🤖 CPU players fill the empty spots
local courts = {}          -- id -> court
local playerCourt = {}     -- player -> court (playing or in lobby)
local watching = {}        -- player -> court
local voteCooldown = {}

local DIV = {} for _, d in ipairs(C.Divisions) do DIV[d.id] = d end
local ANIM = {
	R15 = { swing = 522635514, ready = 507768375, cheer = 507770677 },
	R6 = { swing = 129967390, ready = 182393478, cheer = 129423030 },
}

---------------------------------------------------------------- helpers
local function other(side) return side == "A" and "B" or "A" end
local function names(list) local t = {} for _, e in ipairs(list) do table.insert(t, e.name) end return t end
local function entryOf(court, player)
	for _, side in ipairs({ "A", "B" }) do for i, e in ipairs(court.sides[side]) do if e.player == player then return e, side, i end end end
end

local function snapshot(court)
	local function side(s)
		local t = {}
		for _, e in ipairs(court.sides[s]) do table.insert(t, { name = e.name, userId = e.player and e.player.UserId or 0, cpu = e.cpu == true }) end
		return t
	end
	return {
		id = court.id, name = court.name, sport = court.sportId, icon = court.cfg.Icon, sportName = court.cfg.Name,
		state = court.state, division = court.division, a = side("A"), b = side("B"), perSide = court.cfg.PerSide,
		score = { A = court.score.A, B = court.score.B }, serve = court.serve, kind = court.cfg.Kind, tip = court.cfg.Tip,
		clock = court.state == "Playing" and BB.clock(court) or nil, overtime = court.bb and court.bb.overtime or nil, countdown = court.countdownEnds and math.max(0, math.ceil(court.countdownEnds - os.clock())) or (court.autoFillAt and math.max(0, math.ceil(court.autoFillAt - os.clock()))) or nil,
		autofill = court.autoFillAt ~= nil and not court.countdownEnds, intramurals = intraActive.Value,
		winner = court.winner, voteKick = true,
		vote = court.vote and { target = court.vote.targetName, yes = court.vote.yes, no = court.vote.no, ends = court.vote.ends - os.clock() } or nil,
		shots = (function() local t = {} for k, s in pairs(court.cfg.Shots or {}) do table.insert(t, { key = k, label = s.label, zone = s.zone }) end table.sort(t, function(x, y) return x.zone > y.zone end) return t end)(),
	}
end

local function updateBoard(court)
	local b = court.board
	if not b then return end
	local top = ("%s %s"):format(court.cfg.Icon, court.cfg.Name:upper())
	local function line(s) local n = names(court.sides[s]) return #n > 0 and table.concat(n, " & ") or "—" end
	local status
	if court.state == "Idle" then status = "OPEN — press E at the board to play!"
	elseif court.state == "Lobby" then status = court.countdownEnds and ("Starting in %d…"):format(math.max(0, math.ceil(court.countdownEnds - os.clock()))) or "Waiting for players…"
	elseif court.state == "Playing" and court.cfg.Kind == "Chess" then
		status = court.chess and (court.chess.s.turn == "w" and "⚪ White to move" or "⚫ Black to move") or "Setting up the pieces…"
	elseif court.state == "Playing" and court.cfg.Kind == "Basketball" then
		local c = BB.clock(court) or 0
		status = ("🏀 %s ball  •  ⏱ %d:%02d"):format(court.serve == "A" and "TEAM A" or "TEAM B", c // 60, math.floor(c % 60))
	elseif court.state == "Playing" then status = ("%s serving"):format(court.serve == "A" and "TEAM A" or "TEAM B")
	else status = court.winner and ("🏆 " .. court.winner .. " WIN!") or "Game over" end
	b.Top.Text = top
	b.A.Text = line("A") b.B.Text = line("B")
	b.SA.Text = tostring(court.score.A) b.SB.Text = tostring(court.score.B)
	b.Status.Text = status
end

local function broadcast(court)
	updateBoard(court)
	Event:FireAllClients({ t = "court", court = snapshot(court) })
end
local function toast(player, text) if player and player.Parent then Event:FireClient(player, { t = "toast", text = text }) end end
local function toastCourt(court, text)
	for _, s in ipairs({ "A", "B" }) do for _, e in ipairs(court.sides[s]) do toast(e.player, text) end end
	for p, c in pairs(watching) do if c == court then toast(p, text) end end
end

---------------------------------------------------------------- scoreboard UI on the board part
local function buildBoard(court)
	local part = court.model:FindFirstChild("ScoreBoard", true)
	if not part then return end
	local g = Instance.new("SurfaceGui") g.Name = "LiveScore" g.Face = Enum.NormalId.Front g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = 40 g.LightInfluence = 0 g.Parent = part
	local function lbl(name, size, pos, color, font)
		local t = Instance.new("TextLabel") t.Name = name t.Size = size t.Position = pos t.BackgroundTransparency = 1 t.TextScaled = true
		t.TextColor3 = color t.Font = font or Enum.Font.GothamBlack t.Parent = g return t
	end
	court.board = {
		Top = lbl("Top", UDim2.fromScale(0.96, 0.16), UDim2.fromScale(0.02, 0.03), Color3.fromRGB(255, 220, 120)),
		A = lbl("A", UDim2.fromScale(0.36, 0.14), UDim2.fromScale(0.03, 0.22), Color3.fromRGB(120, 190, 255), Enum.Font.GothamBold),
		B = lbl("B", UDim2.fromScale(0.36, 0.14), UDim2.fromScale(0.61, 0.22), Color3.fromRGB(255, 140, 140), Enum.Font.GothamBold),
		SA = lbl("SA", UDim2.fromScale(0.36, 0.42), UDim2.fromScale(0.03, 0.37), Color3.fromRGB(120, 190, 255), Enum.Font.Arcade),
		SB = lbl("SB", UDim2.fromScale(0.36, 0.42), UDim2.fromScale(0.61, 0.37), Color3.fromRGB(255, 140, 140), Enum.Font.Arcade),
		Status = lbl("Status", UDim2.fromScale(0.96, 0.13), UDim2.fromScale(0.02, 0.83), Color3.new(1, 1, 1), Enum.Font.GothamBold),
	}
	lbl("Dash", UDim2.fromScale(0.2, 0.3), UDim2.fromScale(0.4, 0.43), Color3.new(1, 1, 1), Enum.Font.Arcade).Text = "–"
end

---------------------------------------------------------------- players on court (position, racket, animations)
local function makePaddle(cfg)
	local m = Instance.new("Model") m.Name = "SportsHandProp"
	local function p(name, size, cf, color, shape)
		local x = Instance.new("Part") x.Name = name x.Size = size x.CFrame = cf x.Color = color x.Material = Enum.Material.SmoothPlastic
		x.CanCollide = false x.CanQuery = false x.CanTouch = false x.Massless = true x.CastShadow = false if shape then x.Shape = shape end x.Parent = m return x
	end
	local root = p("Root", Vector3.new(0.1, 0.1, 0.1), CFrame.new(), Color3.new(1, 1, 1)) root.Transparency = 1
	p("Handle", Vector3.new(0.2, 0.7, 0.14), CFrame.new(0, -0.15, 0), Color3.fromRGB(150, 100, 60))
	local big = cfg.Name == "Pickleball"
	local face = p("Face", Vector3.new(0.08, big and 1.3 or 1.0, big and 1.1 or 0.95), CFrame.new(0, big and -1.15 or -0.95, 0) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, math.rad(90), 0), big and Color3.fromRGB(40, 120, 200) or Color3.fromRGB(200, 40, 40), Enum.PartType.Cylinder)
	face.Size = Vector3.new(0.08, big and 1.3 or 1.0, big and 1.3 or 1.0)
	m.PrimaryPart = root
	return m
end
local function makeRacket(sportId)
	local cfg = C.Sports[sportId]
	if cfg and cfg.Racket == "Paddle" then return makePaddle(cfg) end
	local m = Instance.new("Model") m.Name = "SportsHandProp"
	local function p(name, size, cf, color, shape)
		local x = Instance.new("Part") x.Name = name x.Size = size x.CFrame = cf x.Color = color x.Material = Enum.Material.SmoothPlastic
		x.CanCollide = false x.CanQuery = false x.CanTouch = false x.Massless = true x.CastShadow = false if shape then x.Shape = shape end x.Parent = m return x
	end
	local root = p("Root", Vector3.new(0.1, 0.1, 0.1), CFrame.new(), Color3.new(1, 1, 1)) root.Transparency = 1
	p("Grip", Vector3.new(0.16, 0.8, 0.16), CFrame.new(0, -0.1, 0), Color3.fromRGB(30, 30, 35))
	p("Shaft", Vector3.new(0.06, 1.2, 0.06), CFrame.new(0, -1.1, 0), Color3.fromRGB(200, 200, 210))
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		p("Frame", Vector3.new(0.08, 0.3, 0.06), CFrame.new(math.cos(a) * 0.45, -2.25 + math.sin(a) * 0.6, 0) * CFrame.Angles(0, 0, a), Color3.fromRGB(230, 60, 70))
	end
	local strings = p("Strings", Vector3.new(0.8, 1.1, 0.02), CFrame.new(0, -2.25, 0), Color3.fromRGB(240, 240, 240)) strings.Transparency = 0.45
	m.PrimaryPart = root
	return m
end

local function loadTracks(e)
	local ch = e.char
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local rig = hum.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	e.tracks = {}
	for k, id in pairs(ANIM[rig]) do
		local a = Instance.new("Animation") a.AnimationId = "rbxassetid://" .. id
		local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
		if ok then tr.Priority = k == "ready" and Enum.AnimationPriority.Movement or Enum.AnimationPriority.Action tr.Looped = k == "ready" e.tracks[k] = tr end
	end
end
local function play(e, name, speed) local tr = e.tracks and e.tracks[name] if tr then tr:Play(0.08) if speed then tr:AdjustSpeed(speed) end end end

local function spotFor(court, side, i)
	local mk = court.markers
	if #court.sides[side] == 1 then return mk:FindFirstChild(side .. "0").CFrame end
	return mk:FindFirstChild(side .. i).CFrame
end

local function placeEntry(court, e, cf)
	local ch = e.char
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end
	local lift = hum.RigType == Enum.HumanoidRigType.R15 and (hum.HipHeight + root.Size.Y / 2) or 3
	e.home = cf + Vector3.new(0, lift, 0)
	root.Anchored = true
	ch:PivotTo(e.home)
end

local function equip(court, e)
	local ch = e.char
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if e.player then
		-- SC_Frozen: tells ShopServer not to give walk speed / jump back while the game holds you in place
		e.player:SetAttribute("SC_Frozen", true)
		e.saved = { ws = hum.WalkSpeed, jp = hum.JumpPower, jh = hum.JumpHeight, ar = hum.AutoRotate }
		hum.WalkSpeed, hum.JumpPower, hum.JumpHeight, hum.AutoRotate = 0, 0, 0, false
		if hum.Sit then hum.Sit = false end
	end
	loadTracks(e)
	if court.cfg.Kind ~= "Chess" then play(e, "ready") end
	local hand = ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm")
	if hand and court.cfg.Racket then -- volleyball / basketball: no racket, just hands
		local prop = makeRacket(court.sportId)
		prop:PivotTo(hand.CFrame * CFrame.new(0, -hand.Size.Y / 2, 0) * CFrame.Angles(math.rad(-90), 0, 0))
		for _, p in ipairs(prop:GetDescendants()) do if p:IsA("BasePart") then local w = Instance.new("WeldConstraint") w.Part0 = hand w.Part1 = p w.Parent = p end end
		prop.Parent = ch
		e.prop = prop
	end
end

local function unequip(e)
	if e.tracks then for _, tr in pairs(e.tracks) do pcall(function() tr:Stop(0.2) end) end e.tracks = nil end
	if e.prop then e.prop:Destroy() e.prop = nil end
	if e.cpu then if e.char then e.char:Destroy() end return end
	local ch = e.char
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if root then root.Anchored = false pcall(function() root:SetNetworkOwner(e.player) end) end
	if e.player and e.player.Parent then e.player:SetAttribute("SC_Frozen", nil) end
	if hum and e.saved then hum.WalkSpeed, hum.JumpPower, hum.JumpHeight, hum.AutoRotate = e.saved.ws, e.saved.jp, e.saved.jh, e.saved.ar end
	e.saved = nil
end

local function makeCpu(court, side)
	local d = Instance.new("HumanoidDescription")
	local skin = ({ Color3.fromRGB(234, 184, 146), Color3.fromRGB(204, 142, 105), Color3.fromRGB(160, 110, 80) })[rand:NextInteger(1, 3)]
	d.HeadColor, d.LeftArmColor, d.RightArmColor = skin, skin, skin
	d.TorsoColor = side == "A" and Color3.fromRGB(40, 110, 200) or Color3.fromRGB(210, 60, 70)
	d.LeftLegColor, d.RightLegColor = Color3.fromRGB(30, 30, 40), Color3.fromRGB(30, 30, 40)
	local ok, model = pcall(function() return Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15) end)
	if not ok then return nil end
	model.Name = "🤖 CPU"
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayName = "🤖 CPU" hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	model.HumanoidRootPart.Anchored = true
	model.Parent = court.model
	return model
end

---------------------------------------------------------------- court life cycle
local reset, startMatch, serveRally

local function removeEntry(court, e, side, i, quiet)
	table.remove(court.sides[side], i)
	if e.player then playerCourt[e.player] = nil end
	if court.state == "Playing" then unequip(e) elseif e.cpu and e.char then e.char:Destroy() end
	if e.player and not quiet then Event:FireClient(e.player, { t = "left", court = court.id }) end
end

local function forfeitCheck(court)
	if court.state ~= "Playing" then return end
	local humansA, humansB = 0, 0
	for _, e in ipairs(court.sides.A) do if not e.cpu then humansA += 1 end end
	for _, e in ipairs(court.sides.B) do if not e.cpu then humansB += 1 end end
	if #court.sides.A == 0 or #court.sides.B == 0 or (humansA + humansB) == 0 then
		local winSide = #court.sides.A > 0 and "A" or (#court.sides.B > 0 and "B" or nil)
		court.endMatch(winSide, "forfeit")
	end
end

local function leaveCourt(player, reason)
	local court = playerCourt[player]
	if not court then return end
	local e, side, i = entryOf(court, player)
	if e then removeEntry(court, e, side, i) end
	if court.state == "Lobby" then
		local humans = 0
		for _, s in ipairs({ "A", "B" }) do for _, x in ipairs(court.sides[s]) do if not x.cpu then humans += 1 end end end
		if humans == 0 then reset(court) return end
		if #court.sides.A == 0 or #court.sides.B == 0 then court.countdownEnds = nil end
	end
	forfeitCheck(court)
	broadcast(court)
end

function reset(court)
	for _, s in ipairs({ "A", "B" }) do
		for _, e in ipairs(court.sides[s]) do
			unequip(e)
			if e.player then playerCourt[e.player] = nil Event:FireClient(e.player, { t = "left", court = court.id }) end
		end
		court.sides[s] = {}
	end
	if court.bb or court.bbBall then BB.stop(court) end
	if court.cfg.Kind == "Chess" then Chess.reset(court) end
	court.state, court.division, court.countdownEnds, court.winner, court.rally, court.autoFillAt = "Idle", nil, nil, nil, nil, nil
	court.score = { A = 0, B = 0 }
	court.token += 1
	broadcast(court)
end

local function lobbyTick(court)
	-- countdown starts once both sides have a player
	if court.state ~= "Lobby" then return end
	if #court.sides.A > 0 and #court.sides.B > 0 then
		if not court.countdownEnds then court.countdownEnds = os.clock() + court.cfg.LobbyCountdown end
	else court.countdownEnds = nil end
end

function startMatch(court)
	if court.state ~= "Lobby" or #court.sides.A == 0 or #court.sides.B == 0 then return end
	court.state = "Playing"
	court.countdownEnds = nil
	court.score = { A = 0, B = 0 }
	court.serve = rand:NextNumber() < 0.5 and "A" or "B"
	court.token += 1
	for _, s in ipairs({ "A", "B" }) do
		for i, e in ipairs(court.sides[s]) do
			if e.player then e.char = e.player.Character end
			placeEntry(court, e, spotFor(court, s, i))
			equip(court, e)
		end
	end
	if court.cfg.Kind == "Chess" then
		broadcast(court)
		local tk = court.token
		task.delay(1, function() Chess.start(court, tk) end)
		return
	end
	if court.cfg.Kind == "Basketball" then
		toastCourt(court, ("%s %s tips off! First to %d or most points in %d min."):format(court.cfg.Icon, court.cfg.Name, court.cfg.WinScore, court.cfg.GameTime // 60))
		broadcast(court)
		local tk = court.token
		task.delay(1.5, function() BB.start(court, tk) end)
		return
	end
	toastCourt(court, ("%s %s match starts! First to %d."):format(court.cfg.Icon, court.cfg.Name, court.cfg.WinScore))
	broadcast(court)
	task.delay(1.5, function() serveRally(court, court.token) end)
end

local function payout(court, winSide)
	if not okR or not Rewards or not Rewards.addCurrency then return end
	local r = court.cfg.Rewards or {}
	for _, s in ipairs({ "A", "B" }) do
		for _, e in ipairs(court.sides[s]) do
			if e.player and e.player.Parent then
				local amount = (s == winSide) and (r.Win or 0) or (r.Play or 0)
				local cpuGame = false
				for _, x in ipairs(court.sides[other(s)]) do if x.cpu then cpuGame = true end end
				if cpuGame then amount = math.floor(amount / 2) end -- half rewards vs CPU
				local bonus = intraActive.Value
				if bonus then amount *= 2 end -- 🏆 Intramurals is a rare event: double rewards
				if amount > 0 then pcall(Rewards.addCurrency, e.player, r.Currency or "Common", amount) toast(e.player, ("🪙 +%d coins%s"):format(amount, bonus and "  (🏆 Intramurals x2!)" or "")) end
			end
		end
	end
end

local function endMatch(court, winSide, why)
	if court.state ~= "Playing" then return end
	court.state = "Finished"
	court.token += 1
	court.rally = nil
	if court.bb or court.bbBall then BB.stop(court) end
	if court.chess then Chess.stop(court) end
	local winners = winSide and table.concat(names(court.sides[winSide]), " & ") or "Nobody"
	court.winner = winSide and (winSide == "A" and "TEAM A" or "TEAM B") .. " (" .. winners .. ")" or nil
	for _, e in ipairs(court.sides[winSide or "A"]) do if winSide then play(e, "cheer") end end
	Event:FireAllClients({ t = "matchEnd", court = court.id, winner = court.winner, why = why, score = { A = court.score.A, B = court.score.B } })
	if winSide or why == "draw" then payout(court, winSide) end -- a draw pays everyone the "played" reward
	local winners, losers = {}, {}
	for _, s in ipairs({ "A", "B" }) do for _, e in ipairs(court.sides[s]) do if e.player then table.insert(s == winSide and winners or losers, e.player) end end end
	activity:Fire({ type = "result", sport = court.sportId, sportName = court.cfg.Name, icon = court.cfg.Icon, winners = winners, losers = losers, vsCpu = (function() for _, s in ipairs({ "A", "B" }) do for _, e in ipairs(court.sides[s]) do if e.cpu then return true end end end return false end)() })
	broadcast(court)
	task.delay(6, function() if court.state == "Finished" then reset(court) end end)
end

---------------------------------------------------------------- rally engine
local function meterAt(elapsed, speed)
	local p = (elapsed * (speed or C.MeterSpeed)) % 2
	return p < 1 and p or 2 - p
end
-- where the meter was when the player pressed HIT. The client tells us how long after the shot it pressed;
-- we only accept that if it fits the real time (up to 0.35 s of lag), otherwise we use our own clock.
local function pressedAt(r, clientT)
	local te = os.clock() - r.start
	local tc = tonumber(clientT)
	if tc and tc == tc and tc <= te + 0.05 and tc >= te - 0.35 then return tc end
	return te - 0.06
end

local function handPos(e)
	local ch = e.char
	local h = ch and (ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm"))
	return h and (h.Position + Vector3.new(0, 1.2, 0)) or (e.home and e.home.Position + Vector3.new(0, 2.5, 0)) or Vector3.zero
end

local function moveTo(e, pos, t)
	local root = e.char and e.char:FindFirstChild("HumanoidRootPart")
	if not root or not e.home then return end
	local target = CFrame.lookAt(Vector3.new(pos.X, e.home.Y, pos.Z), Vector3.new(pos.X, e.home.Y, pos.Z) + e.home.LookVector)
	TweenService:Create(root, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = target }):Play()
end

local function point(court, winSide, reason, landing)
	if court.state ~= "Playing" then return end
	court.rally = nil
	court.score[winSide] += 1
	court.serve = winSide
	Event:FireAllClients({ t = "point", court = court.id, side = winSide, reason = reason, landing = landing, score = { A = court.score.A, B = court.score.B } })
	local a, b = court.score.A, court.score.B
	local cfg = court.cfg
	local lead = math.abs(a - b)
	if (math.max(a, b) >= cfg.WinScore and lead >= cfg.WinBy) or math.max(a, b) >= cfg.MaxScore then
		broadcast(court)
		court.endMatch(a > b and "A" or "B", "score")
		return
	end
	broadcast(court)
	local token = court.token
	task.delay(1.8, function() serveRally(court, token) end)
end

local sendShot, attack
local function cpuRespond(court, r)
	-- the CPU "presses HIT" at a random moment; harder shots are missed more often
	local skill = court.cfg.CpuSkill
	local zone = (court.cfg.Shots[r.shot] or {}).zone or 0.2
	local chance = skill * math.clamp(zone / 0.2, 0.65, 1) * math.max(0.6, 1 - r.count * 0.02)
	local ok = rand:NextNumber() < chance
	task.delay(r.time * rand:NextNumber(0.45, 0.8), function()
		if court.rally ~= r or r.done then return end
		r.done = true
		if ok then
			-- pick a shot: easy ones more often, smashes sometimes
			local keys = {}
			for k, sh in pairs(court.cfg.Shots) do table.insert(keys, { k = k, w = sh.zone }) end
			table.sort(keys, function(a, b) return a.w > b.w end)
			local roll = rand:NextNumber()
			local pick = roll < 0.5 and keys[1] or (roll < 0.8 and (keys[2] or keys[1]) or keys[#keys])
			attack(court, r.receiver, r.side, pick.k)
		else
			Event:FireAllClients({ t = "miss", court = court.id, from = handPos(r.receiver), side = r.side })
			point(court, other(r.side), "🤖 CPU missed!", nil)
		end
	end)
end

function sendShot(court, hitter, fromSide, shotKey)
	if court.state ~= "Playing" then return end
	local shot = court.cfg.Shots[shotKey] or court.cfg.Shots[court.cfg.ServeShot]
	local toSide = other(fromSide)
	local list = court.sides[toSide]
	if #list == 0 then return end
	local recv = list[rand:NextInteger(1, #list)]
	play(hitter, "swing", 1.3)
	-- landing spot near the receiver (they run there)
	local base = recv.home and recv.home.Position or court.cf.Position
	local landing
	local L = court.cfg.Land
	if L then
		-- e.g. table tennis: the ball bounces on the receiver's half of the table
		local dirZ = toSide == "A" and -1 or 1
		landing = (court.cf * CFrame.new(rand:NextNumber(-L.lateral, L.lateral), L.height, dirZ * rand:NextNumber(L.depth * 0.6, L.depth))).Position
	else
		local lateral = court.cf.RightVector * rand:NextNumber(-3, 3)
		local depth = court.cf.LookVector * (toSide == "A" and 1 or -1) * rand:NextNumber(-2.5, 3)
		landing = Vector3.new(base.X, court.cf.Y + 0.3, base.Z) + lateral + depth
	end
	local from = handPos(hitter)
	local count = (court.rally and court.rally.count or 0) + 1
	local speed = court.cfg.MeterSpeed or C.MeterSpeed
	local half = math.max(0.06, shot.zone * (0.97 ^ count) / 2)
	-- the zone must be reachable before the ball arrives
	local reach = math.min(0.82, speed * shot.time * 0.8)
	local r = { receiver = recv, side = toSide, shot = shotKey, time = shot.time, start = os.clock(), count = count,
		center = rand:NextNumber(math.min(0.18 + half, reach), math.max(0.18 + half, reach)), half = half, landing = landing }
	r.center = math.clamp(r.center, half, 1 - half)
	court.rally = r
	if L then
		-- step sideways behind the table toward the ball
		moveTo(recv, Vector3.new(landing.X, base.Y, base.Z) + court.cf.RightVector * 0, shot.time * 0.8)
	else
		moveTo(recv, landing - court.cf.LookVector * (toSide == "A" and 1.2 or -1.2), shot.time * 0.85)
	end
	local toPos = L and (landing + Vector3.new(0, 0.2, 0)) or (landing + Vector3.new(0, 2.6, 0))
	Event:FireAllClients({ t = "shot", court = court.id, from = from, to = toPos, time = shot.time, height = shot.height, shot = shotKey, count = count,
		ball = court.cfg.Ball, ballColor = court.cfg.BallColor, ballSize = court.cfg.BallSize, holes = court.cfg.Holes, bounceTo = L and handPos(recv) or nil })
	if recv.cpu then cpuRespond(court, r)
	elseif recv.player then
		local smashKey
		for k, sh in pairs(court.cfg.Shots) do if not smashKey or sh.zone < court.cfg.Shots[smashKey].zone then smashKey = k end end
		Event:FireClient(recv.player, { t = "incoming", court = court.id, time = shot.time, center = r.center, half = r.half, speed = speed, shot = shotKey, fast = shotKey == smashKey, label = shot.label, count = count })
	end
	task.delay(shot.time + 0.2, function()
		if court.rally == r and not r.done then
			r.done = true
			point(court, fromSide, ("%s didn't reach it!"):format(recv.name), landing)
		end
	end)
end

-- Team sports (volleyball): the receiver BUMPS the ball to a teammate, the setter SETS it up, then an
-- attacker jumps and sends the chosen shot over the net. Everyone sees the three touches.
local function hop(e, up, t)
	local root = e.char and e.char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local base = root.CFrame
	local tw = TweenService:Create(root, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = base + Vector3.new(0, up, 0) })
	tw:Play()
	task.delay(t, function() if root.Parent then TweenService:Create(root, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = base }):Play() end end)
end

function attack(court, recv, side, key)
	local cfg = court.cfg
	local team = court.sides[side]
	if not cfg.TeamTouches or #team < 2 then return sendShot(court, recv, side, key) end
	local token = court.token
	local mates = {}
	for _, e in ipairs(team) do if e ~= recv then table.insert(mates, e) end end
	local setter = mates[rand:NextInteger(1, #mates)]
	local pool = {}
	for _, e in ipairs(team) do if e ~= setter then table.insert(pool, e) end end
	local hitter = recv.player and recv or pool[rand:NextInteger(1, #pool)] -- a real player who received also gets the kill
	local s = side == "A" and 1 or -1
	local setSpot = (court.cf * CFrame.new(1.5 * s, 0, -2.6 * s)).Position
	local hitSpot = (court.cf * CFrame.new(-5 * s, 0, -3.6 * s)).Position
	local look = { ball = cfg.Ball, ballColor = cfg.BallColor, ballSize = cfg.BallSize, holes = cfg.Holes }
	local function fx(from, to, time, height, shot)
		local d = { t = "shot", court = court.id, from = from, to = to, time = time, height = height, shot = shot, count = 0 }
		for k, v in pairs(look) do d[k] = v end
		Event:FireAllClients(d)
	end
	local function alive() return court.state == "Playing" and court.token == token end
	local shotLabel = (cfg.Shots[key] or {}).label or "Attack"
	Event:FireAllClients({ t = "touch", court = court.id, text = ("🙌 %s bumps → %s sets → %s %s"):format(recv.name, setter.name, hitter.name, shotLabel) })
	-- 1) bump
	play(recv, "swing", 1.1)
	moveTo(setter, setSpot, 0.6)
	moveTo(hitter, hitSpot, 0.9)
	fx(handPos(recv), setSpot + Vector3.new(0, 5.2, 0), 0.75, 7, "bump")
	task.delay(0.75, function()
		if not alive() then return end
		-- 2) set
		play(setter, "swing", 1.3)
		fx(setSpot + Vector3.new(0, 5.2, 0), hitSpot + Vector3.new(0, 6.6, 0), 0.7, 4.5, "set")
		task.delay(0.42, function() if alive() then hop(hitter, 2.4, 0.28) end end)
		task.delay(0.7, function()
			if not alive() then return end
			-- 3) attack over the net
			sendShot(court, hitter, side, key)
		end)
	end)
end

function serveRally(court, token)
	if court.state ~= "Playing" or court.token ~= token then return end
	local list = court.sides[court.serve]
	if #list == 0 then return forfeitCheck(court) end
	-- everyone walks back to their spot
	for _, s in ipairs({ "A", "B" }) do for i, e in ipairs(court.sides[s]) do
		local cf = spotFor(court, s, i)
		local root = e.char and e.char:FindFirstChild("HumanoidRootPart")
		if root and e.home then e.home = CFrame.new(cf.Position + Vector3.new(0, e.home.Y - cf.Y, 0)) * cf.Rotation TweenService:Create(root, TweenInfo.new(0.6), { CFrame = e.home }):Play() end
	end end
	court.rally = nil
	local server = list[rand:NextInteger(1, #list)]
	Event:FireAllClients({ t = "serve", court = court.id, side = court.serve, name = server.name })
	broadcast(court)
	task.delay(court.cfg.ServeDelay, function()
		if court.state ~= "Playing" or court.token ~= token or court.rally then return end
		sendShot(court, server, court.serve, court.cfg.ServeShot)
	end)
end

---------------------------------------------------------------- vote kick
local function voters(court, exclude)
	local list = {}
	for _, s in ipairs({ "A", "B" }) do for _, e in ipairs(court.sides[s]) do if e.player and e.player ~= exclude then list[e.player] = true end end end
	for p, c in pairs(watching) do if c == court and p ~= exclude then list[p] = true end end
	return list
end

local function finishVote(court)
	local v = court.vote
	if not v then return end
	court.vote = nil
	local eligible = 0 for _ in pairs(v.voters) do eligible += 1 end
	local need = math.max(1, math.ceil(eligible * 0.5))
	local passed = v.yes >= need and v.yes > v.no
	if not RunService:IsStudio() and eligible < 2 then passed = false end
	local target = v.target
	if passed and target and target.Parent then
		court.bans[target.UserId] = { untilT = os.clock() + C.VoteKick.BanSeconds }
		toast(target, ("🚫 The players voted you out of this %s game. You can come back in %d minutes."):format(court.cfg.Name, math.floor(C.VoteKick.BanSeconds / 60)))
		leaveCourt(target, "kicked")
		toastCourt(court, ("🚫 %s was voted out (%d yes / %d no)."):format(v.targetName, v.yes, v.no))
	else
		toastCourt(court, ("✅ Vote failed — %s stays (%d yes / %d no)."):format(v.targetName, v.yes, v.no))
	end
	for p in pairs(v.voters) do Event:FireClient(p, { t = "voteEnd", court = court.id }) end
	broadcast(court)
end

local function startVote(court, by, targetId)
	if court.state == "Idle" then return false, "Nobody is playing here yet" end
	if court.vote then return false, "A vote is already running" end
	if voteCooldown[by] and os.clock() - voteCooldown[by] < C.VoteKick.Cooldown then return false, "Wait before starting another vote" end
	local target
	for _, s in ipairs({ "A", "B" }) do for _, e in ipairs(court.sides[s]) do if e.player and e.player.UserId == targetId then target = e.player end end end
	if not target then return false, "That player isn't in this game" end
	if target == by then return false, "You can't vote yourself out" end
	local vs = voters(court, target)
	if not vs[by] then return false, "Only players and watchers of this court can vote" end
	voteCooldown[by] = os.clock()
	court.vote = { target = target, targetName = target.DisplayName, by = by, voters = vs, votes = { [by] = true }, yes = 1, no = 0, ends = os.clock() + C.VoteKick.Duration }
	for p in pairs(vs) do
		Event:FireClient(p, { t = "vote", court = court.id, target = target.DisplayName, by = by.DisplayName, sport = court.cfg.Name, duration = C.VoteKick.Duration, voted = p == by })
	end
	toast(target, ("⚠️ %s started a vote to remove you from this game. The other players decide."):format(by.DisplayName))
	local v = court.vote
	task.delay(C.VoteKick.Duration, function() if court.vote == v then finishVote(court) end end)
	broadcast(court)
	-- everybody already voted?
	local total = 0 for _ in pairs(vs) do total += 1 end
	if v.yes + v.no >= total then finishVote(court) end
	return true
end

Chess.init({ Event = Event, broadcast = broadcast, toastCourt = toastCourt, endMatch = function(court, side, why) court.endMatch(side, why) end })
-- 🏀 the basketball engine uses these helpers
BB.init({
	Event = Event, play = play, broadcast = broadcast, toastCourt = toastCourt, handPos = handPos,
	forfeitCheck = forfeitCheck, pressedAt = pressedAt, meterAt = meterAt,
	endMatch = function(court, side, why) court.endMatch(side, why) end,
})

---------------------------------------------------------------- remote API
Action.OnServerInvoke = function(player, action, data)
	data = type(data) == "table" and data or {}
	local court = data.court and courts[data.court] or playerCourt[player] or watching[player]
	if action == "state" then return court and snapshot(court) or nil end
	if not court then return { ok = false, msg = "No court" } end
	local cfg = court.cfg

	if action == "join" then
		if playerCourt[player] and playerCourt[player] ~= court then return { ok = false, msg = "You're already in another game" } end
		if court.state == "Playing" or court.state == "Finished" then return { ok = false, msg = "A match is being played — watch or wait for the next one!" } end
		local side = data.side == "B" and "B" or "A"
		local e0 = entryOf(court, player)
		if e0 then return { ok = false, msg = "You're already on this court" } end
		local ban = court.bans[player.UserId]
		if ban and os.clock() < ban.untilT then
			return { ok = false, msg = ("You were voted out of this court. Try again in %d s."):format(math.ceil(ban.untilT - os.clock())) }
		end
		if court.state == "Idle" then court.state = "Lobby" end
		if #court.sides[side] >= cfg.PerSide then
			-- replace a CPU if there is one
			local replaced = false
			for i, e in ipairs(court.sides[side]) do if e.cpu then removeEntry(court, e, side, i, true) replaced = true break end end
			if not replaced then return { ok = false, msg = "That side is full" } end
		end
		table.insert(court.sides[side], { player = player, name = player.DisplayName })
		playerCourt[player] = court
		court.autoFillAt = os.clock() + AUTO_FILL
		activity:Fire({ type = "join", player = player, sport = court.sportId })
		if watching[player] == court then watching[player] = nil end
		lobbyTick(court)
		broadcast(court)
		return { ok = true }
	elseif action == "leave" then
		leaveCourt(player, "left")
		return { ok = true }
	elseif action == "cpu" then
		if playerCourt[player] ~= court or court.state ~= "Lobby" then return { ok = false } end
		local side = data.side == "B" and "B" or "A"
		if #court.sides[side] >= cfg.PerSide then return { ok = false, msg = "That side is full" } end
		local rig = makeCpu(court, side)
		if not rig then return { ok = false, msg = "Couldn't add a CPU" } end
		local cpuCount = 0 for _, s in ipairs({ "A", "B" }) do for _, e in ipairs(court.sides[s]) do if e.cpu then cpuCount += 1 end end end
		local e = { cpu = true, name = "🤖 CPU " .. (cpuCount + 1), char = rig }
		table.insert(court.sides[side], e)
		rig:PivotTo(spotFor(court, side, #court.sides[side]) + Vector3.new(0, 3, 0))
		lobbyTick(court)
		broadcast(court)
		return { ok = true }
	elseif action == "start" then
		if playerCourt[player] ~= court or court.state ~= "Lobby" then return { ok = false } end
		if #court.sides.A == 0 or #court.sides.B == 0 then return { ok = false, msg = "Both sides need a player (or a 🤖 CPU)" } end
		startMatch(court)
		return { ok = true }
	elseif action == "move" and cfg.Kind == "Chess" then
		if playerCourt[player] ~= court then return { ok = false } end
		return Chess.move(court, player, data)
	elseif action == "resign" and cfg.Kind == "Chess" then
		if playerCourt[player] ~= court then return { ok = false } end
		return Chess.resign(court, player)
	elseif action == "chess" and cfg.Kind == "Chess" then
		Chess.push(court)
		return { ok = true }
	elseif action == "hit" and cfg.Kind == "Basketball" then
		if playerCourt[player] ~= court then return { ok = false } end
		return BB.hit(court, player, data)
	elseif action == "hit" then
		local r = court.rally
		if court.state ~= "Playing" or not r or r.done or not r.receiver or r.receiver.player ~= player then return { ok = false } end
		local t = pressedAt(r, data.t)
		local pos = meterAt(t, cfg.MeterSpeed)
		local inZone = math.abs(pos - r.center) <= r.half
		local tooLate = t > r.time + 0.1
		r.done = true
		if inZone and not tooLate then
			local shotKey = cfg.Shots[data.shot] and data.shot or cfg.ServeShot
			attack(court, r.receiver, r.side, shotKey)
			return { ok = true, hit = true, pos = pos }
		end
		Event:FireAllClients({ t = "miss", court = court.id, from = handPos(r.receiver), side = r.side })
		point(court, other(r.side), ("%s mis-hit it into the net!"):format(r.receiver.name), nil)
		return { ok = true, hit = false, pos = pos }
	elseif action == "watch" then
		watching[player] = court
		return { ok = true, court = snapshot(court) }
	elseif action == "unwatch" then
		if watching[player] == court then watching[player] = nil end
		return { ok = true }
	elseif action == "votekick" then
		local ok, msg = startVote(court, player, tonumber(data.target))
		return { ok = ok, msg = msg }
	elseif action == "vote" then
		local v = court.vote
		if not v or not v.voters[player] or v.votes[player] ~= nil then return { ok = false } end
		v.votes[player] = data.yes == true
		if data.yes == true then v.yes += 1 else v.no += 1 end
		local total, done = 0, 0
		for p in pairs(v.voters) do total += 1 if v.votes[p] ~= nil then done += 1 end end
		broadcast(court)
		if done >= total then finishVote(court) end
		return { ok = true }
	end
	return { ok = false }
end

---------------------------------------------------------------- set up courts
local function setupCourt(model)
	local sportId = model:GetAttribute("Sport")
	local cfg = sportId and C.Sports[sportId]
	local id = model:GetAttribute("CourtId")
	if not cfg or not id or courts[id] then return end
	local court = {
		id = id, name = model:GetAttribute("CourtName") or id, sportId = sportId, cfg = cfg, model = model,
		cf = model:GetAttribute("CourtCF") or model:GetPivot(), markers = model:WaitForChild("Markers"),
		state = "Idle", sides = { A = {}, B = {} }, score = { A = 0, B = 0 }, serve = "A", token = 0, bans = {},
	}
	court.endMatch = function(side, why) endMatch(court, side, why) end
	courts[id] = court
	buildBoard(court)
	if cfg.Kind == "Chess" then Chess.setupIdle(court) end
	for _, pp in ipairs(model:GetDescendants()) do
		if pp:IsA("ProximityPrompt") and pp.Name == "SportsJoin" then
			pp.Triggered:Connect(function(player) Event:FireClient(player, { t = "open", court = snapshot(court) }) end)
		end
	end
	updateBoard(court)
end

-- "ChessAny" door: a table where someone is already waiting for an opponent, else the first free table
local function pickCourt(sportId)
	local list = {}
	for _, c in pairs(courts) do if c.sportId == sportId then table.insert(list, c) end end
	table.sort(list, function(a, b) return (tonumber(a.id:match("%d+$")) or 0) < (tonumber(b.id:match("%d+$")) or 0) end)
	for _, c in ipairs(list) do
		if c.state == "Lobby" and (#c.sides.A < c.cfg.PerSide or #c.sides.B < c.cfg.PerSide) then
			for _, s in ipairs({ "A", "B" }) do for _, e in ipairs(c.sides[s]) do if e.player then return c end end end
		end
	end
	for _, c in ipairs(list) do if c.state == "Idle" then return c end end
	return list[1]
end

-- teleport pads ("Portal" models with a PortalPrompt and a TeleportTo attribute)
local portalCD = {}
local function hookPortals(root)
	for _, pp in ipairs(root:GetDescendants()) do
		if pp:IsA("ProximityPrompt") and pp.Name == "PortalPrompt" then
			local function go(player)
				local to = pp.Parent:GetAttribute("TeleportTo")
				local ch = player.Character
				local hum = ch and ch:FindFirstChildOfClass("Humanoid")
				if typeof(to) ~= "Vector3" or not hum or playerCourt[player] then return end
				if portalCD[player] and os.clock() - portalCD[player] < 2 then return end
				portalCD[player] = os.clock()
				hum.Sit = false
				ch:PivotTo(CFrame.new(to + Vector3.new(rand:NextNumber(-2, 2), 0, rand:NextNumber(-2, 2))))
				local open = pp.Parent:GetAttribute("OpenCourt")
				local target = open == "ChessAny" and pickCourt("Chess") or (open and courts[open])
				if target then task.delay(0.7, function() Event:FireClient(player, { t = "open", court = snapshot(target) }) end) end
			end
			pp.Triggered:Connect(go)
			-- walking into a door also teleports
			if pp.Parent.Name == "Doorway" then
				pp.Parent.Touched:Connect(function(hit)
					local pl = Players:GetPlayerFromCharacter(hit.Parent)
					if pl and hit.Name == "HumanoidRootPart" then go(pl) end
				end)
			end
		end
	end
end

local venues = workspace:WaitForChild("SportsVenues", 30)
if venues then hookPortals(venues) end
if venues then
	for _, m in ipairs(venues:GetChildren()) do setupCourt(m) end
	venues.ChildAdded:Connect(setupCourt)
end
-- 🏆 the venues are stored in ServerStorage.HiddenVenues (like the School Fair kit) and only come out
-- when the event rotation picks Intramurals; set them up from there too
do
	local store = ServerStorage:FindFirstChild("HiddenVenues")
	if store then
		hookPortals(store)
		for _, m in ipairs(store:GetChildren()) do setupCourt(m) end
	end
end

-- nobody else came: fill the empty spots with 🤖 CPU players and start
local function autoFill(court)
	if court.state ~= "Lobby" then return end
	local humans = 0
	for _, s in ipairs({ "A", "B" }) do for _, e in ipairs(court.sides[s]) do if not e.cpu then humans += 1 end end end
	if humans == 0 then return end
	local target = court.cfg.AutoFill == "full" and court.cfg.PerSide or math.max(1, #court.sides.A, #court.sides.B)
	for _, side in ipairs({ "A", "B" }) do
		while #court.sides[side] < target do
			local rig = makeCpu(court, side)
			if not rig then break end
			local n = 0 for _, s in ipairs({ "A", "B" }) do for _, e in ipairs(court.sides[s]) do if e.cpu then n += 1 end end end
			table.insert(court.sides[side], { cpu = true, name = "🤖 CPU " .. (n + 1), char = rig })
			rig:PivotTo(spotFor(court, side, #court.sides[side]) + Vector3.new(0, 3, 0))
		end
	end
	toastCourt(court, "🤖 No one else joined — CPU players filled the court!")
	broadcast(court)
	startMatch(court)
end

-- countdowns + live board refresh
task.spawn(function()
	while true do
		task.wait(1)
		for _, court in pairs(courts) do
			if court.state == "Playing" and court.cfg.Kind == "Basketball" then updateBoard(court) end -- game clock on the scoreboard
			if court.state == "Lobby" and court.autoFillAt and os.clock() >= court.autoFillAt and (#court.sides.A == 0 or #court.sides.B == 0 or not court.countdownEnds) then
				court.autoFillAt = nil
				autoFill(court)
			elseif court.state == "Lobby" and court.autoFillAt and not court.countdownEnds then
				Event:FireAllClients({ t = "tick", court = court.id, countdown = math.ceil(court.autoFillAt - os.clock()), autofill = true })
			end
			if court.state == "Lobby" and court.countdownEnds then
				if os.clock() >= court.countdownEnds then startMatch(court) else updateBoard(court) Event:FireAllClients({ t = "tick", court = court.id, countdown = math.ceil(court.countdownEnds - os.clock()) }) end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(p)
	leaveCourt(p, "left game")
	watching[p] = nil
	voteCooldown[p] = nil
	for _, court in pairs(courts) do if court.vote and court.vote.voters[p] then court.vote.voters[p] = nil end end
end)
-- dying / respawning removes you from the match
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function() if playerCourt[p] and playerCourt[p].state == "Playing" then leaveCourt(p, "respawned") end end)
end)
for _, p in ipairs(Players:GetPlayers()) do
	p.CharacterAdded:Connect(function() if playerCourt[p] and playerCourt[p].state == "Playing" then leaveCourt(p, "respawned") end end)
end

---------------------------------------------------------------- 🏆 venues only exist during the Intramurals event
-- Closed: every venue (doors, courts, islands, chess tables) waits in ServerStorage.HiddenVenues and the
-- library gets its reading tables back. Open (the event rotation picked Intramurals): everything appears.
-- When the event ends, running matches get a short grace time, then players are sent back to the 1F hall.
local HIDDEN = ServerStorage:FindFirstChild("HiddenVenues") or Instance.new("Folder")
HIDDEN.Name = "HiddenVenues" HIDDEN.Parent = ServerStorage
local HALL = CFrame.new(221.5, 4.6, 150) -- 1F hall, in front of where the doors stand
local CLOSE_GRACE = 30
local libraryRoom = (function()
	local ok, r = pcall(function() return workspace.SamarCollege_Campus["2F"]["02_Rooms"].CollegeLibrary end)
	return ok and r or nil
end)()
local readingBackup = ServerStorage:FindFirstChild("Backup_LibraryReadingArea")

local function insideVenue(player)
	local ch = player.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if not root or not venues then return false end
	if playerCourt[player] or watching[player] then return true end
	for _, m in ipairs(venues:GetChildren()) do
		if m:IsA("Model") then
			local cf, size = m:GetBoundingBox()
			local rel = cf:PointToObjectSpace(root.Position)
			local h = size / 2 + Vector3.new(6, 12, 6)
			if math.abs(rel.X) <= h.X and math.abs(rel.Y) <= h.Y and math.abs(rel.Z) <= h.Z then return true end
		end
	end
	return false
end

local venuesOpen = nil
local closeToken = 0
local function openVenues()
	if not venues then return end
	for _, m in ipairs(HIDDEN:GetChildren()) do m.Parent = venues end
	if libraryRoom and libraryRoom:FindFirstChild("ReadingArea") and readingBackup then libraryRoom.ReadingArea.Parent = readingBackup end
	workspace:SetAttribute("IntramuralsActive", true)
	venuesOpen = true
end
local function closeVenues()
	if not venues then return end
	workspace:SetAttribute("IntramuralsActive", false)
	-- end every game and send people home
	for _, court in pairs(courts) do if court.state ~= "Idle" then reset(court) end end
	for _, p in ipairs(Players:GetPlayers()) do
		if insideVenue(p) then
			local ch = p.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if hum then hum.Sit = false end
			if ch then ch:PivotTo(HALL + Vector3.new(rand:NextNumber(-4, 4), 0, rand:NextNumber(-3, 3))) end
			Event:FireClient(p, { t = "toast", text = "🏆 Intramurals is over — you're back in the 1F hall. See you next time!" })
		end
		watching[p] = nil
	end
	for _, m in ipairs(venues:GetChildren()) do m.Parent = HIDDEN end
	if libraryRoom and readingBackup and readingBackup:FindFirstChild("ReadingArea") then readingBackup.ReadingArea.Parent = libraryRoom end
	venuesOpen = false
end
local function onIntramurals()
	closeToken += 1
	local my = closeToken
	if intraActive.Value then
		if venuesOpen ~= true then openVenues() end
		return
	end
	if venuesOpen == false then return end
	if venuesOpen == nil then closeVenues() return end -- server start: hide right away
	-- the event just ended: let running matches finish (up to CLOSE_GRACE seconds)
	local busy = false
	for _, c in pairs(courts) do if c.state == "Playing" or c.state == "Lobby" then busy = true end end
	if busy then
		for _, p in ipairs(Players:GetPlayers()) do
			if insideVenue(p) then Event:FireClient(p, { t = "toast", text = ("🏆 Intramurals has ended — courts close in %d s. Finish your game!"):format(CLOSE_GRACE) }) end
		end
		local t0 = os.clock()
		repeat
			task.wait(1)
			if my ~= closeToken then return end
			busy = false
			for _, c in pairs(courts) do if c.state == "Playing" then busy = true end end
		until not busy or os.clock() - t0 >= CLOSE_GRACE
	end
	if my == closeToken and not intraActive.Value then closeVenues() end
end
intraActive.Changed:Connect(function() task.spawn(onIntramurals) end)
task.defer(onIntramurals)

-- map teleports and doors can't take you to a closed venue
function _G.SC_IntramuralsOpen() return venuesOpen == true end

-- EquipLock: equipment (bike, coils, boots, flashlight...) is off while you're in a game (lobby or playing)
task.spawn(function()
	while true do
		for _, p in ipairs(Players:GetPlayers()) do
			local inGame = playerCourt[p] ~= nil
			if (p:GetAttribute("Lock_Court") == true) ~= inGame then p:SetAttribute("Lock_Court", inGame or nil) end
		end
		task.wait(0.4)
	end
end)

print(("[Sports] %d court(s) ready"):format((function() local n = 0 for _ in pairs(courts) do n += 1 end return n end)()))
