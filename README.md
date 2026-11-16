# Samar College — Main Game (Roblox)

**Capstone project:** *A Roblox-Based Social Virtual World with Server Category Selection Based on Users' Year Level*
**Team:** TEAM PRUC — BSIT, Samar College, Catbalogan City, Samar

This repository holds the **scripts** for the **Main game** (Junior High, Senior High and College).
The younger players' version lives in a separate repository: **Samar College [Kid Server]**.

## What's in the game
- A virtual recreation of the Samar College campus (classrooms, library, offices, rooftop, plaza)
- Year-level profiles: Junior High, Senior High (STEM, HUMSS, ABM, GAS, TVL-ICT) and College (BSIT, BSCRIM, BSEd)
- Roleplay roles: Student, Teacher, Instructor, Employee, Staff
- Rotating campus events (every 2 minutes, never overlapping):
  Quiz Bee (100+ questions per course/strand), Tower Game, PATAAS sky climb, Escape School,
  Guess the Drawing, Booths, Campus Check-In, and rare events (Intramurals, Foundation Day)
- Leaderboard stands (Top 50): coins, event wins, speed runs, stay time, donations
- Music player, shop, bag/profile UI, loading screen with "tap to continue"
- Optional Robux donations (developer products)

## Repository layout
```
src/
  ServerScriptService/   server logic (events, data, leaderboards, shop, donate…)
  ReplicatedStorage/     shared modules & config (EventConfig, LevelConfig, Music library…)
  ReplicatedFirst/       loading screen
  StarterGui/            HUD and panels
  StarterPlayer/         client scripts
  ServerStorage/         build tools and event maps
  Workspace/             scripts attached to campus objects (doors, fans, NPCs…)
default.project.json     Rojo project file
```
File names follow the Rojo convention: `*.server.luau` = Script, `*.client.luau` = LocalScript, `*.luau` = ModuleScript.

> Only scripts are stored here. The 3D campus (parts, models, terrain) lives in the Roblox place file.

## Docs
- [CHANGELOG.md](CHANGELOG.md) — everything added, version by version
- [FUNCTIONS.md](FUNCTIONS.md) — every core script, what it does and the functions it defines
