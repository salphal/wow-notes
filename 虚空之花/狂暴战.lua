--[[
  狂暴战打地鼠 APL - 泰坦重铸时光服
  作者：Sevenuncle
]]

if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_FURY_WARRIOR_SELFVF then return end APL_FURY_WARRIOR_SELFVF = true

local function getHPPercent(unit)
	unit = unit or "target"
	if not UnitExists(unit) then return 0 end
	local m = UnitHealthMax(unit)
	if m == 0 then return 0 end
	return (UnitHealth(unit) / m) * 100
end

local dwUsed = false

local S = {
	HeroicStrike = --[[select(7, GetSpellInfo("英勇打击")) or ]]47450,
	Bloodthirst = --[[select(7, GetSpellInfo("嗜血")) or ]]23881,
	Whirlwind = --[[select(7, GetSpellInfo("旋风斩")) or ]]1680,
	Slam = --[[select(7, GetSpellInfo("猛击")) or ]]47475,
	Execute = --[[select(7, GetSpellInfo("斩杀")) or ]]47471,
	Bloodrage = --[[select(7, GetSpellInfo("血性狂暴")) or ]]2687,
	BerserkerRage = --[[select(7, GetSpellInfo("狂暴之怒")) or ]]18499,
	Recklessness = --[[select(7, GetSpellInfo("鲁莽")) or ]]1719,
	Cleave = --[[select(7, GetSpellInfo("顺劈斩")) or ]]47520,
	Intercept = --[[select(7, GetSpellInfo("拦截")) or ]]20252,
	HeroicThrow = --[[select(7, GetSpellInfo("英勇投掷")) or ]]57755,
	ShatteringThrow = --[[select(7, GetSpellInfo("碎裂投掷")) or ]]64382,
	DeathWish = --[[select(7, GetSpellInfo("死亡之愿")) or ]]12292,
	Bloodsurge = 46916,
	BURST_MACRO_ID = 9999998,
}
-- 捆绑英勇打击的宏（高怒用）
local S_HS = {
	Bloodthirst = -100000-S.Bloodthirst,
	Whirlwind = -100000-S.Whirlwind,
	Slam = -100000-S.Slam,
	Execute = -100000-S.Execute,
}
-- 捆绑顺劈斩的宏（高怒AOE用）
local S_CL = {
	Bloodthirst = -200000-S.Bloodthirst,
	Whirlwind = -200000-S.Whirlwind,
	Slam = -200000-S.Slam,
	Execute = -200000-S.Execute,
}

local BurstMacroBody = "/cast 死亡之愿\\n/cast 狮心(种族特长)\\n/cast 狂暴(种族特长)\\n/cast 血性狂怒(种族特长)\\n/cast 石像形态(种族特长)\\n/use 10\\n/use 13\\n/use 14\\n/use 通用热力工程炸药\\n/use [@player] 萨隆邪铁炸弹"

local ActionList = {
	-- 捆绑英勇打击的宏（高怒单体）
	{ S_HS.Bloodthirst, "macro", "/cast 嗜血\\n/cast !英勇打击", GetSpellTexture("嗜血") },
	{ S_HS.Whirlwind, "macro", "/cast 旋风斩\\n/cast !英勇打击", GetSpellTexture("旋风斩") },
	{ S_HS.Slam, "macro", "/cast !英勇打击\\n/cast 猛击", GetSpellTexture("猛击") },
	{ S_HS.Execute, "macro", "/cast !英勇打击\\n/cast 斩杀", GetSpellTexture("斩杀") },
	-- 捆绑顺劈斩的宏（高怒AOE）
	{ S_CL.Bloodthirst, "macro", "/cast 嗜血\\n/cast !顺劈斩", GetSpellTexture("嗜血") },
	{ S_CL.Whirlwind, "macro", "/cast 旋风斩\\n/cast !顺劈斩", GetSpellTexture("旋风斩") },
	{ S_CL.Slam, "macro", "/cast !顺劈斩\\n/cast 猛击", GetSpellTexture("猛击") },
	{ S_CL.Execute, "macro", "/cast !顺劈斩\\n/cast 斩杀", GetSpellTexture("斩杀") },
	-- 原技能
	{ S.Bloodthirst, "macro", "/cast 嗜血\\n/stopcasting", GetSpellTexture("嗜血") },
	{ S.Whirlwind, "macro", "/cast 旋风斩\\n/stopcasting", GetSpellTexture("旋风斩") },
	{ S.Slam, "macro", "/cast 猛击\\n/stopcasting", GetSpellTexture("猛击") },
	{ S.Execute, "macro", "/cast 斩杀\\n/stopcasting", GetSpellTexture("斩杀") },
	{ S.BURST_MACRO_ID, "macro", BurstMacroBody, GetSpellTexture("死亡之愿") },
	{ S.Bloodrage, "spell", "血性狂暴" },
	{ S.HeroicStrike, "spell", "英勇打击" },
	{ S.Cleave, "spell", "顺劈斩" },
	{ S.BerserkerRage, "spell", "狂暴之怒" },
	{ S.Recklessness, "spell", "鲁莽" },
	{ S.Intercept, "macro", "/cast [stance:1/2] !狂暴姿态\\n/cast 拦截", GetSpellTexture("拦截") },
	{ S.HeroicThrow, "spell", "英勇投掷" },
	{ S.ShatteringThrow, "spell", "碎裂投掷" },
	{ S.DeathWish, "spell", "死亡之愿" },
	{ 6603, "macro", "/startattack" },
	{ -6603, "macro", "/stopcasting\\n/startattack", GetSpellTexture(6603) },
	{ -112, "macro", "/use 10\\n/use 通用热力工程炸药\\n/use [@player] 萨隆邪铁炸弹", 133035 },
	{ 2458, "spell", "狂暴姿态" }
}

-- 平砍计时器
local SwingTimer = {
	baseSpeed = 0,
	lastSwing = 0,
	pauseTotal = 0,
	isPaused = false
}

local function getSwingRemain()
	SwingTimer.baseSpeed = UnitAttackSpeed("player") or SwingTimer.baseSpeed
	local remain = SwingTimer.baseSpeed - (GetTime() - SwingTimer.lastSwing - SwingTimer.pauseTotal)
	return math.max(0, remain)
end


local Manager = CreateFrame("Frame", "FuryWarriorSwingManager", UIParent)
Manager:SetScript("OnUpdate", function(_, elapsed)
	if SwingTimer.isPaused then
		SwingTimer.pauseTotal = SwingTimer.pauseTotal + elapsed
	end
end)
Manager:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
Manager:RegisterEvent("UNIT_SPELLCAST_START")
Manager:RegisterEvent("UNIT_SPELLCAST_STOP")
Manager:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
Manager:RegisterEvent("PLAYER_REGEN_ENABLED")
Manager:SetScript("OnEvent", function(_, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, subEvent, _, srcGUID, _, _, _, _, _, _, _, spellID, _, _, _, _, _, _, _, _, _, _, _, isOffHand = CombatLogGetCurrentEventInfo()
		if srcGUID ~= UnitGUID("player") then return end
		if subEvent == "SWING_DAMAGE" or subEvent == "SWING_MISSED" then
			if isOffHand then
			-- TODO: 预留未来副手平砍结束怒气不足时取消英勇/顺劈
			else
				SwingTimer.lastSwing = GetTime()
				SwingTimer.pauseTotal = 0
				SwingTimer.isPaused = false
			end
		end
	elseif event == "UNIT_SPELLCAST_START" then
		if ... == "player" then
			SwingTimer.isPaused = true
		end
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" then
		if ... == "player" then
			SwingTimer.isPaused = false
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		SwingTimer.lastSwing = GetTime()
		SwingTimer.pauseTotal = 0
		SwingTimer.isPaused = false
	end
end)

local function hasFear()
	local count = C_LossOfControl.GetActiveLossOfControlDataCountByUnit("player")
	for i = 1, count do
		local data = C_LossOfControl.GetActiveLossOfControlDataByUnit("player", i)
		if data and data.locType and data.locType == "FEAR" then
			return true
		end
	end
	return false
end

-- 8码内敌人数量
local function getNearbyCount()
	local count = 0
	local counted = {}
	for i = 1, 40 do
		local u = "nameplate" .. i
		if UnitExists(u) and UnitCanAttack("player", u) and not UnitIsDead(u) then
			if WeakAuras.CheckRange(u, 8, "<=") then
				local guid = UnitGUID(u)
				if guid and not counted[guid] then
					counted[guid] = true
					count = count + 1
				end
			end
		end
	end
	return count
end

local function APLCallback_FuryWarrior()
-- 脱战重置
	if not UnitAffectingCombat("player") then
		dwUsed = false
		return 6603
	end

	if not UnitExists("target") or UnitIsDeadOrGhost("target") then
		return 6603
	end

	local win = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
	local gcdRemain = VF_getSpellCD(61304) or 0

	local function cd(id)
		return math.max(0, (VF_getSpellCD(id) or 999) - gcdRemain)
	end

	local rage = UnitPower("player", 1) or 0
	local hp = getHPPercent("target")

	-- AOE模式切换
	local intoCleaveMode = (getNearbyCount() >= 2)

	local hasBS = (math.max(0, VF_getBuff("player", S.Bloodsurge, "HELPFUL|PLAYER") - gcdRemain) > 0)
	local isBoss = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
	local inMeleeRange = (IsSpellInRange("嗜血", "target") == 1)

	local bt = cd(S.Bloodthirst)
	local ww = cd(S.Whirlwind)
	local rk = cd(S.Recklessness)
	local ic = cd(S.Intercept)
	local ht = cd(S.HeroicThrow)
	local br = cd(S.Bloodrage)
	local bz = cd(S.BerserkerRage)
	local dw = cd(S.DeathWish)
	local st = cd(S.ShatteringThrow)

	if not dwUsed and dw > 0 then
		dwUsed = true
	end

	-- 狂暴姿态
	if GetShapeshiftForm() ~= 3 then
		return 2458
	end

	-- 血性狂暴
	if rage < 75 and br <= win then
		return S.Bloodrage
	end

	-- 狂暴之怒
	if bz <= win and hasFear() then
		return S.BerserkerRage
	end

	-- 拦截
	if ic <= win and rage >= 10 and not inMeleeRange and (IsSpellInRange("拦截", "target") == 1) then
		return S.Intercept
	end

	-- 英勇投掷
	if isBoss and ht <= win and not inMeleeRange then
		return S.HeroicThrow
	end

	-- 爆发宏
	if isBoss and dw <= win and not dwUsed
	and ((VF_getBuff("player", 2825, "HELPFUL") > 0) or (VF_getBuff("player", 32182, "HELPFUL") > 0)) then
		return S.BURST_MACRO_ID
	end

	-- 碎裂投掷卡CD
	if isBoss and st <= win and (math.max(0, VF_getDebuff("target", S.ShatteringThrow, "HARMFUL") - gcdRemain) <= 0) and rage >= 25 then
		return S.ShatteringThrow
	end

	-- 鲁莽
	if isBoss and dwUsed then
		if rk <= win then
			return S.Recklessness
		end
		if VF_getItemCD(10) <= win and inMeleeRange then
			return -112
		end
	end

	-- 技能自动选择
	local function autoSelectSpell(id)
		if rage >= 45 then
			if intoCleaveMode then
				return -200000 - id
			else
				return -100000 - id
			end
		end
		return id
	end

	-- 嗜血
	if bt <= win then
		return autoSelectSpell(S.Bloodthirst)
	end

	-- 旋风斩
	if ww <= win and bt > win then
		return autoSelectSpell(S.Whirlwind)
	end

	-- 血涌猛击
	if hasBS and bt > win and ww > win then
		return autoSelectSpell(S.Slam)
	end

	-- 斩杀
	if hp < 20 and not hasBS and bt >= 1.5 and ww >= 1.5 and rage >= 60 then
		return autoSelectSpell(S.Execute)
	end

	local SwingRemain = getSwingRemain()
	-- 低怒气下在平砍发生前取消附加技
	if rage < 30 and SwingRemain < 0.3 then
		if IsCurrentSpell(S.HeroicStrike) or IsCurrentSpell(S.Cleave) then
			return -6603
		else
			return 6603
		end
	end

	-- 英勇打击（单体）：怒气 >= 12
	if rage >= 12 and not intoCleaveMode and SwingRemain >= 0.3 then
		if not IsCurrentSpell(S.HeroicStrike) then
			return S.HeroicStrike
		end
	end

	-- 顺劈斩（AOE）：怒气 >= 20
	if rage >= 20 and intoCleaveMode and SwingRemain >= 0.3 then
		if not IsCurrentSpell(S.Cleave) then
			return S.Cleave
		end
	end

	return 6603
end

aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_FuryWarrior
aura_env.APLName = "七叔狂暴战"

