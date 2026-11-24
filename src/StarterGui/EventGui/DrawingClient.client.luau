--[[ DrawingClient — Guess the Drawing on screen + on the public board.
  • Drawer: draw on the canvas (mouse / touch). Points are sent in small batches
    (normalized 0..1) — the server validates them and sends them to everyone.
  • Guessers: see the hint (_ _ _), type guesses; wrong guesses come back FILTERED in the feed.
  • Everyone (even spectators) sees strokes on the world board "Canvas" in the event folder.
  • Players who did NOT join get a small "📺 Watch" button: it opens the same panel in watch mode
    (drawing, hint, timer and the guesses feed — no guessing). The board in the classroom is
    re-synced when it streams in, so you never see a half-empty drawing.
  • SAFETY: 🚫 Hide = vote to hide a bad drawing (server clears it after enough votes).
    🙈 = stop showing other players' drawings to ME (panel + classroom board) until turned back on. ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Remotes = RS:WaitForChild("Events"):WaitForChild("EventRemotes")
local gui = script.Parent

local COLORS = { Color3.fromRGB(25, 25, 25), Color3.fromRGB(220, 60, 60), Color3.fromRGB(60, 110, 220), Color3.fromRGB(60, 170, 90),
	Color3.fromRGB(250, 205, 50), Color3.fromRGB(240, 140, 50), Color3.fromRGB(150, 90, 200), Color3.fromRGB(255, 255, 255) }
local DARK, PINK = Color3.fromRGB(25, 30, 38), Color3.fromRGB(230, 110, 180)
local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 8) c.Parent = p end
local function label(parent, name, size, pos, font, color, maxSize, xa)
	local t = Instance.new("TextLabel") t.Name = name t.Size = size t.Position = pos t.BackgroundTransparency = 1 t.Font = font or Enum.Font.Gotham
	t.TextColor3 = color or Color3.new(1,1,1) t.TextScaled = true t.TextWrapped = true t.TextXAlignment = xa or Enum.TextXAlignment.Center t.Parent = parent
	local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = maxSize or 18 c.Parent = t
	return t
end

---------------------------------------------------------------- panel
local panel = Instance.new("Frame") panel.Name = "DrawingPanel" panel.Size = UDim2.new(0, 560, 0, 330) panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -20) panel.BackgroundColor3 = DARK panel.BackgroundTransparency = 0.05 panel.Visible = false panel.Parent = gui corner(panel, 14)
local scale = Instance.new("UIScale") scale.Parent = panel
local function fit()
	-- the whole screen is already scaled by UIResponsive; fit inside that virtual screen
	local s = gui:GetAttribute("UIScaleFactor") or 1
	local vs = workspace.CurrentCamera.ViewportSize / s
	scale.Scale = math.clamp(math.min(vs.X / 600, vs.Y / 420), 0.7, 1)
end
fit() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) gui:GetAttributeChangedSignal("UIScaleFactor"):Connect(fit)
local stroke = Instance.new("UIStroke") stroke.Color = PINK stroke.Transparency = 0.3 stroke.Thickness = 2 stroke.Parent = panel

local header = label(panel, "Header", UDim2.new(0, 260, 0, 20), UDim2.fromOffset(290, 10), Enum.Font.GothamBold, PINK, 16, Enum.TextXAlignment.Left)
local wordLbl = label(panel, "Word", UDim2.new(0, 260, 0, 34), UDim2.fromOffset(290, 32), Enum.Font.GothamBlack, Color3.new(1,1,1), 28, Enum.TextXAlignment.Left)
local timerLbl = label(panel, "Timer", UDim2.new(0, 260, 0, 18), UDim2.fromOffset(290, 68), Enum.Font.GothamBold, Color3.fromRGB(255, 210, 90), 16, Enum.TextXAlignment.Left)

-- canvas (square)
local canvas = Instance.new("TextButton") canvas.Name = "Canvas" canvas.Text = "" canvas.AutoButtonColor = false canvas.Size = UDim2.fromOffset(270, 270)
canvas.Position = UDim2.fromOffset(10, 10) canvas.BackgroundColor3 = Color3.new(1,1,1) canvas.ClipsDescendants = true canvas.Parent = panel corner(canvas, 6)
local panelStrokes = Instance.new("Frame") panelStrokes.Name = "Strokes" panelStrokes.Size = UDim2.fromScale(1, 1) panelStrokes.BackgroundTransparency = 1 panelStrokes.Parent = canvas

-- drawer tools
local tools = Instance.new("Frame") tools.Name = "Tools" tools.Size = UDim2.fromOffset(270, 34) tools.Position = UDim2.fromOffset(10, 286) tools.BackgroundTransparency = 1 tools.Parent = panel
local colorIdx, width = 1, 2
local swatches = {}
for i, c in ipairs(COLORS) do
	local b = Instance.new("TextButton") b.Name = "Color" .. i b.Text = (i == #COLORS) and "🧽" or "" b.TextScaled = true b.Size = UDim2.fromOffset(24, 24)
	b.Position = UDim2.fromOffset((i - 1) * 27, 5) b.BackgroundColor3 = c b.Parent = tools corner(b, 12)
	local s = Instance.new("UIStroke") s.Thickness = (i == 1) and 3 or 1 s.Color = Color3.fromRGB(255, 210, 90) s.Parent = b
	swatches[i] = s
	b.MouseButton1Click:Connect(function() colorIdx = i for k, sw in ipairs(swatches) do sw.Thickness = (k == i) and 3 or 1 end end)
end
local sizeBtn = Instance.new("TextButton") sizeBtn.Name = "Size" sizeBtn.Size = UDim2.fromOffset(28, 24) sizeBtn.Position = UDim2.fromOffset(218, 5) sizeBtn.Text = "●"
sizeBtn.TextScaled = true sizeBtn.BackgroundColor3 = Color3.fromRGB(70, 75, 85) sizeBtn.TextColor3 = Color3.new(1,1,1) sizeBtn.Parent = tools corner(sizeBtn, 6)
sizeBtn.MouseButton1Click:Connect(function() width = width % 4 + 1 sizeBtn.Text = ({ "·", "●", "⬤", "⬛" })[width] end)
local clearBtn = Instance.new("TextButton") clearBtn.Name = "Clear" clearBtn.Size = UDim2.fromOffset(22, 24) clearBtn.Position = UDim2.fromOffset(248, 5) clearBtn.Text = "🗑"
clearBtn.TextScaled = true clearBtn.BackgroundColor3 = Color3.fromRGB(190, 70, 70) clearBtn.Parent = tools corner(clearBtn, 6)

-- guess area + feed
local feed = Instance.new("Frame") feed.Name = "Feed" feed.Size = UDim2.fromOffset(260, 180) feed.Position = UDim2.fromOffset(290, 92) feed.BackgroundColor3 = Color3.fromRGB(38, 44, 54)
feed.ClipsDescendants = true feed.Parent = panel corner(feed, 8)
local feedList = Instance.new("UIListLayout") feedList.VerticalAlignment = Enum.VerticalAlignment.Bottom feedList.Padding = UDim.new(0, 2) feedList.SortOrder = Enum.SortOrder.LayoutOrder feedList.Parent = feed
local box = Instance.new("TextBox") box.Name = "GuessBox" box.Size = UDim2.fromOffset(190, 34) box.Position = UDim2.fromOffset(290, 284) box.PlaceholderText = "Type your guess…"
box.Text = "" box.Font = Enum.Font.Gotham box.TextScaled = true box.ClearTextOnFocus = false box.BackgroundColor3 = Color3.fromRGB(240, 240, 240) box.TextColor3 = Color3.new(0,0,0) box.Parent = panel corner(box, 8)
local sendBtn = Instance.new("TextButton") sendBtn.Name = "Send" sendBtn.Size = UDim2.fromOffset(64, 34) sendBtn.Position = UDim2.fromOffset(486, 284) sendBtn.Text = "Guess"
sendBtn.Font = Enum.Font.GothamBold sendBtn.TextScaled = true sendBtn.TextColor3 = Color3.new(1,1,1) sendBtn.BackgroundColor3 = PINK sendBtn.Parent = panel corner(sendBtn, 8)

-- 🚫 hide vote + 🙈 don't show drawings (everyone except the drawer)
local hideBtn = Instance.new("TextButton") hideBtn.Name = "HideVote" hideBtn.Size = UDim2.fromOffset(78, 22) hideBtn.Position = UDim2.fromOffset(472, 66)
hideBtn.Text = "🚫 Hide" hideBtn.Font = Enum.Font.GothamBold hideBtn.TextScaled = true hideBtn.TextColor3 = Color3.new(1, 1, 1)
hideBtn.BackgroundColor3 = Color3.fromRGB(190, 60, 60) hideBtn.Visible = false hideBtn.Parent = panel corner(hideBtn, 6)
local eyeBtn = Instance.new("TextButton") eyeBtn.Name = "HideAll" eyeBtn.Size = UDim2.fromOffset(34, 22) eyeBtn.Position = UDim2.fromOffset(434, 66)
eyeBtn.Text = "👁" eyeBtn.Font = Enum.Font.GothamBold eyeBtn.TextScaled = true eyeBtn.TextColor3 = Color3.new(1, 1, 1)
eyeBtn.BackgroundColor3 = Color3.fromRGB(70, 75, 85) eyeBtn.Visible = false eyeBtn.Parent = panel corner(eyeBtn, 6)
local hideOthers = false   -- 🙈 on: other players' drawings are not shown to me
local botRound, voted = false, false

-- 📺 watch mode (players who didn't join)
local spectator = false
local watchNote = label(panel, "WatchNote", UDim2.fromOffset(260, 34), UDim2.fromOffset(290, 284), Enum.Font.GothamBold, Color3.fromRGB(190, 200, 215), 14)
watchNote.Text = "📺 Watching — join from the event banner to guess!" watchNote.Visible = false
local closeBtn = Instance.new("TextButton") closeBtn.Name = "Minimize" closeBtn.Size = UDim2.fromOffset(26, 26) closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -8, 0, 8) closeBtn.Text = "–" closeBtn.Font = Enum.Font.GothamBlack closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(70, 75, 85) closeBtn.TextColor3 = Color3.new(1, 1, 1) closeBtn.Visible = false closeBtn.Parent = panel corner(closeBtn, 13)
local watchBtn = Instance.new("TextButton") watchBtn.Name = "WatchButton" watchBtn.Size = UDim2.fromOffset(176, 36) watchBtn.AnchorPoint = Vector2.new(0.5, 1)
watchBtn.Position = UDim2.new(0.5, 0, 1, -112) watchBtn.Text = "📺 Watch the drawing" watchBtn.Font = Enum.Font.GothamBold watchBtn.TextScaled = true
watchBtn.BackgroundColor3 = PINK watchBtn.TextColor3 = Color3.new(1, 1, 1) watchBtn.Visible = false watchBtn.Parent = gui corner(watchBtn, 18)
do local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = 16 c.Parent = watchBtn local pd = Instance.new("UIPadding") pd.PaddingLeft = UDim.new(0, 10) pd.PaddingRight = UDim.new(0, 10) pd.Parent = watchBtn end
local watchOpen = false
local function applyWatchVisibility()
	if spectator then
		panel.Visible = watchOpen
		watchBtn.Visible = not watchOpen
	end
end
watchBtn.MouseButton1Click:Connect(function() watchOpen = true applyWatchVisibility() end)
closeBtn.MouseButton1Click:Connect(function() watchOpen = false applyWatchVisibility() end)
local function setSpectator(on)
	spectator = on
	closeBtn.Visible = on
	watchNote.Visible = on
	if on then
		box.Visible = false sendBtn.Visible = false tools.Visible = false
		applyWatchVisibility()
	else
		watchBtn.Visible = false
	end
end

local order = 0
local function addFeed(text, color)
	order += 1
	local l = label(feed, "Line", UDim2.new(1, -10, 0, 18), UDim2.new(), Enum.Font.Gotham, color or Color3.fromRGB(225, 230, 238), 14, Enum.TextXAlignment.Left)
	l.LayoutOrder = order l.Text = "  " .. text
	local lines = {}
	for _, c in ipairs(feed:GetChildren()) do if c:IsA("TextLabel") then table.insert(lines, c) end end
	if #lines > 9 then table.sort(lines, function(a, b) return a.LayoutOrder < b.LayoutOrder end) lines[1]:Destroy() end
end

---------------------------------------------------------------- rendering (panel + world board)
local function worldStrokes()
	local live = workspace:FindFirstChild("SamarCollege_Campus") and workspace.SamarCollege_Campus:FindFirstChild("EventZones")
	live = live and live:FindFirstChild("Live")
	if not live then return nil end
	for _, f in ipairs(live:GetChildren()) do
		local c = f:FindFirstChild("Canvas")
		local g = c and c:FindFirstChild("CanvasGui")
		if g then return g:FindFirstChild("Strokes") end
	end
end

local function drawPolyline(container, pts, color, w)
	for i = 1, #pts - 3, 2 do
		local x1, y1, x2, y2 = pts[i], pts[i + 1], pts[i + 2], pts[i + 3]
		local dx, dy = x2 - x1, y2 - y1
		local len = math.sqrt(dx * dx + dy * dy)
		local f = Instance.new("Frame") f.BorderSizePixel = 0 f.BackgroundColor3 = color f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale((x1 + x2) / 2, (y1 + y2) / 2)
		f.Size = UDim2.new(len, w, 0, w) f.Rotation = math.deg(math.atan2(dy, dx))
		corner(f, w) f.Parent = container
	end
	if #pts == 2 then -- single dot
		local f = Instance.new("Frame") f.BorderSizePixel = 0 f.BackgroundColor3 = color f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(pts[1], pts[2]) f.Size = UDim2.fromOffset(w, w) corner(f, w) f.Parent = container
	end
end

local isDrawer -- (set below)
local function drawStroke(d, panelToo)
	if hideOthers and not isDrawer and not botRound then return end
	local c = COLORS[d.c] or COLORS[1]
	if panelToo then drawPolyline(panelStrokes, d.pts, c, (d.w or 2) * 2) end
	local ws = worldStrokes()
	if ws then drawPolyline(ws, d.pts, c, (d.w or 2) * 3) end
end

local function clearAll()
	panelStrokes:ClearAllChildren()
	local ws = worldStrokes()
	if ws then ws:ClearAllChildren() end
end

---------------------------------------------------------------- drawing input (drawer only)
isDrawer = false
local drawing, last, buffer = false, nil, {}
local function canvasPoint(input)
	local p, s = canvas.AbsolutePosition, canvas.AbsoluteSize
	return math.clamp((input.Position.X - p.X) / s.X, 0, 1), math.clamp((input.Position.Y - p.Y) / s.Y, 0, 1)
end
canvas.InputBegan:Connect(function(input)
	if not isDrawer then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		drawing = true
		local x, y = canvasPoint(input)
		last = { x, y }
		buffer = { x, y }
	end
end)
UIS.InputChanged:Connect(function(input)
	if not drawing then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local x, y = canvasPoint(input)
		if last and math.abs(x - last[1]) + math.abs(y - last[2]) < 0.008 then return end
		table.insert(buffer, x) table.insert(buffer, y)
		last = { x, y }
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then drawing = false end
end)
-- send the buffer ~12 times per second (server allows 20/s, max 30 points each)
task.spawn(function()
	while true do
		task.wait(0.08)
		if isDrawer and #buffer >= 2 then
			local send = {}
			for i = 1, math.min(#buffer, 60) do send[i] = buffer[i] end
			local keepX, keepY = buffer[#send - 1], buffer[#send]
			if #buffer > 60 then
				local rest = { keepX, keepY }
				for i = 61, #buffer do table.insert(rest, buffer[i]) end
				buffer = rest
			else
				buffer = drawing and { keepX, keepY } or {}
			end
			if #send >= 2 then task.spawn(function() pcall(function() Remotes.EventAction:InvokeServer("stroke", { pts = send, c = colorIdx, w = width }) end) end) end
		end
	end
end)
clearBtn.MouseButton1Click:Connect(function() if isDrawer then pcall(function() Remotes.EventAction:InvokeServer("clear") end) end end)

---------------------------------------------------------------- guessing
local function submit()
	local text = box.Text
	if isDrawer or #text:gsub("%s", "") == 0 then return end
	box.Text = ""
	local ok, res = pcall(function() return Remotes.EventAction:InvokeServer("guess", { text = text }) end)
	if ok and res then
		if res.correct then addFeed(res.msg .. " (" .. tostring(res.word) .. ")", Color3.fromRGB(120, 230, 150)) wordLbl.Text = string.upper(res.word or "") box.TextEditable = false
		elseif res.msg then addFeed(res.msg, Color3.fromRGB(255, 200, 120)) end
	end
end
sendBtn.MouseButton1Click:Connect(submit)
box.FocusLost:Connect(function(enter) if enter then submit() end end)

---------------------------------------------------------------- server messages
local roundEnds = 0
local function safetyButtons(active)
	-- only for people who aren't drawing, and not when the 🤖 Art Bot draws
	local show = active and not isDrawer and not botRound
	hideBtn.Visible = show
	eyeBtn.Visible = active and not isDrawer
	hideBtn.Text = voted and "✔ Voted" or "🚫 Hide"
	hideBtn.AutoButtonColor = not voted
end
hideBtn.MouseButton1Click:Connect(function()
	if voted or isDrawer then return end
	voted = true safetyButtons(true)
	local ok, res = pcall(function() return Remotes.EventAction:InvokeServer("hideVote") end)
	if ok and type(res) == "table" and res.msg then addFeed(res.msg, Color3.fromRGB(255, 160, 160)) end
	if not (ok and type(res) == "table" and res.ok) and not (ok and res and res.msg and res.msg:find("already")) then voted = false safetyButtons(roundEnds > 0) end
end)
Remotes.EventData.OnClientEvent:Connect(function(d)
	if type(d) ~= "table" or d.event ~= "GuessTheDrawing" then return end
	if d.type == "stroke" then
		drawStroke(d, true)
	elseif d.type == "clear" then
		clearAll()
		if d.hide then panel.Visible = false isDrawer = false setSpectator(false) watchOpen = false end
	elseif d.type == "left" then
		-- pressed 🚪 Leave: close the panel; the small 📺 Watch button stays so they can still look
		isDrawer = false drawing = false tools.Visible = false
		watchOpen = false
		setSpectator(true)
		safetyButtons(false)
	elseif d.type == "hidden" then
		addFeed(d.text or "🚫 The drawing was hidden", Color3.fromRGB(255, 160, 160))
		hideBtn.Visible = false
	elseif d.type == "round" and d.spectator then
		isDrawer = false
		botRound = tostring(d.drawer):find("Art Bot") ~= nil voted = false
		setSpectator(true)
		header.Text = ("📺 Round %d / %d • %s is drawing"):format(d.round or 1, d.rounds or 1, d.drawer)
		wordLbl.Text = d.hint or ""
		roundEnds = os.clock() + (d.time or 60)
		addFeed("📺 " .. d.drawer .. " is drawing — can you guess it?", Color3.fromRGB(255, 210, 90))
	elseif d.type == "round" then
		setSpectator(false)
		panel.Visible = true
		isDrawer = d.isDrawer
		botRound = tostring(d.drawer):find("Art Bot") ~= nil voted = false
		tools.Visible = isDrawer
		box.Visible = not isDrawer sendBtn.Visible = not isDrawer box.TextEditable = true
		header.Text = ("🎨 Round %d / %d • %s %s"):format(d.round or 1, d.rounds or 1, d.drawer, isDrawer and "(you!)" or "is drawing")
		wordLbl.Text = isDrawer and ("✏️ " .. string.upper(d.word or "")) or d.hint
		roundEnds = os.clock() + (d.time or 60)
		addFeed(isDrawer and "✏️ Your turn to draw! Don't write the word." or ("👀 Guess what " .. d.drawer .. " is drawing!"), Color3.fromRGB(255, 210, 90))
	elseif d.type == "hint" then
		if spectator or (not isDrawer and box.TextEditable) then wordLbl.Text = d.hint end
	elseif d.type == "feed" then
		addFeed(d.text, d.good and Color3.fromRGB(120, 230, 150) or nil)
	elseif d.type == "roundEnd" then
		isDrawer = false tools.Visible = false
		wordLbl.Text = "The word was: " .. string.upper(d.word or "")
		roundEnds = 0
		safetyButtons(false)
	end
end)

local lastSync, lastBoard = 0, nil
local function sync(panelToo)
	if os.clock() - lastSync < 2.2 then return end
	lastSync = os.clock()
	local ok, res = pcall(function() return Remotes.EventAction:InvokeServer("drawSync") end)
	if not ok or type(res) ~= "table" or not res.ok then return end
	local ws = worldStrokes()
	if ws then ws:ClearAllChildren() end
	if panelToo then panelStrokes:ClearAllChildren() end
	for _, st in ipairs(res.strokes or {}) do drawStroke(st, panelToo) end
	if res.drawer and not res.joined then
		-- watching mid-round
		setSpectator(true)
		header.Text = ("📺 Round %d / %d • %s is drawing"):format(res.round or 1, res.rounds or 1, res.drawer)
		wordLbl.Text = res.hint or ""
		roundEnds = os.clock() + (res.timeLeft or 0)
	end
end
watchBtn.MouseButton1Click:Connect(function() task.spawn(sync, true) end)
eyeBtn.MouseButton1Click:Connect(function()
	hideOthers = not hideOthers
	eyeBtn.Text = hideOthers and "🙈" or "👁"
	eyeBtn.BackgroundColor3 = hideOthers and Color3.fromRGB(200, 130, 40) or Color3.fromRGB(70, 75, 85)
	if hideOthers then
		clearAll()
		addFeed("🙈 Other players' drawings are hidden for you. Tap again to show them.", Color3.fromRGB(255, 210, 90))
	else
		lastSync = 0 task.spawn(sync, true)
	end
end)
local eventOn = false
Remotes.EventState.OnClientEvent:Connect(function(st)
	eventOn = st.active and st.id == "GuessTheDrawing" and st.phase == "Active"
end)
task.spawn(function()
	while true do
		task.wait(1)
		local ws = worldStrokes()
		if eventOn and ws and ws ~= lastBoard then
			-- the classroom board just appeared (streamed in): fill it with the drawing so far
			lastBoard = ws
			lastSync = 0
			task.spawn(sync, panelStrokes:FindFirstChildWhichIsA("Frame") == nil)
		elseif not ws then lastBoard = nil end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.25)
		if panel.Visible and roundEnds > 0 then safetyButtons(true) elseif roundEnds <= 0 then hideBtn.Visible = false eyeBtn.Visible = false end
		if (panel.Visible or spectator) and roundEnds > 0 then timerLbl.Text = ("⏱ %d s left"):format(math.max(0, math.ceil(roundEnds - os.clock()))) else timerLbl.Text = "" end
	end
end)

Remotes.EventState.OnClientEvent:Connect(function(s)
	if (not s.active or s.id ~= "GuessTheDrawing" or s.phase == "Results") and (panel.Visible or spectator) then panel.Visible = false isDrawer = false setSpectator(false) watchOpen = false end
end)
