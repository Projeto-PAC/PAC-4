local partLava = script.Parent
local listaDeSons = {
	"Não", "Chaves", "Falling", "Socorro", 
	"DepoisdeMorrer", "faustão_errou", "Morrer", "Faustão_Fogo"
}

local tocando = false -- A TRAVA

partLava.Touched:Connect(function(hit)
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)

	if player and not tocando then
		tocando = true

		local indice = math.random(1, #listaDeSons)
		local som = partLava:FindFirstChild(listaDeSons[indice])

		if som then
			som:Play()
			warn("🎲 SORTEIO: O som escolhido foi: " .. listaDeSons[indice])
		end

		task.wait(2) -- Espera 2 segundos para poder tocar outro som
		tocando = false
	end
end)