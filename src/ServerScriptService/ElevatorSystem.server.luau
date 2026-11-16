-- Working elevator 1F <-> 2F <-> 3F <-> 4F <-> 5F. Buttons are tap/click only (ClickDetector, no E prompt).
-- Landings: models tagged "ElevatorLanding" (attribute Floor) with LeafN / LeafS (sliding door leaves),
--   an Indicator part (labels "▲" and the floor number) and a CallPanel with Button parts.
-- Cars: workspace.SamarCollege_Campus.ElevatorSystem.Car_1 / Car_2 with a ButtonPanel (Btn_1, Btn_2, Btn_Open, Btn_Close)
--   and a Display (FloorGui > FloorText). Riding = doors close, riders are moved to the other car, doors open.
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("ElevatorRide")
local sys = workspace:WaitForChild("SamarCollege_Campus"):WaitForChild("ElevatorSystem")

local FLOOR_Y = {[1] = 1.06, [2] = 16.0, [3] = 31.0, [4] = 46.67, [5] = 63.12}
local CAR = {x1 = 216.6, x2 = 222.3, z1 = -204.3, z2 = -197.3, h = 9.2}
local SLIDE = 2.45
local OPEN_TIME, MOVE_TIME = 1.0, 2.6

local landings, cars = {}, {}
local carFloor, busy, doorsOpen = 1, false, false
local closeToken = 0

local function setupLanding(m)
	local f = m:GetAttribute("Floor") if not f then return end
	local L = {model = m, leaves = {}}
	for _, name in ipairs({"LeafN", "LeafS"}) do
		local leaf = m:FindFirstChild(name)
		if leaf then
			local dir = (name == "LeafN") and 1 or -1
			for _, p in ipairs(leaf:GetChildren()) do
				if p:IsA("BasePart") then table.insert(L.leaves, {part = p, closed = p.CFrame, open = p.CFrame + Vector3.new(0, 0, dir * SLIDE)}) end
			end
		end
	end
	-- indicator labels
	local ind = m:FindFirstChild("Indicator")
	if ind then
		for _, t in ipairs(ind:GetDescendants()) do
			if t:IsA("TextLabel") then
				if t.Text:match("%d") then L.numLabel = t else L.arrowLabel = t end
			end
		end
	end
	landings[f] = L
end
for _, m in ipairs(CS:GetTagged("ElevatorLanding")) do setupLanding(m) end
for _, c in ipairs(sys:GetChildren()) do
	local f = c:GetAttribute("Floor") if f then cars[f] = c end
end

local function setDisplays(floorNum, arrow)
	for _, L in pairs(landings) do
		if L.numLabel then L.numLabel.Text = tostring(floorNum) end
		if L.arrowLabel then L.arrowLabel.Text = arrow or "" end
	end
	for _, c in pairs(cars) do
		local d = c:FindFirstChild("Display") local g = d and d:FindFirstChild("FloorGui")
		if g and g:FindFirstChild("FloorText") then g.FloorText.Text = ((arrow and arrow ~= "") and (arrow .. " ") or "") .. tostring(floorNum) end
	end
end

local function moveDoors(f, open)
	local L = landings[f] if not L then return end
	local info = TweenInfo.new(OPEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	for _, lf in ipairs(L.leaves) do TweenService:Create(lf.part, info, {CFrame = open and lf.open or lf.closed}):Play() end
	doorsOpen = open
	task.wait(OPEN_TIME)
end

local function scheduleClose()
	closeToken += 1
	local my = closeToken
	task.delay(7, function()
		if my == closeToken and doorsOpen and not busy then moveDoors(carFloor, false) end
	end)
end

local function openHere()
	if busy then return end
	if not doorsOpen then moveDoors(carFloor, true) end
	scheduleClose()
end

local function ridersIn(f)
	local list = {}
	local y0 = FLOOR_Y[f]
	for _, pl in ipairs(Players:GetPlayers()) do
		local root = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local p = root.Position
			if p.X > CAR.x1 and p.X < CAR.x2 and p.Z > CAR.z1 and p.Z < CAR.z2 and p.Y > y0 - 1 and p.Y < y0 + CAR.h then table.insert(list, pl) end
		end
	end
	return list
end

local function travel(target)
	if busy or target == carFloor or not FLOOR_Y[target] then return end
	busy = true
	closeToken += 1
	if doorsOpen then moveDoors(carFloor, false) end
	task.wait(0.3)
	local from = carFloor
	local arrow = (target > from) and "▲" or "▼"
	local riders = ridersIn(from)
	for _, pl in ipairs(riders) do remote:FireClient(pl, "ride", target, arrow) end
	setDisplays(from, arrow)
	task.wait(0.5)
	local dy = FLOOR_Y[target] - FLOOR_Y[from]
	for _, pl in ipairs(riders) do
		local char = pl.Character
		if char then char:PivotTo(char:GetPivot() + Vector3.new(0, dy, 0)) end
	end
	task.wait(MOVE_TIME * 0.5)
	carFloor = target
	setDisplays(target, arrow)
	task.wait(MOVE_TIME * 0.5)
	setDisplays(target, "")
	busy = false
	moveDoors(target, true)
	scheduleClose()
end

local function call(f)
	if busy then return end
	if f == carFloor then openHere() else task.spawn(travel, f) end
end

local function flash(btn)
	local old, oldMat = btn.Color, btn.Material
	btn.Color = Color3.fromRGB(255, 190, 60) btn.Material = Enum.Material.Neon
	task.delay(1.2, function() btn.Color = old btn.Material = oldMat end)
end

local function hook(part, fn)
	local cd = part:FindFirstChildOfClass("ClickDetector")
	if cd then cd.MouseClick:Connect(function(pl) flash(part) fn(pl) end) end
	-- tap only: drop any leftover E prompt
	for _, pp in ipairs(part:GetChildren()) do if pp:IsA("ProximityPrompt") then pp:Destroy() end end
end

-- landing call buttons
for f, L in pairs(landings) do
	local cp = L.model:FindFirstChild("CallPanel")
	if cp then for _, b in ipairs(cp:GetChildren()) do if b:IsA("BasePart") and b.Name == "Button" then hook(b, function() call(f) end) end end end
end
-- car buttons (a car's buttons only work while the elevator is at that car's floor)
for f, c in pairs(cars) do
	local pnl = c:FindFirstChild("ButtonPanel")
	if pnl then
		for target = 1, 5 do
			local b = pnl:FindFirstChild("Btn_" .. target)
			if b then hook(b, function() if carFloor == f then if f == target then openHere() else task.spawn(travel, target) end end end) end
		end
		hook(pnl.Btn_Open, function() if carFloor == f then openHere() end end)
		hook(pnl.Btn_Close, function() if carFloor == f and doorsOpen and not busy then closeToken += 1 moveDoors(f, false) end end)
	end
end
setDisplays(1, "")

-- test hook (ServerStorage.ElevatorTest:Fire("call", floor) / ("go", floor))
local test = game:GetService("ServerStorage"):FindFirstChild("ElevatorTest") or Instance.new("BindableEvent")
test.Name = "ElevatorTest" test.Parent = game:GetService("ServerStorage")
test.Event:Connect(function(kind, f) if kind == "call" then call(f) elseif kind == "go" then task.spawn(travel, f) end end)
