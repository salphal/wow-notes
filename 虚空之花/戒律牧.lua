--[[
  戒律牧 APL
  贡献人：竹井詩織里&紧张的斧王
  固定宏动作：预展开 player/party/raid 单位，避免战斗中动态生成宏。
]]
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_DisciplinePriest_WLK then return end APL_DisciplinePriest_WLK = true

local S = {
	PWS = 48066, -- 真言术：盾
	PENANCE = 53007, -- 苦修
	FLASH = 48071, -- 快速治疗
	POM = 48113 -- 愈合祷言
}

local SKey = {
	PWS = "PWS",
	PENANCE = "PENANCE",
	FLASH = "FLASH",
	POM = "POM"
}

local C = {
	penanceHealthPercent = 50, -- 对应旧版 LeftToPenance 低于此血量触发苦修(戒律)
	shieldHealthPercent = 85, -- 对应旧版 LeftToShield 低于此血量优先盾(戒律)
	pomHealthPercent = 50, -- 对应旧版 LeftToPrayer 低于此血量触发愈合祷言(戒律)
	flashHealHealthPercent = 50, -- 对应旧版 LeftToFlashHeal 低于此血量触发快速治疗(戒律)
	penanceHealthAdd = 12000, -- 苦修预计总治疗量（防止对同一目标重复施法）
	flashHealHealthAdd = 5000, -- 快速治疗预计治疗量（防止对同一目标重复施法）
	tankHealth = 40000, -- 坦克血量阈值
	healerSupport40Battleground = false, -- 支持40人战场
	supportSpecialDebuff = false -- 支持特殊Debuff
}

if aura_env.config then
	for k, v in pairs(aura_env.config) do
		C[k] = v
	end
end

local DebuffTable = {
	[66331] = true, -- 穿刺
	[66406] = true, -- 狗头人上身
	[66320] = true, -- 燃烧弹
	[66823] = true, -- 麻痹毒素
	[66869] = true, -- 灼热胆汁
	[66689] = true, -- 极寒吐息
	-- [66237] = true,  -- 血肉成灰
	[66334] = true, -- 女王之吻
	[66197] = true, -- 军团烈焰1
	[66199] = true, -- 军团烈焰2
	[66283] = true, -- 旋压痛击
	[66001] = true, -- 黑暗之触
	[65950] = true, -- 光明之触
	[66013] = true, -- 刺骨之寒
	[66012] = true, -- 寒冰打击
	[65775] = true, -- 酸腺撕咬

	[69065] = true, -- 白骨贯体
	[72385] = true, -- 沸腾之血
	[72293] = true, -- 阵亡勇士的印记
	-- [69279] = true,  -- 毒气孢子
	[69240] = true, -- 邪恶毒气
	[69290] = true, -- 枯萎的孢子
	[69674] = true, -- 畸变感染
	[69789] = true, -- 软泥洪流
	[69778] = true, -- 粘稠的软泥
	[71278] = true, -- 窒息毒气
	[72451] = true, -- 畸变瘟疫
	-- [71615] = true,  -- 催泪毒气
	-- [70672] = true,  -- 毒肿
	[70447] = true, -- 不稳定的软泥怪粘合剂
	[71807] = true, -- 闪耀火花
	[71265] = true, -- 蜂拥之影
	[71623] = true, -- 疯狂斩杀
	[71304] = true, -- 黑暗堕落者的契约
	[70744] = true, -- 酸性爆炸
	[70633] = true, -- 胆汁喷溅
	[72963] = true, -- 血肉腐烂
	[69766] = true, -- 动荡
	[70126] = true, -- 冰霜道标
	[70106] = true, -- 寒霜刺骨
	-- [72133] = true,  -- 饱受折磨
	[72546] = true, -- 收割灵魂
	[69409] = true, -- 灵魂收割
	[69242] = true, -- 灵魂尖啸
	[68980] = true, -- 收割灵魂
	[72754] = true -- 污染
}

local function spellName(id, fallback)
	local name = GetSpellInfo(id)
	return name or fallback
end

_G.ShioriPriestLastCastUnits = _G.ShioriPriestLastCastUnits or {
	LastCastPenanceUnitName = "",
	LastCastFlashUnitName = "",
	PenanceGUID = "",
	FlashGUID = "",
	PenanceStartTime = 0
}

local spellNames = {}
spellNames.PWS = spellName(S.PWS, "真言术：盾")
spellNames.PENANCE = spellName(S.PENANCE, "苦修")
spellNames.FLASH = spellName(S.FLASH, "快速治疗")
spellNames.POM = spellName(S.POM, "愈合祷言")

local units = {"player"}
for i = 1, 4 do
	table.insert(units, "party" .. i)
end
for i = 1, (C.healerSupport40Battleground and 40 or 25) do
	table.insert(units, "raid" .. i)
end

local initializedId = 8588000 -- 牧师专属基准ID

local actionIds = {}
local actionList = {}

local function addUnitMacro(key, spellId, macroSpellName, unit, iconId)
	actionIds[key] = actionIds[key] or {}
	local id = initializedId + (#actionList + 1)
	actionIds[key][unit] = id
	local macroText = "/cast [@" .. unit .. ",help,nodead] " .. macroSpellName
	table.insert(actionList, {id, "macro", macroText, iconId or GetSpellTexture(spellId)})
end

for _, unit in ipairs(units) do
	addUnitMacro(SKey.PWS, S.PWS, spellNames.PWS, unit)
	addUnitMacro(SKey.PENANCE, S.PENANCE, spellNames.PENANCE, unit)
	addUnitMacro(SKey.FLASH, S.FLASH, spellNames.FLASH, unit)
	addUnitMacro(SKey.POM, S.POM, spellNames.POM, unit)
end

actionIds.NOOP = initializedId + 200000
table.insert(actionList, {actionIds.NOOP, "macro", "/stopmacro", GetSpellTexture(47536)})
local function hasBuff(unit, spellId, fallbackName, isFromPlayer)
	local expectedName = GetSpellInfo(spellId) or fallbackName
	if not expectedName or expectedName == "" then
		return false
	end
	if isFromPlayer then
		return WA_GetUnitBuff(unit, expectedName, "PLAYER") ~= nil
	end
	return WA_GetUnitBuff(unit, expectedName) ~= nil
end

local function hasDebuff(unit, spellId, fallbackName, isFromPlayer)
	local expectedName = GetSpellInfo(spellId) or fallbackName
	if not expectedName or expectedName == "" then
		return false
	end
	if isFromPlayer then
		return WA_GetUnitDebuff(unit, expectedName, "PLAYER") ~= nil
	end
	return WA_GetUnitDebuff(unit, expectedName) ~= nil
end

local function spellReady(spellId)
	local start, duration, enabled = GetSpellCooldown(spellId)
	if enabled == 0 then
		return false
	end
	if start and start > 0 and duration and duration > 0 then
		if duration <= 1.5 then
			return true
		end -- 过滤公共CD
		return (start + duration - GetTime()) <= 0
	end
	return true
end

local function inRange(unit, spellId)
	if unit == "player" then
		if UnitIsDeadOrGhost(unit) then
			return false
		end
		return true
	end
	if not UnitExists(unit) or not UnitIsConnected(unit) or not UnitIsFriend("player", unit) or UnitIsDeadOrGhost(unit) then
		return false
	end
	local name = GetSpellInfo(spellId)
	if name then
		local range = IsSpellInRange(name, unit)
		if range ~= nil then
			return range == 1
		end
	end
	if UnitInRange then
		local ok = UnitInRange(unit)
		if ok ~= nil then
			return ok
		end
	end
	return true
end

local function isMoving()
	return GetUnitSpeed("player") > 0
end
local function getUnitRoleType(unit, maxUnit, unitMaxHp)
	local _, class = UnitClass(unit)
	local powerType = UnitPowerType(unit)
	if unit == maxUnit then
		return "TANK"
	end

	if WA_GetUnitBuff(unit, "真言术：韧") or WA_GetUnitBuff(unit, "坚韧祷言") or
	WA_GetUnitBuff(unit, "命令怒吼") then
		if unitMaxHp > C.tankHealth * 1.1 then
			return "TANK"
		end
	else
		if unitMaxHp > C.tankHealth then
			return "TANK"
		end
	end

	local Role = "RANGE"
	if class == "WARRIOR" or class == "ROGUE" or class == "DEATHKNIGHT" then
		Role = "MELEE"
	elseif class == "PALADIN" and UnitPowerMax(unit, 0) < 15000 then
		Role = "MELEE"
	elseif class == "SHAMAN" and WA_GetUnitBuff(unit, 49281) then
		Role = "MELEE"
	elseif class == "DRUID" and powerType == 3 then
		Role = "MELEE"
	end
	return Role
end

local function unitHasTOCDebuff(unit)
	if not C.supportSpecialDebuff then
		return false
	end
	for i = 1, 40 do
		local _, _, _, _, _, _, _, _, _, spellID = UnitDebuff(unit, i)
		if not spellID then
			break
		end
		if DebuffTable[spellID] then
			return true
		end
	end
	return false
end

-- 核心新增：计算考虑了治疗预读的真实血量缺口
local function calcUnitHealthDiff(unit, unitHealthMax)
	if not UnitExists(unit) then
		return 0
	end
	local unitHealthDiff = unitHealthMax - UnitHealth(unit)
	local unitName = UnitName(unit) or ""

	if _G.ShioriPriestLastCastUnits.LastCastPenanceUnitName ~= "" and
	(unit == _G.ShioriPriestLastCastUnits.LastCastPenanceUnitName or unitName ==
	_G.ShioriPriestLastCastUnits.LastCastPenanceUnitName) then
		unitHealthDiff = unitHealthDiff - C.penanceHealthAdd
	end

	if _G.ShioriPriestLastCastUnits.LastCastFlashUnitName ~= "" and
	(unit == _G.ShioriPriestLastCastUnits.LastCastFlashUnitName or unitName ==
	_G.ShioriPriestLastCastUnits.LastCastFlashUnitName) then
		unitHealthDiff = unitHealthDiff - C.flashHealHealthAdd
	end

	if unitHealthDiff <= 0 then
		return 0
	end
	return unitHealthDiff
end

local function action(key, unit)
	if unit then
		return actionIds[key] and actionIds[key][unit]
	end
	return actionIds[key]
end

local function runRaid(isParty)
	local maxRaidHealthPlayerUnit = ""
	local maxRaidHealthPlayerHealth = 0
	local unitToCast = ""
	local spellKey = ""

	local inRangeUnitList = {}
	local unitHealthPercentMap = {}
	local unitMaxHpMap = {}

	local raidMax = isParty and 5 or (C.healerSupport40Battleground and 40 or 25)
	local prefix = isParty and "party" or "raid"

	-- 1. 基础信息预遍历
	for i = 1, raidMax do
		local unit = (isParty and i == 1) and "player" or (isParty and prefix .. (i - 1) or prefix .. i)
		if UnitExists(unit) then
			local unitHealthMax = UnitHealthMax(unit)
			if maxRaidHealthPlayerHealth < unitHealthMax then
				maxRaidHealthPlayerHealth = unitHealthMax
				maxRaidHealthPlayerUnit = unit
			end

			-- 戒律牧的基础射程以快速治疗(40码)为准
			if inRange(unit, S.FLASH) then
				table.insert(inRangeUnitList, unit)
				unitMaxHpMap[unit] = unitHealthMax
				-- 获取预估治疗后的缺口
				local adjustedDiff = calcUnitHealthDiff(unit, unitHealthMax)
				-- 反推出预估的血量百分比 (用于适配旧代码的 % 阈值判断)
				local adjustedHpPercent = (unitHealthMax - adjustedDiff) / unitHealthMax * 100
				unitHealthPercentMap[unit] = adjustedHpPercent
			end
		end
	end

	-- 追踪状态机的核心数据变量
	local lowestHpPercent = 100
	local lowestHpUnit = ""
	local lowestHpNoShieldPercent = 100
	local lowestHpNoShieldUnit = ""
	local lowestHpNoPomPercent = 100
	local lowestHpNoPomUnit = ""

	local incinerateFleshUnit = ""
	local tocDebuffUnit = ""
	local firstUnshieldedMelee = ""
	local firstUnshieldedRange = ""
	local firstUnshieldedTank = ""
	local activeTankUnitForPom = ""

	local penanceReady = spellReady(S.PENANCE)
	local pomReady = spellReady(S.POM)
	local isCastingPenance = (_G.ShioriPriestLastCastUnits.PenanceGUID ~= nil and
	_G.ShioriPriestLastCastUnits.PenanceGUID ~= "")
	-- 【增加超时自解锁】
	if isCastingPenance then
	-- 如果这个 GUID 已经记录超过 5 秒了（苦修引导通常也就 2 秒左右），强制解锁
	-- 假设你记录了施法开始的时间戳，或者直接用 GetTime() 比较
		if (_G.ShioriPriestLastCastUnits.PenanceStartTime or 0) + 5 < GetTime() then
			_G.ShioriPriestLastCastUnits.PenanceGUID = ""
			_G.ShioriPriestLastCastUnits.LastCastPenanceUnitName = ""
			_G.ShioriPriestLastCastUnits.PenanceStartTime = 0
			isCastingPenance = false
		end
	end

	-- 2. 状态机提取 (单次O(N)遍历)
	for _, unit in ipairs(inRangeUnitList) do
		local hpPercent = unitHealthPercentMap[unit]
		local maxHp = unitMaxHpMap[unit]
		local role = getUnitRoleType(unit, maxRaidHealthPlayerUnit, maxHp)

		local hasWeakenedSoul = hasDebuff(unit, 6788, "虚弱灵魂")
		local hasPWS = hasBuff(unit, S.PWS, "真言术：盾")
		local shieldUsable = not hasWeakenedSoul and not hasPWS

		-- 提取最低血量
		if hpPercent < lowestHpPercent then
			lowestHpPercent = hpPercent
			lowestHpUnit = unit
		end
		if shieldUsable and hpPercent < lowestHpNoShieldPercent then
			lowestHpNoShieldPercent = hpPercent
			lowestHpNoShieldUnit = unit
		end

		-- 【修正点】完美还原老代码：目标不仅不能有愈合，也不能有盾(48066)
		if not hasBuff(unit, S.POM, "愈合祷言") and not hasPWS and hpPercent < lowestHpNoPomPercent then
			lowestHpNoPomPercent = hpPercent
			lowestHpNoPomUnit = unit
		end

		-- 提取角色未上盾列表
		if shieldUsable then
			if role == "MELEE" and firstUnshieldedMelee == "" then
				firstUnshieldedMelee = unit
			end
			if role == "RANGE" and firstUnshieldedRange == "" then
				firstUnshieldedRange = unit
			end
			if role == "TANK" and firstUnshieldedTank == "" then
				firstUnshieldedTank = unit
			end
		end

		-- 提取特殊机制目标
		if C.supportSpecialDebuff then
			if hasDebuff(unit, 66237, "血肉成灰") and incinerateFleshUnit == "" then
				incinerateFleshUnit = unit
			end
			if unitHasTOCDebuff(unit) and tocDebuffUnit == "" then
				tocDebuffUnit = unit
			end
		end

		-- 提取愈合祷言坦克特判 (老代码没有要求坦克没盾，只要求没愈合)
		if maxHp > C.tankHealth and UnitIsUnit(unit, unit .. "targettarget") and
		not hasBuff(unit, S.POM, "愈合祷言") and activeTankUnitForPom == "" then
			activeTankUnitForPom = unit
		end
	end

	-- 3. 执行优先树 (严格还原老代码 NowSpellLevel 数字从大到小)

	-- Level 50: 苦修 -> 血肉成灰
	if spellKey == "" and penanceReady and not isCastingPenance and incinerateFleshUnit ~= "" and not isMoving() then
		unitToCast = incinerateFleshUnit
		spellKey = SKey.PENANCE
	end

	-- Level 49: 苦修 -> 绝对最低血量且 < 50% 且满足苦修阈值
	if spellKey == "" and penanceReady and not isCastingPenance and lowestHpPercent < 50 and lowestHpPercent <
	C.penanceHealthPercent and not isMoving() then
		unitToCast = lowestHpUnit
		spellKey = SKey.PENANCE
	end

	-- Level 48: 快速治疗 -> 血肉成灰
	if spellKey == "" and incinerateFleshUnit ~= "" and not isMoving() then
		unitToCast = incinerateFleshUnit
		spellKey = SKey.FLASH
	end

	-- Level 40: 真言术：盾 -> TOC Debuff
	if spellKey == "" and tocDebuffUnit ~= "" then
		if not hasDebuff(tocDebuffUnit, 6788, "虚弱灵魂") and not hasBuff(tocDebuffUnit, S.PWS, "真言术：盾") then
			unitToCast = tocDebuffUnit
			spellKey = SKey.PWS
		end
	end

	-- Level 39: 愈合祷言 -> TOC Debuff (前提是全团安全 lowestHpPercent >= 50，且目标无盾无愈合)
	if spellKey == "" and pomReady and tocDebuffUnit ~= "" and lowestHpPercent >= 50 then
		if not hasBuff(tocDebuffUnit, S.POM, "愈合祷言") and not hasBuff(tocDebuffUnit, S.PWS, "真言术：盾") then
			unitToCast = tocDebuffUnit
			spellKey = SKey.POM
		end
	end

	-- Level 30: 真言术：盾 -> 绝对最低血量且血量 < 50% (危急保命盾)
	if spellKey == "" and lowestHpNoShieldUnit ~= "" and lowestHpNoShieldPercent < 50 and lowestHpNoShieldPercent <
	C.shieldHealthPercent then
		unitToCast = lowestHpNoShieldUnit
		spellKey = SKey.PWS
	end

	-- Level 29: 苦修 -> 兜底填补缺口 (被30级的盾压一头，但优先于28级的盾和愈合)
	if spellKey == "" and penanceReady and not isCastingPenance and lowestHpPercent < C.penanceHealthPercent and
	not isMoving() then
		unitToCast = lowestHpUnit
		spellKey = SKey.PENANCE
	end

	-- Level 28 (PoM): 愈合祷言 -> 兜底填补缺口
	if spellKey == "" and pomReady and lowestHpNoPomUnit ~= "" and lowestHpNoPomPercent < C.pomHealthPercent then
		unitToCast = lowestHpNoPomUnit
		spellKey = SKey.POM
	end

	-- Level 28 (Shield): 真言术：盾 -> 兜底填补缺口
	if spellKey == "" and lowestHpNoShieldUnit ~= "" and lowestHpNoShieldPercent < C.shieldHealthPercent then
		unitToCast = lowestHpNoShieldUnit
		spellKey = SKey.PWS
	end

	-- Level 26: 愈合祷言 -> 正在拉怪的坦克 (全团安全前提)
	if spellKey == "" and pomReady and activeTankUnitForPom ~= "" and lowestHpPercent >= 50 then
		unitToCast = activeTankUnitForPom
		spellKey = SKey.POM
	end

	-- Level 19: 快速治疗 -> 最低血量保底
	if spellKey == "" and lowestHpPercent < C.flashHealHealthPercent and not isMoving() then
		unitToCast = lowestHpUnit
		spellKey = SKey.FLASH
	end

	-- Level 20 & 18 & 10: 站街无聊，地鼠铺盾阶段
	if spellKey == "" then
		if firstUnshieldedMelee ~= "" then
			unitToCast = firstUnshieldedMelee
			spellKey = SKey.PWS
		elseif firstUnshieldedRange ~= "" then
			unitToCast = firstUnshieldedRange
			spellKey = SKey.PWS
		elseif firstUnshieldedTank ~= "" and isParty then
			unitToCast = firstUnshieldedTank
			spellKey = SKey.PWS
		end
	end
	if unitToCast == "" or spellKey == "" then
		return action("NOOP")
	end

	return action(spellKey, unitToCast)
end

local function callbackHealer()
	if select(2, UnitClass("player")) ~= "PRIEST" then
		return action("NOOP")
	end
	local isParty = false
	if not IsInGroup() then
		isParty = true -- Solo视作小队逻辑执行
	elseif not IsInRaid() then
		isParty = true
	end
	return runRaid(isParty)
end

--粗糙的性能优化，可能会导致非GCD技能延后
local lastActionID = 0
local lastTime = 0
local function APLCallback()
	local now = GetTime()
	local GCD = VF_getSpellCD(61304)
	local CastWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
	if (now-lastTime >= 0.5) and (GCD <= CastWindow) then
		lastTime = now
		lastActionID = callbackHealer()
	end
	return lastActionID
end

aura_env.APLActionList = actionList
aura_env.APLCallback = APLCallback
aura_env.APLName = "竹井&斧王戒律"



