--[[ EventRewards ────────────────────────────────────────────────────────────
  Pays event rewards on the SERVER only and keeps them saved.
  • Tokens go into the player's Wallet (Common / Event IntValues made by ShopServer).
  • Stats are the saved player attributes (EventsJoined, EventsCommon, EventsRare, ...).
  • Achievements are attributes "Ach_<Id>" = true; PlayerData saves them in the
    "Achievements" list and this module restores them when the player joins.
  • Saving uses PlayerData.save (pcall + retries inside), debounced so many rewards
    in a row only cause one save.
───────────────────────────────────────────────────────────────────────────]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS:WaitForChild("Events"):WaitForChild("EventConfig"))
local PlayerData = require(script.Parent.Parent:WaitForChild("PlayerData"))
local Remotes = RS.Events:WaitForChild("EventRemotes")

local EventRewards = {}
local MAX_SINGLE_REWARD = 5000 -- safety cap so a config typo can never pay out millions

---------------------------------------------------------------- saving (debounced)
local pendingSave = {}
function EventRewards.saveSoon(player)
	if pendingSave[player] then return end
	pendingSave[player] = true
	task.delay(5, function()
		pendingSave[player] = nil
		if player.Parent then pcall(PlayerData.save, player) end
	end)
end

---------------------------------------------------------------- currency
-- currency = "Common" or "Event". Returns the amount actually given.
function EventRewards.addCurrency(player, currency, amount)
	amount = math.clamp(math.floor(tonumber(amount) or 0), 0, MAX_SINGLE_REWARD)
	if amount <= 0 then return 0 end
	local wallet = player:FindFirstChild("Wallet") or player:WaitForChild("Wallet", 10)
	local v = wallet and wallet:FindFirstChild(currency)
	if not (v and v:IsA("IntValue")) then warn("[EventRewards] no Wallet." .. tostring(currency) .. " for " .. player.Name) return 0 end
	v.Value += amount
	EventRewards.saveSoon(player)
	return amount
end

---------------------------------------------------------------- stats
local function bump(player, stat, n)
	player:SetAttribute(stat, (tonumber(player:GetAttribute(stat)) or 0) + (n or 1))
end

-- called once when a player joins an event: EventsJoined +1, plus the rarity and event counters
function EventRewards.countJoin(player, def)
	local counted = { EventsJoined = true }
	counted[def.Rarity == "Rare" and "EventsRare" or "EventsCommon"] = true
	if def.Stat then counted[def.Stat] = true end
	for stat in pairs(counted) do bump(player, stat, 1) end
	EventRewards.grantAchievement(player, "FirstEvent")
	EventRewards.saveSoon(player)
end

---------------------------------------------------------------- achievements
-- returns true if the player did not have it yet
function EventRewards.grantAchievement(player, id)
	if not id or not Config.Achievements[id] then return false end
	local attr = "Ach_" .. id
	if player:GetAttribute(attr) == true then return false end
	player:SetAttribute(attr, true)
	local a = Config.Achievements[id]
	Remotes.EventToast:FireClient(player, ("%s Achievement unlocked: %s"):format(a.Icon or "🏅", a.Name))
	EventRewards.saveSoon(player)
	return true
end

-- restore saved achievements when the player joins (PlayerData is loaded by ShopServer)
local function restore(player)
	local data
	for _ = 1, 60 do
		data = PlayerData.get(player)
		if data or not player.Parent then break end
		task.wait(0.5)
	end
	if not data or type(data.Achievements) ~= "table" then return end
	for _, id in ipairs(data.Achievements) do
		if type(id) == "string" then player:SetAttribute("Ach_" .. id, true) end
	end
end
Players.PlayerAdded:Connect(function(p) task.spawn(restore, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(restore, p) end
Players.PlayerRemoving:Connect(function(p) pendingSave[p] = nil end)

---------------------------------------------------------------- EVENT LEVEL (XP)
-- XP is only given here, by events. Saved as the "XP" stat (PlayerData.STATS); the level is derived from it.
local XPConfig = require(RS.Events:WaitForChild("XPConfig"))
local xpRemote = Remotes:FindFirstChild("XPGain")
if not xpRemote then xpRemote = Instance.new("RemoteEvent") xpRemote.Name = "XPGain" xpRemote.Parent = Remotes end

-- keep "Lvl" attribute + the player-list "Level" column in sync with XP (silent: no popups)
local function syncLevel(player)
	local lvl = XPConfig.fromXP(player:GetAttribute("XP") or 0)
	player:SetAttribute("Lvl", lvl)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local v = ls:FindFirstChild("Level")
		if not v then v = Instance.new("IntValue") v.Name = "Level" v.Parent = ls end
		v.Value = lvl
	end
	return lvl
end
EventRewards.syncLevel = syncLevel

-- milestone achievements you already qualify for (e.g. after loading an old save)
local function checkMilestones(player, lvl, announce)
	for _, m in ipairs(XPConfig.Milestones) do
		if lvl >= m.level and player:GetAttribute("Ach_" .. m.id) ~= true then
			if announce then
				EventRewards.grantAchievement(player, m.id)
				local got = EventRewards.addCurrency(player, "Event", m.coins)
				xpRemote:FireClient(player, { milestone = m.id, name = m.name, icon = m.icon, level = m.level, coins = got })
			else
				player:SetAttribute("Ach_" .. m.id, true)
			end
		end
	end
end

-- give XP (server only). Returns the XP actually added.
function EventRewards.addXP(player, amount, reason)
	amount = math.clamp(math.floor(tonumber(amount) or 0), 0, 1000)
	if amount <= 0 or not player.Parent then return 0 end
	local before = tonumber(player:GetAttribute("XP")) or 0
	local cap = XPConfig.TotalForMax
	if before >= cap then
		xpRemote:FireClient(player, { xp = 0, total = before, maxed = true, reason = reason })
		return 0
	end
	local after = math.min(before + amount, cap)
	local oldLvl = XPConfig.fromXP(before)
	player:SetAttribute("XP", after)
	local newLvl = syncLevel(player)
	xpRemote:FireClient(player, { xp = after - before, total = after, reason = reason, oldLevel = oldLvl, level = newLvl })
	if newLvl > oldLvl then
		Remotes.EventToast:FireClient(player, ("⬆️ Level up! You are now Event Level %d"):format(newLvl))
		checkMilestones(player, newLvl, true)
	end
	EventRewards.saveSoon(player)
	return after - before
end

-- XP for one event result
function EventRewards.xpFor(def, place, hasBonus)
	local rewards = def.Rewards or {}
	local base = rewards.XP or XPConfig.Participation[def.Rarity or "Common"] or XPConfig.Participation.Common
	local xp = base + ((place and XPConfig.Places[place]) or 0)
	if hasBonus then xp += XPConfig.BonusXP end
	return xp
end

-- set up level + leaderstat once the save is loaded
local function initLevel(player)
	for _ = 1, 60 do
		if PlayerData.get(player) or not player.Parent then break end
		task.wait(0.5)
	end
	task.wait(1) -- let LevelServer copy the saved stats onto the player first
	if not player.Parent then return end
	if player:GetAttribute("XP") == nil then player:SetAttribute("XP", 0) end
	for _ = 1, 20 do if player:FindFirstChild("leaderstats") then break end task.wait(0.5) end
	local lvl = syncLevel(player)
	checkMilestones(player, lvl, false)
	player:GetAttributeChangedSignal("XP"):Connect(function() syncLevel(player) end) -- admin resets etc.
end
Players.PlayerAdded:Connect(function(p) task.spawn(initLevel, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(initLevel, p) end

---------------------------------------------------------------- end-of-event payout
-- ranking = array of players, best first (only players with a score / finish)
-- participants = { [player] = true } (everyone who joined and is still here)
-- extra = optional { [player] = { amount = n, label = "..." } } bonus (e.g. winning team)
-- Returns { [player] = { place = n|nil, amount = total, currency = "Common", lines = {...} } }
-- eligible = optional { [player] = true }: when given, only these players are paid (e.g. answered at least one question)
local function keyOf(def)
	for k, d in pairs(Config.Events) do
		if d == def or (type(d) == "table" and d.Name and d.Name == def.Name) then return k end
	end
	return nil
end
EventRewards.keyOf = keyOf

function EventRewards.payEvent(def, ranking, participants, extra, eligible)
	local rewards = def.Rewards or {}
	local currency = Config.currencyOf(def)
	local summary = {}
	local placeOf = {}
	for i, p in ipairs(ranking) do placeOf[p] = i end
	for player in pairs(participants) do
		if player.Parent == Players and (not eligible or eligible[player]) then
			local lines, total = {}, 0
			local part = rewards.Participation or 0
			if part > 0 then total += part table.insert(lines, ("Participation +%d"):format(part)) end
			local place = placeOf[player]
			local bonus = place and rewards.Places and rewards.Places[place]
			if bonus then
				total += bonus
				table.insert(lines, ({ "🥇 1st place", "🥈 2nd place", "🥉 3rd place" })[place] .. (" +%d"):format(bonus))
			end
			local ex = extra and extra[player]
			if ex and ex.amount and ex.amount > 0 then total += ex.amount table.insert(lines, (ex.label or "Bonus") .. (" +%d"):format(ex.amount)) end
			local given = EventRewards.addCurrency(player, currency, total)
			-- ⭐ Event XP (only from events you took part in)
			local xp = EventRewards.addXP(player, EventRewards.xpFor(def, place, ex and ex.amount and ex.amount > 0), def.Name)
			if xp > 0 then table.insert(lines, ("⭐ +%d XP"):format(xp)) end
			if place == 1 then
				EventRewards.grantAchievement(player, "EventWinner")
				-- 🏆 leaderboard: total wins + wins for this event
				bump(player, "EventWins", 1)
				local key = keyOf(def)
				if key then bump(player, "Win_" .. key, 1) end
				EventRewards.saveSoon(player)
			end
			summary[player] = { place = place, amount = given, currency = currency, lines = lines }
		end
	end
	return summary
end

return EventRewards
