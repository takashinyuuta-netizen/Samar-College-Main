-- StaffAccess: who counts as staff / employee for staff-only doors and ID gates.
-- A player is staff when ANY of these is true:
--   player attribute Role is "Teacher", "Staff", "Employee", "Faculty" or "Guard"
--     (the Profile Student/Teacher toggle should set this attribute)
--   player attribute IsStaff == true
--   the player is the game owner (same owner list as AdminServer)
-- Everyone else is treated as a student.
local StaffAccess = {}

local STAFF_ROLES = { Teacher = true, Staff = true, Employee = true, Faculty = true, Guard = true }
local OWNER_IDS = { [2697306367] = true } -- Aka_Yuuki (Umi), keep in sync with AdminServer
if game.CreatorType == Enum.CreatorType.User and game.CreatorId > 0 then OWNER_IDS[game.CreatorId] = true end

function StaffAccess.isStaff(player)
	if not player then return false end
	if player:GetAttribute("IsStaff") == true then return true end
	local role = player:GetAttribute("Role")
	if type(role) == "string" and STAFF_ROLES[role] then return true end
	if player:GetAttribute("TestAsStudent") == true then return false end
	return OWNER_IDS[player.UserId] == true
end

function StaffAccess.label(player)
	return StaffAccess.isStaff(player) and "EMPLOYEE" or "STUDENT"
end

return StaffAccess
