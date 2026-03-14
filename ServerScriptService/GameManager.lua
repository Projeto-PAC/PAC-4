local workspace = game.Workspace
local players = game.Players
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Util = require(ReplicatedStorage.PerguntasMatematica.Utilidades)

-- ==========================================
-- 1. BANCO DE DADOS E EVENTOS
-- ==========================================
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5") 
local eventoIniciar = ReplicatedStorage:WaitForChild("IniciarArena")
local remoteEscolher = ReplicatedStorage:WaitForChild("EscolherSerie")
_G.PodioFila = {} 

-- CONFIGURAÇÃO DOS CAMINHOS
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

-- Sons
local startSound = timerBoard:FindFirstChild("Start")

local CoresAleatorias = {
	Color3.fromRGB(255, 85, 0), Color3.fromRGB(0, 170, 255),
	Color3.fromRGB(85, 255, 127), Color3.fromRGB(255, 170, 0),
	Color3.fromRGB(170, 85, 255), Color3.fromRGB(0, 255, 255)
}

-- ==========================================
-- 2. ESTILIZAÇÃO VISUAL (MANTIDA 100%)
-- ==========================================
local function aplicarEstilo()
	local uiStrokeT = timerLabel:FindFirstChild("UIStroke") or Instance.new("UIStroke", timerLabel)
	if timerLabel:FindFirstChild("UIGradient") then timerLabel.UIGradient:Destroy() end

	timerLabel.Font = Enum.Font.FredokaOne
	timerLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	timerLabel.BackgroundColor3 = Color3.fromRGB(40, 45, 60)

	uiStrokeT.Color = Color3.fromRGB(100, 150, 255)
	uiStrokeT.Thickness = 3
	uiStrokeT.Transparency = 0.2

	local uiStrokeQ = questionLabel:FindFirstChild("UIStroke") or Instance.new("UIStroke", questionLabel)
	if questionLabel:FindFirstChild("UIGradient") then questionLabel.UIGradient:Destroy() end

	questionLabel.Font = Enum.Font.FredokaOne
	questionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	questionLabel.BackgroundColor3 = Color3.fromRGB(30, 35, 30)

	uiStrokeQ.Color = Color3.fromRGB(120, 200, 150)
	uiStrokeQ.Thickness = 3
	uiStrokeQ.Transparency = 0.2
end
aplicarEstilo()

-- ==========================================
-- 3. GERADORES (MANTIDOS 100%)
-- ==========================================
local Geradores = {
	[6] = { Facil = { tempo = 20, f = function() local a, b = math.random(50,200), math.random(30,100) return {txt=a.." + "..b, res=a+b} end }, Medio = { tempo = 23, f = function() local a, b = math.random(12,40), math.random(6,15) return {txt=a.." x "..b, res=a*b} end }, Dificil = { tempo = 40, f = function() local a, b = math.random(100,600)/10, math.random(50,250)/10 return {txt=a.." + "..b.." - 5.5", res=a+b-5.5} end } },
	[7] = { Facil = { tempo = 20, f = function() local a, b = math.random(-30,30), math.random(-30,30) return {txt=a.." + ("..b..")", res=a+b} end }, Medio = { tempo = 30, f = function() local x = math.random(5,25); local c = math.random(10,50) return {txt="x + "..c.." = "..(x+c), res=x} end }, Dificil = { tempo = 40, f = function() local a, x, c = math.random(2,6), math.random(5,20), math.random(1,30) return {txt=a.."x + "..c.." = "..(a*x+c), res=x} end } },
	[8] = { Facil = { tempo = 20, f = function() local n = math.random(2,16) return {txt="√"..(n*n), res=n} end }, Medio = { tempo = 30, f = function() local b, e = math.random(2,5), math.random(2,4) return {txt=b.."^"..e, res=math.pow(b,e)} end }, Dificil = { tempo = 40, f = function() local a, b = math.random(3,12), math.random(3,12) return {txt="√"..(a*a).." + √"..(b*b), res=a+b} end } },
	[9] = { Facil = { tempo = 20, f = function() local x = math.random(1,18) return {txt="x² = "..(x*x), res=x} end }, Medio = { tempo = 30, f = function() local a = math.random(1,15) return {txt=a.." x 10³", res=a*1000} end }, Dificil = { tempo = 40, f = function() local x1, x2 = math.random(1,6), math.random(1,6); local b = -(x1 + x2); local c = x1 * x2 return {txt="x² ".. (b>=0 and "+ "..b or b) .."x + "..c.." = 0", res=x1} end } }
}

-- ==========================================
-- 4. LOGICA DE JOGADORES ATIVOS
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

local function configurarSensores()
	for i = 1, 3 do
		local sensor = sistemaArena:FindFirstChild("SensorArena"..i)
		if sensor then
			sensor.Touched:Connect(function(hit)
				if not aguardandoJogadores then return end
				local p = players:GetPlayerFromCharacter(hit.Parent)
				if p then
					local stats = p:FindFirstChild("PlayerStats")
					if stats and stats.JogoIniciado.Value == false then
						p:SetAttribute("JaEntrou", true)
						stats.JogoIniciado.Value = true
						eventoIniciar:FireClient(p, "PRENDER_INDIVIDUAL") 
					end
				end
			end)
		end
	end
end
configurarSensores()

local function distribuirPremiosRanked()
	local vencedor = _G.PodioFila[#_G.PodioFila]
	if vencedor and vencedor:FindFirstChild("leaderstats") then 
		local camp = vencedor.leaderstats:FindFirstChild("Camp")
		if camp then
			camp.Value += 100 
			pcall(function()
				RankingGlobal:SetAsync("Player_" .. vencedor.UserId, vencedor.leaderstats.Total.Value)
			end)
		end
	end
end

-- ==========================================
-- 5. CICLO DE ROUND (ESTILO NEON)
-- ==========================================
local function executarRound(serie, dificuldade)
	local dados = Geradores[serie][dificuldade]
	local q = dados.f()
	questionLabel.Text = "["..dificuldade.."] "..q.txt.." ("..serie.."º Ano)"

	local corretaNum = tonumber(q.res) or 0
	local posicoesCertasNoGrupo = {}
	for g = 0, 35 do posicoesCertasNoGrupo[g] = math.random(1, 9) end

	for i = 1, totalBlocos do
		local b = answersFolder:FindFirstChild("Answer"..i)
		if b then
			local grupo = math.floor((i-1) / blocosPorGrupo)
			local pos = ((i-1) % blocosPorGrupo) + 1
			local ehCerto = (pos == posicoesCertasNoGrupo[grupo])
			b:SetAttribute("Correta", ehCerto)

			b.Transparency = 0; b.CanCollide = true
			b.Material = Enum.Material.Neon
			local corBase = CoresAleatorias[math.random(1, #CoresAleatorias)]
			b.Color = Color3.new(corBase.R * 0.4, corBase.G * 0.4, corBase.B * 0.4) 

			local lbl = b.SurfaceGui:FindFirstChildWhichIsA("TextLabel")
			if lbl then 
				local valFinal = ehCerto and corretaNum or (corretaNum + math.random(-30, 30))
				lbl.Text = tostring(valFinal) 
			end
		end
	end

	rodadaAtiva = true
	for t = dados.tempo, 0, -1 do
		timerLabel.Text = tostring(t)
		task.wait(1)
		if #getJogadoresAtivos() <= 1 then break end
	end
	rodadaAtiva = false

	for i = 1, totalBlocos do
		local b = answersFolder:FindFirstChild("Answer"..i)
		if b and not b:GetAttribute("Correta") then
			b.Transparency = 1; b.CanCollide = false
		end
	end
	task.wait(4)

	local ativos = getJogadoresAtivos()
	if #ativos == 0 then return "MORTE_TOTAL" end
	if #ativos == 1 then return "FIM" end
	return "CONTINUA"
end

local function resetArena()
	for i = 1, totalBlocos do
		local b = answersFolder:FindFirstChild("Answer"..i)
		if b then
			b.Transparency = 0; b.CanCollide = true
			b.Color = Color3.fromRGB(120, 120, 120)
			local lbl = b.SurfaceGui:FindFirstChildWhichIsA("TextLabel")
			if lbl then lbl.Text = "" end
		end
	end
	timerLabel.Text = ""
end

-- ==========================================
-- 6. LOOP PRINCIPAL (COM MORTE SÚBITA COMPLETA)
-- ==========================================
local function rodarCicloCompeticao()
	while true do
		resetArena()
		aguardandoJogadores = true
		eventoIniciar:FireAllClients("RESET_TOTAL") 
		questionLabel.Text = "AGUARDANDO COMPETIDORES..."

		-- Abre as portas
		for _, porta in pairs(portas) do
			porta.CanCollide = false; porta.Transparency = 0.8; porta.Color = Color3.fromRGB(0, 255, 0)
		end

		repeat task.wait(1) until #getJogadoresAtivos() >= 2

		if startSound then startSound:Play() end
		for i = 10, 1, -1 do 
			timerLabel.Text = tostring(i); questionLabel.Text = "INICIANDO EM "..i.."S"; task.wait(1) 
		end

		aguardandoJogadores = false 
		for _, porta in pairs(portas) do
			porta.CanCollide = true; porta.Transparency = 0; porta.Color = Color3.fromRGB(255, 0, 0)
		end
		eventoIniciar:FireAllClients("FECHAR_ARENA_VERMELHO") 

		local status = "CONTINUA"
		local jogoAcabou = false

		-- 🔹 PARTE 1: CICLO NORMAL (6º ao 9º Ano)
		for _, dif in ipairs({"Facil", "Medio", "Dificil"}) do
			for serie = 6, 9 do
				status = executarRound(serie, dif)
				if status ~= "CONTINUA" then jogoAcabou = true break end
			end
			if jogoAcabou then break end
		end

		-- 🔹 PARTE 2: MORTE SÚBITA (O LOOP QUE VOCÊ QUERIA)
		if not jogoAcabou and #getJogadoresAtivos() > 1 then
			warn("⚠️ Entrando em Morte Súbita!")
			while #getJogadoresAtivos() > 1 do
				questionLabel.Text = "⚠️ MORTE SÚBITA! ⚠️"
				task.wait(2)
				status = executarRound(9, "Dificil")
				if status == "FIM" or status == "MORTE_TOTAL" then break end
			end
		end

		-- FINALIZAÇÃO
		local sobreviventes = getJogadoresAtivos()
		if #sobreviventes == 1 then 
			local vencedor = sobreviventes[1]
			table.insert(_G.PodioFila, vencedor)
			distribuirPremiosRanked() 
			questionLabel.Text = "🏆 VENCEDOR: " .. vencedor.Name
		else 
			questionLabel.Text = "💀 NINGUÉM SOBREVIVEU"
		end

		task.wait(7)

		-- 🧹 RESET DO CICLO
		for _, p in pairs(players:GetPlayers()) do
			p:SetAttribute("JaEntrou", false)
			local stats = p:FindFirstChild("PlayerStats")
			if stats and stats:FindFirstChild("JogoIniciado") then
				stats.JogoIniciado.Value = false 
			end
		end
	end
end

-- Toque nos blocos
for i = 1, totalBlocos do
	local b = answersFolder:FindFirstChild("Answer"..i)
	if b then
		b.Touched:Connect(function(hit)
			if not rodadaAtiva then return end
			local p = players:GetPlayerFromCharacter(hit.Parent)
			if p then p:SetAttribute("EscolhaCorreta", b:GetAttribute("Correta")) end
		end)
	end
end

task.spawn(rodarCicloCompeticao)