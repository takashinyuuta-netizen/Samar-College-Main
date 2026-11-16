-- Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1)
-- Tower floor module (original design). Build(api) works in the floor's local space:
--   x / z from -api.HALF to api.HALF, y = 0 is the floor, api.H tall.
--   Enter at (api.ENTRY, 0, api.ENTRY); reach the exit platform at (api.EXIT, api.EXIT_TOP, api.EXIT).
--   Helpers: api.steps • api.paths.* • api.part • api.at • api.danger(part, dmg) • api.ghost • api.mover
--            api.spinner • api.swing • api.laser • api.conveyor • api.lavaFloor • api.truss • api.beam
return { Name = "Swinging Bars", Difficulty = 3, Color = Color3.fromRGB(240, 120, 70), Build = function(api)
	local pads = api.steps(api.paths.snake(), { size = Vector3.new(3.6, 1, 3.6), spacing = 5.2 })
	-- red pendulums swing across every 4th step at body height
	for i = 3, #pads - 2, 4 do
		local a, b = pads[i], pads[i + 1]
		local la = (api.at(0, 0, 0)):PointToObjectSpace(a.Position)
		local lb = (api.at(0, 0, 0)):PointToObjectSpace(b.Position)
		local dir = Vector3.new(lb.X - la.X, 0, lb.Z - la.Z)
		local yaw = math.atan2(dir.X, dir.Z)
		local topY = la.Y + 0.5
		local pivotY = math.min(api.H - 1, topY + 12)
		api.swing(Vector3.new(la.X, pivotY, la.Z), pivotY - topY - 2.2, yaw, 1.5 + (i % 3) * 0.25, i)
	end
end }
