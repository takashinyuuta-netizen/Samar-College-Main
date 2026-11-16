-- Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1)
-- Tower floor module. Build(api) creates the floor in its own local space:
--   x / z from -20 to 20 (inside the walls), y = 0 is the floor, the floor is 24 tall.
--   You ENTER at corner (-16, -16) and must reach the exit platform at (15, 17.5, 15).
--   Helpers: api.steps(path, opts) • api.paths.* • api.part • api.at • api.kill • api.ghost
--            api.mover • api.spinner • api.conveyor • api.lavaFloor • api.color
return { Name = "Ghost Tiles", Difficulty = 2, Color = Color3.fromRGB(170, 140, 240), Build = function(api)
	-- tiles fade away shortly after you land on them, then come back
	api.steps(api.paths.perimeter(), { size = Vector3.new(4, 0.8, 4), spacing = 5.4, kind = "ghost" })
end }
