-- CoinsClient: compact coin bar at the TOP-RIGHT (icon + number only), side by side,
-- just under the Settings button on every device (clear of the music mini player and the jump button).
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local gui = script.Parent

local C = {
	panel = Color3.fromRGB(30, 30, 40), pill = Color3.fromRGB(42, 44, 58), stroke = Color3.fromRGB(78, 84, 110),
	text = Color3.fromRGB(240, 242, 248), dim = Color3.fromRGB(150, 156, 176),
	common = Color3.fromRGB(255, 200, 60), event = Color3.fromRGB(176, 120, 255),
}
local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = p end
local function stroke(p, col, t) local s = Instance.new("UIStroke") s.Color = col s.Thickness = t or 1.4 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = p return s end

local bar = Instance.new("Frame") bar.Name = "CoinBar" bar.AnchorPoint = Vector2.new(0, 1)
bar.Size = UDim2.fromOffset(100, 82) bar.BackgroundTransparency = 1 bar.Parent = gui
local scale = Instance.new("UIScale") scale.Parent = bar
local lay = Instance.new("UIListLayout") lay.FillDirection = Enum.FillDirection.Vertical lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
lay.HorizontalAlignment = Enum.HorizontalAlignment.Left lay.Padding = UDim.new(0, 6) lay.SortOrder = Enum.SortOrder.LayoutOrder lay.Parent = bar
-- follow the Inventory hotbar on every screen size
local UIS = game:GetService("UserInputService")
local function place()
	local vp = gui.AbsoluteSize
	if vp.X < 2 then vp = workspace.CurrentCamera.ViewportSize end
	local s = math.clamp(math.min(vp.X / 900, vp.Y / 560), 0.62, 1)
	scale.Scale = s
	-- top-right, side by side, right-aligned
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
	lay.VerticalAlignment = Enum.VerticalAlignment.Center
	bar.Size = UDim2.fromOffset(206, 38)
	bar.AnchorPoint = Vector2.new(1, 0)
	local y = 70 -- default: under a 52px Settings button at y=10
	local hud = player.PlayerGui:FindFirstChild("MainHUD")
	local sb = hud and hud:FindFirstChild("SettingsButton", true)
	if sb and sb.Visible and sb.AbsoluteSize.Y > 0 then
		y = (sb.AbsolutePosition.Y + sb.AbsoluteSize.Y) - gui.AbsolutePosition.Y + 6
	end
	bar.Position = UDim2.new(1, -12, 0, math.floor(y))
end
place()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
task.spawn(function() while true do task.wait(1) place() end end)

local pills = {}
local function makePill(name, label, icon, color, order)
	-- no dark background / border: just the coin icon + number
	local p = Instance.new("Frame") p.Name = name .. "Pill" p.Size = UDim2.fromOffset(100, 38) p.BackgroundTransparency = 1 p.LayoutOrder = order p.Parent = bar
	local ic = Instance.new("TextLabel") ic.Name = "Icon" ic.Size = UDim2.fromOffset(30, 30) ic.Position = UDim2.fromOffset(4, 4)
	ic.BackgroundColor3 = color ic.Text = icon ic.TextScaled = true ic.Font = Enum.Font.GothamBold ic.Parent = p corner(ic, 16)
	local pad = Instance.new("UIPadding") pad.PaddingTop = UDim.new(0, 4) pad.PaddingBottom = UDim.new(0, 4) pad.PaddingLeft = UDim.new(0, 4) pad.PaddingRight = UDim.new(0, 4) pad.Parent = ic
	-- number only (no "COMMON COIN" / "EVENT COIN" label)
	local amt = Instance.new("TextLabel") amt.Name = "Amount" amt.BackgroundTransparency = 1 amt.Position = UDim2.fromOffset(40, 0) amt.Size = UDim2.new(1, -48, 1, 0)
	amt.Font = Enum.Font.GothamBlack amt.TextSize = 20 amt.TextColor3 = C.text amt.Text = "0" amt.TextXAlignment = Enum.TextXAlignment.Left amt.TextScaled = false amt.Parent = p
	amt.TextStrokeTransparency = 0.25 amt.TextStrokeColor3 = Color3.new(0, 0, 0)
	local fit = Instance.new("UITextSizeConstraint") fit.MaxTextSize = 20 fit.Parent = amt
	if icon == "C" then
		ic.TextColor3 = Color3.fromRGB(150, 95, 10) ic.Font = Enum.Font.GothamBlack
		local ring = Instance.new("UIStroke") ring.Color = Color3.fromRGB(255, 232, 140) ring.Thickness = 2 ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border ring.Parent = ic
	end
	local ps = Instance.new("UIScale") ps.Parent = p
	pills[name] = { frame = p, amount = amt, scale = ps, color = color, shown = nil }
end
makePill("Common", "COMMON COIN", "C", C.common, 1)
makePill("Event", "EVENT COIN", "⭐", C.event, 2)

local function fmt(n) local s = tostring(math.floor(n)) local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse() return (r:gsub("^,", "")) end

local function floatText(p, delta)
	local f = Instance.new("TextLabel") f.BackgroundTransparency = 1 f.AnchorPoint = Vector2.new(0.5, 0)
	f.Position = UDim2.new(0.5, 10, 0, -22) f.Size = UDim2.fromOffset(90, 20) f.Font = Enum.Font.GothamBlack f.TextSize = 16
	f.Text = (delta > 0 and "+" or "") .. fmt(delta) f.TextColor3 = delta > 0 and Color3.fromRGB(90, 230, 130) or Color3.fromRGB(255, 100, 100)
	f.TextStrokeTransparency = 0.4 f.Parent = p.frame
	TweenService:Create(f, TweenInfo.new(1.1), { Position = UDim2.new(0.5, 10, 0, -46), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.2, function() f:Destroy() end)
end

local function show(name, value)
	local p = pills[name]
	if p.shown == nil then p.shown = value p.amount.Text = fmt(value) return end
	local from = p.shown local delta = value - from
	if delta == 0 then return end
	p.shown = value
	floatText(p, delta)
	p.scale.Scale = 1.12 TweenService:Create(p.scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local nv = Instance.new("NumberValue") nv.Value = from
	nv.Changed:Connect(function(v) p.amount.Text = fmt(v) end)
	local t = TweenService:Create(nv, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Value = value }) t:Play()
	t.Completed:Connect(function() p.amount.Text = fmt(value) nv:Destroy() end)
end

local wallet = player:WaitForChild("Wallet", 30)
if wallet then
	for _, name in ipairs({ "Common", "Event" }) do
		local v = wallet:WaitForChild(name, 10)
		if v then show(name, v.Value) v.Changed:Connect(function(n) show(name, n) end) end
	end
end
