--[[ _Meter: shared logic for timing-meter booths (Ring Toss, Target Throw).
  The marker moves 0 → 1 → 0 like a ping-pong. The SERVER works out where the marker
  is from its own clock when the "shoot" request arrives, so the client can't fake a hit. ]]
local Meter = {}
Meter.SPEED = 0.9 -- full sweeps per second

function Meter.position(startClock)
	local t = (os.clock() - startClock - 0.06) * Meter.SPEED -- 0.06 s ≈ network delay
	local p = t % 2
	return p < 1 and p or 2 - p
end

function Meter.newCenter() return 0.2 + math.random() * 0.6 end

return Meter
