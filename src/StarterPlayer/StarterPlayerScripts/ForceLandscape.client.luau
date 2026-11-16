-- Mobile: keep the game in landscape only (left or right, follows the phone's rotation; never portrait).
local Players = game:GetService("Players")
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
local function lock()
	if pg.ScreenOrientation ~= Enum.ScreenOrientation.LandscapeSensor then
		pg.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
	end
end
lock()
pg:GetPropertyChangedSignal("ScreenOrientation"):Connect(lock)
