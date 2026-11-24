-- ShopServer.lua
-- Token currencies (Common / Event), purchase validation, equip state,
-- equipment effects and consumable effects. The server validates everything.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("ShopRemotes")
local buyItemRemote = remotes:WaitForChild("BuyItem")
local useItemRemote = remotes:WaitForChild("UseItem")
local equipItemRemote = remotes:WaitForChild("EquipItem")
local feedbackRemote = remotes:WaitForChild("UpdateCash") -- fires (message) to the client
local toolsFolder = ReplicatedStorage:WaitForChild("Tools")
local shopItems = require(ReplicatedStorage:WaitForChild("ShopItems"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Outfits = require(ReplicatedStorage:WaitForChild("Outfits"))

-- Starting balances for NEW players (saved players load from PlayerData).
local STARTING_TOKENS = PlayerData.STARTING_COINS
local BASE_WALKSPEED = 16
local BASE_JUMPPOWER = 50

-- Cosmetic and Equipment are bought once and can be equipped.
local EQUIPPABLE = { Cosmetic = true, Equipment = true }

-- What each Equipment item does while equipped.
local EQUIPMENT_EFFECTS = {
	RunningShoes = { Speed = 10 },
	SpringBoots = { Jump = 20 },
	Flashlight = { Tool = "Flashlight" },
}
-- gear with a Tool field (Gravity Coil, Speed Coil, Magic Carpet...) is a tool you hold while it's equipped
for _, item in ipairs(shopItems.Equipment) do
	if item.Tool and not EQUIPMENT_EFFECTS[item.Id] then EQUIPMENT_EFFECTS[item.Id] = { Tool = item.Tool } end
end

-- one place that sets walk speed: base + equipment + held gear (Speed Coil) + drink boosts (Energy Drink / Bloxiade)
-- 🏃 SPRINT / RUN button (SprintServer sets player attribute "Sprinting")
local SPRINT_BONUS = 10
local function normalSpeed(player, sprinting)
	return BASE_WALKSPEED + (player:GetAttribute("EquipSpeed") or 0) + (player:GetAttribute("GearSpeed") or 0) + (player:GetAttribute("BoostSpeed") or 0)
		+ (sprinting and SPRINT_BONUS or 0)
end
local function applySpeed(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	if player:GetAttribute("SC_Frozen") then return end -- a sports game is holding this player in place
	local admin = player:GetAttribute("AdminSpeed")
	if admin then humanoid.WalkSpeed = admin return end
	humanoid.WalkSpeed = normalSpeed(player, player:GetAttribute("Sprinting") == true)
end
local boostToken = {}
local function speedBoost(player, amount, seconds)
	boostToken[player] = (boostToken[player] or 0) + 1
	local my = boostToken[player]
	player:SetAttribute("BoostSpeed", amount)
	applySpeed(player)
	task.delay(seconds, function()
		if boostToken[player] == my and player.Parent then player:SetAttribute("BoostSpeed", nil) applySpeed(player) end
	end)
end

local function findItem(itemId)
	for category, items in pairs(shopItems) do
		for _, item in ipairs(items) do
			if item.Id == itemId then
				return item, category
			end
		end
	end
	return nil
end

local function feedback(player, message)
	feedbackRemote:FireClient(player, message)
end

-- ===== HOTBAR =====
-- The bottom hotbar shows ONLY equipped items (max 9), in the order they were equipped.
-- Player attribute "Hotbar" = "ItemA,ItemB,..." (the clients read it). Equipped_<Id> = true marks each one.
local HOTBAR_SLOTS = 9
local function hotbarList(player)
	local list, seen = {}, {}
	for id in string.gmatch(player:GetAttribute("Hotbar") or "", "[^,]+") do
		if player:GetAttribute("Equipped_" .. id) and not seen[id] then seen[id] = true table.insert(list, id) end
	end
	-- anything equipped some other way (old saves, admin panel) goes at the end
	for _, items in pairs(shopItems) do
		if type(items) == "table" then
			for _, it in ipairs(items) do
				if type(it) == "table" and it.Id and player:GetAttribute("Equipped_" .. it.Id) and not seen[it.Id] then
					seen[it.Id] = true table.insert(list, it.Id)
				end
			end
		end
	end
	return list
end
local function saveHotbar(player, list)
	player:SetAttribute("Hotbar", table.concat(list, ","))
end
local function hotbarAdd(player, id)
	local list = hotbarList(player)
	if table.find(list, id) then return true end
	if #list >= HOTBAR_SLOTS then return false end
	player:SetAttribute("Equipped_" .. id, true)
	table.insert(list, id)
	saveHotbar(player, list)
	return true
end
local function hotbarRemove(player, id)
	player:SetAttribute("Equipped_" .. id, nil)
	local list = hotbarList(player)
	local i = table.find(list, id)
	if i then table.remove(list, i) end
	saveHotbar(player, list)
end

local function getCurrency(player, currencyName)
	local wallet = player:FindFirstChild("Wallet")
	return wallet and wallet:FindFirstChild(currencyName)
end

-- Consumable inventory (Folder of IntValues inside the player; replicates automatically)
local function getInventory(player)
	local inv = player:FindFirstChild("Inventory")
	if not inv then
		inv = Instance.new("Folder")
		inv.Name = "Inventory"
		inv.Parent = player
	end
	return inv
end

local function getItemCount(player, itemId)
	local inv = player:FindFirstChild("Inventory")
	local value = inv and inv:FindFirstChild(itemId)
	return value and value.Value or 0
end

local function addItem(player, itemId, amount)
	local inv = getInventory(player)
	local value = inv:FindFirstChild(itemId)
	if not value then
		value = Instance.new("IntValue")
		value.Name = itemId
		value.Parent = inv
	end
	value.Value += amount
end

local function removeItem(player, itemId, amount)
	local inv = player:FindFirstChild("Inventory")
	local value = inv and inv:FindFirstChild(itemId)
	if not value or value.Value < amount then return false end
	value.Value -= amount
	return true
end

-- Tools (only given while the matching Equipment item is equipped)
local function giveTool(player, toolName)
	local template = toolsFolder:FindFirstChild(toolName)
	if not template then return end
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end
	if backpack:FindFirstChild(toolName) then return end
	local character = player.Character
	if character and character:FindFirstChild(toolName) then return end
	template:Clone().Parent = backpack
end

local function removeTool(player, toolName)
	local backpack = player:FindFirstChild("Backpack")
	local inBackpack = backpack and backpack:FindFirstChild(toolName)
	if inBackpack then inBackpack:Destroy() end
	local character = player.Character
	local inHand = character and character:FindFirstChild(toolName)
	if inHand and inHand:IsA("Tool") then inHand:Destroy() end
end

-- Recalculate speed, jump and tools from whatever Equipment is equipped
local function refreshEquipment(player)
	local speed, jump = 0, 0
	local wantedTools = {}
	-- EquipLocked (set by EquipLock while you're in an event / sports match / on stage): every Equipment item is off
	local locked = player:GetAttribute("EquipLocked") == true

	for _, item in ipairs(shopItems.Equipment) do
		local fx = EQUIPMENT_EFFECTS[item.Id]
		if fx and not locked and player:GetAttribute("Equipped_" .. item.Id) then
			speed += fx.Speed or 0
			jump += fx.Jump or 0
			if fx.Tool then wantedTools[fx.Tool] = true end
		end
	end

	player:SetAttribute("EquipSpeed", speed)
	player:SetAttribute("EquipJump", jump)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and not player:GetAttribute("SC_Frozen") then
		applySpeed(player)
		humanoid.JumpPower = BASE_JUMPPOWER + jump
	end

	for _, item in ipairs(shopItems.Equipment) do
		local fx = EQUIPMENT_EFFECTS[item.Id]
		if fx and fx.Tool then
			if wantedTools[fx.Tool] then
				giveTool(player, fx.Tool)
			else
				removeTool(player, fx.Tool)
			end
		end
	end
end

-- Show the equipped cosmetic on the character (only one at a time)
local function refreshCosmetic(player)
	local character = player.Character
	if not character then return end
	for _, item in ipairs(shopItems.Cosmetic) do
		if Outfits.has(item.Id) then
			Outfits.remove(character, item.Id)
		end
	end
	for _, item in ipairs(shopItems.Cosmetic) do
		if player:GetAttribute("Equipped_" .. item.Id) and Outfits.has(item.Id) then
			Outfits.wear(character, item.Id)
		end
	end
end

-- Consumable item effects (triggered when USED from the inventory)
local function applyConsumable(player, item)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if item.Id == "PizzaSlice" and humanoid then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 15)
	elseif item.Id == "SmallSnack" and humanoid then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 25)
	elseif item.Id == "MedKit" and humanoid then
		humanoid.Health = humanoid.MaxHealth
	elseif item.Id == "EnergyDrink" and humanoid then
		speedBoost(player, 12, 30)
	elseif item.Gear and item.Id ~= "BodySwapPotion" and humanoid then
		-- Roblox gear food / drinks: hold the real model, open + eat/drink sounds, then the effect
		local template = toolsFolder:FindFirstChild(item.Gear)
		local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
		if template and template:FindFirstChild("Handle") and hand then
			local old = character:FindFirstChild("EatingGear")
			if old then old:Destroy() end
			local food = template.Handle:Clone()
			food.Name = "EatingGear"
			food.CanCollide = false food.Massless = true food.Anchored = false
			local grip = template.Grip
			local handOffset = hand.Name == "RightHand" and CFrame.new(0, -0.15, 0) or CFrame.new(0, -1, 0)
			local w = Instance.new("Weld")
			w.Part0 = hand w.Part1 = food
			w.C0 = handOffset * CFrame.Angles(math.rad(-90), 0, 0)
			w.C1 = grip
			w.Parent = food
			food.Parent = character
			local open = food:FindFirstChild("OpenSound") or food:FindFirstChild("Open")
			local drink = food:FindFirstChild("DrinkSound") or food:FindFirstChild("Drink")
			if open then open:Play() end
			-- bring it up to the mouth a few times
			task.spawn(function()
				task.wait(0.5)
				for bite = 1, 3 do
					if not food.Parent then break end
					w.C0 = handOffset * CFrame.new(0, 0.6, -0.3) * CFrame.Angles(math.rad(-150), 0, 0)
					if drink then drink:Play() end
					task.wait(0.45)
					w.C0 = handOffset * CFrame.Angles(math.rad(-90), 0, 0)
					task.wait(0.3)
				end
				if food.Parent then food:Destroy() end
			end)
		end
		local function heal(n) humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + n) end
		if item.Id == "Cheezburger" then
			heal(25)
		elseif item.Id == "BloxyCola" then
			heal(15)
			task.delay(2.4, function()
				local head = character:FindFirstChild("Head")
				if head then
					local burp = Instance.new("Sound") burp.SoundId = "rbxassetid://10722059" burp.PlaybackSpeed = 0.55 burp.Volume = 0.8 burp.Parent = head burp:Play()
					game:GetService("Debris"):AddItem(burp, 3)
				end
			end)
		elseif item.Id == "Bloxiade" then
			heal(10)
			speedBoost(player, 10, 20)
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local sp = Instance.new("Sparkles") sp.Name = "BloxiadeSparkles" sp.SparkleColor = Color3.fromRGB(80, 200, 255) sp.Parent = hrp
				game:GetService("Debris"):AddItem(sp, 20)
			end
		elseif item.Id == "SpaceSandwich" then
			heal(30)
			-- GearClient reads this and makes gravity light until then
			player:SetAttribute("LowGravityUntil", workspace:GetServerTimeNow() + 20)
		end
	elseif item.Id == "GlowStick" and character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local old = hrp:FindFirstChild("GlowStickLight")
			if old then old:Destroy() end
			local light = Instance.new("PointLight")
			light.Name = "GlowStickLight"
			light.Range = 16
			light.Brightness = 1.5
			light.Color = Color3.fromRGB(120, 255, 120)
			light.Parent = hrp
			task.delay(60, function()
				if light.Parent then light:Destroy() end
			end)
		end
	elseif item.Id == "InvisibilityPotion" and character then
		local originals = {}
		for _, obj in character:GetDescendants() do
			if obj:IsA("BasePart") then
				table.insert(originals, {obj, obj.Transparency})
				obj.Transparency = 0.7
			elseif obj:IsA("Decal") then
				table.insert(originals, {obj, obj.Transparency})
				obj.Transparency = 1
			end
		end
		task.delay(10, function()
			for _, saved in ipairs(originals) do
				if saved[1].Parent then saved[1].Transparency = saved[2] end
			end
		end)
	end
end

local function onPlayerAdded(player)
	player:GetAttributeChangedSignal("GearSpeed"):Connect(function() applySpeed(player) end)
	-- sprint on/off: only change the speed if nothing else (an event, detention, a sports game, the
	-- PATAAS climb, admin speed) is controlling it right now, i.e. the player is at their normal speed
	player:GetAttributeChangedSignal("Sprinting"):Connect(function()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not hum or player:GetAttribute("SC_Frozen") or player:GetAttribute("AdminSpeed") then return end
		local nowSprinting = player:GetAttribute("Sprinting") == true
		if math.abs(hum.WalkSpeed - normalSpeed(player, not nowSprinting)) < 0.01 then applySpeed(player) end
	end)
	player:GetAttributeChangedSignal("AdminSpeed"):Connect(function() applySpeed(player) end)
	player:GetAttributeChangedSignal("EquipLocked"):Connect(function() refreshEquipment(player) end)
	local data = PlayerData.load(player)

	-- Leaderboard: Time played + Title
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local timeValue = Instance.new("StringValue")
	timeValue.Name = "Time"
	timeValue.Parent = leaderstats
	local titleValue = Instance.new("StringValue")
	titleValue.Name = "Title"
	titleValue.Value = data.Title or PlayerData.DEFAULT_TITLE
	titleValue.Parent = leaderstats
	leaderstats.Parent = player

	-- Coins (hidden from the leaderboard, shown in the Coins GUI)
	local wallet = Instance.new("Folder")
	wallet.Name = "Wallet"
	for currencyName, amount in pairs(STARTING_TOKENS) do
		local value = Instance.new("IntValue")
		value.Name = currencyName
		value.Value = (data.Coins and tonumber(data.Coins[currencyName])) or amount
		value.Parent = wallet
	end
	wallet.Parent = player

	-- Restore the bag
	for _, id in ipairs(data.Owned) do player:SetAttribute("Owned_" .. id, true) end
	for _, id in ipairs(data.Equipped) do player:SetAttribute("Equipped_" .. id, true) end
	player:SetAttribute("Hotbar", table.concat(data.Equipped, ","))
	saveHotbar(player, hotbarList(player))
	-- 🚲 free School Bike: everyone owns it; the first time it is also put on the hotbar
	if not player:GetAttribute("Owned_SchoolBike") then
		player:SetAttribute("Owned_SchoolBike", true)
		if #hotbarList(player) < 9 then hotbarAdd(player, "SchoolBike") end
	end
	local inv = getInventory(player)
	for id, count in pairs(data.Inventory) do
		local v = Instance.new("IntValue") v.Name = id v.Value = tonumber(count) or 0 v.Parent = inv
	end

	-- Live play-time counter
	task.spawn(function()
		while player.Parent do
			local t = math.floor(PlayerData.getTime(player))
			local h, m, s = math.floor(t / 3600), math.floor(t % 3600 / 60), t % 60
			timeValue.Value = (h > 0) and string.format("%dh %02dm", h, m) or string.format("%dm %02ds", m, s)
			player:SetAttribute("PlayTimeSeconds", t)
			player:SetAttribute("LevelTimeSeconds", math.floor(PlayerData.getLevelTime(player)))
			task.wait(1)
		end
	end)

	getInventory(player)

	-- Re-apply equipped gear on every respawn
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		refreshEquipment(player)
		task.wait(1)
		refreshEquipment(player)
	end)
	-- Cosmetics go on after the avatar's own clothes have loaded and the body
	-- has been resized by DefaultAvatarSize (so the pieces fit the final size)
	player.CharacterAppearanceLoaded:Connect(function(character)
		local started = os.clock()
		while character.Parent and not character:GetAttribute("AvatarSized") and os.clock() - started < 5 do
			task.wait(0.1)
		end
		refreshCosmetic(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

-- Buying
buyItemRemote.OnServerEvent:Connect(function(player, itemId)
	if typeof(itemId) ~= "string" then return end

	local item, category = findItem(itemId)
	if not item then return end

	-- locked "coming soon" items (the cosmetics for now) can't be bought yet
	if item.ComingSoon then
		feedback(player, "🔒 " .. item.Name .. " is coming soon!")
		return
	end

	local balance = getCurrency(player, item.Currency)
	if not balance then return end

	if item.RequiredLevel and (player:GetAttribute("LevelUnlocked") or 1) < item.RequiredLevel then
		local LevelConfig = require(ReplicatedStorage:WaitForChild("LevelConfig"))
		feedback(player, "🔒 Unlocks at " .. LevelConfig.name(item.RequiredLevel) .. " — level up in your Profile!")
		return
	end

	if EQUIPPABLE[category] and player:GetAttribute("Owned_" .. item.Id) then
		feedback(player, "You already own this!")
		return
	end

	if balance.Value < item.Price then
		feedback(player, "Not enough " .. item.Currency .. " tokens!")
		return
	end

	balance.Value -= item.Price

	if EQUIPPABLE[category] then
		player:SetAttribute("Owned_" .. item.Id, true)
		-- new things go straight onto the hotbar when there's room
		if hotbarAdd(player, item.Id) then
			if category == "Equipment" then refreshEquipment(player) elseif category == "Cosmetic" then refreshCosmetic(player) end
			feedback(player, "Purchased " .. item.Name .. "! It's on your hotbar — unequip it any time in your Bag [I]")
		else
			feedback(player, "Purchased " .. item.Name .. "! Your hotbar is full — equip it from your Bag [I]")
		end
	else
		addItem(player, item.Id, 1)
		if hotbarAdd(player, item.Id) then
			feedback(player, "Bought " .. item.Name .. "! It's on your hotbar")
		else
			feedback(player, "Bought " .. item.Name .. "! Hotbar full — equip it from your Bag [I]")
		end
	end
end)

-- Equip / unequip (one item per category at a time)
equipItemRemote.OnServerEvent:Connect(function(player, itemId)
	if typeof(itemId) ~= "string" then return end

	local item, category = findItem(itemId)
	if not item then return end
	if category == "Consumable" then
		if getItemCount(player, item.Id) <= 0 then return end
	elseif not EQUIPPABLE[category] or not player:GetAttribute("Owned_" .. item.Id) then
		return
	end

	local equipNow = not player:GetAttribute("Equipped_" .. item.Id)
	if equipNow and item.ComingSoon then
		feedback(player, "🔒 " .. item.Name .. " is coming soon!")
		return
	end

	-- every item is on / off by itself now (wear shoes AND hold the flashlight AND a cap...)
	if equipNow then
		if not hotbarAdd(player, item.Id) then
			feedback(player, "Your hotbar is full (9) — unequip something first")
			return
		end
	else
		hotbarRemove(player, item.Id)
	end

	if category == "Equipment" then
		refreshEquipment(player)
	elseif category == "Cosmetic" then
		refreshCosmetic(player)
	end

	feedback(player, (equipNow and "Equipped " or "Unequipped ") .. item.Name)
end)

-- Using consumables from the inventory
useItemRemote.OnServerEvent:Connect(function(player, itemId)
	if typeof(itemId) ~= "string" then return end

	local item, category = findItem(itemId)
	if not item or category ~= "Consumable" then return end
	if item.Id == "BodySwapPotion" then return end -- uses the BodySwap remote (pick a player first)
	if getItemCount(player, item.Id) <= 0 then return end

	applyConsumable(player, item)
	if removeItem(player, item.Id, 1) then
		if getItemCount(player, item.Id) <= 0 then
			hotbarRemove(player, item.Id)
		end
		feedback(player, "Used " .. item.Name .. "!")
	end
end)

-- ===== BODY SWAP POTION =====
-- Turns YOUR avatar into another player's avatar (their real Roblox look) for 3 minutes.
-- Only your character changes; the other player is not affected. Everyone sees you as them.
local bodySwapRemote = remotes:FindFirstChild("BodySwap") or Instance.new("RemoteEvent")
bodySwapRemote.Name = "BodySwap"
bodySwapRemote.Parent = remotes
local SWAP_SECONDS = 180
local SIZE = { HeightScale = 1, WidthScale = 1, DepthScale = 1, HeadScale = 1, BodyTypeScale = 0, ProportionScale = 0 } -- same as DefaultAvatarSize
local swaps = {} -- [player] = { original = HumanoidDescription, token = n, character = Model }
local function swapTag(character, text)
	local head = character and character:FindFirstChild("Head")
	if not head then return end
	local tag = head:FindFirstChild("SwapTag")
	if not text then if tag then tag:Destroy() end return end
	if not tag then
		tag = Instance.new("BillboardGui") tag.Name = "SwapTag" tag.Size = UDim2.fromOffset(220, 26) tag.StudsOffset = Vector3.new(0, 3.4, 0)
		tag.AlwaysOnTop = false tag.MaxDistance = 90 tag.Parent = head
		local l = Instance.new("TextLabel") l.Name = "Text" l.Size = UDim2.fromScale(1, 1) l.BackgroundColor3 = Color3.fromRGB(80, 30, 120) l.BackgroundTransparency = 0.2
		l.TextColor3 = Color3.new(1, 1, 1) l.Font = Enum.Font.GothamBold l.TextScaled = true l.Parent = tag
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 10) c.Parent = l
	end
	tag.Text.Text = text
end
local function puff(character)
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local a = Instance.new("Attachment") a.Parent = hrp
	local e = Instance.new("ParticleEmitter") e.Texture = "rbxasset://textures/particles/smoke_main.dds" e.Rate = 0
	e.Color = ColorSequence.new(Color3.fromRGB(190, 110, 255), Color3.fromRGB(110, 220, 255)) e.LightEmission = 0.6
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 4) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	e.Speed = NumberRange.new(4, 9) e.SpreadAngle = Vector2.new(180, 180) e.Lifetime = NumberRange.new(0.6, 1.1) e.Parent = a
	e:Emit(40)
	local s = Instance.new("Sound") s.SoundId = "rbxassetid://12222084" s.Volume = 0.6 s.PlaybackSpeed = 1.4 s.Parent = hrp s:Play()
	game:GetService("Debris"):AddItem(a, 2) game:GetService("Debris"):AddItem(s, 3)
end
local function applyLook(player, desc)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	for k, v in pairs(SIZE) do desc[k] = v end
	-- ApplyDescription rebuilds the hands, which breaks the grip of a held tool (the flashlight etc. would float).
	-- Put the held tool away first, then hand it back after the new look is on.
	local held = character:FindFirstChildOfClass("Tool")
	if held then humanoid:UnequipTools() end
	local ok, err = pcall(function() humanoid:ApplyDescription(desc) end)
	if held and held.Parent and humanoid.Parent and humanoid.Health > 0 then
		pcall(function() humanoid:EquipTool(held) end)
	end
	if not ok then warn("[BodySwap] " .. tostring(err)) return false end
	refreshCosmetic(player) -- shop cosmetics stay on top
	return true
end
local function endSwap(player, why)
	local s = swaps[player]
	if not s then return end
	swaps[player] = nil
	player:SetAttribute("BodySwappedWith", nil)
	if player.Character == s.character and s.original then
		puff(player.Character)
		applyLook(player, s.original)
		swapTag(player.Character, nil)
	end
	if why then feedback(player, why) end
end
bodySwapRemote.OnServerEvent:Connect(function(player, target)
	if getItemCount(player, "BodySwapPotion") <= 0 then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	-- pick the other player (random, or the one they chose)
	local others = {}
	for _, p in ipairs(Players:GetPlayers()) do if p ~= player then table.insert(others, p) end end
	if #others == 0 then feedback(player, "🧬 Nobody else is here to swap with — try again when another player joins!") return end
	local other
	if typeof(target) == "number" then
		other = Players:GetPlayerByUserId(target)
		if not other or other == player then feedback(player, "That player isn't here anymore") return end
	else
		other = others[math.random(1, #others)]
	end
	local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(other.UserId) end)
	if not ok or not desc then feedback(player, "🧬 The potion fizzled — couldn't load that avatar. You kept your potion.") return end
	local s = swaps[player]
	if not s or s.character ~= character then
		local okOrig, original = pcall(function() return humanoid:GetAppliedDescription() end)
		s = { original = okOrig and original or nil, character = character, token = 0 }
		swaps[player] = s
	end
	if not removeItem(player, "BodySwapPotion", 1) then return end
	if getItemCount(player, "BodySwapPotion") <= 0 then hotbarRemove(player, "BodySwapPotion") end
	puff(character)
	if not applyLook(player, desc) then feedback(player, "🧬 The potion fizzled.") return end
	s.token += 1
	local my = s.token
	player:SetAttribute("BodySwappedWith", other.DisplayName)
	feedback(player, "🧬 You swapped bodies with " .. other.DisplayName .. "! (3 minutes — only your look changed)")
	-- countdown tag + switch back
	task.spawn(function()
		local ends = os.clock() + SWAP_SECONDS
		while swaps[player] == s and s.token == my and player.Character == character do
			local left = math.max(0, math.ceil(ends - os.clock()))
			swapTag(character, ("🧬 %s as %s  %d:%02d"):format(player.DisplayName, other.DisplayName, left // 60, left % 60))
			if left <= 0 then endSwap(player, "🧬 The potion wore off — you're you again!") break end
			task.wait(1)
		end
		-- respawned: the new body is already your own look
		if swaps[player] == s and player.Character ~= character then
			swaps[player] = nil
			player:SetAttribute("BodySwappedWith", nil)
		end
	end)
end)
Players.PlayerRemoving:Connect(function(player) swaps[player] = nil boostToken[player] = nil end)

-- Admin panel hook: re-apply equipment/cosmetics after an admin changes a player's items
local ServerStorage = game:GetService("ServerStorage")
local signals = ServerStorage:FindFirstChild("AdminSignals") or Instance.new("Folder")
signals.Name = "AdminSignals" signals.Parent = ServerStorage
local refreshGear = signals:FindFirstChild("RefreshGear") or Instance.new("BindableEvent")
refreshGear.Name = "RefreshGear" refreshGear.Parent = signals
refreshGear.Event:Connect(function(player)
	if player and player.Parent then saveHotbar(player, hotbarList(player)) refreshEquipment(player) refreshCosmetic(player) end
end)
