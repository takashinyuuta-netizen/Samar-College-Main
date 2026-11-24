--[[ InteriorCulling — the big school FPS fix (client only, each player sees their own).
  The campus has ~200,000 parts and ~160,000 of them are room furniture, props, lights, fans, signs and
  effects INSIDE the building. Looking at the school, the device had to draw all of it, even rooms far away.
  Now every room / common area / prop group (tagged SC_CullGroup, with CullCenter / CullHalf / CullKind
  attributes) hides its DETAIL items while your camera is far from it, and puts them back when you get close.
  Walls, floors, ceilings, roofs, windows, doors, stairs and railings always stay, so the building still
  looks complete from outside. Hidden items are removed from the scene for you only (not deleted, not
  changed for anyone else), so they cost nothing: no drawing, no shadows, no lights, no signs, no effects.
  Closer range on phones / tablets and with "Improve FPS" on. ]]
local Players = game:GetService("Players")
local CS = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

local IS_MOBILE = (UIS.TouchEnabled and not UIS.KeyboardEnabled) or game:GetService("GuiService"):IsTenFootInterface()
-- show range (studs from the camera to the edge of the room's box)
local RANGE_PC = { room = 220, common = 260, props = 300 }
local RANGE_LOW = { room = 130, common = 160, props = 190 }
local HYST = 10                -- extra distance before hiding again (no flicker at the border)
local OPS_PER_FRAME = IS_MOBILE and 250 or 500

local STRUCT = { "wall", "floor", "ceiling", "door", "gate", "window", "glass", "stair", "step", "rail",
	"elevator", "shell", "structure", "roof", "beam", "column", "pillar", "louver", "frame", "jamb", "slab",
	"partition", "curtain", "blind", "shutter", "outside", "exterior", "facade", "awning", "canopy" }
local structCache = {}
local function structural(name)
	local v = structCache[name]
	if v ~= nil then return v end
	local n = name:lower()
	v = false
	for _, k in ipairs(STRUCT) do if n:find(k, 1, true) then v = true break end end
	structCache[name] = v
	return v
end
local function isBox(c) return c:IsA("BasePart") or c:IsA("Model") or c:IsA("Folder") end

-- true if this whole item is "detail" (small things, nothing structural, no E prompt)
local function isDetail(inst, memo)
	local m = memo[inst]
	if m ~= nil then return m end
	local ok = not structural(inst.Name) and not inst:GetAttribute("MeshMerged") and inst.Name ~= "RoomMerged"
	if ok and inst:IsA("BasePart") and not inst.Anchored then ok = false end
	if ok and inst:IsA("BasePart") then
		local s = inst.Size
		if math.max(s.X, s.Y, s.Z) >= 10 then ok = false end
	end
	if ok then
		for _, c in ipairs(inst:GetChildren()) do
			if c:IsA("ProximityPrompt") or (isBox(c) and not isDetail(c, memo)) then ok = false break end
		end
	end
	memo[inst] = ok
	return ok
end

local holder = Instance.new("Folder")   -- never in the world: hidden items wait here
holder.Name = "SC_HiddenInterior"

local groups = {}   -- [instance] = state
-- two work queues (array + read position, so taking the next job is instant)
local Q = { show = { h = 1, t = 0 }, hide = { h = 1, t = 0 } }
local function push(q, fn) q.t += 1 q[q.t] = fn end
local function run(q, budget)
	local n = 0
	while q.h <= q.t and n < budget do
		local fn = q[q.h]
		q[q.h] = nil
		q.h += 1
		fn()
		n += 1
	end
	if q.h > q.t then q.h, q.t = 1, 0 end
	return n
end

local function collect(node, memo, out)
	for _, c in ipairs(node:GetChildren()) do
		if isBox(c) then
			-- doors / anything with a prompt or moving (unanchored) parts is never hidden: keep it whole
			if c:FindFirstChildWhichIsA("ProximityPrompt", true) or (c:IsA("BasePart") and not c.Anchored) then
				-- skip
			elseif isDetail(c, memo) then table.insert(out, c) else collect(c, memo, out) end
		end
	end
end

local function hideGroup(g)
	local st = groups[g]
	if not st or st.hidden then return end
	st.hidden = true
	local list = {}
	collect(st.inst, {}, list)
	st.items = st.items or {}
	for _, it in ipairs(list) do
		push(Q.hide, function()
			if st.hidden and it.Parent and it.Parent ~= holder then
				st.items[it] = it.Parent
				pcall(function() it.Parent = holder end)
			end
		end)
	end
end

local function showGroup(g)
	local st = groups[g]
	if not st or not st.hidden then return end
	st.hidden = false
	local items = st.items or {}
	st.items = {}
	for it, parent in pairs(items) do
		push(Q.show, function() -- showing goes first: what you walk toward appears quickly
			if not st.hidden and parent.Parent then
				st.restoring = true
				pcall(function() it.Parent = parent end)
				st.restoring = false
			elseif st.hidden then
				st.items[it] = parent -- hidden again before it came back
			end
		end)
	end
end

local function addGroup(inst)
	if groups[inst] then return end
	local c, h = inst:GetAttribute("CullCenter"), inst:GetAttribute("CullHalf")
	if typeof(c) ~= "Vector3" or typeof(h) ~= "Vector3" then return end
	local st = { inst = inst, center = c, half = h, kind = inst:GetAttribute("CullKind") or "room", hidden = false, items = {} }
	groups[inst] = st
	-- parts that stream in while the group is hidden are hidden too
	inst.DescendantAdded:Connect(function(d)
		if not st.hidden or st.restoring or not isBox(d) then return end
		task.defer(function()
			if st.hidden and d.Parent and d.Parent ~= holder and d:IsDescendantOf(inst) and isDetail(d, {}) then
				st.items[d] = d.Parent
				pcall(function() d.Parent = holder end)
			end
		end)
	end)
end
for _, g in ipairs(CS:GetTagged("SC_CullGroup")) do addGroup(g) end
CS:GetInstanceAddedSignal("SC_CullGroup"):Connect(addGroup)

-- distance from a point to the room's box
local function boxDist(p, c, h)
	local d = (p - c)
	local dx = math.max(math.abs(d.X) - h.X, 0)
	local dy = math.max(math.abs(d.Y) - h.Y, 0)
	local dz = math.max(math.abs(d.Z) - h.Z, 0)
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function update()
	if player:GetAttribute("SC_CullingOff") then -- testing switch: show everything
		for g, st in pairs(groups) do if st.hidden then showGroup(g) end end
		return
	end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local p = cam.CFrame.Position
	local low = IS_MOBILE or player:GetAttribute("Setting_ImproveFPS") == true
	local R = low and RANGE_LOW or RANGE_PC
	for g, st in pairs(groups) do
		if not g.Parent then groups[g] = nil
		else
			local r = R[st.kind] or R.room
			local d = boxDist(p, st.center, st.half)
			if st.hidden and d < r then showGroup(st.inst)
			elseif not st.hidden and d > r + HYST then hideGroup(st.inst) end
		end
	end
	local h, t = 0, 0
	for _, st in pairs(groups) do t += 1 if st.hidden then h += 1 end end
	player:SetAttribute("SC_InteriorHidden", h .. "/" .. t)
end

-- do the queued work a little every frame (no freeze)
RunService.Heartbeat:Connect(function()
	local used = run(Q.show, OPS_PER_FRAME)
	run(Q.hide, OPS_PER_FRAME - used)
end)

-- teleports: update right away so the place you arrive at is complete
local lastPos
task.spawn(function()
	while true do
		local cam = workspace.CurrentCamera
		local p = cam and cam.CFrame.Position
		if p and lastPos and (p - lastPos).Magnitude > 60 then update() end
		lastPos = p
		task.wait(0.1)
	end
end)
while true do
	update()
	task.wait(0.4)
end
