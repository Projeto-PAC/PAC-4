local players = game.Players
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ==========================================
-- 1. CONFIGURAÇÕES
-- ==========================================
local MAX_PLAYERS = 50
local portal = script.Parent
local som = portal:FindFirstChild("SomTeleporte")

-- LOCALIZAÇÃO (Dentro da pasta ModosDeJogo)
local modoPasta = workspace:WaitForChild("ModosDeJogo", 10)
local arenaFolder = modoPasta and modoPasta:WaitForChild("Arena7Ano", 10)

-- ✅ AQUI ESTÁ O NOME QUE VOCÊ QUERIA:
local spawnDestino = arenaFolder and arenaFolder:WaitForChild("SpawnArena7", 5) 
local centroArena = arenaFolder and arenaFolder:WaitForChild("CentroDaArena", 5)
local statusValue = ReplicatedStorage:WaitForChild("StatusArena7", 5)

-- ==========================================
-- 2. FUNÇÃO DE CONTAGEM
-- ==========================================
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

-- ==========================================
-- 3. ATUALIZAÇÃO DO STATUS (MENU)
-- ==========================================
task.spawn(function()
	while true do
		local total = contarPlayers()
		if statusValue and statusValue:IsA("StringValue") then
			statusValue.Value = "7º Ano: " .. total .. "/" .. MAX_PLAYERS
		end
		task.wait(2)
	end
end)

-- ==========================================
-- 4. LÓGICA DE TELEPORTE
-- ==========================================
portal.Touched:Connect(function(hit)
	local char = hit.Parent
	local p = players:GetPlayerFromCharacter(char)

	if p and char:FindFirstChild("HumanoidRootPart") and portal.CanTouch then
		if contarPlayers() < MAX_PLAYERS then
			portal.CanTouch = false

			pcall(function() if som then som:Play() end end)

			-- Teleporte para a SpawnArena7
			if spawnDestino then
				char.HumanoidRootPart.CFrame = spawnDestino.CFrame + Vector3.new(0, 3, 0)
			else
				warn("⚠️ ERRO: SpawnArena7 não encontrada na Arena7Ano!")
			end

			task.wait(1)
			portal.CanTouch = true
		end
	end
end)