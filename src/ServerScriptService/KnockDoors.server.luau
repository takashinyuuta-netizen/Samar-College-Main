-- KnockDoors: staff-only doors that cannot be opened, but you can knock on them.
-- A door is a Model tagged "KnockDoor" with:
--   ProximityPrompt (any name) -> "Knock"
--   part "Leaf"                -> shakes a little when someone knocks
--   optional attribute Reply   -> text shown above the door for a few seconds
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local function setup(m)
	if not m:IsA("Model") then return end
	local prompt = m:FindFirstChildWhichIsA("ProximityPrompt", true)
	local leaf = m:FindFirstChild("Leaf", true)
	if not prompt or not leaf then return end
	prompt.ActionText = "Knock"
	local home = leaf.CFrame
	local bill = Instance.new("BillboardGui")
	bill.Name = "KnockReply"
	bill.Size = UDim2.fromOffset(260, 60)
	bill.StudsOffset = Vector3.new(0, leaf.Size.Y / 2 + 1, 0)
	bill.MaxDistance = 40
	bill.Enabled = false
	bill.Parent = leaf
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	t.BackgroundTransparency = 0.1
	t.TextColor3 = Color3.fromRGB(30, 30, 30)
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.Parent = bill
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0.25, 0) c.Parent = t
	local busy = false
	prompt.Triggered:Connect(function(player)
		if busy then return end
		busy = true
		for _ = 1, 2 do
			local a = TweenService:Create(leaf, TweenInfo.new(0.06), { CFrame = home * CFrame.new(0, 0, 0.03) })
			a:Play() a.Completed:Wait()
			local b = TweenService:Create(leaf, TweenInfo.new(0.06), { CFrame = home })
			b:Play() b.Completed:Wait()
			task.wait(0.15)
		end
		t.Text = m:GetAttribute("Reply") or "Staff only. Please proceed to the windows."
		bill.Enabled = true
		task.wait(3)
		bill.Enabled = false
		busy = false
	end)
end

for _, m in ipairs(CS:GetTagged("KnockDoor")) do task.spawn(setup, m) end
CS:GetInstanceAddedSignal("KnockDoor"):Connect(setup)
