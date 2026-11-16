-- SleepPoseClient: while you lie in a sleeping bag (Seat with attribute SleepSeat), the sitting animation is
-- stopped so you lie flat with straight legs. Other players see it too (your animations replicate).
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function isSitTrack(track)
	local a = track.Animation
	local n = (track.Name .. " " .. (a and a.Name or "") .. " " .. (a and a.AnimationId or "")):lower()
	-- default R15 / R6 sit animations
	return n:find("sit") ~= nil or n:find("2506281703") ~= nil or n:find("178130996") ~= nil
end

local function hook(char)
	local hum = char:WaitForChild("Humanoid")
	local animator = hum:WaitForChild("Animator", 10)
	local sleeping = false
	local conn
	hum.Seated:Connect(function(active, seat)
		sleeping = active and seat ~= nil and seat:GetAttribute("SleepSeat") == true
		if conn then conn:Disconnect() conn = nil end
		if sleeping and animator then
			local function stopSits()
				for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
					if isSitTrack(t) then t:Stop(0.15) end
				end
			end
			task.defer(stopSits)
			task.delay(0.2, stopSits)
			-- the default Animate script may start it again: keep it off while asleep
			conn = animator.AnimationPlayed:Connect(function(t)
				if sleeping and isSitTrack(t) then task.defer(function() t:Stop(0) end) end
			end)
		end
	end)
end
if player.Character then task.spawn(hook, player.Character) end
player.CharacterAdded:Connect(hook)
