local lightPart = script.Parent
local lightSource = lightPart:FindFirstChildWhichIsA("Light")

-- Find the switch's Value inside the Light & Switch model
local lightSwitchModel = workspace:FindFirstChild("Light & Switch")
local switchValue = nil
if lightSwitchModel then
	local modelFolder = lightSwitchModel:FindFirstChild("Model")
	if modelFolder then
		local switch = modelFolder:FindFirstChild("Switch")
		if switch then
			switchValue = switch:FindFirstChild("Value")
		end
	end
end

local function updateLight()
	if not switchValue then return end
	-- Value = 0 means ON, Value = 1 means OFF
	if switchValue.Value == 0 then
		if lightSource then lightSource.Enabled = true end
		lightPart.Material = Enum.Material.Neon
	else
		if lightSource then lightSource.Enabled = false end
		lightPart.Material = Enum.Material.Glass
	end
end

-- Initial update
updateLight()

-- Listen for changes from the switch
if switchValue then
	switchValue.Changed:Connect(updateLight)
end
