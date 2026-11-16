--[[ NPCDialogueClient — simple talk with campus NPCs + their speech bubbles.
  Talking shows only the NPC's ROLE and what they say (typed out with a little voice blip).
  💬 Talk = another line • 👋 Bye = close. ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Shared = RS:WaitForChild("CampusLife")
local C = require(Shared:WaitForChild("CampusLifeConfig"))
local Remotes = Shared:WaitForChild("CampusLifeRemotes")
local player = Players.LocalPlayer
local gui = script.Parent

local ICON = { Student = "🎒", Faculty = "📚", Staff = "🛠️" }
local COLOR = { Student = Color3.fromRGB(30, 110, 60), Faculty = Color3.fromRGB(40, 70, 130), Staff = Color3.fromRGB(120, 80, 40) }
local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 12) c.Parent = p end

---------------------------------------------------------------- sounds
local blip = Instance.new("Sound") blip.Name = "NPC_TalkBlip" blip.SoundId = "rbxasset://sounds/electronicpingshort.wav" blip.Volume = 0.18 blip.Parent = SoundService
local pop = Instance.new("Sound") pop.Name = "NPC_TalkOpen" pop.SoundId = "rbxasset://sounds/electronicpingshort.wav" pop.Volume = 0.35 pop.PlaybackSpeed = 1.6 pop.Parent = SoundService
local function sfxVolume()
	local v = player:GetAttribute("Setting_SFXVolume")
	if type(v) ~= "number" then return 1 end
	if v > 1 then v = v / 100 end
	return math.clamp(v, 0, 1)
end

---------------------------------------------------------------- talk box (bottom-center, above the hotbar)
local box = Instance.new("Frame") box.Name = "TalkBox" box.AnchorPoint = Vector2.new(0.5, 1) box.Position = UDim2.new(0.5, 0, 1, -150)
box.Size = UDim2.new(0.9, 0, 0, 132) box.BackgroundColor3 = Color3.fromRGB(250, 248, 240) box.Visible = false box.Parent = gui corner(box, 16)
local lim = Instance.new("UISizeConstraint") lim.MaxSize = Vector2.new(520, 132) lim.Parent = box
local st = Instance.new("UIStroke") st.Thickness = 3 st.Color = COLOR.Student st.Parent = box
local roleTag = Instance.new("TextLabel") roleTag.Name = "Role" roleTag.AnchorPoint = Vector2.new(0, 0.5) roleTag.Position = UDim2.fromOffset(16, 0) roleTag.Size = UDim2.fromOffset(240, 30)
roleTag.BackgroundColor3 = COLOR.Student roleTag.TextColor3 = Color3.new(1, 1, 1) roleTag.Font = Enum.Font.GothamBlack roleTag.TextScaled = true roleTag.Parent = box corner(roleTag, 15)
do local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = 16 c.Parent = roleTag local p = Instance.new("UIPadding") p.PaddingLeft = UDim.new(0, 10) p.PaddingRight = UDim.new(0, 10) p.Parent = roleTag end
local text = Instance.new("TextLabel") text.Name = "Text" text.Position = UDim2.fromOffset(18, 22) text.Size = UDim2.new(1, -36, 0, 62) text.BackgroundTransparency = 1
text.Font = Enum.Font.GothamBold text.TextColor3 = Color3.fromRGB(35, 35, 40) text.TextScaled = true text.TextWrapped = true text.TextXAlignment = Enum.TextXAlignment.Left text.TextYAlignment = Enum.TextYAlignment.Top text.Parent = box
do local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = 20 c.Parent = text end
local function button(name, label, x, col)
	local b = Instance.new("TextButton") b.Name = name b.Text = label b.AnchorPoint = Vector2.new(1, 1) b.Position = UDim2.new(1, x, 1, -10) b.Size = UDim2.fromOffset(110, 32)
	b.BackgroundColor3 = col b.TextColor3 = Color3.new(1, 1, 1) b.Font = Enum.Font.GothamBlack b.TextScaled = true b.Parent = box corner(b, 10)
	local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = 15 c.Parent = b
	return b
end
local talkBtn = button("Talk", "💬 Talk", -132, Color3.fromRGB(60, 130, 210))
local byeBtn = button("Bye", "👋 Bye", -14, Color3.fromRGB(190, 80, 80))

local current, typing = nil, 0
local function pick(t) return t[math.random(#t)] end
local function linesFor(d)
	local pool = {}
	local extra = d.kind == "Student" and C.Lines.Student or (d.kind == "Faculty" and C.Lines.Faculty or d.lines)
	for _, l in ipairs(extra or {}) do table.insert(pool, l) end
	for _, l in ipairs(C.Lines.Any) do table.insert(pool, l) end
	local tips = C.Answers.Tips[d.kind]
	for _, l in ipairs(tips or {}) do table.insert(pool, l) end
	return pool
end

-- type the line out letter by letter with a small voice blip
local function say(line)
	typing += 1
	local my = typing
	text.Text = ""
	local pitch = current and (current.kind == "Faculty" and 1.6 or (current.kind == "Staff" and 1.4 or 2.1)) or 2
	local vol = sfxVolume()
	for i = 1, #line do
		if typing ~= my then return end
		text.Text = line:sub(1, i)
		local ch = line:sub(i, i)
		if i % 2 == 1 and ch:match("%w") and vol > 0 then
			blip.PlaybackSpeed = pitch + (math.random() - 0.5) * 0.3
			blip.Volume = 0.18 * vol
			blip:Play()
		end
		task.wait(0.025)
	end
end

local function close()
	if box.Visible then Remotes.NPCTalkClose:FireServer() end
	typing += 1
	box.Visible = false
	current = nil
end
byeBtn.MouseButton1Click:Connect(function()
	task.spawn(say, pick({ "Bye! Take care!", "See you around!", "Ingat!", "Have a nice day!" }))
	task.delay(1, close)
end)
talkBtn.MouseButton1Click:Connect(function() if current then task.spawn(say, pick(current.pool)) end end)

Remotes.NPCTalk.OnClientEvent:Connect(function(d)
	do return end -- replaced by the dialogue template (StarterPlayerScripts.CampusNPCDialogue)
	current = { kind = d.kind, npc = d.npc, pool = linesFor(d) }
	roleTag.Text = (ICON[d.kind] or "💬") .. "  " .. (d.role or "Campus")
	roleTag.BackgroundColor3 = COLOR[d.kind] or COLOR.Student
	st.Color = COLOR[d.kind] or COLOR.Student
	box.Visible = true
	box.Size = UDim2.new(0.82, 0, 0, 120)
	TweenService:Create(box, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Size = UDim2.new(0.9, 0, 0, 132) }):Play()
	pop.Volume = 0.35 * sfxVolume() pop:Play()
	local greet = d.kind == "Faculty" and pick({ "Hello! How can I help you?", "Good day! Keep studying hard.", "Yes? Nice to see you." })
		or (d.kind == "Staff" and pick({ "Hi there! Need anything?", "Hello! Have a good day on campus!" }) or pick({ "Hi! What's up?", "Hello! Kumusta?", "Uy, hi! 👋" }))
	task.spawn(say, greet)
end)

-- close when you walk away
task.spawn(function()
	while true do
		task.wait(0.5)
		if box.Visible and current and current.npc then
			local a = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local b = current.npc:FindFirstChild("HumanoidRootPart")
			if not a or not b or not current.npc:IsDescendantOf(workspace) or (a.Position - b.Position).Magnitude > 22 then close() end
		end
	end
end)

---------------------------------------------------------------- speech bubbles over NPC heads
Remotes.NPCBubble.OnClientEvent:Connect(function(headPart, line)
	if typeof(headPart) ~= "Instance" or not headPart.Parent then return end
	local old = headPart:FindFirstChild("SpeechBubble")
	if old then old:Destroy() end
	local bb = Instance.new("BillboardGui") bb.Name = "SpeechBubble" bb.Size = UDim2.fromOffset(200, 54) bb.StudsOffset = Vector3.new(0, 3.6, 0)
	bb.MaxDistance = 60 bb.LightInfluence = 0 bb.Adornee = headPart bb.Parent = headPart
	local f = Instance.new("TextLabel") f.Size = UDim2.fromScale(1, 1) f.BackgroundColor3 = Color3.new(1, 1, 1) f.TextColor3 = Color3.fromRGB(25, 25, 25)
	f.Font = Enum.Font.GothamBold f.TextScaled = true f.TextWrapped = true f.Text = line f.Parent = bb corner(f, 14)
	local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = 16 c.Parent = f
	local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 8) pad.PaddingRight = UDim.new(0, 8) pad.Parent = f
	f.BackgroundTransparency = 1 f.TextTransparency = 1
	TweenService:Create(f, TweenInfo.new(0.2), { BackgroundTransparency = 0.05, TextTransparency = 0 }):Play()
	task.delay(4.5, function()
		if bb.Parent then
			TweenService:Create(f, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
			task.wait(0.45) bb:Destroy()
		end
	end)
end)
