--[[
aura id: 夜雨_双手增强萨
aura uid: cFtyjx8(sFU
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
贡献人：夜雨-双手增强萨 
版本：双手增强萨1.15
]]--
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_SHAMAN_ENHANCEMENT_WLK then return end APL_SHAMAN_ENHANCEMENT_WLK = true
local C = aura_env.config or {}
local function b(v)
    if v == true then return true end
    if v == false then return false end
    if type(v) == "number" then return v ~= 0 end
    if type(v) == "string" then 
        local s = string.lower(tostring(v))
        return s == "true" or s == "1" or s == "on" or s == "yes"
    end
    return false
end
local function n(v, default)
    if type(v) == "number" then return v end
    if type(v) == "string" then
        local num = tonumber(v)
        if num then return num end
    end
    return default or 0
end
local Config = {
    UseFeralSpirit           = b(C.useFeralSpirit),
    UseFireElemental         = b(C.useFireElemental),
    ShamanisticRageThreshold = n(C.shamanisticRageThreshold, 30),
    UseAutoKick              = b(C.autoKick),
    LightningShield_Combat   = b(C.combatShield),
    Windfury_PreCombat       = b(C.preCombatWF),
    SmartAOE                 = b(C.smartAOE),
}
local SPELL = {
    LavaLash           = 1272856,
    LavaLash2          = 60103,
    Stormstrike        = 17364,
    LavaBurst          = 60043,
    FlameShock         = 49233,
    LightningBolt      = 49238,
    ChainLightning     = 49271,
    EarthShock         = 49231,
    FireNova           = 61657,
    MagmaTotem         = 58734,
    LightningShield    = 49281,
    WindfuryWeapon     = 58804,
    FeralSpirit        = 51533,
    FireElemental      = 2894,
    CallOfElements     = select(7, GetSpellInfo("元素的召唤")) or 66842,
    ShamanisticRage    = 30823,
    WindShear          = 57994,
    --StrengthOfEarthTotem = select(7, GetSpellInfo("大地之力图腾")) or 58643,
    --ManaSpringTotem      = select(7, GetSpellInfo("法力之泉图腾")) or 58774,
    --WindfuryTotem        = select(7, GetSpellInfo("风怒图腾")) or 8512,
}
local AURA = {
    MaelstromWeapon = 1283511,
    LightningShield = 49281,
    --ImprovedIcyTalons = 55610,
    --WindfuryTotem = 8512,
    --WindfuryTotem2 = 8515,
    --WindfuryTotem3 = 65990
}
local ActionList = {
    {SPELL.LavaLash,        "spell", "熔岩猛击"},
    {SPELL.Stormstrike,     "spell", "风暴打击"},
    {SPELL.LavaBurst,       "spell", "熔岩爆裂"},
    {SPELL.FlameShock,      "spell", "烈焰震击"},
    {SPELL.LightningBolt,   "spell", "闪电箭"},
    {SPELL.ChainLightning,  "spell", "闪电链"},
    {SPELL.EarthShock,      "spell", "大地震击"},
    {SPELL.FireNova,        "spell", "火焰新星"},
    {SPELL.MagmaTotem,      "spell", "熔岩图腾"},
    {SPELL.LightningShield, "spell", "闪电之盾"},
    {SPELL.WindfuryWeapon,  "spell", "风怒武器"},
    {SPELL.FeralSpirit,     "macro", "/cast 狂暴(种族特长)\\n/cast 血性狂怒(种族特长)\\n/cast 石像形态(种族特长)\\n/use 10\\n/use 13\\n/use 14\\n/cast 野性狼魂\\n/petdefensive\\n/petattack", GetSpellTexture("野性狼魂")},
    {SPELL.FireElemental,   "spell", "火元素图腾"},
    {SPELL.CallOfElements,  "spell", "元素的召唤"},
    {SPELL.ShamanisticRage, "spell", "萨满之怒"},
    {SPELL.WindShear,       "spell", "风剪"},
    --{SPELL.StrengthOfEarthTotem, "spell", "大地之力图腾"},
    --{SPELL.ManaSpringTotem, "spell", "法力之泉图腾"},
    --{SPELL.WindfuryTotem,   "spell", "风怒图腾"},
    {6603, "macro", "/startattack\\n/petattack [combat]"},
    {-112, "macro", "/use 10\\n/use 通用热力工程炸药\\n/use [@player] 萨隆邪铁炸弹", 133035}
}
-- 图腾状态追踪
local TotemState = {
    magmaGUID = nil,
    placedTime = 0,
    targetGUID = nil,
    lastTickDestGUID = nil,
    lastTickAny = 0,
    lastTickTarget = 0,
    lastTotemStart = 0,
}
local petAttackPending = false
local petAttackStep = 0
local lastPetAttackTime = 0
local lastTargetGUID = ""
-- 辅助函数
local function getEnemyCount()
    local count = 0
    local countedGUIDs = {}
    for i = 1, 40 do
        local unitid = "nameplate" .. i
        if UnitExists(unitid) and UnitCanAttack("player", unitid) and not UnitIsDead(unitid) then
            if WeakAuras and WeakAuras.CheckRange(unitid, 8, "<=") then
                local guid = UnitGUID(unitid)
                if guid and not countedGUIDs[guid] then
                    countedGUIDs[guid] = true
                    count = count + 1
                end
            end
        end
    end
    return count
end
local function shouldKick()
    if not UnitExists("target") or UnitIsDead("target") then return false end
    local castName, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if not castName then
        castName, _, _, _, _, _, _, notInterruptible = UnitChannelInfo("target")
    end
    return castName and (not notInterruptible or notInterruptible == false)
end
local function GetFireTotemInfo()
    if not GetTotemInfo then return false, "" end
    local haveTotem, totemName = GetTotemInfo(1)
    return haveTotem and totemName and totemName ~= "", totemName or ""
end
local function HasAllTotems()
    if not GetTotemInfo then return false end
    for slot = 1, 4 do
        local haveTotem, totemName = GetTotemInfo(slot)
        if not haveTotem or not totemName or totemName == "" then
            return false
        end
    end
    return true
end
-- 熔岩图腾需求判断
local function GetTotemNeeds()
    local fireTotemExists, fireTotemName = GetFireTotemInfo()
    local hasFireElemental = (fireTotemName == "火元素图腾")
    local currentTargetGUID = UnitGUID("target") or ""
    local now = GetTime()
    local targetIsBoss = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
    
    -- 火元素在场：禁止重插火系
    if hasFireElemental then
        return true, true, false
    end
    
    -- 无火系图腾：必须补
    if not fireTotemExists then
        TotemState.magmaGUID = nil
        return false, false, true
    end
    
    -- 火系图腾非熔岩：需要重插
    local haveMagma = fireTotemName and (fireTotemName:find("熔岩图腾") or fireTotemName:find("Magma Totem"))
    if not haveMagma then
        TotemState.magmaGUID = nil
        return true, false, true
    end
    
    -- 同步GetTotemInfo，检测新图腾
    local _, _, startTime, duration = GetTotemInfo(1)
    if startTime and math.abs(startTime - TotemState.lastTotemStart) > 0.5 then
        TotemState.lastTotemStart = startTime
        TotemState.placedTime = startTime
        TotemState.targetGUID = currentTargetGUID
        TotemState.lastTickDestGUID = nil
        TotemState.lastTickAny = startTime
        TotemState.lastTickTarget = startTime
    end
    
    local needMagma = false
    
    -- 条件1：图腾快过期（提前2秒）
    if startTime and duration then
        local remain = (startTime + duration) - now
        if remain < 2 then
            needMagma = true
        end
    end
    
    -- 条件2：图腾4秒内没造成任何伤害
    if not needMagma and TotemState.lastTickAny >= TotemState.placedTime then
        if (now - TotemState.lastTickAny > 4) then
            needMagma = true
        end
    end
    
    -- 条件3：转火场景（图腾打小怪，目标切BOSS）
    if not needMagma 
    and TotemState.lastTickDestGUID 
    and TotemState.lastTickDestGUID ~= currentTargetGUID
    and now - TotemState.lastTickAny <= 4 then
        if now - TotemState.lastTickTarget > 4 then
            if WeakAuras and WeakAuras.CheckRange("target", 8, "<=") then
                needMagma = true
            end
        end
    end
    
    -- 条件4：对当前目标断档（BOSS 3秒，小怪 5秒）
    if not needMagma
    and TotemState.lastTickDestGUID == currentTargetGUID
    and TotemState.lastTickTarget >= TotemState.placedTime
    and now - TotemState.lastTickTarget > (targetIsBoss and 3 or 5) then
        needMagma = true
    end
    
    -- 条件5：目标切换后，图腾从未对新目标造成伤害（BOSS严格，小怪宽松）
    if not needMagma
    and currentTargetGUID ~= ""
    and currentTargetGUID ~= TotemState.targetGUID
    and now - TotemState.placedTime > (targetIsBoss and 3 or 999) then
        if now - TotemState.lastTickTarget > 4 then
            if WeakAuras and WeakAuras.CheckRange("target", 8, "<=") then
                needMagma = true
            end
        end
    end
    
    return true, false, needMagma
end
-- 火焰新星命中判断
local function canFireNova()
    local fireTotemExists, fireTotemName = GetFireTotemInfo()
    if not fireTotemExists then
        return false
    end
    
    -- 非熔岩图腾（火元素、灼热图腾等），火焰新星可直接施放
    local haveMagma = fireTotemName and (fireTotemName:find("熔岩图腾") or fireTotemName:find("Magma Totem"))
    if not haveMagma then
        return true
    end
    
    -- 熔岩图腾：使用 TotemState 追踪判断命中
    local now = GetTime()
    local targetIsBoss = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
    
    -- 精确命中：图腾最近2.5秒对当前目标造成伤害（改用lastTickTarget，避免AOE时最后一击目标干扰）
    if now - TotemState.lastTickTarget <= 2.5 then
        return true
    end
    
    -- BOSS不允许兜底
    if targetIsBoss then
        return false
    end
    
    -- 兜底：图腾刚放3秒内且目标5码内 or 8码内2+敌人
    if (now - TotemState.placedTime < 3 and WeakAuras and WeakAuras.CheckRange("target", 5, "<="))
        or (getEnemyCount() >= 2) then
        return true
    end
    return false
end
-- APL主循环
local function APLCallback_EnhancementRotation()
    local NextSpellID = 6603
    if not VF_getSpellCD then return NextSpellID end
    
    if petAttackPending then
        petAttackStep = petAttackStep + 1
        if petAttackStep <= 3 then
            return 6603
        else
            petAttackStep = 0
            petAttackPending = false
            lastPetAttackTime = GetTime()
        end
    end
    
    local currentTargetGUID = UnitGUID("target") or ""
    if currentTargetGUID ~= lastTargetGUID then
        lastTargetGUID = currentTargetGUID
        if UnitExists("pet") and not UnitIsDead("pet")
        and UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
            petAttackPending = true
        end
    end
    
    if GetTime() - lastPetAttackTime > 2.5 then
        if UnitExists("pet") and not UnitIsDead("pet")
        and UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
            lastPetAttackTime = GetTime()
            petAttackPending = true
        end
    end
    
    local GCD = (VF_getSpellCD(61304) or 0)
    local CastWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400) / 1000
    local inCombat = UnitAffectingCombat("player")
    local inMeleeRange = UnitExists("target") and (IsSpellInRange("风暴打击", "target") == 1)
    local inBossFight = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
    local isMoving = (GetUnitSpeed("player") > 0)
    
    local _, maelstromStacks = VF_getBuff("player", AURA.MaelstromWeapon, "HELPFUL|PLAYER")
    maelstromStacks = maelstromStacks or 0
    
    local llCD  = math.max(0, math.min((VF_getSpellCD(SPELL.LavaLash)),(VF_getSpellCD(SPELL.LavaLash2))) - GCD)
    local ssCD  = math.max(0, (VF_getSpellCD(SPELL.Stormstrike) or 999) - GCD)
    local lbCD  = math.max(0, (VF_getSpellCD(SPELL.LavaBurst) or 999) - GCD)
    local fsCD  = math.max(0, (VF_getSpellCD(SPELL.FlameShock) or 999) - GCD)
    local ltCD  = math.max(0, (VF_getSpellCD(SPELL.LightningBolt) or 999) - GCD)
    local esCD  = math.max(0, (VF_getSpellCD(SPELL.EarthShock) or 999) - GCD)
    local fnCD  = math.max(0, (VF_getSpellCD(SPELL.FireNova) or 999) - GCD)
    local mtCD  = math.max(0, (VF_getSpellCD(SPELL.MagmaTotem) or 999) - GCD)
    local clCD  = math.max(0, (VF_getSpellCD(SPELL.ChainLightning) or 999) - GCD)
    local lshCD = math.max(0, (VF_getSpellCD(SPELL.LightningShield) or 999) - GCD)
    local coeCD = math.max(0, (VF_getSpellCD(SPELL.CallOfElements) or 999) - GCD)
    local feralCD = math.max(0, (VF_getSpellCD(SPELL.FeralSpirit) or 999) - GCD)
    local feCD  = math.max(0, (VF_getSpellCD(SPELL.FireElemental) or 999) - GCD)
    local srCD  = math.max(0, (VF_getSpellCD(SPELL.ShamanisticRage) or 999) - GCD)
    local kickCD = math.max(0, (VF_getSpellCD(SPELL.WindShear) or 999) - GCD)
    
    local flameShockRem = math.max(0, (VF_getDebuff("target", SPELL.FlameShock, "HARMFUL|PLAYER") or 0) - GCD)
    local lightningShieldRem = math.max(0, (VF_getBuff("player", AURA.LightningShield, "HELPFUL|PLAYER") or 0) - GCD)
    
    local fireTotemExists, hasFireElemental, needMagmaTotem = GetTotemNeeds()
    
    local enemyCount = getEnemyCount()
    local isAOE = Config.SmartAOE and (enemyCount >= 2)
    
    local manaMax = UnitPowerMax("player", 0)
    local manaPercent = manaMax > 0 and (UnitPower("player", 0) / manaMax) * 100 or 100
    
    -- 战前准备
    if not inCombat then
        if Config.Windfury_PreCombat then
            local hasMainhandEnchant, mainHandExpiration = GetWeaponEnchantInfo()
            if ((not hasMainhandEnchant) or (mainHandExpiration and mainHandExpiration < 300000)) then
                return SPELL.WindfuryWeapon
            end
        end
        
        if lightningShieldRem <= 0 and lshCD <= CastWindow then
            return SPELL.LightningShield
        end
        if not HasAllTotems() and coeCD <= CastWindow then
            return SPELL.CallOfElements
        end
        return 6603
    end
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDead("target") then
        return 6603
    end
    if Config.UseAutoKick and shouldKick() and kickCD <= CastWindow then
        return SPELL.WindShear
    end
    if Config.UseFeralSpirit and inBossFight and inMeleeRange and feralCD <= CastWindow then
        return SPELL.FeralSpirit
    end
    if inBossFight and inMeleeRange and VF_getItemCD(10) <= CastWindow then
        return -112
    end
    if manaPercent < Config.ShamanisticRageThreshold and srCD <= CastWindow then
        return SPELL.ShamanisticRage
    end
    -- AOE循环（2+目标）
    if isAOE then
        if not isMoving and mtCD <= CastWindow and needMagmaTotem then
            return SPELL.MagmaTotem
        end
        
        if flameShockRem <= 0 and fsCD <= CastWindow then
            return SPELL.FlameShock
        end
        if enemyCount >= 3 then
            if canFireNova() and fnCD <= CastWindow then
                return SPELL.FireNova
            end
            if inMeleeRange and llCD <= CastWindow then
                return SPELL.LavaLash
            end
        else
            if inMeleeRange and llCD <= CastWindow then
                return SPELL.LavaLash
            end
            if canFireNova() and fnCD <= CastWindow then
                return SPELL.FireNova
            end
        end
        
        if maelstromStacks == 5 then
            if clCD <= CastWindow then
                return SPELL.ChainLightning
            elseif lbCD <= CastWindow and flameShockRem > 0 then
                return SPELL.LavaBurst
            elseif ltCD <= CastWindow then
                return SPELL.LightningBolt
            end
        end
        
        if inMeleeRange and ssCD <= CastWindow then
            return SPELL.Stormstrike
        end
        
        if maelstromStacks >= 4 and clCD <= CastWindow then
            return SPELL.ChainLightning
        end
    else
        -- 单目标循环
        if flameShockRem <= 0 and fsCD <= CastWindow then
            return SPELL.FlameShock
        end
        
        if inMeleeRange and llCD <= CastWindow then
            return SPELL.LavaLash
        end
        
        if inMeleeRange and ssCD <= CastWindow then
            return SPELL.Stormstrike
        end
        
        if maelstromStacks == 5 and flameShockRem > 0 and lbCD <= CastWindow then
            return SPELL.LavaBurst
        end
        if maelstromStacks == 5 and ltCD <= CastWindow then
            return SPELL.LightningBolt
        end
        
        if not isMoving and mtCD <= CastWindow and needMagmaTotem then
            return SPELL.MagmaTotem
        end
        
        if canFireNova() and fnCD <= CastWindow then
            return SPELL.FireNova
        end
    end
    if Config.UseFireElemental and inBossFight and not isMoving and feCD <= CastWindow then
        return SPELL.FireElemental
    end
    if flameShockRem > 3 and esCD <= CastWindow then
        return SPELL.EarthShock
    end
    if not inMeleeRange and maelstromStacks >= 4 and flameShockRem > 0 and lbCD <= CastWindow then
        return SPELL.LavaBurst
    end
    
    if not inMeleeRange and maelstromStacks >= 4 and ltCD <= CastWindow then
        return SPELL.LightningBolt
    end
    if Config.LightningShield_Combat and lightningShieldRem <= 0 and lshCD <= CastWindow then
        return SPELL.LightningShield
    end
    -- 最低优先级：补缺失风怒图腾
    --[[local hasAirBuff = ((VF_getBuff("player", AURA.ImprovedIcyTalons, "HELPFUL") > 0) 
                        or (VF_getBuff("player", AURA.WindfuryTotem, "HELPFUL") > 0)
                        or (VF_getBuff("player", AURA.WindfuryTotem2, "HELPFUL") > 0)
                        or (VF_getBuff("player", AURA.WindfuryTotem3, "HELPFUL") > 0))
    if not isMoving and not hasAirBuff then
        return SPELL.WindfuryTotem
    end]]
    return NextSpellID
end
-- 战斗日志事件处理
local function onCLEUEvent()
    local _, subEvent, _, srcGUID, srcName, srcFlags, _, destGUID, destName, destFlags, _, spellId, spellName = CombatLogGetCurrentEventInfo()
    local myGUID = (WeakAuras and WeakAuras.myGUID) or UnitGUID("player")
    local now = GetTime()
    
    -- 捕获熔岩图腾GUID
    if myGUID and srcGUID == myGUID and subEvent == "SPELL_SUMMON" then
        if spellId == SPELL.MagmaTotem then
            TotemState.magmaGUID = destGUID
            TotemState.placedTime = now
            TotemState.lastTotemStart = now
            TotemState.targetGUID = UnitGUID("target") or ""
            TotemState.lastTickDestGUID = nil
            TotemState.lastTickAny = now
            TotemState.lastTickTarget = now
        end
    end
    
    -- 熔岩图腾伤害追踪
    if TotemState.magmaGUID and srcGUID == TotemState.magmaGUID then
        if subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_PERIODIC_DAMAGE" then
            TotemState.lastTickAny = now
            TotemState.lastTickDestGUID = destGUID
            if destGUID == UnitGUID("target") then
                TotemState.lastTickTarget = now
            end
        elseif subEvent == "UNIT_DIED" or subEvent == "SPELL_AURA_REMOVED" then
            if destGUID == TotemState.magmaGUID then
                TotemState.magmaGUID = nil
            end
        end
    end
    
    if not myGUID or srcGUID ~= myGUID then return end
    
    -- 熔岩图腾施法成功兜底
    if subEvent == "SPELL_CAST_SUCCESS" and spellId == SPELL.MagmaTotem then
        if not TotemState.magmaGUID then
            TotemState.placedTime = now
            TotemState.lastTotemStart = now
            TotemState.targetGUID = UnitGUID("target") or ""
            TotemState.lastTickDestGUID = nil
            TotemState.lastTickAny = now
            TotemState.lastTickTarget = now
        end
    end
    
    if subEvent == "SPELL_CAST_SUCCESS" and spellId == SPELL.FeralSpirit then
        petAttackPending = true
    end
end
local Manager = CreateFrame("Frame", "EnhancementAPLManager", UIParent)
Manager:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
Manager:SetScript("OnEvent", function(_, event)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            onCLEUEvent()
        end
end)
aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_EnhancementRotation
aura_env.APLName = "夜雨双手增强"

-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)