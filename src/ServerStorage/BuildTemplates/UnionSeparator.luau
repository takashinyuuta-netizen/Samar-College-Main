--[[ UnionSeparator — turns unions back into plain Parts (rule: Parts + MeshParts only), keeping them working.
  Roblox does not let scripts separate unions yet, so:
    local U = require(game.ServerStorage.BuildTemplates.UnionSeparator)
    U.prepare(root)   -- backs up, moves each union's insides out of the way, and SELECTS the unions
    -- the developer presses Separate (Model tab, or Shift+Ctrl+U)
    U.finish()        -- rebuilds: same look, holes cut, welds / doors / scripts / click buttons / decals restored
  Per union: decals & textures go on an invisible "UnionSurface" part with the union's exact box (so they stay on
  the same faces); scripts, click detectors, sounds, prompts, lights, attachments and ropes go on the main new part;
  every weld that used the union now uses the main part (offsets kept); unanchored unions (moving doors) become
  unanchored parts welded together. Negative parts that cut a block become real holes (block split in pieces). ]]
local M = {}
local Selection = game:GetService("Selection")
local SURF = { Decal = true, Texture = true, SurfaceGui = true }
local function isJoint(c) return c:IsA("JointInstance") or c:IsA("WeldConstraint") or c:IsA("NoCollisionConstraint") end

function M.prepare(root, max)
	max = max or 100000
	local list = {}
	for _, d in ipairs(root:GetDescendants()) do
		if #list >= max then break end
		if d:IsA("UnionOperation") and not d:IsA("NegateOperation") and not d:FindFirstAncestorWhichIsA("UnionOperation") then table.insert(list, d) end
	end
	if #list == 0 then return 0 end
	local set = {} for _, u in ipairs(list) do set[u] = true end
	local RB = game.ServerStorage.BuildTemplates.Replaced_Backup
	local bk = RB:FindFirstChild("Unions_Before_Separate") or Instance.new("Folder")
	bk.Name = "Unions_Before_Separate" bk.Parent = RB
	local stash = game.ServerStorage:FindFirstChild("UnionSeparator_Stash") or Instance.new("Folder")
	stash.Name = "UnionSeparator_Stash" stash.Parent = game.ServerStorage
	-- joints anywhere that point at one of these unions
	local joints = {}
	for _, j in ipairs(workspace:GetDescendants()) do
		if j:IsA("JointInstance") or j:IsA("WeldConstraint") then
			local ok0, p0 = pcall(function() return j.Part0 end)
			local ok1, p1 = pcall(function() return j.Part1 end)
			if ok0 and p0 and set[p0] then table.insert(joints, { j = j, side = 0, u = p0 }) end
			if ok1 and p1 and set[p1] then table.insert(joints, { j = j, side = 1, u = p1 }) end
		end
	end
	local recs, before = {}, {}
	for i, u in ipairs(list) do
		local c = u:Clone() c:SetAttribute("From", u:GetFullName()) c.Parent = bk
		local r = { u = u, parent = u.Parent, cf = u.CFrame, size = u.Size, name = u.Name, color = u.Color, upc = u.UsePartColor,
			mat = u.Material, var = u.MaterialVariant, tr = u.Transparency, refl = u.Reflectance, shadow = u.CastShadow,
			collide = u.CanCollide, query = u.CanQuery, touch = u.CanTouch, anchored = u.Anchored, massless = u.Massless,
			joints = {}, moved = {}, surface = nil, primaryOf = nil }
		if u.Parent:IsA("Model") and u.Parent.PrimaryPart == u then r.primaryOf = u.Parent end
		for _, ch in ipairs(u:GetChildren()) do
			if isJoint(ch) then ch.Parent = u.Parent
			elseif SURF[ch.ClassName] then
				if not r.surface then
					local s = Instance.new("Part") s.Name = "UnionSurface" s.CFrame = u.CFrame s.Size = u.Size s.Transparency = 1
					s.CanCollide = false s.CanQuery = false s.CanTouch = false s.CastShadow = false s.Anchored = u.Anchored s.Parent = u.Parent
					r.surface = s
				end
				ch.Parent = r.surface
			else
				local wcf = ch:IsA("Attachment") and ch.WorldCFrame or nil
				ch.Parent = stash
				table.insert(r.moved, { inst = ch, wcf = wcf })
			end
		end
		recs[i] = r
		if not before[u.Parent] then local s = {} for _, ch in ipairs(u.Parent:GetChildren()) do s[ch] = true end before[u.Parent] = s end
	end
	for _, jj in ipairs(joints) do
		for _, r in ipairs(recs) do if r.u == jj.u then table.insert(r.joints, jj) break end end
	end
	_G.UnionSep = { recs = recs, before = before, list = list }
	Selection:Set(list)
	return #list
end

local function inBox(r, p)
	local l = r.cf:PointToObjectSpace(p.Position)
	local h = r.size / 2 + Vector3.new(0.06, 0.06, 0.06)
	return math.abs(l.X) <= h.X and math.abs(l.Y) <= h.Y and math.abs(l.Z) <= h.Z
end

local function subtract(b, n)
	if not (b:IsA("Part") and b.Shape == Enum.PartType.Block) then return false end
	local R = b.CFrame - b.Position
	for _, v in ipairs({ n.CFrame.RightVector, n.CFrame.UpVector, n.CFrame.LookVector }) do
		if math.max(math.abs(v:Dot(R.RightVector)), math.abs(v:Dot(R.UpVector)), math.abs(v:Dot(R.LookVector))) < 0.999 then return false end
	end
	local c = b.CFrame:PointToObjectSpace(n.Position)
	local ex = Vector3.zero
	for _, ax in ipairs({ n.CFrame.RightVector * n.Size.X / 2, n.CFrame.UpVector * n.Size.Y / 2, n.CFrame.LookVector * n.Size.Z / 2 }) do
		local l = b.CFrame:VectorToObjectSpace(ax) ex += Vector3.new(math.abs(l.X), math.abs(l.Y), math.abs(l.Z))
	end
	local h = b.Size / 2
	local lo = Vector3.new(math.max(-h.X, c.X - ex.X), math.max(-h.Y, c.Y - ex.Y), math.max(-h.Z, c.Z - ex.Z))
	local hi = Vector3.new(math.min(h.X, c.X + ex.X), math.min(h.Y, c.Y + ex.Y), math.min(h.Z, c.Z + ex.Z))
	if lo.X >= hi.X or lo.Y >= hi.Y or lo.Z >= hi.Z then return true end
	local pieces = {}
	local function add(a, z) if z.X - a.X > 0.01 and z.Y - a.Y > 0.01 and z.Z - a.Z > 0.01 then table.insert(pieces, { a, z }) end end
	add(Vector3.new(-h.X, -h.Y, -h.Z), Vector3.new(h.X, lo.Y, h.Z))
	add(Vector3.new(-h.X, hi.Y, -h.Z), Vector3.new(h.X, h.Y, h.Z))
	add(Vector3.new(-h.X, lo.Y, -h.Z), Vector3.new(lo.X, hi.Y, h.Z))
	add(Vector3.new(hi.X, lo.Y, -h.Z), Vector3.new(h.X, hi.Y, h.Z))
	add(Vector3.new(lo.X, lo.Y, -h.Z), Vector3.new(hi.X, hi.Y, lo.Z))
	add(Vector3.new(lo.X, lo.Y, hi.Z), Vector3.new(hi.X, hi.Y, h.Z))
	for _, pc in ipairs(pieces) do
		local p = b:Clone() for _, ch in ipairs(p:GetChildren()) do ch:Destroy() end
		p.Size = pc[2] - pc[1] p.CFrame = b.CFrame * CFrame.new((pc[1] + pc[2]) / 2) p.Parent = b.Parent
	end
	b:Destroy()
	return true
end

local function newIn(S, parent)
	local out, negs = {}, {}
	for _, c in ipairs(parent:GetChildren()) do
		if not S.before[parent][c] and c.Name ~= "UnionSurface" then
			if c:IsA("NegateOperation") then table.insert(negs, c) elseif c:IsA("BasePart") then table.insert(out, c) end
		end
	end
	return out, negs
end

function M.finish()
	local S = _G.UnionSep
	if not S then return "nothing prepared" end
	local still = 0
	for _, r in ipairs(S.recs) do if r.u.Parent then still += 1 end end
	if still == #S.recs then return "NOT SEPARATED: nothing changed yet (still prepared and selected - press Separate, then run finish again)" end
	-- 1) holes
	local negDone, negLeft = 0, 0
	for parent in pairs(S.before) do
		local parts, negs = newIn(S, parent)
		for _, n in ipairs(negs) do
			local ok = true
			for _, p in ipairs(parts) do
				if p.Parent and (p.Position - n.Position).Magnitude < (p.Size.Magnitude + n.Size.Magnitude) / 2 then
					if not subtract(p, n) then ok = false end
				end
			end
			parts = newIn(S, parent)
			if ok then n:Destroy() negDone += 1 else n:SetAttribute("NeedsManualHole", true) n.Transparency = 1 n.CanCollide = false negLeft += 1 end
		end
	end
	-- 2) per union: look, main part, welds, insides
	local fixed, welded, restored = 0, 0, 0
	for parent in pairs(S.before) do
		local parts = newIn(S, parent)
		local by = {}
		for _, p in ipairs(parts) do
			for _, r in ipairs(S.recs) do
				if r.parent == parent and not r.u.Parent and inBox(r, p) then by[r] = by[r] or {} table.insert(by[r], p) break end
			end
		end
		for r, list in pairs(by) do
			local main, mv = nil, -1
			for _, p in ipairs(list) do
				if r.upc then p.Color = r.color end
				p.Material = r.mat p.MaterialVariant = r.var p.Transparency = r.tr p.Reflectance = r.refl p.CastShadow = r.shadow
				p.CanCollide = r.collide p.CanQuery = r.query p.CanTouch = r.touch p.Massless = r.massless p.Name = r.name
				p.Anchored = r.anchored
				fixed += 1
				local v = p.Size.X * p.Size.Y * p.Size.Z
				if v > mv then main, mv = p, v end
			end
			if not r.anchored then
				for _, p in ipairs(list) do if p ~= main then local w = Instance.new("WeldConstraint") w.Part0 = main w.Part1 = p w.Parent = main welded += 1 end end
			end
			if r.surface then
				if not r.anchored then local w = Instance.new("WeldConstraint") w.Part0 = main w.Part1 = r.surface w.Parent = main end
			end
			for _, jj in ipairs(r.joints) do
				local j = jj.j
				if j.Parent then
					if j:IsA("JointInstance") then
						if jj.side == 0 then local w = r.cf * j.C0 j.Part0 = main j.C0 = main.CFrame:ToObjectSpace(w)
						else local w = r.cf * j.C1 j.Part1 = main j.C1 = main.CFrame:ToObjectSpace(w) end
					else
						if jj.side == 0 then j.Part0 = main else j.Part1 = main end
					end
				end
			end
			for _, m in ipairs(r.moved) do
				if m.inst.Parent then m.inst.Parent = main if m.wcf then m.inst.WorldCFrame = m.wcf end restored += 1 end
			end
			if r.primaryOf and r.primaryOf.Parent then r.primaryOf.PrimaryPart = main end
		end
	end
	_G.UnionSep = nil
	return ("unions not separated: %d | parts fixed: %d | welds added: %d | scripts/buttons/sounds moved back: %d | holes cut: %d | holes left hidden: %d"):format(still, fixed, welded, restored, negDone, negLeft)
end

-- replace every union left under `root` with ONE plain part of the same box (block, or a cylinder when the
-- union is round), same look, same welds and insides. Used for small nested unions that keep splitting.
function M.toParts(root)
	local RB = game.ServerStorage.BuildTemplates.Replaced_Backup
	local bk = RB:FindFirstChild("Unions_Before_Separate") or Instance.new("Folder")
	bk.Name = "Unions_Before_Separate" bk.Parent = RB
	local list = {}
	for _, d in ipairs(root:GetDescendants()) do if d:IsA("UnionOperation") and not d:IsA("NegateOperation") then table.insert(list, d) end end
	local n, cyl = 0, 0
	-- joints that use one of these unions (found once, not per union)
	local uset = {} for _, u in ipairs(list) do uset[u] = true end
	local jmap = {}
	for _, j in ipairs(workspace:GetDescendants()) do
		if j:IsA("WeldConstraint") or j:IsA("JointInstance") then
			local a, b = j.Part0, j.Part1
			if a and uset[a] then jmap[a] = jmap[a] or {} table.insert(jmap[a], j) end
			if b and uset[b] and b ~= a then jmap[b] = jmap[b] or {} table.insert(jmap[b], j) end
		end
	end
	for i, u in ipairs(list) do
		if u.Parent then
			local c = u:Clone() c:SetAttribute("From", u:GetFullName()) c.Parent = bk
			local p = Instance.new("Part")
			local s = u.Size
			local cf = u.CFrame
			local function near(a, b) return math.abs(a - b) <= math.max(a, b) * 0.08 end
			local round = u.Name:lower():find("wheel") or u.Name:lower():find("knob") or u.Name:lower():find("cap")
			if round and near(s.Y, s.Z) and not near(s.X, s.Y) then
				p.Shape = Enum.PartType.Cylinder p.Size = s cyl += 1
			elseif round and near(s.X, s.Z) and not near(s.Y, s.X) then
				p.Shape = Enum.PartType.Cylinder p.Size = Vector3.new(s.Y, s.X, s.Z) cf = cf * CFrame.Angles(0, 0, math.rad(90)) cyl += 1
			elseif round and near(s.X, s.Y) and not near(s.Z, s.X) then
				p.Shape = Enum.PartType.Cylinder p.Size = Vector3.new(s.Z, s.Y, s.X) cf = cf * CFrame.Angles(0, math.rad(90), 0) cyl += 1
			else
				p.Size = s
			end
			p.Name = u.Name p.CFrame = cf p.Color = u.Color p.Material = u.Material p.MaterialVariant = u.MaterialVariant
			p.Transparency = u.Transparency p.Reflectance = u.Reflectance p.CastShadow = u.CastShadow and s.Magnitude > 2
			p.CanCollide = u.CanCollide p.CanQuery = u.CanQuery p.CanTouch = u.CanTouch p.Anchored = u.Anchored p.Massless = u.Massless
			p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
			for _, ch in ipairs(u:GetChildren()) do ch.Parent = p end
			p.Parent = u.Parent
			if u.Parent:IsA("Model") and u.Parent.PrimaryPart == u then u.Parent.PrimaryPart = p end
			for _, j in ipairs(jmap[u] or {}) do
				if j:IsA("WeldConstraint") then if j.Part0 == u then j.Part0 = p end if j.Part1 == u then j.Part1 = p end
				elseif j:IsA("JointInstance") then
					if j.Part0 == u then local w = u.CFrame * j.C0 j.Part0 = p j.C0 = p.CFrame:ToObjectSpace(w) end
					if j.Part1 == u then local w = u.CFrame * j.C1 j.Part1 = p j.C1 = p.CFrame:ToObjectSpace(w) end
				end
			end
			u:Destroy() n += 1
		end
		if i % 150 == 0 then task.wait() end
	end
	return n, cyl
end

return M
