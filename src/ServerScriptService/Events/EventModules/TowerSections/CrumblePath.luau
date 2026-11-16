-- Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1)
-- Tower floor module (original design). Build(api) works in the floor's local space:
--   x / z from -api.HALF to api.HALF, y = 0 is the floor, api.H tall.
--   Enter at (api.ENTRY, 0, api.ENTRY); reach the exit platform at (api.EXIT, api.EXIT_TOP, api.EXIT).
--   Helpers: api.steps • api.paths.* • api.part • api.at • api.danger(part, dmg) • api.ghost • api.mover
--            api.spinner • api.swing • api.laser • api.conveyor • api.lavaFloor • api.truss • api.beam
return { Name = "Crumble Path", Difficulty = 2, Color = Color3.fromRGB(180, 150, 110), Build = function(api)
	-- tiles crumble almost as soon as you land: keep moving!
	api.steps(api.paths.zigzag(), { size = Vector3.new(3.4, 0.8, 3.4), spacing = 5.2, kind = "crumble" })
end }
