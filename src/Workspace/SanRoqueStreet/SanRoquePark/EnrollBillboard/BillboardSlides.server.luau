-- Enroll billboard: cycles slides every 6 seconds; tap / click the screen to skip to the next one.
local TweenService = game:GetService("TweenService")
local screen = script.Parent:WaitForChild("Screen")
local gui = screen:WaitForChild("Display")
local slides = {}
for i = 1, 4 do slides[i] = gui:WaitForChild("Slide" .. i) end
local dots = gui:WaitForChild("Dots")
local index = 1
local function show(i)
	for k, s in ipairs(slides) do s.Visible = (k == i) end
	for k = 1, #slides do
		local d = dots:FindFirstChild("Dot" .. k)
		if d then d.BackgroundTransparency = (k == i) and 0 or 0.6 end
	end
	-- quick flash so the change feels like a digital screen
	local cover = Instance.new("Frame")
	cover.Size = UDim2.fromScale(1, 1) cover.BackgroundColor3 = Color3.new(1, 1, 1) cover.BackgroundTransparency = 0.3 cover.BorderSizePixel = 0 cover.ZIndex = 10
	cover.Parent = gui
	TweenService:Create(cover, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
	task.delay(0.4, function() cover:Destroy() end)
end
local token = 0
local function nextSlide()
	index = index % #slides + 1
	show(index)
	token += 1
end
screen:WaitForChild("ClickDetector").MouseClick:Connect(nextSlide)
show(1)
while true do
	local my = token
	task.wait(6)
	if my == token then nextSlide() end
end
