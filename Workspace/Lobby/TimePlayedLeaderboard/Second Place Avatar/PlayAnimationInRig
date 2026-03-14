local Players = game:GetService("Players")
local Config = require(script.Parent.Parent.Settings)

local PlayAnimationInRig = {}
PlayAnimationInRig.currentId = -1
PlayAnimationInRig.animation = script.Parent:WaitForChild("AnimationToPlay")
PlayAnimationInRig.rig = script.Parent:WaitForChild("Rig")
PlayAnimationInRig.tag = script.Parent:WaitForChild("FirstPlaceTag")

local rigBackup = PlayAnimationInRig.rig:Clone()

function PlayAnimationInRig.SetRigHumanoidDescription(userId)
	if PlayAnimationInRig.currentId == userId or userId <= 0 then return end
	PlayAnimationInRig.currentId = userId

	-- Reseta o boneco para a forma original antes de vestir
	PlayAnimationInRig.rig:Destroy()
	local newRig = rigBackup:Clone()
	newRig.Parent = script.Parent
	PlayAnimationInRig.rig = newRig

	local humanoid = newRig:WaitForChild("Humanoid")

	task.spawn(function()
		-- Pega a roupa do jogador Top 1
		local success, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
		if success then humanoid:ApplyDescriptionReset(desc) end

		-- Nome flutuante
		local head = newRig:WaitForChild("Head")
		local tag = PlayAnimationInRig.tag:Clone()
		tag.Enabled = true
		tag.Parent = head
		humanoid.DisplayName = Players:GetNameFromUserIdAsync(userId)
	end)

	-- Inicia a animação de dança
	local animator = humanoid:WaitForChild("Animator")
	local track = animator:LoadAnimation(PlayAnimationInRig.animation)
	track.Looped = true
	track:Play()
end

return PlayAnimationInRig