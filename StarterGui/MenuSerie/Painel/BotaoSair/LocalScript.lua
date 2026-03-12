local player = game.Players.LocalPlayer
local botao = script.Parent

-- Procura a pasta "Lobby" e depois o "SpawnLocation"
local success, spawnPrincipal = pcall(function()
	return workspace:WaitForChild("Lobby"):WaitForChild("SpawnLocation")
end)

botao.MouseButton1Click:Connect(function()
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then

		-- 1. Reseta o local de nascimento para o padrão
		player.RespawnLocation = nil

		-- 2. Teleporta o jogador
		if success and spawnPrincipal then
			character.HumanoidRootPart.CFrame = spawnPrincipal.CFrame + Vector3.new(0, 5, 0)
			print("Teleportado para o Lobby com sucesso!")
		else
			-- casa der erro 
			local backupSpawn = workspace:FindFirstChildOfClass("SpawnLocation")
			if backupSpawn then
				character.HumanoidRootPart.CFrame = backupSpawn.CFrame + Vector3.new(0, 5, 0)
			else
				warn("Erro crítico: Não encontrei a pasta 'Lobby' nem nenhum SpawnLocation!")
			end
		end
	end
end)