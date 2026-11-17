-- Economy: the single server store for player money, placed brainrots,
-- rebirths, locks and the collect pile. Every other server module reads
-- and writes through these functions; the client never touches money.

local BrainrotData = require(script.Parent.Parent.Shared.BrainrotData)
local Config = require(script.Parent.Parent.Shared.Config)

local Economy = {}
Economy.Players = {}

function Economy.NewPlayer(player)
	Economy.Players[player.UserId] = {
		Player = player,
		Cash = Config.StartCash,
		Pending = 0,
		Rebirth = 0,
		Placed = {},
		Owned = {},
		Carrying = nil,
		BaseIndex = 0,
		LockUntil = 0,
		LockCooldownUntil = 0,
		StealCooldownUntil = 0,
		JoinTime = os.time(),
		Gear = { Slap = false, CoilUntil = 0, Traps = 0 },
		TutorialStep = 0,
	}
	return Economy.Players[player.UserId]
end

function Economy.Get(player)
	return Economy.Players[player.UserId]
end

function Economy.RemovePlayer(player)
	Economy.Players[player.UserId] = nil
end

function Economy.AddCash(player, amount)
	local state = Economy.Get(player)
	if state == nil then
		return
	end
	state.Cash = state.Cash + amount
end

function Economy.GetCash(player)
	local state = Economy.Get(player)
	if state == nil then
		return 0
	end
	return state.Cash
end

function Economy.GetIncomePerSec(player, eventMult)
	local state = Economy.Get(player)
	if state == nil then
		return 0
	end
	local total = 0
	for _, placed in pairs(state.Placed) do
		local def = BrainrotData.FindCharacter(placed.CharId)
		if def ~= nil then
			total = total + BrainrotData.IncomeFor(def, placed.Mutation, state.Rebirth, eventMult)
		end
	end
	return total
end

function Economy.TickIncome(eventMult)
	for _, state in pairs(Economy.Players) do
		local income = Economy.GetIncomePerSec(state.Player, eventMult)
		if income > 0 then
			state.Pending = state.Pending + income
		end
	end
end

function Economy.CollectCash(player)
	local state = Economy.Get(player)
	if state == nil then
		return 0
	end
	local amount = math.floor(state.Pending)
	state.Pending = state.Pending - amount
	state.Cash = state.Cash + amount
	return amount
end

function Economy.SlotCount(player)
	local state = Economy.Get(player)
	if state == nil then
		return Config.BaseSlots
	end
	return math.min(Config.MaxSlots, Config.BaseSlots + state.Rebirth * Config.RebirthSlotsBonus)
end

function Economy.FreeSlot(player)
	local state = Economy.Get(player)
	if state == nil then
		return 0
	end
	for slot = 1, Economy.SlotCount(player) do
		if state.Placed[slot] == nil then
			return slot
		end
	end
	return 0
end

function Economy.HasCharacter(player, charId)
	local state = Economy.Get(player)
	if state == nil then
		return false
	end
	for _, placed in pairs(state.Placed) do
		if placed.CharId == charId then
			return true
		end
	end
	return false
end

function Economy.BuyBrainrot(player, slotDef)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	if state.Carrying ~= nil then
		return false, "already carrying"
	end
	if state.Cash < slotDef.Cost then
		return false, "not enough cash"
	end
	state.Cash = state.Cash - slotDef.Cost
	state.Carrying = {
		CharId = slotDef.CharId,
		Mutation = slotDef.Mutation,
		FromConveyor = true,
		OwnerId = 0,
		OwnerSlot = 0,
	}
	state.Owned[slotDef.CharId] = true
	return true, "bought"
end

function Economy.PlaceCarried(player, slot)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	if state.Carrying == nil then
		return false, "not carrying"
	end
	if slot < 1 or slot > Economy.SlotCount(player) then
		return false, "bad slot"
	end
	if state.Placed[slot] ~= nil then
		return false, "slot taken"
	end
	local carried = state.Carrying
	state.Placed[slot] = { CharId = carried.CharId, Mutation = carried.Mutation }
	state.Carrying = nil
	if state.TutorialStep < 2 then
		state.TutorialStep = 2
	end
	return true, "placed"
end

function Economy.SellBrainrot(player, slot)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	local placed = state.Placed[slot]
	if placed == nil then
		return false, "empty slot"
	end
	local def = BrainrotData.FindCharacter(placed.CharId)
	if def == nil then
		return false, "unknown character"
	end
	local refund = math.floor(def.Cost * Config.SellRefund)
	state.Cash = state.Cash + refund
	state.Placed[slot] = nil
	return true, "sold"
end

function Economy.RebirthRequirement(level)
	for _, req in ipairs(BrainrotData.REBIRTHS) do
		if req.Level == level then
			return req
		end
	end
	return nil
end

function Economy.CanRebirth(player)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	local nextLevel = state.Rebirth + 1
	local req = Economy.RebirthRequirement(nextLevel)
	if req == nil then
		return false, "max rebirth reached"
	end
	if state.Cash < req.Cost then
		return false, "need cash"
	end
	for _, charId in ipairs(req.Need) do
		if not Economy.HasCharacter(player, charId) then
			return false, "need named character"
		end
	end
	return true, "ready"
end

function Economy.DoRebirth(player)
	local ok, why = Economy.CanRebirth(player)
	if not ok then
		return false, why
	end
	local state = Economy.Get(player)
	local nextLevel = state.Rebirth + 1
	local req = Economy.RebirthRequirement(nextLevel)
	state.Cash = state.Cash - req.Cost
	state.Placed = {}
	state.Pending = 0
	state.Carrying = nil
	state.Rebirth = nextLevel
	return true, "rebirthed"
end

function Economy.IsLocked(player)
	local state = Economy.Get(player)
	if state == nil then
		return false
	end
	return os.time() < state.LockUntil
end

function Economy.LockTimeLeft(player)
	local state = Economy.Get(player)
	if state == nil then
		return 0
	end
	return math.max(0, state.LockUntil - os.time())
end

function Economy.LockBase(player)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	if os.time() < state.LockCooldownUntil then
		return false, "lock cooling down"
	end
	if state.Cash < Config.LockCost then
		return false, "not enough cash"
	end
	state.Cash = state.Cash - Config.LockCost
	local duration = Config.LockDuration + state.Rebirth * Config.LockBonusPerRebirth
	state.LockUntil = os.time() + duration
	state.LockCooldownUntil = state.LockUntil + Config.LockCooldown
	if state.TutorialStep < 3 then
		state.TutorialStep = 3
	end
	return true, "locked"
end

function Economy.MarkBought(player)
	local state = Economy.Get(player)
	if state ~= nil and state.TutorialStep < 1 then
		state.TutorialStep = 1
	end
end

return Economy
