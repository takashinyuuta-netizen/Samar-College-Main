--[[ WeatherPage — Settings → 🌦️ Weather & Season (second settings page).
  Each player can pick any weather or season for their OWN screen (others are not affected),
  or "Auto" to see the live campus weather. Sets player attribute "Setting_Weather" (WeatherClient draws it). ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local hud = script.Parent
local pages = hud:WaitForChild("Panel"):WaitForChild("Pages")
local settingsPage = pages:WaitForChild("SettingsPage")
local folder = RS:WaitForChild("Weather")
local C = require(folder:WaitForChild("WeatherConfig"))

local CARD = Color3.fromRGB(42, 42, 55)
local CARD_ON = Color3.fromRGB(20, 140, 100)
local GREY = Color3.fromRGB(165, 165, 180)
local WHITE = Color3.fromRGB(245, 245, 245)
local function new(class, props, parent) local o = Instance.new(class) for k, v in pairs(props or {}) do o[k] = v end o.Parent = parent return o end
local function corner(p, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 10) }, p) end

if player:GetAttribute("Setting_Weather") == nil then player:SetAttribute("Setting_Weather", "Auto") end

---------------------------------------------------------------- entry button on the Settings page
local entry = new("TextButton", { Name = "WeatherEntry", LayoutOrder = 0, Size = UDim2.new(1, -8, 0, 44), BackgroundColor3 = Color3.fromRGB(30, 60, 90), Text = "", AutoButtonColor = true }, settingsPage)
corner(entry, 10)
new("UIStroke", { Color = Color3.fromRGB(110, 180, 255), Thickness = 1.5, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, entry)
local entryIcon = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(36, 44), Position = UDim2.fromOffset(6, 0), Text = "🌦️", TextScaled = true, Font = Enum.Font.GothamBold }, entry)
new("UITextSizeConstraint", { MaxTextSize = 24 }, entryIcon)
new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -90, 0, 20), Position = UDim2.fromOffset(46, 4), Text = "Weather & Season", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 15 }, entry)
local entrySub = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -90, 0, 16), Position = UDim2.fromOffset(46, 23), Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(170, 200, 230), Font = Enum.Font.Gotham, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd }, entry)
new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 44), Position = UDim2.new(1, -34, 0, 0), Text = "›", TextColor3 = WHITE, Font = Enum.Font.GothamBlack, TextSize = 26 }, entry)

---------------------------------------------------------------- the weather page
local page = new("ScrollingFrame", { Name = "WeatherPage", Size = settingsPage.Size, Position = settingsPage.Position, AnchorPoint = settingsPage.AnchorPoint,
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, ScrollBarImageColor3 = GREY, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, pages)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, page)
new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 12), PaddingRight = UDim.new(0, 6) }, page)

-- header: back + title
local header = new("Frame", { LayoutOrder = 1, Size = UDim2.new(1, -8, 0, 36), BackgroundTransparency = 1 }, page)
local back = new("TextButton", { Size = UDim2.fromOffset(84, 32), Position = UDim2.fromOffset(0, 2), BackgroundColor3 = CARD, Text = "‹  Back", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14 }, header)
corner(back, 8)
new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -96, 1, 0), Position = UDim2.fromOffset(94, 0), Text = "🌦️ Weather & Season", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE, Font = Enum.Font.GothamBlack, TextSize = 17 }, header)

-- live weather box
local live = new("Frame", { LayoutOrder = 2, Size = UDim2.new(1, -8, 0, 58), BackgroundColor3 = Color3.fromRGB(28, 34, 46) }, page)
corner(live, 10)
new("UIStroke", { Color = Color3.fromRGB(80, 90, 110), Thickness = 1, Transparency = 0.3 }, live)
local liveIcon = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(46, 58), Position = UDim2.fromOffset(6, 0), Text = "☀️", TextScaled = true, Font = Enum.Font.GothamBold }, live)
new("UITextSizeConstraint", { MaxTextSize = 32 }, liveIcon)
local liveTitle = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -64, 0, 20), Position = UDim2.fromOffset(56, 8), Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14 }, live)
local liveSub = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -64, 0, 18), Position = UDim2.fromOffset(56, 30), Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GREY, Font = Enum.Font.Gotham, TextSize = 12 }, live)

local function section(order, text)
	new("TextLabel", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = text, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GREY, Font = Enum.Font.GothamBold, TextSize = 13 }, page)
end

local cards = {}
local function makeCard(parent, id, icon, name, desc, wide)
	local b = new("TextButton", { Name = id, Text = "", AutoButtonColor = true, BackgroundColor3 = CARD, Size = wide and UDim2.new(1, -8, 0, 50) or UDim2.new() }, parent)
	corner(b, 10)
	local st = new("UIStroke", { Color = CARD_ON, Thickness = 2, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	local ic = new("TextLabel", { BackgroundTransparency = 1, Size = wide and UDim2.fromOffset(44, 50) or UDim2.new(1, 0, 0, 34), Position = wide and UDim2.fromOffset(6, 0) or UDim2.fromOffset(0, 6), Text = icon, TextScaled = true, Font = Enum.Font.GothamBold }, b)
	new("UITextSizeConstraint", { MaxTextSize = 28 }, ic)
	local nm = new("TextLabel", { BackgroundTransparency = 1, Text = name, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextScaled = true,
		Size = wide and UDim2.new(1, -60, 0, 20) or UDim2.new(1, -8, 0, 16), Position = wide and UDim2.fromOffset(54, 6) or UDim2.fromOffset(4, 42), TextXAlignment = wide and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center }, b)
	new("UITextSizeConstraint", { MaxTextSize = 14 }, nm)
	local ds = new("TextLabel", { BackgroundTransparency = 1, Text = desc, TextColor3 = GREY, Font = Enum.Font.Gotham, TextScaled = true, TextWrapped = true,
		Size = wide and UDim2.new(1, -60, 0, 16) or UDim2.new(1, -10, 0, 22), Position = wide and UDim2.fromOffset(54, 27) or UDim2.fromOffset(5, 59), TextXAlignment = wide and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center }, b)
	new("UITextSizeConstraint", { MaxTextSize = 11 }, ds)
	local check = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -24, 0, 3), Text = "✓", TextColor3 = Color3.fromRGB(120, 240, 170), Font = Enum.Font.GothamBlack, TextSize = 18, Visible = false }, b)
	cards[id] = { button = b, stroke = st, check = check }
	b.MouseButton1Click:Connect(function()
		player:SetAttribute("Setting_Weather", id)
		TweenService:Create(b, TweenInfo.new(0.08), { Size = b.Size }):Play()
	end)
	return b
end

section(3, "MODE")
makeCard(page, "Auto", "🔄", "Auto — live campus weather", "Changes by itself every few minutes, same as everyone", true).LayoutOrder = 4

local function grid(order)
	local f = new("Frame", { LayoutOrder = order, Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, page)
	new("UIGridLayout", { CellSize = UDim2.new(0.333, -6, 0, 86), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, f)
	return f
end
section(5, "WEATHER")
local wGrid = grid(6)
section(7, "SEASONS")
local sGrid = grid(8)
for _, w in ipairs(C.List) do
	local b = makeCard(w.kind == "Season" and sGrid or wGrid, w.id, w.icon, w.name, w.desc, false)
	b.LayoutOrder = w.order
end
---------------------------------------------------------------- season detail switches
section(9, "SEASON DETAILS")
local toggles = {}
local function toggle(order, attr, icon, name, desc)
	if player:GetAttribute(attr) == nil then player:SetAttribute(attr, true) end
	local b = new("TextButton", { LayoutOrder = order, Text = "", AutoButtonColor = true, BackgroundColor3 = CARD, Size = UDim2.new(1, -8, 0, 52) }, page)
	corner(b, 10)
	local ic = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(44, 52), Position = UDim2.fromOffset(6, 0), Text = icon, TextScaled = true, Font = Enum.Font.GothamBold }, b)
	new("UITextSizeConstraint", { MaxTextSize = 24 }, ic)
	new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -140, 0, 20), Position = UDim2.fromOffset(54, 7), Text = name, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd }, b)
	new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -140, 0, 16), Position = UDim2.fromOffset(54, 28), Text = desc, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GREY, Font = Enum.Font.Gotham, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd }, b)
	local pill = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(52, 26), BackgroundColor3 = CARD_ON }, b)
	corner(pill, 13)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, -23, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = WHITE }, pill)
	corner(knob, 10)
	local function draw()
		local isOn = player:GetAttribute(attr) ~= false
		TweenService:Create(pill, TweenInfo.new(0.15), { BackgroundColor3 = isOn and CARD_ON or Color3.fromRGB(70, 70, 85) }):Play()
		TweenService:Create(knob, TweenInfo.new(0.15), { Position = isOn and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }):Play()
	end
	b.MouseButton1Click:Connect(function() player:SetAttribute(attr, player:GetAttribute(attr) == false) end)
	player:GetAttributeChangedSignal(attr):Connect(draw)
	draw()
end
toggle(10, "Setting_GroundCover", "❄️", "Snow & leaves on the ground", "Snow builds up outside, autumn leaves & spring petals pile up")
toggle(11, "Setting_SeasonSteps", "👣", "Season footsteps", "Crunchy snow steps, footprints, rustling leaves")
toggle(12, "Setting_SeasonCritters", "🦋", "Butterflies & frosty breath", "Butterflies in spring/summer, cold breath in winter")

---------------------------------------------------------------- DAY & NIGHT (only your screen)
-- Setting_TimeMode: "Live" | "Frozen" (+ Setting_FrozenTime) | "Dawn" | "Day" | "Dusk" | "Night"  (WeatherClient applies it)
if player:GetAttribute("Setting_TimeMode") == nil then player:SetAttribute("Setting_TimeMode", "Live") end
local Lighting = game:GetService("Lighting")
local function clockText(h)
	h = h % 24
	local hh, mm = math.floor(h), math.floor((h % 1) * 60)
	local ampm = hh >= 12 and "PM" or "AM"
	local h12 = hh % 12 == 0 and 12 or hh % 12
	return ("%d:%02d %s"):format(h12, mm, ampm)
end
section(13, "DAY & NIGHT")
-- cycle switch
local cyc = new("TextButton", { LayoutOrder = 14, Text = "", AutoButtonColor = true, BackgroundColor3 = CARD, Size = UDim2.new(1, -8, 0, 56) }, page)
corner(cyc, 10)
local cycIcon = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(44, 56), Position = UDim2.fromOffset(6, 0), Text = "🔄", TextScaled = true, Font = Enum.Font.GothamBold }, cyc)
new("UITextSizeConstraint", { MaxTextSize = 24 }, cycIcon)
new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -140, 0, 20), Position = UDim2.fromOffset(54, 8), Text = "Moving day & night cycle", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14 }, cyc)
local cycSub = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -140, 0, 16), Position = UDim2.fromOffset(54, 30), Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GREY, Font = Enum.Font.Gotham, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd }, cyc)
local cycPill = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(52, 26), BackgroundColor3 = CARD_ON }, cyc)
corner(cycPill, 13)
local cycKnob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, -23, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = WHITE }, cycPill)
corner(cycKnob, 10)
cyc.MouseButton1Click:Connect(function()
	local mode = player:GetAttribute("Setting_TimeMode") or "Live"
	if mode == "Live" then
		-- OFF: freeze exactly where the sky is now
		player:SetAttribute("Setting_FrozenTime", Lighting.ClockTime)
		player:SetAttribute("Setting_TimeMode", "Frozen")
	else
		player:SetAttribute("Setting_TimeMode", "Live")
	end
end)
-- fixed time presets
local timeGrid = new("Frame", { LayoutOrder = 15, Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, page)
new("UIGridLayout", { CellSize = UDim2.new(0.25, -6, 0, 82), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, timeGrid)
local TIME_PRESETS = {
	{ id = "Dawn", icon = "🌅", name = "Dawn", desc = "6:00 AM sunrise" },
	{ id = "Day", icon = "☀️", name = "Day", desc = "12:00 noon" },
	{ id = "Dusk", icon = "🌇", name = "Dusk", desc = "6:00 PM sunset" },
	{ id = "Night", icon = "🌙", name = "Night", desc = "10:00 PM moon" },
}
local timeCards = {}
for i, p in ipairs(TIME_PRESETS) do
	local b = new("TextButton", { Name = p.id, LayoutOrder = i, Text = "", AutoButtonColor = true, BackgroundColor3 = CARD }, timeGrid)
	corner(b, 10)
	local st = new("UIStroke", { Color = CARD_ON, Thickness = 2, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	local ic = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), Position = UDim2.fromOffset(0, 6), Text = p.icon, TextScaled = true, Font = Enum.Font.GothamBold }, b)
	new("UITextSizeConstraint", { MaxTextSize = 26 }, ic)
	new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 16), Position = UDim2.fromOffset(3, 40), Text = p.name, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13 }, b)
	new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 14), Position = UDim2.fromOffset(3, 58), Text = p.desc, TextColor3 = GREY, Font = Enum.Font.Gotham, TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd }, b)
	local check = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -22, 0, 2), Text = "✓", TextColor3 = Color3.fromRGB(120, 240, 170), Font = Enum.Font.GothamBlack, TextSize = 16, Visible = false }, b)
	timeCards[p.id] = { button = b, stroke = st, check = check }
	b.MouseButton1Click:Connect(function()
		if player:GetAttribute("Setting_TimeMode") == p.id then
			player:SetAttribute("Setting_TimeMode", "Live") -- tap again = back to the moving cycle
		else
			player:SetAttribute("Setting_TimeMode", p.id)
		end
	end)
end
local timeNote = new("TextLabel", { LayoutOrder = 16, Size = UDim2.new(1, -8, 0, 30), BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	Text = "", TextColor3 = GREY, Font = Enum.Font.Gotham, TextSize = 12 }, page)
local function renderTime()
	local mode = player:GetAttribute("Setting_TimeMode") or "Live"
	local live = mode == "Live"
	TweenService:Create(cycPill, TweenInfo.new(0.15), { BackgroundColor3 = live and CARD_ON or Color3.fromRGB(70, 70, 85) }):Play()
	TweenService:Create(cycKnob, TweenInfo.new(0.15), { Position = live and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }):Play()
	local school = Lighting:GetAttribute("SchoolClock") or Lighting.ClockTime
	if live then
		cycSub.Text = "ON • follows the school clock (" .. clockText(school) .. ")"
	elseif mode == "Frozen" then
		cycSub.Text = "OFF • frozen at " .. clockText(player:GetAttribute("Setting_FrozenTime") or school)
	else
		cycSub.Text = "OFF • fixed: " .. mode
	end
	for id, c in pairs(timeCards) do
		local on = id == mode
		c.button.BackgroundColor3 = on and Color3.fromRGB(28, 70, 58) or CARD
		c.stroke.Transparency = on and 0 or 1
		c.check.Visible = on
	end
	timeNote.Text = "Only YOU see this sky. Classes and NPCs keep the real school time (now " .. clockText(school) .. "). Tap a picked time again to go back to the moving cycle."
end
player:GetAttributeChangedSignal("Setting_TimeMode"):Connect(renderTime)
player:GetAttributeChangedSignal("Setting_FrozenTime"):Connect(renderTime)
task.spawn(function() while true do task.wait(1) if page.Visible then renderTime() end end end)
renderTime()

new("TextLabel", { LayoutOrder = 19, Size = UDim2.new(1, -8, 0, 44), BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	Text = "Only YOU see the weather you pick — everyone else keeps their own. Rain, snow and leaves don't fall indoors. Improve FPS shows fewer particles; Disable effects turns them off.", TextColor3 = GREY, Font = Enum.Font.Gotham, TextSize = 12 }, page)

---------------------------------------------------------------- state
local function fmt(s) s = math.max(0, s) return ("%d:%02d"):format(s // 60, s % 60) end
local function render()
	local pick = player:GetAttribute("Setting_Weather") or "Auto"
	for id, c in pairs(cards) do
		local on = id == pick
		c.button.BackgroundColor3 = on and Color3.fromRGB(28, 70, 58) or CARD
		c.stroke.Transparency = on and 0 or 1
		c.check.Visible = on
	end
	local liveId = folder:GetAttribute("Current") or "Sunny"
	local lw = C.ById[liveId] or C.ById.Sunny
	liveIcon.Text = lw.icon
	liveTitle.Text = "Live on campus: " .. lw.name
	local left = (folder:GetAttribute("Ends") or os.time()) - os.time()
	local seen = player:GetAttribute("Weather_Showing")
	local autoText = (seen and seen ~= liveId and C.ById[seen]) and ("your welcome weather " .. C.ById[seen].icon .. " " .. C.ById[seen].name .. " (until the next change)") or "live weather"
	liveSub.Text = ("Changes in about %s  •  You see: %s"):format(fmt(left), pick == "Auto" and autoText or ((C.ById[pick] and (C.ById[pick].icon .. " " .. C.ById[pick].name)) or pick))
	local showing = C.ById[pick] or lw
	entryIcon.Text = showing.icon
	entrySub.Text = pick == "Auto" and ("Auto • live: " .. lw.icon .. " " .. lw.name) or ("Your pick: " .. showing.icon .. " " .. showing.name .. "  (only you)")
end
player:GetAttributeChangedSignal("Setting_Weather"):Connect(render)
folder:GetAttributeChangedSignal("Current"):Connect(render)
task.spawn(function() while true do task.wait(1) render() end end)
render()

---------------------------------------------------------------- page switching
local function openWeather()
	page.Size = settingsPage.Size page.Position = settingsPage.Position
	settingsPage.Visible = false
	page.Visible = true
	page.CanvasPosition = Vector2.zero
end
local function closeWeather()
	page.Visible = false
	settingsPage.Visible = true
end
entry.MouseButton1Click:Connect(openWeather)
back.MouseButton1Click:Connect(closeWeather)
-- any other page shown by the HUD tabs (or Settings re-opened) hides this one
local function watch(p)
	if p == page or not p:IsA("GuiObject") then return end
	p:GetPropertyChangedSignal("Visible"):Connect(function() if p.Visible and page.Visible then page.Visible = false end end)
end
for _, p in ipairs(pages:GetChildren()) do watch(p) end
pages.ChildAdded:Connect(watch)
