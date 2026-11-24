--[[ LeaderboardServer — global top-50 boards for the leaderboard stands (ReplicatedStorage.LeaderboardConfig)
  • Saves each player's current values (coins, event wins) to OrderedDataStores, only when they changed.
  • Speed runs / stay time / donations are written by TowerGame, SkyClimbServer, PlayerRecords, DonateServer.
  • Every board is reloaded from its store every few minutes, then merged with the live values of the
    players on this server (so your new score shows right away) and published to
    ReplicatedStorage.Leaderboards.<Key> (StringValue, JSON { t = time, rows = { {id, n, v}, ... } }).
  • Studio without API access: uses StudioStores (this test session only). ]]
local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local SSS = game:GetService("ServerScriptService")

local Cfg = require(RS:WaitForChild("LeaderboardConfig"))
local PlayerData = require(SSS:WaitForChild("PlayerData"))
local StudioStores = require(SSS:WaitForChild("StudioStores"))

local folder = RS:FindFirstChild("Leaderboards") or Instance.new("Folder")
folder.Name = "Leaderboards" folder.Parent = RS

local tabs, order = {}, {}
local function addTab(t)
	if tabs[t.Key] then return end
	tabs[t.Key] = t table.insert(order, t)
	local v = folder:FindFirstChild(t.Key) or Instance.new("StringValue")
	v.Name = t.Key v.Value = '{"rows":[]}' v.Parent = folder
end
for _, b in ipairs(Cfg.Boards) do
	for _, t in ipairs(b.Tabs) do addTab(t) end
end
for _, t in ipairs(Cfg.ExtraTabs or {}) do addTab(t) end -- Summit Tower board etc.

---------------------------------------------------------------- stores
local fake = false
do
	local ok = pcall(function() DSS:GetOrderedDataStore("SC_LB_Probe_v1"):GetSortedAsync(false, 1) end)
	if not ok then fake = true warn("[Leaderboards] DataStores are off: boards only show this test session.") end
end
local stores = {}
local function storeOf(t)
	if stores[t.Store] then return stores[t.Store] end
	local s
	if not fake then local ok, r = pcall(function() return DSS:GetOrderedDataStore(t.Store) end) s = ok and r or nil end
	s = s or StudioStores.dataStore()
	stores[t.Store] = s
	return s
end

---------------------------------------------------------------- live values of players on this server
local function loaded(p) return PlayerData.get(p) ~= nil end
local function liveValue(p, t)
	if not loaded(p) then return nil end
	if t.Source then
		local kind, name = t.Source:match("^(%w+):(.+)$")
		if kind == "Wallet" then
			local w = p:FindFirstChild("Wallet") local v = w and w:FindFirstChild(name)
			return v and v.Value or nil
		end
		return tonumber(p:GetAttribute(name))
	end
	if t.Key == "Donated" then return tonumber(p:GetAttribute("Donated")) end
	if t.Key == "TowerWins" then return tonumber(p:GetAttribute("TowerWins")) end
	if t.Key == "StayTime" then return math.floor(PlayerData.getTime(p)) end
	local sec
	if t.Key == "Tower" then sec = tonumber(p:GetAttribute("TowerBestTime"))
	elseif t.Key == "PataasEasy" then sec = tonumber(p:GetAttribute("SkyBestEasy"))
	elseif t.Key == "PataasHard" then sec = tonumber(p:GetAttribute("SkyBestHard")) end
	return sec and sec > 0 and math.floor(sec * 1000) or nil
end

---------------------------------------------------------------- names
local names = {}
local function nameOf(id)
	if names[id] then return names[id] end
	local p = Players:GetPlayerByUserId(id)
	if p then names[id] = p.DisplayName return names[id] end
	local ok, n = pcall(function() return Players:GetNameFromUserIdAsync(id) end)
	if ok and n then names[id] = n end
	return names[id] or ("Player " .. id)
end
Players.PlayerAdded:Connect(function(p) names[p.UserId] = p.DisplayName end)
-- ONE call for up to 200 names (asking one by one took up to 50 calls per board = the slow boards)
local UserService = game:GetService("UserService")
local function prefetchNames(ids)
	local need = {}
	for _, id in ipairs(ids) do
		if not names[id] then
			local p = Players:GetPlayerByUserId(id)
			if p then names[id] = p.DisplayName elseif id > 0 then table.insert(need, id) end
		end
	end
	for i = 1, #need, 200 do
		local batch = table.move(need, i, math.min(i + 199, #need), 1, {})
		local ok, infos = pcall(function() return UserService:GetUserInfosByUserIdsAsync(batch) end)
		if ok and type(infos) == "table" then
			for _, info in ipairs(infos) do names[info.Id] = info.DisplayName or info.Username end
		end
	end
end

---------------------------------------------------------------- publish (store rows + live players)
local raw = {} -- key -> { [userId] = value } from the store
local reloadedAt = {} -- key -> os.time() of the last DataStore reload
local function better(t, a, b) if t.Asc then return a < b end return a > b end
local function publish(key)
	local t = tabs[key]
	local vals = {}
	for id, v in pairs(raw[key] or {}) do vals[id] = v end
	for _, p in ipairs(Players:GetPlayers()) do
		local v = liveValue(p, t)
		if v and v > 0 then
			-- the live value of a player on this server is always the newest one (the admin panel may have
			-- changed it, or a new best time was just set)
			vals[p.UserId] = v
		elseif v == 0 or v == nil then
			-- reset to 0 on this server (admin) → not on the board, even if the store still has an old value
			if loaded(p) and raw[key] and raw[key][p.UserId] == nil then vals[p.UserId] = nil end
		end
	end
	local list = {}
	for id, v in pairs(vals) do if v > 0 then table.insert(list, { id, v }) end end
	table.sort(list, function(a, b) if a[2] == b[2] then return a[1] < b[1] end return better(t, a[2], b[2]) end)
	local rows = {}
	for i = 1, math.min(#list, Cfg.TopN) do
		rows[i] = { id = list[i][1], n = nameOf(list[i][1]), v = list[i][2] }
	end
	local sv = folder:FindFirstChild(key)
	-- r = when this board was last reloaded from the DataStore, every = seconds between reloads (boards show a countdown)
	if sv then sv.Value = Http:JSONEncode({ t = os.time(), r = reloadedAt[key] or os.time(), every = Cfg.RefreshEvery, rows = rows }) end
end

local function reload(key)
	local t = tabs[key]
	local ok, pages = pcall(function() return storeOf(t):GetSortedAsync(t.Asc == true, Cfg.TopN) end)
	if ok and pages then
		local map = {}
		local ids = {}
		for _, e in ipairs(pages:GetCurrentPage()) do
			local id, v = tonumber(e.key), tonumber(e.value)
			if id and v and v > 0 then map[id] = v table.insert(ids, id) end
		end
		raw[key] = map
		prefetchNames(ids)
	end
	reloadedAt[key] = os.time()
	publish(key)
end

---------------------------------------------------------------- saving current values (only when changed)
local written = {} -- player -> { key = value }
local function writePlayer(p)
	if not loaded(p) then return end
	written[p] = written[p] or {}
	for _, t in ipairs(order) do
		if t.Source then
			local v = liveValue(p, t)
			if v and v > 0 and written[p][t.Key] ~= v then
				local ok = pcall(function() storeOf(t):SetAsync(tostring(p.UserId), math.floor(v)) end)
				if ok then written[p][t.Key] = v
					raw[t.Key] = raw[t.Key] or {} raw[t.Key][p.UserId] = math.floor(v) end
				task.wait(0.2)
			end
		end
	end
end

Players.PlayerRemoving:Connect(function(p)
	pcall(writePlayer, p)
	written[p] = nil
end)
game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(pcall, writePlayer, p) end
	task.wait(3)
end)

-- saving loop
task.spawn(function()
	task.wait(20)
	while true do
		for _, p in ipairs(Players:GetPlayers()) do pcall(writePlayer, p) end
		task.wait(Cfg.WriteEvery)
	end
end)

-- reload loop: first pass FAST (every board filled ~right after the server starts), then every board
-- once every RefreshEvery (5 min), spread out so the DataStore isn't hit all at once
task.spawn(function()
	task.wait(3)
	for _, t in ipairs(order) do pcall(reload, t.Key) task.wait(0.4) end
	while true do
		for _, t in ipairs(order) do
			task.wait(Cfg.RefreshEvery / #order)
			pcall(reload, t.Key)
		end
	end
end)

-- fast live refresh (no DataStore calls): new scores of players here show within ~15 s
task.spawn(function()
	while true do
		task.wait(15)
		for _, t in ipairs(order) do pcall(publish, t.Key) end
	end
end)

-- the ADMIN panel sets (or removes) one player's value on a board, even if it's worse than before
-- (speed runs normally only ever keep the fastest time). value nil / 0 = remove the player from the board.
local setFn = SSS:FindFirstChild("LeaderboardSet") or Instance.new("BindableFunction")
setFn.Name = "LeaderboardSet" setFn.Parent = SSS
setFn.OnInvoke = function(key, userId, value)
	local t = tabs[key]
	userId = tonumber(userId)
	if not t or not userId then return false end
	value = tonumber(value)
	local ok
	if not value or value <= 0 then
		ok = pcall(function() storeOf(t):RemoveAsync(tostring(userId)) end)
		if raw[key] then raw[key][userId] = nil end
	else
		value = math.floor(value)
		ok = pcall(function() storeOf(t):SetAsync(tostring(userId), value) end)
		raw[key] = raw[key] or {} raw[key][userId] = value
	end
	-- don't let the old "already written" memory skip the next normal save
	for p, w in pairs(written) do if p.UserId == userId then w[key] = nil end end
	pcall(publish, key)
	return ok
end

-- other scripts (DonateServer) can add to a board right away
local bump = SSS:FindFirstChild("LeaderboardBump") or Instance.new("BindableEvent")
bump.Name = "LeaderboardBump" bump.Parent = SSS
bump.Event:Connect(function(key) if tabs[key] then pcall(publish, key) end end)
