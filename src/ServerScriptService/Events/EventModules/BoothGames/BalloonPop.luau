-- 🎈 BALLOON POP: press Play, then click/tap the balloons on the booth wall for 20 seconds (+1 ticket each).
-- Each click throws a real dart from the player's hand: the balloon bursts and the dart sticks in the cork.
-- Pops are checked on the server (ClickDetector + only the player at this booth + time left).
local G = { Name = "Balloon Pop", Icon = "🎈", Color = Color3.fromRGB(240, 150, 60),
	Description = "Click/tap as many balloons as you can in 20 seconds! +1 🎟️ each." }
local ROUND = 20
local COLS = { Color3.fromRGB(240, 60, 70), Color3.fromRGB(60, 140, 240), Color3.fromRGB(250, 210, 50), Color3.fromRGB(80, 200, 110), Color3.fromRGB(200, 90, 220), Color3.fromRGB(255, 140, 60) }
local Dart = nil

local function show(slot, on)
	for _, n in ipairs({ "Balloon", "Knot", "Shine" }) do local p = slot:FindFirstChild(n) if p then p.Transparency = on and 0 or 1 end end
end

function G.HandProp(fx)
	Dart = Dart or require(script.Parent:WaitForChild("TargetThrow"))
	return Dart.makeDart(fx, Color3.fromRGB(255, 140, 200))
end

function G.Bind(ctx, B, fx)
	Dart = Dart or require(script.Parent:WaitForChild("TargetThrow"))
	B.slots = {}
	for _, slot in ipairs(B.game:GetChildren()) do
		if slot.Name == "BalloonSlot" then
			local bal = slot.Balloon
			bal.Color = COLS[fx.rand:NextInteger(1, #COLS)] slot.Knot.Color = bal.Color
			table.insert(B.slots, slot)
			local cd = Instance.new("ClickDetector") cd.MaxActivationDistance = 28 cd.Parent = bal
			local function onClick(player)
				local s = B.session
				if not s or B.occupant ~= player or os.clock() > s.ends or slot:GetAttribute("Popped") then return end
				slot:SetAttribute("Popped", true)
				s.popped += 1
				fx.give(ctx, player, s, 1)
				fx.say(B, ("🎈 %d popped • 🎟️ %d"):format(s.popped, s.tickets or 0))
				task.spawn(function()
					fx.anim(B, "throw", 1.6)
					local target = bal.Position
					local dart = fx.temp(B, Dart.makeDart(fx, Color3.fromRGB(255, 140, 200)))
					local from = fx.hand(B).Position
					local inward = B.cf.LookVector * -1
					fx.fly(dart, CFrame.lookAt(from, target), CFrame.lookAt(target + inward * 0.2, target + inward * 2), 0.3, 0.2)
					show(slot, false)
					fx.burst(target, bal.Color, 22, 12, 0.45)
					fx.sound(B, "Pop", 0.55, fx.rand:NextNumber(1.7, 2.2))
					fx.move(dart, CFrame.lookAt(target + inward * 0.45, target + inward * 2), 0.06)
					task.wait(2.2)
					bal.Color = COLS[fx.rand:NextInteger(1, #COLS)] slot.Knot.Color = bal.Color
					show(slot, true)
					slot:SetAttribute("Popped", nil)
				end)
			end
			ctx:Connect(cd.MouseClick, onClick)
			slot:SetAttribute("_", nil)
			B.debugClicks = B.debugClicks or {}
			table.insert(B.debugClicks, onClick)
		end
	end
end

function G.Start(ctx, player, s, B, fx)
	s.popped = 0
	s.ends = os.clock() + ROUND
	fx.say(B, "🎈 GO! • 🎟️ 0")
	task.delay(ROUND, function()
		if B.session == s then
			ctx:Send(player, { type = "boothResult", game = "BalloonPop", msg = ("🎈 Time! You popped %d balloons (+%d 🎟️)"):format(s.popped, s.popped), done = true })
			if s.popped >= 10 then fx.confetti(B) fx.anim(B, "cheer") end
			task.wait(1.5)
			if s.finish then s.finish() end
		end
	end)
	return { kind = "info", text = "🎈 GO! Click or tap the balloons on the wall!", seconds = ROUND, keepOpen = true }
end

function G.Action(ctx, player, s, data, B, fx) return { ok = false } end

function G.Stop(ctx, player, s, B, fx)
	task.delay(2.6, function() for _, slot in ipairs(B.slots) do if not B.session then show(slot, true) slot:SetAttribute("Popped", nil) end end end)
end

return G
