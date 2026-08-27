--[[
aura id: 五月&XT&如夏_惩戒骑
aura uid: nDOmt81MHuW
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
  惩戒骑 APL 
  贡献人：五月晴空 TachyonXue 如夏
]]

if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_RET_PALADIN_WLK_SELFVF then return end APL_RET_PALADIN_WLK_SELFVF = true

local WAParam = aura_env
local CurrentEncounterID = 0

-- 【五月】平砍计时器全局表
local SwingTimers = { player = nil }

-- 目标剩余血量百分比
local function getHPPercent(unit)
    unit = unit or "target"
    if not UnitExists(unit) then
        return 100
    end
    local currentHP = UnitHealth(unit)
    local maxHP = UnitHealthMax(unit)
    if maxHP == 0 then
        return 0
    end
    local hpPercent = (currentHP / maxHP) * 100
    hpPercent = math.floor(hpPercent * 10) / 10
    return math.max(0, math.min(100, hpPercent))
end

-- 玩家剩余蓝量百分比
local function getManaPercent()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    return maxMana > 0 and (mana / maxMana) * 100 or 100
end

local function isTargetUndeadOrDemon()
    if not UnitExists("target") then
        return false
    end
    -- 如果是玩家则直接返回false（因为玩家没有生物类型）
    if UnitIsPlayer("target") then
        return false
    end
    local creatureType = UnitCreatureType("target")
    if creatureType == "Undead" or creatureType == "Demon" or
    creatureType == "亡灵" or creatureType == "恶魔" then
        return true
    end
    return false
end

local LastAOECheck = 0
local CachedAOECount = 0
local function getAOECount(range)
    local checkTime = GetTime()
    if checkTime - LastAOECheck > 0.1 then
        LastAOECheck = checkTime
        local count = 0
        local countedGUIDs = {}
        for i = 1, 40 do
            local unitid = "nameplate" .. i
            if UnitExists(unitid) and UnitCanAttack("player", unitid) and not UnitIsDead(unitid) then
                local _, maxRange = WeakAuras.GetRange(unitid)
                if maxRange and maxRange <= range then
                    local guid = UnitGUID(unitid)
                    if guid and not countedGUIDs[guid] then
                        countedGUIDs[guid] = true
                        count = count + 1
                    end
                end
            end
        end
        --【五月0.81】AOE计数存入缓存
        CachedAOECount = count
        return count
        --【五月0.81】若计数时间小于0.1秒，则直接返回缓存结果
    else
        return CachedAOECount
    end
end

local SpellId = {
    SealVengeance = 31801, SealCommand = 20375, SealWisdom = 20166,
    DivinePlea = 54428, JudgementWisdom = 53408, HammerOfWrath = 48806,
    CrusaderStrike = 35395, DivineStorm = 53385, Consecration = 48819, Exorcism = 48801,
    AvengingWrath = 31884,
    Salvation = 1038,
    DivinePrayer = 1298728,
    HolyWrath = 48817,
    BurstMacroPlaceholder = 9999998, AutoAttack = 6603, ArtOfWar = 59578,
}

local AuraId = {
    Justice = 1299090,
    SanctifiedWrathBuff = 1298723,
    BurdenOfLight = 1299086,
    ArtOfWar = SpellId.ArtOfWar,
    SealVengeance = SpellId.SealVengeance,
    SealCommand = SpellId.SealCommand,
    SealWisdom = SpellId.SealWisdom,
    Piety = 1298725,
    DebuffVengeance = 31803
}

-- 爆发宏
local BurstMacroBody = "/cast 复仇之怒\\n/cast 狮心(种族特长)\\n/cast 狂暴(种族特长)\\n/cast 血性狂怒(种族特长)\\n/cast 石像形态(种族特长)\\n/use 10\\n/use 13\\n/use 14\\n/use 通用热力工程炸药\\n/use [@player] 萨隆邪铁炸弹"

local ActionList = {
    { SpellId.SealCommand, "spell", "命令圣印" },
    { SpellId.DivinePlea, "spell", "神圣恳求" }, 
    { SpellId.JudgementWisdom, "spell", "智慧审判" },
    { SpellId.HammerOfWrath, "spell", "愤怒之锤" },
    { SpellId.CrusaderStrike, "spell", "十字军打击" },
    { SpellId.DivineStorm, "spell", "神圣风暴" },
    { SpellId.Consecration, "spell", "奉献" },
    { SpellId.Exorcism, "spell", "驱邪术" },
    { SpellId.HolyWrath, "spell", "神圣愤怒" },
    { SpellId.Salvation, "spell", "拯救之手" },
    { SpellId.BurstMacroPlaceholder, "macro", BurstMacroBody, GetSpellTexture("复仇之怒") },
    { SpellId.DivinePrayer, "macro", "/cast [nochanneling] 祈求圣光", GetSpellTexture("祈求圣光") },
    { 6603, "macro", "/startattack" },
    { -112, "macro", "/use 10\\n/use 通用热力工程炸药\\n/use [@player] 萨隆邪铁炸弹", 133035 },
}

local faction = UnitFactionGroup("player")
if faction == "Horde" then
    SpellId.SealVengeance = 348704 --改腐蚀
    AuraId.SealVengeance = SpellId.SealVengeance
    AuraId.DebuffVengeance = 53742
    table.insert(ActionList,{SpellId.SealVengeance,"spell","腐蚀圣印"})
else
    table.insert(ActionList,{SpellId.SealVengeance,"spell","复仇圣印"})
end

-- 【五月】平砍计时
local function GetNextSwingTimeMS()
    local last = SwingTimers.player
    if not last then
        return nil  -- 尚未记录到平砍事件
    end
    local WeaponSpeed = UnitAttackSpeed("player")
    if not WeaponSpeed or WeaponSpeed <= 0 then
        return nil  -- 无效武器速度
    end
    local nextTime = last + WeaponSpeed
    local remainingSec = nextTime - GetTime()
    if remainingSec < 0 then
        remainingSec = 0  -- 轻微延迟导致的负值
    end
    return math.floor(remainingSec * 1000 + 0.5)  -- 返回整数毫秒
end

local meleeGcd = 1.5

local function APLCallback_RetPaladin()
    local win = (tonumber(GetCVar("SpellQueueWindow")) or 400) / 1000
    local gcdRemain = VF_getSpellCD(61304) or 0
    local pietyRem, pietyStacks = VF_getBuff("player", AuraId.Piety, "HELPFUL")
    
    --- 引导优先
    if (UnitChannelInfo("player")) == "祈求圣光" then 
        local pleaCd = math.max(0, (VF_getSpellCD(SpellId.DivinePlea) or 999) - gcdRemain)
        local SalvationCd = math.max(0, (VF_getSpellCD(SpellId.Salvation) or 999) - gcdRemain)
        local manaPct = getManaPercent() or 100
        -- 只要神圣恳求冷却就绪且蓝量低于90%，就在引导中使用
        if pleaCd <= win and manaPct < 90 then
            return SpellId.DivinePlea
        end
        if SalvationCd <= win and pietyStacks >=3 then
            return SpellId.Salvation
        end
        return SpellId.DivinePrayer
    end
    
    local NextSpellID = SpellId.AutoAttack
    
    for i = 1, 1 do
        -- 【五月0.82】武器速度
        local WeaponSpeed = UnitAttackSpeed("player")
        if not WeaponSpeed or WeaponSpeed <= 0 then
            WeaponSpeed = 4.0
        end
        
        local isTargetBoss = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
        local TargetDeadTime = VF_getTargetDeadTime()
        
        -- 【五月】获取目标距离
        local function getTargetDistance()
            if not UnitExists("target") or not UnitCanAttack("player", "target") then
                return 999  -- 无效目标返回超出范围
            end
            local _, maxRange = WeakAuras.GetRange("target")
            return maxRange or 999
        end
        local targetDist = getTargetDistance()
        local isMoving = GetUnitSpeed("player") > 0
        local TargetOutOfMelee = targetDist > 2
        local aoeCount = getAOECount(8) or 0
        local hpPct = getHPPercent("target") or 100
        local manaPct = getManaPercent() or 100
        
        local cd = function(id)
            return math.max(0, (VF_getSpellCD(id) or 999) - gcdRemain)
        end
        
        local pleaCd = cd(SpellId.DivinePlea)
        local judgeCd = cd(SpellId.JudgementWisdom)
        local howCd = cd(SpellId.HammerOfWrath)
        local csCd = cd(SpellId.CrusaderStrike)
        local dsCd = cd(SpellId.DivineStorm)
        local consCd = cd(SpellId.Consecration)
        local exoCd = cd(SpellId.Exorcism)
        local wingsCd = cd(SpellId.AvengingWrath)
        local hwCd = cd(SpellId.HolyWrath)
        local PrayerChannelCd = cd(SpellId.DivinePrayer)
        local aowRem = math.max(0, (VF_getBuff("player", AuraId.ArtOfWar, "HELPFUL|PLAYER") or 0) - gcdRemain)
        local sealVenRem = math.max(0, (VF_getBuff("player", AuraId.SealVengeance, "HELPFUL|PLAYER") or 0) - gcdRemain)
        local sealCmdRem = math.max(0, (VF_getBuff("player", AuraId.SealCommand, "HELPFUL|PLAYER") or 0) - gcdRemain)
        local justiceRem, justiceSt = VF_getBuff("player", AuraId.Justice, "HELPFUL")
        local sanctifiedBuffRem = VF_getBuff("player", AuraId.SanctifiedWrathBuff, "HELPFUL")
        local fuDanRem = VF_getDebuff("player", AuraId.BurdenOfLight, "HARMFUL")
        local targetSealRem, targetSealSt = VF_getDebuff("target", AuraId.DebuffVengeance, "HARMFUL|PLAYER")
        targetSealRem = math.max(0, (targetSealRem-gcdRemain))
        local hasBurden = fuDanRem > win and fuDanRem <= 140
        local ForbRem = VF_getDebuff("player", 25771, "HARMFUL") or 0
        
        if isTargetBoss and WAParam.config.enableDivinePrayer and not isMoving and targetDist <= 8 then
            -- 【五月0.95】初次爆发时，2层即可引导
            if PrayerChannelCd <= win and not hasBurden and TargetDeadTime > 13 then
                if pietyStacks == 0 then
                    if justiceSt == 2 then
                        NextSpellID = SpellId.DivinePrayer
                        break
                    end
                    if justiceSt == 5 then
                        NextSpellID = SpellId.DivinePrayer
                        break
                    end
                elseif pietyRem >= 3 then
                    if (justiceSt + pietyStacks) >= 5 then
                        NextSpellID = SpellId.DivinePrayer
                        break
                    end
                end
            end
            -- 【五月】翅膀逻辑：有裁决BUFF则开翅膀
            if wingsCd <= win and ForbRem < 90 then
                if sanctifiedBuffRem > 0 then
                    NextSpellID = SpellId.BurstMacroPlaceholder
                    break
                end
            end
        end
        
        if WAParam.config.enableSealTwisting and manaPct >= 40 then
            if isTargetBoss then --boss战
                if aoeCount >= 3 then
                    -- 有圣印，主目标有DOT，且剩余10秒以上，切命令圣印
                    if targetSealSt > 4 and targetSealRem >= 10 and sealCmdRem <= 0 then
                        NextSpellID = SpellId.SealCommand
                        break
                        -- 主目标DOT剩余时间小于武器速度+win（武器速度内必有平砍），切回腐蚀/复仇
                    elseif (targetSealRem <= (math.max(WeaponSpeed,gcdRemain) + win)) and sealVenRem <= 0 then 
                        NextSpellID = SpellId.SealVengeance
                        break
                    end
                else-- 非AOE场景，补腐蚀/复仇
                    if sealVenRem <= 0 then 
                        NextSpellID = SpellId.SealVengeance
                        break
                    end
                end
            else --小怪战
                if aoeCount >= 3 and sealCmdRem <= 0 then
                    NextSpellID = SpellId.SealCommand
                    break
                elseif aoeCount == 1 and sealVenRem <= 0 then
                    NextSpellID = SpellId.SealVengeance
                    break
                end
            end
        end
        
        -- 5目标以上AOE，优先风暴和奉献
        if aoeCount >= 5 then
            if dsCd <= win then
                NextSpellID = SpellId.DivineStorm
                break
            elseif manaPct >= 40 and consCd <= win then
                NextSpellID = SpellId.Consecration
                break
            end
        end
        
        -- 愤怒之锤
        if hpPct < 20 and howCd <= win then
            NextSpellID = SpellId.HammerOfWrath
            break
        end
        
        -- 【五月0.97】审判：目标在近战范围外（2~10码），且审判冷却就绪(目标为BOSS，待爆发状态不打)
        if not isTargetBoss or hasBurden or not (pietyStacks == 0 and justiceSt < 2) then
            if judgeCd <= win and TargetOutOfMelee and targetDist <= 10 then
                NextSpellID = SpellId.JudgementWisdom
                break
            end
        end
        -- 【五月0.97】神圣风暴：目标在近战范围外（2~7码），且神圣风暴冷却就绪(目标为BOSS，待爆发状态不打)
        if not isTargetBoss or hasBurden or not (pietyStacks == 0 and justiceSt < 2) then
            if dsCd <= win and TargetOutOfMelee and targetDist <= 7 then
                NextSpellID = SpellId.DivineStorm
                break
            end
        end
        -- 【五月0.97】驱邪术：目标在近战范围外（2~30码），且驱邪术冷却就绪(目标为BOSS，待爆发状态不打)
        if not isTargetBoss or hasBurden or not (pietyStacks == 0 and justiceSt < 2) then
            if exoCd <= win and TargetOutOfMelee and targetDist <= 30 then
                NextSpellID = SpellId.Exorcism
                break
            end
        end
        
        -- 【五月1.10】低蓝量或爆发中审判优先
        if (manaPct < 30 or sanctifiedBuffRem > 0) and judgeCd <= win then
            NextSpellID = SpellId.JudgementWisdom
            break
        end
        
        -- 【五月1.10】正义不满5层，优先十字军打击
        if justiceSt < 5 and csCd <= win then
            NextSpellID = SpellId.CrusaderStrike
            break
        end
        
        -- 【五月】AOE场合或距离下一次平砍1.5s以内可以赌，优先释放
        local nextSwingMS = GetNextSwingTimeMS()
        if (aoeCount >= 2 or nextSwingMS and nextSwingMS <= 1500) and dsCd <= win then
            NextSpellID = SpellId.DivineStorm
            break
        end
        
        if csCd <= win then
            NextSpellID = 35395
            break
        end     
        
        -- 审判
        if judgeCd <= win then
            NextSpellID = SpellId.JudgementWisdom
            break
        end
        
        -- 神圣风暴
        if dsCd <= win then
            NextSpellID = SpellId.DivineStorm
            break
        end
        
        -- 【五月0.98】工程手套
        if isTargetBoss and not TargetOutOfMelee and hasBurden and VF_getItemCD(10) <= win then
            return -112
        end
        
        -- 【五月0.98】神圣恳求：待爆发时只在引导中开
        if hasBurden then
            local pleaPick  -- 用于标记是否决定施放恳求
            -- 法力低于40%：需要十字军打击和审判都在冷却中，且恳求就绪
            if manaPct < 40 and csCd > win and judgeCd > win and pleaCd <= win then
                pleaPick = SpellId.DivinePlea
                -- 法力低于60%：需要十字军打击、审判、神圣风暴、奉献都在冷却中，且恳求就绪
            elseif manaPct < 60 and csCd > win and judgeCd > win and dsCd > win and consCd > win and pleaCd <= win then
                pleaPick = SpellId.DivinePlea
                -- 法力低于95%：需要十字军打击、审判、神圣风暴、奉献、驱邪术都在冷却中，且恳求就绪
            elseif manaPct < 95 and csCd > win and judgeCd > win and dsCd > win and consCd > win and exoCd > win and pleaCd <= win then
                pleaPick = SpellId.DivinePlea
            end
            -- 如果满足任一条件，则施放神圣恳求并跳出循环
            if pleaPick then
                NextSpellID = pleaPick
                break
            end
        end
        
        -- 【五月】奉献：蓝低于40%或距离目标8码以上不施放，可自行修改
        local consOk = manaPct >= 40 and consCd <= win
        if consOk and targetDist <= 8 then
            NextSpellID = SpellId.Consecration
            break
        end
        
        -- 【五月0.98】驱邪术（待爆发不挤占GCD才打，避免推迟爆发时间）
        if aowRem > 0 and exoCd <= win then
            if hasBurden then
                NextSpellID = SpellId.Exorcism
                break
            elseif csCd > (win + meleeGcd) and judgeCd > (win + meleeGcd) and dsCd > (win + meleeGcd) and consCd > (win + meleeGcd) then
                NextSpellID = SpellId.Exorcism
                break
            end
        end
        
        -- 【五月】神圣愤怒：目标为亡灵或恶魔释放
        if isTargetUndeadOrDemon() and hwCd <= win then
            NextSpellID = SpellId.HolyWrath
            break
        end
        break
    end
    return NextSpellID
end

local Manager = CreateFrame("Frame", "RetPaladinAPLManager", UIParent)
Manager:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
Manager:RegisterEvent("ENCOUNTER_START")
Manager:RegisterEvent("ENCOUNTER_END")
Manager:RegisterEvent("UNIT_ATTACK_SPEED")
Manager:SetScript("OnEvent", function(_, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, srcGUID, _, _, _, _, _, _, _, spellId = CombatLogGetCurrentEventInfo()
            if srcGUID == UnitGUID("player") and (subEvent == "SWING_DAMAGE" or subEvent == "SWING_MISSED") then
                SwingTimers.player = GetTime()
            end
        elseif event == "ENCOUNTER_START" then
            local encounterID = ...  -- 第一个参数就是 encounterID
            if encounterID and encounterID > 0 then
                CurrentEncounterID = encounterID
            else
                CurrentEncounterID = 0
            end
        elseif event == "ENCOUNTER_END" then
            CurrentEncounterID = 0
        elseif event == "UNIT_ATTACK_SPEED" then
            local unit = ...
            if unit == "player" then
                SwingTimers.player = nil   -- 武器速度变化，清零计时器
            end     
        end
end)

aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_RetPaladin
aura_env.APLName = "五月XT如夏"

-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)