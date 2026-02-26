local Players = game:GetService("Players")

-- Nome do spawn do Lobby
local NOME_LOBBY = "SpawnLocation" 

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)

		-- VERIFICAÇÃO: Se o player já nasceu uma vez, o script NÃO faz nada
		-- Isso permite que, ao morrer na lava, ele nasça na arquibancada normalmente
		if not player:GetAttribute("PrimeiroNascimentoConcluido") then

			local hrp = character:WaitForChild("HumanoidRootPart", 5)
			local spawnLobby = workspace:FindFirstChild(NOME_LOBBY, true)

			if hrp and spawnLobby then
				task.wait(0.1) -- Delay para carregar
				hrp.CFrame = spawnLobby.CFrame + Vector3.new(0, 5, 0)

				-- MARCA COMO CONCLUÍDO: Agora ele pode morrer e ir para outros spawns
				player:SetAttribute("PrimeiroNascimentoConcluido", true)
				print("Player forçado ao Lobby no início da sessão.")
			end
		else
			print("Player morreu/renasceu. Deixando o sistema de spawn do Roblox agir.")
		end
	end)
end)
