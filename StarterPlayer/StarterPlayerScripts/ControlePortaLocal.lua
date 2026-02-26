local ReplicatedStorage = game:GetService("ReplicatedStorage")
local eventoIniciar = ReplicatedStorage:WaitForChild("IniciarArena")
local player = game.Players.LocalPlayer
local pasta = workspace:WaitForChild("SistemaArena")
local portas = {
	pasta:WaitForChild("Porta1"), 
	pasta:WaitForChild("Porta2"), 
	pasta:WaitForChild("Porta3")
}

-- Função auxiliar para abrir/fechar as portas
local function setPortasEstado(podeEntrar)
	for _, porta in pairs(portas) do
		if podeEntrar then
			-- Abertas para entrar
			porta.CanCollide = false
			porta.Transparency = 0.8
			porta.Color = Color3.fromRGB(0, 255, 0) -- Verde
		else
			-- Fechadas (trancadas)
			porta.CanCollide = true
			porta.Transparency = 0.2
			porta.Color = Color3.fromRGB(255, 0, 0) -- Vermelho
		end
	end
end

eventoIniciar.OnClientEvent:Connect(function(comando)
	print("Comando recebido nas portas: " .. tostring(comando))

	if comando == "PRENDER_INDIVIDUAL" then
		-- Quando o jogador entra, a porta fica sólida apenas para ele não sair
		for _, porta in pairs(portas) do
			porta.CanCollide = true
		end
		print("Você entrou na arena. Porta trancada para você.")

	elseif comando == "FECHAR_ARENA_VERMELHO" or comando == "TRANCAR_GERAL" then
		-- Tranca as portas para todos (partida em andamento)
		setPortasEstado(false)
		print("Arena trancada. Partida em andamento.")

	elseif comando == "RESET_TOTAL" or comando == "RESET_PORTAS" then
		-- Abre as portas para o próximo ciclo
		setPortasEstado(true)
		print("Arena liberada para o próximo ciclo!")
	end
end)

-- Garantir estado inicial (aberto para entrada)
setPortasEstado(true)
