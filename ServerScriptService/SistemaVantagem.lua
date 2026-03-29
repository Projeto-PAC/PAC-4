local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- 📡 1. CONFIGURAÇÃO DE EVENTOS
local function obterEvento(nome, classe)
	local ev = ReplicatedStorage:FindFirstChild(nome) or Instance.new(classe, ReplicatedStorage)
	ev.Name = nome
	return ev
end

local BuyEvent = obterEvento("BuyVantage", "RemoteEvent")
local UseEvent = obterEvento("UseVantage", "RemoteEvent")
local AddTimeEv = obterEvento("AddTimeEvent", "BindableEvent")
local eventoStatusTela = ReplicatedStorage:WaitForChild("AtualizarStatusTela")

-- 🏷️ TABELA DE PREÇOS E MEDIDAS DA ARENA (IGUAL AO GAMEMANAGER)
local PRECOS = { Vantage1 = 50, Vantage2 = 30, Vantage3 = 15 }
local LARGURA_X = 179.5
local PROFUNDIDADE_Z = 179.5
local sistemaArena = workspace:WaitForChild("SistemaArena")
local centroArena = sistemaArena:WaitForChild("CentroDaArena")

-------------------------------------------------
-- 📦 2. INICIALIZAÇÃO DO PLAYER
-------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	local statsLoja = player:FindFirstChild("StatsLoja") or Instance.new("Folder", player)
	statsLoja.Name = "StatsLoja"
	if not statsLoja:FindFirstChild("SaldoUtilizado") then
		local gasto = Instance.new("IntValue", statsLoja)
		gasto.Name = "SaldoUtilizado"; gasto.Value = 0
	end

	local inv = player:FindFirstChild("VantageInventory") or Instance.new("Folder", player)
	inv.Name = "VantageInventory"
	for i = 1, 3 do
		if not inv:FindFirstChild("Vantage"..i) then
			Instance.new("IntValue", inv).Name = "Vantage"..i
		end
	end
end)

-------------------------------------------------
-- 🛒 3. LÓGICA DE COMPRA
-------------------------------------------------
BuyEvent.OnServerEvent:Connect(function(p, item)
	local custo = PRECOS[item] or 999
	local acertos = p:FindFirstChild("AcertosPorSerie")
	local leaderstats = p:FindFirstChild("leaderstats")
	local statsLoja = p:FindFirstChild("StatsLoja")
	local inv = p:FindFirstChild("VantageInventory")

	if acertos and leaderstats and statsLoja and inv then
		local totalPatrimonio = acertos.Serie6.Value + acertos.Serie7.Value + acertos.Serie8.Value + acertos.Serie9.Value + leaderstats.Camp.Value
		local jaGasto = statsLoja.SaldoUtilizado.Value

		if (totalPatrimonio - jaGasto) >= custo then
			statsLoja.SaldoUtilizado.Value += custo
			inv[item].Value += 1
		end
	end
end)

-------------------------------------------------
-- ⚡ 4. LÓGICA DE USO (COM TRAVA DE LIMITE E PERÍMETRO)
-------------------------------------------------
UseEvent.OnServerEvent:Connect(function(p, item)
	-- 1. VERIFICAÇÃO DE SEGURANÇA (PERÍMETRO E ESTADO)
	local statusArena = sistemaArena:GetAttribute("ArenaCamp")
	local char = p.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if statusArena ~= "Arena Camp ON" then return end
	if not p:GetAttribute("JaEntrou") then return end

	-- 2. NOVA TRAVA: LIMITE DE 4 USOS POR PARTIDA
	local usados = p:GetAttribute("VantagensUsadas") or 0
	if usados >= 4 then 
		warn(p.Name .. " atingiu o limite de 4 vantagens nesta partida!")
		return 
	end

	-- 3. VERIFICAÇÃO DE DISTÂNCIA
	if hrp and centroArena then
		local pPos = hrp.Position
		local centroPos = centroArena.Position
		local dentroX = math.abs(pPos.X - centroPos.X) <= (LARGURA_X / 2)
		local dentroZ = math.abs(pPos.Z - centroPos.Z) <= (PROFUNDIDADE_Z / 2)

		if not (dentroX and dentroZ) then return end
	else
		return
	end

	local inv = p:FindFirstChild("VantageInventory")
	if not inv or not inv:FindFirstChild(item) or inv[item].Value <= 0 then return end

	-- SE PASSOU POR TUDO, INCREMENTA O CONTADOR E EXECUTA
	p:SetAttribute("VantagensUsadas", usados + 1)

	local folderAnswers = workspace:FindFirstChild("ModosDeJogo") 
		and workspace.ModosDeJogo.Competitivo:FindFirstChild("Answers")

	-- 🟩 VANTAGEM 1: REVELAR (PRIVADO)
	if item == "Vantage1" then
		if folderAnswers then
			local correto = nil
			for _, bloco in pairs(folderAnswers:GetChildren()) do
				if bloco:IsA("BasePart") and bloco:GetAttribute("Correta") == true then
					correto = bloco
					break
				end
			end

			if correto then
				inv[item].Value -= 1 -- Consome o item no servidor

				local evPrivado = ReplicatedStorage:FindFirstChild("RevelarParaPlayer") or Instance.new("RemoteEvent", ReplicatedStorage)
				evPrivado.Name = "RevelarParaPlayer"

				evPrivado:FireClient(p, correto) 
				print("✨ REVELAR: Comando enviado privadamente para " .. p.Name)
			end
		end

		-- 🟥 VANTAGEM 2: ELIMINAR
	elseif item == "Vantage2" then
		if folderAnswers then
			local erradas = {}
			for _, b in pairs(folderAnswers:GetChildren()) do
				if b:IsA("BasePart") and b:GetAttribute("Correta") ~= true and b.Transparency < 1 then
					table.insert(erradas, b)
				end
			end
			if #erradas > 0 then
				inv[item].Value -= 1
				local alvo = erradas[math.random(1, #erradas)]
				local exp = Instance.new("Explosion", workspace)
				exp.Position = alvo.Position; exp.BlastRadius = 0
				local som = Instance.new("Sound", alvo)
				som.SoundId = "rbxassetid://12222084"; som:Play()
				Debris:AddItem(som, 3)
				alvo.Transparency = 1; alvo.CanCollide = false
				if alvo:FindFirstChildOfClass("SurfaceGui") then alvo:FindFirstChildOfClass("SurfaceGui").Enabled = false end
			end
		end

		-- ⏳ VANTAGEM 3: TEMPO
	elseif item == "Vantage3" then
		inv[item].Value -= 1
		AddTimeEv:Fire(10)
		local centro = workspace:FindFirstChild("SistemaArena") and workspace.SistemaArena:FindFirstChild("CentroDaArena")
		if centro then
			local somTempo = Instance.new("Sound", centro)
			somTempo.SoundId = "rbxassetid://214337110"; somTempo.Volume = 2; somTempo:Play()
			Debris:AddItem(somTempo, 4)
		end
		eventoStatusTela:FireAllClients("⏰ " .. p.DisplayName .. " ADICIONOU +10s!")
	end
end)