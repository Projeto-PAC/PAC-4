local workspace = game.Workspace
local players = game.Players
local DataStoreService = game:GetService("DataStoreService")

-- ==========================================================================
-- 1. CONFIGURAÇÕES E BANCO DE DADOS
-- ==========================================================================
local rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5")
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5")

local arenaFolder = script.Parent 
local questionBoard = arenaFolder:WaitForChild("QuestionBoard9") 
local questionBoard91 = arenaFolder:WaitForChild("QuestionBoard91") 
local questionBoard92 = arenaFolder:WaitForChild("QuestionBoard92") 
local timerBoard = arenaFolder:WaitForChild("TimerBoard9")        
local answersFolder = arenaFolder:WaitForChild("Answers")
local centroArenaPart = arenaFolder:WaitForChild("CentroDaArena")
local destinoLobby = arenaFolder:WaitForChild("DestinoLobby")

-- ✅ REFERÊNCIAS SEPARADAS: Uma para a conta, outra para a dificuldade
local questionLabel = questionBoard.SurfaceGui.TextLabel      -- Quadro 9: A CONTA
local difficultyLabel = questionBoard92.SurfaceGui.TextLabel  -- Quadro 92: A DIFICULDADE
local timerLabel = timerBoard.SurfaceGui.TextLabel

-- Imagem Visual (No quadro 81)
local visualImg = questionBoard91.SurfaceGui:FindFirstChild("QuestaoVisual")

-- IDs das Imagens Oficiais
local IMG_TRIANGULO = "rbxassetid://86930496312387" 
local IMG_GRAFICO = "rbxassetid://116363021360323"   

-- Referências dos Sons
local tickSound = timerBoard:FindFirstChild("TickSound")
local buzzerSound = timerBoard:FindFirstChild("BuzzerSound")
local start = timerBoard:FindFirstChild("Start")
local aplausos4S = timerBoard:FindFirstChild("Aplausos4S")
local narracao45 = timerBoard:FindFirstChild("NarracaoGalvaoBueno45S")
local narracao30 = timerBoard:FindFirstChild("NarracaoGalvaoBueno30S") 
local narracao20 = timerBoard:FindFirstChild("NarracaoGalvaoBueno20S")

local ehDecimal = false
local rodadaAtiva = false
local respostaCorreta = 0
local historicoPerguntas = {}
local indiceSequencial = 1 

local CoresAleatorias = {
	Color3.fromRGB(255, 85, 0), Color3.fromRGB(0, 170, 255),
	Color3.fromRGB(85, 255, 127), Color3.fromRGB(255, 170, 0),
	Color3.fromRGB(170, 85, 255), Color3.fromRGB(0, 255, 255)
}

-- ==========================================================================
-- 2. ESTILIZAÇÃO VISUAL (PROTEÇÃO DE ACENTOS EM AMBOS OS QUADROS)
-- ==========================================================================
local function aplicarEstilos()
	local function estilizar(label)
		if not label then return end
		local uiStroke = label:FindFirstChild("UIStroke") or Instance.new("UIStroke", label)
		label.TextScaled = true
		label.BackgroundColor3 = Color3.fromRGB(30, 30, 30) 
		label.TextColor3 = Color3.fromRGB(255, 255, 255) 
		label.Font = Enum.Font.LuckiestGuy 

		uiStroke.Color = Color3.fromRGB(0, 0, 0) 
		uiStroke.Thickness = 7 
		uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		-- ✅ UIPADDING: Garante que os acentos de "FÁCIL" e "MÉDIO" não sejam cortados
		local padding = label:FindFirstChild("UIPadding") or Instance.new("UIPadding", label)
		padding.PaddingTop = UDim.new(0.12, 0)
		padding.PaddingBottom = UDim.new(0.1, 0)

		label.TextYAlignment = Enum.TextYAlignment.Center
		label.TextXAlignment = Enum.TextXAlignment.Center
	end

	estilizar(questionLabel)
	estilizar(difficultyLabel)

	-- Estilo do Timer
	local uiStrokeT = timerLabel:FindFirstChild("UIStroke") or Instance.new("UIStroke", timerLabel)
	local uiGradientT = timerLabel:FindFirstChild("UIGradient") or Instance.new("UIGradient", timerLabel)
	timerLabel.TextScaled = true
	uiStrokeT.Color = Color3.fromRGB(0, 255, 255) 
	uiStrokeT.Thickness = 5
	uiGradientT.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 170, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 85, 255))
	})
	uiGradientT.Rotation = 90

	if visualImg then visualImg.ImageTransparency = 1 end
end
aplicarEstilos()

-- ==========================================
-- 3. FUNÇÕES AUXILIARES
-- ==========================================
local function faxinaGeral()
	for _, desc in pairs(arenaFolder:GetDescendants()) do
		if desc:IsA("TextLabel") then desc.Text = "" end
	end
	if visualImg then visualImg.ImageTransparency = 1; visualImg.Image = "" end
end

local function formatarDecimal(valor)
	return math.floor(valor * 100 + 0.5) / 100
end

local function registrarEVerificar(txt)
	if historicoPerguntas[txt] then return true end
	historicoPerguntas[txt] = true
	local count = 0
	for _ in pairs(historicoPerguntas) do count += 1 end
	if count > 400 then historicoPerguntas = {} end
	return false
end

-- ==========================================
-- 4. GERADOR OMNI 9º ANO (12 MATÉRIAS COMPLETAS)
-- ==========================================
local sequenciaTemas = {
	{dif = "Facil", tipo = "Radiciacao", tempo = 20},
	{dif = "Medio", tipo = "EquacaoIncompleta", tempo = 35},
	{dif = "Dificil", tipo = "BhaskaraDelta", tempo = 50},
	{dif = "Medio", tipo = "TeoremaTales", tempo = 40},
	{dif = "Facil", tipo = "PotenciaFracionaria", tempo = 25},
	{dif = "Dificil", tipo = "TrigonometriaSOH", tempo = 45},
	{dif = "Medio", tipo = "FuncaoPrimeiroGrau", tempo = 35},
	{dif = "Dificil", tipo = "SomaEProduto", tempo = 45},
	{dif = "Facil", tipo = "NotacaoCientificaNeg", tempo = 30},
	{dif = "Medio", tipo = "AreaCirculo", tempo = 40},
	{dif = "Dificil", tipo = "PitagorasAvancado", tempo = 45},
	{dif = "Medio", tipo = "Racionalizacao", tempo = 40}
}
local function GerarQuestaoNivelamento()
	local config = sequenciaTemas[indiceSequencial]
	local q = {txt = "", res = 0, isDecimal = false, img = nil}
	local failSafe = 0

	repeat
		failSafe += 1
		if config.tipo == "Radiciacao" then
			local n = math.random(2, 5)
			q.txt = "Raiz Cúbica (³√) de " .. (n^3) .. " = ?"; q.res = n

		elseif config.tipo == "EquacaoIncompleta" then
			-- x² - a = 0
			local a = math.random(2, 10)
			q.txt = "x² - " .. (a*a) .. " = 0 | Qual o x positivo?"; q.res = a

		elseif config.tipo == "BhaskaraDelta" then
			-- Δ = b² - 4ac. Calculando apenas o Delta para caber no tempo.
			-- Ex: x² - 5x + 6 (a=1, b=-5, c=6) -> Δ = 25 - 24 = 1
			q.txt = "Delta (Δ) de: x² - 5x + 6 = 0"; q.res = 1

		elseif config.tipo == "TeoremaTales" then
			local x = math.random(2, 5)
			q.txt = "Tales: 2/4 = " .. x .. "/? | Ache o valor"; q.res = x * 2

		elseif config.tipo == "PotenciaFracionaria" then
			-- 9^(1/2) = √9
			local n = math.random(3, 6)
			q.txt = (n*n) .. "^(1/2) é igual a?"; q.res = n

		elseif config.tipo == "TrigonometriaSOH" then
			-- Seno = Oposto / Hipotenusa
			q.txt = "Seno 30° = 0,5. Se hipotenusa=10, Cat. Oposto=?"; q.res = 5

		elseif config.tipo == "FuncaoPrimeiroGrau" then
			-- f(x) = ax + b
			local x = math.random(2, 5)
			q.txt = "f(x) = 2x + 10. Qual o valor de f(" .. x .. ")?"; q.res = (2 * x) + 10

		elseif config.tipo == "SomaEProduto" then
			-- Soma das raízes = -b/a
			q.txt = "Soma das raízes de x² - 7x + 10 = 0"; q.res = 7

		elseif config.tipo == "NotacaoCientificaNeg" then
			q.txt = "0,0001 em potência de base 10?"; q.res = -4

		elseif config.tipo == "AreaCirculo" then
			-- A = π * r² (Usando π = 3 para facilitar o cálculo mental)
			local r = math.random(2, 4)
			q.txt = "Área do Círculo (r=" .. r .. ", π=3)"; q.res = 3 * (r*r)

		elseif config.tipo == "PitagorasAvancado" then
			-- Triângulo 5, 12, 13
			q.txt = "Catetos 5 e 12. Qual a Hipotenusa?"; q.res = 13; q.img = IMG_TRIANGULO

		elseif config.tipo == "Racionalizacao" then
			q.txt = "Racionalize 2/√2. Qual o resultado?"; q.res = 2 -- Simplificado para o quiz (considerando √2 * √2)
			-- Nota: Para o quiz, é melhor perguntas com respostas inteiras.
			q.txt = "Se √2 ≈ 1,41. Quanto é 10 * √2?"; q.res = 14.1; q.isDecimal = true
		end
	until not registrarEVerificar(q.txt) or failSafe > 20

	indiceSequencial = (indiceSequencial % #sequenciaTemas) + 1
	return q, config.dif, config.tempo
end

-- ==========================================
-- 5. LOOP PRINCIPAL (DISPLAY SEPARADO)
-- ==========================================
for i = 1, 36 do
	local b = answersFolder:FindFirstChild("Answer"..i)
	if b then
		b.Touched:Connect(function(hit)
			if not rodadaAtiva then return end
			local p = players:GetPlayerFromCharacter(hit.Parent)
			if p then p:SetAttribute("EscolhaCorreta", b:GetAttribute("Correta")) end
		end)
	end
end

while true do
	local ativos = {}
	for _, p in pairs(players:GetPlayers()) do
		local char = p.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local dist = (char.HumanoidRootPart.Position - centroArenaPart.Position).Magnitude
			if dist <= 130 then table.insert(ativos, p); p:SetAttribute("EscolhaCorreta", nil) end
		end
	end

	if #ativos > 0 then
		faxinaGeral()
		questionLabel.Text = "PREPARE-SE!"
		difficultyLabel.Text = "9º ANO"
		if start then start:Play() end
		task.wait(2)

		local qData, nv, tempoRound = GerarQuestaoNivelamento()
		ehDecimal = qData.isDecimal; respostaCorreta = qData.res

		-- SOM: Narração corrigida (bate com nv da tabela)
		pcall(function()
			if nv == "Dificil" and narracao45 then narracao45:Play()
			elseif nv == "Medio" and narracao30 then narracao30:Play()
			elseif nv == "Facil" and narracao20 then narracao20:Play() end
		end)

		if visualImg then
			visualImg.Image = qData.img or ""
			visualImg.ImageTransparency = qData.img and 0.4 or 1
		end

		-- ✅ SEPARAÇÃO DE TEXTO NO QUADRO
		local labelComAcento = nv == "Facil" and "FÁCIL" or (nv == "Medio" and "MÉDIO" or "DIFÍCIL")

		difficultyLabel.Text = labelComAcento -- Dificuldade no 92
		questionLabel.Text = qData.txt        -- Pergunta no 9

		local baseRespostas = {}
		local posCerta = math.random(1, 9)
		local usados = {[respostaCorreta] = true}

		for i = 1, 9 do
			if i == posCerta then baseRespostas[i] = respostaCorreta
			else
				local errado
				repeat errado = ehDecimal and formatarDecimal(respostaCorreta + math.random(-10, 10)) or (respostaCorreta + math.random(-25, 25))
				until not usados[errado]
				usados[errado] = true
				baseRespostas[i] = errado
			end
		end

		for i = 1, 36 do
			local b = answersFolder:FindFirstChild("Answer"..i)
			if b then
				local idx = ((i-1)%9)+1
				b:SetAttribute("Correta", idx == posCerta)
				b.Color = CoresAleatorias[idx % #CoresAleatorias + 1]
				b.Transparency, b.CanCollide = 0, true
				local lbl = b:FindFirstChildWhichIsA("TextLabel", true)
				if lbl then 
					if ehDecimal or baseRespostas[idx] % 1 ~= 0 then
						lbl.Text = string.format("%.2f", baseRespostas[idx])
					else
						lbl.Text = tostring(math.floor(baseRespostas[idx]))
					end
				end
			end
		end

		rodadaAtiva = true
		for t = tempoRound, 0, -1 do 
			timerLabel.Text = t
			timerLabel.TextColor3 = (t <= 5) and Color3.new(1,0,0) or Color3.new(1,1,1)
			if t <= 5 and t > 0 and tickSound then tickSound:Play() end
			task.wait(1) 
		end
		rodadaAtiva = false

		if buzzerSound then buzzerSound:Play() end
		if aplausos4S then aplausos4S:Play() end

		for i = 1, 36 do
			local b = answersFolder:FindFirstChild("Answer"..i)
			if b and b:IsA("BasePart") then
				if not b:GetAttribute("Correta") then
					b.Color = Color3.fromRGB(50, 50, 50) 
					local lbl = b:FindFirstChildWhichIsA("TextLabel", true)
					if lbl then lbl.Text = "" end
				else
					b.Color = Color3.fromRGB(0, 255, 0)
				end
			end
		end

		-- SALVAMENTO DATASTORE
		for _, p in pairs(ativos) do
			if p:GetAttribute("EscolhaCorreta") == true then
				local acertos = p:FindFirstChild("AcertosPorSerie")
				local stats = p:FindFirstChild("leaderstats")
				if acertos and stats then
					local serie9 = acertos:FindFirstChild("Serie9")
					if serie9 then serie9.Value += 1
						task.spawn(function()
							pcall(function()
								RankingGlobal:SetAsync("Player_" .. p.UserId, stats.Total.Value)
								rankingStore:SetAsync("Player_" .. p.UserId, {
									Serie6 = acertos.Serie6.Value,
									Serie7 = acertos.Serie7.Value,
									Serie8 = acertos.Serie8.Value,
									Serie9 = serie9.Value,
									Camp = stats.Camp.Value,
								})
							end)
						end)
					end
				end
			end
		end
		task.wait(4)
	else
		faxinaGeral()
		questionLabel.Text = "AGUARDANDO ALUNOS..."
		difficultyLabel.Text = "9º ANO"
		task.wait(5)
	end
end