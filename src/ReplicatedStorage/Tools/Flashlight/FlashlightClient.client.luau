-- FlashlightClient: asks the SERVER to switch the light (so EVERY player sees it), sends where you aim,
-- and shows a small battery meter while you hold it.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local tool = script.Parent
local remote = RS:WaitForChild("FlashlightRemote")
local equipped = false

local function toggle() if equipped then remote:FireServer("toggle", tool) end end
tool.Activated:Connect(toggle) -- mouse click and mobile tap

local gui, fill, txt
local function buildGui()
	if gui and gui.Parent then return end
	gui = Instance.new("ScreenGui") gui.Name = "FlashlightGui" gui.ResetOnSpawn = false gui.DisplayOrder = 8
	local f = Instance.new("Frame") f.AnchorPoint = Vector2.new(0.5, 1) f.Position = UDim2.new(0.5, 0, 1, -112) f.Size = UDim2.fromOffset(190, 30)
	f.BackgroundColor3 = Color3.fromRGB(22, 24, 32) f.BackgroundTransparency = 0.15 f.Parent = gui
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
	local ic = Instance.new("TextLabel") ic.BackgroundTransparency = 1 ic.Size = UDim2.fromOffset(28, 30) ic.Position = UDim2.fromOffset(4, 0) ic.Text = "🔦" ic.TextSize = 16 ic.Parent = f
	local bg = Instance.new("Frame") bg.Position = UDim2.fromOffset(34, 10) bg.Size = UDim2.fromOffset(100, 10) bg.BackgroundColor3 = Color3.fromRGB(55, 58, 72) bg.Parent = f
	Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
	fill = Instance.new("Frame") fill.Size = UDim2.fromScale(1, 1) fill.BackgroundColor3 = Color3.fromRGB(110, 220, 120) fill.Parent = bg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	txt = Instance.new("TextLabel") txt.BackgroundTransparency = 1 txt.Position = UDim2.fromOffset(138, 0) txt.Size = UDim2.fromOffset(50, 30) txt.Font = Enum.Font.GothamBold
	txt.TextSize = 12 txt.TextColor3 = Color3.new(1, 1, 1) txt.Text = "" txt.Parent = f
	local hint = Instance.new("TextLabel") hint.BackgroundTransparency = 1 hint.AnchorPoint = Vector2.new(0.5, 1) hint.Position = UDim2.new(0.5, 0, 0, -2) hint.Size = UDim2.fromOffset(260, 16)
	hint.Font = Enum.Font.Gotham hint.TextSize = 11 hint.TextColor3 = Color3.fromRGB(220, 225, 235) hint.TextStrokeTransparency = 0.5
	hint.Text = (UIS.TouchEnabled and not UIS.KeyboardEnabled) and "Tap the screen to switch on/off" or "Click or press F to switch on/off" hint.Parent = f
	local s = Instance.new("UIScale") s.Parent = f
	local function rs() local v = gui.AbsoluteSize if v.Y > 2 then s.Scale = math.clamp(v.Y / 720, 0.7, 1) end end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(rs)
	gui.Parent = player:WaitForChild("PlayerGui") rs()
end
local function updateGui()
	if not (gui and fill) then return end
	local b = tool:GetAttribute("Battery") or 100
	local on = tool:GetAttribute("On") == true
	fill.Size = UDim2.fromScale(math.clamp(b / 100, 0, 1), 1)
	fill.BackgroundColor3 = b > 40 and Color3.fromRGB(110, 220, 120) or (b > 15 and Color3.fromRGB(240, 190, 60) or Color3.fromRGB(235, 80, 80))
	txt.Text = (on and "ON " or "OFF ") .. math.floor(b) .. "%"
end
tool:GetAttributeChangedSignal("Battery"):Connect(updateGui)
tool:GetAttributeChangedSignal("On"):Connect(updateGui)

local aimConn, lastSent = nil, 999
tool.Equipped:Connect(function()
	equipped = true
	buildGui() updateGui()
	CAS:BindAction("FlashlightToggle", function(_, state)
		if state == Enum.UserInputState.Begin then toggle() end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.F)
	local acc = 0
	aimConn = RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.12 then return end
		acc = 0
		local cam = workspace.CurrentCamera
		if not cam then return end
		local pitch = math.asin(math.clamp(cam.CFrame.LookVector.Y, -1, 1))
		if math.abs(pitch - lastSent) > math.rad(3) then lastSent = pitch remote:FireServer("aim", tool, pitch) end
	end)
end)
tool.Unequipped:Connect(function()
	equipped = false
	CAS:UnbindAction("FlashlightToggle")
	if aimConn then aimConn:Disconnect() aimConn = nil end
	lastSent = 999
	if gui then gui:Destroy() gui = nil end
end)
