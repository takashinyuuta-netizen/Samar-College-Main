--[[ IntramuralsPopup — when the event rotation picks 🏆 Intramurals, the sports venues appear and this
  pop-up shows every player the games that just opened (with a "Take me there" button).
  The server sets workspace attribute "IntramuralsActive" (SportsServer). ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local gui = script.Parent

local DARK, GOLD, WHITE = Color3.fromRGB(20, 25, 34), Color3.fromRGB(255, 210, 90), Color3.new(1, 1, 1)
local function new(class, props, parent) local o = Instance.new(class) for k, v in pairs(props or {}) do o[k] = v end o.Parent = parent return o end
local function corner(p, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 10) }, p) end
local function label(parent, props)
	local t = new("TextLabel", { BackgroundTransparency = 1, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextScaled = true }, parent)
	for k, v in pairs(props) do if k ~= "MaxSize" then t[k] = v end end
	new("UITextSizeConstraint", { MaxTextSize = props.MaxSize or 18 }, t)
	return t
end

local GAMES = {
	{ "🏸", "Badminton", "1F Hall", Color3.fromRGB(60, 200, 140) },
	{ "🏓", "Table Tennis", "Sky Island", Color3.fromRGB(250, 170, 60) },
	{ "🥒", "Pickleball", "Sky Island", Color3.fromRGB(150, 210, 60) },
	{ "🏐", "Volleyball", "Sky Island", Color3.fromRGB(70, 150, 255) },
	{ "🏀", "Basketball 3v3", "Sky Island", Color3.fromRGB(235, 95, 45) },
	{ "🏀", "Basketball 5v5", "Sky Arena", Color3.fromRGB(255, 150, 40) },
	{ "♟️", "Chess", "2F Library", Color3.fromRGB(170, 120, 230) },
	{ "🎤", "Talent Stage", "1F Hall stage", Color3.fromRGB(235, 70, 150) },
}

-- dim background + card
local shade = new("Frame", { Name = "IntramuralsShade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 40 }, gui)
local card = new("Frame", { Name = "IntramuralsPopup", Size = UDim2.fromOffset(560, 380), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = DARK, ZIndex = 41 }, shade)
corner(card, 18)
local stroke = new("UIStroke", { Color = GOLD, Thickness = 3 }, card)
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(30, 40, 58), Color3.fromRGB(16, 20, 28)), Rotation = 90 }, card)
local scale = new("UIScale", { Scale = 1 }, card)

local trophy = label(card, { Text = "🏆", Size = UDim2.fromOffset(70, 60), Position = UDim2.new(0.5, -35, 0, 6), MaxSize = 50, ZIndex = 42 })
local title = label(card, { Text = "INTRAMURALS IS NOW OPEN!", Size = UDim2.new(1, -40, 0, 34), Position = UDim2.fromOffset(20, 64), Font = Enum.Font.GothamBlack, TextColor3 = GOLD, MaxSize = 30, ZIndex = 42 })
label(card, { Text = "⭐ Rare event — DOUBLE coins on every game! Walk into a door in the 1F hall to play.", Size = UDim2.new(1, -40, 0, 20), Position = UDim2.fromOffset(20, 100), Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(215, 222, 232), MaxSize = 15, ZIndex = 42 })

local grid = new("Frame", { Size = UDim2.new(1, -40, 0, 170), Position = UDim2.fromOffset(20, 130), BackgroundTransparency = 1, ZIndex = 42 }, card)
new("UIGridLayout", { CellSize = UDim2.new(0.25, -8, 0.5, -8), CellPadding = UDim2.fromOffset(8, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, grid)
local tiles = {}
for i, g in ipairs(GAMES) do
	local t = new("Frame", { BackgroundColor3 = Color3.fromRGB(34, 42, 58), LayoutOrder = i, ZIndex = 42 }, grid)
	corner(t, 12)
	new("UIStroke", { Color = g[4], Thickness = 2, Transparency = 0.2 }, t)
	label(t, { Text = g[1], Size = UDim2.new(1, 0, 0.48, 0), Position = UDim2.fromScale(0, 0.04), MaxSize = 30, ZIndex = 43 })
	label(t, { Text = g[2], Size = UDim2.new(1, -8, 0.24, 0), Position = UDim2.new(0, 4, 0.5, 0), Font = Enum.Font.GothamBlack, TextColor3 = g[4], MaxSize = 15, ZIndex = 43 })
	label(t, { Text = g[3], Size = UDim2.new(1, -8, 0.2, 0), Position = UDim2.new(0, 4, 0.75, 0), Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(170, 180, 195), MaxSize = 12, ZIndex = 43 })
	tiles[i] = t
end

local function btn(text, color, x, w)
	local b = new("TextButton", { Text = text, Size = UDim2.fromOffset(w, 44), Position = UDim2.new(0.5, x, 1, -60), BackgroundColor3 = color, TextColor3 = WHITE, Font = Enum.Font.GothamBlack, TextScaled = true, ZIndex = 42 }, card)
	corner(b, 12) new("UITextSizeConstraint", { MaxTextSize = 18 }, b) new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, b)
	return b
end
local goBtn = btn("📍 Take me there", Color3.fromRGB(60, 160, 90), -200, 230)
local laterBtn = btn("Later", Color3.fromRGB(80, 86, 100), 40, 160)
local timer = label(card, { Text = "", Size = UDim2.fromOffset(120, 14), Position = UDim2.new(1, -130, 1, -16), Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(140, 150, 165), MaxSize = 11, ZIndex = 42 })

-- phones: shrink to fit
local function fit()
	local vp = workspace.CurrentCamera.ViewportSize
	scale.Scale = math.clamp(math.min((vp.X - 24) / 560, (vp.Y - 24) / 380), 0.5, 1.1)
end
fit() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

local shownToken = 0
local function hide()
	shownToken += 1
	if not shade.Visible then return end
	TweenService:Create(shade, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	local tw = TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.fromScale(0.5, 1.4) })
	tw:Play()
	tw.Completed:Wait()
	shade.Visible = false
end
local function sfx(id, vol, pitch)
	local s = new("Sound", { SoundId = id, Volume = vol or 0.5, PlaybackSpeed = pitch or 1 }, gui)
	s:Play() game:GetService("Debris"):AddItem(s, 4)
end
local function show()
	shownToken += 1
	local my = shownToken
	-- still on the loading / server-select screen? wait for it first
	local pg = player:WaitForChild("PlayerGui")
	local t0 = os.clock()
	while pg:FindFirstChild("SC_LoadingScreen") and os.clock() - t0 < 90 do task.wait(0.5) end
	if my ~= shownToken or workspace:GetAttribute("IntramuralsActive") ~= true then return end
	fit()
	shade.Visible = true
	shade.BackgroundTransparency = 1
	card.Position = UDim2.fromScale(0.5, -0.4)
	TweenService:Create(shade, TweenInfo.new(0.3), { BackgroundTransparency = 0.45 }):Play()
	TweenService:Create(card, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
	sfx("rbxasset://sounds/victory.wav", 0.45, 1.1)
	-- tiles pop in one by one
	for i, t in ipairs(tiles) do
		t.BackgroundTransparency = 1
		task.delay(0.25 + i * 0.07, function()
			if my ~= shownToken then return end
			TweenService:Create(t, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
		end)
	end
	-- trophy bounce + glowing border while open
	task.spawn(function()
		local k = 0
		while my == shownToken and shade.Visible do
			k += 1
			trophy.Rotation = math.sin(k / 3) * 8
			stroke.Transparency = 0.15 + (math.sin(k / 4) + 1) * 0.2
			task.wait(0.05)
		end
	end)
	-- closes by itself after 25 s
	task.spawn(function()
		for s = 25, 1, -1 do
			if my ~= shownToken then return end
			timer.Text = ("closes in %d s"):format(s)
			task.wait(1)
		end
		if my == shownToken then hide() end
	end)
end

goBtn.MouseButton1Click:Connect(function()
	local ev = RS:FindFirstChild("Events")
	local remotes = ev and ev:FindFirstChild("EventRemotes")
	local act = remotes and remotes:FindFirstChild("EventAction")
	if act then task.spawn(function() pcall(function() act:InvokeServer("goto") end) end) end
	hide()
end)
laterBtn.MouseButton1Click:Connect(hide)

-- open / close with the event
local last = workspace:GetAttribute("IntramuralsActive") == true
workspace:GetAttributeChangedSignal("IntramuralsActive"):Connect(function()
	local on = workspace:GetAttribute("IntramuralsActive") == true
	if on and not last then show() elseif not on and last then hide() end
	last = on
end)
-- joined while Intramurals is already running: show it once
if last then task.delay(2, function() if workspace:GetAttribute("IntramuralsActive") then show() end end) end
