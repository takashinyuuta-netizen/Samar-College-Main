--[[ CampusCheckIn (Phase 1 test event) ────────────────────────────────────
  A glowing ring appears at a random open area (parts tagged "EventOpenArea").
  Walking into the ring joins the event. The earlier you check in, the more points
  you get, so the first three students earn the place bonuses.
  Use it to test: announce → join → rewards → cleanup.
───────────────────────────────────────────────────────────────────────────]]
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local M = {}
local FALLBACK = { pos = Vector3.new(125, 3.5, 15), name = "Courtyard" }

local function pickArea()
	local spots = CollectionService:GetTagged("EventOpenArea")
	local valid = {}
	for _, s in ipairs(spots) do if s:IsA("BasePart") and s:IsDescendantOf(workspace) then table.insert(valid, s) end end
	if #valid == 0 then return FALLBACK.pos, FALLBACK.name end
	local s = valid[math.random(#valid)]
	return s.Position, s:GetAttribute("AreaName") or s.Name
end

function M.Setup(ctx)
	local pos, name = pickArea()
	local ground = pos - Vector3.new(0, 2.9, 0)
	-- ring on the floor
	local ring = Instance.new("Part")
	ring.Name = "CheckInRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, 12, 12)
	ring.CFrame = CFrame.new(ground) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true ring.CanCollide = false
	ring.Material = Enum.Material.Neon ring.Color = Color3.fromRGB(80, 220, 140) ring.Transparency = 0.35
	ring.Parent = ctx.Folder
	-- light column so it can be seen from far away
	local column = Instance.new("Part")
	column.Name = "LightColumn"
	column.Size = Vector3.new(1.2, 40, 1.2)
	column.CFrame = CFrame.new(ground + Vector3.new(0, 20, 0))
	column.Anchored = true column.CanCollide = false column.CanQuery = false
	column.Material = Enum.Material.Neon column.Color = Color3.fromRGB(120, 255, 180) column.Transparency = 0.6
	column.Parent = ctx.Folder
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(240, 60) bb.StudsOffset = Vector3.new(0, 7, 0) bb.AlwaysOnTop = true bb.MaxDistance = 250
	bb.Parent = ring
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.TextScaled = true t.Font = Enum.Font.GothamBlack
	t.TextColor3 = Color3.new(1, 1, 1) t.TextStrokeTransparency = 0.3 t.Text = "📍 CAMPUS CHECK-IN\nStep into the ring!"
	t.Parent = bb

	ctx:SetLocation(ground, name)
	ctx.GotoPosition = ground + Vector3.new(0, 3, 9)
	ctx.ScoreLabel = "Check-in points"
	ctx.JoinMode = "zone"
	ctx.Data.checked = {}
	ctx.Data.order = 0

	-- step in → join + points (validated on the server by position)
	ctx:Connect(ring.Touched, function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or ctx.Data.checked[player] then return end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - ground).Magnitude > 12 then return end
		if ctx.Phase ~= "Active" and ctx.Phase ~= "Announce" then return end
		if ctx:Join(player) then
			ctx.Data.checked[player] = true
			ctx.Data.order += 1
			ctx:AddScore(player, math.max(10, 110 - ctx.Data.order * 10))
			ctx:Toast(player, ("✅ Checked in #%d!"):format(ctx.Data.order))
		end
	end)
end

function M.Start(ctx)
	ctx:ToastAll("📍 Check-in is open — invite your friends before time runs out!")
end

function M.OnPlayerLeft(ctx, player) ctx.Data.checked[player] = nil end

return M
