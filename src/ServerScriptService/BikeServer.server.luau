--[[ BikeServer — free School Bike for every player.
  • Every player owns the "SchoolBike" item (ShopServer gives it). While it is equipped in the Bag it sits on the hotbar
    as a tool. Tapping it (holding the tool) summons THAT player's bike in front of them and seats them on it.
  • One bike per player. Only the owner can sit on it — anyone else is pushed off.
  • The rider's client drives the bike (it owns the physics); the server only checks ownership and cleans up.
  • Jump = get off. A parked bike shows its kickstand; WALK INTO IT (or tap it) to ride again — only the owner
    gets seated, other players just bump into it. No name tag over the bike. Parked bikes disappear after
    PARK_TIMEOUT seconds, when the owner leaves, dies, unequips it in the Bag, or summons a new one.
  • Bell: the rider rings it (BikeRemote "bell") — everyone nearby hears it. Headlight turns on at night. ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")

local TEMPLATE = SS:WaitForChild("BikeTemplate")
local remote = RS:WaitForChild("BikeRemote")
local TOOL = "SchoolBike"
local PARK_TIMEOUT = 120
local SUMMON_COOLDOWN = 2

local folder = workspace:FindFirstChild("Bikes") or Instance.new("Folder")
folder.Name = "Bikes" folder.Parent = workspace

local bikes = {}      -- player -> model
local lastSummon = {}
local lastBell = {}
local remount = {}    -- player -> { armed = bool }: after getting off you must step away before walking back on
local REMOUNT_RANGE = 3.2  -- walk this close to your parked bike's saddle = get on
local REARM_RANGE = 4.8    -- step this far away after getting off before walking into it seats you again

local function toast(player, msg)
	remote:FireClient(player, "toast", msg)
end

local function setRiderGroup(character, on)
	for _, p in ipairs(character:GetDescendants()) do
		if p:IsA("BasePart") then
			if on then p:SetAttribute("PrevGroup", p.CollisionGroup) p.CollisionGroup = "BikeRider"
			else p.CollisionGroup = p:GetAttribute("PrevGroup") or "Default" end
		end
	end
end

local function despawn(player)
	local b = bikes[player]
	bikes[player] = nil
	if b and b.Parent then
		local seat = b:FindFirstChild("BikeSeat")
		local occ = seat and seat.Occupant
		if occ then occ.Sit = false end
		b:Destroy()
	end
end

local function setParked(bike, parked)
	local root = bike.PrimaryPart
	local ks = bike:FindFirstChild("Kickstand")
	if ks then ks.Transparency = parked and 0 or 1 end
	bike:SetAttribute("Parked", parked)
	bike:SetAttribute("ParkedAt", parked and os.clock() or 0)
	if parked then
		root.Drive.PlaneVelocity = Vector2.zero
		task.delay(0.8, function()
			if bike.Parent and bike:GetAttribute("Parked") then
				-- settle upright with a small kickstand lean, then freeze in place
				local cf = root.CFrame
				local _, yaw = cf:ToEulerAnglesYXZ()
				root.Anchored = true
				bike:PivotTo(CFrame.new(cf.Position) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, math.rad(-7)))
			end
		end)
	else
		root.Anchored = false
	end
end

local function groundBelow(pos, ignore)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = ignore
	local r = workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), rp)
	return r and r.Position
end

local function seatOwner(player, bike)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local seat = bike:FindFirstChild("BikeSeat")
	if not (hum and seat) or hum.Health <= 0 then return end
	if seat.Occupant then return end
	if player:GetAttribute("EquipLocked") then return end
	hum:UnequipTools()
	setParked(bike, false)
	local root = bike.PrimaryPart
	pcall(function() root:SetNetworkOwner(player) end)
	seat.Disabled = false -- the seat is disabled while parked so strangers don't sit on it by touch
	seat:Sit(hum)
end

local function summon(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or hum.Health <= 0 then return end
	if player:GetAttribute("EquipLocked") then toast(player, "🔒 No bikes during events or games") return end
	if hum.Sit and not (hum.SeatPart and hum.SeatPart.Name == "BikeSeat") then toast(player, "Stand up first to use your bike") return end

	-- already have a bike close by? just get on it
	local existing = bikes[player]
	if existing and existing.Parent and (existing:GetPivot().Position - hrp.Position).Magnitude < 25 then
		seatOwner(player, existing)
		return
	end
	if lastSummon[player] and os.clock() - lastSummon[player] < SUMMON_COOLDOWN then return end
	lastSummon[player] = os.clock()
	despawn(player)

	local look = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.1 then look = Vector3.new(0, 0, -1) end
	look = look.Unit
	local spot = hrp.Position + look * 3
	local ground = groundBelow(spot, { char, folder })
	if not ground then toast(player, "There is no room for a bike here") return end
	-- not inside walls: check headroom
	local ov = OverlapParams.new()
	ov.FilterType = Enum.RaycastFilterType.Exclude
	ov.FilterDescendantsInstances = { char, folder }
	local hits = workspace:GetPartBoundsInBox(CFrame.new(ground + Vector3.new(0, 2.2, 0)) * CFrame.lookAt(Vector3.zero, look), Vector3.new(1.6, 2.6, 4.2), ov)
	for _, h in ipairs(hits) do
		if h.CanCollide and h.Transparency < 1 then toast(player, "Not enough space here — move to an open area") return end
	end

	local bike = TEMPLATE:Clone()
	bike.Name = player.Name .. "_Bike"
	bike:SetAttribute("OwnerId", player.UserId)
	local tag = bike.PrimaryPart:FindFirstChild("OwnerTag")
	if tag then tag:Destroy() end -- no name tag over the bike
	-- face the way the player is looking (bike forward = -Z)
	local yawCF = CFrame.lookAt(Vector3.zero, look)
	bike:PivotTo(CFrame.new(ground + Vector3.new(0, 0.05, 0)) * yawCF)
	for _, p in ipairs(bike:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = false end end
	bike.PrimaryPart.Upright.CFrame = yawCF
	bike.Parent = folder
	bikes[player] = bike

	local seat = bike.BikeSeat
	local rider
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occ = seat.Occupant
		if occ then
			local p = Players:GetPlayerFromCharacter(occ.Parent)
			if p ~= player then
				task.defer(function() occ.Sit = false occ.Jump = true end)
				if p then toast(p, "That's " .. player.DisplayName .. "'s bike — use your own from the hotbar 🚲") end
				return
			end
			rider = occ.Parent
			setRiderGroup(rider, true)
			setParked(bike, false)
			pcall(function() bike.PrimaryPart:SetNetworkOwner(player) end)
			bike:SetAttribute("Riding", true)
		else
			if rider and rider.Parent then setRiderGroup(rider, false) end
			rider = nil
			seat.Disabled = true
			remount[player] = { armed = false }
			bike:SetAttribute("Riding", false)
			if bike.Parent then
				pcall(function() bike.PrimaryPart:SetNetworkOwner(nil) end)
				setParked(bike, true)
			end
		end
	end)
	bike.PrimaryPart.RideClick.MouseClick:Connect(function(who)
		if who == player then seatOwner(player, bike)
		else toast(who, "That's " .. player.DisplayName .. "'s bike — tap the 🚲 on your hotbar for your own") end
	end)
	task.wait(0.15)
	seatOwner(player, bike)
end

local function watchCharacter(player, char)
	char.ChildAdded:Connect(function(c)
		if c:IsA("Tool") and c.Name == TOOL then
			summon(player)
			task.defer(function()
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then hum:UnequipTools() end
			end)
		end
	end)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then hum.Died:Connect(function() despawn(player) end) end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char) watchCharacter(player, char) end)
	if player.Character then watchCharacter(player, player.Character) end
	-- unequipping the bike in the Bag removes it
	player:GetAttributeChangedSignal("Equipped_SchoolBike"):Connect(function()
		if not player:GetAttribute("Equipped_SchoolBike") then despawn(player) end
	end)
	-- joining an event / sports match / the stage puts the bike away
	player:GetAttributeChangedSignal("EquipLocked"):Connect(function()
		if player:GetAttribute("EquipLocked") then despawn(player) end
	end)
end)
for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then watchCharacter(p, p.Character) end
end
Players.PlayerRemoving:Connect(function(p) despawn(p) lastSummon[p] = nil lastBell[p] = nil remount[p] = nil end)

-- walk into your own parked bike = get on and ride
task.spawn(function()
	while true do
		task.wait(0.15)
		for player, bike in pairs(bikes) do
			local seat = bike.Parent and bike:FindFirstChild("BikeSeat")
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if seat and hrp and hum and hum.Health > 0 and not seat.Occupant and not hum.Sit then
				local d = Vector3.new(hrp.Position.X - seat.Position.X, 0, hrp.Position.Z - seat.Position.Z).Magnitude
				local dy = math.abs(hrp.Position.Y - seat.Position.Y)
				local st = remount[player]
				if st and not st.armed then
					if d > REARM_RANGE then st.armed = true end
				elseif d <= REMOUNT_RANGE and dy < 4 then
					remount[player] = { armed = false }
					seatOwner(player, bike)
				end
			end
		end
	end
end)

remote.OnServerEvent:Connect(function(player, action)
	local bike = bikes[player]
	if not (bike and bike.Parent) then return end
	if action == "bell" then
		if lastBell[player] and os.clock() - lastBell[player] < 0.6 then return end
		lastBell[player] = os.clock()
		local s = bike.PrimaryPart:FindFirstChild("BellSound")
		if s then s:Play() end
		remote:FireAllClients("bell", bike)
	elseif action == "park" then
		local occ = bike.BikeSeat.Occupant
		if occ and occ.Parent == player.Character then occ.Sit = false end
	elseif action == "putaway" then
		despawn(player)
		toast(player, "Bike put away — tap 🚲 on your hotbar to ride again")
	end
end)

-- housekeeping: headlights at night, parked timeout, fell off the island
task.spawn(function()
	while true do
		local t = Lighting.ClockTime
		local night = (t >= 18 or t < 6)
		for player, bike in pairs(bikes) do
			if not bike.Parent then bikes[player] = nil continue end
			local bulb = bike:FindFirstChild("Bulb")
			if bulb then
				local riding = bike:GetAttribute("Riding")
				bulb.SpotLight.Enabled = night and riding == true
				bulb.Material = (night and riding) and Enum.Material.Neon or Enum.Material.Glass
			end
			if bike:GetAttribute("Parked") and os.clock() - (bike:GetAttribute("ParkedAt") or 0) > PARK_TIMEOUT then
				despawn(player)
				toast(player, "Your parked bike was put away — tap 🚲 on your hotbar to ride again")
			elseif bike.PrimaryPart.Position.Y < -80 then
				despawn(player)
				toast(player, "Your bike fell off the island! Tap 🚲 to summon a new one")
			end
		end
		task.wait(1)
	end
end)
