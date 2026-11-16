--[[ SportsClient — court panel (teams / CPU / start / watch / vote-kick), the timing meter
  for hitting, the flying shuttle that everyone sees, TV cameras for watchers, vote popups and toasts. ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local Sports = RS:WaitForChild("Sports")
local C = require(Sports:WaitForChild("SportsConfig"))
local Action = Sports:WaitForChild("SportsAction")
local Event = Sports:WaitForChild("SportsEvent")
local gui = script.Parent

local DARK, GOLD, WHITE = Color3.fromRGB(22, 27, 36), Color3.fromRGB(255, 210, 90), Color3.new(1, 1, 1)
local BLUE, RED = Color3.fromRGB(70, 140, 235), Color3.fromRGB(230, 80, 90)
local function new(class, props, parent) local o = Instance.new(class) for k, v in pairs(props or {}) do o[k] = v end o.Parent = parent return o end
local function corner(p, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 10) }, p) end
local function stroke(p, c, t) return new("UIStroke", { Color = c or WHITE, Thickness = t or 1.5, Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
local function label(parent, props)
	local t = new("TextLabel", { BackgroundTransparency = 1, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextScaled = true }, parent)
	for k, v in pairs(props) do if k ~= "MaxSize" then t[k] = v end end
	new("UITextSizeConstraint", { MaxTextSize = props.MaxSize or 20 }, t)
	return t
end
local function button(parent, text, size, pos, color, maxSize)
	local b = new("TextButton", { Text = text, Size = size, Position = pos, BackgroundColor3 = color or Color3.fromRGB(60, 150, 90), TextColor3 = WHITE,
		Font = Enum.Font.GothamBold, TextScaled = true, AutoButtonColor = true }, parent)
	corner(b, 8) new("UITextSizeConstraint", { MaxTextSize = maxSize or 16 }, b)
	new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, b)
	return b
end
local function call(action, data)
	local ok, res = pcall(function() return Action:InvokeServer(action, data) end)
	return ok and res or { ok = false }
end
local DIV = {} for _, d in ipairs(C.Divisions) do DIV[d.id] = d end

-- whole UI scales with the screen (phones too)
local uiScale = new("UIScale", {}, gui)
local function rescale()
	local vp = workspace.CurrentCamera.ViewportSize
	uiScale.Scale = math.clamp(math.min(vp.X / 1000, (vp.Y - game:GetService("GuiService"):GetGuiInset().Y) / 560), 0.5, 1.15) -- usable height (minus Roblox top bar)
end
rescale() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

---------------------------------------------------------------- toasts
local toastHolder = new("Frame", { Size = UDim2.new(0, 460, 0, 120), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 110), BackgroundTransparency = 1 }, gui)
new("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, toastHolder)
local tn = 0
local function toast(text, color)
	tn += 1
	local t = label(toastHolder, { Text = text, Size = UDim2.new(1, 0, 0, 26), TextColor3 = color or WHITE, TextStrokeTransparency = 0.3, LayoutOrder = tn, MaxSize = 18 })
	local items = {} for _, c in ipairs(toastHolder:GetChildren()) do if c:IsA("TextLabel") then table.insert(items, c) end end
	if #items > 4 then table.sort(items, function(a, b) return a.LayoutOrder < b.LayoutOrder end) items[1]:Destroy() end
	task.delay(4, function() if t.Parent then TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play() task.wait(0.45) t:Destroy() end end)
end

---------------------------------------------------------------- court panel
local panel = new("Frame", { Name = "CourtPanel", Size = UDim2.fromOffset(520, 380), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = DARK, BackgroundTransparency = 0.04, Visible = false }, gui)
corner(panel, 16) stroke(panel, GOLD, 2)
local pTitle = label(panel, { Size = UDim2.new(1, -60, 0, 30), Position = UDim2.fromOffset(16, 10), Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, MaxSize = 24 })
local pSub = label(panel, { Size = UDim2.new(1, -32, 0, 20), Position = UDim2.fromOffset(16, 42), Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(200, 210, 220), TextXAlignment = Enum.TextXAlignment.Left, MaxSize = 16 })
local closeBtn = button(panel, "X", UDim2.fromOffset(30, 30), UDim2.new(1, -42, 0, 10), Color3.fromRGB(80, 85, 95))
local body = new("Frame", { Size = UDim2.new(1, -32, 1, -120), Position = UDim2.fromOffset(16, 70), BackgroundTransparency = 1 }, panel)
local footer = new("Frame", { Size = UDim2.new(1, -32, 0, 40), Position = UDim2.new(0, 16, 1, -50), BackgroundTransparency = 1 }, panel)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 10) }, footer)

local openCourt = nil   -- court snapshot shown in the panel
local myCourt = nil     -- court id I'm playing on
local chosenDiv = nil

local function clear(f) for _, c in ipairs(f:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end end
local renderPanel

local function sideColumn(st, side, x)
	local col = new("Frame", { Size = UDim2.new(0.5, -6, 1, 0), Position = UDim2.new(x, x > 0 and 6 or 0, 0, 0), BackgroundColor3 = Color3.fromRGB(32, 38, 50) }, body)
	corner(col, 10)
	local color = side == "A" and BLUE or RED
	label(col, { Text = side == "A" and "🔵 TEAM A" or "🔴 TEAM B", Size = UDim2.new(1, -16, 0, 26), Position = UDim2.fromOffset(8, 6), TextColor3 = color, Font = Enum.Font.GothamBlack })
	local list = side == "A" and st.a or st.b
	for i, p in ipairs(list) do
		local row = new("Frame", { Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 34 + (i - 1) * 34), BackgroundColor3 = Color3.fromRGB(45, 52, 66) }, col)
		corner(row, 8)
		label(row, { Text = p.name .. (p.userId == player.UserId and "  (you)" or ""), Size = UDim2.new(1, -50, 1, -6), Position = UDim2.fromOffset(8, 3), TextXAlignment = Enum.TextXAlignment.Left, MaxSize = 16 })
		if st.voteKick and not p.cpu and p.userId ~= player.UserId and not st.vote then
			local k = button(row, "🚫", UDim2.fromOffset(34, 24), UDim2.new(1, -38, 0, 3), Color3.fromRGB(170, 60, 60), 14)
			k.MouseButton1Click:Connect(function()
				local res = call("votekick", { court = st.id, target = p.userId })
				toast(res.ok and "🗳️ Vote started!" or (res.msg or "Couldn't start a vote"), res.ok and GOLD or Color3.fromRGB(255, 170, 120))
			end)
		end
	end
	local full = #list >= st.perSide
	local inThis = myCourt == st.id
	if st.state == "Idle" or st.state == "Lobby" then
		if not inThis and not full then
			local j = button(col, "JOIN TEAM " .. side, UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 1, -42), color)
			j.MouseButton1Click:Connect(function()
				local res = call("join", { court = st.id, side = side })
				if res.ok then myCourt = st.id else toast(res.msg or "Couldn't join", Color3.fromRGB(255, 170, 120)) end
			end)
		elseif inThis and not full and st.state == "Lobby" then
			local c = button(col, "🤖 ADD CPU", UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 1, -42), Color3.fromRGB(90, 95, 110))
			c.MouseButton1Click:Connect(function() local res = call("cpu", { court = st.id, side = side }) if not res.ok and res.msg then toast(res.msg) end end)
		end
	end
end

function renderPanel(st)
	if not st then return end
	openCourt = st
	clear(body) clear(footer)
	local div = st.division and DIV[st.division]
	pTitle.Text = ("%s %s"):format(st.icon, st.name)
	local stateText = ({ Idle = "Open — pick a team and join! Everyone can play", Lobby = "Getting ready…", Playing = "Match in progress", Finished = "Match over" })[st.state] or st.state
	local cd = st.countdown and (st.autofill and ("  • 🤖 CPUs join in " .. st.countdown .. "s if nobody comes") or ("  • starts in " .. st.countdown .. "s")) or ""
	pSub.Text = (st.intramurals and "🏆 INTRAMURALS x2 • " or "") .. stateText .. cd
	sideColumn(st, "A", 0) sideColumn(st, "B", 0.5)
	if st.state == "Playing" or st.state == "Finished" then
		local sc = label(body, { Text = ("%d  –  %d"):format(st.score.A, st.score.B), Size = UDim2.new(0, 160, 0, 40), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 30), Font = Enum.Font.Arcade, TextColor3 = GOLD, MaxSize = 34, ZIndex = 3 })
	end
	if st.vote then label(body, { Text = ("🗳️ Vote to remove %s: %d yes / %d no"):format(st.vote.target, st.vote.yes, st.vote.no), Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, 2), TextColor3 = GOLD, MaxSize = 15 }) end
	-- footer
	if myCourt == st.id and st.state == "Lobby" then
		local s = button(footer, "▶ START NOW", UDim2.fromOffset(150, 38), UDim2.new(), Color3.fromRGB(60, 160, 90))
		s.MouseButton1Click:Connect(function() local res = call("start", { court = st.id }) if not res.ok and res.msg then toast(res.msg) end end)
	end
	if myCourt == st.id then
		local l = button(footer, "LEAVE", UDim2.fromOffset(110, 38), UDim2.new(), Color3.fromRGB(170, 70, 70))
		l.MouseButton1Click:Connect(function() call("leave", { court = st.id }) myCourt = nil renderPanel(openCourt) end)
	end
	local w = button(footer, "📺 WATCH", UDim2.fromOffset(130, 38), UDim2.new(), Color3.fromRGB(80, 90, 160))
	w.MouseButton1Click:Connect(function() panel.Visible = false startWatching(st) end)
	if st.voteKick then label(panel, { Name = "VKNote", Text = "🚫 = start a vote to remove a player (the majority decides)", Size = UDim2.new(1, -32, 0, 14), Position = UDim2.new(0, 16, 1, -14), TextColor3 = Color3.fromRGB(150, 160, 175), Font = Enum.Font.Gotham, MaxSize = 12 })
	else local n = panel:FindFirstChild("VKNote") if n then n:Destroy() end end
end
closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)

---------------------------------------------------------------- match HUD (score) + hitting
local hud = new("Frame", { Name = "MatchHUD", Size = UDim2.fromOffset(360, 54), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 56), BackgroundColor3 = DARK, BackgroundTransparency = 0.15, Visible = false }, gui)
corner(hud, 14) stroke(hud, GOLD, 1.5)
local hudTop = label(hud, { Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, 4), TextColor3 = GOLD, MaxSize = 14 })
local hudA = label(hud, { Size = UDim2.new(0.4, -10, 0, 26), Position = UDim2.fromOffset(8, 24), TextColor3 = BLUE, TextXAlignment = Enum.TextXAlignment.Left, MaxSize = 16 })
local hudS = label(hud, { Size = UDim2.new(0.2, 0, 0, 26), Position = UDim2.new(0.4, 0, 0, 24), Font = Enum.Font.Arcade, MaxSize = 24 })
local hudB = label(hud, { Size = UDim2.new(0.4, -10, 0, 26), Position = UDim2.new(0.6, 2, 0, 24), TextColor3 = RED, TextXAlignment = Enum.TextXAlignment.Right, MaxSize = 16 })
local hudCourt = nil
local hudClockEnd, hudTitle = nil, ""
local function renderHud(st)
	if not st then return end
	hudTitle = ("%s %s"):format(st.icon, st.sportName)
	hudClockEnd = st.clock and (os.clock() + st.clock) or nil
	local ot = st.overtime and "  •  ⚡ NEXT BASKET WINS" or ""
	hudTitle ..= ot
	hudTop.Text = hudTitle
	local function n(list) local t = {} for _, p in ipairs(list) do table.insert(t, p.name) end return table.concat(t, " & ") end
	hudA.Text = (st.serve == "A" and st.state == "Playing" and (st.icon .. " ") or "") .. n(st.a)
	hudB.Text = n(st.b) .. (st.serve == "B" and st.state == "Playing" and (" " .. st.icon) or "")
	hudS.Text = ("%d - %d"):format(st.score.A, st.score.B)
end
-- 🏀 game clock ticks on the match bar
task.spawn(function()
	while true do
		task.wait(0.5)
		if hud.Visible and hudClockEnd then
			local c = math.max(0, hudClockEnd - os.clock())
			hudTop.Text = ("%s  •  ⏱ %d:%02d"):format(hudTitle, c // 60, math.floor(c % 60))
		end
	end
end)

local play = new("Frame", { Name = "HitPanel", Size = UDim2.fromOffset(480, 150), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), BackgroundColor3 = DARK, BackgroundTransparency = 0.1, Visible = false }, gui)
corner(play, 14) stroke(play, GOLD, 1.5)
local hint = label(play, { Text = "Wait for the shuttle…", Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 6), TextColor3 = Color3.fromRGB(210, 220, 230), MaxSize = 15 })
local bar = new("Frame", { Size = UDim2.new(1, -150, 0, 30), Position = UDim2.fromOffset(10, 32), BackgroundColor3 = Color3.fromRGB(55, 62, 76) }, play) corner(bar, 8)
local zone = new("Frame", { Size = UDim2.fromScale(0.2, 1), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), BackgroundColor3 = Color3.fromRGB(80, 210, 120), Visible = false }, bar) corner(zone, 6)
local marker = new("Frame", { Size = UDim2.new(0, 6, 1, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = WHITE, ZIndex = 3, Visible = false }, bar) corner(marker, 3)
local timeBar = new("Frame", { Size = UDim2.new(1, -150, 0, 5), Position = UDim2.fromOffset(10, 66), BackgroundColor3 = GOLD }, play) corner(timeBar, 3)
local hitBtn = button(play, "HIT!", UDim2.fromOffset(120, 60), UDim2.new(1, -130, 0, 14), Color3.fromRGB(220, 90, 70), 26)
local shotRow = new("Frame", { Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, 82), BackgroundTransparency = 1 }, play)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, shotRow)
local keyHint = label(play, { Text = "Tap HIT (or press F / Space) when the white line is in the green zone", Size = UDim2.new(1, -20, 0, 16), Position = UDim2.fromOffset(10, 124), Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(160, 170, 185), MaxSize = 13 })
local chosenShot = "clear"
local shotButtons = {}
local incoming = nil
local function applyZone()
	-- basketball: every move has its own green zone size
	if incoming and incoming.zones and incoming.zones[chosenShot] then
		incoming.half = incoming.zones[chosenShot]
		zone.Size = UDim2.fromScale(incoming.half * 2, 1)
	end
end
local function buildShots(st)
	for _, c in ipairs(shotRow:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
	shotButtons = {}
	local many = #(st.shots or {}) >= 4
	for _, s in ipairs(st.shots or {}) do
		local b = button(shotRow, s.label, UDim2.fromOffset(many and 106 or 110, 32), UDim2.new(), Color3.fromRGB(60, 66, 80), 15)
		shotButtons[s.key] = b
		b.MouseButton1Click:Connect(function()
			chosenShot = s.key
			for k, x in pairs(shotButtons) do x.BackgroundColor3 = k == chosenShot and Color3.fromRGB(60, 130, 210) or Color3.fromRGB(60, 66, 80) end
			applyZone()
		end)
	end
	if not many then
		label(shotRow, { Text = st.tip or "Faster shot = harder to return", Size = UDim2.fromOffset(110, 32), Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(160, 170, 185), MaxSize = 12 })
	end
	if not shotButtons[chosenShot] then
		chosenShot = (shotButtons.layup and "layup") or (st.shots and st.shots[1] and st.shots[1].key) or chosenShot
	end
	if shotButtons[chosenShot] then shotButtons[chosenShot].BackgroundColor3 = Color3.fromRGB(60, 130, 210) end
	keyHint.Text = st.kind == "Basketball" and "Pick a move, then HIT (F / Space) in the green. Bigger green = easier" or "Tap HIT (or press F / Space) when the white line is in the green zone"
end

local meterConn
local function stopMeter()
	incoming = nil
	zone.Visible = false marker.Visible = false
	timeBar.Size = UDim2.new(1, -150, 0, 5)
	hint.Text = "Wait for the ball…"
	hitBtn.BackgroundColor3 = Color3.fromRGB(110, 110, 120)
end
stopMeter()
local function startMeter(d)
	incoming = { start = os.clock(), time = d.time, speed = d.speed, center = d.center, half = d.half, zones = d.zones }
	zone.Size = UDim2.fromScale(d.half * 2, 1) zone.Position = UDim2.fromScale(d.center, 0)
	zone.Visible = true marker.Visible = true
	applyZone()
	hitBtn.BackgroundColor3 = Color3.fromRGB(220, 90, 70)
	hint.Text = d.hint or (d.fast and ("⚡ " .. (d.label or "Smash") .. " incoming — be quick!") or ("Here it comes (" .. (d.label or "shot") .. ") — HIT in the green!"))
end
RunService.RenderStepped:Connect(function()
	if not incoming then return end
	local t = os.clock() - incoming.start
	local p = (t * incoming.speed) % 2
	marker.Position = UDim2.fromScale(p < 1 and p or 2 - p, 0.5)
	local left = math.clamp(1 - t / incoming.time, 0, 1)
	timeBar.Size = UDim2.new((1 - 0) * left, -150 * left, 0, 5)
	if t > incoming.time + 0.15 then stopMeter() end
end)
local function doHit()
	if not incoming then return end
	local t = os.clock() - incoming.start
	stopMeter()
	local res = call("hit", { shot = chosenShot, t = t })
	if res.msg then toast(res.msg, res.hit and Color3.fromRGB(120, 230, 150) or Color3.fromRGB(255, 140, 120))
	elseif res.ok and res.hit then toast("✅ Nice return!", Color3.fromRGB(120, 230, 150)) elseif res.ok then toast("❌ Mis-hit!", Color3.fromRGB(255, 140, 120)) end
end
hitBtn.MouseButton1Click:Connect(doHit)
UIS.InputBegan:Connect(function(i, gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.F or i.KeyCode == Enum.KeyCode.Space or i.KeyCode == Enum.KeyCode.ButtonA then doHit() end
end)

---------------------------------------------------------------- the shuttle everyone sees
local fxFolder = new("Folder", { Name = "SportsFX" }, workspace)
local function makeShuttle()
	local m = new("Model", { Name = "Shuttle" }, fxFolder)
	local cork = new("Part", { Name = "Cork", Shape = Enum.PartType.Ball, Size = Vector3.new(0.45, 0.45, 0.45), Color = WHITE, Material = Enum.Material.SmoothPlastic, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = true }, m)
	local skirt = new("Part", { Name = "Skirt", Size = Vector3.new(0.75, 0.6, 0.75), Color = Color3.fromRGB(245, 245, 245), Material = Enum.Material.SmoothPlastic, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 0.15 }, m)
	new("SpecialMesh", { MeshType = Enum.MeshType.FileMesh, MeshId = "rbxassetid://1033714", Scale = Vector3.new(0.35, 0.5, 0.35) }, skirt)
	local a0 = new("Attachment", { Position = Vector3.new(0, 0.2, 0) }, cork)
	local a1 = new("Attachment", { Position = Vector3.new(0, -0.2, 0) }, cork)
	new("Trail", { Attachment0 = a0, Attachment1 = a1, Lifetime = 0.25, Color = ColorSequence.new(WHITE), Transparency = NumberSequence.new(0.3, 1), WidthScale = NumberSequence.new(1, 0) }, cork)
	return m, cork, skirt
end
local shuttle, cork, skirt
local flyToken = 0
local ballKind = "Shuttle"
local ballPart
local function placeBall(pos, d)
	if not ballPart or not ballPart.Parent then
		ballPart = new("Part", { Name = "Ball", Shape = Enum.PartType.Ball, Material = Enum.Material.SmoothPlastic, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false }, fxFolder)
		local a0 = new("Attachment", { Position = Vector3.new(0, 0.1, 0) }, ballPart) local a1 = new("Attachment", { Position = Vector3.new(0, -0.1, 0) }, ballPart)
		new("Trail", { Attachment0 = a0, Attachment1 = a1, Lifetime = 0.18, Transparency = NumberSequence.new(0.4, 1), WidthScale = NumberSequence.new(1, 0) }, ballPart)
	end
	ballPart.Size = Vector3.one * (d.ballSize or 0.4)
	ballPart.Color = d.ballColor or Color3.fromRGB(255, 150, 40)
	ballPart.Trail.Color = ColorSequence.new(ballPart.Color)
	ballPart.CFrame = CFrame.new(pos)
end
local function placeShuttle(pos, dir)
	if ballKind ~= "Shuttle" then return end
	if not shuttle or not shuttle.Parent then shuttle, cork, skirt = makeShuttle() end
	local look = dir.Magnitude > 0.01 and dir.Unit or Vector3.yAxis
	local cf = CFrame.lookAt(pos, pos + look) * CFrame.Angles(math.rad(-90), 0, 0)
	cork.CFrame = cf
	skirt.CFrame = cf * CFrame.new(0, -0.45, 0) * CFrame.Angles(math.rad(180), 0, 0)
end
local lastShot = {}
local sfx -- defined below
local function fly(from, to, time, height, smash, d, bounceTo)
	flyToken += 1
	local my = flyToken
	local t0 = os.clock()
	local last = from
	d = d or lastShot
	ballKind = d.ball or "Shuttle"
	if ballKind ~= "Shuttle" and shuttle then shuttle:Destroy() shuttle = nil end
	if ballKind == "Shuttle" and ballPart then ballPart:Destroy() ballPart = nil end
	task.spawn(function()
		local function arc(a0, b0, tt, h)
			local s0 = os.clock()
			while my == flyToken do
				local a = math.min(1, (os.clock() - s0) / tt)
				local pos = a0:Lerp(b0, a) + Vector3.new(0, h * 4 * a * (1 - a), 0)
				if ballKind == "Shuttle" then placeShuttle(pos, pos - last) else placeBall(pos, d) end
				last = pos
				if a >= 1 then break end
				RunService.RenderStepped:Wait()
			end
		end
		if bounceTo then
			-- table tennis: bounce on the table, then up to the receiver's paddle
			arc(from, to, time * 0.7, height)
			if my == flyToken then sfx("rbxasset://sounds/clickfast.wav", 0.35, 1.8, to) end
			arc(to, bounceTo, time * 0.3, 0.8)
		else
			arc(from, to, time, height)
		end
	end)
end
sfx = function(id, vol, pitch, pos)
	local p = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, Transparency = 1, Size = Vector3.one * 0.2, CFrame = CFrame.new(pos or workspace.CurrentCamera.CFrame.Position) }, fxFolder)
	local s = new("Sound", { SoundId = id, Volume = vol or 0.5, PlaybackSpeed = pitch or 1, RollOffMaxDistance = 80 }, p)
	s:Play() game:GetService("Debris"):AddItem(p, 3)
end
local function burst(pos, color)
	local p = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, Transparency = 1, Size = Vector3.one * 0.2, CFrame = CFrame.new(pos) }, fxFolder)
	local e = new("ParticleEmitter", { Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(color or WHITE), Size = NumberSequence.new(0.5, 0), Lifetime = NumberRange.new(0.4, 0.7), Speed = NumberRange.new(5, 10), SpreadAngle = Vector2.new(180, 180), Rate = 0 }, p)
	e:Emit(20) game:GetService("Debris"):AddItem(p, 1.5)
end

---------------------------------------------------------------- watching (TV cameras)
local watchCourt, camIndex, camConn = nil, 1, nil
local watchBar = new("Frame", { Name = "WatchBar", Size = UDim2.fromOffset(330, 42), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), BackgroundColor3 = DARK, BackgroundTransparency = 0.15, Visible = false }, gui)
corner(watchBar, 12) stroke(watchBar, GOLD, 1.5)
label(watchBar, { Text = "📺 Watching", Size = UDim2.fromOffset(110, 30), Position = UDim2.fromOffset(8, 6), TextColor3 = GOLD, MaxSize = 16 })
local camBtn = button(watchBar, "🎥 Camera", UDim2.fromOffset(100, 30), UDim2.fromOffset(120, 6), Color3.fromRGB(80, 90, 160))
local stopBtn = button(watchBar, "✖ Stop", UDim2.fromOffset(90, 30), UDim2.fromOffset(230, 6), Color3.fromRGB(150, 70, 70))
local function courtModel(id)
	local v = workspace:FindFirstChild("SportsVenues")
	if not v then return end
	for _, m in ipairs(v:GetChildren()) do if m:GetAttribute("CourtId") == id then return m end end
end
local function setCam()
	local m = watchCourt and courtModel(watchCourt)
	local mk = m and m:FindFirstChild("Markers")
	local c = mk and mk:FindFirstChild("Cam" .. camIndex)
	if not c then camIndex = 1 c = mk and mk:FindFirstChild("Cam1") end
	if not c then return end
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(cam, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { CFrame = c.CFrame }):Play()
end
function startWatching(st)
	watchCourt = st.id
	player:SetAttribute("SC_Watching", st.id)
	camIndex = 1
	call("watch", { court = st.id })
	watchBar.Visible = true
	hudCourt = st.id renderHud(st) hud.Visible = true
	setCam()
end
local function stopWatching()
	if watchCourt then call("unwatch", { court = watchCourt }) end
	watchCourt = nil
	player:SetAttribute("SC_Watching", nil)
	watchBar.Visible = false
	if myCourt == nil then hud.Visible = false hudCourt = nil end
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then cam.CameraSubject = hum end
end
camBtn.MouseButton1Click:Connect(function() camIndex = camIndex % 3 + 1 setCam() end)
stopBtn.MouseButton1Click:Connect(stopWatching)

-- sitting on a court bleacher = watching that court (score HUD shows; camera is optional)
task.spawn(function()
	local seatedCourt = nil
	while true do
		task.wait(0.5)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local seat = hum and hum.SeatPart
		local cid = seat and seat:GetAttribute("CourtId")
		if cid ~= seatedCourt then
			seatedCourt = cid
			if cid then
				local st = call("watch", { court = cid })
				if st and st.court then hudCourt = cid renderHud(st.court) hud.Visible = true toast("📺 You're watching " .. st.court.name .. "  •  🎥 tap Camera for TV view", GOLD) end
				watchCourt = cid watchBar.Visible = true
				player:SetAttribute("SC_Watching", cid)
			elseif watchCourt and not myCourt then
				watchBar.Visible = false call("unwatch", { court = watchCourt }) watchCourt = nil hud.Visible = false hudCourt = nil
				player:SetAttribute("SC_Watching", nil)
				local cam = workspace.CurrentCamera if cam.CameraType == Enum.CameraType.Scriptable then stopWatching() end
			end
		end
	end
end)

---------------------------------------------------------------- vote popup
local votePop = new("Frame", { Name = "VotePopup", Size = UDim2.fromOffset(380, 150), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), BackgroundColor3 = DARK, BackgroundTransparency = 0.05, Visible = false }, gui)
corner(votePop, 14) stroke(votePop, Color3.fromRGB(230, 90, 90), 2)
local voteTitle = label(votePop, { Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 8), TextColor3 = Color3.fromRGB(255, 140, 140), Font = Enum.Font.GothamBlack, MaxSize = 18 })
local voteText = label(votePop, { Size = UDim2.new(1, -20, 0, 48), Position = UDim2.fromOffset(10, 34), Font = Enum.Font.Gotham, MaxSize = 15, TextWrapped = true })
local yesB = button(votePop, "✅ YES, remove", UDim2.new(0.5, -15, 0, 36), UDim2.new(0, 10, 1, -46), Color3.fromRGB(170, 60, 60))
local noB = button(votePop, "❌ NO, keep", UDim2.new(0.5, -15, 0, 36), UDim2.new(0.5, 5, 1, -46), Color3.fromRGB(60, 140, 90))
local voteCourt, voteEnds = nil, 0
local function vote(yes) if voteCourt then call("vote", { court = voteCourt, yes = yes }) end votePop.Visible = false end
yesB.MouseButton1Click:Connect(function() vote(true) end)
noB.MouseButton1Click:Connect(function() vote(false) end)
task.spawn(function() while true do task.wait(0.5) if votePop.Visible then local l = math.ceil(voteEnds - os.clock()) voteTitle.Text = ("🗳️ VOTE KICK  •  %ds"):format(math.max(0, l)) if l <= 0 then votePop.Visible = false end end end end)

---------------------------------------------------------------- server messages
local resultPop = new("Frame", { Size = UDim2.fromOffset(420, 120), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.35), BackgroundColor3 = DARK, Visible = false }, gui)
corner(resultPop, 16) stroke(resultPop, GOLD, 2)
local resultTitle = label(resultPop, { Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 14), Font = Enum.Font.GothamBlack, TextColor3 = GOLD, MaxSize = 30 })
local resultSub = label(resultPop, { Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 62), Font = Enum.Font.GothamBold, MaxSize = 20 })

local function inMyView(id) return id == myCourt or id == watchCourt or id == hudCourt end

Event.OnClientEvent:Connect(function(d)
	if type(d) ~= "table" then return end
	if d.t == "open" then
		panel.Visible = true renderPanel(d.court)
	elseif d.t == "court" then
		local st = d.court
		-- am I on this court?
		local mine = false
		for _, p in ipairs(st.a) do if p.userId == player.UserId then mine = true end end
		for _, p in ipairs(st.b) do if p.userId == player.UserId then mine = true end end
		if mine then myCourt = st.id elseif myCourt == st.id then myCourt = nil end
		if openCourt and openCourt.id == st.id and panel.Visible then renderPanel(st) end
		if mine or inMyView(st.id) then
			hudCourt = st.id renderHud(st)
			hud.Visible = st.state ~= "Idle" or watchCourt == st.id
		end
		if mine and st.state == "Playing" and st.kind ~= "Chess" then
			if not play.Visible then buildShots(st) end
			play.Visible = true panel.Visible = false
		elseif mine and st.state == "Playing" then panel.Visible = false play.Visible = false -- ♟️ chess uses its own board (ChessClient)
		elseif mine then play.Visible = false end
		if not mine and myCourt == nil and watchCourt == nil and hudCourt == st.id then hud.Visible = false end
	elseif d.t == "left" then
		if myCourt == d.court then myCourt = nil end
		play.Visible = false stopMeter()
		if not watchCourt then hud.Visible = false end
	elseif d.t == "incoming" then
		startMeter(d)
	elseif d.t == "shot" then
		local cam = workspace.CurrentCamera
		if (cam.CFrame.Position - d.from).Magnitude < 160 then
			lastShot = d
			fly(d.from, d.to, d.time, d.height, d.shot == "smash", d, d.bounceTo)
			sfx("rbxasset://sounds/clickfast.wav", d.shot == "smash" and 0.8 or 0.5, d.shot == "smash" and 0.8 or 1.3, d.from)
			if d.shot == "smash" then burst(d.from, Color3.fromRGB(255, 220, 120)) end
		end
	elseif d.t == "miss" then
		local from = d.from
		fly(from, from + Vector3.new(0, -2.6, 0), 0.5, 1.5, false, lastShot)
	elseif d.t == "point" then
		if d.landing then burst(d.landing + Vector3.new(0, 0.3, 0), Color3.fromRGB(255, 90, 90)) sfx("rbxasset://sounds/electronicpingshort.wav", 0.4, 0.7, d.landing) end
		if inMyView(d.court) then toast(("%s  •  %d – %d"):format(d.reason or "Point!", d.score.A, d.score.B), d.side == "A" and BLUE or RED) end
		stopMeter()
	elseif d.t == "serve" then
		if inMyView(d.court) then toast(("🎾 %s serves"):format(d.name), Color3.fromRGB(220, 230, 240)) end
	elseif d.t == "touch" then
		-- volleyball team play: bump → set → attack
		if inMyView(d.court) then toast(d.text, Color3.fromRGB(255, 230, 140)) end
	elseif d.t == "matchEnd" then
		if inMyView(d.court) then
			resultTitle.Text = d.winner and ("🏆 " .. d.winner .. " WIN!") or (d.why == "draw" and "🤝 DRAW!" or "Match over")
			resultSub.Text = ("Final score  %d – %d%s"):format(d.score.A, d.score.B, d.why == "forfeit" and "  (forfeit)" or "")
			resultPop.Visible = true
			sfx("rbxasset://sounds/victory.wav", 0.5, 1)
			task.delay(5, function() resultPop.Visible = false end)
		end
		play.Visible = false stopMeter()
	elseif d.t == "tick" then
		if openCourt and openCourt.id == d.court and panel.Visible then openCourt.countdown = d.countdown openCourt.autofill = d.autofill renderPanel(openCourt) end
		if d.court == myCourt and d.countdown <= 5 then toast(d.autofill and ("🤖 Filling with CPUs in %d…"):format(d.countdown) or ("Match starts in %d…"):format(d.countdown), GOLD) end
	elseif d.t == "vote" then
		voteCourt = d.court voteEnds = os.clock() + d.duration
		voteText.Text = ("%s started a vote: remove %s from this %s game?"):format(d.by, d.target, d.sport)
		votePop.Visible = not d.voted
		if d.voted then toast("🗳️ Your vote: YES. Waiting for the others…", GOLD) end
	elseif d.t == "voteEnd" then
		votePop.Visible = false
	elseif d.t == "toast" then
		toast(d.text, GOLD)
	end
end)
