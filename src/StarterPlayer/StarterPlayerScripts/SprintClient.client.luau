-- SprintClient: 🏃 RUN toggle
-- • phones / tablets: a RUN button next to the jump button, tap it to switch running on / off
-- • PC: no button, press Z to switch running on / off
-- The server (SprintServer + ShopServer) changes the real walk speed, so it stacks with
-- Running Shoes / Speed Coil and does nothing while an event is controlling your speed.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local remote = RS:WaitForChild("SprintRemote", 30)

-- phones / tablets (a touchscreen laptop with a mouse counts as a PC)
local TOUCH = UIS.TouchEnabled and (not UIS.KeyboardEnabled or not UIS.MouseEnabled)
local GREEN = Color3.fromRGB(20, 140, 100)
local OFF = Color3.fromRGB(28, 30, 38)

local gui = Instance.new("ScreenGui")
gui.Name = "SprintGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.IgnoreGuiInset = true -- positions below are real screen pixels
gui.Parent = player:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.Name = "RunButton"
btn.AutoButtonColor = true
btn.AnchorPoint = Vector2.new(1, 1)
btn.Size = TOUCH and UDim2.fromOffset(64, 64) or UDim2.fromOffset(84, 84)
-- phones: just left of / above Roblox's jump button; PCs: bottom-right corner
btn.Position = TOUCH and UDim2.new(1, -112, 1, -96) or UDim2.new(1, -18, 1, -18)
btn.BackgroundColor3 = OFF
btn.BackgroundTransparency = 0.15
btn.Text = ""
btn.Visible = false -- shown only on phones / tablets (see placeNextToJump)
btn.Parent = gui
local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(1, 0) corner.Parent = btn
local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(255, 255, 255) stroke.Transparency = 0.6 stroke.Thickness = 2 stroke.Parent = btn
local icon = Instance.new("TextLabel")
icon.BackgroundTransparency = 1
icon.Size = UDim2.new(1, 0, 0.6, 0)
icon.Position = UDim2.fromScale(0, 0.08)
icon.Text = "🏃"
icon.TextScaled = true
icon.Font = Enum.Font.GothamBold
icon.Parent = btn
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size = UDim2.new(1, 0, 0.28, 0)
label.Position = UDim2.fromScale(0, 0.66)
label.Text = TOUCH and "RUN" or "RUN [Shift]"
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.GothamBold
label.Parent = btn
local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 6) pad.PaddingRight = UDim.new(0, 6) pad.Parent = label

-- PHONES & TABLETS: sit just left of (and a bit above) Roblox's own jump button. The jump button is
-- 70 px on phones and 120 px higher up on tablets, so the RUN button follows wherever it really is.
local GuiService = game:GetService("GuiService")
local jumpConns = {}
-- PC / keyboard layout: bottom-right corner
local function placePC()
	btn.Visible = false -- PC players use the Z key instead
end
-- mobile layout is used whenever Roblox is actually SHOWING its touch jump button
-- (more reliable than guessing the device: emulators and tablets with keyboards report both)
local function jumpShown(jump)
	if not (jump and jump.AbsoluteSize.X > 0 and jump.Visible) then return false end
	local p = jump.Parent
	while p and p:IsA("GuiObject") do if not p.Visible then return false end p = p.Parent end
	local tg = jump:FindFirstAncestorWhichIsA("ScreenGui")
	return tg ~= nil and tg.Enabled
end
local function placeNextToJump()
	local tg = player.PlayerGui:FindFirstChild("TouchGui")
	local jump = tg and tg:FindFirstChild("JumpButton", true)
	if not jumpShown(jump) then placePC() return end
	label.Text = "RUN"
	btn.Visible = true
	local insetY = tg.IgnoreGuiInset and 0 or GuiService:GetGuiInset().Y
	local js = jump.AbsoluteSize.X
	local size = math.clamp(math.floor(js * 0.85), 56, 96)
	local jumpLeft = jump.AbsolutePosition.X
	local jumpTop = jump.AbsolutePosition.Y + insetY
	btn.Size = UDim2.fromOffset(size, size)
	btn.AnchorPoint = Vector2.new(1, 1)
	btn.Position = UDim2.fromOffset(jumpLeft - 12, jumpTop + js * 0.35)
end
local function watchJump()
	for _, c in ipairs(jumpConns) do c:Disconnect() end
	table.clear(jumpConns)
	local tg = player.PlayerGui:FindFirstChild("TouchGui")
	local jump = tg and tg:FindFirstChild("JumpButton", true)
	if not jump then return end
	table.insert(jumpConns, jump:GetPropertyChangedSignal("AbsolutePosition"):Connect(placeNextToJump))
	table.insert(jumpConns, jump:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeNextToJump))
	table.insert(jumpConns, jump:GetPropertyChangedSignal("Visible"):Connect(placeNextToJump))
	local tg = jump:FindFirstAncestorWhichIsA("ScreenGui")
	if tg then table.insert(jumpConns, tg:GetPropertyChangedSignal("Enabled"):Connect(placeNextToJump)) end
	placeNextToJump()
end
-- watch for Roblox's touch controls on every device (they appear when the player uses touch)
do
	task.spawn(function()
		local tg = player.PlayerGui:WaitForChild("TouchGui", math.huge)
		if not tg then return end
		local jump = tg:FindFirstChild("JumpButton", true)
		local t0 = os.clock()
		while not jump and os.clock() - t0 < 60 do task.wait(0.5) jump = tg:FindFirstChild("JumpButton", true) end
		watchJump()
		tg.DescendantAdded:Connect(function(d) if d.Name == "JumpButton" then task.defer(watchJump) end end)
	end)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() task.defer(placeNextToJump) end)
end

local sprinting = false
local function render()
	btn.BackgroundColor3 = sprinting and GREEN or OFF
	stroke.Transparency = sprinting and 0.1 or 0.6
end
-- small camera zoom-out while running (back to whatever it was before)
local baseFov
local function fov(on)
	local cam = workspace.CurrentCamera
	if not cam then return end
	if on then
		baseFov = cam.FieldOfView
		TweenService:Create(cam, TweenInfo.new(0.25), { FieldOfView = baseFov + 8 }):Play()
	elseif baseFov then
		TweenService:Create(cam, TweenInfo.new(0.25), { FieldOfView = baseFov }):Play()
		baseFov = nil
	end
end
local function setSprint(on)
	if on == sprinting then return end
	sprinting = on
	render()
	fov(on)
	if remote then remote:FireServer(on) end
end

btn.Activated:Connect(function() setSprint(not sprinting) end)

-- keyboard: press Z to switch running on / off (ignored while typing in chat or a text box)
UIS.InputBegan:Connect(function(input, processed)
	if processed or UIS:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.Z then setSprint(not sprinting) end
end)

-- PC: short hint at the start so players know about the Z key
task.delay(4, function()
	if btn.Visible or TOUCH then return end -- phones / tablets use the button
	local hint = Instance.new("TextLabel")
	hint.Name = "RunHint"
	hint.AnchorPoint = Vector2.new(1, 1)
	hint.Position = UDim2.new(1, -18, 1, -18)
	hint.Size = UDim2.fromOffset(190, 34)
	hint.BackgroundColor3 = OFF
	hint.BackgroundTransparency = 0.2
	hint.TextColor3 = Color3.fromRGB(255, 255, 255)
	hint.Font = Enum.Font.GothamBold
	hint.TextSize = 15
	hint.Text = "🏃 Press Z to run"
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 10) c.Parent = hint
	hint.Parent = gui
	task.wait(6)
	local t = TweenService:Create(hint, TweenInfo.new(0.6), { BackgroundTransparency = 1, TextTransparency = 1 })
	t:Play() t.Completed:Wait() hint:Destroy()
end)

-- after respawning you walk again
player.CharacterAdded:Connect(function()
	if sprinting then sprinting = false fov(false) end
	render()
end)
render()
