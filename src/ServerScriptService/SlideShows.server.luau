-- SlideShows: smart boards / TVs with several slides.
-- A Model tagged "SlideShow" contains a part named "Screen" whose SurfaceGui holds
-- Frames named Slide_1 ... Slide_N, plus parts named "NextButton" and "PrevButton".
-- Tap the buttons to change slides (wraps around). Works alongside PowerToggle.
local CS = game:GetService("CollectionService")
local RANGE = 16
local function setup(m)
	if not m:IsA("Model") or m:GetAttribute("_slideReady") then return end
	local screen = m:FindFirstChild("Screen", true)
	local gui = screen and screen:FindFirstChildOfClass("SurfaceGui")
	if not gui then return end
	local slides = {}
	for _, f in ipairs(gui:GetChildren()) do
		local n = tonumber(f.Name:match("^Slide_(%d+)$"))
		if n then slides[n] = f end
	end
	if #slides == 0 then return end
	m:SetAttribute("_slideReady", true)
	local current = m:GetAttribute("Slide") or 1
	local counter = gui:FindFirstChild("Counter", true)
	local function show(i)
		current = ((i - 1) % #slides) + 1
		for k, f in ipairs(slides) do f.Visible = (k == current) end
		m:SetAttribute("Slide", current)
		if counter and counter:IsA("TextLabel") then counter.Text = current .. " / " .. #slides end
	end
	show(current)
	for _, spec in ipairs({{"NextButton", 1}, {"PrevButton", -1}}) do
		local b = m:FindFirstChild(spec[1], true)
		if b then
			local cd = Instance.new("ClickDetector")
			cd.MaxActivationDistance = RANGE
			cd.Parent = b
			cd.MouseClick:Connect(function(player)
				local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if not hrp or (hrp.Position - b.Position).Magnitude > RANGE + 6 then return end
				show(current + spec[2])
			end)
		end
	end
end
for _, m in ipairs(CS:GetTagged("SlideShow")) do task.spawn(setup, m) end
CS:GetInstanceAddedSignal("SlideShow"):Connect(setup)
