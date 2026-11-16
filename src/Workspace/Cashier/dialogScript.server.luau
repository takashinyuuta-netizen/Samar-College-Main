-- services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--modules
local DialogModule = require(ReplicatedStorage.DialogModule)

--references
local player = game.Players.LocalPlayer
local npc = script.Parent -- Reference to the NPC model
local npcGui = npc:WaitForChild("Head"):WaitForChild("gui")
local prompt = npc:WaitForChild("ProximityPrompt")

-- (Samar College fix) talk to the cashier from across the counter
local TALK_RANGE = 12      -- prompt / tap range (the counter is ~4-5 studs deep)
local SHOP_CLOSE_RANGE = 18 -- the shop closes by itself if you walk away
prompt.MaxActivationDistance = TALK_RANGE
prompt.RequiresLineOfSight = false
prompt.ClickablePrompt = true

local dialogObject = DialogModule.new("Cashier", npc, prompt)
dialogObject:addDialog("Hi! Do you need something?", {"Yes!", "..."})

--

-- what happens when triggered (E / prompt button, or tapping the cashier)
local busy = false
local function startTalk()
	if busy or dialogObject.active or dialogObject.talking then return end
	busy = true
	dialogObject:triggerDialog(player, 1)
	task.delay(0.6, function() busy = false end)
end
prompt.Triggered:Connect(startTalk)

local tap = npc:FindFirstChild("CashierTap") or Instance.new("ClickDetector")
tap.Name = "CashierTap"
tap.MaxActivationDistance = TALK_RANGE
tap.Parent = npc
tap.MouseClick:Connect(function(who)
	if who == player then startTalk() end
end)

-- close the shop if the player walks away from the cashier
local function myDistance()
	local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local body = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
	if not (me and body) then return math.huge end
	return (me.Position - body.Position).Magnitude
end
task.spawn(function()
	while npc.Parent do
		local pg = player:FindFirstChild("PlayerGui")
		local shopGui = pg and pg:FindFirstChild("ShopGui")
		if shopGui and shopGui.Enabled and shopGui:GetAttribute("OpenedByCashier") and myDistance() > SHOP_CLOSE_RANGE then
			shopGui.Enabled = false
			shopGui:SetAttribute("OpenedByCashier", nil)
		end
		task.wait(0.25)
	end
end)

-- logic to go through dialogs
dialogObject.responded:Connect(function(responseNum, dialogNum)
	if dialogNum == 1 then
		if responseNum == 1 then
			dialogObject:hideGui("Take a look!")

			-- open the shop GUI
			local playerGui = player:FindFirstChild("PlayerGui")
			if playerGui then
				local shopGui = playerGui:FindFirstChild("ShopGui")
				if shopGui then
					shopGui:SetAttribute("OpenedByCashier", true)
					shopGui.Enabled = true
				end
			end
		end
	end
end)