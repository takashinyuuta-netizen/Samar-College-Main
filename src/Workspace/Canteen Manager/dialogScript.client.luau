-- Canteen Manager (sits at the manager's desk by the kitchen counter)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DialogModule = require(ReplicatedStorage.DialogModule)

local player = game.Players.LocalPlayer
local npc = script.Parent
npc:WaitForChild("Head"):WaitForChild("gui")
local prompt = npc:WaitForChild("ProximityPrompt")
prompt.ObjectText = "Canteen Manager"
prompt.RequiresLineOfSight = false

local GOLD = "<font color='rgb(255,220,127)'>%s</font>"
local function hi(t) return GOLD:format(t) end
local function pick(t) return t[math.random(#t)] end

local dialogObject = DialogModule.new("Canteen Manager", npc, prompt)
local OPTIONS = { "What's good today?", "Where do I pay?", "Canteen rules?", "Nevermind" }
dialogObject:addDialog("Good day, iho / iha! I'm the " .. hi("canteen manager") .. ". Did you eat already?", OPTIONS) -- 1: greeting
dialogObject:addDialog("Anything else, iho / iha?", OPTIONS) -- 2: after an answer

local ANSWERS = {
	{ "Try our " .. hi("pancit") .. " and " .. hi("turon") .. " — bestsellers!", "The " .. hi("adobo rice meal") .. " is fresh from the kitchen.", "Hot " .. hi("champorado") .. " this morning, masarap!" },
	{ "Order and pay at the " .. hi("canteen counter") .. ", then wait for your food.", "For snacks and school items, talk to the " .. hi("Cashier") .. " at the shop counter." },
	{ "Fall in line, and " .. hi("CLAYGO") .. " — clean as you go!", "Throw your trash in the right bin, okay?", "No running inside the canteen, ha!" },
}
local BYE = { "Okay, eat well ha!", "Ingat, iho / iha!", "Come back at lunch time!" }

local busy = false
prompt.Triggered:Connect(function(p)
	if p ~= player or busy or dialogObject.active or dialogObject.talking then return end
	busy = true
	dialogObject:triggerDialog(player, 1)
	task.delay(0.6, function() busy = false end)
end)

dialogObject.responded:Connect(function(responseNum)
	local answers = ANSWERS[responseNum]
	if not answers then
		dialogObject:hideGui(pick(BYE))
		return
	end
	dialogObject:hideGui(pick(answers), true)
	task.delay(1.8, function() dialogObject:triggerDialog(player, 2) end)
end)
