-- Storyteller System (VERSÃO BALÃO E VOZ)
local mago = script.Parent
local head = mago:WaitForChild("Head", 5)

-- ==========================================================
--  PAINEL DE CONTROLE (VALORES ORIGINAIS MANTIDOS)
-- ==========================================================
local VELOCIDADE_DIGITACAO = 0.04 -- Quanto MENOR, mais RÁPIDO digita
local TEMPO_DE_LEITURA = 4       -- Segundos que o texto fica parado após digitar
local VOLUME_DA_VOZ = 5          -- Volume do áudio (de 0 a 10)
local DistanciaMaximaVolume = 40
local DistanciaMinVolume = 10
-- ==========================================================

-- 1. INSTALANDO O SISTEMA DE SOM
local somVoz = head:FindFirstChild("SomDublagem") or Instance.new("Sound")
somVoz.Name = "SomDublagem"
somVoz.Volume = VOLUME_DA_VOZ
somVoz.Parent = head

-- AJUSTE DE DISTÂNCIA (3D SOUND)
somVoz.RollOffMaxDistance = DistanciaMaximaVolume
somVoz.RollOffMinDistance = DistanciaMinVolume
somVoz.RollOffMode = Enum.RollOffMode.Linear 

-- 2. CONFIGURAÇÃO DO BALÃO
local balaoGui = mago:FindFirstChild("BalaoHistoria", true) 
local linha1 = balaoGui and balaoGui:FindFirstChildOfClass("TextLabel")

local linha2 = balaoGui:FindFirstChild("Linha2")
if not linha2 and balaoGui then
	linha2 = linha1:Clone()
	linha2.Name = "Linha2"
	linha2.Parent = balaoGui
end

if balaoGui and linha1 and linha2 then
	balaoGui.StudsOffset = Vector3.new(0, 7, 0)
	balaoGui.Size = UDim2.new(12, 0, 6, 0)
	linha1.Size = UDim2.new(1, 0, 0.3, 0)
	linha1.Position = UDim2.new(0, 0, 0, 0)
	linha1.TextScaled = true
	linha1.BackgroundTransparency = 1
	linha1.TextColor3 = Color3.fromRGB(255, 255, 255)
	linha2.Size = UDim2.new(0.9, 0, 0.6, 0) 
	linha2.Position = UDim2.new(0.05, 0, 0.35, 0)
	linha2.TextColor3 = Color3.fromRGB(255, 255, 0)
	linha2.TextScaled = true 
	linha2.TextWrapped = true 
	linha2.BackgroundTransparency = 1
end

-- ==========================================================
-- CONTEÚDO DA HISTÓRIA
-- ==========================================================
local historia = {
	{texto = "Olá Amiguinho, bem vindo a arena de Competição ",  audio = "rbxassetid://96957804976853"},
	{texto = "É só atravecar o portal a minha direita, que você chega nela. ",  audio = "rbxassetid://108622466250640"},
	{texto = "Mais uma coisa! Boa sorte, você vai precisar...  ", audio = "rbxassetid://77954090240821"},
}

-- FUNÇÃO DIGITAÇÃO (TYPEWRITER)
local function digitarTexto(label, mensagem)
	label.Text = ""
	for i = 1, #mensagem do
		label.Text = string.sub(mensagem, 1, i)
		task.wait(VELOCIDADE_DIGITACAO)
	end
end

-- LOOP PRINCIPAL (SOMENTE BALÃO E VOZ)
local function iniciarApresentacao()
	while true do
		for i, fase in ipairs(historia) do

			-- --- COMANDO DE ÁUDIO ---
			if fase.audio ~= "rbxassetid://0" then
				somVoz:Stop()
				somVoz.SoundId = fase.audio
				somVoz:Play()
			end

			-- --- COMANDO DE TÍTULO ---
			if i >= #historia - 1 then
				linha1.Text = "⚠️ --- DESAFIO --- ⚠️"
			else
				linha1.Text = "📖  Arena de Competição  📖"
			end

			-- --- COMANDO DE TEXTO ---
			digitarTexto(linha2, fase.texto)
			task.wait(TEMPO_DE_LEITURA)
		end
	end
end

task.wait(2)
task.spawn(iniciarApresentacao)