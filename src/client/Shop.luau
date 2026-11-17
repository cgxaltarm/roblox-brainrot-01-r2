-- Shop: the conveyor cards, the gear shop, the rebirth panel with its
-- named-character requirements and checkmarks, and the collection
-- Index. Cards are dark with bold white text, a rarity-coloured
-- border and a gold price, so they read when shrunk. Cards are
-- display-only: buying happens by holding E on the brainrot model
-- itself (ProximityPrompt), like the real Steal a Brainrot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Format = require(ReplicatedStorage.Shared.Format)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)

local Shop = {}
Shop.Remotes = nil
Shop.ConveyorFrame = nil
Shop.GearPanel = nil
Shop.RebirthPanel = nil
Shop.IndexPanel = nil
Shop.BuffPanel = nil
Shop.OpenPanel = ""

local DARK = Color3.new(0.06, 0.09, 0.16)
local GOLD = Color3.new(1, 0.85, 0.2)

local function makePanel(name, size, pos)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.Position = pos
	panel.BackgroundColor3 = DARK
	panel.BorderColor3 = Color3.new(1, 1, 1)
	panel.BorderSizePixel = 2
	panel.Visible = false
	panel.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("NightMarketHud")
	return panel
end

local function makeTitle(parent, text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 34)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = parent
	return label
end

function Shop.Build(remotes)
	Shop.Remotes = remotes
	local gui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("NightMarketHud")
	local frame = Instance.new("Frame")
	frame.Name = "ConveyorFrame"
	frame.Size = UDim2.new(0, 760, 0, 120)
	frame.Position = UDim2.new(0.5, -380, 1, -140)
	frame.BackgroundTransparency = 1
	frame.Parent = gui
	Shop.ConveyorFrame = frame
	Shop.GearPanel = makePanel("GearPanel", UDim2.new(0, 420, 0, 260), UDim2.new(0.5, -210, 0.5, -130))
	Shop.RebirthPanel = makePanel("RebirthPanel", UDim2.new(0, 460, 0, 300), UDim2.new(0.5, -230, 0.5, -150))
	Shop.IndexPanel = makePanel("IndexPanel", UDim2.new(0, 560, 0, 380), UDim2.new(0.5, -280, 0.5, -190))
	Shop.BuffPanel = makePanel("BuffPanel", UDim2.new(0, 460, 0, 270), UDim2.new(0.5, -230, 0.5, -135))
end

function Shop.Toggle(panelName)
	if Shop.OpenPanel == panelName then
		Shop.OpenPanel = ""
	else
		Shop.OpenPanel = panelName
	end
	Shop.GearPanel.Visible = Shop.OpenPanel == "gear"
	Shop.RebirthPanel.Visible = Shop.OpenPanel == "rebirth"
	Shop.IndexPanel.Visible = Shop.OpenPanel == "index"
	Shop.BuffPanel.Visible = Shop.OpenPanel == "buff"
end

function Shop.ToggleGear()
	Shop.Toggle("gear")
end

function Shop.ToggleRebirth()
	Shop.Toggle("rebirth")
end

function Shop.ToggleIndex()
	Shop.Toggle("index")
end

function Shop.ToggleBuff()
	Shop.Toggle("buff")
end

function Shop.Render(snapshot)
	Shop.RenderConveyor(snapshot)
	if Shop.OpenPanel == "gear" then
		Shop.RenderGear(snapshot)
	elseif Shop.OpenPanel == "rebirth" then
		Shop.RenderRebirth(snapshot)
	elseif Shop.OpenPanel == "index" then
		Shop.RenderIndex(snapshot)
	elseif Shop.OpenPanel == "buff" then
		Shop.RenderBuff(snapshot)
	end
end

function Shop.RenderConveyor(snapshot)
	if Shop.ConveyorFrame == nil then
		return
	end
	for _, child in ipairs(Shop.ConveyorFrame:GetChildren()) do
		child:Destroy()
	end
	for i, slot in ipairs(snapshot.Conveyor) do
		local def = BrainrotData.FindCharacter(slot.CharId)
		if def ~= nil then
			local rarityColor = BrainrotData.RarityColor(def.Rarity)
			local card = Instance.new("Frame")
			card.Name = "Card" .. tostring(i)
			card.Size = UDim2.new(0, 144, 0, 112)
			card.Position = UDim2.new(0, (i - 1) * 152, 0, 0)
			card.BackgroundColor3 = DARK
			card.BorderColor3 = Color3.new(rarityColor[1], rarityColor[2], rarityColor[3])
			card.BorderSizePixel = 3
			card.Parent = Shop.ConveyorFrame
			local mark = BrainrotData.MutationMark(slot.Mutation)
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -8, 0, 30)
			nameLabel.Position = UDim2.new(0, 4, 0, 4)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = def.Name .. " " .. mark
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
			nameLabel.TextScaled = true
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.Parent = card
			local rarityLabel = Instance.new("TextLabel")
			rarityLabel.Size = UDim2.new(1, -8, 0, 26)
			rarityLabel.Position = UDim2.new(0, 4, 0, 36)
			rarityLabel.BackgroundTransparency = 1
			rarityLabel.Text = def.Rarity .. "  " .. Format.Money(def.Income) .. "/s"
			rarityLabel.TextColor3 = Color3.new(rarityColor[1], rarityColor[2], rarityColor[3])
			rarityLabel.TextScaled = true
			rarityLabel.Font = Enum.Font.GothamBold
			rarityLabel.Parent = card
			local priceLabel = Instance.new("TextLabel")
			priceLabel.Size = UDim2.new(1, -8, 0, 30)
			priceLabel.Position = UDim2.new(0, 4, 0, 66)
			priceLabel.BackgroundTransparency = 1
			priceLabel.Text = Format.Money(slot.Cost)
			priceLabel.TextColor3 = GOLD
			priceLabel.TextScaled = true
			priceLabel.Font = Enum.Font.GothamBold
			priceLabel.Parent = card
			if snapshot.Cash < slot.Cost then
				card.BackgroundTransparency = 0.4
			end
		end
	end
end

function Shop.RenderGear(snapshot)
	for _, child in ipairs(Shop.GearPanel:GetChildren()) do
		child:Destroy()
	end
	makeTitle(Shop.GearPanel, "COINS SHOP - GEAR")
	for i, gear in ipairs(BrainrotData.GEAR) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -16, 0, 56)
		button.Position = UDim2.new(0, 8, 0, 40 + (i - 1) * 64)
		button.BackgroundColor3 = DARK
		button.BorderColor3 = GOLD
		button.BorderSizePixel = 2
		button.Text = gear.Name .. "  " .. Format.Money(gear.Cost) .. " - " .. gear.Desc
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.Parent = Shop.GearPanel
		local gearId = gear.Id
		button.MouseButton1Click:Connect(function()
			Shop.Remotes.BuyGear:FireServer(gearId)
		end)
	end
end

function Shop.RenderBuff(snapshot)
	for _, child in ipairs(Shop.BuffPanel:GetChildren()) do
		child:Destroy()
	end
	makeTitle(Shop.BuffPanel, "BUFF SHOP - UPGRADE PERMANEN")
	local upgrades = snapshot.Upgrades or { Luck = 0, Income = 0, Speed = 0 }
	for i, def in ipairs(BrainrotData.UPGRADES) do
		local level = upgrades[def.Id] or 0
		local maxed = level >= BrainrotData.UPGRADE_MAX
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -16, 0, 64)
		row.Position = UDim2.new(0, 8, 0, 40 + (i - 1) * 72)
		row.BackgroundColor3 = DARK
		row.BorderColor3 = GOLD
		row.BorderSizePixel = 2
		row.Parent = Shop.BuffPanel
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -140, 0, 30)
		nameLabel.Position = UDim2.new(0, 8, 0, 4)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = def.Name .. "  Lv " .. tostring(level) .. "/5"
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row
		local effectLabel = Instance.new("TextLabel")
		effectLabel.Size = UDim2.new(1, -140, 0, 26)
		effectLabel.Position = UDim2.new(0, 8, 0, 34)
		effectLabel.BackgroundTransparency = 1
		if maxed then
			effectLabel.Text = "MAX - " .. def.Desc .. " / level"
		else
			effectLabel.Text = "Berikutnya: " .. def.Desc .. " - " .. Format.Money(def.Prices[level + 1])
		end
		effectLabel.TextColor3 = GOLD
		effectLabel.TextScaled = true
		effectLabel.Font = Enum.Font.GothamBold
		effectLabel.TextXAlignment = Enum.TextXAlignment.Left
		effectLabel.Parent = row
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 118, 0, 48)
		button.Position = UDim2.new(1, -126, 0, 8)
		button.BackgroundColor3 = Color3.new(0.64, 0.90, 0.21)
		button.TextColor3 = Color3.new(0.06, 0.09, 0.16)
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.Parent = row
		if maxed then
			button.Text = "MAX"
			button.BackgroundTransparency = 0.5
		else
			button.Text = "UPGRADE " .. Format.Money(def.Prices[level + 1])
			if snapshot.Cash < def.Prices[level + 1] then
				row.BackgroundTransparency = 0.4
				button.BackgroundTransparency = 0.5
			end
			local upgradeId = def.Id
			button.MouseButton1Click:Connect(function()
				Shop.Remotes.BuyUpgrade:FireServer(upgradeId)
			end)
		end
	end
end

function Shop.RenderRebirth(snapshot)
	for _, child in ipairs(Shop.RebirthPanel:GetChildren()) do
		child:Destroy()
	end
	local nextLevel = snapshot.Rebirth + 1
	makeTitle(Shop.RebirthPanel, "REBIRTH Lv" .. tostring(nextLevel) .. " - " .. Format.Money(snapshot.RebirthCost))
	local owned = {}
	for _, charId in ipairs(snapshot.Owned) do
		owned[charId] = true
	end
	local placed = {}
	for _, item in ipairs(snapshot.Placed) do
		placed[item.CharId] = true
	end
	for i, charId in ipairs(snapshot.RebirthNeed) do
		local def = BrainrotData.FindCharacter(charId)
		local hasIt = owned[charId] or placed[charId]
		local mark = "✗"
		local color = Color3.new(1, 0.3, 0.3)
		if hasIt then
			mark = "✓"
			color = Color3.new(0.4, 1, 0.4)
		end
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -16, 0, 34)
		label.Position = UDim2.new(0, 8, 0, 40 + (i - 1) * 38)
		label.BackgroundTransparency = 1
		label.Text = mark .. "  " .. (def ~= nil and def.Name or charId)
		label.TextColor3 = color
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = Shop.RebirthPanel
	end
	local cashLabel = Instance.new("TextLabel")
	cashLabel.Size = UDim2.new(1, -16, 0, 34)
	cashLabel.Position = UDim2.new(0, 8, 0, 130)
	cashLabel.BackgroundTransparency = 1
	cashLabel.Text = "Cash: " .. Format.Money(snapshot.Cash) .. " / " .. Format.Money(snapshot.RebirthCost)
	cashLabel.TextColor3 = GOLD
	cashLabel.TextScaled = true
	cashLabel.Font = Enum.Font.GothamBold
	cashLabel.Parent = Shop.RebirthPanel
	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size = UDim2.new(1, -16, 0, 34)
	rewardLabel.Position = UDim2.new(0, 8, 0, 168)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Text = "Reward: +50% income, +1 base slot, +10s lock"
	rewardLabel.TextColor3 = Color3.new(1, 1, 1)
	rewardLabel.TextScaled = true
	rewardLabel.Font = Enum.Font.GothamBold
	rewardLabel.Parent = Shop.RebirthPanel
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -16, 0, 48)
	button.Position = UDim2.new(0, 8, 0, 212)
	button.BackgroundColor3 = Color3.new(0.64, 0.90, 0.21)
	button.Text = "REBIRTH NOW"
	button.TextColor3 = Color3.new(0.06, 0.09, 0.16)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Parent = Shop.RebirthPanel
	if not snapshot.CanRebirth then
		button.BackgroundTransparency = 0.5
	end
	button.MouseButton1Click:Connect(function()
		Shop.Remotes.DoRebirth:FireServer()
	end)
end

function Shop.RenderIndex(snapshot)
	for _, child in ipairs(Shop.IndexPanel:GetChildren()) do
		child:Destroy()
	end
	local owned = {}
	for _, charId in ipairs(snapshot.Owned) do
		owned[charId] = true
	end
	local count = 0
	for _, _ in pairs(owned) do
		count = count + 1
	end
	makeTitle(Shop.IndexPanel, "INDEX - " .. tostring(count) .. "/" .. tostring(#BrainrotData.CHARACTERS) .. " (" .. tostring(math.floor(count / #BrainrotData.CHARACTERS * 100)) .. "%)")
	for i, def in ipairs(BrainrotData.CHARACTERS) do
		local col = (i - 1) % 4
		local row = math.floor((i - 1) / 4)
		local hasIt = owned[def.Id]
		local rarityColor = BrainrotData.RarityColor(def.Rarity)
		local cell = Instance.new("TextLabel")
		cell.Size = UDim2.new(0, 128, 0, 56)
		cell.Position = UDim2.new(0, 8 + col * 136, 0, 44 + row * 62)
		cell.BackgroundColor3 = DARK
		cell.BorderColor3 = Color3.new(rarityColor[1], rarityColor[2], rarityColor[3])
		cell.BorderSizePixel = 2
		cell.Text = def.Name .. "\n" .. def.Rarity
		if not hasIt then
			cell.Text = "???\n" .. def.Rarity
			cell.TextColor3 = Color3.new(0.4, 0.4, 0.4)
		else
			cell.TextColor3 = Color3.new(1, 1, 1)
		end
		cell.TextScaled = true
		cell.Font = Enum.Font.GothamBold
		cell.Parent = Shop.IndexPanel
	end
end

return Shop
