-- Steal: one player grabs a brainrot from another player's unlocked
-- base, carries it home slowly, and drops it when anyone tags them or
-- slaps them. During Rush Hour a thief NPC raids a random unlocked base.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Economy = require(ServerScriptService.Server.Economy)
local Base = require(ServerScriptService.Server.Base)
local CharacterModels = require(ServerScriptService.Server.CharacterModels)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Config = require(ReplicatedStorage.Shared.Config)

local Steal = {}
Steal.CarriedModels = {}
Steal.Thief = nil
Steal.OnSteal = nil

function Steal.AttachCarried(player, charId, mutation)
	Steal.DropCarried(player, false)
	local def = BrainrotData.FindCharacter(charId)
	if def == nil then
		return
	end
	local character = player.Character
	if character == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	local model = CharacterModels.BuildModel(def, mutation, root.Position + Vector3.new(0, 4, 0))
	model.Parent = workspace
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= model.PrimaryPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = model.PrimaryPart
			weld.Part1 = part
			weld.Parent = model.PrimaryPart
		end
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = model.PrimaryPart
	weld.Parent = model.PrimaryPart
	Steal.CarriedModels[player.UserId] = model
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		humanoid.WalkSpeed = 16 * Config.CarrySpeedMult
	end
end

function Steal.DropCarried(player, returnHome)
	local model = Steal.CarriedModels[player.UserId]
	if model ~= nil then
		model:Destroy()
		Steal.CarriedModels[player.UserId] = nil
	end
	local character = player.Character
	if character ~= nil then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil then
			humanoid.WalkSpeed = 16
		end
	end
	local state = Economy.Get(player)
	if state ~= nil and state.Carrying ~= nil then
		if returnHome and state.Carrying.OwnerId > 0 then
			local owner = game.Players:GetPlayerByUserId(state.Carrying.OwnerId)
			if owner ~= nil then
				local ownerState = Economy.Get(owner)
				if ownerState ~= nil then
					ownerState.Placed[state.Carrying.OwnerSlot] = {
						CharId = state.Carrying.CharId,
						Mutation = state.Carrying.Mutation,
					}
					Base.PlaceModel(owner, state.Carrying.OwnerSlot)
				end
			end
		end
		state.Carrying = nil
	end
end

function Steal.TrySteal(player, targetUserId, slot)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	if state.Carrying ~= nil then
		return false, "already carrying"
	end
	if os.time() < state.StealCooldownUntil then
		return false, "steal cooling down"
	end
	if os.time() - state.JoinTime < Config.NewPlayerGrace then
		return false, "new player grace"
	end
	local target = game.Players:GetPlayerByUserId(targetUserId)
	if target == nil or target == player then
		return false, "bad target"
	end
	if Economy.IsLocked(target) then
		return false, "base locked"
	end
	local targetState = Economy.Get(target)
	if targetState == nil then
		return false, "no target state"
	end
	local placed = targetState.Placed[slot]
	if placed == nil then
		return false, "empty slot"
	end
	targetState.Placed[slot] = nil
	Base.RemoveModel(target, slot)
	state.Carrying = {
		CharId = placed.CharId,
		Mutation = placed.Mutation,
		FromConveyor = false,
		OwnerId = targetUserId,
		OwnerSlot = slot,
	}
	state.StealCooldownUntil = os.time() + Config.StealCooldown
	Steal.AttachCarried(player, placed.CharId, placed.Mutation)
	if Steal.OnSteal ~= nil then
		Steal.OnSteal(player, target)
	end
	return true, "stolen"
end

function Steal.TagCarrier(tagger, carrier)
	local state = Economy.Get(carrier)
	if state == nil or state.Carrying == nil then
		return
	end
	if state.Carrying.FromConveyor then
		return
	end
	Steal.DropCarried(carrier, true)
end

function Steal.CheckTags()
	for _, carrier in ipairs(game.Players:GetPlayers()) do
		local state = Economy.Get(carrier)
		if state ~= nil and state.Carrying ~= nil and not state.Carrying.FromConveyor then
			local char = carrier.Character
			if char ~= nil then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root ~= nil then
					for _, other in ipairs(game.Players:GetPlayers()) do
						if other ~= carrier then
							local otherChar = other.Character
							if otherChar ~= nil then
								local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
								if otherRoot ~= nil and (otherRoot.Position - root.Position).Magnitude < 4 then
									Steal.TagCarrier(other, carrier)
									break
								end
							end
						end
					end
				end
			end
		end
	end
end

function Steal.SpawnThief()
	local players = game.Players:GetPlayers()
	local victims = {}
	for _, p in ipairs(players) do
		if not Economy.IsLocked(p) then
			local state = Economy.Get(p)
			if state ~= nil then
				for _, _ in pairs(state.Placed) do
					table.insert(victims, p)
					break
				end
			end
		end
	end
	if #victims == 0 then
		return
	end
	local victim = victims[math.random(1, #victims)]
	local state = Economy.Get(victim)
	local bestSlot = 0
	local bestIncome = -1
	for slot, placed in pairs(state.Placed) do
		local def = BrainrotData.FindCharacter(placed.CharId)
		if def ~= nil and def.Income > bestIncome then
			bestIncome = def.Income
			bestSlot = slot
		end
	end
	if bestSlot == 0 then
		return
	end
	local placed = state.Placed[bestSlot]
	state.Placed[bestSlot] = nil
	Base.RemoveModel(victim, bestSlot)
	local npc = Instance.new("Model")
	npc.Name = "Pencuri Keliling"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(3, 3, 3)
	body.Color = Color3.new(0.15, 0.15, 0.15)
	body.Position = Vector3.new(0, 4, -44)
	body.Anchored = false
	body.Parent = npc
	npc.PrimaryPart = body
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = npc
	npc.Parent = workspace
	Steal.Thief = { Model = npc, CharId = placed.CharId, Mutation = placed.Mutation, Victim = victim, Slot = bestSlot }
	task.spawn(function()
		task.wait(1)
		humanoid:MoveTo(Vector3.new(0, 3, 44))
		task.wait(20)
		if Steal.Thief ~= nil and Steal.Thief.Model == npc then
			npc:Destroy()
			Steal.Thief = nil
		end
	end)
end

function Steal.ClearThief()
	if Steal.Thief ~= nil then
		Steal.Thief.Model:Destroy()
		Steal.Thief = nil
	end
end

return Steal
