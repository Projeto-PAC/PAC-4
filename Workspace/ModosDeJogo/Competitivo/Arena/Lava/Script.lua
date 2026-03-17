-- Script Servidor dentro da Part Looby
local lobbySpawn = workspace:WaitForChild("Lobby"):WaitForChild("SpawnLocation")

script.Parent.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = game.Players:GetPlayerFromCharacter(character)

	-- Verifica se é um jogador válido e se tem o HumanoidRootPart
	if player and character:FindFirstChild("HumanoidRootPart") then
		local stats = player:FindFirstChild("PlayerStats")

		-- 1. DESATIVA O ESTADO DE JOGO NO SERVIDOR
		-- Isso é vital para que o GameManager pare de contar esse jogador como "Ativo"
		if stats then
			stats.JogoIniciado.Value = false
			stats.Serie.Value = 0
		end

		-- 2. LIMPA O VÍNCULO COM A ARQUIBANCADA
		-- Redefine o local de nascimento para o Lobby principal
		player.RespawnLocation = lobbySpawn

		-- 3. REMOVE AURA DE LÍDER (Se houver)
		-- Evita que o jogador leve o efeito visual de campeão para fora da arena
		local hrp = character.HumanoidRootPart
		local aura = hrp:FindFirstChild("AuraLider")
		if aura then aura:Destroy() end
		wait(2)

		-- 4. TELEPORTE FÍSICO PARA O LOBBY
		-- A folga de 5 no eixo Y evita que o jogador nasça dentro da peça de spawn
		hrp.CFrame = lobbySpawn.CFrame + Vector3.new(0, 5, 0)

		-- 5. FEEDBACK NO LOG
		warn("LOG: " .. player.Name .. " resetou o spawn e retornou ao Lobby com sucesso.")
	end
end)