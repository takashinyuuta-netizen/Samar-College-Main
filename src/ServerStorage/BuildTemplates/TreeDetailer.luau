--[[ TreeDetailer — adds detail to the simple tree models IN PLACE (build tool; run from the command bar / MCP).
    local D = require(game.ServerStorage.BuildTemplates.TreeDetailer)
    D.detail(model)   -> number of parts added (0 if already detailed / unknown type)
  Supported: Tree, StreetTree, Bamboo, Palm, GardenTree. Each tree keeps its own size, colours and original
  parts; the extra parts go in a child Model "Detail" (moves with the tree) and are varied per tree (seeded by
  position) so no two look the same. Extra parts are anchored, non-colliding and not queryable (cheap).
  The model gets attribute Detailed = true so running it again does nothing. ]]
local M = {}

local function lerp(c, to, a) return c:Lerp(to, a) end
local BLACK, WHITE = Color3.new(0, 0, 0), Color3.new(1, 1, 1)

local holder, rng
local function part(shape, size, cf, color, mat)
	local p = Instance.new("Part")
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.CFrame = cf
	p.Color = color
	local ok = pcall(function() p.Material = mat end)
	if not ok then p.Material = Enum.Material.SmoothPlastic end
	p.Anchored = true p.CanCollide = false p.CanTouch = false p.CanQuery = false
	p.CastShadow = size.Magnitude >= 3
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = holder
	return p
end
local CYL, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball
-- cylinder between two points
local function rod(a, b, dia, color, mat)
	local len = (b - a).Magnitude
	if len < 0.05 then return end
	return part(CYL, Vector3.new(len, dia, dia), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0), color, mat)
end
-- a thin ring (cylinder) around an axis
local function ring(center, axis, dia, thick, color, mat)
	local ref = math.abs(axis.Y) < 0.95 and Vector3.yAxis or Vector3.xAxis
	local y = ref:Cross(axis).Unit
	return part(CYL, Vector3.new(thick, dia, dia), CFrame.fromMatrix(center, axis, y), color, mat)
end
-- the long axis of a part (unit vector pointing up) and its length / thickness
local function longAxis(p)
	local s = p.Size
	local v, len, thick
	if s.X >= s.Y and s.X >= s.Z then v, len, thick = p.CFrame.RightVector, s.X, math.min(s.Y, s.Z)
	elseif s.Y >= s.Z then v, len, thick = p.CFrame.UpVector, s.Y, math.min(s.X, s.Z)
	else v, len, thick = p.CFrame.LookVector, s.Z, math.min(s.X, s.Y) end
	if v.Y < 0 then v = -v end
	return v, len, thick
end
local function perpOf(axis)
	local ref = math.abs(axis.Y) < 0.95 and Vector3.yAxis or Vector3.xAxis
	return ref:Cross(axis).Unit
end
local function children(m, name)
	local t = {}
	for _, c in ipairs(m:GetDescendants()) do if c:IsA("BasePart") and c.Name == name and not c:IsDescendantOf(holder) then table.insert(t, c) end end
	return t
end
local function groundBelow(m, pos)
	local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances = { m } rp.RespectCanCollide = true
	local r = workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -20, 0), rp)
	return r and r.Position.Y
end
local function rand(a, b) return a + (b - a) * rng:NextNumber() end
local function randDir(yMin, yMax)
	local ang = rand(0, math.pi * 2)
	local y = rand(yMin, yMax)
	local r = math.sqrt(math.max(0, 1 - y * y))
	return Vector3.new(math.cos(ang) * r, y, math.sin(ang) * r)
end

-- leaf clusters on the surface of the existing leaf balls: lighter on top, darker underneath
local function leafClusters(balls, count, sizeMin, sizeMax, mat)
	if #balls == 0 then return end
	for k = 1, count do
		local b = balls[(k - 1) % #balls + 1]
		local rad = math.max(b.Size.X, b.Size.Y, b.Size.Z) / 2
		local dir = randDir(-0.35, 0.95)
		local s = rad * rand(sizeMin, sizeMax) * 2
		local col = dir.Y > 0.35 and lerp(b.Color, Color3.fromRGB(150, 200, 90), rand(0.12, 0.22)) or lerp(b.Color, BLACK, rand(0.08, 0.2))
		part(BALL, Vector3.new(s, s * rand(0.8, 1), s), CFrame.new(b.Position + dir * rad * rand(0.7, 0.9)), col, mat or b.Material)
	end
end

----------------------------------------------------------------------------------------------- broadleaf "Tree"
local function detailTree(m)
	local trunk = children(m, "Trunk")[1]
	if not trunk then return end
	local axis, L, D = longAxis(trunk)
	local base = trunk.Position - axis * (L / 2)
	local bark = trunk.Color
	local dark = lerp(bark, BLACK, 0.22)
	local perp = perpOf(axis)
	local perp2 = axis:Cross(perp).Unit
	-- root flares spreading into the ground
	local nRoots = 5
	local a0 = rand(0, math.pi * 2)
	for k = 1, nRoots do
		local ang = a0 + k * (math.pi * 2 / nRoots) + rand(-0.25, 0.25)
		local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local s = base + axis * (D * rand(0.45, 0.7))
		local tip = base + dir * (D * rand(1.0, 1.35)) - Vector3.new(0, D * 0.25, 0)
		rod(s, tip, D * rand(0.32, 0.42), dark, trunk.Material)
	end
	-- bark rings + knots up the trunk
	for _, h in ipairs({ 0.22, 0.5 }) do ring(base + axis * (L * h), axis, D * 1.07, D * 0.08, dark, trunk.Material) end
	for k = 1, 2 do
		local ang = rand(0, math.pi * 2)
		local out = perp * math.cos(ang) + perp2 * math.sin(ang)
		part(BALL, Vector3.one * D * rand(0.3, 0.42), CFrame.new(base + axis * (L * rand(0.3, 0.7)) + out * D * 0.45), dark, trunk.Material)
	end
	-- extra branches reaching into the canopy
	local balls = children(m, "Leaves")
	for k = 1, 3 do
		local b = balls[(k * 2 - 1) % math.max(#balls, 1) + 1]
		if b then
			local s = base + axis * (L * rand(0.62, 0.88))
			local e = s:Lerp(b.Position, rand(0.55, 0.75))
			rod(s, e, D * rand(0.22, 0.3), bark, trunk.Material)
			rod(e, e:Lerp(b.Position, 0.6) + randDir(0.2, 0.8) * D * 0.6, D * 0.13, bark, trunk.Material)
		end
	end
	-- fuller, layered canopy
	leafClusters(balls, 7, 0.32, 0.46)
	-- grass + fallen-leaf ground cover at the base
	local gy = groundBelow(m, base)
	if gy then
		part(BALL, Vector3.new(D * 3.4, D * 0.45, D * 3.4), CFrame.new(base.X, gy + D * 0.05, base.Z), Color3.fromRGB(62, 98, 46), Enum.Material.Grass)
	end
	return true
end

------------------------------------------------------------------------------------------------- StreetTree
local function detailStreetTree(m)
	local planter, trunk, soil = children(m, "Planter")[1], children(m, "Trunk")[1], children(m, "Soil")[1]
	if not (planter and trunk) then return end
	local axis, L, D = longAxis(trunk)
	local base = trunk.Position - axis * (L / 2)
	local pc = planter.CFrame
	local ps = planter.Size
	local top = pc * CFrame.new(0, ps.Y / 2, 0)
	local rimCol = lerp(planter.Color, WHITE, 0.18)
	-- raised rim around the planter
	for _, s in ipairs({ -1, 1 }) do
		part(nil, Vector3.new(ps.X + 0.2, 0.2, 0.3), top * CFrame.new(0, 0.1, s * (ps.Z / 2 - 0.05)), rimCol, planter.Material)
		part(nil, Vector3.new(0.3, 0.2, ps.Z - 0.4), top * CFrame.new(s * (ps.X / 2 - 0.05), 0.1, 0), rimCol, planter.Material)
	end
	local soilY = soil and (soil.Position.Y + soil.Size.Y / 2) or top.Position.Y
	-- grass tufts + small flowers in the soil
	for k = 1, 2 do
		local off = Vector3.new(rand(-1, 1), 0, rand(-1, 1)) * (ps.X * 0.28)
		part(BALL, Vector3.new(0.9, 0.45, 0.9), CFrame.new(Vector3.new(base.X, soilY + 0.1, base.Z) + off), Color3.fromRGB(70, 130, 55), Enum.Material.Grass)
	end
	part(BALL, Vector3.new(0.3, 0.3, 0.3), CFrame.new(base.X + ps.X * 0.25, soilY + 0.1, base.Z - ps.Z * 0.2), Color3.fromRGB(240, 200, 60), Enum.Material.SmoothPlastic)
	-- root flare + support stakes with a rubber tie (like real city trees)
	part(CYL, Vector3.new(0.45, D * 1.7, D * 1.7), CFrame.fromMatrix(Vector3.new(base.X, soilY + 0.15, base.Z), Vector3.yAxis, Vector3.xAxis), lerp(trunk.Color, BLACK, 0.15), trunk.Material)
	local perp = perpOf(axis)
	for _, s in ipairs({ -1, 1 }) do
		local foot = Vector3.new(base.X, soilY, base.Z) + perp * s * (D + 0.45)
		part(nil, Vector3.new(0.14, 3.4, 0.14), CFrame.new(foot + Vector3.new(0, 1.7, 0)), Color3.fromRGB(170, 140, 100), Enum.Material.WoodPlanks)
	end
	part(nil, Vector3.new((D + 0.45) * 2, 0.12, 0.12), CFrame.lookAt(Vector3.new(base.X, soilY + 2.7, base.Z), Vector3.new(base.X, soilY + 2.7, base.Z) + perp) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(30, 30, 32), Enum.Material.Rubber)
	-- branches + fuller crown
	local balls = children(m, "Leaves")
	local topPt = base + axis * L
	for k = 1, 2 do
		local b = balls[k] or balls[1]
		if b then rod(base + axis * (L * rand(0.7, 0.85)), topPt:Lerp(b.Position, 0.7), D * 0.4, trunk.Color, trunk.Material) end
	end
	ring(base + axis * (L * 0.35), axis, D * 1.12, 0.1, lerp(trunk.Color, BLACK, 0.2), trunk.Material)
	leafClusters(balls, 4, 0.35, 0.5)
	return true
end

----------------------------------------------------------------------------------------------------- Bamboo
local function detailBamboo(m)
	local culms = children(m, "Culm")
	if #culms == 0 then return end
	local nodeCol
	for _, c in ipairs(culms) do
		local axis, L, D = longAxis(c)
		local base = c.Position - axis * (L / 2)
		nodeCol = lerp(c.Color, Color3.fromRGB(90, 80, 40), 0.35)
		for _, f in ipairs({ 0.18, 0.38, 0.58, 0.78 }) do
			ring(base + axis * (L * (f + rand(-0.03, 0.03))), axis, D * 1.18, 0.16, nodeCol, c.Material)
		end
	end
	-- leaf sprays near the culm tops + a few young shoots at the base
	local balls = children(m, "Leaves")
	leafClusters(balls, 4, 0.4, 0.55)
	for k = 1, 2 do
		local c = culms[k]
		local axis, L = longAxis(c)
		local base = c.Position - axis * (L / 2)
		local gy = groundBelow(m, base) or base.Y
		local foot = Vector3.new(base.X, gy, base.Z) + randDir(0, 0) * 1.4
		rod(foot - Vector3.new(0, 0.3, 0), foot + Vector3.new(rand(-0.3, 0.3), rand(1.4, 2.2), rand(-0.3, 0.3)), 0.4, Color3.fromRGB(120, 110, 60), Enum.Material.Wood)
	end
	return true
end

------------------------------------------------------------------------------------------------------- Palm
local function detailPalm(m)
	local segs = children(m, "PalmTrunk")
	if #segs == 0 then return end
	local ringCol, topPt, topW
	for _, s in ipairs(segs) do
		local axis, L, W = longAxis(s)
		ringCol = lerp(s.Color, BLACK, 0.25)
		local t = s.Position + axis * (L / 2)
		ring(t, axis, W * 1.25, 0.14, ringCol, s.Material)
		if not topPt or t.Y > topPt.Y then topPt, topW = t, W end
	end
	-- crown base, brown dead fronds hanging down, more coconuts
	part(BALL, Vector3.one * topW * 2.1, CFrame.new(topPt + Vector3.new(0, topW * 0.4, 0)), Color3.fromRGB(110, 120, 60), Enum.Material.Grass)
	for k = 1, 2 do
		local ang = rand(0, math.pi * 2)
		local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local c = topPt + dir * 1.0 - Vector3.new(0, 1.0, 0)
		part(nil, Vector3.new(1.1, 0.08, 2.6), CFrame.lookAt(c, c + dir - Vector3.new(0, 1.8, 0)), Color3.fromRGB(140, 105, 60), Enum.Material.LeafyGrass)
	end
	local nuts = children(m, "Coconut")
	local nutCol = nuts[1] and nuts[1].Color or Color3.fromRGB(110, 90, 40)
	for k = 1, 3 do
		local off = randDir(-0.6, 0) * topW * 0.9
		part(BALL, Vector3.one * rand(0.5, 0.65), CFrame.new(topPt + off), lerp(nutCol, Color3.fromRGB(90, 140, 50), rng:NextNumber() < 0.4 and 0.6 or 0), Enum.Material.SmoothPlastic)
	end
	return true
end

------------------------------------------------------------------------------------------------- GardenTree
local function detailGardenTree(m)
	local trunk = children(m, "Trunk")[1]
	if not trunk then return end
	local axis, L, D = longAxis(trunk)
	local base = trunk.Position - axis * (L / 2)
	local dark = lerp(trunk.Color, BLACK, 0.2)
	for k = 1, 3 do
		local ang = k * 2.1 + rand(-0.3, 0.3)
		rod(base + axis * (D * 0.9), base + Vector3.new(math.cos(ang), -0.2, math.sin(ang)) * (D * 1.6), D * 0.45, dark, trunk.Material)
	end
	local balls = children(m, "Canopy")
	for k = 1, 2 do
		local b = balls[k]
		if b then rod(base + axis * (L * rand(0.6, 0.8)), b.Position, D * 0.35, trunk.Color, trunk.Material) end
	end
	leafClusters(balls, 4, 0.3, 0.45)
	return true
end

--------------------------------------------------------------------------------------------------------- Pine
local function detailPine(m)
	local trunks = children(m, "Trunk")
	if #trunks == 0 then return end
	table.sort(trunks, function(a, b) return a.Position.Y < b.Position.Y end)
	local t = trunks[1]
	local axis, L, D = longAxis(t)
	local base = t.Position - axis * (L / 2)
	local dark = lerp(t.Color, BLACK, 0.25)
	for _, h in ipairs({ 0.18, 0.42 }) do ring(base + axis * (L * h), axis, D * 1.08, D * 0.09, dark, t.Material) end
	-- pinecones hanging under the needle tiers
	local tiers = children(m, "Needles")
	for k = 1, math.min(3, #tiers) do
		local tier = tiers[(k * 3) % #tiers + 1]
		local r = math.max(tier.Size.X, tier.Size.Z) / 2
		local ang = rand(0, math.pi * 2)
		local p = tier.Position + Vector3.new(math.cos(ang) * r * 0.45, -tier.Size.Y * 0.45, math.sin(ang) * r * 0.45)
		part(BALL, Vector3.new(D * 0.28, D * 0.4, D * 0.28), CFrame.new(p), Color3.fromRGB(120, 80, 45), Enum.Material.Wood)
	end
	-- fallen needles + cones on the ground
	local gy = groundBelow(m, base)
	if gy then
		part(BALL, Vector3.new(D * 4.2, D * 0.35, D * 4.2), CFrame.new(base.X, gy + D * 0.02, base.Z), Color3.fromRGB(110, 85, 50), Enum.Material.Ground)
		part(BALL, Vector3.new(D * 0.3, D * 0.4, D * 0.3), CFrame.new(base.X + D * 1.3, gy + D * 0.12, base.Z - D * 0.6), Color3.fromRGB(120, 80, 45), Enum.Material.Wood)
	end
	return true
end

------------------------------------------------------------------------------------------------- CoconutTree
local function detailCoconut(m)
	local segs = children(m, "Trunk")
	if #segs == 0 then return end
	local topPt, topW, lowPt, lowW, mat, col
	for _, s in ipairs(segs) do
		local axis, L, W = longAxis(s)
		local t = s.Position + axis * (L / 2)
		local b = s.Position - axis * (L / 2)
		ring(t, axis, W * 1.12, math.min(0.25, W * 0.1), lerp(s.Color, BLACK, 0.22), s.Material)
		if not topPt or t.Y > topPt.Y then topPt, topW = t, W end
		if not lowPt or b.Y < lowPt.Y then lowPt, lowW = b, W end
		mat, col = s.Material, s.Color
	end
	part(BALL, Vector3.one * topW * 1.8, CFrame.new(topPt + Vector3.new(0, topW * 0.3, 0)), Color3.fromRGB(105, 115, 55), Enum.Material.Grass)
	local ang = rand(0, math.pi * 2)
	local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
	local c = topPt + dir * topW * 1.2 - Vector3.new(0, topW * 1.4, 0)
	part(nil, Vector3.new(topW * 1.1, 0.1, topW * 3.2), CFrame.lookAt(c, c + dir - Vector3.new(0, 2, 0)), Color3.fromRGB(150, 115, 65), Enum.Material.LeafyGrass)
	for k = 1, 2 do
		part(BALL, Vector3.one * topW * rand(0.45, 0.55), CFrame.new(topPt + randDir(-0.7, -0.2) * topW * 0.8), Color3.fromRGB(95, 130, 45), Enum.Material.SmoothPlastic)
	end
	local gy = groundBelow(m, lowPt)
	if gy then part(BALL, Vector3.new(lowW * 3, lowW * 0.4, lowW * 3), CFrame.new(lowPt.X, gy + 0.02, lowPt.Z), Color3.fromRGB(150, 130, 90), Enum.Material.Sand) end
	return true
end

local BUILDERS = { Tree = detailTree, StreetTree = detailStreetTree, Bamboo = detailBamboo, Palm = detailPalm, GardenTree = detailGardenTree, Pine = detailPine, CoconutTree = detailCoconut }

function M.kindOf(m)
	return (m.Name:gsub("[_%s]*%d+$", ""))
end

function M.detail(m)
	if m:GetAttribute("Detailed") then return 0 end
	local fn = BUILDERS[M.kindOf(m)]
	if not fn then return 0 end
	local p = m:GetPivot().Position
	rng = Random.new(math.floor(p.X * 7 + p.Z * 13 + p.Y * 3))
	holder = Instance.new("Model")
	holder.Name = "Detail"
	local ok, res = pcall(fn, m)
	if not ok or not res then
		holder:Destroy()
		if not ok then warn("[TreeDetailer] " .. m:GetFullName() .. ": " .. tostring(res)) end
		return 0
	end
	local n = #holder:GetChildren()
	holder.Parent = m
	m:SetAttribute("Detailed", true)
	return n
end

return M
