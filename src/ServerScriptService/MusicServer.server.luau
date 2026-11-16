--[[ MusicServer — saves each player's music data and runs "Listen Together" parties.

  Remotes (created here in ReplicatedStorage.Music):
    MusicFunction (RemoteFunction)
      "load"                -> { favs = {ids}, playlist = {ids}, vol, shuffle, rep }
      "save", data          -> true   (throttled, saved for real on leave)
      "parties"             -> list of open parties
    MusicEvent (RemoteEvent)
      client -> server: "host" | "join", hostUserId | "leave" | "update", state
      server -> client: "party", partyInfo|nil   "state", state   "toast", text

  A party state is { songId, startedAt (server time when the song was at 0:00), paused, pausedAt }.
  Only the host may change it; everyone in the party plays the same song at the same spot. ]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:WaitForChild("Music")
local Library = require(folder:WaitForChild("MusicLibrary"))

local fn = folder:FindFirstChild("MusicFunction") or Instance.new("RemoteFunction")
fn.Name = "MusicFunction"
fn.Parent = folder
local ev = folder:FindFirstChild("MusicEvent") or Instance.new("RemoteEvent")
ev.Name = "MusicEvent"
ev.Parent = folder

local store = nil
pcall(function() store = DataStoreService:GetDataStore("SC_Music_v1") end)

local MAX_LIST = 200
local data = {}      -- [player] = saved table
local dirty = {}     -- [player] = true when there is unsaved data
local lastSave = {}  -- [player] = os.clock()

local function cleanIds(list)
	local out, seen = {}, {}
	if type(list) ~= "table" then return out end
	for _, id in ipairs(list) do
		if type(id) == "number" and Library.ById[id] and not seen[id] then
			seen[id] = true
			table.insert(out, id)
			if #out >= MAX_LIST then break end
		end
	end
	return out
end

local function clean(d)
	d = type(d) == "table" and d or {}
	local vol = tonumber(d.vol) or 0.5
	local rep = d.rep
	if rep ~= "off" and rep ~= "all" and rep ~= "one" then rep = "all" end
	return {
		favs = cleanIds(d.favs),
		playlist = cleanIds(d.playlist),
		vol = math.clamp(vol, 0, 1),
		shuffle = d.shuffle == true,
		rep = rep,
	}
end

local function saveNow(player)
	if not store or not data[player] then return end
	dirty[player] = nil
	lastSave[player] = os.clock()
	local ok, err = pcall(function() store:SetAsync("u_" .. player.UserId, data[player]) end)
	if not ok then warn("[MusicServer] save failed for " .. player.Name .. ": " .. tostring(err)) end
end

local function loadData(player)
	if data[player] then return data[player] end
	local saved = nil
	if store then
		local ok, res = pcall(function() return store:GetAsync("u_" .. player.UserId) end)
		if ok then saved = res end
	end
	data[player] = clean(saved)
	return data[player]
end

------------------------------------------------------------ LISTEN TOGETHER
local parties = {}   -- [hostUserId] = { host = player, members = {[player]=true}, state = {...} }
local memberOf = {}  -- [player] = hostUserId

local function partyInfo(p)
	local names = {}
	for m in pairs(p.members) do table.insert(names, m.DisplayName) end
	table.sort(names)
	return { hostId = p.host.UserId, hostName = p.host.DisplayName, listeners = names, count = #names, state = p.state }
end

local function broadcast(p, ...)
	for m in pairs(p.members) do ev:FireClient(m, ...) end
end

local function leave(player)
	local hid = memberOf[player]
	if not hid then return end
	memberOf[player] = nil
	local p = parties[hid]
	if not p then return end
	p.members[player] = nil
	ev:FireClient(player, "party", nil)
	if p.host == player then
		-- host left: close the party for everyone
		parties[hid] = nil
		for m in pairs(p.members) do
			memberOf[m] = nil
			ev:FireClient(m, "party", nil)
			ev:FireClient(m, "toast", "🎧 " .. player.DisplayName .. " ended the listening party")
		end
	else
		broadcast(p, "party", partyInfo(p))
	end
end

local function validState(s)
	if type(s) ~= "table" then return nil end
	local id = tonumber(s.songId)
	if not id or not Library.ById[id] then return nil end
	local now = workspace:GetServerTimeNow()
	local startedAt = tonumber(s.startedAt) or now
	if math.abs(startedAt - now) > 3600 then startedAt = now end
	return {
		songId = id,
		startedAt = startedAt,
		paused = s.paused == true,
		pausedAt = math.max(0, tonumber(s.pausedAt) or 0),
	}
end

ev.OnServerEvent:Connect(function(player, action, arg)
	if action == "host" then
		leave(player)
		local st = validState(arg)
		if not st then ev:FireClient(player, "toast", "Play a song first, then start a party") return end
		local p = { host = player, members = { [player] = true }, state = st }
		parties[player.UserId] = p
		memberOf[player] = player.UserId
		ev:FireClient(player, "party", partyInfo(p))
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then ev:FireClient(other, "toast", "🎧 " .. player.DisplayName .. " started a listening party — open 🎵 Music to join") end
		end
	elseif action == "join" then
		local p = parties[tonumber(arg) or 0]
		if not p then ev:FireClient(player, "toast", "That party has ended") return end
		if memberOf[player] == p.host.UserId then return end
		leave(player)
		p.members[player] = true
		memberOf[player] = p.host.UserId
		broadcast(p, "party", partyInfo(p))
		ev:FireClient(p.host, "toast", "🎧 " .. player.DisplayName .. " joined your party")
	elseif action == "leave" then
		leave(player)
	elseif action == "update" then
		local p = parties[player.UserId]
		if not p then return end
		local st = validState(arg)
		if not st then return end
		p.state = st
		for m in pairs(p.members) do
			if m ~= player then ev:FireClient(m, "state", st) end
		end
	end
end)

fn.OnServerInvoke = function(player, action, arg)
	if action == "load" then
		return loadData(player)
	elseif action == "save" then
		data[player] = clean(arg)
		dirty[player] = true
		return true
	elseif action == "parties" then
		local list = {}
		for _, p in pairs(parties) do table.insert(list, partyInfo(p)) end
		table.sort(list, function(a, b) return a.count > b.count end)
		return list
	end
	return nil
end

-- save changed data every ~60 s, and always on leave / shutdown
task.spawn(function()
	while true do
		task.wait(15)
		for player in pairs(dirty) do
			if player.Parent and os.clock() - (lastSave[player] or 0) > 60 then saveNow(player) end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	leave(player)
	if dirty[player] then saveNow(player) end
	data[player], dirty[player], lastSave[player] = nil, nil, nil
end)

game:BindToClose(function()
	for player in pairs(dirty) do task.spawn(saveNow, player) end
	task.wait(2)
end)
