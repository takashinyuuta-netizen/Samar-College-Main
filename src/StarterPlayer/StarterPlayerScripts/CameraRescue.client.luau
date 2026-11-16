-- CameraRescue: if the camera or mouse ever gets stuck (a watch/booth camera that didn't let go,
-- a hidden text box still holding the keyboard, a locked mouse), respawning fixes it:
-- Esc → Reset Character always gives back the normal camera, mouse and keyboard.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

local function rescue(char)
	local hum = char:WaitForChild("Humanoid", 10)
	task.wait(0.2)
	local cam = workspace.CurrentCamera
	if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
	if hum then cam.CameraSubject = hum end
	if UIS.MouseBehavior ~= Enum.MouseBehavior.Default and player.CameraMode ~= Enum.CameraMode.LockFirstPerson then UIS.MouseBehavior = Enum.MouseBehavior.Default end
	UIS.MouseIconEnabled = true
	local box = UIS:GetFocusedTextBox()
	if box then box:ReleaseFocus() end
end
player.CharacterAdded:Connect(rescue)
