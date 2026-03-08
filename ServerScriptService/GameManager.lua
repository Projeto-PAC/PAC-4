local workspace = game.Workspace
local players = game.Players
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- ==========================================
-- BANCO DE DADOS
-- ==========================================

local RankingGlobal = DataStoreService:GetOrderedDataStore("RankingAcertos_V6")

-- ==========================================
-- CARREGAR PERGUNTAS
-- ==========================================

local Perguntas = ReplicatedStorage:WaitForChild("PerguntasMatematica")

local Ano6 = require(Perguntas:WaitForChild("Ano6"))
local Ano7 = require(Perguntas:WaitForChild("Ano7"))
local Ano8 = require(Perguntas:WaitForChild("Ano8"))
local Ano9 = require(Perguntas:WaitForChild("Ano9"))

local ModulosSerie = {
	[6] = Ano6,
	[7] = Ano7,
	[8] = Ano8,
	[9] = Ano9
}

-- ==========================================
-- EVENTOS
-- ==========================================

local eventoIniciar = ReplicatedStorage:WaitForChild("IniciarArena")

-- ==========================================
-- ARENA
-- ==========================================

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

local rodadaAtiva = false
local aguardandoJogadores = true

_G.PodioFila = {}

local CoresAleatorias = {
	Color3.fromRGB(255,85,0),
	Color3.fromRGB(0,170,255),
	Color3.fromRGB(85,255,127),
	Color3.fromRGB(255,170,0),
	Color3.fromRGB(170,85,255),
	Color3.fromRGB(0,255,255)
}

-- ==========================================
-- FUNÇÕES AUXILIARES
-- ==========================================

local function getJogadoresAtivos()

	local ativos = {}

	for _,p in pairs(players:GetPlayers()) do

		local stats = p:FindFirstChild("PlayerStats")

		if stats and stats.JogoIniciado.Value then

			local char = p.Character

			if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
				table.insert(ativos,p)
			end
		end
	end

	return ativos
end

-- ==========================================
-- EXECUTAR ROUND
-- ==========================================

local function executarRound(serie,dificuldade)

	local modulo = ModulosSerie[serie]

	local pergunta,resposta,opcoes = modulo[dificuldade]()

	questionLabel.Text = "["..dificuldade.."] "..pergunta.." ("..serie.."º Ano)"

	local tempoRound = 30

	if dificuldade == "Facil" then
		tempoRound = 20
	elseif dificuldade == "Medio" then
		tempoRound = 25
	else
		tempoRound = 30
	end

	local correta = resposta

	-- distribuir respostas

	for i=1,totalBlocos do

		local bloco = answersFolder:FindFirstChild("Answer"..i)

		if bloco then

			local lbl = bloco.SurfaceGui:FindFirstChildWhichIsA("TextLabel")

			local valor = opcoes[math.random(1,#opcoes)]

			local ehCerto = valor == correta

			bloco:SetAttribute("Correta",ehCerto)

			bloco.Transparency = 0
			bloco.CanCollide = true

			local cor = CoresAleatorias[math.random(1,#CoresAleatorias)]
			bloco.Color = cor

			if lbl then
				local Util = require(ReplicatedStorage.PerguntasMatematica.Utilidades)

				lbl.Text = Util.formatarNumero(valor)
			end
		end
	end

	rodadaAtiva = true

	for t = tempoRound,0,-1 do

		timerLabel.Text = tostring(t)

		task.wait(1)

		local ativos = getJogadoresAtivos()

		if #ativos <= 1 then
			break
		end
	end

	rodadaAtiva = false

	-- derrubar respostas erradas

	for i=1,totalBlocos do

		local bloco = answersFolder:FindFirstChild("Answer"..i)

		if bloco and not bloco:GetAttribute("Correta") then

			bloco.Transparency = 1
			bloco.CanCollide = false
		end
	end

	task.wait(4)

	local ativos = getJogadoresAtivos()

	if #ativos == 0 then
		return "MORTE_TOTAL"
	end

	if #ativos == 1 then
		return "FIM"
	end

	return "CONTINUA"
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================

local function rodarCicloCompeticao()

	while true do

		aguardandoJogadores = true

		questionLabel.Text = "ARENA ABERTA!"

		for _,porta in pairs(portas) do
			porta.CanCollide = false
			porta.Transparency = 0.8
			porta.Color = Color3.fromRGB(0,255,0)
		end

		repeat
			task.wait(1)
		until #getJogadoresAtivos() >= 2

		for i=10,1,-1 do
			timerLabel.Text = tostring(i)
			questionLabel.Text = "COMEÇANDO EM "..i
			task.wait(1)
		end

		aguardandoJogadores = false

		for _,porta in pairs(portas) do
			porta.CanCollide = true
			porta.Transparency = 0
			porta.Color = Color3.fromRGB(255,0,0)
		end

		local status = "CONTINUA"

		while true do

			for _, dificuldade in ipairs({"Facil","Medio","Dificil"}) do

				for serie = 6,9 do

					local status = executarRound(serie,dificuldade)

					if status == "FIM" or status == "MORTE_TOTAL" then
						return
					end

				end

			end

		end

		local sobreviventes = getJogadoresAtivos()

		if #sobreviventes == 1 then

			local vencedor = sobreviventes[1]

			questionLabel.Text = "🏆 VENCEDOR: "..vencedor.Name

		else

			questionLabel.Text = "💀 NINGUÉM SOBREVIVEU"

		end

		task.wait(7)

	end
end

task.spawn(rodarCicloCompeticao)