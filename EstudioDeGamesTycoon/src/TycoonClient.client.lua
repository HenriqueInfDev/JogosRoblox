-- ============================================================
--  ESTÚDIO DE GAMES TYCOON - Interface do jogador
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("TycoonConfig"))
local Format = Config.Format
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyEvent = remotes:WaitForChild("Notify")
local rebirthFunc = remotes:WaitForChild("Rebirth")

local gui = Instance.new("ScreenGui")
gui.Name = "TycoonHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

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

-- ---------- Painel de dinheiro ----------
local cashFrame = Instance.new("Frame")
cashFrame.AnchorPoint = Vector2.new(0.5, 0)
cashFrame.Position = UDim2.new(0.5, 0, 0, 8)
cashFrame.Size = UDim2.fromOffset(280, 70)
cashFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 38)
cashFrame.BackgroundTransparency = 0.1
cashFrame.Parent = gui
corner(cashFrame, 16)
stroke(cashFrame, Color3.fromRGB(155, 89, 182), 3)

local cashLabel = label(cashFrame, "$0", Enum.Font.FredokaOne, Color3.fromRGB(110, 255, 140))
cashLabel.Size = UDim2.new(1, -20, 0.6, 0)
cashLabel.Position = UDim2.new(0, 10, 0, 4)

local infoLabel = label(cashFrame, "x1.0 • Rebirths: 0", Enum.Font.GothamBold, Color3.fromRGB(200, 200, 230))
infoLabel.Size = UDim2.new(1, -20, 0.3, 0)
infoLabel.Position = UDim2.new(0, 10, 0.62, 0)

-- ---------- Próxima meta ----------
local goalFrame = Instance.new("Frame")
goalFrame.AnchorPoint = Vector2.new(0.5, 0)
goalFrame.Position = UDim2.new(0.5, 0, 0, 84)
goalFrame.Size = UDim2.fromOffset(280, 44)
goalFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 38)
goalFrame.BackgroundTransparency = 0.1
goalFrame.Visible = false
goalFrame.Parent = gui
corner(goalFrame, 12)

local goalLabel = label(goalFrame, "", Enum.Font.GothamBold, Color3.new(1, 1, 1))
goalLabel.Size = UDim2.new(1, -16, 0, 18)
goalLabel.Position = UDim2.fromOffset(8, 4)

local barBack = Instance.new("Frame")
barBack.Size = UDim2.new(1, -16, 0, 12)
barBack.Position = UDim2.fromOffset(8, 26)
barBack.BackgroundColor3 = Color3.fromRGB(50, 52, 70)
barBack.Parent = goalFrame
corner(barBack, 6)
local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = Color3.fromRGB(110, 255, 140)
barFill.Parent = barBack
corner(barFill, 6)

-- ---------- Notificações ----------
local toastHolder = Instance.new("Frame")
toastHolder.AnchorPoint = Vector2.new(0.5, 0)
toastHolder.Position = UDim2.new(0.5, 0, 0, 136)
toastHolder.Size = UDim2.fromOffset(380, 220)
toastHolder.BackgroundTransparency = 1
toastHolder.Parent = gui
local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 6)
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toastHolder

local TOAST_COLORS = {
	ok = Color3.fromRGB(39, 174, 96),
	erro = Color3.fromRGB(192, 57, 43),
	info = Color3.fromRGB(41, 128, 185),
}
local toastCount = 0

local function toast(text: string, kind: string?)
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
	t.BackgroundColor3 = TOAST_COLORS[kind or "info"] or TOAST_COLORS.info
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 17
	t.TextWrapped = true
	t.Text = text
	t.Parent = toastHolder
	corner(t, 10)
	task.delay(3.2, function()
		if t.Parent then
			local tw = TweenService:Create(t, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 })
			tw:Play()
			tw.Completed:Wait()
			t:Destroy()
		end
	end)
end

notifyEvent.OnClientEvent:Connect(toast)

-- ---------- Botões laterais ----------
local side = Instance.new("Frame")
side.AnchorPoint = Vector2.new(0, 0.5)
side.Position = UDim2.new(0, 12, 0.5, 0)
side.Size = UDim2.fromOffset(200, 200)
side.BackgroundTransparency = 1
side.Parent = gui
local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 8)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Parent = side

local function sideButton(text: string, color: Color3, order: number)
	local b = Instance.new("TextButton")
	b.LayoutOrder = order
	b.Size = UDim2.new(1, 0, 0, 50)
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 22
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

local confirmUntil = 0
rebirthBtn.MouseButton1Click:Connect(function()
	if not player:GetAttribute("CanRebirth") then
		toast("Compre o 🏆 Troféu Game of the Year para liberar o Rebirth!", "erro")
		return
	end
	if os.clock() > confirmUntil then
		confirmUntil = os.clock() + 4
		local bonus = math.floor(Config.REBIRTH_BONUS * 100)
		toast("Clique de novo para confirmar: você perde tudo e ganha +" .. bonus .. "% de renda para sempre", "info")
		return
	end
	confirmUntil = 0
	local ok, msg = rebirthFunc:InvokeServer()
	toast(msg or "", ok and "ok" or "erro")
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

local shop = Instance.new("Frame")
shop.AnchorPoint = Vector2.new(0.5, 0.5)
shop.Position = UDim2.fromScale(0.5, 0.5)
shop.Size = UDim2.fromOffset(340, 90 + #activeProducts * 64)
shop.BackgroundColor3 = Color3.fromRGB(22, 24, 38)
shop.Visible = false
shop.Parent = gui
corner(shop, 16)
stroke(shop, Color3.fromRGB(39, 174, 96), 3)

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
		local amount = product.Amount * (1 + (player:GetAttribute("Rebirths") or 0))
		b.Text = "💰 " .. product.Name .. "  •  +" .. Format(amount)
	end
	updateText()
	player:GetAttributeChangedSignal("Rebirths"):Connect(updateText)
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
hint.Text = "🎮 Encontre um estúdio livre e toque na porta azul para ser o dono!"
hint.Parent = gui
corner(hint, 12)
local hintPad = Instance.new("UIPadding")
hintPad.PaddingLeft = UDim.new(0, 12)
hintPad.PaddingRight = UDim.new(0, 12)
hintPad.PaddingTop = UDim.new(0, 6)
hintPad.PaddingBottom = UDim.new(0, 6)
hintPad.Parent = hint

-- ---------- Atualização ----------
local ls = player:WaitForChild("leaderstats")
local cashValue = ls:WaitForChild("Dinheiro")

local function refresh()
	cashLabel.Text = Format(cashValue.Value)
	local mult = player:GetAttribute("Multiplier") or 1
	local reb = player:GetAttribute("Rebirths") or 0
	local rate = player:GetAttribute("IncomeRate") or 0
	infoLabel.Text = string.format("%s/s  •  x%.1f  •  Rebirths: %d", Format(rate), mult, reb)
	local goal = player:GetAttribute("NextGoal") or ""
	local price = player:GetAttribute("NextPrice") or 0
	goalFrame.Visible = goal ~= "" and player:GetAttribute("PlotName") ~= nil
	if goalFrame.Visible then
		local ratio = price > 0 and math.clamp(cashValue.Value / price, 0, 1) or 1
		goalLabel.Text = (ratio >= 1 and "✅ Pode comprar: " or "🎯 Próxima meta: ") .. goal .. " (" .. Format(price) .. ")"
		TweenService:Create(barFill, TweenInfo.new(0.2), { Size = UDim2.fromScale(ratio, 1) }):Play()
		barFill.BackgroundColor3 = ratio >= 1 and Color3.fromRGB(255, 210, 63) or Color3.fromRGB(110, 255, 140)
	end
	rebirthBtn.BackgroundColor3 = player:GetAttribute("CanRebirth") and Color3.fromRGB(155, 89, 182)
		or Color3.fromRGB(110, 110, 130)
	pass2xBtn.Visible = Config.GAMEPASS_2X_ID ~= 0 and not player:GetAttribute("Has2x")
	passAutoBtn.Visible = Config.GAMEPASS_AUTOCOLLECT_ID ~= 0 and not player:GetAttribute("AutoCollect")
	hint.Visible = player:GetAttribute("PlotName") == nil
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
