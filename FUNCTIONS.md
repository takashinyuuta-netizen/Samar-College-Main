# Samar College (Main) — Systems & Functions
Auto-generated index of every core script: what it does (from its header comment) and the functions it defines.
Scripts attached to individual campus props (doors, fans, lights) in `Workspace` and build tools in `ServerStorage` are not listed.
Data-only modules (question banks, music library, word lists, logo data) are listed without functions.

## ReplicatedFirst

### `LoadingScreen`
`src/ReplicatedFirst/LoadingScreen.client.luau` · LocalScript (client) · 537 lines

**Functions:** `tw(o, t, props, style, dir)`, `new(class, props, parent)`, `corner(p, r)`, `stroke(p, c, t, tr)`, `text(parent, props)`, `hideGui(g)`, `setCore(on)`, `showHud()`, `rescale()`, `placeView(v)`, `setStep(id, state, detail)`, `setProgress(p, msg)`, `fmt(n)`, `stepProgress(id, f, msg)`, `preload(list, id, label, limit)`, `run()`, `finish(msg)`

## ReplicatedStorage

### `CampusLifeConfig`
`src/ReplicatedStorage/CampusLife/CampusLifeConfig.luau` · ModuleScript · 232 lines

**Functions:** `parse(t)`, `C.schoolMinute()`, `C.periodAt(minute)`, `C.formatTime(minute)`, `office(role, dept, room, look, acts, lines)`, `seated(e, seatPath)`, `dean(code, college, lines)`

### `DialogModule`
`src/ReplicatedStorage/DialogModule.luau` · ModuleScript · 334 lines

DialogModule.lua (Grow a Garden/Fisch-style dialogue by supdoggyDev) Samar College edits: R15 support (HumanoidRootPart when there is no Torso), ends the talk if the NPC leaves.

**Functions:** `DialogModule.new(npcName, npc, prompt, animation)`, `DialogModule:addDialog(dialogText, responseOptions)`, `DialogModule:sortDialogs(sortFunc)`, `DialogModule:triggerDialog(player, questionNumber)`, `DialogModule:showGui()`, `DialogModule:hideGui(exitQuip, notActuallyAnExitQuip)`, `DialogModule:nextOption()`, `turnProximityPromptsOn(yes)`

### `EventConfig`
`src/ReplicatedStorage/Events/EventConfig.luau` · ModuleScript · 338 lines

**Functions:** `EventConfig.getServerType()`, `EventConfig.rarityOf(def)`, `EventConfig.weightOf(def)`, `EventConfig.currencyOf(def)`

### `XPConfig`
`src/ReplicatedStorage/Events/XPConfig.luau` · ModuleScript · 62 lines

**Functions:** `XP.need(level)`, `XP.totalFor(level)`, `XP.fromXP(xp)`, `XP.tierOf(level)`

### `HUDConfig`
`src/ReplicatedStorage/HUDConfig.luau` · ModuleScript · 44 lines

HUDConfig.lua Settings for the Bag / Map / Settings HUD. Edit freely.

### `HostingConfig`
`src/ReplicatedStorage/HostingConfig.luau` · ModuleScript · 40 lines

**Functions:** `M.type(id)`, `M.excluded(name)`, `M.pretty(name)`

### `LeaderboardConfig`
`src/ReplicatedStorage/LeaderboardConfig.luau` · ModuleScript · 59 lines

**Functions:** `C.format(fmt, v)`, `commas(n)`

### `LevelConfig`
`src/ReplicatedStorage/LevelConfig.luau` · ModuleScript · 97 lines

LevelConfig: school levels used for Titles, Profile and unlocking. RequiredMinutes = total minutes a player must have played before they can take the quiz that unlocks that level.

**Functions:** `LevelConfig.find(name)`, `LevelConfig.name(i)`, `LevelConfig.dept(i)`, `LevelConfig.minutesFor(i)`, `LevelConfig.programGroup(levelIdx)`, `LevelConfig.titleFor(levelIdx, collegeIdx, strandIdx)`

### `MusicLibrary`
`src/ReplicatedStorage/Music/MusicLibrary.luau` · ModuleScript · 896 lines

_Data module._

### `Outfits`
`src/ReplicatedStorage/Outfits.luau` · ModuleScript · 399 lines

Outfits.lua Builds clothing out of coloured body parts + small welded parts, so it works on R6 and R15 characters without needing uploaded shirt/pants images. Used to dress the NPCs (Guard, Teacher, Cashier) and for shop cosmetics on players. Outfits.wear(character, "Guard")      -- put on an outfit or cosmetic Outfits.remove(character, "Guard")    -- take it off again (restores original look) Out

**Functions:** `isR15(character)`, `regionParts(character, region)`, `torso(character)`, `chestCF(character)`, `waistCF(character)`, `frontZ(character, extra)`, `torsoDepth(character)`, `getFolder(character, outfitName)`, `addPart(folder, attachTo, cf, props)`, `addLabel(part, face, text, textColor, bgColor)`, `origKey(partName)`, `paint(character, folder, region, color)`, `stashClothing(character, folder)`, `idLanyard(folder, character, ribbonColor, cardText)`, `cap(folder, character, color, brimColor, text, textColor)`, `Outfits.has(outfitName)`, `Outfits.remove(character, outfitName)`, `Outfits.removeAll(character)`, `Outfits.wear(character, outfitName)`

### `ReportConfig`
`src/ReplicatedStorage/ReportConfig.luau` · ModuleScript · 22 lines

ReportConfig: what players can report someone for, and the results admins can give a report.

### `RoleplayConfig`
`src/ReplicatedStorage/RoleplayConfig.luau` · ModuleScript · 71 lines

**Functions:** `M.role(i)`, `M.pick(role, row, idx)`, `M.titleFor(roleIdx, a, b, c)`, `M.tagFor(roleIdx, a, b, c)`

### `SC_LogoData`
`src/ReplicatedStorage/SC_LogoData.luau` · ModuleScript · 6 lines

Samar College logo pixel data (256x256, palette + RLE + base64). The school's official seal is NOT stored in this public repository. The real data lives only in the Roblox place file. To run from source, paste the original module contents here, or leave this placeholder: SC_LogoRenderer will simply show no logo.

_Data module._

### `SC_LogoDecoder`
`src/ReplicatedStorage/SC_LogoDecoder.luau` · ModuleScript · 42 lines

Decodes SC_LogoData into an RGBA buffer for an EditableImage.

**Functions:** `b64decode(s)`, `put(ci, count)`

### `ShopItems`
`src/ReplicatedStorage/ShopItems.luau` · ModuleScript · 40 lines

ShopItems.lua Item catalog for the Cashier's shop. Categories: Cosmetic (visual only), Equipment (has an effect while equipped), Consumable (used up). RequiredLevel (optional) = LevelConfig level index needed to buy (2 = Grade 1, 4 = Grade 3, 14 = 1st Year). Currency is "Common" (regular games) or "Event" (special events). Add or edit items here; the shop GUI, inventory GUI and server update autom

### `ChessPieces`
`src/ReplicatedStorage/Sports/ChessPieces.luau` · ModuleScript · 86 lines

**Functions:** `M.build(kind, white, scale, forViewport)`, `part(name, size, cf, shape, col, material)`, `disc(name, d, h, y, col)`

### `SportsConfig`
`src/ReplicatedStorage/Sports/SportsConfig.luau` · ModuleScript · 122 lines

SportsConfig: Intramurals sports courts (Badminton now; more sports reuse the same system). Courts are models in Workspace.SportsVenues with attributes Sport / CourtId / CourtName.

**Functions:** `basketballShots()`, `basketball(name, perSide, winScore, gameTime)`

### `Emotes`
`src/ReplicatedStorage/TalentShow/Emotes.luau` · ModuleScript · 100 lines

**Functions:** `M.play(character, id)`, `M.stop(character)`

### `FlashlightClient`
`src/ReplicatedStorage/Tools/Flashlight/FlashlightClient.client.luau` · LocalScript (client) · 74 lines

FlashlightClient: asks the SERVER to switch the light (so EVERY player sees it), sends where you aim, and shows a small battery meter while you hold it.

**Functions:** `toggle()`, `buildGui()`, `rs()`, `updateGui()`

### `WeatherConfig`
`src/ReplicatedStorage/Weather/WeatherConfig.luau` · ModuleScript · 161 lines

## ServerScriptService

### `AdminServer`
`src/ServerScriptService/AdminServer.server.luau` · Script (server) · 682 lines

AdminServer: Samar College admin panel (TEAM PRUC). Owner = OWNER_IDS + the experience's creator. Co-admins are stored in a DataStore and can be added/removed by the owner only. Every request is checked here on the server.

**Functions:** `loadAdmins()`, `isOwner(userId)`, `isAdmin(userId)`, `roleOf(userId)`, `givePanel(player)`, `findPlayer(userId)`, `resolve(query)`, `getBan(userId)`, `fmtDuration(sec)`, `itemList()`, `liveData(p)`, `publish(msg)`, `applyLive(p, c)`, `applyToSave(d, c)`, `sanitize(c)`, `commit(userId, c)`, `kickLocal(userId, msg)`, `banMessage(b)`, `protectTarget(caller, targetId)`, `saveAdmins()`, `setInvisible(p, on)`, `setGod(p, on)`, `applySpeed(p)`, `reapplyPowers(p)`, `hookPlayer(p)`, `eventControl(cmd, arg, caller)`

### `BikeServer`
`src/ServerScriptService/BikeServer.server.luau` · Script (server) · 278 lines

**Functions:** `toast(player, msg)`, `setRiderGroup(character, on)`, `despawn(player)`, `setParked(bike, parked)`, `groundBelow(pos, ignore)`, `seatOwner(player, bike)`, `summon(player)`, `watchCharacter(player, char)`

### `BoatServer`
`src/ServerScriptService/BoatServer.server.luau` · Script (server) · 181 lines

**Functions:** `flat(v)`, `occupantsOf(S)`, `park(S)`, `respawn(S, why)`, `setup(model)`, `onSeatChanged()`

### `CampusLifeServer`
`src/ServerScriptService/CampusLife/CampusLifeServer.server.luau` · Script (server) · 881 lines

**Functions:** `pick(t)`, `findRoom(name)`, `boundsOf(inst)`, `isOutsidePart(inst, room)`, `spotsIn(room)`, `placeSpot(placeName)`, `nearDoor(pos)`, `openDoor(d)`, `buildBody(lookName, gender)`, `fromTemplate(name)`, `subjectsFor(room, level)`, `levelGroup(room)`, `randomName(gender, title)`, `setupAnims(n)`, `gesture(n, name, t)`, `makeNpc(kind, profile, model, folder)`, `observed(pos, radius)`, `stale(n, token)`, `walkTo(n, dest, token)`, `sitIn(n, room)`, `classIndex(period)`, `decide(n, period)`, `inRoom(act, state, key)`, `goHome(n)`, `comeBack(n, at)`, `refreshRayFilter()`, `floorAt(x, y, z, depth)`, `clearLine(a, b)`, `homeFor(n)`, `pathIn(roomName, path)`, `setupHome(n)`, `flatDist(a, b)`, `stepTo(n, p)`, `putHome(n)`, `trySit(n)`, `runNpc(n)`, `scheduleFor(n)`, `startTalk(n, player)`, `lineFor(n, period)`

### `CeilingFans`
`src/ServerScriptService/CeilingFans.server.luau` · Script (server) · 48 lines

CeilingFans (server): wall switches that turn ceiling fans on and off. A switch is a Model tagged "FanSwitch" with: ProximityPrompt "FanPrompt" ObjectValue "Fans"  -> a Model/Folder holding the fans (Models tagged "CeilingFan") optional parts "Toggle" (flips when switched) and "Indicator" (glows while on) The fans only store the "On" attribute here; the spinning is done by CeilingFans.client. Tag 

**Functions:** `fansOf(sw)`, `setup(sw)`, `apply(on)`

### `ClearanceDesks`
`src/ServerScriptService/ClearanceDesks.server.luau` · Script (server) · 110 lines

ClearanceDesks: E at the Dean's office counter to have your clearance slip signed. A desk is a Model tagged "ClearanceDesk" with: ProximityPrompt "ClearancePrompt" model "Stamp"          -> presses down on the slip part "Slip"            -> appears with its SurfaceGui; the TextLabel "ApprovedMark" shows after the stamp TextLabel "ServingLabel" (who is being served) and "CountLabel" (slips signed o

**Functions:** `setup(desk)`, `labels(name, text)`, `refresh()`, `press()`, `moveAll(offset, info)`

### `DayNightCycle`
`src/ServerScriptService/DayNightCycle.server.luau` · Script (server) · 48 lines

DayNightCycle (synced with the school schedule – see ReplicatedStorage.CampusLife.CampusLifeConfig) The sky clock IS the school clock: Lighting.ClockTime = the time NPC schedules use. • School hours (6:00 AM – 6:00 PM) run slowly so classes last long enough: 1 school minute = DayMinuteSeconds real seconds (2 s → a 90-minute class ≈ 3 real minutes) • The night (6:00 PM – 6:00 AM) passes quickly.

### `DefaultAvatarSize`
`src/ServerScriptService/DefaultAvatarSize.server.luau` · Script (server) · 55 lines

DefaultAvatarSize.lua Gives every player the same body size while keeping their own avatar look: layered (3D) clothing, classic shirts/pants, hair, accessories, face and skin. When a player's avatar finishes loading, only the scale values below are changed; layered clothing re-wraps itself to the new body size automatically. Change the numbers below to adjust the size for everyone.

**Functions:** `applyDefaultSize(character)`, `onPlayerAdded(player)`

### `DonateServer`
`src/ServerScriptService/DonateServer.server.luau` · Script (server) · 105 lines

**Functions:** `loadProducts()`, `toastAll(text)`

### `ElevatorSystem`
`src/ServerScriptService/ElevatorSystem.server.luau` · Script (server) · 162 lines

Working elevator 1F <-> 2F <-> 3F <-> 4F <-> 5F. Buttons are tap/click only (ClickDetector, no E prompt). Landings: models tagged "ElevatorLanding" (attribute Floor) with LeafN / LeafS (sliding door leaves), an Indicator part (labels "▲" and the floor number) and a CallPanel with Button parts. Cars: workspace.SamarCollege_Campus.ElevatorSystem.Car_1 / Car_2 with a ButtonPanel (Btn_1, Btn_2, Btn_Op

**Functions:** `setupLanding(m)`, `setDisplays(floorNum, arrow)`, `moveDoors(f, open)`, `scheduleClose()`, `openHere()`, `ridersIn(f)`, `travel(target)`, `call(f)`, `flash(btn)`, `hook(part, fn)`

### `EquipLock`
`src/ServerScriptService/EquipLock.server.luau` · Script (server) · 28 lines

**Functions:** `update(player)`, `hook(player)`

### `DrawingBotArt`
`src/ServerScriptService/Events/DrawingBotArt.luau` · ModuleScript · 169 lines

_Data module._

### `DrawingWords`
`src/ServerScriptService/Events/DrawingWords.luau` · ModuleScript · 15 lines

_Data module._

### `EventAdmin`
`src/ServerScriptService/Events/EventAdmin.luau` · ModuleScript · 100 lines

**Functions:** `allowed(player)`, `list(manager)`, `control(manager, cmd, arg, caller)`, `EventAdmin.init(manager)`, `handle(player, text)`, `hook(p)`

### `EventBoot`
`src/ServerScriptService/Events/EventBoot.server.luau` · Script (server) · 8 lines

EventBoot: starts the event system (rotation + admin commands). All logic lives in the ModuleScripts next to this script.

### `EventManager`
`src/ServerScriptService/Events/EventManager.luau` · ModuleScript · 462 lines

**Functions:** `busyFor(ctx, player)`, `zonesFolder()`, `serverAllowed(def)`, `moduleFor(id)`, `sortedScores(ctx)`, `countParticipants(ctx)`, `publicState()`, `EventManager.broadcast()`, `markScores()`, `newContext(id, def, mod)`, `ctx:SetLocation(position, name)`, `ctx:Join(player)`, `ctx:Leave(player)`, `ctx:IsIn(player)`, `ctx:AddScore(player, n)`, `ctx:SetScore(player, n)`, `ctx:Toast(player, msg)`, `ctx:ToastAll(msg)`, `ctx:Send(player, payload)`, `ctx:SendAll(payload)`, `ctx:Broadcast(payload)`, `ctx:Connect(signal, fn)`, `ctx:End(reason)`, `ctx:Refresh()`, `ctx:TimeLeft()`, `cleanup(ctx)`, `EventManager.finish(reason)`, `EventManager.start(id, opts)`, `EventManager.stop()`, `EventManager.current()`, `EventManager.pickNext(exclude)`, `EventManager.skipTimer()`, `EventManager.skipPhase()`, `EventManager.secondsUntilNext()`, `EventManager.run()`

### `Booth`
`src/ServerScriptService/Events/EventModules/Booth.luau` · ModuleScript · 365 lines

**Functions:** `fx.fly(obj, fromCF, toCF, height, dur, spin)`, `set(cf)`, `fx.move(obj, toCF, dur, style, dir)`, `fx.burst(pos, color, count, speed, size)`, `fx.confetti(B)`, `fx.sound(B, key, vol, pitch)`, `fx.hand(B)`, `fx.anim(B, name, speed)`, `fx.say(B, text)`, `fx.at(B, x, y, z)`, `fx.part(parent, name, size, cf, color, mat, shape)`, `fx.temp(B, inst)`, `makeBillboard(B)`, `setStatus(B)`, `rigOf(ch)`, `occupy(ctx, B, player)`, `release(B)`, `M.Setup(ctx)`, `M.play(ctx, player, B)`, `M.give(ctx, player, s, t)`, `M.closeSession(ctx, player, s)`, `M.OnAction(ctx, player, action, data)`, `M.OnPlayerLeft(ctx, player)`, `M.Finish(ctx)`

### `BalloonPop`
`src/ServerScriptService/Events/EventModules/BoothGames/BalloonPop.luau` · ModuleScript · 81 lines

🎈 BALLOON POP: press Play, then click/tap the balloons on the booth wall for 20 seconds (+1 ticket each). Each click throws a real dart from the player's hand: the balloon bursts and the dart sticks in the cork. Pops are checked on the server (ClickDetector + only the player at this booth + time left).

**Functions:** `show(slot, on)`, `G.HandProp(fx)`, `G.Bind(ctx, B, fx)`, `onClick(player)`, `G.Start(ctx, player, s, B, fx)`, `G.Action(ctx, player, s, data, B, fx)`, `G.Stop(ctx, player, s, B, fx)`

### `GuessNumber`
`src/ServerScriptService/Events/EventModules/BoothGames/GuessNumber.luau` · ModuleScript · 72 lines

🔮 GUESS THE NUMBER: the fortune-teller booth thinks of 1–50. Fewer guesses = more tickets (max 6). Every guess shows on the big LED board (with HIGHER / LOWER) so the crowd can help!

**Functions:** `board(B)`, `idle(B)`, `glow(B, color)`, `G.Bind(ctx, B, fx)`, `G.Start(ctx, player, s, B, fx)`, `G.Action(ctx, player, s, data, B, fx)`, `G.Stop(ctx, player, s, B, fx)`

### `HoopShot`
`src/ServerScriptService/Events/EventModules/BoothGames/HoopShot.luau` · ModuleScript · 70 lines

🏀 HOOP SHOT: 3 shots. Stop the marker in the green zone to sink the basket (+3 tickets each). The ball really arcs from the player's hands into the hoop (or clangs off the rim) for everyone to see.

**Functions:** `makeBall(fx)`, `G.HandProp(fx)`, `setScreen(B, text)`, `G.Start(ctx, player, s, B, fx)`, `shoot(B, fx, hit, baskets)`, `G.Action(ctx, player, s, data, B, fx)`

### `LuckyWheel`
`src/ServerScriptService/Events/EventModules/BoothGames/LuckyWheel.luau` · ModuleScript · 82 lines

🎡 LUCKY WHEEL: one free spin per player per fair. The SERVER picks the prize, and the big wheel on the stall really spins (with clicks) and stops on that prize for everyone to see.

**Functions:** `G.Bind(ctx, B, fx)`, `pivotAt(B, phi)`, `angleFor(B, blade)`, `G.Start(ctx, player, s, B, fx)`, `spin(B, fx, prizeIndex, done)`, `G.Action(ctx, player, s, data, B, fx)`

### `MemoryMatch`
`src/ServerScriptService/Events/EventModules/BoothGames/MemoryMatch.luau` · ModuleScript · 84 lines

🃏 MEMORY MATCH: 16 face-down cards in a 4 x 4 grid (8 pairs). Match them all in 75 seconds; fewer moves = more tickets. The big cards on the stall wall flip over for everyone to see. Faces stay on the server until flipped.

**Functions:** `G.Bind(ctx, B, fx)`, `flip(B, fx, i, up)`, `resetCards(B)`, `G.Start(ctx, player, s, B, fx)`, `G.Action(ctx, player, s, data, B, fx)`, `G.Stop(ctx, player, s, B, fx)`

### `RingToss`
`src/ServerScriptService/Events/EventModules/BoothGames/RingToss.luau` · ModuleScript · 72 lines

⭕ RING TOSS: 3 rings. Stop the moving marker in the green zone to ring a bottle (+2 tickets each). Everyone around sees the ring fly from the player's hand and land on (or bounce off) a bottle.

**Functions:** `makeRing(fx, color)`, `G.HandProp(fx)`, `G.Bind(ctx, B, fx)`, `G.Start(ctx, player, s, B, fx)`, `throw(B, fx, hit)`, `G.Action(ctx, player, s, data, B, fx)`

### `TargetThrow`
`src/ServerScriptService/Events/EventModules/BoothGames/TargetThrow.luau` · ModuleScript · 68 lines

🎯 DART THROW: 3 darts. Bullseye = 3 tickets, inner ring = 2, outer ring = 1. The dart really flies to the board and sticks where it landed (everyone can see it).

**Functions:** `makeDart(fx, color)`, `G.HandProp(fx)`, `zones(c)`, `G.Start(ctx, player, s, B, fx)`, `throw(B, fx, t)`, `G.Action(ctx, player, s, data, B, fx)`

### `WhackAMole`
`src/ServerScriptService/Events/EventModules/BoothGames/WhackAMole.luau` · ModuleScript · 98 lines

🔨 WHACK-A-MOLE: 20 seconds. Moles pop out of the 9 holes in the cabinet — click/tap them! +1 ticket per mole, golden moles +3. The player swings a real mallet and the moles really pop up and get bonked, so everyone watching sees the game. Whacks are checked on the server.

**Functions:** `G.HandProp(fx)`, `setScreen(B, text)`, `G.Bind(ctx, B, fx)`, `onClick(player)`, `lowerAll(B)`, `G.Start(ctx, player, s, B, fx)`, `G.Action(ctx, player, s, data, B, fx)`, `G.Stop(ctx, player, s, B, fx)`

### `_Meter`
`src/ServerScriptService/Events/EventModules/BoothGames/_Meter.luau` · ModuleScript · 15 lines

**Functions:** `Meter.position(startClock)`, `Meter.newCenter()`

### `CampusCheckIn`
`src/ServerScriptService/Events/EventModules/CampusCheckIn.luau` · ModuleScript · 79 lines

**Functions:** `pickArea()`, `M.Setup(ctx)`, `M.Start(ctx)`, `M.OnPlayerLeft(ctx, player)`

### `EscapeSchool`
`src/ServerScriptService/Events/EventModules/EscapeSchool.luau` · ModuleScript · 575 lines

**Functions:** `part(parent, name, size, cf, color, mat, props)`, `billboard(adornee, text, color, offset, dist, size)`, `findRoom(name)`, `boundsOf(inst)`, `floorSpot(room, exclude)`, `teamCount(ctx)`, `buildKey(ctx, def)`, `keyEffect(ctx, k, def)`, `M.takeKey(ctx, player, def)`, `M.sendHud(ctx, player, extra)`, `routeFromAnchors(name)`, `routeFromRooms(names)`, `sortAlong(pts)`, `computePath(from, to)`, `setupAnimations(n)`, `gesture(n, name, seconds)`, `makeNpc(ctx, kind, at)`, `canSee(ctx, n, player)`, `walkPath(n, waypoints, shouldStop)`, `runNpc(ctx, n)`, `senses(ctx)`, `M.catch(ctx, player, n)`, `M.Setup(ctx)`, `M.CanJoin(ctx, player)`, `M.unlock(ctx, player)`, `M.Start(ctx)`, `M.OnPlayerLeft(ctx, p)`, `M.Finish(ctx)`, `M.Cleanup(ctx)`

### `FoundationDay`
`src/ServerScriptService/Events/EventModules/FoundationDay.luau` · ModuleScript · 1312 lines

**Functions:** `part(parent, name, size, cf, color, mat, props)`, `deco(parent, name, size, cf, color, mat, extra)`, `cyl(parent, name, a, b, d, color, mat, props)`, `sign(p, face, text, bg, fg, ppS, font)`, `facing(pos, dir)`, `balloons(parent, at)`, `bunting(parent, a, b, sag)`, `prompt(parent, action, object, dist, hold)`, `rootOf(p)`, `torsoOf(char)`, `weld(a, b)`, `attachTo(char, base, name, size, offset, color, mat)`, `ensureJoined(ctx, player)`, `segOf(ctx)`, `candidateList(ctx)`, `state(ctx)`, `pushState(ctx)`, `setSash(player, text, gold)`, `giveCrown(player, small)`, `clearRegalia(player, keepCrown)`, `holdItem(player, build, seconds)`, `sfx(at, id, vol)`, `buildBooth(ctx, parent, pos, faceDir, title, icon, color, props, actionText, onUse)`, `at(x, y, z)`, `buildDecoration(parent, spot)`, `buildFloat(parent, def)`, `spawnDancer(parent, cf, colors, label)`, `playDance(rig, animId)`, `firework(ctx, center)`, `M.Setup(ctx)`, `lbl(name, y, h, text, color, font)`, `eat(player, food, anchor)`, `candOf(ctx, player)`, `M.register(ctx, player, title)`, `allCands(ctx)`, `bringToStage(ctx)`, `onStage(player)`, `nearStage(player)`, `tally(ctx, votes, list)`, `M.vote(ctx, player, kind, targetId, title)`, `crowning(ctx)`, `spawnPrizes(ctx)`, `moveLattice(ctx, y)`, `rememberLattice(ctx)`, `runPabitin(ctx, rounds)`, `M.joinSack(ctx, player, lane)`, `setRacerSpeed(player, on)`, `M.sackFinish(ctx, player)`, `runSackHeat(ctx, heat)`, `loadDances()`, `startGuestShow(ctx)`, `endGuestShow(ctx)`, `setScreen(ctx, now, sub)`, `placeFloats(ctx, hidden)`, `routePoint(d)`, `enterSegment(ctx, i)`, `M.Start(ctx)`, `M.OnAction(ctx, player, action, data)`, `M.Finish(ctx)`, `M.Cleanup(ctx)`

### `GuessTheDrawing`
`src/ServerScriptService/Events/EventModules/GuessTheDrawing.luau` · ModuleScript · 492 lines

**Functions:** `pickArea()`, `part(parent, name, size, cf, color, mat, props)`, `normalize(s)`, `isClose(a, b)`, `filtered(text, player)`, `classroomBoards()`, `sgui(p, ppS)`, `tlabel(parent, name, size, pos, text, color, font, align)`, `buildClassroomBoard(ctx, B)`, `at(x, yy)`, `M.Setup(ctx)`, `boardInfo(ctx, text)`, `bset(ctx, key, text)`, `boardFeed(ctx, text, good)`, `boardLeaders(ctx)`, `toSpectators(ctx, payload)`, `chooseDrawer(ctx)`, `hint(word, revealed)`, `runRound(ctx, drawer, word, isBot)`, `M.Start(ctx)`, `M.OnAction(ctx, player, action, data)`, `M.OnPlayerLeft(ctx, player)`, `M.Finish(ctx)`, `M.Cleanup(ctx)`

### `Intramurals`
`src/ServerScriptService/Events/EventModules/Intramurals.luau` · ModuleScript · 78 lines

**Functions:** `signals()`, `M.Setup(ctx)`, `M.Start(ctx)`, `M.Finish(ctx)`, `M.Cleanup(ctx)`

### `QuizBee`
`src/ServerScriptService/Events/EventModules/QuizBee.luau` · ModuleScript · 316 lines

**Functions:** `setupGroups()`, `setCharGroup(char, group)`, `shuffle(t)`, `gatherQuestions(dept, course, grade, need, markUsed)`, `add(list, isMain)`, `rank(q)`, `roomAllowed(anchor, serverType)`, `pickRoom(ctx)`, `part(parent, name, size, cf, color, props)`, `M.Setup(ctx)`, `M.CanJoin(ctx, player)`, `M.enterRoom(ctx, player)`, `M.sendQuestion(ctx, player)`, `moveOutsiders(ctx)`, `M.Start(ctx)`, `M.OnAction(ctx, player, action, data)`, `M.OnPlayerLeft(ctx, player)`, `M.Finish(ctx)`, `M.Cleanup(ctx)`

### `TowerGame`
`src/ServerScriptService/Events/EventModules/TowerGame.luau` · ModuleScript · 668 lines

**Functions:** `nameOf(userId)`, `fmt(sec)`, `saveGlobal(player, time)`, `part(parent, name, size, cf, color, mat, props)`, `sign(p, face, text, bg, fg, ppS)`, `playerFrom(hit)`, `lobbySpawn(ctx)`, `hud(ctx, p, extra)`, `teleport(ctx, p, pos)`, `resetRun(ctx, p, why, toLobby)`, `hurt(ctx, p, amount)`, `win(ctx, p)`, `M.refreshBoard(ctx)`, `lines(list, f)`, `makeApi(ctx, folder, SF, color, G)`, `api.at(x, y, z)`, `api.part(name, size, cf, col, mat, props)`, `api.rawPart(name, size, cf, col, mat, props)`, `api.danger(p, amount)`, `api.ghost(p, delayTime, back)`, `api.mover(p, offset, time)`, `api.spinner(y, length, speed)`, `api.swing(pivotLocal, length, yaw, speed, phase)`, `api.laser(yLow, yHigh, z, time, alongX)`, `api.conveyor(p, dir, speed)`, `api.lavaFloor()`, `api.truss(cf, height)`, `api.beam(a, b, width, isLocal)`, `scaled(list)`, `api.paths.diagonal()`, `api.paths.perimeter()`, `api.paths.zigzag()`, `api.paths.snake()`, `api.paths.spiral()`, `api.steps(points, opts)`, `pointAt(d)`, `seat(parent, name, cf)`, `M.buildDeck(ctx, folder, base, G)`, `at(x, y, z)`, `M.Setup(ctx)`, `lab(text, pos, size, font, col, align)`, `M.Start(ctx)`, `M.OnPlayerLeft(ctx, p)`, `M.Finish(ctx)`, `M.Cleanup(ctx)`

### `BeamWalk`
`src/ServerScriptService/Events/EventModules/TowerSections/BeamWalk.luau` · ModuleScript · 11 lines

Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1) Tower floor module. Build(api) creates the floor in its own local space: x / z from -20 to 20 (inside the walls), y = 0 is the floor, the floor is 24 tall. You ENTER at corner (-16, -16) and must reach the exit platform at (15, 17.5, 15). Helpers: api.steps(path, opts) • api.paths.* • api.part • api.at • api.kill • api.ghost api.mo

### `ConveyorBridges`
`src/ServerScriptService/Events/EventModules/TowerSections/ConveyorBridges.luau` · ModuleScript · 14 lines

Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1) Tower floor module. Build(api) creates the floor in its own local space: x / z from -20 to 20 (inside the walls), y = 0 is the floor, the floor is 24 tall. You ENTER at corner (-16, -16) and must reach the exit platform at (15, 17.5, 15). Helpers: api.steps(path, opts) • api.paths.* • api.part • api.at • api.kill • api.ghost api.mo

### `CrumblePath`
`src/ServerScriptService/Events/EventModules/TowerSections/CrumblePath.luau` · ModuleScript · 10 lines

Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1) Tower floor module (original design). Build(api) works in the floor's local space: x / z from -api.HALF to api.HALF, y = 0 is the floor, api.H tall. Enter at (api.ENTRY, 0, api.ENTRY); reach the exit platform at (api.EXIT, api.EXIT_TOP, api.EXIT). Helpers: api.steps • api.paths.* • api.part • api.at • api.danger(part, dmg) • api.gh

### `DangerStairs`
`src/ServerScriptService/Events/EventModules/TowerSections/DangerStairs.luau` · ModuleScript · 22 lines

Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1) Tower floor module. Build(api) creates the floor in its own local space: x / z from -20 to 20 (inside the walls), y = 0 is the floor, the floor is 24 tall. You ENTER at corner (-16, -16) and must reach the exit platform at (15, 17.5, 15). Helpers: api.steps(path, opts) • api.paths.* • api.part • api.at • api.kill • api.ghost api.mo

### `GhostTiles`
`src/ServerScriptService/Events/EventModules/TowerSections/GhostTiles.luau` · ModuleScript · 10 lines

Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1) Tower floor module. Build(api) creates the floor in its own local space: x / z from -20 to 20 (inside the walls), y = 0 is the floor, the floor is 24 tall. You ENTER at corner (-16, -16) and must reach the exit platform at (15, 17.5, 15). Helpers: api.steps(path, opts) • api.paths.* • api.part • api.at • api.kill • api.ghost api.mo

### `LaserGrid`
`src/ServerScriptService/Events/EventModules/TowerSections/LaserGrid.luau` · ModuleScript · 15 lines

Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1) Tower floor module (original design). Build(api) works in the floor's local space: x / z from -api.HALF to api.HALF, y = 0 is the floor, api.H tall. Enter at (api.ENTRY, 0, api.ENTRY); reach the exit platform at (api.EXIT, api.EXIT_TOP, api.EXIT). Helpers: api.steps • api.paths.* • api.part • api.at • api.danger(part, dmg) • api.gh

### `LavaLake`
`src/ServerScriptService/Events/EventModules/TowerSections/LavaLake.luau` · ModuleScript · 10 lines

Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1) Tower floor module. Build(api) creates the floor in its own local space: x / z from -20 to 20 (inside the walls), y = 0 is the floor, the floor is 24 tall. You ENTER at corner (-16, -16) and must reach the exit platform at (15, 17.5, 15). Helpers: api.steps(path, opts) • api.paths.* • api.part • api.at • api.kill • api.ghost api.mo

### `MovingPads`
`src/ServerScriptService/Events/EventModules/TowerSections/MovingPads.luau` · ModuleScript · 9 lines

Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1) Tower floor module. Build(api) creates the floor in its own local space: x / z from -20 to 20 (inside the walls), y = 0 is the floor, the floor is 24 tall. You ENTER at corner (-16, -16) and must reach the exit platform at (15, 17.5, 15). Helpers: api.steps(path, opts) • api.paths.* • api.part • api.at • api.kill • api.ghost api.mo

### `NarrowPegs`
`src/ServerScriptService/Events/EventModules/TowerSections/NarrowPegs.luau` · ModuleScript · 9 lines

Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1) Tower floor module. Build(api) creates the floor in its own local space: x / z from -20 to 20 (inside the walls), y = 0 is the floor, the floor is 24 tall. You ENTER at corner (-16, -16) and must reach the exit platform at (15, 17.5, 15). Helpers: api.steps(path, opts) • api.paths.* • api.part • api.at • api.kill • api.ghost api.mo

### `PillarHop`
`src/ServerScriptService/Events/EventModules/TowerSections/PillarHop.luau` · ModuleScript · 12 lines

Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1) Tower floor module (original design). Build(api) works in the floor's local space: x / z from -api.HALF to api.HALF, y = 0 is the floor, api.H tall. Enter at (api.ENTRY, 0, api.ENTRY); reach the exit platform at (api.EXIT, api.EXIT_TOP, api.EXIT). Helpers: api.steps • api.paths.* • api.part • api.at • api.danger(part, dmg) • api.gh

### `SpinnerHall`
`src/ServerScriptService/Events/EventModules/TowerSections/SpinnerHall.luau` · ModuleScript · 12 lines

Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1) Tower floor module (original design). Build(api) works in the floor's local space: x / z from -api.HALF to api.HALF, y = 0 is the floor, api.H tall. Enter at (api.ENTRY, 0, api.ENTRY); reach the exit platform at (api.EXIT, api.EXIT_TOP, api.EXIT). Helpers: api.steps • api.paths.* • api.part • api.at • api.danger(part, dmg) • api.gh

### `SteppingStones`
`src/ServerScriptService/Events/EventModules/TowerSections/SteppingStones.luau` · ModuleScript · 9 lines

Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1) Tower floor module. Build(api) creates the floor in its own local space: x / z from -20 to 20 (inside the walls), y = 0 is the floor, the floor is 24 tall. You ENTER at corner (-16, -16) and must reach the exit platform at (15, 17.5, 15). Helpers: api.steps(path, opts) • api.paths.* • api.part • api.at • api.kill • api.ghost api.mo

### `SwingingBars`
`src/ServerScriptService/Events/EventModules/TowerSections/SwingingBars.luau` · ModuleScript · 20 lines

Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1) Tower floor module (original design). Build(api) works in the floor's local space: x / z from -api.HALF to api.HALF, y = 0 is the floor, api.H tall. Enter at (api.ENTRY, 0, api.ENTRY); reach the exit platform at (api.EXIT, api.EXIT_TOP, api.EXIT). Helpers: api.steps • api.paths.* • api.part • api.at • api.danger(part, dmg) • api.gh

### `TrussTower`
`src/ServerScriptService/Events/EventModules/TowerSections/TrussTower.luau` · ModuleScript · 22 lines

Difficulty: 1 easy • 2 medium • 3 hard (the top floors only use 1) Tower floor module (original design). Build(api) works in the floor's local space: x / z from -api.HALF to api.HALF, y = 0 is the floor, api.H tall. Enter at (api.ENTRY, 0, api.ENTRY); reach the exit platform at (api.EXIT, api.EXIT_TOP, api.EXIT). Helpers: api.steps • api.paths.* • api.part • api.at • api.danger(part, dmg) • api.gh

### `EventRewards`
`src/ServerScriptService/Events/EventRewards.luau` · ModuleScript · 223 lines

**Functions:** `EventRewards.saveSoon(player)`, `EventRewards.addCurrency(player, currency, amount)`, `bump(player, stat, n)`, `EventRewards.countJoin(player, def)`, `EventRewards.grantAchievement(player, id)`, `restore(player)`, `syncLevel(player)`, `checkMilestones(player, lvl, announce)`, `EventRewards.addXP(player, amount, reason)`, `EventRewards.xpFor(def, place, hasBonus)`, `initLevel(player)`, `keyOf(def)`, `EventRewards.payEvent(def, ranking, participants, extra, eligible)`

### `Pack_ABM`
`src/ServerScriptService/Events/QuizBeeBank/Pack_ABM.luau` · ModuleScript · 106 lines

Quiz Bee pack: SHS ABM (Accountancy, Business & Management). Format: { question, RIGHT answer, wrong, wrong, wrong }

_Data module._

### `Pack_BSCRIM`
`src/ServerScriptService/Events/QuizBeeBank/Pack_BSCRIM.luau` · ModuleScript · 109 lines

Quiz Bee pack: College BS Criminology. Format: { question, RIGHT answer, wrong, wrong, wrong }

_Data module._

### `Pack_BSEd`
`src/ServerScriptService/Events/QuizBeeBank/Pack_BSEd.luau` · ModuleScript · 109 lines

Quiz Bee pack: College BSEd (Teacher Education). Format: { question, RIGHT answer, wrong, wrong, wrong }

_Data module._

### `Pack_BSIT`
`src/ServerScriptService/Events/QuizBeeBank/Pack_BSIT.luau` · ModuleScript · 119 lines

Quiz Bee pack: College BSIT. Format: { question, RIGHT answer, wrong, wrong, wrong }

_Data module._

### `Pack_Elementary`
`src/ServerScriptService/Events/QuizBeeBank/Pack_Elementary.luau` · ModuleScript · 111 lines

Quiz Bee pack: Elementary (Grades 4-6). Format: { question, RIGHT answer, wrong, wrong, wrong } (options are shuffled in-game)

_Data module._

### `Pack_GAS`
`src/ServerScriptService/Events/QuizBeeBank/Pack_GAS.luau` · ModuleScript · 106 lines

Quiz Bee pack: SHS GAS (General Academic Strand). Format: { question, RIGHT answer, wrong, wrong, wrong }

_Data module._

### `Pack_HUMSS`
`src/ServerScriptService/Events/QuizBeeBank/Pack_HUMSS.luau` · ModuleScript · 106 lines

Quiz Bee pack: SHS HUMSS. Format: { question, RIGHT answer, wrong, wrong, wrong }

_Data module._

### `Pack_JuniorHigh`
`src/ServerScriptService/Events/QuizBeeBank/Pack_JuniorHigh.luau` · ModuleScript · 107 lines

Quiz Bee pack: Junior High School (Grades 7-10). Format: { question, RIGHT answer, wrong, wrong, wrong }

_Data module._

### `Pack_STEM`
`src/ServerScriptService/Events/QuizBeeBank/Pack_STEM.luau` · ModuleScript · 108 lines

Quiz Bee pack: SHS STEM. Format: { question, RIGHT answer, wrong, wrong, wrong }

_Data module._

### `Pack_TVL_ICT`
`src/ServerScriptService/Events/QuizBeeBank/Pack_TVL_ICT.luau` · ModuleScript · 106 lines

Quiz Bee pack: SHS TVL-ICT. Format: { question, RIGHT answer, wrong, wrong, wrong }

_Data module._

### `QuizBeeBank`
`src/ServerScriptService/Events/QuizBeeBank/init.luau` · ModuleScript · 252 lines

### `FacultyKnock`
`src/ServerScriptService/FacultyKnock.server.luau` · Script (server) · 33 lines

Knock on the Faculty Room door: bubble at the door, visitor lamp flashes inside, notice to everyone inside.

### `FallRescue`
`src/ServerScriptService/FallRescue.server.luau` · Script (server) · 42 lines

FallRescue: the campus is a floating island now. Anyone who falls off the edge is brought back (players → the spawn, campus NPCs → the main gate) instead of falling forever.

**Functions:** `spawnPoint()`, `gatePoint()`

### `FlashlightServer`
`src/ServerScriptService/FlashlightServer.server.luau` · Script (server) · 112 lines

**Functions:** `isFlashlight(t)`, `apply(tool, on, power)`, `setOn(tool, on)`, `gripBase(tool)`, `restore(player)`, `setAim(player, tool, pitch)`

### `GearServer`
`src/ServerScriptService/GearServer.server.luau` · Script (server) · 92 lines

**Functions:** `trail(parent, a0pos, a1pos, life, width)`, `cleanup(tool)`, `onEquipped(player, character, tool)`, `onUnequipped(player, character, tool)`, `watchCharacter(player, character)`, `onPlayer(player)`

### `GuardPatrol`
`src/ServerScriptService/GuardPatrol.server.luau` · Script (server) · 229 lines

GuardPatrol.lua Makes every NPC with a "PatrolRoute" attribute walk between the markers in Workspace.PatrolRoutes.<RouteName> (parts named 1, 2, 3...). Route folder attribute "Mode": "Loop" (1-2-3-4-1...) or "PingPong" (1-2-3-2-1...). When a player opens the guard's ProximityPrompt, the guard stops and faces them. Drag the markers in Studio to change where the guards walk.

**Functions:** `getWaypoints(routeName)`, `setupAnimations(humanoid)`, `flatDistance(a, b)`, `walkTo(guard, humanoid, root, target)`, `startPatrol(guard)`

### `HUDServer`
`src/ServerScriptService/HUDServer.server.luau` · Script (server) · 63 lines

HUDServer.lua Handles Map teleports (only to places listed in HUDConfig) and the Elementary / Junior High+ server switch from the Settings panel.

### `HostingServer`
`src/ServerScriptService/HostingServer.server.luau` · Script (server) · 438 lines

**Functions:** `boundsOf(inst)`, `spotIn(R)`, `insideBox(R, pos, pad)`, `eventIn(R)`, `teleport(p, pos)`, `toSpawn(p)`, `countOf(S)`, `view(S, forHost)`, `push()`, `toast(p, text)`, `updateSign(S)`, `makeSign(S)`, `sign(pos, dist)`, `setAttrs(p, S)`, `leave(p)`, `endSession(S, why)`, `join(p, S)`, `filterTitle(text, player)`, `roomState(R)`, `handlers.state(p)`, `handlers.rooms(p)`, `handlers.host(p, d)`, `handlers.invite(p, d)`, `canEnter(p, S)`, `handlers.accept(p, d)`, `handlers.decline(p, d)`, `handlers.leave(p)`, `handlers.kick(p, d)`, `handlers.bring(p)`, `handlers.goto(p)`, `handlers.privacy(p)`

### `KnockDoors`
`src/ServerScriptService/KnockDoors.server.luau` · Script (server) · 52 lines

KnockDoors: staff-only doors that cannot be opened, but you can knock on them. A door is a Model tagged "KnockDoor" with: ProximityPrompt (any name) -> "Knock" part "Leaf"                -> shakes a little when someone knocks optional attribute Reply   -> text shown above the door for a few seconds

**Functions:** `setup(m)`

### `LeaderboardServer`
`src/ServerScriptService/LeaderboardServer.server.luau` · Script (server) · 177 lines

**Functions:** `storeOf(t)`, `loaded(p)`, `liveValue(p, t)`, `nameOf(id)`, `better(t, a, b)`, `publish(key)`, `reload(key)`, `writePlayer(p)`

### `LevelServer`
`src/ServerScriptService/LevelServer.server.luau` · Script (server) · 219 lines

LevelServer: school level (Title) progression. New players start at Kindergarten. To unlock the next level a player must 1) spend the level's minutes AT their current level (LevelConfig.minutesFor) — this "level timer" is separate from total play time and resets after each passed quiz or when an admin promotes/demotes the player, and 2) pass the quiz of their current highest level (server-graded).

**Functions:** `roleTag(player)`, `setTitle(player)`, `feedback(player, msg, good)`, `onPlayer(player)`, `shuffle(t)`, `pickFresh(player, levelName, bank, n)`

### `LibraryTimeIn`
`src/ServerScriptService/LibraryTimeIn.server.luau` · Script (server) · 115 lines

Library time-in kiosk (tag a model "LibraryKiosk"; it needs a ProximityPrompt and a part named "LibraryLogBoard" with a SurfaceGui "LogGui" > Root > Entries). Tap / click the kiosk tablet or press E → the student picks a purpose → they are timed in, shown where to go, and listed on the "Library Log — Today" board.

**Functions:** `manilaTime()`, `boardsAndKiosks()`, `refreshBoards()`, `cell(text, x, w, color, font)`, `nearKiosk(player)`, `open(player)`, `setup(k)`

### `LightSwitches`
`src/ServerScriptService/LightSwitches.server.luau` · Script (server) · 73 lines

LightSwitches: wall switches that turn a group of lights on/off and change brightness. A switch is a Model tagged "LightSwitch" with: ObjectValue "Lights"  -> the folder/model holding the lights (PointLight / SpotLight / SurfaceLight + Neon bulbs) ProximityPrompt "PowerPrompt"      (E)  on / off ProximityPrompt "BrightnessPrompt" (R)  Low -> Medium -> High optional part "Indicator" (green when on)

**Functions:** `setup(sw)`, `apply()`

### `MusicServer`
`src/ServerScriptService/MusicServer.server.luau` · Script (server) · 204 lines

**Functions:** `cleanIds(list)`, `clean(d)`, `saveNow(player)`, `loadData(player)`, `partyInfo(p)`, `broadcast(p, ...)`, `leave(player)`, `validState(s)`

### `OpenClosedSigns`
`src/ServerScriptService/OpenClosedSigns.server.luau` · Script (server) · 22 lines

Tag a part "OpenClosedSign" (with SurfaceGui SignGui > Card > Top/Mid/Bot): tap/click/E flips OPEN <-> CLOSED.

**Functions:** `render(p)`, `setup(p)`, `flip()`

### `PlayerBusy`
`src/ServerScriptService/PlayerBusy.luau` · ModuleScript · 32 lines

**Functions:** `M.reason(player, opts)`, `M.isBusy(player, opts)`

### `PlayerData`
`src/ServerScriptService/PlayerData.luau` · ModuleScript · 189 lines

PlayerData: saves & loads progress with DataStore. Saved: total play Time, level timer, Title, level, Common/Event coins, owned items, equipped items, consumable counts, event statistics and event Achievements.

**Functions:** `PlayerData.key(userId)`, `key(player)`, `PlayerData.fresh()`, `normalize(data)`, `PlayerData.load(player)`, `PlayerData.get(player)`, `PlayerData.hasStore()`, `PlayerData.getTime(player)`, `PlayerData.setTime(player, seconds)`, `PlayerData.getLevelTime(player)`, `PlayerData.setLevelTime(player, seconds)`, `PlayerData.resetLevelTime(player)`, `snapshot(player)`, `PlayerData.save(player)`, `PlayerData.readOffline(userId)`, `PlayerData.updateOffline(userId, fn)`, `PlayerData.lastSnapshot(userId)`, `PlayerData.release(player)`

### `PlayerRecords`
`src/ServerScriptService/PlayerRecords.luau` · ModuleScript · 600 lines

PlayerRecords: who is online in every server, where they are on campus, and every time in / time out. Shown in the admin panel (📋 Player Records). What is kept: SamarCollege_Sessions_v1  DataStore         u_<UserId>: name, first join, last time in / out, number of joins, a progress summary and the last 40 sessions (time in, time out, server) SamarCollege_LastSeen_v1  OrderedDataStore  <UserId> = l

**Functions:** `PlayerRecords.isLive()`, `bg(fn)`, `partBounds(p)`, `boundsOf(inst)`, `nice(name)`, `addZone(label, mn, mx, minHeight)`, `buildZones()`, `spot(label, inst, h)`, `PlayerRecords.areaOf(player)`, `cacheDrop(id)`, `summaryOf(p)`, `serverInfo()`, `presenceOf(p)`, `feedKey(t, userId)`, `onJoin(p)`, `onLeave(p)`, `heartbeat()`, `getRecord(id)`, `PlayerRecords.online(force)`, `PlayerRecords.presence(userId)`, `PlayerRecords.serverOf(job)`, `PlayerRecords.brief(userId)`, `buildRow(id, value, sort, byId)`, `PlayerRecords.list(callerId, sort, more)`, `PlayerRecords.history(userId)`, `PlayerRecords.activity()`, `PlayerRecords.backfill()`

### `PlayerReports`
`src/ServerScriptService/PlayerReports.luau` · ModuleScript · 317 lines

PlayerReports: players report someone who breaks the rules, and the admin team checks every report. A report goes:  🟡 Waiting for review  ->  🔍 Investigating (by an admin)  ->  ✅ Done (checked by an admin, with the result and the proof). Every change is written in the report's history with who did it. Saved in: SamarCollege_Reports_v1          DataStore         r_<id> = the report,  t_<UserId> = i

**Functions:** `announce(msg)`, `broadcast(msg)`, `clean(text, max)`, `filterText(text, fromUserId)`, `getReport(id, fresh)`, `decorate(r)`, `PlayerReports.counts()`, `PlayerReports.countFor(userId)`, `PlayerReports.list(callerId, filter, more, target)`, `PlayerReports.submit(player, targetId, reasonId, details)`, `PlayerReports.create(by, who, reasonId, text)`, `PlayerReports.setStatus(caller, role, id, status, outcome, note)`

### `PowerAndLED`
`src/ServerScriptService/PowerAndLED.server.luau` · Script (server) · 244 lines

PowerAndLED 1) LED borders: Model tagged "LEDBorder" holding parts named "LEDStrip" (attribute Index = order for chase) and Light objects. Attributes: On (bool), Mode ("Steady" | "Breathing" | "Chase"). A switch is a Model tagged "LEDSwitch" (+ TapToUse) with ObjectValue "Target" -> the LED model. Tapping the switch toggles On; a part named "ModeButton" inside the switch cycles the Mode. 2) Main p

**Functions:** `setupBorder(m)`, `renderBorder(m, info, t)`, `setupLEDSwitch(sw)`, `sync()`, `showMode()`, `isEmergency(inst)`, `inPanel(inst, panel)`, `guardAttr(inst, attr, value)`, `guardProp(inst, prop, value)`, `powerOff(panel)`, `powerOn()`, `setupMain(panel)`, `lamps(on)`

### `PowerToggles`
`src/ServerScriptService/PowerToggles.server.luau` · Script (server) · 96 lines

PowerToggles: devices you can switch on and off (aircon, computers, TV, desk lamps ...). A device is a Model tagged "PowerToggle" with: ProximityPrompt "PowerPrompt" (anywhere inside; on the control panel, screen or lamp) attributes: DeviceName ("aircon", "computer" ...), On (true / false), Key ("E" or "F", optional) What changes when it is on / off: Light objects                -> Enabled Particl

**Functions:** `setup(device)`, `apply(animate)`

### `PrincipalKnock`
`src/ServerScriptService/PrincipalKnock.server.luau` · Script (server) · 28 lines

Knock at the Principal's Office (Elementary): bubble at the door + notice to anyone inside.

### `PromptSeats`
`src/ServerScriptService/PromptSeats.server.luau` · Script (server) · 37 lines

Seats tagged "PromptSeat" only seat a player when they press the "Sit" prompt (no accidental sitting when walking past in narrow rooms).

**Functions:** `setup(seat)`

### `Bank_College`
`src/ServerScriptService/QuizBank/Bank_College.luau` · ModuleScript · 218 lines

Bank_College: extra promotion-quiz questions, 1st Year to 4th Year (GE subjects, IT, and a mix of criminology, business and education basics, since every course shares these levels). q(question, CORRECT answer, wrong, wrong, wrong) — the server shuffles the options every quiz.

_Data module._

### `Bank_Elementary`
`src/ServerScriptService/QuizBank/Bank_Elementary.luau` · ModuleScript · 375 lines

Bank_Elementary: extra promotion-quiz questions, Kindergarten to Grade 6. q(question, CORRECT answer, wrong, wrong, wrong) — the server shuffles the options every quiz.

_Data module._

### `Bank_JHS`
`src/ServerScriptService/QuizBank/Bank_JHS.luau` · ModuleScript · 217 lines

Bank_JHS: extra promotion-quiz questions, Grade 7 to Grade 10. q(question, CORRECT answer, wrong, wrong, wrong) — the server shuffles the options every quiz.

_Data module._

### `Bank_SHS`
`src/ServerScriptService/QuizBank/Bank_SHS.luau` · ModuleScript · 111 lines

Bank_SHS: extra promotion-quiz questions, Grade 11 and Grade 12 (Senior High School core subjects). q(question, CORRECT answer, wrong, wrong, wrong) — the server shuffles the options every quiz.

_Data module._

### `QuizBank`
`src/ServerScriptService/QuizBank/init.luau` · ModuleScript · 168 lines

QuizBank: questions per level (key = level name). A = index of the correct option. Pass the quiz of your current level to unlock the next one. Add as many questions as you want; each quiz picks LevelConfig.QuestionsPerQuiz random questions (LevelServer avoids repeats until the player has seen the whole level's list) and shuffles the answer order every time. The big question lists live in the child

### `ROTCPermission`
`src/ServerScriptService/ROTCPermission.server.luau` · Script (server) · 32 lines

Outside the ROTC office: Q / tap "Request permission" -> the cadet's line shows at the door, and everyone inside the office gets a notice.

### `ReportServer`
`src/ServerScriptService/ReportServer.server.luau` · Script (server) · 20 lines

ReportServer: the "Report a player" window (ReportClient) sends reports through here. Everything is checked in PlayerReports (player in this server, reason, cooldowns, text filter).

### `ServerSelectServer`
`src/ServerScriptService/ServerSelectServer.server.luau` · Script (server) · 11 lines

ServerSelectServer: decides if this is the Main or Kid server and handles the loading screen's choice.

### `ServerSwitch`
`src/ServerScriptService/ServerSwitch.luau` · ModuleScript · 85 lines

**Functions:** `elementaryPlace()`, `M.detect()`, `M.current()`, `kidCode(fresh)`, `M.switch(player, target)`, `go(fresh)`

### `SettingsServer`
`src/ServerScriptService/SettingsServer.server.luau` · Script (server) · 87 lines

**Functions:** `publish(p)`, `save(p)`

### `ShopServer`
`src/ServerScriptService/ShopServer.server.luau` · Script (server) · 641 lines

ShopServer.lua Token currencies (Common / Event), purchase validation, equip state, equipment effects and consumable effects. The server validates everything.

**Functions:** `applySpeed(player)`, `speedBoost(player, amount, seconds)`, `findItem(itemId)`, `feedback(player, message)`, `hotbarList(player)`, `saveHotbar(player, list)`, `hotbarAdd(player, id)`, `hotbarRemove(player, id)`, `getCurrency(player, currencyName)`, `getInventory(player)`, `getItemCount(player, itemId)`, `addItem(player, itemId, amount)`, `removeItem(player, itemId, amount)`, `giveTool(player, toolName)`, `removeTool(player, toolName)`, `refreshEquipment(player)`, `refreshCosmetic(player)`, `applyConsumable(player, item)`, `heal(n)`, `onPlayerAdded(player)`, `swapTag(character, text)`, `puff(character)`, `applyLook(player, desc)`, `endSwap(player, why)`

### `SkyClimbServer`
`src/ServerScriptService/SkyClimbServer.server.luau` · Script (server) · 533 lines

**Functions:** `portalSpot()`, `returnSpot()`, `fmt(sec)`, `send(p, msg)`, `toast(p, text)`, `humOf(p)`, `rootOf(p)`, `isReady(p, pos)`, `prestream(p, pos)`, `teleport(p, pos, faceDir)`, `release()`, `lockMovement(p, on)`, `stateOf(p)`, `pushState(p)`, `endRun(p)`, `enterIsland(p)`, `leaveIsland(p)`, `startRun(p, mode)`, `finish(p)`, `trigger(hit)`, `hookPlayer(p)`, `hookField(field)`, `part(name, size, cf, color, mat, props)`, `nameOf(id)`

### `SleepSeats`
`src/ServerScriptService/SleepSeats.server.luau` · Script (server) · 86 lines

**Functions:** `pillowFor(seat)`, `bedTop(seat)`, `layDown(seat, weld)`, `setup(seat)`, `relabel()`

### `SlideShows`
`src/ServerScriptService/SlideShows.server.luau` · Script (server) · 43 lines

SlideShows: smart boards / TVs with several slides. A Model tagged "SlideShow" contains a part named "Screen" whose SurfaceGui holds Frames named Slide_1 ... Slide_N, plus parts named "NextButton" and "PrevButton". Tap the buttons to change slides (wraps around). Works alongside PowerToggle.

**Functions:** `setup(m)`, `show(i)`

### `SlidingBoards`
`src/ServerScriptService/SlidingBoards.server.luau` · Script (server) · 54 lines

SlidingBoards: sliding whiteboard panels that hide / show something behind them (e.g. a TV). A set is a Model tagged "SlidingBoardSet". Each child Model with a Vector3 attribute "OpenOffset" is a panel. Tap / click any panel and every panel in the set slides open (by its OpenOffset) or back closed. The set's "Open" attribute holds the state, so other scripts can open it too.

**Functions:** `setup(set)`, `apply()`

### `SlidingDoors`
`src/ServerScriptService/SlidingDoors.server.luau` · Script (server) · 48 lines

SlidingDoors: E to slide a door open / closed. A door is a Model tagged "SlidingDoor" with: child model "Panel"                -> every part in it slides together ProximityPrompt "DoorPrompt"       -> anywhere inside the model (usually an invisible part in the doorway) optional Sound "SlideSound"        -> plays when the door moves Attribute SlideOffset (Vector3, studs) is how far the panel moves 

**Functions:** `setup(door)`, `set(open)`

### `SlidingWhiteboards`
`src/ServerScriptService/SlidingWhiteboards.server.luau` · Script (server) · 65 lines

SlidingWhiteboards: whiteboards whose middle panels slide sideways to show a TV behind them. A whiteboard is a Model tagged "SlidingWhiteboard" with: child models that have a Vector3 attribute "OpenOffset" (how far they slide when opened) ProximityPrompt "SlidePrompt" (E) somewhere inside (on the slide button) Open/closed state is kept in the "Open" attribute; other scripts can set "RequestOpen" (

**Functions:** `setup(board)`, `setOpen(open)`

### `SlidingWindowsCurtains`
`src/ServerScriptService/SlidingWindowsCurtains.server.luau` · Script (server) · 137 lines

SlidingWindowsCurtains: E to open / close sliding windows and curtains. Models tagged "SlidingWindow": child model "SlidingSash" slides by the unit's SlideX attribute (studs on X) or SlideZ (studs on Z, e.g. drawers in a counter that runs along X). Optional attribute Label (default "window") names it in the prompt, e.g. "drawer". Models tagged "SlidingCurtain": every "Fold" part moves between its 

**Functions:** `partsOf(model)`, `setupWindow(unit)`, `set(open)`, `setupCurtain(model)`, `setupAwning(unit)`

### `BasketballEngine`
`src/ServerScriptService/Sports/BasketballEngine.luau` · ModuleScript · 422 lines

**Functions:** `BB.init(api)`, `other(s)`, `alive(court, seq)`, `viewers(court, msg)`, `hoopOf(court, side)`, `spot(court, side, i, offense, attackSide)`, `root(e)`, `lift(e)`, `runTo(e, pos, lookAt, t)`, `hop(e, up, t)`, `formation(court, side, t)`, `ballPart(court)`, `release(court)`, `hold(court, e)`, `fly(court, from, to, time, height, kind, bounceTo)`, `zonesFor(cfg)`, `clockCheck(court)`, `teamPick(list, notE)`, `possession(court, side, handler, reason)`, `turnover(court, side, why, to)`, `pass(court, from, to)`, `giveTurn(court, e)`, `rebound(court, shooterSide, spotPos)`, `resolveShot(court, sh, blockedBy)`, `shoot(court, e, kind, made)`, `BB.start(court, token)`, `BB.hit(court, player, data)`, `BB.stop(court)`, `BB.clock(court)`

### `ChessEngine`
`src/ServerScriptService/Sports/ChessEngine.luau` · ModuleScript · 285 lines

**Functions:** `idx(f, r)`, `fr(i)`, `colorOf(p)`, `inb(f, r)`, `E.sq(name)`, `E.name(i)`, `E.fromFEN(fen)`, `E.attacked(b, sq, by)`, `E.kingSq(b, color)`, `other(c)`, `E.inCheck(s)`, `E.pseudo(s)`, `add(from, to, flag, promo)`, `slide(list)`, `E.make(s, m)`, `E.legal(s)`, `E.insufficient(b)`, `E.notation(s, m)`, `evaluate(b)`, `order(moves)`, `search(s, depth, alpha, beta, ply)`, `E.bestMove(s, depth, noise)`, `E.key(s)`

### `ChessGame`
`src/ServerScriptService/Sports/ChessGame.luau` · ModuleScript · 314 lines

**Functions:** `G.init(api)`, `sqCF(court, i)`, `folder(court)`, `pieceCF(court, i, p)`, `makePiece(court, i, p)`, `fadeOut(model)`, `sync(court, board)`, `slide(court, from, to, p)`, `animate(court, before, m)`, `fmt(t)`, `clockFace(court)`, `seat(court, e, markerName)`, `unseat(e)`, `who(e)`, `payload(court, extra)`, `push(court, extra)`, `finish(court, winColor, why, text)`, `apply(court, m)`, `cpuMove(court)`, `G.setupIdle(court)`, `G.start(court, token)`, `G.move(court, player, data)`, `G.resign(court, player)`, `G.stop(court)`, `G.reset(court)`

### `SportsServer`
`src/ServerScriptService/Sports/SportsServer.server.luau` · Script (server) · 977 lines

**Functions:** `other(side)`, `names(list)`, `entryOf(court, player)`, `snapshot(court)`, `side(s)`, `updateBoard(court)`, `line(s)`, `broadcast(court)`, `toast(player, text)`, `toastCourt(court, text)`, `buildBoard(court)`, `lbl(name, size, pos, color, font)`, `makePaddle(cfg)`, `p(name, size, cf, color, shape)`, `makeRacket(sportId)`, `loadTracks(e)`, `play(e, name, speed)`, `spotFor(court, side, i)`, `placeEntry(court, e, cf)`, `equip(court, e)`, `unequip(e)`, `makeCpu(court, side)`, `removeEntry(court, e, side, i, quiet)`, `forfeitCheck(court)`, `leaveCourt(player, reason)`, `reset(court)`, `lobbyTick(court)`, `startMatch(court)`, `payout(court, winSide)`, `endMatch(court, winSide, why)`, `meterAt(elapsed, speed)`, `pressedAt(r, clientT)`, `handPos(e)`, `moveTo(e, pos, t)`, `point(court, winSide, reason, landing)`, `cpuRespond(court, r)`, `sendShot(court, hitter, fromSide, shotKey)`, `hop(e, up, t)`, `attack(court, recv, side, key)`, `fx(from, to, time, height, shot)`, `alive()`, `serveRally(court, token)`, `voters(court, exclude)`, `finishVote(court)`, `startVote(court, by, targetId)`, `setupCourt(model)`, `pickCourt(sportId)`, `hookPortals(root)`, `go(player)`, `autoFill(court)`, `insideVenue(player)`, `openVenues()`, `closeVenues()`, `onIntramurals()`, `_G.SC_IntramuralsOpen()`

### `StaffAccess`
`src/ServerScriptService/StaffAccess.luau` · ModuleScript · 27 lines

StaffAccess: who counts as staff / employee for staff-only doors and ID gates. A player is staff when ANY of these is true: player attribute Role is "Teacher", "Staff", "Employee", "Faculty" or "Guard" (the Profile Student/Teacher toggle should set this attribute) player attribute IsStaff == true the player is the game owner (same owner list as AdminServer) Everyone else is treated as a student.

**Functions:** `StaffAccess.isStaff(player)`, `StaffAccess.label(player)`

### `StudioStores`
`src/ServerScriptService/StudioStores.luau` · ModuleScript · 62 lines

StudioStores: stand-ins for DataStores and MemoryStore sorted maps, used only when the real ones are switched off (Studio without "Enable Studio Access to API Services"). They keep data for the current test session and forget it when the test stops.

**Functions:** `StudioStores.dataStore()`, `s:GetAsync(k)`, `s:SetAsync(k, v)`, `s:RemoveAsync(k)`, `s:UpdateAsync(k, fn)`, `s:GetSortedAsync(ascending, pageSize)`, `pages:GetCurrentPage()`, `pages:AdvanceToNextPageAsync()`, `StudioStores.sortedMap()`, `alive(k)`, `m:SetAsync(k, v, ttl)`, `m:GetAsync(k)`, `m:RemoveAsync(k)`, `m:UpdateAsync(k, fn, ttl)`, `m:GetRangeAsync(dir, count)`

### `SuggestionBoxes`
`src/ServerScriptService/SuggestionBoxes.server.luau` · Script (server) · 50 lines

SuggestionBoxes: E to drop a note into a suggestion box. A box is a Model tagged "SuggestionBox" with a ProximityPrompt "DropPrompt" and (optional) a TextLabel named "CountLabel" that shows how many notes were dropped on this server. A player can drop one note every 10 seconds; a paper note pops into the slot for a moment.

**Functions:** `setup(box)`, `refresh()`

### `SwingDoors`
`src/ServerScriptService/SwingDoors.server.luau` · Script (server) · 50 lines

SwingDoors: simple hinged doors (screen doors, gates, cabinet doors) that swing on E. A door is a Model tagged "SwingDoor" with: a part named "HingePin" (the pivot line, vertical) attribute OpenAngle (degrees, + or -)  default 95 attribute ObjectText (prompt label) attribute StartOpen = true to begin open All parts stay anchored; the whole model rotates around the pin.

**Functions:** `setup(m)`, `apply(open, instant)`

### `SwingGates`
`src/ServerScriptService/SwingGates.server.luau` · Script (server) · 58 lines

SwingGates: metal grille gates (one or two leaves) that swing open / closed with E. A gate is a Model tagged "SwingGate" with: leaf models that have a number attribute "OpenAngle" (degrees around Y) and an anchored part "Hinge"; every other part of the leaf is unanchored and welded to its Hinge, so turning the Hinge swings the leaf ProximityPrompt "GatePrompt" somewhere inside (on the lock box) Op

**Functions:** `setup(gate)`, `setOpen(open)`

### `TVAds`
`src/ServerScriptService/TVAds.server.luau` · Script (server) · 56 lines

TVAds: wall TVs that play Samar College ads one after another. A TV is a Model tagged "AdTV" with a part "Screen" whose SurfaceGui holds Frames named Ad_1, Ad_2 ... (one is shown at a time). attribute Interval : seconds per ad (default 6) attribute On       : set by PowerToggles (F); the ads pause while the TV is off attribute Ad       : the ad on screen now ProximityPrompt "AdPrompt" (E, optional

**Functions:** `setup(tv)`, `show(i)`, `nextAd()`, `sync()`

### `TalentShowServer`
`src/ServerScriptService/TalentShowServer.server.luau` · Script (server) · 432 lines

**Functions:** `watcherCount()`, `activitySignal()`, `toast(p, text)`, `performerList()`, `updateLED()`, `broadcast()`, `linkVoice(p)`, `unlinkVoice(p)`, `stopBacking()`, `finish(p, quiet)`, `start(p, mode)`, `holdsMic(p)`, `setStandMic(m, visible)`, `returnMic(m, why)`, `makeMicTool(k)`, `takeMic(p, m, k)`, `hueColor(h, s, v)`, `lightShow(dt)`, `confetti()`, `attach(model)`, `detach()`, `isStage(inst)`, `inZone(p)`

### `TapCurtains`
`src/ServerScriptService/TapCurtains.server.luau` · Script (server) · 50 lines

TapCurtains: tap a curtain to open / close it. The folds bunch to the sides like real curtains. A curtain is a Model tagged "TapCurtain". Each fold part inside it has: attribute OpenCF   (CFrame)  -> where that fold sits when the curtain is open attribute OpenSize (Vector3) -> its size when open (narrower = bunched up) Optional model attribute StartOpen = true opens it when the server starts.

**Functions:** `setup(m)`, `apply(open, instant)`

### `TapDoors`
`src/ServerScriptService/TapDoors.server.luau` · Script (server) · 105 lines

TapDoors: hinged doors you tap / click to open (no E prompt). A door is a Model tagged "TapDoor" with: a part named "HingePin" (vertical pivot line) attribute OpenAngle (degrees, + or -) default 95 attribute AutoClose (seconds, 0 = stays open) default 7 optional Sound named "DoorSound" anywhere inside Parts stay anchored; the whole model rotates around the pin.

**Functions:** `setup(m)`, `setSolid(on)`, `someoneInSwing()`, `setOpen(open)`

### `TapDrawers`
`src/ServerScriptService/TapDrawers.server.luau` · Script (server) · 69 lines

TapDrawers: tap / click a drawer to slide it open, tap again to close it. A drawer is a Model tagged "TapDrawer" with: attribute PullDir  (Vector3) -> direction it slides out attribute PullDist (number)  -> how far it slides (studs) All parts stay anchored; the whole model is moved with PivotTo. Optional attribute UseEPrompt = true (for doors): use an E ProximityPrompt instead of tap/click. Object

**Functions:** `closeEnough(player, m)`, `setup(m)`, `toggle(player)`

### `TapInteract`
`src/ServerScriptService/TapInteract.server.luau` · Script (server) · 78 lines

TapInteract: tap / click things instead of pressing E. Tag a PowerToggle or LightSwitch MODEL with "TapToUse": tapping anywhere on it toggles it on/off. Tag a SEAT with "TapToUse": tapping its chair seats the player. The E prompts on tagged things are hidden (range 0); PowerToggles / LightSwitches / PromptSeats still do the actual work (they react to the "On" attribute / seat occupant).

**Functions:** `hidePrompt(p)`, `hideAll(root)`, `closeEnough(player, root)`, `isOpener(m)`, `setupDevice(m)`, `setupSeat(seat)`, `setup(inst)`

### `ThesisShelves`
`src/ServerScriptService/ThesisShelves.server.luau` · Script (server) · 103 lines

ThesisShelves: F at a thesis bookcase to pull out a bound thesis and read its title. A bookcase is a Model tagged "ThesisShelf" with: ProximityPrompt "BrowsePrompt" parts named "Book" (one of them slides out a little while you read it); spine bands are "BookBand" and are left alone, so only books without a band are pulled out attribute Titles -> thesis titles separated by "|" The title shows above

**Functions:** `setup(m)`

### `ToiletFlush`
`src/ServerScriptService/ToiletFlush.server.luau` · Script (server) · 75 lines

ToiletFlush: E at a toilet to flush it. A toilet is a Model tagged "Toilet" with: ProximityPrompt "FlushPrompt" part "FlushLever" (dips while flushing) part "Water" with a ParticleEmitter "Swirl" (swirls while flushing) The water level drops and refills; the prompt is disabled until the tank refills. Optional attribute TapFlush = true on the toilet Model: tap / click the toilet to flush instead of

**Functions:** `setup(m)`, `flush()`

### `WaterDispensers`
`src/ServerScriptService/WaterDispensers.server.luau` · Script (server) · 72 lines

WaterDispensers: E at a water dispenser to fill a paper cup. A dispenser is a Model tagged "WaterDispenser" with: ProximityPrompt "WaterPrompt" part "CupSpot"   -> invisible; the cup stands on its centre (bottom of the cup) optional part "TapLight" -> lights up while water is running The cup fills, stays for a few seconds and then disappears. One cup at a time per dispenser.

**Functions:** `setup(m)`

### `WeatherServer`
`src/ServerScriptService/WeatherServer.server.luau` · Script (server) · 57 lines

**Functions:** `pick(exclude)`, `set(id, seconds)`, `loop()`

## StarterGui

### `NPCDialogueClient`
`src/StarterGui/CampusLifeGui/NPCDialogueClient.client.luau` · LocalScript (client) · 138 lines

**Functions:** `corner(p, r)`, `sfxVolume()`, `button(name, label, x, col)`, `pick(t)`, `linesFor(d)`, `say(line)`, `close()`

### `CoinsClient`
`src/StarterGui/CoinsGui/CoinsClient.client.luau` · LocalScript (client) · 100 lines

CoinsClient: compact coin bar at the TOP-RIGHT (icon + number only), side by side, just under the Settings button on every device (clear of the music mini player and the jump button).

**Functions:** `corner(p, r)`, `stroke(p, col, t)`, `place()`, `makePill(name, label, icon, color, order)`, `fmt(n)`, `floatText(p, delta)`, `show(name, value)`

### `BoothClient`
`src/StarterGui/EventGui/BoothClient.client.luau` · LocalScript (client) · 252 lines

**Functions:** `corner(p, r)`, `label(parent, name, size, pos, font, color, maxSize)`, `button(parent, name, text, size, pos, col)`, `fitPanel(kind)`, `boothCamera(d)`, `near(p)`, `restoreCamera()`, `clearArea()`, `send(op, extra)`, `close()`, `buildMeter(ui)`, `drawZones(zones)`, `buildGuess(ui)`, `submit()`, `buildMemory(ui)`, `buildWheel(ui)`, `buildInfo(ui)`

### `DrawingClient`
`src/StarterGui/EventGui/DrawingClient.client.luau` · LocalScript (client) · 302 lines

**Functions:** `corner(p, r)`, `label(parent, name, size, pos, font, color, maxSize, xa)`, `fit()`, `applyWatchVisibility()`, `setSpectator(on)`, `addFeed(text, color)`, `worldStrokes()`, `drawPolyline(container, pts, color, w)`, `drawStroke(d, panelToo)`, `clearAll()`, `canvasPoint(input)`, `submit()`, `sync(panelToo)`

### `EscapeClient`
`src/StarterGui/EventGui/EscapeClient.client.luau` · LocalScript (client) · 243 lines

**Functions:** `corner(p, r)`, `label(parent, name, size, pos, font, color, max, xa)`, `keysLayout()`, `buildGrid(keys)`, `setChip(k)`, `showAlert(text, color, seconds)`, `sound(name, id, vol, looped)`, `fade(s, to, t)`, `setMode(m)`, `ap(name, size, color, shape)`, `chooseTarget()`, `stopAll()`

### `EventClient`
`src/StarterGui/EventGui/EventClient.client.luau` · LocalScript (client) · 435 lines

**Functions:** `corner(p, r)`, `stroke(p, col, t)`, `frame(parent, name, size, pos, col, tr)`, `label(parent, name, text, size, pos, font, color, xAlign)`, `button(parent, name, text, size, pos, col)`, `fmtTime2(s)`, `fmtTime(s)`, `outline(t, size, color)`, `layoutButtons()`, `boardLayout()`, `toast(msg)`, `setMapPin(loc, text)`, `alertsOn()`, `boardOn()`, `phaseText()`, `render()`, `act(action)`

### `FoundationClient`
`src/StarterGui/EventGui/FoundationClient.client.luau` · LocalScript (client) · 543 lines

**Functions:** `new(cls, props, parent)`, `corner(p, r)`, `stroke(p, c, t)`, `label(parent, props)`, `button(parent, text, color, props)`, `tw(o, t, props)`, `call(action, data)`, `headshot(userId)`, `guiScale()`, `rescale()`, `musicOn(v)`, `tickerSize(big)`, `buildProgram(program, allDay)`, `markProgram(seg)`, `unscaledScreen()`, `clampCard(x, y)`, `shown(o)`, `relRect(o)`, `obstacles()`, `below(c0, c1)`, `modal(title, sub, w, h)`, `close()`, `toast(msg)`, `myCandidate()`, `segId()`, `refreshButtons()`, `applyState(st)`, `openRegister()`, `openVote()`, `show(cat)`, `coronation(results)`, `photo()`, `spotlight(d)`, `setActive(on)`, `onState(s)`

### `IntramuralsClient`
`src/StarterGui/EventGui/IntramuralsClient.client.luau` · LocalScript (client) · 153 lines

IntramuralsClient: team scoreboard, round banner + timer, relay gate hint, basketball meter, tug-of-war PULL button + rope gauge, and the sports music. All points are decided on the server; this only shows them and sends taps/shots.

**Functions:** `corner(p, r)`, `label(parent, name, size, pos, font, col, max, xa)`, `showPicker(options)`, `fmt(s)`, `hideAll()`, `setMode(m)`

### `QuizBeeClient`
`src/StarterGui/EventGui/QuizBeeClient.client.luau` · LocalScript (client) · 130 lines

**Functions:** `corner(p, r)`, `label(parent, name, size, pos, font, color, maxSize, align)`, `setButtons(visible)`, `showLobby(d)`, `showQuestion(d)`, `showReveal(d)`, `showDone(d)`

### `TowerClient`
`src/StarterGui/EventGui/TowerClient.client.luau` · LocalScript (client) · 169 lines

**Functions:** `corner(p, r)`, `label(parent, name, size, pos, font, color, max, xa)`, `layout()`, `sound(name, id, vol, looped)`, `musicOn(on)`, `showPop(text, color, seconds)`, `buildStrip()`, `paintStrip()`, `fmt(s)`

### `HotbarClient`
`src/StarterGui/HotbarGui/HotbarClient.client.luau` · LocalScript (client) · 391 lines

HotbarClient: bottom inventory hotbar (keys 1-9 / tap). Shows ONLY the items you EQUIPPED (in your Bag [I]), in the order you equipped them (player attribute "Hotbar"). Unequip something in the Bag (or the little X on a slot / long-press on phones) and it leaves the hotbar. Press: Consumable = use one (shows count) • Flashlight = hold / put away • shoes, boots, cosmetics = they are simply ON while

**Functions:** `micTool()`, `corner(p, r)`, `stroke(p, col, t)`, `isTouch()`, `rescale()`, `hintTail()`, `showNote(text)`, `countOf(id)`, `collect()`, `add(id)`, `holdingTool(name)`, `menuOpen()`, `refresh()`, `pulse(s, col)`, `activate(i)`, `unequip(i)`, `hookBackpack(bp)`, `hookInv(inv)`

### `InventoryClient`
`src/StarterGui/InventoryGui/InventoryClient.client.luau` · LocalScript (client) · 174 lines

InventoryClient.lua Grid inventory GUI: Cosmetic / Equipment show EQUIPPED or NOT EQUIPPED with an EQUIP / UNEQUIP button; Consumables show a count with a USE button. Toggle with the [I] key, the close button, or the Inventory button in the shop.

**Functions:** `fit()`, `getItemCount(itemId)`, `refreshSlot(itemId)`, `refreshAll()`, `buildSlots()`, `watchValue(value)`, `watchInventory()`

### `LevelClient`
`src/StarterGui/LevelGui/LevelClient.client.luau` · LocalScript (client) · 176 lines

LevelClient: XP pop-ups, level-up celebration, milestone rewards and the level badge on the Profile button.

**Functions:** `new(cls, props, parent)`, `corner(p, r)`, `tw(o, t, props, style)`, `rescale()`, `sfx(id, vol)`, `showLevel(lvl, into, need)`, `toast(info)`, `celebrate(lvl, subtitle)`, `attachBadge()`, `upd()`, `run()`

### `DonateClient`
`src/StarterGui/MainHUD/DonateClient.client.luau` · LocalScript (client) · 61 lines

DonateClient: 💖 "Support the game" section at the bottom of the Settings page (Robux donations only). Buttons come from ReplicatedStorage.Donate.Products (DonateServer finds the "Donate ..." developer products).

**Functions:** `new(class, props, parent)`, `refreshTotal()`, `render()`

### `HUDClient`
`src/StarterGui/MainHUD/HUDClient.client.luau` · LocalScript (client) · 899 lines

HUDClient.lua Left rail (Bag, Map) + Settings button + one main panel. Keys: [I] Bag, [M] Map. Other scripts can open a page with MainHUD.OpenPanel:Fire("Bag").

**Functions:** `showToast(message)`, `rescale()`, `highlight(name)`, `openPage(name)`, `closePanel()`, `countOf(id)`, `refreshBag()`, `bagChanged()`, `watch(v)`, `toMap(pos)`, `corner(obj, r)`, `stroke(obj, col, th)`, `fitScale()`, `canvasSize(z)`, `clampCenter()`, `layout()`, `goTo(place)`, `focusOn(u, v, z)`, `selectPin(place, u, v)`, `refresh()`, `otherDot(plr)`, `ctrlButton(name, text, order, size)`, `setZoom(z)`, `zoomAt(screenPos, newZoom)`, `rootOf(plr)`, `step(dt)`, `askConfirm(message, detail, onYes)`, `isMusic(sound)`, `assign(sound)`, `makeSlider(frame, initial, onChange)`, `set(alpha)`, `setFromX(x)`, `savedOr(attr, default)`, `sendSetting(attr, value)`, `makeToggle(frame, attr, initial)`, `render()`

### `WeatherPage`
`src/StarterGui/MainHUD/WeatherPage.client.luau` · LocalScript (client) · 262 lines

**Functions:** `new(class, props, parent)`, `corner(p, r)`, `section(order, text)`, `makeCard(parent, id, icon, name, desc, wide)`, `grid(order)`, `toggle(order, attr, icon, name, desc)`, `draw()`, `clockText(h)`, `renderTime()`, `fmt(s)`, `render()`, `openWeather()`, `closeWeather()`, `watch(p)`

### `MusicClient`
`src/StarterGui/MusicGui/MusicClient.client.luau` · LocalScript (client) · 1074 lines

**Functions:** `mk(class, props, parent)`, `corner(o, r)`, `stroke(o, c, t)`, `label(parent, props)`, `button(parent, text, props)`, `coverize(frame, cat)`, `fmt(t)`, `claim(s)`, `locked()`, `syncScale()`, `fit()`, `sideHeader(text)`, `sideTab(id, text)`, `ctrlBtn(text, size, o)`, `sliderTrack(parent, pos, size)`, `showToast(text)`, `placeMini()`, `markDirty()`, `rebuildSets()`, `removeId(t, id)`, `songsFor(tabId)`, `filtered(tabId)`, `shuffleIds(ids, firstId)`, `buildQueue(songs, startId)`, `currentState()`, `sendState()`, `playSong(song, startAt, fromParty, startPaused)`, `prevSong()`, `togglePlay()`, `makeRow(song, i)`, `update()`, `applyState(st)`, `target()`, `setVol(v)`, `slider(hit, onMove, onEnd)`, `at(x)`, `highlightButton(on)`, `openWindow()`, `closeWindow()`, `toggleWindow()`

### `ProfileClient`
`src/StarterGui/ProfileGui/ProfileClient.client.luau` · LocalScript (client) · 480 lines

ProfileClient: Samar College student profile, level/title picker and level-up quiz.

**Functions:** `corner(p, r)`, `stroke(p, col, t)`, `label(parent, text, size, font, color, props)`, `rescale()`, `nextOrder()`, `section(text)`, `refreshLevel()`, `refreshRoleplay()`, `refreshPrograms()`, `stat(key, title, icon, order2)`, `rescaleQ()`, `countOwned()`, `coin(name)`, `fmtNum(n)`, `fmtTime(t)`, `refresh()`, `open()`, `closeAll()`, `showQuestion()`, `showResult(res)`, `backToProfile()`

### `ShopClient`
`src/StarterGui/ShopGui/ShopClient.client.luau` · LocalScript (client) · 237 lines

ShopClient.lua Shop GUI: Cosmetic / Equipment / Consumable tabs, Common + Event token balances, Buy / Owned buttons. The server validates every purchase.

**Functions:** `fit()`, `getBalance(currencyName)`, `refreshBalances()`, `refreshButtons()`, `showMessage(message)`, `buildTab(category)`, `showTab(category)`

### `SkyClimbClient`
`src/StarterGui/SkyClimbGui/SkyClimbClient.client.luau` · LocalScript (client) · 314 lines

**Functions:** `new(cls, props, parent)`, `corner(p, r)`, `stroke(p, c, t)`, `label(parent, props)`, `button(parent, text, color, props)`, `tw(o, t, props)`, `fmt(sec)`, `rescale()`, `applyCollapse()`, `popup(text, color, dur)`, `readZones()`, `currentZone(y)`, `refresh()`, `shown(o)`, `rel(o)`, `obstacles()`, `add(g, deep)`, `below(x0, x1, limit)`, `finishCard(d)`

### `ChessClient`
`src/StarterGui/SportsGui/ChessClient.client.luau` · LocalScript (client) · 302 lines

**Functions:** `new(class, props, parent)`, `corner(p, r)`, `label(parent, props)`, `button(parent, text, size, pos, color)`, `call(action, data)`, `sfx(id, vol, pitch)`, `playerBar(y)`, `slotToIdx(row, col)`, `idxToSlot(i)`, `setPiece(sq, p)`, `fmt(t)`, `capsText(list)`, `paint()`, `bars()`, `fill(bar, color)`, `setStatus()`, `render()`, `sendMove(from, to, pr)`, `showPromo(from, to, options)`, `watchingId()`

### `IntramuralsPopup`
`src/StarterGui/SportsGui/IntramuralsPopup.client.luau` · LocalScript (client) · 147 lines

**Functions:** `new(class, props, parent)`, `corner(p, r)`, `label(parent, props)`, `btn(text, color, x, w)`, `fit()`, `hide()`, `sfx(id, vol, pitch)`, `show()`

### `SportsClient`
`src/StarterGui/SportsGui/SportsClient.client.luau` · LocalScript (client) · 496 lines

**Functions:** `new(class, props, parent)`, `corner(p, r)`, `stroke(p, c, t)`, `label(parent, props)`, `button(parent, text, size, pos, color, maxSize)`, `call(action, data)`, `rescale()`, `toast(text, color)`, `clear(f)`, `sideColumn(st, side, x)`, `renderPanel(st)`, `renderHud(st)`, `n(list)`, `applyZone()`, `buildShots(st)`, `stopMeter()`, `startMeter(d)`, `doHit()`, `makeShuttle()`, `placeBall(pos, d)`, `placeShuttle(pos, dir)`, `fly(from, to, time, height, smash, d, bounceTo)`, `arc(a0, b0, tt, h)`, `burst(pos, color)`, `courtModel(id)`, `setCam()`, `startWatching(st)`, `stopWatching()`, `vote(yes)`, `inMyView(id)`

### `TalentClient`
`src/StarterGui/TalentGui/TalentClient.client.luau` · LocalScript (client) · 403 lines

**Functions:** `mk(class, props, parent)`, `corner(o, r)`, `stroke(o, c, th)`, `label(parent, props)`, `button(parent, text, props)`, `showToast(text)`, `draggable(win, handle)`, `window(name, title, size, pos)`, `performing()`, `onStage()`, `hasMic()`, `tempList()`, `setTemp(t)`, `toggleTemp(id)`, `performerPlayers()`, `setWatching(on)`, `doCheer(btn)`, `floater(text)`, `refresh()`, `clearDance()`

### `update size`
`src/StarterGui/dialog/dialogResponses/template/text/update size.client.luau` · LocalScript (client) · 18 lines

_Data module._

## StarterPlayer

### `AdminPowersClient`
`src/StarterPlayer/StarterPlayerScripts/AdminPowersClient.client.luau` · LocalScript (client) · 105 lines

AdminPowersClient: client side of the admin powers (set by AdminServer through player attributes). AdminFly + AdminFlySpeed : fly (WASD / thumbstick to move, Space / E up, Ctrl / Q down) AdminGod                 : the humanoid can't enter the Dead state AdminInvisible           : you see yourself at 10% opacity (your screen only); everyone else sees nothing

**Functions:** `stopFly()`, `startFly()`, `clearSelfView()`, `isVisual(d)`, `applySelf(inst)`, `watch(inst)`, `startSelfView(char)`, `refresh()`

### `AutoLights`
`src/StarterPlayer/StarterPlayerScripts/AutoLights.client.luau` · LocalScript (client) · 120 lines

**Functions:** `isStormy()`, `seenClock()`, `wantOn()`, `register(part)`, `apply(part, info, on, instant)`, `go()`, `update(instant)`

### `BikeClient`
`src/StarterPlayer/StarterPlayerScripts/BikeClient.client.luau` · LocalScript (client) · 209 lines

**Functions:** `toast(msg)`, `ring()`, `groundY(pos, ignore)`, `startRiding(bike, seat)`, `stopRiding()`, `hookCharacter(char)`, `motorsOf(char)`, `legs(side, ph)`

### `BoatClient`
`src/StarterPlayer/StarterPlayerScripts/BoatClient.client.luau` · LocalScript (client) · 107 lines

**Functions:** `setTip(kind)`, `yawOf(v)`, `start(s)`, `stop()`

### `CameraRescue`
`src/StarterPlayer/StarterPlayerScripts/CameraRescue.client.luau` · LocalScript (client) · 19 lines

CameraRescue: if the camera or mouse ever gets stuck (a watch/booth camera that didn't let go, a hidden text box still holding the keyboard, a locked mouse), respawning fixes it: Esc → Reset Character always gives back the normal camera, mouse and keyboard.

**Functions:** `rescue(char)`

### `CampusMusic`
`src/StarterPlayer/StarterPlayerScripts/CampusMusic.client.luau` · LocalScript (client) · 37 lines

CampusMusic: calm school background music while you are just hanging out. It fades away while you take part in an event or another soundtrack (Escape / Tower) plays, and follows Settings → Music volume (player attribute "Setting_MusicVolume").

**Functions:** `otherMusic()`, `settingVolume()`

### `CampusNPCDialogue`
`src/StarterPlayer/StarterPlayerScripts/CampusNPCDialogue.client.luau` · LocalScript (client) · 141 lines

**Functions:** `hi(t)`, `aOrAn(word)`, `pick(t)`, `split(s)`, `script_for(m)`, `setup(m)`, `forget()`, `watch(folder)`

### `CeilingFanSpin`
`src/StarterPlayer/StarterPlayerScripts/CeilingFanSpin.client.luau` · LocalScript (client) · 79 lines

Spins every fan (Model with attribute Spin=true and a "Blades" model) on the client. The blades turn around the Blades model's pivot Y axis (orbit fans: the motor axis). A fan stops when it, or the model it sits in, has the attribute On = false. Orbit fans: a child model "Head" (with the Blades inside it) also turns slowly all the way round (360°) around the Head pivot's Y axis (the ceiling rod) w

**Functions:** `isOn(m)`, `add(m)`

### `CeilingFans`
`src/StarterPlayer/StarterPlayerScripts/CeilingFans.client.luau` · LocalScript (client) · 92 lines

CeilingFans (client): spins every ceiling fan that is switched on. A fan is a Model tagged "CeilingFan" with a part "Hub" (the blades turn around its up axis) and a child model "Rotor" (the blades). The "On" attribute is set by the server (CeilingFans.server). Speed ramps up and down smoothly. Done on the client so it is smooth and costs the server nothing. Fans are (re)checked every second, so fa

**Functions:** `ready(m)`

### `ElevatorClient`
`src/StarterPlayer/StarterPlayerScripts/ElevatorClient.client.luau` · LocalScript (client) · 23 lines

Elevator ride screen: a short fade with the destination floor.

### `FacultyKnockClient`
`src/StarterPlayer/StarterPlayerScripts/FacultyKnockClient.client.luau` · LocalScript (client) · 11 lines

### `ForceLandscape`
`src/StarterPlayer/StarterPlayerScripts/ForceLandscape.client.luau` · LocalScript (client) · 10 lines

Mobile: keep the game in landscape only (left or right, follows the phone's rotation; never portrait).

**Functions:** `lock()`

### `GearClient`
`src/StarterPlayer/StarterPlayerScripts/GearClient.client.luau` · LocalScript (client) · 248 lines

**Functions:** `holding(name)`, `lowGravityFactor()`, `hookJumpSound(hum)`, `flyButton(text, y)`, `moveVector()`, `startFly(tool)`, `stopFly()`, `fit()`, `lbl(text, y, h, size, color, font)`, `btn(text, y, color)`, `potionCount()`, `close()`, `choose(target)`, `open()`

### `HostingClient`
`src/StarterPlayer/StarterPlayerScripts/HostingClient.client.luau` · LocalScript (client) · 547 lines

HostingClient: 📌 Host button on the left rail. 🏫 Host     — pick a room, type and title, then start (no time limit). While hosting: manage the meeting. 👥 Players  — everyone in the server with their title, role and level; the host can invite them. 📋 Sessions — meetings going on now; join open ones. Invites pop up at the top; a meeting bar shows at the bottom while you're in one.

**Functions:** `corner(o, r)`, `stroke(o, col, t)`, `frame(parent, size, pos, col)`, `label(parent, text, size, font, col, props)`, `button(parent, text, col, size, props)`, `textbox(parent, placeholder, size, props)`, `vlist(o, gap)`, `hlist(o, gap)`, `scroller(parent, size)`, `clear(o)`, `fmtTime(sec)`, `toast(text, good)`, `req(action, data)`, `rescale()`, `draggable(chip, onTap)`, `page(name)`, `paintForm()`, `renderRooms()`, `fetchRooms()`, `renderMine()`, `thumb(img, uid)`, `invitedSet()`, `renderPlayers()`, `renderSessions()`, `showTab(name)`, `open(tab)`, `dropFocus()`, `close()`, `minimize()`, `rescalePop()`, `paintInvites()`, `nextInvite()`, `renderBar()`, `addRailButton(hud)`

### `LeaderboardClient`
`src/StarterPlayer/StarterPlayerScripts/LeaderboardClient.client.luau` · LocalScript (client) · 174 lines

**Functions:** `new(class, props, parent)`, `corner(o, r)`, `decode(key)`, `build(board, screen)`, `scrollBtn(txt, x, dir)`, `render()`, `tryStand(m)`

### `LibraryKioskClient`
`src/StarterPlayer/StarterPlayerScripts/LibraryKioskClient.client.luau` · LocalScript (client) · 122 lines

Library time-in screen: choose what you will do, then see where to go and the rules.

**Functions:** `close()`, `base()`, `button(parent, text, color, order)`, `openChooser(current)`, `showDone(info)`

### `LiveCalendars`
`src/StarterPlayer/StarterPlayerScripts/LiveCalendars.client.luau` · LocalScript (client) · 144 lines

LiveCalendars: whiteboard month calendars that always show the current month (Philippine Time). A calendar is a BasePart tagged "LiveCalendar"; the month grid is drawn on its SurfaceGui (attribute Face = "Front" / "Back" / "Left" / "Right", default Front). Handwritten notes come from attributes named Note_YYYY_MM_DD (e.g. Note_2026_10_08 = "Educators' Night"). Today's box gets a red marker circle.

**Functions:** `now()`, `daysIn(y, m)`, `weekday(y, m, d)`, `label(parent, text, size, pos, props)`, `line(parent, size, pos)`, `draw(part)`, `add(p)`

### `LiveClocks`
`src/StarterPlayer/StarterPlayerScripts/LiveClocks.client.luau` · LocalScript (client) · 43 lines

LiveClocks: wall clocks show the real time (Philippine Time, UTC+8). A clock is anything tagged "LiveClock" with GUI frames named HourHand, MinuteHand and (optional) SecondHand, anchored at the centre of the face (AnchorPoint 0.5, 1; Rotation 0 = 12 o'clock). Attribute "UtcOffset" (hours) changes the time zone of one clock.

**Functions:** `add(clock)`, `remove(clock)`

### `PerformanceSettings`
`src/StarterPlayer/StarterPlayerScripts/PerformanceSettings.client.luau` · LocalScript (client) · 148 lines

Performance settings (client only, each player's own choice): Setting_ImproveFPS     : no shadows, simple materials, no repeating textures, signs drawn only nearby Setting_DisableEffects : particles / beams / trails / fire / smoke off, post effects (bloom, blur, sun rays...) off Setting_Shadows        : false = no sun shadows and no light shadows (true by default) Toggled from the HUD Settings pag

**Functions:** `fpsApply(d)`, `fxApply(d)`, `runChunked(list, fn)`, `registerLight(d)`, `shadowApply(d)`, `updateShadowLights()`, `setShadows(off)`, `setFPS(on)`, `setFX(on)`, `mobileSign(d)`, `sync()`

### `PromptGuard`
`src/StarterPlayer/StarterPlayerScripts/PromptGuard.client.luau` · LocalScript (client) · 203 lines

PromptGuard: E-prompts (sit, lights, doors, gates, windows, whiteboards, NPCs ...) only work when you can really reach them. * A wall, door, window, pillar, floor or ceiling between you and the prompt hides it, so you cannot sit, switch lights or open things on the other side of a wall. Furniture (tables, chairs, desks, benches, small props) does not block, nor does any part with the attribute Fur

**Functions:** `extents(p)`, `isBlocker(p)`, `anchorOf(prompt)`, `small(p)`, `addSmallParts(list, inst)`, `ownerOf(prompt)`, `clearPath(from, to, exclude)`, `write(prompt, st, value)`, `track(prompt)`

### `ReportClient`
`src/StarterPlayer/StarterPlayerScripts/ReportClient.client.luau` · LocalScript (client) · 207 lines

ReportClient: the 🚩 Report button on the left side buttons and the "Report a player" window. Pick who, what they did, and (if you want) tell the admins more. ReportServer checks and saves it, and the admin team sees it in the admin panel (📋 Player Records → 🚩 Reports).

**Functions:** `corner(o, r)`, `stroke(o, col, t)`, `frame(parent, size, pos, col)`, `label(parent, text, size, font, col, props)`, `button(parent, text, col, size, props)`, `sortList(o, gap)`, `rescale()`, `section(text, order)`, `grid(order, cellH)`, `paint()`, `renderPlayers()`, `setStatus(text, good)`, `open()`, `close()`, `addRailButton(hud)`

### `SC_LogoRenderer`
`src/StarterPlayer/StarterPlayerScripts/SC_LogoRenderer.client.luau` · LocalScript (client) · 29 lines

Paints the official Samar College logo onto the gate seal using an EditableImage. If EditableImage is unavailable, the hand-drawn seal underneath stays visible.

### `SeasonGround`
`src/StarterPlayer/StarterPlayerScripts/SeasonGround.client.luau` · LocalScript (client) · 605 lines

**Functions:** `on(k)`, `lowSpec()`, `radius()`, `leafRadius()`, `flat(name, size, color, material)`, `showing()`, `refreshFilter()`, `keyOf(cx, cz)`, `faceRect(part, hitPos, normal)`, `humanoidModel(inst)`, `exposed(pos)`, `cornersExposed(cell)`, `scan(cell)`, `cellCF(cell, lift)`, `clearCell(cell)`, `ensureSnow(cell)`, `ensureBits(cell, kind)`, `applyCell(cell, dist)`, `findTrees()`, `tint()`, `focusPos()`, `anyActive()`, `rebuildNeeded(pos)`, `clearAll()`, `playStep(list, vol)`, `puff(pos, color, n)`, `footprint(cf)`, `footsteps(dt)`, `breath()`, `makeButterfly()`, `updateButterflies(t)`

### `SleepPoseClient`
`src/StarterPlayer/StarterPlayerScripts/SleepPoseClient.client.luau` · LocalScript (client) · 37 lines

SleepPoseClient: while you lie in a sleeping bag (Seat with attribute SleepSeat), the sitting animation is stopped so you lie flat with straight legs. Other players see it too (your animations replicate).

**Functions:** `isSitTrack(track)`, `hook(char)`, `stopSits()`

### `TapPrompts`
`src/StarterPlayer/StarterPlayerScripts/TapPrompts.client.luau` · LocalScript (client) · 347 lines

TapPrompts: every interaction is "tap / click the object itself" - except DOORS (and gates) and NPCs, which keep their normal E / tap-the-prompt button. How: a non-door, non-NPC ProximityPrompt is switched to Custom style (no on-screen button) with no keyboard / gamepad key, so E does nothing. Tapping or clicking the object then fires that prompt (prompt:InputHoldBegin / InputHoldEnd), so every ex

**Functions:** `hasWord(s)`, `hasObjectWord(s)`, `keepsE(prompt)`, `ensureFolder()`, `adorneeOf(prompt)`, `showSmall(prompt)`, `hideSmall(prompt)`, `makeSmall(prompt)`, `convert(prompt)`, `promptPos(prompt)`, `ownerRoot(prompt)`, `promptFor(hitPart, hitPos)`, `worldHit(pos, isGuiPos)`, `feedback(part)`, `fire(prompt, part)`, `tryTap(screenPos, isGuiPos)`

### `UIResponsive`
`src/StarterPlayer/StarterPlayerScripts/UIResponsive.client.luau` · LocalScript (client) · 144 lines

**Functions:** `screenScale()`, `fixText(d)`, `track(gui)`, `update()`, `sidePx(gui)`, `rootScale(gui)`, `applyShift(obj)`, `watchSide(gui, obj, side)`, `scanSide(gui)`, `reapplyAll()`

### `WeatherClient`
`src/StarterPlayer/StarterPlayerScripts/WeatherClient.client.luau` · LocalScript (client) · 521 lines

**Functions:** `todAt(hour)`, `mul(c, t)`, `schoolClock()`, `wantedClock()`, `circDiff(from, to)`, `updateSkyClock(dt)`, `targetOf(w)`, `lerp(a, b, t)`, `chosenId()`, `rigPart(name, size)`, `buildRainbow()`, `loop(name, id)`, `rumble(delay, strength)`, `bolt()`, `zig(a, b, n, width)`, `checkIndoor()`, `quality()`, `put(obj, prop, v, eps)`, `toast(text)`, `refresh(fromServer)`
