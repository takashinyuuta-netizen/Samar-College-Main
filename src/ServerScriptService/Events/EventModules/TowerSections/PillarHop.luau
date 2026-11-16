-- Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1)
-- Tower floor module (original design). Build(api) works in the floor's local space:
--   x / z from -api.HALF to api.HALF, y = 0 is the floor, api.H tall.
--   Enter at (api.ENTRY, 0, api.ENTRY); reach the exit platform at (api.EXIT, api.EXIT_TOP, api.EXIT).
--   Helpers: api.steps • api.paths.* • api.part • api.at • api.danger(part, dmg) • api.ghost • api.mover
--            api.spinner • api.swing • api.laser • api.conveyor • api.lavaFloor • api.truss • api.beam
return { Name = "Pillar Hop", Difficulty = 2, Color = Color3.fromRGB(90, 200, 230), Build = function(api)
	-- small pads on tall pillars, in 3 lanes across the room.
	-- (It used the SPIRAL path before: that loops over itself, so the pillars of the high pads stood right in
	-- the way of the low pads and players got boxed in and couldn't reach the exit. The snake never crosses itself.)
	api.steps(api.paths.snake(), { size = Vector3.new(2.4, 1, 2.4), spacing = 4.6, pillar = true })
end }
