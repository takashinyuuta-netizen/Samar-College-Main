--[[ EventManager ────────────────────────────────────────────────────────────
  The ONE server-side brain of the event system (server-authoritative).

  ROTATION  Every EventConfig.RotationInterval seconds it picks the next event with
            weighted random (Common = high weight, Rare = low weight), never the same
            event twice in a row, and respecting each event's Cooldown and server type.

  LIFECYCLE  Setup ─▶ Announce (lobby countdown) ─▶ Active ─▶ Results (rewards) ─▶ Cleanup

  EVENT MODULES  live in ServerScriptService.Events.EventModules, one ModuleScript per
  event, named exactly like the key in EventConfig.Events. A module can define:
      Setup(ctx)            build parts in ctx.Folder, call ctx:SetLocation(...). Return false to cancel.
      Start(ctx)            the countdown ended, gameplay begins
      OnAction(ctx, player, action, data)  client requests (answers, clicks...) – VALIDATE here
      CanJoin(ctx, player)  return false, "reason" to refuse a player (e.g. level too low)
      OnPlayerLeft(ctx, player)
      Finish(ctx)           time is up: may set ctx.Ranking = { best player, ... }
      Cleanup(ctx)          optional extra cleanup (ctx.Folder is destroyed automatically)

  The ctx (context) object gives modules safe helpers: Join, Leave, AddScore, Toast,
  SendAll, Connect, End, SetLocation. Everything a client sends is checked here first.
───────────────────────────────────────────────────────────────────────────]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Shared = RS:WaitForChild("Events")
local Config = require(Shared:WaitForChild("EventConfig"))
local Remotes = Shared:WaitForChild("EventRemotes")
local Rewards = require(script.Parent:WaitForChild("EventRewards"))
local ModulesFolder = script.Parent:WaitForChild("EventModules")
local Busy = require(script.Parent.Parent:WaitForChild("PlayerBusy"))

-- what keeps a player from joining / teleporting to the current event. Intramurals IS the sports
-- courts + talent stage, so being in a game or on stage there is fine.
local function busyFor(ctx, player)
	local ignore = { Lock_Event = true }
	if ctx and ctx.Id == "Intramurals" then ignore.Lock_Court = true ignore.SC_Performing = true end
	return Busy.reason(player, { ignore = ignore })
end

local EventManager = {}
EventManager.ServerType = Config.getServerType()

local current = nil          -- the running ctx (only one event at a time)
local lastEventId = nil      -- prevents back-to-back repeats
local lastRunAt = {}         -- id -> os.clock() when it last ended (cooldowns)
local nextRotationAt = os.clock() + Config.FirstEventDelay

---------------------------------------------------------------- helpers
local function zonesFolder()
	local campus = workspace:FindFirstChild("SamarCollege_Campus") or workspace
	local f = campus:FindFirstChild("EventZones")
	if not f then f = Instance.new("Folder") f.Name = "EventZones" f.Parent = campus end
	local live = f:FindFirstChild("Live")
	if not live then live = Instance.new("Folder") live.Name = "Live" live.Parent = f end
	return live
end

local function serverAllowed(def)
	if not def.Servers then return true end
	return table.find(def.Servers, EventManager.ServerType) ~= nil
end

local function moduleFor(id)
	local m = ModulesFolder:FindFirstChild(id)
	if not (m and m:IsA("ModuleScript")) then return nil end
	local ok, mod = pcall(require, m)
	if not ok then warn("[EventManager] module " .. id .. " failed to load: " .. tostring(mod)) return nil end
	return mod
end

---------------------------------------------------------------- broadcasting
-- Sorted ranking from the scores table (highest first, ties by who scored first).
local function sortedScores(ctx)
	local list = {}
	for p, s in pairs(ctx.Scores) do
		if p.Parent == Players and ctx.Participants[p] then table.insert(list, { p = p, s = s, t = ctx.ScoreTime[p] or 0 }) end
	end
	if ctx.LowerIsBetter then
		-- times: only real results (> 0) count, smallest first
		local kept = {}
		for _, e in ipairs(list) do if e.s > 0 then table.insert(kept, e) end end
		list = kept
		table.sort(list, function(a, b) if a.s == b.s then return a.t < b.t end return a.s < b.s end)
		return list
	end
	table.sort(list, function(a, b) if a.s == b.s then return a.t < b.t end return a.s > b.s end)
	return list
end

local function countParticipants(ctx)
	local n = 0 for p in pairs(ctx.Participants) do if p.Parent == Players then n += 1 end end return n
end

-- The public state every client receives (no answers or secrets in here!)
local function publicState()
	if not current then
		return { active = false, nextAt = os.time() + math.max(0, math.floor(nextRotationAt - os.clock())), serverType = EventManager.ServerType }
	end
	local ctx, def = current, current.Def
	local top = {}
	for i, e in ipairs(sortedScores(ctx)) do
		if i > 5 then break end
		table.insert(top, { name = e.p.DisplayName, score = e.s })
	end
	return {
		active = true, id = ctx.Id, name = def.Name, icon = def.Icon, rarity = def.Rarity or "Common",
		description = def.Description, phase = ctx.Phase, endsAt = ctx.EndsAt,
		location = ctx.Location and { ctx.Location.X, ctx.Location.Y, ctx.Location.Z } or nil,
		locationName = ctx.LocationName, players = countParticipants(ctx), top = top,
		scoreLabel = ctx.ScoreLabel or "Score", requirement = ctx.RequirementText,
		joinMode = ctx.JoinMode or "button", scoreFormat = ctx.ScoreFormat, -- "time" = show mm:ss.s -- "button" = Join button, "zone" = walk into the area
	}
end

function EventManager.broadcast()
	local st = publicState()
	for _, p in ipairs(Players:GetPlayers()) do
		local mine = table.clone(st)
		if current then
			mine.joined = current.Participants[p] == true
			mine.myScore = current.Scores[p]
		end
		Remotes.EventState:FireClient(p, mine)
	end
end

-- score updates are throttled to max ~3 per second
local scoreDirty = false
local function markScores()
	if scoreDirty then return end
	scoreDirty = true
	task.delay(0.35, function() scoreDirty = false EventManager.broadcast() end)
end

---------------------------------------------------------------- context (what event modules use)
local function newContext(id, def, mod)
	local folder = Instance.new("Folder")
	folder.Name = ("%s_%s"):format(id, os.date("!%H%M%S"))
	folder.Parent = zonesFolder()

	local ctx = {
		Id = id, Def = def, Module = mod, Folder = folder, Phase = "Setup",
		Participants = {}, Scores = {}, ScoreTime = {}, Data = {}, Connections = {},
		ServerType = EventManager.ServerType, Config = Config,
	}

	function ctx:SetLocation(position, name)
		self.Location = position
		self.LocationName = name
	end

	-- Join: the ONLY way a player becomes a participant (counts EventsJoined once)
	function ctx:Join(player)
		if current ~= self or self.Phase == "Results" then return false, "This event has ended" end
		if self.Participants[player] then return true end
		local busy = busyFor(self, player)
		if busy then Remotes.EventToast:FireClient(player, busy) return false, busy end
		if mod.CanJoin then
			local ok, msg = mod.CanJoin(self, player)
			if not ok then Remotes.EventToast:FireClient(player, msg or "You can't join this event") return false, msg end
		end
		self.Participants[player] = true
		-- equipment (bike, coils, boots, flashlight...) is off while you take part (EquipLock).
		-- Intramurals locks per game instead (SportsServer / Talent Stage), so walking around the hall is fine.
		-- LockMode "activity" (Tower, Booths, Foundation Day): the module locks only while you're actually
		-- doing something (climbing, playing a booth, racing) via ctx:SetLock, so joining alone doesn't lock.
		if self.Id ~= "Intramurals" and self.LockMode ~= "activity" then player:SetAttribute("Lock_Event", true) end
		self.Scores[player] = self.Scores[player] or 0
		-- "events joined" counts once per event, even if the player leaves and joins again
		self.Counted = self.Counted or {}
		if not self.Counted[player] then self.Counted[player] = true Rewards.countJoin(player, def) end
		Remotes.EventToast:FireClient(player, ("%s You joined %s!"):format(def.Icon or "🎪", def.Name))
		EventManager.broadcast()
		return true
	end

	-- Leave: the player stops taking part. Their equipment unlocks right away, their score for this
	-- event is cleared (no rewards unless they join again), and the event module tidies up after them.
	function ctx:Leave(player)
		if not self.Participants[player] then return end
		self.Participants[player] = nil
		self.Scores[player] = nil
		self.ScoreTime[player] = nil
		if player.Parent then player:SetAttribute("Lock_Event", nil) end
		if mod.OnPlayerLeft then pcall(mod.OnPlayerLeft, self, player) end
		-- (no popup: the event's own panel just closes and the equipment comes back quietly)
		markScores()
		EventManager.broadcast()
	end

	function ctx:IsIn(player) return self.Participants[player] == true end

	-- equipment lock for ONE player while the event keeps running (EquipLock reads Lock_Event)
	function ctx:SetLock(player, on)
		if self.Id == "Intramurals" or not player.Parent then return end
		if on and not self.Participants[player] then return end
		if (player:GetAttribute("Lock_Event") == true) ~= (on == true) then player:SetAttribute("Lock_Event", on and true or nil) end
	end
	-- the player finished THEIR part (reached the summit, escaped, booth game over...): equipment back right away.
	-- They stay in the event (score + rewards kept).
	function ctx:Done(player, msg)
		local was = player:GetAttribute("Lock_Event") == true
		self:SetLock(player, false)
		if was and player.Parent then Remotes.EventToast:FireClient(player, msg or "🎒 You're done — your equipment is unlocked!") end
	end

	function ctx:AddScore(player, n)
		if not self.Participants[player] then return end
		n = tonumber(n) or 0
		self.Scores[player] = (self.Scores[player] or 0) + n
		self.ScoreTime[player] = os.clock()
		markScores()
	end

	function ctx:SetScore(player, n)
		if not self.Participants[player] then return end
		self.Scores[player] = tonumber(n) or 0
		self.ScoreTime[player] = os.clock()
		markScores()
	end

	function ctx:Toast(player, msg) Remotes.EventToast:FireClient(player, msg) end
	function ctx:ToastAll(msg) for p in pairs(self.Participants) do if p.Parent then Remotes.EventToast:FireClient(p, msg) end end end
	-- event-specific data for the client UI of this event (never put answers in here)
	function ctx:Send(player, payload) payload.event = self.Id Remotes.EventData:FireClient(player, payload) end
	function ctx:SendAll(payload) payload.event = self.Id for p in pairs(self.Participants) do if p.Parent then Remotes.EventData:FireClient(p, payload) end end end
	-- to EVERY player in the server (public visuals like the drawing board)
	function ctx:Broadcast(payload) payload.event = self.Id Remotes.EventData:FireAllClients(payload) end
	function ctx:Connect(signal, fn) local c = signal:Connect(fn) table.insert(self.Connections, c) return c end
	function ctx:End(reason) if current == self then EventManager.finish(reason or "done") end end
	function ctx:Refresh() EventManager.broadcast() end
	function ctx:TimeLeft() return math.max(0, (self.EndsAt or os.time()) - os.time()) end
	return ctx
end

---------------------------------------------------------------- cleanup
local function cleanup(ctx)
	for p in pairs(ctx.Participants) do if p.Parent then p:SetAttribute("Lock_Event", nil) end end
	for _, c in ipairs(ctx.Connections) do pcall(function() c:Disconnect() end) end
	ctx.Connections = {}
	if ctx.Module and ctx.Module.Cleanup then
		local ok, err = pcall(ctx.Module.Cleanup, ctx)
		if not ok then warn("[EventManager] Cleanup error in " .. ctx.Id .. ": " .. tostring(err)) end
	end
	if ctx.Folder then ctx.Folder:Destroy() ctx.Folder = nil end
	if current == ctx then current = nil end
	lastEventId = ctx.Id
	lastRunAt[ctx.Id] = os.clock()
	nextRotationAt = os.clock() + Config.RotationInterval
	EventManager.broadcast()
end

---------------------------------------------------------------- finish + rewards
-- reason: "time" | "done" | "stopped" (admin stop = no rewards)
function EventManager.finish(reason)
	local ctx = current
	if not ctx or ctx.Phase == "Results" then return end
	local wasActive = ctx.Phase == "Active"
	ctx.Phase = "Results"
	-- event over: everyone gets their equipment back
	for p in pairs(ctx.Participants) do if p.Parent then p:SetAttribute("Lock_Event", nil) end end
	if ctx.Module.Finish and wasActive then
		local ok, err = pcall(ctx.Module.Finish, ctx)
		if not ok then warn("[EventManager] Finish error in " .. ctx.Id .. ": " .. tostring(err)) end
	end

	-- ranking: the module's own order, or players sorted by score (score > 0 only)
	local ranking = ctx.Ranking
	if not ranking then
		ranking = {}
		for _, e in ipairs(sortedScores(ctx)) do if e.s > 0 then table.insert(ranking, e.p) end end
	end

	local summary = {}
	if reason ~= "stopped" and wasActive then
		summary = Rewards.payEvent(ctx.Def, ranking, ctx.Participants, ctx.ExtraRewards, ctx.RewardEligible)
		if ctx.Def.Rewards and ctx.Def.Rewards.Achievement and ctx.AchievementPlayers then
			for p in pairs(ctx.AchievementPlayers) do if p.Parent then Rewards.grantAchievement(p, ctx.Def.Rewards.Achievement) end end
		end
	end

	-- results screen: top 3 for everyone + personal reward
	local podium = {}
	for i = 1, math.min(3, #ranking) do
		local p = ranking[i]
		if p and p.Parent then table.insert(podium, { name = p.DisplayName, score = ctx.Scores[p] or 0 }) end
	end
	ctx.EndsAt = os.time() + Config.ResultsTime
	EventManager.broadcast()
	for _, p in ipairs(Players:GetPlayers()) do
		local mine = summary[p]
		Remotes.EventResults:FireClient(p, {
			name = ctx.Def.Name, icon = ctx.Def.Icon, reason = reason, podium = podium, teamWinner = ctx.WinnerText,
			joined = ctx.Participants[p] == true, place = mine and mine.place, amount = mine and mine.amount or 0,
			currency = Config.CurrencyNames[mine and mine.currency or "Common"], lines = mine and mine.lines or {},
		})
	end
	print(("[EventManager] %s ended (%s). Participants: %d"):format(ctx.Def.Name, reason, countParticipants(ctx)))
	task.delay(Config.ResultsTime, function() if ctx.Folder or current == ctx then cleanup(ctx) end end)
end

---------------------------------------------------------------- start
-- opts.forced = admin test (ignores Enabled / cooldown / repeat rules)
-- opts.announce = override lobby countdown seconds
function EventManager.start(id, opts)
	opts = opts or {}
	if current then return false, "An event is already running: " .. current.Def.Name end
	local def = Config.Events[id]
	if not def then return false, "Unknown event '" .. tostring(id) .. "'" end
	if not serverAllowed(def) then return false, def.Name .. " can't run on the " .. EventManager.ServerType .. " server" end
	if not opts.forced and def.Enabled == false then return false, def.Name .. " is disabled in EventConfig" end
	local mod = moduleFor(id)
	if not mod then return false, def.Name .. " isn't built yet (no module in EventModules)" end

	local ctx = newContext(id, def, mod)
	current = ctx
	local ok, res = pcall(mod.Setup or function() end, ctx)
	if not ok or res == false then
		current = nil
		if ctx.Folder then ctx.Folder:Destroy() end
		local why = (not ok) and tostring(res) or (ctx.CancelReason or "no valid place for this event")
		warn("[EventManager] " .. id .. " setup cancelled: " .. why)
		return false, def.Name .. " couldn't start: " .. why
	end

	ctx.Phase = "Announce"
	ctx.EndsAt = os.time() + (opts.announce or def.AnnounceTime or Config.AnnounceTime)
	print(("[EventManager] %s announced at %s%s"):format(def.Name, tostring(ctx.LocationName or "?"), opts.forced and " (forced by admin)" or ""))
	EventManager.broadcast()

	task.spawn(function()
		while current == ctx and ctx.Phase == "Announce" and os.time() < ctx.EndsAt do task.wait(0.25) end
		if current ~= ctx or ctx.Phase ~= "Announce" then return end
		ctx.Phase = "Active"
		ctx.StartedAt = os.time()
		ctx.EndsAt = os.time() + (def.Duration or 180)
		if mod.Start then
			local okS, err = pcall(mod.Start, ctx)
			if not okS then warn("[EventManager] Start error in " .. id .. ": " .. tostring(err)) end
		end
		EventManager.broadcast()
		while current == ctx and ctx.Phase == "Active" and os.time() < ctx.EndsAt do task.wait(0.25) end
		if current == ctx and ctx.Phase == "Active" then EventManager.finish("time") end
	end)
	return true, def.Name .. " started"
end

function EventManager.stop()
	if not current then return false, "No event is running" end
	local name = current.Def.Name
	EventManager.finish("stopped")
	return true, name .. " stopped (no rewards)"
end

function EventManager.current() return current end

---------------------------------------------------------------- rotation (weighted random)
function EventManager.pickNext(exclude)
	local pool, total = {}, 0
	for id, def in pairs(Config.Events) do
		local w = Config.weightOf(def)
		local cooled = not lastRunAt[id] or (os.clock() - lastRunAt[id]) >= (def.Cooldown or 0)
		if def.Enabled ~= false and w > 0 and id ~= lastEventId and cooled and serverAllowed(def) and ModulesFolder:FindFirstChild(id) and not (exclude and exclude[id]) then
			table.insert(pool, { id = id, w = w })
			total += w
		end
	end
	if total <= 0 then
		-- with a short break every event may still be on cooldown: then pick from all events except the
		-- one that just ran (so the same event never runs twice in a row)
		for id, def in pairs(Config.Events) do
			local w = Config.weightOf(def)
			if def.Enabled ~= false and w > 0 and id ~= lastEventId and serverAllowed(def) and ModulesFolder:FindFirstChild(id) and not (exclude and exclude[id]) then
				table.insert(pool, { id = id, w = w })
				total += w
			end
		end
	end
	if total <= 0 then return nil end
	local r = math.random() * total
	for _, e in ipairs(pool) do
		r -= e.w
		if r <= 0 then return e.id end
	end
	return pool[#pool].id
end

function EventManager.skipTimer() nextRotationAt = os.clock() end
-- admin/testing: end the current countdown or the active phase right now
function EventManager.skipPhase()
	if not current then return false, "No event is running" end
	if current.Phase == "Results" then return false, "Already showing results" end
	local from = current.Phase
	current.EndsAt = os.time()
	return true, "Skipped the " .. from .. " phase of " .. current.Def.Name
end
function EventManager.secondsUntilNext() return math.max(0, nextRotationAt - os.clock()) end

function EventManager.run()
	task.spawn(function()
		while true do
			task.wait(1)
			if not current and os.clock() >= nextRotationAt then
				if #Players:GetPlayers() < Config.MinPlayers then
					nextRotationAt = os.clock() + 30
				else
					-- if an event can't start (e.g. its rooms are hosted by players) try another one right away
					local tried, ok = {}, false
					for _ = 1, 5 do
						local id = EventManager.pickNext(tried)
						if not id then break end
						tried[id] = true
						ok = EventManager.start(id)
						if ok then break end
					end
					if not ok then nextRotationAt = os.clock() + Config.RetryWhenEmpty EventManager.broadcast() end
				end
			end
		end
	end)
end

---------------------------------------------------------------- client requests (validated)
local GOTO_COOLDOWN = 10
local lastGoto, callLog = {}, {}

Remotes.EventAction.OnServerInvoke = function(player, action, data)
	-- rate limit: max 15 requests per second per player
	local now = os.clock()
	local log = callLog[player]
	if not log or now - log.t > 1 then log = { t = now, n = 0 } callLog[player] = log end
	log.n += 1
	if log.n > 15 then return { ok = false, msg = "Slow down" } end
	if type(action) ~= "string" or #action > 32 then return { ok = false } end

	if action == "sync" then return { ok = true, state = publicState() } end
	local ctx = current
	if not ctx then return { ok = false, msg = "No event is running right now" } end

	if action == "join" then
		local ok, msg = ctx:Join(player)
		return { ok = ok, msg = msg }
	elseif action == "leave" then
		ctx:Leave(player)
		return { ok = true }
	elseif action == "goto" then
		-- teleport next to the event (only while it is announced / active)
		if ctx.Phase == "Results" or not ctx.Location then return { ok = false, msg = "Nothing to go to" } end
		if lastGoto[player] and now - lastGoto[player] < GOTO_COOLDOWN then return { ok = false, msg = "Wait a moment before teleporting again" } end
		local busy = busyFor(ctx, player)
		if busy then return { ok = false, msg = busy } end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return { ok = false } end
		lastGoto[player] = now
		hum.Sit = false
		local spot = ctx.GotoPosition or (ctx.Location + Vector3.new(math.random(-4, 4), 3, math.random(-4, 4)))
		-- load the event area on the player's device first (no loading freeze when they land)
		pcall(function() player:RequestStreamAroundAsync(spot, 4) end)
		if not char.Parent or hum.Health <= 0 then return { ok = false } end
		char:PivotTo(CFrame.new(spot))
		return { ok = true, msg = "Teleported to " .. (ctx.LocationName or ctx.Def.Name) }
	end

	-- anything else belongs to the running event module (it must validate the data)
	if ctx.Module.OnAction and ctx.Phase ~= "Results" then
		local ok, res = pcall(ctx.Module.OnAction, ctx, player, action, data)
		if not ok then warn("[EventManager] OnAction error in " .. ctx.Id .. ": " .. tostring(res)) return { ok = false } end
		return res or { ok = true }
	end
	return { ok = false, msg = "Unknown action" }
end

Players.PlayerAdded:Connect(function(p)
	task.wait(3)
	if p.Parent then
		local st = publicState()
		Remotes.EventState:FireClient(p, st)
	end
end)
Players.PlayerRemoving:Connect(function(p)
	callLog[p] = nil
	lastGoto[p] = nil
	if current and current.Participants[p] then current:Leave(p) end
	if current then current.Scores[p] = nil end
end)

return EventManager
