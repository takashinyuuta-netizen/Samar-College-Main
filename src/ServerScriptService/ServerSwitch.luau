--[[ ServerSwitch – Main server / Kid server
  • Main server = Junior High, Senior High & College (public servers of this place).
  • Kid server  = Elementary. If HUDConfig.ElementaryPlaceId is set, players go to that place.
                  Otherwise a shared RESERVED server of this same place is used as the Kid server
                  (its access code is saved in the DataStore "SC_Servers" so everyone joins the same one).
  The server type is stored in workspace attribute "ServerType" ("Main" / "Kid").
  Teleports only work in the published game (not in Studio).
]]
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local HUDConfig = require(RS:WaitForChild("HUDConfig"))

local M = {}
M.KID_SERVER_OPEN = false -- 🧸 no teleport to the Kid Server game (it is its own experience; players join it from Roblox)
local cooldown = {}

local function elementaryPlace() return tonumber(HUDConfig.ElementaryPlaceId) or 0 end

-- what kind of server is this? (sets workspace.ServerType)
function M.detect()
	local t = "Main"
	if elementaryPlace() > 0 and game.PlaceId == elementaryPlace() then
		t = "Kid"
	elseif game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
		-- a reserved server: players only get here through M.switch, which sends { serverType = ... }
		local p = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
		local ok, data = pcall(function() return p:GetJoinData().TeleportData end)
		if ok and type(data) == "table" and data.serverType == "Kid" then t = "Kid" end
	end
	workspace:SetAttribute("ServerType", t)
	return t
end

function M.current() return workspace:GetAttribute("ServerType") or "Main" end

local store
local function kidCode(fresh)
	store = store or DataStoreService:GetDataStore("SC_Servers")
	if not fresh then
		local ok, code = pcall(function() return store:GetAsync("KidServerCode") end)
		if ok and type(code) == "string" then return code end
	end
	local code = TeleportService:ReserveServer(game.PlaceId)
	pcall(function() store:SetAsync("KidServerCode", code) end)
	return code
end

-- send a player to "Main" or "Kid". Returns { ok, stay, teleporting, msg }
function M.switch(player, target)
	if target ~= "Main" and target ~= "Kid" then return { ok = false, msg = "Unknown server" } end
	if target == M.current() then return { ok = true, stay = true } end
	if target == "Kid" and not M.KID_SERVER_OPEN then return { ok = false, soon = true, msg = "🧸 The Kid Server is coming soon!" } end
	if RunService:IsStudio() then
		return { ok = false, studio = true, msg = "Switching servers only works in the published game — you'll stay here while testing in Studio." }
	end
	if cooldown[player] and os.clock() - cooldown[player] < 6 then return { ok = false, msg = "Please wait a moment and try again." } end
	cooldown[player] = os.clock()
	local function go(fresh)
		local opts = Instance.new("TeleportOptions")
		opts:SetTeleportData({ serverType = target, fromSelect = true })
		if target == "Kid" then
			if elementaryPlace() > 0 then
				TeleportService:TeleportAsync(elementaryPlace(), { player }, opts)
			else
				opts.ReservedServerAccessCode = kidCode(fresh)
				TeleportService:TeleportAsync(game.PlaceId, { player }, opts)
			end
		else
			TeleportService:TeleportAsync(game.PlaceId, { player }, opts) -- a public Main server
		end
	end
	local ok, err = pcall(go, false)
	if not ok and target == "Kid" and elementaryPlace() == 0 then ok, err = pcall(go, true) end -- old/full Kid server → make a new one
	if not ok then
		warn("[ServerSwitch] teleport failed: " .. tostring(err))
		return { ok = false, msg = "Couldn't switch servers right now. Try again!" }
	end
	return { ok = true, teleporting = true }
end

Players.PlayerRemoving:Connect(function(p) cooldown[p] = nil end)
return M
