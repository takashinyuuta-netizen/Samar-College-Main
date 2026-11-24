--[[ GearClient — the parts of the Roblox gear that run on YOUR character (smooth physics, controls, menus).
  🌀 Gravity Coil (held)      : gravity feels 75% lighter → huge jumps, slow floaty falls (+ boing sound on jump)
  🥪 Space Sandwich (eaten)   : 20 s of low gravity (player attribute LowGravityUntil from the server)
  🌈 Magic Carpet (held)      : FLY! WASD / thumbstick steer (where the camera looks), Space = up, Shift/Ctrl = down
                               (phones get ▲ ▼ buttons). Sitting animation, smooth speed, banking turns.
  🧬 Body Swap Potion        : picker — 🎲 random player or choose one (ReplicatedStorage.OpenBodySwap). ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function holding(name)
	local ch = player.Character
	local t = ch and ch:FindFirstChild(name)
	return t and t:IsA("Tool") and t or nil
end

---------------------------------------------------------------- LOW GRAVITY
local gravForce, gravAtt
local function lowGravityFactor()
	if holding("GravityCoil") then return 0.75 end
	local untilT = player:GetAttribute("LowGravityUntil")
	if untilT and workspace:GetServerTimeNow() < untilT then return 0.6 end
	return 0
end
local lastJump = 0
local function hookJumpSound(hum)
	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping and os.clock() - lastJump > 0.3 then
			lastJump = os.clock()
			local coil = holding("GravityCoil")
			local snd = coil and coil:FindFirstChild("Handle") and coil.Handle:FindFirstChild("CoilSound")
			if snd then snd:Play() end
		end
	end)
end

---------------------------------------------------------------- MAGIC CARPET FLYING
local fly = nil -- { lv, ao, att, track, vel }
local FLY_SPEED, FLY_ACCEL = 52, 4
local upHeld, downHeld = false, false
local flyGui = Instance.new("ScreenGui") flyGui.Name = "CarpetGui" flyGui.ResetOnSpawn = false flyGui.Enabled = false
flyGui.Parent = player:WaitForChild("PlayerGui")
local hint = Instance.new("TextLabel") hint.AnchorPoint = Vector2.new(0.5, 0) hint.Position = UDim2.new(0.5, 0, 0, 60) hint.Size = UDim2.fromOffset(460, 30) hint.TextScaled = true
hint.BackgroundColor3 = Color3.fromRGB(40, 20, 70) hint.BackgroundTransparency = 0.2 hint.TextColor3 = Color3.new(1, 1, 1) hint.Font = Enum.Font.GothamBold hint.TextSize = 13
hint.Text = "🌈 Flying!  WASD steer (where you look) • Space up • Shift down • put the carpet away to land"
hint.Visible = false -- the flying hint banner is hidden (removed from the screen); the ⬆️⬇️ phone buttons stay
hint.Parent = flyGui
Instance.new("UICorner", hint).CornerRadius = UDim.new(0, 15)
local function flyButton(text, y)
	local b = Instance.new("TextButton") b.AnchorPoint = Vector2.new(1, 1) b.Position = UDim2.new(1, -24, 1, y) b.Size = UDim2.fromOffset(64, 64)
	b.BackgroundColor3 = Color3.fromRGB(120, 60, 200) b.BackgroundTransparency = 0.15 b.Text = text b.TextColor3 = Color3.new(1, 1, 1) b.Font = Enum.Font.GothamBlack b.TextSize = 26
	b.Visible = UIS.TouchEnabled b.Parent = flyGui
	Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
	return b
end
local upBtn, downBtn = flyButton("⬆️", -172), flyButton("⬇️", -100) -- stacked just above the Jump button
upBtn.MouseButton1Down:Connect(function() upHeld = true end) upBtn.MouseButton1Up:Connect(function() upHeld = false end)
downBtn.MouseButton1Down:Connect(function() downHeld = true end) downBtn.MouseButton1Up:Connect(function() downHeld = false end)
upBtn.MouseLeave:Connect(function() upHeld = false end) downBtn.MouseLeave:Connect(function() downHeld = false end)

local controls = nil
task.spawn(function()
	local ok, pm = pcall(function() return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")) end)
	if ok and pm then controls = pm:GetControls() end
end)
local function moveVector()
	if controls then
		local ok, mv = pcall(function() return controls:GetMoveVector() end)
		if ok and mv then return mv end
	end
	local ch = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	return hum and camera.CFrame:VectorToObjectSpace(hum.MoveDirection) or Vector3.zero
end

local function startFly(tool)
	local ch = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or fly then return end
	local att = Instance.new("Attachment") att.Name = "CarpetFly" att.Parent = hrp
	local lv = Instance.new("LinearVelocity") lv.Attachment0 = att lv.MaxForce = math.huge lv.VectorVelocity = Vector3.zero
	lv.RelativeTo = Enum.ActuatorRelativeTo.World lv.Parent = hrp
	local ao = Instance.new("AlignOrientation") ao.Mode = Enum.OrientationAlignmentMode.OneAttachment ao.Attachment0 = att
	ao.Responsiveness = 18 ao.MaxTorque = math.huge ao.CFrame = CFrame.new(Vector3.zero, Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)) ao.Parent = hrp
	hum.PlatformStand = true
	-- sit on the carpet (the gear's own sitting animations)
	local track
	local animator = hum:FindFirstChildOfClass("Animator")
	local anim = tool:FindFirstChild(hum.RigType == Enum.HumanoidRigType.R15 and "SitR15" or "Sit", true)
	if animator and anim then
		pcall(function() track = animator:LoadAnimation(anim) track.Priority = Enum.AnimationPriority.Action4 track.Looped = true track:Play(0.2) end)
	end
	fly = { lv = lv, ao = ao, att = att, track = track, vel = Vector3.zero, hum = hum, hrp = hrp }
	flyGui.Enabled = true
end
local function stopFly()
	if not fly then return end
	for _, o in ipairs({ fly.lv, fly.ao, fly.att }) do if o and o.Parent then o:Destroy() end end
	if fly.track then fly.track:Stop(0.2) end
	if fly.hum and fly.hum.Parent then
		fly.hum.PlatformStand = false
		fly.hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	fly = nil
	flyGui.Enabled = false
	upHeld, downHeld = false, false
end

UIS.InputBegan:Connect(function(i, processed)
	if processed then return end
	if i.KeyCode == Enum.KeyCode.Space then upHeld = true end
	if i.KeyCode == Enum.KeyCode.LeftShift or i.KeyCode == Enum.KeyCode.LeftControl or i.KeyCode == Enum.KeyCode.Q then downHeld = true end
end)
UIS.InputEnded:Connect(function(i)
	if i.KeyCode == Enum.KeyCode.Space then upHeld = false end
	if i.KeyCode == Enum.KeyCode.LeftShift or i.KeyCode == Enum.KeyCode.LeftControl or i.KeyCode == Enum.KeyCode.Q then downHeld = false end
end)

---------------------------------------------------------------- every frame
RunService.Heartbeat:Connect(function(dt)
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end
	-- carpet
	local carpet = holding("MagicCarpet")
	if carpet and hum.Health > 0 then
		if not fly then startFly(carpet) end
	elseif fly then
		stopFly()
	end
	if fly then
		local mv = moveVector()
		local cf = camera.CFrame
		local dir = cf.LookVector * -mv.Z + cf.RightVector * mv.X
		local vert = (upHeld and 1 or 0) - (downHeld and 1 or 0)
		local want = dir * FLY_SPEED + Vector3.new(0, vert * FLY_SPEED * 0.7, 0)
		fly.vel = fly.vel:Lerp(want, math.min(1, dt * FLY_ACCEL))
		-- gentle hover bob when still
		local bob = want.Magnitude < 1 and math.sin(os.clock() * 2) * 0.6 or 0
		fly.lv.VectorVelocity = fly.vel + Vector3.new(0, bob, 0)
		local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
		if flat.Magnitude > 0.01 then
			local bank = math.clamp(-mv.X * 0.35, -0.35, 0.35)
			local pitch = math.clamp(-fly.vel.Y / FLY_SPEED * 0.25, -0.25, 0.25)
			fly.ao.CFrame = CFrame.lookAt(Vector3.zero, flat.Unit) * CFrame.Angles(pitch, 0, bank)
		end
		return
	end
	-- low gravity (coil / space sandwich)
	local f = lowGravityFactor()
	if f > 0 then
		if not gravForce or gravForce.Parent ~= hrp then
			gravAtt = Instance.new("Attachment") gravAtt.Name = "LowGravity" gravAtt.Parent = hrp
			gravForce = Instance.new("VectorForce") gravForce.Attachment0 = gravAtt gravForce.RelativeTo = Enum.ActuatorRelativeTo.World
			gravForce.ApplyAtCenterOfMass = true gravForce.Parent = hrp
			hookJumpSound(hum)
		end
		gravForce.Force = Vector3.new(0, hrp.AssemblyMass * workspace.Gravity * f, 0)
	elseif gravForce then
		gravForce:Destroy() if gravAtt then gravAtt:Destroy() end
		gravForce, gravAtt = nil, nil
	end
end)
player.CharacterAdded:Connect(function() fly = nil flyGui.Enabled = false gravForce, gravAtt = nil, nil end)

---------------------------------------------------------------- BODY SWAP PICKER
local swapRemote = RS:WaitForChild("ShopRemotes"):WaitForChild("BodySwap", 30)
local openEvent = RS:WaitForChild("OpenBodySwap", 30)
local swapGui = Instance.new("ScreenGui") swapGui.Name = "BodySwapGui" swapGui.ResetOnSpawn = false swapGui.DisplayOrder = 12 swapGui.Enabled = false
swapGui.Parent = player:WaitForChild("PlayerGui")
local shade = Instance.new("TextButton") shade.Size = UDim2.fromScale(1, 1) shade.BackgroundColor3 = Color3.new(0, 0, 0) shade.BackgroundTransparency = 0.45 shade.Text = "" shade.AutoButtonColor = false shade.Parent = swapGui
local card = Instance.new("Frame") card.AnchorPoint = Vector2.new(0.5, 0.5) card.Position = UDim2.fromScale(0.5, 0.5) card.Size = UDim2.fromOffset(420, 430)
card.BackgroundColor3 = Color3.fromRGB(26, 22, 38) card.Parent = swapGui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)
local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(170, 90, 255) st.Thickness = 2 st.Parent = card
local scale = Instance.new("UIScale") scale.Parent = card
local function fit() local v = camera.ViewportSize local h = v.Y - game:GetService("GuiService"):GetGuiInset().Y scale.Scale = math.clamp(math.min((v.X - 20) / 420, (h - 16) / 430), 0.4, 1) end
fit() camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
local function lbl(text, y, h, size, color, font)
	local l = Instance.new("TextLabel") l.BackgroundTransparency = 1 l.Position = UDim2.fromOffset(20, y) l.Size = UDim2.new(1, -40, 0, h) l.Text = text
	l.TextColor3 = color or Color3.new(1, 1, 1) l.Font = font or Enum.Font.GothamBlack l.TextSize = size l.TextWrapped = true l.Parent = card
	return l
end
lbl("🧬 BODY SWAP POTION", 14, 30, 22, Color3.fromRGB(210, 170, 255))
local sub = lbl("", 46, 40, 13, Color3.fromRGB(190, 190, 205), Enum.Font.GothamMedium)
local function btn(text, y, color)
	local b = Instance.new("TextButton") b.Position = UDim2.fromOffset(20, y) b.Size = UDim2.new(1, -40, 0, 46) b.BackgroundColor3 = color
	b.Text = text b.TextColor3 = Color3.new(1, 1, 1) b.Font = Enum.Font.GothamBold b.TextSize = 16 b.Parent = card
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
	return b
end
local randomBtn = btn("🎲  Swap with a RANDOM player", 92, Color3.fromRGB(150, 70, 230))
lbl("…or pick someone:", 146, 20, 13, Color3.fromRGB(190, 190, 205), Enum.Font.GothamBold)
local list = Instance.new("ScrollingFrame") list.Position = UDim2.fromOffset(20, 170) list.Size = UDim2.new(1, -40, 1, -236) list.BackgroundTransparency = 1
list.BorderSizePixel = 0 list.ScrollBarThickness = 5 list.CanvasSize = UDim2.new() list.AutomaticCanvasSize = Enum.AutomaticSize.Y list.Parent = card
local lay = Instance.new("UIListLayout") lay.Padding = UDim.new(0, 6) lay.Parent = list
local cancel = btn("Cancel", 0, Color3.fromRGB(60, 60, 75)) cancel.Position = UDim2.new(0, 20, 1, -58)
local empty = lbl("Nobody else is in this server right now — the potion needs another player to copy.", 200, 60, 13, Color3.fromRGB(255, 200, 120), Enum.Font.GothamBold)

local function potionCount()
	local inv = player:FindFirstChild("Inventory")
	local v = inv and inv:FindFirstChild("BodySwapPotion")
	return v and v.Value or 0
end
local function close() swapGui.Enabled = false end
local function choose(target)
	if swapRemote then swapRemote:FireServer(target) end
	close()
end
local function open()
	for _, c in ipairs(list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local others = {}
	for _, p in ipairs(Players:GetPlayers()) do if p ~= player then table.insert(others, p) end end
	local n = potionCount()
	sub.Text = ("You have %d potion%s. You'll look like them for 3 minutes — they don't change, only YOU."):format(n, n == 1 and "" or "s")
		.. (player:GetAttribute("BodySwappedWith") and ("\nRight now you are: " .. player:GetAttribute("BodySwappedWith")) or "")
	empty.Visible = #others == 0
	randomBtn.Visible = #others > 0
	for _, p in ipairs(others) do
		local row = Instance.new("TextButton") row.Size = UDim2.new(1, -8, 0, 52) row.BackgroundColor3 = Color3.fromRGB(44, 40, 60) row.Text = "" row.Parent = list
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
		local img = Instance.new("ImageLabel") img.Size = UDim2.fromOffset(42, 42) img.Position = UDim2.fromOffset(5, 5) img.BackgroundColor3 = Color3.fromRGB(70, 60, 95) img.Parent = row
		Instance.new("UICorner", img).CornerRadius = UDim.new(1, 0)
		task.spawn(function()
			local ok, url = pcall(function() return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
			if ok then img.Image = url end
		end)
		local name = Instance.new("TextLabel") name.BackgroundTransparency = 1 name.Position = UDim2.fromOffset(56, 6) name.Size = UDim2.new(1, -150, 0, 22)
		name.Text = p.DisplayName name.TextColor3 = Color3.new(1, 1, 1) name.Font = Enum.Font.GothamBold name.TextSize = 15 name.TextXAlignment = Enum.TextXAlignment.Left name.Parent = row
		local user = name:Clone() user.Position = UDim2.fromOffset(56, 27) user.Text = "@" .. p.Name user.TextColor3 = Color3.fromRGB(170, 170, 185) user.Font = Enum.Font.Gotham user.TextSize = 12 user.Parent = row
		local go = Instance.new("TextLabel") go.BackgroundTransparency = 1 go.AnchorPoint = Vector2.new(1, 0) go.Position = UDim2.new(1, -10, 0, 0) go.Size = UDim2.fromOffset(80, 52)
		go.Text = "🧬 Swap" go.TextColor3 = Color3.fromRGB(210, 170, 255) go.Font = Enum.Font.GothamBold go.TextSize = 14 go.Parent = row
		row.MouseButton1Click:Connect(function() choose(p.UserId) end)
	end
	swapGui.Enabled = true
end
randomBtn.MouseButton1Click:Connect(function() choose("random") end)
cancel.MouseButton1Click:Connect(close)
shade.MouseButton1Click:Connect(close)
if openEvent then openEvent.Event:Connect(function()
	if potionCount() <= 0 then return end
	open()
end) end
