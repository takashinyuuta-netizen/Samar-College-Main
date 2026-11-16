-- LevelConfig: school levels used for Titles, Profile and unlocking.
-- RequiredMinutes = total minutes a player must have played before they can take the quiz that unlocks that level.
local LevelConfig = {}

LevelConfig.Departments = {
	{ Name = "Elementary Department", Short = "Elementary", Color = Color3.fromRGB(64, 170, 110) },
	{ Name = "High School Department", Short = "High School", Color = Color3.fromRGB(70, 140, 230) },
	{ Name = "College / Tertiary Department", Short = "College", Color = Color3.fromRGB(230, 170, 50) },
}

LevelConfig.Levels = {
	{ Name = "Kindergarten", Dept = 1, RequiredMinutes = 0 },
	{ Name = "Grade 1",  Dept = 1, RequiredMinutes = 5 },
	{ Name = "Grade 2",  Dept = 1, RequiredMinutes = 10 },
	{ Name = "Grade 3",  Dept = 1, RequiredMinutes = 15 },
	{ Name = "Grade 4",  Dept = 1, RequiredMinutes = 20 },
	{ Name = "Grade 5",  Dept = 1, RequiredMinutes = 25 },
	{ Name = "Grade 6",  Dept = 1, RequiredMinutes = 30 },
	{ Name = "Grade 7",  Dept = 2, RequiredMinutes = 40 },
	{ Name = "Grade 8",  Dept = 2, RequiredMinutes = 50 },
	{ Name = "Grade 9",  Dept = 2, RequiredMinutes = 60 },
	{ Name = "Grade 10", Dept = 2, RequiredMinutes = 70 },
	{ Name = "Grade 11", Dept = 2, RequiredMinutes = 80 },
	{ Name = "Grade 12", Dept = 2, RequiredMinutes = 90 },
	{ Name = "1st Year", Dept = 3, RequiredMinutes = 105 },
	{ Name = "2nd Year", Dept = 3, RequiredMinutes = 120 },
	{ Name = "3rd Year", Dept = 3, RequiredMinutes = 135 },
	{ Name = "4th Year", Dept = 3, RequiredMinutes = 150 },
}

LevelConfig.QuestionsPerQuiz = 5
LevelConfig.PassScore = 4          -- correct answers needed (out of QuestionsPerQuiz)
LevelConfig.RetryCooldown = 30     -- seconds to wait after failing

function LevelConfig.find(name)
	for i, l in ipairs(LevelConfig.Levels) do if l.Name == name then return i end end
end
function LevelConfig.name(i) local l = LevelConfig.Levels[i] return l and l.Name or "?" end
function LevelConfig.dept(i) local l = LevelConfig.Levels[i] return l and LevelConfig.Departments[l.Dept] end

-- minutes a player must spend AT their current level before the quiz for level i unlocks
-- (the gap between two levels' RequiredMinutes, so the total path length stays the same)
function LevelConfig.minutesFor(i)
	local cur, prev = LevelConfig.Levels[i], LevelConfig.Levels[i - 1]
	if not cur then return 0 end
	return math.max(0, cur.RequiredMinutes - (prev and prev.RequiredMinutes or 0))
end


-- 🎓 Samar College programs: College players pick a COURSE, Grade 11–12 players pick a STRAND.
-- The pick is saved (CollegeProgram / SHSStrand = position in the list, 0 = none) and shown in the title:
--   "BSIT • 3rd Year"   /   "Grade 11 • STEM"
-- Team = matching Intramurals course team (EventConfig.Intramurals.CollegeTeams Id), used if no team was picked yet.
LevelConfig.Programs = {
	College = { Attr = "CollegeProgram", MinLevel = 14, Label = "College Course", List = {
		{ Id = "BSIT",       Name = "BS Information Technology",          Color = Color3.fromRGB(145, 80, 225), Team = "BSIT" },
		{ Id = "BMMA",       Name = "Bachelor of Multimedia Arts",        Color = Color3.fromRGB(200, 90, 210), Team = "BSIT" },
		{ Id = "BSCRIM",     Name = "BS Criminology",                     Color = Color3.fromRGB(150, 25, 45),  Team = "BSCRIM" },
		{ Id = "CBM",        Name = "Business & Management",              Color = Color3.fromRGB(245, 125, 30), Team = "CBM" },
		{ Id = "BSBA",       Name = "BS Business Administration",         Color = Color3.fromRGB(230, 150, 40), Team = "CBM" },
		{ Id = "COED",       Name = "College of Education",               Color = Color3.fromRGB(235, 105, 175), Team = "COED" },
		{ Id = "BEEd",       Name = "Bachelor of Elementary Education",   Color = Color3.fromRGB(240, 130, 190), Team = "COED" },
		{ Id = "BSEd",       Name = "Bachelor of Secondary Education",    Color = Color3.fromRGB(220, 90, 160), Team = "COED" },
		{ Id = "AB English", Name = "AB English Language",                Color = Color3.fromRGB(70, 150, 220) },
		{ Id = "CAS",        Name = "College of Arts & Sciences",         Color = Color3.fromRGB(60, 170, 160) },
		{ Id = "SCTI",       Name = "SCTI – Technical-Vocational",        Color = Color3.fromRGB(150, 160, 180), Team = "SCTI" },
	} },
	SHS = { Attr = "SHSStrand", MinLevel = 12, MaxLevel = 13, Label = "SHS Strand", List = {
		{ Id = "STEM",    Name = "Science, Technology, Engineering & Mathematics", Color = Color3.fromRGB(60, 140, 230) },
		{ Id = "ABM",     Name = "Accountancy, Business & Management",             Color = Color3.fromRGB(240, 170, 40) },
		{ Id = "HUMSS",   Name = "Humanities & Social Sciences",                   Color = Color3.fromRGB(200, 70, 70) },
		{ Id = "GAS",     Name = "General Academic Strand",                        Color = Color3.fromRGB(90, 180, 100) },
		{ Id = "TVL-ICT", Name = "TVL – Information & Communications Technology", Color = Color3.fromRGB(120, 90, 210) },
		{ Id = "TVL-HE",  Name = "TVL – Home Economics",                           Color = Color3.fromRGB(230, 110, 60) },
	} },
}
-- which program group a school level uses ("College", "SHS" or nil)
function LevelConfig.programGroup(levelIdx)
	if not levelIdx then return nil end
	if levelIdx >= LevelConfig.Programs.College.MinLevel then return "College" end
	if levelIdx >= LevelConfig.Programs.SHS.MinLevel and levelIdx <= LevelConfig.Programs.SHS.MaxLevel then return "SHS" end
	return nil
end
-- the title shown on the leaderboard / ID scanners
function LevelConfig.titleFor(levelIdx, collegeIdx, strandIdx)
	local name = LevelConfig.name(levelIdx)
	local g = LevelConfig.programGroup(levelIdx)
	if g == "College" then
		local p = LevelConfig.Programs.College.List[collegeIdx or 0]
		if p then return p.Id .. " • " .. name end
	elseif g == "SHS" then
		local p = LevelConfig.Programs.SHS.List[strandIdx or 0]
		if p then return name .. " • " .. p.Id end
	end
	return name
end
return LevelConfig
