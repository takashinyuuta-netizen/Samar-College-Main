--[[ CampusLifeServer ────────────────────────────────────────────────────────
  The living campus: STUDENT, FACULTY and STAFF NPCs that follow the school clock
  (ReplicatedStorage.CampusLife.CampusLifeConfig).

  • Classrooms come from the "QuizBeeRoom" anchors (Department / Course / GradeLevel / room).
  • Faculty: each teaches 2 rooms; during class periods they walk to the room and teach at
    the front, in their vacant period they work in their faculty room, at breaks they relax.
  • Students: each has a section room; they walk to class and sit, then hang out at recess
    and eat at lunch.
  • Staff: guards, janitor, librarian, canteen staff, nurse, registrar at their posts.
  • NPCs open and close the campus doors (same hinge as the door scripts), chat with
    speech bubbles, and use idle / walk / run / wave / point / laugh / cheer / dance / sit
    animations. Players press "Talk" to open a conversation (see StarterGui.CampusLifeGui).
───────────────────────────────────────────────────────────────────────────]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local TweenService = game:GetService("TweenService")

local Shared = RS:WaitForChild("CampusLife")
local C = require(Shared:WaitForChild("CampusLifeConfig"))
local Remotes = Shared:WaitForChild("CampusLifeRemotes")
local campus = workspace:WaitForChild("SamarCollege_Campus")

task.wait(3) -- let the campus finish loading

---------------------------------------------------------------- folders
local npcFolder = campus:FindFirstChild("CampusNPCs") or Instance.new("Folder")
npcFolder.Name = "CampusNPCs" npcFolder.Parent = campus
for _, n in ipairs({ "Students", "Faculty", "Staff" }) do
	local f = npcFolder:FindFirstChild(n) or Instance.new("Folder") f.Name = n f.Parent = npcFolder
	f:ClearAllChildren()
end

-- NPCs don't bump into each other (no traffic jams in doorways)
pcall(function()
	if not PhysicsService:IsCollisionGroupRegistered("CampusNPC") then PhysicsService:RegisterCollisionGroup("CampusNPC") end
	PhysicsService:CollisionGroupSetCollidable("CampusNPC", "CampusNPC", false)
end)

---------------------------------------------------------------- helpers
local rand = Random.new()
local function pick(t) return t[rand:NextInteger(1, #t)] end
local function findRoom(name)
	for _, fl in ipairs(campus:GetChildren()) do
		local rooms = fl:FindFirstChild("02_Rooms")
		local r = rooms and rooms:FindFirstChild(name)
		if r then return r end
	end
end
local function boundsOf(inst)
	if inst:IsA("Model") then return inst:GetBoundingBox() end
	local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	for _, d in ipairs(inst:GetDescendants()) do if d:IsA("BasePart") then mn = mn:Min(d.Position - d.Size / 2) mx = mx:Max(d.Position + d.Size / 2) end end
	if mn.X > mx.X then return nil end
	return CFrame.new((mn + mx) / 2), mx - mn
end
local rayParams = RaycastParams.new() rayParams.FilterType = Enum.RaycastFilterType.Exclude
local spotCache = {}
-- clear floor spots INSIDE a room (cached). The room's Outside/Exterior decorations are ignored, so
-- the spots are on the room's own floor (between its walls, under its ceiling) — never in the courtyard.
local OUTSIDE_NAMES = { "^Outside", "^Exterior", "OutsideExtras", "CorridorWindow", "^Outside_" }
local function isOutsidePart(inst, room)
	local p = inst
	while p and p ~= room do
		for _, pat in ipairs(OUTSIDE_NAMES) do if p.Name:find(pat) then return true end end
		p = p.Parent
	end
	return false
end
local function spotsIn(room)
	if spotCache[room] then return spotCache[room] end
	local list = {}
	local mn, mx
	for _, d in ipairs(room:GetDescendants()) do
		if d:IsA("BasePart") and d.Size.Magnitude < 160 and not isOutsidePart(d, room) then
			local h = d.Size / 2
			local lo, hi = d.Position - h, d.Position + h
			mn = mn and mn:Min(lo) or lo
			mx = mx and mx:Max(hi) or hi
		end
	end
	if mn then
		rayParams.FilterDescendantsInstances = { npcFolder }
		local op = OverlapParams.new() op.FilterType = Enum.RaycastFilterType.Exclude op.FilterDescendantsInstances = { npcFolder }
		local floorY = mn.Y
		local center = (mn + mx) / 2
		for _ = 1, 160 do
			local x = mn.X + 1.8 + rand:NextNumber() * math.max(0, mx.X - mn.X - 3.6)
			local z = mn.Z + 1.8 + rand:NextNumber() * math.max(0, mx.Z - mn.Z - 3.6)
			local hit = workspace:Raycast(Vector3.new(x, floorY + 5, z), Vector3.new(0, -8, 0), rayParams)
			if hit and hit.Normal.Y > 0.9 and hit.Position.Y < floorY + 1.6 then
				local up = workspace:Raycast(hit.Position + Vector3.new(0, 0.5, 0), Vector3.new(0, 30, 0), rayParams) -- under a ceiling = indoors
				local clear = up ~= nil
				if clear then
					for _, b in ipairs(workspace:GetPartBoundsInBox(CFrame.new(hit.Position + Vector3.new(0, 2.8, 0)), Vector3.new(2.8, 4.4, 2.8), op)) do
						if b.CanCollide then clear = false break end
					end
				end
				if clear then table.insert(list, hit.Position + Vector3.new(0, 3, 0)) end
				if #list >= 12 then break end
			end
		end
		-- spots nearest the middle of the room first
		table.sort(list, function(a, b) return (Vector3.new(a.X, 0, a.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude < (Vector3.new(b.X, 0, b.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude end)
	end
	if #list == 0 then warn("[CampusLife] no free floor inside " .. room:GetFullName()) end
	spotCache[room] = list
	return list
end

---------------------------------------------------------------- places
local classrooms = {}
for _, a in ipairs(CollectionService:GetTagged("QuizBeeRoom")) do
	local r = a:FindFirstChild("Room") and a.Room.Value
	if r then
		local label = (a:GetAttribute("RoomName") or r.Name):match("^(.-) –") or a:GetAttribute("RoomName") or r.Name
		table.insert(classrooms, { model = r, label = label, dept = a:GetAttribute("Department"), course = a:GetAttribute("Course"),
			grade = a:GetAttribute("GradeLevel"), door = a.Position + Vector3.new(0, 2.5, 0), inside = a:GetAttribute("Inside") })
	end
end
table.sort(classrooms, function(x, y) return x.label < y.label end)
local courtyardSpots = {}
for _, s in ipairs(CollectionService:GetTagged("EventOpenArea")) do table.insert(courtyardSpots, s.Position + Vector3.new(0, 0.5, 0)) end
for x = 112, 180, 17 do for z = -20, 90, 22 do table.insert(courtyardSpots, Vector3.new(x, 3.5, z)) end end
local corridorSpots = {}
for _, c in ipairs(classrooms) do table.insert(corridorSpots, c.door) end

local function placeSpot(placeName)
	if placeName == "Courtyard" then return pick(courtyardSpots) end
	if placeName == "Corridor" then return pick(corridorSpots) + Vector3.new(rand:NextNumber(-3, 3), 0, rand:NextNumber(-3, 3)) end
	local r = findRoom(placeName)
	local spots = r and spotsIn(r)
	if spots and #spots > 0 then return spots[rand:NextInteger(1, math.min(#spots, 5))] end
	if r then local cf = r:IsA("Model") and r:GetPivot() or select(1, boundsOf(r)) if cf then return cf.Position end end
	return pick(courtyardSpots)
end
local PLACE_LABEL = { Courtyard = "the courtyard", Corridor = "the hallway", Canteen = "the canteen", Classroom_3F_009 = "the DLRC library" }

---------------------------------------------------------------- doors (NPCs open them like players do)
local doors = {}
for _, d in ipairs(campus:GetDescendants()) do
	if d:IsA("Model") and d.Name == "Door" then
		local hinge = d:FindFirstChild("Doorframe") and d.Doorframe:FindFirstChild("Hinge")
		local base = d:FindFirstChild("Base")
		local prompt = base and base:FindFirstChildOfClass("ProximityPrompt")
		if hinge and base and prompt then table.insert(doors, { hinge = hinge, base = base, prompt = prompt, closedCF = hinge.CFrame }) end
	end
end
local function nearDoor(pos)
	for _, d in ipairs(doors) do
		if (d.base.Position - pos).Magnitude < 6.5 and math.abs(d.base.Position.Y - pos.Y) < 6 then return d end
	end
end
local function openDoor(d)
	if d.prompt.ActionText == "Close" or d.npcOpen then return end -- already open
	d.npcOpen = true
	TweenService:Create(d.hinge, TweenInfo.new(0.8), { CFrame = d.closedCF * CFrame.Angles(0, math.rad(90), 0) }):Play()
	d.prompt.ActionText = "Close"
	task.delay(5, function()
		if d.prompt.ActionText == "Close" then
			TweenService:Create(d.hinge, TweenInfo.new(0.8), { CFrame = d.closedCF }):Play()
			d.prompt.ActionText = "Open"
		end
		d.npcOpen = false
	end)
end

---------------------------------------------------------------- appearance
local ANIMS = { idle = 507766388, walk = 507777826, run = 507767714, wave = 507770239, point = 507770453, cheer = 507770677,
	laugh = 507770818, dance = 507771019, sit = 2506281703, idle2 = 507766666 }
local ANIMS_R6 = { idle = 180435571, walk = 180426354, run = 180426354, wave = 128777973, point = 128853357, cheer = 129423030,
	laugh = 129423131, dance = 182435998, sit = 178130996, idle2 = 180435792 }

local goodHair = {}
do
	for _, id in ipairs(C.Hair) do
		local ok, model = pcall(function()
			local d = Instance.new("HumanoidDescription") d.HairAccessory = tostring(id)
			return Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15)
		end)
		if ok and model then
			if model:FindFirstChildOfClass("Accessory") then table.insert(goodHair, id) end
			model:Destroy()
		end
	end
end

local function buildBody(lookName, gender)
	local look = C.Uniforms[lookName] or C.Uniforms.College
	local d = Instance.new("HumanoidDescription")
	local skin = pick(C.SkinTones)
	d.HeadColor, d.LeftArmColor, d.RightArmColor = skin, skin, skin
	local torso = typeof(look.Torso) == "table" and pick(look.Torso) or look.Torso
	d.TorsoColor = torso
	d.LeftLegColor, d.RightLegColor = look.Legs, look.Legs
	if #goodHair > 0 then d.HairAccessory = tostring(pick(goodHair)) end
	d.HeightScale = (lookName == "Elementary") and 0.82 or rand:NextNumber(0.95, 1.05)
	d.WidthScale = rand:NextNumber(0.92, 1.02)
	local ok, model = pcall(function() return Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15) end)
	if not ok then warn("[CampusLife] body failed: " .. tostring(model)) return nil end
	return model
end

local function fromTemplate(name)
	local src = workspace:FindFirstChild(name)
	if not src then return nil end
	local m = src:Clone()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") or d:IsA("ClickDetector") then d:Destroy() end
		if d:IsA("BasePart") then d.Anchored = false end
	end
	return m
end

---------------------------------------------------------------- NPC records
local npcs = {}
local SUBJECTS = {
	Elementary = { "Math", "Science", "English", "Filipino", "Araling Panlipunan", "MAPEH", "EsP" },
	["Junior High"] = { "Mathematics", "Science", "English", "Filipino", "Araling Panlipunan", "TLE", "MAPEH", "Values Ed" },
	["Senior High"] = { "General Mathematics", "Oral Communication", "Research", "Earth Science", "Philosophy", "PE & Health", "Entrepreneurship" },
	College = { "Programming", "Database Systems", "Networking", "Purposive Communication", "Ethics", "Criminal Law", "Teaching Strategies" },
}
local function subjectsFor(room, level)
	return C.Subjects[room.course] or C.Subjects[level] or SUBJECTS[level]
end
local function levelGroup(room)
	if room.dept == "Elementary" then return "Elementary" end
	if room.dept == "College" then return "College" end
	if room.grade == "Grade 11" or room.grade == "Grade 12" then return "Senior High" end
	return "Junior High"
end
local function randomName(gender, title)
	local first = pick(gender == "F" and C.FirstNamesFemale or C.FirstNamesMale)
	local last = pick(C.LastNames)
	if title then return ("%s %s %s"):format(title, first, last) end
	return first .. " " .. last
end

local function setupAnims(n)
	local animator = n.hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", n.hum)
	local set = n.hum.RigType == Enum.HumanoidRigType.R15 and ANIMS or ANIMS_R6
	n.tracks = {}
	for name, id in pairs(set) do
		local a = Instance.new("Animation") a.AnimationId = "rbxassetid://" .. id
		local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
		if ok and tr then
			local loop = (name == "idle" or name == "idle2" or name == "walk" or name == "run" or name == "sit" or name == "dance")
			tr.Looped = loop
			tr.Priority = (name == "idle" or name == "idle2") and Enum.AnimationPriority.Idle or ((name == "walk" or name == "run") and Enum.AnimationPriority.Movement or Enum.AnimationPriority.Action)
			n.tracks[name] = tr
		end
	end
	n.hum.Running:Connect(function(speed)
		if n.hum.Sit then return end
		local want = speed < 0.5 and "idle" or (speed > 12 and "run" or "walk")
		if want == n.moveAnim then
			if want ~= "idle" and n.tracks[want] then n.tracks[want]:AdjustSpeed(math.max(0.6, speed / (want == "run" and 16 or 9))) end
			return
		end
		for _, k in ipairs({ "idle", "walk", "run" }) do if k ~= want and n.tracks[k] and n.tracks[k].IsPlaying then n.tracks[k]:Stop(0.25) end end
		if n.tracks[want] then n.tracks[want]:Play(0.25) end
		n.moveAnim = want
	end)
	n.hum.Seated:Connect(function(active)
		if active then
			for _, k in ipairs({ "idle", "walk", "run" }) do if n.tracks[k] then n.tracks[k]:Stop(0.2) end end
			if n.tracks.sit then n.tracks.sit:Play(0.2) end
			n.moveAnim = "sit"
		else
			if n.tracks.sit then n.tracks.sit:Stop(0.2) end
			if n.tracks.idle then n.tracks.idle:Play(0.2) end
			n.moveAnim = "idle"
		end
	end)
	if n.tracks.idle then n.tracks.idle:Play() n.moveAnim = "idle" end
end
local function gesture(n, name, t)
	local tr = n.tracks and n.tracks[name]
	if not tr or n.hum.Sit then return end
	tr:Play(0.15)
	task.delay(t or 2, function() if tr.IsPlaying then tr:Stop(0.3) end end)
end

local ICON = { Student = "🎒", Faculty = "📚", Staff = "🛠️" }
local function makeNpc(kind, profile, model, folder)
	model.Name = profile.name
	local hum = model:FindFirstChildOfClass("Humanoid")
	local rootPart = model:FindFirstChild("HumanoidRootPart")
	if not hum or not rootPart then model:Destroy() return nil end
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = kind == "Student" and rand:NextNumber(10, 13) or rand:NextNumber(8, 10)
	hum.BreakJointsOnDeath = false
	hum.MaxHealth, hum.Health = math.huge, math.huge
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.CollisionGroup = "CampusNPC" end end
	-- park new NPCs far away (frozen) until they're placed at their spot, so nobody sees them pile up at the spawn
	model:PivotTo(CFrame.new(0, 3000, 0))
	rootPart.Anchored = true
	-- the whole NPC streams in / out as ONE piece, so its head, name label and Talk prompt are always there
	-- together (with Default streaming the head could arrive late or vanish and break the dialogue)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = folder
	pcall(function() rootPart:SetNetworkOwner(nil) end)
	-- floating role label from the "Grow a Garden/Fisch" dialogue template (ServerStorage.NPCDialogueHeadGui)
	local head = model:FindFirstChild("Head") or rootPart
	local tmpl = game:GetService("ServerStorage"):FindFirstChild("NPCDialogueHeadGui")
	if tmpl then
		local g = tmpl:Clone() g.Name = "gui" g.MaxDistance = 22 g.Parent = head -- short range so far-away labels don't pile up
		g.name.Text = string.upper(profile.role)
		g.dialog.Text = ""
	end
	-- info the dialogue client uses to build this NPC's conversation
	model:SetAttribute("NPCKind", kind)
	model:SetAttribute("NPCRole", profile.role)
	model:SetAttribute("NPCDepartment", profile.department or "Samar College")
	model:SetAttribute("NPCGrade", profile.grade or "")
	model:SetAttribute("NPCCourse", profile.course or "")
	model:SetAttribute("NPCLevel", profile.level or "")
	model:SetAttribute("NPCSubject", profile.subject or "")
	model:SetAttribute("NPCRoom", profile.room and profile.room.label or "")
	model:SetAttribute("NPCSubjects", profile.subjects and table.concat(profile.subjects, ", ") or "")
	model:SetAttribute("NPCFacultyRoom", profile.facultyRoom and (profile.facultyRoom:gsub("_", " ")) or "")
	model:SetAttribute("NPCPost", profile.postName or "")
	if profile.activities then model:SetAttribute("NPCActivities", table.concat(profile.activities, "|")) end
	if profile.lines then model:SetAttribute("NPCLines", table.concat(profile.lines, "|")) end
	-- Talk prompt (tagged "NPCprompt" so the dialogue system hides prompts while you talk)
	local pp = Instance.new("ProximityPrompt") pp.Name = "TalkPrompt" pp.ActionText = "Talk" pp.ObjectText = profile.role
	game:GetService("CollectionService"):AddTag(pp, "NPCprompt")
	pp.HoldDuration = 0 pp.MaxActivationDistance = 12 pp.RequiresLineOfSight = false
	pp:SetAttribute("ReachOverCounter", true) -- you can talk across a desk / counter (walls still block)
	-- own key + always shown, so chair "Sit" / door prompts (E) never hide it
	pp.KeyboardKeyCode = Enum.KeyCode.T pp.GamepadKeyCode = Enum.KeyCode.ButtonY pp.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	pp.Parent = rootPart
	local n = { kind = kind, profile = profile, model = model, hum = hum, root = rootPart, head = head, prompt = pp,
		state = "Idle", activity = "standing around", lastLine = 0, plan = nil, asleep = true }
	setupAnims(n)
	pp.Triggered:Connect(function(player) startTalk(n, player) end)
	table.insert(npcs, n)
	return n
end

---------------------------------------------------------------- build the population
local byLevel = {}
for _, r in ipairs(classrooms) do local g = levelGroup(r) byLevel[g] = byLevel[g] or {} table.insert(byLevel[g], r) end

-- FACULTY: one per faculty room (C.Faculty). They stay in / around their faculty room.
local faculty = {}
do
	for _, f in ipairs(C.Faculty or {}) do
		local gender = rand:NextNumber() < 0.55 and "F" or "M"
		local title = f.Level == "College" and pick({ "Prof.", "Dr.", gender == "F" and "Ms." or "Mr." }) or (gender == "F" and pick({ "Ms.", "Mrs." }) or "Mr.")
		local profile = { name = randomName(gender, title), role = f.Role, department = f.Department, subject = f.Subject, level = f.Level,
			facultyRoom = f.Room, teaching = { false, false, false, false }, gender = gender }
		local model = buildBody("Faculty", gender)
		if model then
			local n = makeNpc("Faculty", profile, model, npcFolder.Faculty)
			if n then table.insert(faculty, n) end
		end
		task.wait()
	end
end

-- STUDENTS: spread over the classrooms
do
	for i = 1, C.Counts.Students do
		local r = classrooms[math.floor((i - 1) * #classrooms / math.max(1, C.Counts.Students)) + 1]
		local level = levelGroup(r)
		local gender = rand:NextNumber() < 0.5 and "F" or "M"
		local section = r.label
		local subjects = table.clone(subjectsFor(r, level))
		local profile = { name = randomName(gender), role = level == "College" and "College Student" or (level .. " Student"),
			department = r.dept, course = r.course, grade = r.grade, level = level, room = r, gender = gender,
			subjects = { subjects[1 + (i % #subjects)], subjects[1 + ((i + 2) % #subjects)], subjects[1 + ((i + 4) % #subjects)], subjects[1 + ((i + 5) % #subjects)] },
			hangout = C.StudentPlaces and C.StudentPlaces[i] ~= "Classroom" and C.StudentPlaces[i] or nil }
		local model = buildBody(level, gender)
		if model then makeNpc("Student", profile, model, npcFolder.Students) end
		task.wait()
	end
end

-- STAFF
do
	for _, sdef in ipairs(C.Staff) do
		local gender = (sdef.Role == "School Nurse" or sdef.Role == "Librarian") and "F" or (rand:NextNumber() < 0.5 and "F" or "M")
		local model = sdef.Template and fromTemplate(sdef.Template) or buildBody(sdef.Look or "Office", gender)
		if model then
			local profile = { name = randomName(gender, gender == "F" and "Ms." or "Mr."), role = sdef.Role, department = sdef.Department,
				post = sdef.Room or sdef.Spot, postName = sdef.PostName, activities = sdef.Activities, lines = sdef.Lines, gender = gender,
				seatPath = sdef.Seat, statusPath = sdef.Status }
			makeNpc("Staff", profile, model, npcFolder.Staff)
		end
	end
end

---------------------------------------------------------------- movement
local function observed(pos, radius)
	for _, p in ipairs(Players:GetPlayers()) do
		local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if r and (r.Position - pos).Magnitude < (radius or 70) then return true end
	end
	return false
end

-- walk to a position (pathfinding + doors). Unwatched NPCs whose path fails "arrive" instantly.
local function stale(n, token)
	return n.token ~= token or (n.planPeriod ~= nil and C.periodAt(C.schoolMinute()).Name ~= n.planPeriod)
end
local function walkTo(n, dest, token)
	if n.hum.Sit then n.hum.Sit = false task.wait(0.3) end
	local path = PathfindingService:CreatePath({ AgentRadius = 1.6, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 5, Costs = { Water = 20 } })
	local ok = pcall(function() path:ComputeAsync(n.root.Position, dest) end)
	if not ok or path.Status ~= Enum.PathStatus.Success then
		if not observed(n.root.Position) and not observed(dest) then n.model:PivotTo(CFrame.new(dest)) return true end
		return false
	end
	for _, wp in ipairs(path:GetWaypoints()) do
		if stale(n, token) then return false end
		while n.talking do task.wait(0.3) if stale(n, token) then return false end end
		-- someone came close: stop for a moment, turn to them and wave
		if not n.noticedAt or os.clock() - n.noticedAt > 12 then
			for _, pl in ipairs(Players:GetPlayers()) do
				local pr = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
				if pr and (pr.Position - n.root.Position).Magnitude < 6 then
					n.noticedAt = os.clock()
					n.hum:MoveTo(n.root.Position)
					n.root.CFrame = CFrame.lookAt(n.root.Position, Vector3.new(pr.Position.X, n.root.Position.Y, pr.Position.Z))
					gesture(n, "wave", 1.5)
					local t0 = os.clock()
					while os.clock() - t0 < 3.5 or n.talking do
						task.wait(0.2)
						if n.token ~= token then return false end
						if not n.talking and (not pr.Parent or (pr.Position - n.root.Position).Magnitude > 10) then break end
					end
					break
				end
			end
		end
		if wp.Action == Enum.PathWaypointAction.Jump then n.hum.Jump = true end
		local d = nearDoor(wp.Position)
		if d then openDoor(d) end
		n.hum:MoveTo(wp.Position)
		local t0 = os.clock()
		while (n.root.Position - wp.Position).Magnitude > 3.2 and os.clock() - t0 < 4 do
			if stale(n, token) then return false end
			task.wait(0.1)
		end
		if os.clock() - t0 >= 4 then -- stuck: try a jump, then teleport if nobody is watching
			n.hum.Jump = true
			if not observed(n.root.Position, 50) then n.model:PivotTo(CFrame.new(dest)) return true end
		end
	end
	return true
end

local function sitIn(n, room)
	if not room then return false end
	for _, s in ipairs(room:GetDescendants()) do
		if s:IsA("Seat") and not s.Occupant and not s:GetAttribute("NPCClaim") and (s.Position - n.root.Position).Magnitude < 60 then
			s:SetAttribute("NPCClaim", true)
			local ok = walkTo(n, s.Position + s.CFrame.LookVector * -0.5 + Vector3.new(0, 2.5, 0), n.token)
			if ok and not s.Occupant then s:Sit(n.hum) task.delay(1, function() s:SetAttribute("NPCClaim", nil) end) return true end
			s:SetAttribute("NPCClaim", nil)
			return false
		end
	end
	return false
end

---------------------------------------------------------------- what should each NPC be doing now?
local function classIndex(period)
	local i = 0
	for _, p in ipairs(C.Schedule) do if p.Kind == "Class" then i += 1 end if p == period then return i end end
end

-- the inside of the main gate: NPCs arrive here in the morning and leave here after class
local gateSpot
do
	local gate = campus:FindFirstChild("MainGate")
	local a = gate and gate:FindFirstChild("PromptAnchor_Inside")
	gateSpot = (a and a.Position or Vector3.new(30, 3.5, 8)) + Vector3.new(10, 0, 0)
end

local function decide(n, period)
	local P = n.profile
	if period.Kind == "Away" then return { key = "away", away = true } end
	if period.Kind == "GoHome" then
		return { key = "home", state = "Walking", activity = "going home", place = "the main gate", dest = gateSpot + Vector3.new(rand:NextNumber(-4, 4), 0, rand:NextNumber(-4, 4)), goHome = true }
	end
	if n.kind == "Faculty" then
		if period.Kind == "Class" then
			local room = P.teaching[classIndex(period)]
			if room then return { key = "teach:" .. room.label, state = "Teaching", activity = ("teaching %s in %s"):format(P.subject, room.label), dest = room.inside and (room.inside + Vector3.new(0, 0.5, 0)) or room.door, room = room, place = room.label, stand = true } end
			return { key = "faculty", state = "Working", activity = pick({ "checking papers", "preparing lesson plans", "encoding grades", "making a quiz" }), place = "the faculty room", dest = placeSpot(P.facultyRoom) }
		elseif period.Kind == "Lunch" then
			local where = rand:NextNumber() < 0.5 and "Canteen" or P.facultyRoom
			return { key = "lunch", state = "OnBreak", activity = "eating lunch", place = where == "Canteen" and "the canteen" or "the faculty room", dest = placeSpot(where) }
		end
		-- recess, before class, clubs: mostly in the faculty office
		return { key = "office:" .. period.Kind, state = period.Kind == "Free" and "Free" or "OnBreak", activity = pick({ "having coffee", "chatting with colleagues", "reading", "advising a student" }), place = "the faculty room", dest = placeSpot(P.facultyRoom) }
	elseif n.kind == "Student" then
		local room = P.room
		local function inRoom(act, state, key)
			local spots = room.model and spotsIn(room.model)
			local dest = (spots and #spots > 0) and pick(spots) or (room.inside and room.inside + Vector3.new(0, 0.5, 0)) or room.door
			return { key = key, state = state, activity = act, place = room.label, dest = dest, room = room, sit = true }
		end
		if period.Kind == "Class" then
			return inRoom(("in %s class"):format(P.subjects[classIndex(period)] or "a"), "InClass", "class" .. classIndex(period))
		elseif period.Kind == "Arrive" then
			return inRoom("waiting for class to start", "Free", "arrive")
		end
		local where = pick(C.Hangouts[period.Kind] or C.Hangouts.Free)
		if where == "Classroom" then return inRoom(pick({ "chatting with classmates", "reviewing notes", "eating snacks" }), period.Kind == "Free" and "Free" or "OnBreak", period.Kind .. ":room") end
		local act = period.Kind == "Lunch" and "eating lunch" or (period.Kind == "Break" and pick({ "buying snacks", "chatting with friends" }) or pick({ "at club activities", "studying", "hanging out" }))
		return { key = period.Kind .. ":" .. where, state = period.Kind == "Free" and "Free" or "OnBreak", activity = act, place = PLACE_LABEL[where] or where, dest = placeSpot(where) }
	else -- staff
		if period.Kind == "Lunch" and P.role ~= "Canteen Staff" and P.role ~= "Security Guard" then
			return { key = "lunch", state = "OnBreak", activity = "on lunch break", place = "the canteen", dest = placeSpot("Canteen") }
		end
		if P.post == "MainGate" then
			return { key = "post", state = "Working", activity = P.activities and pick(P.activities) or "guarding the main gate", place = "the main gate", dest = gateSpot + Vector3.new(-4, 0, -4) }
		elseif P.post == "Courtyard" then
			return { key = "patrol" .. tostring(math.floor(os.clock() / 40)), state = "Working", activity = P.activities and pick(P.activities) or "patrolling the courtyard", place = "the courtyard", dest = placeSpot("Courtyard") }
		elseif P.post == "Wander" then
			return { key = "clean" .. tostring(math.floor(os.clock() / 45)), state = "Working", activity = P.activities and pick(P.activities) or "cleaning the hallways", place = "the hallway", dest = placeSpot("Corridor") }
		end
		return { key = "post", state = "Working", activity = P.activities and pick(P.activities) or "working", place = P.postName or PLACE_LABEL[P.post] or P.post, dest = placeSpot(P.post) }
	end
end

-- go home: the NPC is put away until morning (no NPCs on campus at night)
local homeFolder = game:GetService("ServerStorage"):FindFirstChild("CampusNPCs_AtHome") or Instance.new("Folder")
homeFolder.Name = "CampusNPCs_AtHome" homeFolder.Parent = game:GetService("ServerStorage")
local function goHome(n)
	if n.hidden then return end
	if n.hum.Sit then n.hum.Sit = false end
	n.talking = nil
	n.hidden = true
	n.homeParent = n.model.Parent
	n.model.Parent = homeFolder
end
local function comeBack(n, at)
	if not n.hidden then return end
	n.hidden = false
	n.model:PivotTo(CFrame.new(at))
	n.model.Parent = n.homeParent or npcFolder
	pcall(function() n.root:SetNetworkOwner(nil) end)
end

-- Every NPC has a HOME spot (their office / classroom / post). They stand by there and only
-- patrol to a few points close by that are on the SAME floor with a clear straight line,
-- so they never wander into stairwells or fall to the ground floor.
local patrolRay = RaycastParams.new()
patrolRay.FilterType = Enum.RaycastFilterType.Exclude
patrolRay.RespectCanCollide = true
local function refreshRayFilter()
	local list = { npcFolder }
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(list, p.Character) end end
	patrolRay.FilterDescendantsInstances = list
end
local function floorAt(x, y, z, depth)
	local hit = workspace:Raycast(Vector3.new(x, y, z), Vector3.new(0, -(depth or 12), 0), patrolRay)
	if hit and hit.Normal.Y > 0.85 then return hit.Position.Y end
end
local function clearLine(a, b)
	local d = b - a
	return workspace:Raycast(a, d, patrolRay) == nil
end

local function homeFor(n)
	local P = n.profile
	if n.kind == "Student" and P.hangout then
		return placeSpot(P.hangout), PLACE_LABEL[P.hangout] or (P.hangout:gsub("_", " ")), false
	end
	if n.kind == "Student" then
		local spots = P.room.model and spotsIn(P.room.model)
		return (spots and #spots > 0) and pick(spots) or (P.room.inside and P.room.inside + Vector3.new(0, 0.5, 0)) or P.room.door, P.room.label, false
	elseif n.kind == "Faculty" then
		return placeSpot(P.facultyRoom), (P.facultyRoom:gsub("_", " ")), false
	end
	if P.post == "MainGate" then return gateSpot + Vector3.new(-4, 0, -4), "the main gate", true end
	if P.post == "Courtyard" then return pick(courtyardSpots), "the courtyard", true end
	if P.post == "Wander" then return pick(corridorSpots), "the hallway", true end
	return placeSpot(P.post), P.postName or P.post, false
end

-- "Cubicles.Cubicle_COED.DeanChair.Seat" inside the NPC's room -> that instance
local function pathIn(roomName, path)
	local x = roomName and findRoom(roomName)
	for part in string.gmatch(path or "", "[^%.]+") do x = x and x:FindFirstChild(part) end
	return x
end
local function setupHome(n)
	refreshRayFilter()
	local spot, label, outdoor = homeFor(n)
	-- office NPCs with their own chair (the college deans): home is right next to that chair
	local ownSeat = n.profile.seatPath and pathIn(n.profile.post, n.profile.seatPath)
	if ownSeat and ownSeat:IsA("Seat") then
		n.ownSeat = ownSeat
		spot = ownSeat.Position + Vector3.new(0, 3, 0)
	end
	n.statusSign = n.profile.statusPath and pathIn(n.profile.post, n.profile.statusPath) or nil
	local fy = floorAt(spot.X, spot.Y + 2, spot.Z, 14) or (spot.Y - 3)
	n.floorY = fy
	n.home = Vector3.new(spot.X, fy + 3, spot.Z)
	n.homeLabel = label
	local R = outdoor and (C.PatrolRadiusOutdoor or 16) or (C.PatrolRadius or 9)
	n.patrol = {}
	for _ = 1, 30 do
		if #n.patrol >= 6 then break end
		local ang, dist = rand:NextNumber(0, math.pi * 2), rand:NextNumber(3, R)
		local px, pz = n.home.X + math.cos(ang) * dist, n.home.Z + math.sin(ang) * dist
		local y = floorAt(px, fy + 4, pz, 8)
		local my = floorAt((px + n.home.X) / 2, fy + 4, (pz + n.home.Z) / 2, 8)
		if y and my and math.abs(y - fy) < 1.2 and math.abs(my - fy) < 1.2 then
			local p = Vector3.new(px, fy + 3, pz)
			-- clear at knee and chest height (no walls / desks in the way)
			if clearLine(Vector3.new(n.home.X, fy + 1.2, n.home.Z), Vector3.new(px, fy + 1.2, pz))
				and clearLine(Vector3.new(n.home.X, fy + 3, n.home.Z), Vector3.new(px, fy + 3, pz)) then
				table.insert(n.patrol, p)
			end
		end
	end
	-- a free seat close by (students sit during class)
	n.seats = {}
	if n.ownSeat then n.seats = { n.ownSeat } return end
	local seatRoom = n.kind == "Student" and (n.profile.hangout and findRoom(n.profile.hangout) or n.profile.room.model)
	if seatRoom then
		for _, st in ipairs(seatRoom:GetDescendants()) do
			if st:IsA("Seat") and math.abs(st.Position.Y - fy) < 4 and (Vector3.new(st.Position.X, 0, st.Position.Z) - Vector3.new(n.home.X, 0, n.home.Z)).Magnitude < 14 then
				table.insert(n.seats, st)
			end
		end
	end
end

local function flatDist(a, b) return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude end
local function stepTo(n, p)
	if n.hum.Sit then return end
	n.hum:MoveTo(p)
	local t0 = os.clock()
	while flatDist(n.root.Position, p) > 2 and os.clock() - t0 < 6 do
		if n.talking or n.asleep or n.hidden then n.hum:MoveTo(n.root.Position) return end
		task.wait(0.2)
	end
	if os.clock() - t0 >= 6 then n.hum:MoveTo(n.root.Position) end
end
local function putHome(n)
	n.root.AssemblyLinearVelocity = Vector3.zero
	n.model:PivotTo(CFrame.new(n.home) * CFrame.Angles(0, rand:NextNumber(0, math.pi * 2), 0))
end
local function trySit(n)
	for _, st in ipairs(n.seats) do
		if not st.Occupant and not st:GetAttribute("NPCClaim") then
			st:SetAttribute("NPCClaim", true)
			stepTo(n, st.Position + Vector3.new(0, 2.5, 0))
			if not st.Occupant and flatDist(n.root.Position, st.Position) < 5 and not n.talking then st:Sit(n.hum) end
			task.delay(2, function() st:SetAttribute("NPCClaim", nil) end)
			return
		end
	end
end

local function runNpc(n)
	n.token = 0
	while true do
		local period = C.periodAt(C.schoolMinute())
		if period.Kind == "Away" or period.Kind == "GoHome" then
			-- after class / at night: they leave the campus (disappear until morning)
			if not n.hidden then goHome(n) end
			task.wait(3)
		else
			if n.hidden then comeBack(n, n.home) n.sitKey = nil end
			local ok, want = pcall(decide, n, period)
			if ok and want then n.state, n.activity = want.state or "Working", want.activity or "standing by" end
			n.destination = n.homeLabel
			if n.asleep or n.talking then
				task.wait(2)
			else
				if n.ownSeat then
					-- deans stay at their desk (they stand up only to go home)
					if not n.hum.Sit then trySit(n) end
				elseif n.kind == "Student" and #n.seats > 0 and ((period.Kind == "Class" and not n.profile.hangout) or n.profile.hangout == "Canteen") then
					if not n.hum.Sit and n.sitKey ~= period.Name then n.sitKey = period.Name trySit(n) end
				else
					if n.hum.Sit then n.hum.Sit = false task.wait(0.6) end
					local r = rand:NextNumber()
					if r < 0.4 and #n.patrol > 0 then stepTo(n, pick(n.patrol))
					elseif r < 0.55 then stepTo(n, n.home)
					elseif r < 0.65 then
						local g = pick({ "wave", "laugh", "point", "idle2", n.kind == "Student" and "dance" or "cheer" })
						gesture(n, g, g == "dance" and 3 or 2)
					end
				end
				task.wait(rand:NextNumber(3, 7))
			end
		end
	end
end

-- "DEAN IS IN / OUT" signs follow the deans (IN while they're on campus, OUT after school / at night)
task.spawn(function()
	while true do
		task.wait(2)
		for _, n in ipairs(npcs) do
			if n.statusSign and n.statusSign.Parent then
				local inNow = not n.hidden
				if (n.statusSign:GetAttribute("On") == true) ~= inNow then n.statusSign:SetAttribute("On", inNow) end
			end
		end
	end
end)

-- fall guard: an NPC that drops below (or is flung above) its own floor goes straight back home
task.spawn(function()
	while true do
		task.wait(1)
		for _, n in ipairs(npcs) do
			if n.home and not n.hidden and not n.hum.Sit then
				local y = n.root.Position.Y
				if y < n.floorY - 2 or y > n.floorY + 12 or flatDist(n.root.Position, n.home) > 30 then putHome(n) end
			end
		end
	end
end)

-- performance: NPCs far from every player freeze (anchored, no physics) and wake up when someone comes near
task.spawn(function()
	while true do
		task.wait(1.5)
		local roots = {}
		for _, p in ipairs(Players:GetPlayers()) do
			local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if r then table.insert(roots, r.Position) end
		end
		for _, n in ipairs(npcs) do
			if n.home and not n.hidden then
				local near = false
				for _, pos in ipairs(roots) do if (pos - n.home).Magnitude < (C.WakeDistance or 140) then near = true break end end
				if near and n.asleep then
					n.asleep = false
					n.root.Anchored = false
					pcall(function() n.root:SetNetworkOwner(nil) end)
				elseif not near and not n.asleep and not n.talking then
					n.asleep = true
					n.hum:MoveTo(n.root.Position)
					if not n.hum.Sit then putHome(n) end
					n.root.Anchored = true
				end
			end
		end
	end
end)

---------------------------------------------------------------- conversations
local function scheduleFor(n)
	local P, list = n.profile, {}
	local ci = 0
	for _, p in ipairs(C.Schedule) do
		local line
		if p.Kind == "Class" then
			ci += 1
			if n.kind == "Faculty" then
				local r = P.teaching[ci]
				line = r and ("Teaching %s • %s (%s)"):format(P.subject, r.label, r.grade or "") or ("Vacant • Faculty room")
			elseif n.kind == "Student" then
				line = ("%s • %s"):format(P.subjects[ci] or "Class", P.room.label)
			else line = "On duty" end
		else
			line = p.Name
		end
		table.insert(list, { time = C.formatTime(p.FromMin) .. "–" .. C.formatTime(p.ToMin), what = line })
	end
	return list
end

function startTalk(n, player)
	if n.talking and n.talking ~= player then
		Remotes.NPCBubble:FireClient(player, n.head, "Sorry, I'm talking to someone else right now!")
		return
	end
	n.talking = player
	n.talkStarted = os.clock()
	if not n.hum.Sit then
		n.hum:MoveTo(n.root.Position)
		local pr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if pr then n.root.CFrame = CFrame.lookAt(n.root.Position, Vector3.new(pr.Position.X, n.root.Position.Y, pr.Position.Z)) end
		gesture(n, "wave", 1.6)
	end
	local P = n.profile
	local minute = C.schoolMinute()
	local period = C.periodAt(minute)
	local nextPeriod
	for _, p in ipairs(C.Schedule) do if p.FromMin > minute then nextPeriod = p break end end
	Remotes.NPCTalk:FireClient(player, {
		npc = n.model, kind = n.kind, name = P.name, role = P.role, department = P.department, course = P.course, grade = P.grade,
		level = P.level, subject = P.subject, room = P.room and P.room.label, post = P.postName or P.post,
		status = n.state, activity = n.activity, destination = n.destination, period = period.Name, periodKind = period.Kind,
		time = C.formatTime(minute), nextPeriod = nextPeriod and (nextPeriod.Name .. " at " .. C.formatTime(nextPeriod.FromMin)) or "tomorrow's 1st Period",
		schedule = scheduleFor(n), lines = P.lines,
	})
end
Remotes.NPCTalkClose.OnServerEvent:Connect(function(player)
	for _, n in ipairs(npcs) do if n.talking == player then n.talking = nil end end
end)
Players.PlayerRemoving:Connect(function(player) for _, n in ipairs(npcs) do if n.talking == player then n.talking = nil end end end)

---------------------------------------------------------------- ambient chatter (only near players)
local function lineFor(n, period)
	local pool = {}
	for _, l in ipairs(C.Lines.Any) do table.insert(pool, l) end
	local extra = n.kind == "Student" and C.Lines.Student or (n.kind == "Faculty" and C.Lines.Faculty or n.profile.lines)
	for _, l in ipairs(extra or {}) do table.insert(pool, l) table.insert(pool, l) end
	if period.Kind == "Lunch" then for _, l in ipairs(C.Lines.Lunch) do table.insert(pool, l) end end
	if n.kind == "Faculty" and n.state == "Teaching" then pool = C.Lines.Class end
	return pick(pool)
end
task.spawn(function()
	while true do
		task.wait(rand:NextNumber(2.5, 5))
		local period = C.periodAt(C.schoolMinute())
		local candidates = {}
		for _, n in ipairs(npcs) do
			if not n.hidden and n.model.Parent and not n.talking and os.clock() - n.lastLine > 18 and observed(n.root.Position, 55) then
				if not (n.kind == "Student" and n.state == "InClass" and rand:NextNumber() < 0.8) then table.insert(candidates, n) end
			end
		end
		if #candidates > 0 then
			local n = pick(candidates)
			n.lastLine = os.clock()
			Remotes.NPCBubble:FireAllClients(n.head, lineFor(n, period))
			if rand:NextNumber() < 0.5 then gesture(n, pick({ "point", "laugh", "wave" }), 1.5) end
			-- a nearby friend answers sometimes
			for _, o in ipairs(npcs) do
				if o ~= n and not o.hidden and not o.talking and (o.root.Position - n.root.Position).Magnitude < 10 and rand:NextNumber() < 0.5 then
					task.delay(rand:NextNumber(1.5, 3), function()
						o.lastLine = os.clock()
						Remotes.NPCBubble:FireAllClients(o.head, pick({ "Haha, true!", "Same!", "Really?", "Oo nga!", "Let's go then!", "Hello too!", "Ingat ka!" }))
						gesture(o, "laugh", 1.2)
					end)
					break
				end
			end
		end
		-- free NPCs whose talker walked away
		for _, n in ipairs(npcs) do
			if n.talking then
				local pr = n.talking.Character and n.talking.Character:FindFirstChild("HumanoidRootPart")
				if not pr or (pr.Position - n.root.Position).Magnitude > 25 or os.clock() - (n.talkStarted or 0) > 60 then n.talking = nil end
			end
		end
	end
end)

---------------------------------------------------------------- start everyone at their home spot
do
	local period = C.periodAt(C.schoolMinute())
	for i, n in ipairs(npcs) do
		setupHome(n)
		if period.Kind == "Away" or period.Kind == "GoHome" then goHome(n) else putHome(n) end
		task.spawn(runNpc, n)
		if i % 8 == 0 then task.wait() end
	end
end
workspace:SetAttribute("CampusNPCsReady", true) -- the loading screen waits for this
-- night watcher: at night everybody goes home right away (even NPCs still waiting for a path)
task.spawn(function()
	while true do
		task.wait(2)
		local k = C.periodAt(C.schoolMinute()).Kind
		if k == "Away" or k == "GoHome" then
			for _, n in ipairs(npcs) do
				if not n.hidden then n.token = (n.token or 0) + 1 goHome(n) end
			end
		end
	end
end)

print(("[CampusLife] %d NPCs on campus (%d classrooms, %d doors, %d hairstyles)"):format(#npcs, #classrooms, #doors, #goodHair))
