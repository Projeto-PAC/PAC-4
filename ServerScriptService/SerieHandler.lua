local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local escolherSerie = ReplicatedStorage:WaitForChild("EscolherSerie")
local iniciarJogo = ReplicatedStorage:WaitForChild("IniciarJogo")
local setSerie = ReplicatedStorage:WaitForChild("SetSerie")
local sairDoJogo = ReplicatedStorage:WaitForChild("SairDoJogo")

-- ========================
-- ESCOLHA DE SÉRIE
-- ========================
escolherSerie.OnServerEvent:Connect(function(player, serieEscolhida)
	-- Segurança: valida série
	if typeof(serieEscolhida) ~= "number" then return end
	if serieEscolhida < 6 or serieEscolhida > 9 then return end

	-- Espera PlayerStats carregar
	local stats = player:FindFirstChild("PlayerStats")
	if not stats then return end

	local serie = stats:FindFirstChild("Serie")
	local iniciado = stats:FindFirstChild("JogoIniciado")

	if not serie or not iniciado then return end

	-- Salva a série e avisa o cliente
	serie.Value = serieEscolhida
	setSerie:FireClient(player, serieEscolhida)
	print(player.Name .. " escolheu a série " .. serieEscolhida)

	-- DELAY DE ENTRADA (Segurança para carregar a arena)
	task.delay(3, function()
		-- Jogador ainda existe?
		if not player or not player.Parent then return end

		-- Personagem pronto?
		if not player.Character then
			player.CharacterAdded:Wait()
		end

		-- Ativa o jogador no sistema para o GameManager começar
		iniciado.Value = true

		-- Garante que a vida esteja cheia ao começar
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.MaxHealth = 100
			humanoid.Health = 100
		end

		-- Avisa o cliente para fechar o menu e começar
		iniciarJogo:FireClient(player)
	end)
end)

-- ========================
-- RESET TOTAL AO SAIR (LOBBY)
-- ========================
sairDoJogo.OnServerEvent:Connect(function(player)
	local stats = player:FindFirstChild("PlayerStats")
	if stats then
		-- RESET FORÇADO: Zera a série e o iniciado para o GameManager parar o loop na hora
		stats.JogoIniciado.Value = false
		stats.Serie.Value = 0 
	end

	-- Proteção de vida ao voltar pro Lobby
	local character = player.Character
	if character and character:FindFirstChild("Humanoid") then
		character.Humanoid.MaxHealth = 100
		character.Humanoid.Health = 100

		-- Adiciona um ForceField (Escudo) invisível para garantir imortalidade no Lobby
		if not character:FindFirstChild("LobbyShield") then
			local ff = Instance.new("ForceField")
			ff.Name = "LobbyShield"
			ff.Parent = character
			ff.Visible = false -- Fica invisível, mas protege contra o script de matar
		end
	end

	print("Arena resetada via SerieHandler para " .. player.Name)
end)

-- Garante que se o jogador deslogar, o sistema limpa a conexão
Players.PlayerRemoving:Connect(function(player)
	-- O GameManager já lida com a saída de jogadores via contagem de ativos
end)