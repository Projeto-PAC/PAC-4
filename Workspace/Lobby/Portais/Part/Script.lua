local players = game.Players
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ==========================================================================
-- 1. CONFIGURAÇÕES DO PORTAL (9º ANO )
-- ==========================================================================
local MAX_PLAYERS = 50
local portal = script.Parent
local som = portal:FindFirstChild("SomTeleporte")

-- LOCALIZAÇÃO (Busca dentro da pasta ModosDeJogo)
local modoPasta = workspace:WaitForChild("ModosDeJogo", 10)
local arenaFolder = modoPasta and modoPasta:WaitForChild("Arena9Ano", 10)

-- Referências das Peças (Nomes específicos da Arena 9)
local spawnDestino = arenaFolder and arenaFolder:WaitForChild("SpawnArena9", 5) 
local centroArena = arenaFolder and arenaFolder:WaitForChild("CentroDaArena", 5)
local statusValue = ReplicatedStorage:WaitForChild("StatusArena9", 5)

-- ==========================================================================
-- 2. FUNÇÃO DE CONTAGEM DE ALUNOS
-- ==========================================================================
local function contarPlayers()
	local count = 0
	if not centroArena then 
		warn("⚠️ CentroDaArena 9 não encontrado! Verifique se a peça existe na Arena9Ano.")
		return 0 
	end

	for _, p in pairs(players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			-- Mede a distância até o centro da arena do 9º Ano
			local dist = (p.Character.HumanoidRootPart.Position - centroArena.Position).Magnitude
			if dist < 120 then 
				count += 1 
			end
		end
	end
	return count
end

-- ==========================================================================
-- 3. ATUALIZAÇÃO DO STATUS (TEXTO NO MENU DO LOBBY)
-- ==========================================================================
task.spawn(function()
	while true do
		local total = contarPlayers()
		if statusValue and statusValue:IsA("StringValue") then
			-- Atualiza o valor que aparece para os jogadores no menu principal
			statusValue.Value = "9º Ano: " .. total .. "/" .. MAX_PLAYERS
		end
		task.wait(2) -- Atualiza a cada 2 segundos para manter o servidor leve
	end
end)

-- ==========================================================================
-- 4. LÓGICA DE TELEPORTE SEGURO (PARA SPAWNARENA9)
-- ==========================================================================
portal.Touched:Connect(function(hit)
	local char = hit.Parent
	local p = players:GetPlayerFromCharacter(char)

	-- Só teleporta se for um jogador, se tiver corpo e se o portal estiver pronto
	if p and char:FindFirstChild("HumanoidRootPart") and portal.CanTouch then
		local totalAtuais = contarPlayers()

		if totalAtuais < MAX_PLAYERS then
			portal.CanTouch = false -- Inicia o tempo de espera (Cooldown)

			-- Tocar som de teleporte 
			pcall(function()
				if som then som:Play() end
			end)

			-- Executa o Teleporte para a peça SpawnArena9
			if spawnDestino then
				-- Move o jogador 3 studs acima do ponto para evitar que ele prenda no chão
				char.HumanoidRootPart.CFrame = spawnDestino.CFrame + Vector3.new(0, 3, 0)
				print("✅ " .. p.Name .. " entrou na Arena do 9º Ano (Veterano)")
			else
				warn("⚠️ ERRO: Peça 'SpawnArena9' não encontrada na pasta Arena9Ano!")
			end

			task.wait(1) -- Espera 1 segundo para o portal aceitar o próximo aluno
			portal.CanTouch = true
		else
			-- Aviso caso a arena de elite esteja cheia
			warn("🚨 Arena 9 está lotada no momento!")
		end
	end
end)

-- ==========================================================================
-- ESTILIZAÇÃO DO PORTAL (OURO NEON - ELITE)
-- ==========================================================================
portal.Material = Enum.Material.Neon
portal.Transparency = 0.5
portal.Color = Color3.fromRGB(255, 170, 0) -- Dourado para o último ano!