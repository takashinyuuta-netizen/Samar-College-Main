-- Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1)
-- Tower floor module. Build(api) creates the floor in its own local space:
--   x / z from -20 to 20 (inside the walls), y = 0 is the floor, the floor is 24 tall.
--   You ENTER at corner (-16, -16) and must reach the exit platform at (15, 17.5, 15).
--   Helpers: api.steps(path, opts) • api.paths.* • api.part • api.at • api.kill • api.ghost
--            api.mover • api.spinner • api.conveyor • api.lavaFloor • api.color
return { Name = "Lava Lake", Difficulty = 3, Color = Color3.fromRGB(240, 110, 60), Build = function(api)
	api.lavaFloor() -- the floor is lava: falling = back to the start!
	api.steps(api.paths.zigzag(), { size = Vector3.new(3.6, 1, 3.6), spacing = 5.4 })
end }
