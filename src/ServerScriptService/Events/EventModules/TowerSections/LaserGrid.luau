-- Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1)
-- Tower floor module (original design). Build(api) works in the floor's local space:
--   x / z from -api.HALF to api.HALF, y = 0 is the floor, api.H tall.
--   Enter at (api.ENTRY, 0, api.ENTRY); reach the exit platform at (api.EXIT, api.EXIT_TOP, api.EXIT).
--   Helpers: api.steps • api.paths.* • api.part • api.at • api.danger(part, dmg) • api.ghost • api.mover
--            api.spinner • api.swing • api.laser • api.conveyor • api.lavaFloor • api.truss • api.beam
return { Name = "Laser Grid", Difficulty = 3, Color = Color3.fromRGB(255, 90, 120), Build = function(api)
	api.steps(api.paths.perimeter(), { size = Vector3.new(3.6, 1, 3.6), spacing = 5.2 })
	-- red laser walls sweep up and down across both legs of the path: time your jumps!
	local H = api.H - 3
	api.laser(0.6, H, -api.HALF * 0.35, 2.6, false)
	api.laser(0.6, H, api.HALF * 0.2, 3.1, false)
	api.laser(0.6, H, -api.HALF * 0.25, 2.8, true)
	api.laser(0.6, H, api.HALF * 0.35, 2.4, true)
end }
