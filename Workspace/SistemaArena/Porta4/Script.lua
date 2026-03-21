local porta = script.Parent
local placa = porta:WaitForChild("PlacaPr")
local letreiroPai = placa:WaitForChild("Letreiro")

-- ==========================================================
--  VARIÁVEIS DE CONTROLO (Ajuste aqui)
-- ==========================================================
local LOGO_ID = "rbxassetid://115918467735624" 
local TEXTO_MSG = "ARENA DE COMPETIÇÃO MATH RUSH - VALENDO 100 PONTOS!"

-- 📏 DISTÂNCIAS INTERNAS
local DISTANCIA_LOGO_TEXTO = 25   -- Espaço entre o logo e o texto no mesmo bloco
local ESPACO_ENTRE_REPETICOES = 520 -- Espaço entre o fim de um ciclo e o início do outro

-- ⚡ MOVIMENTO
local VELOCIDADE = 0.0005 
local ALTURA_FONTE = 0.7 -- 70% da altura da placa

-- ==========================================================
--  SETUP DE RENDERIZAÇÃO
-- ==========================================================
placa.AlwaysOnTop = true
placa.LightInfluence = 0
letreiroPai.BackgroundTransparency = 1 
letreiroPai.ClipsDescendants = true
letreiroPai:ClearAllChildren() 

-- Função para criar a unidade [LOGO] [TEXTO]
local function criarVagao(nome)
	local vagao = Instance.new("Frame")
	vagao.Name = nome
	vagao.BackgroundTransparency = 1
	vagao.AnchorPoint = Vector2.new(0, 0.5)
	vagao.AutomaticSize = Enum.AutomaticSize.X 
	vagao.Size = UDim2.new(0, 0, ALTURA_FONTE, 0) 
	vagao.Parent = letreiroPai

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, DISTANCIA_LOGO_TEXTO)
	layout.Parent = vagao

	-- [L] LOGO
	local l = Instance.new("ImageLabel")
	l.Size = UDim2.new(0, 115, 0.8, 0) 
	l.Image = LOGO_ID
	l.BackgroundTransparency = 1
	l.ScaleType = Enum.ScaleType.Fit
	l.Parent = vagao

	-- [T] TEXTO
	local t = Instance.new("TextLabel")
	t.AutomaticSize = Enum.AutomaticSize.X
	t.Size = UDim2.new(0, 0, 1, 0)
	t.Text = TEXTO_MSG
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 255, 0)
	t.Font = Enum.Font.FredokaOne
	t.BackgroundTransparency = 1
	t.Parent = vagao

	return vagao
end

-- 3. MOTOR DE MOVIMENTO SINCRONIZADO
local BlocoA = criarVagao("BlocoA")
local BlocoB = criarVagao("BlocoB")

-- Aguarda a engine calcular os tamanhos antes de iniciar o loop
task.wait(0.1)

-- Cálculo do ponto de reset considerando o novo espaço entre ciclos
local larguraFrame = BlocoA.AbsoluteSize.X / letreiroPai.AbsoluteSize.X
local gapNormalizado = ESPACO_ENTRE_REPETICOES / letreiroPai.AbsoluteSize.X
local LARGURA_TOTAL_CICLO = larguraFrame + gapNormalizado

local posA = 0
local posB = LARGURA_TOTAL_CICLO

print("✅ Letreiro Math Rush: Espaçamento de ciclos configurado.")

while true do
	posA = posA - VELOCIDADE
	posB = posB - VELOCIDADE

	BlocoA.Position = UDim2.new(posA, 0, 0.5, 0)
	BlocoB.Position = UDim2.new(posB, 0, 0.5, 0)

	-- Teletransporte para manter o fluxo contínuo com o espaço definido
	if posA <= -LARGURA_TOTAL_CICLO then
		posA = posB + LARGURA_TOTAL_CICLO
	end

	if posB <= -LARGURA_TOTAL_CICLO then
		posB = posA + LARGURA_TOTAL_CICLO
	end

	task.wait()
end