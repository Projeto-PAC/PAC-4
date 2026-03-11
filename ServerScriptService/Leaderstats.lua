local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Bancos de Dados
local rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5")
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5")

local function setupPlayerData(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Valores que aparecem na tela (Nomes amigáveis)
	local s6 = Instance.new("IntValue", leaderstats); s6.Name = "6º Ano"
	local s7 = Instance.new("IntValue", leaderstats); s7.Name = "7º Ano"
	local s8 = Instance.new("IntValue", leaderstats); s8.Name = "8º Ano"
	local s9 = Instance.new("IntValue", leaderstats); s9.Name = "9º Ano"
	local camp = Instance.new("IntValue", leaderstats); camp.Name = "Camp"
	local total = Instance.new("IntValue", leaderstats); total.Name = "Total"

	-- Função que soma tudo automaticamente
	local function atualizarTotal()
		total.Value = s6.Value + s7.Value + s8.Value + s9.Value + camp.Value
	end

	-- Conecta a mudança de qualquer valor ao Total
	s6.Changed:Connect(atualizarTotal)
	s7.Changed:Connect(atualizarTotal)
	s8.Changed:Connect(atualizarTotal)
	s9.Changed:Connect(atualizarTotal)
	camp.Changed:Connect(atualizarTotal)

	-- Tenta carregar os dados salvos
	local success, data = pcall(function()
		return rankingStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and data then
		-- Mapeia os nomes do Banco de Dados para os nomes da Tela
		s6.Value = data.Serie6 or 0
		s7.Value = data.Serie7 or 0
		s8.Value = data.Serie8 or 0
		s9.Value = data.Serie9 or 0
		camp.Value = data.Comp or 0
		print("✅ Dados de " .. player.Name .. " carregados!")
	else
		warn("🆕 Novo jogador ou erro de rede para: " .. player.Name)
	end
end

local function savePlayerData(player)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local dataToSave = {
			Serie6 = stats["6º Ano"].Value,
			Serie7 = stats["7º Ano"].Value,
			Serie8 = stats["8º Ano"].Value,
			Serie9 = stats["9º Ano"].Value,
			Comp = stats.Camp.Value
		}

		local success, err = pcall(function()
			-- Salva os detalhes na tabela
			rankingStore:SetAsync("Player_" .. player.UserId, dataToSave)
			-- Salva o Total no Ranking Global (OrderedDataStore)
			RankingGlobal:SetAsync("Player_" .. player.UserId, stats.Total.Value)
		end)

		if success then
			print("💾 Dados de " .. player.Name .. " salvos com sucesso!")
		else
			warn("❌ Erro ao salvar dados de " .. player.Name .. ": " .. err)
		end
	end
end

-- Eventos de conexão
game.Players.PlayerAdded:Connect(setupPlayerData)
game.Players.PlayerRemoving:Connect(savePlayerData)

-- Garante que salve se o servidor fechar do nada (Studio ou queda de servidor)
game:BindToClose(function()
	for _, player in pairs(game.Players:GetPlayers()) do
		savePlayerData(player)
	end
	task.wait(2) -- Tempo para o Roblox processar os salvamentos
end)

-- Loop extra para casos onde o player entra antes do script carregar (comum no Studio)
for _, player in pairs(game.Players:GetPlayers()) do
	setupPlayerData(player)
end