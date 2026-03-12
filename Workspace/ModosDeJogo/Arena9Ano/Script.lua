local workspace = game.Workspace
local players = game.Players
local DataStoreService = game:GetService("DataStoreService")

-- ==========================================================================
-- 1. CONFIGURAÇÕES E BANCO DE DADOS
-- ==========================================================================
local rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5")
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5")

local modoPasta = workspace:WaitForChild("ModosDeJogo", 10)
local arenaFolder = modoPasta:WaitForChild("Arena9Ano") 

local questionBoard = arenaFolder:WaitForChild("QuestionBoard9") 
local timerBoard = arenaFolder:WaitForChild("TimerBoard9")       
local answersFolder = arenaFolder:WaitForChild("Answers")
local centroArenaPart = arenaFolder:WaitForChild("CentroDaArena")

-- Referências para Saída e Spawn
local saidaPart = arenaFolder:WaitForChild("SaidaArena9") 
local spawnPonto = arenaFolder:WaitForChild("SpawnArena9")
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
-- 2. ESTILIZAÇÃO VISUAL COMPLETA (AZUL NEON E BRANCO GROSSO)
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
-- 4. GERADORES DE CÁLCULO (9º ANO - ELITE)
-- ==========================================================================
local Geradores9Ano = {
	Facil = { 
		tempo = 20, 
		f = function() 
			ehDecimal = false
			local a = math.random(2, 7)
			return {txt="(-"..a..")²", res = a*a}
		end 
	},
	Medio = { 
		tempo = 30, 
		f = function() 
			ehDecimal = false
			local r = {64, 81, 100, 121, 144}
			local num = r[math.random(1, #r)]
			return {txt="√"..num.." + √16", res = math.sqrt(num) + 4}
		end 
	},
	Dificil = { 
		tempo = 45, 
		f = function() 
			ehDecimal = false
			local x = math.random(5, 12)
			return {txt="x² - "..(x*x).." = 0 | x positivo?", res = x}
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
		questionLabel.Text = "PREPARE-SE (9º ANO)!"
		if start then start:Play() end
		task.wait(2)

		local nv = ({"Facil", "Medio", "Dificil"})[math.random(1,3)]
		local dados = Geradores9Ano[nv]

		pcall(function()
			if nv == "Dificil" and narracao45 then narracao45:Play()
			elseif nv == "Medio" and narracao30 then narracao30:Play()
			elseif nv == "Facil" and narracao20 then narracao20:Play() end
		end)

		local q = dados.f()
		questionLabel.Text = q.txt
		respostaCorreta = q.res

		-- 🚨 LÓGICA ANTI-DUPLICADOS (BLINDADA) 🚨
		local posCerta = math.random(1, 9)
		local gabarito = {}
		local usados = {[respostaCorreta] = true} -- O resultado certo já está proibido para os errados

		for i = 1, 9 do
			if i == posCerta then
				gabarito[i] = respostaCorreta
			else
				local errado
				repeat 
					-- Gera um número diferente do correto
					errado = respostaCorreta + math.random(-25, 25)
					-- Se por azar o random der 0, força uma mudança
					if errado == respostaCorreta then errado = errado + 1 end
				until not usados[errado] -- Sorteia até achar um que NÃO esteja na lista de usados

				usados[errado] = true
				gabarito[i] = errado
			end
		end

		-- Preencher os 36 blocos (Apenas os 4 blocos da posCerta serão corretos)
		for i = 1, 36 do
			local b = answersFolder:FindFirstChild("Answer"..i)
			if b then
				local idx = ((i-1)%9)+1
				b:SetAttribute("Correta", idx == posCerta)
				b.Color = CoresAleatorias[idx % #CoresAleatorias + 1]
				b.Transparency = 0
				b.CanCollide = true -- Piso sólido
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

		-- FINALIZAÇÃO ESTILO ARENA 6 (SÓLIDO)
		for i = 1, 36 do
			local b = answersFolder:FindFirstChild("Answer"..i)
			if b and b:IsA("BasePart") then
				local lbl = b:FindFirstChildWhichIsA("TextLabel", true)
				if not b:GetAttribute("Correta") then
					b.Color = Color3.fromRGB(50, 50, 50) 
					if lbl then lbl.Text = "" end
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
					local s9 = stats:FindFirstChild("9º Ano") or stats:FindFirstChild("9o Ano")
					if s9 then
						s9.Value += 1
						task.spawn(function()
							pcall(function()
								RankingGlobal:SetAsync("Player_" .. p.UserId, stats.Total.Value)
								rankingStore:SetAsync("Player_" .. p.UserId, {
									Serie6 = stats:FindFirstChild("6º Ano") and stats["6º Ano"].Value or 0,
									Serie7 = stats:FindFirstChild("7º Ano") and stats["7º Ano"].Value or 0,
									Serie8 = stats:FindFirstChild("8º Ano") and stats["8º Ano"].Value or 0,
									Serie9 = s9.Value,
									Comp = stats:FindFirstChild("Camp") and stats.Camp.Value or 0
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