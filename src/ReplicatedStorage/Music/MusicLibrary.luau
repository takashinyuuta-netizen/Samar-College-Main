--[[ MusicLibrary — songs for the campus music player.
  EVERY song here is SAFE for the game: uploaded by Roblox's official licensed accounts
    • APMOfficial      = Roblox's licensed APM Music library
    • DistrokidOfficial = official DistroKid releases on Roblox (artists opted in)
  (checked with MarketplaceService:GetProductInfo on 13 Nov 2026).
  Do NOT add songs uploaded by random users — they get removed for copyright and can get the game flagged.
  To add a song: { id = <audio id>, title = "...", artist = "..." } in the right category. ]]
local M = {}

M.Categories = {
	{ id = "Lofi", name = "Lo-fi", icon = "🎧", desc = "Beats to study and chill to" },
	{ id = "Chill", name = "Chill", icon = "🌴", desc = "Easy, laid-back vibes" },
	{ id = "Vocal", name = "Vocal & Pop", icon = "🎤", desc = "Songs with singing" },
	{ id = "Relapse", name = "Relapse", icon = "🥀", desc = "Sad, deep and emotional" },
	{ id = "Peace", name = "Peace", icon = "🕊️", desc = "Calm piano, classical and nature" },
	{ id = "Happy", name = "Happy", icon = "☀️", desc = "Bright and upbeat" },

	{ id = "OPMChill", name = "OPM Chill", icon = "🌙", desc = "Tagalog chill — ulan, kape, gabi vibes" },

	{ id = "OPMHugot", name = "OPM Hugot", icon = "💔", desc = "Tagalog sad & relapse songs" },

	{ id = "OPMKilig", name = "OPM Kilig", icon = "💘", desc = "Tagalog happy & love songs" },

	{ id = "Anime", name = "Anime Vocal", icon = "🎌", desc = "Anime-style songs with singing" },

	{ id = "JPop", name = "J-Pop & City Pop", icon = "🗼", desc = "Japanese vocal pop and 80s city pop" },

	{ id = "CPop", name = "C-Pop", icon = "🐉", desc = "Chinese love and sad songs" },

	{ id = "KPop", name = "K-Pop", icon = "💜", desc = "Korean pop and ballads" },

	{ id = "TrendingPop", name = "Trending Pop", icon = "🔥", desc = "Upbeat pop, dance, K-pop style and party hits" },

	{ id = "AnimeOP", name = "Anime Opening", icon = "⚔️", desc = "High-energy J-rock & J-pop anime opening vibes" },
}

M.Songs = {
	-- 🎧 Lo-fi
	{ id = 9043887091, title = "Lo-fi Chill A", artist = "APM Music", cat = "Lofi" },
	{ id = 1836913827, title = "Lofi Hifi", artist = "APM Music", cat = "Lofi" },
	{ id = 1836049841, title = "Lofi Deep House", artist = "APM Music", cat = "Lofi" },
	{ id = 71557483400828, title = "Tropical Rainforest LoFi", artist = "DistroKid", cat = "Lofi" },
	{ id = 124085407917650, title = "Sahara Desert Evening LoFi", artist = "DistroKid", cat = "Lofi" },
	{ id = 83784623771159, title = "Beach Morning LoFi", artist = "DistroKid", cat = "Lofi" },
	{ id = 117083145236918, title = "Anime", artist = "DistroKid", cat = "Lofi" },
	{ id = 104018619971781, title = "Anime Lover's Dream", artist = "DistroKid", cat = "Lofi" },
	-- 🌴 Chill
	{ id = 1837768517, title = "Bossa Me", artist = "Peter Christiansen", cat = "Chill" },
	{ id = 1837879082, title = "Paradise Falls", artist = "Craig McConnell", cat = "Chill" },
	{ id = 1836098504, title = "Tender Chillstep", artist = "AXS", cat = "Chill" },
	{ id = 1845341094, title = "Chill Jazz", artist = "John Graham Donaldson", cat = "Chill" },
	{ id = 1836105293, title = "Tender Tropical House", artist = "APM Music", cat = "Chill" },
	{ id = 9046865261, title = "Glowing Light", artist = "APM Music", cat = "Chill" },
	{ id = 9046864509, title = "Violet Clouds", artist = "APM Music", cat = "Chill" },
	{ id = 9046863579, title = "City Lights", artist = "APM Music", cat = "Chill" },
	{ id = 9046862941, title = "Sunset Chill", artist = "APM Music", cat = "Chill" },
	{ id = 9046863235, title = "Mellow Mind", artist = "APM Music", cat = "Chill" },
	{ id = 9047104411, title = "Beach Cushions", artist = "APM Music", cat = "Chill" },
	{ id = 9047105308, title = "Dusk To Dawn", artist = "APM Music", cat = "Chill" },
	{ id = 9046864934, title = "Vintage Dreams", artist = "APM Music", cat = "Chill" },
	{ id = 1841647093, title = "Life in an Elevator", artist = "Jeremy Peter Godfrey", cat = "Chill" },
	{ id = 110919391228823, title = "Low Cortisol", artist = "DistroKid", cat = "Chill" },
	-- 🎤 Vocal & Pop
	{ id = 1837021402, title = "Deja Vu", artist = "Dylan R Berry", cat = "Vocal" },
	{ id = 1836807218, title = "A Heart Worth Saving", artist = "APM Music", cat = "Vocal" },
	{ id = 9047324992, title = "Maybe Us", artist = "APM Music", cat = "Vocal" },
	{ id = 9047105410, title = "Say It's For Real", artist = "APM Music", cat = "Vocal" },
	{ id = 9047105000, title = "I'll Show Ya", artist = "APM Music", cat = "Vocal" },
	{ id = 9047104919, title = "Time Goes By", artist = "APM Music", cat = "Vocal" },
	{ id = 80918407121445, title = "Careless Whisper", artist = "DistroKid", cat = "Vocal" },
	{ id = 88819397775374, title = "Starlight Glow", artist = "DistroKid", cat = "Vocal" },
	{ id = 130805341639743, title = "Shining Stars", artist = "DistroKid", cat = "Vocal" },
	{ id = 9039771403, title = "Opportunity", artist = "APM Music", cat = "Vocal" },
	-- 🥀 Relapse (sad / emotional)
	{ id = 114213622974713, title = "The Loneliest Hour", artist = "Chilled Monkey LoFi", cat = "Relapse" },
	{ id = 1838635121, title = "Sad End (Solo Piano)", artist = "Romain Paillot", cat = "Relapse" },
	{ id = 1846458016, title = "No More", artist = "Dave Rosenholz", cat = "Relapse" },
	{ id = 1848028342, title = "Nocturne Op. 9", artist = "Chopin", cat = "Relapse" },
	{ id = 1848056295, title = "Moonlight Sonata", artist = "Beethoven", cat = "Relapse" },
	{ id = 1847105373, title = "Lacrimosa", artist = "Mozart", cat = "Relapse" },
	{ id = 131395520644363, title = "Interstellar (Cornfield Chase)", artist = "DistroKid", cat = "Relapse" },
	{ id = 75793628822368, title = "Mirage Portal", artist = "DistroKid", cat = "Relapse" },
	{ id = 120817494107898, title = "Backrooms", artist = "DistroKid", cat = "Relapse" },
	-- 🕊️ Peace (calm piano, classical, nature)
	{ id = 1838457617, title = "Clair de Lune", artist = "Debussy", cat = "Peace" },
	{ id = 9045766377, title = "Gymnopédie No. 1", artist = "Satie", cat = "Peace" },
	{ id = 1837626326, title = "Für Elise", artist = "Beethoven", cat = "Peace" },
	{ id = 1844159122, title = "Canon", artist = "Pachelbel", cat = "Peace" },
	{ id = 1836222363, title = "Ave Maria", artist = "Schubert", cat = "Peace" },
	{ id = 1846088038, title = "Morning Mood", artist = "Grieg", cat = "Peace" },
	{ id = 9045766074, title = "The Four Seasons – Spring", artist = "Vivaldi", cat = "Peace" },
	{ id = 1848062261, title = "A Little Night Music", artist = "Mozart", cat = "Peace" },
	{ id = 81821734193614, title = "Silent Forest", artist = "DistroKid", cat = "Peace" },
	{ id = 70607720284853, title = "Chill Piano Garden", artist = "DistroKid", cat = "Peace" },
	{ id = 133378537793931, title = "Grace in Motion By The River", artist = "DistroKid", cat = "Peace" },
	{ id = 129381851374164, title = "Ambient Topography Nine", artist = "DistroKid", cat = "Peace" },
	{ id = 100994597925588, title = "Amazing Grace", artist = "DistroKid", cat = "Peace" },
	-- ☀️ Happy
	{ id = 1843404009, title = "Happy Song", artist = "Justement Music", cat = "Happy" },
	{ id = 1843436418, title = "Running", artist = "Tom Hillock", cat = "Happy" },
	{ id = 1839822906, title = "Guitar & Synths", artist = "APM Music", cat = "Happy" },
	{ id = 111253506325051, title = "Echo", artist = "DistroKid", cat = "Happy" },

	-- ===== OPM / Tagalog (all DistrokidOfficial, verified 13 Nov 2026) =====

	{ id = 89057711242218, title = "Ambon at Alaala", artist = "Harana Studio", cat = "OPMChill" },

	{ id = 138838770010872, title = "Kapag Luminaw ang Umaga", artist = "Harana Studio", cat = "OPMChill" },

	{ id = 111889328912397, title = "Hindi Pa Gising ang Mundo", artist = "Harana Studio", cat = "OPMChill" },

	{ id = 71753997499441, title = "May Hangin ang Umaga", artist = "Harana Studio", cat = "OPMChill" },

	{ id = 112162820733482, title = "Sa Banayad na Araw", artist = "Harana Studio", cat = "OPMChill" },

	{ id = 117332007210888, title = "Sa Gitna ng Umaga", artist = "Harana Studio", cat = "OPMChill" },

	{ id = 81533610453144, title = "Harana sa Gabi (Serenade at Night)", artist = "The Mood House", cat = "OPMChill" },

	{ id = 70563381987752, title = "Himig ng Alaala (Melody of a Memory)", artist = "The Mood House", cat = "OPMChill" },

	{ id = 110233521133180, title = "Kape at ulan", artist = "Bettybite", cat = "OPMChill" },

	{ id = 83201552619764, title = "Buwan", artist = "Bettybite", cat = "OPMChill" },

	{ id = 130490070599493, title = "Ulan sa Bintana", artist = "Your Mood Music", cat = "OPMChill" },

	{ id = 129457385587445, title = "Tag-ulan", artist = "Mothy", cat = "OPMChill" },

	{ id = 112561798460781, title = "Sa Ilaw ng Buwan", artist = "Rob Ygot", cat = "OPMChill" },

	{ id = 130813883446480, title = "Sa Himbing ng Gabi", artist = "Jhae-are Abella", cat = "OPMChill" },

	{ id = 102581886052112, title = "Langit", artist = "Music Verse PH", cat = "OPMChill" },

	{ id = 120253812441769, title = "Gabi Na Sa Maynila", artist = "The Manila Hearts Club Band", cat = "OPMChill" },

	{ id = 94412673887553, title = "Alaala Na Lang", artist = "Your Mood Music", cat = "OPMHugot" },

	{ id = 82776615449650, title = "Huling Paalam", artist = "Echoes of Musics PH", cat = "OPMHugot" },

	{ id = 131833491162429, title = "Ulan ng Alaala", artist = "Echoes of Musics PH", cat = "OPMHugot" },

	{ id = 81898172007179, title = "Sa Dulo ng Ating Alaala", artist = "Echoes of Musics PH", cat = "OPMHugot" },

	{ id = 129482198279966, title = "Di Na Tayo Masaya", artist = "Team Sekai", cat = "OPMHugot" },

	{ id = 100294401726930, title = "Hindi Na Tayo", artist = "JJEMP RECORDS", cat = "OPMHugot" },

	{ id = 121906104691722, title = "Kahit walang tayo", artist = "Khenjie", cat = "OPMHugot" },

	{ id = 95083960129164, title = "Walang Tayo", artist = "Rodel Ruiz Studios", cat = "OPMHugot" },

	{ id = 100192989642388, title = "Hanggang Alaala Nalang", artist = "Rodel Ruiz Studios", cat = "OPMHugot" },

	{ id = 136443161143618, title = "Sa Likod ng Luha", artist = "Rodel Ruiz Studios", cat = "OPMHugot" },

	{ id = 93918602436733, title = "PIRA-PIRASONG ALAALA", artist = "Rodel Ruiz Studios", cat = "OPMHugot" },

	{ id = 101239772194250, title = "Ngiting May Luha", artist = "SEPT 25", cat = "OPMHugot" },

	{ id = 109912101426233, title = "Saan Napupunta ang Pusong Wasak", artist = "A_LITO", cat = "OPMHugot" },

	{ id = 119794222318574, title = "Mahal Pa Rin Kita", artist = "A_LITO", cat = "OPMHugot" },

	{ id = 100683193999267, title = "Mahal Kita, Ngunit Lilisan", artist = "Esor", cat = "OPMHugot" },

	{ id = 97788054067271, title = "Tapos Na Pala", artist = "Soundtrip Pinoy", cat = "OPMHugot" },

	{ id = 90696126940624, title = "Tahan Na", artist = "Soundtrip Pinoy", cat = "OPMHugot" },

	{ id = 133531628128722, title = "Bitaw na Muna", artist = "Soundtrip Pinoy", cat = "OPMHugot" },

	{ id = 108370050229944, title = "Walang Pasabi", artist = "Soundtrip Pinoy", cat = "OPMHugot" },

	{ id = 138096789262065, title = "Sana'y panaginip na lang", artist = "Radikal", cat = "OPMHugot" },

	{ id = 115848107927096, title = "Sana Ako Na Lang", artist = "Maple Coco Jam Muzik", cat = "OPMHugot" },

	{ id = 83003494092665, title = "Tayo Pa Ba?", artist = "RNBLiK", cat = "OPMHugot" },

	{ id = 89603126433051, title = "don't leave me now (huwag muna)", artist = "Miguel Ochosa", cat = "OPMHugot" },

	{ id = 104545034516911, title = "sayang", artist = "Jex De Castro", cat = "OPMHugot" },

	{ id = 135266079280048, title = "balewala sayo", artist = "Deen", cat = "OPMHugot" },

	{ id = 135149562293759, title = "natatakot ako", artist = "Deen", cat = "OPMHugot" },

	{ id = 75515706395423, title = "Kilig", artist = "OPM Music Studio", cat = "OPMKilig" },

	{ id = 79438436357411, title = "kilig", artist = "Megs", cat = "OPMKilig" },

	{ id = 131241019086058, title = "Kilig ka?", artist = "Renz0h", cat = "OPMKilig" },

	{ id = 136889170666383, title = "Sa’yo Lang ang Kilig", artist = "AReplyMusic", cat = "OPMKilig" },

	{ id = 100871830546603, title = "Mahal Na Ata Kita", artist = "AscensionFS", cat = "OPMKilig" },

	{ id = 104088399673562, title = "Ikaw Ang Ngiti Ko", artist = "Rodel Ruiz Studios", cat = "OPMKilig" },

	{ id = 77765815049364, title = "Ikaw Ang Chorus Ng Buhay Ko", artist = "Kiel R.", cat = "OPMKilig" },

	{ id = 129303923678752, title = "Ikaw ang Tadhana Ko", artist = "Kiel R.", cat = "OPMKilig" },

	{ id = 85479034326971, title = "Walang Katapusang Saya", artist = "Kiel R.", cat = "OPMKilig" },

	{ id = 122684867771238, title = "Kay saya", artist = "Ikaw-Ako", cat = "OPMKilig" },

	{ id = 120229214941178, title = "Ligaya", artist = "Ikaw-Ako", cat = "OPMKilig" },

	{ id = 94845207129136, title = "Bawat yakap", artist = "Ikaw-Ako", cat = "OPMKilig" },

	{ id = 112913388183690, title = "Sinta", artist = "Ikaw-Ako", cat = "OPMKilig" },

	{ id = 94497088983641, title = "Tayo Lang Dalawa", artist = "Squeezers", cat = "OPMKilig" },

	{ id = 113766651836320, title = "Sayo Lang Din", artist = "KYOSHI", cat = "OPMKilig" },

	{ id = 136631685174790, title = "Lipad Tayo (Let's Fly)", artist = "3NJ", cat = "OPMKilig" },

	{ id = 106539424538555, title = "Magkita Tayo (let's meet)", artist = "Rosh Acoba", cat = "OPMKilig" },

	{ id = 132632564471480, title = "DM Mo Na Ako", artist = "Harana Studio", cat = "OPMKilig" },

	{ id = 87373004703150, title = "Ulan at Ikaw", artist = "Kiel R.", cat = "OPMKilig" },

	{ id = 102877789029259, title = "Ikaw lang talaga", artist = "Plan Motiff", cat = "OPMKilig" },

	-- ===== Batch 3: Anime / J-Pop / C-Pop / K-Pop / International / more OPM (all DistrokidOfficial, verified 13 Nov 2026) =====

	{ id = 139666378376464, title = "SKYBREAKER ～Run, Scream, Fly Beyond～", artist = "Anime Girl Vocal", cat = "Anime" },

	{ id = 140397610798305, title = "Silent Meteor ～駆け抜ける光と影～", artist = "Anime Girl Vocal", cat = "Anime" },

	{ id = 138570554683231, title = "残響リスタート～Echoes of You～", artist = "Anime Girl Vocal", cat = "Anime" },

	{ id = 139472972711111, title = "ラスト・ダッシュ ～鼓動で描く自由～", artist = "Anime Girl Vocal", cat = "Anime" },

	{ id = 134321659580108, title = "青のグルーヴ～走り出せ、今～", artist = "Anime Girl Vocal", cat = "Anime" },

	{ id = 136562645938977, title = "BURNING SKY ～限界を超える鼓動～", artist = "Anime Girl Vocal", cat = "Anime" },

	{ id = 88830333334753, title = "Fly to the Morning Light", artist = "Anime Girl Vocal", cat = "Anime" },

	{ id = 137340351285867, title = "Blizzard Pulse ～Sing Through the Frozen City～", artist = "Anime Girl Vocal", cat = "Anime" },

	{ id = 128016125857239, title = "ステージ・ゼロ～Ready for the Run～", artist = "Anime Girl Vocal", cat = "Anime" },

	{ id = 138647866109727, title = "音速インフェルノ ～Inferno Rush～", artist = "Anime Girl Vocal", cat = "Anime" },

	{ id = 116482454763171, title = "Awakening Horizon", artist = "Anime Girl Vocal", cat = "Anime" },

	{ id = 137730213398076, title = "Ignite the Sky", artist = "Anime Girl Vocal", cat = "Anime" },

	{ id = 76841715215997, title = "燃える鼓動 (Moeru Kodou - Blazing Heartbeat)", artist = "Algaradio", cat = "Anime" },

	{ id = 134024886520742, title = "消えない声 (Kienai Koe - A Voice That Won't Fade)", artist = "Algaradio", cat = "Anime" },

	{ id = 132310052782338, title = "君の鼓動 (Kimi no Kodou - Your Heartbeat)", artist = "Algaradio", cat = "Anime" },

	{ id = 72250735002194, title = "夢のカケラ (Yume no Kakera - Fragments of a Dream)", artist = "Algaradio", cat = "Anime" },

	{ id = 117802174402055, title = "光の誓い (Hikari no Chikai - Oath of Light)", artist = "Algaradio", cat = "Anime" },

	{ id = 73979669866125, title = "最後の約束 (Saigo no Yakusoku - The Last Promise)", artist = "Algaradio", cat = "Anime" },

	{ id = 118984763030340, title = "夜のゲーム (Yoru no Game - Night Game)", artist = "Algaradio", cat = "Anime" },

	{ id = 113287483392873, title = "輝く瞬間 (Kagayaku Shunkan - Shining Moment)", artist = "Algaradio", cat = "Anime" },

	{ id = 96877875415904, title = "飛べるはず (Toberu Hazu - I Can Fly)", artist = "Algaradio", cat = "Anime" },

	{ id = 72982404278746, title = "天翔る影 (Ama Kakeru Kage) - Soaring Shadow", artist = "HDEDragon", cat = "Anime" },

	{ id = 135636126408904, title = "終焉ノ烈火 (Shuuen no Rekka) - Inferno of the End", artist = "HDEDragon", cat = "Anime" },

	{ id = 89549155689397, title = "光を掴んで (Grasp the Light)", artist = "HDEDragon", cat = "Anime" },

	{ id = 138053801157608, title = "夜風ドライブ – Night Breeze", artist = "Yumi Amano Japanese City Pop", cat = "JPop" },

	{ id = 132440106455313, title = "Borrowed Umbrella (1980's Citypop)", artist = "Yumi Amano Japanese City Pop", cat = "JPop" },

	{ id = 93922500855164, title = "銀座の君へ – To You in Ginza", artist = "Yumi Amano Japanese City Pop", cat = "JPop" },

	{ id = 107505157459506, title = "エレベーターのささやき - Elevator Whispers", artist = "Yumi Amano Japanese City Pop", cat = "JPop" },

	{ id = 100294043399421, title = "片道切符とワンピース / One-Way Ticket and One Piece", artist = "City Pop Tokyo", cat = "JPop" },

	{ id = 125596959051282, title = "想い出のドライブ / Memories Drive", artist = "City Pop Tokyo", cat = "JPop" },

	{ id = 90442630535496, title = "夢見るバカンス", artist = "City Pop Tokyo", cat = "JPop" },

	{ id = 95832108604815, title = "君だけのメロディ", artist = "City Pop Tokyo", cat = "JPop" },

	{ id = 140701945132988, title = "コーヒーが冷める前に (Before the Coffee Gets Cold)", artist = "ALSTUDIO", cat = "JPop" },

	{ id = 95780046352161, title = "終電まで (Until the Last Train)", artist = "ALSTUDIO", cat = "JPop" },

	{ id = 102601963247005, title = "恋のタイムアウト", artist = "Cool City Pop", cat = "JPop" },

	{ id = 93305727811788, title = "この夏あなたと弾けたい！", artist = "DRIVING CITY POP STUDIO", cat = "JPop" },

	{ id = 130629862352638, title = "真夜中ハイウェイ", artist = "Ellaivv", cat = "JPop" },

	{ id = 135348842077708, title = "東京タワーの雨", artist = "Ellaivv", cat = "JPop" },

	{ id = 125157050090611, title = "心拍エモーション (Heartbeat Emotion)", artist = "Song Socheata", cat = "JPop" },

	{ id = 118695863221768, title = "さよなら未満 (Almost Goodbye)", artist = "Song Socheata", cat = "JPop" },

	{ id = 132324203929665, title = "夜更かしラブ (Staying-Up Love)", artist = "Song Socheata", cat = "JPop" },

	{ id = 123758299072276, title = "Neon Tears Parade", artist = "Song Socheata", cat = "JPop" },

	{ id = 130862588931458, title = "Anime Heart — J-Pop Style (日本語)", artist = "Kira Mantle", cat = "JPop" },

	{ id = 140175169828824, title = "Kawaii Future Pop", artist = "Love Sleep Repeat", cat = "JPop" },

	{ id = 131162417057143, title = "Tokyo Streets", artist = "Love Sleep Repeat", cat = "JPop" },

	{ id = 96437577964828, title = "サマーのくせに", artist = "Musikwelt", cat = "JPop" },

	{ id = 123932632491015, title = "Candy-Colored Heartbeat", artist = "Musikwelt", cat = "JPop" },

	{ id = 135271968896251, title = "My Story", artist = "BLUE HARBOR", cat = "JPop" },

	{ id = 72221430337217, title = "My Star", artist = "BLUE HARBOR", cat = "JPop" },

	{ id = 126820181157702, title = "The Radiant Youth", artist = "BLUE HARBOR", cat = "JPop" },

	{ id = 111584181638642, title = "春にほどけた手", artist = "AI Japan Song", cat = "JPop" },

	{ id = 116990568952741, title = "会えない距離", artist = "AI Japan Song", cat = "JPop" },

	{ id = 123180721125036, title = "君色、夏祭り", artist = "SakuraCode", cat = "JPop" },

	{ id = 108849060438649, title = "キラメキ∞ループ", artist = "Kawaii Music Tune", cat = "JPop" },

	{ id = 111479990037736, title = "我喜歡這樣的你", artist = "Twinsight Music", cat = "CPop" },

	{ id = 122168954311656, title = "我們沒說完的那句話 (The Words We Never Said)", artist = "Twinsight Music", cat = "CPop" },

	{ id = 137427261969338, title = "月光裡的城市", artist = "Twinsight Music", cat = "CPop" },

	{ id = 139592447928651, title = "深夜餘溫 (After Hours)", artist = "Twinsight Music", cat = "CPop" },

	{ id = 139084907508650, title = "深夜告白 (Late Night Confessions)", artist = "Twinsight Music", cat = "CPop" },

	{ id = 112020020480794, title = "你不用多說 (You Don't Have to Say It)", artist = "Twinsight Music", cat = "CPop" },

	{ id = 78668394690851, title = "走慢一點 (Slowly)", artist = "Twinsight Music", cat = "CPop" },

	{ id = 102744824594786, title = "你走之後我還在 (Still Here Without You)", artist = "Twinsight Music", cat = "CPop" },

	{ id = 102381115052172, title = "剛剛好的距離 (Just Close Enough)", artist = "Twinsight Music", cat = "CPop" },

	{ id = 119279103412941, title = "Coffee & You (咖啡與你)", artist = "Twinsight Music", cat = "CPop" },

	{ id = 137866305139120, title = "你给的伤太深", artist = "Sophea Music", cat = "CPop" },

	{ id = 108959842711687, title = "你不回头", artist = "Sophea Music", cat = "CPop" },

	{ id = 139562074567825, title = "越安靜越傷人的旋律", artist = "Sophea Music", cat = "CPop" },

	{ id = 103934259467868, title = "你不在的冬天", artist = "Music Chinese Official", cat = "CPop" },

	{ id = 115381358994998, title = "不再等你", artist = "Music Chinese Official", cat = "CPop" },

	{ id = 91639428164629, title = "你的背影", artist = "Music Chinese Official", cat = "CPop" },

	{ id = 85184501444528, title = "你的溫柔是我最安心的光", artist = "Music Chinese Official", cat = "CPop" },

	{ id = 130446561775880, title = "夕照残宫花", artist = "Alita Offcial", cat = "CPop" },

	{ id = 121789498225380, title = "如果思念有尽头", artist = "Alita Offcial", cat = "CPop" },

	{ id = 125863132517061, title = "后来我学会沉默", artist = "Alita Offcial", cat = "CPop" },

	{ id = 106091803355709, title = "你的預言 (Your Prediction)", artist = "ALSTUDIO", cat = "CPop" },

	{ id = 110953037243594, title = "心跳无限", artist = "Luy Sokmean", cat = "CPop" },

	{ id = 101328005557095, title = "Under the Starlight (별빛 아래에서)", artist = "Twinsight Music", cat = "KPop" },

	{ id = 113478021208908, title = "Forever & Day (영원 그 이상)", artist = "Twinsight Music", cat = "KPop" },

	{ id = 132161951756209, title = "Caramel Macchiato (카라멜 마키아토)", artist = "Twinsight Music", cat = "KPop" },

	{ id = 140591194032158, title = "항상 여기 있을게 (I'll Always Be Here)", artist = "SKS K-POP", cat = "KPop" },

	{ id = 75903180765871, title = "Roofline Rain", artist = "SKS K-POP", cat = "KPop" },

	{ id = 109627082051840, title = "Drafts in the Folder", artist = "SKS K-POP", cat = "KPop" },

	{ id = 93573494081838, title = "You and Me, So Right", artist = "K-Heart Beats", cat = "KPop" },

	{ id = 131509456274216, title = "You Make Life Shine", artist = "K-Heart Beats", cat = "KPop" },

	{ id = 97223108634576, title = "PIXEL HEART", artist = "aru-k-pop", cat = "KPop" },

	{ id = 90928728029376, title = "Picture in My Mind", artist = "KPOPORO", cat = "KPop" },

	{ id = 123503088388239, title = "Glitch Mode", artist = "KPOPORO", cat = "KPop" },

	{ id = 89788827950815, title = "Happy Signals", artist = "KPOPORO", cat = "KPop" },

	{ id = 72643802482520, title = "작은 방의 기억", artist = "KPOPORO", cat = "KPop" },

	{ id = 82499610082070, title = "Midnight in Seoul", artist = "Kpop Girl", cat = "KPop" },

	{ id = 134219744169520, title = "After Midnight Seoul", artist = "Kpop Girl", cat = "KPop" },

	{ id = 119305597132708, title = "Today", artist = "Kpop ECHO", cat = "KPop" },

	{ id = 139073274844718, title = "Better Days", artist = "Kpop ECHO", cat = "KPop" },

	{ id = 128213597443246, title = "Runway Baby", artist = "Xzy Jane", cat = "KPop" },

	{ id = 127775725318214, title = "Orbit In Your Eyes", artist = "Xzy Jane", cat = "KPop" },

	{ id = 109465269102964, title = "비 오는 날의 약속", artist = "KPoppies", cat = "KPop" },

	{ id = 131241697624870, title = "The Window Seat", artist = "KPoppies", cat = "KPop" },

	{ id = 123860629119609, title = "너는 내 가장 좋은 부분이야", artist = "Natster Original", cat = "KPop" },

	{ id = 77534942014650, title = "여름은 아직 우리 곁에 있어", artist = "DADAM", cat = "KPop" },

	{ id = 105591057954960, title = "서울의 빗소리 (Seoul Rain)", artist = "KimK-POP", cat = "KPop" },

	{ id = 91867574842899, title = "I Almost Sent It", artist = "Seoulstice", cat = "KPop" },

	{ id = 93535982088168, title = "The Empty Room You Left Behind (그대 떠난 빈 방)", artist = "H2Osounds", cat = "KPop" },

	{ id = 123133949304954, title = "스무 살의 나", artist = "ALSTUDIO", cat = "KPop" },

	{ id = 120024233271733, title = "북극성을 따라", artist = "ALSTUDIO", cat = "KPop" },

	{ id = 115539799413381, title = "누구 (Nugu) - Who", artist = "Midnight cocoa", cat = "KPop" },

	{ id = 114147693996861, title = "잘 지내 (Jaljinae) - How are you?", artist = "Midnight cocoa", cat = "KPop" },

	{ id = 77157952531524, title = "Huling Luha", artist = "Rookies Dream", cat = "OPMHugot" },

	{ id = 136260904693174, title = "Luha at Alaala", artist = "Kent Vincent Canedo", cat = "OPMHugot" },

	{ id = 86308532970590, title = "Huwag Muna Tayong Sumuko", artist = "Rodel Ruiz Studios", cat = "OPMHugot" },

	{ id = 78453506803670, title = "Kung Hindi Na Tayo", artist = "Rodel Ruiz Studios", cat = "OPMHugot" },

	{ id = 106186296993028, title = "Kahit Di Na Tayo", artist = "ChiefMarco13", cat = "OPMHugot" },

	{ id = 128545319318638, title = "Kahit Tayo'y Nagkalayo", artist = "Pinoy Music Lover", cat = "OPMHugot" },

	{ id = 93382609198127, title = "Walang Paalam", artist = "Kiel R.", cat = "OPMHugot" },

	{ id = 138232471273068, title = "Pusong Nasugatan", artist = "Jessil Beriso", cat = "OPMHugot" },

	{ id = 129550957509123, title = "Puso'y Kailangan Na Ng Pahinga", artist = "Team Sekai", cat = "OPMHugot" },

	{ id = 114439181654732, title = "Nagtiwala Ako Sayo", artist = "Team Sekai", cat = "OPMHugot" },

	{ id = 74236915827592, title = "Salamat, Paalam", artist = "Eduard B.", cat = "OPMHugot" },

	{ id = 130472020289806, title = "Sandali, Paalam", artist = "Viced", cat = "OPMHugot" },

	{ id = 91391273820352, title = "Nagkamali Ako", artist = "Harana Studio", cat = "OPMHugot" },

	{ id = 93659252984737, title = "Naglalakad Sa Ulan", artist = "Aldz Rockverse", cat = "OPMHugot" },

	{ id = 101608801305237, title = "Yayakapin Ko Ang Iyong Alaala", artist = "Jrl Awitkosayo", cat = "OPMHugot" },

	{ id = 99366089585980, title = "Hanggang Kailan", artist = "Rookies Dream", cat = "OPMHugot" },

	{ id = 120326787038388, title = "Habambuhay, Mahal", artist = "WANDERLEO CHRONICLES", cat = "OPMKilig" },

	{ id = 76648149524650, title = "Mahal Kita, Walang Iba", artist = "WANDERLEO CHRONICLES", cat = "OPMKilig" },

	{ id = 82808021863905, title = "Hanggang Pagtanda", artist = "WANDERLEO CHRONICLES", cat = "OPMKilig" },

	{ id = 135924564135809, title = "Tadhana Nating Dalawa", artist = "Alia Levine", cat = "OPMKilig" },

	{ id = 119960165443483, title = "Sa'Yo Lang", artist = "JuLyo", cat = "OPMKilig" },

	{ id = 84457658725000, title = "Pangarap Kita", artist = "AscensionFS", cat = "OPMKilig" },

	{ id = 88049017199841, title = "Mahal Kita Lagi", artist = "AscensionFS", cat = "OPMKilig" },

	{ id = 95201779894300, title = "Tadhana'y Ikaw", artist = "Kiel R.", cat = "OPMKilig" },

	{ id = 116292060069299, title = "Ikaw Ang Trending Love Ko", artist = "Kiel R.", cat = "OPMKilig" },

	{ id = 105904519111569, title = "Walang Hanggang Tayo", artist = "Rodel Casas", cat = "OPMKilig" },

	{ id = 95495952218554, title = "Sayo Lang Ako", artist = "Rodel Casas", cat = "OPMKilig" },

	{ id = 121241290104098, title = "Mahal Kita, Dahan-Dahan", artist = "Roy Bato Project", cat = "OPMKilig" },

	{ id = 121232995153442, title = "Mahal Kita sa Maliit na Bagay", artist = "Roy Bato Project", cat = "OPMKilig" },

	{ id = 124707770053936, title = "Bakit Kita Mahal", artist = "Dimples Ceniza", cat = "OPMKilig" },

	{ id = 83514289676299, title = "Basta Mahal Kita", artist = "KAGUYAN", cat = "OPMKilig" },

	{ id = 118927956868836, title = "Kilig", artist = "NOKTVRA", cat = "OPMKilig" },

	{ id = 97042848839102, title = "Ikaw Lang", artist = "Payl", cat = "OPMKilig" },

	{ id = 113878571520117, title = "Ikaw Lang", artist = "Jessil Beriso", cat = "OPMKilig" },

	{ id = 132449204319206, title = "Ikaw Pa Rin Ang Tahanan Ko", artist = "MTNLP MUSIC", cat = "OPMKilig" },

	{ id = 87476522132907, title = "Sa Ilalim Ng Buwan", artist = "Yannskie Original Songs", cat = "OPMChill" },

	{ id = 86568016619865, title = "Sa Ilalim ng Buwan", artist = "BorgC", cat = "OPMChill" },

	{ id = 102412475088166, title = "Pag-ibig sa Gitna ng Ulan", artist = "BorgC", cat = "OPMChill" },

	{ id = 80422917053491, title = "Sa Gitna ng Ulan", artist = "CYXHUNTER", cat = "OPMChill" },

	{ id = 123045807130521, title = "Sa Ilalim ng Bituin", artist = "CYXHUNTER", cat = "OPMChill" },

	{ id = 73250535238459, title = "Tahimik na Sandali", artist = "CYXHUNTER", cat = "OPMChill" },

	{ id = 133091010815715, title = "Ulan", artist = "CYXHUNTER", cat = "OPMChill" },

	{ id = 77542608449635, title = "Sa Bawat Patak ng Ulan", artist = "Rodel Casas", cat = "OPMChill" },

	{ id = 78846579857183, title = "Ulan at Alaala", artist = "TheY2Project", cat = "OPMChill" },

	{ id = 98580194522612, title = "Bituin", artist = "Renz0h", cat = "OPMChill" },

	{ id = 118732275469851, title = "Buwan", artist = "Maya Mercado", cat = "OPMChill" },

	{ id = 119957228736067, title = "Harana", artist = "Maya Mercado", cat = "OPMChill" },

	{ id = 104980374658374, title = "Tricycle Sa Ulan", artist = "CaRCara", cat = "OPMChill" },

	{ id = 130696999442825, title = "Sa Himig ng Buwan", artist = "PapaRay Balanza", cat = "OPMChill" },

	{ id = 87918846361594, title = "Biyaheng Langit", artist = "Your Mood Music", cat = "OPMChill" },

	{ id = 108488123898594, title = "Liwanag sa Gabi", artist = "Echoes of Musics PH", cat = "OPMChill" },

	{ id = 77151580639947, title = "Falling Back into You", artist = "Twinsight Music", cat = "Vocal" },

	{ id = 135753845938922, title = "NEON LOVE", artist = "Twinsight Music", cat = "Vocal" },

	{ id = 137274345408658, title = "Midnight Keeps You", artist = "Twinsight Music", cat = "Vocal" },

	{ id = 121301270572003, title = "Main Character", artist = "Twinsight Music", cat = "Vocal" },

	{ id = 84838206593985, title = "Stay a Little Longer", artist = "Twinsight Music", cat = "Vocal" },

	{ id = 103598353672281, title = "Hold Your Hand", artist = "Twinsight Music", cat = "Vocal" },

	{ id = 131681765294489, title = "You and Me", artist = "Twinsight Music", cat = "Vocal" },

	{ id = 126716036360156, title = "Replay My Heart", artist = "Twinsight Music", cat = "Vocal" },

	{ id = 90008774322307, title = "Keep You Around", artist = "Twinsight Music", cat = "Vocal" },

	{ id = 84488321799558, title = "The Sweater Smelled Like Sunday", artist = "Neon Heart Pop", cat = "Vocal" },

	{ id = 101939151064345, title = "Our Favorite Table by the Window", artist = "Neon Heart Pop", cat = "Vocal" },

	{ id = 137058306820212, title = "We Danced Behind the Bowling Alley", artist = "Neon Heart Pop", cat = "Vocal" },

	{ id = 134005962747545, title = "Locker 217 Still Has My Initials", artist = "Neon Heart Pop", cat = "Vocal" },

	{ id = 116776651294649, title = "The Way You Light the Dark", artist = "Heart Whisper", cat = "Vocal" },

	{ id = 106623302151398, title = "Still Choosing You", artist = "Heart Whisper", cat = "Vocal" },

	{ id = 110970379871313, title = "If I Could Stop Time Here", artist = "Heart Whisper", cat = "Vocal" },

	{ id = 132315329572198, title = "Talk All Night", artist = "Skygen", cat = "Vocal" },

	{ id = 75457854019134, title = "Falling In Love on a Rainy Day", artist = "Skygen", cat = "Vocal" },

	{ id = 74300614555253, title = "Inside Jokes", artist = "Skygen", cat = "Vocal" },

	{ id = 132589556313053, title = "You Feel Like Home", artist = "Armosa Project", cat = "Vocal" },

	{ id = 85715989072099, title = "Caught In The Moment", artist = "Armosa Project", cat = "Vocal" },

	{ id = 101531277154319, title = "Keep This Summer", artist = "Saffron Tide", cat = "Vocal" },

	{ id = 77327262559993, title = "Summer Hallway Love", artist = "Forrest Arton", cat = "Vocal" },

	{ id = 106045333504071, title = "The Light You Leave On", artist = "Sky-c Roots", cat = "Vocal" },

	{ id = 129139799155981, title = "Nothing Feels Better", artist = "Mail Soul Midnight", cat = "Vocal" },

	{ id = 127818086722892, title = "Warm Hands In Winter", artist = "Mail Soul Midnight", cat = "Vocal" },

	{ id = 99597415296107, title = "Midnight Feels Like Home", artist = "Mail Soul Midnight", cat = "Vocal" },

	{ id = 84589160518217, title = "Coffee & Quiet Love", artist = "Cozy Chords", cat = "Vocal" },

	{ id = 126333704664658, title = "You Loved Me Until You Didn't", artist = "Erich Official", cat = "Relapse" },

	{ id = 90529937598457, title = "Your Name on My Screen", artist = "Erich Official", cat = "Relapse" },

	{ id = 133126129543759, title = "We Were Almost Forever", artist = "Erich Official", cat = "Relapse" },

	{ id = 81266570508275, title = "The Boy You Left Behind", artist = "Erich Official", cat = "Relapse" },

	{ id = 94013504405979, title = "I Miss You I Forgot Myself", artist = "Jasper Rhys", cat = "Relapse" },

	{ id = 100602743779868, title = "I Left the Light On for Myself", artist = "Jasper Rhys", cat = "Relapse" },

	{ id = 77793716861546, title = "Still Waiting for You", artist = "Jasper Rhys", cat = "Relapse" },

	{ id = 112778236983836, title = "Softly, I Let You Go", artist = "Kdam Sor", cat = "Relapse" },

	{ id = 118276024297629, title = "The Way You Stayed", artist = "Kdam Sor", cat = "Relapse" },

	{ id = 90803404182367, title = "Read Receipts", artist = "Phy 4Ever", cat = "Relapse" },

	{ id = 132769191273157, title = "You Could've Stayed", artist = "Phy 4Ever", cat = "Relapse" },

	{ id = 95597020332881, title = "Stolen Hoodies", artist = "Phy 4Ever", cat = "Relapse" },

	{ id = 138513609871752, title = "Parking Lot Goodbye", artist = "Youllat", cat = "Relapse" },

	{ id = 130790290111204, title = "Echoes of Goodbye", artist = "LEYNAROSE", cat = "Relapse" },

	{ id = 138108296865882, title = "You Were My Safe Place", artist = "Da Songs", cat = "Relapse" },

	{ id = 88297239558413, title = "Rain On My Side", artist = "Xzy Jane", cat = "Relapse" },

	{ id = 136771907698477, title = "I Wish You Stayed Longer", artist = "Mr Manila", cat = "Relapse" },

	{ id = 134278054653020, title = "Still Awake At Midnight", artist = "Eden Strings", cat = "Relapse" },

	{ id = 109922497859169, title = "On the Edge of Your Goodbye", artist = "Emilio Silver", cat = "Relapse" },

	{ id = 122970569781770, title = "Tahimik Pero Sumasayaw", artist = "Kiel R.", cat = "OPMKilig" },

	-- ===== Batch 4 (DistrokidOfficial, verified 14 Nov 2026) =====

	{ id = 92875469381946, title = "Hold Me Near", artist = "Twinsight Music", cat = "Vocal" },

	{ id = 72416343067115, title = "Your Scent Remains", artist = "Twinsight Music", cat = "Vocal" },

	{ id = 79718235539263, title = "Come to Life", artist = "Skygen", cat = "Vocal" },

	{ id = 97223571257650, title = "Sweetpea", artist = "Skygen", cat = "Vocal" },

	{ id = 136425487463996, title = "Smile In Passing", artist = "Simply Pop Collective", cat = "Vocal" },

	{ id = 82872237833743, title = "Echoes of Us", artist = "Twinsight Music", cat = "Relapse" },

	{ id = 105748941335199, title = "Unspoken Words", artist = "Jasper Rhys", cat = "Relapse" },

	{ id = 135053730821320, title = "Love Left Behind", artist = "Jasper Rhys", cat = "Relapse" },

	{ id = 113328859494500, title = "Letters Never Sent to You", artist = "SuperMeng", cat = "Relapse" },

	{ id = 140032388517769, title = "Flowers After Rain", artist = "Kdam Sor", cat = "Relapse" },

	-- ===== Batch 5: Trending Pop + Anime Opening style (licensed: DistrokidOfficial / APMOfficial, found 16 Nov 2026) =====
	-- 🔥 Trending Pop
	{ id = 93590577207175, title = "Inspiring Jazz Funk Pop Upbeat", artist = "Vasyl Manchuk", cat = "TrendingPop" },
	{ id = 121330252311604, title = "CARBON COPY", artist = "Brain EQ", cat = "TrendingPop" },
	{ id = 137550455031751, title = "Upbeat Pop for Deep Focus", artist = "Music for Concentration Flow", cat = "TrendingPop" },
	{ id = 132764607139692, title = "SUNSHINE STATE OF MIND", artist = "Brain EQ", cat = "TrendingPop" },
	{ id = 110486899448143, title = "Spark in the Dark (Upbeat 90s Country-Pop)", artist = "��្ដិ� គ្មានជំនោរ", cat = "TrendingPop" },
	{ id = 128586592071511, title = "GALAXY GIRL", artist = "Brain EQ", cat = "TrendingPop" },
	{ id = 71458156835103, title = "I fight back, with the wheels on fire", artist = "moodne", cat = "TrendingPop" },
	{ id = 1837407430, title = "Let's Work It Out", artist = "APM Music", cat = "TrendingPop" },
	{ id = 1839763308, title = "Upbeat Pop", artist = "APM Music", cat = "TrendingPop" },
	{ id = 9043224248, title = "I Want Your Feels", artist = "APM Music", cat = "TrendingPop" },
	{ id = 82877098600931, title = "SATELLITE SOUL", artist = "Brain EQ", cat = "TrendingPop" },
	{ id = 110537983321500, title = "If You Love San Francisco", artist = "S Scott", cat = "TrendingPop" },
	{ id = 9043224162, title = "Cynics", artist = "APM Music", cat = "TrendingPop" },
	{ id = 1837416899, title = "The Girl In A Tower", artist = "APM Music", cat = "TrendingPop" },
	{ id = 82920560863065, title = "Kickin' Up", artist = "APM Music", cat = "TrendingPop" },
	{ id = 127783699706682, title = "Dance Music On", artist = "MoodMode", cat = "TrendingPop" },
	{ id = 84594189043147, title = "PARTY / UPBEAT POP | Last Call Heroes", artist = "Charmaine Pezzuto", cat = "TrendingPop" },
	{ id = 1837407452, title = "You Want to Get Free", artist = "APM Music", cat = "TrendingPop" },
	{ id = 118486026322822, title = "Upbeat Corporate Pop", artist = "Jerome Chauvel", cat = "TrendingPop" },
	{ id = 89237254792396, title = "Pep in Your Step", artist = "APM Music", cat = "TrendingPop" },
	{ id = 97986838449284, title = "Fresh and Upbeat Pop Folk", artist = "Jerome Chauvel", cat = "TrendingPop" },
	{ id = 97685522520719, title = "Sweet Indulgence (Ice Cream)", artist = "S Scott", cat = "TrendingPop" },
	{ id = 98899646766282, title = "We'll Keep It Upbeat", artist = "S Scott", cat = "TrendingPop" },
	{ id = 116452777077987, title = "I�m driving overtime, yeah overtime", artist = "moodne", cat = "TrendingPop" },
	{ id = 79732514473175, title = "Kickstart the Day", artist = "APM Music", cat = "TrendingPop" },
	{ id = 120525481352077, title = "Ocher Dawn (Upbeat folk-Pop Song)", artist = "spAI Beats", cat = "TrendingPop" },
	{ id = 80501483587926, title = "Emerald Grace (Upbeat Latin-infused Pop Song)", artist = "spAI Beats", cat = "TrendingPop" },
	{ id = 1842612641, title = "Boombox Jazz", artist = "APM Music", cat = "TrendingPop" },
	{ id = 121545323876491, title = "K-pop Cute Crush � Dance Pop Korean (한국어)", artist = "Kira Mantle", cat = "TrendingPop" },
	{ id = 95862004723024, title = "Electric Sunrise (Dance-Pop, R&B, Hip-Hop)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 90409233638163, title = "Glass Cities � 80s Synth Pop | Cold Neon Aesthetic", artist = "Love Sleep Repeat", cat = "TrendingPop" },
	{ id = 1840321644, title = "Rave!", artist = "APM Music", cat = "TrendingPop" },
	{ id = 120664236448458, title = "Disco Voador", artist = "Mauricio MRH", cat = "TrendingPop" },
	{ id = 1840321601, title = "Eurobeat", artist = "APM Music", cat = "TrendingPop" },
	{ id = 103356166395852, title = "Light It Up (Dance Pop)", artist = "VireWolf", cat = "TrendingPop" },
	{ id = 87206464821112, title = "Burning In My Soul (Slap House)", artist = "DeepDrop", cat = "TrendingPop" },
	{ id = 94904036331297, title = "Echoes in the Rain (R&B, Hip-Hop, Reggae)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 88933168125088, title = "Que Homem Eu Sou Hoje?", artist = "Mauricio MRH", cat = "TrendingPop" },
	{ id = 124325173394473, title = "Tomorrow Starts Now (Pop, Electro-Pop, Dance)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 71832028712010, title = "Slow Motion Fire (Dark Dance-Pop, R&B, Hip-Hop)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 81780260027779, title = "Midnight Skyline (Pop, Contemporary R&B)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 135361546383974, title = "K-Pop Party", artist = "Beyond Bassline", cat = "TrendingPop" },
	{ id = 135315392859745, title = "Secret Language (R&B, Dance-Pop)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 107711892588652, title = "Summer Without End (Reggae, Dancehall, Pop)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 121466185599463, title = "NO BRAKES ON MY LIGHT (Afrobeats & Afro Pop Dance)", artist = "Ahmed Elmasry Mazykha Hup", cat = "TrendingPop" },
	{ id = 84501429041638, title = "No Gravity Tonight (Dance-Pop � Electro)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 1846053320, title = "Eurofax", artist = "APM Music", cat = "TrendingPop" },
	{ id = 1840321770, title = "Free Your Mind", artist = "APM Music", cat = "TrendingPop" },
	{ id = 75835628597496, title = "Higher Than Stars (Pop, Electro)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 121416896999522, title = "K-pop Cute Crush � Dance Pop", artist = "Kira Mantle", cat = "TrendingPop" },
	{ id = 109198658650354, title = "Gold Horizon (Pop � Hip-Hop)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 104380317021360, title = "HORIZON BLEU (French Electropop, Contemporary R&B)", artist = "RAYHEN KARAM", cat = "TrendingPop" },
	{ id = 90907227904559, title = "Red Dress � Classic 80s Dance Pop", artist = "001ap", cat = "TrendingPop" },
	{ id = 1836755212, title = "Get Crazy", artist = "APM Music", cat = "TrendingPop" },
	{ id = 1837088686, title = "Struggle", artist = "APM Music", cat = "TrendingPop" },
	{ id = 1836959563, title = "Candy Pop", artist = "APM Music", cat = "TrendingPop" },
	{ id = 1837110650, title = "Temptation", artist = "APM Music", cat = "TrendingPop" },
	{ id = 99970340116134, title = "Brilho Do Teu Olhar", artist = "Mauricio MRH", cat = "TrendingPop" },
	{ id = 117767396224618, title = "In The Glow (Slap House #1)", artist = "DeepDrop", cat = "TrendingPop" },
	{ id = 1845726259, title = "Hallo Mister X", artist = "APM Music", cat = "TrendingPop" },
	{ id = 1845726308, title = "American Swing", artist = "APM Music", cat = "TrendingPop" },
	{ id = 135126215870866, title = "Ás (Alfabeto Amoroso)", artist = "Mauricio MRH", cat = "TrendingPop" },
	{ id = 91064077639600, title = "Rock My Heart /Best for a modern pop/dance song", artist = "ZARAMA", cat = "TrendingPop" },
	{ id = 82028519579865, title = "DJ/Pop Track Concept (Dance-Pop Mix)", artist = "B.H Songs", cat = "TrendingPop" },
	{ id = 96652604083792, title = "Velvet Thunder (R&B � Hip-Hop)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 119706549503483, title = "Club Mosaic (Dance, Reggaeton)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 77998337513700, title = "Chronicles (Dance-pop/Funk)", artist = "Free Content Lab", cat = "TrendingPop" },
	{ id = 1840321272, title = "Dance Up! (A)", artist = "APM Music", cat = "TrendingPop" },
	{ id = 90504879327922, title = "Galactic Groove", artist = "Beyond Bassline", cat = "TrendingPop" },
	{ id = 112672829295297, title = "We Keep Dancing (Latin Pop)", artist = "AmaraCaliente", cat = "TrendingPop" },
	{ id = 111644742240967, title = "Dance Until Sunrise (Dance, Pop)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 77538222353242, title = "Tokyo Cut Japanese Dance Pop", artist = "Lexy Motion", cat = "TrendingPop" },
	{ id = 1842672757, title = "Panoramic", artist = "APM Music", cat = "TrendingPop" },
	{ id = 1837110785, title = "Feeling", artist = "APM Music", cat = "TrendingPop" },
	{ id = 96980403892960, title = "BEATBOX SERENADE (Experimental Pop / Hiphop)", artist = "RAYHEN KARAM", cat = "TrendingPop" },
	{ id = 87831404145279, title = "Lose All Control (Slap House #1)", artist = "DeepDrop", cat = "TrendingPop" },
	{ id = 84485065078860, title = "My Kind Of Crazy (Pop, R&B, Funk)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 137613556119936, title = "Лайк - (Delta)", artist = "MIRENKA", cat = "TrendingPop" },
	{ id = 124025310573669, title = "Dance With Me (My Synth-pop Queen)", artist = "TAPES", cat = "TrendingPop" },
	{ id = 92573082983440, title = "I'm no angel (dance-pop)", artist = "Dabija Marius-Narcis", cat = "TrendingPop" },
	{ id = 1842612564, title = "Ukulele Dance", artist = "APM Music", cat = "TrendingPop" },
	{ id = 102544793058275, title = "MON ADN (Hip-Hop, Pop, Trap)", artist = "RAYHEN KARAM", cat = "TrendingPop" },
	{ id = 1845726194, title = "Von Spanien Nach Südamerika", artist = "APM Music", cat = "TrendingPop" },
	{ id = 1836959397, title = "Move Your Feet", artist = "APM Music", cat = "TrendingPop" },
	{ id = 111845743813666, title = "Euphoria Rising", artist = "Beyond Bassline", cat = "TrendingPop" },
	{ id = 115846580489388, title = "Future Legend (Pop � Hip-Hop � Electro � Dance)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 81164889408968, title = "Eu Não Sei", artist = "Mauricio MRH", cat = "TrendingPop" },
	{ id = 70475024539485, title = "One More Summer (Dancehall � Pop � Reggae)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 93309349726150, title = "Estamos em Obras (Desculpe o Transtorno)", artist = "Mauricio MRH", cat = "TrendingPop" },
	{ id = 1837088591, title = "Indie Trousers", artist = "APM Music", cat = "TrendingPop" },
	{ id = 79473286870737, title = "Se Eu Só Reclamo", artist = "Mauricio MRH", cat = "TrendingPop" },
	{ id = 131582344777239, title = "Pressure Makes Diamonds", artist = "Redline Archive", cat = "TrendingPop" },
	{ id = 123134049430679, title = "Neon Fangs", artist = "Sereon·Vale", cat = "TrendingPop" },
	{ id = 1837105526, title = "She Hurt My Head", artist = "APM Music", cat = "TrendingPop" },
	{ id = 112135198890462, title = "STARLIGHT RENDEZVOUS", artist = "Brain EQ", cat = "TrendingPop" },
	{ id = 103037990639163, title = "Shine, My Star", artist = "Muz Echo", cat = "TrendingPop" },
	{ id = 79699343270829, title = "Dancing Under the Moon � Pop", artist = "Ourn_BG", cat = "TrendingPop" },
	{ id = 117104497222709, title = "Moonlight On Your Doorstep", artist = "Nova Melody 8K", cat = "TrendingPop" },
	{ id = 136535809915934, title = "So Good", artist = "Julian Lima", cat = "TrendingPop" },
	{ id = 118050515357026, title = "Dancing You Away | Synth R&B Pop", artist = "Quantq", cat = "TrendingPop" },
	{ id = 138261472165124, title = "BASSE DESERT STORM (Middle Eastern Trap / Cinematic Hiphop)", artist = "RAYHEN KARAM", cat = "TrendingPop" },
	{ id = 97116611067084, title = "Happy Little Feet", artist = "Muz Echo", cat = "TrendingPop" },
	{ id = 76371345054770, title = "Se Eu Canto, Eu Invento", artist = "Mauricio MRH", cat = "TrendingPop" },
	{ id = 110660191860283, title = "First Thirty (EDM Dance-Pop)", artist = "EmilyChiH", cat = "TrendingPop" },
	{ id = 1845726106, title = "Piano Billy", artist = "APM Music", cat = "TrendingPop" },
	{ id = 96233627115907, title = "Last Call Cowboy (Country Pop + Dance Pop)", artist = "Genre Soup", cat = "TrendingPop" },
	{ id = 131832484195772, title = "NEON MASQUERADE", artist = "Brain EQ", cat = "TrendingPop" },
	{ id = 134732903500343, title = "Electric Soul", artist = "Beyond Bassline", cat = "TrendingPop" },
	{ id = 78058454335367, title = "Me Deixa Respirar", artist = "Mauricio MRH", cat = "TrendingPop" },
	{ id = 127798509428340, title = "No Passport Needed (Reggaeton, Afro-Pop, Dance)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 139120736035382, title = "Dangerously Beautiful (Pop, R&B, Funk)", artist = "YANKAM", cat = "TrendingPop" },
	{ id = 1837110694, title = "Skyhook", artist = "APM Music", cat = "TrendingPop" },
	-- ⚔️ Anime Opening
	{ id = 124853612881772, title = "覚醒 (Kakusei) � Erwachen", artist = "HDEDragon", cat = "AnimeOP" },
	{ id = 140536358818160, title = "終焉��閃光(Shuuen no Senkou) � Flash of the End", artist = "HDEDragon", cat = "AnimeOP" },
	{ id = 109753720862601, title = "Animal Hospital Anime Opening", artist = "BENJIxScarlett", cat = "AnimeOP" },
	{ id = 90588286632687, title = "消������声 (Kienai Koe - A Voice That Won�t Fade)", artist = "Algaradio", cat = "AnimeOP" },
	{ id = 72573266268313, title = "Rise to the Horizon", artist = "HDEDragon", cat = "AnimeOP" },
	{ id = 87065827699369, title = "Fading Memories", artist = "HDEDragon", cat = "AnimeOP" },
	{ id = 96390226565608, title = "燃���! (Moero!) - Burn Up!", artist = "HDEDragon", cat = "AnimeOP" },
	{ id = 104268849297578, title = "影������� (Kage to Dance - Dancing with Shadows)", artist = "Algaradio", cat = "AnimeOP" },
	{ id = 88704298134223, title = "消����星 (Kieta Hoshi) - Die verschwundene Stern)", artist = "HDEDragon", cat = "AnimeOP" },
	{ id = 120729792529978, title = "影��彼方��(Kage no Kanata e) � Beyond the Shadows", artist = "HDEDragon", cat = "AnimeOP" },
	{ id = 106651387537717, title = "虚�����支�� (Utsuronaru Shihaisha)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 131098735247504, title = "終焉��舞台 (Shuuen no Butai)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 112418272582529, title = "影��呑����� (Kage ni Nomareru)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 124768059606843, title = "失�����家族 (Ushinawareta Kazoku)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 72924175370959, title = "終焉��調律 (Shūen no Ch�ritsu)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 139418490226835, title = "守護腁�嘆� (Shugosha no Nageki)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 137471463542585, title = "闇��舞踏会 (Yami no But�kai)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 85686823599079, title = "兄妹��誓�� (Keimai no Chikai)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 117658692949768, title = "黒闇��意志 (Kuroyami no Ishi)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 128797816164821, title = "擂����未来 (Ayatsurareta Mirai)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 125828398252901, title = "愛��境�線 (Ai no Ky�kaisen)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 134498250807519, title = "�野��誓�� (Kouya no Chikai)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 88121193624757, title = "夜��裂��声 (Yoru o Saku Koe)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 139208304161923, title = "運命��歯車 (Unmei no Haguruma)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 126159917381111, title = "奈落��覚醒 (Naraku no Kakusei)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 127567317913669, title = "影畁�王座 (Eikai no �za)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 96468324472307, title = "日蝕��覚醒 (Nisshoku no Kakusei)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 137056382648986, title = "破滅��宴 (Hametsu no Utage)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 72638053883205, title = "境�線��狩人 (Ky�kaisen no Karyūdo)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 74630698259258, title = "暗黒��裁� (Ankoku no Sabaki)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 133706092212567, title = "星屑��交響曲 (Hoshikuzu no K�ky�kyoku)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 107839708800328, title = "光亡�勇腁��� (Hikari Naki Yuusha-tachi)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 90973158086277, title = "擂����運命 (Ayatsurareru Unmei)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 106824895504259, title = "兄妹���裂 (Keimai no Kiretsu)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 81161163728199, title = "闇月��囁� (Yamitsuki no Sasayaki)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 90936789676540, title = "風早��刃 (Kazehaya no Yaiba)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 91843915512270, title = "破滅���奏曲 (Hametsu no Ky�s�kyoku)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 88471982384321, title = "終������序章 (Owari no Josh�)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 108408718528395, title = "禁�������道 (Kinjirareta Michi)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 76378930542140, title = "影���跡 (Kage no Kiseki)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 101405768309399, title = "虚構��道標 (Kyok� no Michishirube)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 131418641453194, title = "闇��裂��灯 (Yami o Saku Hi)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 129548780550125, title = "�醁�灯火 (Hangyaku no Tomoshibi)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 75045752230991, title = "奈落��招待 (Naraku no Sh�tai)", artist = "VnightVibes", cat = "AnimeOP" },
	{ id = 125544997735091, title = "Cute Electro Pop Japan � Viral J-Pop Style Beat", artist = "Love Sleep Repeat", cat = "AnimeOP" },
	{ id = 86329924920782, title = "Sakura Synth J-Pop Vibe", artist = "Love Sleep Repeat", cat = "AnimeOP" },
	{ id = 92888081813185, title = "J-Pop ／ 黒��夢", artist = "ColorArt", cat = "AnimeOP" },
	{ id = 80098020916214, title = "Modern J-Pop Fantasy � Colorful Anime Music", artist = "Love Sleep Repeat", cat = "AnimeOP" },
	{ id = 122411597749714, title = "J-Pop Star Mode � High Energy Japanese Pop Anthem", artist = "Love Sleep Repeat", cat = "AnimeOP" },
	{ id = 99236425251262, title = "Another Time (Retro J-Pop Vibe)", artist = "Love Sleep Repeat", cat = "AnimeOP" },
	{ id = 93493927021653, title = "気��������", artist = "Soul Man", cat = "AnimeOP" },
	{ id = 79243624217032, title = "影�������� (Rhythm of Shadows)", artist = "Soul Man", cat = "AnimeOP" },
	{ id = 103879408091743, title = "無限��流� , Infinite Flow", artist = "Munai", cat = "AnimeOP" },
	{ id = 91446777698251, title = "Anime Heart � J-Pop Style", artist = "Kira Mantle", cat = "AnimeOP" },
	{ id = 135511649698575, title = "Bounce with Me (J Pop)", artist = "GiggleBizzle", cat = "AnimeOP" },
	{ id = 99703196258432, title = "Aisle Seven (Irish Punk/J-Pop)", artist = "The Stray Keys", cat = "AnimeOP" },
	{ id = 118502713566997, title = "Retro Synth J-Pop", artist = "Love Sleep Repeat", cat = "AnimeOP" },
	{ id = 73767616542271, title = "Japanese Future Pop � Sweet Melodic J-Pop Track", artist = "Love Sleep Repeat", cat = "AnimeOP" },
	{ id = 105784238421495, title = "Several days", artist = "Moonie mitchell", cat = "AnimeOP" },
	{ id = 110579742357035, title = "日本語", artist = "Soul Man", cat = "AnimeOP" },
	{ id = 79015389050870, title = "Last Train Mascara (Irish Punk/J-Pop)", artist = "The Stray Keys", cat = "AnimeOP" },
	{ id = 118081426602664, title = "Anime Pop Groove � Fast & Happy J-Pop Sound", artist = "Love Sleep Repeat", cat = "AnimeOP" },
	{ id = 100982778466435, title = "Sleeping Alone Tonight", artist = "Cheyoung Ol", cat = "AnimeOP" },
	{ id = 110349334091971, title = "真夜中��風��触���", artist = "chill chill chill", cat = "AnimeOP" },
	{ id = 118676492721501, title = "Time", artist = "Moonie mitchell", cat = "AnimeOP" },
	{ id = 86298903697208, title = "At the Teahouse Door", artist = "Stillnote Studio", cat = "AnimeOP" },
	{ id = 125171172067754, title = "Kyoto, Again", artist = "Stillnote Studio", cat = "AnimeOP" },
	{ id = 72813658156573, title = "A Cup Replaced", artist = "Stillnote Studio", cat = "AnimeOP" },
	{ id = 130287890480157, title = "雨��������, After the Rain", artist = "Munai", cat = "AnimeOP" },
	{ id = 79778318323251, title = "残響��地平線 , Echoed Horizons", artist = "Munai", cat = "AnimeOP" },
	{ id = 95630372946434, title = "Pink Filter Memories", artist = "Song Socheata", cat = "AnimeOP" },
	{ id = 75337100123161, title = "夜��秘密 (Secrets of the Night)", artist = "Soul Man", cat = "AnimeOP" },
	{ id = 99075846742894, title = "An �I Miss You� Without a Voice", artist = "Cheyoung Ol", cat = "AnimeOP" },
	{ id = 70608074510265, title = "Fourth", artist = "Moonie mitchell", cat = "AnimeOP" },
	{ id = 76953389201887, title = "What if she was a K-pop idol singing J-Jazz", artist = "anytinh", cat = "AnimeOP" },
	{ id = 82554094671345, title = "君����������", artist = "Soul Man", cat = "AnimeOP" },
	{ id = 78412453526537, title = "Warm Can Coffee (Irish Punk/J-Pop)", artist = "The Stray Keys", cat = "AnimeOP" },
	{ id = 97110864321474, title = "Karma Club", artist = "Soul Man", cat = "AnimeOP" },
	{ id = 76137225232899, title = "Love That Didn�t Send", artist = "Song Socheata", cat = "AnimeOP" },
	{ id = 114393911222907, title = "Falling Slowly, Typing Fast", artist = "Song Socheata", cat = "AnimeOP" },
	{ id = 81742782678175, title = "A Love I Carried Alone to the End", artist = "Cheyoung Ol", cat = "AnimeOP" },
	{ id = 125511785437943, title = "After Goodbye", artist = "Stillnote Studio", cat = "AnimeOP" },
	{ id = 118649947112295, title = "生���������", artist = "Soul Man", cat = "AnimeOP" },
	{ id = 106002902103514, title = "The 4 AM Gospel (Irish Punk/J-Pop)", artist = "The Stray Keys", cat = "AnimeOP" },
	{ id = 85868272408940, title = "Beside the Kamogawa", artist = "Stillnote Studio", cat = "AnimeOP" },
	{ id = 78461494654579, title = "Progressive J-Pop Vibe", artist = "Love Sleep Repeat", cat = "AnimeOP" },
	{ id = 101676320640858, title = "Sugar Rush Confession", artist = "Song Socheata", cat = "AnimeOP" },
	{ id = 87766130537065, title = "The First Lesson of Love (J-POP)", artist = "BLUE HARBOR", cat = "AnimeOP" },
	{ id = 137521555727636, title = "Thinking of You on a Lonely Night", artist = "Cheyoung Ol", cat = "AnimeOP" },
	{ id = 70942962895477, title = "Bubble Pop Loneliness", artist = "Song Socheata", cat = "AnimeOP" },
	{ id = 132513820532327, title = "The Warmth He Left", artist = "Stillnote Studio", cat = "AnimeOP" },
	{ id = 127981194826960, title = "New Lovers", artist = "Soul Man", cat = "AnimeOP" },
	{ id = 137843092410112, title = "�死鳥��復活 , Phoenix Rising", artist = "Munai", cat = "AnimeOP" },
	{ id = 129426041361250, title = "Pastel Signal Delay", artist = "Song Socheata", cat = "AnimeOP" },
	{ id = 95676028373944, title = "Stardust Alarm Clock", artist = "Song Socheata", cat = "AnimeOP" },
	{ id = 112462208617673, title = "月��影 , Lunar Shadows", artist = "Munai", cat = "AnimeOP" },
	{ id = 108221454017263, title = "天��潮 , Celestial Tide", artist = "Munai", cat = "AnimeOP" },
	{ id = 127406491308478, title = "Blue Light Burnout (Irish Punk/J-Pop)", artist = "The Stray Keys", cat = "AnimeOP" },
	{ id = 138518012637379, title = "毒光 , Venomous Glow", artist = "Munai", cat = "AnimeOP" },
	{ id = 95339591244502, title = "原宿����������, Harajuku Runway", artist = "Munai", cat = "AnimeOP" },
	{ id = 125651911012472, title = "Moon Sugar Silence", artist = "Song Socheata", cat = "AnimeOP" },
	{ id = 78032830240500, title = "羨����", artist = "Soul Man", cat = "AnimeOP" },
	{ id = 108704788304673, title = "The Heart That Expected Too Much", artist = "Cheyoung Ol", cat = "AnimeOP" },
	{ id = 111196021378166, title = "Where Love Begins", artist = "Stillnote Studio", cat = "AnimeOP" },
	{ id = 71291681568621, title = "輝��花 , Radiant Bloom", artist = "Munai", cat = "AnimeOP" },
	{ id = 98737754639943, title = "The Hand He Offered", artist = "Stillnote Studio", cat = "AnimeOP" },
	{ id = 72374180504140, title = "Candy", artist = "Musikwelt", cat = "AnimeOP" },
	{ id = 107139454035250, title = "Too Late", artist = "Stillnote Studio", cat = "AnimeOP" },
	{ id = 138463093511578, title = "星明������旅 , Starlight Voyage", artist = "Munai", cat = "AnimeOP" },
	{ id = 121320095199148, title = "One Hand Apart", artist = "Stillnote Studio", cat = "AnimeOP" },
	{ id = 134120310493691, title = "Midnight Balcony Thoughts", artist = "Song Socheata", cat = "AnimeOP" },
	{ id = 87186797689587, title = "Glitch Kawaii! _ 8bit, chiptune, Jpop, and a girl", artist = "unbounder", cat = "AnimeOP" },
}

M.ById = {}
for i, s in ipairs(M.Songs) do s.index = i M.ById[s.id] = s end

return M
