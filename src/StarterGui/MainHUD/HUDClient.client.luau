-- HUDClient.lua
-- Left rail (Bag, Map) + Settings button + one main panel.
-- Keys: [I] Bag, [M] Map. Other scripts can open a page with MainHUD.OpenPanel:Fire("Bag").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent
local panel = gui:WaitForChild("Panel")
local pages = panel:WaitForChild("Pages")
local title = panel:WaitForChild("Title")
local subtitle = panel:WaitForChild("Subtitle")
local rail = gui:WaitForChild("Rail")
local settingsButton = gui:WaitForChild("SettingsButton")
local toast = gui:WaitForChild("Toast")
local confirm = gui:WaitForChild("Confirm")

local ACCENT = Color3.fromRGB(20, 140, 100)
local BG2 = Color3.fromRGB(42, 42, 55)
local STROKE = Color3.fromRGB(75, 75, 95)
local MUTED = Color3.fromRGB(165, 165, 180)
local GOOD = Color3.fromRGB(120, 220, 170)

------------------------------------------------------------ helpers
local toastToken = 0
local function showToast(message)
	if not message or message == "" then return end
	toastToken += 1
	local my = toastToken
	toast.Text = message
	toast.Visible = true
	task.delay(2.2, function() if toastToken == my then toast.Visible = false end end)
end

-- shrink everything on small (phone) screens
local scale = gui:WaitForChild("AutoScale")
local UIS_ = game:GetService("UserInputService")
local railLayout = rail:FindFirstChildOfClass("UIListLayout")
local function rescale()
	local v = gui.AbsoluteSize
	if v.Y < 2 then v = workspace.CurrentCamera.ViewportSize end
	local s = math.clamp(v.Y / 760, v.Y < 330 and 0.55 or 0.6, 1) -- short phones (Galaxy S/A) a bit smaller
	scale.Scale = s
	-- side buttons: size the rail to its buttons (Profile, Bag, Map, Admin)
	local contentH = railLayout and (railLayout.AbsoluteContentSize.Y / math.max(s, 0.01)) or 240
	rail.Size = UDim2.fromOffset(72, math.max(contentH, 60))
	if UIS_.TouchEnabled then
		-- phones & tablets: keep the buttons near the top so the thumbstick (bottom-left) never covers them
		rail.AnchorPoint = Vector2.new(0, 0)
		rail.Position = UDim2.fromOffset(10, 6)
	else
		rail.AnchorPoint = Vector2.new(0, 0.5)
		rail.Position = UDim2.new(0, 14, 0.5, 0)
	end
end
rescale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)
if railLayout then railLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(rescale) end

------------------------------------------------------------ page switching
local PAGES = {
	Bag = { frame = pages:WaitForChild("BagPage"), button = rail:WaitForChild("BagButton"), title = "Bag",
		sub = "Cosmetic = looks only · Equipment = has an effect · Consumable = used up" },
	Map = { frame = pages:WaitForChild("MapPage"), button = rail:WaitForChild("MapButton"), title = "Map",
		sub = "Tap a pin to see the place, tap again (or Go) to teleport" },
	Settings = { frame = pages:WaitForChild("SettingsPage"), button = settingsButton, title = "Settings", sub = "" },
}
local current = nil
local onOpen = {}

local function highlight(name)
	for key, page in pairs(PAGES) do
		local s = page.button:FindFirstChildOfClass("UIStroke")
		if s then
			s.Color = (key == name) and ACCENT or STROKE
			s.Thickness = (key == name) and 2.5 or 1.5
		end
	end
end

local function openPage(name)
	if current == name and panel.Visible then
		panel.Visible = false
		current = nil
		highlight(nil)
		return
	end
	current = name
	for key, page in pairs(PAGES) do page.frame.Visible = (key == name) end
	title.Text = PAGES[name].title
	subtitle.Text = PAGES[name].sub
	panel.Visible = true
	highlight(name)
	if onOpen[name] then onOpen[name]() end
end

local function closePanel()
	panel.Visible = false
	current = nil
	highlight(nil)
end

for key, page in pairs(PAGES) do
	page.button.MouseButton1Click:Connect(function() openPage(key) end)
end
panel:WaitForChild("CloseButton").MouseButton1Click:Connect(closePanel)
gui:WaitForChild("OpenPanel").Event:Connect(function(name)
	if PAGES[name] then current = nil openPage(name) end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.I then openPage("Bag")
	elseif input.KeyCode == Enum.KeyCode.M then openPage("Map") end
end)

------------------------------------------------------------ BAG
local shopRemotes = ReplicatedStorage:WaitForChild("ShopRemotes")
local equipRemote = shopRemotes:WaitForChild("EquipItem")
local useRemote = shopRemotes:WaitForChild("UseItem")
local shopItems = require(ReplicatedStorage:WaitForChild("ShopItems"))

local bagPage = PAGES.Bag.frame
local list = bagPage:WaitForChild("List")
local rowTemplate = list:WaitForChild("RowTemplate")
local emptyLabel = list:WaitForChild("Empty")
local tabButtons = {
	Cosmetic = bagPage.Tabs:WaitForChild("CosmeticTab"),
	Equipment = bagPage.Tabs:WaitForChild("EquipmentTab"),
	Consumable = bagPage.Tabs:WaitForChild("ConsumableTab"),
}
local bagTab = "Cosmetic"

local function countOf(id)
	local inv = player:FindFirstChild("Inventory")
	local v = inv and inv:FindFirstChild(id)
	return v and v.Value or 0
end

local function refreshBag()
	for name, b in pairs(tabButtons) do b.BackgroundColor3 = (name == bagTab) and ACCENT or BG2 end
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "RowTemplate" then child:Destroy() end
	end
	local shown = 0
	for i, item in ipairs(shopItems[bagTab] or {}) do
		local isConsumable = bagTab == "Consumable"
		local qty = isConsumable and countOf(item.Id) or 0
		local owned = isConsumable and qty > 0 or player:GetAttribute("Owned_" .. item.Id) == true
		if owned then
			shown += 1
			local equipped = player:GetAttribute("Equipped_" .. item.Id) == true
			-- which hotbar slot is it in? (hotbar = equipped items, in equip order)
			local slotNo = nil
			if equipped then
				local n = 0
				for id in string.gmatch(player:GetAttribute("Hotbar") or "", "[^,]+") do
					n += 1
					if id == item.Id then slotNo = n break end
				end
			end
			local row = rowTemplate:Clone()
			row.Name = item.Id
			row.LayoutOrder = i
			row.IconBox.Icon.Text = item.Icon or "?"
			row.ItemName.Text = item.Name
			row.ItemDesc.Text = item.Desc
			local status = equipped and ("✓ On hotbar" .. (slotNo and ("  •  slot " .. slotNo) or "")) or "Not on hotbar"
			if isConsumable then status = "x" .. qty .. "  ·  " .. status end
			row.Status.Text = status
			row.Status.TextColor3 = equipped and GOOD or MUTED
			row.EquipButton.Text = equipped and "Unequip" or "Equip"
			row.EquipButton.BackgroundColor3 = equipped and Color3.fromRGB(150, 55, 65) or ACCENT
			row.EquipButton.MouseButton1Click:Connect(function() equipRemote:FireServer(item.Id) end)
			row.UseButton.Visible = isConsumable
			if isConsumable then
				row.UseButton.MouseButton1Click:Connect(function()
					if item.Id == "BodySwapPotion" then ReplicatedStorage.OpenBodySwap:Fire() closePanel() else useRemote:FireServer(item.Id) end
				end)
			end
			row.Visible = true
			row.Parent = list
		end
	end
	emptyLabel.Visible = shown == 0
end

for name, b in pairs(tabButtons) do
	b.MouseButton1Click:Connect(function() bagTab = name refreshBag() end)
end
onOpen.Bag = refreshBag

local function bagChanged()
	if current == "Bag" and panel.Visible then refreshBag() end
end
player.AttributeChanged:Connect(function(attr)
	if attr:match("^Owned_") or attr:match("^Equipped_") or attr == "Hotbar" then bagChanged() end
end)
task.spawn(function()
	local inv = player:WaitForChild("Inventory", 15)
	if not inv then return end
	local function watch(v) if v:IsA("IntValue") then v.Changed:Connect(bagChanged) end end
	for _, v in ipairs(inv:GetChildren()) do watch(v) end
	inv.ChildAdded:Connect(function(v) watch(v) bagChanged() end)
end)
-- shop/bag server messages ("Equipped ...", "Used ...") show as a toast while the HUD is open
shopRemotes:WaitForChild("UpdateCash").OnClientEvent:Connect(function(message)
	if panel.Visible then showToast(message) end
end)

------------------------------------------------------------ MAP
-- Top-down photo map: zoom (buttons / wheel / pinch), drag to pan,
-- follow-me mode keeps you centered with an arrow showing where you face.
local config = require(ReplicatedStorage:WaitForChild("HUDConfig"))
local hudRemotes = ReplicatedStorage:WaitForChild("HUDRemotes")
local mapTeleport = hudRemotes:WaitForChild("MapTeleport")
local switchServer = hudRemotes:WaitForChild("SwitchServer")
local RunServiceMap = game:GetService("RunService")
local UISMap = game:GetService("UserInputService")
local PlayersMap = game:GetService("Players")

local mapPage = PAGES.Map.frame
local mapImage = mapPage:WaitForChild("MapImage") -- acts as the clipped viewport
local pinTemplate = mapImage:WaitForChild("PinTemplate")
local pinLabel = mapImage:WaitForChild("PinLabel")
local legend = mapPage:WaitForChild("Legend")
local legendTemplate = legend:WaitForChild("LegendTemplate")
local placeholder = mapImage:WaitForChild("Placeholder")

-- world rectangle covered by the map photo (screen up = +X, screen right = +Z)
local MW = config.MapWorld or { Top = 480, Bottom = -428.78, Left = -560, Right = 570.93 }
local WORLD_W = MW.Right - MW.Left -- studs across (Z)
local WORLD_H = MW.Top - MW.Bottom -- studs down (X)
local function toMap(pos)
	local u = (pos.Z - MW.Left) / WORLD_W
	local v = (MW.Top - pos.X) / WORLD_H
	return u, v
end

mapImage.Image = ""
mapImage.ClipsDescendants = true
mapImage.Active = true
mapImage.BackgroundColor3 = Color3.fromRGB(78, 158, 204) -- sea
mapImage.BackgroundTransparency = 0

-- canvas holds the photo tiles, pins and player markers; it is moved/scaled to zoom & pan
local canvas = Instance.new("Frame")
canvas.Name = "Canvas"
canvas.BackgroundTransparency = 1
canvas.AnchorPoint = Vector2.new(0, 0)
canvas.ZIndex = 1
canvas.Parent = mapImage

local tiles = config.MapTiles or {}
local GRID = config.MapGrid or 2
local hasPhoto = false
for i = 1, GRID * GRID do
	local id = tiles[i]
	if id and id ~= "" then
		hasPhoto = true
		local r, c = (i - 1) // GRID, (i - 1) % GRID
		local img = Instance.new("ImageLabel")
		img.Name = "Tile" .. i
		img.BackgroundTransparency = 1
		img.Image = id
		img.ScaleType = Enum.ScaleType.Stretch
		img.Size = UDim2.fromScale(1 / GRID + 0.0015, 1 / GRID + 0.0015) -- tiny overlap hides seams
		img.Position = UDim2.fromScale(c / GRID, r / GRID)
		img.ZIndex = 1
		img.Parent = canvas
	end
end
pinTemplate.Parent = canvas
pinLabel.ZIndex = 20
placeholder.ZIndex = 20

local function corner(obj, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(r or 0.5, 0) c.Parent = obj end
local function stroke(obj, col, th) local s = Instance.new("UIStroke") s.Color = col s.Thickness = th or 2 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = obj return s end

------------------------------------------------ zoom / pan state
-- the photo now covers the whole island, so zoom levels are ~2.4x the old campus-only values
local MIN_ZOOM, MAX_ZOOM = 1, 20
local ZOOM_NEAR = 6 -- default "around me" zoom
local zoom, targetZoom = ZOOM_NEAR, ZOOM_NEAR
local follow = true
local center = Vector2.new(0.5, 0.5) -- map point (u,v) shown in the middle of the viewport

local function fitScale() -- px per stud at zoom 1 (whole island fits)
	local vs = mapImage.AbsoluteSize
	return math.min(vs.X / WORLD_W, vs.Y / WORLD_H)
end
local function canvasSize(z)
	local s = fitScale() * (z or zoom)
	return Vector2.new(WORLD_W * s, WORLD_H * s)
end
local function clampCenter()
	-- keep some of the island visible while panning
	center = Vector2.new(math.clamp(center.X, 0, 1), math.clamp(center.Y, 0, 1))
end
local function layout()
	local vs = mapImage.AbsoluteSize
	local cs = canvasSize()
	canvas.Size = UDim2.fromOffset(cs.X, cs.Y)
	canvas.Position = UDim2.fromOffset(vs.X / 2 - center.X * cs.X, vs.Y / 2 - center.Y * cs.Y)
end

------------------------------------------------ pins
local selected, selectedAt = nil, 0
local function goTo(place)
	mapTeleport:FireServer(place.Id)
	pinLabel.Visible = false
	selected = nil
end

local function focusOn(u, v, z)
	follow = false
	center = Vector2.new(u, v)
	if z then targetZoom = math.max(targetZoom, z) end
end

local pinNames = {}
local function selectPin(place, u, v)
	if selected == place.Id and os.clock() - selectedAt < 4 then
		goTo(place)
		return
	end
	selected, selectedAt = place.Id, os.clock()
	pinLabel.Text = (place.Icon or "") .. " " .. place.Name .. " — tap again to go"
	pinLabel.Visible = true
	focusOn(u, v)
end

for i, place in ipairs(config.Places) do
	local u, v
	if place.Position then u, v = toMap(place.Position) else u, v = place.MapX or 0.5, place.MapY or 0.5 end
	local offMap = u < 0.02 or u > 0.98 or v < 0.02 or v > 0.98
	u, v = math.clamp(u, 0.02, 0.98), math.clamp(v, 0.02, 0.98)

	local pin = pinTemplate:Clone()
	pin.Name = place.Id
	pin.Position = UDim2.fromScale(u, v)
	pin.ZIndex = 6
	pin.Text = place.Icon or ""
	pin.TextScaled = true
	pin.Visible = true
	pin.Parent = canvas
	pin.MouseButton1Click:Connect(function() selectPin(place, u, v) end)

	-- name tag shows once you zoom in
	local tag = Instance.new("TextLabel")
	tag.Name = "Tag"
	tag.AnchorPoint = Vector2.new(0.5, 0)
	tag.Position = UDim2.new(0.5, 0, 1, 3)
	tag.Size = UDim2.fromOffset(0, 18)
	tag.AutomaticSize = Enum.AutomaticSize.X
	tag.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
	tag.BackgroundTransparency = 0.25
	tag.TextColor3 = Color3.new(1, 1, 1)
	tag.Font = Enum.Font.GothamBold
	tag.TextSize = 12
	tag.Text = "  " .. place.Name .. (offMap and " (island)" or "") .. "  "
	tag.ZIndex = 7
	tag.Visible = false
	corner(tag, 0.4)
	tag.Parent = pin
	table.insert(pinNames, tag)

	local row = legendTemplate:Clone()
	row.Name = place.Id
	row.LayoutOrder = i
	row.PlaceName.Text = (place.Icon or "") .. "  " .. place.Name
	row.Visible = true
	row.Parent = legend
	row.MouseButton1Click:Connect(function() goTo(place) end)
	-- hovering / long-looking at a legend row shows it on the map
	row.MouseEnter:Connect(function() focusOn(u, v, 7) end)
	if place.Intramurals then
		-- 🏆 sports venues only show on the map while the Intramurals event is on
		local function refresh()
			local on = workspace:GetAttribute("IntramuralsActive") == true
			pin.Visible = on row.Visible = on
		end
		refresh()
		workspace:GetAttributeChangedSignal("IntramuralsActive"):Connect(refresh)
	end
end

------------------------------------------------ you + other players
local me = Instance.new("Frame") -- rotating container (points where you face)
me.Name = "YouAreHere"
me.AnchorPoint = Vector2.new(0.5, 0.5)
me.Size = UDim2.fromOffset(40, 40)
me.BackgroundTransparency = 1
me.ZIndex = 12
me.Parent = canvas
-- view cone: soft wedge showing the direction you look
local cone = Instance.new("Frame")
cone.Name = "Cone"
cone.AnchorPoint = Vector2.new(0.5, 0.5)
cone.Position = UDim2.new(0.5, 0, 0.5, -14)
cone.Size = UDim2.fromOffset(28, 28)
cone.Rotation = 45
cone.BackgroundColor3 = Color3.fromRGB(255, 220, 120)
cone.BorderSizePixel = 0
cone.ZIndex = 11
local coneFade = Instance.new("UIGradient") -- keep only the top half of the diamond = a triangle
coneFade.Rotation = 45
coneFade.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.499, 0.6),
	NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1),
})
coneFade.Parent = cone
cone.Parent = me
-- the dot
local dot = Instance.new("Frame")
dot.Name = "Dot"
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromOffset(18, 18)
dot.BackgroundColor3 = Color3.fromRGB(255, 190, 40)
dot.ZIndex = 13
corner(dot)
stroke(dot, Color3.new(1, 1, 1), 3)
dot.Parent = me
-- white arrow tip on the dot
local tip = Instance.new("Frame")
tip.Name = "Arrow"
tip.AnchorPoint = Vector2.new(0.5, 0.5)
tip.Position = UDim2.new(0.5, 0, 0.5, 1)
tip.Size = UDim2.fromOffset(9, 9)
tip.Rotation = 45
tip.BackgroundColor3 = Color3.new(1, 1, 1)
tip.BorderSizePixel = 0
tip.ZIndex = 14
local tipCut = Instance.new("UIGradient")
tipCut.Rotation = 45
tipCut.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.499, 0),
	NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1),
})
tipCut.Parent = tip
tip.Parent = me
local pulse = Instance.new("Frame") -- soft "you are here" ring
pulse.Name = "Pulse"
pulse.AnchorPoint = Vector2.new(0.5, 0.5)
pulse.Position = UDim2.fromScale(0.5, 0.5)
pulse.Size = UDim2.fromOffset(22, 22)
pulse.BackgroundColor3 = Color3.fromRGB(255, 196, 50)
pulse.BackgroundTransparency = 0.6
pulse.ZIndex = 10
corner(pulse)
pulse.Parent = canvas

local others = {}
local function otherDot(plr)
	local d = others[plr]
	if d then return d end
	d = Instance.new("Frame")
	d.Name = "P_" .. plr.Name
	d.AnchorPoint = Vector2.new(0.5, 0.5)
	d.Size = UDim2.fromOffset(12, 12)
	d.BackgroundColor3 = Color3.fromRGB(80, 170, 255)
	d.ZIndex = 9
	corner(d)
	stroke(d, Color3.new(1, 1, 1), 1.5)
	local n = Instance.new("TextLabel")
	n.Name = "Label"
	n.AnchorPoint = Vector2.new(0.5, 1)
	n.Position = UDim2.new(0.5, 0, 0, -2)
	n.Size = UDim2.fromOffset(0, 14)
	n.AutomaticSize = Enum.AutomaticSize.X
	n.BackgroundTransparency = 1
	n.TextColor3 = Color3.new(1, 1, 1)
	n.TextStrokeTransparency = 0.3
	n.Font = Enum.Font.GothamBold
	n.TextSize = 11
	n.Text = plr.DisplayName
	n.ZIndex = 9
	n.Parent = d
	d.Parent = canvas
	others[plr] = d
	return d
end
PlayersMap.PlayerRemoving:Connect(function(plr)
	if others[plr] then others[plr]:Destroy() others[plr] = nil end
end)

------------------------------------------------ controls
local controls = Instance.new("Frame")
controls.Name = "MapControls"
controls.AnchorPoint = Vector2.new(1, 0)
controls.Position = UDim2.new(1, -10, 0, 10)
controls.Size = UDim2.fromOffset(44, 0)
controls.AutomaticSize = Enum.AutomaticSize.Y
controls.BackgroundTransparency = 1
controls.ZIndex = 30
controls.Parent = mapImage
local ll = Instance.new("UIListLayout")
ll.Padding = UDim.new(0, 6)
ll.SortOrder = Enum.SortOrder.LayoutOrder
ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
ll.Parent = controls

local function ctrlButton(name, text, order, size)
	local b = Instance.new("TextButton")
	b.Name = name
	b.LayoutOrder = order
	b.Size = UDim2.fromOffset(40, 40)
	b.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	b.BackgroundTransparency = 0.1
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = size or 24
	b.Text = text
	b.AutoButtonColor = true
	b.ZIndex = 31
	corner(b, 0.3)
	stroke(b, Color3.fromRGB(70, 200, 140), 1.5)
	b.Parent = controls
	return b
end
local zoomIn = ctrlButton("ZoomIn", "+", 1)
local zoomLabel = Instance.new("TextLabel")
zoomLabel.Name = "ZoomLevel"
zoomLabel.LayoutOrder = 2
zoomLabel.Size = UDim2.fromOffset(44, 18)
zoomLabel.BackgroundTransparency = 1
zoomLabel.TextColor3 = Color3.new(1, 1, 1)
zoomLabel.TextStrokeTransparency = 0.4
zoomLabel.Font = Enum.Font.GothamBold
zoomLabel.TextSize = 12
zoomLabel.ZIndex = 31
zoomLabel.Parent = controls
local zoomOut = ctrlButton("ZoomOut", "-", 3, 28)
local recenter = ctrlButton("CenterOnMe", "📍", 4, 20)
local fullView = ctrlButton("ShowAll", "🗺️", 5, 20)

local followTag = Instance.new("TextLabel")
followTag.Name = "FollowTag"
followTag.AnchorPoint = Vector2.new(0, 0)
followTag.Position = UDim2.fromOffset(10, 10)
followTag.Size = UDim2.fromOffset(0, 24)
followTag.AutomaticSize = Enum.AutomaticSize.X
followTag.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
followTag.BackgroundTransparency = 0.15
followTag.TextColor3 = Color3.new(1, 1, 1)
followTag.Font = Enum.Font.GothamBold
followTag.TextSize = 13
followTag.ZIndex = 30
corner(followTag, 0.4)
followTag.Parent = mapImage

local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.AnchorPoint = Vector2.new(0, 1)
hint.Position = UDim2.new(0, 10, 1, -10)
hint.Size = UDim2.fromOffset(0, 20)
hint.AutomaticSize = Enum.AutomaticSize.X
hint.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
hint.BackgroundTransparency = 0.35
hint.TextColor3 = Color3.fromRGB(220, 230, 235)
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.ZIndex = 30
hint.Text = UISMap.TouchEnabled and not UISMap.MouseEnabled
	and "  Drag to move • Pinch to zoom • Tap a pin  "
	or "  Drag to move • Scroll to zoom • Click a pin  "
corner(hint, 0.4)
hint.Parent = mapImage

local function setZoom(z) targetZoom = math.clamp(z, MIN_ZOOM, MAX_ZOOM) end
zoomIn.MouseButton1Click:Connect(function() setZoom(targetZoom * 1.5) end)
zoomOut.MouseButton1Click:Connect(function() setZoom(targetZoom / 1.5) end)
recenter.MouseButton1Click:Connect(function()
	follow = true
	if targetZoom < 4.8 then setZoom(ZOOM_NEAR) end
end)
fullView.MouseButton1Click:Connect(function()
	follow = false
	center = Vector2.new(0.5, 0.5)
	setZoom(1)
end)

-- zoom toward a screen point (keeps the spot under the cursor/fingers in place)
local function zoomAt(screenPos, newZoom)
	newZoom = math.clamp(newZoom, MIN_ZOOM, MAX_ZOOM)
	if not follow then
		local vs, vp = mapImage.AbsoluteSize, mapImage.AbsolutePosition
		local off = (screenPos - vp) - vs / 2
		local cs0, cs1 = canvasSize(zoom), canvasSize(newZoom)
		local world = center + Vector2.new(off.X / cs0.X, off.Y / cs0.Y)
		center = world - Vector2.new(off.X / cs1.X, off.Y / cs1.Y)
		clampCenter()
	end
	zoom, targetZoom = newZoom, newZoom
end

mapImage.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		zoomAt(Vector2.new(input.Position.X, input.Position.Y), targetZoom * (input.Position.Z > 0 and 1.25 or 0.8))
	end
end)

-- drag to pan (mouse or one finger)
local dragging, dragStart, dragCenter, dragMoved = nil, nil, nil, false
mapImage.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if dragging then return end
		dragging = input
		dragStart = Vector2.new(input.Position.X, input.Position.Y)
		dragCenter = center
		dragMoved = false
	end
end)
UISMap.InputChanged:Connect(function(input)
	if not dragging then return end
	local ok = (input == dragging) or (dragging.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)
	if not ok then return end
	local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
	if not dragMoved and delta.Magnitude < 6 then return end
	if not dragMoved then
		dragMoved = true
		if follow then dragCenter = center end
		follow = false
	end
	local cs = canvasSize()
	center = dragCenter - Vector2.new(delta.X / cs.X, delta.Y / cs.Y)
	clampCenter()
end)
UISMap.InputEnded:Connect(function(input)
	if dragging and (input == dragging or input.UserInputType == Enum.UserInputType.MouseButton1) then
		dragging = nil
	end
end)

-- pinch to zoom on phones / tablets
local pinchStartZoom
UISMap.TouchPinch:Connect(function(touches, scale, _, state)
	if not (current == "Map" and panel.Visible) then return end
	if state == Enum.UserInputState.Begin then
		pinchStartZoom = targetZoom
		dragging = nil
	elseif pinchStartZoom then
		local mid = Vector2.zero
		for _, t in ipairs(touches) do mid += Vector2.new(t.X, t.Y) end
		mid /= math.max(#touches, 1)
		zoomAt(mid, pinchStartZoom * scale)
		if state == Enum.UserInputState.End then pinchStartZoom = nil end
	end
end)

------------------------------------------------ live update while the map is open
local function rootOf(plr)
	local c = plr.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local pulseT = 0
local function step(dt)
	-- smooth zoom
	zoom = zoom + (targetZoom - zoom) * math.min(1, dt * 12)
	if math.abs(targetZoom - zoom) < 0.002 then zoom = targetZoom end

	local root = rootOf(player)
	me.Visible = root ~= nil
	pulse.Visible = root ~= nil
	if root then
		local u, v = toMap(root.Position)
		me.Position = UDim2.fromScale(u, v)
		pulse.Position = me.Position
		-- face where the camera looks (falls back to the body)
		local look = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.LookVector or root.CFrame.LookVector
		if Vector2.new(look.X, look.Z).Magnitude < 0.1 then look = root.CFrame.LookVector end
		me.Rotation = math.deg(math.atan2(look.Z, look.X))
		if follow then
			center = center:Lerp(Vector2.new(u, v), math.min(1, dt * 10))
		end
	end
	pulseT = (pulseT + dt) % 1.6
	local p = pulseT / 1.6
	pulse.Size = UDim2.fromOffset(22 + 34 * p, 22 + 34 * p)
	pulse.BackgroundTransparency = 0.45 + 0.55 * p

	for _, plr in ipairs(PlayersMap:GetPlayers()) do
		if plr ~= player then
			local r = rootOf(plr)
			local d = otherDot(plr)
			d.Visible = r ~= nil
			if r then
				local u, v = toMap(r.Position)
				d.Position = UDim2.fromScale(math.clamp(u, 0, 1), math.clamp(v, 0, 1))
				d.Label.Visible = zoom >= 6
			end
		end
	end

	local showNames = zoom >= 4.8
	for _, t in ipairs(pinNames) do t.Visible = showNames end

	zoomLabel.Text = string.format("%.1fx", zoom)
	followTag.Text = follow and "  📍 Following you  " or "  🧭 Free look — press 📍  "
	followTag.BackgroundColor3 = follow and Color3.fromRGB(18, 110, 70) or Color3.fromRGB(20, 24, 32)
	layout()
end

local mapConn
onOpen.Map = function()
	placeholder.Visible = not hasPhoto
	pinLabel.Visible = false
	follow = true
	if targetZoom < 3.6 then targetZoom = ZOOM_NEAR end
	local root = rootOf(player)
	if root then local u, v = toMap(root.Position) center = Vector2.new(u, v) end
	if mapConn then mapConn:Disconnect() end
	mapConn = RunServiceMap.RenderStepped:Connect(function(dt)
		if not (current == "Map" and panel.Visible) then
			mapConn:Disconnect() mapConn = nil
			return
		end
		step(dt)
	end)
	step(1)
end

mapTeleport.OnClientEvent:Connect(function(message)
	showToast(message)
	if message and message:find("^Teleported") then closePanel() end
end)

------------------------------------------------------------ SETTINGS
local setPage = PAGES.Settings.frame
local elemCard = setPage.ServerChoice:WaitForChild("ElementaryCard")
local jhCard = setPage.ServerChoice:WaitForChild("JuniorHighCard")
local serverNote = setPage:WaitForChild("ServerNote")

-- this place is the Junior High+ (main campus) server
jhCard.BackgroundColor3 = Color3.fromRGB(18, 70, 52)
jhCard.UIStroke.Color = ACCENT
jhCard.UIStroke.Thickness = 2.5

local function askConfirm(message, detail, onYes)
	confirm.Card.Message.Text = message
	confirm.Card.Detail.Text = detail
	confirm.Visible = true
	local yesConn, noConn
	yesConn = confirm.Card.Yes.MouseButton1Click:Connect(function()
		yesConn:Disconnect() noConn:Disconnect()
		confirm.Visible = false
		onYes()
	end)
	noConn = confirm.Card.Cancel.MouseButton1Click:Connect(function()
		yesConn:Disconnect() noConn:Disconnect()
		confirm.Visible = false
	end)
end

elemCard.MouseButton1Click:Connect(function()
	if (tonumber(config.ElementaryPlaceId) or 0) <= 0 then
		showToast("The Elementary server isn't set up yet")
		return
	end
	askConfirm("Switch to the Elementary server?",
		"You'll leave this server and join the separate, kid-friendly Elementary server.",
		function() switchServer:FireServer("Elementary") end)
end)
jhCard.MouseButton1Click:Connect(function()
	showToast("You're already on the Junior High+ server")
end)
switchServer.OnClientEvent:Connect(showToast)
-- no server switch: hide the whole "Server" section in Settings
for _, n in ipairs({ "Server", "ServerChoice", "ServerNote" }) do
	local o = setPage:FindFirstChild(n)
	if o then o.Visible = false end
end

-- sound groups: music vs sound effects (assigned locally, so each player has their own volume)
local musicGroup = SoundService:WaitForChild("Music")
local sfxGroup = SoundService:WaitForChild("SFX")
local function isMusic(sound)
	local p = sound
	while p and p ~= game do
		if p.Name:lower():find("music") then return true end
		p = p.Parent
	end
	return false
end
local function assign(sound)
	if not sound:IsA("Sound") then return end
	if sound.SoundGroup and sound.SoundGroup ~= musicGroup and sound.SoundGroup ~= sfxGroup then return end
	sound.SoundGroup = isMusic(sound) and musicGroup or sfxGroup
end
for _, d in ipairs(workspace:GetDescendants()) do assign(d) end
for _, d in ipairs(SoundService:GetDescendants()) do assign(d) end
workspace.DescendantAdded:Connect(assign)
SoundService.DescendantAdded:Connect(assign)

local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local function makeSlider(frame, initial, onChange)
	local track, fill, knob, valueLabel = frame.Track, frame.Track.Fill, frame.Track.Knob, frame.Value
	local hit = track:WaitForChild("HitArea")
	local dragging = false
	local function set(alpha)
		alpha = math.clamp(alpha, 0, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = math.round(alpha * 100) .. "%"
		onChange(alpha)
	end
	local function setFromX(x)
		set((x - track.AbsolutePosition.X) / track.AbsoluteSize.X)
	end
	hit.MouseButton1Down:Connect(function(x)
		dragging = true
		setFromX(x)
	end)
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.Touch then setFromX(input.Position.X) end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	-- mouse dragging: follow the cursor while the left button is held
	RunService.RenderStepped:Connect(function()
		if not dragging then return end
		if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then return end
		if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			dragging = false
			return
		end
		setFromX(UserInputService:GetMouseLocation().X)
	end)
	set(initial)
end
-- SAVED SETTINGS: the server (SettingsServer) remembers every choice below between visits.
-- Wait briefly for the saved values, then start each toggle / slider from them.
local settingsRemote = game:GetService("ReplicatedStorage"):WaitForChild("SettingsRemote", 10)
local savedSettings = {}
do
	local t0 = os.clock()
	while not player:GetAttribute("SettingsLoaded") and os.clock() - t0 < 6 do task.wait(0.1) end
	local raw = player:GetAttribute("SavedSettings")
	if type(raw) == "string" then
		local ok, t = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
		if ok and type(t) == "table" then savedSettings = t end
	end
end
local function savedOr(attr, default)
	local v = savedSettings[attr]
	if v == nil then return default end
	return v
end
local pendingSend = {}
local function sendSetting(attr, value)
	if not settingsRemote then return end
	-- sliders fire many times while dragging: send the latest value a moment later
	local first = pendingSend[attr] == nil
	pendingSend[attr] = value
	if first then
		task.delay(0.4, function()
			local v = pendingSend[attr]
			pendingSend[attr] = nil
			if v ~= nil then settingsRemote:FireServer(attr, v) end
		end)
	end
end

makeSlider(setPage:WaitForChild("MusicSlider"), savedOr("Setting_MusicVolume", 0.7), function(a) musicGroup.Volume = a player:SetAttribute("Setting_MusicVolume", a) sendSetting("Setting_MusicVolume", a) end)
makeSlider(setPage:WaitForChild("SFXSlider"), savedOr("Setting_SFXVolume", 0.85), function(a) sfxGroup.Volume = a player:SetAttribute("Setting_SFXVolume", a) sendSetting("Setting_SFXVolume", a) end)

local function makeToggle(frame, attr, initial)
	local switch = frame.Switch
	local on = savedOr(attr, initial) -- the player's saved choice wins over the default
	local function render()
		switch.BackgroundColor3 = on and ACCENT or Color3.fromRGB(80, 80, 95)
		TweenService:Create(switch.Knob, TweenInfo.new(0.12), {Position = on and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}):Play()
		player:SetAttribute(attr, on)
	end
	switch.MouseButton1Click:Connect(function() on = not on render() sendSetting(attr, on) end)
	render()
end
makeToggle(setPage:WaitForChild("EventAlerts"), "Setting_EventAlerts", true)
makeToggle(setPage:WaitForChild("LeaderboardUpdates"), "Setting_LeaderboardUpdates", true)

-- performance (handled by StarterPlayerScripts.PerformanceSettings)
makeToggle(setPage:WaitForChild("Shadows"), "Setting_Shadows", true) -- 🌗 shadows on/off (default on)
-- phones / tablets start with Improve FPS ON (they can turn it off); PCs start with it off
local UIS = game:GetService("UserInputService")
makeToggle(setPage:WaitForChild("ImproveFPS"), "Setting_ImproveFPS", UIS.TouchEnabled and not UIS.KeyboardEnabled)
makeToggle(setPage:WaitForChild("DisableEffects"), "Setting_DisableEffects", false)
