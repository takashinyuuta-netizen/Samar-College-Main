-- Tag a part "OpenClosedSign" (with SurfaceGui SignGui > Card > Top/Mid/Bot): tap/click/E flips OPEN <-> CLOSED.
local CS = game:GetService("CollectionService")
local function render(p)
	local card = p:FindFirstChild("SignGui") and p.SignGui:FindFirstChild("Card") if not card then return end
	local open = p:GetAttribute("Open")
	card.BackgroundColor3 = open and Color3.fromRGB(30, 140, 70) or Color3.fromRGB(200, 30, 30)
	card.Top.Text = open and "Hello, We are" or "SORRY, We are"
	card.Mid.Text = open and "OPEN" or "CLOSED"
	card.Mid.TextColor3 = open and Color3.fromRGB(30, 140, 70) or Color3.fromRGB(200, 30, 30)
	card.Bot.Text = open and "Come in!" or "Please Come Again"
	local pp = p:FindFirstChildOfClass("ProximityPrompt") if pp then pp.ActionText = open and "Flip to CLOSED" or "Flip to OPEN" end
end
local function setup(p)
	if p:GetAttribute("Open") == nil then p:SetAttribute("Open", false) end
	local function flip() p:SetAttribute("Open", not p:GetAttribute("Open")) end
	local cd = p:FindFirstChildOfClass("ClickDetector") if cd then cd.MouseClick:Connect(flip) end
	local pp = p:FindFirstChildOfClass("ProximityPrompt") if pp then pp.Triggered:Connect(flip) end
	p:GetAttributeChangedSignal("Open"):Connect(function() render(p) end)
	render(p)
end
for _, p in ipairs(CS:GetTagged("OpenClosedSign")) do task.spawn(setup, p) end
CS:GetInstanceAddedSignal("OpenClosedSign"):Connect(setup)
