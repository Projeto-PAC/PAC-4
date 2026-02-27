local workspace = game.Workspace
local players = game.Players
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- ==========================================
-- 1. BANCO DE DADOS E EVENTOS
-- ==========================================
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5")
local eventoIniciar = ReplicatedStorage:WaitForChild("IniciarArena")
local remoteEscolher = ReplicatedStorage:WaitForChild("EscolherSerie")

_G.PodioFila = {} 

local modoCompetitivo = workspace:WaitForChild("ModosDeJogo"):WaitForChild("Competitivo")
local sistemaArena = workspace:WaitForChild("SistemaArena") 
local questionBoard = modoCompetitivo:WaitForChild("QuestionBoard")
local timerBoard = modoCompetitivo:WaitForChild("TimerBoard")
local answersFolder = modoCompetitivo:WaitForChild("Answers")

local questionLabel = questionBoard.SurfaceGui.TextLabel
local timerLabel = timerBoard.SurfaceGui.TextLabel

local portas = {
	sistemaArena:WaitForChild("Porta1"), 
	sistemaArena:WaitForChild("Porta2"), 
	sistemaArena:WaitForChild("Porta3")
}

local totalBlocos = 324 
local blocosPorGrupo = 9
local rodadaAtiva = false
local aguardandoJogadores = true 

local startSound = timerBoard:FindFirstChild("Start")
local CoresAleatorias = {
	Color3.fromRGB(255, 85, 0), Color3.fromRGB(0, 170, 255),
	Color3.fromRGB(85, 255, 127), Color3.fromRGB(255, 170, 0),
	Color3.fromRGB(170, 85, 255), Color3.fromRGB(0, 255, 255)
}

-- ==========================================
-- 2. ESTILIZAÇÃO E GERADORES
-- ==========================================
local function aplicarEstilo()
	local uiStrokeT = timerLabel:FindFirstChild("UIStroke") or Instance.new("UIStroke", timerLabel)
	timerLabel.Font = Enum.Font.FredokaOne; timerLabel.TextColor3 = Color3.fromRGB(240, 240, 240) 
	uiStrokeT.Color = Color3.fromRGB(100, 150, 255); uiStrokeT.Thickness = 3 
	local uiStrokeQ = questionLabel:FindFirstChild("UIStroke") or Instance.new("UIStroke", questionLabel)
	questionLabel.Font = Enum.Font.FredokaOne; questionLabel.TextColor3 = Color3.fromRGB(255, 255, 255) 
	uiStrokeQ.Color = Color3.fromRGB(120, 200, 150); uiStrokeQ.Thickness = 3 
end
aplicarEstilo()

local Geradores = {
	[6] = { Facil = { tempo = 20, f = function() local a, b = math.random(50,200), math.random(30,100) return {txt=a.." + "..b, res=a+b} end }, Medio = { tempo = 23, f = function() local a, b = math.random(12,40), math.random(6,15) return {txt=a.." x "..b, res=a*b} end }, Dificil = { tempo = 40, f = function() local a, b = math.random(100,600)/10, math.random(50,250)/10 return {txt=a.." + "..b.." - 5.5", res=a+b-5.5} end } },
	[7] = { Facil = { tempo = 20, f = function() local a, b = math.random(-30,30), math.random(-30,30) return {txt=a.." + ("..b..")", res=a+b} end }, Medio = { tempo = 30, f = function() local x = math.random(5,25); local c = math.random(10,50) return {txt="x + "..c.." = "..(x+c), res=x} end }, Dificil = { tempo = 40, f = function() local a, x, c = math.random(2,6), math.random(5,20), math.random(1,30) return {txt=a.."x + "..c.." = "..(a*x+c), res=x} end } },
	[8] = { Facil = { tempo = 20, f = function() local n = math.random(2,16) return {txt="√"..(n*n), res=n} end }, Medio = { tempo = 30, f = function() local b, e = math.random(2,5), math.random(2,4) return {txt=b.."^"..e, res=math.pow(b,e)} end }, Dificil = { tempo = 40, f = function() local a, b = math.random(3,12), math.random(3,12) return {txt="√"..(a*a).." + √"..(b*b), res=a+b} end } },
	[9] = { Facil = { tempo = 20, f = function() local x = math.random(1,18) return {txt="x² = "..(x*x), res=x} end }, Medio = { tempo = 30, f = function() local a = math.random(1,15) return {txt=a.." x 10³", res=a*1000} end }, Dificil = { tempo = 40, f = function() local x1, x2 = math.random(1,6), math.random(1,6); local b = -(x1 + x2); local c = x1 * x2 return {txt="x² ".. (b>=0 and "+ "..b or b) .."x + "..c.." = 0", res=x1} end } }
}

-- ==========================================
-- 3. LOGICA DE JOGADORES E PONTOS
-- ==========================================
local function getJogadoresAtivos()
	local ativos = {}
	for _, p in pairs(players:GetPlayers()) do
		local stats = p:FindFirstChild("PlayerStats")
		if stats and stats.JogoIniciado.Value == true then
			local char = p.Character
			if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
				table.insert(ativos, p)
			end
		end
	end
	return ativos
end

local function registrarEntrada(p)
	local stats = p:FindFirstChild("PlayerStats")
	if stats and stats.JogoIniciado.Value == false and aguardandoJogadores then
		p:SetAttribute("JaEntrou", true)
		stats.JogoIniciado.Value = true
		eventoIniciar:FireClient(p, "PRENDER_INDIVIDUAL")
		print("✅ " .. p.Name .. " entrou.")
	end
end

local function distribuirPremiosRanked()
	local vencedor = _G.PodioFila[#_G.PodioFila]
	if vencedor and vencedor:FindFirstChild("leaderstats") then 
		local pontos = vencedor.leaderstats:FindFirstChild("Total") or vencedor.leaderstats:FindFirstChild("Pontos")
		if pontos then
			pontos.Value += 100 
			pcall(function() RankingGlobal:SetAsync("Player_" .. vencedor.UserId, pontos.Value) end)
		end
	end
end

-- ==========================================
-- 4. CICLO DE ROUND (RESISTENTE A MORTES E BLOCOS)
-- ==========================================
local function executarRound(serie, dificuldade)
	local dados = Geradores[serie][dificuldade]
	local q = dados.f()
	questionLabel.Text = "["..dificuldade.."] "..q.txt.." ("..serie.."º Ano)"
	local corretaNum = tonumber(q.res) or 0
	local posCertas = {}
	for g = 0, 35 do posCertas[g] = math.random(1, 9) end
	for i = 1, totalBlocos do
		local b = answersFolder:FindFirstChild("Answer"..i)
		if b then
			local ehCerto = (((i-1)%9)+1 == posCertas[math.floor((i-1)/9)])
			b:SetAttribute("Correta", ehCerto); b.Transparency = 0; b.CanCollide = true; b.Material = Enum.Material.Neon
			local cor = CoresAleatorias[math.random(1, #CoresAleatorias)]
			b.Color = Color3.new(cor.R * 0.4, cor.G * 0.4, cor.B * 0.4) 
			local lbl = b.SurfaceGui:FindFirstChildWhichIsA("TextLabel")
			if lbl then lbl.Text = tostring(ehCerto and corretaNum or (corretaNum + math.random(-30, 30))) end
		end
	end
	rodadaAtiva = true
	for t = dados.tempo, 0, -1 do
		timerLabel.Text = tostring(t); task.wait(1)
		local ativos = getJogadoresAtivos()
		if #ativos == 0 then break end 
		if #ativos == 1 and t > 2 then task.wait(1); break end
	end
	rodadaAtiva = false
	for i = 1, totalBlocos do
		local b = answersFolder:FindFirstChild("Answer"..i)
		if b and not b:GetAttribute("Correta") then b.Transparency = 1; b.CanCollide = false end
	end
	task.wait(4)

	-- 🔴 RESET DOS BLOCOS (Garante que a arena volte para o próximo round/ciclo)
	for i = 1, totalBlocos do
		local b = answersFolder:FindFirstChild("Answer"..i)
		if b then b.Transparency = 0; b.CanCollide = true end
	end

	local ativosPosQueda = getJogadoresAtivos()
	if #ativosPosQueda == 0 then return "MORTE_TOTAL" end

	for _, p in pairs(ativosPosQueda) do
		local stats = p:FindFirstChild("leaderstats")
		if stats then
			local sVal = stats:FindFirstChild(serie .. "º Ano")
			if sVal then sVal.Value += 1 end 
		end
	end
	return (#ativosPosQueda <= 1 and "FIM" or "CONTINUA")
end

-- ==========================================
-- 5. LOOP INFINITO (COM TRANCA FÍSICA E MORTE SÚBITA)
-- ==========================================
local function rodarCicloCompeticao()
	while true do
		-- --- A) LOBBY (ARENA ABERTA) ---
		aguardandoJogadores = true
		_G.PodioFila = {}
		for _, p in pairs(players:GetPlayers()) do
			p:SetAttribute("JaEntrou", nil)
			local ps = p:FindFirstChild("PlayerStats")
			if ps then ps.JogoIniciado.Value = false end
		end
		-- FÍSICA: Abre portas no Servidor (Atravessável)
		for _, porta in pairs(portas) do
			porta.CanCollide = false; porta.Transparency = 0.8; porta.Color = Color3.fromRGB(0, 255, 0)
		end
		eventoIniciar:FireAllClients("RESET_TOTAL")
		questionLabel.Text = "ARENA LIBERADA! ENTREM!"

		repeat 
			task.wait(1) 
			for _, p in pairs(players:GetPlayers()) do
				local char = p.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					local dist = (char.HumanoidRootPart.Position - questionBoard.Position).Magnitude
					if dist < 85 then registrarEntrada(p) end
				end
			end
		until #getJogadoresAtivos() >= 2

		if startSound then startSound:Play() end
		for i = 10, 1, -1 do timerLabel.Text = tostring(i); questionLabel.Text = "INICIANDO EM "..i.."S"; task.wait(1) end

		-- --- B) JOGO (ARENA TRANCA FÍSICA) ---
		aguardandoJogadores = false 
		-- FÍSICA: Tranca portas no Servidor (Quem renascer não atravessa a parede vermelha)
		for _, porta in pairs(portas) do
			porta.CanCollide = true; porta.Transparency = 0; porta.Color = Color3.fromRGB(255, 0, 0)
		end
		eventoIniciar:FireAllClients("FECHAR_ARENA_VERMELHO")

		local statusPartida = "CONTINUA"
		-- RODADAS PADRÃO (6º AO 9º ANO)
		for _, dif in ipairs({"Facil", "Medio", "Dificil"}) do
			for serie = 6, 9 do
				statusPartida = executarRound(serie, dif)
				if statusPartida == "FIM" or statusPartida == "MORTE_TOTAL" then break end
			end
			if statusPartida == "FIM" or statusPartida == "MORTE_TOTAL" then break end
		end

		-- --- C) MORTE SÚBITA (O RETORNO) ---
		if statusPartida == "CONTINUA" and #getJogadoresAtivos() > 1 then
			warn("⚠️ Iniciando Morte Súbita!")
			while #getJogadoresAtivos() > 1 do
				questionLabel.Text = "⚠️ MORTE SÚBITA! ⚠️"
				task.wait(2)
				statusPartida = executarRound(9, "Dificil")
				if statusPartida == "MORTE_TOTAL" then break end
			end
		end

		-- --- D) RESULTADO ---
		local sobreviventes = getJogadoresAtivos()
		if #sobreviventes == 1 then 
			local vencedor = sobreviventes[1]
			table.insert(_G.PodioFila, vencedor)
			distribuirPremiosRanked()
			questionLabel.Text = "🏆 VENCEDOR: " .. vencedor.Name
		else 
			questionLabel.Text = "💀 SEM VENCEDORES NESTA RODADA"
		end

		-- 📢 A PAREDE CONTINUA VERMELHA E SÓLIDA ATÉ O LOOP VOLTAR AO INÍCIO
		task.wait(7) 
	end
end

-- SENSORES
for i = 1, 3 do
	local s = sistemaArena:FindFirstChild("SensorArena"..i)
	if s then s.Touched:Connect(function(hit) 
			local p = players:GetPlayerFromCharacter(hit.Parent)
			if p then registrarEntrada(p) end
		end) end
end

for i = 1, totalBlocos do
	local b = answersFolder:FindFirstChild("Answer"..i)
	if b then b.Touched:Connect(function(hit)
			if not rodadaAtiva then return end
			local p = players:GetPlayerFromCharacter(hit.Parent)
			if p then p:SetAttribute("EscolhaCorreta", b:GetAttribute("Correta")) end
		end) end
end

task.spawn(rodarCicloCompeticao)