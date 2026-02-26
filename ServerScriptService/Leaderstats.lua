local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5")
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5") 

local eventoIniciar = ReplicatedStorage:WaitForChild("IniciarArena")

game.Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"

	local s6 = Instance.new("IntValue", leaderstats); s6.Name = "6º Ano"
	local s7 = Instance.new("IntValue", leaderstats); s7.Name = "7º Ano"
	local s8 = Instance.new("IntValue", leaderstats); s8.Name = "8º Ano"
	local s9 = Instance.new("IntValue", leaderstats); s9.Name = "9º Ano"
	local camp = Instance.new("IntValue", leaderstats); camp.Name = "Camp"
	local arena6 = Instance.new("IntValue", leaderstats); arena6.Name = "Arena6Ano" -- UNIFICADO
	local total = Instance.new("IntValue", leaderstats); total.Name = "Total"

	local function atualizarTotal()
		total.Value = s6.Value + s7.Value + s8.Value + s9.Value + camp.Value + arena6.Value
	end
	s6.Changed:Connect(atualizarTotal); s7.Changed:Connect(atualizarTotal)
	s8.Changed:Connect(atualizarTotal); s9.Changed:Connect(atualizarTotal)
	camp.Changed:Connect(atualizarTotal); arena6.Changed:Connect(atualizarTotal)

	local success, data = pcall(function()
		return rankingStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and data and type(data) == "table" then
		s6.Value = data.Serie6 or 0
		s7.Value = data.Serie7 or 0
		s8.Value = data.Serie8 or 0
		s9.Value = data.Serie9 or 0
		camp.Value = data.Comp or 0
		arena6.Value = data.Arena6Ano or 0
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local data = {
			Serie6 = stats["6º Ano"].Value,
			Serie7 = stats["7º Ano"].Value,
			Serie8 = stats["8º Ano"].Value,
			Serie9 = stats["9º Ano"].Value,
			Comp = stats.Camp.Value,
			Arena6Ano = stats.Arena6Ano.Value
		}
		pcall(function()
			rankingStore:SetAsync("Player_" .. player.UserId, data)
			RankingGlobal:SetAsync("Player_" .. player.UserId, stats.Total.Value)
		end)
	end
end)

_G.DarVitoria = function(player, quantidade)
	if player and player:FindFirstChild("leaderstats") then
		player.leaderstats.Camp.Value += (quantidade or 100)
		eventoIniciar:FireAllClients("RESET_TOTAL") 
	end
end