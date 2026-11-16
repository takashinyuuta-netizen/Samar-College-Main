--[[ CampusLifeConfig ────────────────────────────────────────────────────────
  Settings for the living campus: student, faculty and staff NPCs with schedules,
  conversations, ambient chatter, plus the hangout background music.
  Shared by the server (CampusLifeServer) and the client (dialogue UI + music).
───────────────────────────────────────────────────────────────────────────]]
local C = {}

---------------------------------------------------------------- how many NPCs
C.Counts = { Students = 6, Faculty = 0 }   -- kept small for performance; offices + faculty come from C.OrgChart / C.Faculty below

---------------------------------------------------------------- school clock
-- The SKY clock (Lighting.ClockTime) is the school clock. ServerScriptService.DayNightCycle runs
-- the day slowly and the night quickly:
C.SecondsPerMinute = 2          -- daytime: 1 school minute = 2 real seconds (90-minute class ≈ 3 real minutes)
C.NightRealMinutes = 4          -- the whole night (6 PM – 6 AM) passes in 4 real minutes
C.StartHour = 7.25              -- a new server starts at 7:15 AM
C.ArriveFrom = 6 * 60 + 30      -- 6:30 AM NPCs start arriving through the main gate
C.LeaveBy = 17 * 60 + 30        -- 5:30 PM everybody has gone home (NPCs disappear until morning)
C.DayStart = 7 * 60 + 30         -- 7:30 AM
C.DayEnd   = 16 * 60 + 30        -- 4:30 PM, then the day starts again
-- Kind: "Class" (go to your room), "Break" / "Lunch" (hang out, eat), "Free" (clubs, wander)
C.Schedule = {
	{ From = "7:30",  To = "9:00",  Name = "1st Period", Kind = "Class" },
	{ From = "9:00",  To = "9:30",  Name = "Recess",     Kind = "Break" },
	{ From = "9:30",  To = "11:00", Name = "2nd Period", Kind = "Class" },
	{ From = "11:00", To = "12:00", Name = "Lunch",      Kind = "Lunch" },
	{ From = "12:00", To = "13:30", Name = "3rd Period", Kind = "Class" },
	{ From = "13:30", To = "15:00", Name = "4th Period", Kind = "Class" },
	{ From = "15:00", To = "16:30", Name = "Clubs & Free Time", Kind = "Free" },
}
-- outside the timetable
C.BeforeSchool = { Name = "Before Class", Kind = "Arrive" }
C.Dismissal = { Name = "Dismissal", Kind = "GoHome" }
C.Night = { Name = "Night", Kind = "Away" }

---------------------------------------------------------------- music (hangout / free roam)
C.Music = {
	Hangout = "rbxassetid://1835322104", -- "Hopeful Contemplation" (APM) – calm campus background
	Volume = 0.25,                       -- multiplied by Settings → Music volume
}

---------------------------------------------------------------- random names
C.FirstNamesMale = { "Juan", "Miguel", "Jose", "Rafael", "Carlo", "Paolo", "Mark", "John Paul", "Kevin", "Jericho", "Aldrin", "Christian", "Joshua", "Ramon", "Andres", "Emilio", "Gabriel", "Nathaniel", "Renz", "Marco" }
C.FirstNamesFemale = { "Maria", "Angela", "Patricia", "Kristine", "Andrea", "Camille", "Bea", "Nicole", "Sofia", "Isabel", "Rhea", "Jasmine", "Trisha", "Hannah", "Aira", "Joy", "Liza", "Carmela", "Princess", "Mae" }
C.LastNames = { "Dela Cruz", "Santos", "Reyes", "Garcia", "Mendoza", "Bautista", "Villanueva", "Ramos", "Aquino", "Castillo", "Fernandez", "Gonzales", "Lopez", "Morales", "Navarro", "Pascual", "Rosales", "Tolentino", "Uy", "Cabrera", "Abellar", "Ocenar", "Gabane", "Bacarra", "Tan" }

---------------------------------------------------------------- staff (fixed roles)
-- Room = room model name where they work (a random clear spot inside is used); Template = existing NPC to copy
C.Staff = {
	{ Role = "Security Guard",      Department = "Safety & Security Office", Template = "Guard", Spot = "MainGate", PostName = "Main Gate", Activities = { "checking student IDs", "guarding the main gate", "greeting visitors" }, Lines = { "Good morning! Please wear your ID.", "Stay safe, everyone!", "No ID, no entry ha.", "Walk, don't run in the hallways!" } },
	{ Role = "Security Guard",      Department = "Safety & Security Office", Template = "Guard", Spot = "Courtyard", PostName = "Courtyard", Activities = { "patrolling the courtyard", "watching the students" }, Lines = { "Keep the courtyard clean, okay?", "All clear here.", "Have a nice day, students!" } },
	{ Role = "Utility / Janitor",   Department = "Facilities & Maintenance", Look = "Janitor", Spot = "Wander", PostName = "Hallways", Activities = { "sweeping the hallway", "mopping the floor", "emptying trash bins" }, Lines = { "Careful, the floor is wet!", "Please throw your trash in the bins.", "Ang linis na ng hallway!" } },
	{ Role = "Librarian",           Department = "Learning Resource Center", Look = "Librarian", Room = "Classroom_3F_009", PostName = "DLRC Library", Activities = { "organizing books", "checking out books", "cataloging new arrivals" }, Lines = { "Shhh… quiet in the library please.", "New books just arrived!", "Return your books on time, okay?" } },
	{ Role = "Canteen Staff",       Department = "School Canteen", Look = "Canteen", Room = "Canteen", PostName = "School Canteen", Activities = { "serving food", "cooking lunch", "wiping the tables" }, Lines = { "Lunch is ready! Adobo today!", "Next in line, please!", "Masarap ang pansit ngayon!" } },
	{ Role = "School Nurse",        Department = "Medical & Dental Clinic", Look = "Nurse", Room = "MedicalDentalClinic", PostName = "Medical & Dental Clinic", Activities = { "attending to a patient", "checking supplies", "updating health records" }, Lines = { "Drink water and stay healthy!", "Feeling sick? Come to the clinic.", "Don't forget to wash your hands." } },
}

---------------------------------------------------------------- faculty rooms (where teachers go when they are not teaching)
C.FacultyRooms = {
	["Junior High"] = "JHS_FacultyRoom",
	["Senior High"] = "SHS_Faculty_Room",
	["College"] = "College_FacultyRoom",
	["BSCRIM"] = "Criminology_FacultyOffice",
	["Elementary"] = "JHS_FacultyRoom",
}

-- hangout places for breaks / lunch / free time (room names; "Courtyard" = the open quad)
-- "Classroom" = the student's own section room (most stay inside, so the outside isn't crowded)
C.Hangouts = {
	Break = { "Classroom", "Classroom", "Classroom", "Canteen", "Canteen", "Corridor", "Courtyard" },
	Lunch = { "Canteen", "Canteen", "Canteen", "Classroom", "Classroom" },
	Free  = { "Classroom", "Classroom", "Classroom_3F_009", "Canteen", "Courtyard" },
}

---------------------------------------------------------------- subjects (by course/strand, then by level)
C.Subjects = {
	BSIT = { "Programming", "Database Systems", "Networking", "Web Development", "Systems Analysis", "Purposive Communication" },
	BSCRIM = { "Criminal Law", "Criminalistics", "Law Enforcement", "Forensic Science", "Criminal Sociology", "Ethics" },
	BSEd = { "Teaching Strategies", "Child & Adolescent Development", "Assessment of Learning", "Curriculum Development", "Educational Technology", "Ethics" },
	STEM = { "General Mathematics", "Pre-Calculus", "General Chemistry", "Earth Science", "Research", "Oral Communication" },
	HUMSS = { "Creative Writing", "DIASS", "Philippine Politics", "Philosophy", "Research", "Oral Communication" },
	GAS = { "General Mathematics", "Organization & Management", "Earth & Life Science", "Research", "Oral Communication" },
	ABM = { "Fundamentals of ABM", "Business Mathematics", "Applied Economics", "Marketing", "Research" },
	["TVL-ICT"] = { "Computer Systems Servicing", "Programming", "Animation", "Research", "Entrepreneurship" },
	["Junior High"] = { "Mathematics", "Science", "English", "Filipino", "Araling Panlipunan", "TLE", "MAPEH", "Values Education" },
	Elementary = { "Math", "Science", "English", "Filipino", "Araling Panlipunan", "MAPEH", "EsP" },
}

---------------------------------------------------------------- uniforms (body colors)
C.Uniforms = {
	Elementary = { Torso = Color3.fromRGB(245, 245, 240), Legs = Color3.fromRGB(40, 110, 70) },
	["Junior High"] = { Torso = Color3.fromRGB(245, 245, 240), Legs = Color3.fromRGB(30, 45, 90) },
	["Senior High"] = { Torso = Color3.fromRGB(245, 245, 240), Legs = Color3.fromRGB(80, 85, 95) },
	College = { Torso = Color3.fromRGB(245, 245, 240), Legs = Color3.fromRGB(25, 25, 30) },
	Faculty = { Torso = { Color3.fromRGB(30, 70, 50), Color3.fromRGB(60, 40, 90), Color3.fromRGB(110, 30, 40), Color3.fromRGB(30, 50, 90) }, Legs = Color3.fromRGB(35, 35, 40) },
	Janitor = { Torso = Color3.fromRGB(70, 110, 160), Legs = Color3.fromRGB(50, 70, 100) },
	Librarian = { Torso = Color3.fromRGB(120, 40, 50), Legs = Color3.fromRGB(40, 40, 45) },
	Canteen = { Torso = Color3.fromRGB(250, 250, 250), Legs = Color3.fromRGB(60, 60, 64) },
	Nurse = { Torso = Color3.fromRGB(250, 250, 255), Legs = Color3.fromRGB(240, 240, 245) },
	Office = { Torso = Color3.fromRGB(200, 70, 60), Legs = Color3.fromRGB(40, 40, 45) },
}
C.SkinTones = { Color3.fromRGB(234, 192, 160), Color3.fromRGB(214, 168, 128), Color3.fromRGB(196, 146, 106), Color3.fromRGB(170, 120, 85), Color3.fromRGB(240, 205, 175) }
-- free Roblox hairs (checked when the server starts; the ones that fail to load are skipped)
C.Hair = { 63690008, 451220849, 451221329, 62234425, 4637245782, 5890690147, 6026462825, 4875445470 }

---------------------------------------------------------------- ambient chatter
C.Lines = {
	Any = { "Hello Dear!", "What a nice day!", "Kumusta ka?", "Mabuhay, Samar College!", "Ang init ngayon, grabe!", "Good morning!", "Have you eaten yet?", "Let's go!", "Nice weather today.", "Ingat!" },
	Student = { "Did you finish the assignment?", "Quiz later, don't forget!", "I'm so hungry… canteen tayo?", "Wait for me!", "I hope our teacher is absent today, hehe.", "Let's review together later.", "I love Samar College!", "Who has a pen?", "My crush is in the next room…", "Group project na naman!" },
	Faculty = { "Please settle down, class.", "Don't forget your homework.", "Very good, everyone!", "Any questions so far?", "Submit your projects on Friday.", "Good job today.", "Let's start the lesson.", "Bring your notebooks tomorrow." },
	Class = { "Okay class, open your books.", "Who can answer number three?", "Please be quiet, class is ongoing." },
	Lunch = { "Ang sarap ng ulam!", "Pass the rice please!", "Let's eat together!", "Busog na ako!" },
}

---------------------------------------------------------------- conversation answers (filled with {status}, {room}, {next}…)
C.Answers = {
	Busy = {
		Teaching = { "I'm teaching right now — {room} is in session. Can we talk after class?", "Yes, I'm busy with my class in {room}." },
		Working = { "A bit busy — I'm {activity}.", "I'm working right now, but go ahead." },
		InClass = { "Shh, I'm in class! The teacher is looking…", "I'm in {room}, our class is ongoing." },
		OnBreak = { "Not at all! It's {period}, I'm free.", "Nope, just relaxing. It's {period}!" },
		Free = { "I'm free right now!", "Nope, I have time. What's up?" },
		Walking = { "Kind of — I'm on my way to {destination}.", "I'm heading to {destination}, but I can talk a bit." },
	},
	Tips = {
		Student = { "Study a little every day, it really helps!", "Don't forget to drink water.", "Join a club — it's fun!", "Sit in front, you'll learn more.", "Ask the teacher if you don't understand." },
		Faculty = { "Read your lessons before class.", "Be on time, always.", "Practice what you learned — that's how you remember.", "Respect your classmates and teachers.", "Never stop asking questions." },
		Staff = { "Always wear your school ID.", "Keep the campus clean!", "Take care of school property.", "If you need help, just ask any staff." },
	},
}

---------------------------------------------------------------- helpers
local function parse(t) local h, m = t:match("(%d+):(%d+)") return tonumber(h) * 60 + tonumber(m) end
for _, p in ipairs(C.Schedule) do p.FromMin = parse(p.From) p.ToMin = parse(p.To) end

-- current school minute of the day (same on server and clients)
-- current school minute of the day = the sky clock (same on server and clients)
function C.schoolMinute()
	return game:GetService("Lighting").ClockTime * 60
end
function C.periodAt(minute)
	for i, p in ipairs(C.Schedule) do if minute >= p.FromMin and minute < p.ToMin then return p, i end end
	if minute >= C.ArriveFrom and minute < C.DayStart then return C.BeforeSchool, 0 end
	if minute >= C.DayEnd and minute < C.LeaveBy then return C.Dismissal, #C.Schedule + 1 end
	return C.Night, -1
end
function C.formatTime(minute)
	minute = math.floor(minute)
	local h, m = minute // 60, minute % 60
	local ampm = h >= 12 and "PM" or "AM"
	local h12 = h % 12 if h12 == 0 then h12 = 12 end
	return ("%d:%02d %s"):format(h12, m, ampm)
end

---------------------------------------------------------------- organizational chart (one NPC per office)
-- Each NPC stays in (or patrols a few steps around) their own office. Room = room model name.
local function office(role, dept, room, look, acts, lines)
	return { Role = role, Department = dept, Room = room, Look = look or "Office", Template = (look == "Guard") and "Guard" or nil, PostName = dept, Activities = acts, Lines = lines }
end
local function seated(e, seatPath) e.Seat = seatPath return e end
local function dean(code, college, lines)
	local e = office("Dean, " .. code, college, "CollegeDeans_CoursesOffice", "Faculty", { "signing student clearances", "meeting with " .. code .. " instructors", "checking class records" }, lines)
	e.Seat = "Cubicles.Cubicle_" .. code .. ".DeanChair.Seat"
	e.Status = "Cubicles.Cubicle_" .. code .. ".DeanStatus"
	return e
end
C.OrgChart = {
	-- Administration
	office("Senior Vice President", "Office of the Senior Vice President", "SVP_Office", "Faculty", { "signing documents", "meeting with department heads", "reviewing school policies" }, { "Welcome to Samar College!", "Study hard, the future is yours.", "My door is always open for students." }),
	office("VP for Administration", "Office of the VP for Administration", "SVP_AdminOffice", "Faculty", { "approving requests", "reviewing the budget" }, { "Good day! How can the admin office help?", "Take care of our school, okay?" }),
	office("VP for Academic Programs", "Office of Academic Programs", "SVP_AcademicPrograms_Office", "Faculty", { "reviewing the curriculum", "checking class schedules" }, { "Quality education is our priority.", "Have you checked your class schedule?" }),
	office("Procurement & Property Officer", "Procurement & Property Office", "ProcurementProperty_Office", "Office", { "checking inventory", "processing purchase orders" }, { "New chairs are coming soon!", "Please take care of school property." }),
	-- Finance & records
	office("Accountant", "Accounting Office", "AccountingOffice", "Office", { "balancing the books", "preparing reports" }, { "Numbers don't lie!", "Have you settled your balance?" }),
	office("Cashier", "Cashier & Finance Office", "Cashier_FinanceOffice", "Office", { "receiving payments", "issuing receipts" }, { "Next in line, please.", "Keep your official receipt, okay?" }),
	office("Registrar", "Office of the Registrar", "RegistrarOffice", "Office", { "processing enrollment", "printing transcripts", "updating student records" }, { "Do you have your enrollment form?", "Requests take 3 working days.", "Please fall in line." }),
	office("Records Officer (JHS)", "Junior High Records Section", "JHS_RecordSection", "Office", { "filing report cards", "updating records" }, { "Need your Form 137?", "Records are up to date!" }),
	office("Records Officer (SHS)", "Senior High Records Office", "SHS_Records_Office", "Office", { "filing student records", "printing certificates" }, { "Requesting a certificate?", "Senior High records here!" }),
	-- Academic heads
	seated(office("Dean's Office Secretary", "Office of the College Deans", "CollegeDeans_Office", "Office", { "receiving visitors", "filing clearances", "scheduling appointments with the deans" }, { "The deans' cubicles are in the next room.", "Please write your name in the visitor log.", "Do you have an appointment with your dean?" }), "Inside.Reception.StaffChair.Seat"),
	seated(office("SVP for External Affairs", "Office of the SVP for External Affairs", "CollegeDeans_Office", "Faculty", { "meeting partner schools", "planning community programs" }, { "Samar College works with many partners!", "Join our community outreach!" }), "Inside.SVP_ExternalAffairsOffice.SVPChair.Seat"),
	office("Program Chairperson", "College Programs Office", "CollegeDeans_CoursesOffice", "Faculty", { "advising students", "planning subjects" }, { "Need help with your subjects?", "Choose your electives wisely." }),
	-- the college deans: each one sits at the desk in their own cubicle (Deans' office) and turns their
	-- "DEAN IS IN / OUT" sign on while they're there. Seat / Status = path inside the room model.
	dean("COED", "College of Education", { "Teachers shape the future!", "Practice teaching starts soon — prepare your lesson plans." }),
	dean("COCJE", "College of Criminal Justice Education", { "Discipline and integrity, always.", "Study for the board exam early!" }),
	dean("CBM", "College of Business and Management", { "Business is about people!", "Have you started your feasibility study?" }),
	dean("CITAS", "College of Information Technology and Allied Sciences", { "Code a little every day!", "Your capstone project is your best portfolio." }),
	dean("SCTI", "Samar College Technical Institute", { "Skills get you hired!", "Ready for your TESDA assessment?" }),
	office("Dean of Graduate Studies", "Graduate Studies Office", "GraduateStudiesOffice", "Faculty", { "reviewing theses", "meeting graduate students" }, { "Thinking about a master's degree?", "Research is the key!" }),
	office("Elementary Principal", "Elementary Department", "PrincipalOffice_Elementary", "Faculty", { "observing classes", "signing report cards" }, { "Be kind to the little ones!", "Good day, iho / iha!" }),
	office("JHS Principal", "Junior High School Department", "JHS_PrincipalOffice", "Faculty", { "checking lesson plans", "meeting parents" }, { "Junior High students, behave ha!", "Study hard and play fair." }),
	office("SHS Principal", "Senior High School Department", "SHS_PrincipalOffice", "Faculty", { "reviewing strands", "meeting teachers" }, { "Which strand are you in?", "Prepare well for college!" }),
	-- Student services
	office("OSAS Director", "Office of Student Affairs & Services", "OSAS_Office", "Office", { "approving student activities", "checking club permits" }, { "Join a club, it's fun!", "Need a permit for your event?" }),
	office("Prefect of Discipline", "Office of the Prefect of Discipline", "PrefectOfDiscipline_Office", "Office", { "checking uniforms", "reviewing incident reports" }, { "Wear your ID properly!", "Follow the rules, okay?", "No cutting classes!" }),
	office("Guidance Counselor", "Guidance & Counseling Office", "Guidance_Counseling_Office", "Office", { "talking with a student", "preparing career talks" }, { "I'm here if you need someone to talk to.", "You're doing great, keep going!" }),
	office("Research Coordinator", "IRISE Office", "IRISE_Office", "Office", { "reviewing research papers", "planning a research forum" }, { "Got a research idea?", "Innovation starts with a question!" }),
	office("Assessment Officer", "SCTI Assessment Center", "SCTI_AssessmentCenter", "Office", { "scheduling assessments", "checking exam results" }, { "Ready for your assessment?", "Good luck on your exam!" }),
	office("Photo ID Staff", "Photo ID Studio", "PhotoID_Studio", "Office", { "taking ID photos", "printing IDs" }, { "Smile for your ID photo!", "Your ID will be ready tomorrow." }),
	office("Sports Coordinator", "Tertiary Sports Office", "TertiarySportsOffice", "Office", { "planning intramurals", "checking sports equipment" }, { "Join the varsity team!", "Intramurals are coming!" }),
	office("ROTC Commandant", "ROTC Office", "ROTC_Office", "Guard", { "reviewing cadet records", "planning drills" }, { "Attention, cadet!", "Discipline is everything." }),
	office("GAD Focal Person", "Gender and Development Office", "GAD_Office", "Office", { "preparing GAD programs", "organizing seminars" }, { "Respect everyone, always.", "Join our GAD seminar!" }),
	office("SSLG Adviser", "Supreme Secondary Learner Government", "SSLG_Office", "Faculty", { "meeting student leaders", "planning projects" }, { "Leaders serve others!", "Got a suggestion for SSLG?" }),
	office("SSC President", "Supreme Student Council", "SSC_Office", "College", { "planning student events", "holding a council meeting" }, { "Vote wisely next election!", "The SSC is here for you!" }),
	office("Maintenance Supervisor", "Facilities & Maintenance", "StaffRoom_Janitor", "Janitor", { "fixing a broken chair", "checking supplies" }, { "Report broken things to us!", "Keep our campus clean." }),
	-- Libraries
	office("Librarian", "Main Library", "Library", "Librarian", { "shelving books", "assisting readers" }, { "Shhh… quiet please.", "Looking for a book?" }),
	office("College Librarian", "College Library", "CollegeLibrary", "Librarian", { "cataloging books", "checking out books" }, { "Return your books on time!", "Research materials are over there." }),
	office("Graduate Studies Librarian", "Graduate Studies Library", "GraduateStudiesLibrary", "Librarian", { "organizing theses", "assisting researchers" }, { "Theses are on that shelf.", "Quiet zone, please." }),
	office("BSIT & BSCRIM Librarian", "BSIT & BSCRIM Library", "Library_BSIT_BSCRIM", "Librarian", { "lending laptops", "shelving IT books" }, { "Need a programming book?", "Criminology references are here." }),
}
for _, e in ipairs(C.OrgChart) do table.insert(C.Staff, e) end

-- faculty: one per faculty room; they stay in (or around) their faculty room
C.Faculty = {
	{ Room = "College_FacultyRoom",        Level = "College",     Department = "College Faculty",            Role = "Instructor", Subject = "General Education" },
	{ Room = "CollegeFacultyRoom",         Level = "College",     Department = "BSIT Department",            Role = "Instructor", Subject = "Programming" },
	{ Room = "Criminology_FacultyOffice",  Level = "College",     Department = "BSCRIM Department",          Role = "Instructor", Subject = "Criminal Law" },
	{ Room = "JHS_FacultyRoom",            Level = "Junior High", Department = "Junior High Department",     Role = "Teacher",    Subject = "Mathematics" },
	{ Room = "SHS_Faculty_Room",           Level = "Senior High", Department = "Senior High Department",     Role = "Teacher",    Subject = "Oral Communication" },
}

-- standby / short patrol settings
C.PatrolRadius = 9          -- studs an NPC may walk away from its spot (indoors)
C.PatrolRadiusOutdoor = 16  -- guards / janitor
C.WakeDistance = 140        -- NPCs farther than this from every player freeze (saves performance)

-- where the 6 students stay: their own classroom, the canteen, or the lobby
C.StudentPlaces = { "Classroom", "Canteen", "Registrar_Cashier_Lobby", "Classroom", "Canteen", "Registrar_Cashier_Lobby" }

return C
