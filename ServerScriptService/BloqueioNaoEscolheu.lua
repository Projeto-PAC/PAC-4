local Players = game:GetService("Players")

while true do
	task.wait(5)

	for _, player in pairs(Players:GetPlayers()) do

		local stats = player:FindFirstChild("PlayerStats")
		if not stats then continue end

		local serie = stats:FindFirstChild("Serie")
		local iniciado = stats:FindFirstChild("JogoIniciado")

		-- Só verifica depois que o jogo iniciou
		if iniciado and iniciado.Value == true then

			-- segurança: se por erro não tem série
			if serie and serie.Value == 0 then
				local character = player.Character
				if character and character:FindFirstChild("Humanoid") then
					character.Humanoid.Health = 0
				end
			end

		end
	end
end
