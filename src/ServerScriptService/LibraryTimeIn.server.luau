-- Library time-in kiosk (tag a model "LibraryKiosk"; it needs a ProximityPrompt and a part named
-- "LibraryLogBoard" with a SurfaceGui "LogGui" > Root > Entries).
-- Tap / click the kiosk tablet or press E → the student picks a purpose → they are timed in,
-- shown where to go, and listed on the "Library Log — Today" board.
local CS = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local remote = RS:WaitForChild("LibraryTimeIn")

local PURPOSES = {
	reading  = {label = "Reading",                      icon = "📖"},
	borrow   = {label = "Borrow / return books",        icon = "📚"},
	project  = {label = "Making a project / assignment", icon = "🛠"},
	computer = {label = "Using a computer",             icon = "💻"},
	research = {label = "Research / thesis",            icon = "🔎"},
	study    = {label = "Studying / reviewing",         icon = "✏"},
	other    = {label = "Other",                        icon = "❓"},
	-- BSIT & BSCRIM library (kiosk attribute OptionSet = "itcrim")
	ic_read     = {label = "Read books in the BSIT / BSCRIM section", icon = "📖"},
	ic_borrow   = {label = "Borrow / return books",                   icon = "📚"},
	ic_computer = {label = "Use the computer area",                   icon = "💻"},
	ic_research = {label = "Research / thesis / case study",          icon = "🔎"},
	ic_review   = {label = "Review for exams / board exam",           icon = "✏"},
	ic_group    = {label = "Group study / project work",              icon = "👥"},
}
local MAX_ON_BOARD = 9
local logs = {}           -- [kiosk] = today's entries (newest first)
local lastUse = {}

local function manilaTime()
	return os.date("!%I:%M %p", os.time() + 8 * 3600):gsub("^0", "")
end

local function boardsAndKiosks()
	return CS:GetTagged("LibraryKiosk")
end

local function refreshBoards()
	for _, k in ipairs(boardsAndKiosks()) do
		local log = logs[k] or {}
		local board = k:FindFirstChild("LibraryLogBoard", true)
		local entries = board and board:FindFirstChild("LogGui") and board.LogGui.Root.Entries
		if entries then
			for _, c in ipairs(entries:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
			if #log == 0 then
				local t = Instance.new("TextLabel") t.BackgroundTransparency = 1 t.Size = UDim2.fromScale(1, 0.1)
				t.TextScaled = true t.Font = Enum.Font.Gotham t.TextColor3 = Color3.fromRGB(210, 230, 215)
				t.Text = "No one has timed in yet. Tap the kiosk to time in." t.Parent = entries
			end
			for i = 1, math.min(#log, MAX_ON_BOARD) do
				local e = log[i]
				local row = Instance.new("Frame") row.LayoutOrder = i row.Size = UDim2.fromScale(1, 0.1)
				row.BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(30, 62, 44) or Color3.fromRGB(36, 72, 52) row.BorderSizePixel = 0 row.Parent = entries
				local function cell(text, x, w, color, font)
					local t = Instance.new("TextLabel") t.BackgroundTransparency = 1 t.Position = UDim2.fromScale(x, 0.1) t.Size = UDim2.fromScale(w, 0.8)
					t.TextScaled = true t.Font = font or Enum.Font.Gotham t.TextXAlignment = Enum.TextXAlignment.Left t.TextColor3 = color t.Text = text t.Parent = row
				end
				cell(e.time, 0.02, 0.2, Color3.fromRGB(255, 225, 110), Enum.Font.GothamBold)
				cell(e.name, 0.23, 0.35, Color3.new(1, 1, 1), Enum.Font.GothamBold)
				cell(e.icon .. " " .. e.purpose, 0.6, 0.38, Color3.fromRGB(200, 235, 210))
			end
		end
	end
end

local function nearKiosk(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local best, bestD = nil, 25
	for _, k in ipairs(boardsAndKiosks()) do
		local d = (k:GetPivot().Position - root.Position).Magnitude
		if d <= bestD then best, bestD = k, d end
	end
	return best
end

local function open(player)
	local k = nearKiosk(player)
	if k then remote:FireClient(player, "open", player:GetAttribute("LibraryPurpose"), k:GetAttribute("LibraryName") or "SAMAR COLLEGE LIBRARY", k:GetAttribute("OptionSet")) end
end

local function setup(k)
	local prompt = k:FindFirstChild("TimeInPrompt", true)
	if prompt then prompt.Triggered:Connect(open) end
	-- tap / click the tablet
	for _, p in ipairs(k:GetDescendants()) do
		if p:IsA("BasePart") and (p.Name == "Tablet" or p.Name == "TabletScreen" or p.Name == "IDReader") and not p:FindFirstChildOfClass("ClickDetector") then
			local cd = Instance.new("ClickDetector") cd.MaxActivationDistance = 14 cd.Parent = p
			cd.MouseClick:Connect(open)
		end
	end
end
for _, k in ipairs(CS:GetTagged("LibraryKiosk")) do task.spawn(setup, k) end
CS:GetInstanceAddedSignal("LibraryKiosk"):Connect(setup)

remote.OnServerEvent:Connect(function(player, action, purposeId)
	if action ~= "timein" or type(purposeId) ~= "string" then return end
	local p = PURPOSES[purposeId]
	local kiosk = nearKiosk(player)
	if not p or not kiosk then return end
	if lastUse[player] and os.clock() - lastUse[player] < 3 then return end
	lastUse[player] = os.clock()
	local t = manilaTime()
	logs[kiosk] = logs[kiosk] or {}
	local log = logs[kiosk]
	table.insert(log, 1, {name = player.DisplayName, purpose = p.label, icon = p.icon, time = t})
	while #log > 60 do table.remove(log) end
	player:SetAttribute("LibraryPurpose", purposeId)
	player:SetAttribute("LibraryTimeIn", t)
	refreshBoards()
	remote:FireClient(player, "done", {id = purposeId, label = p.label, icon = p.icon, time = t})
end)

game:GetService("Players").PlayerRemoving:Connect(function(pl) lastUse[pl] = nil end)
refreshBoards()
