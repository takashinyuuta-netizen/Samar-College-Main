--[[ TalentShowServer — the Intramurals TALENT STAGE (1F hall, in front of the old stage).
  The stage model "TalentStage" lives in ServerStorage.HiddenVenues and appears only while the
  Intramurals event runs (SportsServer moves it into workspace.SportsVenues).

  🎤 SINGING  — a mic is REQUIRED: take one from a mic stand (ProximityPrompt). You get a "Microphone" tool
                (shown on your hotbar while you hold it). On stage with the mic, pick a backing track:
                it plays through the stage speakers for everyone nearby, the moving lights follow you,
                the LED screen shows your name + song. If voice chat is on, your voice goes through the
                stage speakers too (when the new Audio API is available). Leave the stage = the mic goes back.
  💃 DANCING  — step on stage and press Dance: you get the emote window and can put emotes on your hotbar
                for as long as you dance (the client clears them when you're done).
  👏 AUDIENCE — cheer for whoever is performing; every 10 cheers fires the confetti cannons.
  🏆 POINTS   — perform at least 20 s: +3 Intramural points; 8+ cheers: +3 more (crowd bonus).

  Remote: ReplicatedStorage.TalentShow.TalentEvent
    client -> server: { a = "sing", song = id } | { a = "stopsing" } | { a = "dance" } | { a = "dancedone" } | { a = "cheer" } | { a = "returnmic" }
    server -> client: { t = "state", ... } | { t = "toast", text = "..." } | { t = "cheer", from = name } ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local folder = RS:WaitForChild("TalentShow")
local ev = folder:WaitForChild("TalentEvent")
local Library = require(RS:WaitForChild("Music"):WaitForChild("MusicLibrary"))

local MIN_SECONDS = 20     -- perform at least this long for points
local CROWD_BONUS = 8      -- cheers needed for the bonus
local LEAVE_GRACE = 8      -- seconds off stage before the mic goes back / the dance ends

local stage = nil
local zone = nil
local backing = nil        -- Sound
local singer = nil         -- player whose backing track is playing
local songInfo = nil
local performers = {}      -- [player] = { mode = "sing"|"dance", start = os.clock(), cheers = 0 }
local onStage = {}         -- [player] = true
local offSince = {}        -- [player] = os.clock() when they stepped off
local mics = {}            -- [k] = { stand = Model, holder = player|nil, tool = Tool|nil }
local lastCheer = {}
local totalCheers = 0
local watchers = {}        -- [player] = true while they spectate the stage (👀 Watch)
local function watcherCount() local n = 0 for p in pairs(watchers) do if p.Parent then n += 1 end end return n end
local voiceLinks = {}      -- [player] = { instances }

local function activitySignal()
	local s = SS:FindFirstChild("SportsSignals")
	return s and s:FindFirstChild("SportsActivity")
end
local function toast(p, text) ev:FireClient(p, { t = "toast", text = text }) end

---------------------------------------------------------------- state for clients + LED screen
local function performerList()
	local list = {}
	for p, perf in pairs(performers) do
		if p.Parent then table.insert(list, { name = p.DisplayName, userId = p.UserId, mode = perf.mode, cheers = perf.cheers }) end
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end
local function updateLED()
	if not stage then return end
	local bg = stage:FindFirstChild("LEDScreen") and stage.LEDScreen.Screen.Display.BG
	if not bg then return end
	local list = performerList()
	if singer and songInfo then
		bg.Title.Text = "🎤 " .. singer.DisplayName
		bg.Sub.Text = "🎵 " .. songInfo.title .. " — " .. songInfo.artist
	elseif #list > 0 then
		local names = {}
		for _, e in ipairs(list) do table.insert(names, (e.mode == "sing" and "🎤 " or "💃 ") .. e.name) end
		bg.Title.Text = table.concat(names, "  •  ")
		bg.Sub.Text = "Now performing — cheer for them!"
	else
		bg.Title.Text = "The stage is open!"
		bg.Sub.Text = "Grab a mic to sing • Step up and dance"
	end
	local w = watcherCount()
	bg.Cheers.Text = (#list > 0 or singer) and ("👏 " .. totalCheers .. " cheers" .. (w > 0 and ("   👀 " .. w .. " watching") or "")) or ""
end
local function broadcast()
	local pos = stage and stage.PrimaryPart and stage.PrimaryPart.Position
	local msg = {
		t = "state", active = stage ~= nil, pos = pos, performers = performerList(), cheers = totalCheers,
		singer = singer and singer.DisplayName or nil, song = songInfo and (songInfo.title .. " — " .. songInfo.artist) or nil,
		watchers = watcherCount(),
	}
	ev:FireAllClients(msg)
	updateLED()
end

---------------------------------------------------------------- voice through the stage speakers (new Audio API, if the game uses it)
local function linkVoice(p)
	if voiceLinks[p] or not stage then return end
	pcall(function()
		local dev = p:FindFirstChildOfClass("AudioDeviceInput")
		if not dev then return end
		local made = {}
		for _, name in ipairs({ "SpeakerL", "SpeakerR" }) do
			local spk = stage:FindFirstChild(name, true)
			if spk then
				local em = Instance.new("AudioEmitter") em.Name = "StageVoice" em.Parent = spk
				local w = Instance.new("Wire") w.SourceInstance = dev w.TargetInstance = em w.Parent = em
				table.insert(made, em)
			end
		end
		voiceLinks[p] = made
	end)
end
local function unlinkVoice(p)
	for _, o in ipairs(voiceLinks[p] or {}) do if o.Parent then o:Destroy() end end
	voiceLinks[p] = nil
end

---------------------------------------------------------------- performances
local function stopBacking()
	if backing then backing:Stop() end
	singer, songInfo = nil, nil
end

local function finish(p, quiet)
	local perf = performers[p]
	if not perf then return end
	performers[p] = nil
	if next(performers) == nil then watchers = {} end -- show's over
	p:SetAttribute("SC_Performing", nil)
	if singer == p then stopBacking() end
	unlinkVoice(p)
	if not quiet and p.Parent then
		local secs = os.clock() - perf.start
		local act = activitySignal()
		if secs >= MIN_SECONDS and act then
			act:Fire({ type = "result", winners = { p }, losers = {} })
			local bonus = perf.cheers >= CROWD_BONUS
			if bonus then act:Fire({ type = "result", winners = { p }, losers = {} }) end
			toast(p, ("⭐ Great performance! +3 Intramural points%s  (👏 %d cheers)"):format(bonus and " +3 crowd bonus" or "", perf.cheers))
		elseif secs < MIN_SECONDS then
			toast(p, ("Perform at least %d seconds to earn Intramural points"):format(MIN_SECONDS))
		end
	end
	broadcast()
end

local function start(p, mode)
	watchers[p] = nil -- performers aren't spectators
	local perf = performers[p]
	if perf and perf.mode == mode then return perf end
	if perf then finish(p, true) end
	perf = { mode = mode, start = os.clock(), cheers = 0 }
	performers[p] = perf
	p:SetAttribute("SC_Performing", mode)
	local act = activitySignal()
	if act then act:Fire({ type = "join", player = p }) end
	broadcast()
	return perf
end

---------------------------------------------------------------- microphones
local function holdsMic(p)
	for _, m in pairs(mics) do if m.holder == p then return m end end
	return nil
end
local function setStandMic(m, visible)
	local micModel = m.stand:FindFirstChild("Mic")
	if micModel then for _, d in ipairs(micModel:GetDescendants()) do if d:IsA("BasePart") then d.Transparency = visible and 0 or 1 end end end
	local pr = m.stand:FindFirstChild("MicPrompt", true)
	if pr then pr.ActionText = visible and "Take mic" or "Return mic" end
end
local function returnMic(m, why)
	if not m or not m.holder then return end
	local p = m.holder
	m.holder = nil
	if m.tool and m.tool.Parent then m.tool:Destroy() end
	m.tool = nil
	setStandMic(m, true)
	if p.Parent then
		p:SetAttribute("SC_HasMic", nil)
		if performers[p] and performers[p].mode == "sing" then finish(p) end
		if why then toast(p, why) end
	end
end
local function makeMicTool(k)
	local tool = Instance.new("Tool")
	tool.Name = "Microphone"
	tool.ToolTip = "Stage mic " .. k
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("StageMic", k)
	local h = Instance.new("Part") h.Name = "Handle" h.Size = Vector3.new(0.26, 1.0, 0.26) h.Color = Color3.fromRGB(30, 30, 34) h.Material = Enum.Material.SmoothPlastic
	h.CanCollide = false h.Massless = true h.Parent = tool
	local ball = Instance.new("Part") ball.Name = "Grille" ball.Shape = Enum.PartType.Ball ball.Size = Vector3.new(0.48, 0.48, 0.48) ball.Color = Color3.fromRGB(190, 192, 198)
	ball.Material = Enum.Material.DiamondPlate ball.CanCollide = false ball.Massless = true ball.CFrame = h.CFrame * CFrame.new(0, 0.6, 0) ball.Parent = tool
	local w = Instance.new("WeldConstraint") w.Part0 = h w.Part1 = ball w.Parent = h
	local ring = Instance.new("Part") ring.Name = "Ring" ring.Shape = Enum.PartType.Cylinder ring.Size = Vector3.new(0.06, 0.3, 0.3) ring.Color = Color3.fromRGB(255, 200, 60)
	ring.Material = Enum.Material.Neon ring.CanCollide = false ring.Massless = true ring.CFrame = h.CFrame * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)) ring.Parent = tool
	local w2 = Instance.new("WeldConstraint") w2.Part0 = h w2.Part1 = ring w2.Parent = h
	-- music notes while singing
	local notes = Instance.new("ParticleEmitter") notes.Name = "Notes" notes.Texture = "rbxasset://textures/particles/sparkles_main.dds" notes.Rate = 0
	notes.Lifetime = NumberRange.new(1, 1.6) notes.Speed = NumberRange.new(2, 4) notes.SpreadAngle = Vector2.new(40, 40) notes.Size = NumberSequence.new(0.3)
	notes.Color = ColorSequence.new(Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 120, 200)) notes.LightEmission = 0.7 notes.Parent = ball
	-- hold it up near the mouth
	tool.Grip = CFrame.new(0, -0.1, 0.15) * CFrame.Angles(math.rad(-70), 0, 0)
	return tool
end
local function takeMic(p, m, k)
	if m.holder == p then returnMic(m, "🎤 Mic returned — thanks!") return end
	if m.holder then toast(p, "🎤 " .. m.holder.DisplayName .. " is using this mic — try the other stand") return end
	if holdsMic(p) then toast(p, "You already have a mic!") return end
	local bp = p:FindFirstChild("Backpack")
	if not bp then return end
	local tool = makeMicTool(k)
	tool.Parent = bp
	m.holder, m.tool = p, tool
	setStandMic(m, false)
	p:SetAttribute("SC_HasMic", k)
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum:EquipTool(tool) end
	toast(p, "🎤 You have the mic! Press 🎤 Sing to pick a song — leaving the stage returns the mic")
	tool.AncestryChanged:Connect(function()
		if not tool:IsDescendantOf(game) and m.tool == tool then returnMic(m) end
	end)
end

---------------------------------------------------------------- the light show
local t = 0
local lastLight = 0
local heads, tiles, strips = {}, {}, {}
local function hueColor(h, s, v) return Color3.fromHSV(h % 1, s or 1, v or 1) end
local function lightShow(dt)
	t += dt
	if os.clock() - lastLight < 0.1 or not stage then return end
	local step = os.clock() - lastLight
	lastLight = os.clock()
	local center = stage.PrimaryPart.Position + Vector3.new(0, 1.5, 0)
	local busy = next(performers) ~= nil
	local singerPos = singer and singer.Character and singer.Character:FindFirstChild("HumanoidRootPart") and singer.Character.HumanoidRootPart.Position
	for i, h in ipairs(heads) do
		local target
		if singerPos and i % 2 == 1 then
			target = singerPos + Vector3.new(0, 1, 0) -- follow-spot on the singer
		else
			local speed = busy and 1.4 or 0.45
			target = center + Vector3.new(math.sin(t * 0.7 * speed + i) * 9, -2, math.cos(t * 0.5 * speed + i * 0.8) * 14)
		end
		local cf = CFrame.lookAt(h.pos, target) * CFrame.Angles(0, math.rad(90), 0)
		h.lamp.CFrame = cf
		if h.lens then h.lens.CFrame = cf * CFrame.new(0.66, 0, 0) end
		local col = (singerPos and i % 2 == 1) and Color3.fromRGB(255, 245, 225) or hueColor(t * (busy and 0.12 or 0.04) + i * 0.13)
		if h.spot then h.spot.Color = col h.spot.Brightness = busy and 6 or 3 end
		if h.lens then h.lens.Color = col end
		if h.beam then h.beam.Color = ColorSequence.new(col) end
	end
	for i, tile in ipairs(tiles) do
		local ix, iz = (i - 1) // 6, (i - 1) % 6
		if busy or singer then
			local wave = math.sin(t * 6 + ix * 1.1 + iz * 0.8)
			tile.Color = hueColor(t * 0.15 + (ix + iz) * 0.08)
			tile.Transparency = wave > 0.2 and 0.15 or 0.55
		else
			tile.Color = Color3.fromRGB(80, 40, 160)
			tile.Transparency = 0.45 + math.sin(t * 1.2 + ix + iz) * 0.12
		end
	end
	local edgeCol = hueColor(t * 0.08)
	for _, s in ipairs(strips) do s.Color = edgeCol end
	local bg = stage.LEDScreen.Screen.Display.BG
	bg.Gradient.Rotation = (t * (busy and 40 or 12)) % 360
	local haze = stage:FindFirstChild("Haze", true)
	if haze and haze:IsA("ParticleEmitter") then haze.Rate = busy and 9 or 3 end
end

local function confetti()
	if not stage then return end
	for _, d in ipairs(stage:GetDescendants()) do
		if d:IsA("ParticleEmitter") and d.Name == "Confetti" then d:Emit(80) end
	end
end

---------------------------------------------------------------- attach / detach the stage
local function attach(model)
	if stage == model then return end
	stage = model
	zone = model:FindFirstChild("StageZone")
	heads, tiles, strips = {}, {}, {}
	for _, h in ipairs(model.MovingHeads:GetChildren()) do
		local lamp = h:FindFirstChild("Lamp")
		if lamp then
			table.insert(heads, { lamp = lamp, lens = h:FindFirstChild("Lens"), pos = lamp.Position, spot = lamp:FindFirstChildOfClass("SpotLight"), beam = lamp:FindFirstChildOfClass("Beam") })
		end
	end
	for _, tile in ipairs(model.DanceFloor:GetChildren()) do table.insert(tiles, tile) end
	table.sort(tiles, function(a, b) if a.Position.X ~= b.Position.X then return a.Position.X < b.Position.X end return a.Position.Z < b.Position.Z end)
	for _, s in ipairs(model.EdgeLED:GetChildren()) do table.insert(strips, s) end
	-- backing-track speaker (one sound in the middle so everyone hears it in sync)
	local screen = model.LEDScreen.Frame
	backing = screen:FindFirstChild("StageMusic_Backing") or Instance.new("Sound")
	backing.Name = "StageMusic_Backing" backing.Volume = 1 backing.RollOffMode = Enum.RollOffMode.InverseTapered
	backing.RollOffMinDistance = 30 backing.RollOffMaxDistance = 150 backing.Parent = screen
	backing.Ended:Connect(function() if singer then finish(singer) end end)
	-- mic stands
	mics = {}
	for k, st in ipairs({ model.MicStands:FindFirstChild("MicStand1"), model.MicStands:FindFirstChild("MicStand2") }) do
		if st then
			local m = { stand = st }
			mics[k] = m
			setStandMic(m, true)
			local pr = st:FindFirstChild("MicPrompt", true)
			if pr then pr.Triggered:Connect(function(p) takeMic(p, m, k) end) end
		end
	end
	totalCheers = 0
	broadcast()
end
local function detach()
	if not stage then return end
	for _, m in pairs(mics) do returnMic(m) end
	for p in pairs(performers) do finish(p, true) end
	stopBacking()
	for p in pairs(onStage) do if p.Parent then p:SetAttribute("SC_OnStage", nil) end end
	onStage, offSince, performers, watchers = {}, {}, {}, {}
	stage, zone = nil, nil
	broadcast()
end
local function isStage(inst) return inst:IsA("Model") and inst.Name == "TalentStage" and inst:GetAttribute("Sport") == "Talent" end
workspace.DescendantAdded:Connect(function(d) if isStage(d) then task.defer(attach, d) end end)
workspace.DescendantRemoving:Connect(function(d) if d == stage then detach() end end)
for _, d in ipairs(workspace:GetDescendants()) do if isStage(d) then attach(d) break end end

---------------------------------------------------------------- who is on the stage
local function inZone(p)
	if not zone then return false end
	local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local rel = zone.CFrame:PointToObjectSpace(hrp.Position)
	local s = zone.Size / 2
	return math.abs(rel.X) <= s.X + 0.5 and math.abs(rel.Y) <= s.Y + 2 and math.abs(rel.Z) <= s.Z + 0.5
end
task.spawn(function()
	while true do
		task.wait(0.3)
		for _, p in ipairs(Players:GetPlayers()) do
			local inside = stage ~= nil and inZone(p)
			if inside then
				offSince[p] = nil
				if not onStage[p] then onStage[p] = true p:SetAttribute("SC_OnStage", true) end
			else
				if onStage[p] then onStage[p] = nil p:SetAttribute("SC_OnStage", nil) offSince[p] = os.clock() end
				-- left the stage for a while: mic goes back, dance ends
				if offSince[p] and os.clock() - offSince[p] > LEAVE_GRACE then
					offSince[p] = nil
					local m = holdsMic(p)
					if m then returnMic(m, "🎤 You left the stage — the mic went back to its stand") end
					if performers[p] then finish(p) end
				end
			end
			-- singing with the mic in hand: sparkly notes
			local m = holdsMic(p)
			if m and m.tool then
				local n = m.tool:FindFirstChild("Notes", true)
				if n then n.Rate = (singer == p and m.tool.Parent == p.Character) and 6 or 0 end
				if singer == p or (performers[p] and performers[p].mode == "sing") then linkVoice(p) end
			end
		end
	end
end)
RunService.Heartbeat:Connect(lightShow)

---------------------------------------------------------------- requests
ev.OnServerEvent:Connect(function(p, msg)
	if type(msg) ~= "table" or not stage then return end
	local a = msg.a
	if a == "sing" then
		if not holdsMic(p) then toast(p, "🎤 You need a mic to sing — take one from a mic stand") return end
		if not onStage[p] then toast(p, "Step onto the stage to sing!") return end
		local song = Library.ById[tonumber(msg.song) or 0]
		if msg.song == "voice" then song = nil elseif not song then return end
		if singer and singer ~= p and backing.IsPlaying then
			toast(p, "🎶 " .. singer.DisplayName .. " is singing — join in as a duet with your voice, or wait for the song to end")
			start(p, "sing")
			return
		end
		start(p, "sing")
		if song then
			singer, songInfo = p, song
			backing:Stop()
			backing.SoundId = "rbxassetid://" .. song.id
			backing.TimePosition = 0
			backing:Play()
		else
			if singer == p then stopBacking() end
		end
		linkVoice(p)
		broadcast()
	elseif a == "stopsing" then
		if performers[p] and performers[p].mode == "sing" then finish(p) end
	elseif a == "dance" then
		if not onStage[p] then toast(p, "Step onto the stage to dance!") return end
		start(p, "dance")
	elseif a == "dancedone" then
		if performers[p] and performers[p].mode == "dance" then finish(p) end
	elseif a == "returnmic" then
		local m = holdsMic(p)
		if m then returnMic(m, "🎤 Mic returned — thanks!") end
	elseif a == "watch" then
		local on = msg.on == true and next(performers) ~= nil and not performers[p]
		if (watchers[p] == true) ~= on then
			watchers[p] = on or nil
			broadcast()
		end
	elseif a == "cheer" then
		if performers[p] then return end
		if os.clock() - (lastCheer[p] or 0) < 1.2 then return end
		if next(performers) == nil then return end
		local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		-- near the stage, or watching it from anywhere with 👀 Watch
		if not watchers[p] and (not hrp or (hrp.Position - stage.PrimaryPart.Position).Magnitude > 120) then return end
		lastCheer[p] = os.clock()
		for _, perf in pairs(performers) do perf.cheers += 1 end
		totalCheers += 1
		if totalCheers % 10 == 0 then confetti() end
		ev:FireAllClients({ t = "cheer", from = p.DisplayName })
		updateLED()
	end
end)

Players.PlayerRemoving:Connect(function(p)
	local m = holdsMic(p)
	if m then returnMic(m) end
	if performers[p] then finish(p, true) end
	onStage[p], offSince[p], lastCheer[p], watchers[p] = nil, nil, nil, nil
end)
Players.PlayerAdded:Connect(function(p) task.wait(3) if p.Parent then broadcast() end end)
