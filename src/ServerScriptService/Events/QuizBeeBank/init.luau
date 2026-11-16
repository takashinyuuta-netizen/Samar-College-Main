--[[ QuizBeeBank ─────────────────────────────────────────────────────────────
  Questions for the QUIZ BEE event (NOT the grade-progression quiz).
  SERVER ONLY (lives in ServerScriptService) so players can never read answers.

  Layout:  Bank[Department][Course][GradeLevel] = { questions }
    Department  = "Elementary" | "High School" | "College"   (room attribute Department)
    Course      = "Elementary", "Junior High", "STEM", "HUMSS", "GAS", "ABM", "TVL-ICT",
                  "BSIT", "BSCRIM", "BSEd" ...                 (room attribute Course)
    GradeLevel  = a name from LevelConfig: "Grade 9", "1st Year" ... (room attribute GradeLevel)

  Each question:  { Q = "question", O = { "A", "B", "C", "D" }, A = index of the right option }

  If a level has fewer questions than a round needs, the Quiz Bee fills up with
  Bank[Department].General[GradeLevel], then the level quiz (ServerScriptService.QuizBank).
  ➜ To add questions just add more lines in the right place. Placeholders are marked.
───────────────────────────────────────────────────────────────────────────]]
local Bank = {}

---------------------------------------------------------------- ELEMENTARY (Elementary server only)
Bank["Elementary"] = {
	["Elementary"] = {
		["Kindergarten"] = {
			{ Q = "How many legs does a cat have?", O = { "2", "4", "6", "8" }, A = 2 },
			{ Q = "Which color do you get by mixing blue and yellow?", O = { "Green", "Red", "Purple", "Orange" }, A = 1 },
			{ Q = "Which one is a fruit?", O = { "Carrot", "Mango", "Rice", "Egg" }, A = 2 },
			{ Q = "What shape has 3 sides?", O = { "Circle", "Square", "Triangle", "Star" }, A = 3 },
		},
		["Grade 1"] = {
			{ Q = "5 + 3 = ?", O = { "7", "8", "9", "6" }, A = 2 },
			{ Q = "Which is a living thing?", O = { "Stone", "Chair", "Tree", "Pencil" }, A = 3 },
			{ Q = "What letter comes after M?", O = { "L", "N", "O", "K" }, A = 2 },
			{ Q = "How many days are in a week?", O = { "5", "6", "7", "8" }, A = 3 },
		},
		["Grade 2"] = {
			{ Q = "12 − 5 = ?", O = { "6", "7", "8", "5" }, A = 2 },
			{ Q = "What do plants need to make food?", O = { "Sunlight", "Sand", "Plastic", "Salt" }, A = 1 },
			{ Q = "Which word is a noun?", O = { "Run", "Happy", "School", "Quickly" }, A = 3 },
			{ Q = "What is the capital of the Philippines?", O = { "Cebu", "Manila", "Davao", "Tacloban" }, A = 2 },
		},
		["Grade 3"] = {
			{ Q = "6 × 4 = ?", O = { "24", "20", "28", "18" }, A = 1 },
			{ Q = "Which planet do we live on?", O = { "Mars", "Venus", "Earth", "Jupiter" }, A = 3 },
			{ Q = "What is the plural of 'child'?", O = { "Childs", "Children", "Childes", "Childrens" }, A = 2 },
			{ Q = "Samar is part of which region?", O = { "Region VIII (Eastern Visayas)", "Region VII", "NCR", "Region XI" }, A = 1 },
		},
		["Grade 4"] = {
			{ Q = "What is 1/2 of 18?", O = { "6", "8", "9", "12" }, A = 3 },
			{ Q = "Water turning into vapor is called…", O = { "Condensation", "Evaporation", "Freezing", "Melting" }, A = 2 },
			{ Q = "Who is the national hero of the Philippines?", O = { "Andres Bonifacio", "José Rizal", "Emilio Aguinaldo", "Apolinario Mabini" }, A = 2 },
			{ Q = "Which is a complete sentence?", O = { "The big dog.", "Running fast.", "The dog barks.", "Under the table." }, A = 3 },
		},
		["Grade 5"] = {
			{ Q = "0.5 is equal to what percent?", O = { "5%", "50%", "0.5%", "500%" }, A = 2 },
			{ Q = "Which organ pumps blood around the body?", O = { "Lungs", "Brain", "Heart", "Liver" }, A = 3 },
			{ Q = "The Philippines has how many main island groups?", O = { "2", "3", "4", "7" }, A = 2 },
			{ Q = "What is the synonym of 'happy'?", O = { "Sad", "Joyful", "Angry", "Tired" }, A = 2 },
		},
		["Grade 6"] = {
			{ Q = "What is the LCM of 4 and 6?", O = { "12", "24", "2", "10" }, A = 1 },
			{ Q = "Which layer of the Earth do we live on?", O = { "Mantle", "Outer core", "Crust", "Inner core" }, A = 3 },
			{ Q = "The 1896 revolution against Spain was led by the…", O = { "Katipunan", "Propaganda Movement", "KKK Party", "Sakdalistas" }, A = 1 },
			{ Q = "Which is an example of a simple machine?", O = { "Lever", "Computer", "Car", "Television" }, A = 1 },
		},
	},
}

---------------------------------------------------------------- HIGH SCHOOL
Bank["High School"] = {
	["Junior High"] = {
		["Grade 7"] = {
			{ Q = "What is the smallest unit of life?", O = { "Atom", "Cell", "Tissue", "Organ" }, A = 2 },
			{ Q = "Solve: 3x = 21. x = ?", O = { "6", "7", "8", "9" }, A = 2 },
			{ Q = "A mixture with a uniform composition is called…", O = { "Heterogeneous", "Homogeneous", "Compound", "Element" }, A = 2 },
			{ Q = "Ibong Adarna is an example of a…", O = { "Korido", "Tula", "Dula", "Alamat" }, A = 1 },
			{ Q = "Which is an integer?", O = { "−4", "0.5", "3/4", "√2" }, A = 1 },
		},
		["Grade 8"] = {
			{ Q = "Which organ system breaks down food into nutrients?", O = { "Digestive", "Respiratory", "Nervous", "Skeletal" }, A = 1 },
			{ Q = "Factor x² − 9.", O = { "(x−3)(x+3)", "(x−9)(x+1)", "(x+3)²", "(x−3)²" }, A = 1 },
			{ Q = "Which part of a story introduces the characters and setting?", O = { "Climax", "Exposition", "Falling action", "Resolution" }, A = 2 },
			{ Q = "Newton's 1st Law is also called the Law of…", O = { "Acceleration", "Inertia", "Interaction", "Gravity" }, A = 2 },
			{ Q = "Florante at Laura was written by…", O = { "José Rizal", "Francisco Balagtas", "Lope K. Santos", "Amado Hernandez" }, A = 2 },
		},
		["Grade 9"] = {
			{ Q = "Work is equal to force times…", O = { "Time", "Mass", "Displacement", "Speed" }, A = 3 },
			{ Q = "The roots of x² − 5x + 6 = 0 are…", O = { "2 and 3", "−2 and −3", "1 and 6", "−1 and 6" }, A = 1 },
			{ Q = "Noli Me Tangere was first published in…", O = { "1887", "1891", "1896", "1898" }, A = 1 },
			{ Q = "Which gas do plants take in for photosynthesis?", O = { "Oxygen", "Nitrogen", "Carbon dioxide", "Hydrogen" }, A = 3 },
			{ Q = "The brightest star in Orion is usually…", O = { "Sirius", "Rigel", "Polaris", "Vega" }, A = 2 },
		},
		["Grade 10"] = {
			{ Q = "The theory that Earth's crust is made of moving plates is…", O = { "Big Bang", "Plate Tectonics", "Evolution", "Relativity" }, A = 2 },
			{ Q = "What is the next term: 2, 6, 18, 54, …?", O = { "108", "162", "72", "216" }, A = 2 },
			{ Q = "El Filibusterismo was dedicated to the…", O = { "Katipunan", "GOMBURZA", "Filipino youth", "Spanish friars" }, A = 2 },
			{ Q = "DNA stands for…", O = { "Deoxyribonucleic acid", "Dinucleic acid", "Deoxyribose amino", "Double nucleic acid" }, A = 1 },
			{ Q = "The probability of tossing heads on a fair coin is…", O = { "1/4", "1/3", "1/2", "1" }, A = 3 },
		},
	},
	-- Senior High: one table per strand (placeholders — add your strand topics)
	["STEM"] = {
		["Grade 11"] = {
			{ Q = "[Gen. Math] f(x) = 2x + 1. f(3) = ?", O = { "5", "6", "7", "8" }, A = 3 },
			{ Q = "[Earth Sci] The layer of the atmosphere we live in is the…", O = { "Stratosphere", "Troposphere", "Mesosphere", "Thermosphere" }, A = 2 },
			{ Q = "[Pre-Calc] A circle's equation x² + y² = 25 has radius…", O = { "25", "5", "10", "√5" }, A = 2 },
			{ Q = "[Gen. Chem] The atomic number of Carbon is…", O = { "6", "12", "8", "14" }, A = 1 },
		},
		["Grade 12"] = {
			{ Q = "[Gen. Physics] The SI unit of force is the…", O = { "Joule", "Watt", "Newton", "Pascal" }, A = 3 },
			{ Q = "[Basic Calculus] d/dx (x³) = ?", O = { "x²", "3x²", "3x", "x³/3" }, A = 2 },
			{ Q = "[Gen. Biology] The powerhouse of the cell is the…", O = { "Nucleus", "Ribosome", "Mitochondrion", "Golgi body" }, A = 3 },
			{ Q = "[Gen. Chem] pH 7 means a solution is…", O = { "Acidic", "Neutral", "Basic", "Salty" }, A = 2 },
		},
	},
	["HUMSS"] = {
		["Grade 11"] = {
			{ Q = "[DIASS] Who is considered the father of sociology?", O = { "Karl Marx", "Auguste Comte", "Max Weber", "Émile Durkheim" }, A = 2 },
			{ Q = "[Creative Writing] A 14-line poem is a…", O = { "Haiku", "Sonnet", "Limerick", "Ode" }, A = 2 },
			{ Q = "[Phil. Politics] The Philippines has how many branches of government?", O = { "2", "3", "4", "5" }, A = 2 },
			{ Q = "[Trends] The study of past human societies through artifacts is…", O = { "Archaeology", "Geology", "Astronomy", "Botany" }, A = 1 },
		},
	},
	["GAS"] = {
		["Grade 11"] = {
			{ Q = "[Gen. Math] Simple interest formula is I = …", O = { "Prt", "P/rt", "P + r + t", "Pr/t" }, A = 1 },
			{ Q = "[Org. & Mgt] Planning, organizing, leading and … are management functions.", O = { "Selling", "Controlling", "Hiring", "Buying" }, A = 2 },
			{ Q = "[Oral Comm] The person who sends the message is the…", O = { "Receiver", "Sender", "Channel", "Feedback" }, A = 2 },
			{ Q = "[Earth & Life] Rocks formed from cooled magma are…", O = { "Igneous", "Sedimentary", "Metamorphic", "Fossil" }, A = 1 },
		},
	},
	["ABM"] = {
		["Grade 12"] = {
			{ Q = "[FABM] Assets = Liabilities + …", O = { "Revenue", "Owner's Equity", "Expenses", "Cash" }, A = 2 },
			{ Q = "[Business Math] 20% of ₱500 is…", O = { "₱50", "₱100", "₱120", "₱200" }, A = 2 },
			{ Q = "[Marketing] The 4 P's: Product, Price, Place and…", O = { "People", "Promotion", "Profit", "Plan" }, A = 2 },
			{ Q = "[Economics] When supply goes up and demand stays the same, price usually…", O = { "Goes up", "Goes down", "Stays the same", "Doubles" }, A = 2 },
		},
	},
	["TVL-ICT"] = {
		["Grade 12"] = {
			{ Q = "[CSS] RAM is a type of…", O = { "Storage", "Memory", "Processor", "Port" }, A = 2 },
			{ Q = "[Programming] Which symbol ends a statement in Java?", O = { ".", ";", ":", "," }, A = 2 },
			{ Q = "[CSS] What does LAN mean?", O = { "Large Area Network", "Local Area Network", "Long Access Node", "Light Area Net" }, A = 2 },
			{ Q = "[Animation] FPS stands for…", O = { "Frames per second", "Files per screen", "Fast picture size", "Frame pixel scale" }, A = 1 },
		},
	},
	-- used to top up any Senior High round
	["General"] = {
		["Grade 11"] = {
			{ Q = "[Oral Comm] Communication that uses no words is…", O = { "Verbal", "Non-verbal", "Written", "Formal" }, A = 2 },
			{ Q = "[Gen. Math] A function assigns each input to … output(s).", O = { "exactly one", "two", "many", "zero" }, A = 1 },
			{ Q = "[PE & Health] Which is a cardiovascular exercise?", O = { "Jogging", "Stretching", "Sleeping", "Reading" }, A = 1 },
		},
		["Grade 12"] = {
			{ Q = "[Research] A tentative answer to a research problem is a…", O = { "Conclusion", "Hypothesis", "Variable", "Sample" }, A = 2 },
			{ Q = "[Media Literacy] Checking if news is true is called…", O = { "Fact-checking", "Editing", "Posting", "Trending" }, A = 1 },
			{ Q = "[Entrepreneurship] A written plan for a new business is a…", O = { "Resume", "Business plan", "Receipt", "Memo" }, A = 2 },
		},
	},
}

---------------------------------------------------------------- COLLEGE (placeholders per course & year)
Bank["College"] = {
	["BSIT"] = {
		["1st Year"] = {
			{ Q = "[Intro to Computing] The brain of the computer is the…", O = { "RAM", "CPU", "SSD", "GPU" }, A = 2 },
			{ Q = "[Programming 1] A variable that holds true/false is a…", O = { "String", "Boolean", "Integer", "Float" }, A = 2 },
			{ Q = "[Programming 1] Which loop always runs at least once?", O = { "for", "while", "do-while", "foreach" }, A = 3 },
			{ Q = "[Intro to Computing] 1 byte = … bits", O = { "4", "8", "16", "1024" }, A = 2 },
		},
		["2nd Year"] = {
			{ Q = "[Data Structures] A FIFO structure is a…", O = { "Stack", "Queue", "Tree", "Graph" }, A = 2 },
			{ Q = "[Database] SQL command to get rows from a table:", O = { "GET", "SELECT", "FETCH", "SHOW" }, A = 2 },
			{ Q = "[Networking] The default port of HTTP is…", O = { "21", "80", "443", "22" }, A = 2 },
			{ Q = "[OOP] Hiding internal details of a class is…", O = { "Inheritance", "Encapsulation", "Polymorphism", "Recursion" }, A = 2 },
		},
		["3rd Year"] = {
			{ Q = "[Web Dev] Which language styles a web page?", O = { "HTML", "CSS", "SQL", "PHP" }, A = 2 },
			{ Q = "[SAD] A diagram showing actors and their goals is a…", O = { "ERD", "Use Case Diagram", "Flowchart", "Gantt chart" }, A = 2 },
			{ Q = "[Info Assurance] CIA triad: Confidentiality, Integrity and…", O = { "Accuracy", "Availability", "Authority", "Access" }, A = 2 },
			{ Q = "[Database] A field that uniquely identifies a row is the…", O = { "Foreign key", "Primary key", "Index", "View" }, A = 2 },
		},
		["4th Year"] = {
			{ Q = "[Capstone] The chapter that reviews past studies is…", O = { "Introduction", "Review of Related Literature", "Results", "Recommendations" }, A = 2 },
			{ Q = "[SIA] Combining separate systems to work together is…", O = { "Integration", "Migration", "Compilation", "Encryption" }, A = 1 },
			{ Q = "[Project Mgmt] A chart that shows tasks over time is a…", O = { "Pie chart", "Gantt chart", "Scatter plot", "Venn diagram" }, A = 2 },
			{ Q = "[Capstone] ISO 25010 is a standard for software…", O = { "Quality", "Pricing", "Licensing", "Hosting" }, A = 1 },
		},
	},
	["BSCRIM"] = {
		["1st Year"] = {
			{ Q = "[Intro to Criminology] Criminology is the study of…", O = { "Crime", "Plants", "Weather", "Money" }, A = 1 },
			{ Q = "[Intro to Criminology] Who is called the father of modern criminology?", O = { "Cesare Lombroso", "Cesare Beccaria", "Sigmund Freud", "Robert Peel" }, A = 1 },
			{ Q = "[Law Enforcement] PNP stands for…", O = { "Philippine National Police", "People's National Patrol", "Public Nation Police", "Philippine Naval Patrol" }, A = 1 },
		},
		["3rd Year"] = {
			{ Q = "[Criminalistics] Study of fingerprints is…", O = { "Dactyloscopy", "Ballistics", "Toxicology", "Serology" }, A = 1 },
			{ Q = "[Criminal Law] The RPC means the Revised … Code", O = { "Public", "Penal", "Police", "Procedure" }, A = 2 },
			{ Q = "[Forensic Ballistics] Study of firearms and bullets is…", O = { "Ballistics", "Polygraphy", "Questioned documents", "Photography" }, A = 1 },
		},
		["4th Year"] = {
			{ Q = "[Board Review] The lie detector is also called a…", O = { "Polygraph", "Seismograph", "Barometer", "Spectrometer" }, A = 1 },
			{ Q = "[Criminal Procedure] Arrest without a warrant is allowed when the person is caught…", O = { "In flagrante delicto", "Sleeping", "At home", "Abroad" }, A = 1 },
			{ Q = "[Correctional Admin] BJMP manages…", O = { "City and municipal jails", "Highways", "Schools", "Ports" }, A = 1 },
		},
	},
	["BSEd"] = {
		["2nd Year"] = {
			{ Q = "[Child & Adolescent Dev.] Who proposed the stages of cognitive development?", O = { "Piaget", "Pavlov", "Skinner", "Freud" }, A = 1 },
			{ Q = "[Facilitating Learning] Learning by observing others is… learning", O = { "Social", "Rote", "Passive", "Classical" }, A = 1 },
			{ Q = "[Assessment] A test given before a lesson is a…", O = { "Pre-test", "Post-test", "Final exam", "Quiz bee" }, A = 1 },
		},
		["3rd Year"] = {
			{ Q = "[Curriculum] The K to 12 program added how many years?", O = { "1", "2", "3", "4" }, A = 2 },
			{ Q = "[Assessment] A rubric is used to…", O = { "Score performance", "Take attendance", "Grade spelling only", "Make lesson plans" }, A = 1 },
			{ Q = "[Teaching Strategies] Bloom's highest level (revised) is…", O = { "Remember", "Apply", "Create", "Analyze" }, A = 3 },
		},
	},
	["General"] = {
		["1st Year"] = {
			{ Q = "[GE] Purposive Communication mainly teaches…", O = { "Effective communication", "Accounting", "Programming", "Cooking" }, A = 1 },
			{ Q = "[GE] Readings in Philippine History studies… sources", O = { "Primary", "Fictional", "Foreign only", "Digital only" }, A = 1 },
		},
		["2nd Year"] = { { Q = "[GE] Ethics is the study of…", O = { "Right and wrong", "Numbers", "Rocks", "Stars" }, A = 1 } },
		["3rd Year"] = { { Q = "[GE] The Life and Works of Rizal course is required by RA…", O = { "1425", "9155", "10533", "7722" }, A = 1 } },
		["4th Year"] = { { Q = "[GE] OJT stands for…", O = { "On-the-Job Training", "Online Job Test", "Official Job Title", "Open Job Training" }, A = 1 } },
	},
}

---------------------------------------------------------------- BIG QUESTION PACKS (child ModuleScripts "Pack_*")
-- Each pack = 100+ questions for one course/strand, used for EVERY grade/year of that course:
--   Bank[Dept][Course].All = { questions }   (the Quiz Bee mixes them with the level questions above)
-- Pack format: { "question", "RIGHT answer", "wrong", "wrong", "wrong" } — options are shuffled in-game.
for _, mod in ipairs(script:GetChildren()) do
	if mod:IsA("ModuleScript") and mod.Name:match("^Pack_") then
		local ok, pack = pcall(require, mod)
		if ok and type(pack) == "table" and pack.Dept and pack.Course and type(pack.Q) == "table" then
			Bank[pack.Dept] = Bank[pack.Dept] or {}
			Bank[pack.Dept][pack.Course] = Bank[pack.Dept][pack.Course] or {}
			local all = Bank[pack.Dept][pack.Course].All or {}
			for _, row in ipairs(pack.Q) do
				if type(row) == "table" and #row == 5 then
					table.insert(all, { Q = row[1], O = { row[2], row[3], row[4], row[5] }, A = 1 })
				end
			end
			Bank[pack.Dept][pack.Course].All = all
		else
			warn("[QuizBeeBank] could not load " .. mod.Name .. ": " .. tostring(pack))
		end
	end
end

return Bank
