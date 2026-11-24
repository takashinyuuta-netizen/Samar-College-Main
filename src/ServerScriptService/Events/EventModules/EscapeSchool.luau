--[[ EscapeSchool – ESCAPE SAMAR COLLEGE (Common event, whole campus) ─────────────
  • 8 department keys (EventConfig.EscapeSchool.Keys) spawn in a random room of their
    department. Keys are SHARED: when any participant takes a key, the whole team has it
    (the key vanishes with a sparkle and everyone is told).
  • Teacher & Guard patrols (EventConfig.EscapeSchool.Patrols/Routes) walk with real
    animations (idle, walk, run, wave at stops, point when they spot you, cheer on a catch).
    They see you inside a view cone with line of sight → ❗ CHASE (chase music for you).
    Get far away / out of sight → ❓ they search, then return to their route.
    Caught → detention in the Prefect of Discipline office (keys stay with the team).
  • When the team has all 8 keys, each player goes to the 🔓 MAIN GATE lock to escape.
    Fastest escapes rank first.
  • The client (EventGui.EscapeClient) shows the key grid, a guide arrow to the nearest key
    (then to the gate), alerts, music and the key pickup effect.
───────────────────────────────────────────────────────────────────────────]]
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local M = {}
local campus = workspace:WaitForChild("SamarCollege_Campus")

---------------------------------------------------------------- NPC animations (Roblox default animations)
local ANIMS = {
	R15 = { idle = 507766388, walk = 507777826, run = 507767714, wave = 507770239, point = 507770453, cheer = 507770677 },
	R6  = { idle = 180435571, walk = 180426354, run = 180426354, wave = 128777973, point = 128853357, cheer = 129423030 },
}

---------------------------------------------------------------- helpers
local function part(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part") p.Name = name p.Size = size p.CFrame = cf p.Color = color p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = parent return p
end
local function billboard(adornee, text, color, offset, dist, size)
	local bb = Instance.new("BillboardGui") bb.Size = size or UDim2.fromOffset(170, 40) bb.StudsOffset = offset or Vector3.new(0, 2.5, 0)
	bb.MaxDistance = dist or 40 bb.LightInfluence = 0 bb.Parent = adornee
	local t = Instance.new("TextLabel") t.Name = "Text" t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.TextScaled = true
	t.Font = Enum.Font.GothamBlack t.TextColor3 = color or Color3.new(1, 1, 1) t.TextStrokeTransparency = 0.25 t.Text = text t.Parent = bb
	return t, bb
end

local function findRoom(name)
	for _, fl in ipairs(campus:GetChildren()) do
		local rooms = fl:FindFirstChild("02_Rooms")
		local r = rooms and rooms:FindFirstChild(name)
		if r then return r, fl.Name end
	end
end
local function boundsOf(inst)
	if inst:IsA("Model") then return inst:GetBoundingBox() end
	local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	for _, d in ipairs(inst:GetDescendants()) do if d:IsA("BasePart") then mn = mn:Min(d.Position - d.Size / 2) mx = mx:Max(d.Position + d.Size / 2) end end
	if mn.X > mx.X then return nil end
	return CFrame.new((mn + mx) / 2), mx - mn
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function floorSpot(room, exclude)
	local cf, size = boundsOf(room)
	if not cf then return nil end
	rayParams.FilterDescendantsInstances = exclude
	local op = OverlapParams.new() op.FilterType = Enum.RaycastFilterType.Exclude op.FilterDescendantsInstances = exclude
	for _ = 1, 30 do
		local x = (math.random() - 0.5) * size.X * 0.7
		local z = (math.random() - 0.5) * size.Z * 0.7
		local top = cf:PointToWorldSpace(Vector3.new(x, size.Y / 2 - 1, z))
		local hit = workspace:Raycast(top, Vector3.new(0, -size.Y, 0), rayParams)
		if hit and hit.Normal.Y > 0.9 and hit.Position.Y < cf.Y - size.Y / 2 + 4 then
			local spot = hit.Position
			local clear = true
			for _, b in ipairs(workspace:GetPartBoundsInBox(CFrame.new(spot + Vector3.new(0, 2.6, 0)), Vector3.new(2.5, 4, 2.5), op)) do
				if b.CanCollide then clear = false break end
			end
			if clear then return spot end
		end
	end
	return nil
end

---------------------------------------------------------------- keys (shared by the team)
local function teamCount(ctx) local n = 0 for _ in pairs(ctx.Data.teamKeys) do n += 1 end return n end

local function buildKey(ctx, def)
	local rooms = {}
	for _, name in ipairs(def.Rooms) do local r, fl = findRoom(name) if r and not r:GetAttribute("HostedBy") then table.insert(rooms, { r = r, fl = fl }) end end -- no keys in hosted rooms
	for i = #rooms, 2, -1 do local j = math.random(i) rooms[i], rooms[j] = rooms[j], rooms[i] end
	local spot, where
	for _, e in ipairs(rooms) do spot = floorSpot(e.r, { ctx.Folder }) if spot then where = e break end end
	if not spot then warn("[Escape] no spot for key " .. def.Id) return nil end
	local key = Instance.new("Model") key.Name = "Key_" .. def.Id key.Parent = ctx.Folder
	key:SetAttribute("KeyId", def.Id) key:SetAttribute("KeyName", def.Name)
	local base = CFrame.new(spot + Vector3.new(0, 2, 0))
	local ring = part(key, "Ring", Vector3.new(0.3, 1.4, 1.4), base * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), def.Color, Enum.Material.Neon, { Shape = Enum.PartType.Cylinder, CanCollide = false })
	part(key, "Shaft", Vector3.new(0.3, 1.6, 0.3), base * CFrame.new(0, -0.5, 0), def.Color, Enum.Material.Neon, { CanCollide = false })
	part(key, "Tooth", Vector3.new(0.3, 0.3, 0.6), base * CFrame.new(0, -1.1, 0.35), def.Color, Enum.Material.Neon, { CanCollide = false })
	local glow = Instance.new("PointLight") glow.Color = def.Color glow.Range = 12 glow.Brightness = 2 glow.Parent = ring
	local sparkle = Instance.new("ParticleEmitter") sparkle.Rate = 6 sparkle.Lifetime = NumberRange.new(0.8, 1.4) sparkle.Speed = NumberRange.new(1, 2)
	sparkle.Size = NumberSequence.new(0.25, 0) sparkle.Color = ColorSequence.new(def.Color) sparkle.LightEmission = 1 sparkle.Parent = ring
	key.PrimaryPart = ring
	billboard(ring, "🔑 " .. def.Name, def.Color, Vector3.new(0, 2.2, 0), 35)
	-- slow spin + bob so it's easy to notice
	task.spawn(function()
		local t = 0
		while key.Parent and ring.Parent do
			t += 0.05
			key:PivotTo(base * CFrame.new(0, math.sin(t * 2) * 0.25, 0) * CFrame.Angles(0, t, 0))
			task.wait(0.05)
		end
	end)
	local pp = Instance.new("ProximityPrompt") pp.ActionText = "Take key" pp.ObjectText = "🔑 " .. def.Name pp.HoldDuration = 0.4
	pp.MaxActivationDistance = 8 pp.RequiresLineOfSight = false pp.Parent = ring
	ctx:Connect(pp.Triggered, function(player) M.takeKey(ctx, player, def) end)
	local fl = where.fl:gsub("_Ground", "")
	local building = def.Id == "ES" and "Elementary" or ((def.Id == "JHS" or def.Id == "SHS") and "High School" or "College")
	return { model = key, pos = spot, hint = ("%s • %s"):format(fl, building), room = where.r.Name }
end

local function keyEffect(ctx, k, def)
	-- burst + chime where the key was, then the key flies up and fades
	local fx = part(ctx.Folder, "KeyBurst", Vector3.new(1, 1, 1), CFrame.new(k.pos + Vector3.new(0, 2.5, 0)), def.Color, Enum.Material.Neon, { Transparency = 1, CanCollide = false })
	local pe = Instance.new("ParticleEmitter") pe.Rate = 0 pe.Speed = NumberRange.new(10, 18) pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.6, 1.1) pe.Size = NumberSequence.new(0.5, 0) pe.Color = ColorSequence.new(def.Color, Color3.new(1, 1, 1)) pe.LightEmission = 1 pe.Parent = fx
	pe:Emit(60)
	local snd = Instance.new("Sound") snd.SoundId = ctx.Config.EscapeSchool.Music.KeyGet snd.Volume = 1 snd.RollOffMaxDistance = 80 snd.Parent = fx snd:Play()
	for _, p in ipairs(k.model:GetDescendants()) do
		if p:IsA("BasePart") then TweenService:Create(p, TweenInfo.new(0.9, Enum.EasingStyle.Quad), { Transparency = 1, CFrame = p.CFrame + Vector3.new(0, 5, 0) }):Play() end
		if p:IsA("ProximityPrompt") then p.Enabled = false end
		if p:IsA("BillboardGui") then p.Enabled = false end
	end
	task.delay(1, function() k.model:Destroy() end)
	task.delay(2, function() fx:Destroy() end)
end

function M.takeKey(ctx, player, def)
	if ctx.Phase ~= "Active" then ctx:Toast(player, "⏳ Keys can be taken when the escape starts!") return end
	if not ctx:IsIn(player) and not ctx:Join(player) then return end
	if ctx.Data.detained[player] then ctx:Toast(player, "🚨 You're in detention — wait it out!") return end
	if ctx.Data.teamKeys[def.Id] then return end
	ctx.Data.teamKeys[def.Id] = player
	ctx.Data.found[player] = (ctx.Data.found[player] or 0) + 1
	ctx:AddScore(player, 100)
	local k = ctx.Data.keyObjs[def.Id]
	if k then keyEffect(ctx, k, def) end
	local n = teamCount(ctx)
	ctx:ToastAll(("🔑 %s found the %s key! (%d / %d)%s"):format(player.DisplayName, def.Name, n, #ctx.Data.keyDefs, n == #ctx.Data.keyDefs and " → Everyone to the MAIN GATE!" or ""))
	for p in pairs(ctx.Participants) do if p.Parent then M.sendHud(ctx, p, { gotKey = def.Id, by = player.DisplayName, byMe = p == player }) end end
end

function M.sendHud(ctx, player, extra)
	local list = {}
	for _, d in ipairs(ctx.Data.keyDefs) do
		local k = ctx.Data.keyObjs[d.Id]
		table.insert(list, { id = d.Id, name = d.Name, color = d.Color, got = ctx.Data.teamKeys[d.Id] ~= nil, hint = k and k.hint or "?", pos = k and k.pos })
	end
	local msg = { type = "keys", keys = list, escaped = ctx.Data.escaped[player] == true, gate = ctx.Data.lockPos }
	for k, v in pairs(extra or {}) do msg[k] = v end
	ctx:Send(player, msg)
end

---------------------------------------------------------------- routes
local function routeFromAnchors(name)
	local want = {
		JHS_3F = function(a) return a:GetAttribute("Floor") == "3F" and a:GetAttribute("Course") == "Junior High" end,
		SHS_2F = function(a) return a:GetAttribute("Floor") == "2F" and a:GetAttribute("Department") == "High School" and a:GetAttribute("Course") ~= "Junior High" end,
		SHS_3F = function(a) return a:GetAttribute("Floor") == "3F" and a:GetAttribute("Department") == "High School" and a:GetAttribute("Course") ~= "Junior High" end,
		College_3F = function(a) return a:GetAttribute("Floor") == "3F" and a:GetAttribute("Department") == "College" end,
		College_4F = function(a) return a:GetAttribute("Floor") == "4F" and a:GetAttribute("Department") == "College" end,
		College_5F = function(a) return a:GetAttribute("Floor") == "5F" and a:GetAttribute("Department") == "College" end,
	}
	local f = want[name]
	if not f then return nil end
	local pts = {}
	for _, a in ipairs(CollectionService:GetTagged("QuizBeeRoom")) do if f(a) then table.insert(pts, a.Position + Vector3.new(0, 2.5, 0)) end end
	return pts
end

-- corridor point in front of each room's door (outside the room)
local function routeFromRooms(names)
	local pts = {}
	for _, name in ipairs(names) do
		local room = findRoom(name)
		if room then
			local cf = boundsOf(room)
			local best
			for _, d in ipairs(room:GetDescendants()) do
				if d:IsA("BasePart") and d.Name == "Base" and d:FindFirstAncestor("E to Open Door") then best = d break end
			end
			if not best and cf then
				-- some rooms keep their door in the floor's 03_Doors folder: take the closest one to the room
				local _, size = boundsOf(room)
				local fl = room:FindFirstAncestorWhichIsA("Folder") and room:FindFirstAncestorWhichIsA("Folder").Parent
				local doors = fl and fl:FindFirstChild("03_Doors")
				local bestD
				if doors then
					for _, d in ipairs(doors:GetDescendants()) do
						if d:IsA("BasePart") and d.Name == "Base" then
							local rel = cf:PointToObjectSpace(d.Position)
							local out = Vector3.new(math.max(0, math.abs(rel.X) - size.X / 2), math.max(0, math.abs(rel.Y) - size.Y / 2), math.max(0, math.abs(rel.Z) - size.Z / 2)).Magnitude
							if out < 4 and (not bestD or out < bestD) then best, bestD = d, out end
						end
					end
				end
			end
			if cf and best then
				local s = best.Size
				local axis = (s.X < s.Z) and best.CFrame.RightVector or best.CFrame.LookVector
				axis = Vector3.new(axis.X, 0, axis.Z).Unit
				local a1, a2 = best.Position + axis * 4.5, best.Position - axis * 4.5
				local out = ((a1 - cf.Position).Magnitude > (a2 - cf.Position).Magnitude) and a1 or a2
				local hit = workspace:Raycast(out + Vector3.new(0, 3, 0), Vector3.new(0, -12, 0))
				if hit then table.insert(pts, hit.Position + Vector3.new(0, 3, 0)) end
			end
		end
	end
	return pts
end

local function sortAlong(pts)
	local mn, mx = Vector3.new(1e9, 0, 1e9), Vector3.new(-1e9, 0, -1e9)
	for _, p in ipairs(pts) do mn = mn:Min(p) mx = mx:Max(p) end
	local alongX = (mx.X - mn.X) > (mx.Z - mn.Z)
	table.sort(pts, function(a, b) if alongX then return a.X < b.X end return a.Z < b.Z end)
	return pts
end

local function computePath(from, to)
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 6 })
	local ok = pcall(function() path:ComputeAsync(from, to) end)
	if ok and path.Status == Enum.PathStatus.Success then return path:GetWaypoints() end
	return nil
end

---------------------------------------------------------------- patrol NPCs
local TEMPLATES = { Guard = "Guard", Teacher = "Ma'am Carlota" }

local function setupAnimations(n)
	local animator = n.hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", n.hum)
	local set = ANIMS[n.hum.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"]
	n.tracks = {}
	for name, id in pairs(set) do
		local a = Instance.new("Animation") a.AnimationId = "rbxassetid://" .. id
		local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
		if ok and tr then
			tr.Priority = (name == "wave" or name == "point" or name == "cheer") and Enum.AnimationPriority.Action or Enum.AnimationPriority.Movement
			tr.Looped = (name == "idle" or name == "walk" or name == "run")
			n.tracks[name] = tr
		end
	end
	if n.tracks.idle then n.tracks.idle.Priority = Enum.AnimationPriority.Idle end
	-- movement animation follows the real speed
	n.hum.Running:Connect(function(speed)
		local want = speed < 0.5 and "idle" or (speed > 12 and "run" or "walk")
		if want == n.moveAnim then
			if want ~= "idle" and n.tracks[want] then n.tracks[want]:AdjustSpeed(speed / (want == "run" and 16 or 9)) end
			return
		end
		for _, k in ipairs({ "idle", "walk", "run" }) do if k ~= want and n.tracks[k] and n.tracks[k].IsPlaying then n.tracks[k]:Stop(0.2) end end
		if n.tracks[want] then n.tracks[want]:Play(0.2) end
		n.moveAnim = want
	end)
	if n.tracks.idle then n.tracks.idle:Play() n.moveAnim = "idle" end
end

local function gesture(n, name, seconds)
	local tr = n.tracks and n.tracks[name]
	if not tr then return end
	tr:Play(0.1)
	task.delay(seconds or 1.5, function() if tr.IsPlaying then tr:Stop(0.3) end end)
end

local function makeNpc(ctx, kind, at)
	local src = workspace:FindFirstChild(TEMPLATES[kind]) or workspace:FindFirstChild("Guard")
	if not src then return nil end
	local npc = src:Clone()
	-- no scripts, prompts or name tags from the original NPC
	for _, d in ipairs(npc:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") or d:IsA("BillboardGui") or d:IsA("Dialog") then d:Destroy() end
	end
	for _, d in ipairs(npc:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = false end end
	npc.Name = ("Patrol%s_%d"):format(kind, #ctx.Data.npcs + 1)
	local hum = npc:FindFirstChildOfClass("Humanoid")
	local root = npc:FindFirstChild("HumanoidRootPart")
	if not hum or not root then npc:Destroy() return nil end
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.NameDisplayDistance = 0
	hum.DisplayName = " "
	hum.WalkSpeed = ctx.Config.EscapeSchool.PatrolSpeed
	npc:PivotTo(CFrame.new(at))
	npc.Parent = ctx.Folder
	pcall(function() root:SetNetworkOwner(nil) end)
	local head = npc:FindFirstChild("Head") or root
	-- only a status icon above the head (❗ chasing / ❓ searching), no names
	local status = billboard(head, "", Color3.fromRGB(255, 70, 70), Vector3.new(0, 3, 0), 120, UDim2.fromOffset(60, 60))
	local n = { model = npc, hum = hum, root = root, head = head, kind = kind, status = status, state = "patrol" }
	setupAnimations(n)
	return n
end

local function canSee(ctx, n, player)
	local cfg = ctx.Config.EscapeSchool
	local char = player.Character
	local proot = char and char:FindFirstChild("HumanoidRootPart")
	if not proot then return false end
	local eye = n.head.Position
	local target = proot.Position + Vector3.new(0, 1.5, 0)
	local d = target - eye
	if d.Magnitude > cfg.ViewRange then return false end
	local look = n.root.CFrame.LookVector
	local flat = Vector3.new(d.X, 0, d.Z)
	if flat.Magnitude > 2 and look:Dot(flat.Unit) < math.cos(math.rad(cfg.ViewAngle / 2)) then return false end
	rayParams.FilterDescendantsInstances = { n.model, char, ctx.Folder }
	return workspace:Raycast(eye, d, rayParams) == nil
end

local function walkPath(n, waypoints, shouldStop)
	for _, wp in ipairs(waypoints) do
		if shouldStop() then return false end
		if wp.Action == Enum.PathWaypointAction.Jump then n.hum.Jump = true end
		n.hum:MoveTo(wp.Position)
		local t0 = os.clock()
		while (n.root.Position - wp.Position).Magnitude > 3.5 and os.clock() - t0 < 4 do
			if shouldStop() then return false end
			task.wait(0.1)
		end
	end
	return true
end

local function runNpc(ctx, n)
	local cfg = ctx.Config.EscapeSchool
	local idx = 1
	while ctx.Phase == "Active" and n.model.Parent do
		if n.state == "patrol" then
			n.hum.WalkSpeed = cfg.PatrolSpeed
			n.status.Text = ""
			local seg = n.segments[idx]
			idx = idx % #n.segments + 1
			walkPath(n, seg, function() return n.state ~= "patrol" or ctx.Phase ~= "Active" end)
			if n.state == "patrol" then
				-- little stop at each route point: look around or wave
				n.hum:MoveTo(n.root.Position)
				if math.random() < 0.35 then gesture(n, "wave", 1.6) end
				for _ = 1, 15 do if n.state ~= "patrol" then break end task.wait(0.1) end
			end
		elseif n.state == "spot" then
			-- freeze, point at the student, then start running
			n.hum:MoveTo(n.root.Position)
			n.status.Text = "❗"
			n.status.TextColor3 = Color3.fromRGB(255, 70, 70)
			local tgt = n.target and n.target.Character and n.target.Character:FindFirstChild("HumanoidRootPart")
			if tgt then n.root.CFrame = CFrame.lookAt(n.root.Position, Vector3.new(tgt.Position.X, n.root.Position.Y, tgt.Position.Z)) end
			gesture(n, "point", 0.9)
			task.wait(0.8)
			if n.state == "spot" then n.state = "chase" end
		elseif n.state == "chase" then
			n.hum.WalkSpeed = cfg.ChaseSpeed
			n.status.Text = "❗"
			local tgt = n.target
			local proot = tgt and tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
			if not proot then n.state = "return"
			else
				local wps = computePath(n.root.Position, proot.Position)
				if wps and #wps > 1 then
					local t0 = os.clock()
					walkPath(n, { wps[2], wps[3] or wps[2] }, function() return n.state ~= "chase" or os.clock() - t0 > 0.9 end)
				else
					n.hum:MoveTo(proot.Position) task.wait(0.4)
				end
			end
		elseif n.state == "caught" then
			n.hum:MoveTo(n.root.Position)
			n.status.Text = "😤"
			gesture(n, "cheer", 1.8)
			task.wait(2)
			if n.state == "caught" then n.state = "return" end
		elseif n.state == "search" then
			n.hum.WalkSpeed = cfg.PatrolSpeed
			n.status.Text = "❓"
			n.status.TextColor3 = Color3.fromRGB(255, 220, 80)
			if n.lastSeen then
				local wps = computePath(n.root.Position, n.lastSeen)
				if wps then walkPath(n, wps, function() return n.state ~= "search" end) end
			end
			n.hum:MoveTo(n.root.Position)
			-- look left and right
			for k = 1, 4 do
				if n.state ~= "search" then break end
				n.root.CFrame = n.root.CFrame * CFrame.Angles(0, math.rad(k % 2 == 0 and 70 or -70), 0)
				task.wait(0.5)
			end
			if n.state == "search" then n.state = "return" end
			n.status.TextColor3 = Color3.fromRGB(255, 70, 70)
		elseif n.state == "return" then
			n.status.Text = ""
			local best, bi = math.huge, 1
			for i, p in ipairs(n.points) do local d = (p - n.root.Position).Magnitude if d < best then best, bi = d, i end end
			local wps = computePath(n.root.Position, n.points[bi])
			if wps then walkPath(n, wps, function() return n.state ~= "return" end) else n.model:PivotTo(CFrame.new(n.points[bi])) end
			if n.state == "return" then n.state = "patrol" idx = math.min(bi, #n.segments) end
		end
		task.wait()
	end
end

local function senses(ctx)
	local cfg = ctx.Config.EscapeSchool
	while ctx.Phase == "Active" do
		for _, n in ipairs(ctx.Data.npcs) do
			if n.model.Parent and n.root.Parent then
				if n.state == "chase" or n.state == "spot" then
					local tgt = n.target
					local proot = tgt and tgt.Parent and tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
					if not proot or ctx.Data.detained[tgt] or ctx.Data.escaped[tgt] or not ctx:IsIn(tgt) then
						if tgt and tgt.Parent then ctx:Send(tgt, { type = "lost", by = n.kind }) end
						n.state = "return" n.target = nil
					else
						local dist = (proot.Position - n.root.Position).Magnitude
						if canSee(ctx, n, tgt) then n.lastSeen = proot.Position n.unseen = 0 else n.unseen = (n.unseen or 0) + 0.2 end
						if n.state == "chase" and dist <= cfg.CatchDistance then
							M.catch(ctx, tgt, n)
							n.state = "caught" n.target = nil
						elseif dist > cfg.LoseDistance or (n.unseen or 0) >= cfg.LoseTime or math.abs(proot.Position.Y - n.root.Position.Y) > 12 then
							ctx:Send(tgt, { type = "lost", by = n.kind })
							n.state = "search" n.target = nil
						end
					end
				elseif n.state == "patrol" or n.state == "search" or n.state == "return" then
					for p in pairs(ctx.Participants) do
						if p.Parent and not ctx.Data.detained[p] and not ctx.Data.escaped[p] and canSee(ctx, n, p) then
							n.state = "spot" n.target = p n.unseen = 0
							n.lastSeen = p.Character.HumanoidRootPart.Position
							ctx:Send(p, { type = "spotted", by = n.kind })
							break
						end
					end
				end
			end
		end
		task.wait(0.2)
	end
end

function M.catch(ctx, player, n)
	local cfg = ctx.Config.EscapeSchool
	if ctx.Data.detained[player] then return end
	ctx.Data.detained[player] = true
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.Sit = false end
	if char then char:PivotTo(CFrame.new(ctx.Data.detention + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2)))) end
	if hum then hum.WalkSpeed = 0 hum.JumpHeight = 0 end
	ctx:Send(player, { type = "caught", by = n.kind, seconds = cfg.DetentionTime })
	ctx:ToastAll(("🚨 %s was caught by a %s!"):format(player.DisplayName, string.lower(n.kind)))
	task.delay(cfg.DetentionTime, function()
		ctx.Data.detained[player] = nil
		if hum and hum.Parent then hum.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed hum.JumpHeight = game.StarterPlayer.CharacterJumpHeight end
		if player.Parent then ctx:Toast(player, "🚪 Detention is over — sneak back out!") end
	end)
end

---------------------------------------------------------------- setup
function M.Setup(ctx)
	local cfg = ctx.Config.EscapeSchool
	ctx.Data.keyDefs, ctx.Data.keyObjs = cfg.Keys, {}
	ctx.Data.teamKeys, ctx.Data.found, ctx.Data.escaped, ctx.Data.order, ctx.Data.detained = {}, {}, {}, {}, {}
	ctx.Data.npcs = {}
	for _, def in ipairs(cfg.Keys) do
		local k = buildKey(ctx, def)
		if k then ctx.Data.keyObjs[def.Id] = k end
	end
	local n = 0 for _ in pairs(ctx.Data.keyObjs) do n += 1 end
	if n < #cfg.Keys then ctx.CancelReason = ("only %d of %d keys could be placed"):format(n, #cfg.Keys) return false end
	local pod = findRoom("PrefectOfDiscipline_Office")
	local spot = pod and floorSpot(pod, { ctx.Folder })
	ctx.Data.detention = (spot or Vector3.new(125, 0.5, 15)) + Vector3.new(0, 3, 0)
	-- main gate lock
	local gate = campus:FindFirstChild("MainGate")
	local inside = gate and gate:FindFirstChild("PromptAnchor_Inside")
	local lockPos = (inside and inside.Position or Vector3.new(26, 3.5, 8)) + Vector3.new(2, 0, 4)
	ctx.Data.lockPos = lockPos
	local outside = gate and gate:FindFirstChild("PromptAnchor_Outside")
	ctx.Data.outside = (outside and outside.Position or Vector3.new(10, 3.5, 8)) + Vector3.new(-6, 1, 0)
	local lock = part(ctx.Folder, "EscapeLock", Vector3.new(1.4, 2.2, 1.4), CFrame.new(lockPos), Color3.fromRGB(40, 40, 46), Enum.Material.Metal)
	part(ctx.Folder, "LockStand", Vector3.new(0.6, 2.4, 0.6), CFrame.new(lockPos - Vector3.new(0, 2.3, 0)), Color3.fromRGB(80, 80, 88), Enum.Material.Metal)
	ctx.Data.lockLight = part(ctx.Folder, "LockLight", Vector3.new(0.6, 0.6, 0.6), CFrame.new(lockPos + Vector3.new(0, 1.5, 0)), Color3.fromRGB(255, 80, 60), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
	billboard(lock, "🔓 MAIN GATE LOCK\nNeeds all 8 department keys", Color3.fromRGB(255, 220, 110), Vector3.new(0, 4, 0), 150, UDim2.fromOffset(240, 60))
	local pp = Instance.new("ProximityPrompt") pp.ActionText = "Unlock the gate" pp.ObjectText = "Main Gate" pp.HoldDuration = 1
	pp.MaxActivationDistance = 9 pp.RequiresLineOfSight = false pp.Parent = lock
	ctx:Connect(pp.Triggered, function(player) M.unlock(ctx, player) end)
	-- patrols (route → pathfinding segments)
	ctx.Data.patrolReport = {}
	for _, pdef in ipairs(cfg.Patrols) do
		local route = cfg.Routes[pdef.Route]
		local pts
		if route == "anchors" then pts = sortAlong(routeFromAnchors(pdef.Route) or {})
		elseif type(route) == "table" and typeof(route[1]) == "string" then pts = sortAlong(routeFromRooms(route))
		else pts = route end
		if type(pts) == "table" and #pts >= 2 then
			local loop = #pts > 2 and typeof(route) == "table" and typeof(route[1]) == "Vector3" and pdef.Route:find("Courtyard") ~= nil -- courtyard squares loop, corridors go back and forth
			local order = table.clone(pts)
			if not loop then for i = #pts - 1, 2, -1 do table.insert(order, pts[i]) end end -- walk back the same way
			local segs = {}
			for i = 1, #order do
				local w = computePath(order[i], order[i % #order + 1])
				if w then table.insert(segs, w) end
			end
			if #segs > 0 then
				local npc = makeNpc(ctx, pdef.Kind, pts[1] + Vector3.new(0, 1, 0))
				if npc then
					npc.segments, npc.points = segs, pts
					table.insert(ctx.Data.npcs, npc)
					table.insert(ctx.Data.patrolReport, ("%s@%s(%d)"):format(pdef.Kind, pdef.Route, #segs))
				end
			else table.insert(ctx.Data.patrolReport, pdef.Route .. ":no path") end
		else table.insert(ctx.Data.patrolReport, pdef.Route .. ":no points") end
	end
	ctx:SetLocation(lockPos, "Main Gate")
	ctx.GotoPosition = ctx.Data.outside + Vector3.new(12, 0, 0)
	ctx.ScoreLabel = "Keys found 🔑"
	ctx.JoinMode = "button"
	print("[Escape] keys: " .. (function() local t = {} for id, k in pairs(ctx.Data.keyObjs) do table.insert(t, id .. "=" .. k.room) end return table.concat(t, ", ") end)())
	print("[Escape] patrols: " .. table.concat(ctx.Data.patrolReport, ", "))
end

function M.CanJoin(ctx, player)
	task.defer(function() if ctx:IsIn(player) then M.sendHud(ctx, player, { music = ctx.Phase == "Active" }) end end)
	return true
end

function M.unlock(ctx, player)
	if ctx.Phase ~= "Active" or not ctx:IsIn(player) or ctx.Data.escaped[player] then return end
	local n = teamCount(ctx)
	if n < #ctx.Data.keyDefs then ctx:Toast(player, ("🔒 Your team needs all %d keys (%d found)"):format(#ctx.Data.keyDefs, n)) return end
	ctx.Data.escaped[player] = true
	table.insert(ctx.Data.order, player)
	local place = #ctx.Data.order
	ctx:AddScore(player, math.max(50, 500 - (place - 1) * 25))
	ctx:ToastAll(("🏃 %s unlocked the Main Gate and ESCAPED! (#%d)"):format(player.DisplayName, place))
	M.sendHud(ctx, player, { escapedNow = true, place = place })
	if player.Character then
		local outside = ctx.Data.outside
		task.spawn(function() -- load the outside area first, then move them (no loading freeze)
			pcall(function() player:RequestStreamAroundAsync(outside, 3) end)
			if player.Character then player.Character:PivotTo(CFrame.new(outside)) end
		end)
	end
	ctx:Done(player, "🎒 You escaped — your equipment is unlocked!")
	local all = true
	for p in pairs(ctx.Participants) do if p.Parent and not ctx.Data.escaped[p] then all = false end end
	if all then task.delay(4, function() ctx:End("done") end) end
end

function M.Start(ctx)
	for p in pairs(ctx.Participants) do M.sendHud(ctx, p, { music = true }) end
	ctx:ToastAll("🗝️ Find the 8 department keys — and don't let the teachers or guards see you!")
	for _, n in ipairs(ctx.Data.npcs) do task.spawn(runNpc, ctx, n) end
	task.spawn(senses, ctx)
end

function M.OnPlayerLeft(ctx, p)
	if ctx.Data.detained[p] then
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed hum.JumpHeight = game.StarterPlayer.CharacterJumpHeight end
	end
	ctx.Data.detained[p] = nil
	ctx:Send(p, { type = "keys", hide = true })
end

function M.Finish(ctx)
	ctx.Ranking = table.clone(ctx.Data.order)
	ctx.RewardEligible, ctx.ExtraRewards = {}, {}
	for p in pairs(ctx.Participants) do ctx.RewardEligible[p] = true end
	for p in pairs(ctx.Data.escaped) do ctx.ExtraRewards[p] = { amount = ctx.Config.EscapeSchool.EscapeBonus, label = "🗝️ Escaped" } end
	ctx.WinnerText = #ctx.Data.order > 0 and ("🏃 %d student(s) escaped Samar College!"):format(#ctx.Data.order) or "🔒 Nobody escaped this time…"
	for p in pairs(ctx.Participants) do if p.Parent then ctx:Send(p, { type = "keys", hide = true }) end end
end

function M.Cleanup(ctx)
	for p in pairs(ctx.Data.detained or {}) do
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed hum.JumpHeight = game.StarterPlayer.CharacterJumpHeight end
	end
end

return M
