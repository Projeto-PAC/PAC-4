local players = game:GetService("Players")

-- Nomes exatos dos seus Spawns na Arena
local destinosNomes = {"Start", "Start1", "Start2"}

script.Parent.Touched:Connect(function(hit)
	local char = hit.Parent
	local p = players:GetPlayerFromCharacter(char)

	if p and char:FindFirstChild("HumanoidRootPart") then
		-- Criamos uma lista com os objetos encontrados no Workspace
		local destinosEncontrados = {}

		for _, nome in pairs(destinosNomes) do
			local spw = workspace:FindFirstChild(nome, true) -- Busca profunda no mapa
			if spw then
				table.insert(destinosEncontrados, spw)
			end
		end

		-- Se encontrou algum dos destinos, escolhe um aleatoriamente
		if #destinosEncontrados > 0 then
			local escolhido = destinosEncontrados[math.random(1, #destinosEncontrados)]

			-- Teleporta o jogador 3 studs acima do spawn para não bugar no chão
			char.HumanoidRootPart.CFrame = escolhido.CFrame + Vector3.new(0, 3, 0)
		else
			warn("⚠️ ERRO: Nenhum dos destinos (Start, Start1, Start2) foi encontrado!")
		end
	end
end)