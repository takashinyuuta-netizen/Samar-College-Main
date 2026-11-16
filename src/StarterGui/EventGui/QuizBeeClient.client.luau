--[[ QuizBeeClient — the Quiz Bee question panel (only for players who joined).
  The server sends: lobby → question (text + 4 options + time) → reveal (right answer,
  your pick, points) → done. The client NEVER knows the answer before the reveal;
  clicking sends only the option number, and the server grades it. ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Remotes = RS:WaitForChild("Events"):WaitForChild("EventRemotes")
local gui = script.Parent

local GOLD, GREEN, RED, DARK = Color3.fromRGB(255, 210, 90), Color3.fromRGB(60, 170, 100), Color3.fromRGB(200, 70, 70), Color3.fromRGB(25, 30, 38)
local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = p end
local function label(parent, name, size, pos, font, color, maxSize, align)
	local t = Instance.new("TextLabel") t.Name = name t.Size = size t.Position = pos t.BackgroundTransparency = 1 t.Font = font or Enum.Font.Gotham
	t.TextColor3 = color or Color3.new(1,1,1) t.TextScaled = true t.TextWrapped = true t.TextXAlignment = align or Enum.TextXAlignment.Center t.Parent = parent
	local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = maxSize or 22 c.Parent = t
	return t
end

local panel = Instance.new("Frame") panel.Name = "QuizBeePanel" panel.Size = UDim2.new(0.9, 0, 0, 290) panel.Position = UDim2.new(0.5, 0, 1, -24)
panel.AnchorPoint = Vector2.new(0.5, 1) panel.BackgroundColor3 = DARK panel.BackgroundTransparency = 0.05 panel.Visible = false panel.Parent = gui corner(panel, 16)
local lim = Instance.new("UISizeConstraint") lim.MaxSize = Vector2.new(620, 290) lim.Parent = panel
local st = Instance.new("UIStroke") st.Color = GOLD st.Transparency = 0.4 st.Thickness = 2 st.Parent = panel

local header = label(panel, "Header", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 10), Enum.Font.GothamBold, GOLD, 18, Enum.TextXAlignment.Left)
local timerBack = Instance.new("Frame") timerBack.Name = "TimerBack" timerBack.Size = UDim2.new(1, -24, 0, 8) timerBack.Position = UDim2.fromOffset(12, 38)
timerBack.BackgroundColor3 = Color3.fromRGB(60, 65, 75) timerBack.BorderSizePixel = 0 timerBack.Parent = panel corner(timerBack, 4)
local timerBar = Instance.new("Frame") timerBar.Name = "TimerBar" timerBar.Size = UDim2.fromScale(1, 1) timerBar.BackgroundColor3 = GOLD timerBar.BorderSizePixel = 0 timerBar.Parent = timerBack corner(timerBar, 4)
local question = label(panel, "Question", UDim2.new(1, -24, 0, 64), UDim2.fromOffset(12, 52), Enum.Font.GothamBold, Color3.new(1,1,1), 24)
local status = label(panel, "Status", UDim2.new(1, -24, 0, 20), UDim2.new(0, 12, 1, -28), Enum.Font.Gotham, Color3.fromRGB(200, 210, 220), 16)

local buttons = {}
for k = 1, 4 do
	local b = Instance.new("TextButton") b.Name = "Option" .. k
	b.Size = UDim2.new(0.5, -18, 0, 52) b.Position = UDim2.new(((k - 1) % 2) * 0.5, 12, 0, 124 + math.floor((k - 1) / 2) * 60)
	b.BackgroundColor3 = Color3.fromRGB(50, 58, 72) b.TextColor3 = Color3.new(1,1,1) b.Font = Enum.Font.GothamBold b.TextScaled = true b.TextWrapped = true
	b.AutoButtonColor = true b.Parent = panel corner(b, 10)
	local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = 18 c.Parent = b
	local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 10) pad.PaddingRight = UDim.new(0, 10) pad.Parent = b
	buttons[k] = b
end

local current = nil  -- { i =, picked = }
local timerTween

local function setButtons(visible)
	for _, b in ipairs(buttons) do b.Visible = visible end
end

local function showLobby(d)
	panel.Visible = true
	setButtons(false)
	if timerTween then timerTween:Cancel() end
	timerBar.Size = UDim2.fromScale(1, 1)
	header.Text = "🧠 QUIZ BEE • " .. d.room
	question.Text = ("Get ready! %d questions for %s (%s)."):format(d.total or 0, d.grade or "", d.course or "")
	status.Text = "The quiz starts when the countdown ends. Answer fast for bonus points!"
end

local function showQuestion(d)
	panel.Visible = true
	current = { i = d.i, picked = nil }
	header.Text = ("🧠 QUIZ BEE • Question %d / %d • %s"):format(d.i, d.n, d.grade or "")
	question.Text = d.q
	for k, b in ipairs(buttons) do
		b.Visible = d.options[k] ~= nil
		b.Text = string.char(64 + k) .. ".  " .. tostring(d.options[k] or "")
		b.BackgroundColor3 = Color3.fromRGB(50, 58, 72)
		b.Active = true b.AutoButtonColor = true
	end
	status.Text = "Pick an answer!"
	if timerTween then timerTween:Cancel() end
	timerBar.Size = UDim2.fromScale(math.clamp(d.time / d.total, 0, 1), 1)
	timerBar.BackgroundColor3 = GOLD
	timerTween = TweenService:Create(timerBar, TweenInfo.new(d.time, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) })
	timerTween:Play()
end

local function showReveal(d)
	if timerTween then timerTween:Cancel() end
	for k, b in ipairs(buttons) do
		b.Active = false b.AutoButtonColor = false
		if k == d.correct then b.BackgroundColor3 = GREEN
		elseif k == d.picked then b.BackgroundColor3 = RED
		else b.BackgroundColor3 = Color3.fromRGB(40, 44, 52) end
	end
	if d.picked == nil then status.Text = "⏰ Time's up! The answer was " .. string.char(64 + d.correct)
	elseif d.picked == d.correct then status.Text = ("✅ Correct! +%d points"):format(d.gained or 0)
	else status.Text = "❌ Not quite — the answer was " .. string.char(64 + d.correct) end
	current = nil
end

local function showDone(d)
	setButtons(false)
	if timerTween then timerTween:Cancel() end
	header.Text = "🧠 QUIZ BEE • Finished!"
	question.Text = ("You got %d / %d correct"):format(d.correct or 0, d.total or 0)
	status.Text = "Check the results for the winners 🏆"
	task.delay(8, function() panel.Visible = false end)
end

for k, b in ipairs(buttons) do
	b.MouseButton1Click:Connect(function()
		if not current or current.picked then return end
		current.picked = k
		for j, other in ipairs(buttons) do
			other.Active = false other.AutoButtonColor = false
			other.BackgroundColor3 = (j == k) and Color3.fromRGB(70, 110, 190) or Color3.fromRGB(40, 44, 52)
		end
		status.Text = "🔒 Answer locked in — waiting for the others…"
		local i = current.i
		local ok, res = pcall(function() return Remotes.EventAction:InvokeServer("answer", { i = i, choice = k }) end)
		if ok and res and res.ok == false and res.msg then status.Text = res.msg end
	end)
end

Remotes.EventData.OnClientEvent:Connect(function(d)
	if type(d) ~= "table" or d.event ~= "QuizBee" then return end
	if d.type == "lobby" then showLobby(d)
	elseif d.type == "question" then showQuestion(d)
	elseif d.type == "reveal" then showReveal(d)
	elseif d.type == "done" then showDone(d) end
end)

-- hide the panel when the event is over / gone
Remotes.EventState.OnClientEvent:Connect(function(s)
	if not s.active or s.id ~= "QuizBee" or not s.joined then
		if panel.Visible and (not s.active or s.id ~= "QuizBee") then panel.Visible = false end
	end
end)
