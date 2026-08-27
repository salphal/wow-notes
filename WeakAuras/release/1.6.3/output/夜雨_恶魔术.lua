--[[
aura id: 夜雨_恶魔术
aura uid: rrz1unREfYr
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
工具人恶魔术
贡献人：时光4-夜雨
简化：哀冬
版本：1.0
适配时光服的恶术士，支持自由开关及BOSS战自动爆发（恶魔变形+种族技能+饰品+手套+速度药水）；仿猫德的AOE循环模式（手动打 1-2 个种子，命中 3 次后自动进入 AOE 循环）；支持变形自动冲锋/法阵传回（需战前施放法阵）；支持焦点和鼠标指向1级暗影箭偷灭杀与双目标DOT。 
]]--
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_YEYU_DEMONOLOGY_BRANCH then return end APL_YEYU_DEMONOLOGY_BRANCH = true
local config = aura_env.config or {}
local function getSmartAOECount()
    local count = 0
    local counted = {}
    for i = 1, 40 do
        local u = "nameplate" .. i
        if UnitExists(u) and UnitCanAttack("player", u) and not UnitIsDead(u) then
            if WeakAuras.CheckRange(u, 30, "<=") then
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
-- 禁止冲锋法阵名单
local ChargeBlacklist = {
    ["奥"] = true,
    ["拉格纳罗斯"] = true,
    ["加顿男爵"] = true,
    ["塔迪乌斯"] = true,
    ["鱼斯拉"] = true,
    ["萨菲隆"] = true,
    ["辛达苟萨"] = true,
    ["奥妮克希亚"] = true,
    --["海里昂"] = true,
    --["菲米斯"] = true,
    ["科隆加恩"] = true,
}
-- 智能AOE
local intoSmartAOE = false
local SeedHitCount = 0
local function onCLEUEvent(event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, srcGUID, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
        if srcGUID ~= WeakAuras.myGUID then return end
        if subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_MISSED" then
            if(spellID == 47834) then
                SeedHitCount = SeedHitCount + 1
                if (SeedHitCount > 2) then
                    intoSmartAOE = true
                else
                    intoSmartAOE = false
                end
            elseif ((spellID == 47809) or (spellID == 47813)) then
                intoSmartAOE = false
            end
        elseif subEvent == "SPELL_CAST_SUCCESS" and UnitAffectingCombat("player") then
            if(spellID == 47836) then
                SeedHitCount = 0
            elseif ((spellID == 47809) or (spellID == 47813)) then
                intoSmartAOE = false
            end
        end
    end
end
local Manager = CreateFrame("Frame")
if config.smartAOE then
    Manager:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    Manager:SetScript("OnEvent", function(self, e, ...) onCLEUEvent(e) end)
end
local ActionList = {
    {47809, "macro", "/cast 暗影箭\\n/petattack [combat]", GetSpellTexture("暗影箭")},
    {47838, "macro", "/cast 烧尽\\n/petattack [combat]", GetSpellTexture("烧尽")},
    {47825, "macro", "/cast 灵魂之火\\n/petattack [combat]", GetSpellTexture("灵魂之火")},
    {47813, "macro", "/cast 腐蚀术\\n/petattack [combat]", GetSpellTexture("腐蚀术")},
    {47811, "macro", "/cast 献祭\\n/petattack [combat]", GetSpellTexture("献祭")},
    {47836, "macro", "/cast 腐蚀之种\\n/petattack [combat]", GetSpellTexture("腐蚀之种")},
    {61290, "macro", "/cast 暗影烈焰\\n/petattack [combat]", GetSpellTexture("暗影烈焰")},
    {47241, "macro", "/cqs\\n/cast 狮心(种族特长)\\n/cast 血性狂怒(种族特长)\\n/use 10\\n/use 13\\n/use 14\\n/use 速度药水\\n/cast 恶魔变形\\n/cqs", GetSpellTexture("恶魔变形")},
    {6603, "macro", "/targetenemy [dead][noharm]\\n/startattack\\n/petattack [combat]"},
    {-47813, "macro", "/cast [@focus] 腐蚀术", GetSpellTexture("腐蚀术")},
    {-47811, "macro", "/cast [@focus] 献祭", GetSpellTexture("献祭")},
    {-47809, "macro", "/cast [@focus] 暗影箭", GetSpellTexture("暗影箭")},
    {999006, "macro", "/cast [@mouseover] 暗影箭(等级 1)", GetSpellTexture("暗影箭")},
    {50589, "macro", "/cast 献祭光环\\n/use 通用热力工程炸药\\n/use [@player] 萨隆邪铁炸弹", GetSpellTexture("献祭光环")},
    {47193, "spell", "恶魔增效"},
    {57946, "spell", "生命分流"},
    {47867, "spell", "厄运诅咒"},
    {54785, "spell", "恶魔冲锋"},
    {48020, "spell", "恶魔法阵：传送"},
    {48018, "spell", "恶魔法阵：召唤"},
    {30146, "spell", "召唤恶魔卫士"},
    {47893, "spell", "邪甲术"},
}
-- 状态
local lastImmCastTime = 0
local lastSB1CastTime = 0
local afterCharge = false
local lastreason = ""
local function recommend(spellId, reason)
    if lastreason ~= reason then
        --print(reason)
        lastreason = reason
    end
    return spellId
end
-- APL主逻辑
local function APLCallback()
    local CastWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
    local isCombat = UnitAffectingCombat("player")
    local isMoving = GetUnitSpeed("player") > 0
    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player", 0) * 100
    local playerHP = UnitHealth("player") / (UnitHealthMax("player") > 0 and UnitHealthMax("player") or 1) * 100
    local GCD = VF_getSpellCD(61304)
    local now = GetTime()
    local castingSpellName, _, _, _, endTimeMs, _, _, _, castingSpellID = UnitCastingInfo("player")
    if castingSpellName ~= nil then 
        GCD = math.max((endTimeMs/1000 - now), GCD)
    end
    local targetDeadTime = VF_getTargetDeadTime()
    local isBoss = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
    
    local hasFocus = UnitExists("focus") and UnitCanAttack("player", "focus") and not UnitIsDead("focus") and UnitGUID("focus") ~= UnitGUID("target")
    
    local LTDur = math.max(0, VF_getBuff("player", 63321, "HELPFUL|PLAYER") - GCD)
    local CorrDur = math.max(0, VF_getDebuff("target", 47813, "HARMFUL|PLAYER") - GCD)
    local ImmDur  = math.max(0, VF_getDebuff("target", 47811, "HARMFUL|PLAYER") - GCD)
    local FocusCorrDur = hasFocus and math.max(0, VF_getDebuff("focus", 47813, "HARMFUL|PLAYER") - GCD) or 999
    local FocusImmDur  = hasFocus and math.max(0, VF_getDebuff("focus", 47811, "HARMFUL|PLAYER") - GCD) or 999
    
    local MetaCD        = math.max(0, VF_getSpellCD(47241) - GCD)
    local MetaBuffDur   = math.max(0, VF_getBuff("player", 47241, "HELPFUL|PLAYER") - GCD)
    local EmpowermentCD = math.max(0, VF_getSpellCD(47193) - GCD)
    local CoDCD         = math.max(0, VF_getSpellCD(47867) - GCD)
    local SFflameCD     = math.max(0, VF_getSpellCD(61290) - GCD)
    local isSFRange     = WeakAuras.CheckRange("target", 10, "<=") or false
    local ChargeCD      = math.max(0, (VF_getSpellCD(54785) or 999) - GCD)
    local AuraCD        = math.max(0, (VF_getSpellCD(50589) or 999) - GCD)
    local DCSummonDur = math.max(0, VF_getBuff("player", 48018, "HELPFUL|PLAYER") - GCD)
    local DCTeleportCD = math.max(0, (VF_getSpellCD(48020) or 999) - GCD)
    local _, MoltenCoreCount = VF_getBuff("player", 71165, "HELPFUL|PLAYER")
    local hasDecimation   = (math.max(0, VF_getBuff("player", 63167, "HELPFUL|PLAYER") - GCD) > 0)
    local DecimationSoon = false
    local ImmCT  = select(4, GetSpellInfo("献祭")) / 1000
    
    if castingSpellName == "献祭" then
        ImmDur = 15
        FocusImmDur = 15
        lastImmCastTime = now + ImmCT
    elseif castingSpellName == "暗影箭" then
        isCombat = true
        if castingSpellID == 686 then
            lastSB1CastTime = now
            DecimationSoon = true
        end
    elseif castingSpellName == "灵魂之火" or castingSpellName == "烧尽" then
        if MoltenCoreCount and MoltenCoreCount > 0 then
            MoltenCoreCount = MoltenCoreCount - 1
        end
    elseif castingSpellName == "腐蚀之种" then
        SeedHitCount = 0
    end
    
    if (now - lastImmCastTime) < 0.3 then ImmDur = 15 FocusImmDur = 15 else lastImmCastTime = 0 end --防止重复献祭
    if (now - lastSB1CastTime) > 3 then DecimationSoon = false lastSB1CastTime = 0 end --防止重复骗灭杀
    -- 非战斗
    if not isCombat or not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDead("target") then
        if not isCombat and not IsMounted() and (not UnitExists("pet") or UnitIsDead("pet")) then
            return recommend(30146, "召唤宠物")
        end
        if VF_getBuff("player", 47893, "HELPFUL|PLAYER") < 600 then
            return recommend(47893, "脱战补邪甲术")
        end
        if config.autoMetaUtility and not isMoving and DCSummonDur < 300 and not isSFRange then
            return recommend(48018, "脱战布局法阵")
        end
        if LTDur <= 5 or manaPercent <= 85 then
            return recommend(57946, "脱战分流")
        end
        return recommend(47809, "脱战暗影箭")
    end
    -- 移动优先技能
    if isMoving then
        if SFflameCD <= CastWindow and isSFRange then
            return recommend(61290, "移动暗影烈焰")
        end
        if playerHP > 50 and (manaPercent <= 80 or LTDur <= 10) and targetDeadTime > 5 then
            return recommend(57946, "移动分流")
        end
    end
    
    -- 分流
    if (LTDur <= 3 or manaPercent <= 15) and targetDeadTime > 10 then
        return recommend(57946, "分流")
    end
    
    -- 变身期间
    if MetaBuffDur > 0 then
        if config.autoMetaUtility and not ChargeBlacklist[UnitName("target")] and ChargeCD <= CastWindow then
            if (IsSpellInRange("恶魔冲锋", "target") == 1) then
                afterCharge = true
                return recommend(54785, "恶魔冲锋")
            end
        end
        if afterCharge and AuraCD <= CastWindow then
            return recommend(50589, "献祭光环")
        end
    end
    -- 变身结束，法阵归位
    if config.autoMetaUtility and not ChargeBlacklist[UnitName("target")] and DCSummonDur > 0 and MetaBuffDur <= 0 and afterCharge then
        if DCTeleportCD <= CastWindow and isSFRange then
            return recommend(48020, "变身结束法阵传回")
        end
        if DCTeleportCD > 10 then
            afterCharge = false
        end
    end
    -- 爆发
    if config.autoBurst and isBoss then
        if MetaCD <= CastWindow and (targetDeadTime > 30 or targetDeadTime == 0 or not targetDeadTime) and not isMoving then
            return recommend(47241, "单体爆发变形")
        end
        if EmpowermentCD <= CastWindow then
            return recommend(47193, "恶魔增效")
        end
    end
    -- AOE
    if intoSmartAOE and not isMoving then
        return recommend(47836, "AOE种子")
    end
    -- 主目标DOT
    if CorrDur <= CastWindow and targetDeadTime > 10 then
        return recommend(47813, "主目标补腐蚀")
    end
    if ImmDur + 0.05 < ImmCT and not isMoving and targetDeadTime > 10 then
        return recommend(47811, "主目标补献祭")
    end
    if isBoss and targetDeadTime > 70 and CoDCD <= CastWindow then
        return recommend(47867, "厄运诅咒")
    end
    -- 多目标&偷灭杀
    local targetHPPercent = UnitHealth("target") / (UnitHealthMax("target") > 0 and UnitHealthMax("target") or 1) * 100
    if hasFocus then
        local fhp = UnitHealth("focus") / (UnitHealthMax("focus") > 0 and UnitHealthMax("focus") or 1) * 100
        if fhp > 8 and FocusCorrDur <= 0 then
            return recommend(-47813, "焦点副目标腐蚀")
        end
        if fhp > 8 and not isMoving and FocusImmDur <= 0 then
            return recommend(-47811, "焦点副目标献祭")
        end
        if config.smartDecimation and targetHPPercent > 35 and not hasDecimation and not DecimationSoon
            and fhp <= 35 and IsSpellInRange("暗影箭", "focus") == 1 then
                return recommend(-47809, "焦点暗影箭偷灭杀")
        end
    end
    if config.smartDecimation and targetHPPercent > 35 and not hasDecimation and not DecimationSoon
        and UnitExists("mouseover") and UnitCanAttack("player", "mouseover") and not UnitIsDead("mouseover") and UnitGUID("mouseover") ~= UnitGUID("target") then
        local mhp = UnitHealth("mouseover") / (UnitHealthMax("mouseover") > 0 and UnitHealthMax("mouseover") or 1) * 100
        if mhp <= 35 and IsSpellInRange("暗影箭", "mouseover") == 1 then
            return recommend(999006, "鼠标指向偷灭杀")
        end
    end
    -- 灭杀触发后灵魂火
    if hasDecimation and not isMoving then
        return recommend(47825, "灭杀灵魂火")
    end
    if MoltenCoreCount > 0 then
        return recommend(47838, "熔火之心烧尽")
    end
    return recommend(47809, "兜底暗影箭")
end
aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback
aura_env.APLName = "夜雨恶魔术"

-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)