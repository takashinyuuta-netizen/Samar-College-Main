--[[ MusicClient — the campus music player.

  • Song list with tabs: All, ⭐ Favorites, 📃 My Playlist, every mood category, 👥 Listen Together
  • Search by title / artist
  • Now Playing bar: cover, title, ⭐, shuffle / prev / play / next / repeat, seek bar, volume, visualizer
  • Mini player under the left rail while the window is closed
  • Listen Together: host a party, others join and hear the same song at the same time
  • Favorites, playlist, volume, shuffle and repeat are saved (MusicServer DataStore)

  Songs come from ReplicatedStorage.Music.MusicLibrary (licensed APM / DistroKid audio only). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = script.Parent
local folder = ReplicatedStorage:WaitForChild("Music")
local Library = require(folder:WaitForChild("MusicLibrary"))
local fn = folder:WaitForChild("MusicFunction")
local ev = folder:WaitForChild("MusicEvent")

------------------------------------------------------------ STYLE
local BG = Color3.fromRGB(24, 24, 32)
local BG1 = Color3.fromRGB(30, 30, 40)
local BG2 = Color3.fromRGB(42, 42, 55)
local BG3 = Color3.fromRGB(52, 52, 68)
local STROKE = Color3.fromRGB(75, 75, 95)
local ACCENT = Color3.fromRGB(20, 140, 100)
local ACCENT2 = Color3.fromRGB(60, 200, 150)
local TEXT = Color3.fromRGB(245, 245, 245)
local MUTED = Color3.fromRGB(165, 165, 180)
local GOLD = Color3.fromRGB(255, 200, 70)

local CAT_COLORS = {
	Lofi = { Color3.fromRGB(120, 90, 200), Color3.fromRGB(60, 40, 120) },
	Chill = { Color3.fromRGB(40, 180, 170), Color3.fromRGB(20, 90, 110) },
	Vocal = { Color3.fromRGB(235, 100, 160), Color3.fromRGB(120, 40, 100) },
	Relapse = { Color3.fromRGB(150, 50, 70), Color3.fromRGB(50, 20, 40) },
	Peace = { Color3.fromRGB(110, 180, 240), Color3.fromRGB(40, 80, 140) },
	Happy = { Color3.fromRGB(255, 200, 70), Color3.fromRGB(220, 110, 40) },
	OPMChill = { Color3.fromRGB(80, 90, 210), Color3.fromRGB(25, 30, 90) },
	OPMHugot = { Color3.fromRGB(200, 50, 80), Color3.fromRGB(70, 15, 40) },
	OPMKilig = { Color3.fromRGB(255, 120, 170), Color3.fromRGB(180, 50, 120) },
	Anime = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(120, 30, 160) },
	JPop = { Color3.fromRGB(255, 150, 200), Color3.fromRGB(90, 60, 200) },
	CPop = { Color3.fromRGB(230, 60, 50), Color3.fromRGB(150, 100, 20) },
	KPop = { Color3.fromRGB(180, 120, 255), Color3.fromRGB(60, 40, 140) },
}
local DEFAULT_COLORS = { Color3.fromRGB(90, 90, 120), Color3.fromRGB(40, 40, 60) }

local catById = {}
for _, c in ipairs(Library.Categories) do catById[c.id] = c end

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function corner(o, r) mk("UICorner", { CornerRadius = UDim.new(0, r or 10) }, o) end
local function stroke(o, c, t)
	return mk("UIStroke", { Color = c or STROKE, Thickness = t or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
local function label(parent, props)
	local l = mk("TextLabel", {
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextColor3 = TEXT, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
	for k, v in pairs(props) do l[k] = v end
	return l
end
local function button(parent, text, props)
	local b = mk("TextButton", {
		Text = text, BackgroundColor3 = BG2, AutoButtonColor = true, Font = Enum.Font.GothamBold,
		TextColor3 = TEXT, TextSize = 14, BorderSizePixel = 0,
	}, parent)
	for k, v in pairs(props) do b[k] = v end
	return b
end
local function coverize(frame, cat)
	local cols = CAT_COLORS[cat] or DEFAULT_COLORS
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	local g = frame:FindFirstChildOfClass("UIGradient") or mk("UIGradient", { Rotation = 45 }, frame)
	g.Color = ColorSequence.new(cols[1], cols[2])
end
local function fmt(t)
	t = math.max(0, math.floor(t or 0))
	return string.format("%d:%02d", t // 60, t % 60)
end

------------------------------------------------------------ STATE
local saved = { favs = {}, playlist = {}, vol = 0.5, shuffle = false, rep = "all" }
local favSet, plSet = {}, {}
local tab = "All"
local search = ""
local queue, qpos = {}, 0
local current = nil
local loadToken = 0
local fails = 0
local party = nil          -- party info from the server (nil = not in a party)
local isHost = false
local partyState = nil

local sound = mk("Sound", { Name = "Playlist_Music", Volume = saved.vol, Looped = false }, SoundService)

------------------------------------------------------------ BACKGROUND MUSIC DUCKING
-- Campus background music and event soundtracks go in their own group (inside Settings' "Music" group,
-- so the Music volume slider still works). While the playlist is playing that group fades to silent;
-- pause / stop the playlist and it fades back. Sound effects (SFX group) are never touched.
local BGM_NAMES = { Campus_Hangout = true, Escape_BG = true, Escape_Chase = true, Tower_Music = true, Intramurals_Music = true, Foundation_Music = true }
local musicGroup = SoundService:WaitForChild("Music", 10)
local bgmGroup = SoundService:FindFirstChild("BackgroundMusic", true) or Instance.new("SoundGroup")
bgmGroup.Name = "BackgroundMusic"
bgmGroup.Parent = musicGroup or SoundService
if musicGroup then sound.SoundGroup = musicGroup end
local function claim(s)
	if s:IsA("Sound") and BGM_NAMES[s.Name] then
		s.SoundGroup = bgmGroup
		-- other scripts may re-assign the group later; keep it ours
		s:GetPropertyChangedSignal("SoundGroup"):Connect(function()
			if s.SoundGroup ~= bgmGroup then s.SoundGroup = bgmGroup end
		end)
	end
end
for _, d in ipairs(SoundService:GetDescendants()) do claim(d) end
SoundService.DescendantAdded:Connect(claim)
local duckTarget = -1
task.spawn(function()
	while true do
		local playlistOn = sound.IsPlaying and sound.Volume > 0.01
		local want = playlistOn and 0 or 1
		if want ~= duckTarget then
			duckTarget = want
			TweenService:Create(bgmGroup, TweenInfo.new(playlistOn and 1.2 or 2.5), { Volume = want }):Play()
		end
		player:SetAttribute("SC_PlaylistPlaying", playlistOn)
		-- a live song on the Talent Stage near you: your playlist goes quiet so you can hear the performer
		local wantVol = saved.vol * (player:GetAttribute("SC_NearLiveStage") and 0.12 or 1)
		if math.abs(sound.Volume - wantVol) > 0.01 and not sound:GetAttribute("Fading") then
			sound:SetAttribute("Fading", true)
			local tw = TweenService:Create(sound, TweenInfo.new(1.2), { Volume = wantVol })
			tw.Completed:Connect(function() sound:SetAttribute("Fading", nil) end)
			tw:Play()
		end
		task.wait(0.25)
	end
end)

local function locked() return party ~= nil and not isHost end

------------------------------------------------------------ UI: WINDOW
local hud = player:WaitForChild("PlayerGui"):WaitForChild("MainHUD")
local hudScale = hud:FindFirstChild("AutoScale")
local uiScale = mk("UIScale", {}, gui)
local function syncScale() uiScale.Scale = hudScale and hudScale.Scale or 1 end
syncScale()
if hudScale then hudScale:GetPropertyChangedSignal("Scale"):Connect(syncScale) end

local WIN_W, WIN_H = 860, 560
local win = mk("Frame", {
	Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 30, 0.5, 0),
	Size = UDim2.fromOffset(WIN_W, WIN_H), BackgroundColor3 = BG, Visible = false, Active = true,
}, gui)
corner(win, 18)
stroke(win, STROKE, 1.5)
local fitScale = mk("UIScale", {}, win)
local function fit()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local vs = cam.ViewportSize
	local s = uiScale.Scale
	fitScale.Scale = math.min(1, (vs.X - 120) / (WIN_W * s), (vs.Y - game:GetService("GuiService"):GetGuiInset().Y - 16) / (WIN_H * s))
end
fit()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
uiScale:GetPropertyChangedSignal("Scale"):Connect(fit)

-- header
label(win, { Text = "🎵  Campus Music", Position = UDim2.fromOffset(22, 14), Size = UDim2.fromOffset(320, 30), TextSize = 22 })
local subLabel = label(win, {
	Text = #Library.Songs .. " songs · all licensed for Roblox", Position = UDim2.fromOffset(22, 44),
	Size = UDim2.fromOffset(380, 16), TextSize = 13, TextColor3 = MUTED, Font = Enum.Font.GothamMedium,
})
local searchBox = mk("Frame", { Position = UDim2.new(1, -350, 0, 16), Size = UDim2.fromOffset(284, 38), BackgroundColor3 = BG2 }, win)
corner(searchBox, 10)
local searchStroke = stroke(searchBox, STROKE, 1)
label(searchBox, { Text = "🔍", Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0, 24, 1, 0), TextSize = 15 })
local searchInput = mk("TextBox", {
	Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -66, 1, 0), BackgroundTransparency = 1, Text = "",
	PlaceholderText = "Search songs or artists…", PlaceholderColor3 = MUTED, TextColor3 = TEXT, Font = Enum.Font.GothamMedium,
	TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
}, searchBox)
local clearSearch = button(searchBox, "X", {
	Position = UDim2.new(1, -30, 0.5, -11), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, TextColor3 = MUTED, TextSize = 13, Visible = false,
})
local closeBtn = button(win, "X", { Position = UDim2.new(1, -54, 0, 16), Size = UDim2.fromOffset(38, 38), TextSize = 16 })
corner(closeBtn, 10)

-- sidebar
local side = mk("ScrollingFrame", {
	Position = UDim2.fromOffset(12, 72), Size = UDim2.new(0, 180, 1, -186), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 3, ScrollBarImageColor3 = STROKE, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, win)
mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, side)

local tabButtons = {}
local order = 0
local function sideHeader(text)
	order += 1
	label(side, { Text = text, Size = UDim2.new(1, -6, 0, 20), TextSize = 11, TextColor3 = MUTED, LayoutOrder = order,
		TextYAlignment = Enum.TextYAlignment.Bottom })
end
local function sideTab(id, text)
	order += 1
	local b = button(side, "", { Size = UDim2.new(1, -6, 0, 30), BackgroundColor3 = BG2, BackgroundTransparency = 1, LayoutOrder = order, AutoButtonColor = false })
	corner(b, 8)
	local bar = mk("Frame", { Size = UDim2.new(0, 3, 0.6, 0), Position = UDim2.new(0, 0, 0.2, 0), BackgroundColor3 = ACCENT2, BorderSizePixel = 0, Visible = false }, b)
	corner(bar, 2)
	local t = label(b, { Text = text, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -50, 1, 0), Font = Enum.Font.GothamMedium })
	local c = label(b, { Text = "", Position = UDim2.new(1, -42, 0, 0), Size = UDim2.new(0, 34, 1, 0), TextSize = 12, TextColor3 = MUTED,
		TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium })
	b.MouseEnter:Connect(function() if tab ~= id then b.BackgroundTransparency = 0.5 end end)
	b.MouseLeave:Connect(function() if tab ~= id then b.BackgroundTransparency = 1 end end)
	tabButtons[id] = { button = b, bar = bar, text = t, count = c }
	return b
end
sideTab("All", "🎶  All Songs")
sideTab("Fav", "⭐  Favorites")
sideTab("Playlist", "📃  My Playlist")
sideHeader("   MOODS")
for _, c in ipairs(Library.Categories) do sideTab(c.id, c.icon .. "  " .. c.name) end
sideHeader("   TOGETHER")
sideTab("Party", "👥  Listen Together")

-- content
local content = mk("Frame", { Position = UDim2.fromOffset(200, 72), Size = UDim2.new(1, -212, 1, -186), BackgroundColor3 = BG1 }, win)
corner(content, 14)
local listTitle = label(content, { Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -150, 0, 22), TextSize = 16 })
local listDesc = label(content, { Position = UDim2.fromOffset(16, 28), Size = UDim2.new(1, -150, 0, 14), TextSize = 11, TextColor3 = MUTED, Font = Enum.Font.GothamMedium })
local playAll = button(content, "▶  Play all", { Position = UDim2.new(1, -124, 0, 10), Size = UDim2.fromOffset(110, 30), BackgroundColor3 = ACCENT, TextSize = 13 })
corner(playAll, 15)
local list = mk("ScrollingFrame", {
	Position = UDim2.fromOffset(6, 48), Size = UDim2.new(1, -12, 1, -54), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 5, ScrollBarImageColor3 = STROKE, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, content)
mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)
local emptyLabel = label(content, {
	Text = "", Position = UDim2.new(0, 20, 0.5, -30), Size = UDim2.new(1, -40, 0, 60), TextColor3 = MUTED, TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, Visible = false, Font = Enum.Font.GothamMedium,
})

-- Listen Together page
local partyPage = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, content)
local card = mk("Frame", { Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 128), BackgroundColor3 = BG2 }, partyPage)
corner(card, 12)
mk("UIGradient", { Rotation = 20, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 230, 220)) }, card)
local cardTitle = label(card, { Position = UDim2.fromOffset(18, 14), Size = UDim2.new(1, -210, 0, 24), TextSize = 18 })
local cardText = label(card, {
	Position = UDim2.fromOffset(18, 42), Size = UDim2.new(1, -210, 0, 76), TextSize = 13, TextColor3 = MUTED, TextWrapped = true,
	TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.GothamMedium,
})
local cardBtn = button(card, "", { Position = UDim2.new(1, -178, 0.5, -21), Size = UDim2.fromOffset(160, 42), BackgroundColor3 = ACCENT, TextSize = 14 })
corner(cardBtn, 21)
label(partyPage, { Text = "OPEN PARTIES ON THIS SERVER", Position = UDim2.fromOffset(16, 150), Size = UDim2.new(1, -32, 0, 20), TextSize = 11, TextColor3 = MUTED })
local partyList = mk("ScrollingFrame", {
	Position = UDim2.fromOffset(6, 174), Size = UDim2.new(1, -12, 1, -180), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 5, ScrollBarImageColor3 = STROKE, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, partyPage)
mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, partyList)
local partyEmpty = label(partyPage, {
	Text = "No parties yet — start one and your friends can join!", Position = UDim2.new(0, 20, 0, 190), Size = UDim2.new(1, -40, 0, 40),
	TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamMedium, TextSize = 13,
})

-- now playing bar
local bar = mk("Frame", { Position = UDim2.new(0, 12, 1, -104), Size = UDim2.new(1, -24, 0, 92), BackgroundColor3 = Color3.fromRGB(34, 34, 46) }, win)
corner(bar, 14)
stroke(bar, STROKE, 1)
local cover = mk("Frame", { Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(68, 68) }, bar)
corner(cover, 12)
coverize(cover, nil)
local coverIcon = label(cover, { Text = "🎵", Size = UDim2.fromScale(1, 1), TextSize = 30, TextXAlignment = Enum.TextXAlignment.Center })
local nTitle = label(bar, { Text = "Nothing playing", Position = UDim2.fromOffset(92, 16), Size = UDim2.fromOffset(150, 22), TextSize = 15 })
local nArtist = label(bar, { Text = "Pick a song from the list", Position = UDim2.fromOffset(92, 38), Size = UDim2.fromOffset(150, 18), TextSize = 12, TextColor3 = MUTED, Font = Enum.Font.GothamMedium })
local nTag = label(bar, { Text = "", Position = UDim2.fromOffset(92, 58), Size = UDim2.fromOffset(150, 16), TextSize = 11, TextColor3 = ACCENT2 })
local nFav = button(bar, "🤍", { Position = UDim2.fromOffset(244, 14), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, TextSize = 20, TextColor3 = MUTED })

local ctrl = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(280, 46), BackgroundTransparency = 1 }, bar)
mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, ctrl)
local function ctrlBtn(text, size, o)
	local b = button(ctrl, text, { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, TextSize = math.floor(size * 0.5), LayoutOrder = o, TextColor3 = TEXT })
	corner(b, size // 2)
	return b
end
local shuffleBtn = ctrlBtn("🔀", 34, 1)
local prevBtn = ctrlBtn("⏮", 36, 2)
local playBtn = ctrlBtn("▶", 46, 3)
playBtn.BackgroundTransparency = 0
playBtn.BackgroundColor3 = ACCENT
playBtn.TextSize = 20
local nextBtn = ctrlBtn("⏭", 36, 4)
local repeatBtn = ctrlBtn("🔁", 34, 5)

local seekRow = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 60), Size = UDim2.fromOffset(310, 22), BackgroundTransparency = 1 }, bar)
local tCur = label(seekRow, { Text = "0:00", Size = UDim2.new(0, 40, 1, 0), TextSize = 11, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium })
local tEnd = label(seekRow, { Text = "0:00", Position = UDim2.new(1, -40, 0, 0), Size = UDim2.new(0, 40, 1, 0), TextSize = 11, TextColor3 = MUTED, Font = Enum.Font.GothamMedium })
local function sliderTrack(parent, pos, size)
	local hit = mk("Frame", { Position = pos, Size = size, BackgroundTransparency = 1, Active = true }, parent)
	local track = mk("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = BG3, BorderSizePixel = 0 }, hit)
	corner(track, 3)
	local fill = mk("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = ACCENT2, BorderSizePixel = 0 }, track)
	corner(fill, 3)
	local knob = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = TEXT, BorderSizePixel = 0 }, track)
	corner(knob, 6)
	return hit, fill, knob
end
local seekHit, seekFill, seekKnob = sliderTrack(seekRow, UDim2.fromOffset(48, 0), UDim2.new(1, -96, 1, 0))

local volBtn = button(bar, "🔊", { Position = UDim2.new(1, -206, 0, 14), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, TextSize = 16 })
local volHit, volFill, volKnob = sliderTrack(bar, UDim2.new(1, -172, 0, 17), UDim2.fromOffset(120, 22))
local volPct = label(bar, { Text = "50%", Position = UDim2.new(1, -46, 0, 17), Size = UDim2.fromOffset(36, 22), TextSize = 11, TextColor3 = MUTED, Font = Enum.Font.GothamMedium })

local vis = mk("Frame", { Position = UDim2.new(1, -206, 0, 48), Size = UDim2.fromOffset(192, 32), BackgroundTransparency = 1, ClipsDescendants = true }, bar)
local VIS_N = 24
local visBars, visH = {}, {}
for i = 1, VIS_N do
	local b = mk("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) / VIS_N, 0, 1, 0), Size = UDim2.new(1 / VIS_N, -3, 0.08, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	}, vis)
	corner(b, 2)
	mk("UIGradient", { Rotation = -90, Color = ColorSequence.new(ACCENT, ACCENT2) }, b)
	visBars[i], visH[i] = b, 0.08
end

-- toast
local toast = label(gui, {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.new(0.9, 0, 0, 34), BackgroundColor3 = BG,
	BackgroundTransparency = 0.1, TextXAlignment = Enum.TextXAlignment.Center, TextSize = 14, TextWrapped = true, Visible = false, ZIndex = 20,
})
mk("UISizeConstraint", { MaxSize = Vector2.new(440, 34) }, toast)
corner(toast, 19)
stroke(toast, ACCENT, 1.5)
local toastToken = 0
local function showToast(text)
	toastToken += 1
	local my = toastToken
	toast.Text = text
	toast.Visible = true
	task.delay(3.2, function() if toastToken == my then toast.Visible = false end end)
end

------------------------------------------------------------ UI: MINI PLAYER (window closed)
local mini = mk("TextButton", { Name = "Mini", Size = UDim2.fromOffset(250, 54), BackgroundColor3 = BG, Text = "", AutoButtonColor = false, Visible = false }, gui)
corner(mini, 14)
stroke(mini, STROKE, 1.5)
local mCover = mk("Frame", { Position = UDim2.fromOffset(7, 7), Size = UDim2.fromOffset(40, 40) }, mini)
corner(mCover, 9)
coverize(mCover, nil)
local mIcon = label(mCover, { Text = "🎵", Size = UDim2.fromScale(1, 1), TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center })
local mTitle = label(mini, { Position = UDim2.fromOffset(54, 9), Size = UDim2.new(1, -128, 0, 18), TextSize = 13 })
local mArtist = label(mini, { Position = UDim2.fromOffset(54, 27), Size = UDim2.new(1, -128, 0, 16), TextSize = 11, TextColor3 = MUTED, Font = Enum.Font.GothamMedium })
local mPlay = button(mini, "▶", { Position = UDim2.new(1, -70, 0.5, -15), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = ACCENT, TextSize = 13 })
corner(mPlay, 15)
local mNext = button(mini, "⏭", { Position = UDim2.new(1, -36, 0.5, -15), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, TextSize = 15 })
local mProg = mk("Frame", { Position = UDim2.new(0, 10, 1, -3), Size = UDim2.new(0, 0, 0, 2), BackgroundColor3 = ACCENT2, BorderSizePixel = 0 }, mini)

local rail = hud:WaitForChild("Rail")
local musicButton = rail:WaitForChild("MusicButton", 10)
local settingsBtn = hud:WaitForChild("SettingsButton", 10)
local UISm = game:GetService("UserInputService")
local function placeMini()
	local s = uiScale.Scale
	local phone = UISm.TouchEnabled and gui.AbsoluteSize.Y > 2 -- phones & tablets
	if phone and settingsBtn then
		-- phones: top-right, next to Settings (keeps the bottom-left free for the thumbstick)
		local sp, ss = settingsBtn.AbsolutePosition, settingsBtn.AbsoluteSize
		mini.AnchorPoint = Vector2.new(1, 0)
		mini.Position = UDim2.fromOffset((sp.X - 8) / s, (sp.Y + ss.Y / 2) / s - 27)
	else
		local ap, as = rail.AbsolutePosition, rail.AbsoluteSize
		mini.AnchorPoint = Vector2.new(0, 0)
		mini.Position = UDim2.fromOffset(ap.X / s, (ap.Y + as.Y) / s + 12)
	end
end
rail:GetPropertyChangedSignal("AbsolutePosition"):Connect(placeMini)
rail:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeMini)
if settingsBtn then settingsBtn:GetPropertyChangedSignal("AbsolutePosition"):Connect(placeMini) end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeMini)
placeMini()

------------------------------------------------------------ SAVE
local saveToken = 0
local function markDirty()
	saveToken += 1
	local my = saveToken
	task.delay(3, function()
		if my ~= saveToken then return end
		pcall(fn.InvokeServer, fn, "save", saved)
	end)
end
local function rebuildSets()
	favSet, plSet = {}, {}
	for _, id in ipairs(saved.favs) do favSet[id] = true end
	for _, id in ipairs(saved.playlist) do plSet[id] = true end
end
local function removeId(t, id)
	for i, v in ipairs(t) do if v == id then table.remove(t, i) return end end
end

------------------------------------------------------------ LISTS
local function songsFor(tabId)
	local out = {}
	if tabId == "All" then
		for _, s in ipairs(Library.Songs) do table.insert(out, s) end
	elseif tabId == "Fav" then
		for _, id in ipairs(saved.favs) do if Library.ById[id] then table.insert(out, Library.ById[id]) end end
	elseif tabId == "Playlist" then
		for _, id in ipairs(saved.playlist) do if Library.ById[id] then table.insert(out, Library.ById[id]) end end
	else
		for _, s in ipairs(Library.Songs) do if s.cat == tabId then table.insert(out, s) end end
	end
	return out
end
local function filtered(tabId)
	local songs = songsFor(tabId)
	if search == "" then return songs end
	local q = search:lower()
	local out = {}
	for _, s in ipairs(songs) do
		if s.title:lower():find(q, 1, true) or s.artist:lower():find(q, 1, true) then table.insert(out, s) end
	end
	return out
end

local function shuffleIds(ids, firstId)
	for i = #ids, 2, -1 do
		local j = math.random(1, i)
		ids[i], ids[j] = ids[j], ids[i]
	end
	if firstId then
		for i, id in ipairs(ids) do
			if id == firstId then table.remove(ids, i) table.insert(ids, 1, id) break end
		end
	end
	return ids
end
local function buildQueue(songs, startId)
	queue = {}
	for _, s in ipairs(songs) do table.insert(queue, s.id) end
	if saved.shuffle then shuffleIds(queue, startId) end
	qpos = 1
	for i, id in ipairs(queue) do if id == startId then qpos = i break end end
end

------------------------------------------------------------ PLAYBACK
local rows = {}
local renderList, refreshNow, refreshTabs, refreshParty

local function currentState()
	if not current then return nil end
	local pos = sound.TimePosition
	return {
		songId = current.id,
		startedAt = workspace:GetServerTimeNow() - pos,
		paused = not sound.IsPlaying,
		pausedAt = pos,
	}
end
local function sendState()
	if party and isHost and current then ev:FireServer("update", currentState()) end
end

local nextSong

-- startAt: number or function returning the start position (evaluated after the song loads)
local function playSong(song, startAt, fromParty, startPaused)
	if not song then return end
	loadToken += 1
	local my = loadToken
	current = song
	sound:Stop()
	sound.SoundId = "rbxassetid://" .. song.id
	refreshNow()
	for id, r in pairs(rows) do r.update() end
	if not win.Visible and not fromParty then
		local cat = catById[song.cat]
		showToast("🎵 Now playing: " .. song.title .. " — " .. song.artist)
	end
	local t0 = os.clock()
	while not (sound.IsLoaded and sound.TimeLength > 0) and os.clock() - t0 < 10 do
		task.wait(0.1)
		if my ~= loadToken then return end
	end
	if my ~= loadToken then return end
	if not sound.IsLoaded or sound.TimeLength <= 0 then
		fails += 1
		showToast("⚠️ Couldn't load \"" .. song.title .. "\"" .. (fromParty and "" or " — skipping"))
		if not fromParty and not locked() and fails < 6 then nextSong(true) end
		return
	end
	fails = 0
	local pos = type(startAt) == "function" and startAt() or (startAt or 0)
	if pos >= sound.TimeLength - 0.5 then pos = 0 end
	sound.TimePosition = math.max(0, pos)
	if startPaused then
		sound:Pause()
	else
		sound:Play()
		sound.TimePosition = math.max(0, pos)
	end
	refreshNow()
	if not fromParty then sendState() end
end

nextSong = function(auto)
	if locked() then showToast("🎧 Only the party host can change songs") return end
	if #queue == 0 then
		local songs = filtered(tab == "Party" and "All" or tab)
		if #songs == 0 then songs = Library.Songs end
		buildQueue(songs, nil)
		qpos = 0
	end
	qpos += 1
	if qpos > #queue then
		if auto and saved.rep == "off" then
			qpos = #queue
			sound:Stop()
			refreshNow()
			sendState()
			return
		end
		qpos = 1
		if saved.shuffle then shuffleIds(queue) end
	end
	playSong(Library.ById[queue[qpos]])
end

local function prevSong()
	if locked() then showToast("🎧 Only the party host can change songs") return end
	if current and sound.TimePosition > 4 then
		sound.TimePosition = 0
		sendState()
		return
	end
	if #queue == 0 then nextSong() return end
	qpos -= 1
	if qpos < 1 then qpos = #queue end
	playSong(Library.ById[queue[qpos]])
end

local function togglePlay()
	if locked() then showToast("🎧 Only the party host can pause — leave the party to play your own music") return end
	if not current then nextSong() return end
	if sound.IsPlaying then
		sound:Pause()
	elseif sound.IsLoaded then
		if sound.TimePosition >= sound.TimeLength - 0.3 then sound.TimePosition = 0 end
		sound:Resume()
	else
		playSong(current)
		return
	end
	refreshNow()
	sendState()
end

sound.Ended:Connect(function()
	if locked() then return end -- members wait for the host
	if saved.rep == "one" then
		sound.TimePosition = 0
		sound:Play()
		sendState()
	else
		nextSong(true)
	end
end)

------------------------------------------------------------ RENDER: NOW PLAYING
refreshNow = function()
	local playing = sound.IsPlaying
	playBtn.Text = playing and "II" or "▶"
	playBtn.TextSize = playing and 17 or 20
	playBtn.Font = playing and Enum.Font.GothamBlack or Enum.Font.GothamBold
	mPlay.Text = playing and "II" or "▶"
	mPlay.TextSize = playing and 13 or 13
	mPlay.Font = playing and Enum.Font.GothamBlack or Enum.Font.GothamBold
	if current then
		local cat = catById[current.cat]
		nTitle.Text = current.title
		nArtist.Text = current.artist
		nTag.Text = cat and (cat.icon .. " " .. cat.name) or ""
		coverIcon.Text = cat and cat.icon or "🎵"
		coverize(cover, current.cat)
		mTitle.Text = current.title
		mArtist.Text = (party and "🎧 " or "") .. current.artist
		mIcon.Text = coverIcon.Text
		coverize(mCover, current.cat)
		nFav.Text = favSet[current.id] and "⭐" or "🤍"
		nFav.TextColor3 = favSet[current.id] and GOLD or MUTED
	else
		nTitle.Text = "Nothing playing"
		nArtist.Text = "Pick a song from the list"
		nTag.Text = ""
		nFav.Text = "🤍"
	end
	shuffleBtn.TextTransparency = saved.shuffle and 0 or 0.6
	shuffleBtn.BackgroundTransparency = saved.shuffle and 0.6 or 1
	shuffleBtn.BackgroundColor3 = ACCENT
	repeatBtn.Text = saved.rep == "one" and "🔂" or "🔁"
	repeatBtn.TextTransparency = saved.rep == "off" and 0.6 or 0
	repeatBtn.BackgroundTransparency = saved.rep == "off" and 1 or 0.6
	repeatBtn.BackgroundColor3 = ACCENT
	prevBtn.TextTransparency = locked() and 0.55 or 0
	nextBtn.TextTransparency = locked() and 0.55 or 0
	if locked() then shuffleBtn.TextTransparency = 0.7 repeatBtn.TextTransparency = 0.7 end
	playBtn.BackgroundColor3 = locked() and BG3 or ACCENT
	volFill.Size = UDim2.fromScale(saved.vol, 1)
	volKnob.Position = UDim2.fromScale(saved.vol, 0.5)
	volPct.Text = math.floor(saved.vol * 100 + 0.5) .. "%"
	volBtn.Text = saved.vol <= 0.001 and "🔇" or (saved.vol < 0.4 and "🔉" or "🔊")
	subLabel.Text = party and (isHost and ("🎧 You're hosting a listening party · " .. party.count .. " listening")
		or ("🎧 Listening together with " .. party.hostName .. " · " .. party.count .. " listening"))
		or (#Library.Songs .. " songs · all licensed for Roblox")
	subLabel.TextColor3 = party and ACCENT2 or MUTED
	mini.Visible = current ~= nil and not win.Visible
end

------------------------------------------------------------ RENDER: SONG LIST
local function makeRow(song, i)
	local row = mk("TextButton", { Size = UDim2.new(1, -6, 0, 46), BackgroundColor3 = BG2, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = i }, list)
	corner(row, 10)
	local num = label(row, { Text = tostring(i), Size = UDim2.new(0, 34, 1, 0), TextColor3 = MUTED, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamMedium })
	local tile = mk("Frame", { Position = UDim2.fromOffset(38, 7), Size = UDim2.fromOffset(32, 32) }, row)
	corner(tile, 8)
	coverize(tile, song.cat)
	local cat = catById[song.cat]
	label(tile, { Text = cat and cat.icon or "🎵", Size = UDim2.fromScale(1, 1), TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center })
	local t = label(row, { Text = song.title, Position = UDim2.fromOffset(80, 6), Size = UDim2.new(1, -270, 0, 18), TextSize = 14 })
	label(row, { Text = song.artist, Position = UDim2.fromOffset(80, 24), Size = UDim2.new(1, -270, 0, 16), TextSize = 12, TextColor3 = MUTED, Font = Enum.Font.GothamMedium })
	label(row, { Text = cat and cat.name or "", Position = UDim2.new(1, -184, 0, 0), Size = UDim2.new(0, 100, 1, 0), TextSize = 11, TextColor3 = MUTED, Font = Enum.Font.GothamMedium })
	local fav = button(row, "🤍", { Position = UDim2.new(1, -76, 0.5, -15), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, TextSize = 18 })
	local add = button(row, "+", { Position = UDim2.new(1, -40, 0.5, -15), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, TextSize = 18 })
	local hovering = false
	local function update()
		local isCur = current and current.id == song.id
		row.BackgroundTransparency = isCur and 0 or (hovering and 0.5 or 1)
		row.BackgroundColor3 = isCur and Color3.fromRGB(28, 70, 58) or BG2
		num.Text = isCur and (sound.IsPlaying and "🎵" or "II") or tostring(i)
		num.TextColor3 = isCur and ACCENT2 or MUTED
		t.TextColor3 = isCur and ACCENT2 or TEXT
		fav.Text = favSet[song.id] and "⭐" or "🤍"
		fav.TextColor3 = favSet[song.id] and GOLD or MUTED
		add.Text = plSet[song.id] and "✓" or "+"
		add.TextColor3 = plSet[song.id] and ACCENT2 or MUTED
	end
	row.MouseEnter:Connect(function() hovering = true update() end)
	row.MouseLeave:Connect(function() hovering = false update() end)
	row.MouseButton1Click:Connect(function()
		if locked() then showToast("🎧 Only the party host can change songs — leave the party to pick your own") return end
		if current and current.id == song.id then togglePlay() return end
		buildQueue(filtered(tab), song.id)
		playSong(song)
	end)
	fav.MouseButton1Click:Connect(function()
		if favSet[song.id] then
			removeId(saved.favs, song.id)
			showToast("Removed from ⭐ Favorites")
		else
			table.insert(saved.favs, song.id)
			showToast("⭐ Added to Favorites")
		end
		rebuildSets()
		markDirty()
		if tab == "Fav" then renderList() else update() end
		refreshTabs()
		refreshNow()
	end)
	add.MouseButton1Click:Connect(function()
		if plSet[song.id] then
			removeId(saved.playlist, song.id)
			showToast("Removed from 📃 My Playlist")
		else
			if #saved.playlist >= 200 then showToast("Your playlist is full (200 songs)") return end
			table.insert(saved.playlist, song.id)
			showToast("📃 Added to My Playlist")
		end
		rebuildSets()
		markDirty()
		if tab == "Playlist" then renderList() else update() end
		refreshTabs()
	end)
	update()
	return { update = update }
end

local EMPTY = {
	Fav = "No favorites yet.\nTap 🤍 on any song to save it here.",
	Playlist = "Your playlist is empty.\nTap + on any song to add it.",
}

renderList = function()
	for _, c in ipairs(list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	rows = {}
	local isParty = tab == "Party"
	partyPage.Visible = isParty
	list.Visible = not isParty
	listTitle.Visible, listDesc.Visible, playAll.Visible = not isParty, not isParty, not isParty
	if isParty then emptyLabel.Visible = false refreshParty(true) return end
	local songs = filtered(tab)
	local cat = catById[tab]
	local name = tab == "All" and "🎶 All Songs" or tab == "Fav" and "⭐ Favorites" or tab == "Playlist" and "📃 My Playlist"
		or (cat and (cat.icon .. " " .. cat.name)) or tab
	listTitle.Text = name .. "  ·  " .. #songs .. (#songs == 1 and " song" or " songs")
	listDesc.Text = search ~= "" and ("Results for \"" .. search .. "\"") or (cat and cat.desc or (tab == "All" and "Everything in the campus library" or "Saved to your account"))
	for i, s in ipairs(songs) do rows[s.id] = makeRow(s, i) end
	emptyLabel.Visible = #songs == 0
	emptyLabel.Text = search ~= "" and "No songs match your search." or (EMPTY[tab] or "No songs here yet.")
	playAll.Visible = #songs > 0
end

refreshTabs = function()
	for id, t in pairs(tabButtons) do
		local on = id == tab
		t.button.BackgroundTransparency = on and 0 or 1
		t.bar.Visible = on
		t.text.TextColor3 = on and TEXT or Color3.fromRGB(210, 210, 220)
		if id == "Party" then
			t.count.Text = party and "●" or ""
			t.count.TextColor3 = ACCENT2
		else
			t.count.Text = tostring(#songsFor(id))
			t.count.TextColor3 = MUTED
		end
	end
end

for id, t in pairs(tabButtons) do
	t.button.MouseButton1Click:Connect(function()
		tab = id
		list.CanvasPosition = Vector2.zero
		refreshTabs()
		renderList()
	end)
end

playAll.MouseButton1Click:Connect(function()
	if locked() then showToast("🎧 Only the party host can change songs") return end
	local songs = filtered(tab)
	if #songs == 0 then return end
	buildQueue(songs, nil)
	qpos = 1
	playSong(Library.ById[queue[1]])
end)

------------------------------------------------------------ LISTEN TOGETHER
local lastPartyFetch = 0
refreshParty = function(fetch)
	if party then
		if isHost then
			cardTitle.Text = "🎧 You're the host"
			cardText.Text = "Everyone in your party hears what you play, at the same moment. Listening: " .. table.concat(party.listeners, ", ")
			cardBtn.Text = "End party"
			cardBtn.BackgroundColor3 = Color3.fromRGB(170, 60, 70)
		else
			cardTitle.Text = "🎧 In " .. party.hostName .. "'s party"
			cardText.Text = party.hostName .. " picks the songs. You can still change your own volume. Listening: " .. table.concat(party.listeners, ", ")
			cardBtn.Text = "Leave party"
			cardBtn.BackgroundColor3 = Color3.fromRGB(170, 60, 70)
		end
	else
		cardTitle.Text = "👥 Listen Together"
		cardText.Text = "Start a listening party and everyone who joins hears the same song at the same time — perfect for hanging out. Play a song first, then start."
		cardBtn.Text = "🎧 Start a party"
		cardBtn.BackgroundColor3 = ACCENT
	end
	if not fetch or os.clock() - lastPartyFetch < 1 then return end
	lastPartyFetch = os.clock()
	task.spawn(function()
		local ok, parties = pcall(fn.InvokeServer, fn, "parties")
		if not ok or type(parties) ~= "table" then return end
		for _, c in ipairs(partyList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		local shown = 0
		for i, p in ipairs(parties) do
			shown += 1
			local r = mk("Frame", { Size = UDim2.new(1, -6, 0, 54), BackgroundColor3 = BG2, LayoutOrder = i }, partyList)
			corner(r, 10)
			local song = p.state and Library.ById[p.state.songId]
			local tile = mk("Frame", { Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(36, 36) }, r)
			corner(tile, 8)
			coverize(tile, song and song.cat)
			label(tile, { Text = "🎧", Size = UDim2.fromScale(1, 1), TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center })
			label(r, { Text = p.hostName .. "'s party  ·  " .. p.count .. " listening", Position = UDim2.fromOffset(56, 8), Size = UDim2.new(1, -170, 0, 18), TextSize = 14 })
			label(r, { Text = song and ("🎵 " .. song.title .. " — " .. song.artist) or "", Position = UDim2.fromOffset(56, 28), Size = UDim2.new(1, -170, 0, 16),
				TextSize = 12, TextColor3 = MUTED, Font = Enum.Font.GothamMedium })
			local inIt = party and party.hostId == p.hostId
			local j = button(r, inIt and "Joined ✓" or "Join", { Position = UDim2.new(1, -104, 0.5, -16), Size = UDim2.fromOffset(92, 32),
				BackgroundColor3 = inIt and BG3 or ACCENT, TextSize = 13, AutoButtonColor = not inIt })
			corner(j, 16)
			if not inIt then
				j.MouseButton1Click:Connect(function() ev:FireServer("join", p.hostId) end)
			end
		end
		partyEmpty.Visible = shown == 0
	end)
end

cardBtn.MouseButton1Click:Connect(function()
	if party then
		ev:FireServer("leave")
	else
		if not current then showToast("Play a song first, then start the party") return end
		ev:FireServer("host", currentState())
	end
end)

local function applyState(st)
	partyState = st
	local song = st and Library.ById[st.songId]
	if not song then return end
	local function target()
		if st.paused then return st.pausedAt end
		return workspace:GetServerTimeNow() - st.startedAt
	end
	if not current or current.id ~= song.id or not sound.IsLoaded then
		playSong(song, target, true, st.paused)
		return
	end
	if st.paused then
		sound:Pause()
		sound.TimePosition = math.min(st.pausedAt, sound.TimeLength)
	else
		local t = target()
		if t >= sound.TimeLength then return end
		if math.abs(sound.TimePosition - t) > 1 then sound.TimePosition = t end
		if not sound.IsPlaying then sound:Resume() end
	end
	refreshNow()
	for _, r in pairs(rows) do r.update() end
end

ev.OnClientEvent:Connect(function(kind, arg)
	if kind == "party" then
		local wasMember = party ~= nil and not isHost
		party = arg
		isHost = party ~= nil and party.hostId == player.UserId
		if party and not isHost and party.state then applyState(party.state) end
		if not party and wasMember then partyState = nil end
		refreshParty(tab == "Party")
		refreshTabs()
		refreshNow()
	elseif kind == "state" then
		if party and not isHost then applyState(arg) end
	elseif kind == "toast" then
		showToast(tostring(arg))
	end
end)

-- keep members in sync (small drift fix every few seconds)
task.spawn(function()
	while true do
		task.wait(4)
		if party and not isHost and partyState and not partyState.paused and current and current.id == partyState.songId and sound.IsLoaded then
			local t = workspace:GetServerTimeNow() - partyState.startedAt
			if t < sound.TimeLength and math.abs(sound.TimePosition - t) > 1.5 then sound.TimePosition = t end
		end
		if win.Visible and tab == "Party" then refreshParty(true) end
	end
end)

------------------------------------------------------------ CONTROLS
playBtn.MouseButton1Click:Connect(togglePlay)
mPlay.MouseButton1Click:Connect(togglePlay)
nextBtn.MouseButton1Click:Connect(function() nextSong(false) end)
mNext.MouseButton1Click:Connect(function() nextSong(false) end)
prevBtn.MouseButton1Click:Connect(prevSong)
shuffleBtn.MouseButton1Click:Connect(function()
	if locked() then return end
	saved.shuffle = not saved.shuffle
	if #queue > 0 then
		local curId = current and current.id
		if saved.shuffle then
			shuffleIds(queue, curId)
		else
			local set = {}
			for _, id in ipairs(queue) do set[id] = true end
			queue = {}
			for _, s in ipairs(Library.Songs) do if set[s.id] then table.insert(queue, s.id) end end
		end
		qpos = 1
		for i, id in ipairs(queue) do if id == curId then qpos = i break end end
	end
	showToast(saved.shuffle and "🔀 Shuffle on" or "Shuffle off")
	markDirty()
	refreshNow()
end)
repeatBtn.MouseButton1Click:Connect(function()
	if locked() then return end
	saved.rep = saved.rep == "all" and "one" or (saved.rep == "one" and "off" or "all")
	showToast(saved.rep == "all" and "🔁 Repeat all" or (saved.rep == "one" and "🔂 Repeat this song" or "Repeat off"))
	markDirty()
	refreshNow()
end)
nFav.MouseButton1Click:Connect(function()
	if not current then return end
	if favSet[current.id] then removeId(saved.favs, current.id) else table.insert(saved.favs, current.id) end
	rebuildSets()
	markDirty()
	if tab == "Fav" then renderList() else for _, r in pairs(rows) do r.update() end end
	refreshTabs()
	refreshNow()
end)

local lastVol = 0.5
local function setVol(v)
	saved.vol = math.clamp(v, 0, 1)
	sound.Volume = saved.vol
	refreshNow()
end
volBtn.MouseButton1Click:Connect(function()
	if saved.vol > 0 then lastVol = saved.vol setVol(0) else setVol(lastVol > 0 and lastVol or 0.5) end
	markDirty()
end)

local function slider(hit, onMove, onEnd)
	local dragging = false
	local function at(x) return math.clamp((x - hit.AbsolutePosition.X) / math.max(1, hit.AbsoluteSize.X), 0, 1) end
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			onMove(at(i.Position.X))
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			onMove(at(i.Position.X))
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			onEnd(at(i.Position.X))
		end
	end)
	return function() return dragging end
end

local seekPreview = nil
local seeking = slider(seekHit, function(f)
	if locked() or not current or sound.TimeLength <= 0 then return end
	seekPreview = f
end, function(f)
	if locked() then showToast("🎧 Only the party host can skip around") return end
	if not current or sound.TimeLength <= 0 then return end
	sound.TimePosition = f * sound.TimeLength
	seekPreview = nil
	sendState()
end)
slider(volHit, function(f) setVol(f) end, function(f) setVol(f) markDirty() end)

------------------------------------------------------------ SEARCH
searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	search = searchInput.Text:gsub("^%s+", ""):gsub("%s+$", "")
	clearSearch.Visible = searchInput.Text ~= ""
	if tab == "Party" and search ~= "" then tab = "All" refreshTabs() end
	renderList()
end)
searchInput.Focused:Connect(function() searchStroke.Color = ACCENT2 end)
searchInput.FocusLost:Connect(function() searchStroke.Color = STROKE end)
clearSearch.MouseButton1Click:Connect(function() searchInput.Text = "" end)

------------------------------------------------------------ OPEN / CLOSE
local hudPanel = hud:WaitForChild("Panel")
local function highlightButton(on)
	if not musicButton then return end
	local s = musicButton:FindFirstChildOfClass("UIStroke")
	if s then s.Color = on and ACCENT or STROKE s.Thickness = on and 2.5 or 1.5 end
end
local function openWindow()
	hudPanel.Visible = false
	fit()
	win.Visible = true
	win.Position = UDim2.new(0.5, 30, 0.5, 16)
	TweenService:Create(win, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 30, 0.5, 0) }):Play()
	highlightButton(true)
	refreshTabs()
	renderList()
	refreshNow()
end
local function closeWindow()
	win.Visible = false
	highlightButton(false)
	refreshNow()
end
local function toggleWindow() if win.Visible then closeWindow() else openWindow() end end
if musicButton then musicButton.MouseButton1Click:Connect(toggleWindow) end
closeBtn.MouseButton1Click:Connect(closeWindow)
mini.MouseButton1Click:Connect(openWindow)
hudPanel:GetPropertyChangedSignal("Visible"):Connect(function() if hudPanel.Visible and win.Visible then closeWindow() end end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.N then toggleWindow() end
end)

------------------------------------------------------------ LOOP: seek bar + visualizer
local lastPlaying = nil
RunService.RenderStepped:Connect(function(dt)
	if sound.IsPlaying ~= lastPlaying then
		lastPlaying = sound.IsPlaying
		refreshNow()
		for _, r in pairs(rows) do r.update() end
	end
	local len = sound.TimeLength
	local f = len > 0 and math.clamp(sound.TimePosition / len, 0, 1) or 0
	if mini.Visible then mProg.Size = UDim2.new(f, -20 * f, 0, 2) end
	if not win.Visible then return end
	local shown = (seeking() and seekPreview) or f
	seekFill.Size = UDim2.fromScale(shown, 1)
	seekKnob.Position = UDim2.fromScale(shown, 0.5)
	tCur.Text = fmt(shown * len)
	tEnd.Text = fmt(len)
	local loud = sound.IsPlaying and math.clamp(sound.PlaybackLoudness / 320, 0, 1) or 0
	local t = os.clock()
	for i = 1, VIS_N do
		local wave = 0.35 + 0.65 * math.abs(math.sin(t * (2.1 + i * 0.37) + i * 1.7))
		local target = math.max(0.08, loud * wave)
		visH[i] += (target - visH[i]) * math.min(1, dt * 14)
		visBars[i].Size = UDim2.new(1 / VIS_N, -3, visH[i], 0)
	end
end)

------------------------------------------------------------ START
task.spawn(function()
	local ok, d = pcall(fn.InvokeServer, fn, "load")
	if ok and type(d) == "table" then
		saved.favs = d.favs or {}
		saved.playlist = d.playlist or {}
		saved.vol = tonumber(d.vol) or 0.5
		saved.shuffle = d.shuffle == true
		saved.rep = d.rep or "all"
	end
	lastVol = saved.vol > 0 and saved.vol or 0.5
	sound.Volume = saved.vol
	rebuildSets()
	refreshTabs()
	if win.Visible then renderList() end
	refreshNow()

	-- AUTO-PLAY: once the player taps "TAP TO CONTINUE", start a random song from the whole library
	local pg = player:WaitForChild("PlayerGui")
	local t0 = os.clock()
	while not player:GetAttribute("SC_Continued") do
		-- fallback: no loading screen at all (e.g. it was skipped) -> start after a moment
		if os.clock() - t0 > 8 and not pg:FindFirstChild("SC_LoadingScreen") then break end
		task.wait(0.25)
	end
	task.wait(1.2)
	if current or party then return end
	queue = {}
	for _, s in ipairs(Library.Songs) do table.insert(queue, s.id) end
	shuffleIds(queue)
	qpos = 1
	playSong(Library.ById[queue[1]])
	task.delay(4, function()
		if not win.Visible then showToast("🎵 Tap Music (or press N) to pause or pick a song") end
	end)
end)
refreshTabs()
refreshNow()
