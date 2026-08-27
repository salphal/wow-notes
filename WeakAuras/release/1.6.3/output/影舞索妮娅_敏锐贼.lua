--[[
aura id: 影舞索妮娅_敏锐贼
aura uid: 7kiVQcs2Cd1
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
  敏锐贼 APL 
  贡献人：影舞者Sonia
  优化：哀冬
]]

if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_SUBTLETY_ROGUE_SONIA_WLK then return end APL_SUBTLETY_ROGUE_SONIA_WLK = true

-- 禁止暗影步名单
local ShadowStepBlacklist = {
    ["奥"] = true,
    --["拉格纳罗斯"] = true,
    --["加顿男爵"] = true,
    ["塔迪乌斯"] = true,
    ["鱼斯拉"] = true,
    ["萨菲隆"] = true,
    ["辛达苟萨"] = true,
    ["奥妮克希亚"] = true,
    ["海里昂"] = true,
    ["菲米斯"] = true,
    ["科隆加恩"] = true,
    ["尤格-萨隆"] = true,
    ["克苏恩"] = true,
    ["克苏恩之眼"] = true,
}

-- 禁止消失名单
local VanishBlacklist = {
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

-- 无背名单
local NoBackList = {
    ["塔迪乌斯"] = true,
    ["科隆加恩"] = true,
}

local MutiTargetEncounterIDlist = {
    [1121] = true,--4DK
    [789] = true,--高阶祭司塞卡尔
    [633] = true,--TOC 大王
    [637] = true,--TOC PVP
    [641] = true,--TOC 双子
    [626] = true,--深水领主
    [649] = true,--格鲁尔老1
    [653] = true,--莫罗斯
    [652] = true,--午夜
    [655] = true,--剧院
    [727] = true,--SW 双子
    [1193] = true,--祖阿曼 妖术领主
    [1137] = true,--左右手
    [750] = true,--奥杜尔猫女
    [1090] = true,--黑曜石三龙
    [1100] = true,--ICC巫妖女
    [1096] = true,--ICC小萨
    [1133] = true,--芙蕾雅
    [1138] = true,--米米隆合体
    [733] = true,--凯尔萨斯
    [1110] = true,--黑女巫
}

local WAParam = aura_env
local CurrentEncounterID = 0
local intoSmartAOE = false
local FoKCount = 0

local ID = {
    Ambush = --[[select(7, GetSpellInfo("伏击")) or ]]48691,
    Envenom = --[[select(7, GetSpellInfo("毒伤")) or ]]57993,
    Eviscerate = --[[select(7, GetSpellInfo("刺骨")) or ]]48668,
    FanOfKnives = --[[select(7, GetSpellInfo("刀扇")) or ]]51723,
    Premeditation = --[[select(7, GetSpellInfo("预谋")) or ]]14183,
    Redirect = --[[select(7, GetSpellInfo("转嫁")) or ]]1282540,
    Vanish = --[[select(7, GetSpellInfo("消失")) or ]]26889,
    Shadowstep = --[[select(7, GetSpellInfo("暗影步")) or ]]36554,
    Hemorrhage = --[[select(7, GetSpellInfo("出血")) or ]]48660,
    Garrote = --[[select(7, GetSpellInfo("Garrote")) or ]]1284409,
    Rupture = --[[select(7, GetSpellInfo("割裂")) or ]]48672,
    SliceAndDice = --[[select(7, GetSpellInfo("切割")) or ]]6774,
    ExposeArmor = --[[select(7, GetSpellInfo("破甲")) or ]]8647,
    BladeFlurry = --[[select(7, GetSpellInfo("剑刃乱舞")) or ]]13877,
    ShadowDance = --[[select(7, GetSpellInfo("暗影之舞")) or ]]51713,
    Stealth = --[[select(7, GetSpellInfo("潜行")) or ]]1784,
    TricksOfTrade = --[[select(7, GetSpellInfo("嫁祸诀窍")) or ]]57934,
    DeathImprint = --[[select(7, GetSpellInfo("死亡印记")) or ]]1284398,
    GhostlyStrike = --[[select(7, GetSpellInfo("鬼魅攻击")) or ]]14278,
    Preparation = --[[select(7, GetSpellInfo("伺机待发")) or ]]14185,
    MasterOfSubtlety = 31665,
    RedirectCharge = 1282539,
    SunderArmor = 7386,
    T9Buff = 67210,
}

local ActionList = {
    { ID.ShadowDance, "macro", "/use 10\\n/use 13\\n/use 14\\n/cast 狮心\\n/cast 石像形态\\n/cast 血性狂怒\\n/cast 狂暴\\n/cast 暗影之舞", GetSpellTexture("暗影之舞") },
    { ID.BladeFlurry, "macro", "/use 10\\n/use 13\\n/use 14\\n/cast 狮心\\n/cast 石像形态\\n/cast 血性狂怒\\n/cast 狂暴\\n/cast 剑刃乱舞", GetSpellTexture("剑刃乱舞") },
    { ID.Eviscerate, "spell", "刺骨" },
    { ID.SliceAndDice, "spell", "切割" },
    { ID.Hemorrhage, "spell", "出血" },
    { ID.TricksOfTrade, "macro", "/cast [@focus,help,exists][@targettarget,help] 嫁祸诀窍", GetSpellTexture("嫁祸诀窍") },
    { ID.Redirect, "spell", "转嫁" },
    { ID.Rupture, "spell", "割裂" },
    { ID.Garrote, "spell", "Garrote" },
    { ID.ExposeArmor, "spell", "破甲" },
    { ID.DeathImprint, "spell", "死亡印记" },
    { ID.Ambush, "spell", "伏击" },
    { ID.Vanish, "spell", "消失" },
    { ID.Premeditation, "spell", "预谋" },
    { ID.Shadowstep, "spell", "暗影步" },
    { ID.Stealth, "macro", "/cast !潜行", GetSpellTexture("潜行") },
    { ID.Envenom, "spell", "毒伤" },
    { ID.FanOfKnives, "spell", "刀扇" },
    { ID.GhostlyStrike, "spell", "鬼魅攻击" },
    { ID.Preparation, "spell", "伺机待发" },
    { -112, "macro", "/use 10\\n/use 通用热力工程炸药\\n/use [@player] 萨隆邪铁炸弹", 133035 },
    { -113, "macro", "/use 菊花茶", 132819 },
    { 6603, "macro", "/startattack" },
}

local function IsMainHandDagger()
    local itemID = GetInventoryItemID("player", INVSLOT_MAINHAND)
    if not itemID then return false end
    local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemID)
    return classID == 2 and subclassID == 15
end

-- 8码内敌人数量
local function getEnemyCount(dist)
    local count = 0
    local counted = {}
    for i = 1, 40 do
        local u = "nameplate" .. i
        if UnitExists(u) and UnitCanAttack("player", u) and not UnitIsDead(u) then
            if WeakAuras.CheckRange(u, dist, "<=") then
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

local function getHPPercent(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return 0 end
    local m = UnitHealthMax(unit)
    if m == 0 then return 0 end
    return (UnitHealth(unit) / m) * 100
end

local function APLCallback()
    local CastWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
    local NextSpellID = 6603
    local inCombat = UnitAffectingCombat("player")
    local StealthDur = VF_getBuff("player", ID.Stealth, "HELPFUL|PLAYER")
    local StealthCD = VF_getSpellCD(ID.Stealth)
    --潜行
    if not inCombat and StealthDur <= 0 and StealthCD <= 0 then
        return ID.Stealth
    end

    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDead("target") then
        return 6603
    end

    local inMeleeRange = (IsSpellInRange(GetSpellInfo(ID.Hemorrhage), "target") == 1)
    local GCD = VF_getSpellCD(61304)
    local _, RedirectCount = VF_getBuff("player", ID.RedirectCharge, "HELPFUL|PLAYER")
    local EnergyMax = UnitPowerMax("player", 3)
    local Energy = math.min(EnergyMax, UnitPower("player", 3) + math.ceil(GCD*10))
    if math.max(0, VF_getBuff("player", ID.T9Buff, "HELPFUL|PLAYER") - GCD) > CastWindow then 
        Energy = Energy + 40
    end
    local CP = GetComboPoints("player", "target")
    local TargetDeadTime = VF_getTargetDeadTime()
    local TargetExecuteTime = VF_getTargetDeadTime(35)
    local HpPct = getHPPercent("target")
    local inBossFight = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
    local isMoving = GetUnitSpeed("player") > 0
    if intoSmartAOE and (getEnemyCount(8) < 3) then intoSmartAOE = false end
    local AOECount = getEnemyCount(5)
    local ShadowstepCD = VF_getSpellCD(ID.Shadowstep)
    local BladeFlurryCD = math.max(0, VF_getSpellCD(ID.BladeFlurry) - GCD)
    local ShadowDanceCD = VF_getSpellCD(ID.ShadowDance)
    local PremeditationCD = VF_getSpellCD(ID.Premeditation)
    local VanishCD = VF_getSpellCD(ID.Vanish)
    local TricksOfTradeCD = math.max(0, VF_getSpellCD(ID.TricksOfTrade) - GCD)
    local DeathImprintCD = math.max(0, VF_getSpellCD(ID.DeathImprint) - GCD)
    local GhostlyStrikeCD = math.max(0, VF_getSpellCD(ID.GhostlyStrike) - GCD)
    local PreparationCD = math.max(0, VF_getSpellCD(ID.Preparation) - GCD)

    local MoSDur = math.max(0, VF_getBuff("player", ID.MasterOfSubtlety, "HELPFUL|PLAYER") - GCD)
    local ToTDur = math.max(0, VF_getBuff("player", ID.TricksOfTrade, "HELPFUL|PLAYER") - GCD)
    local SnDDur = math.max(0, VF_getBuff("player", ID.SliceAndDice, "HELPFUL|PLAYER") - GCD)
    local ShadowDanceDur = math.max(0, VF_getBuff("player", ID.ShadowDance, "HELPFUL|PLAYER") - GCD)
    local BladeFlurryDur = math.max(0, VF_getBuff("player", ID.BladeFlurry, "HELPFUL|PLAYER") - GCD)
    local hasBloodlust = ((VF_getBuff("player", 2825, "HELPFUL") > 0) or (VF_getBuff("player", 32182, "HELPFUL") > 0))

    local RuptureDur = math.max(0, VF_getDebuff("target", ID.Rupture, "HARMFUL|PLAYER") - GCD)
    local GarroteDur = math.max(0, VF_getDebuff("target", ID.Garrote, "HARMFUL|PLAYER") - GCD)
    local DIDur = math.max(0, VF_getDebuff("target", ID.DeathImprint, "HARMFUL|PLAYER") - GCD)
    local EADur = math.max(
        math.max(0, VF_getDebuff("target", ID.ExposeArmor, "HARMFUL") - GCD),
        math.max(0, VF_getDebuff("target", ID.SunderArmor, "HARMFUL") - GCD)
    )
    local tricksReady = WAParam.config.autoTricksTrade and TricksOfTradeCD <= CastWindow and IsInGroup()
        and ((RuptureDur > 1 and SnDDur >= 1 and ShadowDanceDur <= 0) or StealthDur > 0)
        and ((UnitExists("focus") and UnitIsFriend("player", "focus") and not UnitIsDead("focus") and not UnitIsUnit("focus", "player") and (IsSpellInRange(GetSpellInfo(ID.TricksOfTrade), "focus") == 1))
            or (UnitExists("targettarget") and UnitIsFriend("player", "targettarget") and not UnitIsDead("targettarget") and not UnitIsUnit("targettarget", "player") and (IsSpellInRange(GetSpellInfo(ID.TricksOfTrade), "targettarget") == 1)))

    for i = 1, 1 do
        --预谋
        if PremeditationCD <= CastWindow and CP <= 3 and (ShadowDanceDur > 0 or (StealthDur > 0 and SnDDur <= 0)) then
            NextSpellID = ID.Premeditation
            break
        end

        --赌剔骨
        if inCombat and inBossFight
            and ((AOECount >= 2 and BladeFlurryDur > 0 and ((CP >= 3 and BladeFlurryDur <= 1) or CP >= 5)) --剑舞AOE中优先剔骨
                or (CP >= 5 and DIDur > 0 and DIDur <= 0.5) --死印快结束赌个剔骨再考虑续切割
                or (CP >= 4 and ShadowDanceDur > 1 and DIDur > 0)) then --影舞伏击剔骨不要求强制5星
            NextSpellID = ID.Eviscerate
            break
        end

        --切割
        if CP >= 1 and TargetDeadTime >= 5 and ShadowDanceDur <= 0
            and (SnDDur <= 0 or (SnDDur <= math.min(3,DIDur,RuptureDur) and BladeFlurryDur <= 0 and MoSDur <= 0 and ToTDur <= 0))then
            NextSpellID = ID.SliceAndDice
            break
        end

        --嫁祸
        if inBossFight and tricksReady and DIDur > 0 and SnDDur > 0 and TargetExecuteTime >= 10 then
            NextSpellID = ID.TricksOfTrade
            break
        end

        -- 转嫁
        if SnDDur > CastWindow and RedirectCount > CP then
            NextSpellID = ID.Redirect
            break
        end

        --5星终结技：割裂 > 死亡印记 > 剔骨
        if CP >= 5 then
            if ShadowDanceDur > 0 and ShadowDanceDur <= 1 and Energy >= 40 and DIDur > 0 then --影舞最后1秒可以考虑赌个暴击伏击
                NextSpellID = ID.Ambush
                break
            end
            if RuptureDur <= 0 and StealthDur <= 0 and ShadowDanceDur <= 0 and TargetDeadTime > 10 then
                NextSpellID = ID.Rupture
                break
            end
            if DeathImprintCD <= CastWindow and DIDur <= 0 and TargetDeadTime > 6
                and ((RuptureDur > (6+CastWindow)) or StealthDur > 0 or ShadowDanceDur > 0 or MoSDur > 0)then
                NextSpellID = ID.DeathImprint
                break
            end
            if (DIDur > 0 or TargetDeadTime <= 10 or (RuptureDur <= (6+CastWindow) and RuptureDur > 0)) then
                NextSpellID = ID.Eviscerate
                break
            end
        end

        --破甲
        if inBossFight and CP >= 1
            and EADur <= CastWindow and TargetDeadTime >= CP*6*0.75
            and StealthDur <= 0 and ShadowDanceDur <= 0 and MoSDur <= 0 then
            NextSpellID = ID.ExposeArmor
            break
        end

        -- AOE模式，手动打过刀扇击中3个以上敌人就持续刀扇到不足3个或手动打出血为止
        if intoSmartAOE then
            if inBossFight and BladeFlurryCD <= CastWindow and SnDDur >= 3 then
                NextSpellID = ID.BladeFlurry
                break
            end
            NextSpellID = ID.FanOfKnives
            break
        end

        --爆发
        if WAParam.config.autoBurst and inBossFight and inCombat and inMeleeRange and EADur > 0 then
            --特殊AOE场景战自动剑舞
            if MutiTargetEncounterIDlist[CurrentEncounterID] and (AOECount >= 2) and BladeFlurryCD <= CastWindow and SnDDur >= 3 then
                NextSpellID = ID.BladeFlurry
                break
            end
            --伺机待发判定 35%血，消失CD，没有锁喉,不在排除名单，关键爆发都丢
            if (inBossFight and PreparationCD < CastWindow --[[and 排除名单（感觉目前没啥好排除的）]]
                and ShadowDanceDur <= 0 and StealthDur <= 0 and GarroteDur <= 0 and HpPct < 35
                and VanishCD > 15 and BladeFlurryCD > 15 and ShadowstepCD > 5)
            then
                NextSpellID = ID.Preparation
                break
            end
            --消失、影舞
            if StealthDur <= 0 and not intoSmartAOE and RuptureDur > 0 and TargetExecuteTime >= 15 and SnDDur >= 6 then
                if VanishCD <= CastWindow and MoSDur <= CastWindow
                    and not VanishBlacklist[UnitName("target")] and Energy >= 40 and CP <= 2
                    and (DIDur > 1 or BladeFlurryDur > 3) then
                    NextSpellID = ID.Vanish
                    break
                end
                if ShadowDanceCD <= CastWindow and CP <= 3 and (Energy >= (90-(ToTDur+MoSDur*2)*2))
                    and(MoSDur > 0 or VanishCD > 15)then
                    NextSpellID = ID.ShadowDance
                    break
                end
            end
            if VF_getItemCD(10) == 0 then
                return -112
            end
            if Energy < 40 and (ShadowDanceDur > 0 or (VanishCD >= 118 and VanishCD <120))--影舞或刚消失
                and VF_getItemCD(7676) == 0 and GetItemCount(7676) > 0 then
                return -113
            end
        end

        --伏击/绞喉
        if (StealthDur > 0 or (ShadowDanceDur > 0 and CP < 5)) then
            NextSpellID = ID.Ambush
            break
        end

        --攒星
        if CP < 5 then
            --临终毒伤泄星
            if TargetDeadTime <= 2 and CP >= 3 then
                NextSpellID = ID.Envenom
                break
            end
            --低星数且爆发还早,或者没切割割裂的时候可以少留一点能量，否则攒池
            local EnergyRes = EnergyMax-10
            if (CP <= 3 and ShadowDanceCD > 4 and VanishCD > 4 and BladeFlurryCD > 4)
                or RuptureDur <= 1 or SnDDur <= 1 or DIDur <= 1 then
                EnergyRes = EnergyRes - 20
            end
            if CP <= 4 and RuptureDur > 7 and RuptureDur <= 11 and DIDur <= 0 then
                EnergyRes = EnergyRes - 20
            end
            if (Energy >= EnergyRes and ShadowDanceDur <= 0) or (Energy >= EnergyMax-5) or (TargetDeadTime <= 4) then
                NextSpellID = ID.Hemorrhage
                break
            end
        end
    end

    --自动暗影步
    -- 刺骨/伏击/绞喉直接增伤，其他近战技能不在近战范围时
    if ShadowstepCD <= CastWindow and not ShadowStepBlacklist[UnitName("target")]
        and ((NextSpellID == ID.Ambush or NextSpellID == ID.Eviscerate)
            or (not inMeleeRange and NextSpellID ~= 6603 and NextSpellID ~= ID.Premeditation and NextSpellID ~= ID.Redirect
                and NextSpellID ~= ID.Stealth and NextSpellID ~= ID.SliceAndDice and NextSpellID ~= ID.TricksOfTrade
                and NextSpellID ~= ID.ExposeArmor and NextSpellID ~= ID.DeathImprint)) then
        NextSpellID = ID.Shadowstep
    end

    --绞喉伏击选择,主手不是匕首或者没有背智能绞喉，不存在绞喉dot且预期能跳完dot且不再剑舞状态可以换绞喉
    if NextSpellID == ID.Ambush and (not IsMainHandDagger() or NoBackList[UnitName("target")] or (TargetDeadTime > 20 and GarroteDur <= 0 and BladeFlurryDur <= 0)) then
        NextSpellID = ID.Garrote
    end

    --移动战穿插鬼魅
    if NextSpellID == ID.Hemorrhage and GhostlyStrikeCD < CastWindow and isMoving then
        NextSpellID = ID.GhostlyStrike
    end

    return NextSpellID
end

local Manager = CreateFrame("Frame",nil, UIParent)
Manager:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
Manager:RegisterEvent("ENCOUNTER_START")
Manager:RegisterEvent("ENCOUNTER_END")
Manager:SetScript("OnEvent", function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, srcGUID, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
            if ((srcGUID == WeakAuras.myGUID) and (subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_MISSED")) then
                if WAParam.config.smartAOE then
                    if(spellID == ID.FanOfKnives) then
                        FoKCount = FoKCount + 1
                        if (FoKCount > 2) then
                            intoSmartAOE = true
                        else
                            intoSmartAOE = false
                        end
                    elseif (spellID == ID.Hemorrhage) then
                        intoSmartAOE = false
                    end
                end
            elseif (UnitAffectingCombat("player") and (srcGUID == WeakAuras.myGUID) and ( subEvent == "SPELL_CAST_SUCCESS")) then
                if(spellID == ID.FanOfKnives) then
                    FoKCount = 0
                end
            end
        elseif event == "ENCOUNTER_START" then
            local encounterID = ...
            if encounterID and encounterID > 0 then
                CurrentEncounterID = encounterID
            else
                CurrentEncounterID = 0
            end
        elseif event == "ENCOUNTER_END" then
            CurrentEncounterID = 0
        end
end)


aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback
aura_env.APLName = "影舞索妮娅"


-- ===== actions.init 加载时自定义代码 =====
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
VF_registerAPL(aura_env)