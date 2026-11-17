-- Game.client: entrypoint. Builds the HUD and the shop, listens for
-- state snapshots from the server, and wires the Slap key. The client
-- only renders: all money, ownership and steal outcomes live on the
-- server, and every button here fires a RemoteEvent the server checks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Hud = require(script.Parent.Hud)
local Shop = require(script.Parent.Shop)
local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
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

ContextActionService:BindAction("SlapThief", slapAction, false, Enum.KeyCode.E)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		remotes.UseSlap:FireServer()
	end
end)

print("Brainrot Night Market client ready.")
