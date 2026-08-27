--[[
aura id: 凌小猫粮_毁伤
aura uid: TgVuoyCFRv7
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
凌小猫娘两用毁伤贼APL
版本：1.2
]]
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
if APL_ASSASSINATION_ROGUE_CATGIRL then return end; APL_ASSASSINATION_ROGUE_CATGIRL = true

local WAParam = aura_env

-- 禁止名单，后续如果有BOSS不能消失，则把BOSS名字写进来
local vanishColdBloodBlacklist = {
    ["费尔根"] = true,
    ["迈克斯纳"] = true,
    ["斯塔拉格"] = true,
    ["萨菲隆"] = true,
    --["辛达苟萨"] = true,
    --["海里昂"] = true,
    ["维斯匹隆"] = true,
    ["鲜血女王兰娜瑟尔"] = true,
    ["观察者奥尔加隆"] = true,
    --["穆鲁"] = true,
    --["菲米斯"] = true,
    ["普崔塞德教授"] = true,
    ["冰吼"] = true,
    --["哈卡"] = true,
}

-- 流血DEBUFF列表（用于血之饥渴检测，深毁伤专属）
local bleedingDebuffs = {
    48574,  -- 斜掠
    49800,  -- 猫割裂
    413763, -- 重伤
    47465,  -- 撕裂
    48672,  -- 贼割裂
    48676,  -- 老锁喉
    1284409,-- 新锁喉
}

local ActionList = {
    {57934, "macro", "/cast [@focus,help,exists][@targettarget,help] 嫁祸诀窍", GetSpellTexture("嫁祸诀窍")},
    {1784, "spell", "潜行"},
    {1282540, "spell", "转嫁"},
    {6774, "spell", "切割"},
    {8647, "spell", "破甲"},
    {51662, "spell", "血之饥渴"},
    {48672, "spell", "割裂"},
    {48676, "spell", "锁喉"},
    {26889, "spell", "消失"},
    {14177, "spell", "冷血"},
    {57993, "spell", "毒伤"},
    {13877, "spell", "剑刃乱舞"},
    {13, "item", 13},
    {14, "item", 14},
    {-300, "macro", "/use 10\\n/cast 狮心(种族特长)\\n/cast 狂暴(种族特长)\\n/cast 血性狂怒(种族特长)\\n/use 通用热力工程炸药\\n/use [@player] 萨隆邪铁炸弹", 133035},
    {-200, "macro", "/use 菊花茶", 132819},
    {1766, "spell", "脚踢"},
    {48666, "spell", "毁伤"},
    {6603, "macro", "/startattack"}
}

local function APLCallback_RogueAssassinationRotation()
    local CastWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
    local NextSpellID = 6603

    for i = 1, 1 do
        local isDeepAssa = IsPlayerSpell(51662) or false
        local isBladeFlurry = IsPlayerSpell(13877) or false
        local GCD = VF_getSpellCD(61304)
        local Energy = math.min(UnitPowerMax("player", 3), UnitPower("player", 3) + math.ceil(GCD*10))
        local CP = GetComboPoints("player", "target")
        local inMeleeRange = (IsSpellInRange(GetSpellInfo(48666), "target") == 1)
        local inCombat = UnitAffectingCombat("player")
        local inBossFight = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)

        -- 技能冷却
        local StealthCD = VF_getSpellCD(1784)
        local SliceAndDiceCD = math.max(0, VF_getSpellCD(6774)-GCD)
        local VanishCD = math.max(0, VF_getSpellCD(26889)-GCD)
        local ColdBloodCD = math.max(0, VF_getSpellCD(14177)-GCD)
        local EnvenomCD = math.max(0, VF_getSpellCD(57993)-GCD)
        local MutilateCD = math.max(0, VF_getSpellCD(48666)-GCD)
        local TrickOfTheTradeCD = math.max(0, VF_getSpellCD(57934)-GCD)
        local KickCD = VF_getSpellCD(1766) --独立CD不需要减掉GCD剩余
        local BladeFlurryCD = math.max(0, VF_getSpellCD(13877)-GCD)
        local Trinket1CD = VF_getItemCD(13)
        local Trinket2CD = VF_getItemCD(14)
        local ThistleTeaOK = (VF_getItemCD(7676) <= 0 and GetItemCount(7676) > 0)
        local HungerForBloodCD = math.max(0, VF_getSpellCD(51662)-GCD)
        local RuptureCD = math.max(0, VF_getSpellCD(48672)-GCD)
        local GarroteCD = math.max(0, VF_getSpellCD(48676)-GCD)

        -- BUFF持续时间
        local StealthDuration = VF_getBuff("player", 1784, "HELPFUL|PLAYER")
        local SliceAndDiceDuration = math.max(0, VF_getBuff("player", 6774, "HELPFUL|PLAYER")-GCD)
        local EnvenomDuration = math.max(0, VF_getBuff("player", 57993, "HELPFUL|PLAYER")-GCD)
        local ColdBloodBuff = math.max(0, VF_getBuff("player", 14177, "HELPFUL|PLAYER")-GCD)
        local ExtinctionDuration = math.max(0, VF_getBuff("player", 58427, "HELPFUL|PLAYER")-GCD)
        local BladeFlurryDuration = math.max(0, VF_getBuff("player", 13877, "HELPFUL|PLAYER")-GCD)
        local HungerForBloodDuration = math.max(0, VF_getBuff("player", 63848, "HELPFUL|PLAYER")-GCD)
        local _, RedirectCount = VF_getBuff("player", 1282539, "HELPFUL|PLAYER")

        -- 目标DEBUFF
        local DeadlyPoisonDuration = math.max(0, VF_getDebuff("target", 57970, "HARMFUL|PLAYER")-GCD)

        -- 检测目标是否在禁止消失名单
        local isBlacklistedTarget = false
        local targetName = UnitName("target")
        if targetName and vanishColdBloodBlacklist[targetName] then
            isBlacklistedTarget = true
        end

        -- 潜行
        if (not inCombat) and (StealthDuration <= 0) and (StealthCD <= CastWindow) then
            NextSpellID = 1784
            break
        end

        -- ==========================================
        -- 0. 自动打断 (额外优先级)
        -- ==========================================
        if (WAParam.config.autoKick) and (inCombat) and (Energy >= 25) and (KickCD <= CastWindow) then
            local casting, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
            if not casting then
                casting, _, _, _, _, _, _, _, notInterruptible = UnitChannelInfo("target")
            end
            if casting and (not notInterruptible) then
                NextSpellID = 1766
                break
            end
        end

        -- ==========================================
        -- 0. 转嫁 (额外优先级)
        -- ==========================================
        if RedirectCount > CP then
            NextSpellID = 1282540
            break
        end

        -- ==========================================
        -- 0. 自动破甲 (最高优先级)
        -- ==========================================
        if (WAParam.config.autoExposeArmor) then
            local ExposeArmorDuration = math.max(0, VF_getDebuff("target", 8647, "HARMFUL")-GCD)
            if (inCombat) and (inMeleeRange) and (ExposeArmorDuration <= 3) and (VF_getSpellCD(8647) <= CastWindow) then
                if CP >= 1 then
                    NextSpellID = 8647
                    break
                elseif (CP == 0) and (Energy > 55) and (MutilateCD <= CastWindow) then
                    NextSpellID = 48666
                    break
                end
            end
        end
        
        -- ==========================================
        -- 0.5. 饰品手套菊花茶 (额外优先级)
        -- ==========================================
        if inCombat and inBossFight and SliceAndDiceDuration > 6 and inMeleeRange
            and (isDeepAssa or (isBladeFlurry and (BladeFlurryDuration > 1 or BladeFlurryCD > 55)))then --深毁伤和乱舞毁伤差异化
            -- 手套 + 种族技能 + 炸药（任一就绪就触发）
            if (IsSpellKnown(20599) and VF_getSpellCD(20599) <= 0)
                    or (IsSpellKnown(26297) and VF_getSpellCD(26297) <= 0)
                    or (IsSpellKnown(20572) and VF_getSpellCD(20572) <= 0)
                    or (GetItemCount(41119) > 0 and VF_getItemCD(41119) <= 0)
                    or (GetItemCount(42641) > 0 and VF_getItemCD(42641) <= 0)
                    or (VF_getItemCD(10) <= 0) then
                NextSpellID = -300
                break
            end
            
            -- 饰品
            local trinket1Id = GetInventoryItemID("player", 13)
            if trinket1Id and (Trinket1CD <= CastWindow) then
                if trinket1Id ~= 19954 or Energy < 40 then -- 雷纳塔基的狡诈护符：能量<40才用，避免浪费回能
                    NextSpellID = 13
                    break
                end
            end
            local trinket2Id = GetInventoryItemID("player", 14)
            if trinket2Id and (Trinket2CD <= CastWindow) then
                if trinket2Id ~= 19954 or Energy < 40 then
                    NextSpellID = 14
                    break
                end
            end
            
            -- 菊花茶
            if (Energy < 40) and (ThistleTeaOK) then
                NextSpellID = -200
                break
            end
        end

        if isBladeFlurry then
            -- ==========================================
            -- 剑刃乱舞流分支
            -- ==========================================
            -- BLADE FLURRY MODE - 剑刃乱舞激活期间
            if (BladeFlurryDuration > 0) then
                local meleeEnemyCount = 0
                for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
                    local unit = plate.namePlateUnitToken
                    if unit and UnitCanAttack("player", unit) and not UnitIsDead(unit) and IsSpellInRange(GetSpellInfo(48666), unit) == 1 then
                        meleeEnemyCount = meleeEnemyCount + 1
                    end
                end
                if meleeEnemyCount == 0 then meleeEnemyCount = 1 end

                -- 1. 切割补1星（如果buff没了）
                if (SliceAndDiceDuration <= 1) and (CP >= 1) and (SliceAndDiceCD <= CastWindow) and (Energy > 25) then
                    NextSpellID = 6774
                    break
                end

                -- 2. 消失 - 如果没有灭绝buff且消失可用
                if (ExtinctionDuration == 0) and (VanishCD <= CastWindow) and (not isBlacklistedTarget) and inBossFight then
                    NextSpellID = 26889
                    break
                end

                -- 4.5. 冷血+毒伤连招
                if (ColdBloodCD <= CastWindow) and (CP >= 4) and (StealthDuration == 0) and inBossFight then
                    NextSpellID = 14177
                    break
                end
                if (ColdBloodBuff > 0) and (StealthDuration == 0) and (CP >= 4) and (inMeleeRange) and (EnvenomCD <= CastWindow) then
                    NextSpellID = 57993
                    break
                end

                -- 6. 毒伤/毁伤 — 单目标与多目标策略不同
                if (meleeEnemyCount >= 2) then
                    -- 多目标：毒伤宽松，尽量多打
                if (DeadlyPoisonDuration > 0) and (inMeleeRange) and (EnvenomCD <= CastWindow) then
                    if CP >= 2 and Energy >= 35 then
                        NextSpellID = 57993
                        break
                    end
                end
                if (inMeleeRange) and (Energy > 55) and (MutilateCD <= CastWindow) then
                    NextSpellID = 48666
                    break
                else
                        NextSpellID = 6603
                    end
                else
                    -- 单目标：不截断毒伤buff，按三维决策
                    if (DeadlyPoisonDuration > 0) and (inMeleeRange) and (EnvenomCD <= CastWindow) then
                        local canCastEnvenom = false
                        
                        if CP <= 2 then
                            canCastEnvenom = false
                        elseif CP == 3 then
                            if Energy > 90 then
                                canCastEnvenom = true
                            elseif Energy >= 70 and Energy <= 90 and EnvenomDuration < 0.2 then
                                canCastEnvenom = true
                            elseif Energy >= 55 and Energy <= 69 and EnvenomDuration == 0 then
                                canCastEnvenom = true
                            end
                        elseif CP == 4 then
                            if Energy > 90 then
                                canCastEnvenom = true
                            elseif Energy >= 75 and Energy <= 90 and EnvenomDuration < 0.5 then
                                canCastEnvenom = true
                            elseif Energy >= 45 and Energy <= 74 and EnvenomDuration == 0 then
                                canCastEnvenom = true
                            end
                        elseif CP == 5 then
                            if Energy > 90 then
                                canCastEnvenom = true
                            elseif Energy >= 35 and Energy <= 89 and EnvenomDuration < 0.5 then
                                canCastEnvenom = true
                            end
                        end
                        
                        if canCastEnvenom then
                            NextSpellID = 57993
                            break
                        end
                    end
                    
                    if (inMeleeRange) and (Energy > 55) and (MutilateCD <= CastWindow) then
                        local canCastMutilate = false
                        
                        if DeadlyPoisonDuration == 0 then
                            canCastMutilate = true
                        else
                            if CP <= 2 then
                                canCastMutilate = true
                            elseif CP == 3 and Energy > 85 and EnvenomDuration > 0.5 then
                                canCastMutilate = true
                            end
                        end
                        
                        if canCastMutilate then
                            NextSpellID = 48666
                            break
                        end
                    end
                    
                    NextSpellID = 6603
                end

                return NextSpellID
            end

            -- 乱舞就绪 — 阶段一：确保切割>=17s，阶段二：等能量>=90开乱舞
            if (BladeFlurryCD <= CastWindow) and (inMeleeRange) and inBossFight then
                if (SliceAndDiceDuration < 17) then
                    if (CP >= 3) and (SliceAndDiceCD <= CastWindow) and (Energy > 25) then
                        NextSpellID = 6774
                        break
                    elseif (CP < 3) and (Energy > 55) and (MutilateCD <= CastWindow) then
                        NextSpellID = 48666
                        break
                    else
                        NextSpellID = 6603
                        break
                    end
                end
                if (Energy >= 90) then
                    NextSpellID = 13877
                    break
                else
                    NextSpellID = 6603
                    break
                end
            end
        elseif isDeepAssa then
            -- ==========================================
            -- 深毁伤分支
            -- ==========================================
            -- 潜行转嫁切割
            if (StealthDuration > 0) and (Energy > 25) and (SliceAndDiceDuration <= 0) and (CP >= 1) and (SliceAndDiceCD <= CastWindow) then
                NextSpellID = 6774
                break
            end
            local isBleeding = false
            for _, debuffID in ipairs(bleedingDebuffs) do
                if VF_getDebuff("target", debuffID, "HARMFUL") > 0 then
                    isBleeding = true
                    break
                end
            end
            
            -- 锁喉（潜行状态下，目标无流血时起手上流血）
            if (StealthDuration > 0) and (not isBleeding) and (Energy >= 50) and (GarroteCD <= CastWindow) and (inMeleeRange) then
                NextSpellID = 48676
                break
            end
            
            -- 血之饥渴
            if (inCombat) and (isBleeding) and (Energy > 15) and (HungerForBloodDuration < 5) and (HungerForBloodCD <= CastWindow) then
                NextSpellID = 51662
                break
            end
            
            -- 割裂（补流血DEBUFF，仅在血之饥渴未激活时）
            if (inCombat) and (not isBleeding) and (HungerForBloodDuration == 0) and (Energy >= 25) and
                    (CP > 1) and (inMeleeRange) and (RuptureCD <= CastWindow) then
                NextSpellID = 48672
                break
            end
        end

        -- ==========================================
        -- 毁伤通用逻辑
        -- ==========================================
        -- 1. 嫁祸诀窍
        -- ==========================================
        if WAParam.config.autoTricksTrade and TrickOfTheTradeCD <= CastWindow
            and IsInGroup() and (SliceAndDiceDuration >= 1 or StealthDuration > 0)
            and ((UnitExists("focus") and UnitIsFriend("player", "focus") and not UnitIsDead("focus") and not UnitIsUnit("focus", "player") and (IsSpellInRange(GetSpellInfo(57934), "focus") == 1))
                or (UnitExists("targettarget") and UnitIsFriend("player", "targettarget") and not UnitIsDead("targettarget") and not UnitIsUnit("targettarget", "player") and (IsSpellInRange(GetSpellInfo(57934), "targettarget") == 1))) then
            NextSpellID = 57934
            break
        end

        -- 2. 切割
        if (Energy > 25) and (SliceAndDiceDuration <= 1) and (CP >= 1) and (SliceAndDiceCD <= CastWindow) then
            NextSpellID = 6774
            break
        end

        -- 3. 消失
        if (WAParam.config.autoVanish) and (inCombat) and (ExtinctionDuration == 0) and (VanishCD <= CastWindow) and
        (inBossFight) and (not isBlacklistedTarget) and (Energy > 60) and (TrickOfTheTradeCD < 8) then
            NextSpellID = 26889
            break
        end

        -- 4. 冷血
        if (inCombat) and (ColdBloodCD <= CastWindow) and (SliceAndDiceDuration > 0) and (StealthDuration == 0) and
        (CP >= 4) and (inBossFight) then
            NextSpellID = 14177
            break
        end

        -- 5. 毒伤
        if (inCombat) and (DeadlyPoisonDuration > 0) and (inMeleeRange) and (EnvenomCD <= CastWindow) then
            local canCastEnvenom = false

            if CP <= 2 then
                canCastEnvenom = false
            elseif CP == 3 then
                if Energy > 90 then
                    canCastEnvenom = true
                elseif Energy >= 70 and Energy <= 90 and EnvenomDuration < 0.2 then
                    canCastEnvenom = true
                elseif Energy >= 55 and Energy <= 69 and EnvenomDuration == 0 then
                    canCastEnvenom = true
                end
            elseif CP == 4 then
                if Energy > 90 then
                    canCastEnvenom = true
                elseif Energy >= 75 and Energy <= 90 and EnvenomDuration < 0.5 then
                    canCastEnvenom = true
                elseif Energy >= 45 and Energy <= 74 and EnvenomDuration == 0 then
                    canCastEnvenom = true
                end
            elseif CP == 5 then
                if Energy > 90 then
                    canCastEnvenom = true
                elseif Energy >= 35 and Energy <= 89 and EnvenomDuration < 0.5 then
                    canCastEnvenom = true
                end
            end

            if canCastEnvenom then
                NextSpellID = 57993
                break
            end
        end

        -- 6. 毁伤
        if (inMeleeRange) and (Energy > 55) and (MutilateCD <= CastWindow) then
            local canCastMutilate = false

            if DeadlyPoisonDuration == 0 then
                canCastMutilate = true
            else
                if CP <= 2 then
                    canCastMutilate = true
                elseif CP == 3 and Energy > 85 and EnvenomDuration > 0.5 then
                    canCastMutilate = true
                end
            end

            if canCastMutilate then
                NextSpellID = 48666
                break
            end
        end

        -- 7. 自动攻击/收尾
        if (CP <= 2) and (Energy > 55) and (MutilateCD <= CastWindow) and (inMeleeRange) then
            NextSpellID = 48666
        elseif (CP == 3) and (Energy > 85) and (MutilateCD <= CastWindow) and (inMeleeRange) then
            NextSpellID = 48666
        else
            NextSpellID = 6603
        end
    end

    return NextSpellID
end


aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_RogueAssassinationRotation
aura_env.APLName = "凌小猫粮"

-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)