-- LevelServer: school level (Title) progression.
-- New players start at Kindergarten. To unlock the next level a player must
--   1) spend the level's minutes AT their current level (LevelConfig.minutesFor) — this
--      "level timer" is separate from total play time and resets after each passed quiz
--      or when an admin promotes/demotes the player, and
--   2) pass the quiz of their current highest level (server-graded).
-- Players can switch freely between any level they already unlocked.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LevelConfig = require(RS:WaitForChild("LevelConfig"))
local QuizBank = require(script.Parent:WaitForChild("QuizBank"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local remotes = RS:WaitForChild("ProfileRemotes")

local MAX = #LevelConfig.Levels
local active = {}     -- player -> { level=, answers={}, started= }
local cooldown = {}   -- player -> os.clock() when they may retry

local RP = require(RS:WaitForChild("RoleplayConfig"))

-- 🎭 overhead tag for roleplayers (teacher / instructor / employee / staff)
local function roleTag(player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not head then return end
	local old = head:FindFirstChild("RoleTag")
	local l1, l2, color = RP.tagFor(player:GetAttribute("RP_Role"), player:GetAttribute("RP_1"), player:GetAttribute("RP_2"), player:GetAttribute("RP_3"))
	if not l1 then if old then old:Destroy() end return end
	local bb = old or Instance.new("BillboardGui")
	if not old then
		bb.Name = "RoleTag" bb.Size = UDim2.fromOffset(220, 46) bb.StudsOffset = Vector3.new(0, 3.4, 0) bb.MaxDistance = 70 bb.LightInfluence = 0
		local bg = Instance.new("Frame") bg.Name = "Bg" bg.Size = UDim2.fromScale(1, 1) bg.BackgroundColor3 = Color3.fromRGB(18, 22, 28) bg.BackgroundTransparency = 0.25 bg.Parent = bb
		Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)
		local st = Instance.new("UIStroke") st.Name = "Stroke" st.Thickness = 2 st.Parent = bg
		for i, name in ipairs({ "Line1", "Line2" }) do
			local t = Instance.new("TextLabel") t.Name = name t.BackgroundTransparency = 1 t.Position = UDim2.new(0, 6, i == 1 and 0.04 or 0.54, 0) t.Size = UDim2.new(1, -12, i == 1 and 0.5 or 0.42, 0)
			t.Font = i == 1 and Enum.Font.GothamBlack or Enum.Font.GothamBold t.TextScaled = true t.TextColor3 = Color3.new(1, 1, 1) t.Parent = bg
		end
		bb.Parent = head
	end
	bb.Bg.Stroke.Color = color
	bb.Bg.Line1.Text = l1 bb.Bg.Line1.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.35)
	bb.Bg.Line2.Text = l2 or ""
end

local function setTitle(player)
	local ls = player:FindFirstChild("leaderstats")
	local t = ls and ls:FindFirstChild("Title")
	local rpTitle = RP.titleFor(player:GetAttribute("RP_Role"), player:GetAttribute("RP_1"), player:GetAttribute("RP_2"), player:GetAttribute("RP_3"))
	if t then t.Value = rpTitle or LevelConfig.titleFor(player:GetAttribute("SelectedLevel") or 1, player:GetAttribute("CollegeProgram"), player:GetAttribute("SHSStrand")) end
	-- StaffAccess reads "Role" (staff-only gates, ID scanners)
	local role = RP.role(player:GetAttribute("RP_Role"))
	player:SetAttribute("Role", role.StaffRole)
	roleTag(player)
end

local function feedback(player, msg, good)
	remotes.LevelFeedback:FireClient(player, msg, good)
	local shop = RS:FindFirstChild("ShopRemotes")
	if shop and shop:FindFirstChild("UpdateCash") then shop.UpdateCash:FireClient(player, msg) end
end

local function onPlayer(player)
	player:WaitForChild("leaderstats", 30)
	local data = PlayerData.get(player) or {}
	local unlocked = math.clamp(tonumber(data.LevelUnlocked) or 1, 1, MAX)
	local selected = math.clamp(tonumber(data.SelectedLevel) or unlocked, 1, unlocked)
	player:SetAttribute("LevelUnlocked", unlocked)
	player:SetAttribute("SelectedLevel", selected)
	for _, stat in ipairs(PlayerData.STATS) do player:SetAttribute(stat, tonumber(data[stat]) or 0) end
	-- older saves had no level timer: carry over the time already earned toward the next quiz
	if data.LevelTime == nil then
		local spentBefore = (LevelConfig.Levels[unlocked] and LevelConfig.Levels[unlocked].RequiredMinutes or 0) * 60
		PlayerData.setLevelTime(player, math.max(0, PlayerData.getTime(player) - spentBefore))
	end
	setTitle(player)
	player:GetAttributeChangedSignal("SelectedLevel"):Connect(function() setTitle(player) end)
	player:GetAttributeChangedSignal("CollegeProgram"):Connect(function() setTitle(player) end)
	player:GetAttributeChangedSignal("SHSStrand"):Connect(function() setTitle(player) end)
	for _, a in ipairs({ "RP_Role", "RP_1", "RP_2", "RP_3" }) do player:GetAttributeChangedSignal(a):Connect(function() setTitle(player) end) end
	player.CharacterAdded:Connect(function(char) char:WaitForChild("Head", 10) task.wait(0.5) roleTag(player) end)
	if player.Character then task.spawn(roleTag, player) end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, p) end
Players.PlayerRemoving:Connect(function(p) active[p] = nil cooldown[p] = nil end)

remotes.SelectLevel.OnServerEvent:Connect(function(player, idx)
	idx = tonumber(idx)
	if not idx then return end
	idx = math.floor(idx)
	if idx < 1 or idx > (player:GetAttribute("LevelUnlocked") or 1) then return end
	player:SetAttribute("SelectedLevel", idx)
	feedback(player, "Title changed to " .. LevelConfig.name(idx), true)
end)

-- 🎓 pick a Samar College course (College) or strand (SHS); idx 0 = remove
remotes:WaitForChild("SelectProgram").OnServerEvent:Connect(function(player, group, idx)
	local g = LevelConfig.Programs[group]
	idx = tonumber(idx)
	if not g or not idx then return end
	idx = math.floor(idx)
	if idx < 0 or idx > #g.List then return end
	if (player:GetAttribute("LevelUnlocked") or 1) < g.MinLevel then
		feedback(player, ("Reach %s first to pick a %s"):format(LevelConfig.name(g.MinLevel), g.Label:lower()), false)
		return
	end
	player:SetAttribute(g.Attr, idx)
	local p = g.List[idx]
	-- college course → matching Intramurals team, if the player has no team yet
	if p and p.Team and group == "College" and (tonumber(player:GetAttribute("CollegeCourse")) or 0) == 0 then
		local ok, EC = pcall(function() return require(RS.Events.EventConfig) end)
		if ok and EC.Intramurals and EC.Intramurals.CollegeTeams then
			for ti, team in ipairs(EC.Intramurals.CollegeTeams) do if team.Id == p.Team then player:SetAttribute("CollegeCourse", ti) end end
		end
	end
	local sel = player:GetAttribute("SelectedLevel") or 1
	local shown = LevelConfig.programGroup(sel) == group
	feedback(player, p and (("%s set to %s%s"):format(g.Label, p.Id, shown and "" or (" (shows when you wear a " .. (group == "College" and "College" or "Grade 11–12") .. " title)"))) or (g.Label .. " removed"), true)
end)

-- 🎭 roleplay: field "role" (1 = Student) or "opt1" / "opt2" / "opt3" (index in that option list)
remotes:WaitForChild("SelectRoleplay").OnServerEvent:Connect(function(player, field, idx)
	idx = tonumber(idx)
	if not idx then return end
	idx = math.floor(idx)
	if field == "role" then
		if idx < 1 or idx > #RP.Roles then return end
		if idx ~= (player:GetAttribute("RP_Role") or 1) then
			player:SetAttribute("RP_1", 1) player:SetAttribute("RP_2", 1) player:SetAttribute("RP_3", 1)
		end
		player:SetAttribute("RP_Role", idx)
		local r = RP.Roles[idx]
		feedback(player, r.Id == "Student" and "🎒 Back to being a student" or ("🎭 You are now roleplaying as " .. r.Icon .. " " .. r.Name), true)
	else
		local row = tonumber(tostring(field):match("^opt(%d)$"))
		local r = RP.role(player:GetAttribute("RP_Role"))
		local opt = row and r.Options[row]
		if not opt or idx < 1 or idx > #opt.List then return end
		player:SetAttribute("RP_" .. row, idx)
		feedback(player, ("%s: %s"):format(opt.Label, opt.List[idx]), true)
	end
end)

local function shuffle(t) for i = #t, 2, -1 do local j = math.random(i) t[i], t[j] = t[j], t[i] end return t end

-- questions a player already got at each level this session: every new attempt picks ones they haven't
-- seen yet (random order); only when the whole level's bank is used up does it start over
local seenQ = {} -- player -> { [levelName] = { [index] = true, count = n } }
local function pickFresh(player, levelName, bank, n)
	seenQ[player] = seenQ[player] or {}
	local seen = seenQ[player][levelName]
	if not seen or seen.count + n > #bank then seen = { count = 0 } seenQ[player][levelName] = seen end
	local fresh = {}
	for i = 1, #bank do if not seen[i] then table.insert(fresh, i) end end
	shuffle(fresh)
	local picks = {}
	for i = 1, math.min(n, #fresh) do picks[i] = fresh[i] seen[fresh[i]] = true seen.count += 1 end
	return picks
end
Players.PlayerRemoving:Connect(function(p) seenQ[p] = nil end)

remotes.StartQuiz.OnServerInvoke = function(player)
	local current = player:GetAttribute("LevelUnlocked") or 1
	if current >= MAX then return { ok = false, msg = "You already reached the highest level! 🎓" } end
	local nextLevel = LevelConfig.Levels[current + 1]
	local playedMin = PlayerData.getLevelTime(player) / 60
	local needMin = LevelConfig.minutesFor(current + 1)
	if playedMin < needMin then
		return { ok = false, msg = string.format("Stay in the game %d more minute(s) to unlock the quiz.", math.ceil(needMin - playedMin)) }
	end
	if cooldown[player] and os.clock() < cooldown[player] then
		return { ok = false, msg = string.format("Review first! Try again in %d s.", math.ceil(cooldown[player] - os.clock())) }
	end
	local bank = QuizBank[LevelConfig.name(current)] or {}
	if #bank == 0 then return { ok = false, msg = "No questions yet for " .. LevelConfig.name(current) } end
	local n = math.min(LevelConfig.QuestionsPerQuiz, #bank)
	local picks = pickFresh(player, LevelConfig.name(current), bank, n)
	local questions, answers = {}, {}
	for i = 1, n do
		local q = bank[picks[i]]
		-- shuffle options and remember where the right one went
		local order = { 1, 2, 3, 4 }
		local opts = {}
		shuffle(order)
		for k = 1, #q.O do opts[k] = q.O[order[k]] if order[k] == q.A then answers[i] = k end end
		questions[i] = { Q = q.Q, O = opts }
	end
	active[player] = { level = current, answers = answers, started = os.clock() }
	return { ok = true, level = current, levelName = LevelConfig.name(current), nextName = nextLevel.Name,
		questions = questions, pass = math.min(LevelConfig.PassScore, n) }
end

remotes.SubmitQuiz.OnServerInvoke = function(player, picked)
	local quiz = active[player]
	active[player] = nil
	if not quiz or type(picked) ~= "table" then return { ok = false } end
	if (player:GetAttribute("LevelUnlocked") or 1) ~= quiz.level then return { ok = false } end
	local score, total = 0, #quiz.answers
	local correct = {}
	for i, a in ipairs(quiz.answers) do
		correct[i] = a
		if tonumber(picked[i]) == a then score += 1 end
	end
	local need = math.min(LevelConfig.PassScore, total)
	local passed = score >= need
	if passed then
		local newLevel = quiz.level + 1
		player:SetAttribute("LevelUnlocked", newLevel)
		player:SetAttribute("SelectedLevel", newLevel)
		player:SetAttribute("QuizzesPassed", (player:GetAttribute("QuizzesPassed") or 0) + 1)
		PlayerData.resetLevelTime(player) -- the timer for the next quiz starts over
		feedback(player, "🎉 Congratulations! You are now " .. LevelConfig.name(newLevel) .. "!", true)
		task.spawn(PlayerData.save, player)
	else
		cooldown[player] = os.clock() + LevelConfig.RetryCooldown
	end
	return { ok = true, score = score, total = total, need = need, passed = passed, correct = correct,
		newName = passed and LevelConfig.name(quiz.level + 1) or nil }
end
