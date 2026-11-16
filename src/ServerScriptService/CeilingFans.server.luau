-- CeilingFans (server): wall switches that turn ceiling fans on and off.
-- A switch is a Model tagged "FanSwitch" with:
--   ProximityPrompt "FanPrompt"
--   ObjectValue "Fans"  -> a Model/Folder holding the fans (Models tagged "CeilingFan")
--   optional parts "Toggle" (flips when switched) and "Indicator" (glows while on)
-- The fans only store the "On" attribute here; the spinning is done by CeilingFans.client.
-- Tag the switch "TapToUse" too and TapInteract toggles its "On" attribute on tap; this script follows it.
local CS = game:GetService("CollectionService")

local function fansOf(sw)
	local ref = sw:FindFirstChild("Fans")
	local list = {}
	if ref and ref.Value then
		for _, d in ipairs(ref.Value:GetDescendants()) do
			if CS:HasTag(d, "CeilingFan") then table.insert(list, d) end
		end
		if CS:HasTag(ref.Value, "CeilingFan") then table.insert(list, ref.Value) end
	end
	return list
end

local function setup(sw)
	if not sw:IsA("Model") then return end
	local prompt = sw:FindFirstChild("FanPrompt", true)
	if not prompt then return end
	local toggle = sw:FindFirstChild("Toggle", true)
	local indicator = sw:FindFirstChild("Indicator", true)
	local toggleCF = toggle and toggle.CFrame
	local function apply(on)
		for _, f in ipairs(fansOf(sw)) do f:SetAttribute("On", on) end
		prompt.ActionText = on and "Turn off fans" or "Turn on fans"
		if toggle then toggle.CFrame = on and (toggleCF * CFrame.Angles(math.rad(-25), 0, 0)) or toggleCF end
		if indicator then
			indicator.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
			indicator.Color = on and Color3.fromRGB(255, 120, 60) or Color3.fromRGB(120, 60, 40)
		end
	end
	prompt.ObjectText = sw:GetAttribute("ObjectText") or "Ceiling fans"
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function() sw:SetAttribute("On", not sw:GetAttribute("On")) end)
	sw:GetAttributeChangedSignal("On"):Connect(function() apply(sw:GetAttribute("On") == true) end)
	sw:SetAttribute("On", sw:GetAttribute("StartOn") == true)
	apply(sw:GetAttribute("On") == true)
end

for _, s in ipairs(CS:GetTagged("FanSwitch")) do task.spawn(setup, s) end
CS:GetInstanceAddedSignal("FanSwitch"):Connect(setup)
