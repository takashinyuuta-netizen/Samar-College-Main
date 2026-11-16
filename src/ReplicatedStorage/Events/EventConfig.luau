--[[ EventConfig ─────────────────────────────────────────────────────────────
  ONE place to tune the whole event system (Samar College [Recreate]).
  Shared by the server (EventManager) and the client (EventGui).

  • Times are in SECONDS.
  • Weight   = how likely the rotation picks the event (higher = more often).
  • Cooldown = seconds before the SAME event can be picked again.
  • Rewards  = tokens paid at the end. Currency "Common" = Common Tokens,
               "Event" = Event Tokens (these are the Wallet values in ShopServer).
  • Enabled  = false keeps an event out of the rotation (admins can still
               force-start it for testing).
  • Servers  = which server types may run it: "JuniorHighPlus" and/or "Elementary".
───────────────────────────────────────────────────────────────────────────]]
local EventConfig = {}

---------------------------------------------------------------- rotation timing
EventConfig.FirstEventDelay  = 120   -- first event after a server starts
EventConfig.RotationInterval = 120   -- 2-minute break AFTER an event fully ends (results included), then the next one is announced
EventConfig.AnnounceTime     = 45    -- lobby countdown shown before an event starts
EventConfig.ResultsTime      = 12    -- how long the results stay on screen
EventConfig.MinPlayers       = 1     -- players needed in the server to start an event
EventConfig.RetryWhenEmpty   = 60    -- if nothing can start, try again after this

---------------------------------------------------------------- rarity defaults
-- Used when an event does not set its own Weight / currency.
EventConfig.Rarity = {
	Common = { Weight = 20, Currency = "Common", Color = Color3.fromRGB(70, 170, 110), Label = "COMMON EVENT" },
	Rare   = { Weight = 4,  Currency = "Event",  Color = Color3.fromRGB(200, 120, 230), Label = "RARE EVENT" },
	Permanent = { Weight = 0, Currency = "Common", Color = Color3.fromRGB(240, 180, 60), Label = "ALWAYS OPEN" },
}

EventConfig.CurrencyNames = { Common = "Common Tokens", Event = "Event Tokens" }

---------------------------------------------------------------- events
-- Stat = the extra Profile counter this event adds to (besides EventsJoined).
EventConfig.Events = {
	-- Phase 1 smoke test: a quick check-in ring at an open area. Disable once real events exist.
	CampusCheckIn = {
		Name = "Campus Check-In", Icon = "📍", Rarity = "Common", Enabled = false, -- test event: admins can still force-start it
		Weight = 6, Duration = 90, Cooldown = 600, Stat = "EventsCommon",
		Description = "Step into the glowing ring! The first students to check in earn bonus tokens.",
		Servers = { "JuniorHighPlus", "Elementary" },
		Rewards = { Currency = "Common", Participation = 15, Places = { 40, 25, 15 } },
	},
	QuizBee = {
		Name = "Quiz Bee", Icon = "🧠", Rarity = "Common", Enabled = true,
		Weight = 30, Duration = 300, Cooldown = 1800, Stat = "EventsCommon",
		Description = "A competitive quiz in one classroom. Your level must be equal or higher than the room's level.",
		Servers = { "JuniorHighPlus", "Elementary" },
		Rewards = { Currency = "Common", Participation = 20, Places = { 60, 40, 25 } },
	},
	Booth = {
		Name = "School Fair Booths", Icon = "🎪", Rarity = "Common", Enabled = true,
		Weight = 25, Duration = 360, Cooldown = 1800, Stat = "EventsCommon",
		Description = "The School Fair is open in the 1F Open Hall! Play the booths and win tickets.",
		Servers = { "JuniorHighPlus", "Elementary" },
		Rewards = { Currency = "Common", Participation = 15, Places = { 50, 35, 20 } },
	},
	GuessTheDrawing = {
		Name = "Guess the Drawing", Icon = "🎨", Rarity = "Common", Enabled = true,
		Weight = 20, Duration = 300, Cooldown = 1800, Stat = "EventsCommon",
		Description = "One student draws a school word, everyone else guesses fast!",
		Servers = { "JuniorHighPlus", "Elementary" },
		Rewards = { Currency = "Common", Participation = 15, Places = { 50, 35, 20 } },
	},
	TowerGame = {
		Name = "Samar Sky Tower", Icon = "🗼", Rarity = "Common", Enabled = true,
		Weight = 20, Duration = 1200, Cooldown = 1800, Stat = "EventsParkour",
		Description = "A giant random obby tower! No checkpoints — reach the top as fast as you can. Wins and best times are saved.",
		Servers = { "JuniorHighPlus", "Elementary" },
		Rewards = { Currency = "Common", Participation = 15, Places = { 60, 40, 25 }, PerWin = 10, MaxWinBonus = 5 },
	},
	EscapeSchool = {
		Name = "Escape Samar College", Icon = "🗝️", Rarity = "Common", Enabled = true,
		Weight = 15, Duration = 600, Cooldown = 2400, Stat = "EventsEscape",
		Description = "Find all 8 department keys hidden around campus, avoid the Teacher & Guard patrols, then unlock the Main Gate!",
		Servers = { "JuniorHighPlus" },
		Rewards = { Currency = "Common", Participation = 20, Places = { 60, 40, 25 } },
	},

	Intramurals = {
		Name = "Intramurals", Icon = "🏆", Rarity = "Rare", Enabled = true,
		Weight = 4, Duration = 600, Cooldown = 5400, Stat = "EventsRare",
		Description = "Rare event! Walk into the 🏆 Intramurals doors (1F hall) and play Badminton, Table Tennis, Pickleball, Volleyball, Basketball (3v3 / 5v5) or Chess, or perform on the 🎤 Talent Stage (sing & dance) — double coins, no Join button needed.",
		Servers = { "JuniorHighPlus", "Elementary" },
		Rewards = { Currency = "Event", Participation = 15, Places = { 40, 30, 20 }, WinningTeam = 30, Achievement = "IntramuralsChampion" },
	},
	FoundationDay = {
		Name = "Foundation Day", Icon = "🎉", Rarity = "Rare", Enabled = true,
		Weight = 2, Duration = 1020, Cooldown = 7200, Stat = "EventsRare",
		Description = "Founding Anniversary! Decorate, food booths, float parade, Mr. & Ms. Samar College pageant, cultural shows, parlor games & fireworks!",
		Servers = { "JuniorHighPlus", "Elementary" },
		Rewards = { Currency = "Event", Participation = 25, Places = { 40, 30, 20 }, Achievement = "FoundationDay" },
	},
}

---------------------------------------------------------------- Quiz Bee tuning
EventConfig.QuizBee = {
	QuestionsPerRound = 8,    -- questions in one Quiz Bee
	TimePerQuestion   = 15,   -- seconds to answer each question
	RevealTime        = 4,    -- seconds the right answer is shown
	BasePoints        = 100,  -- points for a correct answer
	SpeedBonus        = 50,   -- up to this many extra points for answering fast
	MinQuestions      = 5,    -- if the bank has fewer than this for a room, that room is skipped
}

---------------------------------------------------------------- Booth (school fair) tuning
EventConfig.Booth = {
	Radius        = 16,   -- how far the booths stand from the fair's center
	PlayCooldown  = 5,    -- seconds before the same player can play the same booth again
	-- which booth games are set up (modules in EventModules.BoothGames), in order around the fair
	Games = { "RingToss", "TargetThrow", "BalloonPop", "LuckyWheel", "HoopShot", "WhackAMole", "MemoryMatch", "GuessNumber" },
}

---------------------------------------------------------------- Guess the Drawing tuning
EventConfig.GuessTheDrawing = {
	RoundTime      = 75,  -- seconds per drawing
	BetweenRounds  = 5,   -- seconds the word is shown before the next drawer
	MaxRounds      = 8,   -- each player draws at most once, up to this many rounds
	MinPlayers     = 2,   -- needed to play (in Studio a solo tester gets a practice bot)
	GuessPoints    = 100, -- for a correct guess (+ time bonus below)
	TimeBonus      = 100, -- extra points for guessing fast
	DrawerPoints   = 40,  -- drawer earns this for every player who guesses right
	HintAt         = 0.5, -- reveal one letter when this much of the time is left
	GuessCooldown  = 1,   -- seconds between guesses
	MaxStrokePoints = 4000, -- per round (anti-spam)
}

---------------------------------------------------------------- Samar Sky Tower tuning (parkour)
EventConfig.TowerGame = {
	Center      = Vector3.new(146.5, 0.5, 40),  -- courtyard (quad) center, ground level
	Size        = 64,    -- inside width of the tower (studs)
	FloorHeight = 30,    -- height of one floor
	Floors      = 16,    -- floors per tower (random order from EventModules.TowerSections) → ~480 studs tall
	EasyTopFloors = 2,   -- the last floors only use Difficulty = 1 designs (a friendlier finish)
	VanishDelay = 2,     -- seconds before a disappearing / crumbling tile vanishes after you touch it
	CheckpointEvery = 3, -- a checkpoint on floors 4, 7, 10, 13 …
	ReturnDelay = 4,     -- seconds on the summit before you are sent back down for another run
	LeaderboardRefresh = 45,
	-- red blocks HURT instead of instantly resetting; at 0 HP you go back to your checkpoint
	Damage = { Brick = 20, Spinner = 30, Laser = 25, Swing = 25, Lava = 35 },
	HitCooldown    = 0.6, -- seconds of protection after a hit
	RegenDelay     = 2.5, -- seconds without being hit before you heal
	RegenPerSecond = 6,   -- HP healed per second while safe
	Music = {
		Background = "rbxassetid://9040071406",              -- "Forging New Heroes (Perc)" (APM) – epic climbing beat
		Checkpoint = "rbxasset://sounds/electronicpingshort.wav", -- built-in
		Hurt       = "rbxasset://sounds/electronicpingshort.wav", -- built-in, played low-pitched as a "bonk"
	},
}

---------------------------------------------------------------- Escape the School tuning
EventConfig.EscapeSchool = {
	-- the 8 department keys: each spawns in ONE random room from its list (room model names in */02_Rooms)
	Keys = {
		{ Id = "BSIT", Name = "BSIT / BMMA", Color = Color3.fromRGB(60, 140, 230), Rooms = { "CSS_Laboratory", "ComputerLab_1", "ComputerLab_2", "InternetRoom" } },
		{ Id = "CBM", Name = "CBM", Color = Color3.fromRGB(240, 190, 50), Rooms = { "ADM301", "ADM302", "ADM303", "AccountingOffice" } },
		{ Id = "BSCRIM", Name = "BSCRIM", Color = Color3.fromRGB(200, 60, 60), Rooms = { "Library_BSIT_BSCRIM", "Criminology_FacultyOffice", "ADM401", "ADM403" } },
		{ Id = "SCTI", Name = "SCTI", Color = Color3.fromRGB(150, 90, 210), Rooms = { "SCTI_Laboratory1", "SCTI_Laboratory2", "SCTI_AssessmentCenter" } },
		{ Id = "COED", Name = "COED", Color = Color3.fromRGB(240, 120, 180), Rooms = { "FH1_COED_Room", "FH2_COED_Room", "FH3_COED_Room", "FH4_COED_Room" } },
		{ Id = "JHS", Name = "JHS", Color = Color3.fromRGB(60, 180, 100), Rooms = { "Classroom_3F_011", "Classroom_3F_012", "Classroom_3F_014", "Room306_G9_Orion", "Room311", "JHS_FacultyRoom" } },
		{ Id = "SHS", Name = "SHS", Color = Color3.fromRGB(240, 140, 50), Rooms = { "Room202_SHS_G11_STEM_A", "Room204_SHS_G11_HUMSS_A", "Room302_SHS_G12_TVL_ICT_A", "Room303_SHS_G12_ABM_A", "Room305_SHS_G12_STEM_B" } },
		{ Id = "ES", Name = "Elementary (ES)", Color = Color3.fromRGB(90, 200, 220), Rooms = { "Classroom_1F_007", "Classroom_1F_009", "Classroom_1F_011", "Classroom_2F_006", "Classroom_2F_008", "Room206_Grade6Mobility", "Room212" } },
	},
	-- patrols: Kind = "Guard" or "Teacher"; Route = name of a route below (checked with pathfinding when the event starts)
	Patrols = {
		{ Kind = "Guard",   Route = "Courtyard" },
		{ Kind = "Guard",   Route = "CourtyardCross" },
		{ Kind = "Guard",   Route = "CourtyardNorth" },
		{ Kind = "Guard",   Route = "MainGate" },
		{ Kind = "Teacher", Route = "ES_1F_West" },
		{ Kind = "Teacher", Route = "ES_1F_East" },
		{ Kind = "Teacher", Route = "ES_2F_West" },
		{ Kind = "Teacher", Route = "COED_1F" },
		{ Kind = "Teacher", Route = "JHS_3F" },
		{ Kind = "Teacher", Route = "SHS_2F" },
		{ Kind = "Teacher", Route = "SHS_3F" },
		{ Kind = "Guard",   Route = "College_3F" },
		{ Kind = "Teacher", Route = "College_4F" },
		{ Kind = "Guard",   Route = "College_5F" },
	},
	-- route points (studs, world space). Corridor routes are built from the Quiz Bee door anchors when empty.
	Routes = {
		Courtyard      = { Vector3.new(108, 3.5, -24), Vector3.new(186, 3.5, -24), Vector3.new(186, 3.5, 96), Vector3.new(108, 3.5, 96) },
		CourtyardCross = { Vector3.new(110, 3.5, 35), Vector3.new(184, 3.5, 35) },
		CourtyardNorth = { Vector3.new(150, 3.5, -20), Vector3.new(150, 3.5, 92) },
		MainGate       = { Vector3.new(32, 3.5, 8), Vector3.new(96, 3.5, 10) },
		-- "anchors" = built from the Quiz Bee door anchors; a list of room names = built from those rooms' doors
		JHS_3F = "anchors", SHS_2F = "anchors", SHS_3F = "anchors", College_3F = "anchors", College_4F = "anchors", College_5F = "anchors",
		ES_1F_West = { "Classroom_1F_007", "Classroom_1F_008", "Classroom_1F_009", "Classroom_1F_010", "Classroom_1F_011" },
		ES_1F_East = { "Classroom_1F_012", "Classroom_1F_013", "Classroom_1F_014", "Classroom_1F_015" },
		ES_2F_West = { "Classroom_2F_006", "Classroom_2F_007", "Classroom_2F_008", "Classroom_2F_009", "Classroom_2F_010" },
		COED_1F    = { Vector3.new(88, 4, -69), Vector3.new(88, 4, -32), Vector3.new(88, 4, 46), Vector3.new(88, 4, 83) }, -- FH corridor (FH1–FH4 COED rooms)
	},
	PatrolSpeed   = 9,    -- walking speed on patrol
	ChaseSpeed    = 15,   -- running speed when chasing (players walk at 16)
	ViewRange     = 40,   -- how far they can see you
	ViewAngle     = 110,  -- field of view in degrees
	CatchDistance = 4.5,  -- caught when this close
	LoseDistance  = 55,   -- they give up when you are this far away …
	LoseTime      = 4,    -- … or out of sight for this many seconds
	DetentionTime = 8,    -- seconds in the Prefect of Discipline office
	EscapeBonus   = 25,   -- extra tokens for escaping through the Main Gate
	-- sounds (Roblox-licensed APM music / Pro Sound Effects; swap the ids for your own uploads)
	Music = {
		Background = "rbxassetid://1835322450", -- "Gentle Assurance" (APM) – calm school music
		Chase      = "rbxassetid://1837822435", -- "High Stakes Mission (B)" (APM) – when a patrol chases YOU
		Spotted    = "rbxassetid://9113086354", -- "Alarm Buzzer 2" (Pro Sound Effects) – the moment you are seen
		KeyGet     = "rbxasset://sounds/electronicpingshort.wav", -- built-in Roblox sound
	},
}

---------------------------------------------------------------- Intramurals tuning (RARE)
EventConfig.Intramurals = {
	Center = Vector3.new(146.5, 0.5, 35),   -- courtyard arena center (ground)
	-- Teams: Elementary / JHS / SHS come from LevelUnlocked (1–7 ES, 8–11 JHS, 12–13 SHS).
	-- College players (level 14+) pick their COURSE team the first time (saved as "CollegeCourse").
	CollegeLevel = 14,
	CollegeTeams = {   -- order matters: CollegeCourse = position in this list (1 = BSIT …)
		{ Id = "BSIT",   Name = "BSIT Violet Vipers",    Course = "BSIT / BMMA",       Color = Color3.fromRGB(145, 80, 225) },
		{ Id = "BSCRIM", Name = "BSCRIM Maroon Falcons", Course = "Criminology",       Color = Color3.fromRGB(150, 25, 45) },
		{ Id = "COED",   Name = "COED Rose Owls",        Course = "Education (BSEd)",  Color = Color3.fromRGB(235, 105, 175) },
		{ Id = "CBM",    Name = "CBM Orange Tigers",     Course = "Business (CBM)",    Color = Color3.fromRGB(245, 125, 30) },
		{ Id = "SCTI",   Name = "SCTI Silver Hawks",     Course = "SCTI",              Color = Color3.fromRGB(180, 190, 205) },
	},
	Teams = {
		{ Id = "SHS",     Name = "SHS Golden Lions",        Color = Color3.fromRGB(240, 200, 40), MinLevel = 12 },
		{ Id = "JHS",     Name = "JHS Blue Sharks",         Color = Color3.fromRGB(60, 130, 230), MinLevel = 8 },
		{ Id = "ES",      Name = "Elementary Green Eagles", Color = Color3.fromRGB(70, 180, 90),  MinLevel = 1 },
	},
	Rounds = {
		{ Id = "Relay",    Name = "🏃 Relay Race",          Time = 150, Help = "Run laps through the 4 gates in order! Every lap = +10 for your team." },
		{ Id = "Shootout", Name = "🏀 Basketball Shootout", Time = 120, Help = "Step on a shooting spot and press Shoot — stop the meter in the green! +3 per basket." },
		{ Id = "Tug",      Name = "🪢 Tug-of-War",          Time = 150, Help = "Tap PULL as fast as you can! Win a bout = +25 for your team." },
	},
	Intermission = 8,       -- seconds between rounds
	LapPoints = 10, BasketPoints = 3, TugWinPoints = 25,
	Music = "rbxassetid://1845738382", -- "Speedway" (APM)
}

---------------------------------------------------------------- Foundation Day tuning (RARE) — Founding Anniversary
-- The event runs the anniversary "Schedule of Activities" as a live program in the courtyard (Quadrangle).
EventConfig.FoundationDay = {
	Center = Vector3.new(146.5, 0.5, 35),   -- courtyard
	Anniversary = "FOUNDING ANNIVERSARY",
	Pageant = "Mr. & Ms. Samar College 2026",
	PageantSub = "The Search for Mr. and Ms. Samar College Kaanyag",
	-- program, in order (seconds each)
	Program = {
		{ Id = "Opening",    Icon = "🏫", Name = "Opening • Campus Decoration & Safety Prep", Time = 75,
			Desc = "Help the committee decorate! Press E at the ✨ spots to hang banners, lanterns and buntings." },
		{ Id = "TradeFair",  Icon = "🛍️", Name = "Campus Booths & Trade Fair", Time = 150,
			Desc = "Booths are open! Try every food stall, play Ring Toss, get a souvenir and visit the 📸 Photo Booth." },
		{ Id = "Parade",     Icon = "🎡", Name = "Float Parade", Time = 120,
			Desc = "The department floats are rolling! Walk beside a float to join the parade." },
		{ Id = "Presentation", Icon = "🎗️", Name = "Presentation of Candidates & Sashing Ceremony", Time = 75,
			Desc = "Meet the official candidates! Candidates: walk the runway when your number is called." },
		{ Id = "Talent",     Icon = "🎤", Name = "Talent Competition", Time = 90,
			Desc = "Candidates perform on stage. Vote for BEST IN TALENT! 🗳️" },
		{ Id = "Coronation", Icon = "👑", Name = "Mr. & Ms. Samar College: The Coronation Night", Time = 120,
			Desc = "Vote for Mr. and Ms. Samar College, then watch the crowning! 🗳️" },
		{ Id = "GuestShow",  Icon = "🎭", Name = "Cultural Show featuring Guest Performers", Time = 90,
			Desc = "Sit back and enjoy the guest dance troupe on the main stage." },
		{ Id = "SCTalents",  Icon = "🌟", Name = "Cultural Show featuring SC Talents", Time = 90,
			Desc = "Open stage! Get up on stage and perform — the crowd can cheer for you 👏" },
		{ Id = "ParlorGames", Icon = "🎲", Name = "Parlor Games for Students & Employees", Time = 150,
			Desc = "Grab prizes from the PABITIN, then join the SACK RACE!" },
		{ Id = "Closing",    Icon = "🎆", Name = "Closing Ceremony & Fireworks", Time = 60,
			Desc = "Thank you for celebrating! Look up for the fireworks finale." },
	},
	-- running all event long
	AllDay = {
		{ Icon = "📰", Name = "Media Coverage", Desc = "The SC Press drone covers the whole program live on the stage screen." },
		{ Icon = "📸", Name = "Documentation & Photo Booth", Desc = "Take your anniversary photo at the 📸 Photo Booth any time." },
	},
	MaxCandidates = 6,       -- per title (Mr. / Ms.)
	Points = {
		Decorate = 6, BoothFirst = 3, FoodTripBonus = 15, RingWin = 10, RingTry = 1, Souvenir = 4, FacePaint = 4,
		LuckyDraw = { 2, 5, 10, 20 }, Photo = 4,
		ParadeTick = 2, WatchTick = 2,            -- every 5 s
		Candidate = 20, Runway = 10, PerformTick = 3, Vote = 3,
		BestTalent = 40, Crown = 120, FirstRunner = 70, SecondRunner = 50,
		CheerTop = 30, Pabitin = 4, SackJoin = 5, SackPlaces = { 40, 25, 15 },
	},
	FireworksAt = 45,        -- fireworks during the last seconds
	Music = "rbxassetid://1836080007", -- "Martial Brass And Beats" (APM)
}

-- Display order for admin lists
EventConfig.Order = { "CampusCheckIn", "QuizBee", "Booth", "GuessTheDrawing", "TowerGame", "EscapeSchool", "Intramurals", "FoundationDay" }

---------------------------------------------------------------- achievements
-- Saved in PlayerData (Achievements list) and shown with the attribute "Ach_<Id>" = true.
EventConfig.Achievements = {
	FirstEvent          = { Name = "First Event!",          Icon = "🎟️", Description = "Join your first campus event." },
	EventWinner         = { Name = "Event Champion",        Icon = "🥇", Description = "Finish 1st place in any event." },
	IntramuralsChampion = { Name = "Intramurals Champion",  Icon = "🏆", Description = "Be on the winning team at Intramurals." },
	FoundationDay       = { Name = "Foundation Day Guest",  Icon = "🎉", Description = "Celebrate Samar College Foundation Day." },
	Kaanyag             = { Name = "Mr./Ms. Samar College", Icon = "👑", Description = "Get crowned at the Coronation Night." },
	SkyClimber          = { Name = "Parkour Climber", Icon = "⛰️", Description = "Reach the top of PATAAS! Parkour on Easy." },
	SkyLegend           = { Name = "Parkour Legend", Icon = "🦅", Description = "Reach the top of PATAAS! Parkour on Hard — no checkpoints!" },
	Level5 = { Name = "Rising Star", Icon = "⭐", Description = "Reach Event Level 5.", Level = 5 },
	Level10 = { Name = "Event Regular", Icon = "🎟️", Description = "Reach Event Level 10.", Level = 10 },
	Level20 = { Name = "Campus Favorite", Icon = "🎈", Description = "Reach Event Level 20.", Level = 20 },
	Level30 = { Name = "Spirit of Samar", Icon = "🔥", Description = "Reach Event Level 30.", Level = 30 },
	Level40 = { Name = "Event Enthusiast", Icon = "🎪", Description = "Reach Event Level 40.", Level = 40 },
	Level50 = { Name = "Event Veteran", Icon = "🎖️", Description = "Reach Event Level 50.", Level = 50 },
	Level60 = { Name = "Campus Celebrity", Icon = "🌟", Description = "Reach Event Level 60.", Level = 60 },
	Level75 = { Name = "Legend in the Making", Icon = "💎", Description = "Reach Event Level 75.", Level = 75 },
	Level90 = { Name = "Hall of Fame", Icon = "🏛️", Description = "Reach Event Level 90.", Level = 90 },
	Level100 = { Name = "Samar College Legend", Icon = "👑", Description = "Reach Event Level 100.", Level = 100 },
}

---------------------------------------------------------------- server type
-- The Elementary place id lives in HUDConfig (Settings → server switch).
-- Every other place counts as the Junior High+ server.
function EventConfig.getServerType()
	-- ServerSelectServer sets workspace.ServerType = "Main" / "Kid" (Kid = the Elementary server)
	local RunService = game:GetService("RunService")
	local t = workspace:GetAttribute("ServerType")
	if not t and RunService:IsServer() and game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
		local t0 = os.clock()
		while not workspace:GetAttribute("ServerType") and os.clock() - t0 < 60 do task.wait(0.5) end
		t = workspace:GetAttribute("ServerType")
	end
	if t == "Kid" then return "Elementary" end
	if t == "Main" then return "JuniorHighPlus" end
	local ok, hud = pcall(function() return require(game:GetService("ReplicatedStorage"):WaitForChild("HUDConfig", 5)) end)
	local elementaryId = ok and hud and tonumber(hud.ElementaryPlaceId) or 0
	if elementaryId > 0 and game.PlaceId == elementaryId then return "Elementary" end
	return "JuniorHighPlus"
end

function EventConfig.rarityOf(def) return EventConfig.Rarity[def.Rarity or "Common"] or EventConfig.Rarity.Common end
function EventConfig.weightOf(def) return def.Weight or EventConfig.rarityOf(def).Weight end
function EventConfig.currencyOf(def) return (def.Rewards and def.Rewards.Currency) or EventConfig.rarityOf(def).Currency end

return EventConfig
