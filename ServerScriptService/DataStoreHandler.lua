local DataStoreService = game:GetService("DataStoreService")
local rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5")
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5")

game.Players.PlayerAdded:Connect(function(player)
	-- 1. CRIAR AS PASTAS (Se elas já não existirem por outro script)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"

	local acertos = player:FindFirstChild("AcertosPorSerie") or Instance.new("Folder", player)
	acertos.Name = "AcertosPorSerie"

	-- 2. CRIAR OS VALORES
	local function criarValor(nome, parent)
		local val = parent:FindFirstChild(nome) or Instance.new("IntValue", parent)
		val.Name = nome
		return val
	end

	local s6 = criarValor("Serie6", acertos)
	local s7 = criarValor("Serie7", acertos)
	local s8 = criarValor("Serie8", acertos)
	local s9 = criarValor("Serie9", acertos)
	local camp = criarValor("Camp", leaderstats)
	local total = criarValor("Total", leaderstats)

	-- 3. CARREGAR DADOS DA NUVEM (O PULO DO GATO)
	local key = "Player_" .. player.UserId
	local success, data = pcall(function()
		return rankingStore:GetAsync(key)
	end)

	if success and data then
		-- Se achou dados salvos, coloca eles nos valores do jogador
		s6.Value = data.Serie6 or 0
		s7.Value = data.Serie7 or 0
		s8.Value = data.Serie8 or 0
		s9.Value = data.Serie9 or 0
		camp.Value = data.Camp or 0

		-- Atualiza o total para o ranking
		total.Value = s6.Value + s7.Value + s8.Value + s9.Value + camp.Value
		print("Dados carregados para " .. player.Name)
	else
		print("Novo jogador ou erro ao carregar: " .. player.Name)
	end
end)

-- 4. SALVAR AO SAIR (Importante para não perder nada)
game.Players.PlayerRemoving:Connect(function(player)
	local key = "Player_" .. player.UserId
	local stats = player.leaderstats
	local acertos = player.AcertosPorSerie

	local dadosParaSalvar = {
		Serie6 = acertos.Serie6.Value,
		Serie7 = acertos.Serie7.Value,
		Serie8 = acertos.Serie8.Value,
		Serie9 = acertos.Serie9.Value,
		Camp = stats.Camp.Value
	}

	pcall(function()
		rankingStore:SetAsync(key, dadosParaSalvar)
		RankingGlobal:SetAsync(key, stats.Total.Value)
	end)
end)
