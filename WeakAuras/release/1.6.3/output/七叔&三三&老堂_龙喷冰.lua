--[[
aura id: 七叔&三三&老堂_龙喷冰
aura uid: sLtrWI07vGx
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
多个版本融合，支持血冰、邪冰、对应的传染雕文与否
贡献人：网易DD 宗政白正（Sevenuncle）
贡献人：网易DD 时光服三三
贡献人：B站 老堂（时光1-堂吉诃德）
代码整合：念秋
]]
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_FROSTDK_TITAN_NIANQIU then return end APL_FROSTDK_TITAN_NIANQIU = true
local WAParam = aura_env
WAParam.config = WAParam.config or {}
local hasNecrosis = false--是否点出骨疽，判断冰邪/冰血天赋
local hasDiseaseGlyph = true--是否插了疾病雕文
local hasFSGlyph = true--是否插了冰打雕文
local DiseaseDurMax = 15--最大疾病时长，按照蔓延天赋修改
local LastAOETime = 0--最近一次进入AOE状态的时间
local LastPestilenceTime = 0--最近一次使用传染的时间
local ID = {
    Obliterate = 51425,
    FrostStrike = 55268,
    HowlingBlast = 51411,
    BloodStrike = 49930,
    IcyTouch = 49909,
    PlagueStrike = 49921,
    Pestilence = 50842,
    UnbreakArmor = 51271,
    BloodTap = 45529,
    WinterHorn = 57623,
    FrostWyrm = 1314847,
    EmpowerRune = 47568,
    RaiseDead = 46584,
    BloodPres = 48266,
    MindFreeze = 47528,
    DeathDecay = 49938,
    KillingMachine = 51124,--杀戮机器
    FreezingFog = 59052,--白霜
    FrostFever = 55095,--冰病
    BloodPlague = 55078,--暗病
}
-- ==================== ActionList ====================
local ActionList = {
    {ID.Obliterate, "macro", "/cast [nochanneling] 湮没\\n/petattack [combat]", GetSpellTexture("湮没")},
    {ID.FrostStrike, "macro", "/cast [nochanneling] 冰霜打击\\n/petattack [combat]", GetSpellTexture("冰霜打击")},
    {ID.BloodStrike, "macro", "/cast [nochanneling] 鲜血打击\\n/petattack [combat]", GetSpellTexture("鲜血打击")},
    {ID.IcyTouch, "macro", "/cast [nochanneling] 冰冷触摸\\n/petattack [combat]", GetSpellTexture("冰冷触摸")},
    {ID.PlagueStrike, "macro", "/cast [nochanneling] 暗影打击\\n/petattack [combat]", GetSpellTexture("暗影打击")},
    {ID.Pestilence, "spell", "传染"},
    {ID.HowlingBlast, "spell", "凛风冲击"},
    {ID.UnbreakArmor, "macro", "/cqs\\n/cast 石像形态(种族特长)\\n/cast 狂暴(种族特长)\\n/cast 血性狂怒(种族特长)\\n/cast 狮心(种族特长)\\n/use 13\\n/use 14\\n/use 10\\n/cast 铜墙铁壁\\n/cqs", GetSpellTexture("铜墙铁壁")},
    {ID.BloodTap, "spell", "活力分流"},
    {ID.WinterHorn, "spell", "寒冬号角"},
    {ID.FrostWyrm, "spell", "死从天降"},
    {ID.EmpowerRune, "spell", "符文武器增效"},
    {ID.RaiseDead, "spell", "亡者复生"},
    {ID.BloodPres, "spell", "鲜血灵气"},
    {ID.MindFreeze, "spell", "心灵冰冻"},
    {ID.DeathDecay, "macro", "/cast [@player] 枯萎凋零", GetSpellTexture("枯萎凋零")},
    {6603, "macro", "/startattack\\n/petattack [combat]"},
}
local function getRuneCD(index)
    local start, dur, isReady = GetRuneCooldown(index)
    if isReady then
        return 0
    elseif start > 0 then
        return math.max(0,(start + dur - GetTime()))
    end
    return 1
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
-- ==================== 主回调函数 ====================
local function APLCallback()
    local now = GetTime()
    local CastWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400) / 1000
    local GCD = VF_getSpellCD(61304)
    local RunicPowerMax = UnitPowerMax("player", 6)
    local RunicPower = UnitPower("player", 6) or 0
    local FSRunicPower = hasFSGlyph and 32 or 40
    local AOECount = getNearbyCount()
    local inBossFight = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
    local TargetDeadTime = VF_getTargetDeadTime()
    local inMeleeRange = (IsSpellInRange(GetSpellInfo(49930), "target") == 1)
    --local hasBloodlust = ((VF_getBuff("player", 2825, "HELPFUL") > 0) or (VF_getBuff("player", 32182, "HELPFUL") > 0))
    
    local IcyTouchCD = math.max(0, (VF_getSpellCD(ID.IcyTouch) - GCD))
    local PlagueStrikeCD = math.max(0, (VF_getSpellCD(ID.PlagueStrike) - GCD))
    local BloodStrikeCD = math.max(0, (VF_getSpellCD(ID.BloodStrike) - GCD))
    local ObliterateCD = math.max(0, (VF_getSpellCD(ID.Obliterate) - GCD))
    local HowlingBlastCD = math.max(0, (VF_getSpellCD(ID.HowlingBlast) - GCD))
    local PestilenceCD = math.max(0, (VF_getSpellCD(ID.Pestilence) - GCD))
    local UnbreakArmorCD = math.max(0, (VF_getSpellCD(ID.UnbreakArmor) - GCD))
    local RaiseDeadCD = math.max(0, (VF_getSpellCD(ID.RaiseDead) - GCD))
    local WinterHornCD = math.max(0, (VF_getSpellCD(ID.WinterHorn) - GCD))
    local DeathDecayCD = math.max(0, (VF_getSpellCD(ID.DeathDecay) - GCD))
    local FrostWyrmCD = math.max(0, (VF_getSpellCD(ID.FrostWyrm) - GCD))
    local BloodTapCD = VF_getSpellCD(ID.BloodTap)
    local EmpowerRuneCD = VF_getSpellCD(ID.EmpowerRune)
    
    local KillingMachineDur = math.max(0, (VF_getBuff("player", ID.KillingMachine , "HELPFUL|PLAYER") - GCD))
    local FreezingFogDur = math.max(0, (VF_getBuff("player", ID.FreezingFog, "HELPFUL|PLAYER") - GCD))
    local WinterHornDur = math.max(0, (VF_getBuff("player", ID.WinterHorn, "HELPFUL") - GCD))
    local UnbreakArmorDur = math.max(0, (VF_getBuff("player", ID.UnbreakArmor, "HELPFUL|PLAYER") - GCD))
    local FrostFeverDur = math.max(0, (VF_getDebuff("target", ID.FrostFever, "HARMFUL|PLAYER") - GCD))
    local BloodPlagueDur = math.max(0, (VF_getDebuff("target", ID.BloodPlague, "HARMFUL|PLAYER") - GCD))
    local DiseaseDur = math.min(FrostFeverDur, BloodPlagueDur)
    
    local PestilenceThreshold = hasNecrosis and 3 or 5 --根据当前天赋对应的传染刷新阈值，血冰阈值5秒，邪冰阈值3秒
    local isFrostWyrmSoon = WAParam.config.autoBurst and (UnbreakArmorDur > 0 or UnbreakArmorCD < 3) and FrostWyrmCD <= 3
    
    --符文计数
    local BRune, FRune, URune, DRune = 0, 0, 0, 0
    for i = 1, 6 do
        if math.max(0, getRuneCD(i)-GCD) <= 0 then
            local RunType = GetRuneType(i)
            if RunType == 1 then BRune = BRune + 1
            elseif RunType == 2 then FRune = FRune + 1
            elseif RunType == 3 then URune = URune + 1
            elseif RunType == 4 then DRune = DRune + 1
            end
        end
    end
    --战斗外/空闲状态
    if not UnitAffectingCombat("player") then
        if GetShapeshiftForm() ~= 1 then
            return ID.BloodPres
        end
        if WinterHornDur <= 0 and WinterHornCD <= CastWindow then
            return ID.WinterHorn
        end
        if FrostFeverDur <= 0 and IcyTouchCD <= CastWindow then
            return ID.IcyTouch
        end
        return 6603
    end
    --无效目标
    if not UnitExists("target") or UnitIsDeadOrGhost("target") or not UnitCanAttack("player", "target") then
        return 6603
    end
     
    --打断
    if WAParam.config.autoInterrupt and TargetIsCasting() and VF_getSpellCD(ID.MindFreeze) <= 0 then
        return ID.MindFreeze
    end
    
    --补病（断病立刻补，最高优先级）
    if FrostFeverDur <= 0 and IcyTouchCD <= CastWindow then
        return ID.IcyTouch
    end
    if BloodPlagueDur <= 0 and PlagueStrikeCD <= CastWindow then
        return ID.PlagueStrike
    end
    
    --有疾病雕文时，用传染刷新
    if hasDiseaseGlyph and DiseaseDur > 0 and PestilenceCD <= CastWindow then
        --1、疾病即将到期必须传染
        if DiseaseDur <= PestilenceThreshold then
            return ID.Pestilence
        end
        --2、宽裕AOE条件主动刷新：疾病<8秒，血符文>=2，且10码范围内有其他敌人
        if DiseaseDur <= PestilenceThreshold+3 and BRune >= 2 and AOECount >= 2 then
            LastAOETime = now
            return ID.Pestilence
        end
    end
    
    --无疾病雕文时，用冰触/暗打补病
    if not hasDiseaseGlyph then
        if FrostFeverDur > 0 and FrostFeverDur < 3 and IcyTouchCD  <= CastWindow then
            return ID.IcyTouch
        end
        if BloodPlagueDur > 0 and BloodPlagueDur < 3 and PlagueStrikeCD <= CastWindow then
            return ID.PlagueStrike
        end
    end
    --BOSS战中高优先级爆发
    if WAParam.config.autoBurst and inBossFight and inMeleeRange then
        if UnbreakArmorCD <= CastWindow and DiseaseDur > PestilenceThreshold then
            return ID.UnbreakArmor
        end
        if UnbreakArmorDur > 0 and RunicPower >= 40 and FrostWyrmCD <= CastWindow then
            return ID.FrostWyrm
        end
    end
    --近战范围外有白霜就直接吹风打掉
    if not inMeleeRange then
        if FreezingFogDur > 0 and HowlingBlastCD <= CastWindow then
            return ID.HowlingBlast
        end
    end
    --能量临近溢出的冰打
    if RunicPower >= RunicPowerMax-20 and DiseaseDur > 0 then
        return ID.FrostStrike
    end
    --白霜如果迟迟等不到杀戮机器就先打掉吹风
    if HowlingBlastCD <= CastWindow and FreezingFogDur > 0 and FreezingFogDur <= 3 then
        return ID.HowlingBlast
    end
    --鲜血分流条件：
    --1、有疾病雕文且无血符文、疾病持续时间不足阈值
    --2、刚放完铜墙铁壁、有邪符文但是缺少冰符文的时候允许分流打湮没
    if BloodTapCD <= CastWindow and DRune <= 0
        and ((BRune <= 0 and hasDiseaseGlyph and DiseaseDur > 0 and DiseaseDur <= PestilenceThreshold)
            or (UnbreakArmorDur > 10 and UnbreakArmorCD > 50 and URune > 0 and FRune <= 0)) then
        return ID.BloodTap
    end
    --AOE/单体处理
    if AOECount >= 3 then
        --记录刚从单体进入AOE状态的时间，判断是否立即传染
        if LastAOETime == 0 and DiseaseDur > 1 and PestilenceCD <= CastWindow then
            LastAOETime = now
        end
        if LastAOETime > LastPestilenceTime then
            return ID.Pestilence
        end
        --AOE情况下有白霜或者杀戮直接吹
        if (FreezingFogDur > 0 or KillingMachineDur > 0) and HowlingBlastCD <= CastWindow then
            return ID.HowlingBlast
        end
        --按配置判断是否凋零
        if WAParam.config.autoDnD and DeathDecayCD <= CastWindow then
            return ID.DeathDecay
        end
    else
        --最近一次AOE传染时间超过疾病时长且进入单体状态就可以取消该记录以便下一次AOE传染计算
        if LastAOETime > 0 and (now - LastAOETime) > DiseaseDurMax then
            LastAOETime = 0
        end
    end
    
    --湮没
    --1、有疾病雕文且分流CD在的时候，凭借死符文可以赌一发湮没
    --2、不消耗死符文的普通湮没
    if ObliterateCD <= CastWindow and DiseaseDur > 1.5 and RunicPower < RunicPowerMax-20 then
        if (hasDiseaseGlyph and (BloodTapCD < DiseaseDur or BloodTapCD > 55) and ((DRune >= 2) or (DRune >= 1 and URune >= 1)))
            or (FRune >= 1 and URune >= 1) then
            return ID.Obliterate
        end
    end
    --疾病充裕，有血符文/双死符文/疾病大于符文循环时，打掉血打
    if DiseaseDur > PestilenceThreshold and RunicPower < RunicPowerMax-10 and BloodStrikeCD <= CastWindow
        and (BRune > 0 or DRune >= 2 or DiseaseDur > 10)then
        return ID.BloodStrike
    end
    --实在没技能放就不等杀戮直接白霜吹，不浪费公共CD和机会成本
    if FreezingFogDur > 0 and HowlingBlastCD <= CastWindow then
        return ID.HowlingBlast
    end
    --BOSS战中低优先级爆发
    if WAParam.config.autoBurst and inBossFight and inMeleeRange and TargetDeadTime > 12 then
        --符文全空且双血转化为双死或者吃到嗜血，才用符文武器刷新
        if EmpowerRuneCD < CastWindow and BRune == 0 and FRune == 0 and URune == 0 and DRune == 0
            and RunicPower < RunicPowerMax-25 and GetRuneType(1) == 4 and GetRuneType(2) == 4 then
            return ID.EmpowerRune
        end
        --啥都没了，招个食尸鬼助兴
        if RaiseDeadCD <= CastWindow then
            return ID.RaiseDead
        end
    end
    --号角
    if WinterHornCD <= CastWindow and RunicPower < RunicPowerMax-10 then
        return ID.WinterHorn
    end
    
    --填充冰打
    if not isFrostWyrmSoon and RunicPower >= FSRunicPower then
        return ID.FrostStrike
    end
    --兜底
    return 6603
end
local Manager = CreateFrame("Frame")
Manager:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
Manager:RegisterEvent("PLAYER_REGEN_DISABLED")
Manager:RegisterEvent("PLAYER_REGEN_ENABLED")
Manager:SetScript("OnEvent", function(_, evt)
    if evt == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, sub, _, src, _, _, _, dstG, _, _, _, sID, sName, _, miss = CombatLogGetCurrentEventInfo()
        if sub == "SPELL_CAST_SUCCESS" and src == UnitGUID("player") then
            if sID == ID.Pestilence then
                LastPestilenceTime = GetTime()
            end
        end
    elseif evt == "PLAYER_REGEN_DISABLED" then
        --点了骨疽的算邪冰
        if IsPlayerSpell(51459) or IsPlayerSpell(51462) or IsPlayerSpell(51463) or IsPlayerSpell(51464) or IsPlayerSpell(51465) then
            hasNecrosis = true
        else--否则就是血冰
            hasNecrosis = false
        end
        --根据蔓延计算最大疾病时间
        if IsPlayerSpell(49562) then
            DiseaseDurMax = 21
        elseif IsPlayerSpell(49036) then
            DiseaseDurMax = 18
        else
            DiseaseDurMax = 15
        end
        --查询疾病雕文、冰打雕文是否激活
        hasDiseaseGlyph = false
        hasFSGlyph = false
        for i = 1, 6 do
            local enabled, _, _, glyphSpell = GetGlyphSocketInfo(i)
            if enabled then
                if glyphSpell == 63334 then
                    hasDiseaseGlyph = true
                elseif glyphSpell == 58715 then
                    hasFSGlyph = true
                end
            end
        end
    elseif evt == "PLAYER_REGEN_ENABLED" then
        LastAOETime = 0
        LastPestilenceTime = 0
    end
end)
WAParam.APLActionList = ActionList
WAParam.APLCallback = APLCallback
WAParam.APLName = "共创龙喷冰"

-- ===== actions.init 加载时自定义代码 =====
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
VF_registerAPL(aura_env)