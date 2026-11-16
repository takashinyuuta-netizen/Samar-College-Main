--[[ PlayerBusy — ONE place that knows what a player is busy with, so systems don't pull each other's players away.
  Activities (player attributes set by their own systems):
    InSkyClimb     PATAAS! Parkour (SkyClimbServer)
    Lock_Event     taking part in a campus event (EventManager)
    Lock_Court     playing a sports / chess game (SportsServer)
    SC_Performing  singing / performing on the talent stage (TalentShowServer)
  Use:
    local Busy = require(ServerScriptService.PlayerBusy)
    local reason = Busy.reason(player, { ignore = { Lock_Event = true } })  -- nil = free
  Roleplay (Student / Teacher / Staff...) is NOT an activity: it never blocks anything. ]]
local M = {}

M.Activities = {
	{ attr = "InSkyClimb", msg = "⛰️ You're in PATAAS! Parkour — go back to campus first" },
	{ attr = "SC_Performing", msg = "🎤 You're performing on stage — finish your performance first" },
	{ attr = "Lock_Court", msg = "🏀 You're in a game right now — finish or leave it first" },
	{ attr = "Lock_Event", msg = "🎪 You're in an event right now — leave it first" },
}

-- returns a friendly reason string when the player is busy, or nil when free
function M.reason(player, opts)
	if not player then return nil end
	local ignore = opts and opts.ignore or {}
	for _, a in ipairs(M.Activities) do
		if not ignore[a.attr] and player:GetAttribute(a.attr) then return a.msg end
	end
	return nil
end

function M.isBusy(player, opts) return M.reason(player, opts) ~= nil end

return M
