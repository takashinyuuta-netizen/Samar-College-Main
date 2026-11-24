--[[ WallFanSync — the 16 "Thermoloth" wall fans used to spin with REAL physics on the server (a hinge motor at
  120 rad/s on 43 loose parts each). That kept 16 physics assemblies awake every frame and streamed their motion
  to every player = server + network lag. Now every fan part is anchored and the blades are spun on each
  player's own device by CeilingFanSpin (model attributes Spin / SpinPart / On).
  This script only mirrors the fan's existing switches: the old click scripts still set Fanmotor.AngularVelocity,
  and that becomes the model's On attribute (0 = off). ]]
local function hook(t)
	local reg = t:FindFirstChild("Regulator")
	local shaft = reg and reg:FindFirstChild("Shaft")
	local fm = shaft and shaft:FindFirstChild("Fanmotor")
	if not fm then return end
	local function sync() t:SetAttribute("On", fm.AngularVelocity ~= 0) end
	fm:GetPropertyChangedSignal("AngularVelocity"):Connect(sync)
	task.delay(2, sync) -- after the fan's own script set its starting speed
end
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("Model") and d.Name == "Thermoloth" and d:GetAttribute("SpinPart") then hook(d) end
end
