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

local rebirthFunc = Instance.new("RemoteFunction")
rebirthFunc.Name = "Rebirth"
rebirthFunc.Parent = remotes

game:GetService("Lighting").ClockTime = 14.5

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

local playerData = {} -- [player] = { Cash, Rebirths, Owned, Bank, Loaded }
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
	else
		state.DoorTitle.Text = "🎮 Estúdio Livre"
		state.DoorSub.Text = "Toque na porta para ser o dono!"
		state.Door.Color = Color3.fromRGB(0, 200, 255)
	end
	if state.SignLabel then
		state.SignLabel.Text = state.Owner and ("ESTÚDIO " .. string.upper(state.Owner.DisplayName)) or "ESTÚDIO"
	end
end

local function refreshButtons(state)
	local cash = state.Owner and getCash(state.Owner) or 0
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
		else
			btn.Parent = state.Storage
		end
	end
	if state.Owner then
		state.Owner:SetAttribute("Multiplier", getMultiplier(state))
		state.Owner:SetAttribute("CanRebirth", state.Owned["trofeu"] == true)
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

local function ownItem(state, id: string)
	state.Owned[id] = true
	local model = state.ItemModels[id]
	if model then
		model.Parent = state.Model.Items
		setConveyorVelocity(model)
	end
end

local function hideAllItems(state)
	for id, model in pairs(state.ItemModels) do
		model.Parent = state.Storage
		state.Owned[id] = nil
	end
	state.Owned = {}
	state.Timers = {}
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
	setCash(player, cash - item.Price)
	ownItem(state, id)
	refreshButtons(state)
	notify(player, "✅ Comprado: " .. item.Name, "ok")
	if item.Type == "Trophy" then
		notify(player, "🏆 Você ganhou o Game of the Year! Agora pode fazer REBIRTH.", "ok")
	elseif item.Type == "Multiplier" then
		notify(player, "📈 Renda multiplicada por " .. tostring(item.Mult) .. "x!", "ok")
	elseif item.Type == "Expansion" then
		notify(player, "🏗️ Nova linha de produção liberada!", "ok")
	end
end

-- ---------- Produção (cartuchos) ----------
local function spawnDrop(state, head: BasePart, value: number)
	local drop = Instance.new("Part")
	drop.Name = "Cartucho"
	drop.Size = Vector3.new(1.2, 0.5, 1.6)
	drop.Color = head.Color
	drop.Material = Enum.Material.SmoothPlastic
	drop.TopSurface = Enum.SurfaceType.Smooth
	drop.BottomSurface = Enum.SurfaceType.Smooth
	drop.CFrame = CFrame.new(head.Position - Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, math.rad(math.random(-20, 20)), 0)
	drop:SetAttribute("Value", value)
	drop:SetAttribute("Plot", state.Model.Name)

	local label = Instance.new("Part")
	label.Name = "Etiqueta"
	label.Size = Vector3.new(0.9, 0.1, 0.7)
	label.Color = Color3.new(1, 1, 1)
	label.Material = Enum.Material.SmoothPlastic
	label.CanCollide = false
	label.Massless = true
	label.CFrame = drop.CFrame * CFrame.new(0, 0.28, -0.2)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = drop
	weld.Part1 = label
	weld.Parent = drop
	label.Parent = drop

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
	hit:Destroy()
	if not state.Owner then
		return
	end
	local amount = math.floor(value * getMultiplier(state))
	if state.Owner:GetAttribute("AutoCollect") then
		addCash(state.Owner, amount)
	else
		state.Bank += amount
		updateBank(state)
	end
	-- efeito de brilho na publicadora
	local light = collector:FindFirstChildOfClass("PointLight")
	if light then
		light.Brightness = 4
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
	updateBank(state)
	updateDoor(state)
	refreshButtons(state)
	notify(player, "🎉 Bem-vindo ao seu estúdio de games!", "ok")
	notify(player, "Pise nos botões para contratar e melhorar. Colete o dinheiro no tapete verde.", "info")
end

local function release(state)
	if state.Owner then
		playerPlot[state.Owner] = nil
	end
	state.Owner = nil
	state.Bank = 0
	hideAllItems(state)
	clearDrops(state)
	updateBank(state)
	updateDoor(state)
	refreshButtons(state)
end

-- ---------- Montagem dos estúdios ----------
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
		notify(player, "+" .. Format(amount), "ok")
		task.wait(0.5)
		padDebounce = false
	end)

	-- Publicadoras (coletores), esteiras, letreiros e nomes
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			if d.Name == "Publicadora" then
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(80, 160, 255)
				light.Range = 14
				light.Brightness = 1
				light.Parent = d
				local bb = makeBillboard(d, 6, 200, 50, 90)
				makeLabel(bb, "📦 PUBLICADORA", Color3.fromRGB(150, 210, 255), 1, 0)
				d.Touched:Connect(function(hit)
					onCollectorTouched(state, d, hit)
				end)
			elseif d.Name == "Letreiro" then
				local sg = Instance.new("SurfaceGui")
				sg.Face = Enum.NormalId.Front
				sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
				sg.PixelsPerStud = 40
				sg.LightInfluence = 0
				sg.Parent = d
				state.SignLabel = makeLabel(sg, "ESTÚDIO", Color3.fromRGB(255, 255, 255), 1, 0)
			elseif d.Name == "Outdoor" then
				local sg = Instance.new("SurfaceGui")
				sg.Face = Enum.NormalId.Front
				sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
				sg.PixelsPerStud = 30
				sg.LightInfluence = 0
				sg.Parent = d
				makeLabel(sg, "🎮 NOVO JOGO", Color3.fromRGB(255, 220, 60), 0.55, 0.05)
				makeLabel(sg, "JÁ DISPONÍVEL!", Color3.new(1, 1, 1), 0.35, 0.6)
			elseif d.Name == "Dropper" then
				local item = Config.ById[d.Parent.Name]
				if item then
					local bb = makeBillboard(d, 2.6, 180, 40, 55)
					makeLabel(bb, item.Name, Color3.new(1, 1, 1), 1, 0, Enum.Font.GothamBold)
				end
			elseif d.Name == "Copa" then
				local bb = makeBillboard(d, 3.5, 240, 50, 80)
				makeLabel(bb, "🏆 GAME OF THE YEAR", Color3.fromRGB(255, 215, 0), 1, 0)
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

	updateBank(state)
	updateDoor(state)
	table.insert(plots, state)
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
	}
	local ok, err = pcall(function()
		store:SetAsync("p_" .. player.UserId, payload)
	end)
	if not ok then
		warn("[Tycoon] Erro ao salvar:", err)
	end
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
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if not purchased then
		return
	end
	if passId == Config.GAMEPASS_2X_ID then
		player:SetAttribute("Has2x", true)
		notify(player, "💸 Dinheiro em Dobro ativado!", "ok")
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

	local data = { Cash = Config.START_CASH, Rebirths = 0, Owned = {}, Bank = 0, Loaded = false }
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

	cash.Changed:Connect(function()
		local state = playerPlot[player]
		if state then
			refreshButtons(state)
		end
	end)

	player.CharacterAdded:Connect(function()
		local state = playerPlot[player]
		if state then
			task.wait(0.2)
			teleportToPlot(player, state)
		end
	end)
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
	playerData[player] = nil
	lastNotify[player] = nil
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
		ownItem(state, id)
	end
	updateBank(state)
	refreshButtons(state)
	task.spawn(saveData, player)
	local bonus = math.floor(Config.REBIRTH_BONUS * rebirths * 100)
	return true, "🔄 Rebirth " .. rebirths .. "! Bônus permanente: +" .. bonus .. "% de renda"
end
