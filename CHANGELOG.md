# Changelog — Samar College (Main)

All notable changes to the **Main game** (Junior High, Senior High and College).
The Kid Server has its own changelog in its repository.

## v0.1 – Campus build
- Recreated the Samar College campus: ground floor to 5th floor, rooftop, corridors, front gate, entry/exit gates, driveway and plaza
- School colours applied (emerald-green roofs and trim)
- Every floor sorted into folders by floor, then by type (rooms, doors, props, fans & lights); parts renamed by building/room
- Interactive props: tap/E-to-open doors, sliding & swing doors, gates, curtains, windows, drawers, whiteboards, slide shows, light switches, power toggles & LEDs, ceiling/wall fans, water dispensers, toilets, thesis shelves, elevator
- Seats with sit prompts, sleep seats, faculty/principal knock doors, open/closed signs, library time-in, clearance desks, suggestion boxes, TV ads
- Day/night cycle and weather system
- Fall rescue (respawn players who fall off the map)

## v0.2 – Player systems
- Loading screen with branding, progress bar, rotating tips and "tap to continue"
- Main HUD: Profile, Bag, Map, Music and Settings buttons
- Profile panel: play time, events joined, equipment count, event & common coins, achievements, role toggle
- Bag with Cosmetic / Equipment / Consumable tabs (descriptions, equip status, quantities) and a hotbar
- Level progression: grade-by-grade levels, each unlocked by play time + a level quiz; profile title updates
- Roleplay roles and outfits (RoleplayConfig, Outfits), staff access and ROTC permission
- Settings: music / sound volume, event and leaderboard notifications
- Shop (coins), gear, flashlight, bikes and boats
- Player data saving (PlayerData / PlayerRecords) with a Studio fallback store
- Player reports and admin tools
- Campus Life: NPCs with dialogue, class schedule/periods, deans and office staff
- Room hosting signs (rooms get a hallway sign; doorless rooms use the nearest door)

## v0.3 – Events
- Event manager with rotation, rarity, cooldowns and rewards (common & event coins, XP)
- Common events: Quiz Bee, Booth mini-games (Balloon Pop, Guess the Number, Hoop Shot, Lucky Wheel, Memory Match, Ring Toss, Target Throw, Whack-a-Mole), Guess the Drawing, Tower Game (14 obstacle sections), Escape School, Campus Check-In
- Rare events: Intramurals, Foundation Day
- Talent stage with emotes, sports (basketball, chess)
- PATAAS sky climb (Easy & Hard) with best-time saving
- Event admin controls

## v0.4 – Leaderboards & music
- Four leaderboard stands in the plaza, each a scrollable **Top 50** with tabs:
  - Coins: common coins, rare (event) coins
  - Wins: total event wins + wins per event
  - Speed runs: Tower, PATAAS Easy, PATAAS Hard (fastest time)
  - Legends: stay time (and donations on Main)
- Your own rank shown at the bottom ("You: #rank"), headshots, ▲▼ scrolling
- Music player with a licensed music library (APM / DistroKid catalogues), categories and colours

## v0.5 – Events rotation & Quiz Bee bank
- Event rotation every **2 minutes**; the next countdown only starts after the running event (and its results) finish, so events never overlap
- If every event is on cooldown, a different enabled event is picked instead of stalling
- Quiz Bee: **100+ questions per department/course/strand**, picked by the room's department and grade
  - Elementary, Junior High, STEM, HUMSS, GAS, ABM, TVL-ICT, BSIT, BSCRIM, BSEd
  - Questions asked in the last hour are avoided so rounds don't repeat
- Rooftop gap at the stair end filled in

## v0.6 – Donations
- "💖 Support the game" section inside **Settings** (Robux only)
- Six developer products: 10, 25, 50, 100, 250, 500 R$ (button amounts read from the product names)
- Each receipt is processed once, added to the player's **Donated** total and the Donations leaderboard, and announced to the server
- Cartoon R$ coin + paper-money icons for the products

## v0.7 – Kid Server split & release
- Elementary players moved to a separate **Kid Server** game
- Loading screen: loading → **tap to continue** → straight into the campus (server choice screen and Settings server section hidden)
- Main game made public; content questionnaire completed
- New icon and thumbnail (no Roblox logo, no school seal)
- Source code moved to this repository; backups, Studio scratch copies and the school seal data are not included
