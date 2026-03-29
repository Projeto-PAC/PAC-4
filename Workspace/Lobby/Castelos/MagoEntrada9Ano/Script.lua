-- Script de Animação Final (Sem Erro de Caminho)
-- Local: Workspace.Lobby.Astral Isle Apprentice.Script

local rig = script.Parent
local humanoid = rig:WaitForChild("Humanoid")

-- 1. BUSCA INTELIGENTE: Procura o AnimationToPlay no Modelo todo
-- Isso evita o erro de "Infinite Yield" se ele não estiver no Torso
local animationObject = rig:FindFirstChild("AnimationToPlay", true) 

-- 2. Garante que o motor de animação (Animator) esteja pronto
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

local function rodarAnimacao()
	-- Validação: Se não achou o objeto de jeito nenhum
	if not animationObject then
		warn("⚠️ ENGENHARIA: Objeto 'AnimationToPlay' NÃO encontrado no modelo " .. rig.Name)
		return
	end

	-- Validação: Se o ID está vazio
	if animationObject.AnimationId == "" or animationObject.AnimationId == "rbxassetid://0" then
		warn("⚠️ ENGENHARIA: O ID da animação está VAZIO no objeto " .. animationObject.Name)
		return
	end

	-- 3. Carrega e roda
	local success, track = pcall(function()
		return animator:LoadAnimation(animationObject)
	end)

	if success and track then
		track.Looped = true 
		track.Priority = Enum.AnimationPriority.Action
		track:Play()
		print("✅ Show iniciado no Lobby: " .. rig.Name)
	else
		warn("❌ Falha crítica ao carregar animação: " .. tostring(track))
	end
end

-- Espera 2 segundos para o mapa carregar totalmente
task.wait(2)
rodarAnimacao()