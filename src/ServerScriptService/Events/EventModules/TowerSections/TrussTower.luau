-- Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1)
-- Tower floor module (original design). Build(api) works in the floor's local space:
--   x / z from -api.HALF to api.HALF, y = 0 is the floor, api.H tall.
--   Enter at (api.ENTRY, 0, api.ENTRY); reach the exit platform at (api.EXIT, api.EXIT_TOP, api.EXIT).
--   Helpers: api.steps • api.paths.* • api.part • api.at • api.danger(part, dmg) • api.ghost • api.mover
--            api.spinner • api.swing • api.laser • api.conveyor • api.lavaFloor • api.truss • api.beam
-- TRUSS TOWER: walk to the central pillar, climb 3 trusses with ledges between them, cross the beam.
return { Name = "Truss Tower", Difficulty = 1, Color = Color3.fromRGB(120, 180, 90), Build = function(api)
	local c = api.color
	local T = api.EXIT_TOP            -- ≈ 20.5
	local h = math.floor(T / 3)       -- one truss climb
	api.part("Pillar", Vector3.new(8, T, 8), api.at(0, T / 2, 0), Color3.fromRGB(70, 75, 85), Enum.Material.Concrete) -- x/z -4..4
	api.steps({ Vector2.new(api.ENTRY, api.ENTRY), Vector2.new(-3, -9) }, { size = Vector3.new(3.2, 1, 3.2), spacing = 5, fromY = 1.2, toY = 2.2 })
	api.truss(api.at(-3, h / 2, -5), h)                                   -- 1: -Z face
	api.part("Ledge1", Vector3.new(6, 0.6, 2), api.at(2, h - 0.3, -5), c)
	api.part("Ledge1b", Vector3.new(2, 0.6, 9), api.at(5, h - 0.3, -1.5), c)
	api.truss(api.at(5, h * 1.5, 5), h)                                   -- 2: +X side
	api.part("Ledge2", Vector3.new(8, 0.6, 2), api.at(-1, 2 * h - 0.3, 5), c)
	api.truss(api.at(-5, 2.5 * h + 0.5, 2), h + 1)                        -- 3: -X side
	api.part("PillarTop", Vector3.new(8.4, 0.6, 8.4), api.at(0, T - 0.3, 0), c)
	api.beam(Vector3.new(3, T, 3), Vector3.new(api.EXIT - 2, T, api.EXIT - 2), 1.6, true)
end }
