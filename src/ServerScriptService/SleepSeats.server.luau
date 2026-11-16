--[[ SleepSeats — sleeping bags make you LIE DOWN (on your back, head on the pillow) instead of sitting.
  • Every Seat inside the camp tents (IslandExpansion.CampSite.Tents) is tagged "SleepSeat" at start.
    Any other Seat can be made a bed too: tag it "SleepSeat" (and put a part named "Pillow" next to it).
  • The prompt reads "Sleep". Jump to get up.
  • SleepPoseClient (StarterPlayerScripts) stops the sitting animation so the legs lie straight. ]]
local CS = game:GetService("CollectionService")

local camp = workspace:FindFirstChild("IslandExpansion") and workspace.IslandExpansion:FindFirstChild("CampSite")
local tents = camp and camp:FindFirstChild("Tents")
if tents then
	for _, d in ipairs(tents:GetDescendants()) do
		if d:IsA("Seat") then CS:AddTag(d, "SleepSeat") end
	end
end

local BODY_HALF = 0.55   -- HumanoidRootPart lies this far above the bag
local HEAD_FROM_ROOT = 2.4 -- head is this far from the root along the body

-- the pillow that belongs to this bed (closest part named Pillow in the same model)
local function pillowFor(seat)
	local model = seat:FindFirstAncestorWhichIsA("Model") or seat.Parent
	local best, bd
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Name == "Pillow" then
			local d = (p.Position - seat.Position).Magnitude
			if not bd or d < bd then best, bd = p, d end
		end
	end
	return best
end

-- top of the sleeping bag under the seat (the closest part named SleepingBag; else the seat's own bottom)
local function bedTop(seat)
	local model = seat:FindFirstAncestorWhichIsA("Model") or seat.Parent
	local best, bd
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Name == "SleepingBag" then
			local d = (Vector3.new(p.Position.X, 0, p.Position.Z) - Vector3.new(seat.Position.X, 0, seat.Position.Z)).Magnitude
			if not bd or d < bd then best, bd = p, d end
		end
	end
	if best and bd < 3 then return best.Position.Y + best.Size.Y / 2 end
	return seat.Position.Y - seat.Size.Y / 2
end

local function layDown(seat, weld)
	local pillow = pillowFor(seat)
	local head
	if pillow then
		head = Vector3.new(pillow.Position.X - seat.Position.X, 0, pillow.Position.Z - seat.Position.Z)
	end
	if not head or head.Magnitude < 0.1 then head = Vector3.new(seat.CFrame.LookVector.X, 0, seat.CFrame.LookVector.Z) end
	head = head.Unit
	-- head on the pillow, body along the bag, lying on the back (face up)
	local anchor = pillow and Vector3.new(pillow.Position.X, 0, pillow.Position.Z) or Vector3.new(seat.Position.X, 0, seat.Position.Z) + head * 2
	local rootXZ = anchor - head * HEAD_FROM_ROOT
	local pos = Vector3.new(rootXZ.X, bedTop(seat) + BODY_HALF, rootXZ.Z)
	local back = Vector3.new(0, -1, 0)          -- LookVector = up → face to the sky
	local right = head:Cross(back)
	local want = CFrame.fromMatrix(pos, right, head, back)
	weld.C0 = seat.CFrame:ToObjectSpace(want)
	weld.C1 = CFrame.new()
end

local function setup(seat)
	if not seat:IsA("Seat") or seat:GetAttribute("SleepReady") then return end
	seat:SetAttribute("SleepReady", true)
	seat:SetAttribute("SleepSeat", true)
	seat:SetAttribute("SeatName", "Sleeping bag")
	-- the Sit prompt from PromptSeats says "Sleep" here
	local function relabel()
		local pp = seat:FindFirstChild("SitPrompt")
		if pp then pp.ActionText = "Sleep" pp.ObjectText = "Sleeping bag" end
	end
	relabel()
	seat.ChildAdded:Connect(function(c)
		if c:IsA("ProximityPrompt") then task.defer(relabel) end
		if c:IsA("Weld") and c.Name == "SeatWeld" then
			task.defer(function() if c.Parent then layDown(seat, c) end end)
		end
	end)
	task.delay(1, relabel)
end

for _, s in ipairs(CS:GetTagged("SleepSeat")) do setup(s) end
CS:GetInstanceAddedSignal("SleepSeat"):Connect(setup)
