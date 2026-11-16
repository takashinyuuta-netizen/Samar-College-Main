-- Wall fan motor. Uses the fan's Button (Speed) and Timer (Fanison) if the model has them;
-- if those parts are missing, the fan simply runs at speed 1.
local shaft = script.Parent
local fanModel = shaft.Parent.Parent
local motor = shaft:WaitForChild("Fanmotor")
local hum = shaft:FindFirstChild("FanHummingSFX")

local SPEEDS = {
	[1] = {-120, 25},
	[2] = {-100, 20},
	[3] = {-80, 15},
}

local function apply(speed, on)
	local setting = on and SPEEDS[speed]
	if setting then
		motor.AngularVelocity = setting[1]
		motor.MotorMaxAcceleration = setting[2]
		if hum then hum.Playing = true end
	else
		motor.AngularVelocity = 0
		motor.MotorMaxAcceleration = 10
		if hum then hum.Playing = false end
	end
end

local button = fanModel:FindFirstChild("Button")
local timer = fanModel:FindFirstChild("Timer")
local speedValue = button and button:FindFirstChild("Speed")
local onValue = timer and timer:FindFirstChild("Fanison")

if speedValue and onValue then
	local function update() apply(speedValue.Value, onValue.Value) end
	speedValue.Changed:Connect(update)
	onValue.Changed:Connect(update)
	update()
else
	apply(1, true)
end
