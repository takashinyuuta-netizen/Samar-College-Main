-- Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1)
-- Tower floor module. Build(api) creates the floor in its own local space:
--   x / z from -20 to 20 (inside the walls), y = 0 is the floor, the floor is 24 tall.
--   You ENTER at corner (-16, -16) and must reach the exit platform at (15, 17.5, 15).
--   Helpers: api.steps(path, opts) • api.paths.* • api.part • api.at • api.kill • api.ghost
--            api.mover • api.spinner • api.conveyor • api.lavaFloor • api.color
return { Name = "Conveyor Bridges", Difficulty = 2, Color = Color3.fromRGB(100, 120, 230), Build = function(api)
	-- ramps that push you BACKWARDS: keep running!
	local pads = api.steps(api.paths.perimeter(), { size = Vector3.new(3, 1, 3), spacing = 8 })
	for i = 1, #pads - 1 do
		local b = api.beam(pads[i].Position + Vector3.new(0, 0.5, 0), pads[i + 1].Position + Vector3.new(0, 0.5, 0), 3)
		api.conveyor(b, (pads[i].Position - pads[i + 1].Position).Unit, 9)
	end
end }
