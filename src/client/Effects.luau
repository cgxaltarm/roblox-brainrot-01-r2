-- Effects: small feedback moments. The money label flashes green on
-- a purchase, the banner turns red on a steal alert, and event
-- banners pop in the centre of the screen.

local TweenService = game:GetService("TweenService")

local Effects = {}

function Effects.PlayPurchase(hud)
	if hud.MoneyLabel == nil then
		return
	end
	local goal = { TextColor3 = Color3.new(0.4, 1, 0.4) }
	local tween = TweenService:Create(hud.MoneyLabel, TweenInfo.new(0.3), goal)
	tween:Play()
	tween.Completed:Connect(function()
		local back = { TextColor3 = Color3.new(1, 0.85, 0.2) }
		TweenService:Create(hud.MoneyLabel, TweenInfo.new(0.6), back):Play()
	end)
end

function Effects.PlayStealAlert(hud)
	if hud.BannerLabel == nil then
		return
	end
	hud.BannerLabel.Text = "YOUR BASE IS BEING ROBBED!"
	hud.BannerLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
end

function Effects.PlayEventBanner(hud, text, color)
	if hud.BannerLabel == nil then
		return
	end
	hud.BannerLabel.Text = text
	hud.BannerLabel.TextColor3 = color
end

return Effects
