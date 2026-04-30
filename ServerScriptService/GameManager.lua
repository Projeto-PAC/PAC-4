-- ============================================================
--  GAMEMANAGER (VERSÃO FINAL UNIFICADA - SISTEMA DE LOBBY)
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
local addTimeEv = ReplicatedStorage:WaitForChild("AddTimeEvent") -- FIO DA VANTAGEM

-- Janela de consulta para as vantagens
local checarVantagemRF = ReplicatedStorage:FindFirstChild("ChecarVantagem") or Instance.new("RemoteFunction")
checarVantagemRF.Name = "ChecarVantagem"
checarVantagemRF.Parent = ReplicatedStorage

-- Evento de Desistência (Lobby)
local eventoLobby = ReplicatedStorage:FindFirstChild("IrParaLobby") or Instance.new("RemoteEvent", ReplicatedStorage)
eventoLobby.Name = "IrParaLobby"

-- VARIÁVEL DO RELÓGIO (Necessária para a vantagem de tempo)
local tempoRestante = 0 

_G.PodioFila = {} 

-------------------------------------------------
-- ⏰ CONEXÃO DO BÔNUS DE TEMPO (VANTAGEM 3)
-------------------------------------------------
addTimeEv.Event:Connect(function(segundosExtras)
	tempoRestante = tempoRestante + segundosExtras 
	warn("⏰ BÔNUS COLETIVO! +10 segundos adicionados pelo AddTimeEvent.")
end)

-- 2. CONFIGURAÇÕES DE AMBIENTE E PERÍMETRO QUADRADO
local modoCompetitivo = workspace:WaitForChild("ModosDeJogo"):WaitForChild("Competitivo")
local sistemaArena = workspace:WaitForChild("SistemaArena") 
local NOME_LOBBY_FIXO = "SpawnLocation"

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
-- 5. GERADORES DE MATEMÁTICA OMNI (NUNCA REPETE)
-- ==========================================
local Geradores = {
	[6] = { -- 6º ANO: Decimais, Frações e Conversões
		Facil = { 
			tempo = 20, 
			f = function() 
				local a = math.random(10, 50) + (math.random(1, 9) / 10)
				local b = math.random(5, 20) + (math.random(1, 9) / 10)
				return {txt=string.format("%.1f + %.1f", a, b), res=a+b} 
			end 
		}, 
		Medio = { 
			tempo = 30, 
			f = function() 
				local num = math.random(2, 5)
				local den = math.random(6, 12)
				local mult = den * math.random(2, 5)
				return {txt="Fração: "..num.."/"..den.." de "..mult, res=(mult/den)*num} 
			end 
		}, 
		Dificil = { 
			tempo = 40, 
			f = function() 
				local km = math.random(2, 15)
				return {txt="Conversão: "..km.."km em metros", res=km * 1000} 
			end 
		} 
	},
	[7] = { -- 7º ANO: Negativos, Porcentagem e Equação 1º Grau
		Facil = { 
			tempo = 20, 
			f = function() 
				local a, b = math.random(-50, -10), math.random(20, 60)
				return {txt=a.." + ("..b..")", res=a+b} 
			end 
		}, 
		Medio = { 
			tempo = 30, 
			f = function() 
				local p = math.random(1, 9) * 10
				local v = math.random(10, 50) * 10
				return {txt=p.."% de "..v, res=(p/100)*v} 
			end 
		}, 
		Dificil = { 
			tempo = 45, 
			f = function() 
				local a = math.random(2, 5)
				local x = math.random(2, 10)
				local b = math.random(5, 20)
				local resultado = (a * x) + b
				return {txt="Equação: "..a.."x + "..b.." = "..resultado..". Valor de x?", res=x} 
			end 
		} 
	},
	[8] = { -- 8º ANO: Potência, Plano Cartesiano e Conjuntos
		Facil = { 
			tempo = 25, 
			f = function() 
				local base = math.random(2, 5)
				local exp = math.random(2, 4)
				return {txt="Potência: "..base.."^"..exp, res=math.pow(base, exp)} 
			end 
		}, 
		Medio = { 
			tempo = 35, 
			f = function() 
				local x, y = math.random(-10, 10), math.random(-10, 10)
				local pergunta = math.random(1, 2)
				if pergunta == 1 then
					return {txt="Ponto ("..x..","..y.."). Qual o valor da Abscissa (x)?", res=x}
				else
					return {txt="Ponto ("..x..","..y.."). Qual o valor da Ordenada (y)?", res=y}
				end
			end 
		}, 
		Dificil = { 
			tempo = 45, 
			f = function() 
				-- Conjuntos: União/Intersecção (Representado por contagem)
				local nA = math.random(5, 10)
				local nB = math.random(5, 10)
				local inter = math.random(1, 4)
				return {txt="Conjuntos: A="..nA..", B="..nB..", Intersecção="..inter..". Total A ∪ B?", res=(nA+nB)-inter} 
			end 
		} 
	},
	[9] = { -- 9º ANO: 2º Grau, Log, Trigonometria (Catetos/Hipotenusa)
		Facil = { 
			tempo = 30, 
			f = function() 
				local b = math.random(3, 6)
				local c = math.random(7, 10)
				-- Pitágoras simplificado (arredondado para inteiro se necessário ou usando trios pitagóricos)
				return {txt="Triângulo: Catetos 3 e 4. Qual a Hipotenusa?", res=5} 
			end 
		}, 
		Medio = { 
			tempo = 45, 
			f = function() 
				-- Equação 2º grau (Soma e Produto)
				local x1 = math.random(1, 4)
				local x2 = math.random(5, 9)
				local b = -(x1 + x2)
				local c = x1 * x2
				return {txt="Função: x² "..(b>=0 and "+ "..b or b).."x + "..c.." = 0. Menor raiz?", res=x1, avoid={x2}} 
			end 
		}, 
		Dificil = { 
			tempo = 60, 
			f = function() 
				local modo = math.random(1, 2)
				if modo == 1 then
					-- Logaritmo
					local base = math.random(2, 3)
					local exp = math.random(2, 5)
					return {txt="Logaritmo: log"..base.."("..math.pow(base, exp)..")", res=exp}
				else
					-- Trigonometria SOHCAHTOA
					local hip = math.random(10, 30) * 2
					return {txt="Seno 30° (0.5) com Hipotenusa "..hip..". Cateto Oposto?", res=hip * 0.5}
				end
			end 
		} 
	}
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
-- 🚀 LÓGICA DO BOTÃO LOBBY (DESISTÊNCIA)
-- ==========================================
eventoLobby.OnServerEvent:Connect(function(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local stats = player:FindFirstChild("PlayerStats")
	local lobbySpawn = workspace:FindFirstChild("LobbySpawn")

	print("🚪 JOGADOR DESISTIU: " .. player.Name)

	-- 1. DESLIGA O JOGADOR DA ARENA (Igual ao Died/Regenerate)
	if stats then 
		stats.JogoIniciado.Value = false 
	end
	player:SetAttribute("JaEntrou", false)
	player:SetAttribute("VantagensUsadas", 0)

	-- 2. TELEPORTA PARA O LOBBY
	if hrp and lobbySpawn then
		hrp.CFrame = lobbySpawn.CFrame + Vector3.new(0, 5, 0)
	end

	-- 3. LIBERA A CÂMERA E PORTAS PARA O CLIENTE
	eventoIniciar:FireClient(player, "RESET_TOTAL")
end)

-- ==========================================
-- 8. CICLO DE ROUND DINÂMICO
-- ==========================================
local function executarRound(serie, dificuldade)
	local dados = Geradores[serie][dificuldade]
	local q = dados.f()
	local enumDificuldade = { ["facil"] = "Fácil", ["medio"] = "Médio", ["dificil"] = "Difícil" }

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
			b.SurfaceGui.Enabled = true
			local corBase = CoresAleatorias[math.random(1, #CoresAleatorias)]
			b.Color = Color3.new(corBase.R * 0.4, corBase.G * 0.4, corBase.B * 0.4) 

			local lbl = b.SurfaceGui:FindFirstChildWhichIsA("TextLabel")
			if lbl then 
				local valFinal
				if ehCerto then
					valFinal = corretaNum
				else
					local offset = math.random(-30, 30)
					while offset == 0 or (q.avoid and table.find(q.avoid, corretaNum + offset)) do
						offset = math.random(-30, 30)
					end
					valFinal = corretaNum + offset
				end
				lbl.Text = (valFinal % 1 == 0) and tostring(valFinal) or string.format("%.2f", valFinal)
			end 
		end
	end

	-- RELÓGIO DINÂMICO
	tempoRestante = dados.tempo 
	rodadaAtiva = true

	while tempoRestante > 0 do
		timerLabel.Text = tostring(math.ceil(tempoRestante))
		task.wait(1)
		tempoRestante = tempoRestante - 1

		-- CORREÇÃO: Round continua até o fim mesmo se sobrar 1 player
		if #getJogadoresAtivos() == 0 then break end 
	end
	rodadaAtiva = false

	for i = 1, totalBlocos do
		local b = answersFolder:FindFirstChild("Answer"..i)
		if b and not b:GetAttribute("Correta") then b.Transparency = 1; b.CanCollide = false; b.SurfaceGui.Enabled = false end
	end
	task.wait(4)

	local ativos = getJogadoresAtivos()
	if #ativos == 0 then return "MORTE_TOTAL" elseif #ativos == 1 then return "FIM" else return "CONTINUA" end
end

-- Janela de consulta para as vantagens
checarVantagemRF.OnServerInvoke = function(player)
	local statusArena = sistemaArena:GetAttribute("ArenaCamp")
	if statusArena ~= "Arena Camp ON" then
		return false, "Aguarde a competiÇÃo comeÇar!"
	end
	if not player:GetAttribute("JaEntrou") then
		return false, "Só participantes podem usar vantagens!"
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp and centroArena then
		local pPos = hrp.Position
		local centroPos = centroArena.Position
		local dentroX = math.abs(pPos.X - centroPos.X) <= (LARGURA_X / 2)
		local dentroZ = math.abs(pPos.Z - centroPos.Z) <= (PROFUNDIDADE_Z / 2)
		if dentroX and dentroZ then return true end
	end
	return false, "Saiu da Arena? Agora tem que esperar!"
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
		sistemaArena:SetAttribute("ArenaCamp", "Off")

		repeat task.wait(1) until #getJogadoresAtivos() >= 2

		if startSound then startSound:Play() end
		eventoStatusTela:FireAllClients("ARENA COMEÇA EM 10 SEG")

		for i = 10, 1, -1 do 
			timerLabel.Text = tostring(i); questionLabel.Text = "INICIANDO EM "..i.."S"; task.wait(1) 
		end

		aguardandoJogadores = false 
		atualizarCoresPortas(Color3.fromRGB(255, 0, 0), 0, true)
		eventoIniciar:FireAllClients("FECHAR_ARENA_VERMELHO") 

		sistemaArena:SetAttribute("ArenaCamp", "Arena Camp ON")
		eventoStatusTela:FireAllClients("Arena Camp ON")

		local status = "CONTINUA"
		local jogoAcabou = false
		for _, dif in ipairs({"Facil", "Medio", "Dificil"}) do
			centroArena.StatusCompeticao.Value = dif ----------------------------Escuta para defenir o som do narrador das fazer Facíl, médio e dificil
			for serie = 6, 9 do
				status = executarRound(serie, dif)
				if status ~= "CONTINUA" then jogoAcabou = true break end
			end
			if jogoAcabou then break end
		end

		if not jogoAcabou and #getJogadoresAtivos() > 1 then
			centroArena.StatusCompeticao.Value = "MorteSubita" ----------------------------Escuta para defenir o som do narrador da Morte Subita
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
			centroArena.StatusCompeticao.Value = "Vencedor"------------------------------------Escuta para defenir o som do narrador do Vencedor
			table.insert(_G.PodioFila, ganhador)
			distribuirPremiosRanked()
		else 
			questionLabel.Text = "💀 NINGUÉM SOBREVIVEU"
			centroArena.StatusCompeticao.Value = "Ninguem" ------------------------------------Escuta para defenir o som do narrador de Ningue Sobreviveu
		end

		task.wait(7)
		centroArena.StatusCompeticao.Value = ""  ------------------------------------------Codigo de Limpeza 
		for _, p in pairs(players:GetPlayers()) do
			local s = p:FindFirstChild("PlayerStats")
			if s then s.JogoIniciado.Value = false end
			p:SetAttribute("JaEntrou", false)
			p:SetAttribute("VantagensUsadas", 0) 
		end
		eventoStatusTela:FireAllClients("Arena Camp OFF")
		sistemaArena:SetAttribute("ArenaCamp", "Off")
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
print("✅ SISTEMA COMPLETO ATIVADO.")