--[[ LeaderboardConfig — the 4 leaderboard stands at the Memorial Park rotunda.
  Each stand has tabs; each tab is one global OrderedDataStore (top 50).
  Fmt: "number" | "wins" | "ms" (speed run, lower is better) | "time" (seconds) | "robux"
  Source (server writes it): "Wallet:<name>" or "Attr:<attribute>". No Source = another script already writes it. ]]
local C = {}

C.TopN = 50
C.RefreshEvery = 300   -- every board is reloaded from the DataStore every 5 minutes (all servers' scores)
                       -- (players on this server still see their own new score within ~15 s)
C.WriteEvery = 120     -- seconds between saving the players' current values
C.Center = Vector3.new(-232, 0, -4.5) -- Memorial Park rotunda
C.Radius = 44

local events = {
	{ "CampusCheckIn", "📍 Check-In" }, { "QuizBee", "🧠 Quiz Bee" }, { "Booth", "🎪 Fair Booths" },
	{ "GuessTheDrawing", "🎨 Guess Drawing" }, { "TowerGame", "🗼 Sky Tower" }, { "EscapeSchool", "🗝️ Escape" },
	{ "Intramurals", "🏆 Intramurals" }, { "FoundationDay", "🎉 Foundation Day" },
}
local winTabs = { { Key = "EventWins", Label = "⭐ All Events", Store = "SC_LB_EventWins_v1", Fmt = "wins", Source = "Attr:EventWins" } }
for _, e in ipairs(events) do
	table.insert(winTabs, { Key = "Win_" .. e[1], Label = e[2], Store = "SC_LB_Win_" .. e[1] .. "_v1", Fmt = "wins", Source = "Attr:Win_" .. e[1] })
end

C.Boards = {
	{ Id = "Coins", Title = "💰 RICHEST STUDENTS", Color = Color3.fromRGB(230, 170, 40), Angle = 225, Tabs = {
		{ Key = "CommonCoins", Label = "💰 Common Coins", Store = "SC_LB_CommonCoins_v1", Fmt = "number", Source = "Wallet:Common" },
		{ Key = "RareCoins", Label = "💎 Rare Coins", Store = "SC_LB_RareCoins_v1", Fmt = "number", Source = "Wallet:Event" },
	} },
	{ Id = "Wins", Title = "🏆 EVENT CHAMPIONS", Color = Color3.fromRGB(70, 160, 255), Angle = 315, Tabs = winTabs },
	{ Id = "Speed", Title = "⏱️ SPEED RUNS", Color = Color3.fromRGB(60, 200, 130), Angle = 45, Tabs = {
		{ Key = "Tower", Label = "🗼 Sky Tower", Store = "SC_TowerBestTime_v1", Asc = true, Fmt = "ms" },
		{ Key = "PataasEasy", Label = "☁️ PATAAS Easy", Store = "SC_SkyClimbEasy_v1", Asc = true, Fmt = "ms" },
		{ Key = "PataasHard", Label = "🔥 PATAAS Hard", Store = "SC_SkyClimbHard_v1", Asc = true, Fmt = "ms" },
	} },
	{ Id = "Legends", Title = "💖 CAMPUS LEGENDS", Color = Color3.fromRGB(235, 90, 150), Angle = 135, Tabs = {
		{ Key = "StayTime", Label = "⏳ Most Stay Time", Store = "SamarCollege_PlayTime_v1", Fmt = "time" },
		{ Key = "Donated", Label = "💖 Top Donors", Store = "SC_LB_Donated_v1", Fmt = "robux" },
	} },
}

-- boards that are NOT on the park stands but use the same data + top-50 list (Summit Tower board, PATAAS island board)
C.ExtraTabs = {
	{ Key = "TowerWins", Label = "🏆 Most Summits", Store = "SC_TowerWins_v1", Fmt = "wins" },
}

function C.format(fmt, v)
	v = tonumber(v) or 0
	local function commas(n)
		local s = tostring(math.floor(n))
		return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
	end
	if fmt == "ms" then
		local sec = v / 1000
		return ("%d:%05.2f"):format(sec // 60, sec % 60)
	elseif fmt == "time" then
		local h = math.floor(v / 3600) local m = math.floor(v % 3600 / 60)
		if h > 0 then return ("%sh %dm"):format(commas(h), m) end
		return ("%dm"):format(m)
	elseif fmt == "robux" then return "R$ " .. commas(v)
	elseif fmt == "wins" then return commas(v) .. (v == 1 and " win" or " wins")
	end
	return commas(v)
end

return C
