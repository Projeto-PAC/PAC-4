local player = game.Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local totalValue = leaderstats:WaitForChild("Total")

-- Referência para a label 'SerieAtual' 
local label = script.Parent:WaitForChild("SerieAtual")

local function atualizarTexto()
	label.Text = "Parabéns: " .. totalValue.Value .. " Pontos"
end

-- Toda vez que o Total mudar no servidor, a sua tela muda na hora
totalValue.Changed:Connect(atualizarTexto)

-- Faz a primeira atualização ao entrar
atualizarTexto()