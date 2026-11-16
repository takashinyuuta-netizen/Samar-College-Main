-- SuggestionBoxes: E to drop a note into a suggestion box.
-- A box is a Model tagged "SuggestionBox" with a ProximityPrompt "DropPrompt" and (optional)
-- a TextLabel named "CountLabel" that shows how many notes were dropped on this server.
-- A player can drop one note every 10 seconds; a paper note pops into the slot for a moment.
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local COOLDOWN = 10

local function setup(box)
	if not box:IsA("Model") then return end
	local prompt = box:FindFirstChild("DropPrompt", true)
	if not prompt then return end
	prompt.ActionText = "Drop a suggestion"
	prompt.HoldDuration = 0.4
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	local note = box:FindFirstChild("Note", true)
	local last = {}

	local function refresh()
		local n = box:GetAttribute("Count") or 0
		for _, d in ipairs(box:GetDescendants()) do
			if d:IsA("TextLabel") and d.Name == "CountLabel" then
				d.Text = n == 1 and "1 suggestion today" or (n .. " suggestions today")
			end
		end
	end

	prompt.Triggered:Connect(function(player)
		local now = os.clock()
		if last[player] and now - last[player] < COOLDOWN then return end
		last[player] = now
		box:SetAttribute("Count", (box:GetAttribute("Count") or 0) + 1)
		if note and note:IsA("BasePart") then
			local home = note:GetAttribute("HomeCFrame") or note.CFrame
			note:SetAttribute("HomeCFrame", home)
			note.Transparency = 0
			note.CFrame = home * CFrame.new(0, 0.5, 0)
			local t = TweenService:Create(note, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = home })
			t:Play()
			t.Completed:Once(function() note.Transparency = 1 end)
		end
	end)
	box:GetAttributeChangedSignal("Count"):Connect(refresh)
	refresh()
end

for _, b in ipairs(CS:GetTagged("SuggestionBox")) do task.spawn(setup, b) end
CS:GetInstanceAddedSignal("SuggestionBox"):Connect(setup)
