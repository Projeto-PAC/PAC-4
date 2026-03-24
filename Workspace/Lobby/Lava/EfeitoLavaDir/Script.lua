-- Script no ServerScriptService
local RunService = game:GetService("RunService")
local pastaLava = workspace:WaitForChild("Lobby"):WaitForChild("Lava")

-- Esta função checa se o jogador está na lava a cada frame do servidor
RunService.Heartbeat:Connect(function()
	local players = game.Players:GetPlayers()

	for _, player in ipairs(players) do
		local character = player.Character
		if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then

			-- Pegamos as partes do corpo que costumam tocar o chão
			local partesCorpo = {
				character:FindFirstChild("LeftFoot"), 
				character:FindFirstChild("RightFoot"), 
				character:FindFirstChild("HumanoidRootPart")
			}

			for _, parteCorpo in ipairs(partesCorpo) do
				if parteCorpo then
					-- O comando abaixo checa o que está encostando nessa parte do corpo agora
					local partesTocando = parteCorpo:GetTouchingParts()

					for _, objeto in ipairs(partesTocando) do
						-- Se o que o player está tocando for um "filho" da pasta Lava
						if objeto:IsDescendantOf(pastaLava) then
							character.Humanoid.Health = 0 -- MORTE INSTANTÂNEA
							break -- Para de checar este player se ele já morreu
						end
					end
				end
			end
		end
	end
end)