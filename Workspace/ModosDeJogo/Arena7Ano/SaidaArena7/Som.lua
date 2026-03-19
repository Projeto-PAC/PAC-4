-- Script SonsAleatorios 
local partLava = script.Parent
local listaDeSons = {
	"Morri"
}

local tocandoSom = false

partLava.Touched:Connect(function(hit)
	-- ✅ MELHORIA: Procuramos o Humanoid primeiro, que é mais rápido que buscar o Player
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character.Parent:FindFirstChildOfClass("Humanoid")

	if humanoid and not tocandoSom then
		tocandoSom = true

		-- 🎲 SORTEIO
		local indiceSorteado = math.random(1, #listaDeSons)
		local nomeSorteado = listaDeSons[indiceSorteado]
		local somParaTocar = partLava:FindFirstChild(nomeSorteado)
		task.wait(1)

		if somParaTocar then
			-- ✅ FORÇA O SOM A SER GLOBAL: Assim o player ouve mesmo se for teleportado longe
			somParaTocar.RollOffMaxDistance = 250 
			somParaTocar:Play()
			warn("🎲 SORTEIO: " .. nomeSorteado .. " acionado!")
		end

		task.wait(1.5) -- Debounce curto para o próximo player
		tocandoSom = false
	end
end)