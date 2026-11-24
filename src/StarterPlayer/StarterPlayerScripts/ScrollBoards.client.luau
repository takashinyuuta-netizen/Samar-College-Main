--[[ ScrollBoards — two-column TOP 50 boards you can scroll (Summit Tower board, PATAAS island board).
  Any part tagged "ScrollBoard" gets one. Attributes on the part:
    SB_Title, SB_Face ("Front"/"Right"/...), SB_Color (Color3)
    SB_LeftKey / SB_LeftLabel / SB_LeftFmt     and     SB_RightKey / SB_RightLabel / SB_RightFmt
  Keys are ReplicatedStorage.Leaderboards.<Key> (JSON from LeaderboardServer: top 50, reloaded every 5 min).
  The SurfaceGui lives in PlayerGui (Adornee = the part) so mouse wheel, touch drag and the ▲ ▼ buttons work. ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local pgui = player:WaitForChild("PlayerGui")
local Cfg = require(RS:WaitForChild("LeaderboardConfig"))
local data = RS:WaitForChild("Leaderboards")

local WIDTH_PX = 1000 -- every board is drawn ~1000 px wide, whatever its size
local ROW_H = 46
local WHITE, MUTED = Color3.new(1, 1, 1), Color3.fromRGB(165, 172, 190)
local ROW, ROW_ALT, ROW_ME = Color3.fromRGB(32, 36, 52), Color3.fromRGB(27, 30, 44), Color3.fromRGB(40, 70, 52)
local MEDAL = { Color3.fromRGB(255, 200, 40), Color3.fromRGB(205, 210, 220), Color3.fromRGB(215, 140, 80) }

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
local function faceSize(part, face)
	local s = part.Size
	if face == Enum.NormalId.Front or face == Enum.NormalId.Back then return s.X, s.Y end
	if face == Enum.NormalId.Left or face == Enum.NormalId.Right then return s.Z, s.Y end
	return s.X, s.Z
end

local built = {} -- part -> { sg, conns }

local function build(part)
	if built[part] then return end
	local face = Enum.NormalId[part:GetAttribute("SB_Face") or "Front"] or Enum.NormalId.Front
	local w = faceSize(part, face)
	local accent = part:GetAttribute("SB_Color") or Color3.fromRGB(255, 205, 80)
	local sg = new("SurfaceGui", { Name = "SB_" .. part.Name, Adornee = part, Face = face, ResetOnSpawn = false,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = WIDTH_PX / math.max(w, 1), LightInfluence = 0, MaxDistance = 120,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ClipsDescendants = true }, pgui)
	local conns = {}
	built[part] = { sg = sg, conns = conns }
	-- hide the server's old text, if any
	for _, g in ipairs(part:GetChildren()) do if g:IsA("SurfaceGui") then g.Enabled = false end end

	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(14, 16, 24), BorderSizePixel = 0 }, sg)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(28, 32, 48), Color3.fromRGB(10, 11, 18)) }, bg)
	-- title
	local title = new("Frame", { Size = UDim2.new(1, 0, 0, 86), BackgroundColor3 = accent, BorderSizePixel = 0 }, bg)
	new("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200)) }, title)
	new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(20, 0), Font = Enum.Font.GothamBlack,
		TextScaled = true, TextColor3 = Color3.fromRGB(20, 20, 28), Text = part:GetAttribute("SB_Title") or "🏆 LEADERBOARD" }, title)

	-- footer: countdown to the next update
	local foot = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -6), Size = UDim2.new(1, -32, 0, 34),
		Font = Enum.Font.GothamMedium, TextSize = 22, TextColor3 = MUTED, Text = "" }, bg)

	local cols = {}
	for c, side in ipairs({ "Left", "Right" }) do
		local key = part:GetAttribute("SB_" .. side .. "Key")
		local x = (c - 1) * 0.5
		local col = new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(x, c == 1 and 14 or 7, 0, 98), Size = UDim2.new(0.5, -21, 1, -98 - 48) }, bg)
		-- header with ▲ ▼
		local head = new("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = accent, BackgroundTransparency = 0.78 }, col)
		corner(head, 10)
		new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -150, 1, 0), Font = Enum.Font.GothamBlack,
			TextSize = 26, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			Text = part:GetAttribute("SB_" .. side .. "Label") or "" }, head)
		local list = new("ScrollingFrame", { Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 1, -58), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
			ScrollBarThickness = 12, ScrollBarImageColor3 = accent, ElasticBehavior = Enum.ElasticBehavior.Always, Active = true }, col)
		new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, list)
		new("UIPadding", { PaddingRight = UDim.new(0, 16) }, list)
		local function btn(txt, xOff, dir)
			local b = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0), Size = UDim2.fromOffset(56, 40), BackgroundColor3 = accent,
				Font = Enum.Font.GothamBlack, TextSize = 24, TextColor3 = Color3.fromRGB(20, 20, 28), Text = txt, AutoButtonColor = true }, head)
			corner(b, 8)
			b.Activated:Connect(function()
				local maxY = math.max(0, list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y)
				local target = math.clamp(list.CanvasPosition.Y + dir * (ROW_H + 5) * 5, 0, maxY)
				TweenService:Create(list, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { CanvasPosition = Vector2.new(0, target) }):Play()
			end)
		end
		btn("▼", -6, 1)
		btn("▲", -68, -1)
		local empty = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 90), Font = Enum.Font.GothamBold, TextSize = 24, TextWrapped = true,
			TextColor3 = MUTED, Text = "No records yet — be the first! 🏁", LayoutOrder = 999, Visible = false }, list)
		local rows = {}
		for i = 1, Cfg.TopN do
			local r = new("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, ROW_H), BackgroundColor3 = i % 2 == 0 and ROW_ALT or ROW, Visible = false }, list)
			corner(r, 8)
			local stroke = new("UIStroke", { Color = Color3.fromRGB(110, 230, 140), Thickness = 3, Enabled = false }, r)
			local rank = new("TextLabel", { BackgroundColor3 = i <= 3 and MEDAL[i] or Color3.fromRGB(52, 58, 80), Position = UDim2.fromOffset(6, 5), Size = UDim2.fromOffset(56, 36),
				Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = i <= 3 and Color3.fromRGB(30, 25, 10) or WHITE, Text = "#" .. i }, r) -- top 3 = gold / silver / bronze badge
			corner(rank, 7)
			local name = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(72, 0), Size = UDim2.new(0.62, -72, 1, 0), Font = Enum.Font.GothamBold,
				TextSize = 23, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "" }, r)
			local val = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.62, 0, 0, 0), Size = UDim2.new(0.38, -10, 1, 0), Font = Enum.Font.GothamBlack,
				TextSize = 23, TextColor3 = accent, TextXAlignment = Enum.TextXAlignment.Right, Text = "" }, r)
			rows[i] = { frame = r, stroke = stroke, name = name, val = val, alt = i % 2 == 0 }
		end
		cols[c] = { key = key, fmt = part:GetAttribute("SB_" .. side .. "Fmt") or "number", rows = rows, empty = empty }
	end

	local lastReload, every = nil, Cfg.RefreshEvery
	local function render()
		for _, col in ipairs(cols) do
			local d = decode(col.key or "")
			local list = d.rows or {}
			if d.r then lastReload = math.max(lastReload or 0, d.r) end
			if d.every then every = d.every end
			for i = 1, Cfg.TopN do
				local row, e = col.rows[i], list[i]
				row.frame.Visible = e ~= nil
				if e then
					local mine = e.id == player.UserId
					row.name.Text = (mine and "⭐ " or "") .. tostring(e.n)
					row.val.Text = Cfg.format(col.fmt, e.v)
					row.stroke.Enabled = mine
					row.frame.BackgroundColor3 = mine and ROW_ME or (row.alt and ROW_ALT or ROW)
				end
			end
			col.empty.Visible = #list == 0
		end
	end
	render()
	for _, col in ipairs(cols) do
		local sv = col.key and data:FindFirstChild(col.key)
		if sv then table.insert(conns, sv.Changed:Connect(render)) end
	end
	-- countdown
	task.spawn(function()
		while built[part] and built[part].sg == sg do
			if lastReload then
				local left = math.max(0, lastReload + every - os.time())
				foot.Text = ("🌍 Top %d • all servers  •  🔄 next update in %d:%02d  •  scroll or use ▲ ▼"):format(Cfg.TopN, left // 60, left % 60)
			else
				foot.Text = ("🌍 Top %d • all servers  •  loading…"):format(Cfg.TopN)
			end
			task.wait(1)
		end
	end)
end

local function unbuild(part)
	local b = built[part]
	if not b then return end
	built[part] = nil
	for _, c in ipairs(b.conns) do c:Disconnect() end
	b.sg:Destroy()
end

for _, p in ipairs(CS:GetTagged("ScrollBoard")) do task.spawn(build, p) end
CS:GetInstanceAddedSignal("ScrollBoard"):Connect(function(p) task.defer(build, p) end)
CS:GetInstanceRemovedSignal("ScrollBoard"):Connect(unbuild)
-- PlayerGui is reset on respawn only for ResetOnSpawn guis (ours are not), but rebuild if one got lost
task.spawn(function()
	while true do
		task.wait(5)
		for p, b in pairs(built) do
			if not p:IsDescendantOf(workspace) then unbuild(p)
			elseif not b.sg.Parent then built[p] = nil task.spawn(build, p) end
		end
	end
end)
