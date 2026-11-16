--[[ UIResponsive — makes the event screens fit every device (phones, tablets, PC).
  • Adds a UIScale ("ResponsiveScale") to each listed ScreenGui. Everything inside was designed
    for a ~1000 × 560 screen; on smaller screens it is scaled down (62 %–100 %), so panels never
    run off a phone screen. Updates live when the screen rotates or the window is resized.
  • Text clean-up: every auto-sized label gets a max text size (no giant / jumping text), and
    timers use fixed-width digits so the numbers don't jiggle while counting. ]]
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUIS = { EventGui = true, CampusLifeGui = true }
local BASE_W, BASE_H = 1000, 560
local MIN_SCALE = 0.62
local MONO = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold)

local function screenScale()
	local vs = workspace.CurrentCamera.ViewportSize
	local inset = GuiService:GetGuiInset()
	local w, h = vs.X, vs.Y - inset.Y
	return math.clamp(math.min(w / BASE_W, h / BASE_H), MIN_SCALE, 1)
end

local function fixText(d)
	if not (d:IsA("TextLabel") or d:IsA("TextButton")) then return end
	if d.TextScaled and not d:FindFirstChildOfClass("UITextSizeConstraint") then
		local c = Instance.new("UITextSizeConstraint")
		local h = d.Size.Y.Offset
		c.MaxTextSize = (h > 0) and math.clamp(math.floor(h * 0.72), 10, 30) or 22
		c.MinTextSize = 9
		c.Parent = d
	end
	-- the event pill is always one line (wider, no wrapping onto a 2nd squashed line)
	if d.Name == "Pill" and d:IsA("TextButton") then
		d.AutomaticSize = Enum.AutomaticSize.X d.Size = UDim2.new(0, 0, 0, 30) -- width follows the text
		d.TextScaled = false d.TextWrapped = false d.TextTruncate = Enum.TextTruncate.AtEnd d.TextSize = 15
	end
	-- timers: fixed-width digits (no jiggle while counting)
	if d.Name == "Time" or d.Name == "Timer" or d.Name == "Countdown" then
		d.FontFace = MONO
	end
end

local tracked = {}
local function track(gui)
	if tracked[gui] then return end
	tracked[gui] = true
	local sc = gui:FindFirstChild("ResponsiveScale") or Instance.new("UIScale")
	sc.Name = "ResponsiveScale" sc.Scale = screenScale() sc.Parent = gui
	for _, d in ipairs(gui:GetDescendants()) do fixText(d) end
	gui.DescendantAdded:Connect(function(d) task.defer(fixText, d) end)
end

local function update()
	local s = screenScale()
	for gui in pairs(tracked) do
		if gui.Parent then
			local sc = gui:FindFirstChild("ResponsiveScale")
			if sc then sc.Scale = s end
			gui:SetAttribute("UIScaleFactor", s)
		end
	end
end

for _, g in ipairs(playerGui:GetChildren()) do if GUIS[g.Name] then track(g) end end
playerGui.ChildAdded:Connect(function(g) if GUIS[g.Name] then task.defer(function() track(g) update() end) end end)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
update()

------------------------------------------------------------------ PHONE SIDE SAFE MARGIN
-- iPhones / notch phones in landscape: the Dynamic Island and rounded corners cover the
-- left/right edges. Real devices already inset the UI (CoreUISafeInsets); when the engine
-- reports no side inset (Studio emulator, some Androids) we add a margin ourselves so edge
-- buttons (side rail, Settings, event boards) never sit under the notch or the corners.
local UIS = game:GetService("UserInputService")
local SIDE = {
	MainHUD = { Rail = "L", SettingsButton = "R" },
	EventGui = { Scoreboard = "R", EscapeKeys = "R", IntramuralsBoard = "R" },
	SportsGui = { VotePopup = "R", ChessReopen = "R" },
	TalentGui = { StagePanel = "R" },
	AdminPanelGui = { EventsWindow = "L" },
}
-- probe: a full-screen gui with NO insets. If it starts left of our UI's origin, the device already
-- reports its notch/corner insets and Roblox moves the UI for us -> add nothing extra.
local probeGui = Instance.new("ScreenGui")
probeGui.Name = "SC_InsetProbe" probeGui.ScreenInsets = Enum.ScreenInsets.None probeGui.IgnoreGuiInset = true probeGui.ResetOnSpawn = false
local probe = Instance.new("Frame") probe.Size = UDim2.fromScale(1, 1) probe.BackgroundTransparency = 1 probe.Active = false probe.Parent = probeGui
probeGui.Parent = playerGui
local function sidePx(gui)
	local vs = workspace.CurrentCamera.ViewportSize
	if not UIS.TouchEnabled or vs.X / math.max(vs.Y, 1) < 1.75 then return 0 end
	if probe.AbsolutePosition.X < -2 or gui.AbsolutePosition.X > 2 then return 0 end -- device already insets it
	return math.clamp(math.floor(vs.X * 0.045), 24, 48)
end
local function rootScale(gui)
	for _, c in ipairs(gui:GetChildren()) do if c:IsA("UIScale") then return c.Scale end end
	return 1
end
local shifted = {}
local function applyShift(obj)
	local info = shifted[obj]
	if not info or not info.gui.Parent then return end
	local px = sidePx(info.gui) / math.max(rootScale(info.gui), 0.01)
	local b = info.base
	local x = math.round(b.X.Offset + (info.side == "L" and px or -px)) -- UDim offsets are whole numbers
	info.applied = x
	info.busy = true
	obj.Position = UDim2.new(b.X.Scale, x, b.Y.Scale, b.Y.Offset)
	info.busy = false
end
local function watchSide(gui, obj, side)
	if shifted[obj] then return end
	shifted[obj] = { gui = gui, side = side, base = obj.Position }
	obj:GetPropertyChangedSignal("Position"):Connect(function()
		local info = shifted[obj]
		if info.busy then return end
		local p = obj.Position
		if math.abs(p.X.Offset - (info.applied or math.huge)) < 1 and p.X.Scale == info.base.X.Scale then
			info.base = UDim2.new(info.base.X.Scale, info.base.X.Offset, p.Y.Scale, p.Y.Offset) -- only Y moved
			return
		end
		info.base = p -- a script moved it: re-apply the margin on top
		applyShift(obj)
	end)
	obj.AncestryChanged:Connect(function() if not obj.Parent then shifted[obj] = nil end end)
	applyShift(obj)
end
local function scanSide(gui)
	local list = SIDE[gui.Name]
	if not list then return end
	for name, side in pairs(list) do
		local obj = gui:FindFirstChild(name)
		if obj and obj:IsA("GuiObject") then watchSide(gui, obj, side) end
	end
	gui.ChildAdded:Connect(function(c)
		local side = list[c.Name]
		if side and c:IsA("GuiObject") then task.defer(watchSide, gui, c, side) end
	end)
end
for _, g in ipairs(playerGui:GetChildren()) do if g:IsA("ScreenGui") then task.defer(scanSide, g) end end
playerGui.ChildAdded:Connect(function(g) if g:IsA("ScreenGui") then task.defer(scanSide, g) end end)
local function reapplyAll() for obj in pairs(shifted) do applyShift(obj) end end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() task.defer(reapplyAll) end)
task.spawn(function() while true do task.wait(2) reapplyAll() end end) -- picks up UIScale changes
