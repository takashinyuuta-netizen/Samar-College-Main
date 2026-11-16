--[[ XPConfig — the Event Level system (shared by server and client)
  • XP is ONLY earned by taking part in campus events (paid out with the event rewards).
  • Level 1 → 100 (max). XP needed for the next level grows each level.
  • Milestone levels unlock an achievement + a one-time Event-coin bonus. ]]
local XP = {}
XP.MAX_LEVEL = 100

-- XP from one event
XP.Participation = { Common = 40, Rare = 75 } -- by event rarity (an event can override with Rewards.XP)
XP.Places = { 60, 40, 25 }                       -- 1st / 2nd / 3rd place bonus
XP.BonusXP = 20                                  -- extra reward (e.g. winning team)

-- XP needed to go from level L to L+1
function XP.need(level) return 30 + 6 * level end

-- total XP needed to reach a level
local totals = { [1] = 0 }
for L = 2, XP.MAX_LEVEL do totals[L] = totals[L - 1] + XP.need(L - 1) end
XP.TotalForMax = totals[XP.MAX_LEVEL]
function XP.totalFor(level) return totals[math.clamp(level, 1, XP.MAX_LEVEL)] end

-- level + progress from total XP → level, xpIntoLevel, xpNeededThisLevel (0 at max)
function XP.fromXP(xp)
	xp = math.max(0, math.floor(tonumber(xp) or 0))
	local lo, hi = 1, XP.MAX_LEVEL
	while lo < hi do
		local mid = math.floor((lo + hi + 1) / 2)
		if totals[mid] <= xp then lo = mid else hi = mid - 1 end
	end
	if lo >= XP.MAX_LEVEL then return XP.MAX_LEVEL, 0, 0 end
	return lo, xp - totals[lo], XP.need(lo)
end

-- level badge colour (bronze → silver → gold → emerald → purple → legend red)
XP.Tiers = {
	{ min = 1,   name = "Bronze",   color = Color3.fromRGB(205, 127, 70) },
	{ min = 10,  name = "Silver",   color = Color3.fromRGB(200, 205, 215) },
	{ min = 25,  name = "Gold",     color = Color3.fromRGB(245, 195, 60) },
	{ min = 50,  name = "Emerald",  color = Color3.fromRGB(60, 210, 140) },
	{ min = 75,  name = "Amethyst", color = Color3.fromRGB(175, 110, 255) },
	{ min = 100, name = "Legend",   color = Color3.fromRGB(255, 80, 90) },
}
function XP.tierOf(level)
	local t = XP.Tiers[1]
	for _, tier in ipairs(XP.Tiers) do if level >= tier.min then t = tier end end
	return t
end

-- milestone achievements (ids are also added to EventConfig.Achievements so they save + toast)
XP.Milestones = {
	{ level = 5,   id = "Level5",   name = "Rising Star",           icon = "⭐", coins = 50 },
	{ level = 10,  id = "Level10",  name = "Event Regular",         icon = "🎟️", coins = 100 },
	{ level = 20,  id = "Level20",  name = "Campus Favorite",       icon = "🎈", coins = 150 },
	{ level = 30,  id = "Level30",  name = "Spirit of Samar",       icon = "🔥", coins = 200 },
	{ level = 40,  id = "Level40",  name = "Event Enthusiast",      icon = "🎪", coins = 250 },
	{ level = 50,  id = "Level50",  name = "Event Veteran",         icon = "🎖️", coins = 400 },
	{ level = 60,  id = "Level60",  name = "Campus Celebrity",      icon = "🌟", coins = 450 },
	{ level = 75,  id = "Level75",  name = "Legend in the Making",  icon = "💎", coins = 600 },
	{ level = 90,  id = "Level90",  name = "Hall of Fame",          icon = "🏛️", coins = 800 },
	{ level = 100, id = "Level100", name = "Samar College Legend",  icon = "👑", coins = 1500 },
}
return XP
