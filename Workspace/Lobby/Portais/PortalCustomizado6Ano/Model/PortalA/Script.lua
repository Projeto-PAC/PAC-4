print("Hello world!")
local players = game.Players
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ==========================================================================
-- 1. CONFIGURAÇÕES DO PORTAL
-- ==========================================================================
local MAX_PLAYERS = 50
local portal = script.Parent
local som = portal:FindFirstChild("SomTeleporte")

-- LOCALIZAÇÃO (Verifica se está dentro de 'ModosDeJogo')
-- Se a sua arena NÃO estiver dentro de ModosDeJogo, mude a linha abaixo.
local modoPasta = workspace:WaitForChild("ModosDeJogo", 10)
local arenaFolder = modoPasta and modoPasta:WaitForChild("Arena6Ano", 10)

-- Referências das Peças (Nomes originais do 6º ano)
local spawnDestino = arenaFolder and arenaFolder:WaitForChild("SpawnArena", 5)
local centroArena = arenaFolder and arenaFolder:WaitForChild("CentroDaArena", 5)
local statusValue = ReplicatedStorage:WaitForChild("StatusArena6", 5)

-- ==========================================================================
-- 2. FUNÇÃO DE CONTAGEM DE ALUNOS
-- ==========================================================================
local function contarPlayers()
	local count = 0
	if not centroArena then 
		warn("⚠️ CentroDaArena 6 não encontrado!")
		return 0 
	end

	for _, p in pairs(players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			-- Mede a distância até o centro da arena do 6º Ano
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
			statusValue.Value = "6º Ano: " .. total .. "/" .. MAX_PLAYERS
		end
		task.wait(2) -- Atualiza o placar a cada 2 segundos
	end
end)

-- ==========================================================================
-- 4. LÓGICA DE TELEPORTE (SEM TRAVAMENTOS)
-- ==========================================================================
portal.Touched:Connect(function(hit)
	local char = hit.Parent
	local p = players:GetPlayerFromCharacter(char)

	-- Só teleporta se for um player, se ele tiver corpo e se o portal não estiver em cooldown
	if p and char:FindFirstChild("HumanoidRootPart") and portal.CanTouch then
		local totalAtuais = contarPlayers()

		if totalAtuais < MAX_PLAYERS then
			portal.CanTouch = false -- Desliga o toque temporariamente (Cooldown)

			-- Tocar som de teleporte
			pcall(function()
				if som then som:Play() end
			end)

			-- Executa o Teleporte
			if spawnDestino then
				-- Move o player para a SpawnArena do 6º Ano
				char.HumanoidRootPart.CFrame = spawnDestino.CFrame + Vector3.new(0, 3, 0)
				print("✅ " .. p.Name .. " entrou na Arena 6")
			else
				warn("⚠️ ERRO: Peça 'SpawnArena' não encontrada na pasta Arena6Ano!")
			end

			task.wait(1) -- Espera 1 segundo antes de permitir outro teleporte
			portal.CanTouch = true
		else
			warn("🚨 Arena 6 está lotada!")
		end
	end
end)

-- ==========================================================================
-- ESTILIZAÇÃO DO PORTAL (NEON)
-- ==========================================================================
portal.Material = Enum.Material.Neon
portal.Transparency = 0.5