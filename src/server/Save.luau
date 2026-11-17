-- Save: persist cash, rebirth level, placed brainrots and the owned
-- index in a DataStore, with an autosave every two minutes and a save
-- when the player leaves. A failed save never blocks the game.

local DataStoreService = game:GetService("DataStoreService")
local Economy = require(script.Parent.Economy)
local Config = require(script.Parent.Parent.Shared.Config)

local Save = {}
local store = nil

local function getStore()
	if store ~= nil then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	end
	return store
end

function Save.LoadPlayer(player)
	local state = Economy.NewPlayer(player)
	local ds = getStore()
	if ds == nil then
		return state
	end
	local ok, data = pcall(function()
		return ds:GetAsync("player_" .. tostring(player.UserId))
	end)
	if not ok or type(data) ~= "table" then
		return state
	end
	if type(data.Cash) == "number" then
		state.Cash = data.Cash
	end
	if type(data.Rebirth) == "number" then
		state.Rebirth = data.Rebirth
	end
	if type(data.Placed) == "table" then
		state.Placed = data.Placed
	end
	if type(data.Owned) == "table" then
		state.Owned = data.Owned
	end
	return state
end

function Save.SavePlayer(player)
	local state = Economy.Get(player)
	if state == nil then
		return false
	end
	local ds = getStore()
	if ds == nil then
		return false
	end
	local data = {
		Cash = state.Cash,
		Rebirth = state.Rebirth,
		Placed = state.Placed,
		Owned = state.Owned,
	}
	local ok, _ = pcall(function()
		ds:SetAsync("player_" .. tostring(player.UserId), data)
	end)
	return ok
end

function Save.SaveAll()
	for _, player in ipairs(game.Players:GetPlayers()) do
		Save.SavePlayer(player)
	end
end

return Save
