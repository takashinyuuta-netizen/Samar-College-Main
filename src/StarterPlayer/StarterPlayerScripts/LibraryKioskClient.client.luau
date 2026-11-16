-- Library time-in screen: choose what you will do, then see where to go and the rules.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local remote = RS:WaitForChild("LibraryTimeIn")

local OPTIONS = {
	{id = "reading",  icon = "📖", label = "Reading"},
	{id = "borrow",   icon = "📚", label = "Borrow / return books"},
	{id = "project",  icon = "🛠", label = "Making a project / assignment"},
	{id = "computer", icon = "💻", label = "Using a computer"},
	{id = "research", icon = "🔎", label = "Research / thesis"},
	{id = "study",    icon = "✏", label = "Studying / reviewing"},
	{id = "other",    icon = "❓", label = "Other"},
}
local OPTION_SETS = {
	itcrim = {
		{id = "ic_read",     icon = "📖", label = "Read books in the BSIT / BSCRIM section"},
		{id = "ic_borrow",   icon = "📚", label = "Borrow / return books"},
		{id = "ic_computer", icon = "💻", label = "Use the computer area"},
		{id = "ic_research", icon = "🔎", label = "Research / thesis / case study"},
		{id = "ic_review",   icon = "✏", label = "Review for exams / board exam"},
		{id = "ic_group",    icon = "👥", label = "Group study / project work"},
	},
}
local optSet
local GUIDE = {
	ic_read     = {"BSIT books are on the blue-labelled stacks; BSCRIM books are on the gold-labelled stacks.", "Read at the reading tables in the middle of the library.", "Leave books on the table when you're done — please don't reshelve."},
	ic_borrow   = {"Go to the Circulation Counter in the north-east corner.", "Present your school ID to the librarian.", "Returning? Hand the book over at the counter."},
	ic_computer = {"Go to the Computer Area in the north-west corner.", "Academic use only — research, coding and reports. No games.", "You can rest on the sofas while you wait for a free PC."},
	ic_research = {"Check the reference shelves at the end of each section.", "Use a PC in the Computer Area for online journals.", "Ask the librarian for theses and case studies."},
	ic_review   = {"Find a quiet seat at the reading tables.", "BSCRIM board review books are in the BSCRIM section.", "Phones on silent, please."},
	ic_group    = {"Use the reading tables — keep your voices low.", "One group per table, please.", "Return chairs when you leave."},
	reading  = {"Look up the book on the OPAC (at the counter) to get its call number.", "Find it on the shelves (the stacks are sorted by DDC class).", "Read at any reading table. Leave books on the table or return them to the counter — please don't reshelve."},
	borrow   = {"Go to the Circulation Counter and present your school ID.", "Returning? Hand the book to the librarian.", "Overdue books: ₱5.00 per hour (excluding Sundays and holidays)."},
	project  = {"Use the reading tables; keep group talk low.", "Laptop? Plug in at the Laptop Charging Station beside the THESES shelf.", "Need a book? Check the OPAC first."},
	computer = {"Go to the Internet Room (glass door on the north side).", "Log in at the attendant desk inside.", "Academic use only — no games or social media."},
	research = {"Theses are on the THESES shelf (south-east corner) — room use only.", "General references are along the west wall.", "Ask the librarian at the counter for help with your topic."},
	study    = {"Find a quiet seat at the reading tables.", "Phones on silent, please.", "No sleeping on the tables."},
	other    = {"Please approach the librarian at the Circulation Counter."},
}
local COMMON = "Please deposit your bag at the baggage counter. No food and drinks inside the library."

local gui
local function close() if gui then gui:Destroy() gui = nil end end

local libName = "SAMAR COLLEGE LIBRARY"
local function base()
	close()
	gui = Instance.new("ScreenGui") gui.Name = "LibraryKiosk" gui.ResetOnSpawn = false gui.IgnoreGuiInset = true gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local dim = Instance.new("Frame") dim.Size = UDim2.fromScale(1, 1) dim.BackgroundColor3 = Color3.new(0, 0, 0) dim.BackgroundTransparency = 0.45 dim.Parent = gui
	local panel = Instance.new("Frame") panel.Name = "Panel" panel.AnchorPoint = Vector2.new(0.5, 0.5) panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.9, 0.86) panel.BackgroundColor3 = Color3.fromRGB(250, 248, 240) panel.Parent = gui
	local sc = Instance.new("UISizeConstraint") sc.MaxSize = Vector2.new(560, 640) sc.Parent = panel
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
	local head = Instance.new("Frame") head.Size = UDim2.new(1, 0, 0, 64) head.BackgroundColor3 = Color3.fromRGB(30, 100, 60) head.Parent = panel
	Instance.new("UICorner", head).CornerRadius = UDim.new(0, 16)
	local t = Instance.new("TextLabel") t.BackgroundTransparency = 1 t.Size = UDim2.new(1, -24, 1, -12) t.Position = UDim2.fromOffset(12, 6)
	t.TextScaled = true t.Font = Enum.Font.GothamBlack t.TextColor3 = Color3.new(1, 1, 1) t.Text = "📚 " .. libName .. " — TIME IN" t.Parent = head
	gui.Parent = player:WaitForChild("PlayerGui")
	panel.Size = UDim2.fromScale(0.8, 0.76)
	TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Back), {Size = UDim2.fromScale(0.9, 0.86)}):Play()
	return panel
end

local function button(parent, text, color, order)
	local b = Instance.new("TextButton") b.LayoutOrder = order or 0 b.Size = UDim2.new(1, 0, 0, 46) b.AutoButtonColor = true
	b.BackgroundColor3 = color b.TextColor3 = Color3.new(1, 1, 1) b.Font = Enum.Font.GothamBold b.TextScaled = true b.Text = text b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 12) pad.PaddingRight = UDim.new(0, 12) pad.PaddingTop = UDim.new(0, 8) pad.PaddingBottom = UDim.new(0, 8) pad.Parent = b
	return b
end

local function openChooser(current)
	local panel = base()
	local q = Instance.new("TextLabel") q.BackgroundTransparency = 1 q.Position = UDim2.fromOffset(16, 72) q.Size = UDim2.new(1, -32, 0, 46)
	q.TextScaled = true q.TextWrapped = true q.Font = Enum.Font.GothamBold q.TextColor3 = Color3.fromRGB(40, 40, 40)
	q.Text = "Hi " .. player.DisplayName .. "! What will you do in the library today?" q.Parent = panel
	local list = Instance.new("ScrollingFrame") list.BackgroundTransparency = 1 list.BorderSizePixel = 0 list.Position = UDim2.fromOffset(16, 124)
	list.Size = UDim2.new(1, -32, 1, -190) list.CanvasSize = UDim2.new() list.AutomaticCanvasSize = Enum.AutomaticSize.Y list.ScrollBarThickness = 6 list.Parent = panel
	local lay = Instance.new("UIListLayout") lay.Padding = UDim.new(0, 8) lay.SortOrder = Enum.SortOrder.LayoutOrder lay.Parent = list
	for i, o in ipairs((optSet and OPTION_SETS[optSet]) or OPTIONS) do
		local b = button(list, o.icon .. "  " .. o.label .. (current == o.id and "   ✓" or ""), Color3.fromRGB(46, 120, 78), i)
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.Activated:Connect(function()
			b.Text = "Timing in…"
			remote:FireServer("timein", o.id)
		end)
	end
	local cancel = button(panel, "Cancel", Color3.fromRGB(150, 150, 150))
	cancel.Position = UDim2.new(0, 16, 1, -58) cancel.Size = UDim2.new(1, -32, 0, 44)
	cancel.Activated:Connect(close)
end

local function showDone(info)
	local panel = base()
	local ok = Instance.new("TextLabel") ok.BackgroundTransparency = 1 ok.Position = UDim2.fromOffset(16, 74) ok.Size = UDim2.new(1, -32, 0, 40)
	ok.TextScaled = true ok.Font = Enum.Font.GothamBlack ok.TextColor3 = Color3.fromRGB(30, 110, 60) ok.Text = "✅ Timed in at " .. info.time ok.Parent = panel
	local pur = Instance.new("TextLabel") pur.BackgroundTransparency = 1 pur.Position = UDim2.fromOffset(16, 116) pur.Size = UDim2.new(1, -32, 0, 30)
	pur.TextScaled = true pur.Font = Enum.Font.GothamBold pur.TextColor3 = Color3.fromRGB(50, 50, 50) pur.Text = "Purpose: " .. info.icon .. " " .. info.label pur.Parent = panel
	local box = Instance.new("Frame") box.Position = UDim2.fromOffset(16, 154) box.Size = UDim2.new(1, -32, 1, -224) box.BackgroundColor3 = Color3.fromRGB(236, 244, 238) box.Parent = panel
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)
	local lay = Instance.new("UIListLayout") lay.Padding = UDim.new(0, 6) lay.SortOrder = Enum.SortOrder.LayoutOrder lay.Parent = box
	local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 12) pad.PaddingRight = UDim.new(0, 12) pad.PaddingTop = UDim.new(0, 10) pad.Parent = box
	local hdr = Instance.new("TextLabel") hdr.BackgroundTransparency = 1 hdr.Size = UDim2.new(1, 0, 0, 26) hdr.TextScaled = true hdr.Font = Enum.Font.GothamBold
	hdr.TextXAlignment = Enum.TextXAlignment.Left hdr.TextColor3 = Color3.fromRGB(30, 100, 60) hdr.Text = "What to do next:" hdr.LayoutOrder = 0 hdr.Parent = box
	local lines = table.clone(GUIDE[info.id] or GUIDE.other)
	table.insert(lines, COMMON)
	for i, line in ipairs(lines) do
		local l = Instance.new("TextLabel") l.BackgroundTransparency = 1 l.LayoutOrder = i l.Size = UDim2.new(1, 0, 0, 0) l.AutomaticSize = Enum.AutomaticSize.Y
		l.TextWrapped = true l.TextSize = 16 l.Font = Enum.Font.Gotham l.TextXAlignment = Enum.TextXAlignment.Left l.TextColor3 = Color3.fromRGB(40, 40, 40)
		l.Text = "• " .. line l.Parent = box
	end
	local okb = button(panel, "OK, got it", Color3.fromRGB(30, 100, 60))
	okb.Position = UDim2.new(0, 16, 1, -58) okb.Size = UDim2.new(1, -32, 0, 44)
	okb.Activated:Connect(close)
end

remote.OnClientEvent:Connect(function(action, data, ...)
	if action == "open" then libName = (select(1, ...) or "SAMAR COLLEGE LIBRARY") optSet = select(2, ...) openChooser(data) elseif action == "done" then showDone(data) end
end)
