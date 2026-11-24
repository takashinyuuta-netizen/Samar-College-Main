-- GrassToggle: Settings > "🌿 Grass" (player attribute Setting_Grass, saved between visits).
-- OFF = the moving grass blades are removed for you only: the Grass ground turns into flat LeafyGrass
-- ground (same green look, no blades), so it is lighter for the device. ON = the blades come back exactly
-- where they were (ReplicatedStorage.GrassMap lists every grass voxel).
-- The world streams in and out around you, so while OFF this keeps checking the ground near you.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Terrain = workspace.Terrain
local GRASS, FLAT = Enum.Material.Grass, Enum.Material.LeafyGrass
local RANGE = 520           -- studs around the camera that are kept grass-free while OFF

local map = require(RS:WaitForChild("GrassMap"))
local tiles = {}
for i, t in ipairs(map) do
	local x, z, y0, y1 = t[1], t[2], t[3], t[4]
	tiles[i] = {
		region = Region3.new(Vector3.new(x, y0, z), Vector3.new(x + 32, y1 + 4, z + 32)),
		center = Vector3.new(x + 16, 0, z + 16),
		y0 = y0, x = x, z = z,
		cells = t[5],
	}
end
map = nil

local done = {}       -- [tile] = true when its blades are off for us
local grassOff = false

local function firstCellRegion(t)
	local a, b = string.byte(t.cells, 1, 2)
	local v = a - 48
	local ix, iz, iy = v // 8, v % 8, b - 48
	local p = Vector3.new(t.x + ix * 4, t.y0 + iy * 4, t.z + iz * 4)
	return Region3.new(p, p + Vector3.new(4, 4, 4))
end

local function turnOffNear()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local p = cam.CFrame.Position
	local flat = Vector3.new(p.X, 0, p.Z)
	local n = 0
	for _, t in ipairs(tiles) do
		if not grassOff then return end
		if not done[t] and (t.center - flat).Magnitude < RANGE then
			pcall(Terrain.ReplaceMaterial, Terrain, t.region, 4, GRASS, FLAT)
			done[t] = true
			n += 1
			if n % 25 == 0 then task.wait() end
		end
	end
end

-- ground that streamed out and back in comes back with blades: find it and switch it off again
local function recheckNear()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local p = cam.CFrame.Position
	local flat = Vector3.new(p.X, 0, p.Z)
	local n = 0
	for _, t in ipairs(tiles) do
		if not grassOff then return end
		if done[t] and (t.center - flat).Magnitude < RANGE then
			local ok, m = pcall(Terrain.ReadVoxels, Terrain, firstCellRegion(t), 4)
			if ok and m[1][1][1] == GRASS then done[t] = nil end
			n += 1
			if n % 60 == 0 then task.wait() end
		end
	end
end

local function restoreAll()
	local n = 0
	for t in pairs(done) do
		if grassOff then return end
		local ok, mats, occ = pcall(Terrain.ReadVoxels, Terrain, t.region, 4)
		if ok then
			local s = t.cells
			for c = 1, #s, 2 do
				local a, b = string.byte(s, c, c + 1)
				local v = a - 48
				local ix, iz, iy = v // 8 + 1, v % 8 + 1, b - 48 + 1
				local col = mats[ix] and mats[ix][iy]
				if col and col[iz] == FLAT then col[iz] = GRASS end
			end
			pcall(Terrain.WriteVoxels, Terrain, t.region, 4, mats, occ)
		end
		done[t] = nil
		n += 1
		if n % 20 == 0 then task.wait() end
	end
end

local loopRunning = false
local function setGrass(on)
	if grassOff == not on then return end
	grassOff = not on
	if grassOff then
		if loopRunning then return end
		loopRunning = true
		task.spawn(function()
			local k = 0
			while grassOff do
				turnOffNear()
				k += 1
				if k % 4 == 0 then recheckNear() end
				task.wait(1.5)
			end
			loopRunning = false
		end)
	else
		task.spawn(restoreAll)
	end
end

local function sync() setGrass(player:GetAttribute("Setting_Grass") ~= false) end
player:GetAttributeChangedSignal("Setting_Grass"):Connect(sync)
sync()
