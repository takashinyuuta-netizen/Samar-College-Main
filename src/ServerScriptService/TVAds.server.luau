-- TVAds: wall TVs that play Samar College ads one after another.
-- A TV is a Model tagged "AdTV" with a part "Screen" whose SurfaceGui holds Frames named
-- Ad_1, Ad_2 ... (one is shown at a time).
--   attribute Interval : seconds per ad (default 6)
--   attribute On       : set by PowerToggles (F); the ads pause while the TV is off
--   attribute Ad       : the ad on screen now
--   ProximityPrompt "AdPrompt" (E, optional): skip to the next ad
local CS = game:GetService("CollectionService")

local function setup(tv)
	if not tv:IsA("Model") then return end
	local screen = tv:FindFirstChild("Screen", true)
	local gui = screen and screen:FindFirstChildOfClass("SurfaceGui")
	if not gui then return end
	local ads = {}
	for _, f in ipairs(gui:GetDescendants()) do
		local n = f:IsA("GuiObject") and tonumber(f.Name:match("^Ad_(%d+)$"))
		if n then ads[n] = f end
	end
	if #ads == 0 then return end

	local shownAt = os.clock()
	local function show(i)
		tv:SetAttribute("Ad", i)
		for k, f in ipairs(ads) do f.Visible = (k == i) end
		shownAt = os.clock()
	end
	local function nextAd() show((tv:GetAttribute("Ad") or 0) % #ads + 1) end
	show(1)

	local prompt = tv:FindFirstChild("AdPrompt", true)
	if prompt then
		prompt.ActionText = "Next ad"
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
		prompt.Triggered:Connect(function()
			if tv:GetAttribute("On") ~= false then nextAd() end
		end)
		local function sync() prompt.Enabled = tv:GetAttribute("On") ~= false end
		tv:GetAttributeChangedSignal("On"):Connect(sync)
		sync()
	end

	task.spawn(function()
		while tv.Parent do
			task.wait(0.5)
			if tv:GetAttribute("On") ~= false and os.clock() - shownAt >= (tv:GetAttribute("Interval") or 6) then
				nextAd()
			end
		end
	end)
end

for _, tv in ipairs(CS:GetTagged("AdTV")) do task.spawn(setup, tv) end
CS:GetInstanceAddedSignal("AdTV"):Connect(setup)
