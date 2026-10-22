-- ============================================================
--  ESTÚDIO DE GAMES TYCOON - Servidor
--  Rift Studius
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("TycoonConfig"))
local Format = Config.Format

-- ---------- Remotes ----------
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local notifyEvent = Instance.new("RemoteEvent")
notifyEvent.Name = "Notify"
notifyEvent.Parent = remotes

local soldEvent = Instance.new("RemoteEvent")
soldEvent.Name = "Sold"
soldEvent.Parent = remotes

local rebirthFunc = Instance.new("RemoteFunction")
rebirthFunc.Name = "Rebirth"
rebirthFunc.Parent = remotes

local petFunc = Instance.new("RemoteFunction")
petFunc.Name = "PetAction"
petFunc.Parent = remotes

local skinFunc = Instance.new("RemoteFunction")
skinFunc.Name = "SetSkin"
skinFunc.Parent = remotes

local hatchEvent = Instance.new("RemoteEvent")
hatchEvent.Name = "Hatch"
hatchEvent.Parent = remotes

local HttpService = game:GetService("HttpService")

do
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 14.5
	lighting.Ambient = Color3.fromRGB(95, 95, 110)
	lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 150)
	lighting.Brightness = 2.2
end

local dropsFolder = Instance.new("Folder")
dropsFolder.Name = "Cartuchos"
dropsFolder.Parent = workspace

-- ---------- DataStore ----------
local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DATASTORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[Tycoon] DataStore indisponível (ative 'Enable Studio Access to API Services' para testar no Studio):", result)
	end
end

local playerData = {} -- [player] = dados salvos + Loaded
local playerPlot = {} -- [player] = state
local lastNotify = {} -- [player] = os.clock()

local function notify(player: Player, text: string, kind: string?)
	if kind == "erro" then
		local now = os.clock()
		if lastNotify[player] and now - lastNotify[player] < 1.5 then
			return
		end
		lastNotify[player] = now
	end
	notifyEvent:FireClient(player, text, kind or "info")
end

local function notifyAll(text: string, kind: string?)
	notifyEvent:FireAllClients(text, kind or "info")
end

-- ---------- Helpers de UI no mundo ----------
local function makeBillboard(parent: Instance, offsetY: number, width: number, height: number, maxDist: number?)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(width, height)
	bb.StudsOffset = Vector3.new(0, offsetY, 0)
	bb.MaxDistance = maxDist or 80
	bb.LightInfluence = 0
	bb.Parent = parent
	return bb
end

local function makeLabel(parent: Instance, text: string, color: Color3, sizeY: number, posY: number, font: Enum.Font?)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, sizeY, 0)
	label.Position = UDim2.new(0, 0, posY, 0)
	label.Font = font or Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = parent
	return label
end

local function makeSurface(part: BasePart, face: Enum.NormalId, pps: number)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = pps
	sg.LightInfluence = 0
	sg.Parent = part
	return sg
end

local function addLight(part: BasePart, color: Color3, range: number, brightness: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Parent = part
	return light
end

local function burst(position: Vector3, color: Color3, amount: number)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanTouch = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.Position = position
	holder.Parent = workspace
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.LightEmission = 0.7
	e.Size = NumberSequence.new(0.8, 0)
	e.Speed = NumberRange.new(14, 24)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Lifetime = NumberRange.new(0.6, 1.1)
	e.Acceleration = Vector3.new(0, -30, 0)
	e.Rate = 0
	e.Parent = holder
	e:Emit(amount)
	Debris:AddItem(holder, 2)
end

-- ---------- Dinheiro ----------
local function getCash(player: Player): number
	local ls = player:FindFirstChild("leaderstats")
	local cash = ls and ls:FindFirstChild("Dinheiro")
	return cash and cash.Value or 0
end

local function setCash(player: Player, amount: number)
	local ls = player:FindFirstChild("leaderstats")
	local cash = ls and ls:FindFirstChild("Dinheiro")
	if cash then
		cash.Value = math.max(0, math.floor(amount))
	end
end

local function addCash(player: Player, amount: number)
	setCash(player, getCash(player) + amount)
end

-- ---------- Missões ----------
local function getStat(player: Player, mission): number
	local stat = mission.Stat
	if stat == "Rebirths" then
		return player:GetAttribute("Rebirths") or 0
	elseif stat == "Item" then
		local state = playerPlot[player]
		return (state and state.Owned[mission.Item]) and 1 or 0
	end
	local data = playerData[player]
	return data and data.Stats[stat] or 0
end

local function missionReward(player: Player, mission): number
	local rebirths = player:GetAttribute("Rebirths") or 0
	local rate = player:GetAttribute("IncomeRate") or 0
	return math.floor(math.max(mission.Reward * (1 + rebirths), rate * 60))
end

local function updateMissionAttributes(player: Player)
	local data = playerData[player]
	if not data then
		return
	end
	local mission = Config.MISSIONS[data.Mission]
	if mission then
		player:SetAttribute("MissionText", mission.Text)
		player:SetAttribute("MissionValue", math.min(getStat(player, mission), mission.Goal))
		player:SetAttribute("MissionGoal", mission.Goal)
		player:SetAttribute("MissionReward", missionReward(player, mission))
		player:SetAttribute("MissionIndex", data.Mission)
	else
		player:SetAttribute("MissionText", "")
	end
end

local function checkMissions(player: Player)
	local data = playerData[player]
	if not data then
		return
	end
	while true do
		local mission = Config.MISSIONS[data.Mission]
		if not mission or getStat(player, mission) < mission.Goal then
			break
		end
		local reward = missionReward(player, mission)
		addCash(player, reward)
		data.Mission += 1
		notify(player, "📋 Missão completa: " .. mission.Text .. "  •  +" .. Format(reward), "ok")
	end
	updateMissionAttributes(player)
end

local missionDirty = {}
local function addStat(player: Player, stat: string, amount: number)
	local data = playerData[player]
	if not data then
		return
	end
	data.Stats[stat] = (data.Stats[stat] or 0) + amount
	missionDirty[player] = true
end

-- atualiza missões no máximo 4x por segundo (cartuchos chegam o tempo todo)
task.spawn(function()
	while true do
		task.wait(0.25)
		for player in pairs(missionDirty) do
			missionDirty[player] = nil
			if player.Parent then
				checkMissions(player)
			end
		end
	end
end)

-- ---------- Evento HYPE ----------
local function isHype(): boolean
	return workspace:GetServerTimeNow() < (workspace:GetAttribute("HypeUntil") or 0)
end

task.spawn(function()
	while true do
		task.wait(Config.HYPE_INTERVAL)
		workspace:SetAttribute("HypeUntil", workspace:GetServerTimeNow() + Config.HYPE_DURATION)
		notifyAll("🔥 HYPE! Um jogo viralizou: tudo vale " .. Config.HYPE_MULT .. "x por " .. Config.HYPE_DURATION .. " segundos!", "ok")
	end
end)

-- ---------- Estado dos estúdios ----------
local plots = {}

local function getMultiplier(state): number
	local m = 1
	for id in pairs(state.Owned) do
		local item = Config.ById[id]
		if item and item.Mult then
			m *= item.Mult
		end
	end
	local player = state.Owner
	if player then
		m *= 1 + Config.REBIRTH_BONUS * (player:GetAttribute("Rebirths") or 0)
		m *= 1 + (player:GetAttribute("PetBonus") or 0)
		if player:GetAttribute("Has2x") then
			m *= 2
		end
	end
	return m
end

local function getSpeedFactor(state): number
	local f = 1
	for id in pairs(state.Owned) do
		local item = Config.ById[id]
		if item and item.SpeedMult then
			f *= item.SpeedMult
		end
	end
	return f
end

local function getIncomeRate(state): number
	local perDrop = 0
	for id in pairs(state.Owned) do
		local item = Config.ById[id]
		if item and item.Type == "Dropper" then
			perDrop += item.Value
		end
	end
	local goldenBonus = 1 + Config.GOLDEN_CHANCE * (Config.GOLDEN_MULT - 1)
	return perDrop / (Config.DROP_INTERVAL * getSpeedFactor(state)) * getMultiplier(state) * goldenBonus
end

local function applyTheme(state)
	local rebirths = state.Owner and (state.Owner:GetAttribute("Rebirths") or 0) or 0
	local theme = Config.REBIRTH_THEMES[math.min(rebirths + 1, #Config.REBIRTH_THEMES)]
	for _, part in ipairs(state.ThemeFloor) do
		part.Color = theme.Floor
	end
	for _, part in ipairs(state.ThemeNeon) do
		part.Color = theme.Neon
	end
	if state.Owner then
		state.Owner:SetAttribute("ThemeName", theme.Name)
	end
end

local function updateBank(state)
	if state.CollectLabel then
		state.CollectLabel.Text = Format(state.Bank)
	end
	if state.Owner then
		state.Owner:SetAttribute("Bank", state.Bank)
	end
end

local function updateDoor(state)
	if state.Owner then
		state.DoorTitle.Text = "Estúdio de " .. state.Owner.DisplayName
		state.DoorSub.Text = "🎮 Rift Studius"
		state.Door.Color = Color3.fromRGB(155, 89, 182)
		state.Door:SetAttribute("Owner", state.Owner.Name)
	else
		state.DoorTitle.Text = "🎮 Estúdio Livre"
		state.DoorSub.Text = "Toque na porta para ser o dono!"
		state.Door.Color = Color3.fromRGB(0, 200, 255)
		state.Door:SetAttribute("Owner", "")
	end
	if state.SignLabel then
		state.SignLabel.Text = state.Owner and ("ESTÚDIO " .. string.upper(state.Owner.DisplayName)) or "ESTÚDIO"
	end
end

local function refreshButtons(state)
	local cash = state.Owner and getCash(state.Owner) or 0
	local goal = nil
	for id, btn in pairs(state.Buttons) do
		local item = Config.ById[id]
		local visible = state.Owner ~= nil
			and not state.Owned[id]
			and (item.Requires == nil or state.Owned[item.Requires] == true)
		if visible then
			btn.Parent = state.Model.Buttons
			local canBuy = cash >= item.Price
			btn.Color = canBuy and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
			local price = btn:FindFirstChild("PriceLabel", true)
			if price then
				price.TextColor3 = canBuy and Color3.fromRGB(120, 255, 140) or Color3.fromRGB(255, 120, 110)
			end
			if not goal or item.Price < goal.Price then
				goal = item
			end
		else
			btn.Parent = state.Storage
		end
	end
	local owner = state.Owner
	if owner then
		owner:SetAttribute("NextGoal", goal and goal.Name or "")
		owner:SetAttribute("NextGoalId", goal and goal.Id or "")
		owner:SetAttribute("NextPrice", goal and goal.Price or 0)
		owner:SetAttribute("IncomeRate", math.floor(getIncomeRate(state)))
		owner:SetAttribute("Multiplier", getMultiplier(state))
		owner:SetAttribute("CanRebirth", state.Owned["trofeu"] == true)
	end
end

local function setConveyorVelocity(model: Instance)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Esteira" then
			d.AssemblyLinearVelocity = -d.CFrame.RightVector * Config.CONVEYOR_SPEED
		end
	end
end

local function clearDrops(state)
	for _, drop in ipairs(dropsFolder:GetChildren()) do
		if drop:GetAttribute("Plot") == state.Model.Name then
			drop:Destroy()
		end
	end
end

-- Animação de "construção": as peças caem do céu com um quique
local function animateBuild(model: Instance)
	local parts = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	for i, p in ipairs(parts) do
		local target = p:GetAttribute("BuildCFrame") or p.CFrame
		p:SetAttribute("BuildCFrame", target)
		p.CFrame = target + Vector3.new(0, 10, 0)
		local info = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, math.min(i * 0.015, 0.7))
		TweenService:Create(p, info, { CFrame = target }):Play()
	end
	task.delay(1.4, function()
		setConveyorVelocity(model)
	end)
end

local function ownItem(state, id: string, animate: boolean?)
	state.Owned[id] = true
	local model = state.ItemModels[id]
	if model then
		model.Parent = state.Model.Items
		setConveyorVelocity(model)
		if animate then
			animateBuild(model)
		end
	end
end

local function hideAllItems(state)
	for _, model in pairs(state.ItemModels) do
		model.Parent = state.Storage
	end
	state.Owned = {}
	state.Timers = {}
end

-- ---------- Skins do prédio ----------
local SKIN_PARTS = {
	ParedeEsq = true, ParedeDir = true, ParedeFundo = true, FrenteEsq = true, FrenteDir = true, SobrePorta = true,
	ParedeEsq2 = true, ParedeDir2 = true, ParedeFundo2 = true, Frente2 = true,
	Telhado = true, SobrePortaCob = true,
}

local function isSkinPart(name: string): boolean
	return SKIN_PARTS[name] == true
end

local function applySkin(state)
	local data = state.Owner and playerData[state.Owner]
	local skin = Config.SkinById[data and data.Skin or "classico"] or Config.SkinById["classico"]
	for _, part in ipairs(state.SkinParts) do
		part.Color = skin.Color
		part.Material = skin.Material
		part.Transparency = skin.Transparency or 0
	end
	if skin.Trim then
		for _, part in ipairs(state.ThemeNeon) do
			part.Color = skin.Trim
		end
	end
end

-- ---------- Compra ----------
local function tryBuy(state, player: Player, id: string)
	local item = Config.ById[id]
	if not item or state.Owner ~= player or state.Owned[id] then
		return
	end
	if item.Requires and not state.Owned[item.Requires] then
		return
	end
	local cash = getCash(player)
	if cash < item.Price then
		notify(player, "Faltam " .. Format(item.Price - cash) .. " para: " .. item.Name, "erro")
		return
	end
	local btn = state.Buttons[id]
	setCash(player, cash - item.Price)
	ownItem(state, id, true)
	if btn then
		burst(btn.Position + Vector3.new(0, 2, 0), Color3.fromRGB(255, 215, 0), 40)
	end
	refreshButtons(state)
	addStat(player, "Bought", 1)
	notify(player, "✅ Comprado: " .. item.Name, "compra")
	if item.Notice then
		notify(player, item.Notice, "ok")
	end
	if item.Type == "Trophy" then
		notify(player, "🏆 Você ganhou o Game of the Year! Agora pode fazer REBIRTH.", "ok")
		notifyAll("🏆 " .. player.DisplayName .. " ganhou o Game of the Year!", "info")
	elseif item.Type == "Multiplier" then
		notify(player, "📈 Renda multiplicada por " .. tostring(item.Mult) .. "x!", "ok")
	elseif item.Type == "Speed" then
		notify(player, "⚡ Sua equipe agora produz mais rápido!", "ok")
	end
end

-- ---------- Produção (cartuchos) ----------
local function spawnDrop(state, head: BasePart, value: number)
	local golden = math.random() < Config.GOLDEN_CHANCE
	local drop = Instance.new("Part")
	drop.Name = "Cartucho"
	drop.Size = golden and Vector3.new(1.5, 0.6, 2) or Vector3.new(1.2, 0.5, 1.6)
	drop.Color = golden and Color3.fromRGB(255, 200, 40) or head.Color
	drop.Material = golden and Enum.Material.Neon or Enum.Material.SmoothPlastic
	drop.TopSurface = Enum.SurfaceType.Smooth
	drop.BottomSurface = Enum.SurfaceType.Smooth
	drop.CFrame = CFrame.new(head.Position - Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, math.rad(math.random(-20, 20)), 0)
	drop:SetAttribute("Value", golden and value * Config.GOLDEN_MULT or value)
	drop:SetAttribute("Golden", golden)
	drop:SetAttribute("Plot", state.Model.Name)

	local label = Instance.new("Part")
	label.Name = "Etiqueta"
	label.Size = Vector3.new(drop.Size.X * 0.75, 0.1, drop.Size.Z * 0.45)
	label.Color = golden and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(240, 240, 240)
	label.Material = Enum.Material.SmoothPlastic
	label.CanCollide = false
	label.CanTouch = false
	label.Massless = true
	label.CFrame = drop.CFrame * CFrame.new(0, drop.Size.Y / 2 + 0.03, -drop.Size.Z * 0.12)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = drop
	weld.Part1 = label
	weld.Parent = drop
	label.Parent = drop

	if golden then
		local sparkle = Instance.new("Sparkles")
		sparkle.SparkleColor = Color3.fromRGB(255, 230, 120)
		sparkle.Parent = drop
		addLight(drop, Color3.fromRGB(255, 210, 80), 8, 2)
	end

	drop.Parent = dropsFolder
	pcall(function()
		drop:SetNetworkOwner(nil)
	end)
	Debris:AddItem(drop, 30)
end

local function onCollectorTouched(state, collector: BasePart, hit: BasePart)
	if hit.Name ~= "Cartucho" or hit:GetAttribute("Plot") ~= state.Model.Name or hit:GetAttribute("Done") then
		return
	end
	hit:SetAttribute("Done", true)
	local value = hit:GetAttribute("Value") or 0
	local golden = hit:GetAttribute("Golden") == true
	hit:Destroy()
	local owner = state.Owner
	if not owner then
		return
	end
	local amount = math.floor(value * getMultiplier(state) * (isHype() and Config.HYPE_MULT or 1))
	if owner:GetAttribute("AutoCollect") then
		addCash(owner, amount)
	else
		state.Bank += amount
		updateBank(state)
	end
	addStat(owner, "Earned", amount)
	if golden then
		addStat(owner, "Golden", 1)
	end
	soldEvent:FireClient(owner, collector.Position + Vector3.new(0, 4, 0), amount, golden)
	-- brilho na publicadora
	local light = collector:FindFirstChildOfClass("PointLight")
	if light then
		light.Brightness = golden and 8 or 4
		task.delay(0.15, function()
			light.Brightness = 1
		end)
	end
end

-- ---------- Assumir / liberar estúdio ----------
local function teleportToPlot(player: Player, state)
	local char = player.Character
	if char and state then
		char:PivotTo(state.Door.CFrame * CFrame.new(0, 0, 8) * CFrame.Angles(0, math.pi, 0))
	end
end

local function claim(state, player: Player)
	if state.Owner or playerPlot[player] then
		return
	end
	local data = playerData[player]
	if not data then
		return
	end
	state.Owner = player
	playerPlot[player] = state
	player:SetAttribute("PlotName", state.Model.Name)

	hideAllItems(state)
	for _, id in ipairs(Config.BASE_ITEMS) do
		ownItem(state, id)
	end
	for _, id in ipairs(data.Owned or {}) do
		if Config.ById[id] then
			ownItem(state, id)
		end
	end
	state.Bank = data.Bank or 0
	data.Bank = 0
	applyTheme(state)
	applySkin(state)
	updateBank(state)
	updateDoor(state)
	refreshButtons(state)
	burst(state.Door.Position + Vector3.new(0, 3, 0), Color3.fromRGB(155, 89, 182), 60)
	notify(player, "🎉 Bem-vindo ao seu estúdio de games!", "ok")
	if #(data.Owned or {}) == 0 then
		notify(player, "Pise nos botões verdes para contratar. Colete o dinheiro no tapete verde.", "info")
	end
end

local function release(state)
	if state.Owner then
		playerPlot[state.Owner] = nil
	end
	state.Owner = nil
	state.Bank = 0
	hideAllItems(state)
	clearDrops(state)
	applyTheme(state)
	applySkin(state)
	updateBank(state)
	updateDoor(state)
	refreshButtons(state)
end

-- ---------- Montagem dos estúdios ----------
local hatchEgg -- definida mais abaixo (seção de pets)
local SIGNS = {
	PlacaQA = "🎮 SALA DE TESTES",
	AoVivo = "🔴 AO VIVO",
	PlacaArcade = "👾 FLIPERAMA RETRÔ",
	TelaArena = "🏆 GRANDE FINAL",
	PlacaAndar = "2º ANDAR",
	QuadroCEO = "⭐ CEO ⭐",
}

local function setupPlot(model: Model)
	local base = model:WaitForChild("Base")
	local state = {
		Model = model,
		Owner = nil,
		Owned = {},
		Bank = 0,
		Timers = {},
		Buttons = {},
		ItemModels = {},
		ThemeFloor = {},
		ThemeNeon = {},
		SkinParts = {},
		Storage = Instance.new("Folder"),
	}
	state.Storage.Name = "Armazem_" .. model.Name
	state.Storage.Parent = ServerStorage

	-- Porta
	state.Door = base:WaitForChild("Porta")
	local doorBB = makeBillboard(state.Door, 7, 320, 90, 120)
	state.DoorTitle = makeLabel(doorBB, "", Color3.new(1, 1, 1), 0.6, 0)
	state.DoorSub = makeLabel(doorBB, "", Color3.fromRGB(255, 230, 120), 0.4, 0.6, Enum.Font.GothamBold)
	state.Door.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			claim(state, player)
		end
	end)

	-- Tapete de coleta
	local pad = base:WaitForChild("Coletar")
	local padBB = makeBillboard(pad, 4, 200, 80, 70)
	makeLabel(padBB, "💰 COLETAR", Color3.new(1, 1, 1), 0.45, 0)
	state.CollectLabel = makeLabel(padBB, "$0", Color3.fromRGB(120, 255, 140), 0.55, 0.45)
	addLight(pad, Color3.fromRGB(46, 204, 113), 12, 1.5)
	local padDebounce = false
	pad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or player ~= state.Owner or padDebounce or state.Bank <= 0 then
			return
		end
		padDebounce = true
		local amount = state.Bank
		state.Bank = 0
		addCash(player, amount)
		updateBank(state)
		burst(pad.Position + Vector3.new(0, 1, 0), Color3.fromRGB(110, 255, 140), 30)
		notify(player, "+" .. Format(amount), "coleta")
		task.wait(0.5)
		padDebounce = false
	end)

	-- Publicadoras, esteiras, letreiros, pôsteres, luzes e nomes
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local name = d.Name
			if isSkinPart(name) then
				table.insert(state.SkinParts, d)
			end
			if name == "Publicadora" then
				addLight(d, Color3.fromRGB(80, 160, 255), 14, 1)
				local bb = makeBillboard(d, 6, 200, 50, 90)
				makeLabel(bb, "📦 PUBLICADORA", Color3.fromRGB(150, 210, 255), 1, 0)
				d.Touched:Connect(function(hit)
					onCollectorTouched(state, d, hit)
				end)
			elseif name == "Piso" then
				table.insert(state.ThemeFloor, d)
			elseif name == "FaixaCorredor" or name == "FaixaNeon" or name == "Borda" then
				table.insert(state.ThemeNeon, d)
			elseif name == "Letreiro" then
				state.SignLabel = makeLabel(makeSurface(d, Enum.NormalId.Front, 40), "ESTÚDIO", Color3.new(1, 1, 1), 1, 0)
			elseif name == "Outdoor" then
				local sg = makeSurface(d, Enum.NormalId.Front, 30)
				makeLabel(sg, "🎮 NOVO JOGO", Color3.fromRGB(255, 220, 60), 0.55, 0.05)
				makeLabel(sg, "JÁ DISPONÍVEL!", Color3.new(1, 1, 1), 0.35, 0.6)
			elseif string.sub(name, 1, 6) == "Poster" and tonumber(string.sub(name, 7)) then
				local title = Config.POSTERS[tonumber(string.sub(name, 7))] or "NOVO JOGO"
				local sg = makeSurface(d, Enum.NormalId.Front, 40)
				makeLabel(sg, title, Color3.new(1, 1, 1), 0.5, 0.12)
				makeLabel(sg, "★★★★★", Color3.fromRGB(255, 215, 0), 0.3, 0.62)
			elseif SIGNS[name] then
				for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
					local sg = makeSurface(d, face, 30)
					makeLabel(sg, SIGNS[name], Color3.new(1, 1, 1), 0.8, 0.1)
				end
			elseif name == "LuzTeto" then
				local light = addLight(d, Color3.fromRGB(255, 244, 225), 22, 0.9)
				light.Shadows = false
				local surface = Instance.new("SurfaceLight")
				surface.Face = Enum.NormalId.Bottom
				surface.Range = 14
				surface.Brightness = 0.6
				surface.Angle = 120
				surface.Parent = d
			elseif name == "Incubadora" then
				local prompt = Instance.new("ProximityPrompt")
				prompt.ObjectText = Config.EGG.Name
				prompt.ActionText = "Chocar ovo"
				prompt.HoldDuration = 0.4
				prompt.MaxActivationDistance = 12
				prompt.RequiresLineOfSight = false
				prompt.Parent = d
				prompt.Triggered:Connect(function(player)
					hatchEgg(player)
				end)
				local bb = makeBillboard(d, 7.5, 260, 90, 50)
				makeLabel(bb, "🥚 OVO DE MASCOTE", Color3.fromRGB(255, 230, 150), 0.4, 0)
				local odds = {}
				for _, r in ipairs(Config.RARITIES) do
					table.insert(odds, r.Id .. " " .. r.Chance .. "%")
				end
				makeLabel(bb, table.concat(odds, " • "), Color3.new(1, 1, 1), 0.3, 0.42, Enum.Font.GothamBold)
				makeLabel(bb, "Pets dão bônus de renda!", Color3.fromRGB(120, 255, 140), 0.25, 0.74, Enum.Font.GothamBold)
			elseif name == "LuzLuminaria" then
				addLight(d, Color3.fromRGB(255, 236, 200), 18, 0.8)
			elseif name == "Dropper" then
				local item = Config.ById[d.Parent.Name]
				if item then
					local bb = makeBillboard(d, 2.6, 180, 40, 55)
					makeLabel(bb, item.Name, Color3.new(1, 1, 1), 1, 0, Enum.Font.GothamBold)
				end
			elseif name == "Copa" then
				local bb = makeBillboard(d, 3.5, 240, 50, 80)
				makeLabel(bb, "🏆 GAME OF THE YEAR", Color3.fromRGB(255, 215, 0), 1, 0)
				addLight(d, Color3.fromRGB(255, 215, 0), 14, 2)
			end
		end
	end
	setConveyorVelocity(model)

	-- Itens (guardados até serem comprados)
	for _, item in ipairs(model:WaitForChild("Items"):GetChildren()) do
		state.ItemModels[item.Name] = item
		item.Parent = state.Storage
	end

	-- Botões
	for _, btn in ipairs(model:WaitForChild("Buttons"):GetChildren()) do
		local item = Config.ById[btn.Name]
		if not item then
			warn("[Tycoon] Botão sem item na config:", btn.Name)
			continue
		end
		state.Buttons[btn.Name] = btn
		local bb = makeBillboard(btn, 3, 220, 70, 60)
		makeLabel(bb, item.Name, Color3.new(1, 1, 1), 0.55, 0)
		local priceLabel = makeLabel(bb, Format(item.Price), Color3.fromRGB(120, 255, 140), 0.45, 0.55)
		priceLabel.Name = "PriceLabel"
		btn.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				tryBuy(state, player, btn.Name)
			end
		end)
		btn.Parent = state.Storage
	end

	applyTheme(state)
	updateBank(state)
	updateDoor(state)
	table.insert(plots, state)
end

-- Praça central
do
	local lobby = workspace:FindFirstChild("Lobby")
	if lobby then
		for _, d in ipairs(lobby:GetDescendants()) do
			if d:IsA("BasePart") then
				if d.Name == "PlacaLobby" then
					for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
						local sg = makeSurface(d, face, 30)
						makeLabel(sg, "🎮 ESTÚDIO DE GAMES", Color3.fromRGB(255, 210, 63), 0.55, 0.05)
						makeLabel(sg, "TYCOON", Color3.fromRGB(93, 255, 138), 0.4, 0.58)
					end
				elseif d.Name == "LuzPoste" then
					addLight(d, Color3.fromRGB(255, 236, 200), 20, 0.7)
				end
			end
		end
	end
end

for _, model in ipairs(workspace:WaitForChild("Tycoons"):GetChildren()) do
	if model:IsA("Model") then
		setupPlot(model)
	end
end

-- Loop de produção
RunService.Heartbeat:Connect(function(dt)
	for _, state in ipairs(plots) do
		if state.Owner then
			local interval = Config.DROP_INTERVAL * getSpeedFactor(state)
			for id in pairs(state.Owned) do
				local item = Config.ById[id]
				if item and item.Type == "Dropper" then
					local t = (state.Timers[id] or 0) + dt
					if t >= interval then
						t = 0
						local model = state.ItemModels[id]
						local head = model and model:FindFirstChild("Dropper")
						if head and model.Parent == state.Model.Items then
							spawnDrop(state, head, item.Value)
						end
					end
					state.Timers[id] = t
				end
			end
		end
	end
end)

-- ---------- PETS ----------
local petsFolder = Instance.new("Folder")
petsFolder.Name = "Pets"
petsFolder.Parent = workspace

local activePets = {} -- [player] = { instâncias criadas }
local SLOT_OFFSETS = {
	Vector3.new(-3.5, 0.2, 3),
	Vector3.new(3.5, 0.2, 3),
	Vector3.new(-2, 0.6, 6),
	Vector3.new(2, 0.6, 6),
}

local function petSlots(player: Player): number
	return Config.PET_SLOTS + (player:GetAttribute("VIP") and 1 or 0)
end

local function petBonusOf(id: string?): number
	local def = id and Config.PetById[id]
	return def and def.Bonus or 0
end

local function buildPetModel(def)
	local model = Instance.new("Model")
	model.Name = def.Name
	local function piece(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = cf
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		part.Transparency = transparency or 0
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = model
		return part
	end
	local ghost = def.Id == "fantasma"
	local metal = def.Id == "robo"
	local mat = metal and Enum.Material.Metal or Enum.Material.SmoothPlastic
	local body = piece("Corpo", Vector3.new(1.6, 1.3, 2), CFrame.new(), def.Body, mat, ghost and 0.25 or 0)
	local head = CFrame.new(0, 0.95, -1.05)
	piece("Cabeca", Vector3.new(1.4, 1.3, 1.3), head, def.Body, mat, ghost and 0.25 or 0)
	piece("Olho", Vector3.new(0.24, 0.32, 0.05), head * CFrame.new(-0.3, 0.15, -0.66), Color3.fromRGB(20, 20, 20))
	piece("Olho", Vector3.new(0.24, 0.32, 0.05), head * CFrame.new(0.3, 0.15, -0.66), Color3.fromRGB(20, 20, 20))
	piece("Focinho", Vector3.new(0.6, 0.35, 0.2), head * CFrame.new(0, -0.3, -0.7), def.Accent)
	if def.Id == "coelho" then
		piece("Orelha", Vector3.new(0.3, 1.2, 0.25), head * CFrame.new(-0.35, 1.2, 0), def.Body)
		piece("Orelha", Vector3.new(0.3, 1.2, 0.25), head * CFrame.new(0.35, 1.2, 0), def.Body)
	elseif metal then
		piece("Antena", Vector3.new(0.15, 0.8, 0.15), head * CFrame.new(0, 1, 0), Color3.fromRGB(60, 60, 70))
		piece("LuzAntena", Vector3.new(0.35, 0.35, 0.35), head * CFrame.new(0, 1.45, 0), def.Accent, Enum.Material.Neon)
	elseif not ghost then
		piece("Orelha", Vector3.new(0.4, 0.55, 0.3), head * CFrame.new(-0.45, 0.85, 0), def.Accent)
		piece("Orelha", Vector3.new(0.4, 0.55, 0.3), head * CFrame.new(0.45, 0.85, 0), def.Accent)
	end
	if def.Id == "unicornio" then
		piece("Chifre", Vector3.new(0.25, 1, 0.25), head * CFrame.new(0, 1.05, -0.3), def.Accent, Enum.Material.Neon)
	end
	if not ghost then
		for _, x in ipairs({ -0.55, 0.55 }) do
			for _, z in ipairs({ -0.6, 0.6 }) do
				piece("Pata", Vector3.new(0.4, 0.5, 0.4), CFrame.new(x, -0.85, z), def.Accent)
			end
		end
		piece("Cauda", Vector3.new(0.35, 0.35, 0.9), CFrame.new(0, 0.4, 1.25) * CFrame.Angles(math.rad(30), 0, 0), def.Accent)
	end
	if def.Wings then
		piece("Asa", Vector3.new(1.8, 0.15, 1.1), CFrame.new(-1.5, 0.55, 0.1) * CFrame.Angles(0, 0, math.rad(25)), def.Accent, Enum.Material.Neon)
		piece("Asa", Vector3.new(1.8, 0.15, 1.1), CFrame.new(1.5, 0.55, 0.1) * CFrame.Angles(0, 0, math.rad(-25)), def.Accent, Enum.Material.Neon)
	end
	for _, part in ipairs(model:GetChildren()) do
		if part ~= body then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = part
			weld.Parent = body
		end
	end
	model.PrimaryPart = body
	if def.Glow then
		addLight(body, def.Accent, 9, 1.2)
	end
	if def.Sparkle then
		local sparkle = Instance.new("Sparkles")
		sparkle.SparkleColor = def.Accent
		sparkle.Parent = body
	end
	local rarity = Config.RarityById[def.Rarity]
	local bb = makeBillboard(body, 2.6, 160, 40, 45)
	makeLabel(bb, def.Name, rarity and rarity.Color or Color3.new(1, 1, 1), 0.55, 0, Enum.Font.GothamBold)
	makeLabel(bb, "+" .. math.floor(def.Bonus * 100) .. "% renda", Color3.fromRGB(120, 255, 140), 0.45, 0.55, Enum.Font.GothamBold)
	return model, body
end

local function clearPets(player: Player)
	for _, inst in ipairs(activePets[player] or {}) do
		inst:Destroy()
	end
	activePets[player] = {}
end

local function spawnPets(player: Player)
	clearPets(player)
	local data = playerData[player]
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not data or not root then
		return
	end
	for slot, index in ipairs(data.Equipped) do
		local def = Config.PetById[data.Pets[index]]
		local offset = SLOT_OFFSETS[slot]
		if def and offset then
			local model, body = buildPetModel(def)
			local target = Instance.new("Attachment")
			target.Name = "PetSlot" .. slot
			target.Position = offset
			target.Parent = root
			local own = Instance.new("Attachment")
			own.Parent = body
			local align = Instance.new("AlignPosition")
			align.Attachment0 = own
			align.Attachment1 = target
			align.Responsiveness = 18
			align.MaxForce = 1e6
			align.Parent = body
			local orient = Instance.new("AlignOrientation")
			orient.Attachment0 = own
			orient.Attachment1 = target
			orient.Responsiveness = 14
			orient.MaxTorque = 1e6
			orient.Parent = body
			model:PivotTo(root.CFrame * CFrame.new(offset))
			model.Parent = petsFolder
			pcall(function()
				body:SetNetworkOwner(player)
			end)
			table.insert(activePets[player], model)
			table.insert(activePets[player], target)
		end
	end
end

local function syncPets(player: Player, respawn: boolean?)
	local data = playerData[player]
	if not data then
		return
	end
	local valid = {}
	for _, index in ipairs(data.Equipped) do
		if data.Pets[index] and #valid < petSlots(player) and not table.find(valid, index) then
			table.insert(valid, index)
		end
	end
	data.Equipped = valid
	local bonus = 0
	for _, index in ipairs(valid) do
		bonus += petBonusOf(data.Pets[index])
	end
	player:SetAttribute("PetBonus", bonus)
	player:SetAttribute("PetSlots", petSlots(player))
	player:SetAttribute("PetsJSON", HttpService:JSONEncode(data.Pets))
	player:SetAttribute("EquippedJSON", HttpService:JSONEncode(data.Equipped))
	if respawn ~= false then
		spawnPets(player)
	end
	local state = playerPlot[player]
	if state then
		refreshButtons(state)
	end
end

local function equipBest(player: Player)
	local data = playerData[player]
	local order = {}
	for i in ipairs(data.Pets) do
		table.insert(order, i)
	end
	table.sort(order, function(a, b)
		return petBonusOf(data.Pets[a]) > petBonusOf(data.Pets[b])
	end)
	data.Equipped = {}
	for i = 1, math.min(petSlots(player), #order) do
		table.insert(data.Equipped, order[i])
	end
end

local function rollPet(): string
	local total = 0
	for _, r in ipairs(Config.RARITIES) do
		total += r.Chance
	end
	local roll = math.random() * total
	local rarity = Config.RARITIES[1].Id
	for _, r in ipairs(Config.RARITIES) do
		roll -= r.Chance
		if roll <= 0 then
			rarity = r.Id
			break
		end
	end
	local pool = {}
	for _, pet in ipairs(Config.PETS) do
		if pet.Rarity == rarity then
			table.insert(pool, pet.Id)
		end
	end
	return pool[math.random(1, #pool)]
end

local function givePet(player: Player, id: string)
	local data = playerData[player]
	table.insert(data.Pets, id)
	local newIndex = #data.Pets
	if #data.Equipped < petSlots(player) then
		table.insert(data.Equipped, newIndex)
	else
		local worstSlot, worstBonus = nil, math.huge
		for slot, index in ipairs(data.Equipped) do
			local b = petBonusOf(data.Pets[index])
			if b < worstBonus then
				worstSlot, worstBonus = slot, b
			end
		end
		if worstSlot and petBonusOf(id) > worstBonus then
			data.Equipped[worstSlot] = newIndex
		end
	end
end

local hatchCooldown = {}
hatchEgg = function(player: Player)
	local data = playerData[player]
	if not data or (hatchCooldown[player] and os.clock() - hatchCooldown[player] < 1) then
		return
	end
	hatchCooldown[player] = os.clock()
	if #data.Pets >= Config.PET_INVENTORY then
		notify(player, "🎒 Inventário de pets cheio! Libere espaço no menu 🐾 Pets.", "erro")
		return
	end
	local price = Config.EggPrice(player:GetAttribute("IncomeRate") or 0, player:GetAttribute("Rebirths") or 0)
	local cash = getCash(player)
	if cash < price then
		notify(player, "Faltam " .. Format(price - cash) .. " para chocar um ovo", "erro")
		return
	end
	setCash(player, cash - price)
	local id = rollPet()
	givePet(player, id)
	addStat(player, "Eggs", 1)
	hatchEvent:FireClient(player, id)
	local def = Config.PetById[id]
	if def.Rarity == "Lendário" then
		notifyAll("🌟 " .. player.DisplayName .. " chocou um pet LENDÁRIO: " .. def.Name .. "!", "ok")
	end
	syncPets(player)
end

petFunc.OnServerInvoke = function(player, action, arg)
	local data = playerData[player]
	if not data then
		return false
	end
	if action == "equip" and type(arg) == "number" and data.Pets[arg] then
		if table.find(data.Equipped, arg) then
			return true
		end
		if #data.Equipped >= petSlots(player) then
			return false, "Você já tem " .. petSlots(player) .. " pets equipados. Desequipe um primeiro."
		end
		table.insert(data.Equipped, arg)
	elseif action == "unequip" and type(arg) == "number" then
		local pos = table.find(data.Equipped, arg)
		if pos then
			table.remove(data.Equipped, pos)
		end
	elseif action == "best" then
		equipBest(player)
	elseif action == "delete" and type(arg) == "number" and data.Pets[arg] then
		if data.Pets[arg] == "dragao_vip" then
			return false, "O pet VIP não pode ser liberado."
		end
		table.remove(data.Pets, arg)
		local newEquipped = {}
		for _, index in ipairs(data.Equipped) do
			if index ~= arg then
				table.insert(newEquipped, index > arg and index - 1 or index)
			end
		end
		data.Equipped = newEquipped
	else
		return false
	end
	syncPets(player)
	return true
end

-- ---------- Skins ----------
skinFunc.OnServerInvoke = function(player, skinId)
	local data = playerData[player]
	local skin = type(skinId) == "string" and Config.SkinById[skinId]
	if not data or not skin then
		return false
	end
	if not Config.SkinUnlocked(skin, player:GetAttribute("Rebirths") or 0, player:GetAttribute("VIP") == true) then
		if skin.Vip then
			return false, "👑 Skin exclusiva VIP!"
		end
		return false, "🔒 Libera com " .. skin.Rebirths .. " rebirth(s)."
	end
	data.Skin = skin.Id
	player:SetAttribute("Skin", skin.Id)
	local state = playerPlot[player]
	if state then
		applySkin(state)
	end
	return true, "🎨 Skin aplicada: " .. skin.Name
end

-- ---------- VIP ----------
local function addVipTag(player: Player)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head or not player:GetAttribute("VIP") or head:FindFirstChild("TagVIP") then
		return
	end
	local bb = makeBillboard(head, 2.4, 120, 34, 60)
	bb.Name = "TagVIP"
	makeLabel(bb, "👑 VIP", Color3.fromRGB(255, 215, 0), 1, 0)
end

local function onBecameVip(player: Player)
	local data = playerData[player]
	if not data then
		return
	end
	if not data.VipPetGiven then
		data.VipPetGiven = true
		givePet(player, "dragao_vip")
		notify(player, "🐉 Você ganhou o pet exclusivo Dragão Dourado VIP!", "ok")
	end
	syncPets(player)
	addVipTag(player)
end

-- ---------- Ranking global ----------
local rankRebirths, rankEarned = nil, nil
pcall(function()
	rankRebirths = DataStoreService:GetOrderedDataStore("Ranking_Rebirths_v1")
	rankEarned = DataStoreService:GetOrderedDataStore("Ranking_Ganhos_v1")
end)

local nameCache = {}
local function nameOf(userId: number): string
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nameCache[userId] = ok and name or ("Jogador " .. userId)
	return nameCache[userId]
end

local function makeBoard(part: BasePart, title: string, color: Color3)
	local face = part.Position.X > 0 and Enum.NormalId.Left or Enum.NormalId.Right
	local sg = makeSurface(part, face, 25)
	local titleLabel = makeLabel(sg, title, color, 0.12, 0.02)
	titleLabel.Font = Enum.Font.FredokaOne
	local rows = {}
	for i = 1, 10 do
		local row = makeLabel(sg, i .. ". —", Color3.new(1, 1, 1), 0.075, 0.16 + (i - 1) * 0.083, Enum.Font.GothamBold)
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Size = UDim2.new(0.9, 0, 0.075, 0)
		row.Position = UDim2.new(0.05, 0, 0.16 + (i - 1) * 0.083, 0)
		if i <= 3 then
			row.TextColor3 = ({ Color3.fromRGB(255, 215, 0), Color3.fromRGB(220, 220, 230), Color3.fromRGB(230, 150, 90) })[i]
		end
		rows[i] = row
	end
	return rows
end

local function refreshBoard(store, rows, formatter)
	if not store or not rows then
		return
	end
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, 10)
	end)
	if not ok then
		return
	end
	local entries = pages:GetCurrentPage()
	for i = 1, 10 do
		local entry = entries[i]
		if entry then
			local userId = tonumber(string.sub(entry.key, 3)) or 0
			rows[i].Text = i .. ". " .. nameOf(userId) .. "  —  " .. formatter(entry.value)
		else
			rows[i].Text = i .. ". —"
		end
	end
end

do
	local lobby = workspace:FindFirstChild("Lobby")
	local boardReb = lobby and lobby:FindFirstChild("RankingRebirths")
	local boardCash = lobby and lobby:FindFirstChild("RankingDinheiro")
	local rowsReb = boardReb and makeBoard(boardReb, "🔄 TOP REBIRTHS", Color3.fromRGB(213, 155, 255))
	local rowsCash = boardCash and makeBoard(boardCash, "💰 MAIS RICOS (TOTAL GANHO)", Color3.fromRGB(110, 255, 140))
	task.spawn(function()
		while true do
			refreshBoard(rankRebirths, rowsReb, function(v)
				return tostring(v) .. " rebirths"
			end)
			refreshBoard(rankEarned, rowsCash, function(v)
				return Format(v)
			end)
			task.wait(Config.LEADERBOARD_REFRESH)
		end
	end)

	-- Área VIP: placa, baú e porta
	local vip = workspace:FindFirstChild("AreaVIP")
	if vip then
		for _, d in ipairs(vip:GetDescendants()) do
			if d:IsA("BasePart") and d.Name == "PlacaVIP" then
				for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
					makeLabel(makeSurface(d, face, 30), "👑 ÁREA VIP", Color3.fromRGB(255, 215, 0), 0.9, 0.05)
				end
			elseif d:IsA("BasePart") and d.Name == "LustreVIP" then
				addLight(d, Color3.fromRGB(255, 230, 180), 26, 1.2)
			elseif d:IsA("BasePart") and d.Name == "PortaVIP" then
				local bb = makeBillboard(d, 5.5, 260, 40, 60)
				makeLabel(bb, "Só para VIPs 👑", Color3.fromRGB(255, 215, 0), 1, 0)
				d.Touched:Connect(function(hit)
					local player = Players:GetPlayerFromCharacter(hit.Parent)
					if player and not player:GetAttribute("VIP") and Config.GAMEPASS_VIP_ID ~= 0 then
						local last = player:GetAttribute("VipPromptAt") or 0
						if os.clock() - last > 8 then
							player:SetAttribute("VipPromptAt", os.clock())
							MarketplaceService:PromptGamePassPurchase(player, Config.GAMEPASS_VIP_ID)
						end
					end
				end)
			elseif d:IsA("BasePart") and d.Name == "BauVIP" then
				local bb = makeBillboard(d, 4, 220, 40, 40)
				makeLabel(bb, "🎁 BAÚ VIP", Color3.fromRGB(255, 215, 0), 1, 0)
				local prompt = Instance.new("ProximityPrompt")
				prompt.ObjectText = "Baú VIP"
				prompt.ActionText = "Abrir"
				prompt.HoldDuration = 0.5
				prompt.RequiresLineOfSight = false
				prompt.Parent = d
				prompt.Triggered:Connect(function(player)
					local data = playerData[player]
					if not data then
						return
					end
					if not player:GetAttribute("VIP") then
						notify(player, "👑 O baú é só para VIPs!", "erro")
						return
					end
					local wait = Config.VIP_CHEST_COOLDOWN - (os.time() - (data.LastVipChest or 0))
					if wait > 0 then
						notify(player, string.format("⏳ O baú abre de novo em %d:%02d", wait // 60, wait % 60), "erro")
						return
					end
					data.LastVipChest = os.time()
					local amount = Config.VipChestAmount(player:GetAttribute("IncomeRate") or 0, player:GetAttribute("Rebirths") or 0)
					addCash(player, amount)
					burst(d.Position + Vector3.new(0, 3, 0), Color3.fromRGB(255, 215, 0), 50)
					notify(player, "🎁 Baú VIP: +" .. Format(amount), "compra")
				end)
			end
		end
	end
end

-- ---------- Salvamento ----------
local function saveData(player: Player)
	local data = playerData[player]
	if not store or not data or not data.Loaded then
		return
	end
	local state = playerPlot[player]
	local owned = {}
	if state then
		for id in pairs(state.Owned) do
			table.insert(owned, id)
		end
	else
		owned = data.Owned or {}
	end
	local payload = {
		Cash = getCash(player),
		Rebirths = player:GetAttribute("Rebirths") or 0,
		Owned = owned,
		Bank = state and state.Bank or 0,
		LastDay = data.LastDay,
		Streak = data.Streak,
		LastSeen = os.time(),
		Rate = state and getIncomeRate(state) or data.Rate or 0,
		Stats = data.Stats,
		Mission = data.Mission,
		Pets = data.Pets,
		Equipped = data.Equipped,
		Skin = data.Skin,
		VipPetGiven = data.VipPetGiven,
		LastVipChest = data.LastVipChest,
	}
	local ok, err = pcall(function()
		store:SetAsync("p_" .. player.UserId, payload)
	end)
	if not ok then
		warn("[Tycoon] Erro ao salvar:", err)
	end
	-- ranking global
	pcall(function()
		if rankRebirths then
			rankRebirths:SetAsync("p_" .. player.UserId, math.floor(payload.Rebirths))
		end
		if rankEarned then
			rankEarned:SetAsync("p_" .. player.UserId, math.floor(math.min(data.Stats.Earned or 0, 9e18)))
		end
	end)
end

local function checkGamepasses(player: Player)
	local function owns(id: number): boolean
		if id == 0 then
			return false
		end
		local ok, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
		end)
		return ok and result == true
	end
	player:SetAttribute("Has2x", owns(Config.GAMEPASS_2X_ID))
	player:SetAttribute("AutoCollect", owns(Config.GAMEPASS_AUTOCOLLECT_ID))
	player:SetAttribute("VIP", owns(Config.GAMEPASS_VIP_ID))
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if not purchased then
		return
	end
	if passId == Config.GAMEPASS_2X_ID then
		player:SetAttribute("Has2x", true)
		notify(player, "💸 Dinheiro em Dobro ativado!", "ok")
	elseif passId == Config.GAMEPASS_VIP_ID then
		player:SetAttribute("VIP", true)
		notify(player, "👑 Agora você é VIP! Área VIP, baú VIP, skins e pet exclusivos liberados.", "ok")
		onBecameVip(player)
	elseif passId == Config.GAMEPASS_AUTOCOLLECT_ID then
		player:SetAttribute("AutoCollect", true)
		notify(player, "⚡ Coleta Automática ativada!", "ok")
		local state = playerPlot[player]
		if state and state.Bank > 0 then
			addCash(player, state.Bank)
			state.Bank = 0
			updateBank(state)
		end
	end
	local state = playerPlot[player]
	if state then
		refreshButtons(state)
	end
end)

-- ---------- Jogadores ----------
local function onPlayerAdded(player: Player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local cash = Instance.new("NumberValue")
	cash.Name = "Dinheiro"
	cash.Parent = ls
	local reb = Instance.new("IntValue")
	reb.Name = "Rebirths"
	reb.Parent = ls

	local data = {
		Cash = Config.START_CASH,
		Rebirths = 0,
		Owned = {},
		Bank = 0,
		Loaded = false,
		Streak = 0,
		Rate = 0,
		Stats = { Earned = 0, Bought = 0, Golden = 0, Eggs = 0 },
		Mission = 1,
		Pets = {},
		Equipped = {},
		Skin = "classico",
		VipPetGiven = false,
		LastVipChest = 0,
	}
	if store then
		local ok, result = pcall(function()
			return store:GetAsync("p_" .. player.UserId)
		end)
		if ok then
			data.Loaded = true
			if type(result) == "table" then
				data.Cash = tonumber(result.Cash) or data.Cash
				data.Rebirths = tonumber(result.Rebirths) or 0
				data.Owned = type(result.Owned) == "table" and result.Owned or {}
				data.Bank = tonumber(result.Bank) or 0
				data.LastDay = tonumber(result.LastDay)
				data.Streak = tonumber(result.Streak) or 0
				data.LastSeen = tonumber(result.LastSeen)
				data.Rate = tonumber(result.Rate) or 0
				data.Mission = tonumber(result.Mission) or 1
				if type(result.Pets) == "table" then
					for _, id in ipairs(result.Pets) do
						if Config.PetById[id] then
							table.insert(data.Pets, id)
						end
					end
				end
				if type(result.Equipped) == "table" then
					for _, index in ipairs(result.Equipped) do
						if type(index) == "number" then
							table.insert(data.Equipped, index)
						end
					end
				end
				data.Skin = Config.SkinById[result.Skin] and result.Skin or "classico"
				data.VipPetGiven = result.VipPetGiven == true
				data.LastVipChest = tonumber(result.LastVipChest) or 0
				if type(result.Stats) == "table" then
					for k, v in pairs(result.Stats) do
						data.Stats[k] = tonumber(v) or 0
					end
				end
			end
		else
			warn("[Tycoon] Erro ao carregar dados (não vamos salvar por cima):", result)
		end
	end
	playerData[player] = data

	cash.Value = data.Cash
	reb.Value = data.Rebirths
	player:SetAttribute("Rebirths", data.Rebirths)
	ls.Parent = player

	checkGamepasses(player)

	-- Lucro offline e recompensa diária (só com dados carregados, para não dar em dobro)
	if data.Loaded then
		local messages = {}
		if data.LastSeen and (data.Rate or 0) > 0 then
			local seconds = math.clamp(os.time() - data.LastSeen, 0, Config.OFFLINE_MAX_HOURS * 3600)
			local earned = math.floor(seconds * data.Rate * Config.OFFLINE_RATE)
			if seconds >= 60 and earned > 0 then
				cash.Value += earned
				table.insert(messages, { "🌙 Enquanto você estava fora, seu estúdio lucrou " .. Format(earned) .. "!", "ok" })
			end
		end
		local today = math.floor(os.time() / 86400)
		if data.LastDay ~= today then
			if data.LastDay == today - 1 then
				data.Streak = (data.Streak or 0) + 1
			else
				data.Streak = 1
			end
			data.LastDay = today
			local day = math.min(data.Streak, 7)
			local reward = math.floor(math.max(Config.DAILY_BASE * day * (1 + data.Rebirths), (data.Rate or 0) * 60 * day))
			cash.Value += reward
			table.insert(messages, { "🎁 Recompensa diária (dia " .. data.Streak .. "): +" .. Format(reward) .. "  •  Volte amanhã para ganhar mais!", "ok" })
		end
		player:SetAttribute("Streak", data.Streak or 0)
		if #messages > 0 then
			task.delay(5, function()
				for _, m in ipairs(messages) do
					if player.Parent then
						notify(player, m[1], m[2])
					end
				end
			end)
		end
	end

	checkMissions(player)

	player:SetAttribute("Skin", data.Skin)
	if player:GetAttribute("VIP") then
		onBecameVip(player)
	else
		syncPets(player, false)
	end

	cash.Changed:Connect(function()
		local state = playerPlot[player]
		if state then
			refreshButtons(state)
		end
	end)

	local function onCharacter(char)
		char:WaitForChild("HumanoidRootPart", 10)
		task.wait(0.2)
		local state = playerPlot[player]
		if state then
			teleportToPlot(player, state)
		end
		spawnPets(player)
		addVipTag(player)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	local state = playerPlot[player]
	if state then
		release(state)
	end
	clearPets(player)
	playerData[player] = nil
	lastNotify[player] = nil
	missionDirty[player] = nil
	hatchCooldown[player] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(saveData, player)
	end
	task.wait(3)
end)

-- Salvamento automático a cada 60s
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(saveData, player)
		end
	end
end)

-- ---------- Produtos de desenvolvedor (pacotes de dinheiro) ----------
local productsById = {}
for _, product in ipairs(Config.PRODUCTS) do
	if product.Id ~= 0 then
		productsById[product.Id] = product
	end
end
local processedReceipts = {}

MarketplaceService.ProcessReceipt = function(receipt)
	if processedReceipts[receipt.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local product = productsById[receipt.ProductId]
	if not player or not product or not player:FindFirstChild("leaderstats") then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local amount = Config.ProductAmount(product, player:GetAttribute("IncomeRate") or 0, player:GetAttribute("Rebirths") or 0)
	addCash(player, amount)
	processedReceipts[receipt.PurchaseId] = true
	notify(player, "💰 " .. product.Name .. ": +" .. Format(amount), "compra")
	task.spawn(saveData, player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ---------- Rebirth ----------
rebirthFunc.OnServerInvoke = function(player)
	local state = playerPlot[player]
	if not state then
		return false, "Assuma um estúdio primeiro!"
	end
	if not state.Owned["trofeu"] then
		return false, "Compre o Troféu Game of the Year para fazer Rebirth!"
	end
	local rebirths = (player:GetAttribute("Rebirths") or 0) + 1
	player:SetAttribute("Rebirths", rebirths)
	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Rebirths") then
		ls.Rebirths.Value = rebirths
	end
	setCash(player, 0)
	hideAllItems(state)
	clearDrops(state)
	state.Bank = 0
	for _, id in ipairs(Config.BASE_ITEMS) do
		ownItem(state, id, true)
	end
	applyTheme(state)
	updateBank(state)
	refreshButtons(state)
	checkMissions(player)
	burst(state.Door.Position + Vector3.new(0, 4, 0), Color3.fromRGB(255, 60, 200), 80)
	task.spawn(saveData, player)
	local bonus = math.floor(Config.REBIRTH_BONUS * rebirths * 100)
	local theme = player:GetAttribute("ThemeName") or ""
	notifyAll("🔄 " .. player.DisplayName .. " fez o Rebirth " .. rebirths .. "!", "info")
	return true, "🔄 Rebirth " .. rebirths .. "! Bônus permanente: +" .. bonus .. "% de renda  •  Estúdio " .. theme
end
