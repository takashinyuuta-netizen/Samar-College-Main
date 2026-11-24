--[[ QuizBee (Common event, LEVEL-RESTRICTED) ─────────────────────────────
  • Picks ONE random classroom tagged "QuizBeeRoom" (anchors in
    Workspace.SamarCollege_Campus.EventZones.Anchors.QuizBeeRooms). Each anchor has:
      Building, Department, Course, GradeLevel, RoomName, Floor,
      Inside (spot in the room), DoorCenter / DoorNormal / DoorWidth / DoorHeight.
    Elementary rooms are only used on the Elementary server; the rest only on Junior High+.
  • Questions come from QuizBeeBank[Department][Course][GradeLevel] (server only).
  • Join pad at the door. Only players whose LevelUnlocked ≥ the room's level can join:
      "Unlock Grade 9 to join this Quiz Bee".
  • When the quiz starts an entry gate closes the doorway; only joined players can pass
    (collision groups), and anyone else inside is moved back to the corridor.
  • Timed multiple choice: the SERVER keeps the answers, checks every answer and the time.
    Correct = BasePoints + speed bonus. Live scoreboard via EventManager.
  • Everyone who answered at least one question gets the participation reward;
    1st/2nd/3rd get the place bonuses (EventConfig.Events.QuizBee.Rewards).
───────────────────────────────────────────────────────────────────────────]]
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local RS = game:GetService("ReplicatedStorage")
local LevelConfig = require(RS:WaitForChild("LevelConfig"))
local Bank = require(script.Parent.Parent:WaitForChild("QuizBeeBank"))
local LevelQuizBank = require(script.Parent.Parent.Parent:WaitForChild("QuizBank")) -- fallback only

local M = {}
local GATE_GROUP, IN_GROUP = "QuizBeeGate", "QuizBeeIn"

---------------------------------------------------------------- collision groups (gate)
local function setupGroups()
	for _, g in ipairs({ GATE_GROUP, IN_GROUP }) do
		if not PhysicsService:IsCollisionGroupRegistered(g) then PhysicsService:RegisterCollisionGroup(g) end
	end
	PhysicsService:CollisionGroupSetCollidable(GATE_GROUP, IN_GROUP, false)
end
local function setCharGroup(char, group)
	if not char then return end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then p.CollisionGroup = group end
	end
end

---------------------------------------------------------------- questions
local function shuffle(t) for i = #t, 2, -1 do local j = math.random(i) t[i], t[j] = t[j], t[i] end return t end

-- questions asked recently on this server (so the next Quiz Bee feels fresh)
local recentlyAsked = {} -- question text -> os.clock()
local RECENT_FOR = 3600  -- don't repeat a question for 1 hour if there are fresh ones left

local function gatherQuestions(dept, course, grade, need, markUsed)
	local pool, seen = {}, {}
	local mainSet = {}
	local function add(list, isMain)
		if type(list) ~= "table" then return end
		for _, q in ipairs(list) do
			if type(q) == "table" and q.Q and q.O and q.A and not seen[q.Q] then
				seen[q.Q] = true table.insert(pool, q)
				if isMain then mainSet[q] = true end
			end
		end
	end
	local d = Bank[dept] or {}
	local c = d[course] or {}
	add(c[grade], true) -- this grade/year's own questions
	add(c.All, true)    -- the course/strand question pack (100+)
	local fromMain = #pool
	if #pool < need then add(d.General and d.General[grade]) end
	if #pool < need then add(LevelQuizBank[grade]) end
	shuffle(pool)
	-- room's own course first, then questions not asked recently
	local now = os.clock()
	local function rank(q)
		local r = mainSet[q] and 2 or 0
		local t = recentlyAsked[q.Q]
		if not (t and now - t < RECENT_FOR) then r += 1 end
		return r
	end
	for _, q in ipairs(pool) do q.__rank = rank(q) end
	table.sort(pool, function(a, b) return a.__rank > b.__rank end)
	local picked = {}
	for i = 1, math.min(need, #pool) do picked[i] = pool[i] end
	if markUsed then for _, q in ipairs(picked) do recentlyAsked[q.Q] = now end end
	return shuffle(picked), fromMain
end

---------------------------------------------------------------- room choice
local function roomAllowed(anchor, serverType)
	local dept = anchor:GetAttribute("Department")
	if serverType == "Elementary" then return dept == "Elementary" end
	return dept ~= "Elementary"
end

local function pickRoom(ctx)
	local cfg = ctx.Config.QuizBee
	local options = {}
	for _, a in ipairs(CollectionService:GetTagged("QuizBeeRoom")) do
		local hosted = a:FindFirstChild("Room") and a.Room.Value and a.Room.Value:GetAttribute("HostedBy") -- 📌 a player is hosting a meeting there
		if a:IsA("BasePart") and a:IsDescendantOf(workspace) and roomAllowed(a, ctx.ServerType) and not hosted then
			local grade = a:GetAttribute("GradeLevel")
			if LevelConfig.find(grade or "") then
				local qs = gatherQuestions(a:GetAttribute("Department"), a:GetAttribute("Course"), grade, cfg.QuestionsPerRound)
				if #qs >= cfg.MinQuestions and a ~= M.lastAnchor then table.insert(options, a) end
			end
		end
	end
	if #options == 0 then return nil end
	return options[math.random(#options)]
end

---------------------------------------------------------------- build
local function part(parent, name, size, cf, color, props)
	local p = Instance.new("Part") p.Name = name p.Size = size p.CFrame = cf p.Color = color p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = parent return p
end

local DEPT_COLOR = { ["Elementary"] = Color3.fromRGB(64, 170, 110), ["High School"] = Color3.fromRGB(70, 140, 230), ["College"] = Color3.fromRGB(230, 170, 50) }

function M.Setup(ctx)
	setupGroups()
	local anchor = pickRoom(ctx)
	if not anchor then ctx.CancelReason = "no free Quiz Bee room (rooms may be hosted by players)" return false end
	M.lastAnchor = anchor
	local A = {
		dept = anchor:GetAttribute("Department"), course = anchor:GetAttribute("Course"), grade = anchor:GetAttribute("GradeLevel"),
		room = anchor:GetAttribute("RoomName") or anchor.Name, inside = anchor:GetAttribute("Inside"),
		door = anchor:GetAttribute("DoorCenter"), normal = anchor:GetAttribute("DoorNormal"),
		width = anchor:GetAttribute("DoorWidth") or 4.6, height = anchor:GetAttribute("DoorHeight") or 8,
	}
	A.level = LevelConfig.find(A.grade)
	ctx.Data.A = A
	ctx.Data.questions = gatherQuestions(A.dept, A.course, A.grade, ctx.Config.QuizBee.QuestionsPerRound, true)
	ctx.Data.answered = {}   -- [player] = number of questions answered
	ctx.Data.correct = {}    -- [player] = number correct
	local color = DEPT_COLOR[A.dept] or Color3.fromRGB(240, 180, 60)

	-- join pad (corridor side of the door)
	local padPos = anchor.Position - Vector3.new(0, 0.5, 0)
	local pad = part(ctx.Folder, "JoinPad", Vector3.new(6, 0.25, 6), CFrame.new(padPos + Vector3.new(0, 0.13, 0)), color,
		{ Material = Enum.Material.Neon, Transparency = 0.25, CanCollide = false })
	local bb = Instance.new("BillboardGui") bb.Size = UDim2.fromOffset(280, 92) bb.StudsOffset = Vector3.new(0, 6, 0) bb.AlwaysOnTop = true bb.MaxDistance = 120 bb.Parent = pad
	local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.TextScaled = true t.Font = Enum.Font.GothamBlack
	t.TextColor3 = Color3.new(1, 1, 1) t.TextStrokeTransparency = 0.3
	t.Text = ("🧠 QUIZ BEE\n%s\n%s and up • step on the pad"):format(A.room, A.grade) t.Parent = bb
	ctx.Data.pad = pad

	-- entry gate: a see-through doorway screen on the corridor side (solid only after the start)
	local gcf = CFrame.lookAt(A.door + A.normal * 0.8, A.door + A.normal * 2)
	local gate = part(ctx.Folder, "EntryGate", Vector3.new(A.width + 0.4, A.height + 0.4, 0.3), gcf, color,
		{ Material = Enum.Material.ForceField, Transparency = 1, CanCollide = false, CollisionGroup = GATE_GROUP })
	ctx.Data.gate = gate

	ctx:SetLocation(padPos, A.room)
	ctx.GotoPosition = padPos + A.normal * 4 + Vector3.new(0, 3, 0)
	ctx.ScoreLabel = "Quiz Bee points"
	ctx.JoinMode = "zone"
	ctx.RequirementText = A.grade .. " and up"
	ctx.Data.roomBox = { anchor:FindFirstChild("Room") and anchor.Room.Value }

	-- step on the pad → level check → join → move inside
	ctx:Connect(pad.Touched, function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or ctx:IsIn(player) or ctx.Phase == "Results" then return end
		local now = os.clock()
		ctx.Data.padCooldown = ctx.Data.padCooldown or {}
		if ctx.Data.padCooldown[player] and now - ctx.Data.padCooldown[player] < 3 then return end
		ctx.Data.padCooldown[player] = now
		if ctx:Join(player) then M.enterRoom(ctx, player) end
	end)
end

-- level restriction (server side): LevelUnlocked must be ≥ the room's level
function M.CanJoin(ctx, player)
	local A = ctx.Data.A
	local have = tonumber(player:GetAttribute("LevelUnlocked")) or 1
	if have < A.level then return false, ("🔒 Unlock %s to join this Quiz Bee"):format(A.grade) end
	return true
end

function M.enterRoom(ctx, player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	setCharGroup(char, IN_GROUP)
	if hum then hum.Sit = false end
	if char and ctx.Data.A.inside then
		char:PivotTo(CFrame.new(ctx.Data.A.inside + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))))
	end
	ctx:Send(player, { type = "lobby", room = ctx.Data.A.room, grade = ctx.Data.A.grade, course = ctx.Data.A.course,
		total = #ctx.Data.questions, startsIn = ctx:TimeLeft() })
	-- keep the gate pass after a respawn
	ctx.Data.charConn = ctx.Data.charConn or {}
	if not ctx.Data.charConn[player] then
		ctx.Data.charConn[player] = ctx:Connect(player.CharacterAdded, function(c) task.wait(0.2) setCharGroup(c, IN_GROUP) end)
	end
	-- joined late: show the current question right away
	if ctx.Data.current then M.sendQuestion(ctx, player) end
end

---------------------------------------------------------------- question loop
function M.sendQuestion(ctx, player)
	local cur = ctx.Data.current
	if not cur then return end
	local payload = { type = "question", i = cur.index, n = #ctx.Data.questions, q = cur.q.Q, options = cur.options,
		time = math.max(0, cur.deadline - os.clock()), total = ctx.Config.QuizBee.TimePerQuestion, grade = ctx.Data.A.grade }
	if player then ctx:Send(player, payload) else ctx:SendAll(payload) end
end

local function moveOutsiders(ctx)
	local room = ctx.Data.roomBox[1]
	if not room then return end
	local cf, size = room:GetBoundingBox()
	for _, p in ipairs(Players:GetPlayers()) do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if root and not ctx:IsIn(p) then
			local rel = cf:PointToObjectSpace(root.Position)
			if math.abs(rel.X) < size.X / 2 and math.abs(rel.Y) < size.Y / 2 and math.abs(rel.Z) < size.Z / 2 then
				p.Character:PivotTo(CFrame.new(ctx.GotoPosition))
				ctx:Toast(p, "🧠 A Quiz Bee is in progress in this room")
			end
		end
	end
end

function M.Start(ctx)
	local cfg = ctx.Config.QuizBee
	local gate = ctx.Data.gate
	gate.CanCollide = true
	gate.Transparency = 0.6
	moveOutsiders(ctx)
	ctx:ToastAll("🧠 The Quiz Bee has started — good luck!")
	task.spawn(function()
		task.wait(2)
		for i, q in ipairs(ctx.Data.questions) do
			if ctx.Phase ~= "Active" then return end
			-- shuffle the options; remember where the right one went (server only)
			local order = { 1, 2, 3, 4 }
			shuffle(order)
			local options, correctIdx = {}, nil
			for k = 1, #q.O do options[k] = q.O[order[k]] if order[k] == q.A then correctIdx = k end end
			ctx.Data.current = { index = i, q = q, options = options, correct = correctIdx,
				deadline = os.clock() + cfg.TimePerQuestion, picks = {}, gained = {} }
			M.sendQuestion(ctx)
			-- wait for time-out, or until every participant has answered
			while ctx.Phase == "Active" and os.clock() < ctx.Data.current.deadline do
				local all = true
				for p in pairs(ctx.Participants) do if p.Parent and not ctx.Data.current.picks[p] then all = false break end end
				if all and next(ctx.Participants) then break end
				task.wait(0.2)
			end
			if ctx.Phase ~= "Active" then return end
			-- reveal: everyone sees the right answer + their own result
			local cur = ctx.Data.current
			ctx.Data.current = nil
			for p in pairs(ctx.Participants) do
				if p.Parent then
					ctx:Send(p, { type = "reveal", i = i, correct = cur.correct, picked = cur.picks[p], gained = cur.gained[p] or 0 })
				end
			end
			task.wait(cfg.RevealTime)
		end
		if ctx.Phase == "Active" then ctx:End("done") end
	end)
end

-- the ONLY place answers are checked
function M.OnAction(ctx, player, action, data)
	if action ~= "answer" then return { ok = false } end
	local cur = ctx.Data.current
	if not ctx:IsIn(player) or not cur then return { ok = false, msg = "No question right now" } end
	if type(data) ~= "table" then return { ok = false } end
	local i, choice = tonumber(data.i), tonumber(data.choice)
	if i ~= cur.index or not choice or choice ~= math.floor(choice) or choice < 1 or choice > #cur.options then return { ok = false } end
	if cur.picks[player] then return { ok = false, msg = "Already answered" } end
	local left = cur.deadline - os.clock()
	if left < -0.3 then return { ok = false, msg = "Time's up!" } end
	cur.picks[player] = choice
	ctx.Data.answered[player] = (ctx.Data.answered[player] or 0) + 1
	if choice == cur.correct then
		local cfg = ctx.Config.QuizBee
		local pts = cfg.BasePoints + math.floor(cfg.SpeedBonus * math.clamp(left / cfg.TimePerQuestion, 0, 1))
		cur.gained[player] = pts
		ctx.Data.correct[player] = (ctx.Data.correct[player] or 0) + 1
		ctx:AddScore(player, pts)
	end
	return { ok = true, locked = true }
end

function M.OnPlayerLeft(ctx, player)
	setCharGroup(player.Character, "Default")
	-- pressed Leave inside the quiz room: walk them out (you join by being in the room, so staying would re-join them)
	local room = ctx.Data.roomBox and ctx.Data.roomBox[1]
	local root = player.Parent and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if room and root and ctx.GotoPosition then
		local cf, size = room:GetBoundingBox()
		local rel = cf:PointToObjectSpace(root.Position)
		if math.abs(rel.X) < size.X / 2 and math.abs(rel.Y) < size.Y / 2 and math.abs(rel.Z) < size.Z / 2 then
			player.Character:PivotTo(CFrame.new(ctx.GotoPosition))
		end
	end
	ctx:Send(player, { type = "left" })
end

function M.Finish(ctx)
	-- rewards only for players who answered at least one question ("finished")
	ctx.RewardEligible = {}
	for p, n in pairs(ctx.Data.answered) do if n > 0 then ctx.RewardEligible[p] = true end end
	for p in pairs(ctx.Participants) do
		if p.Parent then
			ctx:Send(p, { type = "done", correct = ctx.Data.correct[p] or 0, total = #ctx.Data.questions })
		end
	end
end

function M.Cleanup(ctx)
	ctx.Data.current = nil
	-- everyone loses the gate pass
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CollisionGroup == IN_GROUP then part.CollisionGroup = "Default" end
			end
		end
	end
end

return M
