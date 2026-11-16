-- ProfileClient: Samar College student profile, level/title picker and level-up quiz.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent
local LevelConfig = require(RS:WaitForChild("LevelConfig"))
local remotes = RS:WaitForChild("ProfileRemotes")

local C = {
	bg = Color3.fromRGB(24, 26, 34), card = Color3.fromRGB(34, 37, 48), card2 = Color3.fromRGB(42, 46, 60),
	stroke = Color3.fromRGB(70, 76, 98), text = Color3.fromRGB(240, 242, 248), dim = Color3.fromRGB(150, 156, 176),
	green = Color3.fromRGB(30, 130, 80), green2 = Color3.fromRGB(18, 90, 56), gold = Color3.fromRGB(242, 192, 64),
	locked = Color3.fromRGB(46, 49, 62), red = Color3.fromRGB(220, 80, 80),
}
local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = p return c end
local function stroke(p, col, t) local s = Instance.new("UIStroke") s.Color = col s.Thickness = t or 1.2 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = p return s end
local function label(parent, text, size, font, color, props)
	local l = Instance.new("TextLabel") l.BackgroundTransparency = 1 l.Text = text l.TextSize = size l.Font = font or Enum.Font.Gotham
	l.TextColor3 = color or C.text l.TextXAlignment = Enum.TextXAlignment.Left l.Size = UDim2.new(1, 0, 0, size + 6)
	for k, v in pairs(props or {}) do l[k] = v end l.Parent = parent return l
end

-- ===================== MAIN PANEL =====================
-- dark background covers the WHOLE screen (also the top bar, notch and rounded corners on phones)
pcall(function() gui.ClipToDeviceSafeArea = false end)
local dim = Instance.new("Frame") dim.Name = "Dim" dim.Position = UDim2.fromOffset(-400, -400) dim.Size = UDim2.new(1, 800, 1, 800)
dim.BorderSizePixel = 0 dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 0.45 dim.Visible = false dim.Parent = gui
local panel = Instance.new("Frame") panel.Name = "Panel" panel.AnchorPoint = Vector2.new(0.5, 0.5) panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(680, 560) panel.BackgroundColor3 = C.bg panel.Visible = false panel.Parent = gui
corner(panel, 18) stroke(panel, C.stroke, 1.4)
local pscale = Instance.new("UIScale") pscale.Parent = panel
-- fit any device: use the usable screen area (without the top bar / notch), not the raw viewport
local function rescale()
	local v = gui.AbsoluteSize
	if v.X < 2 then v = workspace.CurrentCamera.ViewportSize end
	pscale.Scale = math.clamp(math.min((v.X - 16) / 680, (v.Y - 12) / 560), 0.3, 1)
end
rescale() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)

-- header
local header = Instance.new("Frame") header.Name = "Header" header.Size = UDim2.new(1, 0, 0, 96) header.BackgroundColor3 = C.green header.Parent = panel
corner(header, 18)
local hg = Instance.new("UIGradient") hg.Color = ColorSequence.new(Color3.fromRGB(34, 140, 86), Color3.fromRGB(14, 70, 46)) hg.Rotation = 0 hg.Parent = header
local hfix = Instance.new("Frame") hfix.Size = UDim2.new(1, 0, 0, 18) hfix.Position = UDim2.new(0, 0, 1, -18) hfix.BorderSizePixel = 0 hfix.BackgroundColor3 = C.green hfix.Parent = header
local hg2 = hg:Clone() hg2.Parent = hfix
local goldLine = Instance.new("Frame") goldLine.Size = UDim2.new(1, 0, 0, 3) goldLine.Position = UDim2.new(0, 0, 1, 0) goldLine.BorderSizePixel = 0 goldLine.BackgroundColor3 = C.gold goldLine.Parent = header

local avatar = Instance.new("ImageLabel") avatar.Name = "Avatar" avatar.Size = UDim2.fromOffset(68, 68) avatar.Position = UDim2.fromOffset(18, 14)
avatar.BackgroundColor3 = C.green2 avatar.Image = "" avatar.Parent = header corner(avatar, 34) stroke(avatar, C.gold, 2.5)
task.spawn(function()
	local ok, img = pcall(function() return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
	if ok then avatar.Image = img end
end)
local nameL = label(header, player.DisplayName, 24, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(100, 16), Size = UDim2.new(1, -260, 0, 28) })
local userL = label(header, "@" .. player.Name, 12, Enum.Font.Gotham, Color3.fromRGB(200, 230, 210), { Position = UDim2.fromOffset(100, 44), Size = UDim2.new(1, -260, 0, 16) })
local subL = label(header, "", 15, Enum.Font.GothamBold, C.gold, { Position = UDim2.fromOffset(100, 62), Size = UDim2.new(1, -260, 0, 20) })

local crest = Instance.new("Frame") crest.Size = UDim2.fromOffset(120, 44) crest.AnchorPoint = Vector2.new(1, 0) crest.Position = UDim2.new(1, -58, 0, 26)
crest.BackgroundColor3 = C.green2 crest.Parent = header corner(crest, 10) stroke(crest, C.gold, 1.2)
local cc = Instance.new("TextLabel") cc.Size = UDim2.fromOffset(30, 30) cc.Position = UDim2.fromOffset(7, 7) cc.BackgroundColor3 = C.gold cc.Text = "SC"
cc.Font = Enum.Font.GothamBlack cc.TextSize = 13 cc.TextColor3 = C.green2 cc.Parent = crest corner(cc, 15)
label(crest, "SAMAR\nCOLLEGE", 11, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(44, 5), Size = UDim2.fromOffset(72, 34), TextYAlignment = Enum.TextYAlignment.Center, LineHeight = 0.95 })

local close = Instance.new("TextButton") close.Name = "Close" close.AnchorPoint = Vector2.new(1, 0) close.Position = UDim2.new(1, -12, 0, 12)
close.Size = UDim2.fromOffset(34, 34) close.BackgroundColor3 = C.green2 close.Text = "X" close.Font = Enum.Font.GothamBold close.TextSize = 16
close.TextColor3 = C.text close.Parent = header corner(close, 17)

-- scrolling body
local body = Instance.new("ScrollingFrame") body.Name = "Body" body.Position = UDim2.fromOffset(0, 104) body.Size = UDim2.new(1, 0, 1, -110)
body.BackgroundTransparency = 1 body.BorderSizePixel = 0 body.ScrollBarThickness = 5 body.ScrollBarImageColor3 = C.stroke
body.AutomaticCanvasSize = Enum.AutomaticSize.Y body.CanvasSize = UDim2.new() body.Parent = panel
local bpad = Instance.new("UIPadding") bpad.PaddingLeft = UDim.new(0, 18) bpad.PaddingRight = UDim.new(0, 18) bpad.PaddingTop = UDim.new(0, 10) bpad.PaddingBottom = UDim.new(0, 16) bpad.Parent = body
local blay = Instance.new("UIListLayout") blay.Padding = UDim.new(0, 8) blay.SortOrder = Enum.SortOrder.LayoutOrder blay.Parent = body
local order = 0
local function nextOrder() order += 1 return order end
local function section(text) local l = label(body, text, 14, Enum.Font.GothamBold, C.dim) l.LayoutOrder = nextOrder() return l end

-- ⭐ EVENT LEVEL card (XP only from events)
local XPC = require(RS:WaitForChild("Events"):WaitForChild("XPConfig"))
section("⭐  EVENT LEVEL  —  earn XP by joining campus events")
local lvCard = Instance.new("Frame") lvCard.Name = "EventLevel" lvCard.Size = UDim2.new(1, 0, 0, 96) lvCard.BackgroundColor3 = C.card lvCard.LayoutOrder = nextOrder() lvCard.Parent = body
corner(lvCard, 12) local lvStroke = stroke(lvCard, C.gold, 1.4)
local lvBadge = Instance.new("TextLabel") lvBadge.Size = UDim2.fromOffset(70, 70) lvBadge.Position = UDim2.fromOffset(13, 13) lvBadge.BackgroundColor3 = C.gold
lvBadge.Font = Enum.Font.GothamBlack lvBadge.TextSize = 30 lvBadge.TextColor3 = Color3.fromRGB(30, 30, 30) lvBadge.Text = "1" lvBadge.Parent = lvCard corner(lvBadge, 35)
local lvBadgeStroke = stroke(lvBadge, Color3.new(1, 1, 1), 3)
local lvTitle = label(lvCard, "Event Level 1", 18, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(96, 12), Size = UDim2.new(1, -110, 0, 22) })
local lvTier = label(lvCard, "", 12, Enum.Font.GothamBold, C.gold, { Position = UDim2.fromOffset(96, 36), Size = UDim2.new(1, -110, 0, 16) })
local lvBg = Instance.new("Frame") lvBg.Position = UDim2.fromOffset(96, 58) lvBg.Size = UDim2.new(1, -112, 0, 14) lvBg.BackgroundColor3 = C.locked lvBg.Parent = lvCard corner(lvBg, 7)
local lvFill = Instance.new("Frame") lvFill.Size = UDim2.fromScale(0, 1) lvFill.BackgroundColor3 = C.gold lvFill.Parent = lvBg corner(lvFill, 7)
local lvXP = label(lvCard, "", 11, Enum.Font.GothamBold, C.dim, { Position = UDim2.fromOffset(96, 74), Size = UDim2.new(1, -112, 0, 16) })
local function refreshLevel()
	local total = player:GetAttribute("XP") or 0
	local lvl, into, need = XPC.fromXP(total)
	local tier = XPC.tierOf(lvl)
	lvBadge.Text = (lvl >= XPC.MAX_LEVEL) and "👑" or tostring(lvl)
	lvBadge.BackgroundColor3 = tier.color lvStroke.Color = tier.color lvFill.BackgroundColor3 = tier.color lvTier.TextColor3 = tier.color
	lvTitle.Text = "Event Level " .. lvl .. "  /  " .. XPC.MAX_LEVEL
	local nextM
	for _, m in ipairs(XPC.Milestones) do if m.level > lvl then nextM = m break end end
	lvTier.Text = tier.name .. " tier" .. (nextM and ("   •   Next reward: " .. nextM.icon .. " " .. nextM.name .. " at Lv " .. nextM.level) or "   •   All level rewards unlocked!")
	if need == 0 then lvFill.Size = UDim2.fromScale(1, 1) lvXP.Text = string.format("MAX LEVEL  •  %d total XP", total)
	else lvFill.Size = UDim2.fromScale(into / need, 1) lvXP.Text = string.format("%d / %d XP to Level %d   •   %d total XP", into, need, lvl + 1, total) end
end
player:GetAttributeChangedSignal("XP"):Connect(refreshLevel)

section("🎓  SCHOOL LEVEL  —  tap an unlocked level to wear its title")
local chips = {}
for d, dept in ipairs(LevelConfig.Departments) do
	local dl = label(body, dept.Name, 13, Enum.Font.GothamBold, dept.Color) dl.LayoutOrder = nextOrder()
	local row = Instance.new("Frame") row.BackgroundTransparency = 1 row.Size = UDim2.new(1, 0, 0, 0) row.AutomaticSize = Enum.AutomaticSize.Y row.LayoutOrder = nextOrder() row.Parent = body
	local grid = Instance.new("UIGridLayout") grid.CellSize = UDim2.fromOffset(98, 32) grid.CellPadding = UDim2.fromOffset(7, 7) grid.SortOrder = Enum.SortOrder.LayoutOrder grid.Parent = row
	for i, lvl in ipairs(LevelConfig.Levels) do
		if lvl.Dept == d then
			local b = Instance.new("TextButton") b.Name = lvl.Name b.LayoutOrder = i b.AutoButtonColor = false b.Font = Enum.Font.GothamBold b.TextSize = 13
			b.Text = lvl.Name b.Parent = row corner(b, 9)
			local st = stroke(b, C.stroke, 1.2)
			chips[i] = { button = b, stroke = st, dept = dept }
		end
	end
end
local selectedL = label(body, "", 13, Enum.Font.GothamBold, C.text) selectedL.LayoutOrder = nextOrder()

-- 🎓 COURSE / STRAND (Samar College programs) — shown in the title
section("🎓  COURSE / STRAND  —  your Samar College program shows in your title")
local progChips = {}
local progInfo = {}
for _, group in ipairs({ "College", "SHS" }) do
	local g = LevelConfig.Programs[group]
	local hl = label(body, "", 13, Enum.Font.GothamBold, group == "College" and LevelConfig.Departments[3].Color or LevelConfig.Departments[2].Color) hl.LayoutOrder = nextOrder()
	progInfo[group] = hl
	local row = Instance.new("Frame") row.BackgroundTransparency = 1 row.Size = UDim2.new(1, 0, 0, 0) row.AutomaticSize = Enum.AutomaticSize.Y row.LayoutOrder = nextOrder() row.Parent = body
	local grid = Instance.new("UIGridLayout") grid.CellSize = UDim2.fromOffset(112, 32) grid.CellPadding = UDim2.fromOffset(7, 7) grid.SortOrder = Enum.SortOrder.LayoutOrder grid.Parent = row
	progChips[group] = {}
	for i, p in ipairs(g.List) do
		local b = Instance.new("TextButton") b.Name = p.Id b.LayoutOrder = i b.AutoButtonColor = false b.Font = Enum.Font.GothamBold b.TextSize = 13 b.Text = p.Id b.Parent = row corner(b, 9)
		local st = stroke(b, C.stroke, 1.2)
		progChips[group][i] = { button = b, stroke = st, prog = p }
		b.MouseButton1Click:Connect(function()
			if (player:GetAttribute("LevelUnlocked") or 1) < g.MinLevel then
				b.Text = "🔒 " .. LevelConfig.name(g.MinLevel) task.delay(1, function() b.Text = p.Id end)
				return
			end
			local cur = player:GetAttribute(g.Attr) or 0
			remotes.SelectProgram:FireServer(group, cur == i and 0 or i) -- tap the chosen one again to remove it
		end)
	end
end
-- 🎭 ROLEPLAY — student, teacher, instructor, employee or campus staff
local RP = require(RS:WaitForChild("RoleplayConfig"))
section("🎭  ROLEPLAY  —  be a student, teacher, instructor, employee or campus staff")
local rpDesc = label(body, "", 13, Enum.Font.GothamBold, C.text) rpDesc.LayoutOrder = nextOrder()
local rpRoleRow = Instance.new("Frame") rpRoleRow.BackgroundTransparency = 1 rpRoleRow.Size = UDim2.new(1, 0, 0, 0) rpRoleRow.AutomaticSize = Enum.AutomaticSize.Y rpRoleRow.LayoutOrder = nextOrder() rpRoleRow.Parent = body
local rgrid = Instance.new("UIGridLayout") rgrid.CellSize = UDim2.fromOffset(118, 38) rgrid.CellPadding = UDim2.fromOffset(7, 7) rgrid.SortOrder = Enum.SortOrder.LayoutOrder rgrid.Parent = rpRoleRow
local rpRoleChips = {}
for i, r in ipairs(RP.Roles) do
	local b = Instance.new("TextButton") b.Name = r.Id b.LayoutOrder = i b.AutoButtonColor = false b.Font = Enum.Font.GothamBlack b.TextSize = 14 b.Text = r.Icon .. " " .. r.Name b.Parent = rpRoleRow corner(b, 10)
	local st = stroke(b, r.Color, 1.2)
	rpRoleChips[i] = { button = b, stroke = st, role = r }
	b.MouseButton1Click:Connect(function() remotes.SelectRoleplay:FireServer("role", i) end)
end
local rpRows = {}
for row = 1, 3 do
	local hl = label(body, "", 13, Enum.Font.GothamBold, C.gold) hl.LayoutOrder = nextOrder() hl.Visible = false
	local f = Instance.new("Frame") f.BackgroundTransparency = 1 f.Size = UDim2.new(1, 0, 0, 0) f.AutomaticSize = Enum.AutomaticSize.Y f.LayoutOrder = nextOrder() f.Visible = false f.Parent = body
	local g = Instance.new("UIGridLayout") g.CellSize = UDim2.fromOffset(118, 32) g.CellPadding = UDim2.fromOffset(6, 6) g.SortOrder = Enum.SortOrder.LayoutOrder g.Parent = f
	rpRows[row] = { head = hl, frame = f, chips = {}, builtFor = nil }
end
local function refreshRoleplay()
	local ri = player:GetAttribute("RP_Role") or 1
	if ri < 1 then ri = 1 end
	local role = RP.role(ri)
	for i, c in ipairs(rpRoleChips) do
		local on = i == ri
		c.button.BackgroundColor3 = on and c.role.Color or c.role.Color:Lerp(C.card, 0.6)
		c.button.TextColor3 = Color3.new(1, 1, 1)
		c.stroke.Color = on and C.gold or c.role.Color c.stroke.Thickness = on and 2.4 or 1.2
	end
	local t = RP.titleFor(ri, player:GetAttribute("RP_1"), player:GetAttribute("RP_2"), player:GetAttribute("RP_3"))
	rpDesc.Text = role.Icon .. " " .. role.Name .. "  —  " .. role.Desc .. (t and ("   Title: " .. t) or "")
	for row, R in ipairs(rpRows) do
		local opt = role.Options[row]
		R.head.Visible = opt ~= nil R.frame.Visible = opt ~= nil
		if opt then
			if R.builtFor ~= role.Id then
				for _, c in ipairs(R.chips) do c.button:Destroy() end
				R.chips = {}
				for i, name in ipairs(opt.List) do
					local b = Instance.new("TextButton") b.LayoutOrder = i b.AutoButtonColor = false b.Font = Enum.Font.GothamBold b.TextScaled = true b.Text = name b.Parent = R.frame corner(b, 9)
					local tc = Instance.new("UITextSizeConstraint") tc.MaxTextSize = 13 tc.Parent = b
					local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 4) pad.PaddingRight = UDim.new(0, 4) pad.Parent = b
					local st = stroke(b, C.stroke, 1.2)
					R.chips[i] = { button = b, stroke = st }
					b.MouseButton1Click:Connect(function() remotes.SelectRoleplay:FireServer("opt" .. row, i) end)
				end
				R.builtFor = role.Id
			end
			local cur = player:GetAttribute("RP_" .. row) or 1
			R.head.Text = opt.Label .. ":  " .. (opt.List[math.clamp(cur, 1, #opt.List)] or "")
			for i, c in ipairs(R.chips) do
				local on = i == cur
				c.button.BackgroundColor3 = on and role.Color or C.card
				c.button.TextColor3 = on and Color3.new(1, 1, 1) or C.text
				c.stroke.Color = on and C.gold or C.stroke c.stroke.Thickness = on and 2 or 1
			end
		end
	end
end

local function refreshPrograms()
	refreshRoleplay()
	local unlocked = player:GetAttribute("LevelUnlocked") or 1
	for group, list in pairs(progChips) do
		local g = LevelConfig.Programs[group]
		local cur = player:GetAttribute(g.Attr) or 0
		local open = unlocked >= g.MinLevel
		local p = g.List[cur]
		progInfo[group].Text = (group == "College" and "College course" or "Senior High strand") .. (open and (p and ("  —  " .. p.Name) or "  —  tap one to choose") or ("  —  🔒 unlocks at " .. LevelConfig.name(g.MinLevel)))
		for i, c in ipairs(list) do
			local b = c.button
			if not open then
				b.BackgroundColor3 = C.locked b.TextColor3 = C.dim b.Text = c.prog.Id c.stroke.Color = C.stroke c.stroke.Thickness = 1
			elseif i == cur then
				b.BackgroundColor3 = c.prog.Color b.TextColor3 = Color3.new(1, 1, 1) b.Text = "★ " .. c.prog.Id c.stroke.Color = C.gold c.stroke.Thickness = 2.2
			else
				b.BackgroundColor3 = c.prog.Color:Lerp(C.card, 0.55) b.TextColor3 = Color3.new(1, 1, 1) b.Text = c.prog.Id c.stroke.Color = c.prog.Color c.stroke.Thickness = 1.2
			end
		end
	end
end

-- next-level card
local nextCard = Instance.new("Frame") nextCard.Name = "NextLevel" nextCard.Size = UDim2.new(1, 0, 0, 92) nextCard.BackgroundColor3 = C.card nextCard.LayoutOrder = nextOrder() nextCard.Parent = body
corner(nextCard, 12) local nextStroke = stroke(nextCard, C.gold, 1.2)
local nextTitle = label(nextCard, "", 16, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -230, 0, 20) })
local nextInfo = label(nextCard, "", 12, Enum.Font.Gotham, C.dim, { Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -230, 0, 16), TextWrapped = true })
local barBg = Instance.new("Frame") barBg.Position = UDim2.fromOffset(14, 62) barBg.Size = UDim2.new(1, -240, 0, 12) barBg.BackgroundColor3 = C.locked barBg.Parent = nextCard corner(barBg, 6)
local barFill = Instance.new("Frame") barFill.Size = UDim2.fromScale(0, 1) barFill.BackgroundColor3 = C.gold barFill.Parent = barBg corner(barFill, 6)
local barText = label(nextCard, "", 11, Enum.Font.GothamBold, C.dim, { Position = UDim2.new(1, -222, 0, 59), Size = UDim2.fromOffset(60, 16) })
local quizBtn = Instance.new("TextButton") quizBtn.Name = "QuizButton" quizBtn.AnchorPoint = Vector2.new(1, 0.5) quizBtn.Position = UDim2.new(1, -14, 0.5, 0)
quizBtn.Size = UDim2.fromOffset(150, 46) quizBtn.Font = Enum.Font.GothamBlack quizBtn.TextSize = 14 quizBtn.TextWrapped = true quizBtn.Parent = nextCard corner(quizBtn, 12)

-- stats grid
section("📊  STUDENT RECORD")
local statsRow = Instance.new("Frame") statsRow.BackgroundTransparency = 1 statsRow.Size = UDim2.new(1, 0, 0, 0) statsRow.AutomaticSize = Enum.AutomaticSize.Y statsRow.LayoutOrder = nextOrder() statsRow.Parent = body
local sgrid = Instance.new("UIGridLayout") sgrid.CellSize = UDim2.new(1 / 3, -6, 0, 66) sgrid.CellPadding = UDim2.fromOffset(8, 8) sgrid.SortOrder = Enum.SortOrder.LayoutOrder sgrid.Parent = statsRow
local stats = {}
local function stat(key, title, icon, order2)
	local f = Instance.new("Frame") f.Name = key f.BackgroundColor3 = C.card f.LayoutOrder = order2 f.Parent = statsRow corner(f, 12) stroke(f, C.stroke, 1)
	label(f, icon .. "  " .. title, 12, Enum.Font.GothamBold, C.dim, { Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -20, 0, 16) })
	stats[key] = label(f, "0", 22, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -20, 0, 28) })
end
stat("Playtime", "Playtime", "⏱", 1) stat("Events", "Events joined", "🎪", 2) stat("Items", "Items owned", "🎒", 3)
stat("Event", "Event coins", "⭐", 4) stat("Common", "Common coins", "◎", 5) stat("Quizzes", "Quizzes passed", "📝", 6)

-- achievements
section("🏆  ACHIEVEMENTS")
local ACH = {
	{ "First Day", "Join Samar College", function(d) return true end },
	{ "Little Scholar", "Pass the Kindergarten quiz", function(d) return d.level >= 2 end },
	{ "Elementary Graduate", "Reach Grade 7", function(d) return d.level >= 8 end },
	{ "Senior High Ready", "Reach Grade 11", function(d) return d.level >= 12 end },
	{ "College Bound", "Reach 1st Year College", function(d) return d.level >= 14 end },
	{ "Samar College Graduate", "Reach 4th Year", function(d) return d.level >= 17 end },
	{ "Dedicated Student", "Play for 1 hour in total", function(d) return d.time >= 3600 end },
	{ "Campus Shopper", "Own 3 shop items", function(d) return d.items >= 3 end },
	{ "Event Goer", "Join 5 school events", function(d) return d.events >= 5 end },
}
-- ⭐ Event Level achievements
for _, m in ipairs(XPC.Milestones) do
	table.insert(ACH, { m.icon .. " " .. m.name, "Reach Event Level " .. m.level .. "  (+" .. m.coins .. " ⭐)", function(d) return d.lvl >= m.level end })
end
local achRows = {}
for i, a in ipairs(ACH) do
	local r = Instance.new("Frame") r.Size = UDim2.new(1, 0, 0, 40) r.BackgroundColor3 = C.card r.LayoutOrder = nextOrder() r.Parent = body corner(r, 10)
	local ic = label(r, "🏆", 18, Enum.Font.GothamBold, C.gold, { Position = UDim2.fromOffset(12, 7), Size = UDim2.fromOffset(26, 26) })
	local nm = label(r, a[1], 15, Enum.Font.GothamBold, C.text, { Position = UDim2.fromOffset(44, 10), Size = UDim2.new(0.5, 0, 0, 20) })
	local ds = label(r, a[2], 12, Enum.Font.Gotham, C.dim, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.new(0.5, -20, 0, 16), TextXAlignment = Enum.TextXAlignment.Right })
	achRows[i] = { frame = r, icon = ic, name = nm, desc = ds }
end

-- ===================== QUIZ OVERLAY =====================
local quiz = Instance.new("Frame") quiz.Name = "Quiz" quiz.AnchorPoint = Vector2.new(0.5, 0.5) quiz.Position = UDim2.fromScale(0.5, 0.52)
quiz.Size = UDim2.fromOffset(560, 400) quiz.BackgroundColor3 = C.bg quiz.Visible = false quiz.ZIndex = 50 quiz.Parent = gui
corner(quiz, 18) stroke(quiz, C.gold, 1.6)
local qscale = Instance.new("UIScale") qscale.Parent = quiz
local function rescaleQ() local v = workspace.CurrentCamera.ViewportSize v = Vector2.new(v.X, v.Y - game:GetService("GuiService"):GetGuiInset().Y) qscale.Scale = math.min(1, (v.X - 30) / 560, (v.Y - 20) / 400) end
rescaleQ() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescaleQ)
local qHead = Instance.new("Frame") qHead.Size = UDim2.new(1, 0, 0, 56) qHead.BackgroundColor3 = C.green qHead.ZIndex = 51 qHead.Parent = quiz corner(qHead, 18)
local qhfix = Instance.new("Frame") qhfix.Size = UDim2.new(1, 0, 0, 16) qhfix.Position = UDim2.new(0, 0, 1, -16) qhfix.BorderSizePixel = 0 qhfix.BackgroundColor3 = C.green qhfix.ZIndex = 51 qhfix.Parent = qHead
local qTitle = label(qHead, "", 18, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(18, 8), Size = UDim2.new(1, -120, 0, 22), ZIndex = 52 })
local qSub = label(qHead, "", 12, Enum.Font.Gotham, Color3.fromRGB(210, 240, 220), { Position = UDim2.fromOffset(18, 32), Size = UDim2.new(1, -120, 0, 16), ZIndex = 52 })
local qClose = close:Clone() qClose.ZIndex = 53 qClose.Position = UDim2.new(1, -12, 0, 11) qClose.Parent = qHead
local qProg = Instance.new("Frame") qProg.Position = UDim2.fromOffset(18, 68) qProg.Size = UDim2.new(1, -36, 0, 8) qProg.BackgroundColor3 = C.locked qProg.ZIndex = 51 qProg.Parent = quiz corner(qProg, 4)
local qFill = Instance.new("Frame") qFill.Size = UDim2.fromScale(0, 1) qFill.BackgroundColor3 = C.gold qFill.ZIndex = 52 qFill.Parent = qProg corner(qFill, 4)
local qText = label(quiz, "", 19, Enum.Font.GothamBold, C.text, { Position = UDim2.fromOffset(18, 88), Size = UDim2.new(1, -36, 0, 60), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 51 })
local optHolder = Instance.new("Frame") optHolder.BackgroundTransparency = 1 optHolder.Position = UDim2.fromOffset(18, 156) optHolder.Size = UDim2.new(1, -36, 0, 220) optHolder.ZIndex = 51 optHolder.Parent = quiz
local ogrid = Instance.new("UIGridLayout") ogrid.CellSize = UDim2.new(0.5, -6, 0, 100) ogrid.CellPadding = UDim2.fromOffset(12, 12) ogrid.SortOrder = Enum.SortOrder.LayoutOrder ogrid.Parent = optHolder
local optButtons = {}
local LETTERS = { "A", "B", "C", "D" }
for i = 1, 4 do
	local b = Instance.new("TextButton") b.LayoutOrder = i b.BackgroundColor3 = C.card b.AutoButtonColor = true b.Text = "" b.ZIndex = 52 b.Parent = optHolder corner(b, 12)
	local st = stroke(b, C.stroke, 1.4)
	local lt = Instance.new("TextLabel") lt.Size = UDim2.fromOffset(30, 30) lt.Position = UDim2.fromOffset(10, 10) lt.BackgroundColor3 = C.green lt.Text = LETTERS[i]
	lt.Font = Enum.Font.GothamBlack lt.TextSize = 14 lt.TextColor3 = C.text lt.ZIndex = 53 lt.Parent = b corner(lt, 15)
	local tx = label(b, "", 15, Enum.Font.GothamBold, C.text, { Position = UDim2.fromOffset(48, 8), Size = UDim2.new(1, -56, 1, -16), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 53 })
	optButtons[i] = { button = b, text = tx, stroke = st }
end
-- result view
local result = Instance.new("Frame") result.BackgroundTransparency = 1 result.Position = UDim2.fromOffset(0, 60) result.Size = UDim2.new(1, 0, 1, -60) result.Visible = false result.ZIndex = 51 result.Parent = quiz
local rIcon = label(result, "", 54, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 64), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 52 })
local rTitle = label(result, "", 24, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(0, 96), Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 52 })
local rText = label(result, "", 15, Enum.Font.Gotham, C.dim, { Position = UDim2.fromOffset(30, 134), Size = UDim2.new(1, -60, 0, 60), TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true, ZIndex = 52 })
local rBtn = Instance.new("TextButton") rBtn.AnchorPoint = Vector2.new(0.5, 0) rBtn.Position = UDim2.new(0.5, 0, 0, 220) rBtn.Size = UDim2.fromOffset(200, 48)
rBtn.BackgroundColor3 = C.green rBtn.Font = Enum.Font.GothamBlack rBtn.TextSize = 16 rBtn.TextColor3 = C.text rBtn.Text = "Continue" rBtn.ZIndex = 52 rBtn.Parent = result corner(rBtn, 12)

-- ===================== LOGIC =====================
local function countOwned() local n = 0 for k, v in pairs(player:GetAttributes()) do if v == true and k:sub(1, 6) == "Owned_" then n += 1 end end return n end
local function coin(name) local w = player:FindFirstChild("Wallet") local v = w and w:FindFirstChild(name) return v and v.Value or 0 end
local function fmtNum(n) local s = tostring(math.floor(n)) return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")) end
local function fmtTime(t) local h, m = math.floor(t / 3600), math.floor(t % 3600 / 60) if h > 0 then return string.format("%dh %02dm", h, m) end return string.format("%dm %02ds", m, t % 60) end

local function refresh()
	local unlocked = player:GetAttribute("LevelUnlocked") or 1
	local selected = player:GetAttribute("SelectedLevel") or unlocked
	local time = player:GetAttribute("PlayTimeSeconds") or 0
	local dept = LevelConfig.dept(selected)
	local fullTitle = RP.titleFor(player:GetAttribute("RP_Role"), player:GetAttribute("RP_1"), player:GetAttribute("RP_2"), player:GetAttribute("RP_3")) or LevelConfig.titleFor(selected, player:GetAttribute("CollegeProgram"), player:GetAttribute("SHSStrand"))
	local rpRole = RP.role(player:GetAttribute("RP_Role"))
	subL.Text = fullTitle .. "  ·  " .. (rpRole.Id ~= "Student" and ("🎭 Roleplay • " .. rpRole.Name) or (dept and dept.Name or ""))
	refreshPrograms()
	for i, c in pairs(chips) do
		local b = c.button
		if i == selected then
			b.BackgroundColor3 = c.dept.Color b.TextColor3 = Color3.new(1, 1, 1) b.Text = "★ " .. LevelConfig.name(i) c.stroke.Color = C.gold c.stroke.Thickness = 2.2
		elseif i <= unlocked then
			b.BackgroundColor3 = c.dept.Color:Lerp(C.card, 0.35) b.TextColor3 = Color3.new(1, 1, 1) b.Text = LevelConfig.name(i) c.stroke.Color = c.dept.Color c.stroke.Thickness = 1.2
		elseif i == unlocked + 1 then
			b.BackgroundColor3 = C.card b.TextColor3 = C.gold b.Text = "🔓 " .. LevelConfig.name(i) c.stroke.Color = C.gold c.stroke.Thickness = 1.4
		else
			b.BackgroundColor3 = C.locked b.TextColor3 = C.dim b.Text = "🔒 " .. LevelConfig.name(i) c.stroke.Color = C.stroke c.stroke.Thickness = 1
		end
	end
	selectedL.Text = "Current title: " .. fullTitle .. "     •     Highest level: " .. LevelConfig.name(unlocked)
	-- next level card
	if unlocked >= #LevelConfig.Levels then
		nextTitle.Text = "🎓 You reached 4th Year — the highest level!"
		nextInfo.Text = "Congratulations, Samar College graduate! You can still wear any earlier title."
		barFill.Size = UDim2.fromScale(1, 1) barText.Text = "MAX"
		quizBtn.Text = "Completed" quizBtn.BackgroundColor3 = C.locked quizBtn.TextColor3 = C.dim quizBtn.Active = false quizBtn.AutoButtonColor = false
	else
		local nxt = LevelConfig.Levels[unlocked + 1]
		local needMin = LevelConfig.minutesFor(unlocked + 1)
		local needSec = needMin * 60
		local lvlTime = player:GetAttribute("LevelTimeSeconds") or 0
		local pct = needSec == 0 and 1 or math.clamp(lvlTime / needSec, 0, 1)
		nextTitle.Text = "Next: " .. nxt.Name
		nextInfo.Text = "Play " .. needMin .. " min at " .. LevelConfig.name(unlocked) .. ", then pass its quiz (" .. LevelConfig.PassScore .. "/" .. LevelConfig.QuestionsPerQuiz .. "). Timer restarts each level."
		barFill.Size = UDim2.fromScale(pct, 1)
		barText.Text = string.format("%d/%d min", math.floor(lvlTime / 60), needMin)
		if pct >= 1 then
			quizBtn.Text = "📝 Take " .. LevelConfig.name(unlocked) .. " Quiz" quizBtn.BackgroundColor3 = C.gold quizBtn.TextColor3 = C.green2
			quizBtn.Active = true quizBtn.AutoButtonColor = true barFill.BackgroundColor3 = Color3.fromRGB(90, 210, 120)
		else
			local left = math.ceil((needSec - lvlTime) / 60)
			quizBtn.Text = "⏳ Stay " .. left .. " more min" quizBtn.BackgroundColor3 = C.locked quizBtn.TextColor3 = C.dim
			quizBtn.Active = false quizBtn.AutoButtonColor = false barFill.BackgroundColor3 = C.gold
		end
	end
	stats.Playtime.Text = fmtTime(time)
	stats.Events.Text = fmtNum(player:GetAttribute("EventsJoined") or 0)
	stats.Items.Text = fmtNum(countOwned())
	stats.Event.Text = fmtNum(coin("Event"))
	stats.Common.Text = fmtNum(coin("Common"))
	stats.Quizzes.Text = fmtNum(player:GetAttribute("QuizzesPassed") or 0)
	refreshLevel()
	local d = { level = unlocked, time = time, items = countOwned(), events = player:GetAttribute("EventsJoined") or 0, lvl = (XPC.fromXP(player:GetAttribute("XP") or 0)) }
	for i, a in ipairs(ACH) do
		local got = a[3](d) local r = achRows[i]
		r.icon.TextColor3 = got and C.gold or C.dim r.icon.Text = got and "🏆" or "🔒"
		r.name.TextColor3 = got and C.text or C.dim
		r.desc.Text = got and a[2] or ("Locked — " .. a[2])
		r.frame.BackgroundColor3 = got and C.card or Color3.fromRGB(30, 32, 42)
	end
end

for _, at in ipairs({ "CollegeProgram", "SHSStrand", "SelectedLevel", "LevelUnlocked", "RP_Role", "RP_1", "RP_2", "RP_3" }) do player:GetAttributeChangedSignal(at):Connect(function() if panel.Visible then refresh() end end) end
for i, c in pairs(chips) do
	c.button.MouseButton1Click:Connect(function()
		local unlocked = player:GetAttribute("LevelUnlocked") or 1
		if i <= unlocked then remotes.SelectLevel:FireServer(i)
		else
			local s = c.button.Text c.button.Text = (i == unlocked + 1) and "Take the quiz!" or "Locked"
			task.delay(1, function() refresh() end)
		end
	end)
end

local function open() refresh() dim.Visible = true panel.Visible = true panel.Size = UDim2.fromOffset(640, 520)
	TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(680, 560) }):Play() end
local function closeAll() panel.Visible = false dim.Visible = false quiz.Visible = false end
close.MouseButton1Click:Connect(closeAll)
dim.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then if not quiz.Visible then closeAll() end end end)
local hud = player.PlayerGui:WaitForChild("MainHUD", 10)
local railBtn = hud and hud:FindFirstChild("ProfileButton", true)
if railBtn then railBtn.MouseButton1Click:Connect(function() if panel.Visible then closeAll() else open() end end) end
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.P then if panel.Visible then closeAll() else open() end end
end)

-- ---------- quiz flow ----------
local current, idx, picks = nil, 1, {}
local function showQuestion()
	local q = current.questions[idx]
	qSub.Text = string.format("Question %d of %d  •  Need %d correct to pass", idx, #current.questions, current.pass)
	qFill.Size = UDim2.fromScale((idx - 1) / #current.questions, 1)
	qText.Text = q.Q
	for i, o in ipairs(optButtons) do
		local txt = q.O[i]
		o.button.Visible = txt ~= nil o.text.Text = txt or "" o.button.BackgroundColor3 = C.card o.stroke.Color = C.stroke
	end
end
local function showResult(res)
	optHolder.Visible = false qText.Visible = false qProg.Visible = false result.Visible = true
	qFill.Size = UDim2.fromScale(1, 1)
	if res.passed then
		rIcon.Text = "🎉" rTitle.Text = "You passed! " .. res.score .. "/" .. res.total rTitle.TextColor3 = C.gold
		rText.Text = "Welcome to " .. (res.newName or "the next level") .. "! Your new title is now on the leaderboard."
		rBtn.Text = "Awesome!"
	else
		rIcon.Text = "📚" rTitle.Text = "Almost! " .. (res.score or 0) .. "/" .. (res.total or 0) rTitle.TextColor3 = C.red
		rText.Text = "You need " .. (res.need or LevelConfig.PassScore) .. " correct answers. Review and try again in " .. LevelConfig.RetryCooldown .. " seconds."
		rBtn.Text = "Back to Profile"
	end
end
for i, o in ipairs(optButtons) do
	o.button.MouseButton1Click:Connect(function()
		if not current or not quiz.Visible or not optHolder.Visible then return end
		picks[idx] = i
		o.button.BackgroundColor3 = C.green o.stroke.Color = C.gold
		task.wait(0.25)
		if idx < #current.questions then idx += 1 showQuestion()
		else
			qSub.Text = "Checking answers..."
			local res = remotes.SubmitQuiz:InvokeServer(picks)
			showResult(res or { passed = false })
			current = nil
		end
	end)
end
quizBtn.MouseButton1Click:Connect(function()
	if not quizBtn.Active then return end
	quizBtn.Text = "Loading..."
	local data = remotes.StartQuiz:InvokeServer()
	if not data or not data.ok then
		quizBtn.Text = (data and data.msg) or "Try again later"
		task.delay(2.5, refresh)
		return
	end
	current, idx, picks = data, 1, {}
	qTitle.Text = "📝 " .. data.levelName .. " Quiz"
	optHolder.Visible = true qText.Visible = true qProg.Visible = true result.Visible = false
	panel.Visible = false quiz.Visible = true
	showQuestion()
end)
local function backToProfile() quiz.Visible = false current = nil panel.Visible = true refresh() end
rBtn.MouseButton1Click:Connect(backToProfile)
qClose.MouseButton1Click:Connect(function() if current then remotes.SubmitQuiz:InvokeServer({}) end backToProfile() end)

-- live refresh
player.AttributeChanged:Connect(function() if panel.Visible then refresh() end end)
task.spawn(function()
	local w = player:WaitForChild("Wallet", 30)
	if w then for _, v in ipairs(w:GetChildren()) do v.Changed:Connect(function() if panel.Visible then refresh() end end) end end
end)
