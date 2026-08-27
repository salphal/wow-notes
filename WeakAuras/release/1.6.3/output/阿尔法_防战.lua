--[[
aura id: 阿尔法_防战
aura uid: a1phaPr0tWar4
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
  防战一键 APL - 泰坦重铸时光服
  作者：阿尔法
  仇恨优先：盾猛卡CD + 复仇触发 + 毁灭打击填充 + 雷霆/挫志保持
]]
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_PROT_WARRIOR_ALPHA then return end APL_PROT_WARRIOR_ALPHA = true
local WAParam = aura_env
local S = {
    ShieldSlam = 47488,        -- 盾牌猛击
    Revenge = 57823,           -- 复仇
    Devastate = 47498,         -- 毁灭打击
    ThunderClap = 47502,       -- 雷霆一击
    DemoralizingShout = 47509, -- 挫志怒吼
    SunderArmor = 7386,        -- 破甲
    ShieldBlock = 2565,        -- 盾牌格挡
    ShieldWall = 47477,        -- 盾墙
    LastStand = 12975,         -- 破釜沉舟
    Taunt = 355,               -- 嘲讽
    HeroicStrike = 47450,      -- 英勇打击
    Cleave = 47520,            -- 顺劈斩
    Bloodrage = 2687,          -- 血性狂暴
    BerserkerRage = 18499,     -- 狂暴之怒
    Recklessness = 1719,       -- 鲁莽
    Intercept = 20252,         -- 拦截
    HeroicThrow = 57755,       -- 英勇投掷
    ShatteringThrow = 64382,   -- 碎裂投掷
    SpellReflection = 23920,   -- 法术反射
    ShieldBash = 72,           -- 盾击
    AutoAttack = 6603,
    -- 宏 ID
    BurstMacroID = 9999998,
}
local BuffId = {
    ShieldBlock = S.ShieldBlock,
    LastStand = S.LastStand,
    ShieldWall = S.ShieldWall,
    Revenge = 12721,           -- 复仇激活buff（触发后可用）
    Bloodrage = 2687,
}
local DebuffId = {
    ThunderClap = 47502,
    DemoralizingShout = 47509,
    SunderArmor = 7386,
    ShatteringThrow = 64382,
}
local BurstMacroBody = "/cast 鲁莽\\n/cast 狮心(种族特长)\\n/cast 狂暴(种族特长)\\n/cast 血性狂怒(种族特长)\\n/cast 石像形态(种族特长)\\n/use 10\\n/use 13\\n/use 14\\n/use 通用热力工程炸药\\n/use [@player] 萨隆邪铁炸弹"
local ActionList = {
    { S.ShieldSlam, "macro", "/cast [stance:2] !防御姿态\\n/cast 盾牌猛击\\n/startattack", GetSpellTexture("盾牌猛击") },
    { S.Revenge, "macro", "/cast [stance:2] !防御姿态\\n/cast 复仇\\n/startattack", GetSpellTexture("复仇") },
    { S.Devastate, "macro", "/cast [stance:2] !防御姿态\\n/cast 毁灭打击\\n/startattack", GetSpellTexture("毁灭打击") },
    { S.ThunderClap, "macro", "/cast [stance:2] !防御姿态\\n/cast 雷霆一击", GetSpellTexture("雷霆一击") },
    { S.DemoralizingShout, "macro", "/cast [stance:2] !防御姿态\\n/cast 挫志怒吼", GetSpellTexture("挫志怒吼") },
    { S.SunderArmor, "spell", "破甲" },
    { S.ShieldBlock, "macro", "/cast [stance:2] !防御姿态\\n/cast 盾牌格挡", GetSpellTexture("盾牌格挡") },
    { S.ShieldWall, "macro", "/cast [stance:2] !防御姿态\\n/cast 盾墙", GetSpellTexture("盾墙") },
    { S.LastStand, "macro", "/cast [stance:2] !防御姿态\\n/cast 破釜沉舟", GetSpellTexture("破釜沉舟") },
    { S.Taunt, "spell", "嘲讽" },
    { S.HeroicStrike, "spell", "英勇打击" },
    { S.Cleave, "spell", "顺劈斩" },
    { S.Bloodrage, "spell", "血性狂暴" },
    { S.BerserkerRage, "spell", "狂暴之怒" },
    { S.SpellReflection, "spell", "法术反射" },
    { S.ShieldBash, "spell", "盾击" },
    { S.Intercept, "macro", "/cast [stance:1/2] !狂暴姿态\\n/cast 拦截", GetSpellTexture("拦截") },
    { S.HeroicThrow, "spell", "英勇投掷" },
    { S.ShatteringThrow, "spell", "碎裂投掷" },
    { S.BurstMacroID, "macro", BurstMacroBody, GetSpellTexture("鲁莽") },
    { 6603, "macro", "/startattack" },
    { 2458, "spell", "狂暴姿态" },
    { -112, "macro", "/use 10\\n/use 通用热力工程炸药\\n/use [@player] 萨隆邪铁炸弹", 133035 },
}
-- 目标剩余血量百分比
local function getHPPercent(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return 100 end
    local m = UnitHealthMax(unit)
    if m == 0 then return 0 end
    return (UnitHealth(unit) / m) * 100
end
-- 自身HP百分比（自保）
local function getSelfHpPercent()
    local m = UnitHealthMax("player")
    if m == 0 then return 100 end
    return (UnitHealth("player") / m) * 100
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
-- 是否有敌人正在读条（法术反射时机）
local function anyTargetCasting()
    for i = 1, 40 do
        local u = "nameplate" .. i
        if UnitExists(u) and UnitCanAttack("player", u) then
            local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(u)
            if name and not notInterruptible then
                return true
            end
        end
    end
    return false
end
-- ==================== 主回调函数 ====================
local function APLCallback_ProtWarrior()
    local NextSpellID = S.AutoAttack
    local GCD = VF_getSpellCD(61304)
    local win = (tonumber(GetCVar("SpellQueueWindow")) or 400) / 1000
    local inCombat = UnitAffectingCombat("player")
    local SelfHp = getSelfHpPercent()
    local Rage = UnitPower("player", 1) or 0
    local AOECount = getNearbyCount()
    local isBossFight = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
    local TargetHPPercent = getHPPercent("target")
    local TargetDeadTime = VF_getTargetDeadTime()
    local inMeleeRange = (IsSpellInRange(GetSpellInfo(S.ShieldSlam), "target") == 1)
    local inDefensive = (GetShapeshiftForm() == 2)

    local function cd(id)
        return math.max(0, (VF_getSpellCD(id) or 999) - GCD)
    end
    local ssCD = cd(S.ShieldSlam)
    local revCD = cd(S.Revenge)
    local devCD = cd(S.Devastate)
    local tcCD = cd(S.ThunderClap)
    local dsCD = cd(S.DemoralizingShout)
    local sunderCD = cd(S.SunderArmor)
    local sbCD = cd(S.ShieldBlock)
    local swCD = cd(S.ShieldWall)
    local lsCD = cd(S.LastStand)
    local tauntCD = cd(S.Taunt)
    local hsCD = cd(S.HeroicStrike)
    local cleaveCD = cd(S.Cleave)
    local brCD = cd(S.Bloodrage)
    local bzCD = cd(S.BerserkerRage)
    local rkCD = cd(S.Recklessness)
    local srCD = cd(S.SpellReflection)
    local bashCD = cd(S.ShieldBash)
    local htCD = cd(S.HeroicThrow)
    local stCD = cd(S.ShatteringThrow)

    -- Buffs/Debuffs
    local sbDur = math.max(0, VF_getBuff("player", BuffId.ShieldBlock, "HELPFUL|PLAYER") - GCD)
    local lsDur = math.max(0, VF_getBuff("player", BuffId.LastStand, "HELPFUL|PLAYER") - GCD)
    local swDur = math.max(0, VF_getBuff("player", BuffId.ShieldWall, "HELPFUL|PLAYER") - GCD)
    local brDur = math.max(0, VF_getBuff("player", BuffId.Bloodrage, "HELPFUL|PLAYER") - GCD)
    local revReady = (VF_getBuff("player", BuffId.Revenge, "HELPFUL|PLAYER") > 0)
    local tcRem = math.max(0, VF_getDebuff("target", DebuffId.ThunderClap, "HARMFUL") - GCD)
    local dsRem = math.max(0, VF_getDebuff("target", DebuffId.DemoralizingShout, "HARMFUL") - GCD)
    local sunderRem = math.max(0, VF_getDebuff("target", DebuffId.SunderArmor, "HARMFUL") - GCD)

    -- 脱战准备
    if not inCombat then
        if not inDefensive then
            NextSpellID = 71 -- 防御姿态
            return NextSpellID
        end
        if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") then
            if tcRem <= 0 and tcCD <= win then
                NextSpellID = S.ThunderClap
                return NextSpellID
            end
            if sunderRem <= 0 and sunderCD <= win and Rage >= 15 then
                NextSpellID = S.SunderArmor
                return NextSpellID
            end
            if htCD <= win then
                NextSpellID = S.HeroicThrow
                return NextSpellID
            end
        end
        return NextSpellID
    end

    -- 战斗自保（优先级最高）
    if SelfHp < 35 and lsCD <= win then
        NextSpellID = S.LastStand
        return NextSpellID
    end
    if SelfHp < 20 and swCD <= win then
        NextSpellID = S.ShieldWall
        return NextSpellID
    end

    -- 无效目标
    if not UnitExists("target") or UnitIsDeadOrGhost("target") or not UnitCanAttack("player", "target") then
        return S.AutoAttack
    end

    -- 打断
    if WAParam.config.autoInterrupt and TargetIsCasting() and bashCD <= win and Rage >= 10 then
        NextSpellID = S.ShieldBash
        return NextSpellID
    end

    -- 法术反射
    if WAParam.config.autoReflect and srCD <= win and anyTargetCasting() then
        NextSpellID = S.SpellReflection
        return NextSpellID
    end

    -- 嘲讽：目标不攻击自己时
    if WAParam.config.autoTaunt and tauntCD <= win then
        if UnitExists("target") and not UnitIsUnit("targettarget", "player") then
            NextSpellID = S.Taunt
            return NextSpellID
        end
    end

    -- 血性狂暴（起手/低怒）
    if Rage < 30 and brCD <= win then
        NextSpellID = S.Bloodrage
        return NextSpellID
    end

    -- 盾牌格挡保持（战斗姿态防御）
    if sbDur <= 3 and sbCD <= win then
        NextSpellID = S.ShieldBlock
        return NextSpellID
    end

    -- 雷霆一击保持（减攻速debuff）
    if tcRem <= 3 and tcCD <= win then
        NextSpellID = S.ThunderClap
        return NextSpellID
    end

    -- 挫志怒吼保持（减伤debuff）
    if dsRem <= 3 and dsCD <= win then
        NextSpellID = S.DemoralizingShout
        return NextSpellID
    end

    -- 爆发（鲁莽）
    if WAParam.config.autoBurst and isBossFight and rkCD <= win and TargetDeadTime > 15 then
        NextSpellID = S.BurstMacroID
        return NextSpellID
    end

    -- 碎裂投掷（Boss战破甲）
    if isBossFight and stCD <= win and (math.max(0, VF_getDebuff("target", DebuffId.ShatteringThrow, "HARMFUL") - GCD) <= 0) and Rage >= 25 then
        NextSpellID = S.ShatteringThrow
        return NextSpellID
    end

    -- 盾牌猛击（卡CD，主仇恨）
    if ssCD <= win and inMeleeRange then
        NextSpellID = S.ShieldSlam
        return NextSpellID
    end

    -- 复仇（触发时，高仇恨）
    if revReady and revCD <= win and inMeleeRange then
        NextSpellID = S.Revenge
        return NextSpellID
    end

    -- 破甲（保持5层）
    if sunderRem <= 3 and sunderCD <= win and Rage >= 15 then
        NextSpellID = S.SunderArmor
        return NextSpellID
    end

    -- 英勇打击（高怒泄怒，单体）
    if Rage >= 50 and hsCD <= win and not (AOECount >= 2) then
        NextSpellID = S.HeroicStrike
        return NextSpellID
    end

    -- 顺劈斩（高怒泄怒，AOE）
    if Rage >= 50 and cleaveCD <= win and AOECount >= 2 then
        NextSpellID = S.Cleave
        return NextSpellID
    end

    -- 毁灭打击（填充，叠破甲）
    if devCD <= win and inMeleeRange then
        NextSpellID = S.Devastate
        return NextSpellID
    end

    -- 兜底
    return NextSpellID
end
aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_ProtWarrior
aura_env.APLName = "阿尔法防战"

-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)
