--[[
aura id: 哀冬_猫咪猛挠
aura uid: je31AJGrE7T
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
原生哀冬的猫咪猛挠逻辑
版本：2.81
作者：哀冬
鸣谢：不愿透露ID的cksky先生
]]
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
if APL_CAT_WLK then return end; APL_CAT_WLK = true
local WAParam = aura_env
local CastWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
local intoSmartAOE = false
local SwipeCount = 0
local isFirstBerserkDone = false
local LostRipTime = 0
local LostRakeTime = 0
local ImportantBuffList = 
{
    75456,--284龙鳞
    75458,--271龙鳞
    71561,--277意志-力量
    71560,--277意志-急速
    71556,--277意志-敏捷
    71484,--264意志-力量
    71492,--264意志-急速
    71485,--264意志-敏捷
    71541,--264尖牙
    71401,--251尖牙
    67772,--258裁决-敏捷
    67703,--245裁决-敏捷
    1249838,--258旌旗，物品ID249820
    67671,--200旌旗
    65019,--雷神符石
    65024,--黑暗物质
    71403,--毒蝎
    60233,--伟大-敏捷
    72412,--277戒指480AP
    59620,--武器附魔狂暴
    42976,--武器附魔斩杀
    55775,--披风剑刃刺绣
}
local ActionList = {
    {-112, "item", 10},
    {50334, "spell", "狂暴"},
    {16857, "spell", "精灵之火（野性）"},
    {select(7, GetSpellInfo("割裂")), "spell", "割裂"},
    {52610, "spell", "野蛮咆哮"},
    {select(7, GetSpellInfo("裂伤（豹）")), "spell", "裂伤（豹）"}, 
    {select(7, GetSpellInfo("猛虎之怒")), "spell", "猛虎之怒"},
    {select(7, GetSpellInfo("斜掠")), "spell", "斜掠"},
    {62078, "spell", "横扫（豹）"},
    {select(7, GetSpellInfo("凶猛撕咬")), "spell", "凶猛撕咬"},
    {select(7, GetSpellInfo("撕碎")), "spell", "撕碎"},
    {768, "spell", "猎豹形态"},
    {6603, "macro", "/startattack"}
}
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
local function APLCallback_CatRotation()
    if (GetShapeshiftForm() ~= 3) then
        return 768
    end
    local NextSpellID = 6603
    for i = 1, 1 do
        local GCD = VF_getSpellCD(61304)
        local Energy = math.min(100, (UnitPower("player", 3)+math.ceil(GCD*10)))
        local CP = GetComboPoints("player", "target")
        local inMeleeRange = (IsSpellInRange(GetSpellInfo(ActionList[6][1]), "target") == 1)
        local inCombat = UnitAffectingCombat("player")
        local inBossFight = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
        local FFCD = math.max(0, VF_getSpellCD(16857)-GCD)
        local FuryCD = VF_getSpellCD(ActionList[7][1])
        local GloveCD = VF_getItemCD(10)
        local BerserkCD = math.max(0, GCD, VF_getSpellCD(50334)-GCD)
        local OOCDuration = VF_getBuff("player", 16870, "HELPFUL|PLAYER")
        local RoarDuration = 34
        if(GetSpellInfo("野蛮咆哮") ~= nil) then
            RoarDuration = math.max(0, VF_getBuff("player", 52610, "HELPFUL|PLAYER")-GCD)
        end
        local FuryDuration = math.max(0, VF_getBuff("player", ActionList[7][1], "HELPFUL|PLAYER")-GCD)
        local BerserkDuration = math.max(0, VF_getBuff("player", 50334, "HELPFUL|PLAYER")-GCD)
        local RakeDuration = math.max(0, VF_getDebuff("target", ActionList[8][1], "HARMFUL|PLAYER")-GCD)
        local RipDuration = math.max(0, VF_getDebuff("target", ActionList[4][1], "HARMFUL|PLAYER")-GCD)
        local ManagleDuration = math.max(0, VF_getDebuff("target", ActionList[6][1], "HARMFUL")-GCD, VF_getDebuff("target", 48564, "HARMFUL")-GCD, VF_getDebuff("target", 46857, "HARMFUL")-GCD, VF_getDebuff("target", 46855, "HARMFUL")-GCD)
        local isBleeding = (VF_getDebuff("target", ActionList[4][1], "HARMFUL") > GCD) or (VF_getDebuff("target", ActionList[8][1], "HARMFUL") > GCD) or (VF_getDebuff("target", 48568, "HARMFUL") > GCD) or (VF_getDebuff("target", 48672, "HARMFUL") > GCD) or (VF_getDebuff("target", 48660, "HARMFUL") > GCD) or (VF_getDebuff("target", 47465, "HARMFUL") > GCD) or (VF_getDebuff("target", 413763, "HARMFUL") > GCD)
        local CryingMoonDuration = math.max(0, VF_getBuff("player", 71175, "HELPFUL|PLAYER")-GCD)
        local ShredNow = false
        local isImportantBuffTiming = false
        local ImportantBuffCount = 0
        local AOECount = 0
        local TargetDeadTime = VF_getTargetDeadTime()
        
        if(inCombat == false) then
            isFirstBerserkDone = false
            if(OOCDuration == 0) then
                NextSpellID = 16857
                break
            elseif((ManagleDuration == 0) and inMeleeRange) then
                NextSpellID = ActionList[6][1]
                break
            end
        end
        
        if (inCombat) then
            
            if((LostRipTime == 0) and (RipDuration == 0)) then
                LostRipTime = GetTime()
            elseif((RipDuration > 0) or (inCombat ~= true)) then
                LostRipTime = 0
            end
            
            if((LostRakeTime == 0) and (RakeDuration == 0)) then
                LostRakeTime = GetTime()
            elseif((LostRakeTime > 0) or (inCombat ~= true)) then
                LostRakeTime = 0
            end
            
            if (intoSmartAOE == true) then
                AOECount = getNearbyCount()
                if (AOECount < 3) and (AOECount ~= 0) then
                    intoSmartAOE = false
                end
            end
            
            for j=1, #ImportantBuffList do
                local BuffDuration = math.max(0, VF_getBuff("player", ImportantBuffList[j], "HELPFUL|PLAYER")-GCD)
                if(BuffDuration > 0) then
                    ImportantBuffCount = ImportantBuffCount + 1
                    if(BuffDuration < 2) then
                        --print("Buff: "..ImportantBuffList[j].." is about to pass")
                        isImportantBuffTiming = true
                    end
                end
            end
            
            if (inBossFight and (GloveCD <= CastWindow) and (RoarDuration > 2)) then
                NextSpellID = -112
                break
            end
            
            if (WAParam.config.autoFirstBerserk and (isFirstBerserkDone == false) and inBossFight and (BerserkCD < CastWindow) and (FuryDuration > 0) and (RoarDuration > 5)) then
                NextSpellID = 50334
                break
            end
            
            if((BerserkDuration == 0) and inMeleeRange and (FuryCD < CastWindow) and (
                    ((FFCD < 1) and (UnitPower("player", 3) < (20-FFCD*10))) or
                    ((FFCD >= 1) and (UnitPower("player", 3) < 30))
            )) then
                NextSpellID = ActionList[7][1]
                break
            end
            
            if (((intoSmartAOE == false) and inMeleeRange and (RipDuration == 0) and (ManagleDuration > CastWindow) and (CP >= 5) and (RoarDuration > CastWindow)) and ((OOCDuration == 0) or (isBleeding == false)))then
                NextSpellID = ActionList[4][1]
                if(TargetDeadTime < 10) then
                    if(((BerserkDuration == 0) and (OOCDuration == 0) and (Energy < 60)) or
                        ((BerserkDuration == 0) and (OOCDuration > 0) and (Energy < 25)) or
                        ((BerserkDuration > 0) and (OOCDuration == 0) and (Energy < 38)) or
                        ((BerserkDuration > 0) and (OOCDuration > 0) and (Energy < 17))) then
                        NextSpellID = ActionList[10][1]
                    else
                        NextSpellID = ActionList[11][1]
                    end
                end
                break
            end
            
            if((intoSmartAOE == false) and inMeleeRange and (ManagleDuration > CastWindow) and isBleeding and (RoarDuration >= CastWindow) and
                (
                    ((CP >= 5) and (FuryCD < 28) and ((LostRipTime == 0) or ((GetTime()-LostRipTime) < 4)) and
                        (
                            ((RoarDuration >= 3) and (RipDuration > 8)) or 
                            (((FFCD <= 2) or (FuryCD <= 4)) and
                                (
                                    ((RoarDuration < 3) and (RipDuration > 8) and (ImportantBuffCount >= 1)) or 
                                    ((RoarDuration >11) and (RipDuration < 4) and (ImportantBuffCount >= 2)) or 
                                    ((RoarDuration <= 11) and (RoarDuration >= 7) and (RoarDuration > (RipDuration+3)) and (ImportantBuffCount >= 2))
                                )
                            )
                        )
                    ) or 
                    ((CP >= 5) and (TargetDeadTime < 10)) or
                    ((CP >= 4) and (TargetDeadTime < 3))
                )
            ) then
                local timing = math.ceil(math.min(BerserkDuration, 1))
                if(
                    ((BerserkDuration > 0) and (OOCDuration == 0) and (Energy < (38-timing*10))) or
                    ((BerserkDuration > 0) and (OOCDuration > 0) and (Energy < (17-timing*10))) or
                    ((BerserkDuration == 0) and (OOCDuration > 0) and (Energy < 25)) or
                    ((BerserkDuration == 0) and (OOCDuration == 0) and (Energy > 20) and 
                        ((Energy < 60) or ((Energy < 67) and (RakeDuration > 0)))
                    )
                ) then
                    NextSpellID = ActionList[10][1]
                    break
                else
                    ShredNow = true
                end
            end
            
            if ((OOCDuration == 0) and 
                (
                    ((CP >= 5) and (FFCD < CastWindow) and (RipDuration > GCD)) or 
                    ((CP < 5) and (FFCD <= GCD))
                ) and
                (
                    (inMeleeRange == false) or
                    ((BerserkDuration == 0) and (Energy <= (80+CastWindow*10))) or
                    --((BerserkDuration > 0) and (Energy <= math.ceil(math.min(2,BerserkDuration)*10)))
                    ((BerserkDuration > 0) and (Energy <= (80+CastWindow*10)) and (BerserkDuration >= math.ceil((Energy+30)/11)) and (isImportantBuffTiming == false)) or
                    ((BerserkDuration > 0) and (Energy <= 20))
                )
            )then
                NextSpellID = 16857
                break
            end
            
            if (inMeleeRange and (((RoarDuration <= GCD) and (CP >= 1)) or
                    ((RipDuration > 0) and (RoarDuration > 0) and (RipDuration <= (5*CP-16)) and (RoarDuration <= RipDuration +4)))) then
                NextSpellID = 52610
                break
            end
            
            if((intoSmartAOE == false) and inMeleeRange and
                ((ManagleDuration <= CastWindow) or
                    ((ManagleDuration < (5-CP)) and (ManagleDuration < (RipDuration+CastWindow))) or
                    ((ManagleDuration < 1) and (ManagleDuration < (RakeDuration+CastWindow))))
            ) then
                NextSpellID = ActionList[6][1]
                break
            end
            
            if(inMeleeRange and (RakeDuration == 0) and 
                (
                    ((CP ==0) and (RoarDuration == 0)) or
                    ((intoSmartAOE == false) and (ManagleDuration > CastWindow) and (RoarDuration > CastWindow) and 
                        (
                            (OOCDuration == 0) or
                            ((LostRakeTime > 0) and ((GetTime()-LostRakeTime) >= 2)) or
                            (isBleeding == false) or
                            (RoarDuration < CastWindow) or
                            (RipDuration < CastWindow) or
                            isImportantBuffTiming or
                            --(GetArmorPenetration() < 92) or
                            ((CryingMoonDuration > 0) and (CryingMoonDuration <= 9))
                        )
                    )
                )
            ) then
                NextSpellID = ActionList[8][1]
                if((intoSmartAOE == false) and ((TargetDeadTime < 6) or ((TargetDeadTime < 9) and isBleeding))) then
                    NextSpellID = ActionList[11][1]
                end
                break
            end
            
            if(intoSmartAOE and inMeleeRange and ((RoarDuration > CastWindow) or (OOCDuration > 0))) then
                NextSpellID = 62078
                break
            end
            
            if((intoSmartAOE == false) and inMeleeRange) then
                if((RakeDuration > CastWindow) and (RoarDuration == 0) and (CP ==0)) then
                    NextSpellID = ActionList[11][1]
                    break
                elseif((ManagleDuration > CastWindow) and (RoarDuration > CastWindow) and (isBleeding or (TargetDeadTime < 6)) and
                    (
                        (OOCDuration > 0) or
                        ((BerserkDuration > 0) and ((CP < 5) or ((CP >= 5) and (Energy >= 27)))) or
                        ((BerserkDuration == 0) and 
                            (
                                ((CP >= 5) and (Energy >= (57 + math.ceil(math.min(2,FuryCD,FFCD)*15)))) or
                                ((CP < 5) and (Energy >= (42 + math.ceil(math.min(2,FuryCD,FFCD,RipDuration)*15)))) or
                                ((RipDuration >= 1) and (isImportantBuffTiming or ShredNow))
                            )
                        )
                    )
                ) then
                    NextSpellID = ActionList[11][1]
                    break
                end
            end            
        end
        NextSpellID = 6603
    end
    local isSingle = ((GetNumGroupMembers()<2) and (UnitExists("targettarget") and UnitIsUnit("targettarget", "player")))
    if ((NextSpellID == ActionList[11][1]) and isSingle) then
        NextSpellID = ActionList[6][1]
    end
    return NextSpellID
end
local function intoCatForm()
    SetCVar("SpellQueueWindow", 200)
    CastWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
end
local function leaveCatForm()
    SetCVar("SpellQueueWindow", 400)
    CastWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
end
local function onCLEUEvent(event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, srcGUID, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
        if ((srcGUID == WeakAuras.myGUID) and (subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_MISSED")) then
            if WAParam.config.smartSwipe then
                if(spellID == 62078) then
                    SwipeCount = SwipeCount + 1
                    if (SwipeCount > 2) then
                        intoSmartAOE = true
                    else
                        intoSmartAOE = false
                    end
                elseif ((spellID == ActionList[11][1]) or (spellID == ActionList[6][1])) then
                    intoSmartAOE = false
                end
            end
        elseif (UnitAffectingCombat("player") and (srcGUID == WeakAuras.myGUID) and ((GetShapeshiftForm() == 3)) and ( subEvent == "SPELL_CAST_SUCCESS")) then
            if(spellID == 62078) then
                SwipeCount = 0
            end
            if(spellID == 50334) then
                isFirstBerserkDone = true
            end
        end
    end
end
local Manager = CreateFrame("Frame","WLKCatAPLManager", UIParent)
Manager:SetScript("OnShow", intoCatForm)
Manager:SetScript("OnHide", leaveCatForm)
Manager:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
Manager:SetScript("OnEvent", function(self, e, ...)
        if (e == "COMBAT_LOG_EVENT_UNFILTERED") then
            onCLEUEvent(e)
        end
end)
RegisterStateDriver(Manager, "visibility", "[stance:3] show; hide")
if(GetShapeshiftForm() == 3) then
    intoCatForm()
end
aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_CatRotation
aura_env.APLName = "猫咪猛挠"

-- ===== actions.init 加载时自定义代码 =====
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
VF_registerAPL(aura_env)