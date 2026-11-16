--[[ HostingConfig — player-hosted meetings / classes in any campus room (no time limit).
  HostingServer locks the room (room attribute "HostedBy") so room events (Quiz Bee, Guess the Drawing,
  Escape School keys) skip it until the host ends the meeting. ]]
local M = {}

M.Types = {
	{ Id = "Meeting",      Icon = "📌", Name = "Meeting" },
	{ Id = "Class",        Icon = "📚", Name = "Class / Lecture" },
	{ Id = "Review",       Icon = "📝", Name = "Review Session" },
	{ Id = "StudyGroup",   Icon = "👥", Name = "Study Group" },
	{ Id = "Club",         Icon = "🎭", Name = "Club Meeting" },
	{ Id = "Faculty",      Icon = "👩‍🏫", Name = "Faculty Meeting" },
	{ Id = "Orientation",  Icon = "🎓", Name = "Orientation" },
	{ Id = "Consultation", Icon = "💬", Name = "Consultation" },
	{ Id = "Practice",     Icon = "🎤", Name = "Practice / Rehearsal" },
	{ Id = "Hangout",      Icon = "🎉", Name = "Hangout" },
}
function M.type(id) for _, t in ipairs(M.Types) do if t.Id == id then return t end end return M.Types[1] end

M.MaxTitle = 40
M.MaxAttendees = 40
M.InviteCooldown = 6 -- seconds between invites to the same player

-- rooms in */02_Rooms that can't be hosted in (name patterns)
M.Exclude = { "Bathroom", "Restroom", "CR_", "Storage", "Janitor", "Utility", "Closet", "PowerHouse", "BackRoom", "Backstage" }
function M.excluded(name) for _, p in ipairs(M.Exclude) do if name:find(p) then return true end end return false end

M.FloorOrder = { "1F_Ground", "2F", "3F", "4F", "5F", "Roof" }
M.FloorLabel = { ["1F_Ground"] = "1F", ["2F"] = "2F", ["3F"] = "3F", ["4F"] = "4F", ["5F"] = "5F", Roof = "Roof" }

-- "Classroom_2F_006" → "Classroom 2F 006", "MedicalDentalClinic" → "Medical Dental Clinic", "ADM301" → "ADM 301"
function M.pretty(name)
	local s = name:gsub("_", " ")
	s = s:gsub("(%l)(%u)", "%1 %2")
	s = s:gsub("^(%u%u%u)(%d)", "%1 %2")
	s = s:gsub("%s+", " ")
	return s
end

return M
