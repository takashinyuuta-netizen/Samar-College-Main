-- ClearanceDesks: E at the Dean's office counter to have your clearance slip signed.
-- A desk is a Model tagged "ClearanceDesk" with:
--   ProximityPrompt "ClearancePrompt"
--   model "Stamp"          -> presses down on the slip
--   part "Slip"            -> appears with its SurfaceGui; the TextLabel "ApprovedMark" shows after the stamp
--   TextLabel "ServingLabel" (who is being served) and "CountLabel" (slips signed on this server)
-- Optional desk attributes: ActionText, ObjectText, CountText (e.g. "%d requests received today",
-- "%d" is replaced by the number) so other offices can reuse it for their own forms.
-- One slip per player every 8 seconds.
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local COOLDOWN = 8

local function setup(desk)
	if not desk:IsA("Model") then return end
	local prompt = desk:FindFirstChild("ClearancePrompt", true)
	if not prompt then return end
	prompt.ActionText = desk:GetAttribute("ActionText") or "Submit clearance slip"
	prompt.ObjectText = desk:GetAttribute("ObjectText") or "Dean's Office"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 6
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton

	local stamp = desk:FindFirstChild("Stamp")
	local slip = desk:FindFirstChild("Slip", true)
	local slipGui = slip and slip:FindFirstChildOfClass("SurfaceGui")
	local mark = slipGui and slipGui:FindFirstChild("ApprovedMark", true)
	local stampParts = {}
	if stamp then
		for _, p in ipairs(stamp:GetDescendants()) do
			if p:IsA("BasePart") then stampParts[p] = p.CFrame end
		end
	end

	local function labels(name, text)
		for _, d in ipairs(desk:GetDescendants()) do
			if d:IsA("TextLabel") and d.Name == name then d.Text = text end
		end
	end
	local function refresh()
		local n = desk:GetAttribute("Count") or 0
		local fmt = desk:GetAttribute("CountText")
		if fmt then
			labels("CountLabel", (fmt:gsub("%%d", tostring(n))))
		else
			labels("CountLabel", n == 1 and "1 slip signed today" or (n .. " slips signed today"))
		end
	end

	-- the stamp moves over the slip, presses down and goes back
	local function press()
		if not (stamp and slip) then return end
		local first = next(stampParts)
		if not first then return end
		local home = stampParts[first]
		local over = slip.Position - home.Position
		local lift = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local down = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local function moveAll(offset, info)
			local last
			for p, cf in pairs(stampParts) do
				last = TweenService:Create(p, info, { CFrame = cf + offset })
				last:Play()
			end
			if last then last.Completed:Wait() end
		end
		local flat = Vector3.new(over.X, 0, over.Z)
		moveAll(Vector3.new(0, 0.6, 0), lift)
		moveAll(flat + Vector3.new(0, 0.6, 0), lift)
		moveAll(flat + Vector3.new(0, -0.05, 0), down)
		if mark then mark.Visible = true end
		moveAll(flat + Vector3.new(0, 0.6, 0), lift)
		moveAll(Vector3.new(0, 0.6, 0), lift)
		moveAll(Vector3.zero, down)
	end

	local busy = false
	local last = {}
	prompt.Triggered:Connect(function(player)
		local now = os.clock()
		if busy or (last[player] and now - last[player] < COOLDOWN) then return end
		last[player] = now
		busy = true
		prompt.Enabled = false
		labels("ServingLabel", player.DisplayName)
		if slip then
			slip.Transparency = 0
			if slipGui then slipGui.Enabled = true end
			if mark then mark.Visible = false end
		end
		task.wait(0.4)
		press()
		desk:SetAttribute("Count", (desk:GetAttribute("Count") or 0) + 1)
		task.wait(2.5)
		if slip then
			slip.Transparency = 1
			if slipGui then slipGui.Enabled = false end
		end
		labels("ServingLabel", "—")
		prompt.Enabled = true
		busy = false
	end)
	desk:GetAttributeChangedSignal("Count"):Connect(refresh)
	refresh()
end

for _, d in ipairs(CS:GetTagged("ClearanceDesk")) do task.spawn(setup, d) end
CS:GetInstanceAddedSignal("ClearanceDesk"):Connect(setup)
