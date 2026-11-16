-- TapPrompts: every interaction is "tap / click the object itself" - except DOORS (and gates) and NPCs,
-- which keep their normal E / tap-the-prompt button.
-- How: a non-door, non-NPC ProximityPrompt is switched to Custom style (no on-screen button) with no
-- keyboard / gamepad key, so E does nothing. Tapping or clicking the object then fires that prompt
-- (prompt:InputHoldBegin / InputHoldEnd), so every existing system keeps working unchanged.
-- PromptGuard still decides when a prompt is reachable (walls, range), so you cannot tap through walls.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local HAND = "rbxasset://SystemCursors/PointingHand"

local KEEP_WORDS = { "door", "gate", "knock", "staffonly", "staff only", "permission", "exit" }

local converted = {}   -- prompt -> true
local shown = {}       -- prompt -> true while ProximityPromptService shows it (in range + reachable)

local function hasWord(s)
	s = string.lower(s)
	s = s:gsub("outdoor", ""):gsub("indoor", "") -- "OutdoorBench" is not a door
	for _, w in ipairs(KEEP_WORDS) do
		if string.find(s, w, 1, true) then return true end
	end
	return false
end

-- objects that only LOOK like doors / gates by name (cabinet doors, fridge doors, signs on doors, ID readers,
-- chairs by the staff exit...) are still "tap the object"
local OBJECT_WORDS = { "cabinet", "fridge", "refrigerator", "safe", "locker", "cupboard", "drawer", "sign",
	"lock", "reader", "scan", "chair", "seat", "bench", "dispenser", "water", "button", "panel", "window",
	"curtain", "tv", "kiosk", "box", "shelf", "bookcase", "status", "switch", "lamp", "light" }
local function hasObjectWord(s)
	s = string.lower(s)
	for _, w in ipairs(OBJECT_WORDS) do
		if string.find(s, w, 1, true) then return true end
	end
	return false
end

-- doors / gates / NPCs keep the E prompt
local function keepsE(prompt)
	-- NPCs always keep it
	local a0 = prompt.Parent
	for _ = 1, 4 do
		if not a0 or a0 == workspace then break end
		if a0:IsA("Model") and a0:FindFirstChildOfClass("Humanoid") then return true end
		a0 = a0.Parent
	end
	local m = prompt:FindFirstAncestorWhichIsA("Model")
	if prompt.ActionText == "Sit" or hasObjectWord(prompt.ObjectText) or (m and hasObjectWord(m.Name)) then return false end
	if hasWord(prompt.Name) or hasWord(prompt.ObjectText) or hasWord(prompt.ActionText) then return true end
	local a = prompt.Parent
	local depth = 0
	while a and a ~= workspace and depth < 6 do
		if a:IsA("Model") and a:FindFirstChildOfClass("Humanoid") then return true end -- NPC
		if hasWord(a.Name) then return true end
		a = a.Parent
		depth += 1
	end
	return false
end

-- ===== small E button for doors / gates / NPCs (replaces Roblox's big default prompt) =====
local small = {} -- prompt -> true
local smallGui = {} -- prompt -> BillboardGui
-- the folder lives in PlayerGui, which is cleared when you respawn: it is made again whenever it's gone
-- (see ensureFolder / the respawn hook below), otherwise every door / NPC button vanished after a reset
local smallFolder
local onFolderLost -- set below: rebuilds the buttons that were on screen
local function ensureFolder()
	if smallFolder and smallFolder.Parent then return smallFolder end
	local f = Instance.new("Folder")
	f.Name = "SmallPrompts"
	f.Parent = player:WaitForChild("PlayerGui")
	smallFolder = f
	f.AncestryChanged:Connect(function()
		if not f.Parent and smallFolder == f and onFolderLost then task.defer(onFolderLost) end
	end)
	return f
end
ensureFolder()
local smallShown = {} -- prompt -> true while it is on screen (to rebuild the buttons after a respawn)
local TOUCH = UIS.TouchEnabled and not UIS.KeyboardEnabled

local function adorneeOf(prompt)
	local p = prompt.Parent
	if p:IsA("BasePart") or p:IsA("Attachment") then return p end
	if p:IsA("Model") then return p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart", true) end
	return nil
end

local function showSmall(prompt)
	local ad = adorneeOf(prompt)
	if not ad then return end
	local old = smallGui[prompt]
	if old then old:Destroy() end
	local bb = Instance.new("BillboardGui")
	bb.Name = "SmallPrompt"
	smallGui[prompt] = bb
	bb.Adornee = ad
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Size = UDim2.fromOffset(96, 24)
	bb.StudsOffset = Vector3.new(0, 0.6, 0)
	bb.ResetOnSpawn = false
	bb.Active = true
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(1, 1)
	btn.BackgroundColor3 = Color3.fromRGB(20, 24, 28)
	btn.BackgroundTransparency = 0.25
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = bb
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
	local st = Instance.new("UIStroke", btn) st.Color = Color3.fromRGB(0, 160, 100) st.Thickness = 1.2 st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local fill = Instance.new("Frame")
	fill.Name = "Hold" fill.BackgroundColor3 = Color3.fromRGB(0, 160, 100) fill.BackgroundTransparency = 0.35
	fill.Size = UDim2.fromScale(0, 1) fill.BorderSizePixel = 0 fill.Parent = btn
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	local key = Instance.new("TextLabel")
	key.Size = UDim2.fromOffset(18, 18) key.Position = UDim2.fromOffset(3, 3)
	key.BackgroundColor3 = Color3.fromRGB(245, 245, 240) key.TextColor3 = Color3.fromRGB(20, 24, 28)
	key.Font = Enum.Font.GothamBold key.TextSize = 11
	key.Text = TOUCH and "👆" or (prompt.KeyboardKeyCode ~= Enum.KeyCode.Unknown and prompt.KeyboardKeyCode.Name or "E")
	key.Parent = btn
	Instance.new("UICorner", key).CornerRadius = UDim.new(1, 0)
	local txt = Instance.new("TextLabel")
	txt.BackgroundTransparency = 1 txt.Position = UDim2.fromOffset(25, 0) txt.Size = UDim2.new(1, -29, 1, 0)
	txt.Font = Enum.Font.GothamMedium txt.TextSize = 11 txt.TextColor3 = Color3.new(1, 1, 1)
	txt.TextXAlignment = Enum.TextXAlignment.Left txt.TextTruncate = Enum.TextTruncate.AtEnd
	txt.Text = (prompt.ActionText ~= "" and prompt.ActionText ~= "Interact") and prompt.ActionText or (prompt.ObjectText ~= "" and prompt.ObjectText or "Open")
	txt.Parent = btn
	-- tap / click the little button = press E
	btn.MouseButton1Down:Connect(function() pcall(function() prompt:InputHoldBegin() end) end)
	btn.MouseButton1Up:Connect(function() pcall(function() prompt:InputHoldEnd() end) end)
	btn.MouseLeave:Connect(function() pcall(function() prompt:InputHoldEnd() end) end)
	bb.Parent = ensureFolder()
end
local function hideSmall(prompt)
	local g = smallGui[prompt]
	smallGui[prompt] = nil
	if g then g:Destroy() end
end

local function makeSmall(prompt)
	if small[prompt] then return end
	small[prompt] = true
	prompt.Style = Enum.ProximityPromptStyle.Custom -- E still works; we draw our own small button
	prompt:GetPropertyChangedSignal("Style"):Connect(function()
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then prompt.Style = Enum.ProximityPromptStyle.Custom end
	end)
	prompt.PromptShown:Connect(function() smallShown[prompt] = true showSmall(prompt) end)
	prompt.PromptHidden:Connect(function() smallShown[prompt] = nil hideSmall(prompt) end)
	prompt.PromptButtonHoldBegan:Connect(function()
		local g = smallGui[prompt]
		local fill = g and g:FindFirstChild("Hold", true)
		if fill and prompt.HoldDuration > 0 then
			fill.Size = UDim2.fromScale(0, 1)
			game:GetService("TweenService"):Create(fill, TweenInfo.new(prompt.HoldDuration), { Size = UDim2.fromScale(1, 1) }):Play()
		end
	end)
	prompt.PromptButtonHoldEnded:Connect(function()
		local g = smallGui[prompt]
		local fill = g and g:FindFirstChild("Hold", true)
		if fill then fill.Size = UDim2.fromScale(0, 1) end
	end)
	-- label follows the door state ("Open" / "Close")
	prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
		if smallGui[prompt] then showSmall(prompt) end
	end)
	prompt.AncestryChanged:Connect(function()
		if not prompt:IsDescendantOf(workspace) then small[prompt] = nil smallShown[prompt] = nil hideSmall(prompt) end
	end)
end

-- respawn: PlayerGui was cleared, so put the buttons of the prompts that are still showing back on screen
onFolderLost = function()
	ensureFolder()
	for prompt in pairs(smallShown) do
		if prompt.Parent and (not smallGui[prompt] or not smallGui[prompt].Parent) then showSmall(prompt) end
	end
end
player.CharacterAdded:Connect(function() task.wait(0.3) onFolderLost() end)

local function convert(prompt)
	if converted[prompt] or not prompt:IsA("ProximityPrompt") then return end
	if not prompt:IsDescendantOf(workspace) then return end
	if keepsE(prompt) then makeSmall(prompt) return end
	converted[prompt] = true
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.KeyboardKeyCode = Enum.KeyCode.Unknown
	prompt.GamepadKeyCode = Enum.KeyCode.Unknown
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	prompt.ClickablePrompt = false
	prompt.PromptShown:Connect(function() shown[prompt] = true end)
	prompt.PromptHidden:Connect(function() shown[prompt] = nil end)
	prompt.AncestryChanged:Connect(function()
		if not prompt:IsDescendantOf(workspace) then converted[prompt] = nil shown[prompt] = nil end
	end)
	-- keep it key-less even if a script tries to put E back
	prompt:GetPropertyChangedSignal("KeyboardKeyCode"):Connect(function()
		if prompt.KeyboardKeyCode ~= Enum.KeyCode.Unknown then prompt.KeyboardKeyCode = Enum.KeyCode.Unknown end
	end)
	prompt:GetPropertyChangedSignal("Exclusivity"):Connect(function()
		if prompt.Exclusivity ~= Enum.ProximityPromptExclusivity.AlwaysShow then prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow end
	end)
	prompt:GetPropertyChangedSignal("Style"):Connect(function()
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then prompt.Style = Enum.ProximityPromptStyle.Custom end
	end)
end

for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("ProximityPrompt") then convert(d) end
end
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("ProximityPrompt") then task.defer(convert, d) end
end)

-- where a prompt sits in the world
local function promptPos(prompt)
	local p = prompt.Parent
	if p:IsA("BasePart") then return p.Position end
	if p:IsA("Attachment") then return p.WorldPosition end
	if p:IsA("Model") then return p:GetPivot().Position end
	return nil
end

-- the object a prompt belongs to (the part, or its small model)
local function ownerRoot(prompt)
	local p = prompt.Parent
	if p:IsA("Attachment") then p = p.Parent end
	local m = p:FindFirstAncestorWhichIsA("Model")
	if p:IsA("Model") then m = p end
	if m and m ~= workspace then
		local ok, _, size = pcall(function() return m:GetBoundingBox() end)
		if ok and size and size.Magnitude <= 30 then return m end
	end
	return p
end

-- find the shown, converted prompt that belongs to the tapped part
local function promptFor(hitPart, hitPos)
	local best, bestD
	for prompt in pairs(shown) do
		if converted[prompt] and prompt.Enabled and prompt.Parent then
			local root = ownerRoot(prompt)
			if root and (hitPart == root or hitPart:IsDescendantOf(root)) then
				local pos = promptPos(prompt)
				local d = pos and (pos - hitPos).Magnitude or 0
				if not bestD or d < bestD then best, bestD = prompt, d end
			end
		end
	end
	return best
end

-- pos is a viewport position (mouse) or a screen/GUI position (touch)
local function worldHit(pos, isGuiPos)
	local cam = workspace.CurrentCamera
	local ray = isGuiPos and cam:ScreenPointToRay(pos.X, pos.Y) or cam:ViewportPointToRay(pos.X, pos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local origin, dir = ray.Origin, ray.Direction * 120
	for _ = 1, 6 do
		local r = workspace:Raycast(origin, dir, params)
		if not r then return nil end
		-- skip invisible helper parts (fall guards, colliders) so you hit what you see
		if r.Instance.Transparency >= 0.95 then
			params:AddToFilter(r.Instance)
		else
			return r.Instance, r.Position
		end
	end
	return nil
end

-- INSTANT FEEDBACK: the moment you tap, you hear a click and the thing you tapped flashes,
-- so it never feels like the tap was missed while the server answers.
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local clickSnd = Instance.new("Sound")
clickSnd.Name = "SC_TapClick" clickSnd.SoundId = "rbxasset://sounds/electronicpingshort.wav" clickSnd.Volume = 0.4
clickSnd.Parent = SoundService
local function feedback(part)
	pcall(function() SoundService:PlayLocalSound(clickSnd) end)
	if not (part and part.Parent) then return end
	local h = Instance.new("Highlight")
	h.Adornee = part h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.FillColor = Color3.fromRGB(140, 255, 190) h.FillTransparency = 0.45
	h.OutlineColor = Color3.new(1, 1, 1) h.OutlineTransparency = 0.1
	h.Parent = workspace.CurrentCamera
	local tw = TweenService:Create(h, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { FillTransparency = 1, OutlineTransparency = 1 })
	tw:Play()
	tw.Completed:Connect(function() h:Destroy() end)
end

local busy = false
local function fire(prompt, part)
	if busy then return end
	busy = true
	feedback(part)
	task.spawn(function()
		pcall(function() prompt:InputHoldBegin() end)
		if prompt.HoldDuration > 0 then task.wait(prompt.HoldDuration + 0.05) else task.wait() end
		pcall(function() prompt:InputHoldEnd() end)
		task.wait(0.15)
		busy = false
	end)
end

local function tryTap(screenPos, isGuiPos)
	local part, pos = worldHit(screenPos, isGuiPos)
	if not part then return end
	local prompt = promptFor(part, pos)
	if prompt then fire(prompt, part) end
end

-- mouse click (PC)
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tryTap(UIS:GetMouseLocation(), false)
	end
end)
-- tap (mobile / tablet): only real taps in the 3D world, not camera drags or GUI
UIS.TouchTapInWorld:Connect(function(position, processed)
	if processed then return end
	tryTap(position, true)
end)

-- hand cursor when hovering something you can tap
local hovering = false
RunService.RenderStepped:Connect(function()
	if UIS.TouchEnabled and not UIS.MouseEnabled then return end
	local can = false
	if next(shown) then
		local part, pos = worldHit(UIS:GetMouseLocation(), false)
		can = part ~= nil and promptFor(part, pos) ~= nil
	end
	if can ~= hovering then
		hovering = can
		mouse.Icon = can and HAND or ""
	end
end)
