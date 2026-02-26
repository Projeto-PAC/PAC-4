local players = game.Players
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. CONFIGURAÇÕES (Mudamos para a 7ª Série)
local SERIE_ALVO = 7
local MAX_PLAYERS = 50
local portal = script.Parent
local som = portal:WaitForChild("SomTeleporte", 5)

-- 2. LOCALIZAÇÃO EXATA
local modoPasta = workspace:WaitForChild("ModosDeJogo", 10)
local arenaFolder = modoPasta and modoPasta:WaitForChild("Arena7Ano", 10) -- Pasta do 7º Ano

local spawnDestino = arenaFolder and arenaFolder:WaitForChild("SpawnArena", 5)
local centroArena = arenaFolder and arenaFolder:WaitForChild("CentroDaArena", 5)
local statusValue = ReplicatedStorage:WaitForChild("StatusArena7", 5) -- StringValue da 7ª Série

-- 3. FUNÇÃO DE CONTAGEM
local function contarPlayers()
	local count = 0
	if not centroArena then return 0 end
	for _, p in pairs(players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (p.Character.HumanoidRootPart.Position - centroArena.Position).Magnitude
			if dist < 120 then count += 1 end
		end
	end
	return count
end

-- 4. ATUALIZAÇÃO DO STATUS NO PAINEL
task.spawn(function()
	while true do
		local total = contarPlayers()
		if statusValue and statusValue:IsA("StringValue") then
			statusValue.Value = SERIE_ALVO .. "º Ano: " .. total .. "/" .. MAX_PLAYERS
		end
		task.wait(2)
	end
end)

-- 5. LÓGICA DE TELETRANSPORTE
portal.Touched:Connect(function(hit)
	local char = hit.Parent
	local p = players:GetPlayerFromCharacter(char)

	if p and char:FindFirstChild("HumanoidRootPart") and portal.CanTouch then
		if contarPlayers() < MAX_PLAYERS then
			portal.CanTouch = false

			pcall(function() if som then som:Play() end end)

			if spawnDestino then
				char.HumanoidRootPart.CFrame = spawnDestino.CFrame + Vector3.new(0, 3, 0)
			end

			task.wait(1)
			portal.CanTouch = true
		end
	end
end)
