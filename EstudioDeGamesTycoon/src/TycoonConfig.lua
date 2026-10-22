-- ============================================================
--  ESTÚDIO DE GAMES TYCOON - Configurações
--  Altere preços, valores e IDs de gamepass aqui.
-- ============================================================
local Config = {}

-- IDs dos Gamepasses (crie no site do Roblox e cole o número aqui; 0 = desativado)
Config.GAMEPASS_2X_ID = 0          -- "Dinheiro em Dobro"
Config.GAMEPASS_AUTOCOLLECT_ID = 0 -- "Coleta Automática"
Config.GAMEPASS_VIP_ID = 0         -- "VIP" (área VIP, baú VIP, skins e pet exclusivos, +1 espaço de pet, tag)

-- ===== VIP =====
Config.VIP_CHEST_COOLDOWN = 600   -- baú VIP a cada 10 minutos
Config.VIP_CHEST_MINUTES = 5      -- o baú dá 5 minutos da renda atual...
Config.VIP_CHEST_MIN = 25000      -- ...com este mínimo (x (1 + rebirths))

-- ===== PETS =====
-- Os ovos custam dinheiro do jogo (não Robux). Preço = o maior entre MinPrice e X minutos de renda.
Config.EGG = { Name = "Ovo de Mascote", MinPrice = 2500, IncomeMinutes = 4 }
Config.PET_SLOTS = 3              -- pets equipados ao mesmo tempo (VIP ganha +1)
Config.PET_INVENTORY = 40         -- máximo de pets guardados
Config.RARITIES = {
	{ Id = "Comum",    Chance = 60, Color = Color3.fromRGB(189, 195, 199) },
	{ Id = "Raro",     Chance = 28, Color = Color3.fromRGB(52, 152, 219) },
	{ Id = "Épico",    Chance = 10, Color = Color3.fromRGB(155, 89, 182) },
	{ Id = "Lendário", Chance = 2,  Color = Color3.fromRGB(255, 200, 40) },
}
-- Bonus = renda extra (0.10 = +10%). Os bônus dos pets equipados somam.
Config.PETS = {
	{ Id = "cachorro",   Name = "Cachorro Pixel",     Rarity = "Comum",    Bonus = 0.10, Body = Color3.fromRGB(205, 133, 63),  Accent = Color3.fromRGB(120, 70, 30) },
	{ Id = "gato",       Name = "Gato Gamer",         Rarity = "Comum",    Bonus = 0.10, Body = Color3.fromRGB(130, 130, 140), Accent = Color3.fromRGB(60, 60, 70) },
	{ Id = "coelho",     Name = "Coelho Turbo",       Rarity = "Comum",    Bonus = 0.12, Body = Color3.fromRGB(245, 245, 245), Accent = Color3.fromRGB(255, 160, 190) },
	{ Id = "pinguim",    Name = "Pinguim Dev",        Rarity = "Raro",     Bonus = 0.25, Body = Color3.fromRGB(30, 30, 40),    Accent = Color3.fromRGB(255, 255, 255) },
	{ Id = "raposa",     Name = "Raposa Hacker",      Rarity = "Raro",     Bonus = 0.25, Body = Color3.fromRGB(230, 126, 34),  Accent = Color3.fromRGB(255, 255, 255) },
	{ Id = "panda",      Name = "Panda Streamer",     Rarity = "Raro",     Bonus = 0.30, Body = Color3.fromRGB(250, 250, 250), Accent = Color3.fromRGB(25, 25, 30) },
	{ Id = "robo",       Name = "Robô Assistente",    Rarity = "Épico",    Bonus = 0.50, Body = Color3.fromRGB(160, 170, 185), Accent = Color3.fromRGB(0, 230, 255), Glow = true },
	{ Id = "fantasma",   Name = "Fantasma do Bug",    Rarity = "Épico",    Bonus = 0.55, Body = Color3.fromRGB(220, 230, 255), Accent = Color3.fromRGB(120, 80, 255), Glow = true },
	{ Id = "unicornio",  Name = "Unicórnio Indie",    Rarity = "Lendário", Bonus = 1.00, Body = Color3.fromRGB(255, 220, 250), Accent = Color3.fromRGB(255, 80, 200), Glow = true, Sparkle = true },
	{ Id = "dragao",     Name = "Dragão do Código",   Rarity = "Lendário", Bonus = 1.20, Body = Color3.fromRGB(46, 204, 113),  Accent = Color3.fromRGB(255, 215, 0), Glow = true, Sparkle = true, Wings = true },
	{ Id = "dragao_vip", Name = "Dragão Dourado VIP", Rarity = "VIP",      Bonus = 0.80, Body = Color3.fromRGB(255, 200, 40),  Accent = Color3.fromRGB(255, 255, 255), Glow = true, Sparkle = true, Wings = true },
}
Config.PetById = {}
for _, pet in ipairs(Config.PETS) do
	Config.PetById[pet.Id] = pet
end
Config.RarityById = {}
for _, r in ipairs(Config.RARITIES) do
	Config.RarityById[r.Id] = r
end
Config.RarityById["VIP"] = { Id = "VIP", Chance = 0, Color = Color3.fromRGB(255, 215, 0) }

function Config.EggPrice(incomeRate: number, rebirths: number): number
	return math.floor(math.max(Config.EGG.MinPrice * (1 + rebirths), incomeRate * Config.EGG.IncomeMinutes * 60))
end

function Config.VipChestAmount(incomeRate: number, rebirths: number): number
	return math.floor(math.max(Config.VIP_CHEST_MIN * (1 + rebirths), incomeRate * Config.VIP_CHEST_MINUTES * 60))
end

function Config.SkinUnlocked(skin, rebirths: number, isVip: boolean): boolean
	if skin.Vip then
		return isVip
	end
	return rebirths >= (skin.Rebirths or 0)
end

-- ===== SKINS DO PRÉDIO (só visual) =====
-- Rebirths = quantos rebirths precisa para liberar; Vip = só para quem tem o passe VIP
Config.SKINS = {
	{ Id = "classico", Name = "Clássico",        Color = Color3.fromRGB(236, 240, 241), Material = Enum.Material.SmoothPlastic, Rebirths = 0 },
	{ Id = "tijolo",   Name = "Tijolinho",       Color = Color3.fromRGB(178, 80, 60),   Material = Enum.Material.Brick,         Rebirths = 1 },
	{ Id = "madeira",  Name = "Chalé de Madeira", Color = Color3.fromRGB(160, 110, 70),  Material = Enum.Material.WoodPlanks,    Rebirths = 2 },
	{ Id = "vidro",    Name = "Torre de Vidro",  Color = Color3.fromRGB(120, 190, 255), Material = Enum.Material.Glass,         Rebirths = 3, Transparency = 0.25 },
	{ Id = "marmore",  Name = "Mármore Real",    Color = Color3.fromRGB(245, 245, 245), Material = Enum.Material.Marble,        Rebirths = 5 },
	{ Id = "neon",     Name = "Neon Noturno",    Color = Color3.fromRGB(28, 26, 40),    Material = Enum.Material.SmoothPlastic, Vip = true, Trim = Color3.fromRGB(255, 60, 200) },
	{ Id = "ouro",     Name = "Ouro Puro",       Color = Color3.fromRGB(255, 200, 40),  Material = Enum.Material.Metal,         Vip = true },
	{ Id = "diamante", Name = "Diamante",        Color = Color3.fromRGB(150, 235, 255), Material = Enum.Material.Ice,           Vip = true },
}
Config.SkinById = {}
for _, skin in ipairs(Config.SKINS) do
	Config.SkinById[skin.Id] = skin
end

-- ===== RANKING GLOBAL =====
Config.LEADERBOARD_REFRESH = 90  -- segundos entre atualizações dos telões

-- Produtos de desenvolvedor (pacotes de dinheiro, podem ser comprados várias vezes; 0 = desativado)
-- Cada pacote dá X minutos da renda atual do jogador (com um mínimo), então vale a pena do começo ao fim.
Config.PRODUCTS = {
	{ Id = 0, Name = "Pacote Pequeno", Minutes = 10,  Min = 5000 },
	{ Id = 0, Name = "Pacote Médio",   Minutes = 60,  Min = 50000 },
	{ Id = 0, Name = "Pacote Grande",  Minutes = 360, Min = 500000 },
}

function Config.ProductAmount(product, incomeRate: number, rebirths: number): number
	return math.floor(math.max(product.Min * (1 + rebirths), incomeRate * product.Minutes * 60))
end

Config.DATASTORE_NAME = "EstudioTycoon_v1"
Config.DROP_INTERVAL = 2      -- segundos entre cada cartucho produzido
Config.CONVEYOR_SPEED = 9     -- velocidade da esteira
Config.REBIRTH_BONUS = 0.5    -- +50% de renda por rebirth
Config.START_CASH = 0
Config.DAILY_BASE = 500        -- recompensa diária: o maior entre DAILY_BASE x dia x (1 + rebirths) e 1 min de renda x dia (dia vai até 7)
Config.OFFLINE_MAX_HOURS = 8   -- máximo de horas de lucro offline
Config.OFFLINE_RATE = 0.5      -- o estúdio rende 50% enquanto o jogador está fora
Config.BASE_ITEMS = { "mesa1" } -- itens que todo estúdio já começa com

-- Cartucho dourado: chance de sair um jogo "sucesso" que vale muito mais
Config.GOLDEN_CHANCE = 0.04
Config.GOLDEN_MULT = 10

-- Evento HYPE (para o servidor todo): de tempos em tempos um jogo viraliza e tudo vale mais
Config.HYPE_INTERVAL = 240 -- segundos entre eventos
Config.HYPE_DURATION = 30
Config.HYPE_MULT = 2

-- Missões (em sequência). Stat: Earned = dinheiro ganho, Bought = melhorias compradas,
-- Golden = cartuchos dourados, Eggs = ovos chocados, Rebirths = rebirths feitos, Item = ter comprado o item (campo Item).
-- O prêmio é o maior entre Reward x (1 + rebirths) e 1 minuto da renda atual.
Config.MISSIONS = {
	{ Text = "Compre 2 melhorias",                Stat = "Bought",   Goal = 2,      Reward = 100 },
	{ Text = "Ganhe $1K com seus jogos",          Stat = "Earned",   Goal = 1000,   Reward = 300 },
	{ Text = "Venda 1 cartucho dourado",          Stat = "Golden",   Goal = 1,      Reward = 500 },
	{ Text = "Compre 6 melhorias",                Stat = "Bought",   Goal = 6,      Reward = 1500 },
	{ Text = "Ganhe $20K com seus jogos",         Stat = "Earned",   Goal = 20000,  Reward = 4000 },
	{ Text = "Venda 5 cartuchos dourados",        Stat = "Golden",   Goal = 5,      Reward = 8000 },
	{ Text = "Choque seu primeiro ovo de mascote", Stat = "Eggs",    Goal = 1,      Reward = 5000 },
	{ Text = "Compre 12 melhorias",               Stat = "Bought",   Goal = 12,     Reward = 20000 },
	{ Text = "Construa o 2º andar",               Stat = "Item",     Item = "andar2", Goal = 1, Reward = 100000 },
	{ Text = "Ganhe $5M com seus jogos",          Stat = "Earned",   Goal = 5e6,    Reward = 300000 },
	{ Text = "Venda 25 cartuchos dourados",       Stat = "Golden",   Goal = 25,     Reward = 600000 },
	{ Text = "Abra a Arena de eSports",           Stat = "Item",     Item = "esports", Goal = 1, Reward = 2e6 },
	{ Text = "Choque 15 ovos de mascote",         Stat = "Eggs",     Goal = 15,     Reward = 4e6 },
	{ Text = "Construa a Cobertura",              Stat = "Item",     Item = "andar3", Goal = 1, Reward = 8e6 },
	{ Text = "Ganhe $250M com seus jogos",        Stat = "Earned",   Goal = 250e6,  Reward = 25e6 },
	{ Text = "Compre o Heliponto",                Stat = "Item",     Item = "heliponto", Goal = 1, Reward = 60e6 },
	{ Text = "Ganhe o Troféu Game of the Year",   Stat = "Item",     Item = "trofeu", Goal = 1, Reward = 100e6 },
	{ Text = "Faça seu primeiro Rebirth",         Stat = "Rebirths", Goal = 1,      Reward = 10000 },
	{ Text = "Venda 100 cartuchos dourados",      Stat = "Golden",   Goal = 100,    Reward = 50000 },
	{ Text = "Chegue a 3 Rebirths",               Stat = "Rebirths", Goal = 3,      Reward = 200000 },
	{ Text = "Ganhe $10B com seus jogos",         Stat = "Earned",   Goal = 10e9,   Reward = 1e9 },
	{ Text = "Chegue a 5 Rebirths",               Stat = "Rebirths", Goal = 5,      Reward = 1e6 },
	{ Text = "Venda 500 cartuchos dourados",      Stat = "Golden",   Goal = 500,    Reward = 2e6 },
	{ Text = "Chegue a 10 Rebirths",              Stat = "Rebirths", Goal = 10,     Reward = 5e6 },
}

-- Visual do estúdio muda conforme os rebirths (cor do piso e do neon)
Config.REBIRTH_THEMES = {
	{ Name = "Garagem",   Floor = Color3.fromRGB(52, 58, 82),  Neon = Color3.fromRGB(155, 89, 182) },
	{ Name = "Bronze",    Floor = Color3.fromRGB(94, 64, 44),  Neon = Color3.fromRGB(230, 126, 34) },
	{ Name = "Prata",     Floor = Color3.fromRGB(90, 98, 112), Neon = Color3.fromRGB(189, 195, 199) },
	{ Name = "Ouro",      Floor = Color3.fromRGB(110, 86, 30), Neon = Color3.fromRGB(255, 215, 0) },
	{ Name = "Diamante",  Floor = Color3.fromRGB(30, 80, 110), Neon = Color3.fromRGB(0, 230, 255) },
	{ Name = "Lendário",  Floor = Color3.fromRGB(60, 20, 70),  Neon = Color3.fromRGB(255, 60, 200) },
}

-- Jogos "lançados" pelo estúdio (aparecem nos pôsteres da parede)
Config.POSTERS = { "CRAFTDEVIL", "PIZZA ESPACIAL", "ROBÔ RACER", "NINJA DO PIXEL" }

-- Sons (troque por IDs da Creator Store se quiser: "rbxassetid://123456")
Config.SOUNDS = {
	Buy = "rbxasset://sounds/electronicpingshort.wav",
	Collect = "rbxasset://sounds/electronicpingshort.wav",
	Error = "rbxasset://sounds/clickfast.wav",
}

-- Tipos:
--  Dropper    = funcionário que produz jogos (cartuchos). Value = valor de cada cartucho
--  Multiplier = multiplica todo o dinheiro ganho (Mult)
--  Speed      = acelera a produção (SpeedMult < 1 = mais rápido)
--  Decor      = decoração
--  Expansion  = libera uma nova linha de produção ou um novo andar
--  Trophy     = libera o Rebirth
-- Notice = mensagem extra mostrada quando o item é comprado
Config.Items = {
	-- ===== TÉRREO =====
	{ Id = "mesa1",       Name = "Mesa do Fundador",          Price = 0,      Type = "Dropper", Value = 5 },
	{ Id = "dev2",        Name = "Estagiário",                Price = 60,     Requires = "mesa1",      Type = "Dropper", Value = 10 },
	{ Id = "paredes",     Name = "Paredes do Escritório",     Price = 200,    Requires = "dev2",       Type = "Decor" },
	{ Id = "dev3",        Name = "Programador Júnior",        Price = 620,    Requires = "paredes",    Type = "Dropper", Value = 20 },
	{ Id = "cafe",        Name = "Máquina de Café",           Price = 1000,   Requires = "dev3",       Type = "Speed", SpeedMult = 0.75 },
	{ Id = "dev4",        Name = "Artista 2D",                Price = 1800,   Requires = "dev3",       Type = "Dropper", Value = 40 },
	{ Id = "placa",       Name = "Letreiro do Estúdio",       Price = 2200,   Requires = "paredes",    Type = "Decor" },
	{ Id = "dev5",        Name = "Game Designer",             Price = 3800,   Requires = "dev4",       Type = "Dropper", Value = 75 },
	{ Id = "marketing",   Name = "Outdoor de Marketing",      Price = 6200,   Requires = "dev5",       Type = "Multiplier", Mult = 1.5 },
	{ Id = "expansao",    Name = "Expansão do Estúdio",       Price = 10000,  Requires = "dev5",       Type = "Expansion", Notice = "🏗️ Nova linha de produção liberada!" },
	{ Id = "dev6",        Name = "Animador 3D",               Price = 14000,  Requires = "expansao",   Type = "Dropper", Value = 125 },
	{ Id = "sofa",        Name = "Sala de Descanso",          Price = 15000,  Requires = "expansao",   Type = "Speed", SpeedMult = 0.9 },
	{ Id = "dev7",        Name = "Engenheiro de Áudio",       Price = 22000,  Requires = "dev6",       Type = "Dropper", Value = 200 },
	{ Id = "servidores",  Name = "Servidores na Nuvem",       Price = 35000,  Requires = "dev7",       Type = "Multiplier", Mult = 1.5 },
	{ Id = "dev8",        Name = "Programador Sênior",        Price = 45000,  Requires = "dev7",       Type = "Dropper", Value = 325 },
	{ Id = "dev9",        Name = "Diretor de Arte",           Price = 70000,  Requires = "dev8",       Type = "Dropper", Value = 500 },
	{ Id = "publicadora", Name = "Contrato com Publicadora Global", Price = 100000, Requires = "dev9", Type = "Multiplier", Mult = 2 },
	{ Id = "dev10",       Name = "Lenda dos Games",           Price = 150000, Requires = "dev9",       Type = "Dropper", Value = 800 },
	{ Id = "andar2",      Name = "Construir 2º Andar",        Price = 750000, Requires = "dev10",      Type = "Expansion",
		Notice = "🏢 2º andar construído! Suba pela escada no fundo do estúdio." },
	-- ===== 2º ANDAR =====
	{ Id = "linha3",      Name = "Linha de Produção 3",       Price = 1.4e6,  Requires = "andar2",     Type = "Expansion", Notice = "🏗️ Terceira linha de produção liberada!" },
	{ Id = "dev11",       Name = "Dev de Realidade Virtual",  Price = 1.8e6,  Requires = "linha3",     Type = "Dropper", Value = 1300 },
	{ Id = "testes",      Name = "Sala de Testes (QA)",       Price = 2.4e6,  Requires = "linha3",     Type = "Speed", SpeedMult = 0.85 },
	{ Id = "dev12",       Name = "Especialista em IA",        Price = 3e6,    Requires = "dev11",      Type = "Dropper", Value = 2000 },
	{ Id = "streaming",   Name = "Estúdio de Streaming",      Price = 4.2e6,  Requires = "dev12",      Type = "Multiplier", Mult = 1.5 },
	{ Id = "dev13",       Name = "Roteirista",                Price = 5.7e6,  Requires = "dev12",      Type = "Dropper", Value = 3200 },
	{ Id = "arcade",      Name = "Fliperamas Retrô",          Price = 7.5e6,  Requires = "testes",     Type = "Multiplier", Mult = 1.25 },
	{ Id = "dev14",       Name = "Produtor Executivo",        Price = 12e6,   Requires = "dev13",      Type = "Dropper", Value = 5000 },
	{ Id = "esports",     Name = "Arena de eSports",          Price = 21e6,   Requires = "dev14",      Type = "Multiplier", Mult = 2 },
	{ Id = "dev15",       Name = "Gênio dos Games",           Price = 30e6,   Requires = "dev14",      Type = "Dropper", Value = 8000 },
	{ Id = "andar3",      Name = "Construir Cobertura",       Price = 60e6,   Requires = "dev15",      Type = "Expansion",
		Notice = "🌆 Cobertura construída! Suba pela escada na frente do 2º andar." },
	-- ===== COBERTURA =====
	{ Id = "dev16",       Name = "Diretor Criativo",          Price = 98e6,   Requires = "andar3",     Type = "Dropper", Value = 13000 },
	{ Id = "sala_ceo",    Name = "Sala do CEO",               Price = 140e6,  Requires = "andar3",     Type = "Multiplier", Mult = 1.5 },
	{ Id = "dev17",       Name = "Vice-Presidente",           Price = 210e6,  Requires = "dev16",      Type = "Dropper", Value = 20000 },
	{ Id = "terraco",     Name = "Terraço com Piscina",       Price = 300e6,  Requires = "andar3",     Type = "Speed", SpeedMult = 0.9 },
	{ Id = "dev18",       Name = "CEO Visionário",            Price = 420e6,  Requires = "dev17",      Type = "Dropper", Value = 32000 },
	{ Id = "heliponto",   Name = "Heliponto + Helicóptero",   Price = 630e6,  Requires = "sala_ceo",   Type = "Multiplier", Mult = 2 },
	{ Id = "trofeu",      Name = "Troféu Game of the Year",   Price = 1e9,    Requires = "dev18",      Type = "Trophy" },
}

Config.ById = {}
for i, item in ipairs(Config.Items) do
	item.Order = i
	Config.ById[item.Id] = item
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }

function Config.Format(n: number): string
	n = math.floor(n or 0)
	local value = n
	local i = 1
	while math.abs(value) >= 1000 and i < #SUFFIXES do
		value = value / 1000
		i += 1
	end
	if i == 1 then
		return "$" .. tostring(n)
	end
	return string.format("$%.1f%s", value, SUFFIXES[i])
end

return Config
