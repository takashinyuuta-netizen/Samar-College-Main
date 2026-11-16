--[[ Intramurals (RARE event) — the sports courts become the Intramurals.
  • No Join button: you take part by playing ANY intramural game while the event runs.
    Go to the 🏆 Intramurals doors in the 1F hall (or use "Go there"), walk into a door,
    pick a team (everyone plays together). If nobody else comes in 10 s, 🤖 CPU players fill the court
    (opponents, and teammates in team games).
  • While the event runs every court pays DOUBLE coins (rare event bonus).
  • Event points: win a game +3, play a game +1 (wins vs CPU +2). Most points = top places,
    and everyone who played gets the rare event participation reward at the end.
  The sports system lives in ServerScriptService.Sports.SportsServer; they talk through
  ServerStorage.SportsSignals (IntramuralsActive + SportsActivity).
]]
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local M = {}
local HUB = Vector3.new(221, 1, 160) -- in front of the Intramurals doors (1F hall)

local function signals()
	local f = ServerStorage:WaitForChild("SportsSignals", 10)
	return f and f:FindFirstChild("IntramuralsActive"), f and f:FindFirstChild("SportsActivity")
end

function M.Setup(ctx)
	local active, activity = signals()
	if not active or not activity then ctx.CancelReason = "the sports courts aren't set up" return false end
	ctx:SetLocation(HUB, "🏆 Intramurals Doors (1F Hall)")
	ctx.GotoPosition = HUB + Vector3.new(0, 3.5, -4)
	ctx.JoinMode = "zone"            -- no Join button: playing a game = taking part
	ctx.ScoreLabel = "Intramural points"
	ctx.Data.games = {}
	active.Value = true
	ctx:Connect(activity.Event, function(info)
		if type(info) ~= "table" or ctx.Phase == "Results" then return end
		if info.type == "join" and info.player and info.player.Parent then
			if not ctx:IsIn(info.player) then ctx:Join(info.player) end
		elseif info.type == "result" then
			for _, p in ipairs(info.winners or {}) do
				if p.Parent then
					if not ctx:IsIn(p) then ctx:Join(p) end
					local pts = info.vsCpu and 2 or 3
					ctx:AddScore(p, pts)
					ctx:Toast(p, ("🏆 Intramurals: %s %s win! +%d points"):format(info.icon or "", info.sportName or "", pts))
				end
			end
			for _, p in ipairs(info.losers or {}) do
				if p.Parent then
					if not ctx:IsIn(p) then ctx:Join(p) end
					ctx:AddScore(p, 1)
					ctx:Toast(p, "🏆 Intramurals: +1 point for playing!")
				end
			end
		end
	end)
end

function M.Start(ctx)
	for _, p in ipairs(Players:GetPlayers()) do
		ctx:Toast(p, "🏆 INTRAMURALS have started! Walk into a door in the 1F hall — double coins on every court!")
	end
end

function M.Finish(ctx)
	local list = {}
	for p, sc in pairs(ctx.Scores) do if p.Parent and sc > 0 then table.insert(list, { p = p, s = sc }) end end
	table.sort(list, function(a, b) return a.s > b.s end)
	ctx.Ranking = {}
	for _, e in ipairs(list) do table.insert(ctx.Ranking, e.p) end
	ctx.RewardEligible = {}
	for p in pairs(ctx.Participants) do ctx.RewardEligible[p] = true end
	local active = signals()
	if active then active.Value = false end
end

function M.Cleanup(ctx)
	local active = signals()
	if active then active.Value = false end
end

return M
