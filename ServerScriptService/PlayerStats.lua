local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)

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

end)