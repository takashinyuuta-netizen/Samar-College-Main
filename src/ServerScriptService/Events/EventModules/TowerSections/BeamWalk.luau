-- Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1)
-- Tower floor module. Build(api) creates the floor in its own local space:
--   x / z from -20 to 20 (inside the walls), y = 0 is the floor, the floor is 24 tall.
--   You ENTER at corner (-16, -16) and must reach the exit platform at (15, 17.5, 15).
--   Helpers: api.steps(path, opts) • api.paths.* • api.part • api.at • api.kill • api.ghost
--            api.mover • api.spinner • api.conveyor • api.lavaFloor • api.color
return { Name = "Beam Walk", Difficulty = 1, Color = Color3.fromRGB(240, 200, 70), Build = function(api)
	-- narrow sloped beams between small landing pads
	local pads = api.steps(api.paths.zigzag(), { size = Vector3.new(2.6, 1, 2.6), spacing = 7 })
	for i = 1, #pads - 1 do api.beam(pads[i].Position + Vector3.new(0, 0.5, 0), pads[i + 1].Position + Vector3.new(0, 0.5, 0), 1.3) end
end }
