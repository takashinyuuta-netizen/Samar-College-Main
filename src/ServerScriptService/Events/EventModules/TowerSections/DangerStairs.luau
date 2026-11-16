-- Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1)
-- Tower floor module. Build(api) creates the floor in its own local space:
--   x / z from -20 to 20 (inside the walls), y = 0 is the floor, the floor is 24 tall.
--   You ENTER at corner (-16, -16) and must reach the exit platform at (15, 17.5, 15).
--   Helpers: api.steps(path, opts) • api.paths.* • api.part • api.at • api.kill • api.ghost
--            api.mover • api.spinner • api.conveyor • api.lavaFloor • api.color
return { Name = "Danger Stairs", Difficulty = 3, Color = Color3.fromRGB(250, 170, 60), Build = function(api)
	-- wide ramps with lava bricks to dodge
	local pads = api.steps(api.paths.zigzag(), { size = Vector3.new(3.4, 1, 3.4), spacing = 8 })
	for i = 1, #pads - 1 do
		local a, b = pads[i].Position + Vector3.new(0, 0.5, 0), pads[i + 1].Position + Vector3.new(0, 0.5, 0)
		local ramp = api.beam(a, b, 4)
		for k = 1, 2 do
			local t = 0.3 + 0.35 * (k - 1) + math.random() * 0.1
			local side = (math.random() < 0.5) and -1.2 or 1.2
			local p = a:Lerp(b, t)
			local right = ramp.CFrame.RightVector
			local brick = api.rawPart("LavaBrick", Vector3.new(1.2, 0.5, 1.2), CFrame.new(p + right * side + Vector3.new(0, 0.3, 0)), Color3.fromRGB(255, 60, 40), Enum.Material.Neon)
			api.kill(brick)
		end
	end
end }
