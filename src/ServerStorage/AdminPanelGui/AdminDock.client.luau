--[[ AdminDock — the 🛡 Admin and 🎪 Events buttons live together in a small floating dock that
  admins can DRAG anywhere (mouse or touch, using the ≡ Move handle) and HIDE / SHOW with the 👁 button.
  Position and hidden state are remembered for this session (also after respawning). ]]
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local gui = script.Parent
local playerGui = player:WaitForChild("PlayerGui")

local DARK, GOLD = Color3.fromRGB(28, 32, 42), Color3.fromRGB(255, 205, 90)
local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = p end

-- wait for the two buttons (made by AdminClient + EventAdminClient)
local hud = playerGui:WaitForChild("MainHUD", 20)
local rail = hud and hud:WaitForChild("Rail", 10)
local adminBtn = rail and rail:WaitForChild("AdminButton", 15)
local eventsBtn = gui:WaitForChild("EventsButton", 15)
if not adminBtn and not eventsBtn then return end

-- dock frame
local dock = Instance.new("Frame") dock.Name = "AdminDockFrame" dock.BackgroundColor3 = DARK dock.BackgroundTransparency = 0.15
dock.AutomaticSize = Enum.AutomaticSize.XY dock.Size = UDim2.fromOffset(0, 0) dock.ZIndex = 50 dock.Parent = gui corner(dock, 12)
local st = Instance.new("UIStroke") st.Color = GOLD st.Transparency = 0.4 st.Thickness = 1.5 st.Parent = dock
local pad = Instance.new("UIPadding") for _, k in ipairs({ "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight" }) do pad[k] = UDim.new(0, 6) end pad.Parent = dock
local lay = Instance.new("UIListLayout") lay.Padding = UDim.new(0, 6) lay.SortOrder = Enum.SortOrder.LayoutOrder lay.HorizontalAlignment = Enum.HorizontalAlignment.Center lay.Parent = dock
local scale = Instance.new("UIScale") scale.Parent = dock
local function fit() local v = workspace.CurrentCamera.ViewportSize scale.Scale = math.clamp(math.min(v.X / 900, v.Y / 560), 0.62, 1) end
fit() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

-- top bar: drag handle + hide/show toggle
local bar = Instance.new("Frame") bar.Name = "TopBar" bar.LayoutOrder = 0 bar.Size = UDim2.fromOffset(110, 26) bar.BackgroundTransparency = 1 bar.Parent = dock
local grip = Instance.new("TextButton") grip.Name = "DragHandle" grip.Size = UDim2.new(1, -32, 1, 0) grip.BackgroundColor3 = Color3.fromRGB(55, 60, 75)
grip.Text = "≡ Move" grip.Font = Enum.Font.GothamBold grip.TextSize = 13 grip.TextColor3 = Color3.fromRGB(200, 205, 220) grip.AutoButtonColor = false grip.ZIndex = 51 grip.Parent = bar corner(grip, 8)
local toggle = Instance.new("TextButton") toggle.Name = "HideToggle" toggle.AnchorPoint = Vector2.new(1, 0) toggle.Position = UDim2.new(1, 0, 0, 0) toggle.Size = UDim2.fromOffset(26, 26)
toggle.BackgroundColor3 = Color3.fromRGB(55, 60, 75) toggle.Text = "👁" toggle.TextScaled = true toggle.Font = Enum.Font.GothamBold toggle.ZIndex = 51 toggle.Parent = bar corner(toggle, 8)

-- body: the two buttons
local body = Instance.new("Frame") body.Name = "Buttons" body.LayoutOrder = 1 body.BackgroundTransparency = 1 body.AutomaticSize = Enum.AutomaticSize.XY body.Size = UDim2.fromOffset(0, 0) body.Parent = dock
local bl = Instance.new("UIListLayout") bl.Padding = UDim.new(0, 6) bl.SortOrder = Enum.SortOrder.LayoutOrder bl.HorizontalAlignment = Enum.HorizontalAlignment.Center bl.Parent = body

-- default spot: just right of the Profile/Bag/Map rail, at its top (never covers those buttons)
local startPos = Vector2.new(12, 300)
if rail then startPos = Vector2.new(rail.AbsolutePosition.X + rail.AbsoluteSize.X + 10, rail.AbsolutePosition.Y) end
if adminBtn then
	adminBtn.Parent = body adminBtn.LayoutOrder = 1
	adminBtn.Size = UDim2.fromOffset(110, 60)
end
if eventsBtn then
	eventsBtn.Parent = body eventsBtn.LayoutOrder = 2
	eventsBtn.AnchorPoint = Vector2.new(0, 0) eventsBtn.Position = UDim2.new() eventsBtn.Size = UDim2.fromOffset(110, 34)
end
local saved = player:GetAttribute("AdminDockPos")
dock.Position = typeof(saved) == "Vector2" and UDim2.fromOffset(saved.X, saved.Y) or UDim2.fromOffset(startPos.X, startPos.Y)

-- keep the dock on screen
local function clamp()
	local v = gui.AbsoluteSize
	local s = dock.AbsoluteSize
	local x = math.clamp(dock.Position.X.Offset, 0, math.max(0, v.X - s.X))
	local y = math.clamp(dock.Position.Y.Offset, 0, math.max(0, v.Y - s.Y))
	dock.Position = UDim2.fromOffset(x, y)
end
task.defer(clamp)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() task.defer(clamp) end)

-- hide / show
local moved = false
local function setHidden(h)
	body.Visible = not h
	grip.Visible = not h
	bar.Size = h and UDim2.fromOffset(26, 26) or UDim2.fromOffset(110, 26)
	toggle.Text = h and "🛡" or "👁"
	dock.BackgroundTransparency = h and 0.4 or 0.15
	player:SetAttribute("AdminDockHidden", h)
	task.defer(clamp)
end
toggle.MouseButton1Click:Connect(function()
	if moved then moved = false return end -- it was a drag, not a tap
	setHidden(body.Visible)
end)
setHidden(player:GetAttribute("AdminDockHidden") == true)

-- dragging (mouse + touch) by the handle, or by the 🛡 tab while hidden
local dragging, dragStart, startOffset, dragInput
local function begin(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	dragging, dragStart, startOffset, dragInput = true, input.Position, Vector2.new(dock.Position.X.Offset, dock.Position.Y.Offset), input
	st.Transparency = 0
	input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			dragging = false st.Transparency = 0.4
			player:SetAttribute("AdminDockPos", Vector2.new(dock.Position.X.Offset, dock.Position.Y.Offset))
		end
	end)
end
grip.InputBegan:Connect(begin)
toggle.InputBegan:Connect(function(input) if not body.Visible then moved = false begin(input) end end)
UIS.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput or input.UserInputType == Enum.UserInputType.Touch then
		local delta = (Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(dragStart.X, dragStart.Y)) / scale.Scale * scale.Scale
		if delta.Magnitude > 4 then moved = true end
		local p = startOffset + delta
		dock.Position = UDim2.fromOffset(p.X, p.Y)
		clamp()
	end
end)
