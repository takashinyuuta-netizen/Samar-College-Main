-- FPSDisplay: a small FPS counter at the top-middle of the screen.
-- Shown when Settings > "📊 Show FPS" is on (player attribute Setting_ShowFPS, saved between visits).
-- Green = smooth (50+), yellow = OK (30-49), red = slow (under 30). Updates twice a second (very cheap).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "FPSDisplay"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.Enabled = false

local label = Instance.new("TextLabel")
label.Name = "FPS"
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 6)
label.Size = UDim2.fromOffset(52, 16)
label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
label.BackgroundTransparency = 0.55
label.Font = Enum.Font.GothamMedium
label.TextSize = 11
label.TextColor3 = Color3.fromRGB(120, 230, 140)
label.Text = "-- FPS"
label.Active = false
label.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 5)
corner.Parent = label
gui.Parent = player:WaitForChild("PlayerGui")

local GREEN, YELLOW, RED = Color3.fromRGB(120, 230, 140), Color3.fromRGB(245, 210, 90), Color3.fromRGB(240, 110, 100)
local frames, t0 = 0, os.clock()
local conn
local function setShown(on)
	gui.Enabled = on
	if on and not conn then
		frames, t0 = 0, os.clock()
		conn = RunService.RenderStepped:Connect(function()
			frames += 1
			local now = os.clock()
			if now - t0 >= 0.5 then
				local fps = math.floor(frames / (now - t0) + 0.5)
				frames, t0 = 0, now
				label.Text = fps .. " FPS"
				label.TextColor3 = fps >= 50 and GREEN or (fps >= 30 and YELLOW or RED)
			end
		end)
	elseif not on and conn then
		conn:Disconnect()
		conn = nil
	end
end

local function sync() setShown(player:GetAttribute("Setting_ShowFPS") ~= false) end
player:GetAttributeChangedSignal("Setting_ShowFPS"):Connect(sync)
sync()
