-- PowerAndLED
-- 1) LED borders: Model tagged "LEDBorder" holding parts named "LEDStrip" (attribute Index = order for chase)
--    and Light objects. Attributes: On (bool), Mode ("Steady" | "Breathing" | "Chase").
--    A switch is a Model tagged "LEDSwitch" (+ TapToUse) with ObjectValue "Target" -> the LED model.
--    Tapping the switch toggles On; a part named "ModeButton" inside the switch cycles the Mode.
-- 2) Main power: Model tagged "MainPower" (+ TapToUse). Its On attribute (default true) is the building's
--    main breaker. When it goes off, every light, glowing bulb, device (PowerToggle), fan and LED border on
--    every floor is switched off and held off; emergency lights (anything named "Emergency...") come on.
--    When it comes back, everything returns to how it was.
local CS = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local campus = workspace:WaitForChild("SamarCollege_Campus")

local MODES = { "Steady", "Breathing", "Chase" }

----------------------------------------------------------------- LED borders
local borders = {}
local function setupBorder(m)
	if not m:IsA("Model") or borders[m] then return end
	local strips, lights = {}, {}
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "LEDStrip" then
			if d:GetAttribute("OnColor") == nil then d:SetAttribute("OnColor", d.Color) end
			table.insert(strips, d)
		elseif d:IsA("Light") then
			if d:GetAttribute("BaseBrightness") == nil then d:SetAttribute("BaseBrightness", d.Brightness) end
			table.insert(lights, d)
		end
	end
	local maxIndex = 1
	for _, p in ipairs(strips) do maxIndex = math.max(maxIndex, p:GetAttribute("Index") or 1) end
	borders[m] = { strips = strips, lights = lights, maxIndex = maxIndex }
	if m:GetAttribute("Mode") == nil then m:SetAttribute("Mode", "Steady") end
end
for _, m in ipairs(CS:GetTagged("LEDBorder")) do setupBorder(m) end
CS:GetInstanceAddedSignal("LEDBorder"):Connect(setupBorder)

local function renderBorder(m, info, t)
	local on = m:GetAttribute("On") == true
	local mode = m:GetAttribute("Mode") or "Steady"
	for _, p in ipairs(info.strips) do
		if not on then
			p.Material = Enum.Material.SmoothPlastic
			p.Color = Color3.fromRGB(150, 140, 110)
			p.Transparency = 0
		else
			p.Material = Enum.Material.Neon
			p.Color = p:GetAttribute("OnColor")
			local a = 1
			if mode == "Breathing" then
				a = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 2.2))
			elseif mode == "Chase" then
				local idx = p:GetAttribute("Index") or 1
				local phase = (idx - t * 14) % 12
				a = (phase < 5) and 1 or 0.15
			end
			p.Transparency = (1 - a) * 0.75
		end
	end
	for _, l in ipairs(info.lights) do
		l.Enabled = on
		local base = l:GetAttribute("BaseBrightness") or 1
		if mode == "Breathing" then
			l.Brightness = base * (0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 2.2)))
		else
			l.Brightness = base
		end
	end
end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.08 then return end
	acc = 0
	local t = os.clock()
	for m, info in pairs(borders) do
		if m.Parent then
			local on = m:GetAttribute("On") == true
			local mode = m:GetAttribute("Mode") or "Steady"
			local key = tostring(on) .. mode
			if on and mode ~= "Steady" then
				renderBorder(m, info, t)
			elseif info.last ~= key then
				renderBorder(m, info, t)
			end
			info.last = key
		end
	end
end)

local function setupLEDSwitch(sw)
	if not sw:IsA("Model") or sw:GetAttribute("_ledReady") then return end
	local link = sw:FindFirstChild("Target")
	if not link or not link.Value then return end
	sw:SetAttribute("_ledReady", true)
	local target = link.Value
	local indicator = sw:FindFirstChild("Indicator", true)
	local modeLabel = sw:FindFirstChild("ModeLabel", true)
	local function sync()
		local on = sw:GetAttribute("On") == true
		target:SetAttribute("On", on)
		if indicator then
			indicator.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
			indicator.Color = on and Color3.fromRGB(255, 200, 80) or Color3.fromRGB(90, 70, 40)
		end
	end
	local function showMode()
		if modeLabel then modeLabel.Text = "MODE: " .. string.upper(target:GetAttribute("Mode") or "Steady") end
	end
	sw:GetAttributeChangedSignal("On"):Connect(sync)
	target:GetAttributeChangedSignal("Mode"):Connect(showMode)
	-- keep the switch in step if the LED is changed elsewhere (e.g. main power)
	target:GetAttributeChangedSignal("On"):Connect(function()
		local v = target:GetAttribute("On") == true
		if (sw:GetAttribute("On") == true) ~= v then sw:SetAttribute("On", v) end
	end)
	if sw:GetAttribute("On") == nil then sw:SetAttribute("On", target:GetAttribute("On") == true) end
	sync() showMode()
	local mb = sw:FindFirstChild("ModeButton", true)
	if mb then
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 14
		cd.Parent = mb
		cd.MouseClick:Connect(function()
			local cur = target:GetAttribute("Mode") or "Steady"
			local i = table.find(MODES, cur) or 1
			target:SetAttribute("Mode", MODES[i % #MODES + 1])
		end)
	end
end
for _, sw in ipairs(CS:GetTagged("LEDSwitch")) do task.spawn(setupLEDSwitch, sw) end
CS:GetInstanceAddedSignal("LEDSwitch"):Connect(setupLEDSwitch)

----------------------------------------------------------------- Main power
local guards = {}
local saved = {}
local function isEmergency(inst)
	return inst:GetFullName():find("Emergency") ~= nil
end
local function inPanel(inst, panel)
	return inst == panel or inst:IsDescendantOf(panel)
end
local function guardAttr(inst, attr, value)
	table.insert(guards, inst:GetAttributeChangedSignal(attr):Connect(function()
		if inst:GetAttribute(attr) ~= value then inst:SetAttribute(attr, value) end
	end))
end
local function guardProp(inst, prop, value)
	table.insert(guards, inst:GetPropertyChangedSignal(prop):Connect(function()
		if inst[prop] ~= value then inst[prop] = value end
	end))
end

local function powerOff(panel)
	saved = { lights = {}, neon = {}, attrs = {}, emergency = {} }
	-- devices first, so their own scripts do their "off" work
	for _, tag in ipairs({ "PowerToggle", "FanSwitch", "LEDSwitch", "LEDBorder" }) do
		for _, m in ipairs(CS:GetTagged(tag)) do
			if m:IsDescendantOf(campus) and not inPanel(m, panel) and not isEmergency(m) then
				table.insert(saved.attrs, { m, m:GetAttribute("On") })
				m:SetAttribute("On", false)
				guardAttr(m, "On", false)
			end
		end
	end
	task.wait()
	for _, d in ipairs(campus:GetDescendants()) do
		if not inPanel(d, panel) then
			if d:IsA("Light") then
				if isEmergency(d) then
					table.insert(saved.emergency, { d, d.Enabled })
					d.Enabled = true
				else
					table.insert(saved.lights, { d, d.Enabled })
					d.Enabled = false
					guardProp(d, "Enabled", false)
				end
			elseif d:IsA("BasePart") and d.Material == Enum.Material.Neon and not isEmergency(d) then
				table.insert(saved.neon, { d, d.Material })
				d.Material = Enum.Material.SmoothPlastic
				guardProp(d, "Material", Enum.Material.SmoothPlastic)
			end
		end
	end
	for _, d in ipairs(campus:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Bulb" and isEmergency(d) then d.Material = Enum.Material.Neon end
	end
end

local function powerOn()
	for _, c in ipairs(guards) do c:Disconnect() end
	guards = {}
	if not saved.lights then return end
	for _, e in ipairs(saved.neon) do if e[1].Parent then e[1].Material = e[2] end end
	for _, e in ipairs(saved.lights) do if e[1].Parent then e[1].Enabled = e[2] end end
	for _, e in ipairs(saved.emergency) do if e[1].Parent then e[1].Enabled = e[2] end end
	for _, d in ipairs(campus:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Bulb" and isEmergency(d) then d.Material = Enum.Material.SmoothPlastic end
	end
	for _, e in ipairs(saved.attrs) do if e[1].Parent then e[1]:SetAttribute("On", e[2]) end end
	saved = {}
end

local function setupMain(panel)
	if not panel:IsA("Model") or panel:GetAttribute("_mainReady") then return end
	panel:SetAttribute("_mainReady", true)
	if panel:GetAttribute("On") == nil then panel:SetAttribute("On", true) end
	local lever = panel:FindFirstChild("Lever", true)
	local leverCF = lever and lever.CFrame
	local function lamps(on)
		for _, d in ipairs(panel:GetDescendants()) do
			if d:IsA("BasePart") then
				if d.Name == "LampOn" then
					d.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
					d.Color = on and Color3.fromRGB(70, 230, 100) or Color3.fromRGB(30, 70, 40)
				elseif d.Name == "LampOff" then
					d.Material = on and Enum.Material.SmoothPlastic or Enum.Material.Neon
					d.Color = on and Color3.fromRGB(90, 30, 30) or Color3.fromRGB(255, 50, 50)
				end
			elseif d:IsA("TextLabel") and d.Name == "StatusText" then
				d.Text = on and "MAIN POWER: ON" or "MAIN POWER: OFF"
				d.TextColor3 = on and Color3.fromRGB(90, 240, 120) or Color3.fromRGB(255, 80, 80)
			end
		end
		if lever and leverCF then
			lever.CFrame = on and leverCF or (leverCF * CFrame.new(0, -0.9, 0))
		end
	end
	local busy = false
	panel:GetAttributeChangedSignal("On"):Connect(function()
		local on = panel:GetAttribute("On") ~= false
		workspace:SetAttribute("MainPowerOn", on)
		lamps(on)
		if busy then return end
		busy = true
		if on then powerOn() else powerOff(panel) end
		busy = false
	end)
	workspace:SetAttribute("MainPowerOn", panel:GetAttribute("On") ~= false)
	lamps(panel:GetAttribute("On") ~= false)
end
for _, p in ipairs(CS:GetTagged("MainPower")) do task.spawn(setupMain, p) end
CS:GetInstanceAddedSignal("MainPower"):Connect(setupMain)
