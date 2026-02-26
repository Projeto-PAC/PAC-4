local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local eventoIniciar = ReplicatedStorage:WaitForChild("IniciarArena")
local remoteEscolher = ReplicatedStorage:WaitForChild("EscolherSerie")

local gui = script.Parent
local painel = gui:WaitForChild("Painel")
local labelSerie = gui:WaitForChild("SerieAtual")
local botaoSair = painel:WaitForChild("BotaoSair")

-- Referência física das portas
local pastaArena = workspace:WaitForChild("SistemaArena")
local portas = {
	pastaArena:WaitForChild("Porta1"), 
	pastaArena:WaitForChild("Porta2"), 
	pastaArena:WaitForChild("Porta3")
}

-- ==========================================
-- FUNÇÃO DE CORES E ESTADOS (O CORAÇÃO DO CICLO)
-- ==========================================
local function atualizarPortas(estado)
	if estado == "VERDE" then
		-- ESTADO: Arena Livre
		for _, porta in pairs(portas) do
			porta.CanCollide = false
			porta.Transparency = 0.7
			porta.Color = Color3.fromRGB(0, 255, 0) -- Verde
		end
		labelSerie.Text = "Atenção"
		labelSerie.TextColor3 = Color3.fromRGB(200, 96, 26)
		painel.Visible = true
		botaoSair.Visible = true

		-- ESCONDE BOTÕES DE SÉRIE (Limpeza para o próximo ciclo)
		painel.S6.Visible = false
		painel.S7.Visible = false
		painel.S8.Visible = false
		painel.S9.Visible = false

	elseif estado == "LARANJA" then
		-- ESTADO: Jogador entrou, aguardando início
		for _, porta in pairs(portas) do
			porta.CanCollide = true 
			porta.Transparency = 0.3
			porta.Color = Color3.fromRGB(255, 165, 0) -- Laranja
		end
		labelSerie.Text = "Aguarde..."
		labelSerie.TextColor3 = Color3.fromRGB(255, 165, 0)
		botaoSair.Visible = false

	elseif estado == "VERMELHO" then
		-- ESTADO: Partida em andamento (GO!)
		for _, porta in pairs(portas) do
			porta.CanCollide = true
			porta.Transparency = 0
			porta.Color = Color3.fromRGB(255, 0, 0) -- Vermelho
		end
		labelSerie.Text = "Valendo"
		labelSerie.TextColor3 = Color3.fromRGB(0, 255, 127)
	end
end

local function selecionarSerie(valor)
	remoteEscolher:FireServer(valor)
	atualizarPortas("LARANJA")
end

-- ==========================================
-- ESCUTA OS COMANDOS DO GAME MANAGER
-- ==========================================
eventoIniciar.OnClientEvent:Connect(function(comando)
	print("Recebido do Servidor: " .. tostring(comando))

	if comando == "RESET_TOTAL" then
		atualizarPortas("VERDE")

	elseif comando == "SENSOR_ATIVADO" or comando == "PORTA_LARANJA" or comando == "PRENDER_INDIVIDUAL" then
		-- Quando pisa no sensor ou escolhe manual
		selecionarSerie(6)

	elseif comando == "FECHAR_ARENA_VERMELHO" or comando == "TRANCAR_GERAL" then
		-- Quando o servidor inicia a pergunta
		atualizarPortas("VERMELHO")
	end
end)

-- ==========================================
-- CONFIGURAÇÃO DOS BOTÕES
-- ==========================================
painel.S6.MouseButton1Click:Connect(function() selecionarSerie(6) end)
painel.S7.MouseButton1Click:Connect(function() selecionarSerie(7) end)
painel.S8.MouseButton1Click:Connect(function() selecionarSerie(8) end)
painel.S9.MouseButton1Click:Connect(function() selecionarSerie(9) end)

-- Garante que se o player morrer, a UI reseta para o estado inicial
player.CharacterAdded:Connect(function()
	task.wait(0.5)
	atualizarPortas("VERDE")
end)