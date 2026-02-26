local Players = game:GetService("Players")
local Workspace = game.Workspace
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ========================
-- REFERÊNCIAS
-- ========================
local modosDeJogo = Workspace:WaitForChild("ModosDeJogo")
local modoInfinito = modosDeJogo:WaitForChild("Competitivo")
local arena = modoInfinito:WaitForChild("Arena")
local pontoStart = arena:WaitForChild("Start") -- Deve ser um SpawnLocation ancorado

local lobby = Workspace:WaitForChild("Lobby")
local lobbySpawn = lobby:WaitForChild("SpawnLocation")
local portal = lobby:WaitForChild("PortalInfinito")
local prompt = portal:WaitForChild("ProximityPrompt")

local sairDoJogoEvent = ReplicatedStorage:WaitForChild("SairDoJogo")

-- ========================
-- FUNÇÃO: ENTRAR NA ARENA
-- ========================
prompt.Triggered:Connect(function(player)
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then

		-- 1. Teleporta para a arena
		character.HumanoidRootPart.CFrame = pontoStart.CFrame + Vector3.new(0, 5, 0)
		character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

		-- 2. Fixa o Respawn na Arena
		player.RespawnLocation = pontoStart

		-- 3. Vínculo de segurança: Se morrer, garante o retorno ao Start da Arena
		-- Criamos uma conexão única para o personagem adicionado
		local connection
		connection = player.CharacterAdded:Connect(function(newCharacter)
			local stats = player:FindFirstChild("PlayerStats")

			-- Só puxa de volta se o jogo ainda estiver ativo (não clicou em sair)
			if stats and stats.JogoIniciado.Value == true then
				task.wait(0.1)
				local hrp = newCharacter:WaitForChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = pontoStart.CFrame + Vector3.new(0, 5, 0)
				end
			else
				-- Se o jogo parou, encerra este monitoramento específico
				connection:Disconnect()
			end
		end)

		print(player.Name .. " entrou na arena. Checkpoint fixado.")
	end
end)

-- ========================
-- FUNÇÃO: SAIR DA ARENA (Via Botão)
-- ========================
sairDoJogoEvent.OnServerEvent:Connect(function(player)
	local stats = player:FindFirstChild("PlayerStats")

	-- 1. Desativa o status de jogo (para o cronômetro e respawn de segurança)
	if stats then 
		stats.JogoIniciado.Value = false 
	end

	-- 2. Limpa o local de renascimento (volta para o Lobby)
	player.RespawnLocation = nil

	-- 3. Teleporta o jogador fisicamente para o Lobby
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = lobbySpawn.CFrame + Vector3.new(0, 5, 0)
		character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	end

	-- 4. Reset de Vida (Proteção para o Lobby)
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.MaxHealth = 9999
		humanoid.Health = 9999
	end

	print(player.Name .. " saiu da arena e o checkpoint foi resetado.")
end)