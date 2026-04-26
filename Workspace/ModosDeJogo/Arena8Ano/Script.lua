local workspace = game.Workspace
local players = game.Players
local DataStoreService = game:GetService("DataStoreService")

-- ==========================================================================
-- 1. CONFIGURAÇÕES E BANCO DE DADOS
-- ==========================================================================
local rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5")
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5")

local arenaFolder = script.Parent 
local questionBoard = arenaFolder:WaitForChild("QuestionBoard8") 
local questionBoard81 = arenaFolder:WaitForChild("QuestionBoard81") 
local questionBoard82 = arenaFolder:WaitForChild("QuestionBoard82") 
local timerBoard = arenaFolder:WaitForChild("TimerBoard8")        
local answersFolder = arenaFolder:WaitForChild("Answers")
local centroArenaPart = arenaFolder:WaitForChild("CentroDaArena")
local destinoLobby = arenaFolder:WaitForChild("DestinoLobby")

-- ✅ REFERÊNCIAS SEPARADAS: Uma para a conta, outra para a dificuldade
local questionLabel = questionBoard.SurfaceGui.TextLabel      -- Quadro 8: A CONTA
local difficultyLabel = questionBoard82.SurfaceGui.TextLabel  -- Quadro 82: A DIFICULDADE
local timerLabel = timerBoard.SurfaceGui.TextLabel

-- Imagem Visual (No quadro 81)
local visualImg = questionBoard81.SurfaceGui:FindFirstChild("QuestaoVisual")

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
-- 4. GERADOR OMNI 8º ANO (12 MATÉRIAS COMPLETAS)
-- ==========================================
local sequenciaTemas = {
	{dif = "Facil", tipo = "NotacaoCientifica", tempo = 20},
	{dif = "Medio", tipo = "ProdutosNotaveis", tempo = 45},
	{dif = "Medio", tipo = "SistemaSoma", tempo = 40},
	{dif = "Dificil", tipo = "Fatoracao", tempo = 45},
	{dif = "Facil", tipo = "RaizExata", tempo = 20},
	{dif = "Medio", tipo = "AngulosPoligono", tempo = 30},
	{dif = "Medio", tipo = "PorcentagemJuros", tempo = 30},
	{dif = "Dificil", tipo = "VolumeBloco", tempo = 45},
	{dif = "Facil", tipo = "PotenciaNegativa", tempo = 25},
	{dif = "Medio", tipo = "EquacaoFracionaria", tempo = 40},
	{dif = "Dificil", tipo = "PitagorasSimples", tempo = 45},
	{dif = "Facil", tipo = "DizimaPeriodica", tempo = 30}
}

local function GerarQuestaoNivelamento()
	local config = sequenciaTemas[indiceSequencial]
	local q = {txt = "", res = 0, isDecimal = false, img = nil}
	local failSafe = 0

	repeat
		failSafe += 1
		if config.tipo == "NotacaoCientifica" then
			local n = math.random(2, 9)
			local exp = math.random(3, 6)
			q.txt = n .. " * 10^" .. exp .. " tem quantos zeros?"; q.res = exp

		elseif config.tipo == "ProdutosNotaveis" then
			-- (x + a)^2 = x^2 + 2ax + a^2 -> Pergunta o termo do meio
			local a = math.random(2, 9)
			q.txt = "(x + " .. a .. ")² = x² + ?x + " .. (a*a); q.res = 2 * a

		elseif config.tipo == "SistemaSoma" then
			-- x + y = S | x - y = D
			local x = math.random(5, 15)
			local y = math.random(1, 4)
			q.txt = "x + y = " .. (x+y) .. " e x - y = " .. (x-y) .. " | x=?"; q.res = x

		elseif config.tipo == "Fatoracao" then
			local a = math.random(2, 5)
			q.txt = a .. "x + " .. (a*math.random(2,5)) .. " | Fator comum?"; q.res = a

		elseif config.tipo == "RaizExata" then
			local n = math.random(13, 25)
			q.txt = "√" .. (n*n) .. " = ?"; q.res = n

		elseif config.tipo == "AngulosPoligono" then
			-- Soma dos ângulos internos (n-2)*180
			local lados = math.random(3, 6)
			q.txt = "Soma ângulos internos de polígono de " .. lados .. " lados?"; q.res = (lados - 2) * 180

		elseif config.tipo == "PorcentagemJuros" then
			local capital = math.random(1, 5) * 100
			q.txt = "Juros simples de 10% sobre R$" .. capital; q.res = capital * 0.1

		elseif config.tipo == "VolumeBloco" then
			local a, b, c = math.random(2, 4), math.random(2, 4), math.random(2, 5)
			q.txt = "Volume do Cuboide: " .. a .. "x" .. b .. "x" .. c; q.res = a * b * c

		elseif config.tipo == "PotenciaNegativa" then
			q.txt = "Qual o valor de 2^-2? (Em %)"; q.res = 25 -- 0.25

		elseif config.tipo == "EquacaoFracionaria" then
			local x = math.random(2, 6)
			q.txt = "x/2 + 5 = " .. ( (x/2) + 5 ) .. " | x=?"; q.res = x

		elseif config.tipo == "PitagorasSimples" then
			-- Triângulo 3, 4, 5 ou múltiplos
			local m = math.random(1, 3)
			q.txt = "Catetos " .. (3*m) .. " e " .. (4*m) .. ". Hipotenusa?"; q.res = 5 * m; q.img = IMG_TRIANGULO

		elseif config.tipo == "DizimaPeriodica" then
			q.txt = "Fração geratriz de 0,333... é 1/?"; q.res = 3
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
		difficultyLabel.Text = "8º ANO"
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

		difficultyLabel.Text = labelComAcento -- Dificuldade no 82
		questionLabel.Text = qData.txt        -- Pergunta no 8

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
					local serie8 = acertos:FindFirstChild("Serie8")
					if serie8 then serie8.Value += 1
						task.spawn(function()
							pcall(function()
								RankingGlobal:SetAsync("Player_" .. p.UserId, stats.Total.Value)
								rankingStore:SetAsync("Player_" .. p.UserId, {
									Serie6 = acertos.Serie6.Value,
									Serie7 = acertos.Serie7.Value,
									Serie8 = serie8.Value,
									Serie9 = acertos.Serie9.Value,
									Camp = stats.Camp.Value
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
		difficultyLabel.Text = "8º ANO"
		task.wait(5)
	end
end