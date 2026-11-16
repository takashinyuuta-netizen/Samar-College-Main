-- SlidingDoors: E to slide a door open / closed.
-- A door is a Model tagged "SlidingDoor" with:
--   child model "Panel"                -> every part in it slides together
--   ProximityPrompt "DoorPrompt"       -> anywhere inside the model (usually an invisible part in the doorway)
--   optional Sound "SlideSound"        -> plays when the door moves
-- Attribute SlideOffset (Vector3, studs) is how far the panel moves when open (default 5 on Z).
-- Open/closed state is in the "Open" attribute; set "RequestOpen" from other scripts to open/close it.
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local function setup(door)
	if not door:IsA("Model") then return end
	local panel = door:WaitForChild("Panel", 5)
	local prompt = door:FindFirstChild("DoorPrompt", true)
	if not panel or not prompt then return end
	local sound = door:FindFirstChild("SlideSound", true)
	local base = {}
	for _, p in ipairs(panel:GetDescendants()) do
		if p:IsA("BasePart") then base[p] = p.CFrame end
	end
	local info = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local busy = false
	local function set(open)
		if busy then return end
		busy = true
		local offset = open and (door:GetAttribute("SlideOffset") or Vector3.new(0, 0, 5)) or Vector3.zero
		if sound then sound:Play() end
		local last
		for p, cf in pairs(base) do
			last = TweenService:Create(p, info, { CFrame = cf + offset })
			last:Play()
		end
		if last then last.Completed:Wait() end
		door:SetAttribute("Open", open)
		prompt.ActionText = open and "Close door" or "Open door"
		busy = false
	end
	prompt.Triggered:Connect(function() set(not door:GetAttribute("Open")) end)
	door:GetAttributeChangedSignal("RequestOpen"):Connect(function()
		local want = door:GetAttribute("RequestOpen")
		if want ~= nil and want ~= door:GetAttribute("Open") then set(want) end
	end)
	door:SetAttribute("Open", false)
	prompt.ActionText = "Open door"
end

for _, d in ipairs(CS:GetTagged("SlidingDoor")) do task.spawn(setup, d) end
CS:GetInstanceAddedSignal("SlidingDoor"):Connect(setup)
