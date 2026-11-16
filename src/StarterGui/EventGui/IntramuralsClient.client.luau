-- IntramuralsClient: team scoreboard, round banner + timer, relay gate hint, basketball
-- meter, tug-of-war PULL button + rope gauge, and the sports music. All points are decided
-- on the server; this only shows them and sends taps/shots.
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Remotes = RS:WaitForChild("Events"):WaitForChild("EventRemotes")
local Config = require(RS.Events:WaitForChild("EventConfig"))
local player = game:GetService("Players").LocalPlayer
local gui = script.Parent
local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = p end
local function label(parent, name, size, pos, font, col, max, xa)
	local t = Instance.new("TextLabel") t.Name = name t.Size = size t.Position = pos t.BackgroundTransparency = 1 t.Font = font t.TextColor3 = col
	t.TextScaled = true t.TextXAlignment = xa or Enum.TextXAlignment.Left t.Parent = parent
	local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = max or 16 c.Parent = t
	return t
end

-- team board (top-right under the event pill area)
local board = Instance.new("Frame") board.Name = "IntramuralsBoard" board.AnchorPoint = Vector2.new(1, 0) board.Position = UDim2.new(1, -12, 0, 104)
board.Size = UDim2.fromOffset(250, 176) board.BackgroundColor3 = Color3.fromRGB(20, 24, 32) board.BackgroundTransparency = 0.08 board.Visible = false board.Parent = gui corner(board, 12)
local roundL = label(board, "Round", UDim2.new(1, -16, 0, 22), UDim2.fromOffset(8, 6), Enum.Font.GothamBlack, Color3.fromRGB(255, 210, 90), 18)
local timeL = label(board, "Time", UDim2.new(1, -16, 0, 16), UDim2.fromOffset(8, 28), Enum.Font.GothamBold, Color3.fromRGB(200, 210, 225), 14)
local rows = {}
for i = 1, 8 do
	local r = Instance.new("Frame") r.Size = UDim2.new(1, -16, 0, 26) r.Position = UDim2.fromOffset(8, 48 + (i - 1) * 30) r.BackgroundColor3 = Color3.fromRGB(40, 46, 58) r.Parent = board corner(r, 8)
	local bar = Instance.new("Frame") bar.Name = "Bar" bar.Size = UDim2.fromScale(0, 1) bar.BackgroundTransparency = 0.35 bar.Parent = r corner(bar, 8)
	local t = label(r, "Text", UDim2.new(1, -12, 1, -4), UDim2.fromOffset(6, 2), Enum.Font.GothamBold, Color3.new(1, 1, 1), 14)
	rows[i] = { frame = r, bar = bar, text = t }
end
-- help / gate hint
local help = label(gui, "IntramuralsHelp", UDim2.fromOffset(480, 30), UDim2.new(0.5, -240, 0, 140), Enum.Font.GothamBold, Color3.new(1, 1, 1), 18, Enum.TextXAlignment.Center)
help.TextStrokeTransparency = 0.3 help.Visible = false
-- action panel (meter / pull)
local act = Instance.new("Frame") act.Name = "IntramuralsAction" act.AnchorPoint = Vector2.new(0.5, 1) act.Position = UDim2.new(0.5, 0, 1, -150)
act.Size = UDim2.fromOffset(380, 120) act.BackgroundColor3 = Color3.fromRGB(20, 24, 32) act.BackgroundTransparency = 0.08 act.Visible = false act.Parent = gui corner(act, 14)
local meterBar = Instance.new("Frame") meterBar.Size = UDim2.new(1, -24, 0, 30) meterBar.Position = UDim2.fromOffset(12, 14) meterBar.BackgroundColor3 = Color3.fromRGB(60, 66, 78) meterBar.Parent = act corner(meterBar, 8)
local zone = Instance.new("Frame") zone.AnchorPoint = Vector2.new(0.5, 0) zone.Size = UDim2.fromScale(0.18, 1) zone.BackgroundColor3 = Color3.fromRGB(80, 210, 120) zone.Parent = meterBar
local marker = Instance.new("Frame") marker.AnchorPoint = Vector2.new(0.5, 0.5) marker.Size = UDim2.new(0, 6, 1, 10) marker.Position = UDim2.fromScale(0, 0.5) marker.BackgroundColor3 = Color3.new(1, 1, 1) marker.ZIndex = 3 marker.Parent = meterBar corner(marker, 3)
local bigBtn = Instance.new("TextButton") bigBtn.Size = UDim2.new(1, -24, 0, 54) bigBtn.Position = UDim2.fromOffset(12, 56) bigBtn.Font = Enum.Font.GothamBlack bigBtn.TextScaled = true
bigBtn.TextColor3 = Color3.new(1, 1, 1) bigBtn.BackgroundColor3 = Color3.fromRGB(230, 110, 50) bigBtn.Parent = act corner(bigBtn, 12)
-- College course picker (shown once; the choice is saved)
local picker = Instance.new("Frame") picker.Name = "CoursePicker" picker.AnchorPoint = Vector2.new(0.5, 0) picker.Position = UDim2.new(0.5, 0, 0, 50) picker.ZIndex = 20
picker.Size = UDim2.fromOffset(340, 300) picker.BackgroundColor3 = Color3.fromRGB(20, 24, 32) picker.Visible = false picker.Parent = gui corner(picker, 16)
local pTitle = label(picker, "Title", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 10), Enum.Font.GothamBlack, Color3.fromRGB(255, 210, 90), 20, Enum.TextXAlignment.Center)
pTitle.Text = "🎓 Pick your course team" pTitle.ZIndex = 21
local pSub = label(picker, "Sub", UDim2.new(1, -24, 0, 18), UDim2.fromOffset(12, 40), Enum.Font.Gotham, Color3.fromRGB(200, 210, 225), 13, Enum.TextXAlignment.Center)
pSub.Text = "You only pick once — it's saved for every Intramurals." pSub.ZIndex = 21
local pList = Instance.new("Frame") pList.ZIndex = 21 pList.Size = UDim2.new(1, -24, 1, -72) pList.Position = UDim2.fromOffset(12, 64) pList.BackgroundTransparency = 1 pList.Parent = picker
local pl = Instance.new("UIListLayout") pl.Padding = UDim.new(0, 6) pl.Parent = pList
local function showPicker(options)
	for _, ch in ipairs(pList:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
	for _, o in ipairs(options) do
		local b = Instance.new("TextButton") b.Size = UDim2.new(1, 0, 0, 36) b.BackgroundColor3 = o.color b.Font = Enum.Font.GothamBlack b.TextScaled = true b.ZIndex = 21
		b.TextColor3 = Color3.new(1, 1, 1) b.TextStrokeTransparency = 0.4 b.Text = ("%s\n%s"):format(o.name, o.course) b.Parent = pList corner(b, 10)
		local cst = Instance.new("UITextSizeConstraint") cst.MaxTextSize = 15 cst.Parent = b
		b.MouseButton1Click:Connect(function()
			local ok, res = pcall(function() return Remotes.EventAction:InvokeServer("course", { index = o.index }) end)
			if ok and res and res.ok then picker.Visible = false end
		end)
	end
	picker.Size = UDim2.fromOffset(340, 76 + #options * 42)
	picker.Visible = true
end
local music = Instance.new("Sound") music.Name = "Intramurals_Music" music.SoundId = Config.Intramurals.Music music.Looped = true music.Volume = 0 music.Parent = SoundService

local mode, meter, ends = nil, nil, 0
local conn
local function fmt(s) s = math.max(0, math.floor(s)) return ("%d:%02d"):format(s // 60, s % 60) end
local function hideAll()
	board.Visible = false help.Visible = false act.Visible = false mode = nil
	if conn then conn:Disconnect() conn = nil end
	TweenService:Create(music, TweenInfo.new(1), { Volume = 0 }):Play()
end
local function setMode(m)
	mode = m
	act.Visible = m ~= nil
	meterBar.Visible = m == "meter" or m == "tug"
	zone.Visible = m == "meter"
	if conn then conn:Disconnect() conn = nil end
	if m == "meter" then
		bigBtn.Text = "🏀 SHOOT!" bigBtn.BackgroundColor3 = Color3.fromRGB(230, 110, 50)
		conn = RunService.RenderStepped:Connect(function()
			if not meter then return end
			local p = ((os.clock() - meter.start) * meter.speed) % 2
			marker.Position = UDim2.fromScale(p < 1 and p or 2 - p, 0.5)
		end)
	elseif m == "tug" then
		bigBtn.Text = "🪢 PULL! PULL! PULL!" bigBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	end
end

bigBtn.MouseButton1Click:Connect(function()
	if mode == "meter" then
		local ok, res = pcall(function() return Remotes.EventAction:InvokeServer("shoot") end)
		if ok and res and res.ok then
			help.Text = res.msg help.Visible = true
			meter = { start = os.clock(), speed = 0.95 }
			zone.Position = UDim2.fromScale(res.center, 0)
		end
	elseif mode == "tug" then
		task.spawn(function() pcall(function() Remotes.EventAction:InvokeServer("pull") end) end)
		bigBtn.Size = UDim2.new(1, -30, 0, 50)
		TweenService:Create(bigBtn, TweenInfo.new(0.1), { Size = UDim2.new(1, -24, 0, 54) }):Play()
	end
end)

Remotes.EventData.OnClientEvent:Connect(function(d)
	if type(d) ~= "table" or d.event ~= "Intramurals" then return end
	if d.type == "hide" then hideAll() picker.Visible = false return end
	if d.type == "chooseCourse" then showPicker(d.options) return end
	if d.type == "courseChosen" then picker.Visible = false return end
	if d.type == "teams" then
		board.Visible = true
		if music.Volume < 0.05 then if not music.IsPlaying then music:Play() end TweenService:Create(music, TweenInfo.new(1), { Volume = 0.3 }):Play() end
		roundL.Text = d.round or "🏆 Intramurals"
		ends = d.ends or 0
		local top = math.max(1, d.teams[1] and d.teams[1].score or 1)
		board.Size = UDim2.fromOffset(250, 54 + math.max(1, math.min(8, #d.teams)) * 30)
		for i, r in ipairs(rows) do
			local t = d.teams[i]
			r.frame.Visible = t ~= nil
			if t then
				r.bar.BackgroundColor3 = t.color
				r.bar.Size = UDim2.fromScale(math.clamp(t.score / top, 0.02, 1), 1)
				r.text.Text = ("%s  %d  (👥%d)"):format(t.name, t.score, t.members)
			end
		end
		help.Text = d.help or "" help.Visible = d.help ~= nil
		if d.roundId == "Tug" and d.tug then
			setMode(mode == "tug" and "tug" or "tug")
			marker.Position = UDim2.fromScale(0.5 + d.tug.offset / 20, 0.5)
			meterBar.BackgroundColor3 = Color3.fromRGB(60, 66, 78)
			help.Text = ("🪢 %s  ⟵  vs  ⟶  %s"):format(d.tug.a, d.tug.b)
		elseif d.roundId == "Shootout" then
			if mode ~= "meter" then help.Text = d.help end
		elseif mode then setMode(nil) end
	elseif d.type == "meter" then
		meter = { start = os.clock(), speed = d.speed }
		zone.Position = UDim2.fromScale(d.center, 0) zone.Size = UDim2.fromScale(d.half * 2, 1)
		setMode("meter")
	elseif d.type == "gate" then
		help.Text = ("🏃 Run to GATE %d!"):format(d.next) help.Visible = true
	elseif d.type == "intermission" then
		setMode(nil)
	end
end)

task.spawn(function()
	while true do task.wait(0.5) if board.Visible then timeL.Text = "⏱ " .. fmt(ends - os.time()) .. " left in this round" end end
end)
Remotes.EventState.OnClientEvent:Connect(function(s) if not s.active or s.id ~= "Intramurals" or s.phase == "Results" then hideAll() end end)
