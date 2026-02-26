local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)

	-- ========================
	-- LEADERSTATS (ranking)
	-- ========================
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local pontos = Instance.new("IntValue")
	pontos.Name = "Pontos"
	pontos.Value = 0
	pontos.Parent = leaderstats

	-- ========================
	-- PLAYER STATS (PRO)
	-- ========================
	local stats = Instance.new("Folder")
	stats.Name = "PlayerStats"
	stats.Parent = player

	local serie = Instance.new("IntValue")
	serie.Name = "Serie"
	serie.Value = 0 -- ainda não escolheu
	serie.Parent = stats

	local iniciado = Instance.new("BoolValue")
	iniciado.Name = "JogoIniciado"
	iniciado.Value = false
	iniciado.Parent = stats

	local tempo = Instance.new("IntValue")
	tempo.Name = "Tempo"
	tempo.Value = 0
	tempo.Parent = stats

	-- contador de tempo jogado
	task.spawn(function()
		while player.Parent do
			if iniciado.Value then
				tempo.Value += 1
			end
			task.wait(1)
		end
	end)

	-- ========================
	-- SPAWN PROTEGIDO
	-- ========================
	player.CharacterAdded:Connect(function(character)

		local humanoid = character:WaitForChild("Humanoid")

		-- Enquanto não iniciou o jogo
		if iniciado.Value == false then
			humanoid.MaxHealth = 9999
			humanoid.Health = 9999
		else
			humanoid.MaxHealth = 100
			humanoid.Health = 100
		end

	end)

end)
