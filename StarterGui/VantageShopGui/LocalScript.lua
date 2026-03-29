local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local Rep = game:GetService("ReplicatedStorage")
local gui = script.Parent

-- 🚪 ESTADO INICIAL
gui.Enabled = true 
local menu = gui:WaitForChild("Menu")
local btnAbrirInv = gui:WaitForChild("BotaoAbrirInv")

-- REFERÊNCIA DA VALIDAÇÃO (ARENA)
local checarVantagemRF = Rep:WaitForChild("ChecarVantagem")

-- O Botão nunca deve sumir, então garantimos a visibilidade aqui
menu.Visible = false
btnAbrirInv.Visible = true

-------------------------------------------------
-- 📱 CONFIGURAÇÃO EXCLUSIVA PARA CELULAR (MOBILE RULES)
-------------------------------------------------
-- AnchorPoint 0.5 garante que o botão cresça do centro, sem sair da tela
btnAbrirInv.AnchorPoint = Vector2.new(0.5, 0.5)

-- Size e Position em SCALE para adaptar a qualquer resolução de celular
btnAbrirInv.Size = UDim2.new(0.15, 0, 0.05, 0) 
-- Posição 60% horizontal e 15% vertical conforme seu último ajuste
btnAbrirInv.Position = UDim2.new(0.60, 0, 0.15, 0)

-- TextScaled ativado para o texto não vazar em telas pequenas
btnAbrirInv.TextScaled = true

-- UIAspectRatioConstraint impede que o botão fique "achatado" em tablets
local aspect = btnAbrirInv:FindFirstChild("UIAspectRatioConstraint") or Instance.new("UIAspectRatioConstraint", btnAbrirInv)
aspect.AspectRatio = 3 

-------------------------------------------------
-- 🚀 CONFIGURAÇÃO GERAL (Nomes e Preços)
-------------------------------------------------
local NOMES = { Vantage1 = "REVELAR", Vantage2 = "ELIMINAR", Vantage3 = "TEMPO" }
local PRECOS = { Vantage1 = 50, Vantage2 = 30, Vantage3 = 15 }

local frameLoja = menu:WaitForChild("FrameLoja")
local frameInv = menu:WaitForChild("FrameInventario")

-- 📂 NOVO CAMINHO DOS TEXTOS (Dentro do FramePainel)
local framePainel = menu:WaitForChild("FramePainel")
local txtResto = framePainel:WaitForChild("TextoResto")
local txtUtilizado = framePainel:WaitForChild("TextoUtilizado")
local txtSaldoTotal = framePainel:WaitForChild("TextoSaldo")

-- 📂 DADOS
local leaderstats = player:WaitForChild("leaderstats", 15)
local acertos = player:WaitForChild("AcertosPorSerie", 15)
local statsLoja = player:WaitForChild("StatsLoja", 15)
local inv = player:WaitForChild("VantageInventory", 15)

-------------------------------------------------
-- 📊 FUNÇÃO DE ATUALIZAÇÃO DOS PAINÉIS
-------------------------------------------------
local function atualizarPaineis()
	if not leaderstats or not acertos or not statsLoja then return 0 end

	local s6 = acertos:FindFirstChild("Serie6") and acertos.Serie6.Value or 0
	local s7 = acertos:FindFirstChild("Serie7") and acertos.Serie7.Value or 0
	local s8 = acertos:FindFirstChild("Serie8") and acertos.Serie8.Value or 0
	local s9 = acertos:FindFirstChild("Serie9") and acertos.Serie9.Value or 0
	local camp = leaderstats:FindFirstChild("Camp") and leaderstats.Camp.Value or 0
	local gastoNum = statsLoja:FindFirstChild("SaldoUtilizado") and statsLoja.SaldoUtilizado.Value or 0

	local total = s6 + s7 + s8 + s9 + camp
	local resto = total - gastoNum

	txtSaldoTotal.TextScaled = true
	txtSaldoTotal.Text = "  Saldo   Total: " .. total .. " Pts" 

	txtUtilizado.TextScaled = true
	txtUtilizado.Text = "Saldo   Utilizado: ".. gastoNum .." Pts" 

	txtResto.TextScaled = true
	txtResto.Text = "Resto p/ Utilizar: ".. resto .." Pts" 

	return resto
end

-------------------------------------------------
-- ⚠️ AVISO DE SALDO PISCANTE
-------------------------------------------------
local aviso = gui:FindFirstChild("AvisoSaldo")
if not aviso then
	aviso = Instance.new("TextLabel")
	aviso.Name = "AvisoSaldo"; aviso.Parent = gui; aviso.Size = UDim2.new(0, 320, 0, 90)
	aviso.Position = UDim2.new(0.5, -160, 0.5, -45); aviso.BackgroundColor3 = Color3.fromRGB(255, 230, 0)
	aviso.Text = "SALDO INSUFICIENTE!"; aviso.TextColor3 = Color3.fromRGB(0, 0, 0)
	aviso.Font = Enum.Font.FredokaOne; aviso.TextSize = 28; aviso.Visible = false; aviso.ZIndex = 10
	aviso.TextScaled = true 
	Instance.new("UICorner", aviso).CornerRadius = UDim.new(0, 20)
end

local function mostrarAviso(msg)
	if aviso.Visible then return end
	aviso.Text = msg
	aviso.Visible = true
	task.spawn(function()
		for i = 1, 6 do
			aviso.BackgroundColor3 = Color3.fromRGB(255, 255, 255); task.wait(0.1)
			aviso.BackgroundColor3 = Color3.fromRGB(255, 230, 0); task.wait(0.1)
		end
		task.wait(1.5); aviso.Visible = false
	end)
end

-------------------------------------------------
-- ⌨️ INTERAÇÃO (X, Proximity e TOUCH)
-------------------------------------------------

local function toggleInventario()
	if menu.Visible and frameInv.Visible then
		menu.Visible = false
	else
		menu.Visible = true
		frameLoja.Visible = false
		frameInv.Visible = true
		atualizarPaineis()
	end
end

-- activated para celular
btnAbrirInv.Activated:Connect(toggleInventario)

UIS.InputBegan:Connect(function(input, proc)
	if proc then return end
	if input.KeyCode == Enum.KeyCode.X then
		toggleInventario()
	end
end)

task.spawn(function()
	local shopModel = workspace:WaitForChild("Shop", 15)
	local prompt = shopModel and shopModel:FindFirstChildWhichIsA("ProximityPrompt", true)

	if prompt then
		prompt.Triggered:Connect(function()
			menu.Visible = true
			frameLoja.Visible = true
			frameInv.Visible = false
			atualizarPaineis()

			task.spawn(function()
				while menu.Visible and frameLoja.Visible do
					if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						local dist = (player.Character.HumanoidRootPart.Position - prompt.Parent.Position).Magnitude
						if dist > 15 then 
							menu.Visible = false
							break
						end
					end
					task.wait(0.5)
				end
			end)
		end)
	end
end)

-------------------------------------------------
-- 🛒 CONFIGURAÇÃO DOS BOTÕES
-------------------------------------------------
for i = 1, 3 do
	local itemID = "Vantage"..i
	local bB = frameLoja:FindFirstChild("BuyV"..i)
	local bU = frameInv:FindFirstChild("UseV"..i)
	local preco = PRECOS[itemID]

	if bB then
		bB.TextScaled = true
		bB.Text = NOMES[itemID] .. " (" .. preco .. " Pts)"
		bB.MouseButton1Click:Connect(function()
			if atualizarPaineis() >= preco then 
				Rep.BuyVantage:FireServer(itemID)
			else 
				mostrarAviso("SALDO INSUFICIENTE!") 
			end
		end)
	end

	if bU then
		bU.TextScaled = true
		local val = inv and inv:WaitForChild(itemID, 10)
		local function atualizarBotaoUso()
			if val then
				bU.Text = "USAR " .. NOMES[itemID] .. "    (x" .. val.Value .. ")  "
				bU.BackgroundColor3 = (val.Value > 0) and Color3.fromRGB(85, 255, 127) or Color3.fromRGB(255, 255, 255)
			end
		end

		if val then
			val.Changed:Connect(atualizarBotaoUso)
			atualizarBotaoUso()
		end

		bU.MouseButton1Click:Connect(function() 
			-- Verifica se já usou 4 antes de perguntar ao servidor
			local jaUsados = player:GetAttribute("VantagensUsadas") or 0
			if jaUsados >= 4 then
				mostrarAviso("LIMITE DE 4 USOS ATINGIDO!")
				return
			end

			-- FILTRO: VERIFICAÇÃO NA ARENA
			local podeUsar, erro = checarVantagemRF:InvokeServer()
			if podeUsar then
				Rep.UseVantage:FireServer(itemID) 
			else
				mostrarAviso(string.upper(erro))
			end
		end)
	end
end

-------------------------------------------------
-- ⚡ SINCRONIZAÇÃO EM TEMPO REAL
-------------------------------------------------
if acertos then
	for _, v in pairs(acertos:GetChildren()) do v.Changed:Connect(atualizarPaineis) end
end
if leaderstats and leaderstats:FindFirstChild("Camp") then 
	leaderstats.Camp.Changed:Connect(atualizarPaineis) 
end
if statsLoja and statsLoja:FindFirstChild("SaldoUtilizado") then 
	statsLoja.SaldoUtilizado.Changed:Connect(atualizarPaineis) 
end

-------------------------------------------------
-- ✨ RECEPTOR DA VANTAGEM REVELAR (PRIVADO)
-------------------------------------------------
local eventoRevelarPrivado = Rep:WaitForChild("RevelarParaPlayer")

eventoRevelarPrivado.OnClientEvent:Connect(function(blocoCorreto)
	if blocoCorreto then
		-- 1. Cria o Efeito de Brilho LOCALMENTE (só você vê)
		local high = Instance.new("Highlight")
		high.Parent = blocoCorreto
		high.FillColor = Color3.fromRGB(0, 255, 0) -- Verde
		high.OutlineColor = Color3.fromRGB(255, 255, 255) -- Branco
		high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

		-- 2. Som Mágico Local
		local somMagico = Instance.new("Sound", blocoCorreto)
		somMagico.SoundId = "rbxassetid://131070686"
		somMagico.Volume = 1.5
		somMagico:Play()

		-- 3. Limpeza Local após 5 segundos
		task.delay(5, function()
			if high then high:Destroy() end
			if somMagico then somMagico:Destroy() end
		end)
	end
end)

task.wait(0.1)
atualizarPaineis()