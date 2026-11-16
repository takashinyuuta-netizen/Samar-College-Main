-- EventBoot: starts the event system (rotation + admin commands).
-- All logic lives in the ModuleScripts next to this script.
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local EventAdmin = require(script.Parent:WaitForChild("EventAdmin"))

EventAdmin.init(EventManager)
EventManager.run()
print("[Events] Event system running on the " .. EventManager.ServerType .. " server")
