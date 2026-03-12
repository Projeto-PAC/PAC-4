local workspace = game.Workspace
local players = game.Players
local DataStoreService = game:GetService("DataStoreService")

-- ==========================================================================
-- 1. CONFIGURAÇÕES E BANCO DE DADOS
-- ==========================================================================
local rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5")
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5")

local modoPasta = workspace:WaitForChild("ModosDeJogo", 10)
local arenaFolder = modoPasta:WaitForChild("Arena8Ano") 

local questionBoard = arenaFolder:WaitForChild("QuestionBoard8") 
local timerBoard = arenaFolder:WaitForChild("TimerBoard8")       
local answersFolder = arenaFolder:WaitForChild("Answers")
local centroArenaPart = arenaFolder:WaitForChild("CentroDaArena")

-- Referências para Saída e Spawn
local saidaPart = arenaFolder:WaitForChild("SaidaArena8") 
local spawnPonto = arenaFolder:WaitForChild("SpawnArena8")
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
-- 2. ESTILIZAÇÃO VISUAL COMPLETA
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
-- 3. FUNÇÕES AUXILIARES
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
-- 4. GERADORES DE CÁLCULO (8º ANO - MATÉRIA)
-- ==========================================================================
local Geradores8Ano = {
	Facil = { 
		tempo = 20, 
		f = function() 
			ehDecimal = false
			local tipo = math.random(1, 2)
			if tipo == 1 then -- Raiz Quadrada
				local r = {16, 25, 36, 49, 64, 81, 100, 121, 144, 169}
				local num = r[math.random(1, #r)]
				return {txt="√"..num, res = math.sqrt(num)}
			else -- Expressão Algébrica
				local x = math.random(2, 10)
				return {txt="Se x="..x..", quanto é 2x + 10?", res = (2*x)+10}
			end
		end 
	},
	Medio = { 
		tempo = 30, 
		f = function() 
			ehDecimal = false
			local x = math.random(3, 15)
			return {txt="3x - 5 = "..(3*x-5).." | x=?", res = x}
		end 
	},
	Dificil = { 
		tempo = 45, 
		f = function() 
			ehDecimal = false
			local trios = {{3,4,5}, {6,8,10}, {5,12,13}, {8,15,17}}
			local t = trios[math.random(1, #trios)]
			return {txt="Pitágoras: Catetos "..t[1].." e "..t[2]..". Hipotenusa = ?", res = t[3]}
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
-- 6. LOOP PRINCIPAL (REGRA: SEM QUEDA E RESULTADOS ÚNICOS)
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
		questionLabel.Text = "PREPARE-SE (8º ANO)!"
		if start then start:Play() end
		task.wait(2)

		local nv = ({"Facil", "Medio", "Dificil"})[math.random(1,3)]
		local dados = Geradores8Ano[nv]

		pcall(function()
			if nv == "Dificil" and narracao45 then narracao45:Play()
			elseif nv == "Medio" and narracao30 then narracao30:Play()
			elseif nv == "Facil" and narracao20 then narracao20:Play() end
		end)

		local q = dados.f()
		questionLabel.Text = q.txt
		respostaCorreta = q.res

		-- 🚨 GERAÇÃO DE RESULTADOS ÚNICOS 🚨
		local posCerta = math.random(1, 9)
		local gabarito = {}
		local usados = {[respostaCorreta] = true}

		for i = 1, 9 do
			if i == posCerta then
				gabarito[i] = respostaCorreta
			else
				local errado
				repeat 
					errado = respostaCorreta + math.random(-30, 30)
				until not usados[errado] and errado ~= respostaCorreta
				usados[errado] = true
				gabarito[i] = errado
			end
		end

		-- Preencher os 36 blocos (apenas 4 corretos no mapa)
		for i = 1, 36 do
			local b = answersFolder:FindFirstChild("Answer"..i)
			if b then
				local idx = ((i-1)%9)+1
				b:SetAttribute("Correta", idx == posCerta)
				b.Color = CoresAleatorias[idx % #CoresAleatorias + 1]
				b.Transparency = 0
				b.CanCollide = true -- Sempre sólido
				local lbl = b:FindFirstChildWhichIsA("TextLabel", true)
				if lbl then 
					lbl.Text = tostring(math.floor(gabarito[idx]))
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

		-- 🚨 FINALIZAÇÃO: ESTILO ARENA 6 (SÓLIDO E SEM QUEDA) 🚨
		for i = 1, 36 do
			local b = answersFolder:FindFirstChild("Answer"..i)
			if b and b:IsA("BasePart") then
				local lbl = b:FindFirstChildWhichIsA("TextLabel", true)
				if not b:GetAttribute("Correta") then
					-- Errados apagam e ficam cinza (Mas continuam sólidos)
					b.Color = Color3.fromRGB(50, 50, 50) 
					if lbl then lbl.Text = "" end
				else
					-- Apenas os 4 certos ficam verdes
					b.Color = Color3.fromRGB(0, 255, 0)
				end
			end
		end

		-- ✅ SALVAMENTO BLINDADO (8º ANO)
		for _, p in pairs(ativos) do
			if p:GetAttribute("EscolhaCorreta") == true then
				local stats = p:FindFirstChild("leaderstats")
				if stats then
					local s8 = stats:FindFirstChild("8º Ano") or stats:FindFirstChild("8o Ano")
					if s8 then
						s8.Value += 1
						task.spawn(function()
							pcall(function()
								RankingGlobal:SetAsync("Player_" .. p.UserId, stats.Total.Value)
								rankingStore:SetAsync("Player_" .. p.UserId, {
									Serie6 = stats["6º Ano"].Value,
									Serie7 = stats["7º Ano"].Value,
									Serie8 = s8.Value,
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