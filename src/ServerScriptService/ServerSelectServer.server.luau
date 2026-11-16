-- ServerSelectServer: decides if this is the Main or Kid server and handles the loading screen's choice.
local RS = game:GetService("ReplicatedStorage")
local Switch = require(script.Parent:WaitForChild("ServerSwitch"))
local choose = RS:WaitForChild("ServerSelect"):WaitForChild("ChooseServer")

task.spawn(Switch.detect)

choose.OnServerInvoke = function(player, target)
	if typeof(target) ~= "string" then return { ok = false } end
	return Switch.switch(player, target)
end
