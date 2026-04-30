--  	

local Model = script.Parent
local Debris = game:GetService("Debris")

-- ==========================================================================
-- 1. CONFIGURAÇÕES DOS ÍCONES (EXCLUSIVAMENTE 3 OPÇÕES)
-- ==========================================================================
-- Removi as espadas, hambúrguer e o ícone de vazio.
local Icons = {
	{ID = "Vantage1", Name = "MÁGICO", ImgID = 122050960529804}, -- Mágico (Revelar)
	{ID = "Vantage2", Name = "BOMBA", ImgID = 73545359543335},  -- Bomba (Eliminar)
	{ID = "Vantage3", Name = "RELÓGIO", ImgID = 94752839130654}  -- Relógio (Tempo)
}

local CoresVantagens = {
	["Vantage1"] = Color3.fromRGB(255, 0, 255), -- Magenta (Magia)
	["Vantage2"] = Color3.fromRGB(255, 0, 0),   -- Vermelho (Bomba)
	["Vantage3"] = Color3.fromRGB(0, 255, 255), -- Ciano (Relógio)
}

local CooldownTime = 2
local SPIN_COST = 1 
local im = "rbxassetid://"

local OnCooldown = false
local C = {Slot1 = "", Slot2 = "", Slot3 = ""}
local ultimoPremio = "" 

-- Referências de Peças (Baseado na sua estrutura image_3892a5.png)
local Slots = {Model.Slot1, Model.Slot2, Model.Slot3}
local Image1, Image2, Image3 = Slots[1].Decal, Slots[2].Decal, Slots[3].Decal
local SpinProx = Model.ActivationPart.SpinProx

-- Limpeza de prompts de aposta
if Model.ActivationPart:FindFirstChild("UpProx") then Model.ActivationPart.UpProx.Enabled = false end
if Model.ActivationPart:FindFirstChild("DownProx") then Model.ActivationPart.DownProx.Enabled = false end

-- ==========================================================================
-- 2. LÓGICA DE ECONOMIA (SISTEMA DE PONTOS DO MATH RUSH)
-- ==========================================================================
local function GetAvailablePoints(Player)
	local acertos = Player:FindFirstChild("AcertosPorSerie")
	local leaderstats = Player:FindFirstChild("leaderstats")
	local statsLoja = Player:FindFirstChild("StatsLoja")

	if not acertos or not leaderstats or not statsLoja then return 0 end

	local s6 = acertos:FindFirstChild("Serie6") and acertos.Serie6.Value or 0
	local s7 = acertos:FindFirstChild("Serie7") and acertos.Serie7.Value or 0
	local s8 = acertos:FindFirstChild("Serie8") and acertos.Serie8.Value or 0
	local s9 = acertos:FindFirstChild("Serie9") and acertos.Serie9.Value or 0
	local camp = leaderstats:FindFirstChild("Camp") and leaderstats.Camp.Value or 0
	local gastoNum = statsLoja:FindFirstChild("SaldoUtilizado") and statsLoja.SaldoUtilizado.Value or 0

	return (s6 + s7 + s8 + s9 + camp) - gastoNum
end

local function AdicionarGasto(Player, Valor)
	local statsLoja = Player:FindFirstChild("StatsLoja")
	if statsLoja and statsLoja:FindFirstChild("SaldoUtilizado") then
		statsLoja.SaldoUtilizado.Value += Valor
		return true
	end
	return false
end

local function EntregarPremio(Player, itemID)
	local inventory = Player:FindFirstChild("VantageInventory")
	if inventory then
		local item = inventory:FindFirstChild(itemID)
		if item and item:IsA("IntValue") then
			item.Value += 1
			print("✅ ENGENHARIA: JackPot! " .. itemID .. " adicionado ao inventário.")
		end
	end
end

-- ==========================================
-- 3. MOTOR DE GIRO
-- ==========================================
function MakeCombo()
	-- Sorteia entre os 3 ícones disponíveis
	local s1 = Icons[math.random(#Icons)]
	local s2 = Icons[math.random(#Icons)]
	local s3 = Icons[math.random(#Icons)]

	-- Regra de Variedade: Evita dar o mesmo prêmio duas vezes seguidas se cair jackpot
	if s1.ID == s2.ID and s2.ID == s3.ID and s1.ID == ultimoPremio then
		-- Tenta embaralhar o terceiro slot para quebrar a sequência
		repeat s3 = Icons[math.random(#Icons)] until s3.ID ~= s1.ID
	end

	C.Slot1, C.Slot2, C.Slot3 = s1, s2, s3
end

function CheckWinner()
	-- Verifica se os três slots são idênticos
	if C.Slot1.ID == C.Slot2.ID and C.Slot2.ID == C.Slot3.ID then
		ultimoPremio = C.Slot1.ID
		return C.Slot1.ID
	end
	return nil
end

function RunMachine(Player)
	if OnCooldown then return end

	-- Verificação de saldo
	if GetAvailablePoints(Player) < SPIN_COST then
		print("❌ SALDO INSUFICIENTE!")
		return
	end

	-- Cobrança automática (Sincronizada com sua UI)
	AdicionarGasto(Player, SPIN_COST)

	OnCooldown = true
	SpinProx.Enabled = false
	Model.Main.Start:Play()

	-- ANIMAÇÃO DE GIRO (MÁGICO, BOMBA, RELÓGIO)
	for i = 1, 15 do
		task.wait(0.08)
		Image1.Texture = im..Icons[math.random(#Icons)].ImgID
		Image2.Texture = im..Icons[math.random(#Icons)].ImgID
		Image3.Texture = im..Icons[math.random(#Icons)].ImgID
		Image1.Transparency, Image2.Transparency, Image3.Transparency = 0.4, 0.4, 0.4
	end

	MakeCombo()

	-- REVELAÇÃO DOS RESULTADOS
	Model.Main.Click:Play()
	Image1.Texture = im..C.Slot1.ImgID; Image1.Transparency = 0; task.wait(0.4)
	Model.Main.Click:Play()
	Image2.Texture = im..C.Slot2.ImgID; Image2.Transparency = 0; task.wait(0.4)
	Model.Main.Click:Play()
	Image3.Texture = im..C.Slot3.ImgID; Image3.Transparency = 0

	-- VERIFICA VITÓRIA
	local WonID = CheckWinner()
	if WonID then
		Model.Main.Winner:Play()

		-- Efeito na peça Explosion conforme sua estrutura
		if Model:FindFirstChild("Explosion") then
			Model.Explosion.Color = CoresVantagens[WonID] or Color3.new(1,1,1)
			Model.Explosion.Transparency = 0
			task.delay(1.5, function() Model.Explosion.Transparency = 1 end)
		end

		EntregarPremio(Player, WonID)
	else
		Model.Main.Bass:Play() -- Som de "perdeu" (não saíram 3 iguais)
	end

	task.wait(CooldownTime)
	SpinProx.Enabled = true
	OnCooldown = false
end

-- ==========================================
-- 4. INICIALIZAÇÃO
-- ==========================================
SpinProx.Triggered:Connect(function(Player)
	RunMachine(Player)
end)

SpinProx.ActionText = "Girar (Custo: ".. SPIN_COST .." Ponto)"