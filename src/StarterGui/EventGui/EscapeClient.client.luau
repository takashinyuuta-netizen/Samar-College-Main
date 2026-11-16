--[[ EscapeClient — Escape Samar College on YOUR screen.
  • Team key grid (top-right) + "next key" hint line
  • 🧭 Guide arrow above your head → nearest missing key (distance + floors up/down),
    then → the Main Gate when the team has all 8 keys
  • Music: calm school background; alarm + chase music while a patrol is chasing you
  • "SPOTTED!", "You lost them", detention countdown and the key pickup pop
  Everything here is visual/sound only — the server decides keys, catches and escapes. ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Remotes = RS:WaitForChild("Events"):WaitForChild("EventRemotes")
local Config = require(RS.Events:WaitForChild("EventConfig"))
local player = Players.LocalPlayer
local gui = script.Parent
local MUSIC = Config.EscapeSchool.Music

local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = p end
local function label(parent, name, size, pos, font, color, max, xa)
	local t = Instance.new("TextLabel") t.Name = name t.Size = size t.Position = pos t.BackgroundTransparency = 1 t.Font = font t.TextColor3 = color
	t.TextScaled = true t.TextXAlignment = xa or Enum.TextXAlignment.Left t.Parent = parent
	local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = max or 18 c.Parent = t
	return t
end

---------------------------------------------------------------- key panel (top-right, clear of Profile/Bag/Map)
local panel = Instance.new("Frame") panel.Name = "EscapeKeys" panel.Size = UDim2.fromOffset(250, 150) panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -12, 0.3, 0) panel.BackgroundColor3 = Color3.fromRGB(22, 27, 35) panel.BackgroundTransparency = 0.08 panel.Visible = false panel.Parent = gui corner(panel, 14)
local pst = Instance.new("UIStroke") pst.Color = Color3.fromRGB(255, 210, 90) pst.Transparency = 0.45 pst.Thickness = 1.5 pst.Parent = panel
local head = label(panel, "Head", UDim2.new(1, -52, 0, 24), UDim2.fromOffset(10, 6), Enum.Font.GothamBlack, Color3.fromRGB(255, 210, 90), 20)
local grid = Instance.new("Frame") grid.Name = "Grid" grid.Size = UDim2.new(1, -20, 0, 76) grid.Position = UDim2.fromOffset(10, 34) grid.BackgroundTransparency = 1 grid.Parent = panel
local gl = Instance.new("UIGridLayout") gl.CellSize = UDim2.new(0.25, -5, 0, 34) gl.CellPadding = UDim2.fromOffset(5, 6) gl.SortOrder = Enum.SortOrder.LayoutOrder gl.Parent = grid
local nextLine = label(panel, "Next", UDim2.new(1, -20, 0, 26), UDim2.new(0, 10, 1, -32), Enum.Font.GothamBold, Color3.fromRGB(170, 220, 255), 15)

-- minimize / expand (tap-sized for phones). Collapsed = just "TEAM KEYS x/8".
local keysCollapsed = false
local minBtn = Instance.new("TextButton") minBtn.Name = "Minimize" minBtn.AnchorPoint = Vector2.new(1, 0)
minBtn.Position = UDim2.new(1, -5, 0, 4) minBtn.Size = UDim2.fromOffset(32, 28) minBtn.BackgroundColor3 = Color3.fromRGB(55, 62, 78)
minBtn.Text = "–" minBtn.Font = Enum.Font.GothamBlack minBtn.TextSize = 20 minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.ZIndex = 5 minBtn.Parent = panel corner(minBtn, 8)
local function keysLayout()
	grid.Visible = not keysCollapsed nextLine.Visible = not keysCollapsed
	panel.Size = keysCollapsed and UDim2.fromOffset(190, 36) or UDim2.fromOffset(250, 150)
	minBtn.Text = keysCollapsed and "+" or "–"
end
minBtn.Activated:Connect(function() keysCollapsed = not keysCollapsed keysLayout() end)
keysLayout()

local chips = {}
local function buildGrid(keys)
	for _, c in ipairs(grid:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	chips = {}
	for i, k in ipairs(keys) do
		local f = Instance.new("Frame") f.Name = k.id f.LayoutOrder = i f.BackgroundColor3 = k.color f.BackgroundTransparency = 0.55 f.Parent = grid corner(f, 8)
		local s = Instance.new("UIStroke") s.Color = k.color s.Thickness = 1.5 s.Parent = f
		local t = label(f, "Name", UDim2.new(1, -4, 1, -4), UDim2.fromOffset(2, 2), Enum.Font.GothamBlack, Color3.new(1, 1, 1), 14, Enum.TextXAlignment.Center)
		t.Text = k.id
		chips[k.id] = { frame = f, text = t, stroke = s }
	end
end
local function setChip(k)
	local c = chips[k.id]
	if not c then return end
	c.frame.BackgroundTransparency = k.got and 0.05 or 0.6
	c.text.Text = k.got and ("✓ " .. k.id) or k.id
	c.text.TextTransparency = k.got and 0 or 0.25
end

---------------------------------------------------------------- alerts + key pop
local alert = Instance.new("TextLabel") alert.Name = "Alert" alert.Size = UDim2.fromOffset(440, 64) alert.AnchorPoint = Vector2.new(0.5, 0) alert.Position = UDim2.new(0.5, 0, 0.24, 0)
alert.BackgroundColor3 = Color3.fromRGB(200, 40, 40) alert.TextColor3 = Color3.new(1, 1, 1) alert.Font = Enum.Font.GothamBlack alert.TextScaled = true alert.Visible = false alert.Parent = gui corner(alert, 14)
do local lim = Instance.new("UISizeConstraint") lim.MaxSize = Vector2.new(440, 64) lim.Parent = alert local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 12) pad.PaddingRight = UDim.new(0, 12) pad.Parent = alert end
local alertToken = 0
local function showAlert(text, color, seconds)
	alertToken += 1
	local my = alertToken
	alert.Text = text alert.BackgroundColor3 = color alert.Visible = true
	alert.Size = UDim2.fromOffset(400, 56)
	TweenService:Create(alert, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(440, 64) }):Play()
	task.delay(seconds or 2.5, function() if alertToken == my then alert.Visible = false end end)
end

local pop = Instance.new("TextLabel") pop.Name = "KeyPop" pop.AnchorPoint = Vector2.new(0.5, 0.5) pop.Position = UDim2.fromScale(0.5, 0.42) pop.Size = UDim2.fromOffset(460, 90)
pop.BackgroundTransparency = 1 pop.Font = Enum.Font.GothamBlack pop.TextScaled = true pop.TextStrokeTransparency = 0 pop.Visible = false pop.Parent = gui
local popScale = Instance.new("UIScale") popScale.Parent = pop
local flash = Instance.new("Frame") flash.Name = "Flash" flash.Size = UDim2.fromScale(1, 1) flash.BackgroundTransparency = 1 flash.BorderSizePixel = 0 flash.ZIndex = 0 flash.Parent = gui

---------------------------------------------------------------- music
local function sound(name, id, vol, looped)
	local s = Instance.new("Sound") s.Name = name s.SoundId = id s.Volume = vol s.Looped = looped s.Parent = SoundService
	return s
end
local bg = sound("Escape_BG", MUSIC.Background, 0, true)
local chase = sound("Escape_Chase", MUSIC.Chase, 0, true)
local stinger = sound("Escape_Spotted", MUSIC.Spotted, 0.7, false)
local keySfx = sound("Escape_Key", MUSIC.KeyGet, 0.9, false)
local mode = "off" -- off | calm | chase
local function fade(s, to, t)
	if to > 0 and not s.IsPlaying then s:Play() end
	local tw = TweenService:Create(s, TweenInfo.new(t or 1), { Volume = to })
	tw:Play()
	if to == 0 then tw.Completed:Connect(function() if s.Volume == 0 then s:Pause() end end) end
end
local function setMode(m)
	if m == mode then return end
	mode = m
	if m == "calm" then fade(chase, 0, 1.5) fade(bg, 0.3, 1.5)
	elseif m == "chase" then fade(bg, 0.05, 0.4) fade(chase, 0.55, 0.4)
	else fade(bg, 0, 1.5) fade(chase, 0, 1.5) end
end

---------------------------------------------------------------- guide arrow (local only)
local arrow = Instance.new("Model") arrow.Name = "EscapeGuideArrow"
local function ap(name, size, color, shape)
	local p = Instance.new(shape == "wedge" and "WedgePart" or "Part") p.Name = name p.Size = size p.Color = color p.Material = Enum.Material.Neon
	p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false p.Parent = arrow
	return p
end
local shaft = ap("Shaft", Vector3.new(0.35, 0.35, 2.2), Color3.fromRGB(255, 220, 80))
local tip = ap("ArmLeft", Vector3.new(0.4, 0.4, 1.4), Color3.fromRGB(255, 220, 80))
local tip2 = ap("ArmRight", Vector3.new(0.4, 0.4, 1.4), Color3.fromRGB(255, 220, 80))
local tag = Instance.new("BillboardGui") tag.Size = UDim2.fromOffset(200, 34) tag.StudsOffset = Vector3.new(0, 1.3, 0) tag.AlwaysOnTop = true tag.LightInfluence = 0 tag.Parent = shaft
local tagText = label(tag, "Text", UDim2.fromScale(1, 1), UDim2.new(), Enum.Font.GothamBlack, Color3.new(1, 1, 1), 18, Enum.TextXAlignment.Center)
tagText.TextStrokeTransparency = 0.2
local target = nil   -- { pos =, name =, color = }
local keysState = {}
local gatePos = nil
local active = false

local function chooseTarget()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local best, bd
	local missing = 0
	for _, k in ipairs(keysState) do
		if not k.got and k.pos then
			missing += 1
			local d = (k.pos - root.Position).Magnitude + math.abs(k.pos.Y - root.Position.Y) * 2
			if not bd or d < bd then best, bd = k, d end
		end
	end
	if best then return { pos = best.pos, name = "🔑 " .. best.name, color = best.color, hint = best.hint } end
	if missing == 0 and gatePos and #keysState > 0 then return { pos = gatePos, name = "🔓 MAIN GATE", color = Color3.fromRGB(90, 230, 130), hint = "1F • Main Gate" } end
	return nil
end

RunService.RenderStepped:Connect(function()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not active or not target or not root then arrow.Parent = nil return end
	arrow.Parent = workspace.CurrentCamera
	local from = root.Position + Vector3.new(0, 4.2, 0)
	local flatTarget = Vector3.new(target.pos.X, from.Y, target.pos.Z)
	local dir = flatTarget - from
	if dir.Magnitude < 0.5 then dir = root.CFrame.LookVector end
	local cf = CFrame.lookAt(from, from + dir.Unit) * CFrame.new(0, 0, math.sin(os.clock() * 4) * 0.2)
	shaft.CFrame = cf
	-- chevron head: two arms angled back from the tip (the arrow points along -Z)
	tip.CFrame = cf * CFrame.new(0, 0, -1.1) * CFrame.Angles(0, math.rad(35), 0) * CFrame.new(0, 0, 0.6)
	tip2.CFrame = cf * CFrame.new(0, 0, -1.1) * CFrame.Angles(0, math.rad(-35), 0) * CFrame.new(0, 0, 0.6)
	for _, p in ipairs({ shaft, tip, tip2 }) do p.Color = target.color end
	local dist = (target.pos - root.Position).Magnitude
	local floors = math.floor((target.pos.Y - root.Position.Y) / 14 + 0.5)
	local up = floors > 0 and ("  ⬆️ " .. floors .. " floor" .. (floors > 1 and "s" or "") .. " up") or (floors < 0 and ("  ⬇️ " .. -floors .. " floor" .. (floors < -1 and "s" or "") .. " down") or "")
	tagText.Text = ("%s • %dm%s"):format(target.name, math.floor(dist), up)
	tagText.TextColor3 = target.color
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		if active then
			target = chooseTarget()
			if target then nextLine.Text = "🧭 " .. target.name .. "  ·  " .. (target.hint or "") end
		end
	end
end)

---------------------------------------------------------------- messages
local function stopAll()
	active = false panel.Visible = false alert.Visible = false arrow.Parent = nil target = nil
	setMode("off")
end

Remotes.EventData.OnClientEvent:Connect(function(d)
	if type(d) ~= "table" or d.event ~= "EscapeSchool" then return end
	if d.type == "keys" then
		if d.hide then stopAll() return end
		if not active or #keysState ~= #d.keys then buildGrid(d.keys) end
		active = not d.escaped
		panel.Visible = true
		keysState = d.keys
		gatePos = d.gate
		local got = 0
		for _, k in ipairs(d.keys) do setChip(k) if k.got then got += 1 end end
		head.Text = d.escaped and "🏃 YOU ESCAPED!" or (got == #d.keys and "🗝️ ALL KEYS! → MAIN GATE" or ("🗝️ TEAM KEYS  %d / %d"):format(got, #d.keys))
		target = chooseTarget()
		if d.music and mode == "off" then setMode("calm") end
		if d.gotKey then
			local k for _, x in ipairs(d.keys) do if x.id == d.gotKey then k = x end end
			keySfx:Play()
			pop.Text = ("🔑 %s KEY!%s"):format(k and string.upper(k.name) or d.gotKey, d.byMe and "" or ("\nfound by " .. tostring(d.by)))
			pop.TextColor3 = k and k.color or Color3.new(1, 1, 1)
			pop.Visible = true popScale.Scale = 0.3
			TweenService:Create(popScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			flash.BackgroundColor3 = k and k.color or Color3.new(1, 1, 1) flash.BackgroundTransparency = 0.6
			TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
			if chips[d.gotKey] then
				local f = chips[d.gotKey].frame
				TweenService:Create(chips[d.gotKey].stroke, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 6, true), { Thickness = 4 }):Play()
			end
			task.delay(1.8, function() pop.Visible = false end)
		end
		if d.escapedNow then
			showAlert(("🏃 YOU ESCAPED! #%d"):format(d.place or 1), Color3.fromRGB(40, 150, 80), 4)
			setMode("off") arrow.Parent = nil
		end
	elseif d.type == "spotted" then
		stinger:Play()
		setMode("chase")
		showAlert(("👀 SPOTTED BY A %s! RUN!"):format(string.upper(d.by or "guard")), Color3.fromRGB(200, 40, 40), 2.5)
	elseif d.type == "lost" then
		setMode("calm")
		showAlert("😮‍💨 You lost them…", Color3.fromRGB(60, 110, 190), 2)
	elseif d.type == "caught" then
		setMode("calm")
		local ends = os.clock() + (d.seconds or 8)
		alertToken += 1
		local my = alertToken
		task.spawn(function()
			while os.clock() < ends and alertToken == my do
				alert.Visible = true alert.BackgroundColor3 = Color3.fromRGB(120, 60, 160)
				alert.Text = ("🚨 CAUGHT by a %s! Detention: %d"):format(string.lower(d.by or "guard"), math.ceil(ends - os.clock()))
				task.wait(0.2)
			end
			if alertToken == my then alert.Visible = false end
		end)
	end
end)

Remotes.EventState.OnClientEvent:Connect(function(s)
	if not s.active or s.id ~= "EscapeSchool" or s.phase == "Results" then stopAll() end
end)
