--[[
aura id: 竹井詩織里_奶骑
aura uid: 3DrMLmHuFgb
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== trigger 1 自定义触发器 =====
function (event, ...)
    _G.ShioriPaladinLastCastUnits = _G.ShioriPaladinLastCastUnits or {
        LastCastHolyLightUnit = "",
        LastCastFlashOfLightUnit = "",
        HolyLightGUID = "",
        FlashOfLightGUID = ""
    }
    local t = _G.ShioriPaladinLastCastUnits
    if event == "UNIT_SPELLCAST_SENT" then
        -- SENT 事件有 4 个参数
        local unit, target, castGUID, spellID = ...
        if unit == "player" then
            if spellID == 48782 then
                t.LastCastHolyLightUnit = target
                t.HolyLightGUID = castGUID -- 记录这次施法的唯一 ID
            elseif spellID == 48785 then
                t.LastCastFlashOfLightUnit = target
                t.FlashOfLightGUID = castGUID
            end
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_FAILED" or event ==
    "UNIT_SPELLCAST_INTERRUPTED" then
        -- 结束类事件只有 3 个参数 (没有 target)
        local unit, castGUID, spellID = ...
        if unit == "player" then
            if t.HolyLightGUID and castGUID == t.HolyLightGUID then
                t.LastCastHolyLightUnit = ""
                t.HolyLightGUID = nil
            elseif t.FlashOfLightGUID and castGUID == t.FlashOfLightGUID then
                t.LastCastFlashOfLightUnit = ""
                t.FlashOfLightGUID = nil
            end
        end
    end
    return true
end

-- UNIT_SPELLCAST_SENT,UNIT_SPELLCAST_SUCCEEDED,UNIT_SPELLCAST_FAILED,UNIT_SPELLCAST_INTERRUPTED

-- ===== actions.init 自定义代码 =====
--[[
  奶骑 APL 
  贡献人：竹井詩織里
  固定宏动作：预展开 player/party/raid 单位，避免战斗中动态生成宏。
]]
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_HolyParadin_WLK then return end APL_HolyParadin_WLK = true
local S = {
    HL = 48782, -- 圣光术 (Holy Light)
    FOL = 48785, -- 圣光闪现 (Flash of Light)
    BEACON = 53563, -- 圣光道标 (Beacon of Light)
    AUTO_ATTACK = 6603 -- 自动攻击 (Auto Attack)
}
local SKey = {
    HL = "HL", -- 圣光术 (Holy Light)
    FOL = "FOL", -- 圣光闪现 (Flash of Light)
    BEACON = "BEACON", -- 圣光道标 (Beacon of Light)
    AUTO_ATTACK = "AUTO_ATTACK" -- 自动攻击 (Auto Attack)
}
-- 提取老版本的核心配置项，并增加类似奶德的战场支持选项
local C = {
    holyLightHealthDiff = 4000, -- 圣光术缺口 || 调整掉血多少可以释放圣光术
    flashOfLightHealthDiff = 2000, -- 圣光闪现缺口 || 调整掉血多少可以释放圣光术，不能比圣光术缺口大，不然就判定为圣光术的一半
    holyLightHealthAdd = 12000, -- 圣光术治疗量 || 你当前无暴击圣光术治疗量，大概数值即可
    flashOfLightHealthAdd = 5000, -- 圣光闪现治疗量 || 你当前无暴击圣光闪现治疗量，大概数值即可
    tankHealth = 40000, -- 坦克血量阈值 || 选择当前坦克的血量阈值，用于更好的判断坦克角色
    enableFlashOfLight = false, -- 启用圣光闪现 || 是否启用圣光闪现
    enablePreCast = true, -- 启用强制预读 || 是否强制预读
    enableDebuffPlayerPreCast = true, -- 对DEBUFF玩家无脑治疗 || 是否对还未掉血的DEBUFF人员进行预读，设置为是，只要有规定的那些DEBUFF例如燃烧弹等等，哪怕目标还没掉血，也进行预读，设置为否的情况下，如果未开启前面的启用预读选项，则只要DEBUFF人员掉血就对他治疗，若开启前面的启用预读选项，则DEBUFF人员必须掉到缺口血量才进行治疗（这个功能配合开启预读，并把几个缺口阈值拉满，可以改变手法为只奶T）
    healerSupport40Battleground = true, -- 支持40人战场 || 这个选项会增加raid26-raid40的单位宏，增加CPU占用，如果你不打战场或者打小型战场，建议关闭这个选项
    supportSpecialDebuff = false, -- 支持特殊Debuff || 这个选项会增加对一些TOC和ICC特殊Debuff的检查，增加CPU占用，如果你不打这些副本，建议关闭这个选项
    autoCastBeaconOfLightToFocus = true, -- 自动对焦点释放圣光道标 || 是否在道标结束后自动对焦点目标释放圣光道标
    beaconOfLightEarlySecond = 1 -- 提前几秒释放圣光道标 || 在圣光道标结束前，设定提前几秒释放圣光道标
}

if aura_env.config then
    for k, v in pairs(aura_env.config) do
        C[k] = v
    end
end

-- 确保闪现的阈值不会高于大圣光
if C.flashOfLightHealthDiff >= C.holyLightHealthDiff then
    C.flashOfLightHealthDiff = C.holyLightHealthDiff / 2
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

_G.ShioriPaladinLastCastUnits = _G.ShioriPaladinLastCastUnits or {
    LastCastHolyLightUnit = "",
    LastCastFlashOfLightUnit = "",
    HolyLightGUID = "",
    FlashOfLightGUID = ""
}

local spellNames = {}

spellNames.HL = spellName(S.HL, "圣光术")
spellNames.FOL = spellName(S.FOL, "圣光闪现")
spellNames.BEACON = spellName(S.BEACON, "圣光道标")
spellNames.AUTO_ATTACK = spellName(S.AUTO_ATTACK, "攻击")

-- 构建目标单位池
local units = {"player", "focus"} -- 奶骑特别需要焦点目标来挂道标
for i = 1, 4 do
    table.insert(units, "party" .. i)
end
for i = 1, (C.healerSupport40Battleground and 40 or 25) do
    table.insert(units, "raid" .. i)
end

-- 定义初始化的 Action ID (使用 8380000 避免与奶德 8080000 冲突)
local initializedId = 8380000
local actionIds = {}
local actionList = {}

local function addUnitMacro(key, spellId, macroSpellName, unit, iconId)
    actionIds[key] = actionIds[key] or {}
    local id = initializedId + (#actionList + 1)
    actionIds[key][unit] = id
    
    local macroText = ""
    -- 针对圣光道标 + 焦点的特殊处理（如果配置了优先给焦点道标）
    if key == SKey.BEACON and unit == "focus" then
        macroText = "/startattack\\n/cast [@focus,help,nodead] " .. macroSpellName
    else
        macroText = "/startattack\\n/cast [@" .. unit .. ",help,nodead] " .. macroSpellName
    end
    
    table.insert(actionList, {id, "macro", macroText, iconId or GetSpellTexture(spellId)})
end

-- 为所有单位循环生成圣光术、闪现、道标宏
for _, unit in ipairs(units) do
    addUnitMacro(SKey.HL, S.HL, spellNames.HL, unit)
    addUnitMacro(SKey.FOL, S.FOL, spellNames.FOL, unit)
    addUnitMacro(SKey.BEACON, S.BEACON, spellNames.BEACON, unit)
end
-- 生成一个空闲降级动作 (NOOP)
actionIds.NOOP = initializedId + 200000
table.insert(actionList, {actionIds.NOOP, "macro", "/stopmacro\\n/startattack", GetSpellTexture(S.AUTO_ATTACK)})

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
    return C.supportSpecialDebuff and hasDebuff(unit, 66237, "血肉成灰", false)
end

local function unitHasBeaconOfLightFromPlayer(unit)
    return hasBuff(unit, 53563, "圣光道标", true)
end

local function getUnitRoleType(unit, maxUnit)
    local _, class = UnitClass(unit)
    local powerType = UnitPowerType(unit)
    if unit == maxUnit then
        return "TANK"
    end
    
    if WA_GetUnitBuff(unit, "真言术：韧") or WA_GetUnitBuff(unit, "坚韧祷言") or
    WA_GetUnitBuff(unit, "命令怒吼") then
        if UnitHealthMax(unit) > C.tankHealth * 1.1 then
            return "TANK"
        end
    else
        if UnitHealthMax(unit) > C.tankHealth then
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

local function calcUnitHealthDiff(unit)
    if not UnitExists(unit) then
        return 0
    end
    local unitHealthDiff = UnitHealthMax(unit) - UnitHealth(unit)
    local unitName = UnitName(unit) or ""
    if _G.ShioriPaladinLastCastUnits.LastCastHolyLightUnitName ~= "" and
    (unit == _G.ShioriPaladinLastCastUnits.LastCastHolyLightUnitName or unitName ==
    _G.ShioriPaladinLastCastUnits.LastCastHolyLightUnitName) then
        unitHealthDiff = unitHealthDiff - C.holyLightHealthAdd
    end
    if _G.ShioriPaladinLastCastUnits.LastCastFlashOfLightUnitName ~= "" and
    (unit == _G.ShioriPaladinLastCastUnits.LastCastFlashOfLightUnitName or unitName ==
    _G.ShioriPaladinLastCastUnits.LastCastFlashOfLightUnitName) then
        unitHealthDiff = unitHealthDiff - C.flashOfLightHealthAdd
    end
    if unitHealthDiff <= 0 then
        return 0
    end
    return unitHealthDiff
end

local function holyLightUsable(unit, unitHealthDiff)
    return unitHealthDiff >= C.holyLightHealthDiff and not isMoving()
end

local function flashOfLightUsable(unit, unitHealthDiff, directCheckAtLeastOneBloodCutDown)
    directCheckAtLeastOneBloodCutDown = directCheckAtLeastOneBloodCutDown or false
    if directCheckAtLeastOneBloodCutDown then
        return unitHealthDiff >= 1 and not isMoving()
    end
    return unitHealthDiff >= C.flashOfLightHealthDiff and not isMoving()
end

local function beaconOfLightToFocusUsable(beaconOfLightBuffFromPlayerUnit)
    if not C.autoCastBeaconOfLightToFocus then
        return false
    end
    -- 有道标目标，且如果不是焦点，则检查道标剩余时间，如果道标快结束了，提前给焦点上道标
    if beaconOfLightBuffFromPlayerUnit ~= "" then
        if C.beaconOfLightEarlySecond == 0 then
            return false
        end
        local name, _, _, _, _, endTime = WA_GetUnitBuff(beaconOfLightBuffFromPlayerUnit, "圣光道标", "PLAYER")
        if name ~= nil and endTime - GetTime() > C.beaconOfLightEarlySecond then
            return false
        end
    end
    local unit = "focus"
    return inRange(unit, S.BEACON)
end

-- 一个快捷的获取最终 Action ID 的函数
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
    if not inRange(unit, S.FOL) then
        return action("NOOP")
    end
    local spellKey = ""
    local unitHealthDiff = calcUnitHealthDiff(unit)
    
    if holyLightUsable(unit, unitHealthDiff) then
        spellKey = SKey.HL
    elseif flashOfLightUsable(unit, unitHealthDiff) then
        spellKey = C.enableFlashOfLight and SKey.FOL or SKey.HL
    else
        spellKey = ""
    end
    
    return doFinalCheck(unit, spellKey)
end

local function runParty()
    local maxPartyHealthPlayerUnit = ""
    local maxParthHealthPlayerHealth = 0
    local beaconOfLightBuffFromPlayerUnit = ""
    local meleeUnit = ""
    local tank1Unit = ""
    local unitToCast = ""
    local spellKey = ""
    local inRangeUnitList = {}
    local unitHealthDiffMap = {}
    local unitHealthDiffMapAll = {}
    
    -- 找最大血量的
    for i = 1, 5 do
        local unit = i == 1 and "player" or "party" .. (i - 1)
        if UnitExists(unit) then
            if maxParthHealthPlayerHealth < UnitHealthMax(unit) then
                maxParthHealthPlayerHealth = UnitHealthMax(unit)
                maxPartyHealthPlayerUnit = unit
            end
            if inRange(unit, S.FOL) then
                table.insert(inRangeUnitList, unit)
                unitHealthDiffMap[unit] = calcUnitHealthDiff(unit)
                unitHealthDiffMapAll[unit] = unitHealthDiffMap[unit]
            else
                unitHealthDiffMapAll[unit] = calcUnitHealthDiff(unit)
            end
            if beaconOfLightBuffFromPlayerUnit == "" and unitHasBeaconOfLightFromPlayer(unit) then
                beaconOfLightBuffFromPlayerUnit = unit
            end
        end
    end
    local bestMeleeUnit = ""
    local maxMeleeCutHealthDiff = 0
    
    local maxHealthDiffOfNoBeaconOfLightFromPlayerAndHolyLightUsableUnit = ""
    local maxHealthDiffOfNoBeaconOfLightFromPlayerAndHolyLightUsable = 0
    local maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableUnit = ""
    local maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsable = 0
    local maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableAndAtLeastOneBloodCutDownUnit = ""
    local maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableAndAtLeastOneBloodCutDown = 0
    
    for unit, unitHealthDiff in pairs(unitHealthDiffMap) do
        local unitRole = getUnitRoleType(unit, maxPartyHealthPlayerUnit)
        if unitRole == "MELEE" then
            if bestMeleeUnit == "" then
                bestMeleeUnit = unit
                maxMeleeCutHealthDiff = unitHealthDiff
            else
                if maxMeleeCutHealthDiff < unitHealthDiff then
                    bestMeleeUnit = unit
                    maxMeleeCutHealthDiff = unitHealthDiff
                end
            end
        elseif tank1Unit == "" and unitRole == "TANK" then
            tank1Unit = unit
        end
        if unit ~= beaconOfLightBuffFromPlayerUnit then
            if holyLightUsable(unit, unitHealthDiff) then
                if maxHealthDiffOfNoBeaconOfLightFromPlayerAndHolyLightUsable < unitHealthDiff then
                    maxHealthDiffOfNoBeaconOfLightFromPlayerAndHolyLightUsable = unitHealthDiff
                    maxHealthDiffOfNoBeaconOfLightFromPlayerAndHolyLightUsableUnit = unit
                end
            end
            if flashOfLightUsable(unit, unitHealthDiff, true) then
                if maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableAndAtLeastOneBloodCutDown <
                unitHealthDiff then
                    maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableAndAtLeastOneBloodCutDown =
                    unitHealthDiff
                    maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableAndAtLeastOneBloodCutDownUnit = unit
                end
            end
            if flashOfLightUsable(unit, unitHealthDiff) then
                if maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsable < unitHealthDiff then
                    maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsable = unitHealthDiff
                    maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableUnit = unit
                end
            end
        end
    end
    if bestMeleeUnit ~= "" then
        meleeUnit = bestMeleeUnit
    end
    if beaconOfLightToFocusUsable(beaconOfLightBuffFromPlayerUnit) then
        unitToCast = "focus"
        spellKey = SKey.BEACON
    end
    if spellKey == "" and beaconOfLightBuffFromPlayerUnit ~= "" then
        -- 如果道标没给T，那么先检查T要不要奶，如果需要，则奶T
        if tank1Unit ~= "" and beaconOfLightBuffFromPlayerUnit ~= tank1Unit then
            local tankHealthDiff = unitHealthDiffMap[tank1Unit] or calcUnitHealthDiff(tank1Unit)
            if holyLightUsable(tank1Unit, tankHealthDiff) then
                unitToCast = tank1Unit
                spellKey = SKey.HL
            end
        end
        local beaconOfLightPlayerHealthDiff = unitHealthDiffMapAll[beaconOfLightBuffFromPlayerUnit] or
        calcUnitHealthDiff(beaconOfLightBuffFromPlayerUnit)
        -- 检查另外四个人是否可以奶，可以就奶，让有道标的吃道标，选择掉血满足条件但是掉的最多的家伙
        if spellKey == "" then
            if maxHealthDiffOfNoBeaconOfLightFromPlayerAndHolyLightUsableUnit ~= "" then
                unitToCast = maxHealthDiffOfNoBeaconOfLightFromPlayerAndHolyLightUsableUnit
                spellKey = SKey.HL
            end
        end
        -- 如果都不能奶，直接检查道标目标需不需要奶，这时候肯定没有超过大圣光缺口的人了，不然前面就丢出去大圣光了 
        if spellKey == "" and beaconOfLightPlayerHealthDiff > 0 then
            -- 判断其他目标需不需要奶，如果需要，则奶掉血最多的
            if maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableAndAtLeastOneBloodCutDownUnit ~= "" then
                unitToCast = maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableAndAtLeastOneBloodCutDownUnit
                spellKey =
                beaconOfLightPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or C.enableFlashOfLight and
                SKey.FOL or SKey.HL
            end
            -- 其他人都没血量缺口，如果道标是T，奶自己，不然奶T
            if spellKey == "" and not isMoving() then
                -- 判读道标目标是不是T，不是T，奶T，是T，奶近战，实在不行，奶自己
                if tank1Unit ~= "" and tank1Unit ~= beaconOfLightBuffFromPlayerUnit then
                    unitToCast = tank1Unit
                    spellKey = beaconOfLightPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or
                    C.enableFlashOfLight and SKey.FOL or SKey.HL
                end
                if meleeUnit ~= "" and meleeUnit ~= beaconOfLightBuffFromPlayerUnit then
                    unitToCast = meleeUnit
                    spellKey = beaconOfLightPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or
                    C.enableFlashOfLight and SKey.FOL or SKey.HL
                end
                if spellKey == "" then
                    unitToCast = "player"
                    spellKey = beaconOfLightPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or
                    C.enableFlashOfLight and SKey.FOL or SKey.HL
                end
            end
        end
    end
    -- 啥都不行，找个最小血的目标，奶这个傻逼，判断是大还是小光
    if spellKey == "" then
        if maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableUnit ~= "" then
            unitToCast = maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableUnit
            spellKey = maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsable >= C.holyLightHealthDiff and
            SKey.HL or C.enableFlashOfLight and SKey.FOL or SKey.HL
        end
    end
    if C.enablePreCast and spellKey == "" and not isMoving() then
        if tank1Unit ~= "" and beaconOfLightBuffFromPlayerUnit ~= tank1Unit then
            unitToCast = tank1Unit
            spellKey = C.enableFlashOfLight and SKey.FOL or SKey.HL
        end
        if spellKey == "" and meleeUnit ~= "" and beaconOfLightBuffFromPlayerUnit ~= meleeUnit then
            unitToCast = meleeUnit
            spellKey = C.enableFlashOfLight and SKey.FOL or SKey.HL
        end
        if spellKey == "" and beaconOfLightBuffFromPlayerUnit ~= "player" then
            unitToCast = "player"
            spellKey = C.enableFlashOfLight and SKey.FOL or SKey.HL
        end
    end
    
    return doFinalCheck(unitToCast, spellKey)
end

local function runRaid()
    local maxRaidHealthPlayerUnit = ""
    local maxRaidHealthPlayerHealth = 0
    local beaconOfLightBuffFromPlayerUnit = ""
    local meleeUnit = ""
    local tank1Unit = ""
    local tank2Unit = ""
    local tank3Unit = ""
    local selfInRaidUnit = ""
    local incinerateFleshDebuffUnit = ""
    local otherTocDebuffUnit = ""
    local unitToCast = ""
    local spellKey = ""
    
    local inRangeUnitList = {}
    local unitHealthDiffMap = {}
    local unitHealthDiffMapAll = {}
    
    local raidMax = C.healerSupport40Battleground and 40 or 25
    
    -- 1. 遍历团队获取基础信息
    for i = 1, raidMax do
        local unit = "raid" .. i
        if UnitExists(unit) then
            if maxRaidHealthPlayerHealth < UnitHealthMax(unit) then
                maxRaidHealthPlayerHealth = UnitHealthMax(unit)
                maxRaidHealthPlayerUnit = unit
            end
            
            if inRange(unit, S.FOL) then
                table.insert(inRangeUnitList, unit)
                unitHealthDiffMap[unit] = calcUnitHealthDiff(unit)
                unitHealthDiffMapAll[unit] = unitHealthDiffMap[unit]
                if incinerateFleshDebuffUnit == "" and unitHasIncinerateFleshDebuff(unit) then
                    incinerateFleshDebuffUnit = unit
                end
                if otherTocDebuffUnit == "" and unitHasTOCDebuff(unit) then
                    otherTocDebuffUnit = unit
                end
            else
                unitHealthDiffMapAll[unit] = calcUnitHealthDiff(unit)
            end
            
            if selfInRaidUnit == "" and UnitIsUnit(unit, "player") then
                selfInRaidUnit = unit
            end
            if beaconOfLightBuffFromPlayerUnit == "" and unitHasBeaconOfLightFromPlayer(unit) then
                beaconOfLightBuffFromPlayerUnit = unit
            end
        end
    end
    
    local bestMeleeUnit = ""
    local maxMeleeCutHealthDiff = 0
    
    -- 分离提取大光/小闪缺口最大的人 (模仿你 Party 里的优雅写法)
    local maxHealthDiffOfNoBeaconOfLightFromPlayerAndHolyLightUsableUnit = ""
    local maxHealthDiffOfNoBeaconOfLightFromPlayerAndHolyLightUsable = 0
    local maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableUnit = ""
    local maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsable = 0
    local maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableAndAtLeastOneBloodCutDownUnit = ""
    local maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableAndAtLeastOneBloodCutDown = 0
    
    -- 2. 角色分类与缺口计算
    for unit, unitHealthDiff in pairs(unitHealthDiffMap) do
        local unitRole = getUnitRoleType(unit, maxRaidHealthPlayerUnit)
        
        if unitRole == "MELEE" then
            if bestMeleeUnit == "" then
                bestMeleeUnit = unit
                maxMeleeCutHealthDiff = unitHealthDiff
            else
                if maxMeleeCutHealthDiff < unitHealthDiff then
                    bestMeleeUnit = unit
                    maxMeleeCutHealthDiff = unitHealthDiff
                end
            end
        elseif unitRole == "TANK" then
            if tank1Unit == "" then
                tank1Unit = unit
            elseif tank2Unit == "" then
                tank2Unit = unit
            elseif tank3Unit == "" then
                tank3Unit = unit
            end
        end
        
        if unit ~= beaconOfLightBuffFromPlayerUnit then
            if maxHealthDiffOfNoBeaconOfLightFromPlayerAndHolyLightUsable < unitHealthDiff and
            holyLightUsable(unit, unitHealthDiff) then
                maxHealthDiffOfNoBeaconOfLightFromPlayerAndHolyLightUsable = unitHealthDiff
                maxHealthDiffOfNoBeaconOfLightFromPlayerAndHolyLightUsableUnit = unit
            end
            if maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableAndAtLeastOneBloodCutDown < unitHealthDiff and
            flashOfLightUsable(unit, unitHealthDiff, true) then
                maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableAndAtLeastOneBloodCutDown = unitHealthDiff
                maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableAndAtLeastOneBloodCutDownUnit = unit
            end
            if maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsable < unitHealthDiff and
            flashOfLightUsable(unit, unitHealthDiff, C.enablePreCast) then
                maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsable = unitHealthDiff
                maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableUnit = unit
            end
        end
    end
    if bestMeleeUnit ~= "" then
        meleeUnit = bestMeleeUnit
    end
    
    -- 3. 施法优先级判定
    -- 优先级 1: 焦点道标补篮
    if beaconOfLightToFocusUsable(beaconOfLightBuffFromPlayerUnit) then
        unitToCast = "focus"
        spellKey = SKey.BEACON
    end
    
    -- 优先级 2: 血肉成灰特判 (团长不骂娘判定)
    if spellKey == "" and incinerateFleshDebuffUnit ~= "" and beaconOfLightBuffFromPlayerUnit ~=
    incinerateFleshDebuffUnit and not isMoving() then
        unitToCast = incinerateFleshDebuffUnit
        spellKey = SKey.HL
    end
    
    local beaconPlayerHealthDiff = unitHealthDiffMapAll[beaconOfLightBuffFromPlayerUnit] or
    calcUnitHealthDiff(beaconOfLightBuffFromPlayerUnit)
    
    -- 优先级 3: 有道标时的优先照顾
    if spellKey == "" and beaconOfLightBuffFromPlayerUnit ~= "" then
        -- 坦克的大光
        if tank1Unit ~= "" and beaconOfLightBuffFromPlayerUnit ~= tank1Unit and
        holyLightUsable(tank1Unit, unitHealthDiffMap[tank1Unit]) then
            unitToCast = tank1Unit
            spellKey = SKey.HL
        elseif tank2Unit ~= "" and beaconOfLightBuffFromPlayerUnit ~= tank2Unit and
        holyLightUsable(tank2Unit, unitHealthDiffMap[tank2Unit]) then
            unitToCast = tank2Unit
            spellKey = SKey.HL
        elseif tank3Unit ~= "" and beaconOfLightBuffFromPlayerUnit ~= tank3Unit and
        holyLightUsable(tank3Unit, unitHealthDiffMap[tank3Unit]) then
            unitToCast = tank3Unit
            spellKey = SKey.HL
        end
        
        -- 大团的大光
        if spellKey == "" and maxHealthDiffOfNoBeaconOfLightFromPlayerAndHolyLightUsableUnit ~= "" then
            unitToCast = maxHealthDiffOfNoBeaconOfLightFromPlayerAndHolyLightUsableUnit
            spellKey = SKey.HL
        end
        
        -- 坦克和小分队的小光
        if spellKey == "" then
            if tank1Unit ~= "" and beaconOfLightBuffFromPlayerUnit ~= tank1Unit and
            flashOfLightUsable(tank1Unit, unitHealthDiffMap[tank1Unit]) then
                unitToCast = tank1Unit
                spellKey = beaconPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or C.enableFlashOfLight and
                SKey.FOL or SKey.HL
            elseif tank2Unit ~= "" and beaconOfLightBuffFromPlayerUnit ~= tank2Unit and
            flashOfLightUsable(tank2Unit, unitHealthDiffMap[tank2Unit]) then
                unitToCast = tank2Unit
                spellKey = beaconPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or C.enableFlashOfLight and
                SKey.FOL or SKey.HL
            elseif tank3Unit ~= "" and beaconOfLightBuffFromPlayerUnit ~= tank3Unit and
            flashOfLightUsable(tank3Unit, unitHealthDiffMap[tank3Unit]) then
                unitToCast = tank3Unit
                spellKey = beaconPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or C.enableFlashOfLight and
                SKey.FOL or SKey.HL
            elseif meleeUnit ~= "" and beaconOfLightBuffFromPlayerUnit ~= meleeUnit and
            flashOfLightUsable(meleeUnit, unitHealthDiffMap[meleeUnit]) then
                unitToCast = meleeUnit
                spellKey = beaconPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or C.enableFlashOfLight and
                SKey.FOL or SKey.HL
            end
        end
        
        -- 折射治疗: 大家都满血，道标在掉血，打地鼠给道标刷血
        if spellKey == "" and beaconPlayerHealthDiff > 0 then
            if maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableAndAtLeastOneBloodCutDownUnit ~= "" then
                unitToCast = maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableAndAtLeastOneBloodCutDownUnit
                spellKey = beaconPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or C.enableFlashOfLight and
                SKey.FOL or SKey.HL
            end
            
            -- TOC危险Debuff预读
            if spellKey == "" and otherTocDebuffUnit ~= "" and beaconOfLightBuffFromPlayerUnit ~= otherTocDebuffUnit then
                local debuffDiff = C.enableDebuffPlayerPreCast and 10000 or unitHealthDiffMap[otherTocDebuffUnit]
                if flashOfLightUsable(otherTocDebuffUnit, debuffDiff, C.enableDebuffPlayerPreCast) then
                    unitToCast = otherTocDebuffUnit
                    spellKey = beaconPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or C.enableFlashOfLight and
                    SKey.FOL or SKey.HL
                end
            end
            
            if spellKey == "" then
                if tank1Unit ~= "" and tank1Unit ~= beaconOfLightBuffFromPlayerUnit and unitHealthDiffMap[tank1Unit] and
                flashOfLightUsable(tank1Unit, unitHealthDiffMap[tank1Unit], true) then
                    unitToCast = tank1Unit
                    spellKey = beaconPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or C.enableFlashOfLight and
                    SKey.FOL or SKey.HL
                elseif tank2Unit ~= "" and tank2Unit ~= beaconOfLightBuffFromPlayerUnit and unitHealthDiffMap[tank2Unit] and
                flashOfLightUsable(tank2Unit, unitHealthDiffMap[tank2Unit], true) then
                    unitToCast = tank2Unit
                    spellKey = beaconPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or C.enableFlashOfLight and
                    SKey.FOL or SKey.HL
                elseif tank3Unit ~= "" and tank3Unit ~= beaconOfLightBuffFromPlayerUnit and unitHealthDiffMap[tank3Unit] and
                flashOfLightUsable(tank3Unit, unitHealthDiffMap[tank3Unit], true) then
                    unitToCast = tank3Unit
                    spellKey = beaconPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or C.enableFlashOfLight and
                    SKey.FOL or SKey.HL
                elseif meleeUnit ~= "" and meleeUnit ~= beaconOfLightBuffFromPlayerUnit and unitHealthDiffMap[meleeUnit] and
                flashOfLightUsable(meleeUnit, unitHealthDiffMap[meleeUnit], true) then
                    unitToCast = meleeUnit
                    spellKey = beaconPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or C.enableFlashOfLight and
                    SKey.FOL or SKey.HL
                end
            end
            if spellKey == "" then
                unitToCast = selfInRaidUnit ~= "" and selfInRaidUnit or "player"
                spellKey = beaconPlayerHealthDiff >= C.holyLightHealthDiff and SKey.HL or C.enableFlashOfLight and
                SKey.FOL or SKey.HL
            end
        end
    end
    
    -- 补防血肉成灰的人就是道标目标 (原版机制：如果道标中血肉，刷自己折射给他)
    if spellKey == "" and incinerateFleshDebuffUnit ~= "" and beaconOfLightBuffFromPlayerUnit ==
    incinerateFleshDebuffUnit and not isMoving() then
        unitToCast = selfInRaidUnit ~= "" and selfInRaidUnit or "player"
        spellKey = SKey.HL
    end
    
    -- 优先级 4: 无人需求大光时的正常逻辑
    if spellKey == "" then
        if maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableUnit ~= "" then
            unitToCast = maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsableUnit
            spellKey = maxHealthDiffOfNoBeaconOfLightFromPlayerAndFlashOfLightUsable >= C.holyLightHealthDiff and
            SKey.HL or C.enableFlashOfLight and SKey.FOL or SKey.HL
        end
        
        if spellKey == "" and otherTocDebuffUnit ~= "" and otherTocDebuffUnit ~= beaconOfLightBuffFromPlayerUnit then
            local debuffDiff = C.enableDebuffPlayerPreCast and 10000 or unitHealthDiffMap[otherTocDebuffUnit]
            if flashOfLightUsable(otherTocDebuffUnit, debuffDiff, C.enableDebuffPlayerPreCast) then
                unitToCast = otherTocDebuffUnit
                spellKey = C.enableFlashOfLight and SKey.FOL or SKey.HL
            end
        end
    end
    
    -- 优先级 5: 常规满血空闲预读打地鼠
    if C.enablePreCast and spellKey == "" and not isMoving() then
        if tank1Unit ~= "" and beaconOfLightBuffFromPlayerUnit ~= tank1Unit then
            unitToCast = tank1Unit
            spellKey = C.enableFlashOfLight and SKey.FOL or SKey.HL
        elseif tank2Unit ~= "" and beaconOfLightBuffFromPlayerUnit ~= tank2Unit then
            unitToCast = tank2Unit
            spellKey = C.enableFlashOfLight and SKey.FOL or SKey.HL
        elseif tank3Unit ~= "" and beaconOfLightBuffFromPlayerUnit ~= tank3Unit then
            unitToCast = tank3Unit
            spellKey = C.enableFlashOfLight and SKey.FOL or SKey.HL
        elseif meleeUnit ~= "" and beaconOfLightBuffFromPlayerUnit ~= meleeUnit then
            unitToCast = meleeUnit
            spellKey = C.enableFlashOfLight and SKey.FOL or SKey.HL
        elseif selfInRaidUnit ~= "" and beaconOfLightBuffFromPlayerUnit ~= selfInRaidUnit then
            unitToCast = selfInRaidUnit
            spellKey = C.enableFlashOfLight and SKey.FOL or SKey.HL
        end
    end
    
    return doFinalCheck(unitToCast, spellKey)
end

local function callbackHealer()
    if select(2, UnitClass("player")) ~= "PALADIN" then
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