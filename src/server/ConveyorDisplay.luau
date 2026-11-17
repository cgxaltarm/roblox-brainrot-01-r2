-- ConveyorDisplay: the five brainrot models standing on the red
-- carpet, spaced wide apart so their three-line labels never overlap.
-- Clicking a model buys it; the display rebuilds whenever a slot is
-- taken or a new brainrot rolls in.

local Conveyor = require(script.Parent.Conveyor)
local CharacterModels = require(script.Parent.CharacterModels)
local BrainrotData = require(script.Parent.Parent.Shared.BrainrotData)
local Config = require(script.Parent.Parent.Shared.Config)
local Format = require(script.Parent.Parent.Shared.Format)

local ConveyorDisplay = {}
ConveyorDisplay.Models = {}
ConveyorDisplay.OnBuyRequest = nil

function ConveyorDisplay.SlotPosition(index)
	local x = (index - 3) * Config.ConveyorSpacing
	return Vector3.new(x, 1, Config.ConveyorZ)
end

function ConveyorDisplay.Refresh()
	for _, model in pairs(ConveyorDisplay.Models) do
		model:Destroy()
	end
	ConveyorDisplay.Models = {}
	local slots = Conveyor.GetSlots()
	for i, slot in ipairs(slots) do
		local def = BrainrotData.FindCharacter(slot.CharId)
		if def ~= nil then
			local model = CharacterModels.BuildModel(def, slot.Mutation, ConveyorDisplay.SlotPosition(i))
			CharacterModels.SetLabelPrice(model, Format.Money(slot.Cost))
			for _, part in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end
			model.Parent = workspace
			local click = Instance.new("ClickDetector")
			click.Name = "BuyClick"
			click.MaxActivationDistance = 32
			click.Parent = model.PrimaryPart
			local slotIndex = i
			click.MouseClick:Connect(function(player)
				if ConveyorDisplay.OnBuyRequest ~= nil then
					ConveyorDisplay.OnBuyRequest(player, slotIndex)
				end
			end)
			ConveyorDisplay.Models[i] = model
		end
	end
end

return ConveyorDisplay
