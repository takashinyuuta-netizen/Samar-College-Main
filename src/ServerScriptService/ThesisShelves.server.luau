-- ThesisShelves: F at a thesis bookcase to pull out a bound thesis and read its title.
-- A bookcase is a Model tagged "ThesisShelf" with:
--   ProximityPrompt "BrowsePrompt"
--   parts named "Book" (one of them slides out a little while you read it); spine bands are "BookBand"
--   and are left alone, so only books without a band are pulled out
--   attribute Titles -> thesis titles separated by "|"
-- The title shows above the bookcase for a few seconds. One reader at a time per bookcase.
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local SHOW_TIME = 4

local function setup(m)
	if not m:IsA("Model") then return end
	local prompt = m:FindFirstChild("BrowsePrompt", true)
	if not prompt then return end
	prompt.ActionText = "Browse a thesis"
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton

	local titles = string.split(m:GetAttribute("Titles") or "Untitled thesis", "|")
	local books, bands = {}, {}
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "BookBand" then table.insert(bands, d) end
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Book" then
			local banded = false
			for _, b in ipairs(bands) do
				if (b.Position - d.Position).Magnitude < d.Size.Y and math.abs(b.Position.X - d.Position.X) < 0.05 and math.abs(b.Position.Z - d.Position.Z) < 0.05 + d.Size.Z then banded = true break end
			end
			if not banded then table.insert(books, d) end
		end
	end

	-- the card that shows the title
	local anchor = prompt.Parent
	local bill = Instance.new("BillboardGui")
	bill.Name = "ThesisCard"
	bill.Size = UDim2.fromOffset(300, 90)
	bill.StudsOffset = Vector3.new(0, 3.2, 0)
	bill.MaxDistance = 30
	bill.Enabled = false
	bill.Parent = anchor
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(250, 248, 240)
	frame.BackgroundTransparency = 0.05
	frame.Parent = bill
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(30, 110, 60)
	stroke.Thickness = 2
	local head = Instance.new("TextLabel")
	head.Size = UDim2.new(1, -16, 0, 22)
	head.Position = UDim2.fromOffset(8, 4)
	head.BackgroundTransparency = 1
	head.Font = Enum.Font.GothamBold
	head.TextScaled = true
	head.TextColor3 = Color3.fromRGB(30, 110, 60)
	head.Text = "GRADUATE THESIS"
	head.Parent = frame
	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -16, 1, -32)
	body.Position = UDim2.fromOffset(8, 28)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.Gotham
	body.TextScaled = true
	body.TextWrapped = true
	body.TextColor3 = Color3.fromRGB(30, 30, 30)
	body.Parent = frame

	local busy = false
	local last = 0
	prompt.Triggered:Connect(function(player)
		if busy then return end
		busy = true
		prompt.Enabled = false
		local pick = math.random(1, #titles)
		if #titles > 1 and pick == last then pick = pick % #titles + 1 end
		last = pick
		body.Text = titles[pick]
		head.Text = "GRADUATE THESIS · read by " .. player.DisplayName
		bill.Enabled = true
		-- slide one book out toward the reader
		local book = #books > 0 and books[math.random(1, #books)]
		local home = book and book.CFrame
		if book then
			local dir = (prompt.Parent.Position - book.Position) * Vector3.new(1, 0, 1)
			dir = math.abs(dir.X) > math.abs(dir.Z) and Vector3.new(math.sign(dir.X), 0, 0) or Vector3.new(0, 0, math.sign(dir.Z))
			TweenService:Create(book, TweenInfo.new(0.35), { CFrame = home + dir * 0.45 }):Play()
		end
		task.wait(SHOW_TIME)
		bill.Enabled = false
		if book then TweenService:Create(book, TweenInfo.new(0.35), { CFrame = home }):Play() end
		task.wait(0.4)
		prompt.Enabled = true
		busy = false
	end)
end

for _, m in ipairs(CS:GetTagged("ThesisShelf")) do task.spawn(setup, m) end
CS:GetInstanceAddedSignal("ThesisShelf"):Connect(setup)
