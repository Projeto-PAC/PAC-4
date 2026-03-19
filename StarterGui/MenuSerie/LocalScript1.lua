local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Referência da imagem
local painel = script.Parent
local labell = painel:WaitForChild("PontoAtual")
local fotoBoneco = labell:WaitForChild("ImageLabel")

-- Dados
local leaderstats = player:WaitForChild("leaderstats")
local acertos = player:WaitForChild("AcertosPorSerie")

local s6 = acertos:WaitForChild("Serie6")
local s7 = acertos:WaitForChild("Serie7")
local s8 = acertos:WaitForChild("Serie8")
local s9 = acertos:WaitForChild("Serie9")

local camp = leaderstats:WaitForChild("Camp")

-------------------------------------------------
-- TÍTULOS MATEMÁTICOS
-------------------------------------------------

local Titulos = {

	{nome = "📚 Aprendiz", pontos = 0},
	{nome = "🧮 Calculador", pontos = 150},
	{nome = "♟ Estrategista", pontos = 400},
	{nome = "🧠 Gênio", pontos = 800},
	{nome = "👑 Mestre da Matemática", pontos = 1500}

}

local function pegarTitulo(pontos)

	local tituloAtual = Titulos[1].nome

	for i = 1,#Titulos do
		if pontos >= Titulos[i].pontos then
			tituloAtual = Titulos[i].nome
		end
	end

	return tituloAtual

end

-------------------------------------------------
-- FOTO DO PLAYER
-------------------------------------------------

local function carregarFoto()

	local userId = player.UserId
	if userId <= 0 then userId = 1 end

	local content, isReady = Players:GetUserThumbnailAsync(
		userId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size420x420
	)

	fotoBoneco.Image = content

end

-------------------------------------------------
-- ATUALIZAÇÃO DA UI
-------------------------------------------------

local function atualizarUI()

	local valorCamp = camp.Value

	local somaTotal =
		s6.Value +
		s7.Value +
		s8.Value +
		s9.Value +
		valorCamp

	local titulo = pegarTitulo(somaTotal)

	labell.Text =
		titulo.." | "..player.DisplayName.." | "..somaTotal.." Pts"

end

-------------------------------------------------
-- EXECUÇÃO
-------------------------------------------------

carregarFoto()

-- Atualiza quando valores mudarem
s6.Changed:Connect(atualizarUI)
s7.Changed:Connect(atualizarUI)
s8.Changed:Connect(atualizarUI)
s9.Changed:Connect(atualizarUI)
camp.Changed:Connect(atualizarUI)

-- Atualiza no início
atualizarUI()