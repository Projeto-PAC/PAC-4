local PlayersService = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Config = require(script.Parent.Settings)

local TimePlayedClass = {}
TimePlayedClass.__index = TimePlayedClass

function TimePlayedClass.new()
	local self = setmetatable({}, TimePlayedClass)
	self._dataStoreName = Config.DATA_STORE
	self._boardUpdateDelay = Config.LEADERBOARD_UPDATE * 60
	self._scoreBlock = script.Parent:WaitForChild("ScoreBlock")
	self._updateBoardTimer = script.Parent:WaitForChild("UpdateBoardTimer").Timer.TextLabel

	self._ultimoLider = nil

	-- Sincronizado com o DataStore Principal
	self._rankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5")
	self._rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5") 

	self:_startLoop()
	return self
end

function TimePlayedClass:SoltarFogos()
	local somExplosao = Instance.new("Sound")
	somExplosao.SoundId = "rbxassetid://4612374921"
	somExplosao.Parent = workspace
	local posicaoBase = self._scoreBlock.Position + Vector3.new(0, 10, 0)

	for i = 1, 5 do
		task.spawn(function()
			local foguete = Instance.new("Part")
			foguete.Size = Vector3.new(1, 2, 1)
			foguete.Color = Color3.fromHSV(math.random(), 1, 1)
			foguete.CFrame = CFrame.new(posicaoBase + Vector3.new(math.random(-15, 15), 0, math.random(-15, 15)))
			foguete.CanCollide = false; foguete.Parent = workspace
			local a0 = Instance.new("Attachment", foguete); a0.Position = Vector3.new(0, 0.5, 0)
			local a1 = Instance.new("Attachment", foguete); a1.Position = Vector3.new(0, -0.5, 0)
			local rastro = Instance.new("Trail", foguete)
			rastro.Attachment0 = a0; rastro.Attachment1 = a1; rastro.Color = ColorSequence.new(foguete.Color)
			local velocity = Instance.new("LinearVelocity", foguete)
			velocity.MaxForce = math.huge; velocity.VectorVelocity = Vector3.new(0, 60, 0); velocity.Attachment0 = a0
			task.wait(1.5)
			local att = Instance.new("Attachment", workspace)
			att.CFrame = foguete.CFrame
			somExplosao:Play()
			foguete:Destroy()
			task.wait(2)
			att:Destroy()
		end)
		task.wait(0.3)
	end
end

function TimePlayedClass:_updateBoard()
	print("--- Placar 3D: Sincronizando ---")

	local success, pages = pcall(function() 
		return self._rankingGlobal:GetSortedAsync(false, 10) 
	end)

	if not success or not pages then return end

	local results = pages:GetCurrentPage()
	local gui = self._scoreBlock:WaitForChild("Leaderboard")

	-- Resetar visualização
	for i = 1, 10 do
		pcall(function()
			gui.Names["Name"..i].Visible = false
			gui.Score["Score"..i].Visible = false
			gui.Photos["Photo"..i].Visible = false
		end)
	end

	local listaParaOrdenar = {}

	for _, v in pairs(results) do
		local userIdString = v.key
		local userId = tonumber((string.gsub(userIdString, "Player_", ""))) 

		if userId and userId > 0 then
			-- USA O VALOR DO RANKING GLOBAL COMO RESERVA (Garante que o 213 apareça)
			local scoreFinal = v.value 

			local detalhes = {s6=0, s7=0, s8=0, s9=0, camp=0}
			local sDet, dataDet = pcall(function() return self._rankingStore:GetAsync(userIdString) end)

			if sDet and dataDet then
				detalhes.s6 = dataDet.Serie6 or 0
				detalhes.s7 = dataDet.Serie7 or 0
				detalhes.s8 = dataDet.Serie8 or 0
				detalhes.s9 = dataDet.Serie9 or 0
				detalhes.camp = dataDet.Camp or dataDet.Comp or 0
				-- Se carregou os detalhes, atualiza para a soma real mais precisa
				scoreFinal = detalhes.s6 + detalhes.s7 + detalhes.s8 + detalhes.s9 + detalhes.camp
			end

			local name = "Jogador"
			local thumb = "rbxassetid://15116527581"
			pcall(function()
				name = PlayersService:GetNameFromUserIdAsync(userId)
				thumb = PlayersService:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			end)

			table.insert(listaParaOrdenar, {
				userId = userId,
				name = name,
				score = scoreFinal,
				thumb = thumb
			})
		end
	end

	-- ORDENAR PARA NÃO TER ERRO
	table.sort(listaParaOrdenar, function(a, b)
		return a.score > b.score
	end)

	-- EXIBIR NA TELA
	local mod1 = script.Parent:FindFirstChild("First Place Avatar") and require(script.Parent["First Place Avatar"].PlayAnimationInRig)
	local mod2 = script.Parent:FindFirstChild("Second Place Avatar") and require(script.Parent["Second Place Avatar"].PlayAnimationInRig)
	local mod3 = script.Parent:FindFirstChild("Third Place Avatar") and require(script.Parent["Third Place Avatar"].PlayAnimationInRig)

	for k, dados in ipairs(listaParaOrdenar) do
		if gui.Names:FindFirstChild("Name"..k) then
			gui.Names["Name"..k].Text = dados.name
			gui.Score["Score"..k].Text = dados.score .. " Pts"
			gui.Photos["Photo"..k].Image = dados.thumb
			gui.Names["Name"..k].Visible = true
			gui.Score["Score"..k].Visible = true
			gui.Photos["Photo"..k].Visible = true
		end

		if k == 1 and mod1 then mod1.SetRigHumanoidDescription(dados.userId)
		elseif k == 2 and mod2 then mod2.SetRigHumanoidDescription(dados.userId)
		elseif k == 3 and mod3 then mod3.SetRigHumanoidDescription(dados.userId) end
	end
end

function TimePlayedClass:_startLoop()
	task.spawn(function()
		while true do
			self:_updateBoard()
			local count = self._boardUpdateDelay
			while count > 0 do
				self._updateBoardTimer.Text = "Próxima atualização: " .. count .. "s"
				task.wait(1)
				count -= 1
			end
		end
	end)
end

TimePlayedClass.new()