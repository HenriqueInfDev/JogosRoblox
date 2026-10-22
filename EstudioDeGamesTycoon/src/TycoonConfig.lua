-- ============================================================
--  ESTÚDIO DE GAMES TYCOON - Configurações
--  Altere preços, valores e IDs de gamepass aqui.
-- ============================================================
local Config = {}

-- IDs dos Gamepasses (crie no site do Roblox e cole o número aqui; 0 = desativado)
Config.GAMEPASS_2X_ID = 0          -- "Dinheiro em Dobro"
Config.GAMEPASS_AUTOCOLLECT_ID = 0 -- "Coleta Automática"

Config.DATASTORE_NAME = "EstudioTycoon_v1"
Config.DROP_INTERVAL = 2      -- segundos entre cada cartucho produzido
Config.CONVEYOR_SPEED = 9     -- velocidade da esteira
Config.REBIRTH_BONUS = 0.5    -- +50% de renda por rebirth
Config.START_CASH = 0
Config.BASE_ITEMS = { "mesa1" } -- itens que todo estúdio já começa com

-- Tipos:
--  Dropper    = funcionário que produz jogos (cartuchos). Value = valor de cada cartucho
--  Multiplier = multiplica todo o dinheiro ganho (Mult)
--  Speed      = acelera a produção (SpeedMult < 1 = mais rápido)
--  Decor      = decoração
--  Expansion  = libera a segunda linha de produção
--  Trophy     = libera o Rebirth
Config.Items = {
	{ Id = "mesa1",       Name = "Mesa do Fundador",          Price = 0,      Type = "Dropper", Value = 5 },
	{ Id = "dev2",        Name = "Estagiário",                Price = 60,     Requires = "mesa1",      Type = "Dropper", Value = 10 },
	{ Id = "paredes",     Name = "Paredes do Escritório",     Price = 150,    Requires = "dev2",       Type = "Decor" },
	{ Id = "dev3",        Name = "Programador Júnior",        Price = 250,    Requires = "dev2",       Type = "Dropper", Value = 20 },
	{ Id = "cafe",        Name = "Máquina de Café",           Price = 400,    Requires = "dev3",       Type = "Speed", SpeedMult = 0.75 },
	{ Id = "dev4",        Name = "Artista 2D",                Price = 700,    Requires = "dev3",       Type = "Dropper", Value = 40 },
	{ Id = "placa",       Name = "Letreiro do Estúdio",       Price = 900,    Requires = "paredes",    Type = "Decor" },
	{ Id = "dev5",        Name = "Game Designer",             Price = 1500,   Requires = "dev4",       Type = "Dropper", Value = 75 },
	{ Id = "marketing",   Name = "Outdoor de Marketing",      Price = 2500,   Requires = "dev5",       Type = "Multiplier", Mult = 1.5 },
	{ Id = "expansao",    Name = "Expansão do Estúdio",       Price = 4000,   Requires = "dev5",       Type = "Expansion" },
	{ Id = "dev6",        Name = "Animador 3D",               Price = 5500,   Requires = "expansao",   Type = "Dropper", Value = 125 },
	{ Id = "sofa",        Name = "Sala de Descanso",          Price = 6000,   Requires = "expansao",   Type = "Speed", SpeedMult = 0.9 },
	{ Id = "dev7",        Name = "Engenheiro de Áudio",       Price = 9000,   Requires = "dev6",       Type = "Dropper", Value = 200 },
	{ Id = "servidores",  Name = "Servidores na Nuvem",       Price = 14000,  Requires = "dev7",       Type = "Multiplier", Mult = 1.5 },
	{ Id = "dev8",        Name = "Programador Sênior",        Price = 18000,  Requires = "dev7",       Type = "Dropper", Value = 325 },
	{ Id = "dev9",        Name = "Diretor de Arte",           Price = 28000,  Requires = "dev8",       Type = "Dropper", Value = 500 },
	{ Id = "publicadora", Name = "Contrato com Publicadora Global", Price = 40000, Requires = "dev9",  Type = "Multiplier", Mult = 2 },
	{ Id = "dev10",       Name = "Lenda dos Games",           Price = 60000,  Requires = "dev9",       Type = "Dropper", Value = 800 },
	{ Id = "trofeu",      Name = "Troféu Game of the Year",   Price = 150000, Requires = "dev10",      Type = "Trophy" },
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
