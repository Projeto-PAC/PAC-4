local DataStoreService = game:GetService("DataStoreService")
-- RANKING UNIFICADO
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5")
local rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5") 

local scrollingFrame = script.Parent 

local function criarCelula(parent, texto, cor, proporcao)
	local cell = Instance.new("TextLabel")
	cell.Size = UDim2.new(proporcao, 0, 1, 0)
	cell.Text = tostring(texto)
	cell.BackgroundColor3 = cor
	cell.BorderSizePixel = 4
	cell.BorderColor3 = Color3.new(0,0,0)
	cell.Font = Enum.Font.GothamBold
	cell.TextSize = 25 -- Ajustado para caber a nova coluna
	cell.TextColor3 = Color3.new(0, 0, 0)
	cell.Parent = parent
end

local function atualizarRanking()
	for _, child in pairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local success, pages = pcall(function()
		return RankingGlobal:GetSortedAsync(false, 10)
	end)

	if success then
		local data = pages:GetCurrentPage()
		for rank, entry in ipairs(data) do
			local userIdString = entry.key
			local totalGeral = entry.value

			-- CARREGAR TODAS AS COLUNAS
			local detalhes = {s6=0, s7=0, s8=0, s9=0, comp=0}
			local sDet, dataDet = pcall(function() return rankingStore:GetAsync(userIdString) end)
			if sDet and dataDet then
				detalhes.s6 = dataDet.Serie6 or 0
				detalhes.s7 = dataDet.Serie7 or 0
				detalhes.s8 = dataDet.Serie8 or 0
				detalhes.s9 = dataDet.Serie9 or 0
				detalhes.comp = dataDet.Comp or 0 -- NOVA COLUNA
			end

			local nome = "Jogador"
			local idApenas = string.gsub(userIdString, "Player_", "")
			pcall(function() nome = game.Players:GetNameFromUserIdAsync(tonumber(idApenas)) end)

			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 50)
			row.BackgroundTransparency = 1
			row.Parent = scrollingFrame
			Instance.new("UIListLayout", row).FillDirection = Enum.FillDirection.Horizontal

			-- AJUSTE DE PROPORÇÕES (TOTAL 1.0)
			criarCelula(row, rank.."º", Color3.fromRGB(180, 255, 180), 0.08) -- Rank
			criarCelula(row, nome, Color3.fromRGB(100, 150, 255), 0.24)      -- Nome
			criarCelula(row, detalhes.s6, Color3.fromRGB(255, 255, 100), 0.09) -- S6
			criarCelula(row, detalhes.s7, Color3.fromRGB(255, 255, 150), 0.09) -- S7
			criarCelula(row, detalhes.s8, Color3.fromRGB(255, 200, 100), 0.09) -- S8
			criarCelula(row, detalhes.s9, Color3.fromRGB(255, 150, 100), 0.09) -- S9
			criarCelula(row, detalhes.comp, Color3.fromRGB(215, 100, 255), 0.15) -- COMP (DESTAQUE)
			criarCelula(row, totalGeral, Color3.fromRGB(200, 200, 200), 0.16)    -- TOTAL
		end
	end
end

while true do atualizarRanking(); task.wait(60) end