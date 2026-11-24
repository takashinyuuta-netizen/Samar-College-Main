-- AdminAnnounceClient: shows an admin's 📢 announcement as big text in the middle of the screen
-- (text only, no background), like the "admin abuse" messages in other games.
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local gui = script.Parent
local ev = RS:WaitForChild("AdminRemotes", 60) and RS.AdminRemotes:WaitForChild("AdminAnnounce", 60)
if not ev then return end

local holder = Instance.new("Frame")
holder.Name = "Announcement" holder.BackgroundTransparency = 1
holder.AnchorPoint = Vector2.new(0.5, 0.5) holder.Position = UDim2.fromScale(0.5, 0.38)
holder.Size = UDim2.new(0.86, 0, 0, 0) holder.AutomaticSize = Enum.AutomaticSize.Y
holder.Visible = false holder.Parent = gui
local layout = Instance.new("UIListLayout") layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder layout.Padding = UDim.new(0, 4) layout.Parent = holder
local pop = Instance.new("UIScale") pop.Parent = holder

local function textLabel(order, font, color, strokeT)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1 l.LayoutOrder = order l.Font = font l.TextColor3 = color
	l.Size = UDim2.new(1, 0, 0, 0) l.AutomaticSize = Enum.AutomaticSize.Y l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Center l.Text = "" l.RichText = false
	l.TextStrokeTransparency = 1
	local st = Instance.new("UIStroke") st.Color = Color3.new(0, 0, 0) st.Thickness = strokeT st.Transparency = 0.1
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual st.Parent = l
	l.Parent = holder
	return l, st
end
local fromL, fromS = textLabel(1, Enum.Font.GothamBlack, Color3.fromRGB(255, 205, 70), 2)
local msgL, msgS = textLabel(2, Enum.Font.GothamBlack, Color3.fromRGB(255, 255, 255), 3)

local function sizes()
	local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local base = math.min(v.X, v.Y * 1.6)
	msgL.TextSize = math.clamp(math.floor(base / 26), 22, 46)
	fromL.TextSize = math.clamp(math.floor(base / 52), 14, 24)
end

local function setAlpha(a) -- 0 = visible, 1 = hidden
	fromL.TextTransparency = a msgL.TextTransparency = a
	fromS.Transparency = 0.1 + a * 0.9 msgS.Transparency = 0.1 + a * 0.9
end

local queue, showing = {}, false
local function showNext()
	if showing then return end
	local m = table.remove(queue, 1)
	if not m then return end
	showing = true
	sizes()
	fromL.Text = (m.global and "🌍 " or "📢 ") .. "ADMIN • " .. tostring(m.from or "Admin")
	msgL.Text = tostring(m.text or "")
	holder.Visible = true
	setAlpha(1) pop.Scale = 0.85
	local v = Instance.new("NumberValue") v.Value = 1
	v.Changed:Connect(setAlpha)
	TweenService:Create(v, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Value = 0 }):Play()
	TweenService:Create(pop, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local hold = math.clamp(4 + #msgL.Text / 18, 4, 10)
	task.wait(0.35 + hold)
	local out = TweenService:Create(v, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { Value = 1 })
	out:Play() out.Completed:Wait()
	v:Destroy()
	holder.Visible = false
	showing = false
	showNext()
end

ev.OnClientEvent:Connect(function(m)
	if type(m) ~= "table" or type(m.text) ~= "string" then return end
	table.insert(queue, m)
	task.spawn(showNext)
end)
