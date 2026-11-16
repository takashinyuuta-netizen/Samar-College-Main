-- DonateClient: 💖 "Support the game" section at the bottom of the Settings page (Robux donations only).
-- Buttons come from ReplicatedStorage.Donate.Products (DonateServer finds the "Donate ..." developer products).
local Players = game:GetService("Players")
local MPS = game:GetService("MarketplaceService")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")

local player = Players.LocalPlayer
local gui = script.Parent
local page = gui:WaitForChild("Panel"):WaitForChild("Pages"):WaitForChild("SettingsPage")
local donate = RS:WaitForChild("Donate")
local productsValue = donate:WaitForChild("Products")

local ACCENT = Color3.fromRGB(235, 90, 150)
local MUTED = Color3.fromRGB(165, 165, 180)

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

new("TextLabel", { Name = "DonateHeader", LayoutOrder = 40, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
	TextSize = 13, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left, Text = "💖 Support the game" }, page)
local note = new("TextLabel", { Name = "DonateNote", LayoutOrder = 41, Size = UDim2.new(1, -8, 0, 32), BackgroundTransparency = 1, Font = Enum.Font.Gotham,
	TextSize = 12, TextWrapped = true, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Donations are Robux only and give no in-game items. Thank you for helping Samar College grow!" }, page)
local grid = new("Frame", { Name = "DonateButtons", LayoutOrder = 42, Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, page)
new("UIGridLayout", { CellSize = UDim2.new(0.33, -6, 0, 40), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
local total = new("TextLabel", { Name = "DonateTotal", LayoutOrder = 43, Size = UDim2.new(1, -8, 0, 22), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
	TextSize = 13, TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, page)

local function refreshTotal()
	local d = tonumber(player:GetAttribute("Donated")) or 0
	total.Text = d > 0 and ("You have donated R$ %d — you're on the 💖 Top Donors board!"):format(d) or ""
	total.Visible = d > 0
end
player:GetAttributeChangedSignal("Donated"):Connect(refreshTotal)
refreshTotal()

local function render()
	for _, c in ipairs(grid:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local ok, arr = pcall(function() return Http:JSONDecode(productsValue.Value) end)
	arr = ok and type(arr) == "table" and arr or {}
	if #arr == 0 then
		note.Text = "Donations are coming soon. Thank you for playing Samar College!"
		return
	end
	note.Text = "Donations are Robux only and give no in-game items. Thank you for helping Samar College grow!"
	for i, p in ipairs(arr) do
		local b = new("TextButton", { Name = "Donate_" .. p.price, LayoutOrder = i, BackgroundColor3 = ACCENT, AutoButtonColor = true,
			Font = Enum.Font.GothamBlack, TextSize = 15, TextColor3 = Color3.new(1, 1, 1), Text = "💖 R$ " .. tostring(p.price) }, grid)
		new("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
		b.Activated:Connect(function()
			pcall(function() MPS:PromptProductPurchase(player, p.id) end)
		end)
	end
end
productsValue.Changed:Connect(render)
render()
