local workspace = game.Workspace
local players = game.Players
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5")

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

local totalBlocos = 324 
local blocosPorGrupo = 9
local rodadaAtiva = false
local aguardandoJogadores = true 

-- Sons e Estilização
local tickSound = timerBoard:FindFirstChild("TickSound")
local startSound = timerBoard:FindFirstChild("Start")
local narracao45 = timerBoard:FindFirstChild("NarracaoGalvaoBueno45S")

local CoresAleatorias = {
	Color3.fromRGB(255, 85, 0), Color3.fromRGB(0, 170, 255),
	Color3.fromRGB(85, 255, 127), Color3.fromRGB(255, 170, 0),
	Color3.fromRGB(170, 85, 255), Color3.fromRGB(0, 255, 255)
}

-- ==========================================
-- 2. ESTILIZAÇÃO VISUAL (MANTIDA 100%)
-- ==========================================
local function aplicarEstilo()
	-- --- ESTILO DO TIMER (Limpo e Profissional) ---
	local uiStrokeT = timerLabel:FindFirstChild("UIStroke") or Instance.new("UIStroke", timerLabel)
	if timerLabel:FindFirstChild("UIGradient") then timerLabel.UIGradient:Destroy() end -- Remove o brilho

	timerLabel.Font = Enum.Font.FredokaOne -- Fonte arredondada, mas muito mais legível
	timerLabel.TextColor3 = Color3.fromRGB(240, 240, 240) -- Branco "suave" (não agride o olho)
	timerLabel.BackgroundColor3 = Color3.fromRGB(40, 45, 60) -- Azul acinzentado escuro

	uiStrokeT.Color = Color3.fromRGB(100, 150, 255) -- Azul pastel (suave)
	uiStrokeT.Thickness = 3 -- Borda fina e elegante
	uiStrokeT.Transparency = 0.2 -- Leve transparência na borda para suavizar

	-- --- ESTILO DA PERGUNTA (Foco Total na Leitura) ---
	local uiStrokeQ = questionLabel:FindFirstChild("UIStroke") or Instance.new("UIStroke", questionLabel)
	if questionLabel:FindFirstChild("UIGradient") then questionLabel.UIGradient:Destroy() end

	questionLabel.Font = Enum.Font.FredokaOne
	questionLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Branco puro
	questionLabel.BackgroundColor3 = Color3.fromRGB(30, 35, 30) -- Verde floresta muito escuro (fundo repousante)

	uiStrokeQ.Color = Color3.fromRGB(120, 200, 150) -- Verde água pastel
	uiStrokeQ.Thickness = 3 -- Borda fina
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
		if stats and stats.JogoIniciado.Value == true and p:GetAttribute("JaEntrou") == true then 
			table.insert(ativos, p) 
		end
	end
	return ativos
end

-- SENSORES (INDIVIDUAL LARANJA)
local function configurarSensores()
	for i = 1, 3 do
		local sensor = sistemaArena:FindFirstChild("SensorArena"..i)
		if sensor then
			sensor.Touched:Connect(function(hit)
				if not aguardandoJogadores then return end
				local p = players:GetPlayerFromCharacter(hit.Parent)
				if p then
					local stats = p:FindFirstChild("PlayerStats")
					local folder = p:FindFirstChild("AcertosPorSerie")
					if stats and folder and stats.JogoIniciado.Value == false then
						p:SetAttribute("JaEntrou", true)
						stats.JogoIniciado.Value = true
						folder.Serie6.Value = true
						eventoIniciar:FireClient(p, "PRENDER_INDIVIDUAL") 
						warn("Sensor Arena "..i.." ativado")
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
		vencedor.leaderstats.Pontos.Value += 100 
		local total = vencedor.leaderstats.Pontos.Value
		pcall(function()
			RankingGlobal:SetAsync("Player_" .. vencedor.UserId, total)
		end)
	end
end

-- ==========================================
-- 5. CICLO DE ROUND (ESTILO NEON MANTIDO)
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

			-- ESTILO NEON ORIGINAL PRESERVADO
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
		if #getJogadoresAtivos() <= 1 then break end
		task.wait(1)
	end
	rodadaAtiva = false

	-- QUEDA DOS BLOCOS
	for i = 1, totalBlocos do
		local b = answersFolder:FindFirstChild("Answer"..i)
		if b and not b:GetAttribute("Correta") then b.Transparency = 1; b.CanCollide = false end
	end
	task.wait(4)
	for i = 1, totalBlocos do
		local b = answersFolder:FindFirstChild("Answer"..i)
		if b then b.Transparency = 0; b.CanCollide = true end
	end

	if #getJogadoresAtivos() <= 1 then return "FIM" end
	return "CONTINUA"
end

-- ==========================================
-- 6. LOOP INFINITO (COM MORTE SÚBITA)
-- ==========================================
local function rodarCicloCompeticao()
	while true do
		_G.PodioFila = {}
		aguardandoJogadores = true
		eventoIniciar:FireAllClients("RESET_TOTAL") 

		questionLabel.Text = "AGUARDANDO COMPETIDORES..."
		repeat task.wait(1) until #getJogadoresAtivos() >= 2

		if startSound then startSound:Play() end
		for i = 10, 1, -1 do 
			timerLabel.Text = tostring(i)
			questionLabel.Text = "PARTIDA INICIANDO EM "..i.."S"
			task.wait(1) 
		end

		aguardandoJogadores = false 
		eventoIniciar:FireAllClients("FECHAR_ARENA_VERMELHO") 

		local jogoAcabou = false
		-- LOOP NORMAL (6º AO 9º ANO)
		for _, dif in ipairs({"Facil", "Medio", "Dificil"}) do
			for serie = 6, 9 do
				if executarRound(serie, dif) == "FIM" then jogoAcabou = true break end
			end
			if jogoAcabou then break end
		end

		-- SEGUNDA PARTE: LÓGICA DE MORTE SÚBITA (SÓ SE SOBRAR GENTE)
		if not jogoAcabou and #getJogadoresAtivos() > 1 then
			warn("⚠️ Entrando em Morte Súbita!")
			while #getJogadoresAtivos() > 1 do
				questionLabel.Text = "⚠️ MORTE SÚBITA! ⚠️"
				task.wait(2)
				if executarRound(9, "Dificil") == "FIM" then break end
			end
		end

		-- FINALIZAÇÃO E VENCEDOR
		local sobreviventes = getJogadoresAtivos()
		if #sobreviventes == 1 then 
			local vencedor = sobreviventes[1]
			table.insert(_G.PodioFila, vencedor)
			distribuirPremiosRanked() 
			questionLabel.Text = "🏆 VENCEDOR: " .. vencedor.Name .. " 🏆"
		else 
			questionLabel.Text = "💀 SEM VENCEDORES 💀"
		end

		task.wait(7)

		-- RESET FINAL PARA A PRÓXIMA PARTIDA
		for _, p in pairs(players:GetPlayers()) do
			p:SetAttribute("JaEntrou", nil)
			local stats = p:FindFirstChild("PlayerStats")
			local folder = p:FindFirstChild("AcertosPorSerie")
			if stats then stats.JogoIniciado.Value = false end
			if folder then
				for _, val in pairs(folder:GetChildren()) do val.Value = false end
			end
		end
		warn("♻️ Arena Resetada!")
		task.wait(2)
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

rodarCicloCompeticao()