--[[ WeatherConfig — every weather / season look.
  The server (WeatherServer) rolls the LIVE campus weather from C.Rotation. Every player sees the live weather
  ("Auto") unless they pick their own look in Settings → 🌦️ Weather & Season (only they see it).
  Values:
    bright        multiplier on the normal sun brightness
    exposure      ExposureCompensation
    atmo          Atmosphere { density, haze, glare, color, decay }
    clouds        Terrain clouds { cover, density, color }
    cc            colour grading { tint, sat, contrast, bright }
    sunrays       SunRays intensity
    wind          GlobalWind (moves clouds, particles, leaves)
    rain / snow   0..1 how hard it falls
    leaves/petals how many falling leaves / petals around you
    dust          floating haze / pollen
    lightning     { min, max } seconds between strikes
    rainbow       true = a rainbow over the campus
    sound         { rain, storm, wind } volumes ]]
local C = {}
local rgb = Color3.fromRGB

C.Sounds = {
	rain = "rbxassetid://9064263922",
	storm = "rbxassetid://9064263922", -- heavy rain layer (played slower / deeper during storms)
	wind = "rbxassetid://5799870105",
}

C.List = {
	-------------------------------------------------- weather
	{ id = "Sunny", name = "Sunny", icon = "☀️", kind = "Weather", desc = "Clear blue sky",
		bright = 1.05, exposure = 0.1, sunrays = 0.12,
		atmo = { density = 0.25, haze = 1, glare = 0.35, color = rgb(200, 222, 245), decay = rgb(120, 150, 190) },
		clouds = { cover = 0.42, density = 0.5, color = rgb(255, 255, 255) },
		cc = { tint = rgb(255, 252, 244), sat = 0.12, contrast = 0.05, bright = 0 },
		wind = Vector3.new(3, 0, 1), sound = { wind = 0.05 } },
	{ id = "PartlyCloudy", name = "Partly Cloudy", icon = "⛅", kind = "Weather", desc = "Sun and clouds",
		bright = 0.95, exposure = 0, sunrays = 0.08,
		atmo = { density = 0.3, haze = 1.4, glare = 0.2, color = rgb(205, 220, 238), decay = rgb(125, 150, 185) },
		clouds = { cover = 0.65, density = 0.6, color = rgb(250, 250, 252) },
		cc = { tint = rgb(250, 250, 248), sat = 0.05, contrast = 0.03, bright = 0 },
		wind = Vector3.new(6, 0, 2), sound = { wind = 0.08 } },
	{ id = "Cloudy", name = "Cloudy", icon = "☁️", kind = "Weather", desc = "Grey and calm",
		bright = 0.7, exposure = -0.2, sunrays = 0,
		atmo = { density = 0.36, haze = 2, glare = 0, color = rgb(192, 199, 210), decay = rgb(130, 138, 150) },
		clouds = { cover = 0.86, density = 0.75, color = rgb(218, 221, 228) },
		cc = { tint = rgb(236, 240, 246), sat = -0.15, contrast = 0, bright = 0 },
		wind = Vector3.new(8, 0, 3), sound = { wind = 0.12 } },
	{ id = "Windy", name = "Windy", icon = "🌬️", kind = "Weather", desc = "Strong breeze, flying leaves",
		bright = 0.95, exposure = 0, sunrays = 0.05,
		atmo = { density = 0.3, haze = 1.6, glare = 0.15, color = rgb(205, 218, 232), decay = rgb(130, 150, 175) },
		clouds = { cover = 0.62, density = 0.55, color = rgb(245, 246, 250) },
		cc = { tint = rgb(248, 250, 250), sat = 0, contrast = 0.04, bright = 0 },
		wind = Vector3.new(34, 0, 12), leaves = 26, dust = 5, sound = { wind = 0.55 } },
	{ id = "Drizzle", name = "Drizzle", icon = "🌦️", kind = "Weather", desc = "Light, gentle rain",
		bright = 0.68, exposure = -0.15, sunrays = 0,
		atmo = { density = 0.38, haze = 2.2, glare = 0, color = rgb(185, 195, 208), decay = rgb(125, 135, 150) },
		clouds = { cover = 0.84, density = 0.78, color = rgb(205, 209, 216) },
		cc = { tint = rgb(232, 238, 246), sat = -0.15, contrast = 0.02, bright = 0 },
		wind = Vector3.new(6, 0, 2), rain = 0.25, sound = { rain = 0.25, wind = 0.1 } },
	{ id = "Rainy", name = "Rainy", icon = "🌧️", kind = "Weather", desc = "Steady rain (tag-ulan)",
		bright = 0.5, exposure = -0.35, sunrays = 0,
		atmo = { density = 0.46, haze = 3, glare = 0, color = rgb(160, 170, 185), decay = rgb(105, 115, 130) },
		clouds = { cover = 0.95, density = 0.9, color = rgb(150, 155, 165) },
		cc = { tint = rgb(220, 228, 240), sat = -0.3, contrast = 0.05, bright = 0 },
		wind = Vector3.new(10, 0, 4), rain = 0.72, sound = { rain = 0.6, wind = 0.15 } },
	{ id = "Thunderstorm", name = "Thunderstorm", icon = "⛈️", kind = "Weather", desc = "Heavy rain and lightning",
		bright = 0.3, exposure = -0.6, sunrays = 0,
		atmo = { density = 0.56, haze = 4, glare = 0, color = rgb(112, 120, 138), decay = rgb(70, 76, 92) },
		clouds = { cover = 1, density = 1, color = rgb(88, 92, 104) },
		cc = { tint = rgb(200, 210, 235), sat = -0.45, contrast = 0.1, bright = -0.03 },
		wind = Vector3.new(24, 0, 8), rain = 1, lightning = { 5, 12 }, sound = { rain = 0.7, storm = 0.55, wind = 0.3 } },
	{ id = "Typhoon", name = "Typhoon (Bagyo)", icon = "🌀", kind = "Weather", desc = "Signal #3 — howling wind",
		bright = 0.24, exposure = -0.7, sunrays = 0,
		atmo = { density = 0.62, haze = 5, glare = 0, color = rgb(105, 112, 125), decay = rgb(65, 70, 82) },
		clouds = { cover = 1, density = 1, color = rgb(80, 84, 94) },
		cc = { tint = rgb(198, 208, 225), sat = -0.5, contrast = 0.12, bright = -0.04 },
		wind = Vector3.new(60, 0, 22), rain = 1, leaves = 45, lightning = { 8, 18 }, sound = { rain = 0.8, storm = 0.4, wind = 0.9 } },
	{ id = "Foggy", name = "Foggy", icon = "🌫️", kind = "Weather", desc = "Thick morning mist",
		bright = 0.65, exposure = -0.05, sunrays = 0,
		atmo = { density = 0.74, haze = 6, glare = 0, color = rgb(214, 220, 226), decay = rgb(170, 178, 188) },
		clouds = { cover = 0.8, density = 0.7, color = rgb(230, 232, 235) },
		cc = { tint = rgb(240, 243, 246), sat = -0.22, contrast = -0.05, bright = 0.02 },
		wind = Vector3.new(2, 0, 1), dust = 3, sound = { wind = 0.06 } },
	{ id = "HeatWave", name = "Heat Wave", icon = "🔥", kind = "Weather", desc = "Scorching hot sun",
		bright = 1.25, exposure = 0.35, sunrays = 0.25,
		atmo = { density = 0.33, haze = 2.6, glare = 0.65, color = rgb(255, 226, 182), decay = rgb(255, 188, 120) },
		clouds = { cover = 0.3, density = 0.4, color = rgb(255, 246, 232) },
		cc = { tint = rgb(255, 234, 205), sat = 0.2, contrast = 0.08, bright = 0.02 },
		wind = Vector3.new(2, 0, 1), dust = 4, sound = { wind = 0.04 } },
	{ id = "Rainbow", name = "Rainbow", icon = "🌈", kind = "Weather", desc = "Sunshine after the rain",
		bright = 1.05, exposure = 0.12, sunrays = 0.15,
		atmo = { density = 0.24, haze = 0.8, glare = 0.3, color = rgb(205, 228, 250), decay = rgb(125, 160, 200) },
		clouds = { cover = 0.55, density = 0.55, color = rgb(250, 250, 255) },
		cc = { tint = rgb(252, 252, 255), sat = 0.22, contrast = 0.06, bright = 0.01 },
		wind = Vector3.new(4, 0, 2), rainbow = true, sound = { wind = 0.05 } },
	{ id = "Snow", name = "Snow", icon = "❄️", kind = "Weather", desc = "Soft snowflakes",
		bright = 0.85, exposure = 0.1, sunrays = 0,
		atmo = { density = 0.42, haze = 2.2, glare = 0.1, color = rgb(225, 235, 250), decay = rgb(170, 185, 210) },
		clouds = { cover = 0.9, density = 0.8, color = rgb(235, 238, 245) },
		cc = { tint = rgb(225, 236, 255), sat = -0.25, contrast = 0.02, bright = 0.02 },
		wind = Vector3.new(4, 0, 2), snow = 0.6, sound = { wind = 0.15 } },
	{ id = "Blizzard", name = "Blizzard", icon = "🌨️", kind = "Weather", desc = "Freezing snowstorm",
		bright = 0.6, exposure = 0, sunrays = 0,
		atmo = { density = 0.7, haze = 5, glare = 0, color = rgb(230, 236, 245), decay = rgb(180, 192, 210) },
		clouds = { cover = 1, density = 0.95, color = rgb(215, 220, 230) },
		cc = { tint = rgb(220, 232, 255), sat = -0.4, contrast = 0.05, bright = 0.02 },
		wind = Vector3.new(42, 0, 16), snow = 1, sound = { wind = 0.8 } },
	-------------------------------------------------- seasons
	{ id = "Spring", name = "Spring", icon = "🌸", kind = "Season", desc = "Blossoms in the breeze",
		bright = 1.05, exposure = 0.1, sunrays = 0.12,
		atmo = { density = 0.26, haze = 1.2, glare = 0.25, color = rgb(232, 222, 240), decay = rgb(170, 150, 190) },
		clouds = { cover = 0.5, density = 0.5, color = rgb(255, 250, 252) },
		cc = { tint = rgb(255, 242, 246), sat = 0.22, contrast = 0.04, bright = 0.01 },
		wind = Vector3.new(7, 0, 3), petals = 60, sound = { wind = 0.08 } },
	{ id = "Summer", name = "Summer (Tag-init)", icon = "🏖️", kind = "Season", desc = "Bright, warm and dry",
		bright = 1.18, exposure = 0.22, sunrays = 0.2,
		atmo = { density = 0.28, haze = 1.6, glare = 0.5, color = rgb(250, 230, 200), decay = rgb(240, 190, 140) },
		clouds = { cover = 0.35, density = 0.45, color = rgb(255, 250, 240) },
		cc = { tint = rgb(255, 242, 220), sat = 0.18, contrast = 0.06, bright = 0.01 },
		wind = Vector3.new(4, 0, 2), dust = 2, sound = { wind = 0.05 } },
	{ id = "Autumn", name = "Autumn", icon = "🍂", kind = "Season", desc = "Falling golden leaves",
		bright = 0.92, exposure = 0.05, sunrays = 0.1,
		atmo = { density = 0.32, haze = 1.8, glare = 0.3, color = rgb(240, 214, 180), decay = rgb(200, 150, 100) },
		clouds = { cover = 0.6, density = 0.6, color = rgb(250, 240, 230) },
		cc = { tint = rgb(255, 232, 205), sat = 0.06, contrast = 0.05, bright = 0 },
		wind = Vector3.new(10, 0, 4), leaves = 55, sound = { wind = 0.15 } },
	{ id = "Winter", name = "Winter", icon = "⛄", kind = "Season", desc = "Cold air, light snow",
		bright = 0.85, exposure = 0.05, sunrays = 0.04,
		atmo = { density = 0.4, haze = 2, glare = 0.1, color = rgb(222, 232, 250), decay = rgb(165, 180, 210) },
		clouds = { cover = 0.8, density = 0.7, color = rgb(238, 242, 250) },
		cc = { tint = rgb(228, 238, 255), sat = -0.2, contrast = 0.03, bright = 0.01 },
		wind = Vector3.new(5, 0, 2), snow = 0.3, sound = { wind = 0.12 } },
}
C.ById = {}
for i, w in ipairs(C.List) do w.order = i C.ById[w.id] = w end

-- LIVE campus weather: what the server can roll and how often (weights). Snow/seasons are picks only.
C.Rotation = {
	{ "Sunny", 26 }, { "PartlyCloudy", 18 }, { "Cloudy", 13 }, { "Windy", 9 }, { "Drizzle", 8 },
	{ "Rainy", 11 }, { "Thunderstorm", 5 }, { "Foggy", 4 }, { "HeatWave", 5 }, { "Typhoon", 1 },
}
C.Duration = { 360, 600 }     -- each live weather lasts 6–10 minutes
C.RainbowChance = 0.5          -- after rain / a storm, half the time a rainbow follows
C.RainbowDuration = 150
C.Transition = 7               -- seconds to blend from one look to the next

-- what the toast says when the live weather changes
C.Announce = {
	Sunny = "☀️ The sun is out — clear skies over the campus!",
	PartlyCloudy = "⛅ Some clouds rolling in.",
	Cloudy = "☁️ It's getting cloudy.",
	Windy = "🌬️ The wind is picking up!",
	Drizzle = "🌦️ A light drizzle is falling.",
	Rainy = "🌧️ It's raining — grab an umbrella!",
	Thunderstorm = "⛈️ Thunderstorm! Stay indoors.",
	Typhoon = "🌀 Typhoon warning! Signal #3 over Catbalogan.",
	Foggy = "🌫️ Thick fog covers the campus.",
	HeatWave = "🔥 Heat wave! Stay hydrated.",
	Rainbow = "🌈 A rainbow appeared after the rain!",
}

return C
