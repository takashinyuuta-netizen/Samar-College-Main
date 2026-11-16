-- SportsConfig: Intramurals sports courts (Badminton now; more sports reuse the same system).
-- Courts are models in Workspace.SportsVenues with attributes Sport / CourtId / CourtName.
local C = {}

-- No divisions: everyone plays together (Men's / Women's / Mixed was removed).
C.Divisions = {}

C.MeterSpeed = 1.05 -- timing meter sweeps per second

-- Vote-kick (every game): players and watchers vote; the majority decides
C.VoteKick = {
	Duration = 20,     -- seconds to vote
	BanSeconds = 300,  -- kicked players can't rejoin that court for 5 minutes
	Cooldown = 45,     -- seconds before the same player can start another vote
}

C.Sports = {
	Badminton = {
		Name = "Badminton", Icon = "🏸", Kind = "Rally", VoteKick = true,
		PerSide = 2,              -- singles (1 v 1) or doubles (2 v 2)
		WinScore = 11, WinBy = 2, MaxScore = 15,
		LobbyCountdown = 20,      -- seconds after both sides have a player
		ServeDelay = 1.6,
		Ball = "Shuttle", Racket = "Racket",
		-- shots: time = flight seconds, height = arc, zone = how big the receiver's green zone is
		Shots = {
			clear = { label = "Clear ⤴", time = 1.35, height = 10, zone = 0.22 },
			drop  = { label = "Drop ↘",  time = 1.15, height = 4,  zone = 0.17 },
			smash = { label = "Smash ⚡", time = 0.78, height = 1.2, zone = 0.11 },
		},
		ServeShot = "clear",
		CpuSkill = 0.74,          -- chance the CPU returns a normal shot
		Rewards = { Win = 30, Play = 10, Currency = "Common" },
	},
	TableTennis = {
		Name = "Table Tennis", Icon = "🏓", Kind = "Rally", VoteKick = true,
		PerSide = 2, WinScore = 11, WinBy = 2, MaxScore = 15,
		LobbyCountdown = 20, ServeDelay = 1.3, MeterSpeed = 1.7,
		Ball = "Ball", BallColor = Color3.fromRGB(255, 150, 40), BallSize = 0.32, Racket = "Paddle",
		-- the ball lands on the table, near the receiver's end
		Land = { depth = 3.4, lateral = 2.0, height = 3.4 },
		Shots = {
			push  = { label = "Push ↗",   time = 1.05, height = 1.4, zone = 0.22 },
			loop  = { label = "Topspin 🌀", time = 0.85, height = 2.4, zone = 0.16 },
			smash = { label = "Smash ⚡",  time = 0.62, height = 0.8, zone = 0.11 },
		},
		ServeShot = "push", CpuSkill = 0.72,
		Rewards = { Win = 30, Play = 10, Currency = "Common" },
	},
	Pickleball = {
		Name = "Pickleball", Icon = "🥒", Kind = "Rally", VoteKick = true,
		PerSide = 2, WinScore = 11, WinBy = 2, MaxScore = 15,
		LobbyCountdown = 20, ServeDelay = 1.5, MeterSpeed = 1.25,
		Ball = "Ball", BallColor = Color3.fromRGB(230, 240, 60), BallSize = 0.55, Holes = true, Racket = "Paddle",
		Shots = {
			dink  = { label = "Dink 🪶",  time = 1.3,  height = 3,   zone = 0.22 },
			drive = { label = "Drive ➡",  time = 0.95, height = 2,   zone = 0.16 },
			smash = { label = "Smash ⚡", time = 0.72, height = 1.2, zone = 0.11 },
		},
		ServeShot = "dink", CpuSkill = 0.74,
		Rewards = { Win = 30, Play = 10, Currency = "Common" },
	},
	Volleyball = {
		Name = "Volleyball", Icon = "🏐", Kind = "Rally", VoteKick = true,
		PerSide = 4,              -- 4 v 4 (empty spots are filled with 🤖 CPUs)
		AutoFill = "full",        -- nobody came: you get CPU teammates AND a CPU team to play against
		WinScore = 15, WinBy = 2, MaxScore = 21,
		LobbyCountdown = 20, ServeDelay = 1.8, MeterSpeed = 1.1,
		Ball = "Ball", BallColor = Color3.fromRGB(250, 215, 70), BallSize = 1.05, -- no racket: hands
		-- team play: the receiver BUMPS to a teammate, the setter SETS, then an attacker sends your chosen shot over
		TeamTouches = true,
		Shots = {
			float = { label = "Float 🎈", time = 1.45, height = 12, zone = 0.22 },
			tip   = { label = "Tip 🤏",   time = 1.1,  height = 6,  zone = 0.16 },
			spike = { label = "Spike ⚡", time = 0.75, height = 2.5, zone = 0.11 },
		},
		ServeShot = "float", CpuSkill = 0.76,
		Rewards = { Win = 35, Play = 12, Currency = "Common" },
	},
}

-- 🏀 Basketball (BasketballEngine): possessions instead of rallies.
-- Shots: zone = size of the green zone (bigger = easier), good / bad = chance to score when you hit inside /
-- outside the zone, cpu = chance a 🤖 CPU scores it, points, flight time and arc height.
local function basketballShots()
	return {
		pass  = { label = "Pass 🤝",   zone = 0.36, short = "pass" },
		layup = { label = "Layup 🏀",  zone = 0.26, points = 2, time = 0.55, height = 2.5, good = 0.9,  bad = 0.2,  cpu = 0.6,  short = "layup" },
		mid   = { label = "Jumper 🎯", zone = 0.18, points = 2, time = 0.85, height = 6,   good = 0.85, bad = 0.12, cpu = 0.47, short = "jumper" },
		three = { label = "3PT 🔥",    zone = 0.11, points = 3, time = 1.05, height = 8,   good = 0.78, bad = 0.06, cpu = 0.36, short = "three" },
	}
end
local function basketball(name, perSide, winScore, gameTime)
	return {
		Name = name, Icon = "🏀", Kind = "Basketball", VoteKick = true,
		PerSide = perSide, AutoFill = "full",  -- nobody came: CPU teammates AND a CPU team
		WinScore = winScore, GameTime = gameTime, -- first to WinScore, or the leader when the clock runs out (tied = next basket wins)
		LobbyCountdown = 20, MeterSpeed = 1.0,
		ShotClock = 8,          -- seconds you can hold the ball
		BlockWindow = 0.95, BlockZone = 0.16, -- defense: quick BLOCK meter when the other team shoots
		CpuStealChance = 0.08, CpuBlockChance = 0.07, OffRebound = 0.32,
		BallColor = Color3.fromRGB(225, 105, 35),
		Tip = "Big green = easy. 3PT is hardest!",
		Shots = basketballShots(),
		Rewards = { Win = 40, Play = 14, Currency = "Common" },
	}
end
C.Sports.Basketball3v3 = basketball("Basketball 3v3", 3, 21, 300)
C.Sports.Basketball5v5 = basketball("Basketball 5v5", 5, 30, 360)

-- ♟️ Chess (ChessGame + ChessEngine): library tables, 1 v 1. Team A = White, Team B = Black.
C.Sports.Chess = {
	Name = "Chess", Icon = "♟️", Kind = "Chess", VoteKick = true,
	PerSide = 1, AutoFill = "full",   -- nobody came in 10 s: a 🤖 CPU plays you
	WinScore = 0, LobbyCountdown = 15,
	ClockSeconds = 300, Increment = 2, -- 5 minutes each + 2 seconds per move
	CpuDepth = 3, CpuNoise = 25,       -- CPU thinks 3 moves ahead (noise = a little variety)
	Shots = {}, Tip = "Tap a piece, then a square",
	Rewards = { Win = 40, Play = 14, Currency = "Common" },
}

return C
