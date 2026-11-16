local Lighting = game:GetService("Lighting")
local lightPart = script.Parent
local lightSource = lightPart:FindFirstChildWhichIsA("Light") -- Finds your PointLight/SpotLight

local function updateLight()
	local currentTime = Lighting.ClockTime

	-- Turn ON lights between 6 PM (18) and 6 AM (6)
	if currentTime >= 18 or currentTime <= 6 then
		if lightSource then lightSource.Enabled = true end
		lightPart.Material = Enum.Material.Neon -- Makes the physical part glow
	else
		-- Turn OFF lights during daytime
		if lightSource then lightSource.Enabled = false end
		lightPart.Material = Enum.Material.Glass -- Normal unlit material
	end
end

-- Check the time immediately when the game starts
updateLight()

-- Check every time the clock time shifts
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(updateLight)
