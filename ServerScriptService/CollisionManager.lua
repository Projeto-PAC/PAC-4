local PhysicsService = game:GetService("PhysicsService")
local players = game.Players

-- Cria o grupo de colisão
local groupName = "Jogadores"
pcall(function()
	PhysicsService:RegisterCollisionGroup(groupName)
end)

-- Define que o grupo "Jogadores" NÃO colide com ele mesmo
PhysicsService:CollisionGroupSetCollidable(groupName, groupName, false)

local function configurarColisao(char)
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = groupName
		end
	end
end

players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(configurarColisao)
end)
