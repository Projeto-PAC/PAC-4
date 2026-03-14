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

	-- Memória para os fogos de artifício
	self._ultimoLider = nil

	-- IGUAL AO RANKING SERVER: Carrega os dois bancos
	self._rankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5")
	self._rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5") 

	self:_startLoop()
	return self
end

function TimePlayedClass:SoltarFogos()
	print("🎆 FESTA! Temos um novo líder no ranking!")
	local somExplosao = Instance.new("Sound")
	somExplosao.SoundId = "rbxassetid://138542306"
	somExplosao.Parent = workspace

	local posicaoBase = script.Parent.Parent.Position + Vector3.new(0, 5, 5)

	for i = 1, 5 do
		task.spawn(function()
			local foguete = Instance.new("Part")
			foguete.Size = Vector3.new(1, 2, 1)
			foguete.Color = Color3.fromHSV(math.random(), 1, 1)
			foguete.CFrame = CFrame.new(posicaoBase + Vector3.new(math.random(-10, 10), 0, math.random(-5, 5)))
			foguete.CanCollide = false
			foguete.Parent = workspace

			local a0 = Instance.new("Attachment", foguete); a0.Position = Vector3.new(0, 0.5, 0)
			local a1 = Instance.new("Attachment", foguete); a1.Position = Vector3.new(0, -0.5, 0)

			local rastro = Instance.new("Trail")
			rastro.Attachment0 = a0; rastro.Attachment1 = a1
			rastro.Color = ColorSequence.new(foguete.Color)
			rastro.Parent = foguete

			local velocity = Instance.new("LinearVelocity", foguete)
			velocity.MaxForce = math.huge
			velocity.VectorVelocity = Vector3.new(0, 50, 0)
			velocity.Attachment0 = a0

			task.wait(1.5)

			local explosao = Instance.new("ParticleEmitter")
			explosao.Texture = "rbxassetid://6034117070"
			explosao.Color = ColorSequence.new(foguete.Color)
			explosao.Size = NumberSequence.new({NumberKeypoint.new(0, 5), NumberKeypoint.new(1, 0)})
			explosao.Lifetime = NumberRange.new(1, 2)
			explosao.Rate = 0 
			explosao.Speed = NumberRange.new(20, 40)

			local attachmentExplosao = Instance.new("Attachment", workspace)
			attachmentExplosao.CFrame = foguete.CFrame
			explosao.Parent = attachmentExplosao

			somExplosao:Play()
			foguete:Destroy()

			explosao:Emit(100)
			task.wait(2)
			attachmentExplosao:Destroy()
		end)
		task.wait(0.3)
	end
end

function TimePlayedClass:_updateBoard()
	print("--- Atualizando Placa e Pódio (Lógica Calculada) ---")

	-- 1. Busca os tops no Ranking Global
	local success, pages = pcall(function() 
		return self._rankingGlobal:GetSortedAsync(false, 10) 
	end)

	if not success or not pages then 
		warn("Erro ao buscar dados: ", pages)
		return 
	end

	local results = pages:GetCurrentPage()
	local gui = self._scoreBlock:WaitForChild("Leaderboard")

	-- Esconde as linhas antes de atualizar
	for i = 1, 10 do
		pcall(function()
			gui.Names["Name"..i].Visible = false
			gui.Score["Score"..i].Visible = false
			gui.Photos["Photo"..i].Visible = false
		end)
	end

	local mod1 = script.Parent:FindFirstChild("First Place Avatar") and require(script.Parent["First Place Avatar"].PlayAnimationInRig)
	local mod2 = script.Parent:FindFirstChild("Second Place Avatar") and require(script.Parent["Second Place Avatar"].PlayAnimationInRig)
	local mod3 = script.Parent:FindFirstChild("Third Place Avatar") and require(script.Parent["Third Place Avatar"].PlayAnimationInRig)

	for k, v in pairs(results) do
		local userIdString = v.key
		local userId = tonumber((string.gsub(userIdString, "Player_", ""))) 

		if userId and userId > 0 then
			-- 2. LÓGICA DO RANKING SERVER: Busca os detalhes para somar o Total Real
			local detalhes = {s6=0, s7=0, s8=0, s9=0, comp=0}
			local sDet, dataDet = pcall(function() return self._rankingStore:GetAsync(userIdString) end)

			if sDet and dataDet then
				detalhes.s6 = dataDet.Serie6 or 0
				detalhes.s7 = dataDet.Serie7 or 0
				detalhes.s8 = dataDet.Serie8 or 0
				detalhes.s9 = dataDet.Serie9 or 0
				detalhes.comp = dataDet.Comp or dataDet.Camp or 0 -- Aceita os dois nomes
			end

			-- CALCULA O TOTAL REAL IGUAL AO PAINEL 2D
			local totalCalculado = detalhes.s6 + detalhes.s7 + detalhes.s8 + detalhes.s9 + detalhes.comp

			local name = "Jogador"
			local thumb = "rbxassetid://15116527581"

			pcall(function()
				name = PlayersService:GetNameFromUserIdAsync(userId)
				thumb = PlayersService:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			end)

			-- Atualiza a UI com o TOTAL CALCULADO
			if gui.Names:FindFirstChild("Name"..k) then
				gui.Names["Name"..k].Text = name
				gui.Score["Score"..k].Text = totalCalculado .. " Pts"
				gui.Photos["Photo"..k].Image = thumb
				gui.Names["Name"..k].Visible = true
				gui.Score["Score"..k].Visible = true
				gui.Photos["Photo"..k].Visible = true
			end

			-- Atualiza os Avatares
			if k == 1 and mod1 then mod1.SetRigHumanoidDescription(userId)
			elseif k == 2 and mod2 then mod2.SetRigHumanoidDescription(userId)
			elseif k == 3 and mod3 then mod3.SetRigHumanoidDescription(userId) end
		end
	end

	-- 🚀 LÓGICA DOS FOGOS
	local liderAtual = results[1] and results[1].key
	if liderAtual then
		if self._ultimoLider and self._ultimoLider ~= liderAtual then
			self:SoltarFogos()
		end
		self._ultimoLider = liderAtual
	end

	print("Placa e Pódio sincronizados com a soma real!")
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