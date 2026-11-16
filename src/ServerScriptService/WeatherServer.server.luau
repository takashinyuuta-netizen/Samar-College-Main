--[[ WeatherServer — rolls the LIVE campus weather (everyone in "Auto" sees it).
  ReplicatedStorage.Weather attributes:  Current (id), Since, Ends (os.time)
  Each weather lasts WeatherConfig.Duration seconds; after rain / a storm a rainbow may follow.
  Admins / scripts can force one:  ServerStorage.WeatherSet:Fire("Thunderstorm", seconds) ]]
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local folder = RS:WaitForChild("Weather")
local C = require(folder:WaitForChild("WeatherConfig"))
local rand = Random.new()

local setter = SS:FindFirstChild("WeatherSet") or Instance.new("BindableEvent")
setter.Name = "WeatherSet" setter.Parent = SS

local token = 0
local function pick(exclude)
	local total = 0
	for _, e in ipairs(C.Rotation) do if e[1] ~= exclude then total += e[2] end end
	local r = rand:NextNumber(0, total)
	for _, e in ipairs(C.Rotation) do
		if e[1] ~= exclude then r -= e[2] if r <= 0 then return e[1] end end
	end
	return "Sunny"
end

local function set(id, seconds)
	if not C.ById[id] then return end
	token += 1
	local now = os.time()
	folder:SetAttribute("Current", id)
	folder:SetAttribute("Since", now)
	folder:SetAttribute("Ends", now + seconds)
	print(("[Weather] %s %s for %d min"):format(C.ById[id].icon, C.ById[id].name, math.floor(seconds / 60 + 0.5)))
	return token
end

local function loop()
	local current = folder:GetAttribute("Current")
	if not C.ById[current or ""] then current = nil end
	set(current or "Sunny", rand:NextInteger(C.Duration[1], C.Duration[2]))
	while true do
		local my = token
		while os.time() < (folder:GetAttribute("Ends") or 0) do
			task.wait(1)
			if token ~= my then my = token end -- forced change: keep waiting for the new end time
		end
		local prev = folder:GetAttribute("Current")
		if (prev == "Rainy" or prev == "Thunderstorm" or prev == "Drizzle") and rand:NextNumber() < C.RainbowChance then
			set("Rainbow", C.RainbowDuration)
		else
			local nxt = pick(prev)
			set(nxt, nxt == "Typhoon" and 240 or rand:NextInteger(C.Duration[1], C.Duration[2]))
		end
	end
end

setter.Event:Connect(function(id, seconds) set(id, tonumber(seconds) or rand:NextInteger(C.Duration[1], C.Duration[2])) end)
task.spawn(loop)
