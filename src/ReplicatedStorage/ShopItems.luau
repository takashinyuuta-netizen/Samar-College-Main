-- ShopItems.lua
-- Item catalog for the Cashier's shop.
-- Categories: Cosmetic (visual only), Equipment (has an effect while equipped), Consumable (used up).
-- RequiredLevel (optional) = LevelConfig level index needed to buy (2 = Grade 1, 4 = Grade 3, 14 = 1st Year).
-- Currency is "Common" (regular games) or "Event" (special events).
-- Add or edit items here; the shop GUI, inventory GUI and server update automatically.

return {
	Cosmetic = {
		-- ComingSoon = true: shown in the shop but locked (can't be bought yet)
		{Id = "FoundationCap", Name = "Foundation Day Cap", Desc = "Limited event cosmetic. Visual only.", Icon = "🧢", Price = 40, Currency = "Event", RequiredLevel = 2, ComingSoon = true},
		{Id = "ReadingGlasses", Name = "Reading Glasses", Desc = "A face accessory. Visual only.", Icon = "👓", Price = 60, Currency = "Common", RequiredLevel = 4, ComingSoon = true},
		{Id = "CLASUniform", Name = "CLAS Uniform", Desc = "Department outfit. Visual only.", Icon = "👕", Price = 80, Currency = "Common", RequiredLevel = 14, ComingSoon = true},
	},
	Equipment = {
		-- FREE for everyone: every player owns it automatically. Tap it on the hotbar to summon YOUR bike and ride (only you can ride it).
		{Id = "SchoolBike", Name = "School Bike", Desc = "FREE for every student! Tap it on your hotbar to summon your own bike and ride around campus. Only you can ride it.", Icon = "🚲", Price = 0, Currency = "Common", Tool = "SchoolBike", Free = true},
		{Id = "RunningShoes", Name = "Running Shoes", Desc = "Walk faster while equipped.", Icon = "👟", Price = 30, Currency = "Event"},
		{Id = "SpringBoots", Name = "Spring Boots", Desc = "Jump higher while equipped.", Icon = "🥾", Price = 200, Currency = "Common"},
		{Id = "Flashlight", Name = "Flashlight", Desc = "A flashlight tool while equipped. Lights up dark areas.", Icon = "🔦", Price = 100, Currency = "Common"},
		-- Roblox gear (real gear models, our own scripts). Tool = name in ReplicatedStorage.Tools, given while equipped.
		{Id = "GravityCoil", Name = "Gravity Coil", Desc = "Hold it to jump super high and float down slowly (low gravity).", Icon = "🌀", Price = 250, Currency = "Common", Tool = "GravityCoil"},
		{Id = "SpeedCoil", Name = "Speed Coil", Desc = "Hold it to run much faster (+12 speed).", Icon = "⚡", Price = 250, Currency = "Common", Tool = "SpeedCoil"},
		{Id = "MagicCarpet", Name = "Rainbow Magic Carpet", Desc = "Hold it to FLY anywhere on a rainbow carpet! WASD steer, Space up, Shift down. Rare & expensive.", Icon = "🌈", Price = 2500, Currency = "Common", Tool = "MagicCarpet"},
	},
	Consumable = {
		{Id = "PizzaSlice", Name = "Pizza Slice", Desc = "Restores 15 health instantly.", Icon = "🍕", Price = 15, Currency = "Common"},
		{Id = "SmallSnack", Name = "Canteen Snack", Desc = "Restores 25 health instantly.", Icon = "🍪", Price = 25, Currency = "Common"},
		{Id = "MedKit", Name = "Med Kit", Desc = "Restores all of your health instantly.", Icon = "🩹", Price = 80, Currency = "Common"},
		{Id = "EnergyDrink", Name = "Energy Drink", Desc = "Speed boost for 30 seconds.", Icon = "🥤", Price = 40, Currency = "Common"},
		{Id = "GlowStick", Name = "Glow Stick", Desc = "Attaches a light to your character for 60 seconds.", Icon = "✨", Price = 15, Currency = "Event"},
		{Id = "InvisibilityPotion", Name = "Invisibility Potion", Desc = "Turns you invisible for 10 seconds.", Icon = "🧪", Price = 100, Currency = "Common"},
		-- Roblox gear food & potions (eaten from the hotbar with the real gear model in your hand)
		{Id = "Cheezburger", Name = "Cheezburger", Desc = "Om nom nom! Restores 25 health.", Icon = "🍔", Price = 20, Currency = "Common", Gear = "Cheezburger"},
		{Id = "BloxyCola", Name = "Bloxy Cola", Desc = "Fizzy classic. Restores 15 health (burp!).", Icon = "🥫", Price = 15, Currency = "Common", Gear = "BloxyCola"},
		{Id = "Bloxiade", Name = "Bloxiade", Desc = "Energy drink: +10 health and +10 speed for 20 seconds.", Icon = "🧃", Price = 35, Currency = "Common", Gear = "Bloxiade"},
		{Id = "SpaceSandwich", Name = "Space Sandwich", Desc = "Restores 30 health and gives you low gravity for 20 seconds.", Icon = "🥪", Price = 40, Currency = "Common", Gear = "SpaceSandwich"},
		{Id = "BodySwapPotion", Name = "Body Swap Potion", Desc = "Turn into another player's avatar for 3 minutes (random or pick one). Only YOUR look changes.", Icon = "🧬", Price = 150, Currency = "Common", Gear = "BodySwapPotion"},
	},
}