--[[ TowerClient — Summit Tower HUD (top-center under the event pill; clear of the Inventory hotbar and side buttons)
  • Floor x / 14 with a progress strip (🚩 = checkpoint floors)
  • Live run timer (the server measures the real time) • HP bar • best time & wins
  • Pop-ups: checkpoint ✓, hurt (red screen flash), knocked out, summit
  • Climbing music while you are in a run ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Remotes = RS:WaitForChild("Events"):WaitForChild("EventRemotes")
local Config = require(RS.Events:WaitForChild("EventConfig"))
local player = Players.LocalPlayer
local gui = script.Parent
local MUSIC = Config.TowerGame.Music

local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = p end
local function label(parent, name, size, pos, font, color, max, xa)
	local t = Instance.new("TextLabel") t.Name = name t.Size = size t.Position = pos t.BackgroundTransparency = 1 t.Font = font t.TextColor3 = color
	t.TextScaled = true t.TextXAlignment = xa or Enum.TextXAlignment.Center t.Parent = parent
	local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = max or 18 c.Parent = t
	return t
end

local hud = Instance.new("Frame") hud.Name = "TowerHUD" hud.AnchorPoint = Vector2.new(0.5, 0) hud.Position = UDim2.new(0.5, 0, 0, 102) -- top-center under the event pill (clear of the Inventory hotbar)
hud.Size = UDim2.new(0.92, 0, 0, 92) hud.BackgroundColor3 = Color3.fromRGB(20, 24, 32) hud.BackgroundTransparency = 0.1 hud.Visible = false hud.Parent = gui corner(hud, 14)
local lim = Instance.new("UISizeConstraint") lim.MaxSize = Vector2.new(460, 92) lim.Parent = hud
local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(255, 210, 90) st.Transparency = 0.5 st.Thickness = 1.5 st.Parent = hud
local floorLbl = label(hud, "Floor", UDim2.new(0.3, 0, 0, 26), UDim2.fromOffset(10, 6), Enum.Font.GothamBlack, Color3.new(1, 1, 1), 20, Enum.TextXAlignment.Left)
local timer = label(hud, "Time", UDim2.new(0.38, 0, 0, 30), UDim2.new(0.31, 0, 0, 4), Enum.Font.GothamBlack, Color3.fromRGB(255, 210, 90), 26)
local stats = label(hud, "Stats", UDim2.new(0.3, -46, 0, 22), UDim2.new(0.7, 0, 0, 8), Enum.Font.GothamBold, Color3.fromRGB(170, 220, 255), 14, Enum.TextXAlignment.Right)
-- floor strip
local strip = Instance.new("Frame") strip.Name = "FloorStrip" strip.Size = UDim2.new(1, -20, 0, 14) strip.Position = UDim2.fromOffset(10, 40) strip.BackgroundTransparency = 1 strip.Parent = hud
local sl = Instance.new("UIListLayout") sl.FillDirection = Enum.FillDirection.Horizontal sl.Padding = UDim.new(0, 3) sl.Parent = strip
-- hp bar
local hpBack = Instance.new("Frame") hpBack.Name = "HPBack" hpBack.Size = UDim2.new(1, -20, 0, 20) hpBack.Position = UDim2.fromOffset(10, 62) hpBack.BackgroundColor3 = Color3.fromRGB(50, 55, 65) hpBack.Parent = hud corner(hpBack, 8)
local hpBar = Instance.new("Frame") hpBar.Name = "HPBar" hpBar.Size = UDim2.fromScale(1, 1) hpBar.BackgroundColor3 = Color3.fromRGB(80, 220, 120) hpBar.Parent = hpBack corner(hpBar, 8)
local hpText = label(hpBack, "HPText", UDim2.fromScale(1, 1), UDim2.new(), Enum.Font.GothamBlack, Color3.new(1, 1, 1), 14)
hpText.ZIndex = 3

-- minimize / expand (big enough to tap on phones). Collapsed = one slim row: floor + timer.
local FULL_H, MINI_H = 92, 38
local collapsed = false
local minBtn = Instance.new("TextButton") minBtn.Name = "Minimize" minBtn.AnchorPoint = Vector2.new(1, 0)
minBtn.Position = UDim2.new(1, -5, 0, 5) minBtn.Size = UDim2.fromOffset(30, 28) minBtn.BackgroundColor3 = Color3.fromRGB(55, 62, 78)
minBtn.Text = "–" minBtn.Font = Enum.Font.GothamBlack minBtn.TextSize = 20 minBtn.TextColor3 = Color3.new(1, 1, 1) minBtn.AutoButtonColor = true
minBtn.ZIndex = 5 minBtn.Parent = hud corner(minBtn, 8)
local function layout()
	strip.Visible = not collapsed hpBack.Visible = not collapsed stats.Visible = not collapsed
	local h = collapsed and MINI_H or FULL_H
	hud.Size = UDim2.new(collapsed and 0.62 or 0.92, 0, 0, h)
	lim.MaxSize = Vector2.new(collapsed and 300 or 460, h)
	if collapsed then
		floorLbl.Size = UDim2.new(0.5, -10, 0, 26) floorLbl.Position = UDim2.fromOffset(10, 6)
		timer.Size = UDim2.new(0.5, -44, 0, 26) timer.Position = UDim2.new(0.5, 0, 0, 6)
	else
		floorLbl.Size = UDim2.new(0.3, 0, 0, 26) floorLbl.Position = UDim2.fromOffset(10, 6)
		timer.Size = UDim2.new(0.38, 0, 0, 30) timer.Position = UDim2.new(0.31, 0, 0, 4)
	end
	minBtn.Text = collapsed and "+" or "–"
end
minBtn.Activated:Connect(function() collapsed = not collapsed layout() end)
layout()

local pop = label(gui, "TowerPop", UDim2.fromOffset(480, 80), UDim2.fromScale(0.5, 0.36), Enum.Font.GothamBlack, Color3.new(1, 1, 1), 48)
pop.AnchorPoint = Vector2.new(0.5, 0.5) pop.TextStrokeTransparency = 0 pop.Visible = false
local popScale = Instance.new("UIScale") popScale.Parent = pop
local flash = Instance.new("Frame") flash.Name = "HurtFlash" flash.Size = UDim2.fromScale(1, 1) flash.BackgroundColor3 = Color3.fromRGB(255, 30, 30) flash.BackgroundTransparency = 1 flash.BorderSizePixel = 0 flash.ZIndex = 0 flash.Parent = gui

local function sound(name, id, vol, looped) local s = Instance.new("Sound") s.Name = name s.SoundId = id s.Volume = vol s.Looped = looped s.Parent = SoundService return s end
local music = sound("Tower_Music", MUSIC.Background, 0, true)
local chime = sound("Tower_Checkpoint", MUSIC.Checkpoint, 0.9, false) chime.PlaybackSpeed = 1.25
local ouch = sound("Tower_Hurt", MUSIC.Hurt, 0.8, false) ouch.PlaybackSpeed = 0.45 -- deep "bonk"
local function musicOn(on)
	if on and not music.IsPlaying then music:Play() end
	TweenService:Create(music, TweenInfo.new(1.2), { Volume = on and 0.35 or 0 }):Play()
	if not on then task.delay(1.3, function() if music.Volume < 0.01 then music:Stop() end end) end
end

local popToken = 0
local function showPop(text, color, seconds)
	popToken += 1
	local my = popToken
	pop.Text = text pop.TextColor3 = color pop.Visible = true popScale.Scale = 0.4
	TweenService:Create(popScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(seconds or 1.8, function() if popToken == my then pop.Visible = false end end)
end

local floors, cps, current, cp = 0, {}, 1, 0
local function buildStrip()
	for _, c in ipairs(strip:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local isCp = {} for _, f in ipairs(cps) do isCp[f] = true end
	for i = 1, floors do
		local seg = Instance.new("Frame") seg.Name = "F" .. i seg.LayoutOrder = i
		seg.Size = UDim2.new(1 / floors, -3, 1, 0) seg.BackgroundColor3 = Color3.fromRGB(60, 66, 78) seg.Parent = strip corner(seg, 3)
		if isCp[i] then
			local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(90, 230, 130) s.Thickness = 1.5 s.Parent = seg
			local f = label(seg, "Flag", UDim2.new(1, 0, 1, 6), UDim2.fromOffset(0, -3), Enum.Font.GothamBlack, Color3.new(1, 1, 1), 11) f.Text = "🚩"
		end
	end
end
local function paintStrip()
	for i = 1, floors do
		local seg = strip:FindFirstChild("F" .. i)
		if seg then
			seg.BackgroundColor3 = (i < current) and Color3.fromRGB(255, 210, 90) or (i == current and Color3.fromRGB(255, 240, 170) or Color3.fromRGB(60, 66, 78))
			if i <= cp and table.find(cps, i) then seg.BackgroundColor3 = Color3.fromRGB(90, 230, 130) end
		end
	end
end

local startAt, running = nil, false
local function fmt(s) s = math.max(0, s) return ("%d:%05.2f"):format(s // 60, s % 60) end

Remotes.EventData.OnClientEvent:Connect(function(d)
	if type(d) ~= "table" or d.event ~= "TowerGame" or d.type ~= "tower" then return end
	if d.hide then hud.Visible = false running = false musicOn(false) return end
	hud.Visible = true
	if d.floors and (d.floors ~= floors or #(d.cps or {}) ~= #cps) then floors = d.floors cps = d.cps or {} buildStrip() end
	stats.Text = ("⭐ %s   🏆 %d"):format((d.best or 0) > 0 and fmt(d.best) or "--", d.wins or 0)
	if d.music then musicOn(true) end
	if d.hurt then
		ouch:Play()
		flash.BackgroundTransparency = 0.55
		TweenService:Create(flash, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
	end
	if d.knocked then showPop("💫 KNOCKED OUT!", Color3.fromRGB(255, 120, 120), 1.6) end
	if d.fell then showPop((d.cp or 0) > 0 and "⬇️ FELL! BACK TO CHECKPOINT" or "⬇️ FELL TO THE BOTTOM!", Color3.fromRGB(150, 200, 255), 1.6) end
	if d.checkpoint then chime:Play() showPop(("🚩 CHECKPOINT • FLOOR %d"):format(d.checkpoint), Color3.fromRGB(120, 255, 170), 1.8) end
	if d.won then
		running = false
		floorLbl.Text = "🏆 SUMMIT!"
		timer.Text = "⏱ " .. fmt(d.time or 0)
		showPop(d.newBest and ("⭐ NEW BEST  " .. fmt(d.time or 0)) or ("🏆 SUMMIT  " .. fmt(d.time or 0)), Color3.fromRGB(255, 225, 110), 3)
		current = floors paintStrip()
		return
	end
	if d.state == "running" then
		current, cp = d.floor or 1, d.cp or 0
		floorLbl.Text = ("🗼 FLOOR %d/%d"):format(current, floors)
		if not running or d.started then startAt = os.clock() - (d.elapsed or 0) end
		running = true
		musicOn(true)
	else
		running = false current, cp = 0, 0
		floorLbl.Text = "🗼 Walk in to start"
		timer.Text = "⏱ 0:00.00"
	end
	paintStrip()
end)

task.spawn(function()
	while true do
		task.wait(0.05)
		if hud.Visible then
			if running and startAt then timer.Text = "⏱ " .. fmt(os.clock() - startAt) end
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				local f = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
				hpBar.Size = UDim2.fromScale(f, 1)
				hpBar.BackgroundColor3 = f > 0.6 and Color3.fromRGB(80, 220, 120) or (f > 0.3 and Color3.fromRGB(250, 200, 60) or Color3.fromRGB(240, 70, 60))
				hpText.Text = ("❤ %d / %d"):format(math.ceil(hum.Health), hum.MaxHealth)
			end
		end
	end
end)

---------------------------------------------------------------- camera guard: the tower's GLASS walls stop the camera
-- Roblox's camera only stops at walls that are mostly solid (under 25% see-through). The tower walls are glass
-- (55% see-through), so the camera slid outside the tower. Here the camera is pulled back in front of any tower
-- wall between your character and the camera. Only the tower's own "Wall" parts count.
local RunService = game:GetService("RunService")
local walls, wallsFrom = {}, nil
local function towerFolder()
	local zones = workspace:FindFirstChild("SamarCollege_Campus") and workspace.SamarCollege_Campus:FindFirstChild("EventZones")
	local live = zones and zones:FindFirstChild("Live")
	return live and live:FindFirstChild("SummitTower", true)
end
local lastScan = 0
RunService:BindToRenderStep("TowerCameraGuard", Enum.RenderPriority.Camera.Value + 1, function()
	-- refresh the wall list now and then (the tower is built when the event starts, and streams in)
	if os.clock() - lastScan > 2 then
		lastScan = os.clock()
		local t = towerFolder()
		if t ~= wallsFrom or (t and #walls == 0) then
			wallsFrom = t
			walls = {}
			if t then for _, d in ipairs(t:GetDescendants()) do if d:IsA("BasePart") and d.Name == "Wall" then table.insert(walls, d) end end end
		end
	end
	if #walls == 0 then return end
	local cam = workspace.CurrentCamera
	if cam.CameraType ~= Enum.CameraType.Custom then return end
	local focus = cam.Focus.Position
	local camPos = cam.CFrame.Position
	local dir = camPos - focus
	if dir.Magnitude < 0.5 then return end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = walls
	local hit = workspace:Raycast(focus, dir, params)
	if hit then
		-- stop just in front of the glass, on your side of it
		local newPos = hit.Position - dir.Unit * 0.6
		cam.CFrame = cam.CFrame + (newPos - camPos)
	end
end)

Remotes.EventState.OnClientEvent:Connect(function(s)
	-- also hide it when you're not (or no longer) in the event, e.g. after pressing 🚪 Leave
	if not s.active or s.id ~= "TowerGame" or s.phase == "Results" or not s.joined then hud.Visible = false running = false musicOn(false) end
end)
