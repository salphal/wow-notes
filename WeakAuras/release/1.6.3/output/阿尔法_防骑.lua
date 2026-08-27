--[[
aura id: 阿尔法_防骑
aura uid: a1phaPr0tPal4
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
  防骑一键 APL - 泰坦重铸时光服
  作者：阿尔法
  仇恨优先：盾击循环 + 正义之锤卡CD + 奉献保持
]]
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_PROT_PALADIN_ALPHA then return end APL_PROT_PALADIN_ALPHA = true
local WAParam = aura_env
local S = {
    SealVengeance = 31801,       -- 复仇圣印
    SealCommand = 20375,         -- 命令圣印
    HammerOfRighteous = 53595,   -- 正义之锤
    AvengerShield = 48827,       -- 复仇者之盾
    Consecration = 48819,        -- 奉献
    HolyShield = 48927,          -- 神圣之盾
    Judgement = 53408,           -- 智慧审判
    DivinePlea = 54428,          -- 神圣恳求
    HolyWrath = 48817,           -- 神圣愤怒
    AvengingWrath = 31884,       -- 复仇之怒
    HammerOfWrath = 48806,       -- 愤怒之锤
    HandOfReckoning = 62124,     -- 正义防御（嘲讽）
    HammerOfJustice = 853,       -- 制裁之锤
    FlashOfLight = 48785,        -- 圣光闪现
    SacredShield = 1298725,      -- 虔诚之盾
    RighteousFury = 25780,       -- 正义之怒
    AutoAttack = 6603,
    -- 宏 ID
    BurstMacroID = 9999997,
}
local AuraId = {
    HolyShield = S.HolyShield,
    SacredShield = 1298725,
    AvengingWrath = S.AvengingWrath,
    SealVengeance = S.SealVengeance,
    DivinePlea = S.DivinePlea,
}
local DebuffId = {
    Judgement = 53408,           -- 审判（智慧审判效果）
    Vengeance = 31803,           -- 复仇（圣印dot）
}
local BurstMacroBody = "/cast 复仇之怒\\n/cast 狮心(种族特长)\\n/cast 狂暴(种族特长)\\n/cast 血性狂怒(种族特长)\\n/cast 石像形态(种族特长)\\n/use 10\\n/use 13\\n/use 14\\n/use 通用热力工程炸药\\n/use [@player] 萨隆邪铁炸弹"
local ActionList = {
    { S.SealVengeance, "spell", "复仇圣印" },
    { S.HammerOfRighteous, "macro", "/cast [nochanneling] 正义之锤\\n/startattack", GetSpellTexture("正义之锤") },
    { S.AvengerShield, "macro", "/cast [nochanneling] 复仇者之盾\\n/startattack", GetSpellTexture("复仇者之盾") },
    { S.Consecration, "spell", "奉献" },
    { S.HolyShield, "spell", "神圣之盾" },
    { S.Judgement, "spell", "智慧审判" },
    { S.DivinePlea, "spell", "神圣恳求" },
    { S.HolyWrath, "spell", "神圣愤怒" },
    { S.HammerOfWrath, "spell", "愤怒之锤" },
    { S.HandOfReckoning, "spell", "正义防御" },
    { S.HammerOfJustice, "spell", "制裁之锤" },
    { S.FlashOfLight, "spell", "圣光闪现" },
    { S.RighteousFury, "spell", "正义之怒" },
    { S.BurstMacroID, "macro", BurstMacroBody, GetSpellTexture("复仇之怒") },
    { 6603, "macro", "/startattack" },
    { -112, "macro", "/use 10\\n/use 通用热力工程炸药\\n/use [@player] 萨隆邪铁炸弹", 133035 },
}
local faction = UnitFactionGroup("player")
if faction == "Horde" then
    S.SealVengeance = 348704 -- 部落改腐蚀
    AuraId.SealVengeance = S.SealVengeance
    DebuffId.Vengeance = 53742
    ActionList[1] = { S.SealVengeance, "spell", "腐蚀圣印" }
end
-- 目标剩余血量百分比
local function getHPPercent(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return 100 end
    local m = UnitHealthMax(unit)
    if m == 0 then return 0 end
    return (UnitHealth(unit) / m) * 100
end
-- 玩家剩余蓝量百分比
local function getManaPercent()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    return maxMana > 0 and (mana / maxMana) * 100 or 100
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
-- 目标是否为亡灵/恶魔（神圣愤怒）
local function isTargetUndeadOrDemon()
    if not UnitExists("target") or UnitIsPlayer("target") then
        return false
    end
    local ct = UnitCreatureType("target")
    return ct == "Undead" or ct == "Demon" or ct == "亡灵" or ct == "恶魔"
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
-- ==================== 主回调函数 ====================
local function APLCallback_ProtPaladin()
    local NextSpellID = S.AutoAttack
    local GCD = VF_getSpellCD(61304)
    local win = (tonumber(GetCVar("SpellQueueWindow")) or 400) / 1000
    local inCombat = UnitAffectingCombat("player")
    local ManaPercent = getManaPercent()
    local SelfHp = getSelfHpPercent()
    local AOECount = getNearbyCount()
    local isBossFight = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
    local TargetHPPercent = getHPPercent("target")
    local TargetDeadTime = VF_getTargetDeadTime()

    local function cd(id)
        return math.max(0, (VF_getSpellCD(id) or 999) - GCD)
    end
    local HotrCD = cd(S.HammerOfRighteous)
    local AvengerCD = cd(S.AvengerShield)
    local ConsecrationCD = cd(S.Consecration)
    local HolyShieldCD = cd(S.HolyShield)
    local JudgeCD = cd(S.Judgement)
    local PleaCD = cd(S.DivinePlea)
    local HolyWrathCD = cd(S.HolyWrath)
    local HowCD = cd(S.HammerOfWrath)
    local HoRCD = cd(S.HandOfReckoning)
    local HojCD = cd(S.HammerOfJustice)
    local WingsCD = cd(S.AvengingWrath)

    -- Buffs
    local HolyShieldDur = math.max(0, VF_getBuff("player", AuraId.HolyShield, "HELPFUL|PLAYER") - GCD)
    local SacredDur = math.max(0, VF_getBuff("player", AuraId.SacredShield, "HELPFUL|PLAYER") - GCD)
    local WingsDur = math.max(0, VF_getBuff("player", AuraId.AvengingWrath, "HELPFUL|PLAYER") - GCD)
    local SealVenDur = math.max(0, VF_getBuff("player", AuraId.SealVengeance, "HELPFUL|PLAYER") - GCD)
    local RFDur = math.max(0, VF_getBuff("player", S.RighteousFury, "HELPFUL|PLAYER") - GCD)
    local PleaDur = math.max(0, VF_getBuff("player", AuraId.DivinePlea, "HELPFUL|PLAYER") - GCD)

    -- Debuffs
    local JudgeRem = math.max(0, VF_getDebuff("target", DebuffId.Judgement, "HARMFUL|PLAYER") - GCD)
    local SealDebuffRem = math.max(0, VF_getDebuff("target", DebuffId.Vengeance, "HARMFUL|PLAYER") - GCD)

    -- 脱战准备
    if not inCombat then
        if RFDur <= 0 then
            NextSpellID = S.RighteousFury
            return NextSpellID
        end
        if SealVenDur <= 0 and cd(S.SealVengeance) <= win then
            NextSpellID = S.SealVengeance
            return NextSpellID
        end
        if PleaDur <= 0 and PleaCD <= win then
            NextSpellID = S.DivinePlea
            return NextSpellID
        end
        if HolyShieldDur <= 0 and HolyShieldCD <= win then
            NextSpellID = S.HolyShield
            return NextSpellID
        end
        if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") then
            if JudgeRem <= 0 and JudgeCD <= win then
                NextSpellID = S.Judgement
                return NextSpellID
            end
            if AvengerCD <= win then
                NextSpellID = S.AvengerShield
                return NextSpellID
            end
        end
        return NextSpellID
    end

    -- 战斗自保（优先级最高）
    if SelfHp < 40 and cd(S.FlashOfLight) <= win and not UnitCastingInfo("player") then
        NextSpellID = S.FlashOfLight
        return NextSpellID
    end

    -- 无效目标
    if not UnitExists("target") or UnitIsDeadOrGhost("target") or not UnitCanAttack("player", "target") then
        return S.AutoAttack
    end

    -- 打断
    if WAParam.config.autoInterrupt and TargetIsCasting() and cd(96231) <= win then
        NextSpellID = 96231 -- 责难
        return NextSpellID
    end

    -- 嘲讽：目标不攻击自己时（Boss战或拉怪）
    if WAParam.config.autoTaunt and HoRCD <= win then
        if UnitExists("target") and not UnitIsUnit("targettarget", "player") then
            NextSpellID = S.HandOfReckoning
            return NextSpellID
        end
    end

    -- 神圣之盾保持
    if HolyShieldDur <= 3 and HolyShieldCD <= win then
        NextSpellID = S.HolyShield
        return NextSpellID
    end

    -- 正义之怒保持（战斗中防意外消失）
    if RFDur <= 0 and cd(S.RighteousFury) <= win then
        NextSpellID = S.RighteousFury
        return NextSpellID
    end

    -- 爆发
    if WAParam.config.autoBurst and isBossFight and WingsCD <= win and TargetDeadTime > 15 then
        NextSpellID = S.BurstMacroID
        return NextSpellID
    end

    -- 愤怒之锤（斩杀）
    if TargetHPPercent < 20 and HowCD <= win then
        NextSpellID = S.HammerOfWrath
        return NextSpellID
    end

    -- 复仇者之盾（卡CD，聚怪/仇恨）
    if AvengerCD <= win and not UnitCastingInfo("player") then
        NextSpellID = S.AvengerShield
        return NextSpellID
    end

    -- 正义之锤（卡CD，主仇恨技能）
    if HotrCD <= win then
        NextSpellID = S.HammerOfRighteous
        return NextSpellID
    end

    -- 审判（卡CD，回蓝+仇恨）
    if JudgeRem <= 2 and JudgeCD <= win then
        NextSpellID = S.Judgement
        return NextSpellID
    end

    -- 奉献（保持，AOE仇恨）
    if ConsecrationCD <= win and AOECount >= 1 and ManaPercent > 30 then
        NextSpellID = S.Consecration
        return NextSpellID
    end

    -- 神圣愤怒（亡灵/恶魔 或 AOE）
    if HolyWrathCD <= win and (isTargetUndeadOrDemon() or AOECount >= 2) then
        NextSpellID = S.HolyWrath
        return NextSpellID
    end

    -- 制裁之锤（应急打断/控制）
    if WAParam.config.autoHammerOfJustice and HojCD <= win and isBossFight and TargetHPPercent < 35 then
        NextSpellID = S.HammerOfJustice
        return NextSpellID
    end

    -- 神圣恳求（战斗中回蓝，翅膀期不打）
    if ManaPercent < 25 and PleaCD <= win and WingsDur <= 0 then
        NextSpellID = S.DivinePlea
        return NextSpellID
    end

    -- 兜底
    return NextSpellID
end
aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_ProtPaladin
aura_env.APLName = "阿尔法防骑"

-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)
