local partLava = script.Parent
local Players = game:GetService("Players")

-- ==========================================================
-- PAINEL DE CONTROLE (REGRA 1: COMPLEXIDADE MANTIDA)
-- ==========================================================
local CONFIG = {
	TEMPO_DEBOUNCE_SOUND = 1.5,
	ESPERA_ENTRE_CHECHAGEM_ESTATICA = 0.5, -- Para detectar quem está parado
	RAIO_MORTE = 0.1, -- Offset para detecção
}

local listaDeSons = {
	"Morri", "Socorro", "DepoisdeMorrer", 
	"faustão_errou", "Morrer", "Faustão_Fogo"
}

-- Tabelas de Controle Individual (Debounce por Jogador)
local mortosNaRodada = {} 
local sonsEmProcesso = {}

-------------------------------------------------
-- 🔊 FUNÇÃO DE ÁUDIO ALEATÓRIO
-------------------------------------------------
local function tocarSomAleatorio(character)
	if sonsEmProcesso[character] then return end
	sonsEmProcesso[character] = true

	local indiceSorteado = math.random(1, #listaDeSons)
	local nomeSorteado = listaDeSons[indiceSorteado]
	local somParaTocar = partLava:FindFirstChild(nomeSorteado)

	if somParaTocar then
		local somClone = somParaTocar:Clone() -- Clona para permitir múltiplos sons ao mesmo tempo
		somClone.Parent = character:FindFirstChild("Head") or partLava
		somClone.RollOffMaxDistance = 250
		somClone:Play()

		game:GetService("Debris"):AddItem(somClone, somClone.TimeLength + 1)
		warn("🎲 SOM ACIONADO PARA: " .. character.Name .. " (" .. nomeSorteado .. ")")
	end

	task.wait(CONFIG.TEMPO_DEBOUNCE_SOUND)
	sonsEmProcesso[character] = nil
end

-------------------------------------------------
-- 💀 FUNÇÃO DE EXECUÇÃO DE MORTE
-------------------------------------------------
local function processarMorte(character)
	if mortosNaRodada[character] then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		mortosNaRodada[character] = true

		-- Executa o som
		task.spawn(tocarSomAleatorio, character)

		-- Física e Dano
		print("💥 FISICA: Boneco " .. character.Name .. " processado pela lava.")
		character:BreakJoints()
		humanoid.Health = 0

		-- Libera o boneco da lista após o respawn (2 segundos)
		task.delay(2, function()
			mortosNaRodada[character] = nil
		end)
	end
end

-------------------------------------------------
-- 🔥 DETECÇÃO 1: MOVIMENTO (Touched)
-------------------------------------------------
partLava.Touched:Connect(function(hit)
	local character = hit.Parent
	if character:FindFirstChildOfClass("Humanoid") then
		processarMorte(character)
	elseif character.Parent:FindFirstChildOfClass("Humanoid") then
		processarMorte(character.Parent)
	end
end)

-------------------------------------------------
-- 🔥 DETECÇÃO 2: ESTÁTICA (Para quem está parado)
-------------------------------------------------
-- Esta função checa quem está DENTRO da lava, mesmo se não houver movimento
task.spawn(function()
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {partLava} -- Ignora a própria lava

	while true do
		-- Pega TODAS as partes que estão encostando ou dentro da lava agora
		local partesNaLava = workspace:GetPartsInPart(partLava, params)

		for _, parte in pairs(partesNaLava) do
			local char = parte.Parent
			if char:FindFirstChildOfClass("Humanoid") then
				processarMorte(char)
			end
		end

		task.wait(CONFIG.ESPERA_ENTRE_CHECHAGEM_ESTATICA)
	end
end)

print("🔥 [LAVA ENGINE]: Sistema Multiprocessado ativado com detecção estática.")