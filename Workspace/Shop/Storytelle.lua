-- Storyteller System (VERSÃO AUTO-GERERADA PARA O SHOP)
local mago = script.Parent
local head = mago:WaitForChild("Head", 10)

-- ==========================================================
--  PAINEL DE CONTROLE
-- ==========================================================
local VELOCIDADE_DIGITACAO = 0.04 
local TEMPO_DE_LEITURA = 3       
local VOLUME_DA_VOZ = 5          
local DistanciaAtivacao = 20     -- Raio para ele começar a falar
local DistanciaMaximaVolume = 40
local DistanciaMinVolume = 10
-- ==========================================================

-- 1. SISTEMA DE SOM
local somVoz = head:FindFirstChild("SomDublagem") or Instance.new("Sound")
somVoz.Name = "SomDublagem"
somVoz.Volume = VOLUME_DA_VOZ
somVoz.Parent = head
somVoz.RollOffMaxDistance = DistanciaMaximaVolume
somVoz.RollOffMinDistance = DistanciaMinVolume
somVoz.RollOffMode = Enum.RollOffMode.Linear 

-- 2. AUTO-CRIAÇÃO DO BALÃO (BILLBOARD GUI)
local balaoGui = mago:FindFirstChild("BalaoHistoria", true) 

if not balaoGui then
	-- Se não existe, o script cria agora!
	balaoGui = Instance.new("BillboardGui")
	balaoGui.Name = "BalaoHistoria"
	balaoGui.Parent = mago
	balaoGui.Adornee = head
	balaoGui.Size = UDim2.new(12, 0, 6, 0)
	balaoGui.StudsOffset = Vector3.new(0, 5, 0) -- Altura acima da cabeça
	balaoGui.AlwaysOnTop = true
end

local linha1 = balaoGui:FindFirstChild("Linha1") or Instance.new("TextLabel")
if linha1.Name ~= "Linha1" then
	linha1.Name = "Linha1"
	linha1.Parent = balaoGui
	linha1.Size = UDim2.new(1, 0, 0.3, 0)
	linha1.BackgroundTransparency = 1
	linha1.TextColor3 = Color3.fromRGB(255, 255, 255)
	linha1.TextStrokeTransparency = 0
	linha1.Font = Enum.Font.Bangers
	linha1.TextScaled = true
end

local linha2 = balaoGui:FindFirstChild("Linha2") or Instance.new("TextLabel")
if linha2.Name ~= "Linha2" then
	linha2.Name = "Linha2"
	linha2.Parent = balaoGui
	linha2.Position = UDim2.new(0, 0, 0.35, 0)
	linha2.Size = UDim2.new(1, 0, 0.6, 0)
	linha2.BackgroundTransparency = 1
	linha2.TextColor3 = Color3.fromRGB(255, 255, 0) -- Amarelo para destaque
	linha2.TextStrokeTransparency = 0
	linha2.Font = Enum.Font.FredokaOne
	linha2.TextScaled = true
	linha2.TextWrapped = true
end

balaoGui.Enabled = false

-- ==========================================================
-- 	
-- ==========================================================
local historia = {
	{texto = "Ei você aí !Tá difícil né?  ", audio = "rbxassetid://126705248572734"},
	{texto = "Tenho as melhores vantagens para você vencer a Arena!", audio = "rbxassetid://121601664777551"},
	{texto = "Use seus pontos para comprar a 'Revelação de Resultados', a 'Eliminação' ou 'Tempo'!", audio = "rbxassetid://101386836336147"},
	{texto = "Ótima Escolha Jogador, boa sorte e volte sempre.", audio = "rbxassetid://87606481014918"},
}


-- FUNÇÃO DIGITAÇÃO
local function digitarTexto(label, mensagem)
	label.Text = ""
	for i = 1, #mensagem do
		label.Text = string.sub(mensagem, 1, i)
		task.wait(VELOCIDADE_DIGITACAO)
	end
end

-- CHECAR JOGADOR PRÓXIMO
local function obterJogadorProximo()
	local playerMaisProximo = nil
	local menorDistancia = DistanciaAtivacao
	for _, p in pairs(game.Players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (head.Position - p.Character.HumanoidRootPart.Position).Magnitude
			if dist < menorDistancia then
				menorDistancia = dist
				playerMaisProximo = p
			end
		end
	end
	return playerMaisProximo
end

-- LOOP PRINCIPAL
local estaFalando = false
local function iniciarApresentacao()
	while true do
		local alvo = obterJogadorProximo()
		if alvo and not estaFalando then
			estaFalando = true
			balaoGui.Enabled = true

			for i, fase in ipairs(historia) do
				-- Se o jogador fugir, ele para de falar
				if not alvo.Character or (head.Position - alvo.Character.HumanoidRootPart.Position).Magnitude > (DistanciaAtivacao + 5) then
					break 
				end

				if fase.audio ~= "rbxassetid://0" then
					somVoz:Stop()
					somVoz.SoundId = fase.audio
					somVoz:Play()
				end

				linha1.Text = "🏪 [ VENDEDOR DO SHOP ] 🏪"
				digitarTexto(linha2, fase.texto)
				task.wait(TEMPO_DE_LEITURA)
			end

			balaoGui.Enabled = false
			estaFalando = false
			task.wait(4) 
		end
		task.wait(1)
	end
end

task.spawn(iniciarApresentacao)