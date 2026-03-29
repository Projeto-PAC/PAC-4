-- Storyteller & Slideshow System 
local mago = script.Parent
local head = mago:WaitForChild("Head", 5)

-- ==========================================================
--  PAINEL DE CONTROLE (VALORES ORIGINAIS MANTIDOS)
-- ==========================================================
local VELOCIDADE_DIGITACAO = 0.04 -- Quanto MENOR, mais RÁPIDO digita
local TEMPO_DE_LEITURA = 4       -- Segundos que o texto fica parado após digitar
local VOLUME_DA_VOZ = 10          -- Volume do áudio (de 0 a 10)
local DistanciaMaximaVolume = 70
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
somVoz.RollOffMode = Enum.RollOffMode.Linear -- Garante que o som suma exatamente na distância máxima

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
	{texto = "Em um universo, onde a magia e a matemática são a mesma coisa ", 
		imagem = "rbxassetid://115918467735624",
		audio = "rbxassetid://127770876728210"
	},

	{texto = "Onde os Magos Matemáticos, criaram a Arena de Cálculos de Nivelamento ",
		imagem = "rbxassetid://130372073808818",
		audio = "rbxassetid://133026540008764"
	},

	{texto = "E criaram também a Arena de Cálculos de Competição ",
		imagem = "rbxassetid://105879529087531",
		audio = "rbxassetid://138927289382812"
	},

	{texto = "Cálculos dos desafios, seram para os Alunos de 6º, à 9º Ano ",
		imagem = "rbxassetid://129429634060348",
		audio = "rbxassetid://101781474592700"
	},

	{texto = "Você escolhe, em qual Arena entrar, para treinar, ou competir ",
		imagem = "rbxassetid://129429634060348",
		audio = "rbxassetid://80373305650502"
	},
	
	{texto = "Lembrando que, antes de entrar na Arena de Nivelamento ",
		imagem = "rbxassetid://129429634060348",
		audio = "rbxassetid://83632598378934"
	},

	{texto = "Os MAGOS decidiram, que você irá enfrentar, o desafio das Tabuadas ",
		imagem = "rbxassetid://115577276264245",
		audio = "rbxassetid://70912097556910"
	},

	{texto = "Mas Muita atenção, para pular nos blocos certos, se nao vc cai na Lava ",
		imagem = "rbxassetid://115282622884426",
		audio = "rbxassetid://99223960014257"
	},

	{texto = "Ao passar pela Tabuada, não fique matando aula, se não o Antimático pega você ",
		imagem = "rbxassetid://140358910668350",
		audio = "rbxassetid://121295237461066"
	},

	{texto = "Entre rapido no portal dentro do castelo, que leva para o Desafio e ganhe 1 ponto por acerto ",
		imagem = "rbxassetid://140358910668350",
		audio = "rbxassetid://98335142402469"
	},

	{texto = "Arena de Competição, é o desafio que dará 100 pontos se vence-lo ",
		imagem = "rbxassetid://105879529087531",
		audio = "rbxassetid://120789674547955"
	},

	{texto = "É só passar pelo portal, e aguardar sua vêz na Arena",
		imagem = "rbxassetid://130931436682497",
		audio = "rbxassetid://93339843512144"
	},

	{texto = "É nessa jornada, que os jogadores buscam provar seu valor, e subir no Ranking Global ",
		imagem = "rbxassetid://116975535158969",
		audio = "rbxassetid://73396805879445"
	},

	{texto = "Apareceu dificuldade? tente trocar seus pontos Globais nos Shop em vantagens! ",
		imagem = "rbxassetid://123420388733433",
		audio = "rbxassetid://79141317366297"
	},

	{texto = "Desafio Math Rush, Aprenda se divertindo ",
		imagem = "rbxassetid://115918467735624",
		audio = "rbxassetid://107468455504674"
	},

	{texto = "Assim... O Mago da Matemática, determinou...!",
		imagem = "rbxassetid://127359741999141",
		audio = "rbxassetid://124455574464079"
	},

	{texto = "Boa sorte, você vai precisar... he he he he he... ",
		imagem = "rbxassetid://115918467735624",
		audio = "rbxassetid://140205543994836"
	},

}

-- FUNÇÃO DIGITAÇÃO (TYPEWRITER)
local function digitarTexto(label, mensagem)
	label.Text = ""
	for i = 1, #mensagem do
		label.Text = string.sub(mensagem, 1, i)
		task.wait(VELOCIDADE_DIGITACAO)
	end
end

-- LOOP PRINCIPAL
local function iniciarApresentacao()
	local lobby = workspace:WaitForChild("Lobby", 10)
	local telaoModelo = lobby:FindFirstChild("Tela Video do jogo", true)
	local slideShow = telaoModelo and telaoModelo:FindFirstChild("SlideShow", true)

	while true do
		for i, fase in ipairs(historia) do
			-- --- COMANDO DE IMAGEM ---
			if slideShow then 
				slideShow.Image = fase.imagem 
				slideShow.ImageTransparency = 0 
				slideShow.Visible = true
			end

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
				linha1.Text = "📖 --- HISTÓRIA --- 📖"
			end

			-- --- COMANDO DE TEXTO ---
			digitarTexto(linha2, fase.texto)
			task.wait(TEMPO_DE_LEITURA)
		end
	end
end

task.wait(2)
task.spawn(iniciarApresentacao)