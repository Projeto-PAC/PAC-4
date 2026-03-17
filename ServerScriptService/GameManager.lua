-- ============================================================
--  GAMEMANAGER TOTAL: DETECÇÃO QUADRADA + RANKING + STATUS
-- ============================================================
local workspace = game.Workspace
local players = game.Players
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- 1. BANCO DE DADOS E EVENTOS
local rankingStore = DataStoreService:GetDataStore("RankingAcertos_V5")
local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V5") 
local Util = require(ReplicatedStorage.PerguntasMatematica.Utilidades)

local eventoIniciar = ReplicatedStorage:WaitForChild("IniciarArena")
local eventoVencedor = ReplicatedStorage:WaitForChild("VencedorDefinido")
local remoteEscolher = ReplicatedStorage:WaitForChild("EscolherSerie")
local eventoStatusTela = ReplicatedStorage:WaitForChild("AtualizarStatusTela")

_G.PodioFila = {} 

-- 2. CONFIGURAÇÕES DE AMBIENTE E PERÍMETRO QUADRADO
local modoCompetitivo = workspace:WaitForChild("ModosDeJogo"):WaitForChild("Competitivo")
local sistemaArena = workspace:WaitForChild("SistemaArena") 
local NOME_LOBBY_FIXO = "SpawnLocation"

-- CONFIGURAÇÃO DO QUADRADO (Ajuste esses valores para o tamanho real da arena)
local LARGURA_X = 179.5  -- Tamanho total no eixo X
local PROFUNDIDADE_Z = 179.5 -- Tamanho total no eixo Z
local centroArena = sistemaArena:WaitForChild("CentroDaArena", 5)

-- Inicializa os Atributos de Controle
sistemaArena:SetAttribute("ArenaCamp", "Off")
sistemaArena:SetAttribute("PodeAtivarSensor2", false)

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
-- 3. FUNÇÕES DE PREMIAÇÃO E RANKING (100 PTS)
-- ==========================================
local function distribuirPremiosRanked()
	local vencedor = _G.PodioFila[#_G.PodioFila]
	if vencedor and vencedor:FindFirstChild("leaderstats") and vencedor:FindFirstChild("AcertosPorSerie") then 
		local campValue = vencedor.leaderstats:FindFirstChild("Camp")
		local acertos = vencedor.AcertosPorSerie
		if campValue then
			campValue.Value += 100 
			local key = "Player_" .. vencedor.UserId
			pcall(function() RankingGlobal:SetAsync(key, vencedor.leaderstats.Total.Value) end)
			pcall(function()
				local detalhes = rankingStore:GetAsync(key) or {Serie6=0, Serie7=0, Serie8=0, Serie9=0, Camp=0}
				detalhes.Serie6 = acertos.Serie6.Value
				detalhes.Serie7 = acertos.Serie7.Value
				detalhes.Serie8 = acertos.Serie8.Value
				detalhes.Serie9 = acertos.Serie9.Value
				detalhes.Camp = campValue.Value
				rankingStore:SetAsync(key, detalhes)
			end)
			print("✅ SUCESSO: 100 Pontos e Ranking atualizados para " .. vencedor.Name)
		end
	end
end

-- ==========================================
-- 4. FUNÇÕES DE ESTILO E AUXÍLIO
-- ==========================================
local function atualizarCoresPortas(cor, transparencia, colisao)
	for _, porta in pairs(portas) do
		porta.Color = cor
		porta.Transparency = transparencia
		porta.CanCollide = colisao
	end
end

local function aplicarEstilo()
	local uiStrokeT = timerLabel:FindFirstChild("UIStroke") or Instance.new("UIStroke", timerLabel)
	if timerLabel:FindFirstChild("UIGradient") then timerLabel.UIGradient:Destroy() end
	timerLabel.Font = Enum.Font.FredokaOne
	timerLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	timerLabel.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
	uiStrokeT.Color = Color3.fromRGB(100, 150, 255); uiStrokeT.Thickness = 3; uiStrokeT.Transparency = 0.2

	local uiStrokeQ = questionLabel:FindFirstChild("UIStroke") or Instance.new("UIStroke", questionLabel)
	if questionLabel:FindFirstChild("UIGradient") then questionLabel.UIGradient:Destroy() end
	questionLabel.Font = Enum.Font.FredokaOne
	questionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	questionLabel.BackgroundColor3 = Color3.fromRGB(30, 35, 30)
	uiStrokeQ.Color = Color3.fromRGB(120, 200, 150); uiStrokeQ.Thickness = 3; uiStrokeQ.Transparency = 0.2
end
aplicarEstilo()

-- ==========================================
-- 5. GERADORES DE MATEMÁTICA
-- ==========================================
local Geradores = {
	[6] = { Facil = { tempo = 20, f = function() local a, b = math.random(50,200), math.random(30,100) return {txt=a.." + "..b, res=a+b} end }, Medio = { tempo = 23, f = function() local a, b = math.random(12,40), math.random(6,15) return {txt=a.." x "..b, res=a*b} end }, Dificil = { tempo = 40, f = function() local a, b = math.random(100,600)/10, math.random(50,250)/10 return {txt=a.." + "..b.." - 5.5", res=a+b-5.5} end } },
	[7] = { Facil = { tempo = 20, f = function() local a, b = math.random(-30,30), math.random(-30,30) return {txt=a.." + ("..b..")", res=a+b} end }, Medio = { tempo = 30, f = function() local x = math.random(5,25); local c = math.random(10,50) return {txt="x + "..c.." = "..(x+c), res=x} end }, Dificil = { tempo = 40, f = function() local a, x, c = math.random(2,6), math.random(5,20), math.random(1,30) return {txt=a.."x + "..c.." = "..(a*x+c), res=x} end } },
	[8] = { Facil = { tempo = 20, f = function() local n = math.random(2,16) return {txt="√"..(n*n), res=n} end }, Medio = { tempo = 30, f = function() local b, e = math.random(2,5), math.random(2,4) return {txt=b.."^"..e, res=math.pow(b,e)} end }, Dificil = { tempo = 40, f = function() local a, b = math.random(3,12), math.random(3,12) return {txt="√"..(a*a).." + √"..(b*b), res=a+b} end } },
	[9] = { Facil = { tempo = 20, f = function() local x = math.random(1,18) return {txt="x² = "..(x*x), res=x} end }, Medio = { tempo = 30, f = function() local a = math.random(1,15) return {txt=a.." x 10³", res=a*1000} end }, Dificil = { tempo = 40, f = function() local x1, x2 = math.random(1,6), math.random(1,6); local b = -(x1 + x2); local c = x1 * x2 return {txt="x² ".. (b>=0 and "+ "..b or b) .."x + "..c.." = 0", res=x1} end } }
}

-- ============================================================
--  SISTEMA DE VIGIA (PERÍMETRO QUADRADO)
-- ============================================================
task.spawn(function()
	while true do
		if centroArena then
			local jogadoresEncontrados = {}
			local contadorNaArena = 0
			local centroPos = centroArena.Position

			for _, p in pairs(players:GetPlayers()) do
				local char = p.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					local pPos = char.HumanoidRootPart.Position

					-- LÓGICA DE DETECÇÃO QUADRADA (AABB)
					-- Verifica se o player está dentro dos limites X e Z do quadrado
					local dentroX = math.abs(pPos.X - centroPos.X) <= (LARGURA_X / 2)
					local dentroZ = math.abs(pPos.Z - centroPos.Z) <= (PROFUNDIDADE_Z / 2)

					if dentroX and dentroZ then
						contadorNaArena = contadorNaArena + 1
						table.insert(jogadoresEncontrados, p)
					end
				end
			end

			if aguardandoJogadores then
				if contadorNaArena >= 2 then
					atualizarCoresPortas(Color3.fromRGB(255, 170, 0), 0.5, false)

					if sistemaArena:GetAttribute("ArenaCamp") ~= "Aguarde" then
						sistemaArena:SetAttribute("ArenaCamp", "Aguarde")
						sistemaArena:SetAttribute("PodeAtivarSensor2", true)
						eventoStatusTela:FireAllClients("Aguarde...")
						warn(">>> STATUS: Aguarde (Quadrado Detectado)")
					end

					for _, p in pairs(jogadoresEncontrados) do
						local stats = p:FindFirstChild("PlayerStats")
						if stats and stats.JogoIniciado.Value == false then
							p:SetAttribute("JaEntrou", true) 
							stats.JogoIniciado.Value = true
							eventoIniciar:FireClient(p, "PRENDER_INDIVIDUAL")
						end
					end
				else
					atualizarCoresPortas(Color3.fromRGB(0, 255, 0), 0.8, false)
					questionLabel.Text = "AGUARDANDO JOGADORES NA ARENA...MÍNIMO (" .. contadorNaArena .. "/2)"

					if sistemaArena:GetAttribute("ArenaCamp") ~= "Off" then
						sistemaArena:SetAttribute("ArenaCamp", "Off")
						sistemaArena:SetAttribute("PodeAtivarSensor2", false)
						eventoStatusTela:FireAllClients("Arena Camp OFF")
						warn(">>> STATUS: Arena Camp OFF")
					end
				end
			end
		end
		task.wait(0.5)
	end
end)

-- ==========================================
-- 7. LÓGICA DE SPAWN E ENTRADA
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

local function gerenciarEntrada(p)
	p.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		local stats = p:WaitForChild("PlayerStats", 10)
		local lobby = workspace:FindFirstChild("LobbySpawn")
		local spawnLobbyFocar = workspace:FindFirstChild(NOME_LOBBY_FIXO, true)

		if not p:GetAttribute("PrimeiroNascimentoConcluido") then
			if hrp and spawnLobbyFocar then
				task.wait(0.1)
				hrp.CFrame = spawnLobbyFocar.CFrame + Vector3.new(0, 5, 0)
				p:SetAttribute("PrimeiroNascimentoConcluido", true)
			end
		end

		hum.Died:Connect(function()
			if stats then stats.JogoIniciado.Value = false end
			task.wait(3)
			p:LoadCharacter()
		end)

		if lobby and stats and stats.JogoIniciado.Value == false then
			task.wait(0.1)
			char:PivotTo(lobby.CFrame + Vector3.new(0, 5, 0))
		end
	end)
	if not p.Character then p:LoadCharacter() end
end

players.PlayerAdded:Connect(gerenciarEntrada)
for _, player in pairs(players:GetPlayers()) do gerenciarEntrada(player) end

-- ==========================================
-- 8. CICLO DE ROUND E COMPETIÇÃO
-- ==========================================
local function executarRound(serie, dificuldade)
	local dados = Geradores[serie][dificuldade]
	local q = dados.f()
	local enumDificuldade = {
		["facil"] = "Fácil",
		["medio"] = "Médio",
		["dificil"] = "Difícil"
	}

	local dificuldadeTexto = enumDificuldade[string.lower(dificuldade)] or dificuldade
	questionLabel.Text = "["..dificuldadeTexto.."] "..q.txt.." ("..serie.."º Ano)"
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
			b.Transparency = 0; b.CanCollide = true; b.Material = Enum.Material.Neon
			b:FindFirstChildOfClass("SurfaceGui").Enabled = true
			local corBase = CoresAleatorias[math.random(1, #CoresAleatorias)]
			b.Color = Color3.new(corBase.R * 0.4, corBase.G * 0.4, corBase.B * 0.4) 
			local lbl = b.SurfaceGui:FindFirstChildWhichIsA("TextLabel")
			if lbl then 
				local valFinal = ehCerto and corretaNum or (corretaNum + math.random(-30, 30))
				lbl.Text = (valFinal % 1 == 0) and tostring(valFinal) or string.format("%.2f", valFinal)
			end 
		end
	end

	rodadaAtiva = true
	for t = dados.tempo, 0, -1 do
		timerLabel.Text = tostring(t); task.wait(1)
		if #getJogadoresAtivos() <= 1 then break end
	end
	rodadaAtiva = false

	for i = 1, totalBlocos do
		local b = answersFolder:FindFirstChild("Answer"..i)
		if b and not b:GetAttribute("Correta") then b.Transparency = 1; b.CanCollide = false; b:FindFirstChildOfClass("SurfaceGui").Enabled = false end
		
	end
	task.wait(4)
	local ativos = getJogadoresAtivos()
	if #ativos == 0 then return "MORTE_TOTAL" elseif #ativos == 1 then return "FIM" else return "CONTINUA" end
end

local function rodarCicloCompeticao()
	while true do
		aguardandoJogadores = true
		_G.PodioFila = {}
		for i = 1, totalBlocos do
			local b = answersFolder:FindFirstChild("Answer"..i)
			if b then b.Transparency = 0; b.CanCollide = true; b.Color = Color3.fromRGB(200, 147, 87); b.Material = Enum.Material.Cobblestone;  b.SurfaceGui.TextLabel.Text = "" end
		end
		timerLabel.Text = ""; eventoIniciar:FireAllClients("RESET_TOTAL")
		eventoStatusTela:FireAllClients("Arena Camp OFF")

		repeat task.wait(1) until #getJogadoresAtivos() >= 2

		if startSound then startSound:Play() end
		eventoStatusTela:FireAllClients("ARENA COMEÇA EM 10 SEG")

		for i = 10, 1, -1 do 
			timerLabel.Text = tostring(i); questionLabel.Text = "INICIANDO EM "..i.."S"; task.wait(1) 
		end

		aguardandoJogadores = false 
		atualizarCoresPortas(Color3.fromRGB(255, 0, 0), 0, true)
		eventoIniciar:FireAllClients("FECHAR_ARENA_VERMELHO") 
		eventoStatusTela:FireAllClients("Arena Camp ON")

		local status = "CONTINUA"
		local jogoAcabou = false
		for _, dif in ipairs({"Facil", "Medio", "Dificil"}) do
			for serie = 6, 9 do
				status = executarRound(serie, dif)
				if status ~= "CONTINUA" then jogoAcabou = true break end
			end
			if jogoAcabou then break end
		end

		if not jogoAcabou and #getJogadoresAtivos() > 1 then
			while #getJogadoresAtivos() > 1 do
				questionLabel.Text = "⚠️ MORTE SÚBITA! ⚠️"; task.wait(2)
				status = executarRound(9, "Dificil")
				if status == "FIM" or status == "MORTE_TOTAL" then break end
			end
		end

		local sobreviventes = getJogadoresAtivos()
		if #sobreviventes == 1 then 
			local ganhador = sobreviventes[1]
			questionLabel.Text = "🏆 VENCEDOR: " .. ganhador.Name
			table.insert(_G.PodioFila, ganhador)
			distribuirPremiosRanked()
		else 
			questionLabel.Text = "💀 NINGUÉM SOBREVIVEU"
		end

		task.wait(7)
		for _, p in pairs(players:GetPlayers()) do
			local s = p:FindFirstChild("PlayerStats")
			if s and s:FindFirstChild("JogoIniciado") then s.JogoIniciado.Value = false end
			p:SetAttribute("JaEntrou", false)
		end
		eventoStatusTela:FireAllClients("Arena Camp OFF")
	end
end

-- Interação com blocos
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
print("✅ PERÍMETRO QUADRADO ATIVADO: OFF -> Aguarde -> ON.")