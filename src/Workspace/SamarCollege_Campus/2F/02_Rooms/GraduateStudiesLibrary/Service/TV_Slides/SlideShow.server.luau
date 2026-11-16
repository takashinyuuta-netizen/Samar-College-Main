-- cycles the TV slides while it is on
local tv = script.Parent
local slide = tv:FindFirstChild("Screen"):FindFirstChild("SlideGui"):FindFirstChild("Slide")
local slides = {
	{"PICK YOURS", "New arrivals for graduate students", Color3.fromRGB(150,60,220), Color3.fromRGB(250,220,60)},
	{"THESIS WRITING", "Ask for the APA 7th edition guide at the counter", Color3.fromRGB(30,110,70), Color3.fromRGB(200,240,140)},
	{"E-JOURNALS", "Free access at the Internet Section", Color3.fromRGB(30,80,160), Color3.fromRGB(120,200,240)},
	{"SILENCE PLEASE", "Respect others who are studying", Color3.fromRGB(180,40,60), Color3.fromRGB(250,180,120)},
}
local i = 1
while true do
	task.wait(5)
	if tv:GetAttribute("On") then
		i = i % #slides + 1
		local s = slides[i]
		slide.Title.Text = s[1] slide.Sub.Text = s[2]
		slide.UIGradient.Color = ColorSequence.new(s[3], s[4])
	end
end
