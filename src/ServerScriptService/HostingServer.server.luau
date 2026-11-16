--[[ HostingServer — any player can host a meeting / class / study group in any campus room.
  • No time limit: it lasts until the host ends it or leaves the server.
  • The host invites players in the server; invited players get a popup (Accept → teleported into the room).
    "Open" meetings can also be joined from the Sessions list; "Invite only" ones need an invite.
  • While hosted, the room has attribute HostedBy, so Quiz Bee / Guess the Drawing / Escape School keys
    skip it. A room an event is using right now can't be hosted.
  Remotes: HostingRemotes.Request (RemoteFunction, validated here) and Update (server → client). ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local TextService = game:GetService("TextService")
local HC = require(RS:WaitForChild("HostingConfig"))
local EM = require(script.Parent:WaitForChild("Events"):WaitForChild("EventManager"))
local Busy = require(script.Parent:WaitForChild("PlayerBusy")) -- parkour / event / game / stage: don't pull players away
local campus = workspace:WaitForChild("SamarCollege_Campus")
local remotes = RS:WaitForChild("HostingRemotes")
local Request, Update = remotes:WaitForChild("Request"), remotes:WaitForChild("Update")

local signFolder = Instance.new("Folder") signFolder.Name = "HostedMeetings" signFolder.Parent = workspace

---------------------------------------------------------------- room catalog
local function boundsOf(inst)
	if inst:IsA("Model") then return inst:GetBoundingBox() end
	local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	for _, d in ipairs(inst:GetDescendants()) do if d:IsA("BasePart") then mn = mn:Min(d.Position - d.Size / 2) mx = mx:Max(d.Position + d.Size / 2) end end
	if mn.X > mx.X then return nil end
	return CFrame.new((mn + mx) / 2), mx - mn
end

local rooms, roomOrder = {}, {}
do
	local anchorOf = {}
	for _, a in ipairs(CS:GetTagged("QuizBeeRoom")) do local r = a:FindFirstChild("Room") and a.Room.Value if r then anchorOf[r] = a end end
	for fi, flName in ipairs(HC.FloorOrder) do
		local fl = campus:FindFirstChild(flName)
		local folder = fl and fl:FindFirstChild("02_Rooms")
		if folder then
			for _, m in ipairs(folder:GetChildren()) do
				if (m:IsA("Model") or m:IsA("Folder")) and not HC.excluded(m.Name) then
					local cf, size = boundsOf(m)
					if cf and size.X > 6 and size.Z > 6 then
						local a = anchorOf[m]
						local R = { key = flName .. "/" .. m.Name, inst = m, anchor = a, cf = cf, size = size, fi = fi,
							label = a and a:GetAttribute("RoomName") or HC.pretty(m.Name), floor = HC.FloorLabel[flName] or flName }
						rooms[R.key] = R table.insert(roomOrder, R)
					end
				end
			end
		end
	end
	table.sort(roomOrder, function(a, b) if a.fi ~= b.fi then return a.fi < b.fi end return a.label < b.label end)
end

local rayParams = RaycastParams.new() rayParams.FilterType = Enum.RaycastFilterType.Exclude
local overlap = OverlapParams.new() overlap.FilterType = Enum.RaycastFilterType.Exclude
local function spotIn(R)
	local ex = { signFolder }
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ex, p.Character) end end
	rayParams.FilterDescendantsInstances = ex overlap.FilterDescendantsInstances = ex
	local cf, size = R.cf, R.size
	for _ = 1, 30 do
		local x, z = (math.random() - 0.5) * size.X * 0.6, (math.random() - 0.5) * size.Z * 0.6
		local top = cf:PointToWorldSpace(Vector3.new(x, size.Y / 2 - 1, z))
		local hit = workspace:Raycast(top, Vector3.new(0, -size.Y, 0), rayParams)
		if hit and hit.Normal.Y > 0.9 and hit.Position.Y < cf.Y - size.Y / 2 + 4 then
			local clear = true
			for _, b in ipairs(workspace:GetPartBoundsInBox(CFrame.new(hit.Position + Vector3.new(0, 2.6, 0)), Vector3.new(2.5, 4, 2.5), overlap)) do
				if b.CanCollide then clear = false break end
			end
			if clear then return hit.Position + Vector3.new(0, 3, 0) end
		end
	end
	local inside = R.anchor and R.anchor:GetAttribute("Inside")
	if typeof(inside) == "Vector3" then return inside + Vector3.new(math.random(-2, 2), 3, math.random(-2, 2)) end
	return Vector3.new(cf.X, cf.Y - size.Y / 2 + 3.5, cf.Z)
end

local function insideBox(R, pos, pad)
	local l = R.cf:PointToObjectSpace(pos)
	local h = R.size / 2 + Vector3.new(pad, pad, pad)
	return math.abs(l.X) <= h.X and math.abs(l.Y) <= h.Y and math.abs(l.Z) <= h.Z
end
-- name of the campus event using this room right now, if any
local function eventIn(R)
	local ctx = EM.current()
	if not ctx or ctx.Phase == "Results" then return nil end
	local d = ctx.Data or {}
	if d.roomBox and d.roomBox[1] == R.inst then return ctx.Def.Name end
	for _, p in ipairs({ ctx.Location, ctx.GotoPosition }) do
		if typeof(p) == "Vector3" and insideBox(R, p, 1) then return ctx.Def.Name end
	end
	return nil
end

local function teleport(p, pos)
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	pcall(function() p:RequestStreamAroundAsync(pos, 5) end)
	hum.Sit = false
	char:PivotTo(CFrame.new(pos))
	return true
end
local function toSpawn(p)
	local sp = workspace:FindFirstChild("SpawnLocation")
	if sp then teleport(p, sp.Position + Vector3.new(math.random(-4, 4), 4, math.random(-4, 4))) end
end

---------------------------------------------------------------- sessions
local sessions, byHost, inSession = {}, {}, {}
local nextId = 0

local function countOf(S) local n = 0 for _ in pairs(S.attendees) do n += 1 end return n end

local function view(S, forHost)
	local att = {}
	for p in pairs(S.attendees) do table.insert(att, { userId = p.UserId, name = p.DisplayName, user = p.Name, host = p == S.host }) end
	table.sort(att, function(a, b) if a.host ~= b.host then return a.host end return a.name < b.name end)
	local v = { id = S.id, title = S.title, type = S.type, privacy = S.privacy, room = S.room.label, floor = S.room.floor,
		host = S.host.DisplayName, hostId = S.host.UserId, startedAt = S.startedAt, count = #att, attendees = att }
	if forHost then v.invited = {} for uid in pairs(S.invited) do table.insert(v.invited, uid) end end
	return v
end

local pushQueued = false
local function push()
	if pushQueued then return end
	pushQueued = true
	task.defer(function()
		pushQueued = false
		local list = {}
		for _, S in pairs(sessions) do table.insert(list, view(S)) end
		table.sort(list, function(a, b) return a.startedAt < b.startedAt end)
		for _, p in ipairs(Players:GetPlayers()) do
			local S = inSession[p]
			Update:FireClient(p, { kind = "state", mine = S and view(S, S.host == p) or nil, isHost = S ~= nil and S.host == p, sessions = list, now = os.time() })
		end
	end)
end
local function toast(p, text) if p and p.Parent then Update:FireClient(p, { kind = "toast", text = text }) end end

local function updateSign(S)
	if not S.sign then return end
	local t = HC.type(S.type)
	for _, l in ipairs(S.sign:GetDescendants()) do
		if l.Name == "L1" then l.Text = t.Icon .. " " .. t.Name:upper() .. "  •  " .. S.title
		elseif l.Name == "L2" then l.Text = ("Hosted by %s  •  %s  •  %d inside"):format(S.host.DisplayName, S.privacy == "Open" and "🔓 Open" or "🔒 Invite only", countOf(S)) end
	end
end
local function makeSign(S)
	local R = S.room
	local m = Instance.new("Model") m.Name = "Meeting_" .. S.id
	local function sign(pos, dist)
		local p = Instance.new("Part") p.Name = "Sign" p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.Transparency = 1
		p.Size = Vector3.new(1, 1, 1) p.Position = pos p.Parent = m
		local bb = Instance.new("BillboardGui") bb.Size = UDim2.fromOffset(300, 62) bb.MaxDistance = dist bb.LightInfluence = 0 bb.Parent = p
		local f = Instance.new("Frame") f.Size = UDim2.fromScale(1, 1) f.BackgroundColor3 = Color3.fromRGB(18, 40, 28) f.BackgroundTransparency = 0.15 f.Parent = bb
		Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
		local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(240, 196, 70) st.Thickness = 2 st.Parent = f
		for i, n in ipairs({ "L1", "L2" }) do
			local t = Instance.new("TextLabel") t.Name = n t.BackgroundTransparency = 1 t.TextScaled = true t.TextColor3 = i == 1 and Color3.fromRGB(255, 222, 120) or Color3.new(1, 1, 1)
			t.Font = i == 1 and Enum.Font.GothamBlack or Enum.Font.GothamBold
			t.Position = UDim2.new(0, 8, i == 1 and 0.06 or 0.56, 0) t.Size = UDim2.new(1, -16, i == 1 and 0.48 or 0.36, 0) t.Parent = f
		end
	end
	-- ONE sign, above the door on the hallway side (no sign inside the room — it showed through the doorway)
	if R.anchor then
		sign(R.anchor.Position + Vector3.new(0, 6.5, 0), 45)
	else
		local door = R.door
		if door == nil then
			R.door = false
			-- nearest door of the same floor whose centre is inside / at the edge of the room
			local doors = R.inst.Parent and R.inst.Parent.Parent and R.inst.Parent.Parent:FindFirstChild("03_Doors")
			local best, bestD = nil, math.huge
			for _, d in ipairs(doors and doors:GetChildren() or {}) do
				local ok, dcf = pcall(function() return (d:GetBoundingBox()) end)
				if ok and insideBox(R, dcf.Position, 3) then
					local dist = (Vector3.new(dcf.X, 0, dcf.Z) - Vector3.new(R.cf.X, 0, R.cf.Z)).Magnitude
					if dist < bestD then best, bestD = dcf.Position, dist end
				end
			end
			-- some rooms keep their door inside the room model itself
			if not best then
				for _, d in ipairs(R.inst:GetDescendants()) do
					if d:IsA("Model") and d.Name:lower():find("door") then
						local ok, dcf = pcall(function() return (d:GetBoundingBox()) end)
						if ok then
							local dist = (Vector3.new(dcf.X, 0, dcf.Z) - Vector3.new(R.cf.X, 0, R.cf.Z)).Magnitude
							if dist < bestD then best, bestD = dcf.Position, dist end
						end
					end
				end
			end
			if best then
				-- push the sign 1.6 studs out of the room so it hangs in the hallway, not inside
				local out = Vector3.new(best.X - R.cf.X, 0, best.Z - R.cf.Z)
				local l = R.cf:VectorToObjectSpace(out)
				-- snap to the room's nearest wall direction
				local axis = (math.abs(l.X) / R.size.X > math.abs(l.Z) / R.size.Z) and R.cf:VectorToWorldSpace(Vector3.new(math.sign(l.X), 0, 0)) or R.cf:VectorToWorldSpace(Vector3.new(0, 0, math.sign(l.Z)))
				R.door = Vector3.new(best.X, R.cf.Y - R.size.Y / 2, best.Z) + axis * 1.6
			else
				-- open-entrance room (no door): hang the sign just outside the wall that faces the hallway
				local near, nd = nil, math.huge
				for _, d in ipairs(doors and doors:GetChildren() or {}) do
					local ok, dcf = pcall(function() return (d:GetBoundingBox()) end)
					if ok then
						local dist = (Vector3.new(dcf.X, 0, dcf.Z) - Vector3.new(R.cf.X, 0, R.cf.Z)).Magnitude
						if dist < nd then near, nd = dcf.Position, dist end
					end
				end
				if near then
					local l = R.cf:PointToObjectSpace(near)
					local off
					if math.abs(l.X) / R.size.X > math.abs(l.Z) / R.size.Z then
						off = Vector3.new(math.sign(l.X) * (R.size.X / 2 + 1.6), 0, math.clamp(l.Z, -R.size.Z / 2 + 3, R.size.Z / 2 - 3))
					else
						off = Vector3.new(math.clamp(l.X, -R.size.X / 2 + 3, R.size.X / 2 - 3), 0, math.sign(l.Z) * (R.size.Z / 2 + 1.6))
					end
					local w = R.cf:PointToWorldSpace(off)
					R.door = Vector3.new(w.X, R.cf.Y - R.size.Y / 2, w.Z)
				end
			end
			door = R.door
		end
		if door then
			sign(door + Vector3.new(0, 9.6, 0), 45)
		else
			-- no door found: small sign at the room's entrance height in the middle (last resort)
			local floorY = R.cf.Y - R.size.Y / 2
			sign(Vector3.new(R.cf.X, floorY + math.clamp(R.size.Y - 2, 6, 8.5), R.cf.Z), 40)
		end
	end
	m.Parent = signFolder
	S.sign = m
	updateSign(S)
end

local function setAttrs(p, S)
	p:SetAttribute("MeetingId", S and S.id or nil)
	p:SetAttribute("MeetingRoom", S and S.room.label or nil)
	p:SetAttribute("MeetingHost", S and S.host == p or nil)
end

local endSession
local function leave(p)
	local S = inSession[p]
	if not S then return end
	if S.host == p then endSession(S, "The host ended the meeting") return end
	S.attendees[p] = nil inSession[p] = nil setAttrs(p, nil)
	updateSign(S) push()
end
function endSession(S, why)
	if not sessions[S.id] then return end
	sessions[S.id] = nil byHost[S.host] = nil
	for p in pairs(S.attendees) do
		inSession[p] = nil setAttrs(p, nil)
		if p ~= S.host then toast(p, "📌 " .. why) end
	end
	S.room.inst:SetAttribute("HostedBy", nil) S.room.inst:SetAttribute("HostedTitle", nil)
	if S.sign then S.sign:Destroy() end
	push()
end

local function join(p, S)
	local busy = Busy.reason(p)
	if busy then return false, busy end
	if inSession[p] == S then teleport(p, spotIn(S.room)) return true, "Back in " .. S.room.label end
	if countOf(S) >= HC.MaxAttendees then return false, "This meeting is full" end
	if byHost[p] and byHost[p] ~= S then return false, "End your own meeting first" end
	leave(p)
	S.attendees[p] = true inSession[p] = S setAttrs(p, S)
	teleport(p, spotIn(S.room))
	if p ~= S.host then toast(S.host, "👋 " .. p.DisplayName .. " joined your " .. HC.type(S.type).Name:lower()) end
	updateSign(S) push()
	return true, "Joined: " .. S.title
end

local function filterTitle(text, player)
	local ok, res = pcall(function()
		return TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat):GetNonChatStringForBroadcastAsync()
	end)
	return ok and res or nil
end

---------------------------------------------------------------- requests
local callLog, inviteAt, gotoAt = {}, {}, {}
local function roomState(R)
	local hb = R.inst:GetAttribute("HostedBy")
	if hb then return "hosted", hb end
	local ev = eventIn(R)
	if ev then return "event", ev end
	return "free"
end

local handlers = {}
function handlers.state(p) push() return { ok = true } end

function handlers.rooms(p)
	local list = {}
	for _, R in ipairs(roomOrder) do
		local st, by = roomState(R)
		table.insert(list, { key = R.key, label = R.label, floor = R.floor, state = st, by = by })
	end
	return { ok = true, rooms = list }
end

function handlers.host(p, d)
	if byHost[p] then return { ok = false, msg = "You're already hosting — end that meeting first" } end
	local busy = Busy.reason(p)
	if busy then return { ok = false, msg = busy } end
	local R = type(d.room) == "string" and rooms[d.room]
	if not R then return { ok = false, msg = "Pick a room first" } end
	local st, by = roomState(R)
	if st == "hosted" then return { ok = false, msg = R.label .. " is already hosted by " .. by } end
	if st == "event" then return { ok = false, msg = by .. " is using " .. R.label .. " right now" } end
	local t = HC.type(d.type)
	local title = type(d.title) == "string" and d.title:gsub("[%c]", " "):match("^%s*(.-)%s*$"):sub(1, HC.MaxTitle) or ""
	if title ~= "" then title = filterTitle(title, p) or "" end
	if title == "" or not title:find("[^#%s]") then title = p.DisplayName .. "'s " .. t.Name end
	nextId += 1
	local S = { id = nextId, host = p, room = R, title = title, type = t.Id, privacy = d.privacy == "Invite" and "Invite" or "Open",
		invited = {}, attendees = {}, startedAt = os.time() }
	sessions[S.id] = S byHost[p] = S
	R.inst:SetAttribute("HostedBy", p.DisplayName) R.inst:SetAttribute("HostedTitle", title)
	makeSign(S)
	join(p, S)
	return { ok = true, msg = ("%s %s started in %s"):format(t.Icon, t.Name, R.label) }
end

function handlers.invite(p, d)
	local S = byHost[p]
	if not S then return { ok = false, msg = "Host a meeting first" } end
	local t = Players:GetPlayerByUserId(tonumber(d.userId) or 0)
	if not t or t == p then return { ok = false, msg = "That player isn't in the server" } end
	if S.attendees[t] then return { ok = false, msg = t.DisplayName .. " is already in your meeting" } end
	local k = p.UserId .. ":" .. t.UserId
	if inviteAt[k] and os.clock() - inviteAt[k] < HC.InviteCooldown then return { ok = false, msg = "Wait a moment before inviting " .. t.DisplayName .. " again" } end
	inviteAt[k] = os.clock()
	S.invited[t.UserId] = true
	local ty = HC.type(S.type)
	Update:FireClient(t, { kind = "invite", id = S.id, from = p.DisplayName, fromId = p.UserId, title = S.title, type = S.type,
		icon = ty.Icon, typeName = ty.Name, room = S.room.label, floor = S.room.floor })
	push()
	return { ok = true, msg = "📩 Invite sent to " .. t.DisplayName }
end

local function canEnter(p, S) return S.privacy == "Open" or S.invited[p.UserId] or S.host == p end
function handlers.accept(p, d)
	local S = sessions[tonumber(d.id) or 0]
	if not S then return { ok = false, msg = "That meeting already ended" } end
	if not canEnter(p, S) then return { ok = false, msg = "This meeting is invite only" } end
	local ok, msg = join(p, S)
	return { ok = ok, msg = msg }
end
handlers.join = handlers.accept

function handlers.decline(p, d)
	local S = sessions[tonumber(d.id) or 0]
	if S and S.invited[p.UserId] then toast(S.host, "🙅 " .. p.DisplayName .. " can't join right now") end
	return { ok = true }
end

function handlers.leave(p)
	local S = inSession[p]
	if not S then return { ok = false, msg = "You're not in a meeting" } end
	if S.host == p then endSession(S, "The host ended the meeting") return { ok = true, msg = "Meeting ended" } end
	leave(p) toast(S.host, "🚶 " .. p.DisplayName .. " left your meeting")
	return { ok = true, msg = "You left the meeting" }
end
handlers["end"] = function(p)
	local S = byHost[p]
	if not S then return { ok = false, msg = "You aren't hosting" } end
	endSession(S, "The host ended the meeting")
	return { ok = true, msg = "Meeting ended" }
end

function handlers.kick(p, d)
	local S = byHost[p]
	local t = Players:GetPlayerByUserId(tonumber(d.userId) or 0)
	if not S or not t or t == p or not S.attendees[t] then return { ok = false } end
	S.invited[t.UserId] = nil
	leave(t) toSpawn(t) toast(t, "You were removed from " .. S.title)
	return { ok = true, msg = t.DisplayName .. " was removed" }
end

function handlers.bring(p)
	local S = byHost[p]
	if not S then return { ok = false } end
	local brought, skipped = 0, 0
	for a in pairs(S.attendees) do
		if a ~= p then
			if Busy.isBusy(a) then skipped += 1 else teleport(a, spotIn(S.room)) brought += 1 end
		end
	end
	return { ok = true, msg = ("Everyone was brought to %s%s"):format(S.room.label, skipped > 0 and (" (%d busy in an event / game / Parkour)"):format(skipped) or "") }
end

function handlers.goto(p)
	local S = inSession[p]
	if not S then return { ok = false } end
	if gotoAt[p] and os.clock() - gotoAt[p] < 5 then return { ok = false, msg = "Wait a moment" } end
	local busy = Busy.reason(p)
	if busy then return { ok = false, msg = busy } end
	gotoAt[p] = os.clock()
	teleport(p, spotIn(S.room))
	return { ok = true, msg = "Back in " .. S.room.label }
end

function handlers.privacy(p)
	local S = byHost[p]
	if not S then return { ok = false } end
	S.privacy = S.privacy == "Open" and "Invite" or "Open"
	updateSign(S) push()
	return { ok = true, msg = S.privacy == "Open" and "🔓 Anyone can join now" or "🔒 Invite only" }
end

Request.OnServerInvoke = function(p, action, data)
	local now = os.clock()
	local log = callLog[p]
	if not log or now - log.t > 1 then log = { t = now, n = 0 } callLog[p] = log end
	log.n += 1
	if log.n > 10 then return { ok = false, msg = "Slow down" } end
	local h = type(action) == "string" and handlers[action]
	if not h then return { ok = false } end
	local ok, res = pcall(h, p, type(data) == "table" and data or {})
	if not ok then warn("[Hosting] " .. action .. ": " .. tostring(res)) return { ok = false, msg = "Something went wrong" } end
	return res
end

Players.PlayerRemoving:Connect(function(p)
	local S = byHost[p]
	if S then endSession(S, "The host left the server") else leave(p) end
	callLog[p] = nil gotoAt[p] = nil
end)
Players.PlayerAdded:Connect(function() push() end)

print(("[Hosting] %d rooms can be hosted"):format(#roomOrder))
