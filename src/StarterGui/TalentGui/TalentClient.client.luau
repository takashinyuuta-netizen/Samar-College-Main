--[[ TalentClient — the Intramurals Talent Stage on the player's screen.
  • On stage: a stage panel  [💃 Dance] [🎤 Sing] [✅ Done]
  • 💃 Dance opens a DRAGGABLE emote window (Dance / Fun / Greet). Tap an emote to do it, or "+" to put it on
    your hotbar (temporary, player attribute "TempHotbar"). When you're done dancing (✅ Done, or leaving the stage)
    the emotes are removed from the hotbar again.
  • 🎤 Sing needs a mic (take one from a mic stand). Pick a backing track or "voice only".
  • Audience near the stage: "Now performing" bar + 👏 Cheer button.
  Talks to TalentShowServer through ReplicatedStorage.TalentShow.TalentEvent. ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent
local folder = RS:WaitForChild("TalentShow")
local ev = folder:WaitForChild("TalentEvent")
local Emotes = require(folder:WaitForChild("Emotes"))
local Library = require(RS:WaitForChild("Music"):WaitForChild("MusicLibrary"))

local BG, BG2, BG3 = Color3.fromRGB(24, 24, 32), Color3.fromRGB(42, 42, 55), Color3.fromRGB(56, 56, 72)
local STROKE, TEXT, MUTED = Color3.fromRGB(75, 75, 95), Color3.fromRGB(245, 245, 245), Color3.fromRGB(165, 165, 180)
local PINK, GOLD, GREEN = Color3.fromRGB(235, 70, 150), Color3.fromRGB(255, 200, 70), Color3.fromRGB(20, 140, 100)

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function corner(o, r) mk("UICorner", { CornerRadius = UDim.new(0, r or 10) }, o) end
local function stroke(o, c, th) return mk("UIStroke", { Color = c or STROKE, Thickness = th or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o) end
local function label(parent, props)
	local l = mk("TextLabel", { BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextColor3 = TEXT, TextSize = 14 }, parent)
	for k, v in pairs(props) do l[k] = v end
	return l
end
local function button(parent, text, props)
	local b = mk("TextButton", { Text = text, BackgroundColor3 = BG2, AutoButtonColor = true, Font = Enum.Font.GothamBold, TextColor3 = TEXT, TextSize = 14, BorderSizePixel = 0 }, parent)
	for k, v in pairs(props) do b[k] = v end
	corner(b, 10)
	return b
end

-- scale like the rest of the HUD
local uiScale = mk("UIScale", {}, gui)
task.spawn(function()
	local hud = player:WaitForChild("PlayerGui"):WaitForChild("MainHUD", 20)
	local s = hud and hud:FindFirstChild("AutoScale")
	if s then uiScale.Scale = s.Scale s:GetPropertyChangedSignal("Scale"):Connect(function() uiScale.Scale = s.Scale end) end
end)

-- toast
local toast = label(gui, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 110), Size = UDim2.fromOffset(520, 40), BackgroundColor3 = BG,
	BackgroundTransparency = 0.08, TextSize = 14, TextWrapped = true, Visible = false, ZIndex = 30 })
corner(toast, 20) stroke(toast, PINK, 1.5)
local toastTok = 0
local function showToast(text)
	toastTok += 1 local my = toastTok
	toast.Text = text toast.Visible = true
	task.delay(3.6, function() if my == toastTok then toast.Visible = false end end)
end

-- makes a window draggable by its title bar
local function draggable(win, handle)
	local dragging, startPos, startInput
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, startPos, startInput = true, win.Position, i.Position
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = (i.Position - startInput) / uiScale.Scale
			win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end
local function window(name, title, size, pos)
	local w = mk("Frame", { Name = name, Size = size, Position = pos, BackgroundColor3 = BG, Visible = false, Active = true }, gui)
	corner(w, 16) stroke(w, PINK, 1.5)
	local bar = mk("Frame", { Name = "TitleBar", Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Color3.fromRGB(60, 20, 70), Active = true }, w)
	corner(bar, 16)
	mk("Frame", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), BackgroundColor3 = Color3.fromRGB(60, 20, 70), BorderSizePixel = 0 }, bar)
	label(bar, { Text = title, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -110, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 15 })
	label(bar, { Text = "drag", Position = UDim2.new(1, -110, 0, 0), Size = UDim2.fromOffset(60, 40), TextColor3 = MUTED, TextSize = 11, Font = Enum.Font.GothamMedium })
	local x = button(bar, "X", { Position = UDim2.new(1, -38, 0, 6), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = BG2, TextSize = 13 })
	x.MouseButton1Click:Connect(function() w.Visible = false end)
	draggable(w, bar)
	return w
end

---------------------------------------------------------------- state
local stageState = { active = false, performers = {}, cheers = 0 }
local function performing() return player:GetAttribute("SC_Performing") end
local function onStage() return player:GetAttribute("SC_OnStage") == true end
local function hasMic() return player:GetAttribute("SC_HasMic") ~= nil end

-- temporary hotbar emotes (HotbarClient shows them after your equipped items)
local function tempList()
	local t = {}
	for id in string.gmatch(player:GetAttribute("TempHotbar") or "", "[^,]+") do table.insert(t, id) end
	return t
end
local function setTemp(t) player:SetAttribute("TempHotbar", #t > 0 and table.concat(t, ",") or nil) end
local function toggleTemp(id)
	local t = tempList()
	local i = table.find(t, id)
	if i then table.remove(t, i) else
		if #t >= 6 then showToast("You can put up to 6 emotes on the hotbar") return end
		table.insert(t, id)
	end
	setTemp(t)
end

---------------------------------------------------------------- stage panel (right side)
local panel = mk("Frame", { Name = "StagePanel", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 40), Size = UDim2.fromOffset(210, 214), BackgroundColor3 = BG, Visible = false }, gui)
corner(panel, 16) stroke(panel, PINK, 2)
mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(205, 190, 225)) }, panel)
label(panel, { Text = "🎤 YOU'RE ON STAGE", Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 22), TextSize = 15, TextColor3 = GOLD })
local panelSub = label(panel, { Text = "", Position = UDim2.fromOffset(10, 30), Size = UDim2.new(1, -20, 0, 30), TextSize = 11, TextColor3 = MUTED, TextWrapped = true, Font = Enum.Font.GothamMedium })
local danceBtn = button(panel, "💃  Dance", { Position = UDim2.fromOffset(12, 66), Size = UDim2.new(1, -24, 0, 40), BackgroundColor3 = Color3.fromRGB(150, 50, 170), TextSize = 16 })
local singBtn = button(panel, "🎤  Sing", { Position = UDim2.fromOffset(12, 112), Size = UDim2.new(1, -24, 0, 40), BackgroundColor3 = Color3.fromRGB(200, 60, 110), TextSize = 16 })
local doneBtn = button(panel, "✅  Done", { Position = UDim2.fromOffset(12, 160), Size = UDim2.new(1, -24, 0, 40), BackgroundColor3 = GREEN, TextSize = 16 })

---------------------------------------------------------------- emote window (draggable)
local emoteWin = window("EmoteWindow", "💃 Emotes — tap to dance, + to add to hotbar", UDim2.fromOffset(460, 400), UDim2.new(0.5, -230, 0.5, -230))
local tabs = mk("Frame", { Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 0, 32), BackgroundTransparency = 1 }, emoteWin)
mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, tabs)
local grid = mk("ScrollingFrame", { Position = UDim2.fromOffset(12, 88), Size = UDim2.new(1, -24, 1, -134), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, emoteWin)
mk("UIGridLayout", { CellSize = UDim2.fromOffset(100, 78), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
label(emoteWin, { Text = "Emotes you add stay on your hotbar while you dance • ✅ Done removes them", Position = UDim2.new(0, 12, 1, -40), Size = UDim2.new(1, -24, 0, 32),
	TextSize = 11, TextColor3 = MUTED, TextWrapped = true, Font = Enum.Font.GothamMedium })
local emoteTab = "Dance"
local tabBtns = {}
local renderEmotes
for _, c in ipairs(Emotes.Categories) do
	local b = button(tabs, c.icon .. " " .. c.name, { Size = UDim2.fromOffset(110, 32), TextSize = 13 })
	tabBtns[c.id] = b
	b.MouseButton1Click:Connect(function() emoteTab = c.id renderEmotes() end)
end
renderEmotes = function()
	for id, b in pairs(tabBtns) do b.BackgroundColor3 = id == emoteTab and PINK or BG2 end
	for _, c in ipairs(grid:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local temp = tempList()
	for i, e in ipairs(Emotes.List) do
		if e.cat == emoteTab then
			local cell = button(grid, "", { LayoutOrder = i, BackgroundColor3 = BG2 })
			label(cell, { Text = e.icon, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 4), TextSize = 28 })
			label(cell, { Text = e.name, Size = UDim2.new(1, -6, 0, 18), Position = UDim2.fromOffset(3, 50), TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd })
			local added = table.find(temp, e.id) ~= nil
			local add = button(cell, added and "✓" or "+", { Position = UDim2.new(1, -26, 0, 4), Size = UDim2.fromOffset(22, 22), TextSize = 13,
				BackgroundColor3 = added and GREEN or BG3 })
			cell.MouseButton1Click:Connect(function() Emotes.play(player.Character, e.id) end)
			add.MouseButton1Click:Connect(function() toggleTemp(e.id) renderEmotes() end)
		end
	end
end

---------------------------------------------------------------- sing window (draggable)
local SING_CATS = { "Vocal", "OPMKilig", "OPMHugot", "OPMChill", "Anime", "JPop", "KPop", "CPop", "Relapse", "Happy" }
local singWin = window("SingWindow", "🎤 Sing — pick a backing track", UDim2.fromOffset(460, 430), UDim2.new(0.5, -230, 0.5, -250))
local catRow = mk("ScrollingFrame", { Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 0, 36), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X }, singWin)
mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, catRow)
local songList = mk("ScrollingFrame", { Position = UDim2.fromOffset(12, 92), Size = UDim2.new(1, -24, 1, -186), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, singWin)
mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, songList)
local voiceBtn = button(singWin, "🎙️ Voice only", { Position = UDim2.new(0, 12, 1, -86), Size = UDim2.new(0.33, -12, 0, 36), BackgroundColor3 = BG3, TextSize = 13 })
local stopBtn = button(singWin, "⏹️ Stop song", { Position = UDim2.new(0.33, 4, 1, -86), Size = UDim2.new(0.33, -8, 0, 36), BackgroundColor3 = Color3.fromRGB(150, 55, 65), TextSize = 13 })
local retBtn = button(singWin, "🔙 Return mic", { Position = UDim2.new(0.66, 4, 1, -86), Size = UDim2.new(0.34, -16, 0, 36), BackgroundColor3 = BG2, TextSize = 13 })
label(singWin, { Text = "The song plays through the stage speakers for everyone nearby. Voice chat on? You can sing live!", Position = UDim2.new(0, 12, 1, -44), Size = UDim2.new(1, -24, 0, 36),
	TextSize = 11, TextColor3 = MUTED, TextWrapped = true, Font = Enum.Font.GothamMedium })
local singCat = "Vocal"
local catBtns = {}
local renderSongs
local catById = {}
for _, c in ipairs(Library.Categories) do catById[c.id] = c end
for _, id in ipairs(SING_CATS) do
	local c = catById[id]
	if c then
		local b = button(catRow, c.icon .. " " .. c.name, { Size = UDim2.fromOffset(120, 30), TextSize = 12 })
		catBtns[id] = b
		b.MouseButton1Click:Connect(function() singCat = id renderSongs() end)
	end
end
renderSongs = function()
	for id, b in pairs(catBtns) do b.BackgroundColor3 = id == singCat and PINK or BG2 end
	for _, c in ipairs(songList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local n = 0
	for _, s in ipairs(Library.Songs) do
		if s.cat == singCat then
			n += 1
			local row = button(songList, "", { LayoutOrder = n, Size = UDim2.new(1, -6, 0, 40), BackgroundColor3 = BG2 })
			label(row, { Text = "🎵 " .. s.title, Position = UDim2.fromOffset(12, 3), Size = UDim2.new(1, -90, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd })
			label(row, { Text = s.artist, Position = UDim2.fromOffset(12, 21), Size = UDim2.new(1, -90, 0, 15), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 11, TextColor3 = MUTED, Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.AtEnd })
			label(row, { Text = "▶ Sing", Position = UDim2.new(1, -76, 0, 0), Size = UDim2.new(0, 66, 1, 0), TextSize = 12, TextColor3 = GOLD })
			row.MouseButton1Click:Connect(function()
				ev:FireServer({ a = "sing", song = s.id })
				singWin.Visible = false
			end)
		end
	end
end
voiceBtn.MouseButton1Click:Connect(function() ev:FireServer({ a = "sing", song = "voice" }) singWin.Visible = false end)
stopBtn.MouseButton1Click:Connect(function() ev:FireServer({ a = "stopsing" }) end)
retBtn.MouseButton1Click:Connect(function() ev:FireServer({ a = "returnmic" }) singWin.Visible = false end)

---------------------------------------------------------------- audience bar
local aud = mk("Frame", { Name = "AudienceBar", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(470, 56), BackgroundColor3 = BG, BackgroundTransparency = 0.05, Visible = false }, gui)
corner(aud, 28) stroke(aud, PINK, 1.5)
aud.Size = UDim2.fromOffset(560, 56)
local audText = label(aud, { Text = "", Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -262, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 13, TextWrapped = true })
local watchBtn = button(aud, "👀 Watch", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -132, 0.5, 0), Size = UDim2.fromOffset(110, 42), BackgroundColor3 = Color3.fromRGB(60, 120, 220), TextSize = 16 })
corner(watchBtn, 21)
local cheerBtn = button(aud, "👏 Cheer", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(118, 42), BackgroundColor3 = PINK, TextSize = 17 })
corner(cheerBtn, 21)

---------------------------------------------------------------- 👀 WATCH (spectate the performers from anywhere)
local camera = workspace.CurrentCamera
local watching = false
local watchIndex = 1
local watchTarget = nil
local camPos, camLook = nil, nil
local watchBar = mk("Frame", { Name = "WatchBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -128), Size = UDim2.fromOffset(470, 58), BackgroundColor3 = BG, BackgroundTransparency = 0.05, Visible = false }, gui)
corner(watchBar, 29) stroke(watchBar, Color3.fromRGB(60, 120, 220), 2)
local prevBtn = button(watchBar, "◀", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.fromOffset(42, 42), TextSize = 16 })
corner(prevBtn, 21)
local watchText = label(watchBar, { Text = "", Position = UDim2.fromOffset(58, 0), Size = UDim2.new(1, -230, 1, 0), TextSize = 14, TextWrapped = true })
local nextBtn = button(watchBar, "▶", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -170, 0.5, 0), Size = UDim2.fromOffset(42, 42), TextSize = 16 })
corner(nextBtn, 21)
local cheer2 = button(watchBar, "👏", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -116, 0.5, 0), Size = UDim2.fromOffset(46, 42), BackgroundColor3 = PINK, TextSize = 18 })
corner(cheer2, 21)
local stopWatch = button(watchBar, "X Stop", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(100, 42), BackgroundColor3 = Color3.fromRGB(150, 55, 65), TextSize = 14 })
corner(stopWatch, 21)

local function performerPlayers()
	local list = {}
	for _, e in ipairs(stageState.performers or {}) do
		local p = Players:GetPlayerByUserId(e.userId)
		if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then table.insert(list, { player = p, info = e }) end
	end
	return list
end
local function setWatching(on)
	if watching == on then return end
	watching = on
	ev:FireServer({ a = "watch", on = on })
	watchBar.Visible = on
	if on then
		camPos, camLook = camera.CFrame.Position, camera.CFrame.Position + camera.CFrame.LookVector * 10
		camera.CameraType = Enum.CameraType.Scriptable
	else
		camera.CameraType = Enum.CameraType.Custom
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then camera.CameraSubject = hum end
	end
end
watchBtn.MouseButton1Click:Connect(function() setWatching(not watching) end)
stopWatch.MouseButton1Click:Connect(function() setWatching(false) end)
prevBtn.MouseButton1Click:Connect(function() watchIndex -= 1 end)
nextBtn.MouseButton1Click:Connect(function() watchIndex += 1 end)

game:GetService("RunService").RenderStepped:Connect(function(dt)
	if not watching then return end
	local list = performerPlayers()
	if #list == 0 or not stageState.active then
		setWatching(false)
		showToast("🎤 The performance ended — back to you!")
		return
	end
	if watchIndex < 1 then watchIndex = #list elseif watchIndex > #list then watchIndex = 1 end
	local e = list[watchIndex]
	watchTarget = e.player
	local hrp = e.player.Character.HumanoidRootPart
	local head = e.player.Character:FindFirstChild("Head")
	local focus = (head and head.Position or hrp.Position + Vector3.new(0, 1.5, 0)) - Vector3.new(0, 0.6, 0)
	-- audience view: in front of the stage (the stage faces -X), slowly drifting left/right like a TV camera
	local t = os.clock()
	local side = math.sin(t * 0.25) * 7
	local want = focus + Vector3.new(-13 - math.sin(t * 0.17) * 2, 3.5, side)
	local k = math.min(1, dt * 3)
	camPos = camPos:Lerp(want, k)
	camLook = camLook:Lerp(focus, math.min(1, dt * 5))
	camera.CFrame = CFrame.lookAt(camPos, camLook)
	watchText.Text = ("👀 Watching %s  %s\n%s"):format(e.info.name, e.info.mode == "sing" and "🎤 singing" or "💃 dancing",
		(e.info.mode == "sing" and stageState.song) and ("🎵 " .. stageState.song) or (#list > 1 and ("◀ ▶ switch performer (" .. watchIndex .. "/" .. #list .. ")") or ""))
end)
-- walking or jumping takes you out of watch mode
UIS.InputBegan:Connect(function(i, processed)
	if watching and not processed and (i.KeyCode == Enum.KeyCode.W or i.KeyCode == Enum.KeyCode.A or i.KeyCode == Enum.KeyCode.S or i.KeyCode == Enum.KeyCode.D or i.KeyCode == Enum.KeyCode.Space) then
		setWatching(false)
	end
end)
local floaters = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 74), Size = UDim2.fromOffset(300, 120), BackgroundTransparency = 1 }, gui)
local cheerCooldown = 0
local function doCheer(btn)
	if os.clock() < cheerCooldown then return end
	cheerCooldown = os.clock() + 1.2
	ev:FireServer({ a = "cheer" })
	local sc = btn:FindFirstChildOfClass("UIScale") or mk("UIScale", {}, btn)
	sc.Scale = 0.85 TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end
cheerBtn.MouseButton1Click:Connect(function() doCheer(cheerBtn) end)
cheer2.MouseButton1Click:Connect(function() doCheer(cheer2) end)
local function floater(text)
	local l = label(floaters, { Text = text, Position = UDim2.new(math.random(10, 70) / 100, 0, 0, 90), Size = UDim2.fromOffset(160, 22), TextSize = 14, TextColor3 = GOLD, TextStrokeTransparency = 0.5 })
	TweenService:Create(l, TweenInfo.new(1.6), { Position = l.Position - UDim2.fromOffset(0, 90), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	game:GetService("Debris"):AddItem(l, 1.7)
end

---------------------------------------------------------------- refresh
local function refresh()
	-- stage panel
	local on = onStage() and stageState.active
	panel.Visible = on or performing() ~= nil
	local mode = performing()
	if mode == "dance" then panelSub.Text = "💃 Dancing — the crowd can cheer for you!"
	elseif mode == "sing" then panelSub.Text = "🎤 Singing — " .. (stageState.song or "voice only")
	else panelSub.Text = hasMic() and "You have the mic — press Sing!" or "Take a mic from a stand to sing" end
	singBtn.BackgroundColor3 = hasMic() and Color3.fromRGB(200, 60, 110) or BG3
	doneBtn.Visible = mode ~= nil
	panel.Size = UDim2.fromOffset(210, mode and 214 or 166)
	-- audience bar
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local near = stageState.active and stageState.pos and hrp and (hrp.Position - stageState.pos).Magnitude < 120
	local list = stageState.performers or {}
	-- the "now performing" bar shows anywhere on campus while someone performs (watch from far away)
	aud.Visible = stageState.active and #list > 0 and mode == nil and not watching
	if aud.Visible then
		local names = {}
		for _, e in ipairs(list) do table.insert(names, (e.mode == "sing" and "🎤 " or "💃 ") .. e.name) end
		audText.Text = "🔴 LIVE ON STAGE: " .. table.concat(names, ", ") .. (stageState.song and ("\n🎵 " .. stageState.song) or "")
			.. "   👏 " .. (stageState.cheers or 0) .. ((stageState.watchers or 0) > 0 and ("  👀 " .. stageState.watchers) or "")
		-- cheering works near the stage or while watching
		cheerBtn.Visible = near
		watchBtn.Position = near and UDim2.new(1, -132, 0.5, 0) or UDim2.new(1, -8, 0.5, 0)
	end
	if mode ~= nil and watching then setWatching(false) end
	-- turn your own playlist down while a song plays live on the stage near you
	player:SetAttribute("SC_NearLiveStage", (near and stageState.song ~= nil) or nil)
end

danceBtn.MouseButton1Click:Connect(function()
	ev:FireServer({ a = "dance" })
	singWin.Visible = false
	emoteWin.Visible = true
	renderEmotes()
end)
singBtn.MouseButton1Click:Connect(function()
	if not hasMic() then showToast("🎤 You need a mic — walk to a mic stand and take one") return end
	emoteWin.Visible = false
	singWin.Visible = true
	renderSongs()
end)
local function clearDance()
	setTemp({})
	Emotes.stop(player.Character)
	emoteWin.Visible = false
end
doneBtn.MouseButton1Click:Connect(function()
	local mode = performing()
	if mode == "dance" then ev:FireServer({ a = "dancedone" }) end
	if mode == "sing" then ev:FireServer({ a = "stopsing" }) end
	clearDance()
	singWin.Visible = false
end)

-- dance over (Done, left the stage, Intramurals ended): take the emotes off the hotbar
player:GetAttributeChangedSignal("SC_Performing"):Connect(function()
	if performing() ~= "dance" and player:GetAttribute("TempHotbar") then
		clearDance()
		showToast("💃 Dance over — your emotes were removed from the hotbar")
	end
	refresh()
end)
for _, a in ipairs({ "SC_OnStage", "SC_HasMic", "TempHotbar" }) do
	player:GetAttributeChangedSignal(a):Connect(function()
		if a == "TempHotbar" and emoteWin.Visible then renderEmotes() end
		if a == "SC_OnStage" and not onStage() then singWin.Visible = false end
		refresh()
	end)
end

ev.OnClientEvent:Connect(function(msg)
	if type(msg) ~= "table" then return end
	if msg.t == "state" then
		stageState = msg
		if not msg.active then clearDance() singWin.Visible = false end
		refresh()
	elseif msg.t == "toast" then
		showToast(msg.text)
	elseif msg.t == "cheer" then
		stageState.cheers = (stageState.cheers or 0) + 1
		if aud.Visible or performing() or watching then floater("👏 " .. tostring(msg.from)) end
		refresh()
	end
end)
task.spawn(function() while true do task.wait(1) refresh() end end)
refresh()
