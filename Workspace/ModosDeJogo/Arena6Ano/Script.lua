local workspace = game.Workspace
local players = game.Players
local DataStoreService = game:GetService("DataStoreService")

-- ==========================================
-- 1. CONFIGURAÇÕES E BANCO DE DADOS
-- ==========================================
local rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5")
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5")

local arenaFolder = script.Parent 
local questionBoard = arenaFolder:WaitForChild("QuestionBoard6")
local timerBoard = arenaFolder:WaitForChild("TimerBoard6")
local answersFolder = arenaFolder:WaitForChild("Answers")
local centroArenaPart = arenaFolder:WaitForChild("CentroDaArena")

-- Referências para o Teletransporte
local saidaPart = arenaFolder:WaitForChild("SaidaArena6")
local destinoLobby = arenaFolder:WaitForChild("DestinoLobby")

local questionLabel = questionBoard.SurfaceGui.TextLabel
local timerLabel = timerBoard.SurfaceGui.TextLabel

-- Referências dos Sons
local tickSound = timerBoard:FindFirstChild("TickSound")
local buzzerSound = timerBoard:FindFirstChild("BuzzerSound")
local start = timerBoard:FindFirstChild("Start")
local aplausos4S = timerBoard:FindFirstChild("Aplausos4S")
local narracaoGalvaoBueno45S = timerBoard:FindFirstChild("NarracaoGalvaoBueno45S")
local narracaoGalvaoBueno30S = timerBoard:FindFirstChild("NarracaoGalvaoBueno30S")
local narracaoGalvaoBueno20S = timerBoard:FindFirstChild("NarracaoGalvaoBueno20S")

local ehDecimal = false
local rodadaAtiva = false
local respostaCorreta = 0

local CoresAleatorias = {
	Color3.fromRGB(255, 85, 0), Color3.fromRGB(0, 170, 255),
	Color3.fromRGB(85, 255, 127), Color3.fromRGB(255, 170, 0),
	Color3.fromRGB(170, 85, 255), Color3.fromRGB(0, 255, 255)
}

-- ==========================================
-- ESTILIZAÇÃO DO TIMERBOARD (AZUL NEON BRILHANTE)
-- ==========================================
local uiStrokeT = timerLabel:FindFirstChild("UIStroke") or Instance.new("UIStroke", timerLabel)
local uiGradientT = timerLabel:FindFirstChild("UIGradient") or Instance.new("UIGradient", timerLabel)

timerLabel.Size = UDim2.new(1, 0, 1, 0)
timerLabel.Position = UDim2.new(0, 0, 0, 0)
timerLabel.TextXAlignment = Enum.TextXAlignment.Center
timerLabel.TextYAlignment = Enum.TextYAlignment.Center
timerLabel.TextScaled = true
timerLabel.BackgroundColor3 = Color3.fromRGB(0, 85, 255) 
timerLabel.BackgroundTransparency = 0 
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255) 
timerLabel.Font = Enum.Font.LuckiestGuy 

uiStrokeT.Color = Color3.fromRGB(0, 255, 255) 
uiStrokeT.Thickness = 10
uiStrokeT.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

uiGradientT.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 85, 255))
})
uiGradientT.Rotation = 90

-- ==========================================
-- ESTILIZAÇÃO DO QUESTIONBOARD (VERDE TECNOLÓGICO)
-- ==========================================
local uiStrokeQ = questionLabel:FindFirstChild("UIStroke") or Instance.new("UIStroke", questionLabel)
local uiGradientQ = questionLabel:FindFirstChild("UIGradient") or Instance.new("UIGradient", questionLabel)

questionLabel.Size = UDim2.new(1, 0, 1, 0)
questionLabel.TextScaled = true
questionLabel.BackgroundColor3 = Color3.fromRGB(0, 40, 0) 
questionLabel.TextColor3 = Color3.fromRGB(255, 170, 0) 
questionLabel.Font = Enum.Font.LuckiestGuy 

uiStrokeQ.Color = Color3.fromRGB(0, 255, 127) 
uiStrokeQ.Thickness = 9
uiStrokeQ.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

uiGradientQ.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 50, 0))
})
uiGradientQ.Rotation = 90

saidaPart.Material = Enum.Material.Neon
-- saidaPart.Color = Color3.fromRGB(0, 255, 127)  Isolado essa linha par que o timeboard fique com a testura

local rodadaAtiva = false
local respostaCorreta = 0

local CoresAleatorias = {
	Color3.fromRGB(255, 85, 0), Color3.fromRGB(0, 170, 255),
	Color3.fromRGB(85, 255, 127), Color3.fromRGB(255, 170, 0),
	Color3.fromRGB(170, 85, 255), Color3.fromRGB(0, 255, 255)
}

-- ==========================================
-- 2. FUNÇÕES E TELETRANSPORTE
-- ==========================================
local function faxinaGeral()
	for _, desc in pairs(arenaFolder:GetDescendants()) do
		if desc:IsA("TextLabel") then desc.Text = "" end
	end
end
faxinaGeral() 

saidaPart.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = players:GetPlayerFromCharacter(character)
	if player and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = destinoLobby.CFrame + Vector3.new(0, 3, 0)
		player:SetAttribute("EscolhaCorreta", nil)
	end
end)

-- ==========================================
-- 2. FUNÇÕES AUXILIARES
-- ==========================================
local function faxinaGeral()
	for _, desc in pairs(arenaFolder:GetDescendants()) do
		if desc:IsA("TextLabel") then desc.Text = "" end
	end
end
faxinaGeral() 

saidaPart.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = players:GetPlayerFromCharacter(character)
	if player and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = destinoLobby.CFrame + Vector3.new(0, 3, 0)
		player:SetAttribute("EscolhaCorreta", nil)
	end
end)

-- ==========================================
-- 3. GERADOR TOTAL ALEATÓRIO (6º ANO)
-- ==========================================
local Geradores6Ano = {
	Facil = { 
		tempo = 20, 
		f = function() 
			ehDecimal = false
			local tipo = math.random(1, 4)
			if tipo == 1 then -- Adição/Subtração
				local a, b = math.random(10, 100), math.random(10, 100)
				return {txt=a.." + "..b, res=a+b}
			elseif tipo == 2 then -- Negativos Básicos
				local a, b = math.random(1, 10), math.random(11, 25)
				return {txt=a.." - "..b, res=a-b}
			elseif tipo == 3 then -- Multiplicação Base 10
				local a = math.random(1, 50)
				return {txt=a.." x 10", res=a*10}
			else -- Dobro/Metade
				local a = math.random(2, 100) * 2
				return {txt="Metade de "..a, res=a/2}
			end
		end 
	},
	Medio = { 
		tempo = 30, 
		f = function() 
			local tipo = math.random(1, 5)
			ehDecimal = false
			if tipo == 1 then -- Potência
				local a = math.random(2, 12)
				return {txt=a.."²", res=a*a}
			elseif tipo == 2 then -- Expressão Simples
				local a, b, c = math.random(2, 5), math.random(2, 5), math.random(1, 10)
				return {txt=a.." x "..b.." + "..c, res=(a*b)+c}
			elseif tipo == 3 then -- Perímetro
				local l = math.random(5, 15)
				return {txt="Perímetro Quadrado Lado "..l, res=l*4}
			elseif tipo == 4 then -- Multiplicação Negativos
				local a = math.random(2, 6); local b = math.random(-10, -2)
				return {txt=a.." x ("..b..")", res=a*b}
			else -- Porcentagem 50%
				local a = math.random(1, 20) * 10
				return {txt="50% de "..a, res=a/2}
			end
		end 
	},
	Dificil = { 
		tempo = 45, 
		f = function() 
			local tipo = math.random(1, 5)
			if tipo == 1 then -- R$ DINHEIRO (ATIVA 2 CASAS)
				ehDecimal = true
				local a, b = math.random(100, 900)/100, math.random(50, 500)/100
				return {txt="R$ "..string.format("%.2f", a).." + R$ "..string.format("%.2f", b), res=a+b}
			elseif tipo == 2 then -- ÁREA
				ehDecimal = false
				local b, h = math.random(5, 12), math.random(3, 8)
				return {txt="Área Retângulo "..b.."x"..h, res=b*h}
			elseif tipo == 3 then -- DIVISÃO
				ehDecimal = false
				local b = math.random(5, 15); local res = math.random(10, 25)
				return {txt=(b*res).." ÷ "..b, res=res}
			elseif tipo == 4 then -- SALDO NEGATIVO (2 CASAS)
				ehDecimal = true
				local s = math.random(-200, 100)/100; local d = math.random(100, 300)/100
				return {txt="Saldo R$ "..string.format("%.2f", s).." | Tirou R$ "..string.format("%.2f", d), res=s-d}
			else -- EXPRESSÃO COMPLEXA
				ehDecimal = false
				local a = math.random(-5, -1); local b = math.random(2, 4)
				return {txt="("..a.." x "..b..") + 20", res=(a*b)+20}
			end
		end 
	}
}

-- ==========================================
-- 4. DETECÇÃO DE TOQUE (36 BLOCOS)
-- ==========================================
for i = 1, 36 do
	local b = answersFolder:FindFirstChild("Answer"..i)
	if b then
		b.Touched:Connect(function(hit)
			if not rodadaAtiva then return end
			local p = players:GetPlayerFromCharacter(hit.Parent)
			if p then 
				-- Salva se o jogador pisou no bloco certo ou errado
				p:SetAttribute("EscolhaCorreta", b:GetAttribute("Correta")) 
			end
		end)
	end
end

-- ==========================================
-- 5. LOOP PRINCIPAL COM PROTEÇÃO CONTRA TRAVAS
-- ==========================================
while true do
	local ativos = {}
	for _, p in pairs(players:GetPlayers()) do
		local char = p.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local dist = (char.HumanoidRootPart.Position - centroArenaPart.Position).Magnitude
			if dist <= 130 then 
				table.insert(ativos, p)
				p:SetAttribute("EscolhaCorreta", nil) -- Reseta a escolha
			end
		end
	end

	if #ativos > 0 then
		faxinaGeral()
		questionLabel.Text = "PREPARE-SE (6º ANO)!"
		if start then start:Play() end
		task.wait(2) -- Tempo de espera inicial

		local niveis = {"Facil", "Medio", "Dificil"}
		local nivelEscolhido = niveis[math.random(1, #niveis)] 

		-- Narrações
		if nivelEscolhido == "Dificil" and narracaoGalvaoBueno45S then narracaoGalvaoBueno45S:Play()
		elseif nivelEscolhido == "Medio" and narracaoGalvaoBueno30S then narracaoGalvaoBueno30S:Play()
		elseif nivelEscolhido == "Facil" and narracaoGalvaoBueno20S then narracaoGalvaoBueno20S:Play() end

		local dados = Geradores6Ano[nivelEscolhido]
		local q = dados.f()
		questionLabel.Text = q.txt
		respostaCorreta = q.res

		-- Gerador de Respostas com trava de segurança (previne loop infinito)
		local baseRespostas = {}
		local posCertaBase = math.random(1, 9)
		local valoresUsados = {[respostaCorreta] = true}

		for i = 1, 9 do
			if i == posCertaBase then
				baseRespostas[i] = respostaCorreta
			else
				local valorErrado
				local tentativas = 0
				repeat 
					tentativas += 1
					if ehDecimal then
						valorErrado = tonumber(string.format("%.2f", respostaCorreta + (math.random(-500, 500)/100)))
					else
						valorErrado = math.random(respostaCorreta - 30, respostaCorreta + 30)
					end
				until not valoresUsados[valorErrado] or tentativas > 10
				valoresUsados[valorErrado] = true
				baseRespostas[i] = valorErrado
			end
		end

		-- Atualiza os blocos no mapa
		for i = 1, 36 do
			local b = answersFolder:FindFirstChild("Answer"..i)
			if b and b:IsA("BasePart") then -- Garante que é uma peça
				local indexBase = ((i - 1) % 9) + 1
				local valorFinal = baseRespostas[indexBase]
				b.Color = CoresAleatorias[indexBase % #CoresAleatorias + 1]
				b.Transparency, b.CanCollide = 0, true
				b:SetAttribute("Correta", indexBase == posCertaBase)

				local lbl = b:FindFirstChildWhichIsA("TextLabel", true)
				if lbl then 
					if ehDecimal then lbl.Text = string.format("%.2f", valorFinal)
					else lbl.Text = tostring(math.floor(valorFinal)) end
				end
			end
		end

		rodadaAtiva = true
		for t = dados.tempo, 0, -1 do 
			timerLabel.Text = tostring(t)
			timerLabel.TextColor3 = (t <= 5) and Color3.new(1,0,0) or Color3.new(1,1,1)
			if t <= 5 and t > 0 and tickSound then tickSound:Play() end
			task.wait(1) 
		end
		rodadaAtiva = false

		-- Finalização
		if buzzerSound then buzzerSound:Play() end
		if aplausos4S then aplausos4S:Play() end

		for i = 1, 36 do
			local b = answersFolder:FindFirstChild("Answer"..i)
			if b and b:IsA("BasePart") then
				if not b:GetAttribute("Correta") then
					local lbl = b:FindFirstChildWhichIsA("TextLabel", true)
					if lbl then lbl.Text = "" end
					b.Color = Color3.fromRGB(50, 50, 50) 
				end
			end
		end

		-- ==========================================
		-- PREMIAÇÃO CORRIGIDA (PARA ATUALIZAR O TELÃO)
		-- ==========================================
		for _, p in pairs(ativos) do
			if p:GetAttribute("EscolhaCorreta") == true then
				local stats = p:FindFirstChild("leaderstats")
				if stats then
					-- 1. Dá o ponto na série certa
					stats["6º Ano"].Value += 1 -- Se for na arena 7, muda para "7º Ano"

					-- 2. Salva imediatamente para o Telão não demorar
					task.spawn(function()
						pcall(function()
							-- Salva o TOTAL no ranking de posições
							RankingGlobal:SetAsync("Player_" .. p.UserId, stats.Total.Value)

							-- Salva os DETALHES para as colunas s6, s7, s8...
							rankingStore:SetAsync("Player_" .. p.UserId, {
								Serie6 = stats["6º Ano"].Value,
								Serie7 = stats["7º Ano"].Value,
								Serie8 = stats["8º Ano"].Value,
								Serie9 = stats["9º Ano"].Value,
								Comp = stats.Camp.Value
							})
						end)
					end)
				end
			end
		end

		print("🔄 Rodada finalizada. Iniciando próxima em 4 segundos...")
		task.wait(4)
	else
		faxinaGeral()
		questionLabel.Text = "Aguardando Alunos..."
		task.wait(5)
	end
end