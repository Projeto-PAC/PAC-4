local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Bancos de Dados
local rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5")
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5")

Players.PlayerAdded:Connect(function(p)
	-- 1. Cria a leaderstats (Visual do Placar e Parede)
	local leaderstats = Instance.new("Folder", p); leaderstats.Name = "leaderstats"

	local s6 = Instance.new("IntValue", leaderstats); s6.Name = "6º Ano"
	local s7 = Instance.new("IntValue", leaderstats); s7.Name = "7º Ano"
	local s8 = Instance.new("IntValue", leaderstats); s8.Name = "8º Ano"
	local s9 = Instance.new("IntValue", leaderstats); s9.Name = "9º Ano"
	local camp = Instance.new("IntValue", leaderstats); camp.Name = "Camp"
	local total = Instance.new("IntValue", leaderstats); total.Name = "Total"

	-- 2. Pasta interna para as Arenas (AcertosPorSerie)
	local acertosFolder = Instance.new("Folder", p); acertosFolder.Name = "AcertosPorSerie"
	local i6 = Instance.new("IntValue", acertosFolder); i6.Name = "Serie6"
	local i7 = Instance.new("IntValue", acertosFolder); i7.Name = "Serie7"
	local i8 = Instance.new("IntValue", acertosFolder); i8.Name = "Serie8"
	local i9 = Instance.new("IntValue", acertosFolder); i9.Name = "Serie9"

	-- ==================================================
	-- 🚀 CALCULADORA REAL-TIME (SOMA TUDO + CAMP)
	-- ==================================================
	-- 1. Remova o RankingGlobal:SetAsync de dentro da função atualizarTudo
	local function atualizarTudo()
		s6.Value = i6.Value
		s7.Value = i7.Value
		s8.Value = i8.Value
		s9.Value = i9.Value

		local somaTotal = i6.Value + i7.Value + i8.Value + i9.Value + camp.Value
		total.Value = somaTotal
		-- REMOVIDO: RankingGlobal:SetAsync daqui de dentro!
	end

	-- 2. Adicione este loop de salvamento (salva a cada 60 segundos)
	task.spawn(function()
		while p.Parent do
			task.wait(60) -- Salva a cada 1 minuto para não dar lag
			pcall(function()
				RankingGlobal:SetAsync("Player_" .. p.UserId, total.Value)
				print("💾 Dados de " .. p.Name .. " sincronizados com o Ranking Global.")
			end)
		end
	end)

	-- ESCUTADORES (Gatilhos): Se qualquer um dos 5 mudar, ele soma na hora
	i6.Changed:Connect(atualizarTudo)
	i7.Changed:Connect(atualizarTudo)
	i8.Changed:Connect(atualizarTudo)
	i9.Changed:Connect(atualizarTudo)
	camp.Changed:Connect(atualizarTudo) -- O Camp agora acorda a calculadora!

	-- 3. CARREGAR DADOS SALVOS
	local success, data = pcall(function() return rankingStore:GetAsync("Player_" .. p.UserId) end)
	if success and data then
		i6.Value = data.Serie6 or 0
		i7.Value = data.Serie7 or 0
		i8.Value = data.Serie8 or 0
		i9.Value = data.Serie9 or 0
		camp.Value = data.Comp or 0 -- Nome que o seu telão usa no banco
		atualizarTudo()
	end
end)

-- Salvar ao Sair
Players.PlayerRemoving:Connect(function(p)
	local acertos = p:FindFirstChild("AcertosPorSerie")
	local leaderstats = p:FindFirstChild("leaderstats")
	if acertos and leaderstats then
		pcall(function()
			rankingStore:SetAsync("Player_" .. p.UserId, {
				Serie6 = acertos.Serie6.Value,
				Serie7 = acertos.Serie7.Value,
				Serie8 = acertos.Serie8.Value,
				Serie9 = acertos.Serie9.Value,
				Camp = leaderstats.Camp.Value
			})
		end)
	end
end)