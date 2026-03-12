local workspace = game.Workspace
local players = game.Players
local DataStoreService = game:GetService("DataStoreService")

-- ==========================================================================
-- 1. CONFIGURAÇÕES E BANCO DE DADOS
-- ==========================================================================
local rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5")
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5")

local arenaFolder = script.Parent 
local questionBoard = arenaFolder:WaitForChild("QuestionBoard7") 
local timerBoard = arenaFolder:WaitForChild("TimerBoard7")        
local answersFolder = arenaFolder:WaitForChild("Answers")
local centroArenaPart = arenaFolder:WaitForChild("CentroDaArena")

-- Referências para Saída e Spawn
local saidaPart = arenaFolder:WaitForChild("SaidaArena7") 
local spawnPonto = arenaFolder:WaitForChild("SpawnArena7")
local destinoLobby = arenaFolder:WaitForChild("DestinoLobby")

local questionLabel = questionBoard.SurfaceGui.TextLabel
local timerLabel = timerBoard.SurfaceGui.TextLabel

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

local CoresAleatorias = {
	Color3.fromRGB(255, 85, 0), Color3.fromRGB(0, 170, 255),
	Color3.fromRGB(85, 255, 127), Color3.fromRGB(255, 170, 0),
	Color3.fromRGB(170, 85, 255), Color3.fromRGB(0, 255, 255)
}

-- ==========================================================================
-- 2. ESTILIZAÇÃO VISUAL COMPLETA (MANTENDO TODAS AS LINHAS)
-- ==========================================================================
local function aplicarEstilos()
	-- TIMERBOARD (AZUL NEON BRILHANTE)
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

	-- QUESTIONBOARD (BRANCO COM BORDA PRETA GROSSA)
	local uiStrokeQ = questionLabel:FindFirstChild("UIStroke") or Instance.new("UIStroke", questionLabel)

	questionLabel.Size = UDim2.new(1, 0, 1, 0)
	questionLabel.TextScaled = true
	questionLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30) 
	questionLabel.TextColor3 = Color3.fromRGB(255, 255, 255) 
	questionLabel.Font = Enum.Font.LuckiestGuy 

	uiStrokeQ.Color = Color3.fromRGB(0, 0, 0) 
	uiStrokeQ.Thickness = 12 
	uiStrokeQ.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	saidaPart.Material = Enum.Material.Neon
end
aplicarEstilos()

-- ==========================================================================
-- 3. FUNÇÕES AUXILIARES E TELEPORTE
-- ==========================================================================
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

-- ==========================================================================
-- 4. GERADORES DE CÁLCULO (7º ANO)
-- ==========================================================================
local Geradores7Ano = {
	Facil = { 
		tempo = 20, 
		f = function() 
			ehDecimal = false
			local tipo = math.random(1, 3)
			if tipo == 1 then -- Soma de Inteiros
				local a, b = math.random(-25, 15), math.random(-15, 25)
				return {txt="("..a..") + ("..b..")", res = a + b}
			elseif tipo == 2 then -- Equação Simples
				local x = math.random(2, 20)
				return {txt="x + 10 = "..(x+10).." | x=?", res = x}
			else -- Subtração de Inteiros
				local a, b = math.random(-15, 15), math.random(1, 15)
				return {txt=a.." - "..b, res = a - b}
			end
		end 
	},
	Medio = { 
		tempo = 30, 
		f = function() 
			ehDecimal = false
			local tipo = math.random(1, 3)
			if tipo == 1 then -- Regra de Sinais
				local a, b = math.random(-8, 5), math.random(-5, 8)
				return {txt="("..a..") x ("..b..")", res = a * b}
			elseif tipo == 2 then -- Ângulos
				local a = math.random(10, 80)
				return {txt="Complemento de "..a.."°", res = 90 - a}
			else -- Porcentagem 25%
				local v = math.random(1, 10) * 40
				return {txt="25% de R$ "..v, res = v * 0.25}
			end
		end 
	},
	Dificil = { 
		tempo = 45, 
		f = function() 
			local tipo = math.random(1, 3)
			if tipo == 1 then -- Decimais Negativos
				ehDecimal = true
				local a = math.random(-600, 200)/100; local b = math.random(100, 400)/100
				return {txt="Saldo R$ "..string.format("%.2f", a).." - R$ "..string.format("%.2f", b), res = a-b}
			elseif tipo == 2 then -- Equação 2x + a = b
				ehDecimal = false
				local x = math.random(2, 10); local a = math.random(1, 10)
				return {txt="2x + "..a.." = "..(2*x+a).." | x=?", res = x}
			else -- Razão (Regra de Três)
				ehDecimal = false
				local p = math.random(3, 8)
				return {txt="2 itens = "..(p*2).." | 10 itens = ?", res = p*10}
			end
		end 
	}
}

-- ==========================================================================
-- 5. DETECÇÃO DE TOQUE (36 BLOCOS)
-- ==========================================================================
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

-- ==========================================================================
-- 6. LOOP PRINCIPAL (ESTILO ARENA 6 - SEM QUEDA)
-- ==========================================================================
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
		questionLabel.Text = "PREPARE-SE (7º ANO)!"
		if start then start:Play() end
		task.wait(2)

		local niveis = {"Facil", "Medio", "Dificil"}
		local nv_nome = niveis[math.random(1, #niveis)]
		local dados = Geradores7Ano[nv_nome]

		pcall(function()
			if nv_nome == "Dificil" and narracao45 then narracao45:Play()
			elseif nv_nome == "Medio" and narracao30 then narracao30:Play()
			elseif nv_nome == "Facil" and narracao20 then narracao20:Play() end
		end)

		local q = dados.f()
		questionLabel.Text = q.txt
		respostaCorreta = q.res

		-- 🚨 LÓGICA DE PREENCHIMENTO (ÚNICOS E 4 CERTOS)
		local baseRespostas = {}
		local posCerta = math.random(1, 9)
		local usados = {[respostaCorreta] = true}

		for i = 1, 9 do
			if i == posCerta then
				baseRespostas[i] = respostaCorreta
			else
				local errado
				local tentativas = 0
				repeat 
					tentativas = tentativas + 1
					errado = ehDecimal and tonumber(string.format("%.2f", respostaCorreta + (math.random(-500, 500)/100))) or (respostaCorreta + math.random(-25, 25))
				until (not usados[errado] and errado ~= respostaCorreta) or tentativas > 20
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
				b.Transparency = 0
				b.CanCollide = true -- Sempre sólido no início
				local lbl = b:FindFirstChildWhichIsA("TextLabel", true)
				if lbl then 
					lbl.Text = ehDecimal and string.format("%.2f", baseRespostas[idx]) or tostring(math.floor(baseRespostas[idx]))
				end
			end
		end

		rodadaAtiva = true
		for t = dados.tempo, 0, -1 do 
			timerLabel.Text = t
			timerLabel.TextColor3 = (t <= 5) and Color3.new(1,0,0) or Color3.new(1,1,1)
			if t <= 5 and t > 0 and tickSound then tickSound:Play() end
			task.wait(1) 
		end
		rodadaAtiva = false

		if buzzerSound then buzzerSound:Play() end
		if aplausos4S then aplausos4S:Play() end

		-- 🚨 FINALIZAÇÃO: ESTILO ARENA 6 (FICA SÓLIDO!) 🚨
		for i = 1, 36 do
			local b = answersFolder:FindFirstChild("Answer"..i)
			if b and b:IsA("BasePart") then
				local lbl = b:FindFirstChildWhichIsA("TextLabel", true)
				if not b:GetAttribute("Correta") then
					-- Fica cinza escuro e esconde o texto, mas continua sólido
					b.Color = Color3.fromRGB(50, 50, 50) 
					if lbl then lbl.Text = "" end
					-- b.CanCollide continua TRUE (Não cai na lava!)
				else
					-- Apenas os 4 blocos da resposta certa ficam verdes
					b.Color = Color3.fromRGB(0, 255, 0)
				end
			end
		end

		-- ✅ SALVAMENTO BLINDADO
		for _, p in pairs(ativos) do
			if p:GetAttribute("EscolhaCorreta") == true then
				local stats = p:FindFirstChild("leaderstats")
				if stats then
					local s7 = stats:FindFirstChild("7º Ano")
					if s7 then
						s7.Value += 1
						task.spawn(function()
							pcall(function()
								RankingGlobal:SetAsync("Player_" .. p.UserId, stats.Total.Value)
								rankingStore:SetAsync("Player_" .. p.UserId, {
									Serie6 = stats["6º Ano"].Value,
									Serie7 = s7.Value,
									Serie8 = stats["8º Ano"].Value,
									Serie9 = stats["9º Ano"].Value,
									Comp = stats.Camp.Value
								})
							end)
						end)
					end
				end
			end
		end
		task.wait(4)
	else
		faxinaGeral(); questionLabel.Text = "AGUARDANDO ALUNOS..."; task.wait(5)
	end
end