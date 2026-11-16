-- HotbarClient: bottom inventory hotbar (keys 1-9 / tap).
-- Shows ONLY the items you EQUIPPED (in your Bag [I]), in the order you equipped them (player attribute "Hotbar").
-- Unequip something in the Bag (or the little X on a slot / long-press on phones) and it leaves the hotbar.
-- Press: Consumable = use one (shows count) • Flashlight = hold / put away • shoes, boots, cosmetics = they are
-- simply ON while they're on the hotbar.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local gui = script.Parent
local shopItems = require(RS:WaitForChild("ShopItems"))
local remotes = RS:WaitForChild("ShopRemotes")
local equipRemote = remotes:WaitForChild("EquipItem")
local useRemote = remotes:WaitForChild("UseItem")

-- our own hotbar replaces Roblox's backpack bar. Keep it off (other scripts may turn "All" core UI back on,
-- e.g. the loading screen when it finishes), so tools like the stage mic never show a second bar.
task.spawn(function()
	while true do
		local ok, on = pcall(function() return StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) end)
		if not ok or on then pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end) end
		task.wait(1)
	end
end)

local SLOTS = 9
local C = {
	panel = Color3.fromRGB(22, 26, 36), slot = Color3.fromRGB(34, 40, 54), slotHover = Color3.fromRGB(46, 54, 72),
	stroke = Color3.fromRGB(70, 82, 104), equip = Color3.fromRGB(72, 214, 120), consume = Color3.fromRGB(255, 196, 64),
	cosmetic = Color3.fromRGB(176, 132, 255), equipment = Color3.fromRGB(86, 170, 255), text = Color3.fromRGB(235, 240, 248), dim = Color3.fromRGB(140, 150, 170),
}
local CAT_COLOR = { Equipment = C.equipment, Consumable = C.consume, Cosmetic = C.cosmetic, Mic = Color3.fromRGB(235, 70, 150), Emote = Color3.fromRGB(190, 110, 255) }
-- Talent Stage extras (temporary slots): the stage mic while you hold it, and emotes you added while dancing
local Emotes = nil
task.spawn(function()
	local ts = RS:WaitForChild("TalentShow", 30)
	if ts then Emotes = require(ts:WaitForChild("Emotes")) end
end)
local talentEvent = nil
local function micTool()
	local ch, bp = player.Character, player:FindFirstChild("Backpack")
	return (ch and ch:FindFirstChild("Microphone")) or (bp and bp:FindFirstChild("Microphone"))
end

local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = p return c end
local function stroke(p, col, t) local s = Instance.new("UIStroke") s.Color = col s.Thickness = t or 1.5 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = p return s end

-- ===== layout =====
local holder = Instance.new("Frame") holder.Name = "Hotbar" holder.AnchorPoint = Vector2.new(0.5, 1)
holder.Position = UDim2.new(0.5, 0, 1, -14) holder.Size = UDim2.fromOffset(SLOTS * 62 + 24, 84)
holder.BackgroundColor3 = C.panel holder.BackgroundTransparency = 0.18 holder.Parent = gui
corner(holder, 16) stroke(holder, C.stroke, 1.2)
local scale = Instance.new("UIScale") scale.Parent = holder
-- fit any screen: phones (Android / iPhone), tablets, PC. On touch screens keep clear of the
-- thumbstick (bottom-left) and jump button (bottom-right).
local BASE_W, BASE_H = SLOTS * 62 + 24, 84 + 24 -- bar + title line above it
local function isTouch()
	-- phones / tablets (also when testing with Studio's device emulator)
	local v = workspace.CurrentCamera.ViewportSize
	return UIS.TouchEnabled and (not UIS.KeyboardEnabled or math.min(v.X, v.Y) < 900)
end
local function rescale()
	local vp = gui.AbsoluteSize
	if vp.X < 2 then vp = workspace.CurrentCamera.ViewportSize end
	local short = math.min(vp.X, vp.Y)
	local side = 16
	if isTouch() then side = short <= 500 and 105 or 150 end -- jump button / thumbstick zones
	local availW = math.max(vp.X - side * 2, 200)
	local availH = vp.Y * (isTouch() and 0.25 or 0.16)
	scale.Scale = math.clamp(math.min(availW / BASE_W, availH / BASE_H, 1), 0.42, 1)
	holder.Position = UDim2.new(0.5, 0, 1, isTouch() and -8 or -14)
end
rescale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)
UIS.LastInputTypeChanged:Connect(rescale)

local title = Instance.new("TextLabel") title.Name = "Title" title.BackgroundTransparency = 1
title.AnchorPoint = Vector2.new(0, 1) title.Position = UDim2.new(0, 14, 0, -2) title.Size = UDim2.fromOffset(260, 20)
title.Font = Enum.Font.GothamBold title.TextSize = 13 title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = C.text title.Text = "🎒 INVENTORY" title.TextStrokeTransparency = 0.6 title.Parent = holder
local hint = title:Clone() hint.Name = "Hint" hint.AnchorPoint = Vector2.new(1, 1) hint.Position = UDim2.new(1, -14, 0, -2)
hint.TextXAlignment = Enum.TextXAlignment.Right hint.Font = Enum.Font.Gotham hint.TextSize = 12 hint.TextColor3 = C.dim
hint.Text = "1-9 to use  •  [I] Bag" hint.Parent = holder
local function hintTail() return isTouch() and "Tap to use" or "1-9 to use  •  [I] Bag" end

local row = Instance.new("Frame") row.BackgroundTransparency = 1 row.Position = UDim2.fromOffset(12, 12) row.Size = UDim2.new(1, -24, 0, 58) row.Parent = holder
local lay = Instance.new("UIListLayout") lay.FillDirection = Enum.FillDirection.Horizontal lay.Padding = UDim.new(0, 6)
lay.HorizontalAlignment = Enum.HorizontalAlignment.Center lay.Parent = row

-- tooltip
local tip = Instance.new("Frame") tip.Name = "Tooltip" tip.AnchorPoint = Vector2.new(0.5, 1) tip.Size = UDim2.fromOffset(190, 52)
tip.BackgroundColor3 = C.panel tip.BackgroundTransparency = 0.05 tip.Visible = false tip.ZIndex = 20 tip.Parent = gui
corner(tip, 10) local tipStroke = stroke(tip, C.stroke, 1.2)
local tipName = Instance.new("TextLabel") tipName.BackgroundTransparency = 1 tipName.Position = UDim2.fromOffset(10, 6) tipName.Size = UDim2.new(1, -20, 0, 18)
tipName.Font = Enum.Font.GothamBold tipName.TextSize = 14 tipName.TextColor3 = C.text tipName.TextXAlignment = Enum.TextXAlignment.Left tipName.ZIndex = 21 tipName.Parent = tip
local tipDesc = tipName:Clone() tipDesc.Position = UDim2.fromOffset(10, 25) tipDesc.Size = UDim2.new(1, -20, 0, 20)
tipDesc.Font = Enum.Font.Gotham tipDesc.TextSize = 11 tipDesc.TextColor3 = C.dim tipDesc.TextWrapped = true tipDesc.Parent = tip

local slots = {}
for i = 1, SLOTS do
	local b = Instance.new("TextButton") b.Name = "Slot" .. i b.Size = UDim2.fromOffset(56, 56) b.AutoButtonColor = false
	b.BackgroundColor3 = C.slot b.Text = "" b.LayoutOrder = i b.Parent = row
	corner(b, 12) local st = stroke(b, C.stroke, 1.5)
	local icon = Instance.new("TextLabel") icon.Name = "Icon" icon.BackgroundTransparency = 1 icon.Size = UDim2.new(1, 0, 1, -6)
	icon.Font = Enum.Font.GothamBold icon.TextScaled = true icon.Text = "" icon.Parent = b
	local pad = Instance.new("UIPadding") pad.PaddingTop = UDim.new(0, 9) pad.PaddingBottom = UDim.new(0, 4) pad.PaddingLeft = UDim.new(0, 10) pad.PaddingRight = UDim.new(0, 10) pad.Parent = icon
	local key = Instance.new("TextLabel") key.Name = "Key" key.BackgroundTransparency = 1 key.Position = UDim2.fromOffset(5, 2) key.Size = UDim2.fromOffset(14, 14)
	key.Font = Enum.Font.GothamBold key.TextSize = 11 key.TextColor3 = C.dim key.Text = tostring(i) key.TextXAlignment = Enum.TextXAlignment.Left key.Parent = b
	local count = Instance.new("TextLabel") count.Name = "Count" count.AnchorPoint = Vector2.new(1, 1) count.Position = UDim2.new(1, -3, 1, -3)
	count.Size = UDim2.fromOffset(26, 15) count.BackgroundColor3 = C.consume count.Font = Enum.Font.GothamBlack count.TextSize = 10
	count.TextColor3 = Color3.fromRGB(30, 24, 10) count.Visible = false count.Parent = b corner(count, 6)
	local eq = Instance.new("TextLabel") eq.Name = "EquippedTag" eq.AnchorPoint = Vector2.new(1, 0) eq.Position = UDim2.new(1, -3, 0, 3)
	eq.Size = UDim2.fromOffset(16, 16) eq.BackgroundColor3 = C.equip eq.Font = Enum.Font.GothamBlack eq.TextSize = 11 eq.Text = "✓"
	eq.TextColor3 = Color3.fromRGB(10, 40, 20) eq.Visible = false eq.Parent = b corner(eq, 8)
	local bar = Instance.new("Frame") bar.Name = "CatBar" bar.AnchorPoint = Vector2.new(0.5, 1) bar.Position = UDim2.new(0.5, 0, 1, -1)
	bar.Size = UDim2.new(0.5, 0, 0, 3) bar.BorderSizePixel = 0 bar.BackgroundTransparency = 1 bar.Parent = b corner(bar, 2)
	local x = Instance.new("TextButton") x.Name = "Unequip" x.AnchorPoint = Vector2.new(1, 0) x.Position = UDim2.new(1, 4, 0, -4)
	x.Size = UDim2.fromOffset(18, 18) x.BackgroundColor3 = Color3.fromRGB(200, 70, 80) x.Text = "X" x.TextColor3 = Color3.new(1, 1, 1)
	x.Font = Enum.Font.GothamBlack x.TextSize = 10 x.Visible = false x.ZIndex = 5 x.Parent = b corner(x, 9)
	slots[i] = { button = b, stroke = st, icon = icon, count = count, eq = eq, bar = bar, x = x, item = nil, cat = nil }
end

-- small message above the hotbar
local note = Instance.new("TextLabel") note.Name = "Note" note.AnchorPoint = Vector2.new(0.5, 1) note.Position = UDim2.new(0.5, 0, 0, -28)
note.Size = UDim2.fromOffset(420, 26) note.BackgroundColor3 = C.panel note.BackgroundTransparency = 0.1 note.Font = Enum.Font.GothamBold
note.TextSize = 13 note.TextColor3 = C.text note.Visible = false note.Parent = holder corner(note, 13)
local noteToken = 0
local function showNote(text)
	noteToken += 1 local my = noteToken
	note.Text = text note.Visible = true
	task.delay(2.6, function() if my == noteToken then note.Visible = false end end)
end

local empty = Instance.new("TextLabel") empty.BackgroundTransparency = 1 empty.Size = UDim2.new(1, 0, 1, 0) empty.Font = Enum.Font.Gotham
empty.TextSize = 13 empty.TextColor3 = C.dim empty.Text = "Nothing equipped — open your Bag [I] to put items here" empty.Visible = false empty.ZIndex = 5 empty.Position = UDim2.fromOffset(0, 12) empty.Size = UDim2.new(1, 0, 0, 58) empty.Parent = holder

-- ===== data =====
local function countOf(id) local inv = player:FindFirstChild("Inventory") local v = inv and inv:FindFirstChild(id) return v and v.Value or 0 end
local byId = {}
for _, cat in ipairs({ "Equipment", "Consumable", "Cosmetic" }) do
	for _, it in ipairs(shopItems[cat] or {}) do byId[it.Id] = { it, cat } end
end
-- equipped items only, in hotbar order
local function collect()
	local list, seen = {}, {}
	local function add(id)
		local e = byId[id]
		if not e or seen[id] or not player:GetAttribute("Equipped_" .. id) then return end
		if e[2] == "Consumable" then if countOf(id) <= 0 then return end
		elseif not player:GetAttribute("Owned_" .. id) then return end
		seen[id] = true
		table.insert(list, e)
	end
	for id in string.gmatch(player:GetAttribute("Hotbar") or "", "[^,]+") do add(id) end
	for _, cat in ipairs({ "Equipment", "Consumable", "Cosmetic" }) do
		for _, it in ipairs(shopItems[cat] or {}) do add(it.Id) end
	end
	-- temporary: stage mic + dance emotes
	if micTool() then
		table.insert(list, { { Id = "__mic", Name = "Stage Microphone", Icon = "🎤", Desc = "Hold it to sing on stage" }, "Mic" })
	end
	if Emotes then
		for id in string.gmatch(player:GetAttribute("TempHotbar") or "", "[^,]+") do
			local e = Emotes.ById[id]
			if e then table.insert(list, { { Id = "emote:" .. id, Name = e.name, Icon = e.icon, Desc = "Emote (until you're done dancing)", emote = id }, "Emote" }) end
		end
	end
	return list
end

local function holdingTool(name) local ch = player.Character return ch and ch:FindFirstChild(name) and ch[name]:IsA("Tool") end

-- ===== hide while a menu is open (Bag, Map, Settings, Profile, Admin, Shop) =====
local playerGui = player:WaitForChild("PlayerGui")
local MENUS = {
	{ "MainHUD", "Panel" },          -- Bag / Map / Settings
	{ "ProfileGui", "Panel" },       -- Profile
	{ "AdminPanelGui", "AdminPanel" }, -- Admin (admins only)
	-- event panels that sit at the bottom of the screen: the hotbar would cover their buttons / guess box
	{ "EventGui", "QuizBeePanel" },   -- Quiz Bee answers
	{ "EventGui", "DrawingPanel" },   -- Guess the Drawing (canvas + guess box)
}
local SCREEN_MENUS = { "InventoryGui", "ShopGui" } -- whole ScreenGuis that open as menus
local function menuOpen()
	for _, m in ipairs(MENUS) do
		local g = playerGui:FindFirstChild(m[1])
		local f = g and g:FindFirstChild(m[2])
		if f and f:IsA("GuiObject") and f.Visible and (not g:IsA("ScreenGui") or g.Enabled) then return true end
	end
	for _, n in ipairs(SCREEN_MENUS) do
		local g = playerGui:FindFirstChild(n)
		if g and g:IsA("ScreenGui") and g.Enabled then return true end
	end
	return false
end
task.spawn(function()
	while gui.Parent do
		local show = not menuOpen()
		if holder.Visible ~= show then
			holder.Visible = show
			if not show then tip.Visible = false end
		end
		task.wait(0.1)
	end
end)

local shownIds = {}
local function refresh()
	local list = collect()
	empty.Visible = (#list == 0)
	local newIds = {}
	for i, s in ipairs(slots) do
		local e = list[i]
		s.item, s.cat = e and e[1] or nil, e and e[2] or nil
		s.button.Visible = (#list > 0)
		if s.item then
			newIds[s.item.Id] = true
			-- pop-in when an item lands on the hotbar
			if not shownIds[s.item.Id] then
				local sc = s.button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", s.button)
				sc.Scale = 0.6 TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			end
		else
			s.x.Visible = false
		end
		if s.item then
			local equipped = player:GetAttribute("Equipped_" .. s.item.Id) == true
			if s.cat == "Mic" then equipped = holdingTool("Microphone") == true elseif s.cat == "Emote" then equipped = false end
			local locked = s.cat == "Equipment" and player:GetAttribute("EquipLocked") == true
			if locked then equipped = false end
			s.icon.Text = locked and "🔒" or (s.item.Icon or "?")
			s.icon.TextTransparency = locked and 0.35 or 0
			s.bar.BackgroundTransparency = 0 s.bar.BackgroundColor3 = CAT_COLOR[s.cat] or C.stroke
			s.eq.Visible = equipped
			s.eq.Text = ((s.item.Tool or s.item.Id == "Flashlight") and holdingTool(s.item.Tool or "Flashlight")) and "✋" or "✓"
			s.stroke.Color = equipped and C.equip or C.stroke s.stroke.Thickness = equipped and 2.4 or 1.5
			if s.cat == "Consumable" then s.count.Visible = true s.count.Text = "x" .. countOf(s.item.Id) else s.count.Visible = false end
		else
			s.icon.Text = "" s.count.Visible = false s.eq.Visible = false s.bar.BackgroundTransparency = 1
			s.stroke.Color = C.stroke s.stroke.Thickness = 1.5
		end
		s.button.BackgroundTransparency = s.item and 0 or 0.45
	end
	shownIds = newIds
	local total = #list
	hint.Text = (total > SLOTS and ("+" .. (total - SLOTS) .. " more in Bag  •  ") or "") .. hintTail()
end

local function pulse(s, col)
	s.button.BackgroundColor3 = col
	TweenService:Create(s.button, TweenInfo.new(0.35), { BackgroundColor3 = C.slot }):Play()
	local sc = s.button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", s.button)
	sc.Scale = 0.88 TweenService:Create(sc, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local busy = {}
local function activate(i)
	local s = slots[i] if not s or not s.item then return end
	if busy[i] then return end busy[i] = true task.delay(0.35, function() busy[i] = nil end)
	local id = s.item.Id
	if s.cat == "Equipment" and player:GetAttribute("EquipLocked") then
		showNote("🔒 Equipment is off while you're in an event or game")
		return
	end
	if s.cat == "Emote" then
		if Emotes then Emotes.play(player.Character, s.item.emote) end
		pulse(s, CAT_COLOR.Emote)
	elseif s.cat == "Mic" then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local tool = micTool()
		if hum and tool then
			if tool.Parent == player.Character then hum:UnequipTools() else hum:EquipTool(tool) end
		end
		pulse(s, CAT_COLOR.Mic) task.delay(0.15, refresh)
	elseif id == "BodySwapPotion" then
		-- pick who to swap with first (GearClient shows the picker)
		local open = RS:FindFirstChild("OpenBodySwap")
		if open then open:Fire() end
		pulse(s, C.consume)
	elseif s.cat == "Consumable" then
		useRemote:FireServer(id) pulse(s, C.consume)
	elseif id == "Flashlight" or s.item.Tool then
		-- tools (Flashlight, Gravity Coil, Speed Coil, Magic Carpet): press to hold / put away
		local toolName = s.item.Tool or "Flashlight"
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local bp = player:FindFirstChild("Backpack")
		if hum then
			if holdingTool(toolName) then hum:UnequipTools()
			elseif bp and bp:FindFirstChild(toolName) then hum:EquipTool(bp[toolName]) end
		end
		pulse(s, C.equipment) task.delay(0.15, refresh)
	else
		-- shoes, boots, cosmetics: they work while they're on the hotbar
		pulse(s, CAT_COLOR[s.cat] or C.equip)
		showNote((s.item.Icon or "") .. " " .. s.item.Name .. " is ON  •  " .. (isTouch() and "hold the slot" or "tap X") .. " or use your Bag to unequip")
	end
end

local function unequip(i)
	local s = slots[i] if not s or not s.item then return end
	if s.cat == "Emote" then
		local t = {}
		for id in string.gmatch(player:GetAttribute("TempHotbar") or "", "[^,]+") do if id ~= s.item.emote then table.insert(t, id) end end
		player:SetAttribute("TempHotbar", #t > 0 and table.concat(t, ",") or nil)
		tip.Visible = false
		return
	elseif s.cat == "Mic" then
		local ts = RS:FindFirstChild("TalentShow")
		local evt = ts and ts:FindFirstChild("TalentEvent")
		if evt then evt:FireServer({ a = "returnmic" }) end
		tip.Visible = false
		return
	end
	if s.item.Id == "Flashlight" or s.item.Tool then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:UnequipTools() end
	end
	equipRemote:FireServer(s.item.Id)
	showNote("Unequipped " .. s.item.Name .. "  •  re-equip it in your Bag [I]")
	tip.Visible = false
end

for i, s in ipairs(slots) do
	local longPressed = false
	s.button.MouseButton1Click:Connect(function()
		if longPressed then longPressed = false return end
		activate(i)
	end)
	s.x.MouseButton1Click:Connect(function() unequip(i) end)
	-- phones: hold a slot to unequip it
	s.button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch or not s.item then return end
		local id = s.item.Id
		local held = true
		local conn conn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then held = false conn:Disconnect() end
		end)
		task.delay(0.65, function()
			if held and s.item and s.item.Id == id then longPressed = true unequip(i) end
		end)
	end)
	s.button.MouseEnter:Connect(function()
		if not s.item then return end
		s.x.Visible = true
		s.button.BackgroundColor3 = C.slotHover
		tipName.Text = s.item.Name
		local how = s.cat == "Consumable" and "Press to use" or "ON • X to unequip"
		if s.item.Id == "Flashlight" or s.item.Tool then how = "Press to hold / put away • X to unequip" end
		if s.item.Id == "BodySwapPotion" then how = "Press to choose who to swap with" end
		tipDesc.Text = (s.item.Desc or s.cat) .. "  •  " .. how
		tipStroke.Color = CAT_COLOR[s.cat] or C.stroke
		local abs = s.button.AbsolutePosition local sz = s.button.AbsoluteSize
		tip.Position = UDim2.fromOffset(abs.X + sz.X / 2, abs.Y - 8 + (gui.IgnoreGuiInset and 0 or 0))
		tip.Visible = true
	end)
	s.button.MouseLeave:Connect(function() s.button.BackgroundColor3 = C.slot tip.Visible = false s.x.Visible = false end)
end

local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine }
UIS.InputBegan:Connect(function(input, processed)
	if processed or not holder.Visible then return end
	for i, k in ipairs(KEYS) do if input.KeyCode == k then activate(i) return end end
end)

-- ===== live updates =====
player.AttributeChanged:Connect(function(n) if n:sub(1, 6) == "Owned_" or n:sub(1, 9) == "Equipped_" or n == "Hotbar" or n == "TempHotbar" or n == "EquipLocked" then refresh() end
	if n == "EquipLocked" then
		showNote(player:GetAttribute("EquipLocked") and "🔒 Equipment is off during the event/game" or "🔓 Your equipment is back!")
	end
end)
-- the stage mic arrives / leaves through the Backpack
local function hookBackpack(bp)
	bp.ChildAdded:Connect(function() task.defer(refresh) end)
	bp.ChildRemoved:Connect(function() task.defer(refresh) end)
end
if player:FindFirstChild("Backpack") then hookBackpack(player.Backpack) end
player.ChildAdded:Connect(function(c) if c:IsA("Backpack") then hookBackpack(c) end end)
local function hookInv(inv)
	inv.ChildAdded:Connect(function(v) if v:IsA("IntValue") then v.Changed:Connect(refresh) end refresh() end)
	inv.ChildRemoved:Connect(refresh)
	for _, v in ipairs(inv:GetChildren()) do if v:IsA("IntValue") then v.Changed:Connect(refresh) end end
end
local inv = player:FindFirstChild("Inventory") if inv then hookInv(inv) end
player.ChildAdded:Connect(function(c) if c.Name == "Inventory" then hookInv(c) refresh() end end)
player.CharacterAdded:Connect(function(ch) ch.ChildAdded:Connect(refresh) ch.ChildRemoved:Connect(refresh) task.wait(1) refresh() end)
if player.Character then player.Character.ChildAdded:Connect(refresh) player.Character.ChildRemoved:Connect(refresh) end
refresh()
