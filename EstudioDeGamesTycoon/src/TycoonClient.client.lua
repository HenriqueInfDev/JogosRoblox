-- ============================================================
--  ESTÚDIO DE GAMES TYCOON - Interface do jogador
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("TycoonConfig"))
local Format = Config.Format
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyEvent = remotes:WaitForChild("Notify")
local soldEvent = remotes:WaitForChild("Sold")
local rebirthFunc = remotes:WaitForChild("Rebirth")
local petFunc = remotes:WaitForChild("PetAction")
local skinFunc = remotes:WaitForChild("SetSkin")
local hatchEvent = remotes:WaitForChild("Hatch")
local HttpService = game:GetService("HttpService")

local gui = Instance.new("ScreenGui")
gui.Name = "TycoonHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Interface menor em telas pequenas (celular)
local uiScale = Instance.new("UIScale")
uiScale.Parent = gui
local function updateScale()
	local camera = workspace.CurrentCamera
	local w = camera and camera.ViewportSize.X or 1200
	uiScale.Scale = w < 700 and 0.65 or (w < 1000 and 0.8 or 1)
end
updateScale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

-- ---------- Sons ----------
local sounds = {}
for key, id in pairs(Config.SOUNDS) do
	local s = Instance.new("Sound")
	s.Name = "Tycoon_" .. key
	s.SoundId = id
	s.Volume = 0.5
	s.Parent = SoundService
	sounds[key] = s
end
local function playSound(key: string, pitch: number?)
	local s = sounds[key]
	if s then
		s.PlaybackSpeed = pitch or 1
		pcall(function()
			SoundService:PlayLocalSound(s)
		end)
	end
end

-- ---------- Helpers ----------
local function corner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number?)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

local function label(parent: Instance, text: string, font: Enum.Font, color: Color3)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = font
	l.TextColor3 = color
	l.TextScaled = true
	l.Text = text
	l.Parent = parent
	return l
end

local function panel(size: UDim2, pos: UDim2, anchor: Vector2, strokeColor: Color3)
	local f = Instance.new("Frame")
	f.AnchorPoint = anchor
	f.Position = pos
	f.Size = size
	f.BackgroundColor3 = Color3.fromRGB(22, 24, 38)
	f.BackgroundTransparency = 0.1
	f.Parent = gui
	corner(f, 14)
	stroke(f, strokeColor, 3)
	return f
end

local function bar(parent: Instance, pos: UDim2, size: UDim2, color: Color3)
	local back = Instance.new("Frame")
	back.Position = pos
	back.Size = size
	back.BackgroundColor3 = Color3.fromRGB(50, 52, 70)
	back.Parent = parent
	corner(back, 6)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = color
	fill.Parent = back
	corner(fill, 6)
	return fill
end

-- ---------- Painel de dinheiro ----------
local cashFrame = panel(UDim2.fromOffset(300, 70), UDim2.new(0.5, 0, 0, 8), Vector2.new(0.5, 0), Color3.fromRGB(155, 89, 182))
local cashLabel = label(cashFrame, "$0", Enum.Font.FredokaOne, Color3.fromRGB(110, 255, 140))
cashLabel.Size = UDim2.new(1, -20, 0.6, 0)
cashLabel.Position = UDim2.new(0, 10, 0, 4)
local infoLabel = label(cashFrame, "", Enum.Font.GothamBold, Color3.fromRGB(200, 200, 230))
infoLabel.Size = UDim2.new(1, -20, 0.3, 0)
infoLabel.Position = UDim2.new(0, 10, 0.62, 0)

-- ---------- Próxima meta ----------
local goalFrame = panel(UDim2.fromOffset(300, 46), UDim2.new(0.5, 0, 0, 84), Vector2.new(0.5, 0), Color3.fromRGB(60, 62, 90))
goalFrame.Visible = false
local goalLabel = label(goalFrame, "", Enum.Font.GothamBold, Color3.new(1, 1, 1))
goalLabel.Size = UDim2.new(1, -16, 0, 18)
goalLabel.Position = UDim2.fromOffset(8, 4)
local goalFill = bar(goalFrame, UDim2.fromOffset(8, 27), UDim2.new(1, -16, 0, 12), Color3.fromRGB(110, 255, 140))

-- ---------- Faixa do evento HYPE ----------
local hypeFrame = panel(UDim2.fromOffset(420, 44), UDim2.new(0.5, 0, 0, 138), Vector2.new(0.5, 0), Color3.fromRGB(255, 120, 0))
hypeFrame.BackgroundColor3 = Color3.fromRGB(200, 60, 20)
hypeFrame.Visible = false
local hypeLabel = label(hypeFrame, "", Enum.Font.FredokaOne, Color3.new(1, 1, 1))
hypeLabel.Size = UDim2.new(1, -16, 1, -10)
hypeLabel.Position = UDim2.fromOffset(8, 5)

-- ---------- Missão ----------
local missionFrame = panel(UDim2.fromOffset(270, 104), UDim2.new(1, -12, 0, 8), Vector2.new(1, 0), Color3.fromRGB(52, 152, 219))
missionFrame.Visible = false
local missionTitle = label(missionFrame, "📋 MISSÃO", Enum.Font.FredokaOne, Color3.fromRGB(111, 227, 255))
missionTitle.Size = UDim2.new(1, -20, 0, 22)
missionTitle.Position = UDim2.fromOffset(10, 6)
missionTitle.TextXAlignment = Enum.TextXAlignment.Left
local missionText = label(missionFrame, "", Enum.Font.GothamBold, Color3.new(1, 1, 1))
missionText.Size = UDim2.new(1, -20, 0, 20)
missionText.Position = UDim2.fromOffset(10, 30)
missionText.TextXAlignment = Enum.TextXAlignment.Left
local missionFill = bar(missionFrame, UDim2.fromOffset(10, 56), UDim2.new(1, -20, 0, 14), Color3.fromRGB(52, 152, 219))
local missionProgress = label(missionFrame, "", Enum.Font.GothamBold, Color3.fromRGB(200, 200, 230))
missionProgress.Size = UDim2.new(1, -20, 0, 18)
missionProgress.Position = UDim2.fromOffset(10, 76)
missionProgress.TextXAlignment = Enum.TextXAlignment.Left

-- ---------- Notificações ----------
local toastHolder = Instance.new("Frame")
toastHolder.AnchorPoint = Vector2.new(0.5, 0)
toastHolder.Position = UDim2.new(0.5, 0, 0, 190)
toastHolder.Size = UDim2.fromOffset(400, 220)
toastHolder.BackgroundTransparency = 1
toastHolder.Parent = gui
local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 6)
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toastHolder

local TOAST_COLORS = {
	ok = Color3.fromRGB(39, 174, 96),
	compra = Color3.fromRGB(39, 174, 96),
	coleta = Color3.fromRGB(22, 160, 133),
	erro = Color3.fromRGB(192, 57, 43),
	info = Color3.fromRGB(41, 128, 185),
}
local toastCount = 0

local function toast(text: string, kind: string?)
	kind = kind or "info"
	if kind == "compra" then
		playSound("Buy", 1.1)
	elseif kind == "coleta" then
		playSound("Collect", 1.3)
	elseif kind == "erro" then
		playSound("Error")
	end
	toastCount += 1
	local items = {}
	for _, c in ipairs(toastHolder:GetChildren()) do
		if c:IsA("TextLabel") then
			table.insert(items, c)
		end
	end
	if #items >= 4 then
		table.sort(items, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		items[1]:Destroy()
	end
	local t = Instance.new("TextLabel")
	t.LayoutOrder = toastCount
	t.Size = UDim2.new(1, 0, 0, 38)
	t.BackgroundColor3 = TOAST_COLORS[kind] or TOAST_COLORS.info
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 17
	t.TextWrapped = true
	t.Text = text
	t.Parent = toastHolder
	corner(t, 10)
	local scale = Instance.new("UIScale")
	scale.Scale = 0.6
	scale.Parent = t
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(3.4, function()
		if t.Parent then
			local tw = TweenService:Create(t, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 })
			tw:Play()
			tw.Completed:Wait()
			t:Destroy()
		end
	end)
end

notifyEvent.OnClientEvent:Connect(toast)

-- ---------- "+$" flutuando sobre a Publicadora ----------
local popups = 0
soldEvent.OnClientEvent:Connect(function(position: Vector3, amount: number, golden: boolean)
	if popups >= 8 and not golden then
		return
	end
	popups += 1
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = position + Vector3.new(math.random(-15, 15) / 10, 0, math.random(-15, 15) / 10)
	anchor.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(golden and 220 or 140, golden and 60 or 40)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 90
	bb.LightInfluence = 0
	bb.Parent = anchor
	local l = label(bb, (golden and "✨ +" or "+") .. Format(amount), Enum.Font.FredokaOne,
		golden and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(110, 255, 140))
	l.Size = UDim2.fromScale(1, 1)
	l.TextStrokeTransparency = 0.2
	if golden then
		playSound("Collect", 1.6)
	end
	TweenService:Create(bb, TweenInfo.new(1.1, Enum.EasingStyle.Quad), { StudsOffset = Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(l, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.15, function()
		anchor:Destroy()
		popups -= 1
	end)
end)

-- ---------- Botões laterais ----------
local side = Instance.new("Frame")
side.AnchorPoint = Vector2.new(0, 0.5)
side.Position = UDim2.new(0, 12, 0.5, 0)
side.Size = UDim2.fromOffset(190, 420)
side.BackgroundTransparency = 1
side.Parent = gui
local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 8)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Parent = side

local function sideButton(text: string, color: Color3, order: number)
	local b = Instance.new("TextButton")
	b.LayoutOrder = order
	b.Size = UDim2.new(1, 0, 0, 46)
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 21
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = side
	corner(b, 12)
	stroke(b, Color3.fromRGB(20, 20, 30), 2)
	return b
end

local rebirthBtn = sideButton("🔄 Rebirth", Color3.fromRGB(110, 110, 130), 1)
local pass2xBtn = sideButton("💸 Dinheiro 2x", Color3.fromRGB(241, 196, 15), 2)
local passAutoBtn = sideButton("⚡ Coleta Auto", Color3.fromRGB(52, 152, 219), 3)

-- botão de rebirth pulsa quando está liberado
local rebirthScale = Instance.new("UIScale")
rebirthScale.Parent = rebirthBtn
local pulse = TweenService:Create(rebirthScale, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.08 })

local confirmUntil = 0
rebirthBtn.MouseButton1Click:Connect(function()
	if not player:GetAttribute("CanRebirth") then
		toast("Compre o 🏆 Troféu Game of the Year para liberar o Rebirth!", "erro")
		return
	end
	if os.clock() > confirmUntil then
		confirmUntil = os.clock() + 4
		local bonus = math.floor(Config.REBIRTH_BONUS * 100)
		toast("Clique de novo para confirmar: você recomeça e ganha +" .. bonus .. "% de renda para sempre", "info")
		return
	end
	confirmUntil = 0
	local ok, msg = rebirthFunc:InvokeServer()
	toast(msg or "", ok and "compra" or "erro")
end)

pass2xBtn.MouseButton1Click:Connect(function()
	if Config.GAMEPASS_2X_ID ~= 0 then
		MarketplaceService:PromptGamePassPurchase(player, Config.GAMEPASS_2X_ID)
	end
end)
passAutoBtn.MouseButton1Click:Connect(function()
	if Config.GAMEPASS_AUTOCOLLECT_ID ~= 0 then
		MarketplaceService:PromptGamePassPurchase(player, Config.GAMEPASS_AUTOCOLLECT_ID)
	end
end)

-- ---------- Loja de pacotes de dinheiro ----------
local activeProducts = {}
for _, product in ipairs(Config.PRODUCTS) do
	if product.Id ~= 0 then
		table.insert(activeProducts, product)
	end
end

local shopBtn = sideButton("🛒 Loja", Color3.fromRGB(39, 174, 96), 4)
shopBtn.Visible = #activeProducts > 0

local shop = panel(UDim2.fromOffset(340, 90 + #activeProducts * 64), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), Color3.fromRGB(39, 174, 96))
shop.Visible = false

local shopTitle = label(shop, "🛒 Pacotes de Dinheiro", Enum.Font.FredokaOne, Color3.new(1, 1, 1))
shopTitle.Size = UDim2.new(1, -60, 0, 40)
shopTitle.Position = UDim2.fromOffset(14, 10)
shopTitle.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(36, 36)
closeBtn.Position = UDim2.new(1, -46, 0, 12)
closeBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 20
closeBtn.Text = "X"
closeBtn.Parent = shop
corner(closeBtn, 8)

for i, product in ipairs(activeProducts) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -28, 0, 54)
	b.Position = UDim2.fromOffset(14, 60 + (i - 1) * 64)
	b.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 20
	b.Parent = shop
	corner(b, 10)
	local function updateText()
		local amount = Config.ProductAmount(product, player:GetAttribute("IncomeRate") or 0, player:GetAttribute("Rebirths") or 0)
		b.Text = "💰 " .. product.Name .. "  •  +" .. Format(amount)
	end
	updateText()
	player:GetAttributeChangedSignal("Rebirths"):Connect(updateText)
	player:GetAttributeChangedSignal("IncomeRate"):Connect(updateText)
	b.MouseButton1Click:Connect(function()
		MarketplaceService:PromptProductPurchase(player, product.Id)
	end)
end

shopBtn.MouseButton1Click:Connect(function()
	shop.Visible = not shop.Visible
end)
closeBtn.MouseButton1Click:Connect(function()
	shop.Visible = false
end)

-- ---------- Janelas (pets e skins) ----------
local openWindow = nil
local function window(title: string, width: number, height: number, strokeColor: Color3)
	local f = panel(UDim2.fromOffset(width, height), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), strokeColor)
	f.Visible = false
	f.ZIndex = 5
	local t = label(f, title, Enum.Font.FredokaOne, Color3.new(1, 1, 1))
	t.Size = UDim2.new(1, -70, 0, 34)
	t.Position = UDim2.fromOffset(14, 10)
	t.TextXAlignment = Enum.TextXAlignment.Left
	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(36, 36)
	close.Position = UDim2.new(1, -46, 0, 10)
	close.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Font = Enum.Font.FredokaOne
	close.TextSize = 20
	close.Text = "X"
	close.Parent = f
	corner(close, 8)
	close.MouseButton1Click:Connect(function()
		f.Visible = false
		openWindow = nil
	end)
	return f, t
end
local function toggleWindow(f: Frame)
	if openWindow and openWindow ~= f then
		openWindow.Visible = false
	end
	f.Visible = not f.Visible
	openWindow = f.Visible and f or nil
end

-- ---------- PETS ----------
local petsBtn = sideButton("🐾 Pets", Color3.fromRGB(230, 126, 34), 5)
local petsWin, petsTitle = window("🐾 Meus Pets", 560, 460, Color3.fromRGB(230, 126, 34))
local petsInfo = label(petsWin, "", Enum.Font.GothamBold, Color3.fromRGB(200, 200, 230))
petsInfo.Size = UDim2.new(1, -28, 0, 20)
petsInfo.Position = UDim2.fromOffset(14, 46)
petsInfo.TextXAlignment = Enum.TextXAlignment.Left

local bestBtn = Instance.new("TextButton")
bestBtn.Size = UDim2.fromOffset(200, 38)
bestBtn.Position = UDim2.new(0, 14, 1, -50)
bestBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
bestBtn.TextColor3 = Color3.new(1, 1, 1)
bestBtn.Font = Enum.Font.FredokaOne
bestBtn.TextSize = 19
bestBtn.Text = "⭐ Equipar melhores"
bestBtn.Parent = petsWin
corner(bestBtn, 10)

local petsHint = label(petsWin, "Clique para equipar/desequipar • ✖ libera o pet (clique 2x)", Enum.Font.Gotham, Color3.fromRGB(170, 170, 200))
petsHint.Size = UDim2.new(1, -240, 0, 18)
petsHint.Position = UDim2.new(0, 226, 1, -40)
petsHint.TextXAlignment = Enum.TextXAlignment.Left

local petsScroll = Instance.new("ScrollingFrame")
petsScroll.Size = UDim2.new(1, -28, 1, -136)
petsScroll.Position = UDim2.fromOffset(14, 72)
petsScroll.BackgroundTransparency = 1
petsScroll.BorderSizePixel = 0
petsScroll.ScrollBarThickness = 6
petsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
petsScroll.CanvasSize = UDim2.new()
petsScroll.Parent = petsWin
local petsGrid = Instance.new("UIGridLayout")
petsGrid.CellSize = UDim2.fromOffset(160, 92)
petsGrid.CellPadding = UDim2.fromOffset(10, 10)
petsGrid.SortOrder = Enum.SortOrder.LayoutOrder
petsGrid.Parent = petsScroll

local function decode(attr: string)
	local ok, value = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute(attr) or "[]")
	end)
	return ok and value or {}
end

local releaseConfirm = { index = 0, at = 0 }
local function rebuildPets()
	for _, c in ipairs(petsScroll:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local pets = decode("PetsJSON")
	local equipped = decode("EquippedJSON")
	local slots = player:GetAttribute("PetSlots") or Config.PET_SLOTS
	local bonus = player:GetAttribute("PetBonus") or 0
	petsTitle.Text = string.format("🐾 Meus Pets (%d/%d)", #pets, Config.PET_INVENTORY)
	petsInfo.Text = string.format("Equipados: %d/%d  •  Bônus total: +%d%% de renda", #equipped, slots, math.floor(bonus * 100 + 0.5))
	-- ordena: equipados primeiro, depois por bônus
	local order = {}
	for i in ipairs(pets) do
		table.insert(order, i)
	end
	table.sort(order, function(a, b)
		local ea, eb = table.find(equipped, a) ~= nil, table.find(equipped, b) ~= nil
		if ea ~= eb then
			return ea
		end
		local ba = Config.PetById[pets[a]] and Config.PetById[pets[a]].Bonus or 0
		local bb = Config.PetById[pets[b]] and Config.PetById[pets[b]].Bonus or 0
		return ba > bb
	end)
	if #pets == 0 then
		local empty = label(petsScroll, "Choque ovos na 🥚 incubadora do seu estúdio para ganhar pets!", Enum.Font.GothamBold, Color3.fromRGB(255, 230, 150))
		empty.Size = UDim2.fromOffset(500, 40)
	end
	for pos, index in ipairs(order) do
		local def = Config.PetById[pets[index]]
		if def then
			local isOn = table.find(equipped, index) ~= nil
			local rarity = Config.RarityById[def.Rarity]
			local cell = Instance.new("TextButton")
			cell.LayoutOrder = pos
			cell.Text = ""
			cell.AutoButtonColor = true
			cell.BackgroundColor3 = isOn and Color3.fromRGB(39, 90, 60) or Color3.fromRGB(40, 42, 60)
			cell.Parent = petsScroll
			corner(cell, 10)
			stroke(cell, rarity and rarity.Color or Color3.new(1, 1, 1), isOn and 3 or 1.5)
			local n = label(cell, def.Name, Enum.Font.FredokaOne, rarity and rarity.Color or Color3.new(1, 1, 1))
			n.Size = UDim2.new(1, -30, 0, 26)
			n.Position = UDim2.fromOffset(8, 6)
			n.TextXAlignment = Enum.TextXAlignment.Left
			local r = label(cell, def.Rarity .. "  •  +" .. math.floor(def.Bonus * 100) .. "%", Enum.Font.GothamBold, Color3.fromRGB(120, 255, 140))
			r.Size = UDim2.new(1, -16, 0, 20)
			r.Position = UDim2.fromOffset(8, 36)
			r.TextXAlignment = Enum.TextXAlignment.Left
			local st = label(cell, isOn and "✔ Equipado" or "Clique para equipar", Enum.Font.Gotham, Color3.fromRGB(210, 210, 230))
			st.Size = UDim2.new(1, -16, 0, 18)
			st.Position = UDim2.fromOffset(8, 64)
			st.TextXAlignment = Enum.TextXAlignment.Left
			cell.MouseButton1Click:Connect(function()
				local ok, msg = petFunc:InvokeServer(isOn and "unequip" or "equip", index)
				if not ok and msg then
					toast(msg, "erro")
				end
			end)
			if def.Rarity ~= "VIP" then
				local del = Instance.new("TextButton")
				del.Size = UDim2.fromOffset(22, 22)
				del.Position = UDim2.new(1, -28, 0, 6)
				del.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
				del.TextColor3 = Color3.new(1, 1, 1)
				del.Font = Enum.Font.GothamBold
				del.TextSize = 14
				del.Text = "✖"
				del.Parent = cell
				corner(del, 6)
				del.MouseButton1Click:Connect(function()
					if releaseConfirm.index == index and os.clock() - releaseConfirm.at < 3 then
						releaseConfirm.index = 0
						petFunc:InvokeServer("delete", index)
					else
						releaseConfirm.index = index
						releaseConfirm.at = os.clock()
						toast("Clique no ✖ de novo para liberar " .. def.Name, "info")
					end
				end)
			end
		end
	end
end

petsBtn.MouseButton1Click:Connect(function()
	rebuildPets()
	toggleWindow(petsWin)
end)
bestBtn.MouseButton1Click:Connect(function()
	petFunc:InvokeServer("best")
end)
for _, attr in ipairs({ "PetsJSON", "EquippedJSON", "PetSlots", "PetBonus" }) do
	player:GetAttributeChangedSignal(attr):Connect(function()
		if petsWin.Visible then
			rebuildPets()
		end
	end)
end

-- animação do ovo chocando
local hatchFrame = panel(UDim2.fromOffset(380, 230), UDim2.fromScale(0.5, 0.45), Vector2.new(0.5, 0.5), Color3.fromRGB(255, 215, 0))
hatchFrame.Visible = false
hatchFrame.ZIndex = 10
local hatchEgg = label(hatchFrame, "🥚", Enum.Font.FredokaOne, Color3.new(1, 1, 1))
hatchEgg.Size = UDim2.new(1, 0, 0, 110)
hatchEgg.Position = UDim2.fromOffset(0, 14)
local hatchName = label(hatchFrame, "", Enum.Font.FredokaOne, Color3.new(1, 1, 1))
hatchName.Size = UDim2.new(1, -20, 0, 44)
hatchName.Position = UDim2.fromOffset(10, 128)
local hatchInfo = label(hatchFrame, "", Enum.Font.GothamBold, Color3.fromRGB(120, 255, 140))
hatchInfo.Size = UDim2.new(1, -20, 0, 26)
hatchInfo.Position = UDim2.fromOffset(10, 178)

hatchEvent.OnClientEvent:Connect(function(id: string)
	local def = Config.PetById[id]
	if not def then
		return
	end
	local rarity = Config.RarityById[def.Rarity]
	hatchFrame.Visible = true
	hatchEgg.Text = "🥚"
	hatchName.Text = "Chocando..."
	hatchName.TextColor3 = Color3.new(1, 1, 1)
	hatchInfo.Text = ""
	for i = 1, 6 do
		hatchEgg.Rotation = (i % 2 == 0) and 12 or -12
		playSound("Error", 1 + i * 0.1)
		task.wait(0.12)
	end
	hatchEgg.Rotation = 0
	hatchEgg.Text = def.Rarity == "Lendário" and "🌟" or (def.Rarity == "Épico" and "✨" or "🐾")
	hatchName.Text = def.Name
	hatchName.TextColor3 = rarity and rarity.Color or Color3.new(1, 1, 1)
	hatchInfo.Text = def.Rarity .. "  •  +" .. math.floor(def.Bonus * 100) .. "% de renda"
	playSound("Buy", def.Rarity == "Lendário" and 0.8 or 1.2)
	task.wait(2.2)
	hatchFrame.Visible = false
end)

-- preço do ovo em cima de cada incubadora (cada jogador vê o seu)
local function setupIncubator(part: Instance)
	if not part:IsA("BasePart") or part.Name ~= "Incubadora" or part:FindFirstChild("PrecoOvo") then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "PrecoOvo"
	bb.Size = UDim2.fromOffset(200, 30)
	bb.StudsOffset = Vector3.new(0, 4.6, 0)
	bb.MaxDistance = 50
	bb.LightInfluence = 0
	bb.Parent = part
	local l = label(bb, "", Enum.Font.FredokaOne, Color3.fromRGB(120, 255, 140))
	l.Size = UDim2.fromScale(1, 1)
	l.TextStrokeTransparency = 0.3
	local function update()
		l.Text = "Preço: " .. Format(Config.EggPrice(player:GetAttribute("IncomeRate") or 0, player:GetAttribute("Rebirths") or 0))
	end
	update()
	player:GetAttributeChangedSignal("IncomeRate"):Connect(update)
	player:GetAttributeChangedSignal("Rebirths"):Connect(update)
end

-- ---------- SKINS ----------
local skinsBtn = sideButton("🎨 Skins", Color3.fromRGB(41, 128, 185), 6)
local skinsWin = window("🎨 Skins do Prédio", 440, 120 + #Config.SKINS * 52, Color3.fromRGB(41, 128, 185))
local skinButtons = {}
for i, skin in ipairs(Config.SKINS) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -28, 0, 44)
	b.Position = UDim2.fromOffset(14, 54 + (i - 1) * 52)
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 19
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Parent = skinsWin
	corner(b, 10)
	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.fromOffset(28, 28)
	swatch.Position = UDim2.fromOffset(8, 8)
	swatch.BackgroundColor3 = skin.Color
	swatch.Parent = b
	corner(swatch, 6)
	b.MouseButton1Click:Connect(function()
		local ok, msg = skinFunc:InvokeServer(skin.Id)
		if msg then
			toast(msg, ok and "compra" or "erro")
		end
	end)
	skinButtons[skin.Id] = b
end
local function refreshSkins()
	local reb = player:GetAttribute("Rebirths") or 0
	local isVip = player:GetAttribute("VIP") == true
	local current = player:GetAttribute("Skin") or "classico"
	for _, skin in ipairs(Config.SKINS) do
		local b = skinButtons[skin.Id]
		local unlocked = Config.SkinUnlocked(skin, reb, isVip)
		local status
		if current == skin.Id then
			status = "✔ Usando"
		elseif unlocked then
			status = "Usar"
		elseif skin.Vip then
			status = "👑 VIP"
		else
			status = "🔒 " .. skin.Rebirths .. " rebirth" .. (skin.Rebirths > 1 and "s" or "")
		end
		b.Text = "      " .. skin.Name .. "   •   " .. status
		b.BackgroundColor3 = current == skin.Id and Color3.fromRGB(39, 174, 96)
			or (unlocked and Color3.fromRGB(52, 73, 94) or Color3.fromRGB(45, 45, 55))
	end
end
skinsBtn.MouseButton1Click:Connect(function()
	refreshSkins()
	toggleWindow(skinsWin)
end)
for _, attr in ipairs({ "Skin", "VIP", "Rebirths" }) do
	player:GetAttributeChangedSignal(attr):Connect(refreshSkins)
end

-- ---------- VIP ----------
local vipBtn = sideButton("👑 VIP", Color3.fromRGB(212, 160, 23), 7)
vipBtn.MouseButton1Click:Connect(function()
	if Config.GAMEPASS_VIP_ID ~= 0 then
		MarketplaceService:PromptGamePassPurchase(player, Config.GAMEPASS_VIP_ID)
	end
end)
local function refreshVip()
	local isVip = player:GetAttribute("VIP") == true
	vipBtn.Visible = Config.GAMEPASS_VIP_ID ~= 0 and not isVip
	local area = workspace:FindFirstChild("AreaVIP")
	local door = area and area:FindFirstChild("PortaVIP")
	if door then
		door.CanCollide = not isVip -- só VIPs passam pela porta
	end
end
refreshVip()
player:GetAttributeChangedSignal("VIP"):Connect(refreshVip)

-- ---------- Dica inicial ----------
local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -24)
hint.Size = UDim2.fromOffset(520, 46)
hint.BackgroundColor3 = Color3.fromRGB(22, 24, 38)
hint.BackgroundTransparency = 0.15
hint.TextColor3 = Color3.fromRGB(255, 230, 120)
hint.Font = Enum.Font.GothamBold
hint.TextScaled = true
hint.Text = "🎮 Siga a seta e toque na porta azul de um estúdio livre para ser o dono!"
hint.Parent = gui
corner(hint, 12)
local hintPad = Instance.new("UIPadding")
hintPad.PaddingLeft = UDim.new(0, 12)
hintPad.PaddingRight = UDim.new(0, 12)
hintPad.PaddingTop = UDim.new(0, 6)
hintPad.PaddingBottom = UDim.new(0, 6)
hintPad.Parent = hint

-- ---------- Seta guia (leva até a porta livre ou até a próxima compra) ----------
local beam = Instance.new("Beam")
beam.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(110, 255, 140))
beam.LightEmission = 1
beam.FaceCamera = true
beam.Width0 = 0.8
beam.Width1 = 0.8
beam.Segments = 20
beam.Transparency = NumberSequence.new(0.15)
beam.Enabled = false
beam.Parent = workspace
local targetAttachment = Instance.new("Attachment")
targetAttachment.Name = "AlvoGuia"
targetAttachment.Parent = workspace.Terrain

local function findGuideTarget(): BasePart?
	local tycoons = workspace:FindFirstChild("Tycoons")
	if not tycoons then
		return nil
	end
	local plotName = player:GetAttribute("PlotName")
	if not plotName then
		-- porta livre mais próxima
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local best, bestDist = nil, math.huge
		for _, plot in ipairs(tycoons:GetChildren()) do
			local door = plot:FindFirstChild("Base") and plot.Base:FindFirstChild("Porta")
			if door and (door:GetAttribute("Owner") or "") == "" then
				local d = root and (door.Position - root.Position).Magnitude or 0
				if d < bestDist then
					best, bestDist = door, d
				end
			end
		end
		return best
	end
	local goalId = player:GetAttribute("NextGoalId") or ""
	local price = player:GetAttribute("NextPrice") or 0
	local ls = player:FindFirstChild("leaderstats")
	local cash = ls and ls:FindFirstChild("Dinheiro")
	if goalId == "" or not cash or cash.Value < price then
		return nil
	end
	local plot = tycoons:FindFirstChild(plotName)
	local buttons = plot and plot:FindFirstChild("Buttons")
	return buttons and buttons:FindFirstChild(goalId)
end

task.spawn(function()
	while true do
		task.wait(0.3)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local target = findGuideTarget()
		if root and target and (target.Position - root.Position).Magnitude > 8 then
			local a0 = root:FindFirstChild("GuiaOrigem")
			if not a0 then
				a0 = Instance.new("Attachment")
				a0.Name = "GuiaOrigem"
				a0.Position = Vector3.new(0, -2, 0)
				a0.Parent = root
			end
			targetAttachment.WorldPosition = target.Position + Vector3.new(0, 1, 0)
			beam.Attachment0 = a0
			beam.Attachment1 = targetAttachment
			beam.Enabled = true
		else
			beam.Enabled = false
		end
	end
end)

-- ---------- Funcionários "digitando" ----------
local function animateArm(part: Instance)
	if not part:IsA("BasePart") or (part.Name ~= "NPC_BracoE" and part.Name ~= "NPC_BracoD") then
		return
	end
	task.defer(function()
		if not part.Parent then
			return
		end
		-- espera a animação de construção terminar antes de pegar a posição
		task.wait(2 + (part.Name == "NPC_BracoE" and 0 or 0.18) + math.random() * 0.3)
		if part.Parent then
			local base = part.CFrame
			TweenService:Create(part, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ CFrame = base * CFrame.new(0, 0.18, 0) }):Play()
		end
	end)
end
local tycoonsFolder = workspace:WaitForChild("Tycoons")
for _, d in ipairs(tycoonsFolder:GetDescendants()) do
	animateArm(d)
	setupIncubator(d)
end
tycoonsFolder.DescendantAdded:Connect(function(d)
	animateArm(d)
	setupIncubator(d)
end)

-- ---------- Atualização ----------
local ls = player:WaitForChild("leaderstats")
local cashValue = ls:WaitForChild("Dinheiro")

local function refresh()
	cashLabel.Text = Format(cashValue.Value)
	local mult = player:GetAttribute("Multiplier") or 1
	local reb = player:GetAttribute("Rebirths") or 0
	local rate = player:GetAttribute("IncomeRate") or 0
	infoLabel.Text = string.format("%s/s  •  x%.1f  •  Rebirths: %d", Format(rate), mult, reb)

	local hasPlot = player:GetAttribute("PlotName") ~= nil
	local goal = player:GetAttribute("NextGoal") or ""
	local price = player:GetAttribute("NextPrice") or 0
	goalFrame.Visible = goal ~= "" and hasPlot
	if goalFrame.Visible then
		local ratio = price > 0 and math.clamp(cashValue.Value / price, 0, 1) or 1
		goalLabel.Text = (ratio >= 1 and "✅ Pode comprar: " or "🎯 Próxima meta: ") .. goal .. " (" .. Format(price) .. ")"
		TweenService:Create(goalFill, TweenInfo.new(0.2), { Size = UDim2.fromScale(ratio, 1) }):Play()
		goalFill.BackgroundColor3 = ratio >= 1 and Color3.fromRGB(255, 210, 63) or Color3.fromRGB(110, 255, 140)
	end

	local mText = player:GetAttribute("MissionText") or ""
	missionFrame.Visible = mText ~= "" and hasPlot
	if missionFrame.Visible then
		local value = player:GetAttribute("MissionValue") or 0
		local mGoal = math.max(player:GetAttribute("MissionGoal") or 1, 1)
		missionTitle.Text = "📋 MISSÃO " .. tostring(player:GetAttribute("MissionIndex") or 1) .. "/" .. #Config.MISSIONS
		missionText.Text = mText
		missionProgress.Text = string.format("%s / %s  •  Prêmio: %s",
			value >= 1000 and Format(value):sub(2) or tostring(math.floor(value)),
			mGoal >= 1000 and Format(mGoal):sub(2) or tostring(mGoal),
			Format(player:GetAttribute("MissionReward") or 0))
		TweenService:Create(missionFill, TweenInfo.new(0.2), { Size = UDim2.fromScale(math.clamp(value / mGoal, 0, 1), 1) }):Play()
	end

	local canRebirth = player:GetAttribute("CanRebirth") == true
	rebirthBtn.BackgroundColor3 = canRebirth and Color3.fromRGB(155, 89, 182) or Color3.fromRGB(110, 110, 130)
	if canRebirth then
		pulse:Play()
	else
		pulse:Cancel()
		rebirthScale.Scale = 1
	end
	pass2xBtn.Visible = Config.GAMEPASS_2X_ID ~= 0 and not player:GetAttribute("Has2x")
	passAutoBtn.Visible = Config.GAMEPASS_AUTOCOLLECT_ID ~= 0 and not player:GetAttribute("AutoCollect")
	hint.Visible = not hasPlot
end

local lastCash = cashValue.Value
cashValue.Changed:Connect(function(v)
	if v > lastCash then
		local up = TweenService:Create(cashLabel, TweenInfo.new(0.08), { TextColor3 = Color3.fromRGB(255, 255, 140) })
		up:Play()
		up.Completed:Connect(function()
			TweenService:Create(cashLabel, TweenInfo.new(0.25), { TextColor3 = Color3.fromRGB(110, 255, 140) }):Play()
		end)
	end
	lastCash = v
	refresh()
end)
player.AttributeChanged:Connect(refresh)
refresh()

-- contagem do HYPE
RunService.Heartbeat:Connect(function()
	local left = (workspace:GetAttribute("HypeUntil") or 0) - workspace:GetServerTimeNow()
	if left > 0 then
		hypeFrame.Visible = true
		hypeLabel.Text = string.format("🔥 HYPE! Tudo vale %dx  •  0:%02d", Config.HYPE_MULT, math.ceil(left))
	else
		hypeFrame.Visible = false
	end
end)
