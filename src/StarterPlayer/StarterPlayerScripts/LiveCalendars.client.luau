-- LiveCalendars: whiteboard month calendars that always show the current month (Philippine Time).
-- A calendar is a BasePart tagged "LiveCalendar"; the month grid is drawn on its SurfaceGui
-- (attribute Face = "Front" / "Back" / "Left" / "Right", default Front).
-- Handwritten notes come from attributes named Note_YYYY_MM_DD (e.g. Note_2026_10_08 = "Educators' Night").
-- Today's box gets a red marker circle. The calendar redraws itself when the day changes.
local CS = game:GetService("CollectionService")

local UTC_OFFSET = 8 * 3600
local DAYS = { "SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY" }
local MONTHS = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }
local INK = Color3.fromRGB(35, 40, 60)
local FONT = Enum.Font.PermanentMarker

local function now()
	return os.date("!*t", os.time() + UTC_OFFSET)
end

local MONTH_DAYS = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
local function daysIn(y, m)
	if m == 2 and (y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)) then return 29 end
	return MONTH_DAYS[m]
end

-- weekday of a date, 1 = Sunday (Sakamoto's method, no time zones involved)
local T = { 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 }
local function weekday(y, m, d)
	if m < 3 then y -= 1 end
	return (y + y // 4 - y // 100 + y // 400 + T[m] + d) % 7 + 1
end

local function label(parent, text, size, pos, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = size
	t.Position = pos
	t.Text = text
	t.TextColor3 = INK
	t.Font = FONT
	t.TextScaled = true
	t.TextWrapped = true
	for k, v in pairs(props or {}) do t[k] = v end
	t.Parent = parent
	return t
end

local function line(parent, size, pos)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = INK
	f.BackgroundTransparency = 0.25
	f.Size = size
	f.Position = pos
	f.Parent = parent
	return f
end

local function draw(part)
	local gui = part:FindFirstChild("CalendarGui")
	if not gui then
		gui = Instance.new("SurfaceGui")
		gui.Name = "CalendarGui"
		gui.Face = Enum.NormalId[part:GetAttribute("Face") or "Front"]
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 80
		gui.LightInfluence = 0.6
		gui.Parent = part
	end
	gui:ClearAllChildren()
	local t = now()
	local y, m, today = t.year, t.month, t.day
	local first = weekday(y, m, 1) -- 1 = Sunday
	local n = daysIn(y, m)
	local rows = math.ceil((first - 1 + n) / 7)

	local root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.fromRGB(250, 251, 252)
	root.BorderSizePixel = 0
	root.Parent = gui

	label(root, MONTHS[m] .. " " .. y, UDim2.fromScale(0.35, 0.1), UDim2.fromScale(0.62, 0.01), { TextXAlignment = Enum.TextXAlignment.Right })
	local top, headH = 0.12, 0.055
	local gridTop = top + headH
	local cellW, cellH = 1 / 7, (0.97 - gridTop) / rows
	line(root, UDim2.new(1, 0, 0, 2), UDim2.fromScale(0, top))
	for d = 1, 7 do
		label(root, DAYS[d], UDim2.fromScale(cellW * 0.9, headH * 0.8), UDim2.fromScale((d - 1) * cellW + cellW * 0.05, top + headH * 0.1))
	end
	for r = 0, rows do line(root, UDim2.new(1, 0, 0, 2), UDim2.fromScale(0, gridTop + r * cellH)) end
	for c = 1, 6 do line(root, UDim2.new(0, 2, 0.97 - top, 0), UDim2.fromScale(c * cellW, top)) end

	for day = 1, n do
		local idx = first - 1 + day - 1
		local col, row = idx % 7, math.floor(idx / 7)
		local cell = Instance.new("Frame")
		cell.BackgroundTransparency = 1
		cell.Size = UDim2.fromScale(cellW, cellH)
		cell.Position = UDim2.fromScale(col * cellW, gridTop + row * cellH)
		cell.Parent = root
		-- little box with the number in the top-right corner (as drawn on the real board)
		local box = Instance.new("Frame")
		box.Size = UDim2.fromScale(0.22, 0.3)
		box.Position = UDim2.fromScale(0.76, 0.03)
		box.BackgroundTransparency = 1
		box.Parent = cell
		local st = Instance.new("UIStroke") st.Color = INK st.Thickness = 1.5 st.Parent = box
		label(box, tostring(day), UDim2.fromScale(0.9, 0.9), UDim2.fromScale(0.05, 0.05))
		local note = part:GetAttribute(string.format("Note_%04d_%02d_%02d", y, m, day))
		if note then
			label(cell, note, UDim2.fromScale(0.9, 0.6), UDim2.fromScale(0.05, 0.36), { TextColor3 = Color3.fromRGB(30, 50, 110) })
		end
		if day == today then
			local ring = Instance.new("Frame")
			ring.Size = UDim2.fromScale(0.36, 0.48)
			ring.Position = UDim2.fromScale(0.69, -0.06)
			ring.BackgroundTransparency = 1
			ring.Parent = cell
			local cr = Instance.new("UICorner") cr.CornerRadius = UDim.new(0.5, 0) cr.Parent = ring
			local rs = Instance.new("UIStroke") rs.Color = Color3.fromRGB(210, 30, 30) rs.Thickness = 3 rs.Parent = ring
			label(cell, "TODAY", UDim2.fromScale(0.6, 0.2), UDim2.fromScale(0.04, 0.06), { TextColor3 = Color3.fromRGB(210, 30, 30), TextXAlignment = Enum.TextXAlignment.Left })
		end
	end
	part:SetAttribute("ShownDate", string.format("%04d-%02d-%02d", y, m, today))
end

local calendars = {}
local function add(p)
	if p:IsA("BasePart") then calendars[p] = true task.spawn(draw, p) end
end
for _, p in ipairs(CS:GetTagged("LiveCalendar")) do add(p) end
CS:GetInstanceAddedSignal("LiveCalendar"):Connect(add)
CS:GetInstanceRemovedSignal("LiveCalendar"):Connect(function(p) calendars[p] = nil end)

-- redraw when the date changes
task.spawn(function()
	while true do
		task.wait(30)
		local t = now()
		local key = string.format("%04d-%02d-%02d", t.year, t.month, t.day)
		for p in pairs(calendars) do
			if p.Parent and p:GetAttribute("ShownDate") ~= key then draw(p) end
		end
	end
end)
