local pastaTaboada = script.Parent
local displayPrincipal = pastaTaboada:WaitForChild("Answer0")
local blocoFinal = pastaTaboada:WaitForChild("Answer31")

-- ==========================================================
-- CONFIGURAÇÕES DE CONTROLE (Sua autoridade)
-- ==========================================================
local TABUADA_PARA_COMECAR = 3  -- Determine aqui onde o desafio inicia 
local TEMPO_DE_TROCA = 60 
local MATERIAL_FOSCO = Enum.Material.Plastic
local TAMANHO_FONTE_MEGA = 135 

-- ==========================================================
-- FUNÇÕES DE SUPORTE
-- ==========================================================

-- Atualiza os textos com a Mega Fonte (135)
local function atualizarTexto(bloco, texto)
	local gui = bloco:FindFirstChildOfClass("SurfaceGui")
	if gui then
		local label = gui:FindFirstChildOfClass("TextLabel")
		if label then
			label.Text = tostring(texto)
			label.TextSize = TAMANHO_FONTE_MEGA
			label.TextScaled = false 
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
	-- Configura blocos de Início e Fim (Sólidos e Foscos)
	displayPrincipal.Color = Color3.fromRGB(255, 255, 0)
	displayPrincipal.Material = MATERIAL_FOSCO
	displayPrincipal.CanCollide = true 

	blocoFinal.Color = Color3.fromRGB(0, 255, 0)
	blocoFinal.Material = MATERIAL_FOSCO
	blocoFinal.CanCollide = true 
	atualizarTexto(blocoFinal, "FINAL")

	-- Inicializa o ponteiro na tabuada escolhida
	local n = TABUADA_PARA_COMECAR

	while true do
		-- Validação de segurança: se o usuário colocar algo fora de 2-9, reseta para 2
		if n < 2 or n > 9 then n = 2 end

		atualizarTexto(displayPrincipal, "TABUADA: " .. n)
		warn("🏆 ARENA ATIVA: Iniciando sequência na Tabuada do " .. n)

		-- Renderiza os 10 grupos (Answer1 ao 30)
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

					atualizarTexto(bloco, valorNoBloco)
					bloco.Material = MATERIAL_FOSCO
					bloco.Color = gerarCorAleatoria()
					bloco.Transparency = 0

					-- Física: Só o correto é sólido
					if valorNoBloco == resultadoCorreto then
						bloco.CanCollide = true
					else
						bloco.CanCollide = false 
					end
				end
			end
		end

		task.wait(TEMPO_DE_TROCA)

		-- Lógica de Progressão Circular:
		-- Incrementa o valor. Se chegar em 10, volta para o 2.
		n = n + 1
		if n > 9 then
			n = 2
		end
	end
end

iniciarArenaPro()