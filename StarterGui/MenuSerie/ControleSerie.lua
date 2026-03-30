-- ==========================================
-- CONTROLE SERIES (LOCAL SCRIPT) - INTEGRADO
-- ==========================================
local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local eventoIniciar = ReplicatedStorage:WaitForChild("IniciarArena")
local remoteEscolher = ReplicatedStorage:WaitForChild("EscolherSerie")

-- NOVO EVENTO PARA O STATUS DE "ARENA CAMP ON/OFF"
local eventoStatusTela = ReplicatedStorage:WaitForChild("AtualizarStatusTela")

-- EVENTO PARA SAIR DA ARENA (LOBBY)
local eventoLobby = ReplicatedStorage:WaitForChild("IrParaLobby")

local gui = script.Parent
local painel = gui:WaitForChild("Painel")
local labelSerie = gui:WaitForChild("SerieAtual")
local botaoSair = painel:WaitForChild("BotaoSair")

-- Referência física das portas (Pasta SistemaArena no Workspace)
local pastaArena = workspace:WaitForChild("SistemaArena")
local portas = {
	pastaArena:WaitForChild("Porta1"), 
	pastaArena:WaitForChild("Porta2"), 
	pastaArena:WaitForChild("Porta3")
}

-- ==========================================
-- FUNÇÃO DE CORES E ESTADOS (VISUAL E FÍSICO)
-- ==========================================
local function atualizarPortas(estado)
	if estado == "VERDE" then
		-- ESTADO: Arena Livre para Entrada
		for _, porta in pairs(portas) do
			porta.CanCollide = false
			porta.Transparency = 0.7
			porta.Color = Color3.fromRGB(0, 255, 0) -- Verde
		end
		labelSerie.Text = "Arena Camp OFF"
		labelSerie.TextColor3 = Color3.fromRGB(200, 96, 26)

		-- GARANTE QUE O PAINEL E O BOTÃO FIQUEM VISÍVEIS
		painel.Visible = true
		botaoSair.Visible = true

	elseif estado == "LARANJA" then
		-- ESTADO: Jogador entrou, aguardando início (Pré-jogo)
		for _, porta in pairs(portas) do
			porta.CanCollide = true 
			porta.Transparency = 0.3
			porta.Color = Color3.fromRGB(255, 165, 0) -- Laranja
		end
		labelSerie.Text = "Aguarde..."
		labelSerie.TextColor3 = Color3.fromRGB(255, 165, 0)

		-- MANTÉM O BOTÃO VISÍVEL MESMO AGUARDANDO
		botaoSair.Visible = true 

	elseif estado == "VERMELHO" then
		-- ESTADO: Partida em andamento (Bloqueio Total)
		for _, porta in pairs(portas) do
			porta.CanCollide = true
			porta.Transparency = 0
			porta.Color = Color3.fromRGB(255, 0, 0) -- Vermelho
		end
		labelSerie.Text = "Arena Camp ON"
		labelSerie.TextColor3 = Color3.fromRGB(0, 255, 127)

		-- REGRA: NÃO ESCONDER O PAINEL DURANTE A COMPETIÇÃO
		painel.Visible = true
		botaoSair.Visible = true 
	end
end

local function selecionarSerie(valor)
	remoteEscolher:FireServer(valor)
	atualizarPortas("LARANJA")
end

-- ==========================================
-- ESCUTA O STATUS ESPECÍFICO (ARENA CAMP ON/OFF)
-- ==========================================
eventoStatusTela.OnClientEvent:Connect(function(novoStatus)
	labelSerie.Text = novoStatus

	if novoStatus == "Arena Camp ON" then
		labelSerie.TextColor3 = Color3.fromRGB(0, 255, 127)
	elseif novoStatus == "Aguarde..." then
		labelSerie.TextColor3 = Color3.fromRGB(255, 165, 0)
	else
		labelSerie.TextColor3 = Color3.fromRGB(200, 96, 26)
	end
end)

-- ==========================================
-- ESCUTA OS COMANDOS DO SERVIDOR (GAME MANAGER)
-- ==========================================
eventoIniciar.OnClientEvent:Connect(function(comando)
	print("Recebido do Servidor: " .. tostring(comando))

	if comando == "RESET_TOTAL" then
		atualizarPortas("VERDE")

	elseif comando == "SENSOR_ATIVADO" or comando == "PORTA_LARANJA" or comando == "PRENDER_INDIVIDUAL" then
		selecionarSerie(6)

	elseif comando == "FECHAR_ARENA_VERMELHO" or comando == "TRANCAR_GERAL" then
		if player:GetAttribute("JaEntrou") == true then
			atualizarPortas("VERMELHO")
		else
			-- Visual para quem está fora
			for _, porta in pairs(portas) do
				porta.CanCollide = true
				porta.Transparency = 0
				porta.Color = Color3.fromRGB(255, 0, 0)
			end
			painel.Visible = true 
		end
	end
end)

-- ==========================================
-- CONFIGURAÇÃO DO BOTÃO DE SAÍDA (LOBBY)
-- ==========================================
botaoSair.MouseButton1Click:Connect(function()
	-- Dispara o evento para o servidor limpar nosso status da arena
	eventoLobby:FireServer()
	print("Tentando sair da arena e ir para o Lobby...")
end)

-- ==========================================
-- CONFIGURAÇÃO DOS BOTÕES DA UI ( OPCIONAL )
-- ==========================================
-- painel.S6.MouseButton1Click:Connect(function() selecionarSerie(6) end)
-- painel.S7.MouseButton1Click:Connect(function() selecionarSerie(7) end)
-- painel.S8.MouseButton1Click:Connect(function() selecionarSerie(8) end)
-- painel.S9.MouseButton1Click:Connect(function() selecionarSerie(9) end)