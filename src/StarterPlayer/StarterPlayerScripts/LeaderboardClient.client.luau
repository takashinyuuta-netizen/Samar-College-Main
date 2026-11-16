--[[ LeaderboardClient — draws the live top-50 boards on the leaderboard stands.
  The SurfaceGuis live in PlayerGui (Adornee = stand Screen) so tabs, scrolling (mouse wheel / touch drag)
  and the ▲ ▼ buttons work. Data: ReplicatedStorage.Leaderboards.<Key> (JSON from LeaderboardServer). ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local pgui = player:WaitForChild("PlayerGui")
local Cfg = require(RS:WaitForChild("LeaderboardConfig"))
local data = RS:WaitForChild("Leaderboards")
local standsFolder = workspace:WaitForChild("LeaderboardStands")

local PPS = 32 -- pixels per stud → 16x20 screen = 512x640 (bigger text, ~7 rows visible, scroll for the rest)
local ROW_H = 54
local WHITE, MUTED = Color3.new(1, 1, 1), Color3.fromRGB(165, 170, 190)
local MEDAL = { Color3.fromRGB(255, 200, 40), Color3.fromRGB(200, 205, 215), Color3.fromRGB(215, 140, 80) }

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(0, r or 10) }, o) end

local function decode(key)
	local sv = data:FindFirstChild(key)
	if not sv then return { rows = {} } end
	local ok, d = pcall(function() return Http:JSONDecode(sv.Value) end)
	return ok and type(d) == "table" and d or { rows = {} }
end

local function build(board, screen)
	local accent = board.Color
	local sg = new("SurfaceGui", { Name = "LB_" .. board.Id, Adornee = screen, Face = Enum.NormalId.Front, ResetOnSpawn = false,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = PPS, LightInfluence = 0, MaxDistance = 110,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ClipsDescendants = true }, pgui)
	local loading = screen:FindFirstChild("Loading") if loading then loading.Enabled = false end
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(16, 18, 28), BorderSizePixel = 0 }, sg)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(30, 34, 52), Color3.fromRGB(12, 13, 20)) }, bg)

	-- tabs
	local tabBar = new("ScrollingFrame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 0, 62), BackgroundTransparency = 1,
		ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(),
		ScrollBarThickness = 6, ScrollBarImageColor3 = accent, BorderSizePixel = 0 }, bg)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, tabBar)

	-- column header
	local head = new("Frame", { Position = UDim2.fromOffset(10, 80), Size = UDim2.new(1, -20, 0, 34), BackgroundColor3 = accent, BackgroundTransparency = 0.75 }, bg)
	corner(head, 8)
	local tabTitle = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0.6, 0, 1, 0), Font = Enum.Font.GothamBlack,
		TextSize = 22, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, head)
	new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.6, 0, 0, 0), Size = UDim2.new(0.4, -14, 1, 0), Font = Enum.Font.GothamBold,
		TextSize = 18, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Right, Text = "TOP " .. Cfg.TopN }, head)

	-- list
	local list = new("ScrollingFrame", { Position = UDim2.fromOffset(10, 122), Size = UDim2.new(1, -20, 1, -122 - 70), BackgroundTransparency = 1,
		ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
		ScrollBarThickness = 14, ScrollBarImageColor3 = accent, BorderSizePixel = 0, ElasticBehavior = Enum.ElasticBehavior.Always, Active = true }, bg)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	new("UIPadding", { PaddingRight = UDim.new(0, 18) }, list)
	local empty = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 120), Font = Enum.Font.GothamBold, TextSize = 24, TextWrapped = true,
		TextColor3 = MUTED, Text = "No records yet — be the first! 🏁", LayoutOrder = 999, Visible = false }, list)

	local rows = {}
	for i = 1, Cfg.TopN do
		local r = new("Frame", { Name = "Row" .. i, LayoutOrder = i, Size = UDim2.new(1, 0, 0, ROW_H), BackgroundColor3 = Color3.fromRGB(34, 38, 56), Visible = false }, list)
		corner(r, 10)
		local stroke = new("UIStroke", { Color = accent, Thickness = 3, Enabled = false }, r)
		local rank = new("TextLabel", { BackgroundColor3 = i <= 3 and MEDAL[i] or Color3.fromRGB(55, 60, 82), Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(52, 40),
			Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = i <= 3 and Color3.fromRGB(30, 25, 10) or WHITE, Text = "#" .. i }, r)
		corner(rank, 8)
		local pic = new("ImageLabel", { BackgroundColor3 = Color3.fromRGB(60, 64, 86), Position = UDim2.fromOffset(68, 5), Size = UDim2.fromOffset(44, 44), Image = "" }, r)
		corner(pic, 22)
		local name = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(122, 0), Size = UDim2.new(0.58, -122, 1, 0), Font = Enum.Font.GothamBold,
			TextSize = 22, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "" }, r)
		local val = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.58, 0, 0, 0), Size = UDim2.new(0.42, -14, 1, 0), Font = Enum.Font.GothamBlack,
			TextSize = 22, TextColor3 = accent, TextXAlignment = Enum.TextXAlignment.Right, Text = "" }, r)
		rows[i] = { frame = r, stroke = stroke, pic = pic, name = name, val = val, id = nil }
	end

	-- footer: your rank + scroll buttons
	local foot = new("Frame", { Position = UDim2.new(0, 10, 1, -62), Size = UDim2.new(1, -20, 0, 52), BackgroundColor3 = Color3.fromRGB(34, 38, 56) }, bg)
	corner(foot, 10)
	local me = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -150, 1, 0), Font = Enum.Font.GothamBold,
		TextSize = 19, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "" }, foot)
	local function scrollBtn(txt, x, dir)
		local b = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(58, 40), BackgroundColor3 = accent,
			Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = Color3.fromRGB(20, 20, 30), Text = txt, AutoButtonColor = true }, foot)
		corner(b, 8)
		b.Activated:Connect(function()
			local maxY = math.max(0, list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y)
			local target = math.clamp(list.CanvasPosition.Y + dir * (ROW_H + 6) * 5, 0, maxY)
			TweenService:Create(list, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { CanvasPosition = Vector2.new(0, target) }):Play()
		end)
	end
	scrollBtn("▼", -8, 1)
	scrollBtn("▲", -72, -1)

	-- tab logic
	local current
	local tabButtons = {}
	local function render()
		local t = current
		tabTitle.Text = t.Label
		local d = decode(t.Key)
		local list_ = d.rows or {}
		local myRank, myVal
		for i = 1, Cfg.TopN do
			local row, e = rows[i], list_[i]
			row.frame.Visible = e ~= nil
			if e then
				if row.id ~= e.id then
					row.id = e.id
					row.pic.Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48"):format(e.id)
				end
				row.name.Text = tostring(e.n)
				row.val.Text = Cfg.format(t.Fmt, e.v)
				local mine = e.id == player.UserId
				row.stroke.Enabled = mine
				row.frame.BackgroundColor3 = mine and Color3.fromRGB(48, 56, 86) or Color3.fromRGB(34, 38, 56)
				if mine then myRank, myVal = i, e.v end
			end
		end
		empty.Visible = #list_ == 0
		if myRank then
			me.Text = ("⭐ You: #%d  •  %s"):format(myRank, Cfg.format(t.Fmt, myVal))
		else
			me.Text = "You're not in the top " .. Cfg.TopN .. " yet — keep going!"
		end
		for key, b in pairs(tabButtons) do
			local on = key == t.Key
			b.BackgroundColor3 = on and accent or Color3.fromRGB(44, 48, 68)
			b.TextColor3 = on and Color3.fromRGB(20, 20, 30) or WHITE
		end
	end
	for i, t in ipairs(board.Tabs) do
		local b = new("TextButton", { LayoutOrder = i, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 50), BackgroundColor3 = Color3.fromRGB(44, 48, 68),
			Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = WHITE, Text = t.Label, AutoButtonColor = true }, tabBar)
		corner(b, 10)
		new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, b)
		tabButtons[t.Key] = b
		b.Activated:Connect(function()
			if current == t then return end
			current = t
			list.CanvasPosition = Vector2.new()
			render()
		end)
		local sv = data:WaitForChild(t.Key, 30)
		if sv then sv.Changed:Connect(function() if current == t then render() end end) end
	end
	current = board.Tabs[1]
	render()
	return sg
end

local built = {}
local function tryStand(m)
	local id = m:GetAttribute("BoardId")
	if not id or built[m] then return end
	local board
	for _, b in ipairs(Cfg.Boards) do if b.Id == id then board = b end end
	if not board then return end
	local screen = m:WaitForChild("Screen", 30)
	if not screen then return end
	built[m] = build(board, screen)
	m.AncestryChanged:Connect(function()
		if not m:IsDescendantOf(workspace) and built[m] then built[m]:Destroy() built[m] = nil end
	end)
end
for _, m in ipairs(standsFolder:GetChildren()) do task.spawn(tryStand, m) end
standsFolder.ChildAdded:Connect(function(m) task.spawn(tryStand, m) end)
