-- Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1)
-- Tower floor module (original design). Build(api) works in the floor's local space:
--   x / z from -api.HALF to api.HALF, y = 0 is the floor, api.H tall.
--   Enter at (api.ENTRY, 0, api.ENTRY); reach the exit platform at (api.EXIT, api.EXIT_TOP, api.EXIT).
--   Helpers: api.steps • api.paths.* • api.part • api.at • api.danger(part, dmg) • api.ghost • api.mover
--            api.spinner • api.swing • api.laser • api.conveyor • api.lavaFloor • api.truss • api.beam
return { Name = "Spinner Hall", Difficulty = 3, Color = Color3.fromRGB(230, 70, 90), Build = function(api)
	api.steps(api.paths.snake(), { size = Vector3.new(4, 1, 4), spacing = 5.4 })
	api.part("Hub", Vector3.new(2.4, api.EXIT_TOP + 2, 2.4), api.at(0, (api.EXIT_TOP + 2) / 2, 0), Color3.fromRGB(60, 60, 66), Enum.Material.Metal)
	api.spinner(api.EXIT_TOP * 0.33, nil, 0.9)   -- two red bars sweep the whole floor: jump over them!
	api.spinner(api.EXIT_TOP * 0.72, nil, -1.15)
end }
