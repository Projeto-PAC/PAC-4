local ReplicatedStorage = game:GetService("ReplicatedStorage")
local eventoIniciar = ReplicatedStorage:WaitForChild("IniciarArena")
local eventoVencedor = ReplicatedStorage:WaitForChild("VencedorDefinido")
local pasta = workspace:WaitForChild("SistemaArena")

local portas = {pasta:WaitForChild("Porta1"), pasta:WaitForChild("Porta2"), pasta:WaitForChild("Porta3")}
local jogadoresNaArena = {} 
local contagemIniciada = false

-- Função para colocar no MODO INICIAL
local function modoInicial()
	print("Arena em modo: Aguardando competidores...")
	for _, porta in pairs(portas) do
		porta.CanCollide = false
		porta.Transparency = 0.8
		porta.Color = Color3.fromRGB(0, 255, 0) -- Verde
	end
	pasta:SetAttribute("Ativa", nil)
	contagemIniciada = false
	jogadoresNaArena = {}

	-- Limpa os atributos dos players para poderem entrar de novo
	for _, p in pairs(game.Players:GetPlayers()) do
		p:SetAttribute("JaEntrou", nil)
	end
end

-- Executa o modo inicial ao ligar o server
modoInicial()

local function aoTocar(hit)
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)

	if player and not player:GetAttribute("JaEntrou") and not pasta:GetAttribute("Ativa") then
		player:SetAttribute("JaEntrou", true)
		table.insert(jogadoresNaArena, player)

		-- Prende o jogador (Válvula)
		eventoIniciar:FireClient(player, "PRENDER_INDIVIDUAL")

		-- SÓ MUDA O ESTADO SE TIVER 2 OU MAIS
		if #jogadoresNaArena >= 2 and not contagemIniciada then
			contagemIniciada = true
			print("Mínimo atingido! Saindo do modo Aguardando...")

			eventoIniciar:FireAllClients("MOSTRAR_ATENCAO")

			task.wait(10) -- Tempo de entrada/atenção

			-- MODO JOGO (TRAVA TUDO)
			pasta:SetAttribute("Ativa", true)
			for _, porta in pairs(portas) do
				porta.CanCollide = true
				porta.Transparency = 0
				porta.Color = Color3.fromRGB(255, 0, 0) -- Vermelho
			end
			eventoIniciar:FireAllClients("TRANCAR_GERAL")
		end
	end
end

-- Sensores
for _, objeto in pairs(pasta:GetChildren()) do
	if objeto:IsA("BasePart") and string.find(objeto.Name, "SensorArena") then
		objeto.Touched:Connect(aoTocar)
	end
end

-- VOLTAR AO MODO INICIAL QUANDO TIVER VENCEDOR
eventoVencedor.OnServerEvent:Connect(function()
	print(">>> DEBUG: O Servidor recebeu o sinal de Vencedor! Vou resetar agora...")

	task.wait(2) -- respiro

	-- FORÇA O RESET VISUAL NO SERVIDOR
	for _, porta in pairs(portas) do
		porta.CanCollide = false
		porta.Transparency = 0.8
		porta.Color = Color3.fromRGB(0, 255, 0)
	end

	-- AVISA OS CLIENTES
	for _, p in pairs(getJogadoresAtivos()) do
		if p:GetAttribute("JaEntrou") == true then
			eventoIniciar:FireClient(p, "TRANCAR_GERAL")
		end
	end

	--  resetar quando a arena ficar vazia
	task.spawn(function()
		while true do
			task.wait(5)
			if #jogadoresNaArena == 0 and pasta:GetAttribute("Ativa") then
				print("Arena vazia detectada. Forçando Reset...")
				eventoVencedor:FireServer() -- Simula o fim da partida
			end
		end
	end)
end)