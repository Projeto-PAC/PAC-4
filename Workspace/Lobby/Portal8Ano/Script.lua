local players = game.Players
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ==========================================================================
-- 1. CONFIGURAÇÕES DO PORTAL (8º ANO)
-- ==========================================================================
local MAX_PLAYERS = 50
local portal = script.Parent
local som = portal:FindFirstChild("SomTeleporte")

-- LOCALIZAÇÃO (Busca dentro da pasta ModosDeJogo)
local modoPasta = workspace:WaitForChild("ModosDeJogo", 10)
local arenaFolder = modoPasta and modoPasta:WaitForChild("Arena8Ano", 10)

-- Referências das Peças (Nomes específicos da Arena 8)
local spawnDestino = arenaFolder and arenaFolder:WaitForChild("SpawnArena8", 5) 
local centroArena = arenaFolder and arenaFolder:WaitForChild("CentroDaArena", 5)
local statusValue = ReplicatedStorage:WaitForChild("StatusArena8", 5)

-- ==========================================================================
-- 2. FUNÇÃO DE CONTAGEM DE ALUNOS 
-- ==========================================================================
local function contarPlayers()
	local count = 0
	if not centroArena then 
		warn("⚠️ CentroDaArena 8 não encontrado!")
		return 0 
	end

	for _, p in pairs(players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			-- Mede a distância até o centro da arena do 8º Ano
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
			-- Atualiza o valor que aparece para os jogadores no menu
			statusValue.Value = "8º Ano: " .. total .. "/" .. MAX_PLAYERS
		end
		task.wait(2) -- Atualiza a cada 2 segundos para evitar lag
	end
end)

-- ==========================================================================
-- 4. LÓGICA DE TELEPORTE SEGURO (PARA SPAWNARENA8)
-- ==========================================================================
portal.Touched:Connect(function(hit)
	local char = hit.Parent
	local p = players:GetPlayerFromCharacter(char)

	-- Verifica se é um jogador real e se o portal não está em tempo de espera
	if p and char:FindFirstChild("HumanoidRootPart") and portal.CanTouch then
		local totalAtuais = contarPlayers()

		if totalAtuais < MAX_PLAYERS then
			portal.CanTouch = false -- Bloqueia o toque temporariamente (Cooldown)

			-- Tocar som de teleporte com proteção de erro
			pcall(function()
				if som then som:Play() end
			end)

			-- Executa o Teleporte para a peça SpawnArena8
			if spawnDestino then
				-- Move o jogador 3 studs acima da peça para não bugar no chão
				char.HumanoidRootPart.CFrame = spawnDestino.CFrame + Vector3.new(0, 3, 0)
				print("✅ " .. p.Name .. " teleportado para Arena 8")
			else
				warn("⚠️ ERRO: Peça 'SpawnArena8' não encontrada na pasta Arena8Ano!")
			end

			task.wait(1) -- Espera 1 segundo para liberar o portal novamente
			portal.CanTouch = true
		else
			-- Aviso caso a arena esteja cheia
			warn("🚨 Arena 8 está lotada!")
		end
	end
end)

-- ==========================================================================
-- ESTILIZAÇÃO DO PORTAL (AZUL NEON / Roxo para diferenciar)
-- ==========================================================================
portal.Material = Enum.Material.Neon
portal.Transparency = 0.5
portal.Color = Color3.fromRGB(170, 85, 255) -- Um roxo neon para o 8º ano