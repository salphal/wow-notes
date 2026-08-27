--[[
aura id: 竹井詩織里_奶德
aura uid: b0XypM1A9kg
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== trigger 1 自定义触发器 =====
function (event, ...)
    _G.ShioriDruidLastCastUnits = _G.ShioriDruidLastCastUnits or {
        LastCastNourishUnit = "",
        LastCastRegrowthUnit = "",
        NourishGUID = "",
        RegrowthGUID = ""
    }
    local t = _G.ShioriDruidLastCastUnits
    if event == "UNIT_SPELLCAST_SENT" then
        -- SENT 事件有 4 个参数
        local unit, target, castGUID, spellID = ...
        if unit == "player" then
            if spellID == 50464 or spellID == 48378 then
                t.LastCastNourishUnit = target
                t.NourishGUID = castGUID -- 记录这次施法的唯一 ID
            elseif spellID == 48443 then
                t.LastCastRegrowthUnit = target
                t.RegrowthGUID = castGUID
            end
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_FAILED" or event ==
    "UNIT_SPELLCAST_INTERRUPTED" then
        -- 结束类事件只有 3 个参数 (没有 target)
        local unit, castGUID, spellID = ...
        if unit == "player" then
            if t.NourishGUID and castGUID == t.NourishGUID then
                t.LastCastNourishUnit = ""
                t.NourishGUID = nil
            elseif t.RegrowthGUID and castGUID == t.RegrowthGUID then
                t.LastCastRegrowthUnit = ""
                t.RegrowthGUID = nil
            end
        end
    end
    return true
end

-- UNIT_SPELLCAST_SENT,UNIT_SPELLCAST_SUCCEEDED,UNIT_SPELLCAST_FAILED,UNIT_SPELLCAST_INTERRUPTED

-- ===== actions.init 自定义代码 =====
--[[
  奶德 APL 
  贡献人：竹井詩織里
  固定宏动作：预展开 player/party/raid 单位，避免战斗中动态生成宏。
]]
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_RestorationDruid_WLK then return end APL_RestorationDruid_WLK = true
local S = {
    REJUV = 48441, -- 回春术 (Rejuvenation)
    WG = 53251, -- 野性成长 (Wild Growth)
    SM = 18562, -- 迅捷治愈 (Swiftmend)
    NOURISH = 50464, -- 滋养 (Nourish)
    REGROWTH = 48443, -- 愈合 (Regrowth)
    HT = 48378, -- 治疗之触 (Healing Touch)
    LB = 48451, -- 生命绽放 (Lifebloom)
    BARKSKIN = 1283513 -- 树皮术 (Barkskin)
}

local SKey = {
    REJUV = "REJUV", -- 回春术 (Rejuvenation)
    WG = "WG", -- 野性成长 (Wild Growth)
    SM = "SM", -- 迅捷治愈 (Swiftmend)
    NOURISH = "NOURISH", -- 滋养 (Nourish)
    REGROWTH = "REGROWTH", -- 愈合 (Regrowth)
    HT = "HT", -- 治疗之触 (Healing Touch)
    LB = "LB", -- 生命绽放 (Lifebloom)
    BARKSKIN = "BARKSKIN" -- 树皮术 (Barkskin)
}

local C = {
    wildGrowthHealthDiff = 0, -- 野性成长缺口 || 调整掉血多少可以释放野性成长，如果你不想卡CD丢野性成长，配置一下这个选项
    swiftmendHealthDiff = 8000, -- 小迅捷缺口 || 调整掉血多少可以释放迅捷治愈
    nourishHealthDiff = 6000, -- 滋养/治疗之触缺口 || 调整掉血多少可以释放滋养/治疗之触(看你下面是不是勾选了使用治疗之触替换滋养)
    regrowthHealthDiff = 4500, -- 愈合第一口缺口 || 调整掉血多少可以释放愈合
    nourishHealthAdd = 6000, -- 滋养/治疗之触治疗量 || 你当前无暴击滋养/治疗之触治疗量，大概数值即可(看你下面是不是勾选了使用治疗之触替换滋养)
    regrowthHealthAdd = 4500, -- 愈合治疗量 || 你当前无暴击愈合第一口治疗量，大概数值即可
    autoBarkskinHealthPercent = 50, -- 自动树皮血量百分比 || 当目标血量低于这个百分比时，自动使用树皮术保护
    tankHealth = 40000, -- 坦克血量阈值 || 选择当前坦克的血量阈值，用于更好的判断坦克角色
    autoReplaceRejuvenationWithLifebloomWhenPlayerHasClearcastingBuff = true, -- 有节能施法时，替换回春术为生命绽放 || 为了偷回蓝，对于在存在节能施法的情况下，对于需要释放回春术的目标，自动更换为释放生命绽放，如果没有能施法的目标，则对自己或者T或其他目标释放生命绽放
    replaceNourishWithHealingTouch = false, -- 使用治疗之触替换滋养 || 勾选后将释放治疗之触而不是滋养，秒触天赋可以用
    replaceRejuvenationWithLifebloom = false, -- 使用生命绽放替换回春术 || 我不是很明白为什么有人需要全团给生命绽放，但是我大受震撼并添加了这个选项
    onlyCheckSelfHot = false, -- 只检查自己的HOT || 一般情况下，一个目标已经有相同的HOT，我们应该忽略这个目标，但是特殊情况下，我们希望顶掉这个其他玩家对这个目标的HOT以便更好的数据或者其他什么见鬼的原因，那么勾选这个即可
    ignorePowerWordShield = true, -- 无视目标是否存在真言术：盾 || 哪怕目标被牧师上了盾，依然给他回春等HOT
    healerSupport40Battleground = true, -- 支持40人战场 || 这个选项会增加raid26-raid40的单位宏，增加内存占用，如果你不打战场或者打小型战场，建议关闭这个选项
    supportSpecialDebuff = false -- 支持特殊Debuff || 这个选项会增加对一些TOC和ICC特殊Debuff的检查，增加CPU占用，如果你不打这些副本，建议关闭这个选项
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

_G.ShioriDruidLastCastUnits = _G.ShioriDruidLastCastUnits or {
    LastCastNourishUnit = "",
    LastCastRegrowthUnit = "",
    NourishGUID = "",
    RegrowthGUID = ""
}

local spellNames = {}
spellNames.REJUV = spellName(S.REJUV, "回春术")
spellNames.WG = spellName(S.WG, "野性成长")
spellNames.SM = spellName(S.SM, "迅捷治愈")
spellNames.NOURISH = spellName(S.NOURISH, "滋养")
spellNames.REGROWTH = spellName(S.REGROWTH, "愈合")
spellNames.HT = spellName(S.HT, "治疗之触")
spellNames.LB = spellName(S.LB, "生命绽放")
spellNames.BARKSKIN = spellName(S.BARKSKIN, "树皮术")

local units = {"player"}
for i = 1, 4 do
    table.insert(units, "party" .. i)
end

for i = 1, (C.healerSupport40Battleground and 40 or 25) do
    table.insert(units, "raid" .. i)
end

local initializedId = 8080000
local actionIds = {}
local actionList = {}
local recent = {}

local function addUnitMacro(key, spellId, macroSpellName, unit, iconId)
    actionIds[key] = actionIds[key] or {}
    local id = initializedId + (#actionList + 1)
    actionIds[key][unit] = id
    table.insert(actionList, {id, "macro", "/cast [@" .. unit .. ",help,nodead] " .. macroSpellName,
            iconId or GetSpellTexture(spellId)})
end

for _, unit in ipairs(units) do
    addUnitMacro(SKey.REJUV, S.REJUV, spellNames.REJUV, unit)
    addUnitMacro(SKey.WG, S.WG, spellNames.WG, unit)
    addUnitMacro(SKey.SM, S.SM, spellNames.SM, unit)
    addUnitMacro(SKey.LB, S.LB, spellNames.LB, unit)
    if C.replaceNourishWithHealingTouch then
        addUnitMacro(SKey.HT, S.HT, spellNames.HT, unit)
    else
        addUnitMacro(SKey.NOURISH, S.NOURISH, spellNames.NOURISH, unit)
    end
    addUnitMacro(SKey.REGROWTH, S.REGROWTH, spellNames.REGROWTH, unit)
    addUnitMacro(SKey.BARKSKIN, S.BARKSKIN, spellNames.BARKSKIN, unit)
end

actionIds.NOOP = initializedId + 200000
table.insert(actionList, {actionIds.NOOP, "macro", "/stopmacro", GetSpellTexture(33883)})

local function hasBuff(unit, spellId, fallbackName, isFromPlayer)
    local expectedName = GetSpellInfo(spellId) or fallbackName
    if not expectedName or expectedName == "" then
        return false
    end
    local hasBuff = false
    if isFromPlayer then
        hasBuff = WA_GetUnitBuff(unit, expectedName, "PLAYER") ~= nil
    else
        hasBuff = WA_GetUnitBuff(unit, expectedName) ~= nil
    end
    return hasBuff
end

local function hasDebuff(unit, spellId, fallbackName, isFromPlayer)
    local expectedName = GetSpellInfo(spellId) or fallbackName
    if not expectedName or expectedName == "" then
        return false
    end
    local hasDebuff = false
    if isFromPlayer then
        hasDebuff = WA_GetUnitDebuff(unit, expectedName, "PLAYER") ~= nil
    else
        hasDebuff = WA_GetUnitDebuff(unit, expectedName) ~= nil
    end
    return hasDebuff
end

local function spellReady(spellId)
    local start, duration, enabled = GetSpellCooldown(spellId)
    if enabled == 0 then
        return false
    end
    if start and start > 0 and duration and duration > 0 then
        -- 【核心修改】如果冷却持续时间 <= 1.5 秒，说明这只是普通的公共冷却 (GCD)。
        -- 奶德带有CD的技能（如野性成长6秒，迅捷治愈15秒）真实CD都远大于1.5秒。
        -- 因此直接返回 true，允许排队施法，不再卡手。
        if duration <= 1.5 then
            return true
        end
        -- 如果大于 1.5 秒，说明技能确实在真正的冷却中，判断是否转完
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

local function unitHasTOCDebuff(unit)
    if C.supportSpecialDebuff == false then
        return false
    end
    for i = 1, 40 do -- 检查前40个debuff
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
-- 特别的，先检查血肉成灰，不然团长暴跳如雷
local function unitHasIncinerateFleshDebuff(unit)
    return hasDebuff(unit, 66237, "血肉成灰", false)
end

local function getUnitRoleType(unit, maxUnit, unitHealthMax)
    local _, class = UnitClass(unit)
    local powerType = UnitPowerType(unit)
    if unit == maxUnit then
        return "TANK"
    end
    
    if WA_GetUnitBuff(unit, "真言术：韧") or WA_GetUnitBuff(unit, "坚韧祷言") or
    WA_GetUnitBuff(unit, "命令怒吼") then
        if unitHealthMax > C.tankHealth * 1.1 then
            return "TANK"
        end
    else
        if unitHealthMax > C.tankHealth then
            return "TANK"
        end
    end
    
    local Role = "RANGE"
    -- 默认近战职业（战士、盗贼、DK、增强萨、惩戒骑、野德）
    if class == "WARRIOR" or class == "ROGUE" or class == "DEATHKNIGHT" then
        Role = "MELEE"
    elseif class == "PALADIN" then
        -- 惩戒骑通常蓝少
        if UnitPowerMax(unit, 0) < 15000 then
            Role = "MELEE"
        end
    elseif class == "SHAMAN" then
        -- 增强萨通常带闪电盾
        if WA_GetUnitBuff(unit, 49281) then
            Role = "MELEE"
        end
    elseif class == "DRUID" then
        -- 野德是近战
        if powerType == 3 then -- 能量（猫德）
            Role = "MELEE"
        elseif powerType == 1 then -- 怒气（熊德）
            Role = "TANK"
        end
    end
    return Role
end

local function calcUnitHealthDiff(unit, unitHealthMax)
    if not UnitExists(unit) then
        return 0
    end
    local unitHealthDiff = unitHealthMax - UnitHealth(unit)
    local unitName = UnitName(unit) or ""
    if _G.ShioriDruidLastCastUnits.LastCastNourishUnit ~= "" and
    (unit == _G.ShioriDruidLastCastUnits.LastCastNourishUnit or unitName ==
    _G.ShioriDruidLastCastUnits.LastCastNourishUnit) then
        unitHealthDiff = unitHealthDiff - C.nourishHealthAdd
    end
    if _G.ShioriDruidLastCastUnits.LastCastRegrowthUnit ~= "" and
    (unit == _G.ShioriDruidLastCastUnits.LastCastRegrowthUnit or unitName ==
    _G.ShioriDruidLastCastUnits.LastCastRegrowthUnit) then
        unitHealthDiff = unitHealthDiff - C.regrowthHealthAdd
    end
    if unitHealthDiff <= 0 then
        return 0
    end
    return unitHealthDiff
end

local function wildGrowthUsable(unitHealthDiff)
    return unitHealthDiff >= C.wildGrowthHealthDiff
end

local function barkskinUsable(unit, unitHealthMax, unitHealthDiff)
    if (not unitHealthMax or unitHealthMax <= 0) or C.autoBarkskinHealthPercent == nil or C.autoBarkskinHealthPercent <= 0 then
        return false
    end
    local unitHealthPercent = (unitHealthMax - unitHealthDiff) / unitHealthMax * 100
    return spellReady(S.BARKSKIN) and unitHealthPercent <= C.autoBarkskinHealthPercent
end

local function swiftmendUsable(unit, unitHealthDiff)
    -- 判断unit身上存在回春术或者愈合
    local hasRejuvenationOrRegrowth = hasBuff(unit, S.REJUV, "回春术", false) or hasBuff(unit, S.REGROWTH, "愈合", false)
    return hasRejuvenationOrRegrowth and unitHealthDiff >= C.swiftmendHealthDiff
end

local function rejuvenationOrLifebloomUsable(unit, forceUseLifebloom)
    forceUseLifebloom = forceUseLifebloom or false
    local needReplace = C.replaceRejuvenationWithLifebloom or forceUseLifebloom
    local castId = needReplace and S.LB or S.REJUV
    local castName = needReplace and "生命绽放" or "回春术"
    local hasPlayerRejuvenationOrLifebloom = hasBuff(unit, castId, castName, C.onlyCheckSelfHot)
    return not hasPlayerRejuvenationOrLifebloom
end

local function checkUnitHasPowerWordShield(unit)
    local hasBuff = false
    if C.ignorePowerWordShield then
        hasBuff = false
    else
        hasBuff = WA_GetUnitBuff(unit, "真言术：盾") ~= nil
    end
    return hasBuff
end

local function nourishOrHealingTouchUsable(unitHealthDiff)
    return unitHealthDiff >= C.nourishHealthDiff
end

local function regrowthUsable(unit, unitHealthDiff)
    local hasPlayerRegrowth = hasBuff(unit, S.REGROWTH, "愈合", C.onlyCheckSelfHot)
    return not hasPlayerRegrowth and unitHealthDiff >= C.regrowthHealthDiff
    
end
local function action(key, unit)
    if unit then
        return actionIds[key] and actionIds[key][unit]
    end
    return actionIds[key]
end

local function doFinalCheck(unit, spellKey)
    if unit == "" or spellKey == "" then
        return action("NOOP")
    end
    return action(spellKey, unit)
end

local function runSolo()
    local unit = "player"
    if not inRange(unit, S.REJUV) then
        return action("NOOP")
    end
    local spellKey = ""
    local unitHealthMax = UnitHealthMax(unit)
    local unitHealthDiff = calcUnitHealthDiff(unit, unitHealthMax)
    
    if spellReady(S.SM) and swiftmendUsable(unit, unitHealthDiff) then
        spellKey = SKey.SM
    elseif barkskinUsable(unit, unitHealthMax, unitHealthDiff) then
        spellKey = SKey.BARKSKIN
    elseif spellReady(S.WG) and wildGrowthUsable(unitHealthDiff) then
        spellKey = SKey.WG
    elseif rejuvenationOrLifebloomUsable(unit) then
        spellKey = C.replaceRejuvenationWithLifebloom and SKey.LB or SKey.REJUV
    elseif not isMoving() and nourishOrHealingTouchUsable(unitHealthDiff) then
        spellKey = C.replaceNourishWithHealingTouch and SKey.HT or SKey.NOURISH
    elseif not isMoving() and regrowthUsable(unit, unitHealthDiff) then
        spellKey = SKey.REGROWTH
    else
        spellKey = ""
    end
    local playerHasClearcastingBuff = WA_GetUnitBuff("player", 16870) ~= nil -- 有清晰预兆
    if playerHasClearcastingBuff and C.autoReplaceRejuvenationWithLifebloomWhenPlayerHasClearcastingBuff and spellKey ~=
    SKey.LB then
        if spellKey == SKey.REJUV then
            spellKey = SKey.LB
        elseif spellKey == "" then
            spellKey = SKey.LB
        end
    end
    return doFinalCheck(unit, spellKey)
end

local function runParty()
    -- 处理小队 判断T的位置，判断全队血量是否有少8000且能用迅捷治愈，如果有，优先使用迅捷治愈，随后判断是否可以释放野性成长，可以，优先给T，如果T超过距离，优先给自己
    -- 如果上述都不行，则判断回春术是否可以施放，如果可以，施放回春术，也是优先给T，随后其他人 
    local maxPartyHealthPlayerUnit = ""
    local maxParthHealthPlayerHealth = 0
    local meleeUnit = ""
    local tank1Unit = ""
    local unitToCast = ""
    local spellKey = ""
    local inRangeUnitList = {}
    local unitHealthMaxMap = {}
    local unitHealthDiffMap = {}
    local maxHealthDiffOfWildGrowthUsableUnit = ""
    local maxHealthDiffOfWildGrowthUsable = 0
    local maxHealthDiffOfRejuvenationOrLifebloomUsableUnit = ""
    local maxHealthDiffOfRejuvenationOrLifebloomUsable = 0
    
    -- 找最大血量的
    for i = 1, 5 do
        local unit = i == 1 and "player" or "party" .. (i - 1)
        if UnitExists(unit) then
            local unitHealthMax = UnitHealthMax(unit)
            if maxParthHealthPlayerHealth < unitHealthMax then
                maxParthHealthPlayerHealth = unitHealthMax
                maxPartyHealthPlayerUnit = unit
            end
            if inRange(unit, S.REJUV) then
                table.insert(inRangeUnitList, unit)
                unitHealthMaxMap[unit] = unitHealthMax
                unitHealthDiffMap[unit] = calcUnitHealthDiff(unit, unitHealthMax)
            end
        end
    end
    for _, unit in ipairs(inRangeUnitList) do
        if meleeUnit == "" or tank1Unit == "" then
            local unitRole = getUnitRoleType(unit, maxPartyHealthPlayerUnit, unitHealthMaxMap[unit])
            if unitRole == "MELEE" then
                meleeUnit = unit
            elseif unitRole == "TANK" then
                tank1Unit = unit
            end
        end
        local unitHealthDiff = unitHealthDiffMap[unit]
        if unitHealthDiff then
            if spellReady(S.SM) and swiftmendUsable(unit, unitHealthDiff) then
                unitToCast = unit
                spellKey = SKey.SM
                break
            end
            if unitHealthMaxMap[unit] and barkskinUsable(unit, unitHealthMaxMap[unit], unitHealthDiff) then
                unitToCast = unit
                spellKey = SKey.BARKSKIN
                break
            end
            if wildGrowthUsable(unitHealthDiff) and maxHealthDiffOfWildGrowthUsable < unitHealthDiff then
                maxHealthDiffOfWildGrowthUsable = unitHealthDiff
                maxHealthDiffOfWildGrowthUsableUnit = unit
            end
            if rejuvenationOrLifebloomUsable(unit) and maxHealthDiffOfRejuvenationOrLifebloomUsable < unitHealthDiff then
                maxHealthDiffOfRejuvenationOrLifebloomUsable = unitHealthDiff
                maxHealthDiffOfRejuvenationOrLifebloomUsableUnit = unit
            end
        end
    end
    -- 如果已经有施放了迅捷治愈，则不再施放
    if spellKey == "" then
        if spellReady(S.WG) then
            if tank1Unit ~= "" then
                local unitHealthDiff = unitHealthDiffMap[tank1Unit]
                if unitHealthDiff and wildGrowthUsable(unitHealthDiff) then
                    unitToCast = tank1Unit
                    spellKey = SKey.WG
                end
            end
            if spellKey == "" and meleeUnit ~= "" then
                local unitHealthDiff = unitHealthDiffMap[meleeUnit]
                if unitHealthDiff and wildGrowthUsable(unitHealthDiff) then
                    unitToCast = meleeUnit
                    spellKey = SKey.WG
                end
            end
            if spellKey == "" and maxHealthDiffOfWildGrowthUsableUnit ~= "" then
                unitToCast = maxHealthDiffOfWildGrowthUsableUnit
                spellKey = SKey.WG
            end
            if spellKey == "" and unitHealthDiffMap["player"] and wildGrowthUsable(unitHealthDiffMap["player"]) then
                unitToCast = "player"
                spellKey = SKey.WG
            end
        end
        
    end
    -- 再看看要不要给T加个HOT
    if spellKey == "" and not isMoving() and tank1Unit ~= "" then
        local unitHealthDiff = unitHealthDiffMap[tank1Unit]
        if unitHealthDiff and regrowthUsable(tank1Unit, unitHealthDiff) then
            unitToCast = tank1Unit
            spellKey = SKey.REGROWTH
        end
    end
    -- 先救人！
    if spellKey == "" and not isMoving() then
        for _, unit in ipairs(inRangeUnitList) do
            local unitHealthDiff = unitHealthDiffMap[unit]
            if unitHealthDiff and nourishOrHealingTouchUsable(unitHealthDiff) then
                unitToCast = unit
                spellKey = C.replaceNourishWithHealingTouch and SKey.HT or SKey.NOURISH
                break
            end
        end
    end
    -- 给T先来个回春
    if spellKey == "" and tank1Unit ~= "" then
        if rejuvenationOrLifebloomUsable(tank1Unit) and not checkUnitHasPowerWordShield(tank1Unit) then
            unitToCast = tank1Unit
            spellKey = C.replaceRejuvenationWithLifebloom and SKey.LB or SKey.REJUV
        end
    end
    -- 找个掉血最多的上回春
    if spellKey == "" and maxHealthDiffOfRejuvenationOrLifebloomUsableUnit ~= "" then
        unitToCast = maxHealthDiffOfRejuvenationOrLifebloomUsableUnit
        spellKey = C.replaceRejuvenationWithLifebloom and SKey.LB or SKey.REJUV
    end
    -- 都没掉血，那么挨个回春吧
    if spellKey == "" then
        for unit, unitHealthDiff in pairs(unitHealthDiffMap) do
            if rejuvenationOrLifebloomUsable(unit) then
                unitToCast = unit
                spellKey = C.replaceRejuvenationWithLifebloom and SKey.LB or SKey.REJUV
                break
            end
        end
    end
    local playerHasClearcastingBuff = WA_GetUnitBuff("player", 16870) ~= nil -- 有清晰预兆
    if playerHasClearcastingBuff and C.autoReplaceRejuvenationWithLifebloomWhenPlayerHasClearcastingBuff and spellKey ~=
    SKey.LB then
        if spellKey == SKey.REJUV then
            spellKey = SKey.LB
        elseif spellKey == "" then
            if tank1Unit ~= "" then
                if rejuvenationOrLifebloomUsable(tank1Unit, true) then
                    unitToCast = tank1Unit
                    spellKey = SKey.LB
                end
            end
            if spellKey == "" and meleeUnit ~= "" then
                if rejuvenationOrLifebloomUsable(meleeUnit, true) then
                    unitToCast = meleeUnit
                    spellKey = SKey.LB
                end
            end
            if spellKey == "" then
                unitToCast = "player"
                spellKey = SKey.LB
            end
        end
    end
    
    return doFinalCheck(unitToCast, spellKey)
end

local function runRaid()
    local selfInRaidUnit = ""
    local maxRaidHealthPlayerUnit = ""
    local maxRaidHealthPlayerHealth = 0
    local unitToCast = ""
    local spellKey = ""
    local inRangeUnitList = {}
    local unitHealthMaxMap = {}
    local unitHealthDiffMap = {}
    local tank1Unit = ""
    local tank2Unit = ""
    local tank3Unit = ""
    local meleeUnit = ""
    local maxHealthDiffOfWildGrowthUsableUnit = ""
    local maxHealthDiffOfWildGrowthUsable = 0
    local maxHealthDiffOfNourishOrHealingTouchUsableUnit = ""
    local maxHealthDiffOfNourishOrHealingTouchUsable = 0
    local maxHealthDiffOfRejuvenationOrLifebloomUsableOnlyAboveZeroWithoutPowerWordShieldCheckUnit = ""
    local maxHealthDiffOfRejuvenationOrLifebloomUsableOnlyAboveZeroWithoutPowerWordShieldCheck = 0
    local firstRejuvenationOrLifebloomUsableContainZeroWithPowerWordShieldCheckUnit = ""
    
    -- 找最大血量的
    for i = 1, (C.healerSupport40Battleground and 40 or 25) do
        local unit = "raid" .. i
        if UnitExists(unit) then
            local unitHealthMax = UnitHealthMax(unit)
            if maxRaidHealthPlayerHealth < unitHealthMax then
                maxRaidHealthPlayerHealth = unitHealthMax
                maxRaidHealthPlayerUnit = unit
            end
            -- 只针对可以施放回春术的目标进行循环，避免不必要的计算和判断
            if inRange(unit, S.REJUV) then
                table.insert(inRangeUnitList, unit)
                local unitHealthDiff = calcUnitHealthDiff(unit, unitHealthMax)
                unitHealthMaxMap[unit] = unitHealthMax
                unitHealthDiffMap[unit] = unitHealthDiff
                if selfInRaidUnit == "" and UnitIsUnit(unit, "player") then
                    selfInRaidUnit = unit
                end
                if wildGrowthUsable(unitHealthDiff) then
                    if maxHealthDiffOfWildGrowthUsable < unitHealthDiff then
                        maxHealthDiffOfWildGrowthUsable = unitHealthDiff
                        maxHealthDiffOfWildGrowthUsableUnit = unit
                    end
                end
                if nourishOrHealingTouchUsable(unitHealthDiff) then
                    if maxHealthDiffOfNourishOrHealingTouchUsable < unitHealthDiff then
                        maxHealthDiffOfNourishOrHealingTouchUsable = unitHealthDiff
                        maxHealthDiffOfNourishOrHealingTouchUsableUnit = unit
                    end
                end
                if rejuvenationOrLifebloomUsable(unit) then
                    if maxHealthDiffOfRejuvenationOrLifebloomUsableOnlyAboveZeroWithoutPowerWordShieldCheck <
                    unitHealthDiff then
                        maxHealthDiffOfRejuvenationOrLifebloomUsableOnlyAboveZeroWithoutPowerWordShieldCheck =
                        unitHealthDiff
                        maxHealthDiffOfRejuvenationOrLifebloomUsableOnlyAboveZeroWithoutPowerWordShieldCheckUnit = unit
                    end
                end
                -- 这样保证从小队1开始
                if rejuvenationOrLifebloomUsable(unit) and not checkUnitHasPowerWordShield(unit) and
                firstRejuvenationOrLifebloomUsableContainZeroWithPowerWordShieldCheckUnit == "" then
                    firstRejuvenationOrLifebloomUsableContainZeroWithPowerWordShieldCheckUnit = unit
                end
            end
        end
    end
    
    for _, unit in ipairs(inRangeUnitList) do
        local unitHealthDiff = unitHealthDiffMap[unit]
        if meleeUnit == "" or tank1Unit == "" or tank2Unit == "" or tank3Unit == "" then
            local unitRole = getUnitRoleType(unit, maxRaidHealthPlayerUnit, unitHealthMaxMap[unit])
            if meleeUnit == "" and unitRole == "MELEE" then
                meleeUnit = unit
            elseif unitRole == "TANK" then
                if tank1Unit == "" then
                    tank1Unit = unit
                elseif tank2Unit == "" then
                    tank2Unit = unit
                elseif tank3Unit == "" then
                    tank3Unit = unit
                end
            end
        end
        if spellReady(S.SM) and swiftmendUsable(unit, unitHealthDiff) then
            unitToCast = unit
            spellKey = SKey.SM
            break
        end
        if unitHealthMaxMap[unit] and barkskinUsable(unit, unitHealthMaxMap[unit], unitHealthDiff) then
            unitToCast = unit
            spellKey = SKey.BARKSKIN
            break
        end
    end
    -- 刷血肉！！！
    if spellKey == "" and C.supportSpecialDebuff then
        for _, unit in ipairs(inRangeUnitList) do
            if unitHasIncinerateFleshDebuff(unit) then
                unitToCast = unit
                spellKey = C.replaceNourishWithHealingTouch and SKey.HT or SKey.NOURISH
                break
            end
        end
    end
    if spellKey == "" and spellReady(S.WG) then
        -- 先判定野性成长
        if tank1Unit ~= "" then
            local unitHealthDiff = unitHealthDiffMap[tank1Unit]
            if unitHealthDiff and wildGrowthUsable(unitHealthDiff) then
                unitToCast = tank1Unit
                spellKey = SKey.WG
            end
        end
        if spellKey == "" and tank2Unit ~= "" then
            local unitHealthDiff = unitHealthDiffMap[tank2Unit]
            if unitHealthDiff and wildGrowthUsable(unitHealthDiff) then
                unitToCast = tank2Unit
                spellKey = SKey.WG
            end
        end
        if spellKey == "" and tank3Unit ~= "" then
            local unitHealthDiff = unitHealthDiffMap[tank3Unit]
            if unitHealthDiff and wildGrowthUsable(unitHealthDiff) then
                unitToCast = tank3Unit
                spellKey = SKey.WG
            end
        end
        if spellKey == "" and meleeUnit ~= "" then
            local unitHealthDiff = unitHealthDiffMap[meleeUnit]
            if unitHealthDiff and wildGrowthUsable(unitHealthDiff) then
                unitToCast = meleeUnit
                spellKey = SKey.WG
            end
        end
        if spellKey == "" then
            if maxHealthDiffOfWildGrowthUsableUnit ~= "" then
                unitToCast = maxHealthDiffOfWildGrowthUsableUnit
                spellKey = SKey.WG
            end
        end
        if spellKey == "" and selfInRaidUnit ~= "" and unitHealthDiffMap[selfInRaidUnit] and
        wildGrowthUsable(unitHealthDiffMap[selfInRaidUnit]) then
            unitToCast = selfInRaidUnit
            spellKey = SKey.WG
        end
    end
    
    if spellKey == "" then
        if tank1Unit ~= "" then
            if rejuvenationOrLifebloomUsable(tank1Unit) and not checkUnitHasPowerWordShield(tank1Unit) then
                unitToCast = tank1Unit
                spellKey = C.replaceRejuvenationWithLifebloom and SKey.LB or SKey.REJUV
            end
        end
        if spellKey == "" and tank2Unit ~= "" then
            if rejuvenationOrLifebloomUsable(tank2Unit) and not checkUnitHasPowerWordShield(tank2Unit) then
                unitToCast = tank2Unit
                spellKey = C.replaceRejuvenationWithLifebloom and SKey.LB or SKey.REJUV
            end
        end
        if spellKey == "" and tank3Unit ~= "" then
            if rejuvenationOrLifebloomUsable(tank3Unit) and not checkUnitHasPowerWordShield(tank3Unit) then
                unitToCast = tank3Unit
                spellKey = C.replaceRejuvenationWithLifebloom and SKey.LB or SKey.REJUV
            end
        end
        
    end
    -- 判断坦克身上是否有愈合且血量掉了指定血量，给他们加愈合
    if spellKey == "" and not isMoving() then
        if tank1Unit ~= "" then
            local unitHealthDiff = unitHealthDiffMap[tank1Unit]
            if unitHealthDiff and regrowthUsable(tank1Unit, unitHealthDiff) then
                unitToCast = tank1Unit
                spellKey = SKey.REGROWTH
            end
        end
        if spellKey == "" and tank2Unit ~= "" then
            local unitHealthDiff = unitHealthDiffMap[tank2Unit]
            if unitHealthDiff and regrowthUsable(tank2Unit, unitHealthDiff) then
                unitToCast = tank2Unit
                spellKey = SKey.REGROWTH
            end
        end
        if spellKey == "" and tank3Unit ~= "" then
            local unitHealthDiff = unitHealthDiffMap[tank3Unit]
            if unitHealthDiff and regrowthUsable(tank3Unit, unitHealthDiff) then
                unitToCast = tank3Unit
                spellKey = SKey.REGROWTH
            end
        end
    end
    
    if spellKey == "" and not isMoving() then
        -- 判断坦克是否掉了很多血，并给滋养
        if tank1Unit ~= "" then
            local unitHealthDiff = unitHealthDiffMap[tank1Unit]
            if nourishOrHealingTouchUsable(unitHealthDiff) then
                unitToCast = tank1Unit
                spellKey = C.replaceNourishWithHealingTouch and SKey.HT or SKey.NOURISH
            end
        end
        if spellKey == "" and tank2Unit ~= "" then
            local unitHealthDiff = unitHealthDiffMap[tank2Unit]
            if nourishOrHealingTouchUsable(unitHealthDiff) then
                unitToCast = tank2Unit
                spellKey = C.replaceNourishWithHealingTouch and SKey.HT or SKey.NOURISH
            end
        end
        if spellKey == "" and tank3Unit ~= "" then
            local unitHealthDiff = unitHealthDiffMap[tank3Unit]
            if nourishOrHealingTouchUsable(unitHealthDiff) then
                unitToCast = tank3Unit
                spellKey = C.replaceNourishWithHealingTouch and SKey.HT or SKey.NOURISH
            end
        end
        -- 找到掉血中的人，上滋养
        if spellKey == "" and maxHealthDiffOfNourishOrHealingTouchUsableUnit ~= "" then
            unitToCast = maxHealthDiffOfNourishOrHealingTouchUsableUnit
            spellKey = C.replaceNourishWithHealingTouch and SKey.HT or SKey.NOURISH
        end
    end
    if spellKey == "" and maxHealthDiffOfRejuvenationOrLifebloomUsableOnlyAboveZeroWithoutPowerWordShieldCheckUnit ~= "" then
        spellKey = C.replaceRejuvenationWithLifebloom and SKey.LB or SKey.REJUV
        unitToCast = maxHealthDiffOfRejuvenationOrLifebloomUsableOnlyAboveZeroWithoutPowerWordShieldCheckUnit
    end
    -- 理论上这些DEBUFF不该奶德去刷，奶德应该全团回春，直接掉血后在前面判断更为合理
    if spellKey == "" and C.supportSpecialDebuff then
        for unit, unitHealthDiff in pairs(unitHealthDiffMap) do
            if unitHasTOCDebuff(unit) then
                unitToCast = unit
                spellKey = C.replaceNourishWithHealingTouch and SKey.HT or SKey.NOURISH
                break
            end
        end
    end
    if spellKey == "" and firstRejuvenationOrLifebloomUsableContainZeroWithPowerWordShieldCheckUnit ~= "" then
        unitToCast = firstRejuvenationOrLifebloomUsableContainZeroWithPowerWordShieldCheckUnit
        spellKey = C.replaceRejuvenationWithLifebloom and SKey.LB or SKey.REJUV
    end
    local playerHasClearcastingBuff = WA_GetUnitBuff("player", 16870) ~= nil -- 有清晰预兆
    if playerHasClearcastingBuff and C.autoReplaceRejuvenationWithLifebloomWhenPlayerHasClearcastingBuff and spellKey ~=
    SKey.LB then
        if spellKey == SKey.REJUV then
            spellKey = SKey.LB
        elseif spellKey == "" then
            if tank1Unit ~= "" then
                if rejuvenationOrLifebloomUsable(tank1Unit, true) and not checkUnitHasPowerWordShield(tank1Unit) then
                    unitToCast = tank1Unit
                    spellKey = SKey.LB
                end
            end
            if spellKey == "" and tank2Unit ~= "" then
                if rejuvenationOrLifebloomUsable(tank2Unit, true) and not checkUnitHasPowerWordShield(tank2Unit) then
                    unitToCast = tank2Unit
                    spellKey = SKey.LB
                end
            end
            if spellKey == "" and tank3Unit ~= "" then
                if rejuvenationOrLifebloomUsable(tank3Unit, true) and not checkUnitHasPowerWordShield(tank3Unit) then
                    unitToCast = tank3Unit
                    spellKey = SKey.LB
                end
            end
            if spellKey == "" and meleeUnit ~= "" then
                if rejuvenationOrLifebloomUsable(meleeUnit, true) and not checkUnitHasPowerWordShield(meleeUnit) then
                    unitToCast = meleeUnit
                    spellKey = SKey.LB
                end
            end
            if spellKey == "" and selfInRaidUnit ~= "" then
                unitToCast = selfInRaidUnit
                spellKey = SKey.LB
            end
            
        end
    end
    
    return doFinalCheck(unitToCast, spellKey)
    
end

local function callbackHealer()
    if select(2, UnitClass("player")) ~= "DRUID" then
        return action("NOOP")
    end
    if not IsInGroup() then
        return runSolo()
    end
    if not IsInRaid() then
        return runParty()
    end
    return runRaid()
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
aura_env.APLName = "竹井詩織里"

-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)