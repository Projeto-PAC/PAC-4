local DataStoreService = game:GetService("DataStoreService")

-- RANKING UNIFICADO
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5")
local rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5") 

local scrollingFrame = script.Parent 

-- Função auxiliar para criar as colunas da linha
local function criarCelula(parent, texto, cor, proporcao)
	local cell = Instance.new("TextLabel")
	cell.Size = UDim2.new(proporcao, 0, 1, 0)
	cell.Text = tostring(texto)
	cell.BackgroundColor3 = cor
	cell.BorderSizePixel = 4
	cell.BorderColor3 = Color3.new(0,0,0)
	cell.Font = Enum.Font.GothamBold
	cell.TextSize = 22
	cell.TextColor3 = Color3.new(0, 0, 0)
	cell.Parent = parent
end

local function atualizarRanking()
	-- ==========================================================
	-- CONFIGURAÇÃO DE FILTRO (Gatekeeper)
	-- ==========================================================
	local MOSTRAR_BOTS_E_NEGATIVOS = true -- Altere para 'true' ou 'false' para testar IDs de bots
	-- ==========================================================

	-- Limpa o layout antes de carregar os 50 novos
	for _, child in pairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	-- 1. BUSCA OS 50 PRIMEIROS NO RANKING GLOBAL
	local success, pages = pcall(function()
		return RankingGlobal:GetSortedAsync(false, 50)
	end)

	if success then
		local data = pages:GetCurrentPage()
		local listaTemporaria = {} 

		-- 2. COLETAR E CALCULAR TUDO
		for _, entry in ipairs(data) do
			local userIdString = entry.key
			local idApenas = string.gsub(userIdString, "Player_", "")
			local userId = tonumber(idApenas)

			-- Validação de ID conforme sua regra
			local deveAparecer = false
			if MOSTRAR_BOTS_E_NEGATIVOS then
				if userId then deveAparecer = true end
			else
				if userId and userId > 0 then deveAparecer = true end
			end

			if deveAparecer then
				local detalhes = {s6=0, s7=0, s8=0, s9=0, camp=0}

				-- Busca os dados específicos de cada série no DataStore comum
				local sDet, dataDet = pcall(function() return rankingStore:GetAsync(userIdString) end)

				if sDet and dataDet then
					-- TRECHO DE DEBUG MANTIDO
					print("---------- DEBUG: ID " .. tostring(userId) .. " ----------")
					for chave, valor in pairs(dataDet) do
						print("CHAVE ENCONTRADA: [" .. tostring(chave) .. "] | VALOR: " .. tostring(valor))
					end

					detalhes.s6 = dataDet.Serie6 or 0
					detalhes.s7 = dataDet.Serie7 or 0
					detalhes.s8 = dataDet.Serie8 or 0
					detalhes.s9 = dataDet.Serie9 or 0
					detalhes.camp = dataDet.Camp or 0
				end

				-- Cálculo do total real para garantir precisão no sorteio
				local totalCalculado = detalhes.s6 + detalhes.s7 + detalhes.s8 + detalhes.s9 + detalhes.camp

				-- Obtenção do nome (com tratamento para bots se o ID for <= 0)
				local nome = "Jogador"
				if userId and userId > 0 then
					pcall(function() 
						nome = game.Players:GetNameFromUserIdAsync(userId) 
					end)
				else
					nome = "Bot_" .. math.abs(userId or 0)
				end

				-- Adiciona os dados processados à lista
				table.insert(listaTemporaria, {
					nome = nome,
					total = totalCalculado,
					detalhes = detalhes
				})
			end
		end

		-- 3. ORDENAÇÃO MANUAL (Garantia de integridade para 50 players)
		table.sort(listaTemporaria, function(a, b)
			return a.total > b.total
		end)

		-- 4. CONSTRUÇÃO DA INTERFACE (UI)
		for rank, info in ipairs(listaTemporaria) do
			local row = Instance.new("Frame")
			row.Name = "Posicao_" .. rank
			row.Size = UDim2.new(1, 0, 0, 50)
			row.BackgroundTransparency = 1
			row.Parent = scrollingFrame

			local layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = row

			-- Renderização das Células conforme suas proporções e cores
			criarCelula(row, rank.."º", Color3.fromRGB(180, 255, 180), 0.08)
			criarCelula(row, info.nome, Color3.fromRGB(100, 150, 255), 0.24)
			criarCelula(row, info.detalhes.s6, Color3.fromRGB(255, 255, 100), 0.09)
			criarCelula(row, info.detalhes.s7, Color3.fromRGB(255, 255, 150), 0.09)
			criarCelula(row, info.detalhes.s8, Color3.fromRGB(255, 200, 100), 0.09)
			criarCelula(row, info.detalhes.s9, Color3.fromRGB(255, 150, 100), 0.09)
			criarCelula(row, info.detalhes.camp, Color3.fromRGB(215, 100, 255), 0.15)
			criarCelula(row, info.total, Color3.fromRGB(200, 200, 200), 0.16)

			-- Otimização leve para não sobrecarregar o frame rate em listas longas
			if rank % 15 == 0 then task.wait() end
		end

		warn("✅ Ranking Top 50 atualizado. Filtro Bots: " .. tostring(MOSTRAR_BOTS_E_NEGATIVOS))
	else
		warn("❌ Erro crítico ao carregar ranking: " .. tostring(pages))
	end
end

-- LOOP DE ATUALIZAÇÃO (A cada 30 segundos)
while true do 
	atualizarRanking() 
	task.wait(30) 
end