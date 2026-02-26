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

-- Referências para o Teletransporte (Devem estar dentro da pasta da Arena)
local saidaPart = arenaFolder:WaitForChild("SaidaArena6")
local destinoLobby = arenaFolder:WaitForChild("DestinoLobby")

local questionLabel = questionBoard.SurfaceGui.TextLabel
local timerLabel = timerBoard.SurfaceGui.TextLabel

-- Referências dos Sons (Devem estar dentro da TimerBoard6)
local tickSound = timerBoard:FindFirstChild("TickSound")
local buzzerSound = timerBoard:FindFirstChild("BuzzerSound")
local start = timerBoard:FindFirstChild("Start")
local apalusos4S = timerBoard:FindFirstChild("Apalusos4S")
local narracaoGalvaoBueno45S = timerBoard:FindFirstChild("NarracaoGalvaoBueno45S")
local narracaoGalvaoBueno30S = timerBoard:FindFirstChild("NarracaoGalvaoBueno30S")
local narracaoGalvaoBueno20S = timerBoard:FindFirstChild("NarracaoGalvaoBueno20S")

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
questionLabel.TextColor3 = Color3.fromRGB(200, 255, 200) 
questionLabel.Font = Enum.Font.LuckiestGuy 

uiStrokeQ.Color = Color3.fromRGB(0, 255, 127) 
uiStrokeQ.Thickness = 9
uiStrokeQ.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

uiGradientQ.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 150, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 50, 0))
})
uiGradientQ.Rotation = 90

saidaPart.Material = Enum.Material.Neon
saidaPart.Color = Color3.fromRGB(0, 255, 127)

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
-- 3. GERADORES AMPLIADOS (6º ANO)
-- ==========================================
local Geradores6Ano = {
	Facil = { 
		tempo = 20, 
		f = function() 
			local tipo = math.random(1, 2)
			if tipo == 1 then 
				local a, b = math.random(10, 500), math.random(10, 500)
				return {txt=a.." + "..b, res=a+b}
			else 
				local a = math.random(1, 99)
				local mult = (math.random(1, 2) == 1) and 10 or 100
				return {txt=a.." x "..mult, res=a*mult}
			end
		end 
	},
	Medio = { 
		tempo = 30, 
		f = function() 
			local tipo = math.random(1, 3)
			if tipo == 1 then 
				local a = math.random(2, 12)
				return {txt=a.."²", res=a*a}
			elseif tipo == 2 then 
				local a = math.random(1, 50) * 2
				return {txt="Metade de "..a, res=a/2}
			else 
				local a, b, c = math.random(2, 10), math.random(2, 5), math.random(1, 10)
				return {txt=a.." x ("..b.." + "..c..")", res=a*(b+c)}
			end
		end 
	},
	Dificil = { 
		tempo = 45, 
		f = function() 
			local tipo = math.random(1, 3)
			if tipo == 1 then 
				local a, b = math.random(100, 900)/100, math.random(50, 500)/100
				local res = a + b
				return {txt="R$ "..string.format("%.2f", a).." + R$ "..string.format("%.2f", b), res=tonumber(string.format("%.2f", res))}
			elseif tipo == 2 then 
				local lado = math.random(5, 25)
				return {txt="Perímetro do quadrado lado "..lado, res=lado*4}
			else 
				local b = math.random(5, 15)
				local res = math.random(10, 30)
				local a = b * res
				return {txt=a.." ÷ "..b, res=res}
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
			if p then p:SetAttribute("EscolhaCorreta", b:GetAttribute("Correta")) end
		end)
	end
end

-- ==========================================
-- 5. LOOP PRINCIPAL COM NARRAÇÕES DINÂMICAS
-- ==========================================
while true do
	local ativos = {}
	for _, p in pairs(players:GetPlayers()) do
		local char = p.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local dist = (char.HumanoidRootPart.Position - centroArenaPart.Position).Magnitude
			if dist <= 150 then 
				table.insert(ativos, p)
				p:SetAttribute("EscolhaCorreta", nil) 
			end
		end
	end

	if #ativos > 0 then
		faxinaGeral()
		questionLabel.Text = "PREPARE-SE (6º ANO)!"
		if start then start:Play() end
		task.wait(5)

		local niveis = {"Facil", "Medio", "Dificil"}
		local nivelEscolhido = niveis[math.random(1, #niveis)] 

		-- LÓGICA DE NARRAÇÃO POR TEMPO/NÍVEL
		if nivelEscolhido == "Dificil" then
			if narracaoGalvaoBueno45S then narracaoGalvaoBueno45S:Play() end
		elseif nivelEscolhido == "Medio" then
			if narracaoGalvaoBueno30S then narracaoGalvaoBueno30S:Play() end 
		elseif nivelEscolhido == "Facil" then
			if narracaoGalvaoBueno20S then narracaoGalvaoBueno20S:Play() end
		end

		local dados = Geradores6Ano[nivelEscolhido]
		local q = dados.f()
		questionLabel.Text = q.txt
		respostaCorreta = q.res

		local baseRespostas = {}
		local posCertaBase = math.random(1, 9)
		local valoresUsados = {[respostaCorreta] = true}

		for i = 1, 9 do
			if i == posCertaBase then
				baseRespostas[i] = respostaCorreta
			else
				local valorErrado
				repeat 
					valorErrado = tonumber(string.format("%.1f", respostaCorreta + math.random(-30, 30)))
				until not valoresUsados[valorErrado]
				valoresUsados[valorErrado] = true
				baseRespostas[i] = valorErrado
			end
		end

		for i = 1, 36 do
			local b = answersFolder:FindFirstChild("Answer"..i)
			if b then
				local indexBase = ((i - 1) % 9) + 1
				local valorFinal = baseRespostas[indexBase]
				b.Color = CoresAleatorias[indexBase % #CoresAleatorias + 1]
				b.Transparency, b.CanCollide = 0, true
				b:SetAttribute("Correta", indexBase == posCertaBase)
				local lbl = b.SurfaceGui:FindFirstChildWhichIsA("TextLabel")
				if lbl then lbl.Text = string.format("%.1f", valorFinal):gsub("%.0$", "") end
			end
		end

		rodadaAtiva = true
		for t = dados.tempo, 0, -1 do 
			timerLabel.Text = tostring(t)
			if t <= 5 and t > 0 then
				timerLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
				if tickSound then tickSound:Play() end
			else
				timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
			task.wait(1) 
		end

		rodadaAtiva = false
		if buzzerSound then buzzerSound:Play() end
		if apalusos4S then apalusos4S:Play() end

		for i = 1, 36 do
			local b = answersFolder:FindFirstChild("Answer"..i)
			if b and not b:GetAttribute("Correta") then 
				if b.SurfaceGui:FindFirstChild("TextLabel") then b.SurfaceGui.TextLabel.Text = "" end
				b.Color = Color3.fromRGB(50, 50, 50) 
			end
		end

		for _, p in pairs(ativos) do
			if p:GetAttribute("EscolhaCorreta") == true then
				local folder = p:FindFirstChild("AcertosPorSerie")
				if folder then
					folder.Serie6.Value += 1
					local total = folder.Serie6.Value + folder.Serie7.Value + folder.Serie8.Value + folder.Serie9.Value
					p.leaderstats.Pontos.Value = total
					pcall(function()
						rankingStore:SetAsync("Player_" .. p.UserId, {Serie6=folder.Serie6.Value, Serie7=folder.Serie7.Value, Serie8=folder.Serie8.Value, Serie9=folder.Serie9.Value})
						RankingGlobal:SetAsync("Player_" .. p.UserId, total)
					end)
				end
			end
		end
		task.wait(4)
	else
		faxinaGeral(); questionLabel.Text = "Aguardando Alunos..."; task.wait(2)
	end
end