--[[ BoothClient — the pop-up panel for the School Fair booth games.
  The server opens a panel with { kind = "meter" | "guess" | "memory" | "wheel" | "info" }.
  Every move is sent with EventAction("booth", { op = ... }) and the server answers
  with the result (tickets are always decided on the server). ]]
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Remotes = RS:WaitForChild("Events"):WaitForChild("EventRemotes")
local gui = script.Parent

local DARK, GOLD = Color3.fromRGB(25, 30, 38), Color3.fromRGB(255, 210, 90)
local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = p end
local function label(parent, name, size, pos, font, color, maxSize)
	local t = Instance.new("TextLabel") t.Name = name t.Size = size t.Position = pos t.BackgroundTransparency = 1 t.Font = font or Enum.Font.Gotham
	t.TextColor3 = color or Color3.new(1,1,1) t.TextScaled = true t.TextWrapped = true t.Parent = parent
	local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = maxSize or 20 c.Parent = t
	return t
end
local function button(parent, name, text, size, pos, col)
	local b = Instance.new("TextButton") b.Name = name b.Text = text b.Size = size b.Position = pos b.BackgroundColor3 = col or Color3.fromRGB(60, 150, 90)
	b.TextColor3 = Color3.new(1,1,1) b.Font = Enum.Font.GothamBold b.TextScaled = true b.Parent = parent corner(b, 10)
	local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = 20 c.Parent = b
	return b
end

local panel = Instance.new("Frame") panel.Name = "BoothPanel" panel.Size = UDim2.new(0.9, 0, 0, 300) panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -24) panel.BackgroundColor3 = DARK panel.BackgroundTransparency = 0.05 panel.Visible = false panel.Parent = gui corner(panel, 16)
local lim = Instance.new("UISizeConstraint") lim.MaxSize = Vector2.new(560, 300) lim.Parent = panel
local st = Instance.new("UIStroke") st.Color = GOLD st.Transparency = 0.4 st.Thickness = 2 st.Parent = panel
local title = label(panel, "Title", UDim2.new(1, -60, 0, 26), UDim2.fromOffset(14, 10), Enum.Font.GothamBlack, GOLD, 22)
title.TextXAlignment = Enum.TextXAlignment.Left
local desc = label(panel, "Description", UDim2.new(1, -28, 0, 30), UDim2.fromOffset(14, 38), Enum.Font.Gotham, Color3.fromRGB(210, 218, 228), 15)
local status = label(panel, "Status", UDim2.new(1, -28, 0, 24), UDim2.new(0, 14, 1, -34), Enum.Font.GothamBold, Color3.new(1,1,1), 18)
local quit = button(panel, "Quit", "X", UDim2.fromOffset(30, 30), UDim2.new(1, -40, 0, 10), Color3.fromRGB(80, 85, 95))
local area = Instance.new("Frame") area.Name = "GameArea" area.Size = UDim2.new(1, -28, 0, 180) area.Position = UDim2.fromOffset(14, 74) area.BackgroundTransparency = 1 area.Parent = panel

local session = nil   -- current game info
-- the panel is only as tall as the game needs, so the stall stays visible above it
local HEIGHTS = { info = 162, meter = 236, guess = 214, memory = 352, wheel = 262 }
local function fitPanel(kind)
	local h = HEIGHTS[kind] or 296
	lim.MaxSize = Vector2.new(560, h)
	panel.Size = UDim2.new(0.9, 0, 0, h)
	area.Size = UDim2.new(1, -28, 0, h - 116)
end
-- while playing, the camera looks at the stall from behind the player
local camSaved = false
local ghosted = {} -- fans / bunting / lights between the camera and the stall are faded (only on this screen)
local function boothCamera(d)
	local cam = workspace.CurrentCamera
	if not d.camPos or not d.camLook then return end
	camSaved = true
	cam.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(cam, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.lookAt(d.camPos, d.camLook) }):Play()
	-- fade decorations / ceiling fans that sit between the camera and the stall
	local a, b = d.camPos, d.camLook
	local ab = b - a
	local function near(p)
		local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
		return t < 0.8 and (a + ab * t - p).Magnitude < 5
	end
	local fair = d.boothModel and d.boothModel.Parent and d.boothModel.Parent.Parent
	local roots = {}
	if fair and fair:FindFirstChild("Decor") then table.insert(roots, fair.Decor) end
	local campus = workspace:FindFirstChild("SamarCollege_Campus")
	local hall = campus and campus:FindFirstChild("1F_Ground") and campus["1F_Ground"]:FindFirstChild("02_Rooms") and campus["1F_Ground"]["02_Rooms"]:FindFirstChild("OpenHall_1F")
	if hall then for _, n in ipairs({ "Fans", "Lighting" }) do if hall:FindFirstChild(n) then table.insert(roots, hall[n]) end end end
	for _, r in ipairs(roots) do
		for _, p in ipairs(r:GetDescendants()) do
			if p:IsA("BasePart") and p.Size.Magnitude < 30 and near(p.Position) then table.insert(ghosted, p) p.LocalTransparencyModifier = 0.92 end
		end
	end
end
local function restoreCamera()
	for _, p in ipairs(ghosted) do if p.Parent then p.LocalTransparencyModifier = 0 end end
	ghosted = {}
	if not camSaved then return end
	camSaved = false
	local cam = workspace.CurrentCamera
	local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	cam.CameraType = Enum.CameraType.Custom
	if hum then cam.CameraSubject = hum end
end
local meterConn = nil

local function clearArea()
	if meterConn then meterConn:Disconnect() meterConn = nil end
	for _, c in ipairs(area:GetChildren()) do c:Destroy() end
end
local function send(op, extra)
	local data = extra or {}
	data.op = op
	local ok, res = pcall(function() return Remotes.EventAction:InvokeServer("booth", data) end)
	return ok and res or { ok = false }
end
local function close() clearArea() session = nil panel.Visible = false restoreCamera() end
quit.MouseButton1Click:Connect(function() pcall(function() Remotes.EventAction:InvokeServer("boothQuit") end) close() end)

---------------------------------------------------------------- METER (ring toss / target throw)
local function buildMeter(ui)
	local bar = Instance.new("Frame") bar.Name = "MeterBar" bar.Size = UDim2.new(1, 0, 0, 36) bar.Position = UDim2.fromOffset(0, 0)
	bar.BackgroundColor3 = Color3.fromRGB(60, 66, 78) bar.Parent = area corner(bar, 8)
	local zoneHolder = Instance.new("Frame") zoneHolder.Size = UDim2.fromScale(1, 1) zoneHolder.BackgroundTransparency = 1 zoneHolder.Parent = bar
	local function drawZones(zones)
		for _, z in ipairs(zoneHolder:GetChildren()) do z:Destroy() end
		local cols = { Color3.fromRGB(240, 200, 80), Color3.fromRGB(240, 140, 60), Color3.fromRGB(80, 210, 120) }
		for i, z in ipairs(zones) do
			local f = Instance.new("Frame") f.AnchorPoint = Vector2.new(0.5, 0) f.Position = UDim2.fromScale(z.center, 0) f.Size = UDim2.fromScale(z.half * 2, 1)
			f.BackgroundColor3 = (#zones == 1) and Color3.fromRGB(80, 210, 120) or cols[i] f.BorderSizePixel = 0 f.Parent = zoneHolder
		end
	end
	drawZones(ui.zones)
	local marker = Instance.new("Frame") marker.Name = "Marker" marker.Size = UDim2.new(0, 6, 1, 12) marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Position = UDim2.fromScale(0, 0.5) marker.BackgroundColor3 = Color3.new(1,1,1) marker.ZIndex = 3 marker.Parent = bar corner(marker, 3)
	local shots = label(area, "Shots", UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 42), Enum.Font.Gotham, Color3.fromRGB(220, 225, 235), 18)
	local fire = button(area, "Fire", ui.verb or "GO", UDim2.new(0, 180, 0, 44), UDim2.new(0.5, -90, 0, 66), Color3.fromRGB(220, 90, 70))
	local start, speed, left = os.clock(), ui.speed or 0.9, ui.shots
	shots.Text = ("Shots left: %d"):format(left)
	meterConn = RunService.RenderStepped:Connect(function()
		local p = ((os.clock() - start) * speed) % 2
		marker.Position = UDim2.fromScale(p < 1 and p or 2 - p, 0.5)
	end)
	local busy = false
	fire.MouseButton1Click:Connect(function()
		if busy or left <= 0 then return end
		busy = true
		local res = send("shoot")
		if res.ok then
			left = res.shots
			shots.Text = ("Shots left: %d"):format(left)
			status.Text = res.msg or ""
			if res.zones then drawZones(res.zones) start = os.clock() end
			if res.done then fire.Active = false fire.AutoButtonColor = false fire.BackgroundColor3 = Color3.fromRGB(80, 85, 95) end
		end
		task.wait(0.35)
		busy = false
	end)
end

---------------------------------------------------------------- GUESS THE NUMBER
local function buildGuess(ui)
	local box = Instance.new("TextBox") box.Name = "Input" box.Size = UDim2.new(0.5, 0, 0, 46) box.Position = UDim2.new(0.1, 0, 0, 0)
	box.PlaceholderText = ("%d – %d"):format(ui.min, ui.max) box.Text = "" box.Font = Enum.Font.GothamBold box.TextScaled = true box.ClearTextOnFocus = true
	box.BackgroundColor3 = Color3.fromRGB(240, 240, 240) box.TextColor3 = Color3.fromRGB(20, 20, 20) box.Parent = area corner(box, 8)
	local go = button(area, "Guess", "GUESS", UDim2.new(0.28, 0, 0, 46), UDim2.new(0.62, 0, 0, 0))
	local hint = label(area, "Hint", UDim2.new(1, 0, 0, 36), UDim2.fromOffset(0, 54), Enum.Font.GothamBlack, GOLD, 26)
	hint.Text = ("You have %d tries"):format(ui.tries)
	local function submit()
		local n = tonumber(box.Text)
		if not n then hint.Text = "Type a number" return end
		local res = send("guess", { guess = n })
		box.Text = ""
		if res.hint then hint.Text = ("%d? %s  (%d tries left)"):format(n, res.hint, res.triesLeft or 0) end
		if res.msg then status.Text = res.msg end
		if res.done then go.Active = false box.TextEditable = false hint.Text = "" end
	end
	go.MouseButton1Click:Connect(submit)
	box.FocusLost:Connect(function(enter) if enter then submit() end end)
end

---------------------------------------------------------------- MEMORY MATCH
local function buildMemory(ui)
	local cards = {}
	local busy = false
	for i = 1, ui.count do
		local rowsN = math.ceil(ui.count / 4)
		local ch = rowsN >= 4 and 50 or 80
		local c = button(area, "Card" .. i, "❓", UDim2.new(0.25, -8, 0, ch), UDim2.new(((i - 1) % 4) * 0.25, 4, 0, math.floor((i - 1) / 4) * (ch + 6)), Color3.fromRGB(70, 110, 190))
		cards[i] = c
		c.MouseButton1Click:Connect(function()
			if busy or c.Text ~= "❓" then return end
			local res = send("flip", { flip = i })
			if not res.ok then return end
			c.Text = res.face c.BackgroundColor3 = Color3.fromRGB(240, 240, 240) c.TextColor3 = Color3.new(0,0,0)
			if res.match then for _, k in ipairs(res.match) do cards[k].BackgroundColor3 = Color3.fromRGB(90, 200, 120) end end
			if res.miss then
				busy = true
				task.wait(0.8)
				for _, k in ipairs(res.miss) do cards[k].Text = "❓" cards[k].BackgroundColor3 = Color3.fromRGB(70, 110, 190) cards[k].TextColor3 = Color3.new(1,1,1) end
				busy = false
			end
			if res.msg then status.Text = res.msg end
		end)
	end
	status.Text = ("Find all pairs in %d seconds!"):format(ui.seconds or 45)
end

---------------------------------------------------------------- LUCKY WHEEL
local function buildWheel(ui)
	local wheel = Instance.new("Frame") wheel.Name = "Wheel" wheel.Size = UDim2.fromOffset(120, 120) wheel.Position = UDim2.new(0.5, -170, 0, 14)
	wheel.BackgroundColor3 = Color3.fromRGB(250, 220, 90) wheel.Parent = area corner(wheel, 65)
	local labels = {}
	for i, txt in ipairs(ui.segments) do
		local a = (i - 1) / #ui.segments * math.pi * 2
		local l = label(wheel, "Seg" .. i, UDim2.fromOffset(34, 22), UDim2.new(0.5, math.sin(a) * 44 - 17, 0.5, -math.cos(a) * 44 - 11), Enum.Font.GothamBlack, Color3.fromRGB(40, 40, 40), 16)
		l.Text = txt labels[i] = l
	end
	local pointer = label(area, "Pointer", UDim2.fromOffset(30, 24), UDim2.new(0.5, -120, 0, 0), Enum.Font.GothamBlack, Color3.fromRGB(230, 70, 70), 22)
	pointer.Text = "▼"
	local spin = button(area, "Spin", "SPIN!", UDim2.new(0, 160, 0, 54), UDim2.new(0.5, 10, 0, 60), Color3.fromRGB(230, 120, 60))
	spin.MouseButton1Click:Connect(function()
		spin.Active = false spin.AutoButtonColor = false
		local res = send("spin")
		if not res.ok then status.Text = res.msg or "" return end
		-- spin, then stop on the server's segment
		local target = -((res.segment - 1) / #ui.segments) * 360 + 360 * 5
		TweenService:Create(wheel, TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Rotation = target }):Play()
		task.wait(3.1)
		status.Text = res.msg or ""
	end)
end

---------------------------------------------------------------- INFO (balloon pop, messages)
local function buildInfo(ui)
	local l = label(area, "Info", UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 0), Enum.Font.GothamBlack, GOLD, 24)
	l.Text = ui.text or ""
	if ui.seconds then
		local t = label(area, "Timer", UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 38), Enum.Font.GothamBold, Color3.new(1,1,1), 28)
		local ends = os.clock() + ui.seconds
		task.spawn(function()
			while t.Parent and os.clock() < ends do t.Text = ("⏱ %d"):format(math.ceil(ends - os.clock())) task.wait(0.2) end
			if t.Parent then t.Text = "" end
		end)
	end
end

Remotes.EventData.OnClientEvent:Connect(function(d)
	if type(d) ~= "table" or d.event ~= "Booth" then return end
	if d.type == "boothOpen" then
		clearArea()
		session = d
		title.Text = (d.icon or "🎪") .. " " .. (d.name or "Booth")
		desc.Text = d.description or ""
		status.Text = ""
		fitPanel(d.kind)
		panel.Visible = true
		boothCamera(d)
		if d.kind == "meter" then buildMeter(d)
		elseif d.kind == "guess" then buildGuess(d)
		elseif d.kind == "memory" then buildMemory(d)
		elseif d.kind == "wheel" then buildWheel(d)
		else buildInfo(d) end
	elseif d.type == "boothResult" then
		status.Text = d.msg or ""
	elseif d.type == "boothClose" then
		task.delay(0.3, function() if session and session.game == d.game then close() end end)
	end
end)

Remotes.EventState.OnClientEvent:Connect(function(s)
	if (not s.active or s.id ~= "Booth" or s.phase == "Results") and panel.Visible then close() end
end)
