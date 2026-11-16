--[[ SkyClimbServer — "PATAAS! Parkour" (permanent Only-Up style challenge)
  • Separate floating island in the sky (workspace.SkyClimb, built by ServerStorage.SkyClimbBuilder)
  • Portal in the park across the street from spawn  →  start island
  • EASY  = checkpoints (fall into the void → last checkpoint)
    HARD  = no checkpoints (fall into the void → back to the bottom, the timer keeps running)
  • Fair climbing: walk speed 16 / jump power 50, no tools or bikes while climbing
  • Finish → coins + XP, achievements (SkyClimber / SkyLegend), saved best times + global board
  Remote: ReplicatedStorage.SkyClimb.Remote  (client → "restart" | "checkpoint" | "leave" | "campus" | "state") ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")
local SSS = game:GetService("ServerScriptService")

local root = workspace:WaitForChild("SkyClimb")
local Rewards = require(SSS:WaitForChild("Events"):WaitForChild("EventRewards"))
local Busy = require(SSS:WaitForChild("PlayerBusy")) -- don't pull players out of events / games / the stage

local folder = RS:FindFirstChild("SkyClimb") or Instance.new("Folder")
folder.Name = "SkyClimb" folder.Parent = RS
local Remote = folder:FindFirstChild("Remote") or Instance.new("RemoteEvent")
Remote.Name = "Remote" Remote.Parent = folder

local CFG = {
	Speed = 16, JumpPower = 50,
	VoidBelow = 40,        -- studs under the island top = fell off
	MinFinishTime = 45,    -- anything faster is not a real climb (no reward)
	Easy = { Coins = 40, XP = 60, FirstCoins = 100, Achievement = "SkyClimber" },
	Hard = { Coins = 120, XP = 150, FirstCoins = 250, Achievement = "SkyLegend" },
}

local BASE_Y = root:GetAttribute("BaseY")
local TOP_Y = root:GetAttribute("TopY")
local island = root:WaitForChild("StartIsland")
local ARRIVAL = island:WaitForChild("Arrival").Position + Vector3.new(0, 3, 0)
local START = root:WaitForChild("StartLine").Position
local START_POS = Vector3.new(START.X, BASE_Y + 3, START.Z) + (Vector3.new(island:GetPivot().X, 0, island:GetPivot().Z) - Vector3.new(START.X, 0, START.Z)).Unit * 6
-- campus portal: the open courtyard in front of the barred classroom windows (was in the park at -86, -0.13, 11)
local CAMPUS_PORTAL = Vector3.new(105, 0.6, 89)
-- the portal now lives in Workspace ("SkyClimbPortal", visible in Studio). If you move it in Studio,
-- players coming back from the climb land next to wherever it is.
local function portalSpot()
	local m = workspace:FindFirstChild("SkyClimbPortal")
	local b = m and m:FindFirstChild("Base")
	return b and (b.Position - Vector3.new(0, 0.4, 0)) or CAMPUS_PORTAL
end
-- where players land when they go back to campus: 16 studs out from the portal on the OPEN side
-- (the courtyard, not under the corridor roof), facing AWAY from the ring so they don't walk straight back in
local function returnSpot()
	local m = workspace:FindFirstChild("SkyClimbPortal")
	local f = m and m:FindFirstChild("Field")
	local base = portalSpot()
	local axis = f and f.CFrame.RightVector or Vector3.new(1, 0, 0) -- the ring faces along its X axis
	axis = Vector3.new(axis.X, 0, axis.Z).Unit
	local params = RaycastParams.new() params.FilterType = Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances = { m }
	for _, dir in ipairs({ axis, -axis }) do
		local spot = base + dir * 16
		local roof = workspace:Raycast(spot + Vector3.new(0, 3, 0), Vector3.new(0, 12, 0), params)
		local ground = workspace:Raycast(spot + Vector3.new(0, 6, 0), Vector3.new(0, -12, 0), params)
		if ground and not roof then return ground.Position + Vector3.new(0, 3.2, 0), dir end
	end
	return base + axis * 16 + Vector3.new(0, 3.5, 0), axis
end
local portalCooldown = {} -- player -> os.clock() until the campus portal can fire again

---------------------------------------------------------------- saved boards
local stores = {}
for _, m in ipairs({ "Easy", "Hard" }) do
	local ok, s = pcall(function() return DataStoreService:GetOrderedDataStore("SC_SkyClimb" .. m .. "_v1") end)
	stores[m] = ok and s or nil
end
local session = { Easy = {}, Hard = {} } -- userId -> best seconds (this server)
local names = {}
local function fmt(sec) sec = math.max(0, sec or 0) return ("%d:%05.2f"):format(sec // 60, sec % 60) end

---------------------------------------------------------------- per-player run state
local runs = {}   -- player -> { mode, start, cp, cpPos, falls, finished }
local saved = {}  -- player -> previous walk speed / jump

local function send(p, msg) Remote:FireClient(p, msg) end
local function toast(p, text)
	local r = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("EventRemotes")
	local t = r and r:FindFirstChild("EventToast")
	if t then t:FireClient(p, text) end
end
local function humOf(p) return p.Character and p.Character:FindFirstChildOfClass("Humanoid") end
local function rootOf(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end

-- INSTANT teleport: the destination is pre-loaded while the player walks up to a portal (see the
-- pre-stream loop below), so the move happens the moment they tap. If it isn't loaded yet, the player
-- is moved right away and held in place (anchored) for a moment while the area streams in, instead
-- of standing still at the portal waiting. Nothing here yields, so the fall checker never stalls.
local prestreamed = {} -- player -> { pos, t, done }
local function isReady(p, pos)
	local s = prestreamed[p]
	return s and s.done and (s.pos - pos).Magnitude < 60 and os.clock() - s.t < 25
end
local function prestream(p, pos)
	local s = prestreamed[p]
	if s and (s.pos - pos).Magnitude < 60 and os.clock() - s.t < 20 then return end
	local entry = { pos = pos, t = os.clock(), done = false }
	prestreamed[p] = entry
	task.spawn(function()
		pcall(function() p:RequestStreamAroundAsync(pos, 6) end)
		entry.done = true
	end)
end

local holdToken = {}
local graceUntil = {} -- player -> os.clock(): just teleported / respawned, don't treat a stale position as "moved away"
local function teleport(p, pos, faceDir)
	graceUntil[p] = os.clock() + 4
	local char = p.Character
	local r = rootOf(p)
	if not (char and r) then return end
	local hum = humOf(p)
	if hum and hum.Sit then hum.Sit = false end
	local ready = isReady(p, pos)
	r.AssemblyLinearVelocity = Vector3.zero
	r.AssemblyAngularVelocity = Vector3.zero
	if faceDir then
		char:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(faceDir.X, 0, faceDir.Z)))
	else
		char:PivotTo(CFrame.new(pos) * CFrame.Angles(0, select(2, r.CFrame:ToOrientation()), 0))
	end
	if not ready then
		-- hold them in place until the ground under them has streamed in (max ~2.5 s)
		local token = {}
		holdToken[p] = token
		r.Anchored = true
		local released = false
		local function release()
			if released or holdToken[p] ~= token then return end
			released = true
			holdToken[p] = nil
			if r.Parent then r.Anchored = false end
		end
		task.spawn(function()
			pcall(function() p:RequestStreamAroundAsync(pos, 3) end)
			release()
		end)
		task.delay(2.5, release)
	end
end

local function lockMovement(p, on)
	local hum = humOf(p)
	if not hum then return end
	if on then
		if not saved[p] then saved[p] = { ws = hum.WalkSpeed, jp = hum.JumpPower, jh = hum.JumpHeight, use = hum.UseJumpPower } end
		hum.UseJumpPower = true hum.JumpPower = CFG.JumpPower hum.WalkSpeed = CFG.Speed
		hum:UnequipTools()
	else
		local s = saved[p]
		saved[p] = nil
		if s then hum.UseJumpPower = s.use hum.JumpPower = s.jp hum.JumpHeight = s.jh hum.WalkSpeed = s.ws end
		-- let the shop re-apply equipped speed / jump gear
		local v = p:GetAttribute("EquipSpeed") p:SetAttribute("EquipSpeed", (v or 0) + 0.001) p:SetAttribute("EquipSpeed", v)
	end
end

local function stateOf(p)
	local r = runs[p]
	return {
		type = "state", inside = p:GetAttribute("InSkyClimb") == true,
		running = r ~= nil and not r.finished, mode = r and r.mode, start = r and r.start, cp = r and r.cp or 0,
		falls = r and r.falls or 0, baseY = BASE_Y, topY = TOP_Y,
		bestEasy = p:GetAttribute("SkyBestEasy") or 0, bestHard = p:GetAttribute("SkyBestHard") or 0,
		checkpoints = root:GetAttribute("Checkpoints"),
	}
end
local function pushState(p) send(p, stateOf(p)) end

local function endRun(p)
	runs[p] = nil
	p:SetAttribute("SkyMode", nil)
	lockMovement(p, false)
end

---------------------------------------------------------------- enter / leave the island
local function enterIsland(p)
	local busy = Busy.reason(p, { ignore = { InSkyClimb = true } })
	if busy then toast(p, busy) return end
	p:SetAttribute("InSkyClimb", true)
	teleport(p, ARRIVAL)
	pushState(p)
	send(p, { type = "enter" })
end
local function leaveIsland(p)
	endRun(p)
	p:SetAttribute("InSkyClimb", nil)
	portalCooldown[p] = os.clock() + 4 -- never bounce straight back into the climb
	local spot, face = returnSpot()
	teleport(p, spot, face)
	pushState(p)
end

local function startRun(p, mode)
	if mode ~= "Easy" and mode ~= "Hard" then return end
	runs[p] = { mode = mode, start = workspace:GetServerTimeNow(), cp = 0, cpPos = nil, falls = 0 }
	p:SetAttribute("SkyMode", mode)
	p:SetAttribute("InSkyClimb", true)
	p:SetAttribute("SkyRuns", (p:GetAttribute("SkyRuns") or 0) + 1)
	lockMovement(p, true)
	teleport(p, START_POS)
	pushState(p)
	send(p, { type = "start", mode = mode })
	toast(p, mode == "Easy" and "🟢 EASY climb started — checkpoints will save your progress!" or "🔴 HARD climb started — no checkpoints. Don't look down!")
end

---------------------------------------------------------------- checkpoints
for _, trig in ipairs(CS:GetTagged("SkyClimbCheckpoint")) do
	trig.Touched:Connect(function(hit)
		local p = Players:GetPlayerFromCharacter(hit.Parent)
		local r = p and runs[p]
		if not r or r.finished then return end
		local idx = trig:GetAttribute("Index")
		if r.mode == "Easy" and idx > r.cp then
			r.cp = idx
			r.cpPos = trig.Position - Vector3.new(0, 4, 0) + Vector3.new(0, 3.5, 0)
			send(p, { type = "checkpoint", index = idx, zone = trig:GetAttribute("Zone") })
			pushState(p)
		elseif r.mode == "Hard" and idx > (r.seen or 0) then
			r.seen = idx
			send(p, { type = "zone", zone = trig:GetAttribute("Zone"), hard = true })
		end
	end)
end

---------------------------------------------------------------- finish
local refreshBoard = function() end -- defined below
local function finish(p)
	local r = runs[p]
	if not r or r.finished then return end
	r.finished = true
	local time = workspace:GetServerTimeNow() - r.start
	local mode = r.mode
	local key = "SkyBest" .. mode
	local best = tonumber(p:GetAttribute(key)) or 0
	local newBest = best <= 0 or time < best
	if newBest then p:SetAttribute(key, math.floor(time * 100) / 100) end
	p:SetAttribute("SkyWins", (p:GetAttribute("SkyWins") or 0) + 1)
	local coins, xp, first = 0, 0, false
	local rc = CFG[mode]
	if time >= CFG.MinFinishTime then
		first = Rewards.grantAchievement(p, rc.Achievement)
		coins = Rewards.addCurrency(p, "Common", rc.Coins + (first and rc.FirstCoins or 0))
		xp = Rewards.addXP(p, rc.XP, "PATAAS! Parkour (" .. mode .. ")")
	end
	Rewards.saveSoon(p)
	lockMovement(p, false)
	p:SetAttribute("SkyMode", nil)
	names[p.UserId] = p.DisplayName
	if not session[mode][p.UserId] or time < session[mode][p.UserId] then session[mode][p.UserId] = time end
	if stores[mode] then
		task.spawn(function()
			local ms = math.floor(time * 1000)
			pcall(function() stores[mode]:UpdateAsync(tostring(p.UserId), function(old) if old == nil or ms < old then return ms end return nil end) end)
			refreshBoard()
		end)
	end
	send(p, { type = "finish", mode = mode, time = time, newBest = newBest, best = p:GetAttribute(key), coins = coins, xp = xp, first = first, falls = r.falls })
	for _, other in ipairs(Players:GetPlayers()) do
		toast(other, ("⛰️ %s reached the top of PATAAS! Parkour (%s) in %s!%s"):format(p.DisplayName, mode, fmt(time), newBest and " ⭐" or ""))
	end
	pushState(p)
	refreshBoard()
end
for _, goal in ipairs(CS:GetTagged("SkyClimbFinish")) do
	goal.Touched:Connect(function(hit)
		local p = Players:GetPlayerFromCharacter(hit.Parent)
		if p then finish(p) end
	end)
end

---------------------------------------------------------------- prompts (kiosks, portals)
for _, k in ipairs(CS:GetTagged("SkyClimbKiosk")) do
	local pp = k:FindFirstChildWhichIsA("ProximityPrompt", true)
	if pp then pp.Triggered:Connect(function(p) startRun(p, k:GetAttribute("Mode")) end) end
end
for _, part in ipairs(CS:GetTagged("SkyClimbReturn")) do
	local pp = part:FindFirstChildWhichIsA("ProximityPrompt")
	if pp then pp.Triggered:Connect(leaveIsland) end
end
for _, part in ipairs(CS:GetTagged("SkyClimbToStart")) do
	local pp = part:FindFirstChildWhichIsA("ProximityPrompt")
	if pp then pp.Triggered:Connect(function(p) endRun(p) teleport(p, ARRIVAL) pushState(p) end) end
end

---------------------------------------------------------------- vanishing book stacks
for _, m in ipairs(CS:GetTagged("SkyClimbVanish")) do
	local parts, orig = {}, {}
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts, d) orig[d] = { t = d.Transparency, c = d.CanCollide } end end
	local busy = false
	local function trigger(hit)
		if busy or not Players:GetPlayerFromCharacter(hit.Parent) then return end
		busy = true
		for _, d in ipairs(parts) do TweenService:Create(d, TweenInfo.new(1.1), { Transparency = math.max(orig[d].t, 0.75) }):Play() end
		task.wait(1.15)
		for _, d in ipairs(parts) do d.Transparency = 1 d.CanCollide = false end
		task.wait(3)
		for _, d in ipairs(parts) do d.CanCollide = orig[d].c d.Transparency = 0.9 TweenService:Create(d, TweenInfo.new(0.5), { Transparency = orig[d].t }):Play() end
		task.wait(0.6)
		busy = false
	end
	for _, d in ipairs(parts) do d.CanTouch = true d.Touched:Connect(trigger) end
	if parts[1] then
		local bb = Instance.new("BillboardGui") bb.Size = UDim2.fromOffset(160, 26) bb.StudsOffset = Vector3.new(0, 5, 0) bb.MaxDistance = 45 bb.Parent = parts[1]
		local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.Font = Enum.Font.GothamBold t.TextScaled = true
		t.TextColor3 = Color3.fromRGB(255, 200, 120) t.TextStrokeTransparency = 0.3 t.Text = "⚠️ Crumbling books — be quick!" t.Parent = bb
	end
end

---------------------------------------------------------------- falling + fair movement
task.spawn(function()
	while true do
		task.wait(0.15)
		for _, p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("InSkyClimb") then
				local r = rootOf(p)
				local hum = humOf(p)
				if r and hum and hum.Health > 0 then
					local run = runs[p]
					local flat = Vector3.new(r.Position.X - ARRIVAL.X, 0, r.Position.Z - ARRIVAL.Z).Magnitude
					if r.Position.Y < BASE_Y - 150 and flat > 450 and os.clock() > (graceUntil[p] or 0) then
						-- something else (an admin teleport, an event, a meeting...) already moved them back to campus:
						-- end the climb cleanly instead of yanking them back up to the island
						endRun(p)
						p:SetAttribute("InSkyClimb", nil)
						pushState(p)
					elseif r.Position.Y < BASE_Y - CFG.VoidBelow then
						if run and not run.finished then
							run.falls += 1
							if run.mode == "Easy" and run.cpPos then
								teleport(p, run.cpPos)
								send(p, { type = "fell", to = "checkpoint", falls = run.falls })
							else
								teleport(p, START_POS)
								send(p, { type = "fell", to = "start", falls = run.falls })
							end
						else
							teleport(p, ARRIVAL)
						end
					elseif run and not run.finished then
						if hum.WalkSpeed ~= CFG.Speed then hum.WalkSpeed = CFG.Speed end
						if not hum.UseJumpPower then hum.UseJumpPower = true end
						if hum.JumpPower ~= CFG.JumpPower then hum.JumpPower = CFG.JumpPower end
						if p.Character:FindFirstChildOfClass("Tool") then hum:UnequipTools() end
						if hum.SeatPart then hum.Sit = false end
					end
				end
			end
		end
	end
end)

---------------------------------------------------------------- client requests
Remote.OnServerEvent:Connect(function(p, action, data)
	local r = runs[p]
	if action == "state" then pushState(p)
	elseif action == "start" and p:GetAttribute("InSkyClimb") and (data == "Easy" or data == "Hard") then startRun(p, data)
	elseif action == "restart" and r then startRun(p, r.mode)
	elseif action == "checkpoint" and r and not r.finished then
		if r.mode == "Easy" and r.cpPos then teleport(p, r.cpPos) else teleport(p, START_POS) end
	elseif action == "leave" then endRun(p) teleport(p, ARRIVAL) pushState(p)
	elseif action == "campus" and p:GetAttribute("InSkyClimb") then leaveIsland(p)
	elseif action == "enter" and not p:GetAttribute("InSkyClimb") then enterIsland(p)
	end
end)

---------------------------------------------------------------- respawn / leave
local function hookPlayer(p)
	p.CharacterAdded:Connect(function()
		graceUntil[p] = os.clock() + 5
		if not p:GetAttribute("InSkyClimb") then return end
		task.wait(0.4)
		local r = runs[p]
		if r and not r.finished then
			saved[p] = nil
			lockMovement(p, true)
			teleport(p, (r.mode == "Easy" and r.cpPos) or START_POS)
		else
			teleport(p, ARRIVAL)
		end
	end)
end
Players.PlayerAdded:Connect(hookPlayer)
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerRemoving:Connect(function(p) runs[p] = nil saved[p] = nil prestreamed[p] = nil holdToken[p] = nil portalCooldown[p] = nil graceUntil[p] = nil end)

-- pre-load the destination while a player is walking up to a portal, so the tap teleports instantly
task.spawn(function()
	local returnParts = CS:GetTagged("SkyClimbReturn")
	while true do
		task.wait(0.5)
		local campus = portalSpot()
		for _, p in ipairs(Players:GetPlayers()) do
			local r = rootOf(p)
			if r then
				if not p:GetAttribute("InSkyClimb") then
					if (r.Position - campus).Magnitude < 45 then prestream(p, ARRIVAL) end
				else
					local run = runs[p]
					if not run or run.finished then
						-- on the island: keep the start line ready, and campus ready when near a return portal
						local nearReturn = false
						for _, part in ipairs(returnParts) do
							if (r.Position - part.Position).Magnitude < 40 then nearReturn = true break end
						end
						if nearReturn then prestream(p, (returnSpot())) else prestream(p, START_POS) end
					end
				end
			end
		end
	end
end)

---------------------------------------------------------------- campus portal (courtyard by the barred classroom windows)
do
	-- use the portal placed in Studio; only build a new one if it's missing
	-- WALK-THROUGH portal: you only go up when your body actually passes through the glowing ring.
	-- (It used to be a tap prompt with a 12-stud range on the whole model, so tapping / clicking the floor
	-- disc - or tap-to-move on mobile - near it teleported people who never touched the ring.)
	local function hookField(field)
		for _, pp in ipairs(field:GetChildren()) do if pp:IsA("ProximityPrompt") then pp:Destroy() end end
		field.CanTouch = true
		field.Touched:Connect(function(hit)
			-- only the BODY counts: hats / hair / wings have big invisible hitboxes that brush the ring's edge
			-- while the player is walking past it
			if hit:FindFirstAncestorWhichIsA("Accoutrement") or hit:FindFirstAncestorWhichIsA("Tool") then return end
			if hit.Name ~= "HumanoidRootPart" and hit.Name ~= "UpperTorso" and hit.Name ~= "LowerTorso" and hit.Name ~= "Torso" and hit.Name ~= "Head" then return end
			local char = hit:FindFirstAncestorOfClass("Model")
			local p = char and Players:GetPlayerFromCharacter(char)
			if not p or p:GetAttribute("InSkyClimb") then return end
			if Busy.isBusy(p) then return end -- in an event / game / on stage: walk through without teleporting
			local hum = char:FindFirstChildOfClass("Humanoid")
			local r = char:FindFirstChild("HumanoidRootPart")
			if not (hum and r) or hum.Health <= 0 then return end
			if portalCooldown[p] and os.clock() < portalCooldown[p] then return end
			-- the Field is only the glowing disc INSIDE the ring, so a body part touching it means the player
			-- really walked into the ring. (No extra position check: the touch is reported by the player's
			-- device and the server's copy of their position lags a few studs behind.)
			portalCooldown[p] = os.clock() + 3
			enterIsland(p)
		end)
		-- small hint so players know to walk in
		local base = field.Parent:FindFirstChild("Base")
		if base and not base:FindFirstChild("WalkHint") then
			local bb = Instance.new("BillboardGui") bb.Name = "WalkHint" bb.Size = UDim2.fromOffset(170, 22) bb.StudsOffset = Vector3.new(0, 1.6, 0)
			bb.MaxDistance = 40 bb.LightInfluence = 0 bb.Parent = base
			local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundColor3 = Color3.fromRGB(20, 24, 28) t.BackgroundTransparency = 0.3
			t.Font = Enum.Font.GothamBold t.TextSize = 12 t.TextColor3 = Color3.fromRGB(245, 200, 60) t.Text = "🚶 Walk through the ring to climb" t.Parent = bb
			Instance.new("UICorner", t).CornerRadius = UDim.new(1, 0)
		end
	end
	local existing = workspace:FindFirstChild("SkyClimbPortal")
	local existingField = existing and existing:FindFirstChild("Field")
	if existingField then
		hookField(existingField)
	else
	if existing then existing:Destroy() end
	local m = Instance.new("Model") m.Name = "SkyClimbPortal" m.Parent = workspace
	local base = CAMPUS_PORTAL
	local function part(name, size, cf, color, mat, props)
		local p = Instance.new("Part") p.Name = name p.Size = size p.CFrame = cf p.Color = color p.Material = mat or Enum.Material.SmoothPlastic p.Anchored = true
		for k, v in pairs(props or {}) do p[k] = v end
		p.Parent = m return p
	end
	part("Base", Vector3.new(1, 14, 14), CFrame.new(base + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(240, 240, 235), Enum.Material.Marble, { Shape = Enum.PartType.Cylinder })
	for k = 0, 19 do
		local a = k / 20 * math.pi * 2
		part("Ring", Vector3.new(1.3, 1.3, 1.3), CFrame.new(base + Vector3.new(0, 7.5 + math.sin(a) * 6, math.cos(a) * 6)), k % 2 == 0 and Color3.fromRGB(120, 200, 255) or Color3.fromRGB(245, 200, 60), Enum.Material.Neon, { Shape = Enum.PartType.Ball, CanCollide = false })
	end
	local field = part("Field", Vector3.new(0.3, 11, 11), CFrame.new(base + Vector3.new(0, 7.5, 0)), Color3.fromRGB(150, 220, 255), Enum.Material.ForceField, { Shape = Enum.PartType.Cylinder, CanCollide = false })
	local sign = part("Sign", Vector3.new(0.4, 3, 12), CFrame.new(base + Vector3.new(0, 15.5, 0)), Color3.fromRGB(25, 60, 40), Enum.Material.SmoothPlastic)
	for _, face in ipairs({ Enum.NormalId.Right, Enum.NormalId.Left }) do
		local g = Instance.new("SurfaceGui") g.Face = face g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = 30 g.Parent = sign
		local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.Font = Enum.Font.GothamBlack t.TextScaled = true t.TextColor3 = Color3.fromRGB(245, 200, 60) t.Text = "⛰️ PATAAS! PARKOUR" t.Parent = g
	end
	hookField(field)
	local pe = Instance.new("ParticleEmitter") pe.Rate = 12 pe.Lifetime = NumberRange.new(1.5, 2.5) pe.Speed = NumberRange.new(1, 3) pe.LightEmission = 1
	pe.Size = NumberSequence.new(0.4, 0) pe.Color = ColorSequence.new(Color3.fromRGB(150, 220, 255), Color3.fromRGB(245, 200, 60)) pe.Parent = field
	end
end

---------------------------------------------------------------- leaderboard board on the island
local board = CS:GetTagged("SkyClimbBoard")[1]
local boardText
if board then
	local g = Instance.new("SurfaceGui") g.Face = Enum.NormalId.Right g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = 25 g.LightInfluence = 0 g.Parent = board
	local bg = Instance.new("Frame") bg.Size = UDim2.fromScale(1, 1) bg.BackgroundColor3 = Color3.fromRGB(16, 22, 28) bg.Parent = g
	local title = Instance.new("TextLabel") title.Size = UDim2.new(1, 0, 0.14, 0) title.BackgroundColor3 = Color3.fromRGB(25, 60, 40) title.Font = Enum.Font.GothamBlack title.TextScaled = true title.TextColor3 = Color3.fromRGB(245, 200, 60) title.Text = "🏆 FASTEST CLIMBERS" title.Parent = bg
	boardText = {}
	for i, mode in ipairs({ "Easy", "Hard" }) do
		local col = Instance.new("TextLabel") col.Position = UDim2.new((i - 1) * 0.5, 8, 0.16, 0) col.Size = UDim2.new(0.5, -16, 0.82, 0) col.BackgroundTransparency = 1
		col.Font = Enum.Font.GothamBold col.TextScaled = true col.TextXAlignment = Enum.TextXAlignment.Left col.TextYAlignment = Enum.TextYAlignment.Top
		col.TextColor3 = Color3.new(1, 1, 1) col.RichText = true col.Text = "" col.Parent = bg
		boardText[mode] = col
	end
end
local function nameOf(id)
	if names[id] then return names[id] end
	local ok, n = pcall(function() return Players:GetNameFromUserIdAsync(id) end)
	names[id] = ok and n or ("#" .. id)
	return names[id]
end
local refreshing = false
refreshBoard = function()
	if not boardText or refreshing then return end
	refreshing = true
	for _, mode in ipairs({ "Easy", "Hard" }) do
		local rows = {}
		local okList = false
		if stores[mode] then
			local ok, pages = pcall(function() return stores[mode]:GetSortedAsync(true, 10) end)
			if ok and pages then
				okList = true
				for _, e in ipairs(pages:GetCurrentPage()) do table.insert(rows, { id = tonumber(e.key), t = e.value / 1000 }) end
			end
		end
		if not okList then
			for id, t in pairs(session[mode]) do table.insert(rows, { id = id, t = t }) end
			table.sort(rows, function(a, b) return a.t < b.t end)
		end
		local lines = { (mode == "Easy" and '<font color="#7CE08C">🟢 EASY</font>' or '<font color="#FF7070">🔴 HARD</font>') }
		for i = 1, math.min(10, #rows) do table.insert(lines, ("%d. %s  <font color=\"#F5C83C\">%s</font>"):format(i, nameOf(rows[i].id), fmt(rows[i].t))) end
		if #rows == 0 then table.insert(lines, '<font color="#8A96A0">No climbers yet — be the first!</font>') end
		boardText[mode].Text = table.concat(lines, "\n")
	end
	refreshing = false
end
task.spawn(function() while true do refreshBoard() task.wait(90) end end)
