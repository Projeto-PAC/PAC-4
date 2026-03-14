local player = game.Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local acertos = player:WaitForChild("AcertosPorSerie")

-- 1. Referências para os valores (Data)
local s6 = acertos:WaitForChild("Serie6")
local s7 = acertos:WaitForChild("Serie7")
local s8 = acertos:WaitForChild("Serie8")
local s9 = acertos:WaitForChild("Serie9")
local camp = leaderstats:WaitForChild("Camp") -- O valor do Campeonato

-- 2. Referência para a Label na sua tela
local label = script.Parent:WaitForChild("SerieAtual")

--  FUNÇÃO DE ATUALIZAÇÃO INSTANTÂNEA
local function atualizarUI()
	-- Ele soma tudo na hora, sem depender do valor "Total" do servidor
	local somaTotal = s6.Value + s7.Value + s8.Value + s9.Value + camp.Value

	print("Atualizando UI Local: " .. somaTotal)
	label.Text = "Parabéns: " .. somaTotal .. " Pontos"
end

--  ESCUTADORES (Gatilhos)
-- Se QUALQUER uma das séries ou o campeonato mudar, ele atualiza o texto na hora
s6.Changed:Connect(atualizarUI)
s7.Changed:Connect(atualizarUI)
s8.Changed:Connect(atualizarUI)
s9.Changed:Connect(atualizarUI)
camp.Changed:Connect(atualizarUI)

-- Primeira execução ao entrar ou abrir o menu
atualizarUI()