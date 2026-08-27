--[[
aura id: 竹井詩織里&斧王_奶萨
aura uid: Yg2taATA23K
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== trigger 1 自定义触发器 =====
function (event, ...)
    _G.ShioriShamanLastCastUnits = _G.ShioriShamanLastCastUnits or {
        LastCastCHUnitName = "",
        LastCastRiptideUnitName = "",
        CHGUID = "",
        RiptideGUID = ""
    }
    local t = _G.ShioriShamanLastCastUnits
    
    if event == "UNIT_SPELLCAST_SENT" then
        local unit, target, castGUID, spellID = ...
        if unit == "player" then
            -- 治疗链：55459 (包含迅捷瞬发的链子和读条链)
            if spellID == 55459 then
                t.LastCastCHUnitName = target
                t.CHGUID = castGUID 
                -- 激流：61295
            elseif spellID == 61295 then
                t.LastCastRiptideUnitName = target
                t.RiptideGUID = castGUID
            end
        end
        
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        local unit, castGUID, spellID = ...
        if unit == "player" then
            if t.CHGUID and castGUID == t.CHGUID then
                t.LastCastCHUnitName = ""
                t.CHGUID = nil
            elseif t.RiptideGUID and castGUID == t.RiptideGUID then
                t.LastCastRiptideUnitName = ""
                t.RiptideGUID = nil
            end
        end
    end
    
    return true
end
-- UNIT_SPELLCAST_SENT,UNIT_SPELLCAST_SUCCEEDED,UNIT_SPELLCAST_FAILED,UNIT_SPELLCAST_INTERRUPTED

-- ===== actions.init 自定义代码 =====
--[[
  奶萨 APL 
  贡献人：竹井詩織里&紧张的斧王
  固定宏动作：预展开 player/party/raid 单位，避免战斗中动态生成宏。
]]
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_RestorationShaman_WLK then return end APL_RestorationShaman_WLK = true
local S = {
    CH = 55459, -- 治疗链 (Chain Heal)
    ES = 49284, -- 大地之盾 (Earth Shield)
    RIPTIDE = 61301, -- 激流 (Riptide)
    NS = 16188 -- 自然迅捷 (Nature's Swiftness)
}
local SKey = {
    SWIFT_CH = "SWIFT_CH", -- 迅捷治疗链
    CH = "CH", -- 常规治疗链
    RIPTIDE = "RIPTIDE", -- 激流
    ES = "ES" -- 大地之盾
}
local C = {
    swiftHealthPercent = 35, -- 对应旧版 LeftToSwift：低于此血量触发迅捷链应急
    riptideHealthPercent = 80, -- 对应旧版 LeftToTorrent：激流血线
    chainHealHealthPercent = 95, -- 对应旧版 LeftToChanHeal：治疗链血线
    chainHealHealthAdd = 9000, -- 治疗链主目标预计治疗量
    riptideHealthAdd = 2500, -- 激流预计直接治疗量
    tankHealth = 40000, -- 坦克血量阈值
    healerSupport40Battleground = false,
    supportSpecialDebuff = false
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
_G.ShioriShamanLastCastUnits = _G.ShioriShamanLastCastUnits or {
    LastCastCHUnitName = "",
    LastCastRiptideUnitName = "",
    CHGUID = nil,
    RiptideGUID = nil
}
local spellNames = {}
spellNames.NS = spellName(S.NS, "自然迅捷")
spellNames.CH = spellName(S.CH, "治疗链")
spellNames.RIPTIDE = spellName(S.RIPTIDE, "激流")
spellNames.ES = spellName(S.ES, "大地之盾")
local units = {"player", "focus"}
for i = 1, 4 do
    table.insert(units, "party" .. i)
end
for i = 1, (C.healerSupport40Battleground and 40 or 25) do
    table.insert(units, "raid" .. i)
end
local initializedId = 8790000 -- 奶萨专属基准ID
local actionIds = {}
local actionList = {}
local function addUnitMacro(key, spellId, macroSpellName, unit, iconId)
    actionIds[key] = actionIds[key] or {}
    local id = initializedId + (#actionList + 1)
    actionIds[key][unit] = id
    
    local macroText = ""
    if key == SKey.SWIFT_CH then
        -- 迅捷链绑定宏
        macroText = "/cast " .. spellNames.NS .. "\\n/cast [@" .. unit .. ",help,nodead] " .. spellNames.CH
    else
        macroText = "/cast [@" .. unit .. ",help,nodead] " .. macroSpellName
    end
    table.insert(actionList, {id, "macro", macroText, iconId or GetSpellTexture(spellId)})
end
for _, unit in ipairs(units) do
    addUnitMacro(SKey.SWIFT_CH, S.CH, spellNames.CH, unit, GetSpellTexture(S.NS)) -- 用迅捷图标
    addUnitMacro(SKey.CH, S.CH, spellNames.CH, unit)
    addUnitMacro(SKey.RIPTIDE, S.RIPTIDE, spellNames.RIPTIDE, unit)
    addUnitMacro(SKey.ES, S.ES, spellNames.ES, unit)
end
actionIds.NOOP = initializedId + 200000
table.insert(actionList, {actionIds.NOOP, "macro", "/stopmacro", GetSpellTexture(51566)})
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
local function isMoving()
    return GetUnitSpeed("player") > 0
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
-- 计算考虑了治疗预读的真实血量缺口
local function calcUnitHealthDiff(unit, unitHealthMax)
    if not UnitExists(unit) then
        return 0
    end
    local unitHealthDiff = unitHealthMax - UnitHealth(unit)
    local unitName = UnitName(unit) or ""
    
    if _G.ShioriShamanLastCastUnits.LastCastCHUnitName ~= "" and
    (unit == _G.ShioriShamanLastCastUnits.LastCastCHUnitName or unitName ==
    _G.ShioriShamanLastCastUnits.LastCastCHUnitName) then
        unitHealthDiff = unitHealthDiff - C.chainHealHealthAdd
    end
    if _G.ShioriShamanLastCastUnits.LastCastRiptideUnitName ~= "" and
    (unit == _G.ShioriShamanLastCastUnits.LastCastRiptideUnitName or unitName ==
    _G.ShioriShamanLastCastUnits.LastCastRiptideUnitName) then
        unitHealthDiff = unitHealthDiff - C.riptideHealthAdd
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
            
            if inRange(unit, S.CH) then -- 这里使用任意40码治疗法术ID判定距离即可，例如次级波
                table.insert(inRangeUnitList, unit)
                unitMaxHpMap[unit] = unitHealthMax
                local adjustedDiff = calcUnitHealthDiff(unit, unitHealthMax)
                local adjustedHpPercent = (unitHealthMax - adjustedDiff) / unitHealthMax * 100
                unitHealthPercentMap[unit] = adjustedHpPercent
            end
            
        end
    end
    
    -- 追踪状态变量
    local lowestSwiftHpPercent = 100
    local lowestSwiftUnit = ""
    
    local lowestRiptideDebuffHpPercent = 100
    local lowestRiptideDebuffUnit = ""
    
    local lowestRiptideTankMoveHpPercent = 100
    local lowestRiptideTankMoveUnit = ""
    
    local lowestRiptidePartyHpPercent = 100
    local lowestRiptidePartyUnit = ""
    
    local lowestCHHpPercent = 100
    local lowestCHUnit = ""
    
    local playerESActive = false
    local inRangeFocusUnit = ""
    local potentialESTank = ""
    
    local swiftCanCast = spellReady(S.NS) or WA_GetUnitBuff("player", "自然迅捷") ~= nil
    local riptideCanCast = spellReady(S.RIPTIDE)
    
    -- 2. 状态机提取 (单次O(N)遍历)
    for _, unit in ipairs(inRangeUnitList) do
        local hpPercent = unitHealthPercentMap[unit]
        local maxHp = unitMaxHpMap[unit]
        local hasTOCDebuff = unitHasTOCDebuff(unit)
        
        -- 提取迅捷链目标
        if hpPercent < lowestSwiftHpPercent then
            lowestSwiftHpPercent = hpPercent
            lowestSwiftUnit = unit
        end
        
        -- 提取激流目标 (Debuff)
        if hasTOCDebuff and hpPercent < lowestRiptideDebuffHpPercent then
            lowestRiptideDebuffHpPercent = hpPercent
            lowestRiptideDebuffUnit = unit
        end
        
        -- 提取激流目标 (坦克或移动)
        local isTank = (maxHp > C.tankHealth and UnitIsUnit(unit, unit .. "targettarget"))
        if (isTank or isMoving()) and hpPercent < lowestRiptideTankMoveHpPercent then
            lowestRiptideTankMoveHpPercent = hpPercent
            lowestRiptideTankMoveUnit = unit
        end
        
        -- 提取激流目标 (小队/常规补漏)
        if isParty and hpPercent < lowestRiptidePartyHpPercent then
            lowestRiptidePartyHpPercent = hpPercent
            lowestRiptidePartyUnit = unit
        end
        
        -- 提取常规治疗链目标
        if hpPercent < lowestCHHpPercent then
            lowestCHHpPercent = hpPercent
            lowestCHUnit = unit
        end
        if hasBuff(unit, S.ES, "大地之盾", true) then
            playerESActive = true
        end
        
        -- 提取大地之盾需求 (通过真正的Buff检查)
        if UnitIsUnit(unit, "focus") then
            inRangeFocusUnit = unit
        end
        if isTank and potentialESTank == "" then
            potentialESTank = unit
        end
    end
    -- 3. 执行优先树 (严格还原老代码 NowSpellLevel 从 20 到 14 的排列顺序)
    -- Level 20: 迅捷治疗链应急
    if spellKey == "" and swiftCanCast and lowestSwiftHpPercent < C.swiftHealthPercent then
        unitToCast = lowestSwiftUnit
        spellKey = SKey.SWIFT_CH
    end
    
    -- Level 19 & 18: 大地之盾 -> 场上无地盾时，优先给焦点，其次给坦克
    if spellKey == "" and not playerESActive then
        if inRangeFocusUnit ~= "" then
            unitToCast = inRangeFocusUnit
            spellKey = SKey.ES
        elseif potentialESTank ~= "" then
            unitToCast = potentialESTank
            spellKey = SKey.ES
        end
    end
    
    -- Level 17: 激流 -> TOC 危险Debuff
    if spellKey == "" and riptideCanCast and lowestRiptideDebuffUnit ~= "" and lowestRiptideDebuffHpPercent <
    C.riptideHealthPercent then
        unitToCast = lowestRiptideDebuffUnit
        spellKey = SKey.RIPTIDE
    end
    
    -- Level 16: 激流 -> 坦克 或 移动战保命
    if spellKey == "" and riptideCanCast and lowestRiptideTankMoveUnit ~= "" and lowestRiptideTankMoveHpPercent <
    C.riptideHealthPercent then
        unitToCast = lowestRiptideTankMoveUnit
        spellKey = SKey.RIPTIDE
    end
    
    -- Level 15: 激流 -> 小队模式下的保底补漏
    if spellKey == "" and riptideCanCast and isParty and lowestRiptidePartyUnit ~= "" and lowestRiptidePartyHpPercent <
    C.riptideHealthPercent then
        unitToCast = lowestRiptidePartyUnit
        spellKey = SKey.RIPTIDE
    end
    
    -- Level 14: 治疗链 -> 常规大团地鼠填充
    if spellKey == "" and lowestCHUnit ~= "" and lowestCHHpPercent < C.chainHealHealthPercent and not isMoving() then
        unitToCast = lowestCHUnit
        spellKey = SKey.CH
    end
    
    if unitToCast == "" or spellKey == "" then
        return action("NOOP")
    end
    
    return action(spellKey, unitToCast)
end
local function callbackHealer()
    if select(2, UnitClass("player")) ~= "SHAMAN" then
        return action("NOOP")
    end
    local isParty = false
    if not IsInGroup() then
        isParty = true
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
aura_env.APLName = "竹井&斧王奶萨"

-- ===== actions.init 加载时自定义代码 =====
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC or not VF_registerAPL then
    return
end
VF_registerAPL(aura_env)