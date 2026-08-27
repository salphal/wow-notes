--[[
aura id: 阿尔法_双光环DKT
aura uid: a1phaDualAuraDk
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
  双光环DKT APL - 泰坦重铸时光服
  作者：阿尔法
  双光环=冰霜灵气(攻速光环)+血系仇恨循环
  仇恨优先：开怪6冰触 + 心打卡CD + 凋零/血沸AOE + 灵打自保
]]
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_DUALAURA_DK_ALPHA then return end APL_DUALAURA_DK_ALPHA = true
local WAParam = aura_env
local S = {
    FrostPresence = 48263,       -- 冰霜灵气（双光环核心）
    IcyTouch = 49909,            -- 冰冷触摸
    PlagueStrike = 49921,        -- 暗影打击
    HeartStrike = 55262,         -- 心脏打击
    DeathStrike = 49924,         -- 灵界打击
    BloodBoil = 49941,           -- 血液沸腾
    DeathAndDecay = 49938,       -- 枯萎凋零
    Pestilence = 50842,          -- 传染
    DeathCoil = 49895,           -- 凋零缠绕
    BloodTap = 45529,            -- 活力分流
    RuneWeapon = 47568,          -- 符文武器增效
    HornOfWinter = 57623,        -- 寒冬号角
    BoneShield = 49222,          -- 白骨之盾
    VampiricBlood = 55233,       -- 吸血鬼之血
    IceboundFortitude = 48792,   -- 冰封之韧
    DeathGrip = 49576,           -- 死亡之握
    MindFreeze = 47528,          -- 心灵冰冻
    DarkCommand = 56222,         -- 黑暗命令（嘲讽）
    GCDProbe = 61304,
}
-- BUFF/DEBUFF
local FrostFeverID = 55095     -- 冰霜热疫
local BloodPlagueID = 55078    -- 血之疫病
local HornOfWinterBuffID = 57623  -- 寒冬号角BUFF
local BoneShieldBuffID = 49222    -- 白骨之盾BUFF
local VampiricBloodBuffID = 55233 -- 吸血鬼之血BUFF
-- 起手序列状态（开怪6冰触仇恨爆发）
local openerStep = 0
local openerDone = false
local openerSQ = {
    S.IcyTouch, S.IcyTouch, S.BloodTap, S.IcyTouch,
    S.PlagueStrike, S.BloodBoil, S.DeathAndDecay, S.RuneWeapon,
    S.IcyTouch
}
-- 辅助函数
local function getDebuffRemain(unit, spellId)
    return math.max(0, VF_getDebuff(unit, spellId, "HARMFUL|PLAYER") or 0)
end
-- 自身HP百分比（自保）
local function getSelfHpPercent()
    local m = UnitHealthMax("player")
    if m == 0 then return 100 end
    return (UnitHealth("player") / m) * 100
end
-- AOE计数：周围10码内敌人数量
local function getAOECount()
    local count = 0
    local counted = {}
    for i = 1, 40 do
        local unitid = "nameplate" .. i
        if UnitExists(unitid) and UnitCanAttack("player", unitid) and not UnitIsDead(unitid) then
            if WeakAuras.CheckRange(unitid, 10, "<=") then
                local guid = UnitGUID(unitid)
                if guid and not counted[guid] then
                    counted[guid] = true
                    count = count + 1
                end
            end
        end
    end
    return count
end
--确认疾病雕文
local function hasPestilenceGlyph()
    for i = 1, 6 do
        local _, _, _, glyphID = GetGlyphSocketInfo(i)
        if glyphID == 1287384 then
            return true
        end
    end
    return false
end
local function TargetIsCasting()
    local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and not notInterruptible then
        return true
    end
    local channelName, _, _, _, _, _, notInterruptible2 = UnitChannelInfo("target")
    if channelName and not notInterruptible2 then
        return true
    end
    return false
end
-- 战斗日志监听：推进起手序列
local function onCLEUEvent()
    local _, subEvent, _, srcGUID, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    if srcGUID ~= UnitGUID("player") then return end
    if subEvent == "SPELL_CAST_SUCCESS" then
        if not openerDone and openerStep >= 1 then
            if openerStep <= #openerSQ and spellID == openerSQ[openerStep] then
                openerStep = openerStep + 1
                if openerStep > #openerSQ then
                    openerDone = true
                end
            end
        end
    end
end
local Manager = CreateFrame("Frame", "DualAuraDKAPLManager", UIParent)
Manager:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
Manager:SetScript("OnEvent", function(_, e)
        if e == "COMBAT_LOG_EVENT_UNFILTERED" then
            onCLEUEvent()
        end
end)
-- ActionList（主技能宏绑定符文打击）
local ActionList = {
    { S.IcyTouch, "macro", "/cast 冰冷触摸\\n/cast !符文打击", GetSpellTexture("冰冷触摸") },
    { S.PlagueStrike, "macro", "/cast 暗影打击\\n/cast !符文打击", GetSpellTexture("暗影打击") },
    { S.HeartStrike, "macro", "/cast 心脏打击\\n/cast !符文打击", GetSpellTexture("心脏打击") },
    { S.DeathStrike, "macro", "/cast 灵界打击\\n/cast !符文打击", GetSpellTexture("灵界打击") },
    { S.BloodBoil, "macro", "/cast 血液沸腾\\n/cast !符文打击", GetSpellTexture("血液沸腾") },
    { S.DeathAndDecay, "macro", "/cast [@player] 枯萎凋零\\n/cast !符文打击", GetSpellTexture("枯萎凋零") },
    { S.Pestilence, "macro", "/cast 传染\\n/cast !符文打击", GetSpellTexture("传染") },
    { S.DeathCoil, "macro", "/cast 凋零缠绕\\n/cast !符文打击", GetSpellTexture("凋零缠绕") },
    { S.BloodTap, "spell", "活力分流" },
    { S.RuneWeapon, "spell", "符文武器增效" },
    { S.HornOfWinter, "macro", "/cast 寒冬号角\\n/cast !符文打击", GetSpellTexture("寒冬号角") },
    { S.BoneShield, "spell", "白骨之盾" },
    { S.VampiricBlood, "spell", "吸血鬼之血" },
    { S.IceboundFortitude, "spell", "冰封之韧" },
    { S.DeathGrip, "spell", "死亡之握" },
    { S.MindFreeze, "spell", "心灵冰冻" },
    { S.DarkCommand, "spell", "黑暗命令" },
    { S.FrostPresence, "spell", "冰霜灵气" },
    { 6603, "macro", "/startattack\\n/cast !符文打击" },
}
local function APLCallback_DualAuraDK()
    local win = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and not UnitIsDeadOrGhost("target") and UnitCanAttack("player", "target")
    local gcdRemain = VF_getSpellCD(S.GCDProbe) or 0
    local SelfHp = getSelfHpPercent()
    local function cd(id)
        return math.max(0, (VF_getSpellCD(id) or 999) - gcdRemain)
    end

    -- 脱战准备：冰霜灵气（双光环核心）+ 骨盾
    if not inCombat then
        openerStep = 0
        openerDone = false
        if GetShapeshiftForm() ~= 2 then
            return S.FrostPresence
        end
        if cd(S.BoneShield) <= win and (VF_getBuff("player", BoneShieldBuffID, "HELPFUL") or 0) <= 60 then
            return S.BoneShield
        end
        if hasTarget then
            return S.IcyTouch
        end
        return 6603
    end

    if not hasTarget then return 6603 end

    local runicPower = UnitPower("player", 6) or 0
    local isBoss = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
    local aoeCount = getAOECount()

    -- 双病剩余
    local ffRem = getDebuffRemain("target", FrostFeverID)
    local bpRem = getDebuffRemain("target", BloodPlagueID)
    local bothDiseases = ffRem > 0 and bpRem > 0

    -- 枯萎凋零CD剩余（真实CD）
    local dndStart, dndDuration = GetSpellCooldown(S.DeathAndDecay)
    local dndRemain = 0
    if dndStart and dndDuration and dndDuration > 0 then
        dndRemain = dndStart + dndDuration - GetTime()
        if dndRemain < 0 then dndRemain = 0 end
    end

    -- 自保（优先级最高）
    if SelfHp < 40 and cd(S.VampiricBlood) <= win then
        return S.VampiricBlood
    end
    if SelfHp < 20 and cd(S.IceboundFortitude) <= win then
        return S.IceboundFortitude
    end
    -- 灵打自保：血<60% && 有血符文/死符文 && 双病存在
    if SelfHp < 60 and bothDiseases and cd(S.DeathStrike) <= win then
        return S.DeathStrike
    end

    -- 打断
    if WAParam.config.autoInterrupt and TargetIsCasting() and cd(S.MindFreeze) <= win then
        return S.MindFreeze
    end

    -- 嘲讽：目标不攻击自己时
    if WAParam.config.autoTaunt and cd(S.DarkCommand) <= win then
        if UnitExists("target") and not UnitIsUnit("targettarget", "player") then
            return S.DarkCommand
        end
    end

    -- ===== 一、BOSS起手固定序列（需要冰脸+目标为BOSS）=====
    local isFrostPresence = GetShapeshiftForm() == 2  -- 2 = 冰霜灵气
    if isBoss and isFrostPresence and not openerDone then
        if openerStep == 0 then
            openerStep = 1
        end
        if openerStep <= #openerSQ then
            local spellID = openerSQ[openerStep]
            if cd(spellID) <= win then
                return spellID
            end
            openerStep = openerStep + 1
            if openerStep > #openerSQ then
                openerDone = true
            end
        else
            openerDone = true
        end
    end

    -- ===== 二、传染 =====
    local needPest = false
    -- AOE场景传染（不受雕文限制）
    if aoeCount >= 2 and bothDiseases then
        for i = 1, 40 do
            local unitid = "nameplate" .. i
            if UnitExists(unitid) and UnitCanAttack("player", unitid) and not UnitIsDead(unitid) then
                if WeakAuras.CheckRange(unitid, 10, "<=") then
                    local ff = getDebuffRemain(unitid, FrostFeverID)
                    local bp = getDebuffRemain(unitid, BloodPlagueID)
                    if ff <= 4 or bp <= 4 then
                        needPest = true
                        break
                    end
                end
            end
        end
    end
    -- 单体传染（需要疾病雕文）
    if not needPest and bothDiseases and (ffRem < 3 or bpRem < 3) and hasPestilenceGlyph() then
        needPest = true
    end
    if needPest and cd(S.Pestilence) <= win then
        return S.Pestilence
    end

    -- ===== 三、枯萎凋零：AOE或Boss常规 =====
    if cd(S.DeathAndDecay) <= win and (aoeCount >= 2 or isBoss) then
        return S.DeathAndDecay
    end

    -- ===== 四、常规循环 =====
    -- 4.1 补双病（缺失时置顶）
    if not bothDiseases then
        if ffRem <= 0 and cd(S.IcyTouch) <= win then
            return S.IcyTouch
        end
        if bpRem <= 0 and cd(S.PlagueStrike) <= win then
            return S.PlagueStrike
        end
    end

    -- 4.2 心打/AOE血沸：双病齐全 + 双病剩余>=4秒 + CD就绪
    if bothDiseases and ffRem >= 4 and bpRem >= 4 then
        if aoeCount >= 3 then
            if cd(S.BloodBoil) <= win then
                return S.BloodBoil
            end
        else
            if cd(S.HeartStrike) <= win then
                return S.HeartStrike
            end
        end
    end

    -- 4.3 心打/血沸CD中 + 血符文充足 → 灵打
    if bothDiseases and ffRem >= 4 and bpRem >= 4 then
        if cd(S.DeathStrike) <= win then
            return S.DeathStrike
        end
    end

    -- ===== 五、凋零缠绕：能量高 + 凋零CD中 =====
    if dndRemain > 0 then
        if dndRemain >= 2 and cd(S.DeathCoil) <= win and runicPower >= 60 then
            return S.DeathCoil
        end
    end

    -- ===== 六、填充技能 =====
    -- 血沸
    if cd(S.BloodBoil) <= win then
        return S.BloodBoil
    end

    -- 寒冬号角：无技能可用时 + CD好 + 无号角BUFF + 双病中任一病剩余>2秒
    local hasHornBuff = (VF_getBuff("player", HornOfWinterBuffID, "HELPFUL|PLAYER") or 0) > 0
    if cd(S.HornOfWinter) <= win and not hasHornBuff and (ffRem > 2 or bpRem > 2) then
        return S.HornOfWinter
    end

    -- 死亡之握（拉远程怪，应急）
    if WAParam.config.autoDeathGrip and cd(S.DeathGrip) <= win then
        if UnitExists("target") and not UnitIsUnit("targettarget", "player")
            and (UnitIsPlayer("target") or UnitLevel("target") ~= -1) then
            return S.DeathGrip
        end
    end

    return 6603
end
aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_DualAuraDK
aura_env.APLName = "阿尔法双光环"

-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)
