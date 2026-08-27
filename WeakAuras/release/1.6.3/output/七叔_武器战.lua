--[[
aura id: 七叔_武器战
aura uid: qTDkx8oApDs
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
  武器战打地鼠 APL - 泰坦重铸时光服
  作者：Sevenuncle
]]
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_ARMS_WARRIOR_SELFVF then return end APL_ARMS_WARRIOR_SELFVF = true
local WAParam = aura_env
-- 技能ID
local S = {
    Rend = --[[select(7, GetSpellInfo("撕裂")) or ]]47465,
    Overpower = --[[select(7, GetSpellInfo("压制")) or ]]7384,
    MortalStrike = --[[select(7, GetSpellInfo("致死打击")) or ]]47486,
    Bladestorm = --[[select(7, GetSpellInfo("利刃风暴")) or ]]46924,
    BladestormBurstMacro = --[[-select(7, GetSpellInfo("利刃风暴")) or ]]-46924,
    Slam = --[[select(7, GetSpellInfo("猛击")) or ]]47475,
    --HeroicStrike = select(7, GetSpellInfo("英勇打击")),
    --Cleave = select(7, GetSpellInfo("顺劈斩")),
    SweepingStrikes = --[[select(7, GetSpellInfo("横扫攻击")) or ]]12328,
    Execute = --[[select(7, GetSpellInfo("斩杀")) or ]]47471,
    Charge = --[[select(7, GetSpellInfo("冲锋")) or ]]11578,
    Intercept = --[[select(7, GetSpellInfo("拦截")) or ]]20252,
    HeroicThrow = --[[select(7, GetSpellInfo("英勇投掷")) or ]]57755,
    Bloodrage = --[[select(7, GetSpellInfo("血性狂暴")) or ]]2687,
    Recklessness = --[[select(7, GetSpellInfo("鲁莽")) or ]]1719,
    ShatteringThrow = --[[select(7, GetSpellInfo("碎裂投掷")) or ]]64382,
    ThunderClap = --[[select(7, GetSpellInfo("雷霆一击")) or ]]47502,
    BerserkerRage = --[[select(7, GetSpellInfo("狂暴之怒")) or ]]18499,
    Hamstring = --[[select(7, GetSpellInfo("断筋")) or ]]1715,
    Attack = 6603,
    TasteForBlood = 60503,
    SuddenDeath = 52437,
    RendWound = 413763,
    Heroism = 32182,
    Bloodlust = 2825,
    Destroyer = 1283507,  -- 破坏能手 Buff ID
}
-- 捆绑英勇打击的宏（高怒单体用）
local S_HS = {
    Rend = -100000 - S.Rend,
    Overpower = -100000 - S.Overpower,
    MortalStrike = -100000 - S.MortalStrike,
    Slam = -100000 - S.Slam,
    Execute = -100000 - S.Execute,
    Attack = -100000 - S.Attack,
}
-- 捆绑顺劈斩的宏（高怒AOE用）
local S_CL = {
    Rend = -200000 - S.Rend,
    Overpower = -200000 - S.Overpower,
    MortalStrike = -200000 - S.MortalStrike,
    Slam = -200000 - S.Slam,
    Execute = -200000 - S.Execute,
    Attack = -200000 - S.Attack,
}
local ActionList = {
    -- 捆绑英勇打击的宏（高怒单体）
    { S_HS.Rend, "macro", "/cast [stance:2/3] !战斗姿态\\n/cast 撕裂\\n/cast !英勇打击", GetSpellTexture("撕裂") },
    { S_HS.Overpower, "macro", "/cast [stance:2/3] !战斗姿态\\n/cast 压制\\n/cast !英勇打击", GetSpellTexture("压制") },
    { S_HS.MortalStrike, "macro", "/cast [stance:2/3] !战斗姿态\\n/cast 致死打击\\n/cast !英勇打击", GetSpellTexture("致死打击") },
    { S_HS.Slam, "macro", "/cast 猛击\\n/cast !英勇打击", GetSpellTexture("猛击") },
    { S_HS.Execute, "macro", "/cast 英勇打击\\n/cast 斩杀", GetSpellTexture("斩杀") },
    { S_HS.Attack, "macro", "/startattack\\n/cast !英勇打击", GetSpellTexture("英勇打击") },
    -- 捆绑顺劈斩的宏（高怒AOE）
    { S_CL.Rend, "macro", "/cast [stance:2/3] !战斗姿态\\n/cast 撕裂\\n/cast !顺劈斩", GetSpellTexture("撕裂") },
    { S_CL.Overpower, "macro", "/cast [stance:2/3] !战斗姿态\\n/cast 压制\\n/cast !顺劈斩", GetSpellTexture("压制") },
    { S_CL.MortalStrike, "macro", "/cast [stance:2/3] !战斗姿态\\n/cast 致死打击\\n/cast !顺劈斩", GetSpellTexture("致死打击") },
    { S_CL.Slam, "macro", "/cast 猛击\\n/cast !顺劈斩", GetSpellTexture("猛击") },
    { S_CL.Execute, "macro", "/cast 顺劈斩\\n/cast 斩杀", GetSpellTexture("斩杀") },
    { S_CL.Attack, "macro", "/startattack\\n/cast !顺劈斩", GetSpellTexture("顺劈斩") },
    -- 原有技能
    { S.Rend, "macro", "/cast [stance:2/3] !战斗姿态\\n/cast 撕裂", GetSpellTexture("撕裂") },
    { S.Overpower, "macro", "/cast [stance:2/3] !战斗姿态\\n/cast 压制", GetSpellTexture("压制") },
    { S.MortalStrike, "macro", "/cast [stance:2/3] !战斗姿态\\n/cast 致死打击", GetSpellTexture("致死打击") },
    { S.Slam, "spell", "猛击" },
    { S.Execute, "spell", "斩杀" },
    { S.Attack, "macro", "/startattack" },
    { S.HeroicThrow, "spell", "英勇投掷" },
    { S.Hamstring, "spell", "断筋" },
    { S.Recklessness, "macro", "/cast [stance:1/2] !狂暴姿态\\n/cast 鲁莽", GetSpellTexture("鲁莽") },
    { S.ShatteringThrow, "spell", "碎裂投掷" },
    { S.Charge, "macro", "/cast [stance:2/3] !战斗姿态\\n/cast 冲锋", GetSpellTexture("冲锋") },
    { S.Intercept, "macro", "/cast [stance:1/2] !狂暴姿态\\n/cast 拦截", GetSpellTexture("拦截") },
    { S.BladestormBurstMacro, "macro", "/cqs\\n/cast 狮心(种族特长)\\n/cast 狂暴(种族特长)\\n/cast 血性狂怒(种族特长)\\n/cast 石像形态(种族特长)\\n/use 13\\n/use 14\\n/cast 利刃风暴\\n/cqs", GetSpellTexture("利刃风暴") },
    { S.Bladestorm, "spell", "利刃风暴" },
    { S.SweepingStrikes, "spell", "横扫攻击" },
    { S.ThunderClap, "macro", "/cast [stance:2/3] !战斗姿态\\n/cast 雷霆一击", GetSpellTexture("雷霆一击") },
    { S.Bloodrage, "spell", "血性狂暴" },
    { -112, "macro", "/use 10\\n/use 通用热力工程炸药\\n/use [@player] 萨隆邪铁炸弹", 133035 }
}
-- 平砍计时
local SwingTimer = {
    baseSpeed = 0, lastSwing = 0, pauseTotal = 0,
    isPaused = false
}
local function getSwingRemain()
    SwingTimer.baseSpeed = UnitAttackSpeed("player") or SwingTimer.baseSpeed
    local remain = SwingTimer.baseSpeed - (GetTime() - SwingTimer.lastSwing - SwingTimer.pauseTotal)
    return math.max(0, remain)
end
local BladestormActive = false
local BladestormStart = 0
local intoCleaveMode = false
local function getNearbyCount()
    local count = 0
    local counted = {}
    for i = 1, 40 do
        local unitid = "nameplate" .. i
        if UnitExists(unitid) and UnitCanAttack("player", unitid) and not UnitIsDead(unitid) then
            if WeakAuras.CheckRange(unitid, 5, "<=") then
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
local function getHPPercent(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return 100 end
    local m = UnitHealthMax(unit)
    if m == 0 then return 100 end
    return (UnitHealth(unit) / m) * 100
end
SwingTimer.baseSpeed = UnitAttackSpeed("player") or 3.6
SwingTimer.lastSwing = GetTime()
local Manager = CreateFrame("Frame", "ArmsWarriorAPLManager", UIParent)
Manager:SetScript("OnUpdate", function(_, elapsed)
        if SwingTimer.isPaused then
            SwingTimer.pauseTotal = SwingTimer.pauseTotal + elapsed
        end
end)
Manager:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
Manager:RegisterEvent("UNIT_SPELLCAST_START")
Manager:RegisterEvent("UNIT_SPELLCAST_STOP")
Manager:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
Manager:RegisterEvent("PLAYER_REGEN_ENABLED")
Manager:SetScript("OnEvent", function(_, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, srcGUID, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
            if srcGUID ~= UnitGUID("player") then return end
            if (subEvent == "SWING_DAMAGE" or subEvent == "SWING_MISSED") then
                SwingTimer.lastSwing = GetTime()
                SwingTimer.pauseTotal = 0
                SwingTimer.isPaused = false
            elseif subEvent == "SPELL_CAST_SUCCESS" and spellID == S.Bladestorm then
                BladestormActive = true
                BladestormStart = GetTime()
            end
        elseif event == "UNIT_SPELLCAST_START" then
            if ... == "player" then
                SwingTimer.isPaused = true
            end
        elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" then
            if ... == "player" then
                SwingTimer.isPaused = false
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            SwingTimer.lastSwing = GetTime()
            SwingTimer.pauseTotal = 0
            SwingTimer.isPaused = false
        end
end)
local function hasFear()
    local count = C_LossOfControl.GetActiveLossOfControlDataCountByUnit("player")
    for i = 1, count do
        local data = C_LossOfControl.GetActiveLossOfControlDataByUnit("player", i)
        if data and data.locType and data.locType == "FEAR" then
            return true
        end
    end
    return false
end
local function APLCallback_ArmsWarrior()
    local msWindow = 1
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and not UnitIsDeadOrGhost("target")
    local isBoss = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
    local inMeleeRange = (IsSpellInRange("致死打击", "target") == 1)
    local gcdRemain = VF_getSpellCD(61304) or 0
    local win = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
    local function cd(id)
        return math.max(0, (VF_getSpellCD(id) or 999) - gcdRemain)
    end
    local rage = UnitPower("player", 1) or 0
    
    -- 狂暴之怒（解恐惧）
    if cd(S.BerserkerRage) <= win and hasFear() then
        return S.BerserkerRage
    end
    
    -- 鲁莽（冲锋之前，BOSS起手爆发）
    if hasTarget and isBoss and cd(S.Recklessness) <= win then
        if ((not inCombat) or (inCombat and rage <= 10)) then 
            return S.Recklessness
        end
    end
    
    -- 距离判定（冲锋/拦截/英勇投掷）
    if hasTarget then
        local chargeCD = cd(S.Charge)
        local interceptCD = cd(S.Intercept)
        local heroThrowCD = cd(S.HeroicThrow)
        
        if not inMeleeRange and (IsSpellInRange("冲锋", "target") == 1) then
            if chargeCD <= win then
                return S.Charge
            end
            if rage >= 10 and chargeCD < 17 and chargeCD > win and interceptCD <= win then
                return S.Intercept
            end
        end
        
        if isBoss and heroThrowCD <= win and not inMeleeRange then
            return S.HeroicThrow
        end
    end
    -- 血性狂暴
    if rage < 75 and cd(S.Bloodrage) <= win then
        return S.Bloodrage
    end
    
    -- 断筋PvP（敌对+距离+无debuff）
    if hasTarget and UnitIsPlayer("target") and UnitCanAttack("player", "target") and inMeleeRange then
        if (math.max(0, VF_getDebuff("target", S.Hamstring, "HARMFUL") - gcdRemain) <= 0) and cd(S.Hamstring) <= win then
            return S.Hamstring
        end
    end
    
    -- 碎裂投掷（冲锋之后，BOSS近身）
    if hasTarget and isBoss then
        if cd(S.ShatteringThrow) <= win and (math.max(0, VF_getDebuff("target", S.ShatteringThrow, "HARMFUL") - gcdRemain) <= 0) and rage >= 25 then
            return S.ShatteringThrow
        end
        
        if VF_getItemCD(10) <= win and inMeleeRange then
            return -112
        end
    end
    
    if (not inCombat) or (not hasTarget) then 
        return S.Attack
    end
    -- 利刃风暴持续中
    if BladestormActive then
        if GetTime() - BladestormStart >= 6 then
            BladestormActive = false
        end
        return S.Bladestorm
    end
    local hp = getHPPercent("target")
    local TfBDUr = math.max(0, VF_getBuff("player", S.TasteForBlood, "HELPFUL|PLAYER") - gcdRemain)
    local hasTfB = (TfBDUr > 0)
    local hasSD = (math.max(0, VF_getBuff("player", S.SuddenDeath, "HELPFUL|PLAYER") - gcdRemain) > 0)
    local hasRend = (math.max(0, VF_getDebuff("target", S.Rend, "HARMFUL|PLAYER") - gcdRemain) > 0)
    local hasSS = (math.max(0, VF_getBuff("player", S.SweepingStrikes, "HELPFUL|PLAYER") - gcdRemain) > 0)
    local _, destroyerStacks = VF_getBuff("player", S.Destroyer, "HELPFUL|PLAYER")
    local targetDeadTime = VF_getTargetDeadTime() or 999
    local swingRemain = getSwingRemain()
    local rendCD = cd(S.Rend)
    local opCD = cd(S.Overpower)
    local msCD = cd(S.MortalStrike)
    local bsCD = cd(S.Bladestorm)
    local slamCD = cd(S.Slam)
    local exeCD = cd(S.Execute)
    local tcCD = cd(S.ThunderClap)
    
    -- AOE模式切换
    local AOECount = getNearbyCount()
    if WAParam.config.SmartAOE and AOECount >= 2 then
        intoCleaveMode = true
    else
        intoCleaveMode = false
    end
    -- 普通/英勇/顺劈自动选择
    local function autoSelectSpell(id)
        if rage >= 75 --[[ and swingRemain <= 0.3]] then
            if intoCleaveMode and ((not hasSS) or AOECount >= 3) then
                return -200000 - id
            else
                return -100000 - id
            end
        end
        return id
    end
    -- 1. 撕裂（无撕裂时优先补）
    if not hasRend and rendCD <= win then
        return autoSelectSpell(S.Rend)
    end
    
    -- 2. 致死打击（卡CD使用）
    if msCD <= win then
        return autoSelectSpell(S.MortalStrike)
    end
    -- 3. 压制
    if opCD <= win and hasTfB then
        return autoSelectSpell(S.Overpower)
    end
    
    -- 4. 斩杀只有点了猝死天赋或者高怒最后一击且打猛击导致的延时会打不出普攻时才用
    if exeCD <= win and msCD > msWindow and rage > 65 
        and (hasSD or (hp < 20 and (targetDeadTime <= math.max(gcdRemain+0.5, swingRemain+0.5)))) then
        return autoSelectSpell(S.Execute)
    end
    -- 5. AOE
    if intoCleaveMode then
        if rage >= 30 and cd(S.SweepingStrikes) < win then
            return S.SweepingStrikes
        end
        if rage >= 55 and AOECount > 5 and tcCD <= win then
            return S.ThunderClap
        end
    end
    
    -- 6. 利刃风暴
    if WAParam.config.AutoBladestorm and bsCD <= win and targetDeadTime > 3 then
        if isBoss and (math.max(0, VF_getBuff("player", S.Heroism, "HELPFUL")-gcdRemain) > 0) or (math.max(0, VF_getBuff("player", S.Bloodlust, "HELPFUL")-gcdRemain) > 0) then
            return S.BladestormBurstMacro
        else
            return S.Bladestorm
        end
    end
    
    -- 7. 猛击
    if msCD > msWindow and rage >= 25 and slamCD <= win and destroyerStacks < 3 then
        if TfBDUr <= 0 or TfBDUr >= 5 then
            return autoSelectSpell(S.Slam)
        end
    end
    -- 8. 都在等致死CD可主动填充一下英勇或者顺劈，怒气不够自然变白刀
    return autoSelectSpell(S.Attack)
end
aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_ArmsWarrior
aura_env.APLName = "七叔武器战"

-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)