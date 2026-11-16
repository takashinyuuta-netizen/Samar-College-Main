--[[ RoleplayConfig — be a Student, Teacher, Instructor, Employee or campus Staff.
  Saved player attributes (numbers): RP_Role (1 = Student), RP_1, RP_2, RP_3 (picked option per row, 1-based).
  StaffRole is written to the player's "Role" attribute, which StaffAccess reads (staff-only gates, ID scanners).
  To add or rename options, just edit the lists below. ]]
local RS = game:GetService("ReplicatedStorage")
local LevelConfig = require(RS:WaitForChild("LevelConfig"))

local M = {}

local GRADES = {}
for i = 1, 13 do table.insert(GRADES, LevelConfig.name(i)) end -- Kindergarten … Grade 12
local COURSES = {}
for _, p in ipairs(LevelConfig.Programs.College.List) do table.insert(COURSES, p.Id) end

M.Roles = {
	{ Id = "Student", Icon = "🎒", Name = "Student", Color = Color3.fromRGB(60, 150, 90), Desc = "Your normal school level, course and strand.", Options = {} },
	{ Id = "Teacher", Icon = "👩‍🏫", Name = "Teacher", StaffRole = "Teacher", Color = Color3.fromRGB(70, 140, 230),
		Desc = "Teach Kindergarten to Grade 12.",
		Options = {
			{ Label = "Grade level assigned", List = GRADES },
			{ Label = "Subject", List = { "Mathematics", "English", "Filipino", "Science", "Araling Panlipunan", "MAPEH", "Values Education", "TLE", "ICT / Computer", "Reading", "Research", "Homeroom" } },
			{ Label = "Duty / role", List = { "Class Adviser", "Subject Teacher", "Grade Coordinator", "Guidance Teacher", "Club Moderator", "Sports Coach", "Documenting", "Technical Support", "Event Coordinator", "Librarian" } },
		} },
	{ Id = "Instructor", Icon = "🧑‍🏫", Name = "Instructor", StaffRole = "Faculty", Color = Color3.fromRGB(230, 170, 50),
		Desc = "Teach a Samar College course.",
		Options = {
			{ Label = "Course assigned", List = COURSES },
			{ Label = "Subject", List = { "Programming", "Networking", "Database", "Web Development", "Multimedia", "Criminal Law", "Forensic Science", "Criminology", "Accounting", "Marketing", "Management", "Teaching Methods", "English", "Mathematics", "Research / Thesis", "General Education", "PE / NSTP" } },
			{ Label = "Duty / role", List = { "Instructor", "Program Head", "Dean", "Class Adviser", "Thesis Adviser", "OJT Coordinator", "Research Coordinator", "Documenting", "Technical Support", "Accreditation" } },
		} },
	{ Id = "Employee", Icon = "💼", Name = "Employee", StaffRole = "Employee", Color = Color3.fromRGB(150, 90, 200),
		Desc = "Work in one of the campus offices.",
		Options = {
			{ Label = "Office", List = { "Registrar", "Cashier", "Accounting", "Admissions", "Library", "Guidance Office", "Clinic", "OSAS", "HR Office", "MIS / IT Office", "Procurement", "Principal's Office", "Dean's Office", "President's Office" } },
			{ Label = "Duty / role", List = { "Documenting", "Technical Support", "Front Desk", "Records / Encoding", "Cashiering", "Photographer / Media", "Event Coordinator", "Counselor", "Nurse", "Librarian", "Office Head" } },
		} },
	{ Id = "Staff", Icon = "🧹", Name = "Staff", StaffRole = "Staff", Color = Color3.fromRGB(200, 110, 60),
		Desc = "Keep the campus clean, safe and running.",
		Options = {
			{ Label = "Job", List = { "Cleaning / Utility", "Security Guard", "Maintenance", "Electrician", "Plumber", "Gardener", "Canteen Staff", "Driver", "Messenger", "Lab Assistant", "Library Aide", "Stage Crew" } },
			{ Label = "Area assigned", List = { "Whole Campus", "1st Floor", "2nd Floor", "3rd Floor", "4th Floor", "5th Floor", "Canteen", "Library", "Gym / Court", "Main Gate", "Offices", "Comfort Rooms" } },
		} },
}

function M.role(i) return M.Roles[i or 1] or M.Roles[1] end
function M.pick(role, row, idx)
	local opt = role.Options[row]
	if not opt then return nil end
	return opt.List[math.clamp(idx or 1, 1, #opt.List)]
end
-- title for the leaderboard / ID scanners (nil = use the student title)
function M.titleFor(roleIdx, a, b, c)
	local r = M.role(roleIdx)
	if r.Id == "Student" then return nil end
	if r.Id == "Teacher" then return ("Teacher • %s • %s"):format(M.pick(r, 1, a), M.pick(r, 2, b)) end
	if r.Id == "Instructor" then return ("Instructor • %s • %s"):format(M.pick(r, 1, a), M.pick(r, 2, b)) end
	if r.Id == "Employee" then return ("%s • %s"):format(M.pick(r, 1, a), M.pick(r, 2, b)) end
	if r.Id == "Staff" then return ("%s • %s"):format(M.pick(r, 1, a), M.pick(r, 2, b)) end
end
-- two lines for the overhead tag
function M.tagFor(roleIdx, a, b, c)
	local r = M.role(roleIdx)
	if r.Id == "Student" then return nil end
	if r.Id == "Teacher" or r.Id == "Instructor" then
		return ("%s %s • %s"):format(r.Icon, r.Name, M.pick(r, 3, c)), ("%s · %s"):format(M.pick(r, 1, a), M.pick(r, 2, b)), r.Color
	end
	if r.Id == "Employee" then return ("%s %s"):format(r.Icon, M.pick(r, 1, a)), M.pick(r, 2, b), r.Color end
	return ("%s %s"):format(r.Icon, M.pick(r, 1, a)), "Area: " .. M.pick(r, 2, b), r.Color
end

return M
