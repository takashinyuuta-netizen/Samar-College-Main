-- LevelClient: XP pop-ups, level-up celebration, milestone rewards and the level badge on the Profile button.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local gui = script.Parent
local XP = require(RS:WaitForChild("Events"):WaitForChild("XPConfig"))
local remote = RS.Events:WaitForChild("EventRemotes"):WaitForChild("XPGain")

local function new(cls, props, parent) local o = Instance.new(cls) for k, v in pairs(props) do o[k] = v end o.Parent = parent return o end
local function corner(p, r) return new("UICorner", { CornerRadius = r or UDim.new(1, 0) }, p) end
local function tw(o, t, props, style) local x = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props) x:Play() return x end
local scale = new("UIScale", {}, gui)
local function rescale() local v = gui.AbsoluteSize if v.Y > 2 then scale.Scale = math.clamp(v.Y / 720, 0.6, 1) end end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale) rescale()
local function sfx(id, vol)
	local s = new("Sound", { SoundId = "rbxassetid://" .. id, Volume = vol or 0.6 }, SoundService)
	local grp = SoundService:FindFirstChild("SFX") if grp then s.SoundGroup = grp end
	s:Play() Debris:AddItem(s, 8)
end

-- XP toast (bottom centre, above the hotbar)
local bar = new("Frame", { Name = "XPToast", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -150), Size = UDim2.fromOffset(340, 58),
	BackgroundColor3 = Color3.fromRGB(22, 24, 32), BackgroundTransparency = 0.08, Visible = false }, gui)
corner(bar, UDim.new(0, 14))
local bstroke = new("UIStroke", { Color = Color3.fromRGB(245, 195, 60), Thickness = 1.6 }, bar)
local badge = new("TextLabel", { Size = UDim2.fromOffset(44, 44), Position = UDim2.fromOffset(8, 7), BackgroundColor3 = Color3.fromRGB(245, 195, 60),
	Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = Color3.fromRGB(30, 30, 30), Text = "1" }, bar)
corner(badge)
local title = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(62, 6), Size = UDim2.new(1, -70, 0, 20), Font = Enum.Font.GothamBold,
	TextSize = 14, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "" }, bar)
local track = new("Frame", { Position = UDim2.fromOffset(62, 32), Size = UDim2.new(1, -120, 0, 12), BackgroundColor3 = Color3.fromRGB(55, 58, 72) }, bar)
corner(track)
local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(245, 195, 60) }, track)
corner(fill)
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(240, 160, 40)) }, fill)
local pct = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 29), Size = UDim2.fromOffset(52, 18),
	Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(200, 205, 220), Text = "" }, bar)
local gain = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -4), Size = UDim2.fromOffset(200, 30),
	Font = Enum.Font.GothamBlack, TextSize = 26, TextColor3 = Color3.fromRGB(255, 215, 80), TextStrokeTransparency = 0.4, Text = "" }, bar)
local function showLevel(lvl, into, need)
	local tier = XP.tierOf(lvl)
	badge.Text = tostring(lvl) badge.BackgroundColor3 = tier.color bstroke.Color = tier.color
	pct.Text = (need == 0) and "MAX" or (math.floor(into / need * 100) .. "%")
end
local hideToken = 0
local function toast(info)
	hideToken += 1
	local my = hideToken
	local total = info.total or (player:GetAttribute("XP") or 0)
	local lvl, into, need = XP.fromXP(total)
	local oldLvl, pInto, pNeed = XP.fromXP(total - (info.xp or 0))
	bar.Visible = true
	bar.Position = UDim2.new(0.5, 0, 1, -130)
	tw(bar, 0.35, { Position = UDim2.new(0.5, 0, 1, -150) }, Enum.EasingStyle.Back)
	if info.maxed then
		title.Text = "👑 Max level reached — Level 100!"
		showLevel(XP.MAX_LEVEL, 0, 0) fill.Size = UDim2.fromScale(1, 1) gain.Text = ""
	else
		title.Text = (info.reason and (info.reason .. "  •  ") or "") .. "Event Level " .. lvl
		gain.Text = "+" .. (info.xp or 0) .. " XP" gain.TextTransparency = 0 gain.Position = UDim2.new(0.5, 0, 0, -4)
		tw(gain, 1.6, { Position = UDim2.new(0.5, 0, 0, -26), TextTransparency = 0.2 })
		showLevel(oldLvl, pInto, pNeed)
		fill.Size = UDim2.fromScale(pNeed > 0 and pInto / pNeed or 1, 1)
		if lvl > oldLvl then
			tw(fill, 0.5, { Size = UDim2.fromScale(1, 1) })
			task.delay(0.55, function() fill.Size = UDim2.fromScale(0, 1) showLevel(lvl, into, need) tw(fill, 0.5, { Size = UDim2.fromScale(need > 0 and into / need or 1, 1) }) end)
		else
			tw(fill, 0.8, { Size = UDim2.fromScale(need > 0 and into / need or 1, 1) })
			task.delay(0.8, function() showLevel(lvl, into, need) end)
		end
		sfx(134821092416328, 0.45)
	end
	task.delay(5, function()
		if hideToken ~= my then return end
		tw(bar, 0.3, { Position = UDim2.new(0.5, 0, 1, -120) }).Completed:Wait()
		if hideToken == my then bar.Visible = false end
	end)
end

-- LEVEL UP celebration
local burst = new("Frame", { Name = "LevelUp", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(420, 190),
	BackgroundTransparency = 1, Visible = false }, gui)
local glow = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(200, 200),
	BackgroundColor3 = Color3.fromRGB(255, 215, 90), BackgroundTransparency = 0.7 }, burst)
corner(glow)
local rays = {}
for i = 0, 11 do
	rays[i] = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(10, 120), Rotation = i * 30,
		BackgroundColor3 = Color3.fromRGB(255, 225, 120), BackgroundTransparency = 0.55, BorderSizePixel = 0 }, burst)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, rays[i])
end
local medal = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(110, 110),
	BackgroundColor3 = Color3.fromRGB(245, 195, 60), Font = Enum.Font.GothamBlack, TextSize = 48, TextColor3 = Color3.fromRGB(35, 30, 20), Text = "2" }, burst)
corner(medal)
new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 5 }, medal)
local lvTxt = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.78), Size = UDim2.fromOffset(420, 40),
	Font = Enum.Font.GothamBlack, TextSize = 34, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.3, Text = "LEVEL UP!" }, burst)
local subTxt = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.78, 38), Size = UDim2.fromOffset(460, 24),
	Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(255, 225, 140), TextStrokeTransparency = 0.4, Text = "" }, burst)
local spin
local function celebrate(lvl, subtitle)
	local tier = XP.tierOf(lvl)
	medal.Text = tostring(lvl) medal.BackgroundColor3 = tier.color glow.BackgroundColor3 = tier.color
	for _, r in pairs(rays) do r.BackgroundColor3 = tier.color:Lerp(Color3.new(1, 1, 1), 0.4) end
	lvTxt.Text = (lvl >= XP.MAX_LEVEL) and "MAX LEVEL!" or "LEVEL UP!"
	subTxt.Text = subtitle or (tier.name .. " tier  •  Event Level " .. lvl)
	burst.Visible = true
	medal.Size = UDim2.fromOffset(20, 20) tw(medal, 0.5, { Size = UDim2.fromOffset(110, 110) }, Enum.EasingStyle.Back)
	lvTxt.TextTransparency = 1 tw(lvTxt, 0.4, { TextTransparency = 0 })
	subTxt.TextTransparency = 1 tw(subTxt, 0.6, { TextTransparency = 0 })
	if spin then spin:Disconnect() end
	local a = 0
	spin = game:GetService("RunService").RenderStepped:Connect(function(dt) a += dt * 40 for i, r in pairs(rays) do r.Rotation = i * 30 + a end end)
	for i = 1, 28 do
		local c = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(8, 12), Rotation = math.random(0, 360),
			BackgroundColor3 = ({ Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 210, 60), Color3.fromRGB(80, 200, 255), Color3.fromRGB(120, 230, 120), Color3.fromRGB(220, 120, 255) })[i % 5 + 1], BorderSizePixel = 0 }, burst)
		local ang = math.rad(math.random(0, 360)) local d = math.random(120, 260)
		tw(c, 1.4, { Position = UDim2.new(0.5, math.cos(ang) * d, 0.42, math.sin(ang) * d + 80), Rotation = c.Rotation + math.random(-360, 360), BackgroundTransparency = 1 })
		Debris:AddItem(c, 1.5)
	end
	sfx(112485797063762, 0.6)
	task.delay(3.4, function()
		tw(medal, 0.3, { Size = UDim2.fromOffset(10, 10) }) tw(lvTxt, 0.3, { TextTransparency = 1 }) tw(subTxt, 0.3, { TextTransparency = 1 })
		task.wait(0.32)
		burst.Visible = false
		if spin then spin:Disconnect() spin = nil end
	end)
end

-- level badge on the Profile button
local function attachBadge()
	local hud = player.PlayerGui:WaitForChild("MainHUD", 30)
	local btn = hud and hud:FindFirstChild("ProfileButton", true)
	if not btn then return end
	local old = btn:FindFirstChild("LevelBadge") if old then old:Destroy() end
	-- dark pill + white number so it reads on every tier; the tier colour is the ring around it
	local b = new("TextLabel", { Name = "LevelBadge", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 4, 0, -4), Size = UDim2.fromOffset(38, 26),
		BackgroundColor3 = Color3.fromRGB(22, 24, 32), BackgroundTransparency = 0, Font = Enum.Font.GothamBlack, TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 255, 255), TextStrokeTransparency = 1, Text = "1", ZIndex = 50 }, btn)
	corner(b, UDim.new(1, 0))
	new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, b)
	new("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = 18 }, b)
	local ring = new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Color3.fromRGB(245, 195, 60), Thickness = 2.5 }, b)
	local function upd()
		local lvl = player:GetAttribute("Lvl") or XP.fromXP(player:GetAttribute("XP") or 0)
		b.Text = (lvl >= XP.MAX_LEVEL) and "MAX" or tostring(lvl)
		ring.Color = XP.tierOf(lvl).color
	end
	upd()
	player:GetAttributeChangedSignal("Lvl"):Connect(upd)
	player:GetAttributeChangedSignal("XP"):Connect(upd)
end
task.spawn(attachBadge)

-- events from the server (queued so popups never overlap)
local queue, busy = {}, false
local function run()
	if busy then return end
	busy = true
	while #queue > 0 do
		local info = table.remove(queue, 1)
		if info.milestone then
			celebrate(info.level, ("%s %s unlocked!  +%d ⭐ Event coins"):format(info.icon or "🏅", info.name or "Achievement", info.coins or 0))
			task.wait(3.8)
		else
			toast(info)
			if info.level and info.oldLevel and info.level > info.oldLevel then task.wait(0.6) celebrate(info.level) task.wait(3.8)
			else task.wait(1) end
		end
	end
	busy = false
end
remote.OnClientEvent:Connect(function(info) table.insert(queue, info) task.spawn(run) end)
