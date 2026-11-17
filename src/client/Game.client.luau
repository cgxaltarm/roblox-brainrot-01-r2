-- Game.client: entrypoint. Builds the HUD and the shop, listens for
-- state snapshots from the server, and wires the Slap key. The client
-- only renders: all money, ownership and steal outcomes live on the
-- server, and every button here fires a RemoteEvent the server checks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local PlayerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")

local Hud = require(PlayerScripts.Client.Hud)
local Shop = require(PlayerScripts.Client.Shop)
local Effects = require(PlayerScripts.Client.Effects)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
for _, name in ipairs({"StateSync", "BuyBrainrot", "SellBrainrot", "LockBase", "DoRebirth", "CollectCash", "BuyGear", "BuyUpgrade", "UseSlap", "StealAttempt", "OpenGearShop", "Toast"}) do
	remotes:WaitForChild(name)
end

-- Hold-to-buy: every conveyor brainrot carries a ProximityPrompt with
-- its slot number as an attribute. When the hold completes, fire the
-- same BuyBrainrot remote the shop cards used to fire. Prompts are
-- rebuilt whenever a slot is taken, so hook new ones as they appear.
local function hookBuyPrompt(prompt)
	prompt.Triggered:Connect(function()
		local slotIndex = prompt:GetAttribute("SlotIndex")
		if slotIndex ~= nil then
			remotes.BuyBrainrot:FireServer(slotIndex)
		end
	end)
end
for _, descendant in ipairs(Workspace:GetDescendants()) do
	if descendant:IsA("ProximityPrompt") then
		hookBuyPrompt(descendant)
	end
end
Workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("ProximityPrompt") then
		hookBuyPrompt(descendant)
	end
end)
local lastEvent = "None"
local lastCarrying = false

Hud.Build(remotes, {
	ToggleGear = function()
		Shop.ToggleGear()
	end,
	ToggleRebirth = function()
		Shop.ToggleRebirth()
	end,
	ToggleIndex = function()
		Shop.ToggleIndex()
	end,
	ToggleBuff = function()
		Shop.ToggleBuff()
	end,
})
Shop.Build(remotes)

remotes.StateSync.OnClientEvent:Connect(function(snapshot)
	Hud.Render(snapshot)
	Shop.Render(snapshot)
	if snapshot.Event ~= lastEvent then
		if snapshot.Event == "RushHour" then
			Effects.PlayEventBanner(Hud, "RUSH HOUR! Thief on the loose - guard your base!", Color3.new(1, 0.3, 0.3))
		elseif snapshot.Event == "Festival" then
			Effects.PlayEventBanner(Hud, "FESTIVAL! 2x income!", Color3.new(1, 0.85, 0.2))
		elseif snapshot.Event == "GoldenHour" then
			Effects.PlayEventBanner(Hud, "GOLDEN HOUR! Every spawn is Golden!", Color3.new(1, 0.85, 0.2))
		end
		lastEvent = snapshot.Event
	end
	if snapshot.Carrying ~= nil and not lastCarrying then
		Effects.PlayPurchase(Hud)
	end
	lastCarrying = snapshot.Carrying ~= nil
end)

remotes.Toast.OnClientEvent:Connect(function(text)
	Hud.ShowToast(text)
end)

remotes.OpenGearShop.OnClientEvent:Connect(function()
	Shop.ToggleGear()
end)

local function slapAction(_, state, _)
	if state == Enum.UserInputState.Begin then
		remotes.UseSlap:FireServer()
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("SlapThief", slapAction, false, Enum.KeyCode.Q)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q then
		remotes.UseSlap:FireServer()
	end
end)

print("Brainrot Night Market client ready.")
