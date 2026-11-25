-- CameraNoUnderground: when you zoom out or swing the camera low, it never goes below the ground,
-- so players can't see under the floors / terrain. Only active while you're standing at ground level.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local MIN_Y = 1.2      -- lowest camera height (ground / floors are at about y 0 - 1.5)
local ACTIVE_BELOW = 40 -- only when the character is near ground level (not on upper floors / the sky island)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() camera = workspace.CurrentCamera end)

RunService:BindToRenderStep("CameraNoUnderground", Enum.RenderPriority.Camera.Value + 1, function()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not camera then return end
	local y = root.Position.Y
	if y < 0 or y > ACTIVE_BELOW then return end
	local cf = camera.CFrame
	if cf.Position.Y < MIN_Y then
		camera.CFrame = cf + Vector3.new(0, MIN_Y - cf.Position.Y, 0)
	end
end)
