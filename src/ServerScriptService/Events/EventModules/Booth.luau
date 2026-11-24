--[[ Booth v2 – SCHOOL FAIR in the 1F Open Hall ─────────────────────────────────────────────
  The fair (8 detailed stalls + arch, prize corner, carpet, lights, bunting) is a ready-made kit:
  ServerStorage.SchoolFairKit  (edit it in Studio: move it to Workspace, change, move it back).
  When the event starts the kit is cloned into the event folder; when it ends it is removed.

  ONE PLAYER PER BOOTH. While someone plays:
    • they stand on the booth's "PLAY HERE" mat facing the stall (can't walk away),
    • they hold the booth's item (ring, dart, ball, mallet…) and play real animations,
    • everyone around SEES the game: rings fly onto bottles, darts stick in the board, balloons pop,
      the wheel spins, cards flip, moles pop up, the ball goes through the hoop…
    • the stall lamp turns RED and the sign above says who is playing and their tickets.

  Booth game modules (EventModules.BoothGames) provide:
     Name, Icon, Color, Description
     HandProp(fx)                       → a part/model the player holds (optional)
     Bind(ctx, B, fx)                   → wire up the stall's props once (optional)
     Start(ctx, player, s, B, fx)       → UI description for the client panel
     Action(ctx, player, s, data, B, fx)→ validates a move, returns { tickets =, done =, msg = ... }
     Stop(ctx, player, s, B, fx)        → reset the stall's props (optional)
  Tickets are the event score; most tickets at the end = place bonuses.
───────────────────────────────────────────────────────────────────────────────────────────]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")

local M = {}
local GamesFolder = script.Parent:WaitForChild("BoothGames")
local FAIR_CENTER = Vector3.new(143.1, 1, -61)
local FAIR_NAME = "Open Hall (1F)"
local GOTO = Vector3.new(184, 4.5, -61)
-- three ways to start a booth: press E, click / tap the booth, or stand on the PLAY HERE mat for a moment
local MAT_RADIUS = 2.8   -- how close to the middle of the mat counts as "on the mat"
local MAT_HOLD = 1.5     -- seconds standing on the mat before the game starts by itself
local PROMPT_RANGE = 7   -- E range, measured from the mat (short, so neighbouring booths / chairs don't fight over E)

---------------------------------------------------------------- sounds + animations
M.SOUNDS = {
	Ping = "rbxasset://sounds/electronicpingshort.wav",   -- built-in Roblox sounds (always load)
	Swoosh = "rbxasset://sounds/action_get_up.mp3",
	Click = "rbxasset://sounds/clickfast.wav",
	Pop = "rbxasset://sounds/snap.mp3",
	Bonk = "rbxasset://sounds/Kerplunk.wav",
	Clang = "rbxasset://sounds/hit.wav",
	Win = "rbxasset://sounds/victory.wav",
}
local ANIMS = {
	R15 = { hold = 507768375, throw = 522635514, lunge = 522638767, point = 507770453, cheer = 507770677, wave = 507770239 },
	R6  = { hold = 182393478, throw = 129967390, lunge = 129967478, point = 128853357, cheer = 129423030, wave = 128777973 },
}

---------------------------------------------------------------- FX helpers (shared with the booth games)
local fx = {}
M.fx = fx
fx.rand = Random.new()

-- move a part or model along an arc (blocks until done; call inside task.spawn for async)
function fx.fly(obj, fromCF, toCF, height, dur, spin)
	local t0 = os.clock()
	local function set(cf) if obj:IsA("Model") then obj:PivotTo(cf) else obj.CFrame = cf end end
	while true do
		local t = math.min(1, (os.clock() - t0) / dur)
		local pos = fromCF.Position:Lerp(toCF.Position, t) + Vector3.new(0, (height or 0) * 4 * t * (1 - t), 0)
		local rot = fromCF.Rotation:Lerp(toCF.Rotation, t)
		if spin then rot = rot * CFrame.Angles(spin * t, 0, 0) end
		set(CFrame.new(pos) * rot)
		if t >= 1 then break end
		RunService.Heartbeat:Wait()
	end
end
-- smooth move of a model or part to a CFrame
function fx.move(obj, toCF, dur, style, dir)
	local from = obj:IsA("Model") and obj:GetPivot() or obj.CFrame
	local v = Instance.new("NumberValue")
	local conn = v.Changed:Connect(function(a)
		local cf = from:Lerp(toCF, a)
		if obj:IsA("Model") then obj:PivotTo(cf) else obj.CFrame = cf end
	end)
	local tw = TweenService:Create(v, TweenInfo.new(dur, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), { Value = 1 })
	tw.Completed:Connect(function() conn:Disconnect() v:Destroy() end)
	tw:Play()
	return tw
end
-- particle burst at a position
function fx.burst(pos, color, count, speed, size)
	local p = Instance.new("Part") p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2) p.CFrame = CFrame.new(pos) p.Parent = workspace
	local e = Instance.new("ParticleEmitter") e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = typeof(color) == "ColorSequence" and color or ColorSequence.new(color or Color3.new(1, 1, 1))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size or 0.5), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.5, 0.9) e.Speed = NumberRange.new((speed or 10) * 0.5, speed or 10) e.SpreadAngle = Vector2.new(180, 180)
	e.Drag = 4 e.LightEmission = 0.6 e.Rate = 0 e.Parent = p
	e:Emit(count or 20)
	Debris:AddItem(p, 1.5)
end
local RAINBOW = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 220, 120)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 160, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 100, 255)) })
fx.RAINBOW = RAINBOW
function fx.confetti(B)
	for _, x in ipairs({ -3, 0, 3 }) do fx.burst((B.cf * CFrame.new(x, 8, -3)).Position, RAINBOW, 40, 16, 0.6) end
	fx.sound(B, "Win", 0.6, 1.25)
end
function fx.sound(B, key, vol, pitch)
	local s = Instance.new("Sound") s.SoundId = M.SOUNDS[key] or key s.Volume = vol or 0.5 s.PlaybackSpeed = pitch or 1
	s.RollOffMaxDistance = 60 s.Parent = B.counter
	s:Play() Debris:AddItem(s, 4)
end
-- the player's right hand (where thrown things start)
function fx.hand(B)
	local ch = B.occupant and B.occupant.Character
	local h = ch and (ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm"))
	if h then return h.CFrame * CFrame.new(0, -h.Size.Y / 2, 0) end
	return B.cf * CFrame.new(0.8, 4.5, -5.6)
end
function fx.anim(B, name, speed)
	local tr = B.tracks and B.tracks[name]
	if tr then tr:Play(0.1) if speed then tr:AdjustSpeed(speed) end end
end
-- second line of the booth's sign (e.g. "🎟️ +6  •  2 shots left")
function fx.say(B, text) if B.sub then B.sub.Text = text or "" end end
-- a world CFrame from booth-local coordinates
function fx.at(B, x, y, z) return B.cf * CFrame.new(x, y, z) end
-- anchored, non-colliding helper part
function fx.part(parent, name, size, cf, color, mat, shape)
	local p = Instance.new("Part") p.Name = name p.Size = size p.CFrame = cf p.Color = color p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = parent return p
end
-- things made during a session (thrown rings, darts…) are cleaned when the session ends
function fx.temp(B, inst) table.insert(B.temps, inst) inst.Parent = B.model return inst end

---------------------------------------------------------------- booth status (lamp + sign)
local function makeBillboard(B)
	local g = Instance.new("BillboardGui") g.Name = "BoothStatus" g.Size = UDim2.new(5.4, 0, 1.6, 0) g.StudsOffset = Vector3.new(0, 0, 0)
	g.MaxDistance = 80 g.LightInfluence = 0 g.Adornee = B.model.StatusAnchor g.Parent = B.model.StatusAnchor
	local f = Instance.new("Frame") f.Size = UDim2.fromScale(1, 1) f.BackgroundColor3 = Color3.fromRGB(20, 24, 32) f.BackgroundTransparency = 0.2 f.Parent = g
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0.25, 0) c.Parent = f
	local st = Instance.new("UIStroke") st.Thickness = 2 st.Color = Color3.fromRGB(80, 230, 110) st.Parent = f
	local t = Instance.new("TextLabel") t.Name = "Title" t.Size = UDim2.fromScale(0.94, 0.56) t.Position = UDim2.fromScale(0.03, 0.04) t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBlack t.TextScaled = true t.TextColor3 = Color3.new(1, 1, 1) t.Parent = f
	local s = Instance.new("TextLabel") s.Name = "Sub" s.Size = UDim2.fromScale(0.94, 0.36) s.Position = UDim2.fromScale(0.03, 0.6) s.BackgroundTransparency = 1
	s.Font = Enum.Font.GothamBold s.TextScaled = true s.TextColor3 = Color3.fromRGB(255, 225, 120) s.Parent = f
	B.title, B.sub, B.stroke = t, s, st
end
local function setStatus(B)
	local busy = B.occupant ~= nil
	local col = busy and Color3.fromRGB(240, 70, 60) or Color3.fromRGB(80, 230, 110)
	B.lamp.Color = col
	local gl = B.lamp:FindFirstChildOfClass("PointLight") if gl then gl.Color = col end
	B.stroke.Color = col
	if busy then
		B.title.Text = "🎮 " .. B.occupant.DisplayName .. " is playing"
		B.prompt.Enabled = false
	else
		B.title.Text = "🟢 OPEN — " .. B.g.Icon .. " " .. B.g.Name
		B.sub.Text = "Stand on the mat • E or click to play"
		B.prompt.Enabled = true
	end
end

---------------------------------------------------------------- keep-out zones (NO invisible walls)
-- Invisible solid walls caught every click / tap (Roblox makes a solid part "queryable" even with CanQuery off),
-- so balloons, moles etc. could not be clicked. Instead the server gently moves people out of:
--   1) the stall itself (inside it or on its roof) — always, for everyone,
--   2) the PLAY HERE mat while someone else is playing on it.
local function addBarriers(B)
	local old = B.model:FindFirstChild("Barriers") if old then old:Destroy() end
	local mz = B.cf:PointToObjectSpace(B.spot.Position).Z
	B.zone = { matFront = mz - 2.6, matBack = -3.95, matHalfW = 2.8, stallHalfW = 6.4, stallFront = -3.95, stallBack = 4.0, top = 16 }
end
local function setGuard(B, on) B.guardOn = on end
-- true + a safe spot in front of the booth if this world position is somewhere it shouldn't be
local function keepOutSpot(B, pos, isOccupant)
	local z = B.zone
	if not z then return nil end
	local lp = B.cf:PointToObjectSpace(pos)
	if lp.Y < -2 or lp.Y > z.top then return nil end
	local inStall = math.abs(lp.X) <= z.stallHalfW and lp.Z > z.stallFront and lp.Z < z.stallBack
	local onBusyMat = B.guardOn and not isOccupant and math.abs(lp.X) <= z.matHalfW and lp.Z >= z.matFront and lp.Z <= z.matBack
	if not (inStall or onBusyMat) then return nil end
	local x = math.clamp(lp.X, -z.stallHalfW + 1, z.stallHalfW - 1)
	if onBusyMat or math.abs(x) <= z.matHalfW + 0.5 then x = (lp.X >= 0 and 1 or -1) * (z.matHalfW + 1.8) end -- beside the mat, not on it
	local spot = B.cf * CFrame.new(x, 3.2, z.matFront - 1.5)
	local face = B.cf * CFrame.new(x, 3.2, 0)
	return CFrame.lookAt(spot.Position, Vector3.new(face.X, spot.Y, face.Z))
end

---------------------------------------------------------------- occupy / release a booth
local function rigOf(ch) local h = ch and ch:FindFirstChildOfClass("Humanoid") return h, h and (h.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6") end

local function occupy(ctx, B, player)
	local ch = player.Character
	local hum, rig = rigOf(ch)
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then return false end
	B.occupant = player
	B.saved = { ws = hum.WalkSpeed, jp = hum.JumpPower, jh = hum.JumpHeight, ar = hum.AutoRotate }
	hum.WalkSpeed, hum.JumpPower, hum.JumpHeight, hum.AutoRotate = 0, 0, 0, false
	if hum.Sit then hum.Sit = false end
	local lift = rig == "R15" and (hum.HipHeight + root.Size.Y / 2) or 3
	local spot = B.spot.Position
	local face = (B.cf * CFrame.new(0, 0, 4)).Position
	ch:PivotTo(CFrame.lookAt(Vector3.new(spot.X, B.cf.Y + lift, spot.Z), Vector3.new(face.X, B.cf.Y + lift, face.Z)))
	root.Anchored = true
	setGuard(B, true) -- others can't step onto the mat while this player plays
	-- animations everyone can see
	B.tracks = {}
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	for name, id in pairs(ANIMS[rig]) do
		local a = Instance.new("Animation") a.AnimationId = "rbxassetid://" .. id
		local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
		if ok and tr then
			tr.Priority = name == "hold" and Enum.AnimationPriority.Movement or Enum.AnimationPriority.Action
			tr.Looped = name == "hold"
			B.tracks[name] = tr
		end
	end
	if B.tracks.hold then B.tracks.hold:Play(0.2) end
	-- the item in their hand
	if B.g.HandProp then
		local ok, prop = pcall(B.g.HandProp, fx)
		local hand = ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm")
		if ok and prop and hand then
			local grip = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2 - 0.05, 0)
			if prop:IsA("Model") then prop:PivotTo(grip) else prop.CFrame = grip end
			for _, p in ipairs(prop:IsA("Model") and prop:GetDescendants() or { prop }) do
				if p:IsA("BasePart") then p.Anchored = false p.CanCollide = false p.Massless = true p.CanQuery = false
					local w = Instance.new("WeldConstraint") w.Part0 = hand w.Part1 = p w.Parent = p end
			end
			prop.Name = "BoothHandProp" prop.Parent = ch
			B.prop = prop
		end
	end
	B.deathConn = hum.Died:Connect(function() if B.session then M.closeSession(ctx, player, B.session) end end)
	setStatus(B)
	fx.say(B, "🎟️ 0")
	return true
end

local function release(B)
	setGuard(B, false)
	local player = B.occupant
	B.occupant = nil
	if B.deathConn then B.deathConn:Disconnect() B.deathConn = nil end
	if B.tracks then for _, tr in pairs(B.tracks) do pcall(function() tr:Stop(0.2) end) end B.tracks = nil end
	if B.prop then B.prop:Destroy() B.prop = nil end
	local ch = player and player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if root then root.Anchored = false end
	if hum and B.saved then hum.WalkSpeed, hum.JumpPower, hum.JumpHeight, hum.AutoRotate = B.saved.ws, B.saved.jp, B.saved.jh, B.saved.ar end
	if root and root.Parent then pcall(function() root:SetNetworkOwner(player) end) end
	B.saved = nil
	setStatus(B)
end

---------------------------------------------------------------- setup
function M.Setup(ctx)
	local kit = ServerStorage:FindFirstChild("SchoolFairKit")
	if not kit or not kit:FindFirstChild("Booths") then ctx.CancelReason = "SchoolFairKit missing in ServerStorage" return false end
	ctx.Data.sessions, ctx.Data.cooldown, ctx.Data.played, ctx.Data.booths = {}, {}, {}, {}
	local fair = Instance.new("Folder") fair.Name = "SchoolFair" fair.Parent = ctx.Folder
	-- decorations (cloned piece by piece so the server doesn't hitch)
	local decor = Instance.new("Folder") decor.Name = "Decor" decor.Parent = fair
	if kit:FindFirstChild("Decor") then for _, d in ipairs(kit.Decor:GetChildren()) do d:Clone().Parent = decor task.wait() end end
	local boothsFolder = Instance.new("Folder") boothsFolder.Name = "Booths" boothsFolder.Parent = fair
	local order = ctx.Config.Booth and ctx.Config.Booth.Games
	for _, src in ipairs(kit.Booths:GetChildren()) do
		local id = src:GetAttribute("Game")
		local mod = id and GamesFolder:FindFirstChild(id)
		local ok, g = false, nil
		if mod then ok, g = pcall(require, mod) end
		local listed = not order or table.find(order, id) ~= nil
		if ok and type(g) == "table" and g.Start and listed then
			local model = src:Clone() model.Parent = boothsFolder
			local B = { id = id, g = g, model = model, cf = model:GetAttribute("BoothCF"), game = model:FindFirstChild("Game"),
				spot = model.PlayerSpot, lamp = model.StatusLamp, counter = model.Stall.Counter, temps = {} }
			-- the prompt sits on the PLAY HERE mat: E works (KeepE tells TapPrompts not to remove the key) and
			-- clicking / tapping anywhere on the booth fires it too. Only the closest booth's prompt is shown.
			local pp = Instance.new("ProximityPrompt") pp.Name = "PlayPrompt" pp.ActionText = "Play" pp.ObjectText = g.Icon .. " " .. g.Name
			pp.HoldDuration = 0 pp.MaxActivationDistance = PROMPT_RANGE pp.RequiresLineOfSight = false
			pp.KeyboardKeyCode = Enum.KeyCode.E pp.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
			pp:SetAttribute("KeepE", true) pp:SetAttribute("ReachOverCounter", true)
			pp.Parent = B.spot
			B.prompt = pp
			addBarriers(B)
			makeBillboard(B)
			setStatus(B)
			ctx:Connect(pp.Triggered, function(player) M.play(ctx, player, B) end)
			if g.Bind then local okB, err = pcall(g.Bind, ctx, B, fx) if not okB then warn("[Booth] bind " .. id .. ": " .. tostring(err)) end end
			ctx.Data.booths[id] = B
		elseif id then
			warn("[Booth] skipped booth " .. tostring(id))
		end
		task.wait()
	end
	if not next(ctx.Data.booths) then ctx.CancelReason = "no booth games found" return false end
	ctx:SetLocation(FAIR_CENTER, FAIR_NAME)
	ctx.GotoPosition = GOTO
	ctx.ScoreLabel = "Tickets 🎟️"
	ctx.LockMode = "activity" -- equipment is locked only while you play a booth game
	ctx.JoinMode = "button"
	if RunService:IsStudio() then
		-- Studio only: ServerStorage.BoothDebug:Invoke("click", "BalloonPop") clicks every target once
		local dbg = Instance.new("BindableFunction") dbg.Name = "BoothDebug" dbg.Parent = ctx.Folder
		local old = ServerStorage:FindFirstChild("BoothDebug") if old then old:Destroy() end
		local ref = Instance.new("ObjectValue") ref.Name = "BoothDebug" ref.Value = dbg ref.Parent = ServerStorage
		dbg.OnInvoke = function(op, id)
			local B = ctx.Data.booths[id]
			if op == "click" and B and B.occupant and B.debugClicks then
				for _, f in ipairs(B.debugClicks) do f(B.occupant) end
				return true
			end
			return false
		end
	end
	ctx:Connect(Players.PlayerRemoving, function(p) for _, B in pairs(ctx.Data.booths) do if B.occupant == p then B.session = nil release(B) end end end)
	-- stand on the mat for MAT_HOLD seconds = the game starts by itself (one try per visit to the mat)
	task.spawn(function()
		local standing = {} -- [B] = { player = , t = , tried = }
		while ctx.Folder and ctx.Folder.Parent do
			task.wait(0.2)
			-- keep-out: nobody inside a stall / on its roof, nobody on a mat someone else is playing on
			for _, B in pairs(ctx.Data.booths) do
				for _, p in ipairs(Players:GetPlayers()) do
					local ch = p.Character
					local r = ch and ch:FindFirstChild("HumanoidRootPart")
					if r and p ~= B.occupant then
						local cf = keepOutSpot(B, r.Position, false)
						if cf then
							local h = ch:FindFirstChildOfClass("Humanoid")
							if h and h.Sit then h.Sit = false end
							ch:PivotTo(cf)
							if not B.lastToast or os.clock() - (B.lastToast[p] or 0) > 4 then
								B.lastToast = B.lastToast or {}
								B.lastToast[p] = os.clock()
								ctx:Toast(p, B.occupant and ("⏳ " .. B.occupant.DisplayName .. " is playing — wait for your turn!") or "🎪 Stand on the mat in front of the booth to play!")
							end
						end
					end
				end
			end
			if ctx.Phase == "Active" then
				for _, B in pairs(ctx.Data.booths) do
					local st = standing[B]
					if B.occupant then
						-- remember the player: when their game ends they're still on the mat, so don't restart it by itself
						standing[B] = { player = B.occupant, t = 0, tried = true }
					else
						-- who is on the mat (closest one)
						local who, best = nil, MAT_RADIUS
						local sp = B.spot.Position
						for _, p in ipairs(Players:GetPlayers()) do
							local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
							local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
							if r and h and h.Health > 0 and not ctx.Data.sessions[p] and math.abs(r.Position.Y - sp.Y) < 6 then
								local d = (Vector3.new(r.Position.X, sp.Y, r.Position.Z) - sp).Magnitude
								if d <= best then who, best = p, d end
							end
						end
						if not who then
							if st then standing[B] = nil setStatus(B) end
						elseif not st or st.player ~= who then
							standing[B] = { player = who, t = os.clock() }
						elseif not st.tried then
							local left = MAT_HOLD - (os.clock() - st.t)
							if left <= 0 then
								st.tried = true -- leave the mat and step back on to try again
								setStatus(B)
								task.spawn(M.play, ctx, who, B)
							else
								local dots = math.clamp(math.ceil((1 - left / MAT_HOLD) * 3), 1, 3)
								B.sub.Text = "⏳ Starting " .. string.rep("●", dots) .. string.rep("○", 3 - dots)
							end
						end
					end
				end
			end
		end
	end)
end

---------------------------------------------------------------- play a booth
function M.play(ctx, player, B)
	if ctx.Phase == "Announce" then ctx:Toast(player, "🎪 The booths open when the countdown ends!") return end
	if ctx.Phase ~= "Active" then return end
	if B.occupant and B.occupant ~= player then ctx:Toast(player, "⏳ " .. B.occupant.DisplayName .. " is playing — wait for your turn!") return end
	if not ctx:IsIn(player) then ctx:Join(player) end -- walking up to a booth joins the fair
	if not ctx:IsIn(player) then return end
	if ctx.Data.sessions[player] then ctx:Toast(player, "Finish your current booth game first") return end
	local key = B.id .. ":" .. player.UserId
	local cd = ctx.Data.cooldown[key]
	if cd and os.clock() < cd then ctx:Toast(player, ("Wait %d s before playing %s again"):format(math.ceil(cd - os.clock()), B.g.Name)) return end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - B.spot.Position).Magnitude > 16 then return end
	if not occupy(ctx, B, player) then return end
	ctx:SetLock(player, true) -- equipment off while playing this booth
	local s = { game = B.id, booth = B, tickets = 0 }
	ctx.Data.sessions[player] = s
	B.session = s
	s.finish = function() M.closeSession(ctx, player, s) end
	local ok, ui = pcall(B.g.Start, ctx, player, s, B, fx)
	if not ok or type(ui) ~= "table" then warn("[Booth] start " .. B.id .. ": " .. tostring(ui)) ctx.Data.sessions[player] = nil B.session = nil release(B) ctx:SetLock(player, false) return end
	ctx.Data.played[player] = true
	ui.type = "boothOpen" ui.game = B.id ui.name = B.g.Name ui.icon = B.g.Icon ui.description = B.g.Description
	-- a nice camera view behind the player, looking at the stall (the client moves the camera there)
	local cam = B.g.Camera or {}
	ui.camPos = (B.cf * CFrame.new(cam.pos or Vector3.new(2.6, 8.6, -13))).Position
	ui.camLook = (B.cf * CFrame.new(cam.look or Vector3.new(0.4, 5.6, 1.5))).Position
	ui.boothModel = B.model
	ctx:Send(player, ui)
	if ui.kind == "info" and not ui.keepOpen then task.delay(ui.seconds or 3, function() M.closeSession(ctx, player, s) end) end
end

-- tickets from a booth (also shown on the booth's sign)
function M.give(ctx, player, s, t)
	if t <= 0 then return end
	ctx:AddScore(player, t)
	s.tickets = (s.tickets or 0) + t
	if s.booth and s.booth.session == s then fx.say(s.booth, "🎟️ +" .. s.tickets .. " tickets") end
end
fx.give = function(ctx, player, s, t) M.give(ctx, player, s, t) end

function M.closeSession(ctx, player, s)
	if ctx.Data.sessions[player] ~= s then return end
	ctx.Data.sessions[player] = nil
	ctx.Data.cooldown[s.game .. ":" .. player.UserId] = os.clock() + ctx.Config.Booth.PlayCooldown
	local B = s.booth
	if B and B.session == s then
		B.session = nil
		if B.g.Stop then pcall(B.g.Stop, ctx, player, s, B, fx) end
		release(B)
		local temps = B.temps B.temps = {}
		task.delay(2.5, function() for _, t in ipairs(temps) do if t.Parent then t:Destroy() end end end)
	end
	if player.Parent then ctx:Send(player, { type = "boothClose", game = s.game }) end
	ctx:SetLock(player, false) -- booth game over: equipment back (walk to the next booth freely)
end

function M.OnAction(ctx, player, action, data)
	local s = ctx.Data.sessions[player]
	if action == "boothQuit" then if s then M.closeSession(ctx, player, s) end return { ok = true } end
	if action ~= "booth" or not s or type(data) ~= "table" or ctx.Phase ~= "Active" then return { ok = false } end
	local B = s.booth
	local ok, res = pcall(B.g.Action, ctx, player, s, data, B, fx)
	if not ok then warn("[Booth] action " .. s.game .. ": " .. tostring(res)) return { ok = false } end
	res = res or { ok = false }
	local t = math.clamp(math.floor(tonumber(res.tickets) or 0), 0, 20) -- one move can never give more than 20
	M.give(ctx, player, s, t)
	if res.done then task.delay(res.closeDelay or 3, function() M.closeSession(ctx, player, s) end) end
	return res
end

function M.OnPlayerLeft(ctx, player)
	local s = ctx.Data.sessions[player]
	if s then M.closeSession(ctx, player, s) end
end

function M.Finish(ctx)
	ctx.RewardEligible = {}
	for p in pairs(ctx.Data.played) do ctx.RewardEligible[p] = true end
	for p, s in pairs(ctx.Data.sessions) do M.closeSession(ctx, p, s) end
	ctx.Data.sessions = {}
	for _, B in pairs(ctx.Data.booths or {}) do if B.occupant then release(B) end end
end

return M
