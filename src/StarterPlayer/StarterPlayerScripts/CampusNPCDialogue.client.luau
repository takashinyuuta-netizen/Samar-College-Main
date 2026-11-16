--[[ CampusNPCDialogue — every campus NPC (students, faculty, staff) talks with the
  "Grow a Garden / Fisch" dialogue template (ReplicatedStorage.DialogModule + StarterGui.dialog).
  • The NPC's words type out above its head; you answer with the numbered buttons (or keys 1-9).
  • What they say depends on their ROLE (info the server puts on the NPC as attributes).
  • Talking: "Talk" prompt on the NPC (tagged NPCprompt). ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local DialogModule = require(RS:WaitForChild("DialogModule"))
local Remotes = RS:WaitForChild("CampusLife"):WaitForChild("CampusLifeRemotes")
local C = require(RS.CampusLife:WaitForChild("CampusLifeConfig"))

local GOLD = "<font color='rgb(255,220,127)'>%s</font>"
local function hi(t) return GOLD:format(t) end
local function aOrAn(word) return (tostring(word):match("^[AEIOUaeiou]") and "an " or "a ") end
local function pick(t) return t[math.random(#t)] end
local function split(s) local out = {} for part in string.gmatch(s or "", "[^|]+") do table.insert(out, part) end return out end

local TIPS = {
	Student = { "Study a little every day — it really helps!", "Drink water and get enough sleep.", "Join a club, it's super fun!", "Ask the teacher if you don't understand." },
	Faculty = { "Read your lessons before class.", "Always be on time.", "Practice what you learned — that's how you remember.", "Never stop asking questions." },
	Staff = { "Always wear your school ID.", "Please keep the campus clean!", "Take care of school property.", "If you need help, just ask any staff." },
}
local BYE = { "Okay, take care!", "See you around!", "Ingat!", "Have a nice day!" }

-- the conversation for one NPC (from its attributes)
local function script_for(m)
	local kind = m:GetAttribute("NPCKind") or "Student"
	local role = m:GetAttribute("NPCRole") or "Student"
	local dept = m:GetAttribute("NPCDepartment") or "Samar College"
	if kind == "Student" then
		local grade, course, level = m:GetAttribute("NPCGrade") or "", m:GetAttribute("NPCCourse") or "", m:GetAttribute("NPCLevel") or ""
		local what = level == "College" and (grade .. " " .. course) or (grade ~= "" and grade or level)
		local subs = m:GetAttribute("NPCSubjects") or ""
		local room = m:GetAttribute("NPCRoom") or "my classroom"
		return {
			greet = ("Hi! I'm %s%s student here. What's up?"):format(aOrAn(what), hi(what)),
			again = "Anything else?",
			options = {
				{ "What do you study?", function() return subs ~= "" and ("Our subjects are " .. hi(subs) .. ".") or "Lots of subjects, hehe!" end },
				{ "Where's your classroom?", function() return ("My section room is %s."):format(hi(room)) end },
				{ "Any study tips?", function() return pick(TIPS.Student) end },
			},
		}
	elseif kind == "Faculty" then
		local subject = m:GetAttribute("NPCSubject") or "my subject"
		local froom = m:GetAttribute("NPCFacultyRoom") or "faculty room"
		return {
			greet = ("Good day! I'm %s%s of the %s."):format(aOrAn(role), hi(role), hi(dept)),
			again = "Anything else I can help with?",
			options = {
				{ "What do you teach?", function() return ("I teach %s. I hope you enjoy it!"):format(hi(subject)) end },
				{ "Where can I find you?", function() return ("When I'm not teaching, I'm at the %s."):format(hi(froom)) end },
				{ "Any advice?", function() return pick(TIPS.Faculty) end },
			},
		}
	else
		local acts = split(m:GetAttribute("NPCActivities"))
		local lines = split(m:GetAttribute("NPCLines"))
		local post = m:GetAttribute("NPCPost") or ""
		local code = role:match("^Dean, (.+)$")
		if code then
			-- a college dean (Deans' office cubicles)
			return {
				greet = ("Good day! I'm the %s of the %s (%s). How can I help you?"):format(hi("Dean"), hi(dept), code),
				again = "Anything else?",
				options = {
					{ "What does a dean do?", function() return ("I lead the %s — right now I'm %s."):format(hi(code), hi(acts[1] or "working")) end },
					{ "Can you sign my clearance?", function() return ("Bring your clearance slip to the %s counter, and I'll sign it."):format(hi("Dean's Office")) end },
					{ "Any advice?", function() return #lines > 0 and pick(lines) or pick(TIPS.Faculty) end },
				},
			}
		end
		return {
			greet = ("Hello! I'm the %s%s. Need anything?"):format(hi(role), post ~= "" and (" at the " .. post) or ""),
			again = "Anything else?",
			options = {
				{ "What do you do here?", function() return #acts > 0 and ("I'm in charge of %s, and more!"):format(hi(acts[1]:gsub("^%l", string.upper))) or ("I work for the " .. hi(dept) .. ".") end },
				{ "Any tips?", function() return (#lines > 0 and math.random() < 0.5) and pick(lines) or pick(TIPS.Staff) end },
			},
		}
	end
end

local made = {}
local pending = {}
local function setup(m)
	if made[m] or pending[m] or not m:IsA("Model") then return end
	pending[m] = true
	-- wait for the NPC's head label + Talk prompt to arrive (they can stream in a moment after the model)
	local head = m:WaitForChild("Head", 20)
	local gui = head and head:WaitForChild("gui", 20)
	local root = m:WaitForChild("HumanoidRootPart", 20)
	local prompt = root and root:WaitForChild("TalkPrompt", 20)
	pending[m] = nil
	if not (gui and prompt) or not m:IsDescendantOf(workspace) or made[m] then return end
	local data = script_for(m)
	local d = DialogModule.new(m.Name, m, prompt)
	-- the NPC streamed out / was removed: drop this talk so a fresh one is made when it comes back
	local function forget()
		if made[m] ~= d then return end
		made[m] = nil
		for _, c in ipairs(d.connections or {}) do pcall(function() c:Disconnect() end) end
	end
	m.AncestryChanged:Connect(function() if not m:IsDescendantOf(workspace) then forget() end end)
	head.AncestryChanged:Connect(function() if not head:IsDescendantOf(m) then forget() task.defer(function() if m:IsDescendantOf(workspace) then setup(m) end end) end end)
	local labels = {}
	for i, o in ipairs(data.options) do labels[i] = o[1] end
	table.insert(labels, "Nevermind")
	d:addDialog(data.greet, labels)      -- dialog 1: greeting
	d:addDialog(data.again, labels)      -- dialog 2: after an answer
	made[m] = d
	m:SetAttribute("DialogReady", true)

	prompt.Triggered:Connect(function(p)
		if p ~= player or d.active or d.talking then return end -- no double-start while already talking
		d:triggerDialog(player, 1)
	end)
	d.responded:Connect(function(choice)
		local opt = data.options[choice]
		if not opt then
			-- Nevermind: say bye and end the talk
			d:hideGui(pick(BYE))
			Remotes.NPCTalkClose:FireServer()
			return
		end
		-- answer, then offer the choices again
		d:hideGui(opt[2](), true)
		task.delay(1.6, function()
			if m:IsDescendantOf(workspace) then d:triggerDialog(player, 2) end
		end)
	end)
end

local function watch(folder)
	for _, m in ipairs(folder:GetChildren()) do task.spawn(setup, m) end
	folder.ChildAdded:Connect(function(m) task.spawn(setup, m) end)
end
local campus = workspace:WaitForChild("SamarCollege_Campus")
local npcs = campus:WaitForChild("CampusNPCs")
for _, n in ipairs({ "Students", "Faculty", "Staff" }) do watch(npcs:WaitForChild(n)) end
