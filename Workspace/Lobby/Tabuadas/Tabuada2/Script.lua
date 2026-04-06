local pastaTaboada = script.Parent
local displayPrincipal = pastaTaboada:WaitForChild("Answer0")
local displayPrincipall = pastaTaboada:WaitForChild("Answer0.1")

local blocoFinal = pastaTaboada:WaitForChild("Answer31")

local replicatedStorage = game:GetService("ReplicatedStorage")
local modeloPergunta = replicatedStorage:WaitForChild("PerguntasDesafio"):WaitForChild("BillboardGui")


-- ==========================================================
-- CONFIGURAÇÕES DE CONTROLE (Sua autoridade)
-- ==========================================================
local TABUADA_PARA_COMECAR = 5  -- Onde o desafio inicia 
local TEMPO_DE_TROCA = 120  -- Segundos para a contagem
local MATERIAL_FOSCO = Enum.Material.Plastic
local TAMANHO_FONTE_MEGA = 135 

-- ==========================================================
-- FUNÇÕES DE SUPORTE
-- ==========================================================


local function aplicarPerguntaNoBloco(bloco, n, questao)
	local antigo = bloco:FindFirstChild("BillboardGui")
	if antigo then
		antigo:Destroy()
	end

	local clone = modeloPergunta:Clone()
	clone.Parent = bloco

	clone.Size = UDim2.new(0, 140, 0, 45)

	-- esquerda + altura correta
	clone.StudsOffset = Vector3.new(-(bloco.Size.X + 1), 2, 0)

	clone.MaxDistance = 25

	local label = clone:FindFirstChildOfClass("TextLabel")
	if label then
		label.Text = n .. " x " .. questao .. " = ?"

		label.Size = UDim2.new(1, 0, 1, 0)

		label.TextScaled = false
		label.TextSize = 20

		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.fromRGB(255,255,255)
		label.TextStrokeTransparency = 0

		label.BackgroundTransparency = 0.25
		label.BackgroundColor3 = Color3.fromRGB(20,20,20)

		label.BorderSizePixel = 1
		label.BorderColor3 = Color3.fromRGB(255,255,255)
	end
end

-- Atualiza os textos (Ajustado para aceitar duas linhas)
local function atualizarTexto(bloco, texto)
	local gui = bloco:FindFirstChildOfClass("SurfaceGui")
	if gui then
		local label = gui:FindFirstChildOfClass("TextLabel")
		if label then
			label.Text = tostring(texto)
			-- Se o texto for grande (duas linhas), usamos TextScaled para não cortar
			if string.find(tostring(texto), "\n") then
				label.TextScaled = true
			else
				label.TextSize = TAMANHO_FONTE_MEGA
				label.TextScaled = false 
			end
			label.Font = Enum.Font.GothamBold
		end
	end
end

-- Gera cores individuais para cada Answer
local function gerarCorAleatoria()
	return Color3.fromHSV(math.random(), 0.7, 0.9)
end

-- Gera apenas números para as respostas erradas
local function gerarRespostasErradas(correta)
	local erradas = {}
	while #erradas < 2 do
		local numErrado = correta + math.random(-7, 10)
		if numErrado > 0 and numErrado ~= correta and not table.find(erradas, numErrado) then
			table.insert(erradas, numErrado)
		end
	end
	return erradas
end

-- ==========================================================
-- LOOP PRINCIPAL (LÓGICA DE ENGENHARIA)
-- ==========================================================
local function iniciarArenaPro()
	-- Configura blocos de Início e Fim
	displayPrincipal.Color = Color3.fromRGB(255, 255, 0)
	displayPrincipal.Material = MATERIAL_FOSCO
	displayPrincipal.CanCollide = true 

	displayPrincipall.Color = Color3.fromRGB(255, 255, 0)
	displayPrincipall.Material = MATERIAL_FOSCO
	displayPrincipall.CanCollide = true

	blocoFinal.Color = Color3.fromRGB(0, 255, 0)
	blocoFinal.Material = MATERIAL_FOSCO
	blocoFinal.CanCollide = true 
	atualizarTexto(blocoFinal, "FINAL")

	local n = TABUADA_PARA_COMECAR

	while true do
		if n < 2 or n > 9 then n = 2 end

		atualizarTexto(displayPrincipal, "DESTINO PARA ARENA 7º  TABUADA DE: " .. n)
		warn("🏆 ARENA ATIVA: Iniciando sequência na Tabuada do " .. n)

		-- Renderiza os 10 grupos
		for questao = 1, 10 do
			local resultadoCorreto = n * questao
			local respostasErradas = gerarRespostasErradas(resultadoCorreto)
			local sorteioGanhador = math.random(1, 3)
			local indexBase = (questao - 1) * 3

			local listaValores = {respostasErradas[1], respostasErradas[2]}
			table.insert(listaValores, sorteioGanhador, resultadoCorreto)

			for i = 1, 3 do
				local nomeBloco = "Answer" .. (indexBase + i)
				local bloco = pastaTaboada:FindFirstChild(nomeBloco)

				if bloco and bloco:IsA("BasePart") then
					local valorNoBloco = listaValores[i]
					if i == 1 then
						aplicarPerguntaNoBloco(bloco, n, questao)
					end
					atualizarTexto(bloco, valorNoBloco)
					bloco.Material = MATERIAL_FOSCO
					bloco.Color = gerarCorAleatoria()
					bloco.Transparency = 0

					if valorNoBloco == resultadoCorreto then
						bloco.CanCollide = true
					else
						bloco.CanCollide = false 
					end
				end
			end
		end

		-- ==========================================================
		-- TIMER REGRESSIVO DUPLO NO ANSWER0.1
		-- ==========================================================
		for segundosRestantes = TEMPO_DE_TROCA, 0, -1 do
			-- A MÁGICA ESTÁ AQUI: "\n" pula a linha
			local textoDuplo = "DESTINO PARA ARENA 7º ANO" .. "" .. "\nTABUADA DE: " .. n .. " TEMPO: " .. segundosRestantes .. "s"
			atualizarTexto(displayPrincipall, textoDuplo)

			-- Alerta visual nos últimos 10 segundos
			if segundosRestantes <= 10 then
				displayPrincipall.Color = Color3.fromRGB(255, 0, 0)
			else
				displayPrincipall.Color = Color3.fromRGB(255, 255, 0)
			end

			task.wait(1)
		end

		n = n + 1
		if n > 9 then n = 2 end
	end
end

iniciarArenaPro()