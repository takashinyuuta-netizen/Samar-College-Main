-- DayNightCycle (synced with the school schedule – see ReplicatedStorage.CampusLife.CampusLifeConfig)
-- The sky clock IS the school clock: Lighting.ClockTime = the time NPC schedules use.
--  • School hours (6:00 AM – 6:00 PM) run slowly so classes last long enough:
--      1 school minute = DayMinuteSeconds real seconds (2 s → a 90-minute class ≈ 3 real minutes)
--  • The night (6:00 PM – 6:00 AM) passes quickly.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("CampusLife"):WaitForChild("CampusLifeConfig"))

local DAY_FROM, DAY_TO = 6, 18                        -- slow part of the day (hours)
local DAY_MINUTE_SECONDS = C.SecondsPerMinute or 2    -- real seconds per school minute in the day
local NIGHT_MINUTES = C.NightRealMinutes or 4         -- real minutes for the whole night
local nightHourSeconds = NIGHT_MINUTES * 60 / (24 - (DAY_TO - DAY_FROM))

Lighting.ClockTime = C.StartHour or 7.25 -- every server starts in the morning (7:15 AM)

-- the real school clock, also as an attribute: players who freeze / pick their own sky (Settings)
-- change Lighting.ClockTime only on their screen, and use this to fade back to live time.
-- PERFORMANCE: the clock is counted every frame, but Lighting.ClockTime is only WRITTEN a few times a second.
-- (Writing it every frame sent it to every player 60x a second, re-ran every ClockTime script
-- (night lights, nature) 60x a second and made every client redraw its sun shadows each frame.)
-- At this speed the sun moves less than half a degree per step, so it still looks smooth.
local WRITE_EVERY = 0.5
local ATTR_EVERY = 1
local t = Lighting.ClockTime
local sinceWrite, sinceAttr = 0, 0
Lighting:SetAttribute("SchoolClock", t)
RunService.Heartbeat:Connect(function(dt)
	local secondsPerHour = (t >= DAY_FROM and t < DAY_TO) and (DAY_MINUTE_SECONDS * 60) or nightHourSeconds
	t += dt / secondsPerHour
	if t >= 24 then t -= 24 end
	sinceWrite += dt
	sinceAttr += dt
	if sinceWrite >= WRITE_EVERY then
		sinceWrite = 0
		Lighting.ClockTime = t
	end
	if sinceAttr >= ATTR_EVERY then
		sinceAttr = 0
		Lighting:SetAttribute("SchoolClock", t)
	end
end)
-- admin tools / anything else that sets the time: follow it
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
	local c = Lighting.ClockTime
	if math.abs(c - t) > 0.05 and math.abs(c - t) < 23.9 then t = c Lighting:SetAttribute("SchoolClock", t) end
end)
