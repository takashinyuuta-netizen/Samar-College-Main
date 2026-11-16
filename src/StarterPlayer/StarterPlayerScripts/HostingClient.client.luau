-- HostingClient: 📌 Host button on the left rail.
--   🏫 Host     — pick a room, type and title, then start (no time limit). While hosting: manage the meeting.
--   👥 Players  — everyone in the server with their title, role and level; the host can invite them.
--   📋 Sessions — meetings going on now; join open ones.
-- Invites pop up at the top; a meeting bar shows at the bottom while you're in one.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local HC = require(RS:WaitForChild("HostingConfig"))
local LevelConfig = require(RS:WaitForChild("LevelConfig"))
local RP = require(RS:WaitForChild("RoleplayConfig"))
local remotes = RS:WaitForChild("HostingRemotes")
local Request, Update = remotes:WaitForChild("Request"), remotes:WaitForChild("Update")

local C = {
	bg = Color3.fromRGB(24, 26, 34), card = Color3.fromRGB(42, 45, 60), input = Color3.fromRGB(22, 24, 32),
	stroke = Color3.fromRGB(70, 74, 96), text = Color3.fromRGB(240, 240, 245), dim = Color3.fromRGB(160, 164, 186),
	red = Color3.fromRGB(200, 60, 60), green = Color3.fromRGB(39, 120, 70), green2 = Color3.fromRGB(60, 170, 100),
	gold = Color3.fromRGB(240, 196, 70), blue = Color3.fromRGB(60, 120, 210), locked = Color3.fromRGB(52, 54, 66),
}
local function corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = o return c end
local function stroke(o, col, t) local s = Instance.new("UIStroke") s.Color = col or C.stroke s.Thickness = t or 1 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = o return s end
local function frame(parent, size, pos, col)
	local f = Instance.new("Frame") f.Size = size f.Position = pos or UDim2.new() f.BackgroundColor3 = col or C.card f.BorderSizePixel = 0 f.Parent = parent return f
end
local function label(parent, text, size, font, col, props)
	local l = Instance.new("TextLabel") l.BackgroundTransparency = 1 l.Text = text l.TextSize = size or 14
	l.Font = font or Enum.Font.GothamBold l.TextColor3 = col or C.text l.TextXAlignment = Enum.TextXAlignment.Left
	l.Size = UDim2.new(1, 0, 0, (size or 14) + 6) l.TextTruncate = Enum.TextTruncate.AtEnd
	for k, v in pairs(props or {}) do l[k] = v end
	l.Parent = parent return l
end
local function button(parent, text, col, size, props)
	local b = Instance.new("TextButton") b.AutoButtonColor = true b.BackgroundColor3 = col or C.card b.Text = text
	b.Font = Enum.Font.GothamBold b.TextSize = 13 b.TextColor3 = C.text b.Size = size
	for k, v in pairs(props or {}) do b[k] = v end b.Parent = parent corner(b, 8) return b
end
local function textbox(parent, placeholder, size, props)
	local t = Instance.new("TextBox") t.Size = size t.BackgroundColor3 = C.input t.Text = "" t.PlaceholderText = placeholder
	t.PlaceholderColor3 = C.dim t.TextColor3 = C.text t.Font = Enum.Font.GothamBold t.TextSize = 14 t.ClearTextOnFocus = false
	t.TextXAlignment = Enum.TextXAlignment.Left
	for k, v in pairs(props or {}) do t[k] = v end
	t.Parent = parent corner(t, 8) stroke(t, C.stroke, 1)
	local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 10) pad.PaddingRight = UDim.new(0, 10) pad.Parent = t
	return t
end
local function vlist(o, gap) local l = Instance.new("UIListLayout") l.Padding = UDim.new(0, gap or 8) l.SortOrder = Enum.SortOrder.LayoutOrder l.Parent = o return l end
local function hlist(o, gap) local l = vlist(o, gap) l.FillDirection = Enum.FillDirection.Horizontal l.VerticalAlignment = Enum.VerticalAlignment.Center return l end
local function scroller(parent, size)
	local s = Instance.new("ScrollingFrame") s.Size = size s.BackgroundColor3 = C.input s.BackgroundTransparency = 0.2 s.BorderSizePixel = 0
	s.ScrollBarThickness = 5 s.ScrollBarImageColor3 = C.stroke s.AutomaticCanvasSize = Enum.AutomaticSize.Y s.CanvasSize = UDim2.new() s.Parent = parent corner(s, 10)
	local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 6) pad.PaddingRight = UDim.new(0, 10) pad.PaddingTop = UDim.new(0, 6) pad.PaddingBottom = UDim.new(0, 6) pad.Parent = s
	vlist(s, 5)
	return s
end
local function clear(o) for _, c in ipairs(o:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end end
local function fmtTime(sec)
	sec = math.max(0, math.floor(sec))
	local h, m, s = math.floor(sec / 3600), math.floor(sec % 3600 / 60), sec % 60
	if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
	return string.format("%d:%02d", m, s)
end

local gui = Instance.new("ScreenGui")
gui.Name = "HostingGui" gui.ResetOnSpawn = false gui.DisplayOrder = 14 gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

---------------------------------------------------------------- toast
local toastL = label(gui, "", 15, Enum.Font.GothamBold, C.text, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -172),
	Size = UDim2.fromOffset(460, 36), BackgroundTransparency = 0.1, BackgroundColor3 = C.bg, TextXAlignment = Enum.TextXAlignment.Center, Visible = false, ZIndex = 60 })
corner(toastL, 10) local toastStroke = stroke(toastL, C.gold, 1.4)
local toastToken = 0
local function toast(text, good)
	toastToken += 1 local my = toastToken
	toastL.Text = text toastStroke.Color = good == false and C.red or C.gold toastL.Visible = true
	task.delay(3.5, function() if toastToken == my then toastL.Visible = false end end)
end

local function req(action, data)
	local ok, r = pcall(Request.InvokeServer, Request, action, data)
	if not ok or type(r) ~= "table" then toast("Couldn't reach the server, try again", false) return nil end
	if r.msg then toast(r.msg, r.ok) end
	return r
end

---------------------------------------------------------------- state
local state = { mine = nil, isHost = false, sessions = {} }

---------------------------------------------------------------- panel
local dim = frame(gui, UDim2.new(1, 800, 1, 800), UDim2.fromOffset(-400, -400), Color3.new(0, 0, 0))
dim.BackgroundTransparency = 0.5 dim.Visible = false dim.Active = true
local panel = frame(gui, UDim2.fromOffset(680, 580), UDim2.fromScale(0.5, 0.5), C.bg)
panel.Name = "Panel" panel.AnchorPoint = Vector2.new(0.5, 0.5) panel.Visible = false panel.Active = true corner(panel, 16) stroke(panel, C.gold, 1.5)
local pscale = Instance.new("UIScale") pscale.Parent = panel
local function rescale() local v = workspace.CurrentCamera.ViewportSize pscale.Scale = math.min(1, (v.X - 20) / 680, (v.Y - 70) / 580) end
rescale() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

local header = frame(panel, UDim2.new(1, 0, 0, 60), nil, C.green) corner(header, 16)
frame(header, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 1, -16), C.green)
label(header, "📌  HOST A MEETING", 20, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(18, 8), Size = UDim2.new(1, -80, 0, 24) })
label(header, "Classes, meetings, study groups — in any room, no time limit", 12, Enum.Font.Gotham, Color3.fromRGB(205, 235, 215), { Position = UDim2.fromOffset(18, 34), Size = UDim2.new(1, -80, 0, 16) })
local closeBtn = button(header, "X", Color3.fromRGB(25, 80, 50), UDim2.fromOffset(34, 34), { Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 13), TextSize = 16 })
corner(closeBtn, 17)
local minBtn = button(header, "–", Color3.fromRGB(25, 80, 50), UDim2.fromOffset(34, 34), { Name = "Minimize", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -54, 0, 13), TextSize = 22, Font = Enum.Font.GothamBlack })
corner(minBtn, 17)

-- drag a small chip around the screen; a tap (no drag) calls onTap
local function draggable(chip, onTap)
	local dragging, moved, startIn, startPos = false, false, nil, nil
	chip.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging, moved, startIn, startPos = true, false, i.Position, chip.Position
		i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
	end)
	UIS.InputChanged:Connect(function(i)
		if not dragging or (i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch) then return end
		local d = i.Position - startIn
		if d.Magnitude > 6 then moved = true end
		if not moved then return end
		chip.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		-- keep it on screen
		local vp, ap, as = gui.AbsoluteSize, chip.AbsolutePosition, chip.AbsoluteSize
		local fx = math.clamp(ap.X, 0, math.max(0, vp.X - as.X)) - ap.X
		local fy = math.clamp(ap.Y, 0, math.max(0, vp.Y - as.Y)) - ap.Y
		if fx ~= 0 or fy ~= 0 then chip.Position = chip.Position + UDim2.fromOffset(fx, fy) end
	end)
	chip.MouseButton1Click:Connect(function() if not moved then onTap() end moved = false end)
end

local tabsRow = frame(panel, UDim2.new(1, -36, 0, 34), UDim2.fromOffset(18, 70), C.bg) tabsRow.BackgroundTransparency = 1 hlist(tabsRow, 8)
local tabs, pages = {}, {}
local function page(name)
	local f = frame(panel, UDim2.new(1, -36, 1, -128), UDim2.fromOffset(18, 114), C.bg) f.Name = name f.BackgroundTransparency = 1 f.Visible = false
	pages[name] = f return f
end
for i, t in ipairs({ { "Host", "🏫  Host" }, { "Players", "👥  Players" }, { "Sessions", "📋  Sessions" } }) do
	tabs[t[1]] = button(tabsRow, t[2], C.card, UDim2.fromOffset(150, 34), { Name = t[1] .. "Tab", LayoutOrder = i, TextSize = 14 })
end

---------------------------------------------------------------- 🏫 host form
local pHost = page("HostForm") vlist(pHost, 7)
local selType, selPrivacy, selRoom, floorFilter, roomsCache = "Meeting", "Open", nil, "All", {}
local titleBox = textbox(pHost, "Title (optional) — e.g. BSIT Capstone Meeting, Math Review", UDim2.new(1, 0, 0, 36), { Name = "TitleBox", LayoutOrder = 1 })
titleBox:GetPropertyChangedSignal("Text"):Connect(function() if #titleBox.Text > HC.MaxTitle then titleBox.Text = titleBox.Text:sub(1, HC.MaxTitle) end end)
local typeGrid = frame(pHost, UDim2.new(1, 0, 0, 66), nil, C.bg) typeGrid.BackgroundTransparency = 1 typeGrid.LayoutOrder = 2
local tg = Instance.new("UIGridLayout") tg.CellSize = UDim2.new(0.2, -6, 0, 30) tg.CellPadding = UDim2.fromOffset(6, 6) tg.SortOrder = Enum.SortOrder.LayoutOrder tg.Parent = typeGrid
local typeBtns = {}
for i, t in ipairs(HC.Types) do
	local b = button(typeGrid, t.Icon .. " " .. t.Name, C.card, UDim2.new(), { LayoutOrder = i, TextScaled = true })
	local tc = Instance.new("UITextSizeConstraint") tc.MaxTextSize = 12 tc.Parent = b
	local pd = Instance.new("UIPadding") pd.PaddingLeft = UDim.new(0, 4) pd.PaddingRight = UDim.new(0, 4) pd.Parent = b
	typeBtns[t.Id] = { b = b, s = stroke(b, C.stroke, 1) }
end
local privRow = frame(pHost, UDim2.new(1, 0, 0, 30), nil, C.bg) privRow.BackgroundTransparency = 1 privRow.LayoutOrder = 3 hlist(privRow, 8)
label(privRow, "Who can join:", 13, Enum.Font.GothamBold, C.dim, { Size = UDim2.fromOffset(100, 30), LayoutOrder = 0 })
local privBtns = {
	Open = button(privRow, "🔓 Open — anyone can join", C.card, UDim2.fromOffset(200, 30), { LayoutOrder = 1 }),
	Invite = button(privRow, "🔒 Invite only", C.card, UDim2.fromOffset(150, 30), { LayoutOrder = 2 }),
}
local searchRow = frame(pHost, UDim2.new(1, 0, 0, 30), nil, C.bg) searchRow.BackgroundTransparency = 1 searchRow.LayoutOrder = 4 hlist(searchRow, 5)
local roomSearch = textbox(searchRow, "🔍 Search room", UDim2.fromOffset(190, 30), { LayoutOrder = 0, TextSize = 13 })
local floorBtns = {}
for i, f in ipairs({ "All", "1F", "2F", "3F", "4F", "5F", "Roof" }) do
	floorBtns[f] = button(searchRow, f, C.card, UDim2.fromOffset(f == "Roof" and 54 or 48, 30), { LayoutOrder = i })
end
local roomList = scroller(pHost, UDim2.new(1, 0, 0, 212)) roomList.Name = "RoomList" roomList.LayoutOrder = 5
local startBtn = button(pHost, "▶  START HOSTING", C.green2, UDim2.new(1, 0, 0, 42), { Name = "StartButton", LayoutOrder = 6, Font = Enum.Font.GothamBlack, TextSize = 16 })

local function paintForm()
	for id, t in pairs(typeBtns) do
		local on = id == selType
		t.b.BackgroundColor3 = on and C.green or C.card t.s.Color = on and C.gold or C.stroke t.s.Thickness = on and 2 or 1
	end
	for id, b in pairs(privBtns) do b.BackgroundColor3 = id == selPrivacy and C.blue or C.card end
	for id, b in pairs(floorBtns) do b.BackgroundColor3 = id == floorFilter and C.blue or C.card end
end
local function renderRooms()
	clear(roomList)
	local q = roomSearch.Text:lower()
	local shown = 0
	for i, r in ipairs(roomsCache) do
		if (floorFilter == "All" or r.floor == floorFilter) and (q == "" or r.label:lower():find(q, 1, true)) then
			shown += 1
			local free = r.state == "free"
			local on = r.key == selRoom
			local row = button(roomList, "", on and C.green or C.card, UDim2.new(1, 0, 0, 30), { Name = "Room_" .. r.key:gsub("[^%w]", "_"), LayoutOrder = i, AutoButtonColor = free })
			if on then stroke(row, C.gold, 2) end
			label(row, r.floor, 12, Enum.Font.GothamBlack, C.gold, { Position = UDim2.fromOffset(8, 5), Size = UDim2.fromOffset(38, 20) })
			label(row, r.label, 13, Enum.Font.GothamBold, free and C.text or C.dim, { Position = UDim2.fromOffset(48, 5), Size = UDim2.new(1, -200, 0, 20) })
			label(row, free and "✅ Free" or (r.state == "hosted" and ("📌 Hosted by " .. tostring(r.by)) or ("🎪 " .. tostring(r.by))), 12, Enum.Font.GothamBold,
				free and C.green2 or C.gold, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 5), Size = UDim2.fromOffset(150, 20), TextXAlignment = Enum.TextXAlignment.Right })
			row.MouseButton1Click:Connect(function()
				if not free then toast(r.label .. " isn't free right now", false) return end
				selRoom = r.key renderRooms()
			end)
		end
	end
	if shown == 0 then label(roomList, "No rooms match.", 13, Enum.Font.GothamBold, C.dim, { LayoutOrder = 0 }) end
	local sel
	for _, r in ipairs(roomsCache) do if r.key == selRoom then sel = r end end
	if sel and sel.state ~= "free" then selRoom = nil sel = nil end
	startBtn.Text = sel and ("▶  START HOSTING in " .. sel.label) or "▶  START HOSTING  (pick a room)"
end
local fetching = false
local function fetchRooms()
	if fetching then return end
	fetching = true
	local ok, r = pcall(Request.InvokeServer, Request, "rooms")
	fetching = false
	if ok and type(r) == "table" and r.rooms then roomsCache = r.rooms renderRooms() end
end
for id, t in pairs(typeBtns) do t.b.MouseButton1Click:Connect(function() selType = id paintForm() end) end
for id, b in pairs(privBtns) do b.MouseButton1Click:Connect(function() selPrivacy = id paintForm() end) end
for id, b in pairs(floorBtns) do b.MouseButton1Click:Connect(function() floorFilter = id paintForm() renderRooms() end) end
roomSearch:GetPropertyChangedSignal("Text"):Connect(renderRooms)
local showTab
startBtn.MouseButton1Click:Connect(function()
	if not selRoom then toast("Pick a free room from the list first", false) return end
	startBtn.Active = false
	local r = req("host", { room = selRoom, title = titleBox.Text, type = selType, privacy = selPrivacy })
	startBtn.Active = true
	if r and r.ok then titleBox.Text = "" selRoom = nil end
	fetchRooms()
end)

---------------------------------------------------------------- 📌 my meeting
local pMine = page("MyMeeting") vlist(pMine, 8)
local info = frame(pMine, UDim2.new(1, 0, 0, 104), nil, C.card) info.LayoutOrder = 1 corner(info, 12) stroke(info, C.gold, 1.4)
local mIcon = label(info, "📌", 40, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(60, 60), TextXAlignment = Enum.TextXAlignment.Center })
local mTitle = label(info, "", 18, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(80, 10), Size = UDim2.new(1, -200, 0, 22) })
local mRoom = label(info, "", 13, Enum.Font.GothamBold, C.gold, { Position = UDim2.fromOffset(80, 36), Size = UDim2.new(1, -200, 0, 18) })
local mHost = label(info, "", 13, Enum.Font.Gotham, C.dim, { Position = UDim2.fromOffset(80, 56), Size = UDim2.new(1, -200, 0, 18) })
local mPriv = label(info, "", 12, Enum.Font.GothamBold, C.text, { Position = UDim2.fromOffset(80, 77), Size = UDim2.new(1, -200, 0, 16) })
label(info, "TIME", 11, Enum.Font.GothamBold, C.dim, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(110, 14), TextXAlignment = Enum.TextXAlignment.Right })
local mTime = label(info, "0:00", 24, Enum.Font.GothamBlack, C.gold, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 30), Size = UDim2.fromOffset(110, 28), TextXAlignment = Enum.TextXAlignment.Right })
label(info, "no time limit", 11, Enum.Font.Gotham, C.dim, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 62), Size = UDim2.fromOffset(110, 14), TextXAlignment = Enum.TextXAlignment.Right })
local actRow = frame(pMine, UDim2.new(1, 0, 0, 36), nil, C.bg) actRow.BackgroundTransparency = 1 actRow.LayoutOrder = 2 hlist(actRow, 8)
local goBtn = button(actRow, "📍 Go to room", C.blue, UDim2.fromOffset(140, 36), { LayoutOrder = 1 })
local bringBtn = button(actRow, "🙋 Bring everyone", C.card, UDim2.fromOffset(150, 36), { LayoutOrder = 2 })
local privBtn = button(actRow, "🔒 Make invite only", C.card, UDim2.fromOffset(160, 36), { LayoutOrder = 3 })
local endBtn = button(actRow, "⛔ End meeting", C.red, UDim2.fromOffset(150, 36), { Name = "EndButton", LayoutOrder = 4 })
local peopleL = label(pMine, "", 14, Enum.Font.GothamBold, C.dim, { LayoutOrder = 3 })
local peopleList = scroller(pMine, UDim2.new(1, 0, 0, 196)) peopleList.LayoutOrder = 4
local tipL = label(pMine, "", 12, Enum.Font.Gotham, C.dim, { LayoutOrder = 5, TextWrapped = true, Size = UDim2.new(1, 0, 0, 30) })

local function renderMine()
	local m = state.mine
	if not m then return end
	local t = HC.type(m.type)
	mIcon.Text = t.Icon mTitle.Text = m.title
	mRoom.Text = "📍 " .. m.room .. "  •  " .. m.floor
	mHost.Text = t.Name .. "  •  hosted by " .. m.host
	mPriv.Text = m.privacy == "Open" and "🔓 Open — anyone can join from Sessions" or "🔒 Invite only"
	bringBtn.Visible = state.isHost privBtn.Visible = state.isHost
	privBtn.Text = m.privacy == "Open" and "🔒 Make invite only" or "🔓 Make open"
	endBtn.Text = state.isHost and "⛔ End meeting" or "🚪 Leave"
	peopleL.Text = ("👥  PEOPLE HERE (%d / %d)"):format(m.count, HC.MaxAttendees)
	tipL.Text = state.isHost and "Invite players from the 👥 Players tab. The room is reserved for you — campus events skip it until you end the meeting." or "You can leave any time. 📍 Go to room brings you back if you walk away."
	clear(peopleList)
	for i, a in ipairs(m.attendees) do
		local row = frame(peopleList, UDim2.new(1, 0, 0, 32), nil, C.card) row.LayoutOrder = i corner(row, 8)
		label(row, (a.host and "⭐ " or "• ") .. a.name .. "  @" .. a.user .. (a.host and "   (host)" or ""), 13, Enum.Font.GothamBold, a.host and C.gold or C.text, { Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -110, 0, 20) })
		if state.isHost and not a.host then
			local k = button(row, "Remove", C.red, UDim2.fromOffset(80, 24), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), TextSize = 12 })
			k.MouseButton1Click:Connect(function() req("kick", { userId = a.userId }) end)
		end
	end
end
goBtn.MouseButton1Click:Connect(function() req("goto") end)
bringBtn.MouseButton1Click:Connect(function() req("bring") end)
privBtn.MouseButton1Click:Connect(function() req("privacy") end)
endBtn.MouseButton1Click:Connect(function() req(state.isHost and "end" or "leave") end)

---------------------------------------------------------------- 👥 players
local pPlayers = page("Players") vlist(pPlayers, 7)
local pfRow = frame(pPlayers, UDim2.new(1, 0, 0, 30), nil, C.bg) pfRow.BackgroundTransparency = 1 pfRow.LayoutOrder = 1 hlist(pfRow, 5)
local playerSearch = textbox(pfRow, "🔍 Search player", UDim2.fromOffset(170, 30), { LayoutOrder = 0, TextSize = 13 })
local roleFilter = "All"
local roleBtns = {}
local ROLE_FILTERS = { { "All", "All" } }
for _, r in ipairs(RP.Roles) do table.insert(ROLE_FILTERS, { r.Id, r.Icon .. " " .. r.Name }) end
for i, f in ipairs(ROLE_FILTERS) do
	roleBtns[f[1]] = button(pfRow, f[2], C.card, UDim2.fromOffset(f[1] == "All" and 44 or 82, 30), { LayoutOrder = i, TextScaled = true })
	local tc = Instance.new("UITextSizeConstraint") tc.MaxTextSize = 12 tc.Parent = roleBtns[f[1]]
end
local playersInfo = label(pPlayers, "", 12, Enum.Font.Gotham, C.dim, { LayoutOrder = 2 })
local playerList = scroller(pPlayers, UDim2.new(1, 0, 1, -70)) playerList.LayoutOrder = 3

local thumbs = {}
local function thumb(img, uid)
	if thumbs[uid] then img.Image = thumbs[uid] return end
	task.spawn(function()
		local ok, url = pcall(Players.GetUserThumbnailAsync, Players, uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		if ok then thumbs[uid] = url if img.Parent then img.Image = url end end
	end)
end
local function invitedSet()
	local s = {}
	if state.mine and state.mine.invited then for _, uid in ipairs(state.mine.invited) do s[uid] = true end end
	return s
end
local function renderPlayers()
	for id, b in pairs(roleBtns) do b.BackgroundColor3 = id == roleFilter and C.blue or C.card end
	clear(playerList)
	local q = playerSearch.Text:lower()
	local inv = invitedSet()
	local here = {}
	if state.mine then for _, a in ipairs(state.mine.attendees) do here[a.userId] = true end end
	local list = Players:GetPlayers()
	table.sort(list, function(a, b) if (a == player) ~= (b == player) then return a == player end return a.DisplayName:lower() < b.DisplayName:lower() end)
	local shown = 0
	for i, p in ipairs(list) do
		local role = RP.role(p:GetAttribute("RP_Role"))
		if (roleFilter == "All" or role.Id == roleFilter) and (q == "" or p.DisplayName:lower():find(q, 1, true) or p.Name:lower():find(q, 1, true)) then
			shown += 1
			local row = frame(playerList, UDim2.new(1, 0, 0, 58), nil, C.card) row.LayoutOrder = i corner(row, 10)
			stroke(row, role.Color:Lerp(C.stroke, 0.4), 1.2)
			local img = Instance.new("ImageLabel") img.Size = UDim2.fromOffset(44, 44) img.Position = UDim2.fromOffset(7, 7) img.BackgroundColor3 = C.input img.Parent = row corner(img, 22)
			thumb(img, p.UserId)
			label(row, p.DisplayName .. "  @" .. p.Name .. (p == player and "  (you)" or ""), 14, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(58, 6), Size = UDim2.new(1, -300, 0, 18) })
			local ls = p:FindFirstChild("leaderstats")
			local title = ls and ls:FindFirstChild("Title") and ls.Title.Value or ""
			label(row, "🏷 " .. title, 12, Enum.Font.GothamBold, C.gold, { Position = UDim2.fromOffset(58, 25), Size = UDim2.new(1, -300, 0, 15) })
			local lvl = LevelConfig.name(p:GetAttribute("SelectedLevel") or p:GetAttribute("LevelUnlocked") or 1)
			local status = p:GetAttribute("MeetingHost") and ("📌 Hosting in " .. tostring(p:GetAttribute("MeetingRoom")))
				or (p:GetAttribute("MeetingRoom") and ("👥 In a meeting • " .. tostring(p:GetAttribute("MeetingRoom")))) or ("🎓 Level: " .. lvl)
			label(row, status, 11, Enum.Font.Gotham, C.dim, { Position = UDim2.fromOffset(58, 41), Size = UDim2.new(1, -300, 0, 13) })
			-- role badge + level (right side)
			local badge = label(row, role.Icon .. " " .. role.Name, 12, Enum.Font.GothamBlack, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -112, 0, 9),
				Size = UDim2.fromOffset(120, 20), BackgroundTransparency = 0, BackgroundColor3 = role.Color, TextXAlignment = Enum.TextXAlignment.Center })
			corner(badge, 10)
			label(row, lvl, 11, Enum.Font.GothamBold, C.dim, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -112, 0, 33), Size = UDim2.fromOffset(120, 15), TextXAlignment = Enum.TextXAlignment.Center })
			if state.isHost and p ~= player then
				local txt, col = "📩 Invite", C.green2
				if here[p.UserId] then txt, col = "✅ Here", C.locked elseif inv[p.UserId] then txt, col = "📩 Again", C.blue end
				local b = button(row, txt, col, UDim2.fromOffset(94, 34), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0), AutoButtonColor = not here[p.UserId] })
				if not here[p.UserId] then b.MouseButton1Click:Connect(function() req("invite", { userId = p.UserId }) end) end
			end
		end
	end
	playersInfo.Text = ("%d player(s) in this server"):format(#list) .. (state.isHost and "  •  tap 📩 Invite to call them to your meeting" or "  •  host a meeting to invite them")
	if shown == 0 then label(playerList, "No players match.", 13, Enum.Font.GothamBold, C.dim) end
end
for id, b in pairs(roleBtns) do b.MouseButton1Click:Connect(function() roleFilter = id renderPlayers() end) end
playerSearch:GetPropertyChangedSignal("Text"):Connect(renderPlayers)

---------------------------------------------------------------- 📋 sessions
local pSessions = page("Sessions") vlist(pSessions, 7)
label(pSessions, "Meetings happening now — join an open one or wait for an invite", 13, Enum.Font.GothamBold, C.dim, { LayoutOrder = 1 })
local sessionList = scroller(pSessions, UDim2.new(1, 0, 1, -30)) sessionList.LayoutOrder = 2
local invitedTo = {} -- [session id] = true
local function renderSessions()
	clear(sessionList)
	if #state.sessions == 0 then
		label(sessionList, "No one is hosting right now. Be the first — open the 🏫 Host tab!", 13, Enum.Font.GothamBold, C.dim, { TextWrapped = true, Size = UDim2.new(1, 0, 0, 40) })
		return
	end
	local now = workspace:GetServerTimeNow()
	for i, s in ipairs(state.sessions) do
		local t = HC.type(s.type)
		local row = frame(sessionList, UDim2.new(1, 0, 0, 62), nil, C.card) row.LayoutOrder = i corner(row, 10)
		label(row, t.Icon, 28, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(8, 12), Size = UDim2.fromOffset(40, 36), TextXAlignment = Enum.TextXAlignment.Center })
		label(row, s.title, 15, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(54, 7), Size = UDim2.new(1, -180, 0, 18) })
		label(row, ("📍 %s • %s   👤 %s"):format(s.room, s.floor, s.host), 12, Enum.Font.GothamBold, C.gold, { Position = UDim2.fromOffset(54, 26), Size = UDim2.new(1, -180, 0, 15) })
		label(row, ("%s • %d inside • %s • %s"):format(t.Name, s.count, fmtTime(now - s.startedAt), s.privacy == "Open" and "🔓 Open" or "🔒 Invite only"), 11, Enum.Font.Gotham, C.dim,
			{ Position = UDim2.fromOffset(54, 43), Size = UDim2.new(1, -180, 0, 14) })
		local mine = state.mine and state.mine.id == s.id
		local canJoin = s.privacy == "Open" or invitedTo[s.id]
		local b = button(row, mine and "✅ You're in" or (canJoin and "➡ Join" or "🔒 Invite only"), mine and C.locked or (canJoin and C.green2 or C.locked),
			UDim2.fromOffset(110, 36), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), AutoButtonColor = canJoin and not mine })
		if canJoin and not mine then b.MouseButton1Click:Connect(function() req("join", { id = s.id }) end) end
	end
end

---------------------------------------------------------------- tabs
local currentTab = "Host"
function showTab(name)
	currentTab = name
	for id, b in pairs(tabs) do b.BackgroundColor3 = id == name and C.green2 or C.card end
	tabs.Host.Text = state.mine and "📌  My Meeting" or "🏫  Host"
	for _, p in pairs(pages) do p.Visible = false end
	if name == "Host" then
		if state.mine then pMine.Visible = true renderMine() else pHost.Visible = true paintForm() fetchRooms() end
	elseif name == "Players" then pPlayers.Visible = true renderPlayers()
	else pSessions.Visible = true renderSessions() end
end
for id, b in pairs(tabs) do b.MouseButton1Click:Connect(function() showTab(id) end) end

-- minimized window → a small draggable chip (right side); tap it to reopen
local hostChip = button(gui, "", C.bg, UDim2.fromOffset(176, 40), { Name = "HostChip", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 40),
	Visible = false, Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = C.gold, AutoButtonColor = true })
corner(hostChip, 20) stroke(hostChip, C.gold, 1.6)
local function open(tab) hostChip.Visible = false dim.Visible = true panel.Visible = true showTab(tab or currentTab) end
local function dropFocus() local b = UIS:GetFocusedTextBox() if b and b:IsDescendantOf(gui) then b:ReleaseFocus() end end
local function close() dropFocus() hostChip.Visible = false panel.Visible = false dim.Visible = false end
local function minimize()
	dropFocus()
	panel.Visible = false dim.Visible = false
	hostChip.Text = (state.mine and "📌 My Meeting" or "📌 Host") .. "  •  open"
	hostChip.Visible = true
end
minBtn.MouseButton1Click:Connect(minimize)
draggable(hostChip, function() open() end)
closeBtn.MouseButton1Click:Connect(close)
dim.InputBegan:Connect(function(i)
	if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
	-- only close when the tap is outside the window
	local pos, a, s = Vector2.new(i.Position.X, i.Position.Y), panel.AbsolutePosition, panel.AbsoluteSize
	if pos.X >= a.X and pos.X <= a.X + s.X and pos.Y >= a.Y and pos.Y <= a.Y + s.Y then return end
	close()
end)

---------------------------------------------------------------- invite popup
local popup = frame(gui, UDim2.fromOffset(440, 118), UDim2.new(0.5, 0, 0, 96), C.bg)
popup.Name = "InvitePopup" popup.AnchorPoint = Vector2.new(0.5, 0) popup.Visible = false popup.ZIndex = 40 corner(popup, 14) stroke(popup, C.gold, 2)
local popScale = Instance.new("UIScale") popScale.Parent = popup
local function rescalePop() local v = workspace.CurrentCamera.ViewportSize popScale.Scale = math.min(1, (v.X - 20) / 440) end
rescalePop() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescalePop)
local popTitle = label(popup, "", 15, Enum.Font.GothamBlack, C.gold, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -60, 0, 20), ZIndex = 41 })
local popMin = button(popup, "–", C.card, UDim2.fromOffset(28, 26), { Name = "Minimize", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), TextSize = 20, Font = Enum.Font.GothamBlack, ZIndex = 42 })
local popText = label(popup, "", 13, Enum.Font.GothamBold, C.text, { Position = UDim2.fromOffset(16, 32), Size = UDim2.new(1, -32, 0, 36), ZIndex = 41, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top })
local acceptBtn = button(popup, "✅ Accept & go", C.green2, UDim2.fromOffset(196, 34), { Name = "Accept", Position = UDim2.fromOffset(16, 74), ZIndex = 41 })
local declineBtn = button(popup, "Not now", C.card, UDim2.fromOffset(196, 34), { Name = "Decline", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 74), ZIndex = 41 })
local queue, showing = {}, nil
-- minimized invites → "📩 2 invites" chip (tap to see them again)
local inviteChip = button(gui, "", C.bg, UDim2.fromOffset(176, 36), { Name = "InviteChip", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96),
	Visible = false, Font = Enum.Font.GothamBlack, TextSize = 13, TextColor3 = C.gold, ZIndex = 40 })
corner(inviteChip, 18) stroke(inviteChip, C.gold, 1.6)
local invMin = false
local function paintInvites()
	local n = (showing and 1 or 0) + #queue
	if n == 0 then invMin = false end
	inviteChip.Text = ("📩 %d %s  •  open"):format(n, n == 1 and "invite" or "invites")
	inviteChip.Visible = invMin and n > 0
	popup.Visible = (not invMin) and showing ~= nil
end
popMin.MouseButton1Click:Connect(function() invMin = true paintInvites() end)
draggable(inviteChip, function() invMin = false paintInvites() end)
local function nextInvite()
	showing = table.remove(queue, 1)
	if not showing then paintInvites() return end
	local inv = showing
	popTitle.Text = "📩 " .. inv.from .. " invited you!"
	popText.Text = ("%s %s: %s\n📍 %s • %s"):format(inv.icon, inv.typeName, inv.title, inv.room, inv.floor)
	paintInvites()
	task.delay(40, function() if showing == inv then nextInvite() end end)
end
acceptBtn.MouseButton1Click:Connect(function() local inv = showing if inv then nextInvite() req("accept", { id = inv.id }) end end)
declineBtn.MouseButton1Click:Connect(function() local inv = showing if inv then nextInvite() pcall(Request.InvokeServer, Request, "decline", { id = inv.id }) end end)

---------------------------------------------------------------- meeting bar (bottom)
local bar = button(gui, "", C.bg, UDim2.fromOffset(380, 38), { Name = "MeetingBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -118), Visible = false, BackgroundTransparency = 0.1 })
corner(bar, 19) stroke(bar, C.gold, 1.6)
local barText = label(bar, "", 13, Enum.Font.GothamBold, C.text, { Position = UDim2.fromOffset(14, 9), Size = UDim2.new(1, -110, 0, 20) })
local barTime = label(bar, "", 13, Enum.Font.GothamBlack, C.gold, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -40, 0, 9), Size = UDim2.fromOffset(90, 20), TextXAlignment = Enum.TextXAlignment.Right })
bar.MouseButton1Click:Connect(function() if panel.Visible then close() else open("Host") end end)
-- ➖ collapse the meeting bar into a small draggable timer pill
local barCollapsed = false
local barMinBtn = button(bar, "–", C.card, UDim2.fromOffset(28, 28), { Name = "Minimize", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), TextSize = 20, Font = Enum.Font.GothamBlack })
corner(barMinBtn, 14)
local barMini = button(gui, "📌", C.bg, UDim2.fromOffset(108, 38), { Name = "MeetingMini", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -118),
	Visible = false, Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = C.gold, BackgroundTransparency = 0.1 })
corner(barMini, 19) stroke(barMini, C.gold, 1.6)
local renderBar
barMinBtn.MouseButton1Click:Connect(function() barCollapsed = true renderBar() end)
draggable(barMini, function() barCollapsed = false renderBar() end)
panel:GetPropertyChangedSignal("Visible"):Connect(function() renderBar() end)

function renderBar()
	local m = state.mine
	if not m then barCollapsed = false end
	local hidden = panel.Visible -- the window already shows the meeting
	bar.Visible = m ~= nil and not barCollapsed and not hidden
	barMini.Visible = m ~= nil and barCollapsed and not hidden
	if m then barText.Text = (state.isHost and "📌 Hosting: " or "👥 ") .. m.title .. "  •  " .. m.room end
end

---------------------------------------------------------------- server updates
Update.OnClientEvent:Connect(function(msg)
	if type(msg) ~= "table" then return end
	if msg.kind == "state" then
		local wasIn = state.mine ~= nil
		state.mine, state.isHost, state.sessions = msg.mine, msg.isHost, msg.sessions or {}
		local alive = {} for _, s in ipairs(state.sessions) do alive[s.id] = true end
		for id in pairs(invitedTo) do if not alive[id] then invitedTo[id] = nil end end
		renderBar()
		if panel.Visible then
			if currentTab == "Host" and wasIn ~= (state.mine ~= nil) then showTab("Host")
			elseif currentTab == "Host" and state.mine then renderMine()
			elseif currentTab == "Players" then renderPlayers()
			elseif currentTab == "Sessions" then renderSessions() end
			tabs.Host.Text = state.mine and "📌  My Meeting" or "🏫  Host"
		end
	elseif msg.kind == "invite" then
		invitedTo[msg.id] = true
		for i = #queue, 1, -1 do if queue[i].id == msg.id then table.remove(queue, i) end end
		if not (showing and showing.id == msg.id) then table.insert(queue, msg) end
		if not showing then nextInvite() end
		paintInvites()
	elseif msg.kind == "toast" then
		toast(msg.text)
	end
end)

-- live timers + refreshes
task.spawn(function()
	local tick = 0
	while true do
		task.wait(1) tick += 1
		local m = state.mine
		if m then
			local t = fmtTime(workspace:GetServerTimeNow() - m.startedAt)
			barTime.Text = "⏱ " .. t mTime.Text = t barMini.Text = "📌 " .. t
		end
		if panel.Visible then
			if currentTab == "Host" and not state.mine and tick % 5 == 0 then fetchRooms() end
			if currentTab == "Players" and tick % 3 == 0 then renderPlayers() end
			if currentTab == "Sessions" and tick % 5 == 0 then renderSessions() end
		end
	end
end)
Players.PlayerAdded:Connect(function() if panel.Visible and currentTab == "Players" then renderPlayers() end end)
Players.PlayerRemoving:Connect(function() task.defer(function() if panel.Visible and currentTab == "Players" then renderPlayers() end end) end)

---------------------------------------------------------------- 📌 Host button on the left rail
local function addRailButton(hud)
	local rail = hud and hud:FindFirstChild("Rail")
	local tmpl = rail and rail:FindFirstChild("MapButton")
	if not tmpl or rail:FindFirstChild("HostButton") then return end
	local b = tmpl:Clone()
	b.Name = "HostButton" b.LayoutOrder = 4
	for _, d in ipairs(b:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() end end
	if b:FindFirstChild("Icon") then b.Icon.Text = "📌" end
	if b:FindFirstChild("Caption") then b.Caption.Text = "Host" end
	b.Parent = rail
	b.MouseButton1Click:Connect(function() if panel.Visible then close() else open() end end)
end
local pg = player:WaitForChild("PlayerGui")
pg.ChildAdded:Connect(function(c) if c.Name == "MainHUD" then c:WaitForChild("Rail", 10) task.wait(0.3) addRailButton(c) end end)
task.spawn(function()
	local hud = pg:WaitForChild("MainHUD", 30)
	if hud then hud:WaitForChild("Rail", 10) task.wait(0.3) addRailButton(hud) end
end)

pcall(Request.InvokeServer, Request, "state")
