local partLava = script.Parent
local quebrando = false -- A TRAVA

partLava.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChild("Humanoid")

	if humanoid and humanoid.Health > 0 and not quebrando then
		quebrando = true

		print("💥 FISICA: Boneco " .. character.Name .. " despedaçado pela lava.")
		character:BreakJoints()
		humanoid.Health = 0

		task.wait(2)
		quebrando = false
	end
end)