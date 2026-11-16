--[[ LoadingScreen (ReplicatedFirst)
  1) Loads the campus for real: waits for the game, streams in the blocks & buildings around you,
     preloads textures/signs, sounds, effects, and waits for the students & teachers (NPCs).
  2) "TAP TO CONTINUE"
  3) Choose a server: 🏫 Main Server (Junior High, Senior High & College) or 🧸 Kid Server (Elementary).
     Choosing your current server just continues; the other one teleports you (published game only).
  Players who arrive from the server switch skip step 3.
]]
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")

ReplicatedFirst:RemoveDefaultLoadingScreen()
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

---------------------------------------------------------------- style
local GREEN, DEEP, NAVY = Color3.fromRGB(22, 120, 70), Color3.fromRGB(7, 26, 20), Color3.fromRGB(10, 18, 42)
local GOLD, WHITE, SOFT = Color3.fromRGB(255, 206, 84), Color3.new(1, 1, 1), Color3.fromRGB(190, 210, 200)
local BOLD, BLACK, REG = Enum.Font.GothamBold, Enum.Font.GothamBlack, Enum.Font.Gotham
local function tw(o, t, props, style, dir) local x = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props) x:Play() return x end
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	o.Parent = parent
	return o
end
local function corner(p, r) return new("UICorner", { CornerRadius = r or UDim.new(0, 12) }, p) end
local function stroke(p, c, t, tr) return new("UIStroke", { Color = c or WHITE, Thickness = t or 1.5, Transparency = tr or 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
local function text(parent, props)
	local t = new("TextLabel", { BackgroundTransparency = 1, TextColor3 = WHITE, Font = BOLD, TextScaled = true, Size = UDim2.fromScale(1, 1) }, parent)
	for k, v in pairs(props) do t[k] = v end
	return t
end

---------------------------------------------------------------- root
local gui = new("ScreenGui", { Name = "SC_LoadingScreen", IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.None, ResetOnSpawn = false, DisplayOrder = 1000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
-- invisible probe that measures the SAFE area (below Roblox's top bar, away from the iPhone notch / rounded
-- corners). The background fills the whole screen; the logo, text and buttons are fitted inside the safe area.
local safeGui = new("ScreenGui", { Name = "SC_LoadingSafe", ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets, IgnoreGuiInset = false, ResetOnSpawn = false, DisplayOrder = 0 }, playerGui)
local safeProbe = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Active = false }, safeGui)
gui.AncestryChanged:Connect(function() if not gui.Parent then safeGui:Destroy() end end)
---------------------------------------------------------------- hide the game's HUD until we're done
-- Every other ScreenGui (coins, inventory, menu buttons, event banner…) and Roblox's own chat/backpack/
-- player list stay hidden while loading and choosing a server. They come back when you're "good to go".
local StarterGui = game:GetService("StarterGui")
local hiddenGuis = {}   -- [ScreenGui] = the Enabled value it wanted
local hidingHud = true
local function hideGui(g)
	if not hidingHud or g == gui or g.Name == "SC_LoadingSafe" or g.Name == "SC_InsetProbe" or not g:IsA("LayerCollector") or hiddenGuis[g] ~= nil then return end
	hiddenGuis[g] = g.Enabled
	g.Enabled = false
	-- if a script turns it on while we load, remember that and keep it hidden for now
	g:GetPropertyChangedSignal("Enabled"):Connect(function()
		if hidingHud and g.Enabled then hiddenGuis[g] = true g.Enabled = false end
	end)
end
for _, g in ipairs(playerGui:GetChildren()) do hideGui(g) end
local hudConn = playerGui.ChildAdded:Connect(hideGui)
local function setCore(on)
	for _ = 1, 20 do
		local ok = pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, on) end)
		-- the game has its own inventory hotbar: Roblox's default backpack bar always stays off
		if ok and on then pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end) end
		if ok then break end
		task.wait(0.25)
	end
end
task.spawn(setCore, false)
local function showHud()
	if not hidingHud then return end
	hidingHud = false
	hudConn:Disconnect()
	for g, wanted in pairs(hiddenGuis) do if g.Parent then g.Enabled = wanted end end
	hiddenGuis = {}
	task.spawn(setCore, true)
end

local root = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = DEEP, BorderSizePixel = 0 }, gui)
local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, root)
local grad = new("UIGradient", { Rotation = 35, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 60, 38)), ColorSequenceKeypoint.new(0.55, DEEP), ColorSequenceKeypoint.new(1, NAVY) }) }, bg)
task.spawn(function() while bg.Parent do grad.Rotation = (grad.Rotation + 0.05) % 360 RunService.RenderStepped:Wait() end end)

-- floating "blocks" (little cubes drifting up)
local blocks = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true }, root)
local blockColors = { GOLD, GREEN, WHITE, Color3.fromRGB(80, 170, 255) }
for i = 1, 26 do
	task.spawn(function()
		local r = Random.new(i * 77)
		while blocks.Parent do
			local s = r:NextInteger(10, 44)
			local b = new("Frame", { Size = UDim2.fromOffset(s, s), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(r:NextNumber(0, 1), 0, 1.1, 0),
				BackgroundColor3 = blockColors[r:NextInteger(1, #blockColors)], BackgroundTransparency = r:NextNumber(0.72, 0.9), Rotation = r:NextInteger(0, 90), BorderSizePixel = 0 }, blocks)
			corner(b, UDim.new(0, math.floor(s / 5)))
			local t = r:NextNumber(9, 18)
			tw(b, t, { Position = UDim2.new(b.Position.X.Scale + r:NextNumber(-0.08, 0.08), 0, -0.1, 0), Rotation = b.Rotation + r:NextInteger(-180, 180) }, Enum.EasingStyle.Linear)
			task.wait(t)
			b:Destroy()
		end
	end)
	task.wait()
end

-- everything else scales with the screen (designed for 1000 x 600, works on phones too)
local stage = new("Frame", { Size = UDim2.fromOffset(1000, 600), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1 }, root)
local scale = new("UIScale", {}, stage)
local wide, applyMode = false, nil -- "wide" = landscape phone layout (logo left, panel right)
local function rescale()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1000, 600)
	local sa, ss = safeProbe.AbsolutePosition, safeProbe.AbsoluteSize
	local ra = root.AbsolutePosition
	if ss.X > 10 and ss.Y > 10 then
		-- fit the 1000 x 630 design into the safe area and centre it there
		local pad = math.clamp(math.min(ss.X, ss.Y) * 0.03, 4, 20)
		local nowWide = ss.X / ss.Y >= 1.6 and ss.Y < 560
		if nowWide ~= wide then wide = nowWide if applyMode then applyMode() end end
		local W, H = wide and 1060 or 1000, wide and 440 or 630
		scale.Scale = math.clamp(math.min((ss.X - pad * 2) / W, (ss.Y - pad * 2) / H), 0.3, 1.6)
		stage.Position = UDim2.fromOffset(sa.X - ra.X + ss.X / 2, sa.Y - ra.Y + ss.Y / 2)
	else
		local inset = game:GetService("GuiService"):GetGuiInset().Y
		scale.Scale = math.clamp(math.min(vp.X / 1000, (vp.Y - inset) / 630), 0.3, 1.6)
		stage.Position = UDim2.new(0.5, 0, 0.5, inset / 2)
	end
end
rescale()
task.spawn(function() while gui.Parent do rescale() task.wait(0.5) end end)
safeProbe:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)
safeProbe:GetPropertyChangedSignal("AbsolutePosition"):Connect(rescale)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale) end

---------------------------------------------------------------- logo + title
local logoX, logoY = UDim.new(0.5, 0), 34
local logo = new("Frame", { Size = UDim2.fromOffset(120, 120), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 34), BackgroundColor3 = GREEN }, stage)
corner(logo, UDim.new(1, 0)) stroke(logo, GOLD, 4, 0)
text(logo, { Text = "SC", Font = BLACK, TextColor3 = WHITE, Size = UDim2.fromScale(0.62, 0.5), Position = UDim2.fromScale(0.19, 0.25) })
local ring = new("Frame", { Size = UDim2.fromOffset(140, 140), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1 }, logo)
corner(ring, UDim.new(1, 0))
local ringStroke = stroke(ring, GOLD, 3, 0)
local ringGrad = new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 0) }) }, ringStroke)
task.spawn(function() while ring.Parent do ringGrad.Rotation = (ringGrad.Rotation + 3) % 360 RunService.RenderStepped:Wait() end end)
task.spawn(function() while logo.Parent do tw(logo, 1.2, { Position = UDim2.new(logoX, UDim.new(0, logoY - 6)) }, Enum.EasingStyle.Sine) task.wait(1.2) tw(logo, 1.2, { Position = UDim2.new(logoX, UDim.new(0, logoY + 4)) }, Enum.EasingStyle.Sine) task.wait(1.2) end end)

local title = text(stage, { Text = "SAMAR COLLEGE", Font = BLACK, Size = UDim2.new(1, 0, 0, 58), Position = UDim2.new(0, 0, 0, 172) })
new("UIGradient", { Color = ColorSequence.new(WHITE, GOLD), Rotation = 90 }, title)
local subtitle = text(stage, { Text = "VIRTUAL CAMPUS  •  CATBALOGAN CITY, SAMAR", Font = BOLD, TextColor3 = GOLD, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 232) })

---------------------------------------------------------------- LOADING view
---------------------------------------------------------------- landscape phone layout
-- Phones held sideways are short: the tall layout (logo on top, panel under it) would be tiny.
-- "Wide" mode puts the logo + title in a left column and every panel (loading list, tap to continue,
-- server choice) in the right column, so everything shows ~45% bigger. Switches live on rotate/resize.
local movedViews = {}
local function placeView(v)
	if not v:IsA("GuiObject") or v == logo or v == title or v == subtitle then return end
	local base = movedViews[v]
	if not base then
		local p = v.Position
		if p.Y.Scale ~= 0 or p.Y.Offset < 260 then return end -- only the panels under the title
		base = p
		movedViews[v] = base
	end
	v.Position = wide and UDim2.new(base.X.Scale, base.X.Offset + 195, 0, base.Y.Offset - 228) or base
end
applyMode = function()
	stage.Size = wide and UDim2.fromOffset(1060, 430) or UDim2.fromOffset(1000, 600)
	if wide then
		logoX, logoY = UDim.new(0, 165), 92
		title.Size = UDim2.fromOffset(330, 50) title.Position = UDim2.fromOffset(0, 236)
		subtitle.Size = UDim2.fromOffset(330, 15) subtitle.Position = UDim2.fromOffset(0, 292)
	else
		logoX, logoY = UDim.new(0.5, 0), 34
		title.Size = UDim2.new(1, 0, 0, 58) title.Position = UDim2.new(0, 0, 0, 172)
		subtitle.Size = UDim2.new(1, 0, 0, 20) subtitle.Position = UDim2.new(0, 0, 0, 232)
	end
	logo.Position = UDim2.new(logoX, UDim.new(0, logoY))
	for _, c in ipairs(stage:GetChildren()) do placeView(c) end
end
stage.ChildAdded:Connect(function(c) placeView(c) task.defer(placeView, c) end)
applyMode()
rescale()

local loadView = new("Frame", { Size = UDim2.new(1, 0, 0, 330), Position = UDim2.new(0, 0, 0, 268), BackgroundTransparency = 1 }, stage)
-- checklist card
local card = new("Frame", { Size = UDim2.fromOffset(440, 210), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(10, 20, 18), BackgroundTransparency = 0.25 }, loadView)
corner(card, UDim.new(0, 16)) stroke(card, GOLD, 1.5, 0.7)
new("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }, card)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, card)
local STEPS = {
	{ id = "connect", name = "Connecting to campus", w = 5 },
	{ id = "blocks",  name = "Blocks & buildings", w = 25 },
	{ id = "art",     name = "Textures, signs & models", w = 30 },
	{ id = "sound",   name = "Sounds & music", w = 12 },
	{ id = "fx",      name = "Effects & lights", w = 10 },
	{ id = "npc",     name = "Students & teachers", w = 13 },
	{ id = "ready",   name = "Getting you ready", w = 5 },
}
local rows = {}
for i, st in ipairs(STEPS) do
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = i }, card)
	local icon = text(row, { Text = "•", TextColor3 = SOFT, Size = UDim2.fromOffset(24, 24) })
	local name = text(row, { Text = st.name, Font = REG, TextColor3 = SOFT, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.62, -30, 0, 18), Position = UDim2.fromOffset(30, 3) })
	local detail = text(row, { Text = "", Font = REG, TextColor3 = Color3.fromRGB(150, 170, 160), TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0.38, 0, 0, 16), Position = UDim2.new(0.62, 0, 0, 4) })
	rows[st.id] = { icon = icon, name = name, detail = detail }
end
local spinChars = { "◐", "◓", "◑", "◒" }
local active = nil
task.spawn(function()
	local k = 0
	while card.Parent do
		k += 1
		if active and rows[active] then rows[active].icon.Text = spinChars[k % 4 + 1] end
		task.wait(0.12)
	end
end)
local function setStep(id, state, detail)
	local r = rows[id]
	if detail then r.detail.Text = detail end
	if state == "active" then active = id r.icon.TextColor3 = GOLD r.name.TextColor3 = WHITE r.name.Font = BOLD
	elseif state == "done" then if active == id then active = nil end r.icon.Text = "✓" r.icon.TextColor3 = Color3.fromRGB(110, 230, 140) r.name.TextColor3 = SOFT r.name.Font = REG end
end

-- progress bar
local barBack = new("Frame", { Size = UDim2.fromOffset(520, 16), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 222), BackgroundColor3 = Color3.fromRGB(20, 34, 30) }, loadView)
corner(barBack, UDim.new(1, 0)) stroke(barBack, WHITE, 1, 0.85)
local barFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, ClipsDescendants = true }, barBack)
corner(barFill, UDim.new(1, 0))
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(60, 200, 120), GOLD) }, barFill)
local shine = new("Frame", { Size = UDim2.new(0, 60, 1, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.6, BorderSizePixel = 0 }, barFill)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) }) }, shine)
task.spawn(function() while shine.Parent do shine.Position = UDim2.new(-0.2, 0, 0, 0) tw(shine, 1.4, { Position = UDim2.new(1.1, 0, 0, 0) }, Enum.EasingStyle.Linear) task.wait(1.8) end end)
local percent = text(loadView, { Text = "0%", Font = BLACK, TextColor3 = GOLD, Size = UDim2.fromOffset(120, 26), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 236) })
local status = text(loadView, { Text = "Starting up…", Font = REG, TextColor3 = SOFT, Size = UDim2.fromOffset(600, 18), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 264) })
local TIPS = {
	"💡 Press E (or tap) to talk to students and teachers.",
	"🎪 Watch the top of the screen for campus events — join to win coins!",
	"🗺️ Open the Map to jump to the Main Gate, Courtyard or Canteen.",
	"🪑 Chairs really work — walk up and sit down.",
	"🏆 Events give you tickets, coins and achievements.",
	"🔦 Light switches in classrooms turn the lights on and off.",
	"🎡 The School Fair is held in the 1F Open Hall.",
}
local tip = text(loadView, { Text = TIPS[1], Font = REG, TextColor3 = Color3.fromRGB(220, 230, 225), Size = UDim2.fromOffset(700, 18), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 300) })
task.spawn(function()
	local i = 1
	while tip.Parent do
		task.wait(4)
		i = i % #TIPS + 1
		tw(tip, 0.3, { TextTransparency = 1 }) task.wait(0.3)
		tip.Text = TIPS[i]
		tw(tip, 0.3, { TextTransparency = 0 })
	end
end)
text(stage, { Text = "BSIT Capstone Project  •  Samar College Roblox Recreation", Font = REG, TextColor3 = Color3.fromRGB(130, 150, 140), TextTransparency = 0.2, Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, 2) })

local shown = 0
local function setProgress(p, msg)
	p = math.clamp(p, 0, 1)
	if msg then status.Text = msg end
	tw(barFill, 0.25, { Size = UDim2.fromScale(p, 1) })
	task.spawn(function()
		local from = shown
		shown = p
		for k = 1, 8 do percent.Text = math.floor((from + (p - from) * k / 8) * 100 + 0.5) .. "%" task.wait(0.03) end
	end)
end

---------------------------------------------------------------- the real loading
local function fmt(n) local s = tostring(math.floor(n)) local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse() return (r:gsub("^,", "")) end
local weightBefore = {}
do local acc = 0 for _, st in ipairs(STEPS) do weightBefore[st.id] = acc acc += st.w end end
local function stepProgress(id, f, msg)
	local st for _, s in ipairs(STEPS) do if s.id == id then st = s end end
	setProgress((weightBefore[id] + st.w * math.clamp(f, 0, 1)) / 100, msg)
end
-- preload a list of instances in small batches (with a time limit so nobody gets stuck)
local function preload(list, id, label, limit)
	local total, done, t0 = #list, 0, os.clock()
	if total == 0 then return end
	local batch = 30
	for i = 1, total, batch do
		local chunk = {}
		for k = i, math.min(total, i + batch - 1) do table.insert(chunk, list[k]) end
		pcall(function() ContentProvider:PreloadAsync(chunk) end)
		done = math.min(total, i + batch - 1)
		setStep(id, "active", fmt(done) .. " / " .. fmt(total))
		stepProgress(id, done / total, label)
		if os.clock() - t0 > (limit or 20) then setStep(id, "active", "rest in background") break end
	end
end

local function run()
	-- 1) connect
	setStep("connect", "active")
	setProgress(0.01, "Connecting to Samar College…")
	if not game:IsLoaded() then game.Loaded:Wait() end
	setStep("connect", "done", "online")

	-- 2) blocks & buildings (streamed in around where you spawn)
	setStep("blocks", "active")
	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart", 15)
	if root then pcall(function() player:RequestStreamAroundAsync(root.Position, 8) end) end
	local t0 = os.clock()
	local last, stable = -1, 0
	local count = 0
	for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("BasePart") then count += 1 end end
	local addConn = workspace.DescendantAdded:Connect(function(d) if d:IsA("BasePart") then count += 1 end end)
	while os.clock() - t0 < 14 do
		local n = count
		setStep("blocks", "active", fmt(n) .. " blocks")
		stepProgress("blocks", math.min(0.95, (os.clock() - t0) / 6 + (stable * 0.1)), "Building the campus…")
		if n == last then stable += 1 else stable = 0 end
		last = n
		if stable >= 2 and os.clock() - t0 > 2.5 then break end
		task.wait(0.6)
	end
	addConn:Disconnect()
	setStep("blocks", "done", fmt(last) .. " blocks")

	-- 3) textures, signs, meshes
	setStep("art", "active")
	local art, sounds, fx = {}, {}, {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Decal") or d:IsA("MeshPart") or d:IsA("SpecialMesh") or d:IsA("SurfaceAppearance") then table.insert(art, d)
		elseif d:IsA("Sound") then table.insert(sounds, d)
		elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then table.insert(fx, d) end
	end
	for _, d in ipairs(playerGui:GetDescendants()) do if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.Image ~= "" then table.insert(art, d) end end
	for _, d in ipairs(game:GetService("SoundService"):GetDescendants()) do if d:IsA("Sound") then table.insert(sounds, d) end end
	preload(art, "art", "Painting the walls and signs…", 18)
	setStep("art", "done", fmt(#art) .. " items")

	-- 4) sounds
	setStep("sound", "active")
	preload(sounds, "sound", "Tuning the school bell…", 8)
	setStep("sound", "done", fmt(#sounds) .. " sounds")

	-- 5) effects
	setStep("fx", "active")
	preload(fx, "fx", "Turning on the lights…", 6)
	local lights = 0 for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Light") then lights += 1 end end
	stepProgress("fx", 1, "Turning on the lights…")
	setStep("fx", "done", fmt(#fx + lights) .. " effects")

	-- 6) NPCs
	setStep("npc", "active")
	local t1 = os.clock()
	while not workspace:GetAttribute("CampusNPCsReady") and os.clock() - t1 < 25 do
		local n = 0
		local campus = workspace:FindFirstChild("SamarCollege_Campus")
		local f = campus and campus:FindFirstChild("CampusNPCs")
		if f then for _, h in ipairs(f:GetDescendants()) do if h:IsA("Humanoid") then n += 1 end end end
		setStep("npc", "active", n .. " arrived")
		stepProgress("npc", (os.clock() - t1) / 25, "Students and teachers are arriving…")
		task.wait(0.5)
	end
	setStep("npc", "done", "on campus")

	-- 7) ready
	setStep("ready", "active")
	stepProgress("ready", 0.5, "Almost there…")
	task.wait(0.4)
	setStep("ready", "done", "")
	setProgress(1, "Done! Welcome to Samar College 🎓")
	task.wait(0.6)
end
local ok, err = pcall(run)
if not ok then warn("[LoadingScreen] " .. tostring(err)) setProgress(1, "Ready!") end

---------------------------------------------------------------- TAP TO CONTINUE
for _, d in ipairs(loadView:GetDescendants()) do
	if d:IsA("TextLabel") then tw(d, 0.35, { TextTransparency = 1 }) elseif d:IsA("Frame") then tw(d, 0.35, { BackgroundTransparency = 1 }) elseif d:IsA("UIStroke") then tw(d, 0.35, { Transparency = 1 }) end
end
task.wait(0.4)
loadView.Visible = false

local tapView = new("Frame", { Size = UDim2.new(1, 0, 0, 300), Position = UDim2.new(0, 0, 0, 280), BackgroundTransparency = 1 }, stage)
local tapBtn = new("TextButton", { Size = UDim2.fromOffset(380, 70), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40), BackgroundColor3 = GREEN, Text = "", AutoButtonColor = false }, tapView)
corner(tapBtn, UDim.new(1, 0)) local tapStroke = stroke(tapBtn, GOLD, 3, 0)
text(tapBtn, { Text = "▶  TAP TO CONTINUE", Font = BLACK, Size = UDim2.new(0.8, 0, 0.5, 0), Position = UDim2.fromScale(0.1, 0.25) })
local hint = text(tapView, { Text = UserInputService.TouchEnabled and "Tap anywhere" or "Click anywhere or press any key", Font = REG, TextColor3 = SOFT, Size = UDim2.fromOffset(500, 18), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 126) })
local welcome = text(tapView, { Text = "Hi " .. player.DisplayName .. "! Your campus is ready.", Font = BOLD, TextColor3 = WHITE, Size = UDim2.fromOffset(600, 24), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0) })
local pulsing = true
task.spawn(function()
	while pulsing do
		tw(tapBtn, 0.6, { Size = UDim2.fromOffset(400, 74) }, Enum.EasingStyle.Sine) tw(tapStroke, 0.6, { Transparency = 0.5 }, Enum.EasingStyle.Sine) task.wait(0.6)
		tw(tapBtn, 0.6, { Size = UDim2.fromOffset(380, 70) }, Enum.EasingStyle.Sine) tw(tapStroke, 0.6, { Transparency = 0 }, Enum.EasingStyle.Sine) task.wait(0.6)
	end
end)
local continued = Instance.new("BindableEvent")
local anywhere = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 0 }, root)
local c1 = anywhere.MouseButton1Click:Connect(function() continued:Fire() end)
local c2 = tapBtn.MouseButton1Click:Connect(function() continued:Fire() end)
local c3 = UserInputService.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Keyboard or i.UserInputType == Enum.UserInputType.Gamepad1 then continued:Fire() end end)
continued.Event:Wait()
c1:Disconnect() c2:Disconnect() c3:Disconnect() anywhere:Destroy()
-- tells the music player (random song) and the weather (random weather/season) that the player is in
player:SetAttribute("SC_Continued", true)
pulsing = false
tw(tapBtn, 0.15, { Size = UDim2.fromOffset(340, 62) }) task.wait(0.15)
tapView:Destroy()

---------------------------------------------------------------- campus fly-around behind the menu
local cam = workspace.CurrentCamera
local orbiting = true
local CENTER = Vector3.new(140, 12, -20)
task.spawn(function()
	cam.CameraType = Enum.CameraType.Scriptable
	local a = 0
	while orbiting do
		a += RunService.RenderStepped:Wait() * 0.06
		cam.CFrame = CFrame.lookAt(CENTER + Vector3.new(math.cos(a) * 190, 70, math.sin(a) * 190), CENTER)
	end
end)
tw(bg, 0.8, { BackgroundTransparency = 0.35 }) tw(root, 0.8, { BackgroundTransparency = 1 })

---------------------------------------------------------------- SERVER SELECT
local tpData = nil
pcall(function() tpData = TeleportService:GetLocalPlayerTeleportData() end)
local currentType = workspace:GetAttribute("ServerType") or "Main"
local remote = game:GetService("ReplicatedStorage"):WaitForChild("ServerSelect", 10)
remote = remote and remote:WaitForChild("ChooseServer", 10)

local function finish(msg)
	local done = new("Frame", { Size = UDim2.new(1, 0, 0, 200), Position = UDim2.new(0, 0, 0, 300), BackgroundTransparency = 1 }, stage)
	local check = new("Frame", { Size = UDim2.fromOffset(0, 0), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 40), BackgroundColor3 = Color3.fromRGB(60, 200, 110) }, done)
	corner(check, UDim.new(1, 0)) stroke(check, WHITE, 3, 0.2)
	text(check, { Text = "✓", Font = BLACK })
	tw(check, 0.45, { Size = UDim2.fromOffset(78, 78) }, Enum.EasingStyle.Back)
	text(done, { Text = msg or "You're good to go!", Font = BLACK, Size = UDim2.fromOffset(700, 34), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 92) })
	task.wait(1.5)
	orbiting = false
	showHud() -- the HUD comes back as the loading screen fades out
	tw(root, 0.8, { GroupTransparency = 1 })
	task.wait(0.85)
	cam.CameraType = Enum.CameraType.Custom
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then cam.CameraSubject = hum end
	gui:Destroy()
end

-- no server choice: after "tap to continue" go straight in
do
	finish("You're good to go!")
	return
end

local selectView = new("Frame", { Size = UDim2.new(1, 0, 0, 340), Position = UDim2.new(0, 0, 0, 268), BackgroundTransparency = 1 }, stage)
text(selectView, { Text = "CHOOSE YOUR SERVER", Font = BLACK, TextColor3 = WHITE, Size = UDim2.fromOffset(600, 30), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0) })
text(selectView, { Text = "You can switch any time in ⚙ Settings", Font = REG, TextColor3 = SOFT, Size = UDim2.fromOffset(600, 16), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 34) })
local cardsRow = new("Frame", { Size = UDim2.fromOffset(640, 262), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 62), BackgroundTransparency = 1 }, selectView)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 24), SortOrder = Enum.SortOrder.LayoutOrder }, cardsRow)
local msgLabel = text(selectView, { Text = "", Font = BOLD, TextColor3 = GOLD, Size = UDim2.fromOffset(700, 18), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 330) })

local SERVERS = {
	{ id = "Main", icon = "🏫", name = "MAIN SERVER", color = Color3.fromRGB(30, 140, 80), tags = { "JHS", "SHS", "College" }, desc = "The full campus with all events:\nTower, Escape, Intramurals & more." },
	{ id = "Kid", icon = "🧸", name = "KID SERVER", color = Color3.fromRGB(240, 140, 40), tags = { "Elementary", "Kid-friendly" }, desc = "A calmer campus for younger students\nwith kid-friendly events.", soon = true },
}
local busy = false
local cards = {}
for i, sv in ipairs(SERVERS) do
	local c = new("TextButton", { Size = UDim2.fromOffset(300, 250), BackgroundColor3 = Color3.fromRGB(12, 22, 20), BackgroundTransparency = 0.15, Text = "", AutoButtonColor = false, LayoutOrder = i }, cardsRow)
	corner(c, UDim.new(0, 20))
	local cs = stroke(c, sv.color, 2, 0.3)
	local top = new("Frame", { Size = UDim2.new(1, 0, 0, 92), BackgroundColor3 = sv.color }, c)
	corner(top, UDim.new(0, 20))
	new("Frame", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -20), BackgroundColor3 = sv.color, BorderSizePixel = 0 }, top)
	new("UIGradient", { Color = ColorSequence.new(WHITE, Color3.fromRGB(200, 200, 200)), Rotation = 90 }, top)
	text(top, { Text = sv.icon, Font = BLACK, Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0, 16, 0.5, -30) })
	text(top, { Text = sv.name, Font = BLACK, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -96, 0, 28), Position = UDim2.new(0, 86, 0.5, -16) })
	if sv.id == currentType then
		local badge = new("Frame", { Size = UDim2.fromOffset(92, 22), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), BackgroundColor3 = WHITE }, c)
		corner(badge, UDim.new(1, 0))
		text(badge, { Text = "● YOU'RE HERE", Font = BLACK, TextColor3 = sv.color, Size = UDim2.new(0.86, 0, 0.6, 0), Position = UDim2.fromScale(0.07, 0.2) })
	end
	local tags = new("Frame", { Size = UDim2.new(1, -28, 0, 24), Position = UDim2.new(0, 14, 0, 104), BackgroundTransparency = 1 }, c)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, tags)
	for _, tg in ipairs(sv.tags) do
		local chip = new("Frame", { Size = UDim2.fromOffset(#tg * 8 + 22, 22), BackgroundColor3 = sv.color, BackgroundTransparency = 0.6 }, tags)
		corner(chip, UDim.new(1, 0))
		text(chip, { Text = tg, Font = BOLD, Size = UDim2.new(0.84, 0, 0.62, 0), Position = UDim2.fromScale(0.08, 0.19) })
	end
	text(c, { Text = sv.desc, Font = REG, TextColor3 = SOFT, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, -28, 0, 50), Position = UDim2.new(0, 14, 0, 136) })
	local btn = new("Frame", { Size = UDim2.new(1, -28, 0, 44), Position = UDim2.new(0, 14, 1, -56), BackgroundColor3 = sv.color }, c)
	corner(btn, UDim.new(0, 12))
	local btnText = text(btn, { Text = sv.id == currentType and "PLAY HERE  ▶" or "JOIN  ▶", Font = BLACK, Size = UDim2.new(0.8, 0, 0.5, 0), Position = UDim2.fromScale(0.1, 0.25) })
	if sv.soon and sv.id ~= currentType then
		-- coming soon: greyed out with a ribbon, can't be picked yet
		btn.BackgroundColor3 = Color3.fromRGB(80, 85, 95)
		btnText.Text = "🔒  COMING SOON"
		top.BackgroundColor3 = sv.color:Lerp(Color3.fromRGB(90, 90, 100), 0.45)
		local badge = new("Frame", { Size = UDim2.fromOffset(118, 22), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), BackgroundColor3 = GOLD, ZIndex = 5 }, c)
		corner(badge, UDim.new(1, 0))
		text(badge, { Text = "🔒 COMING SOON", Font = BLACK, TextColor3 = Color3.fromRGB(60, 40, 10), Size = UDim2.new(0.86, 0, 0.6, 0), Position = UDim2.fromScale(0.07, 0.2), ZIndex = 6 })
		c.ClipsDescendants = true
		c.BackgroundTransparency = 0.35
	end
	cards[sv.id] = { card = c, stroke = cs, btnText = btnText }
	c.MouseEnter:Connect(function() if not busy and not (sv.soon and sv.id ~= currentType) then tw(c, 0.15, { Size = UDim2.fromOffset(310, 258) }) tw(cs, 0.15, { Thickness = 4, Transparency = 0 }) end end)
	c.MouseLeave:Connect(function() tw(c, 0.15, { Size = UDim2.fromOffset(300, 250) }) tw(cs, 0.15, { Thickness = 2, Transparency = 0.3 }) end)
	c.MouseButton1Click:Connect(function()
		if busy then return end
		if sv.soon and sv.id ~= currentType then
			msgLabel.Text = "🧸 The Kid Server is coming soon! Stay tuned."
			tw(c, 0.06, { Rotation = 2 }) task.wait(0.06) tw(c, 0.06, { Rotation = -2 }) task.wait(0.06) tw(c, 0.06, { Rotation = 0 })
			return
		end
		busy = true
		btnText.Text = "JOINING…"
		tw(cs, 0.15, { Thickness = 5, Transparency = 0 })
		local res = { ok = true, stay = true }
		if sv.id ~= currentType then
			local okCall, r = pcall(function() return remote:InvokeServer(sv.id) end)
			res = okCall and r or { ok = false, msg = "Couldn't reach the server. Staying here." }
		end
		if res.ok and res.stay then
			selectView:Destroy()
			finish(("You're good to go! (%s Server)"):format(sv.id))
		elseif res.ok and res.teleporting then
			selectView:Destroy()
			pcall(function() TeleportService:SetTeleportGui(gui) end)
			text(stage, { Text = ("Taking you to the %s Server… %s"):format(sv.id, sv.icon), Font = BLACK, Size = UDim2.fromOffset(700, 34), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 330) })
			task.delay(25, function() if gui.Parent then finish("You're good to go!") end end) -- teleport didn't happen: just continue
		else
			msgLabel.Text = res.msg or "Couldn't switch. Staying here."
			btnText.Text = "…"
			task.wait(2.6)
			selectView:Destroy()
			finish(("You're good to go! (%s Server)"):format(currentType))
		end
	end)
end
