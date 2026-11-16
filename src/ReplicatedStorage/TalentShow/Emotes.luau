--[[ TalentShow.Emotes — emotes for the Intramurals Talent Stage (dance UI + temporary hotbar slots).
  Every animation here is made by Roblox (from Roblox's own catalog emotes), so it plays in any game.
  They are R15 animations; R6 avatars get the classic Roblox dances instead. ]]
local M = {}

M.Categories = {
	{ id = "Dance", name = "Dance", icon = "💃" },
	{ id = "Fun", name = "Fun", icon = "🎉" },
	{ id = "Greet", name = "Greet", icon = "👋" },
}

M.List = {
	{ id = "Hello", name = "Hello", icon = "👋", cat = "Greet", anim = "http://www.roblox.com/asset/?id=10714359093" },
	{ id = "HighWave", name = "High Wave", icon = "🙋", cat = "Greet", anim = "http://www.roblox.com/asset/?id=10714362852" },
	{ id = "JumpingWave", name = "Jumping Wave", icon = "🤸", cat = "Greet", anim = "http://www.roblox.com/asset/?id=10714378156" },
	{ id = "Salute", name = "Salute", icon = "🫡", cat = "Greet", anim = "http://www.roblox.com/asset/?id=10714389988" },
	{ id = "Curtsy", name = "Curtsy", icon = "🎀", cat = "Greet", anim = "http://www.roblox.com/asset/?id=10714061912" },
	{ id = "Beckon", name = "Beckon", icon = "🫴", cat = "Greet", anim = "http://www.roblox.com/asset/?id=10713984554" },
	{ id = "FlossDance", name = "Floss Dance", icon = "🕺", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10714340543" },
	{ id = "LineDance", name = "Line Dance", icon = "🤠", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10714383856" },
	{ id = "Samba", name = "Samba", icon = "💃", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10714386947" },
	{ id = "ChaCha", name = "Cha Cha", icon = "💃", cat = "Dance", anim = "http://www.roblox.com/asset/?id=6862001787" },
	{ id = "BreakDance", name = "Break Dance", icon = "🌀", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10714003221" },
	{ id = "Robot", name = "Robot", icon = "🤖", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10714392151" },
	{ id = "DorkyDance", name = "Dorky Dance", icon = "🤓", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10714069471" },
	{ id = "BabyDance", name = "Baby Dance", icon = "👶", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10713983178" },
	{ id = "DolphinDance", name = "Dolphin Dance", icon = "🐬", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10714068222" },
	{ id = "SidetoSide", name = "Side to Side", icon = "💫", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10714366910" },
	{ id = "FancyFeet", name = "Fancy Feet", icon = "👟", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10714076981" },
	{ id = "Shuffle", name = "Shuffle", icon = "🎶", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10714371274" },
	{ id = "TopRock", name = "Top Rock", icon = "🔥", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10714336041" },
	{ id = "BlockPartier", name = "Block Partier", icon = "🎉", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10713988674" },
	{ id = "Twirl", name = "Twirl", icon = "🌪️", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10714293450" },
	{ id = "FastHands", name = "Fast Hands", icon = "✋", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10714100539" },
	{ id = "Fashionable", name = "Fashionable", icon = "😎", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10714091938" },
	{ id = "AroundTown", name = "Around Town", icon = "🚶", cat = "Dance", anim = "http://www.roblox.com/asset/?id=10713981723" },
	{ id = "Stadium", name = "Stadium", icon = "🏟️", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714356920" },
	{ id = "Godlike", name = "Godlike", icon = "✨", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714347256" },
	{ id = "HeroLanding", name = "Hero Landing", icon = "🦸", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714360164" },
	{ id = "Celebrate", name = "Celebrate", icon = "🥳", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714016223" },
	{ id = "Applaud", name = "Applaud", icon = "👏", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10713966026" },
	{ id = "RockOn", name = "Rock On", icon = "🤘", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714403700" },
	{ id = "Idol", name = "Idol", icon = "🌟", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714372526" },
	{ id = "Bodybuilder", name = "Bodybuilder", icon = "💪", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10713990381" },
	{ id = "PowerBlast", name = "Power Blast", icon = "⚡", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714389396" },
	{ id = "Greatest", name = "Greatest", icon = "🏆", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714349037" },
	{ id = "Shrug", name = "Shrug", icon = "🤷", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714374484" },
	{ id = "Haha", name = "Haha", icon = "😂", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714350889" },
	{ id = "Tilt", name = "Tilt", icon = "🙃", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714338461" },
	{ id = "Shy", name = "Shy", icon = "😳", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714369325" },
	{ id = "Happy", name = "Happy", icon = "😄", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714352626" },
	{ id = "Monkey", name = "Monkey", icon = "🐒", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714388352" },
	{ id = "Tree", name = "Tree", icon = "🌳", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714330764" },
	{ id = "Zombie", name = "Zombie", icon = "🧟", cat = "Fun", anim = "http://www.roblox.com/asset/?id=10714089137" },
}

M.ById = {}
for i, e in ipairs(M.List) do e.index = i M.ById[e.id] = e end

-- classic R6 dances (Roblox) used when the avatar is R6
local R6_DANCES = { "rbxassetid://182435998", "rbxassetid://182491037", "rbxassetid://182491065" }

local current = {} -- [humanoid] = track
-- play an emote on a character (call from the player's own client: it replicates to everyone)
function M.play(character, id)
	local e = M.ById[id]
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not e or not hum then return nil end
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	M.stop(character)
	local anim = Instance.new("Animation")
	if hum.RigType == Enum.HumanoidRigType.R6 then
		anim.AnimationId = R6_DANCES[(e.index % #R6_DANCES) + 1]
	else
		anim.AnimationId = e.anim
	end
	local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
	if not ok or not track then return nil end
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = (e.cat == "Dance")
	track:Play(0.2)
	current[hum] = track
	-- walking or jumping stops the emote
	local conn
	conn = hum:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if hum.MoveDirection.Magnitude > 0.2 then
			if current[hum] == track then track:Stop(0.25) current[hum] = nil end
			conn:Disconnect()
		end
	end)
	track.Stopped:Connect(function() if conn.Connected then conn:Disconnect() end end)
	return track
end

function M.stop(character)
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if hum and current[hum] then current[hum]:Stop(0.25) current[hum] = nil end
end

return M
