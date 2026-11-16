--[[ DonateServer — Robux donations (Settings → 💖 Support the game)
  • Donate buttons = every Developer Product of this game whose name starts with "Donate"
    (create them in Creator Dashboard → Monetization → Developer Products, e.g. "Donate 10", "Donate 50").
    Extra product ids can also be listed in MANUAL below.
  • On purchase: "Donated" stat (saved), SC_LB_Donated_v1 leaderboard, thank-you shout to the server.
  • Each receipt is recorded once (SC_DonateReceipts_v1) so a purchase is never counted twice.
  NOTE: this is the game's only ProcessReceipt. If you add other products later, handle them here too. ]]
local Players = game:GetService("Players")
local MPS = game:GetService("MarketplaceService")
local DSS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local SSS = game:GetService("ServerScriptService")

-- productId = amount shown on the button (Creator Dashboard → Developer Products)
local MANUAL = {
	[3732310893] = 10,  -- Donate 10
	[3732311021] = 25,  -- Donate 25
	[3732311148] = 50,  -- Donate 50
	[3732311237] = 100, -- Donate 100
	[3732311586] = 250, -- Donate 250
	[3732311678] = 500, -- Donate 500
}

local folder = RS:FindFirstChild("Donate") or Instance.new("Folder")
folder.Name = "Donate" folder.Parent = RS
local list = folder:FindFirstChild("Products") or Instance.new("StringValue")
list.Name = "Products" list.Value = "[]" list.Parent = folder

local products = {} -- productId -> price
local function loadProducts()
	local found = {}
	for id, price in pairs(MANUAL) do found[id] = price end
	local ok, pages = pcall(function() return MPS:GetDeveloperProductsAsync() end)
	if ok and pages then
		while true do
			for _, p in ipairs(pages:GetCurrentPage()) do
				local id = p.ProductId or p.DeveloperProductId
				if id and type(p.Name) == "string" and p.Name:lower():find("^donat") then
					-- the number in the name is the button amount (PriceInRobux can be a regional price)
					found[id] = tonumber(p.Name:match("%d+")) or tonumber(p.PriceInRobux) or 0
				end
			end
			if pages.IsFinished then break end
			local okN = pcall(function() pages:AdvanceToNextPageAsync() end)
			if not okN then break end
		end
	end
	products = found
	local arr = {}
	for id, price in pairs(found) do table.insert(arr, { id = id, price = price }) end
	table.sort(arr, function(a, b) return a.price < b.price end)
	list.Value = Http:JSONEncode(arr)
end
task.spawn(function()
	while true do pcall(loadProducts) task.wait(600) end
end)

local okR, receipts = pcall(function() return DSS:GetDataStore("SC_DonateReceipts_v1") end)
local okL, board = pcall(function() return DSS:GetOrderedDataStore("SC_LB_Donated_v1") end)
local seen = {} -- this server (also covers Studio without DataStores)

local function toastAll(text)
	local r = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("EventRemotes")
	local t = r and r:FindFirstChild("EventToast")
	if t then t:FireAllClients(text) end
end

MPS.ProcessReceipt = function(info)
	local price = products[info.ProductId]
	if price == nil then
		pcall(loadProducts) -- maybe a product made after this server started
		price = products[info.ProductId]
	end
	if price == nil then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local amount = tonumber(info.CurrencySpent) or price
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
	if seen[info.PurchaseId] then return Enum.ProductPurchaseDecision.PurchaseGranted end

	-- record the receipt once
	if okR and receipts then
		local already = false
		local ok = pcall(function()
			receipts:UpdateAsync(info.PurchaseId, function(old)
				if old then already = true return nil end
				return { u = info.PlayerId, r = amount, t = os.time() }
			end)
		end)
		if ok and already then seen[info.PurchaseId] = true return Enum.ProductPurchaseDecision.PurchaseGranted end
		-- if DataStores are down we still grant (it is a donation, nothing to lose) and remember it here
	end
	seen[info.PurchaseId] = true

	player:SetAttribute("Donated", (tonumber(player:GetAttribute("Donated")) or 0) + amount)
	local okRw, Rewards = pcall(function() return require(SSS.Events.EventRewards) end)
	if okRw and Rewards and Rewards.saveSoon then Rewards.saveSoon(player) end
	if okL and board then
		task.spawn(function() pcall(function() board:IncrementAsync(tostring(info.PlayerId), amount) end) end)
	end
	local bump = SSS:FindFirstChild("LeaderboardBump")
	if bump then bump:Fire("Donated") end
	toastAll(("💖 %s donated R$ %d to Samar College! Thank you!"):format(player.DisplayName, amount))
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
