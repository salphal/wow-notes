--[[
aura id: 凌小猫粮_暗牧
aura uid: LG2FBGNwCqk
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
新版暗牧 APL — by时光1凌姐
简化：哀冬
支持二段鞭，支持焦点双目标dot维护，在渊飞天引导期间会自动切焦点续dot，注意目标不要乱点，否则从焦点就回不去主目标了。
]]
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
if APL_PRIEST_SHADOW_CATGIRL_WLK then return end; APL_PRIEST_SHADOW_CATGIRL_WLK = true

local WAParam = aura_env
local CastWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000

local S = {
    VampiricTouch   = 48160,
    DevouringPlague = 48300,
    MindBlast       = 48127,
    MindFlay        = 48156,
    InnerFocus      = 14751,
    ShadowWordDeath = 48158,
    ShadowWordPain  = 48125,
    ShadowFiend     = 34433,
    Shadowform      = 15473,
    ShadowWordAbyss = 1299469,
    InnerFire       = 48168,
    VampiricEmbrace = 15286,
    Spirit          = 48073,
    SpiritAlt       = 48074,
}

-- 断鞭版用偏移ID，和nochanneling版区分
local CLIP_OFFSET = 100000
local FOCUS_OFFSET = 200000

-- ActionList: {动作ID, 类型, 名称/宏, [图标]}
-- 每个技能两条：nochanneling版 + 断鞭版
local ActionList = {
    {S.MindFlay,        "macro", "/cast [nochanneling] 精神鞭笞", GetSpellTexture("精神鞭笞")},
    -- nochanneling版
    {S.VampiricTouch,   "macro", "/cast [nochanneling] 吸血鬼之触", GetSpellTexture("吸血鬼之触")},
    {S.DevouringPlague, "macro", "/cqs\\n/cast [nochanneling] 噬灵疫病", GetSpellTexture("噬灵疫病")},
    {S.MindBlast,       "macro", "/cast [nochanneling] 心灵震爆", GetSpellTexture("心灵震爆")},
    {S.InnerFocus,      "macro", "/cqs\\n/cast [nochanneling] 心灵专注\\n/cast [nochanneling] 暗言术：灭", GetSpellTexture("心灵专注")},
    {S.ShadowWordDeath, "macro", "/cqs\\n/cast [nochanneling] 暗言术：灭", GetSpellTexture("暗言术：灭")},
    {S.ShadowWordPain,  "macro", "/cast [nochanneling] 暗言术：痛", GetSpellTexture("暗言术：痛")},
    {S.ShadowFiend,     "macro", "/cast [nochanneling] 暗影魔", GetSpellTexture("暗影魔")},
    {S.ShadowWordAbyss, "macro", "/cast [nochanneling] 暗言术：渊", GetSpellTexture("暗言术：渊")},
    {6603, "macro", "/targetenemy [dead][noharm]"},
    -- 渊引导中焦点切换
    {-10000, "macro", "/target focus", GetSpellTexture(6603)},
    {-20000, "macro", "/targetlasttarget", GetSpellTexture(6603)},
    -- 断鞭版（允许打断鞭笞，但不打断渊）
    {S.VampiricTouch   + CLIP_OFFSET, "macro", "/cast [nochanneling:暗言术：渊] 吸血鬼之触", GetSpellTexture("吸血鬼之触")},
    {S.DevouringPlague + CLIP_OFFSET, "macro", "/cqs\\n/cast [nochanneling:暗言术：渊] 噬灵疫病", GetSpellTexture("噬灵疫病")},
    {S.MindBlast       + CLIP_OFFSET, "macro", "/cast [nochanneling:暗言术：渊] 心灵震爆", GetSpellTexture("心灵震爆")},
    {S.InnerFocus      + CLIP_OFFSET, "macro", "/cqs\\n/cast [nochanneling:暗言术：渊] 心灵专注\\n/cast [nochanneling:暗言术：渊] 暗言术：灭", GetSpellTexture("心灵专注")},
    {S.ShadowWordDeath + CLIP_OFFSET, "macro", "/cqs\\n/cast [nochanneling:暗言术：渊] 暗言术：灭", GetSpellTexture("暗言术：灭")},
    {S.ShadowWordPain  + CLIP_OFFSET, "macro", "/cast [nochanneling:暗言术：渊] 暗言术：痛", GetSpellTexture("暗言术：痛")},
    {S.ShadowFiend     + CLIP_OFFSET, "macro", "/cast [nochanneling:暗言术：渊] 暗影魔", GetSpellTexture("暗影魔")},
    {S.ShadowWordAbyss + CLIP_OFFSET, "macro", "/cast 暗言术：渊", GetSpellTexture("暗言术：渊")},
    -- 焦点鞭笞（续焦点痛）
    {S.MindFlay + FOCUS_OFFSET, "macro", "/cast [target=focus,nochanneling:暗言术：渊] 精神鞭笞", GetSpellTexture("精神鞭笞")},
    -- 焦点痛（nochanneling版）
    {S.ShadowWordPain + FOCUS_OFFSET, "macro", "/cast [target=focus,nochanneling] 暗言术：痛", GetSpellTexture("暗言术：痛")},
    -- 焦点痛（断鞭版）
    {S.ShadowWordPain + FOCUS_OFFSET + CLIP_OFFSET, "macro", "/cast [target=focus,nochanneling:暗言术：渊] 暗言术：痛", GetSpellTexture("暗言术：痛")},
    -- 焦点触（nochanneling版）
    {S.VampiricTouch + FOCUS_OFFSET, "macro", "/cast [target=focus,nochanneling] 吸血鬼之触", GetSpellTexture("吸血鬼之触")},
    -- 焦点触（断鞭版）
    {S.VampiricTouch + FOCUS_OFFSET + CLIP_OFFSET, "macro", "/cast [target=focus,nochanneling:暗言术：渊] 吸血鬼之触", GetSpellTexture("吸血鬼之触")},
    -- 全爆发（一键开所有不占GCD增伤）
    {-30000, "macro", "/cqs\\n/use [nochanneling] 10\\n/use [nochanneling] 13\\n/use [nochanneling] 14\\n/cast [nochanneling] 狮心\\n/cast [nochanneling] 狂暴\\n/cast [nochanneling] 血性狂怒\\n/cqs", 237566},
    -- 全爆发（断鞭版）
    {-30000 + CLIP_OFFSET, "macro", "/cqs\\n/use 10\\n/use 13\\n/use 14\\n/cast 狮心\\n/cast 狂暴\\n/cast 血性狂怒\\n/cqs", 237566},
    -- 补buff
    {S.Shadowform, "spell", "暗影形态"},
    {S.InnerFire, "spell", "心灵之火"},
    {S.VampiricEmbrace, "spell", "吸血鬼的拥抱"},
    {S.Spirit, "spell", "神圣之灵"},
}


-- 判断是否有可用的爆发技能
local function HasBurstReady()
    -- 手套饰品就绪
    if VF_getItemCD(10) <= 0
        or VF_getItemCD(13) <= 0
        or VF_getItemCD(14) <= 0 then
        return true
    end

    -- 种族技能就绪
    if VF_getSpellCD(20599) <= 0-- 狮心
        or VF_getSpellCD(26297) <= 0-- 狂暴
        or VF_getSpellCD(33697) <= 0 then-- 血性狂怒
        return true
    end
    
    return false
end

local P5SuitActive = false

-- 渊升空追踪：0=正常，1=需要插疫病，2=已推荐过疫病
local SWALiftoffDP = 0
local SWALiftoffTime = 0

-- 痛暴击快照（需在事件处理器之前声明，否则事件中写入全局变量）
local PainCritRecorded = 0

-- 焦点触锁/痛锁
local FocusPainCritRecorded = 0

-- 渊引导中焦点切换：0=idle, 1=/target focus, 2=/targetlasttarget, 3=locked
local SWAFocusPhase = 0
local SWAFocusLockTime = 0
local SWAFocusPhase2Time = 0  -- Phase 2 进入时间

-- 鞭笞跳数追踪
local MF_DMG_ID = 58381
local MFTicks = 0
local MFTick2Time = 0        -- 第2跳出伤的时间（COMBAT_LOG确认）
local HighPrioSinceTime = 0  -- 非MF推荐首次出现的时间
local MFStartTime = 0        -- MF引导开始时间
local MFHasteRatio = 1       -- MF引导时的急速倍率
local MFLockUntil = 0      -- MF引导结束前禁止再推荐MF

local EventFrame = CreateFrame("Frame", nil, UIParent)
EventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
EventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
EventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
EventFrame:SetScript("OnEvent", function(self, e, ...)
    local now = GetTime()
    if e == "UNIT_SPELLCAST_CHANNEL_START" then
        local unit = ...
        if unit == "player" then
            local channelName, _, _, _, channelEnd = UnitChannelInfo("player")
            if channelName == "精神鞭笞" then
                MFTicks = 0
                MFTick2Time = 0
                HighPrioSinceTime = 0
                MFStartTime = now
                MFHasteRatio = 1 + (UnitSpellHaste("player") or 0) / 100
                local _, currentSW = VF_getBuff("player", 15258, "HELPFUL|PLAYER")
                if (currentSW or 0) < 5 then
                    MFLockUntil = (channelEnd or 0) / 1000 + 0.3
                end
            elseif channelName == "暗言术：渊" then
                -- 如果SWA刚出手不到200ms，可能是延迟压缩到同一帧，不重置flag
                if now - SWALiftoffTime >= 0.2 then
                    SWALiftoffDP = 0
                    SWALiftoffTime = 0
                end
                SWAFocusPhase2Time = 0
                -- 有焦点且焦点≠目标时，启动焦点切换流程
                local focusGUID = UnitGUID("focus")
                if focusGUID and focusGUID ~= UnitGUID("target")
                and (SWAFocusPhase ~= 3 or (now - SWAFocusLockTime) >= 6) then
                    SWAFocusPhase = 1
                end
            end
        end
    elseif e == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, srcGUID, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo()
        if srcGUID == WeakAuras.myGUID then
            local focusGUID = UnitGUID("focus")
            if subEvent == "SPELL_CAST_SUCCESS" and spellID == S.DevouringPlague then
                if SWALiftoffDP == 1 then
                    SWALiftoffDP = 2
                end
            elseif subEvent == "SPELL_CAST_SUCCESS" and spellID == S.ShadowWordAbyss then
                SWALiftoffDP = 1
                SWALiftoffTime = now
            elseif subEvent == "SPELL_CAST_SUCCESS" and spellID == S.ShadowWordPain then
                if focusGUID and destGUID == focusGUID then
                    FocusPainCritRecorded = GetSpellCritChance(6) or 0
                else
                    PainCritRecorded = GetSpellCritChance(6) or 0
                end
            elseif (subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_PERIODIC_DAMAGE")
            and spellID == MF_DMG_ID then
                MFTicks = MFTicks + 1
                if MFTicks == 2 then
                    MFTick2Time = now
                end
            end
        end
    elseif e == "PLAYER_REGEN_DISABLED" then
        --P5套装效果战前检测
        local P5SuitCount = 0
        if GetInventoryItemID("player", INVSLOT_WRIST) == 34434 then P5SuitCount = P5SuitCount + 1 end--手腕
        if GetInventoryItemID("player", INVSLOT_WAIST) == 34528 then P5SuitCount = P5SuitCount + 1 end--腰带
        if GetInventoryItemID("player", INVSLOT_FEET) == 34563 then P5SuitCount = P5SuitCount + 1 end--鞋子
        if P5SuitCount >= 2 then
            P5SuitActive = true
        end
    elseif e == "PLAYER_REGEN_ENABLED" then
        P5SuitActive = false
    end
end)


-- ==========================================
-- 断鞭管理器（事件驱动：追踪鞭笞跳数）
-- ==========================================

-- 判断当前鞭笞引导是否已过安全跳数
-- 返回: "none"(未在引导) / "wait"(还需继续等) / "clip"(可以断鞭)
local function ClipDecision()
    local channelName, _, _, channelStartMS, channelEndMS = UnitChannelInfo("player")
    if not channelName then return "none" end

    if channelName ~= "精神鞭笞" then return "none" end

    if not channelEndMS then return "none" end

    -- 服务器时间反算，3跳均分
    local tickInterval = (channelEndMS - channelStartMS) / 3000
    local remaining = (channelEndMS - GetTime() * 1000) / 1000

    -- 剩余 < 1 跳 → 第 2 跳已完成，可以断鞭
    if remaining < tickInterval then
        return "clip"
    end

    return "wait"
end

-- ==========================================
-- 优先级逻辑（纯决策，不管引导状态）
-- ==========================================
local function DecidePriority()
    CastWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
    local isCombat = UnitAffectingCombat("player")
    local inBossFight = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
    local GCD = VF_getSpellCD(61304)
    local now = GetTime()
    local castingSpellName, _, _, _, endTimeMs = UnitCastingInfo("player")
    if castingSpellName ~= nil then 
        GCD = math.max((endTimeMs/1000 - now), GCD)
    else
        castingSpellName = UnitChannelInfo("player")
    end
    local currentCrit = GetSpellCritChance(6) or 0
    local hasFocus = UnitExists("focus") and UnitCanAttack("player", "focus") and not UnitIsDead("focus") and UnitGUID("focus") ~= UnitGUID("target")
    local _, SWStack = VF_getBuff("player", 15258, "HELPFUL|PLAYER")
    local ReaperDur = math.max(VF_getBuff("player", 1303678, "HELPFUL|PLAYER")-GCD,0)
    local VTouchDur = math.max(VF_getDebuff("target", S.VampiricTouch, "HARMFUL|PLAYER")-GCD,0)
    local FocusVTDur = math.max(VF_getDebuff("focus", S.VampiricTouch, "HARMFUL|PLAYER")-GCD,0)
    local PainDur = math.max(VF_getDebuff("target", S.ShadowWordPain, "HARMFUL|PLAYER")-GCD,0)
    local FocusPainDur = math.max(VF_getDebuff("focus", S.ShadowWordPain, "HARMFUL|PLAYER")-GCD,0)
    local DPDur = math.max(VF_getDebuff("target", S.DevouringPlague, "HARMFUL|PLAYER")-GCD,0)
    local SWDCD = math.max(VF_getSpellCD(S.ShadowWordDeath)-GCD,0)
    local SWACD = math.max(VF_getSpellCD(S.ShadowWordAbyss)-GCD,0)
    local VTouchCT = (select(4, GetSpellInfo("吸血鬼之触")) / 1000)

    if castingSpellName == "心灵震爆" then
        isCombat = true
    elseif castingSpellName == "吸血鬼之触" then
        VTouchDur = 15
        FocusVTDur = 15
    elseif castingSpellName == "暗言术：渊" then
        -- 渊引导中：焦点切换（只阻拦切目标，不阻拦其他优先级）
        -- 阶段推进：检测目标是否已切换
        if SWAFocusPhase == 1 then
            local focusGUID = UnitGUID("focus")
            if focusGUID and UnitGUID("target") == focusGUID then
                SWAFocusPhase = 2
                SWAFocusPhase2Time = now
            else
                return -10000
            end
        elseif SWAFocusPhase == 2 then
            local focusGUID = UnitGUID("focus")
            if focusGUID and UnitGUID("target") ~= focusGUID then
                SWAFocusPhase = 3
                SWAFocusLockTime = now
            elseif (now - SWAFocusPhase2Time) >= 0.2 then
                return -20000
            end
        elseif SWAFocusPhase == 3 and (now - SWAFocusLockTime) >= 6 then
            SWAFocusPhase = 0
        end
        if SWALiftoffDP > 0 then
            SWALiftoffDP = 0
            SWALiftoffTime = 0
        end
        return 6603
    else
        -- 万一渊引导中断时清理残留的焦点切换阶段
        if SWAFocusPhase > 0 and SWAFocusPhase < 3 then
            SWAFocusPhase = 0
        end
    end

    -- 暗影形态（最高优先级，无论战斗/读条/引导）
    if (VF_getBuff("player", 15473, "HELPFUL|PLAYER") or 0) == 0 then
        return S.Shadowform
    end

    -- 补buff（战斗外，缺了或剩余<10分钟时提醒，不需要目标）
    if not isCombat then
        local ifDur = VF_getBuff("player", S.InnerFire, "HELPFUL|PLAYER") or 0
        if ifDur < 600 then
            return S.InnerFire
        end
        local veDur = VF_getBuff("player", S.VampiricEmbrace, "HELPFUL|PLAYER") or 0
        if veDur < 600 then
            return S.VampiricEmbrace
        end
        local spDur = math.max(VF_getBuff("player", S.Spirit, "HELPFUL"), VF_getBuff("player", S.SpiritAlt, "HELPFUL"))
        if spDur < 600 then
            return S.Spirit
        end
        if UnitExists("target") and UnitCanAttack("player", "target") then
            return S.MindBlast
        end
    end

    if not UnitExists("target") or not UnitCanAttack("player", "target") then
        return 6603
    end

    -- P0: 升空窗口
    if SWALiftoffDP > 0 then
        if SWALiftoffTime > 0 and now - SWALiftoffTime > 0.8 then
            SWALiftoffDP = 0
            SWALiftoffTime = 0
        elseif SWALiftoffDP == 1 then
            local hastePct = UnitSpellHaste("player") or 0
            local hasteFactor = 1 + hastePct / 100
            local SWATotal = 8 / hasteFactor + 2.6  -- 读条2+引导6=8, 升空0.6+缓冲2=2.6
            if PainDur <= 0 and SWStack == 5 then
                return S.ShadowWordPain
            end
            if hasFocus and FocusPainDur <= 0 and SWStack == 5 then
                return S.ShadowWordPain + FOCUS_OFFSET
            end
            if DPDur <= SWATotal then
                return S.DevouringPlague
            end
            if SWDCD <= CastWindow then
                return S.ShadowWordDeath
            end
        else
            return 6603
        end
    end

    -- P0.5: 痛快断时鞭笞最高优先
    if PainDur > 0 and PainDur < 2.5 then
        return S.MindFlay
    end

    -- P0.6: 暗言术：灭（死神慈悲<2秒时最高优先，断鞭版）
    if SWDCD <= CastWindow and ReaperDur > 0 and ReaperDur < 2 then
        return S.ShadowWordDeath
    end

    -- P1: 暗言术：痛（只在暗影交织5层时施放/刷新）
    if SWStack == 5 then
        if PainDur <= 0 or currentCrit > PainCritRecorded + 1 then
            return S.ShadowWordPain
        end
    end

    -- P1.5: 焦点痛快断时焦点鞭笞续痛
    if hasFocus and FocusPainDur > 0 and FocusPainDur < 4 then
        return S.MindFlay + FOCUS_OFFSET
    end

    -- P1.6: 焦点暗言术：痛（只在暗影交织5层时施放/刷新）
    if hasFocus and SWStack == 5 then
        if FocusPainDur == 0 then
            return S.ShadowWordPain + FOCUS_OFFSET
        elseif currentCrit > FocusPainCritRecorded + 1 then
            return S.ShadowWordPain + FOCUS_OFFSET
        end
    end

    -- P1.7: 渊即将就绪，预判焦点dot是否够撑过渊（暗影交织5）
    if SWACD <= 2 then
        if SWStack == 5 then
            if hasFocus then
                local _, maxRange = WeakAuras.GetRange("focus")
                local FocusThreshold
                if maxRange and maxRange <= 20 then
                    FocusThreshold = 5+SWACD
                else
                    FocusThreshold = 7+SWACD
                end
                -- 焦点痛
                if FocusPainDur > 0 and FocusPainDur <= FocusThreshold then
                    if castingSpellName ~= "暗言术：渊" then
                        return S.MindFlay + FOCUS_OFFSET
                    end
                end
                -- 焦点触
                if FocusVTDur <= FocusThreshold then
                    return S.VampiricTouch + FOCUS_OFFSET
                end
            end
        end
    end

    -- P2: 暗言术：渊（暗影交织5 + CD就绪，仅主目标）
    if SWACD <= CastWindow then
        if SWStack == 5 then
            local _, maxRange = WeakAuras.GetRange("target")
            local SWAThreshold, PainThreshold
            if maxRange and maxRange <= 20 then
                SWAThreshold = 5+SWACD
                PainThreshold = 5+SWACD
            else
                SWAThreshold = 7+SWACD
                PainThreshold = 7+SWACD
            end
            if PainDur <= PainThreshold then
                return S.MindFlay
            end
            if VTouchDur > SWAThreshold then
                return S.ShadowWordAbyss
            else
                return S.VampiricTouch
            end
            return 6603
        end
    end
    
    -- P2.5: P5套装效果激活就卡CD灭
    if P5SuitActive and SWDCD <= CastWindow then
        return S.ShadowWordDeath
    end

    -- P3: 暗影魔
    if WAParam.config.auto_shadow_fiend and inBossFight and isCombat and math.max(VF_getSpellCD(S.ShadowFiend)-GCD) <= CastWindow then
        return S.ShadowFiend
    end

    -- P4: 吸血鬼之触（正常刷新）& 爆发
    if VTouchDur <= VTouchCT then
        if WAParam.config.autoBurst and inBossFight and HasBurstReady() then
            return -30000
        else
            return S.VampiricTouch
        end
    end

    -- P4.5: 焦点吸血鬼之触
    if hasFocus and FocusVTDur <= VTouchCT then
        return S.VampiricTouch + FOCUS_OFFSET
    end

    -- P4: 噬灵疫病（渊CD就绪时跳过，升空窗口会自动插疫病）
    if SWACD > CastWindow then
        if DPDur == 0 then
            return S.DevouringPlague
        end
    end

    -- P5: 心灵震爆
    if VF_getSpellCD(S.MindBlast) <= CastWindow then
        return S.MindBlast
    end

    -- P6: 暗言术：灭（死神慈悲buff时使用）
    if SWDCD <= CastWindow and ReaperDur > 0 then
        return S.ShadowWordDeath
    end

    -- P7: 精神鞭笞
    if VF_getSpellCD(S.MindFlay) <= CastWindow and castingSpellName == nil then
        -- MF引导刚结束300ms内，如果交织!=5，等buff更新，避免P7抢先于P1
        if now < MFLockUntil then
            return 6603
        end
        return S.MindFlay
    end

    return 6603
end

-- ==========================================
-- 主回调：优先级 + 断鞭管理
-- ==========================================
local function APLCallback_ShadowPriest()
    local spell = DecidePriority()

    -- 不需要断鞭判断的技能直接返回
    if spell == 6603 then
        return spell
    end
    if spell == S.MindFlay or spell == S.MindFlay + FOCUS_OFFSET then
        HighPrioSinceTime = 0
        return spell
    end

    --有慈悲的情况替换成专注灭
    if VF_getBuff("player", 1303678, "HELPFUL|PLAYER") > 0 and VF_getSpellCD(S.InnerFocus) <= 0 and spell == S.ShadowWordDeath then
        spell = S.InnerFocus
    end

    -- 记录非MF推荐首次出现的时间
    if HighPrioSinceTime == 0 then
        HighPrioSinceTime = GetTime()
    end

    -- 需要断鞭判断的技能（VT/DP/MB/SWD/SWP/SWA）
    local clip = ClipDecision()

    if clip ~= "clip" then
        return spell
    end

    -- clip: 已过2跳，只有第2跳之前推荐的技能才断鞭
    local _, _, _, channelStartMS, channelEndMS = UnitChannelInfo("player")
    local tickInterval = (channelEndMS - channelStartMS) / 3000
    local tick2EndTime = channelStartMS / 1000 + 2 * tickInterval
    if HighPrioSinceTime <= tick2EndTime then
        return spell + CLIP_OFFSET
    else
        return spell
    end
end

aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_ShadowPriest
aura_env.APLName = "凌小猫粮"


-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)