--[[ SeasonGround — season details on the GROUND for this player only (works with WeatherClient).

  Reads player attribute "Weather_Showing" (what WeatherClient is drawing right now).

  ❄️ Snow / Blizzard / Winter
     • snow slowly BUILDS UP on outdoor roofs, floors, walkways, benches and the grass — patchy at first, then
       a thick white layer (faster in a blizzard). It MELTS away again when the weather changes.
     • Only surfaces open to the sky get snow (checked with rays from the sky), so it never appears indoors.
     • crunchy snow footsteps + footprints that fade + little snow puffs, frosty breath in the cold.
  🍂 Autumn   fallen leaves pile up on roofs and floors outside, trees turn orange, rustling leaf footsteps.
  🌸 Spring   cherry petals on the ground, blossoming trees, fresh green grass, butterflies.
  ☀️ Summer / Heat Wave   sun-dried grass, butterflies.

  Settings (Settings → 🌦️ Weather & Season):
     Setting_GroundCover     (snow, leaves & petals on the ground + tree colours)   default ON
     Setting_SeasonSteps     (footstep sounds, footprints, puffs)                    default ON
     Setting_SeasonCritters  (butterflies & frosty breath)                           default ON
     Setting_DisableEffects = everything off, Setting_ImproveFPS = smaller area.
  Everything here is created by this LocalScript, so only this player sees it. ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local terrain = workspace.Terrain
local rand = Random.new()

local SNOW = { Snow = 1 / 45, Blizzard = 1 / 22, Winter = 1 / 40 } -- build-up speed (per second)
local LEAVES = { Autumn = true }
local PETALS = { Spring = true }
local SUMMER = { Summer = true, HeatWave = true }
local CRITTERS = { Spring = true, Summer = true, HeatWave = true, Sunny = true, Rainbow = true }

-- PERFORMANCE: bigger cells + a smaller area = far fewer raycasts and parts (was ~1,800 cells / 140 studs)
local CELL = 8
local UIS = game:GetService("UserInputService")
local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled
local SNOW_COLOR = Color3.fromRGB(242, 246, 252)
local LEAF_COLORS = { Color3.fromRGB(214, 120, 40), Color3.fromRGB(190, 70, 35), Color3.fromRGB(230, 170, 50), Color3.fromRGB(150, 95, 45), Color3.fromRGB(200, 140, 60) }
local PETAL_COLORS = { Color3.fromRGB(255, 190, 210), Color3.fromRGB(255, 215, 230), Color3.fromRGB(250, 240, 245), Color3.fromRGB(240, 160, 190) }
local SFX = SoundService:FindFirstChild("SFX")
local SND_SNOW = { "rbxassetid://9126274119", "rbxassetid://9126273948" }
local SND_LEAF = { "rbxassetid://9114518233", "rbxassetid://9117087210" }

for _, k in ipairs({ "Setting_GroundCover", "Setting_SeasonSteps", "Setting_SeasonCritters" }) do
	if player:GetAttribute(k) == nil then player:SetAttribute(k, true) end
end
local function on(k) return player:GetAttribute(k) ~= false and player:GetAttribute("Setting_DisableEffects") ~= true end
local function lowSpec() return IS_MOBILE or player:GetAttribute("Setting_ImproveFPS") == true end
local function radius()
	if player:GetAttribute("Setting_ImproveFPS") == true then return IS_MOBILE and 48 or 60 end
	return IS_MOBILE and 64 or 96
end
local function leafRadius()
	if player:GetAttribute("Setting_ImproveFPS") == true then return IS_MOBILE and 28 or 36 end
	return IS_MOBILE and 36 or 56
end

local folder = Instance.new("Folder")
folder.Name = "SC_SeasonGround"
folder.Parent = workspace

local function flat(name, size, color, material)
	local p = Instance.new("Part")
	p.Name = name p.Size = size p.Color = color p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

---------------------------------------------------------------- amounts (0..1) that grow / melt over time
local amt = { snow = 0, leaves = 0, petals = 0, summer = 0 }
local function showing() return player:GetAttribute("Weather_Showing") or "Sunny" end

---------------------------------------------------------------- sky scan (which surfaces are outdoors)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function refreshFilter()
	local list = { folder, camera }
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(list, p.Character) end end
	rayParams.FilterDescendantsInstances = list
end
refreshFilter()

local cells = {}      -- [key] = cell
local pending = {}    -- keys waiting to be scanned
local pendingSet = {}

local function keyOf(cx, cz) return cx .. "," .. cz end

-- the clipped tile rectangle on the top face of a block part (so snow never hangs over an edge)
local function faceRect(part, hitPos, normal)
	if not part:IsA("Part") or part.Shape ~= Enum.PartType.Block then return nil end
	local cf = part.CFrame
	local axes = { cf.RightVector, cf.UpVector, -cf.LookVector }
	local sizes = { part.Size.X, part.Size.Y, part.Size.Z }
	local best, bestDot = 1, 0
	for i = 1, 3 do
		local d = axes[i]:Dot(normal)
		if math.abs(d) > math.abs(bestDot) then best, bestDot = i, d end
	end
	if math.abs(bestDot) < 0.9 then return nil end
	local up = axes[best] * (bestDot > 0 and 1 or -1)
	local u = best == 1 and 2 or 1
	local v = best == 3 and 2 or 3
	local U, V = axes[u], axes[v]
	local rel = hitPos - cf.Position
	local hu, hv = rel:Dot(U), rel:Dot(V)
	local half = CELL / 2 + 0.15
	local eu, ev = sizes[u] / 2, sizes[v] / 2
	local lu, hu2 = math.max(-eu, hu - half), math.min(eu, hu + half)
	local lv, hv2 = math.max(-ev, hv - half), math.min(ev, hv + half)
	if hu2 - lu < 0.6 or hv2 - lv < 0.6 then return nil end
	local center = cf.Position + up * (sizes[best] / 2) + U * ((lu + hu2) / 2) + V * ((lv + hv2) / 2)
	return center, U, up, hu2 - lu, hv2 - lv
end

local function humanoidModel(inst)
	local m = inst:FindFirstAncestorOfClass("Model")
	while m do
		if m:FindFirstChildOfClass("Humanoid") then return true end
		m = m:FindFirstAncestorOfClass("Model")
	end
	return false
end

local function exposed(pos)
	return workspace:Raycast(pos + Vector3.new(0, 0.3, 0), Vector3.new(0, 400, 0), rayParams) == nil
end
local function cornersExposed(cell)
	local f = cell.up:Cross(cell.right)
	local hw, hd = cell.w / 2 - 0.3, cell.d / 2 - 0.3
	for _, o in ipairs({ { hw, hd }, { -hw, hd }, { hw, -hd }, { -hw, -hd } }) do
		if not exposed(cell.center + cell.right * o[1] + f * o[2]) then return false end
	end
	return true
end

local function scan(cell)
	local x, z = (cell.cx + 0.5) * CELL, (cell.cz + 0.5) * CELL
	local hit = workspace:Raycast(Vector3.new(x, 700, z), Vector3.new(0, -1000, 0), rayParams)
	cell.scanned = os.clock()
	cell.ok = false
	if not hit then return end
	local inst = hit.Instance
	if inst == terrain then
		if hit.Material == Enum.Material.Water then return end
		cell.ok, cell.terrain = true, true
		cell.center, cell.up, cell.right = hit.Position, hit.Normal, hit.Normal:Cross(Vector3.zAxis).Magnitude > 0.1 and hit.Normal:Cross(Vector3.zAxis).Unit or Vector3.xAxis
		cell.w, cell.d = CELL, CELL
		cell.part = terrain
		return
	end
	if hit.Normal.Y < 0.4 then return end                     -- walls / steep
	if inst.Transparency > 0.4 or not inst:IsA("BasePart") then return end
	if humanoidModel(inst) then cell.retry = true return end   -- an NPC / player was standing there
	local s = inst.Size
	if math.max(s.X, s.Y, s.Z) < 2.5 then return end            -- tiny props: no snow hats on cups
	local center, U, up, w, d = faceRect(inst, hit.Position, hit.Normal)
	if not center then
		-- meshes / wedges / round parts: a small pad following the surface
		local n = hit.Normal
		local r = n:Cross(Vector3.zAxis)
		r = r.Magnitude > 0.1 and r.Unit or Vector3.xAxis
		center, U, up, w, d = hit.Position, r, n, 3.2, 3.2
	end
	cell.ok, cell.terrain = true, false
	cell.center, cell.up, cell.right, cell.w, cell.d = center, up, U, w, d
	cell.part = inst
	-- near walls / under eaves: shrink the patch so it never pokes under a roof or through a doorway
	if not cornersExposed(cell) then
		cell.center = hit.Position
		cell.w, cell.d = math.min(cell.w, 2.6), math.min(cell.d, 2.6)
		if not cornersExposed(cell) then cell.ok = false end
	end
end

local function cellCF(cell, lift)
	return CFrame.fromMatrix(cell.center + cell.up * lift, cell.right, cell.up)
end

---------------------------------------------------------------- what each cell shows
local function clearCell(cell)
	if cell.tile then cell.tile:Destroy() cell.tile = nil end
	if cell.bits then for _, b in ipairs(cell.bits) do b.part:Destroy() end cell.bits = nil end
end

local function ensureSnow(cell)
	if cell.terrain then return end -- terrain grass turns white by colour instead (looks smoother on hills)
	if not cell.tile then
		local t = flat("Snow", Vector3.new(cell.w, 0.05, cell.d), SNOW_COLOR, Enum.Material.Snow)
		t.Transparency = 1
		t.CFrame = cellCF(cell, 0.03)
		t.Parent = folder
		cell.tile = t
		cell.threshold = rand:NextNumber(0, 0.45) -- patchy at first, then full cover
		cell.level = -1
	end
end

local function ensureBits(cell, kind)
	if cell.bits and cell.bitsKind == kind then return end
	if cell.bits then for _, b in ipairs(cell.bits) do b.part:Destroy() end end
	cell.bits, cell.bitsKind = {}, kind
	local n = kind == "leaves" and rand:NextInteger(2, 4) or rand:NextInteger(1, 3)
	if cell.w < 2 or cell.d < 2 then n = 1 end
	for i = 1, n do
		local ox, oz = rand:NextNumber(-cell.w / 2 + 0.4, cell.w / 2 - 0.4), rand:NextNumber(-cell.d / 2 + 0.4, cell.d / 2 - 0.4)
		local size = kind == "leaves" and Vector3.new(rand:NextNumber(0.7, 1.1), 0.05, rand:NextNumber(0.45, 0.7)) or Vector3.new(0.45, 0.04, 0.35)
		local col = kind == "leaves" and LEAF_COLORS[rand:NextInteger(1, #LEAF_COLORS)] or PETAL_COLORS[rand:NextInteger(1, #PETAL_COLORS)]
		local p = flat(kind == "leaves" and "FallenLeaf" or "Petal", size, col)
		p.Transparency = 1
		local base = cellCF(cell, 0.04) * CFrame.new(ox, 0, oz) * CFrame.Angles(rand:NextNumber(-0.15, 0.15), rand:NextNumber(0, math.pi * 2), rand:NextNumber(-0.15, 0.15))
		if exposed(base.Position) then
			p.CFrame = base
			p.Parent = folder
			table.insert(cell.bits, { part = p, base = base, threshold = rand:NextNumber(0.02, 0.9), shown = false })
		else
			p:Destroy()
		end
	end
end

local function applyCell(cell, dist)
	if not cell.ok then return end
	local ground = on("Setting_GroundCover")
	-- snow
	if ground and amt.snow > 0.001 then
		ensureSnow(cell)
		if cell.tile then
			local k = math.clamp((amt.snow - cell.threshold) / (1 - cell.threshold), 0, 1)
			local level = math.floor(k * 20 + 0.5)
			if level ~= cell.level then
				cell.level = level
				local thick = 0.05 + 0.55 * (level / 20)
				cell.tile.Size = Vector3.new(cell.w, thick, cell.d)
				cell.tile.CFrame = cellCF(cell, thick / 2 - 0.01)
				cell.tile.Transparency = level == 0 and 1 or (level < 3 and 0.35 or 0)
			end
		end
	elseif cell.tile then
		cell.tile:Destroy() cell.tile = nil
	end
	-- leaves / petals (smaller area: lots of little parts)
	local kind = (amt.leaves >= amt.petals and amt.leaves > 0.001) and "leaves" or (amt.petals > 0.001 and "petals" or nil)
	if ground and kind and dist <= leafRadius() then
		ensureBits(cell, kind)
		local a = kind == "leaves" and amt.leaves or amt.petals
		for _, b in ipairs(cell.bits) do
			local want = a > b.threshold
			if want ~= b.shown then
				b.shown = want
				if want then
					-- drifts down and settles
					b.part.CFrame = b.base * CFrame.new(rand:NextNumber(-1, 1), 2.5, rand:NextNumber(-1, 1)) * CFrame.Angles(rand:NextNumber(-1, 1), 0, rand:NextNumber(-1, 1))
					b.part.Transparency = 0
					TweenService:Create(b.part, TweenInfo.new(rand:NextNumber(0.9, 1.6), Enum.EasingStyle.Sine), { CFrame = b.base }):Play()
				else
					TweenService:Create(b.part, TweenInfo.new(0.8), { Transparency = 1 }):Play()
				end
			end
		end
	elseif cell.bits then
		for _, b in ipairs(cell.bits) do b.part:Destroy() end
		cell.bits = nil
	end
end

---------------------------------------------------------------- terrain grass + tree colours
local GRASS = Enum.Material.Grass
local baseGrass = terrain:GetMaterialColor(GRASS)
local baseLeafy = terrain:GetMaterialColor(Enum.Material.LeafyGrass)
local trees = nil -- { {part, color} } outdoor tree / shrub parts (found once)
local TREE_NAMES = { Canopy = true, Shrub = true, PalmLeaf = true, Leaves = true, Foliage = true, Bush = true, TreeTop = true }
local function findTrees()
	trees = {}
	local up = RaycastParams.new()
	up.FilterType = Enum.RaycastFilterType.Exclude
	local n = 0
	for _, d in ipairs(workspace:GetDescendants()) do
		n += 1
		if n % 4000 == 0 then task.wait() end
		if d:IsA("BasePart") and TREE_NAMES[d.Name] and d.Transparency < 0.5 and not d:IsDescendantOf(folder) then
			up.FilterDescendantsInstances = { d.Parent }
			if not workspace:Raycast(d.Position + Vector3.new(0, d.Size.Y / 2 + 0.2, 0), Vector3.new(0, 200, 0), up) then
				table.insert(trees, { part = d, color = d.Color })
			end
		end
	end
end
local lastTint = nil
local function tint()
	local ground = on("Setting_GroundCover")
	local s = ground and amt.snow or 0
	local l = ground and amt.leaves or 0
	local p = ground and amt.petals or 0
	local su = ground and amt.summer or 0
	local key = math.floor(s * 30) .. "/" .. math.floor(l * 30) .. "/" .. math.floor(p * 30) .. "/" .. math.floor(su * 30)
	if key == lastTint then return end
	lastTint = key
	local g = baseGrass
	g = g:Lerp(Color3.fromRGB(150, 160, 70), su * 0.45)   -- sun-dried
	g = g:Lerp(Color3.fromRGB(90, 175, 70), p * 0.45)     -- fresh spring green
	g = g:Lerp(Color3.fromRGB(176, 128, 58), l * 0.75)    -- autumn brown
	g = g:Lerp(SNOW_COLOR, s * 0.95)                       -- snow
	terrain:SetMaterialColor(GRASS, g)
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, baseLeafy:Lerp(Color3.fromRGB(176, 128, 58), l * 0.75):Lerp(SNOW_COLOR, s * 0.9))
	if (s + l + p) > 0.001 and not trees then task.spawn(findTrees) end
	if trees then
		for _, t in ipairs(trees) do
			if t.part.Parent then
				local c = t.color
				c = c:Lerp(Color3.fromRGB(255, 180, 205), p * 0.8)
				c = c:Lerp(Color3.fromRGB(215, 115, 40), l * 0.85)
				c = c:Lerp(Color3.fromRGB(235, 242, 250), s * 0.7)
				t.part.Color = c
			end
		end
	end
end

---------------------------------------------------------------- keep cells around the player
local lastCX, lastCZ = nil, nil
local function focusPos()
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position or camera.CFrame.Position
end
local function anyActive()
	return amt.snow > 0.001 or amt.leaves > 0.001 or amt.petals > 0.001
end
local function rebuildNeeded(pos)
	local R = radius()
	local cx, cz = math.floor(pos.X / CELL), math.floor(pos.Z / CELL)
	if cx == lastCX and cz == lastCZ then return end
	lastCX, lastCZ = cx, cz
	local r = math.ceil(R / CELL)
	-- drop far cells
	for key, cell in pairs(cells) do
		if (cell.cx - cx) ^ 2 + (cell.cz - cz) ^ 2 > (r + 2) ^ 2 then clearCell(cell) cells[key] = nil end
	end
	-- queue new cells, nearest first
	local add = {}
	for dx = -r, r do
		for dz = -r, r do
			local d2 = dx * dx + dz * dz
			if d2 <= r * r then
				local key = keyOf(cx + dx, cz + dz)
				if not cells[key] and not pendingSet[key] then table.insert(add, { key, cx + dx, cz + dz, d2 }) end
			end
		end
	end
	table.sort(add, function(a, b) return a[4] < b[4] end)
	for _, a in ipairs(add) do
		pendingSet[a[1]] = true
		table.insert(pending, { key = a[1], cx = a[2], cz = a[3] })
	end
end
local function clearAll()
	for _, cell in pairs(cells) do clearCell(cell) end
	cells, pending, pendingSet = {}, {}, {}
	lastCX, lastCZ = nil, nil
end

---------------------------------------------------------------- footsteps, footprints, puffs
local prints = {}
local function playStep(list, vol)
	local s = Instance.new("Sound")
	s.SoundId = list[rand:NextInteger(1, #list)]
	s.Volume = vol
	s.PlaybackSpeed = rand:NextNumber(0.9, 1.15)
	if SFX then s.SoundGroup = SFX end
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 1.5)
end
local function puff(pos, color, n)
	local a = Instance.new("Attachment")
	a.WorldPosition = pos
	a.Parent = terrain
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0.7) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.35, 0.6) e.Speed = NumberRange.new(1.5, 3) e.SpreadAngle = Vector2.new(70, 70)
	e.Acceleration = Vector3.new(0, -6, 0) e.EmissionDirection = Enum.NormalId.Top e.Rate = 0 e.LightEmission = 0.1
	e.Parent = a
	e:Emit(n)
	Debris:AddItem(a, 1)
end
local function footprint(cf)
	local p = flat("Footprint", Vector3.new(0.75, 0.04, 1.15), Color3.fromRGB(200, 210, 225), Enum.Material.Snow)
	p.CFrame = cf
	p.Transparency = 0.15
	p.Parent = folder
	table.insert(prints, p)
	if #prints > 50 then local old = table.remove(prints, 1) if old then old:Destroy() end end
	task.delay(10, function()
		if p.Parent then
			TweenService:Create(p, TweenInfo.new(6), { Transparency = 1 }):Play()
			Debris:AddItem(p, 6.2)
		end
	end)
end

local stepClock, leftFoot = 0, false
local stepParams = RaycastParams.new()
stepParams.FilterType = Enum.RaycastFilterType.Exclude
local function footsteps(dt)
	if not on("Setting_SeasonSteps") or not on("Setting_GroundCover") then return end
	if amt.snow < 0.25 and amt.leaves < 0.25 then return end
	local ch = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.FloorMaterial == Enum.Material.Air then return end
	local v = hrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
	if v.Magnitude < 3 then stepClock = 0 return end
	stepClock += dt
	local interval = math.clamp(5.4 / v.Magnitude, 0.22, 0.5)
	if stepClock < interval then return end
	stepClock = 0
	leftFoot = not leftFoot
	stepParams.FilterDescendantsInstances = { ch, folder }
	local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -8, 0), stepParams)
	if not hit then return end
	-- only counts if this spot is an outdoor (sky-open) surface
	local cell = cells[keyOf(math.floor(hit.Position.X / CELL), math.floor(hit.Position.Z / CELL))]
	if not cell or not cell.ok or (cell.part ~= hit.Instance) then return end
	if amt.snow >= 0.25 and (cell.terrain or (cell.tile and cell.level and cell.level > 2)) then
		playStep(SND_SNOW, 0.45)
		local dir = v.Unit
		local side = dir:Cross(Vector3.yAxis) * (leftFoot and 0.45 or -0.45)
		local top = cell.terrain and hit.Position.Y + 0.05 or (cell.tile.Position.Y + cell.tile.Size.Y / 2 + 0.01)
		local pos = Vector3.new(hit.Position.X, top, hit.Position.Z) + side
		footprint(CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, 0, 0))
		puff(pos, Color3.fromRGB(245, 248, 255), 5)
	elseif amt.leaves >= 0.25 then
		playStep(SND_LEAF, 0.35)
		puff(hit.Position, LEAF_COLORS[rand:NextInteger(1, #LEAF_COLORS)], 3)
	end
end

---------------------------------------------------------------- frosty breath + butterflies
local breathNext = 0
local function breath()
	if not on("Setting_SeasonCritters") or amt.snow < 0.15 then return end
	if os.clock() < breathNext then return end
	breathNext = os.clock() + rand:NextNumber(2.2, 3.4)
	local me = focusPos()
	for _, p in ipairs(Players:GetPlayers()) do
		local head = p.Character and p.Character:FindFirstChild("Head")
		if head and (head.Position - me).Magnitude < 70 then
			-- only outside
			if not workspace:Raycast(head.Position, Vector3.new(0, 120, 0), rayParams) then
				local pos = (head.CFrame * CFrame.new(0, -0.2, -0.75)).Position
				local a = Instance.new("Attachment") a.WorldPosition = pos a.Parent = terrain
				local e = Instance.new("ParticleEmitter")
				e.Texture = "rbxasset://textures/particles/smoke_main.dds"
				e.Color = ColorSequence.new(Color3.fromRGB(240, 245, 255))
				e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.9) })
				e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
				e.Lifetime = NumberRange.new(0.9, 1.3) e.Speed = NumberRange.new(0.8, 1.4) e.SpreadAngle = Vector2.new(15, 15)
				e.Acceleration = Vector3.new(0, 0.6, 0) e.Rate = 0
				a.CFrame = CFrame.lookAt(pos, pos + head.CFrame.LookVector) * CFrame.Angles(-math.pi / 2, 0, 0)
				e.EmissionDirection = Enum.NormalId.Top
				e.Parent = a
				e:Emit(5)
				Debris:AddItem(a, 1.6)
			end
		end
	end
end

local BUTTERFLY_COLORS = { Color3.fromRGB(255, 190, 60), Color3.fromRGB(120, 190, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 140, 190), Color3.fromRGB(190, 140, 255) }
local butterflies = {}
local function makeButterfly()
	local col = BUTTERFLY_COLORS[rand:NextInteger(1, #BUTTERFLY_COLORS)]
	local b = { home = Vector3.zero, phase = rand:NextNumber(0, 10), speed = rand:NextNumber(0.6, 1.1) }
	b.body = flat("Butterfly", Vector3.new(0.08, 0.08, 0.35), Color3.fromRGB(40, 30, 25))
	b.left = flat("Wing", Vector3.new(0.45, 0.03, 0.5), col, Enum.Material.Neon)
	b.right = b.left:Clone()
	for _, p in ipairs({ b.body, b.left, b.right }) do p.Transparency = 1 p.Parent = folder end
	return b
end
local bfIndoor, bfCheck = false, 0
local function updateButterflies(t)
	local want = 0
	local w = showing()
	if on("Setting_SeasonCritters") and CRITTERS[w] then want = (PETALS[w] or SUMMER[w]) and (lowSpec() and 4 or 7) or (lowSpec() and 2 or 3) end
	local me = focusPos()
	if want > 0 and os.clock() - bfCheck > 0.3 then -- indoors? (checked 3x a second, not every frame)
		bfCheck = os.clock()
		bfIndoor = workspace:Raycast(me + Vector3.new(0, 3, 0), Vector3.new(0, 120, 0), rayParams) ~= nil
	end
	if bfIndoor then want = 0 end
	if want == 0 and #butterflies == 0 then return end
	while #butterflies < want do table.insert(butterflies, makeButterfly()) end
	for i, b in ipairs(butterflies) do
		if i > want then
			if b.body.Transparency < 1 then for _, p in ipairs({ b.body, b.left, b.right }) do p.Transparency = 1 end end
			b.home = Vector3.zero
		else
			if b.home == Vector3.zero or (b.home - me).Magnitude > 35 then
				b.home = me + Vector3.new(rand:NextNumber(-18, 18), rand:NextNumber(1, 5), rand:NextNumber(-18, 18))
			end
			local s = t * b.speed + b.phase
			local pos = b.home + Vector3.new(math.sin(s * 0.7) * 4 + math.sin(s * 1.9) * 1.2, math.sin(s * 1.3) * 1.2 + math.sin(s * 3.1) * 0.3, math.cos(s * 0.6) * 4)
			local ahead = b.home + Vector3.new(math.sin((s + 0.1) * 0.7) * 4 + math.sin((s + 0.1) * 1.9) * 1.2, pos.Y - b.home.Y, math.cos((s + 0.1) * 0.6) * 4)
			local cf = CFrame.lookAt(pos, ahead)
			local flap = math.sin(t * 22 + b.phase) * 0.9
			b.body.CFrame = cf
			b.left.CFrame = cf * CFrame.Angles(0, 0, flap) * CFrame.new(-0.25, 0, 0)
			b.right.CFrame = cf * CFrame.Angles(0, 0, -flap) * CFrame.new(0.25, 0, 0)
			if b.body.Transparency > 0 then for _, p in ipairs({ b.body, b.left, b.right }) do p.Transparency = 0 end b.left.Transparency = 0.1 b.right.Transparency = 0.1 end
		end
	end
end

---------------------------------------------------------------- main loop
local applyIndex = 0
local cellList = {}
local lastListBuild = 0
local lastFilter = 0
local t = 0
local wasActive = false

-- settings switched off -> wipe instantly
for _, k in ipairs({ "Setting_GroundCover", "Setting_DisableEffects", "Setting_ImproveFPS" }) do
	player:GetAttributeChangedSignal(k):Connect(function()
		if not on("Setting_GroundCover") then clearAll() end
		lastCX = nil lastTint = nil
	end)
end

RunService.Heartbeat:Connect(function(dt)
	t += dt
	local w = showing()
	local ground = on("Setting_GroundCover")
	-- grow / melt
	local snowRate = SNOW[w]
	if snowRate then amt.snow = math.min(1, amt.snow + snowRate * dt) else amt.snow = math.max(0, amt.snow - dt / 30) end
	if LEAVES[w] then amt.leaves = math.min(1, amt.leaves + dt / 28) else amt.leaves = math.max(0, amt.leaves - dt / 20) end
	if PETALS[w] then amt.petals = math.min(1, amt.petals + dt / 28) else amt.petals = math.max(0, amt.petals - dt / 20) end
	if SUMMER[w] then amt.summer = math.min(1, amt.summer + dt / 20) else amt.summer = math.max(0, amt.summer - dt / 20) end

	tint()
	breath()
	updateButterflies(t)
	footsteps(dt)

	local active = ground and anyActive()
	if not active then
		if wasActive then clearAll() end
		wasActive = false
		return
	end
	wasActive = true

	if os.clock() - lastFilter > 3 then lastFilter = os.clock() refreshFilter() end
	local pos = focusPos()
	rebuildNeeded(pos)

	-- scan a few new cells each frame (nearest first), with a time budget so it never stalls a frame
	local budget = lowSpec() and 8 or 16
	local t0 = os.clock()
	local maxTime = lowSpec() and 0.0015 or 0.003
	while budget > 0 and #pending > 0 and os.clock() - t0 < maxTime do
		local pc = table.remove(pending, 1)
		pendingSet[pc.key] = nil
		local cell = { cx = pc.cx, cz = pc.cz }
		scan(cell)
		cells[pc.key] = cell
		budget -= 1
	end

	-- apply snow / leaves to a slice of the cells each frame
	if os.clock() - lastListBuild > 0.5 then
		lastListBuild = os.clock()
		cellList = {}
		for _, cell in pairs(cells) do table.insert(cellList, cell) end
	end
	local n = #cellList
	if n == 0 then return end
	local slice = math.max(lowSpec() and 20 or 40, math.ceil(n / (lowSpec() and 16 or 10)))
	local fx, fz = pos.X, pos.Z
	for _ = 1, math.min(slice, n) do
		applyIndex = applyIndex % n + 1
		local cell = cellList[applyIndex]
		if cell then
			-- re-check old / blocked cells now and then (parts stream in, NPCs walk away)
			if (cell.retry and os.clock() - cell.scanned > 4) or os.clock() - cell.scanned > 45 then
				local oldPart = cell.part
				cell.retry = nil
				scan(cell)
				if cell.part ~= oldPart or not cell.ok then clearCell(cell) end
			end
			local cx, cz = (cell.cx + 0.5) * CELL, (cell.cz + 0.5) * CELL
			applyCell(cell, math.sqrt((cx - fx) ^ 2 + (cz - fz) ^ 2))
		end
	end
end)
