local ReplicatedStorage = game:GetService("ReplicatedStorage")
local eventoIniciar = ReplicatedStorage:WaitForChild("IniciarArena")
local eventoVencedor = ReplicatedStorage:WaitForChild("VencedorDefinido")

local sistemaArena = workspace:WaitForChild("SistemaArena")

local portas = {
	sistemaArena:WaitForChild("Porta1"), 
	sistemaArena:WaitForChild("Porta2"), 
	sistemaArena:WaitForChild("Porta3")
}

local jogadoresNaArena = {}
local partidaAtiva = false

-- Função para trancar/abrir
local function setPortasGeral(fechar)
	for _, porta in pairs(portas) do
		porta.CanCollide = fechar
		if fechar then
			porta.Color = Color3.fromRGB(255, 0, 0)
			porta.Transparency = 0.3
		else
			porta.Color = Color3.fromRGB(0, 255, 0)
			porta.Transparency = 0.8
		end
	end
end

-- Limpa a lista de jogadores mortos ou que saíram
local function limparLista()
	for i = #jogadoresNaArena, 1, -1 do
		local p = jogadoresNaArena[i]
		if not p or not p.Parent or not p.Character or not p.Character:FindFirstChild("Humanoid") then
			table.remove(jogadoresNaArena, i)
		end
	end
end

local function aoTocar(hit)
	if partidaAtiva then return end -- Se já começou, ignora toques

	local player = game.Players:GetPlayerFromCharacter(hit.Parent)
	if player and not player:GetAttribute("Preso") then

		-- Verifica se ele já está na lista para não contar 2x o mesmo cara
		local jaEstaNaLista = false
		for _, p in pairs(jogadoresNaArena) do
			if p == player then jaEstaNaLista = true break end
		end

		if not jaEstaNaLista then
			player:SetAttribute("Preso", true)
			table.insert(jogadoresNaArena, player)

			-- Prende ele individualmente pelo LocalScript
			eventoIniciar:FireClient(player, "PRENDER_INDIVIDUAL")

			limparLista()
			print("Jogadores prontos: " .. #jogadoresNaArena .. "/2")

			-- SÓ COMEÇA SE TIVER 2 OU MAIS
			if #jogadoresNaArena >= 2 then
				partidaAtiva = true
				print("MÍNIMO ATINGIDO! Iniciando Atenção...")

				-- Avisa a sua UI para mostrar "ATENÇÃO" e começar os 10s
				eventoIniciar:FireAllClients("MOSTRAR_ATENCAO")

				task.wait(10) -- ESPERA OS 10 SEGUNDOS DE ATENÇÃO

				-- VERIFICAÇÃO FINAL ANTES DO GO
				limparLista()
				if #jogadoresNaArena >= 2 then
					print("GOOOO!")
					setPortasGeral(true) -- Tranca geral
					eventoIniciar:FireAllClients("TRANCAR_GERAL")
				else
					print("Alguém sumiu! Abortando...")
					partidaAtiva = false
					-- Opcional: avisar que falta gente
				end
			end
		end
	end
end

-- Conectar Sensores
for _, obj in pairs(sistemaArena:GetChildren()) do
	if obj:IsA("BasePart") and string.find(obj.Name, "SensorArena") then
		obj.CanCollide = false
		obj.Touched:Connect(aoTocar)
	end
end

-- RESET TOTAL
eventoVencedor.OnServerEvent:Connect(function()
	task.wait(5)
	partidaAtiva = false
	jogadoresNaArena = {}
	setPortasGeral(false)
	eventoIniciar:FireAllClients("RESET_PORTAS")
	-- Limpa os atributos de todo mundo
	for _, p in pairs(game.Players:GetPlayers()) do
		p:SetAttribute("Preso", nil)
	end
end)