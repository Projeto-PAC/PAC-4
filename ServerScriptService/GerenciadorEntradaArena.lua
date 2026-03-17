-- SERVIÇOS E VARIÁVEIS (INTEGRADO)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local eventoIniciar = ReplicatedStorage:WaitForChild("IniciarArena")
local eventoVencedor = ReplicatedStorage:WaitForChild("VencedorDefinido")
local pasta = workspace:WaitForChild("SistemaArena")

local portas = {pasta:WaitForChild("Porta1"), pasta:WaitForChild("Porta2"), pasta:WaitForChild("Porta3")}
local jogadoresNaArena = {} 
local contagemIniciada = false

-- VARIÁVEL DO FOCARLOBBY
local NOME_LOBBY = "SpawnLocation" 

-- ==========================================
-- 1. SISTEMA DA ARENA (GERENCIADOR)
-- ==========================================

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

-- Sensores da Arena
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

	-- Nota: A função getJogadoresAtivos() não estava definida no snippet original, 
	-- certifique-se que ela exista no seu script principal ou use game.Players:GetPlayers()
	for _, p in pairs(game.Players:GetPlayers()) do
		if p:GetAttribute("JaEntrou") == true then
			eventoIniciar:FireClient(p, "TRANCAR_GERAL")
		end
	end

	-- resetar quando a arena ficar vazia
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


-- ==========================================
-- 2. SEGURANÇA, RESPawn E FOCO NO LOBBY
-- ==========================================

local function gerenciarEntrada(p)
	print("🔍 MONITORANDO: " .. p.Name)

	p.CharacterAdded:Connect(function(char)
		print("📦 BONECO NASCEU: " .. p.Name)

		local hum = char:WaitForChild("Humanoid")
		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		local stats = p:WaitForChild("PlayerStats", 10)
		local lobby = workspace:FindFirstChild("LobbySpawn") -- Usado pelo Gerenciador
		local spawnLobbyFocar = workspace:FindFirstChild(NOME_LOBBY, true) -- Usado pelo FocarLobby

		-- --- LÓGICA DO FOCARLOBBY.LUA ---
		if not p:GetAttribute("PrimeiroNascimentoConcluido") then
			if hrp and spawnLobbyFocar then
				task.wait(0.1) -- Delay para carregar
				hrp.CFrame = spawnLobbyFocar.CFrame + Vector3.new(0, 5, 0)

				p:SetAttribute("PrimeiroNascimentoConcluido", true)
				print("Player forçado ao Lobby no início da sessão.")
			end
		else
			print("Player morreu/renasceu. Deixando o sistema de spawn do Roblox agir.")
		end

		-- --- LÓGICA DE RESPAWN DO GERENCIADOR ---
		hum.Died:Connect(function()
			print("💀 " .. p.Name .. " morreu. Preparando respawn...")

			if stats then stats.JogoIniciado.Value = false end

			task.wait(3) -- Tempo de espera do túmulo
			p:LoadCharacter() 
		end)

		-- TELEPORTE PARA O LOBBY (Se não estiver em jogo e não for o primeiro nascimento já tratado)
		if lobby and hrp and stats and stats.JogoIniciado.Value == false then
			task.wait(0.1) 
			char:PivotTo(lobby.CFrame + Vector3.new(0, 5, 0))
			print("📍 " .. p.Name .. " enviado ao Lobby pelo Gerenciador.")
		end
	end)

	if not p.Character then
		p:LoadCharacter()
	end
end

-- Conexão para novos players
Players.PlayerAdded:Connect(gerenciarEntrada)