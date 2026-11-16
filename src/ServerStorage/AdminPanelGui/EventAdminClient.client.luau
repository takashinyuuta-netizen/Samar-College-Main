--[[ EventAdminClient — the 🎪 Events section of the admin panel.
  A small button (bottom-left) opens a list of every event with Start buttons,
  plus Stop and "Next now". Requests go through AdminRemotes.AdminRequest
  (AdminServer checks admin rights) → the event system's EventControl. ]]
local RS = game:GetService("ReplicatedStorage")
local gui = script.Parent
local req = RS:WaitForChild("AdminRemotes"):WaitForChild("AdminRequest")

local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 8) c.Parent = p end
local function btn(parent, text, size, pos, col)
	local b = Instance.new("TextButton") b.Text = text b.Size = size b.Position = pos b.BackgroundColor3 = col or Color3.fromRGB(60, 140, 90)
	b.TextColor3 = Color3.new(1,1,1) b.Font = Enum.Font.GothamBold b.TextScaled = true b.BorderSizePixel = 0 b.Parent = parent corner(b)
	local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = 15 c.Parent = b
	return b
end

-- top-left, to the right of the Profile/Bag/Map column (never covers the Report / Admin buttons)
local open = btn(gui, "🎪 Events", UDim2.fromOffset(110, 34), UDim2.new(0, 100, 0, 8), Color3.fromRGB(150, 90, 200))
open.Name = "EventsButton"
local win = Instance.new("Frame") win.Name = "EventsWindow" win.Size = UDim2.fromOffset(330, 380) win.Position = UDim2.new(0, 100, 0, 48)
win.BackgroundColor3 = Color3.fromRGB(25, 30, 38) win.BorderSizePixel = 0 win.Visible = false win.Parent = gui corner(win, 12)
do -- fit on phones
	local sc = Instance.new("UIScale") sc.Parent = win
	local function fit()
		local vs = workspace.CurrentCamera.ViewportSize
		local h = vs.Y - game:GetService("GuiService"):GetGuiInset().Y - 60
		sc.Scale = math.clamp(h / 380, 0.55, 1)
	end
	fit() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
end
local head = Instance.new("TextLabel") head.Size = UDim2.new(1, -20, 0, 28) head.Position = UDim2.fromOffset(10, 6) head.BackgroundTransparency = 1
head.Font = Enum.Font.GothamBold head.TextColor3 = Color3.new(1,1,1) head.TextScaled = true head.TextXAlignment = Enum.TextXAlignment.Left head.Text = "🎪 Events" head.Parent = win
local status = Instance.new("TextLabel") status.Size = UDim2.new(1, -20, 0, 20) status.Position = UDim2.fromOffset(10, 34) status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham status.TextColor3 = Color3.fromRGB(255, 220, 120) status.TextScaled = true status.TextXAlignment = Enum.TextXAlignment.Left status.Parent = win
local listF = Instance.new("ScrollingFrame") listF.Size = UDim2.new(1, -20, 1, -110) listF.Position = UDim2.fromOffset(10, 60) listF.BackgroundTransparency = 1
listF.CanvasSize = UDim2.new() listF.AutomaticCanvasSize = Enum.AutomaticSize.Y listF.ScrollBarThickness = 4 listF.BorderSizePixel = 0 listF.Parent = win
local lay = Instance.new("UIListLayout") lay.Padding = UDim.new(0, 4) lay.Parent = listF
local stop = btn(win, "⏹ Stop", UDim2.new(0.33, -12, 0, 32), UDim2.new(0, 10, 1, -42), Color3.fromRGB(190, 70, 70))
local phase = btn(win, "⏩ Skip phase", UDim2.new(0.33, -12, 0, 32), UDim2.new(0.33, 4, 1, -42), Color3.fromRGB(200, 140, 40))
local skip = btn(win, "⏭ Next now", UDim2.new(0.33, -12, 0, 32), UDim2.new(0.66, -2, 1, -42), Color3.fromRGB(60, 110, 190))

local function call(action, args)
	local ok, res = pcall(function() return req:InvokeServer(action, args or {}) end)
	return ok and res or { ok = false, msg = "Request failed" }
end
local function refresh()
	for _, c in ipairs(listF:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local res = call("event_list")
	if not res.ok then status.Text = tostring(res.msg) return end
	status.Text = res.running and ("Running: " .. res.running .. " (" .. tostring(res.phase) .. ")") or ("Next rotation in " .. res.nextIn .. "s • " .. res.serverType)
	for _, e in ipairs(res.events) do
		local row = Instance.new("Frame") row.Size = UDim2.new(1, -6, 0, 32) row.BackgroundColor3 = Color3.fromRGB(38, 44, 54) row.BorderSizePixel = 0 row.Parent = listF corner(row, 6)
		local t = Instance.new("TextLabel") t.Size = UDim2.new(1, -90, 1, 0) t.Position = UDim2.fromOffset(8, 0) t.BackgroundTransparency = 1 t.Font = Enum.Font.Gotham
		t.TextColor3 = e.built and Color3.new(1,1,1) or Color3.fromRGB(140, 140, 150) t.TextScaled = true t.TextXAlignment = Enum.TextXAlignment.Left
		t.Text = (e.icon or "") .. " " .. e.name .. (e.rarity == "Rare" and "  ★" or "") .. (e.built and "" or "  (soon)") t.Parent = row
		local c = Instance.new("UITextSizeConstraint") c.MaxTextSize = 15 c.Parent = t
		local b = btn(row, "▶ Start", UDim2.fromOffset(72, 24), UDim2.new(1, -78, 0, 4))
		b.AutoButtonColor = e.built
		b.MouseButton1Click:Connect(function() local r = call("event_start", { id = e.id }) status.Text = tostring(r.msg) task.wait(0.5) refresh() end)
	end
end
open.MouseButton1Click:Connect(function() win.Visible = not win.Visible if win.Visible then refresh() end end)
stop.MouseButton1Click:Connect(function() local r = call("event_stop") status.Text = tostring(r.msg) end)
skip.MouseButton1Click:Connect(function() local r = call("event_skip") status.Text = tostring(r.msg) end)

phase.MouseButton1Click:Connect(function() local r = call("event_skipphase") status.Text = tostring(r.msg) end)
