--[[ EventAdmin ──────────────────────────────────────────────────────────────
  Admin / test controls for events.
  • Chat:  /event list            – show every event and its status
           /event start QuizBee   – force-start an event (ignores Enabled/cooldowns)
           /event stop            – stop the running event (no rewards)
           /event next            – start the rotation pick now
           /event skipphase       – end the countdown / active phase now (testing)
  • Admin panel (🎪 Events section) calls AdminServer → ServerStorage.EventSignals.EventControl.
  Only admins can use it: the IsAdmin attribute set by AdminServer (owner + co-admins).
  In Studio play tests everyone is allowed, so you can test alone.
───────────────────────────────────────────────────────────────────────────]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TextChatService = game:GetService("TextChatService")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS:WaitForChild("Events"):WaitForChild("EventConfig"))
local Remotes = RS.Events:WaitForChild("EventRemotes")

local EventAdmin = {}

local function allowed(player)
	if RunService:IsStudio() then return true end
	return player and player:GetAttribute("IsAdmin") == true
end

local function list(manager)
	local rows = {}
	for _, id in ipairs(Config.Order) do
		local def = Config.Events[id]
		if def then
			local built = script.Parent.EventModules:FindFirstChild(id) ~= nil
			table.insert(rows, { id = id, name = def.Name, icon = def.Icon, rarity = def.Rarity,
				enabled = def.Enabled ~= false, built = built })
		end
	end
	local cur = manager.current()
	return { ok = true, events = rows, running = cur and cur.Def.Name or nil, phase = cur and cur.Phase or nil,
		nextIn = math.floor(manager.secondsUntilNext()), serverType = manager.ServerType }
end

local function control(manager, cmd, arg, caller)
	if not allowed(caller) then return { ok = false, msg = "Not an admin" } end
	if cmd == "list" then return list(manager) end
	if cmd == "start" then
		local id = arg
		for key in pairs(Config.Events) do if key:lower() == tostring(arg):lower() then id = key end end
		local ok, msg = manager.start(id, { forced = true, announce = 15 })
		return { ok = ok, msg = msg }
	end
	if cmd == "stop" then local ok, msg = manager.stop() return { ok = ok, msg = msg } end
	if cmd == "skip" then manager.skipTimer() return { ok = true, msg = "Rotation will pick an event now" } end
	if cmd == "skipphase" then local ok, msg = manager.skipPhase() return { ok = ok, msg = msg } end
	return { ok = false, msg = "Unknown command" }
end

function EventAdmin.init(manager)
	-- bridge for the Admin panel (AdminServer invokes this)
	local sig = ServerStorage:FindFirstChild("EventSignals") or Instance.new("Folder")
	sig.Name = "EventSignals" sig.Parent = ServerStorage
	local fn = sig:FindFirstChild("EventControl") or Instance.new("BindableFunction")
	fn.Name = "EventControl" fn.Parent = sig
	fn.OnInvoke = function(cmd, arg, caller) return control(manager, cmd, arg, caller) end

	-- chat command
	local function handle(player, text)
		local args = string.split(text, " ")
		if (args[1] or ""):lower() ~= "/event" then return end
		local cmd = (args[2] or "list"):lower()
		if cmd == "next" then cmd = "skip" end
		local res = control(manager, cmd, args[3], player)
		if cmd == "list" and res.ok then
			local parts = {}
			for _, r in ipairs(res.events) do
				table.insert(parts, ("%s %s%s"):format(r.icon or "", r.id, r.built and "" or " (not built)"))
			end
			Remotes.EventToast:FireClient(player, "Events: " .. table.concat(parts, " • ") .. (res.running and (" | Running: " .. res.running) or (" | Next in " .. res.nextIn .. "s")))
		else
			Remotes.EventToast:FireClient(player, (res.ok and "✅ " or "⚠️ ") .. tostring(res.msg))
		end
	end

	local ok = pcall(function()
		local cmd = TextChatService:FindFirstChild("EventCommand") or Instance.new("TextChatCommand")
		cmd.Name = "EventCommand"
		cmd.PrimaryAlias = "/event"
		cmd.Parent = TextChatService
		cmd.Triggered:Connect(function(source, text)
			local p = Players:GetPlayerByUserId(source.UserId)
			if p then handle(p, text) end
		end)
	end)
	if not ok then warn("[EventAdmin] TextChatCommand unavailable, using Chatted") end
	-- legacy chat fallback
	local function hook(p) p.Chatted:Connect(function(msg) if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then handle(p, msg) end end) end
	Players.PlayerAdded:Connect(hook)
	for _, p in ipairs(Players:GetPlayers()) do hook(p) end
end

return EventAdmin
