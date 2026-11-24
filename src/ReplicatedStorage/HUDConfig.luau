-- HUDConfig.lua
-- Settings for the Bag / Map / Settings HUD. Edit freely.

return {
	-- Place ID of the separate Elementary (kids) server. 0 = not set up yet.
	ElementaryPlaceId = 0, -- no teleport to the Kid Server game (0 = off)

	-- World area that your map image covers (top-down, image top = MinZ, left = MinX).
	-- Pins are placed on the image using these bounds.
	MapWorld = { Top = 720, Bottom = -1460, Left = -820, Right = 800 }, -- whole island (up = +X, right = +Z)
	MapGrid = 4,
	-- Full-island 4x4 map photo (Nov 16, 2026 night), row by row from the top-left.
	-- Previous campus-only photo used MapWorld = { Top = 480, Bottom = -428.78, Left = -560, Right = 570.93 } with tiles:
	-- 106765627604824, 76051108460027, 91440350729900, 82166223265229, 104925889488275, 129649018358204, 77211906074524, 136751656862621,
	-- 122028083044018, 88662357566084, 108569228587068, 100817797946968, 110200292067291, 131592926231247, 136155596144777, 128012188318115
	MapTiles = {
		"rbxassetid://106236425734749", "rbxassetid://135188659999463", "rbxassetid://124008989049995", "rbxassetid://86509324712151",
		"rbxassetid://126000418895980", "rbxassetid://105345426874947", "rbxassetid://77774667821707", "rbxassetid://105024901321520",
		"rbxassetid://131518668034629", "rbxassetid://134439582456468", "rbxassetid://119419538383284", "rbxassetid://124905238547746",
		"rbxassetid://120894212935176", "rbxassetid://138963956958689", "rbxassetid://134810467312739", "rbxassetid://114359626576120",
	},
	MapBounds = { MinX = -130, MaxX = 330, MinZ = -400, MaxZ = 380 },

	-- Places on the map. Position = where the player is teleported (standing height).
	-- Optional LookAt = a point the player faces after teleporting.
	-- Optional MapX / MapY (0-1) override the pin position on the image.
	Places = {
		{ Id = "MainGate",      Name = "Main Gate",            Icon = "🚪", Position = Vector3.new(5, 4, 8), LookAt = Vector3.new(19.5, 4, 8) }, -- outside the front gate, facing it
		{ Id = "Courtyard",     Name = "Courtyard",            Icon = "🏀", Position = Vector3.new(125, 3.5, 15) },
		{ Id = "Canteen",       Name = "Canteen (Cashier)",    Icon = "🍽️", Position = Vector3.new(114, 4.6, 158.5), LookAt = Vector3.new(98, 4.6, 170) }, -- open floor inside the east door, facing the cashier
		{ Id = "BadmintonHall", Intramurals = true, Name = "🏸 Badminton (1F Hall)", Icon = "🏸", Position = Vector3.new(221.5, 4.5, 196) },
		{ Id = "TableTennisIsland", Intramurals = true, Name = "🏓 Table Tennis Island", Icon = "🏓", Position = Vector3.new(-470, 74, -138) },
		{ Id = "PickleballIsland", Intramurals = true, Name = "🥒 Pickleball Island", Icon = "🥒", Position = Vector3.new(-470, 74, 16) },
		{ Id = "VolleyballCampus", Intramurals = true, Name = "🏐 Volleyball Sky Island", Icon = "🏐", Position = Vector3.new(-470, 114.5, -314) }, -- moved from the campus street (375, 4.5, 6) to its own sky island (Nov 17)
		{ Id = "Basketball3v3Island", Intramurals = true, Name = "🏀 3v3 Basketball Island", Icon = "🏀", Position = Vector3.new(-470, 74.35, 186.5) },
		{ Id = "Basketball5v5Island", Intramurals = true, Name = "🏀 5v5 Basketball Arena", Icon = "🏀", Position = Vector3.new(-470, 74.35, 359) },
		{ Id = "ChessLibrary1", Intramurals = true, Name = "♟️ Chess (2F Library)", Icon = "♟️", Position = Vector3.new(144.5, 19.6, -175) },
		{ Id = "TalentStage", Intramurals = true, Name = "🎤 Talent Stage (1F Hall)", Icon = "🎤", Position = Vector3.new(200, 3.5, 40) },
		{ Id = "QueenIsabelPlaza", Name = "Queen Isabel II Plaza", Icon = "🌴", Position = Vector3.new(-231, 3, -350) },
		{ Id = "DeansOffice",   Name = "Dean's Office",       Icon = "🏛️", Position = Vector3.new(205, 4, -135) },
	},

	TeleportCooldown = 3, -- seconds between map teleports
}
