--[[
aura id: 凌小猫粮_元素萨
aura uid: QjFmxGVu7Bc
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
元素萨 APL — by时光1凌姐
简化：哀冬
元素萨一键输出，默认纯单目标闪电箭填充
]]

if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_ELEMENTAL_SHAMAN_WLK_CATGIRL_BOLT then return end APL_ELEMENTAL_SHAMAN_WLK_CATGIRL_BOLT = true

local config = aura_env.config or {}

-- ==========================================
-- 技能 ID 定义
-- ==========================================
local S = {
    FlameShock    = 49233,   -- 烈焰震击
    LavaBurst     = 60043,   -- 熔岩爆裂
    LightningBolt = 49238,   -- 闪电箭
    ChainLightning = 49271,  -- 闪电链
    FlametongueWeapon = 58790, -- 火舌武器
    ElementalMastery = 16166, -- 元素掌握
    Thunderstorm  = 59159,   -- 雷霆风暴
    WaterShield   = 57960,   -- 水之护盾
    WindShear     = 57994,   -- 风剪（打断）
    Purge         = 8012,    -- 净化术
    CallOfElements     = select(7, GetSpellInfo("元素的召唤")) or 66842,
    Berserking    = 26297,   -- 狂暴（巨魔）
    BloodFury     = 33697,   -- 血性狂怒（兽人）
}

-- ==========================================
-- ActionList 定义
-- ==========================================
local ActionList = {
    {S.FlameShock,    "spell", "烈焰震击"},
    {S.LavaBurst,     "spell", "熔岩爆裂"},
    {S.ChainLightning, "spell", "闪电链"},
    {S.LightningBolt, "spell", "闪电箭"},
    {6603, "macro", "/targetenemy [dead][noharm]\\n/startattack"},
    {S.ElementalMastery, "macro", "/cqs\\n/use 10\\n/use 13\\n/use 14\\n/cast 狂暴(种族特长)\\n/cast 血性狂怒(种族特长)\\n/cast 元素掌握\\n/cqs", GetSpellTexture("元素掌握")},
    {S.Thunderstorm, "spell", "雷霆风暴"},
    {S.FlametongueWeapon, "spell", "火舌武器"},
    {S.WaterShield, "spell", "水之护盾"},
    {S.WindShear, "spell", "风剪"},
    {S.Purge, "spell", "净化术"},
    {S.CallOfElements,  "spell", "元素的召唤"},
}


-- 判断是否在爆发期（有任一爆发 buff）
local function InBurstWindow()
    -- 常用爆发 Buff ID
    local BuffIDs = {
        64701, -- 元素掌握
        2825,  -- 嗜血
        32182, -- 英勇
        26297, -- 狂暴
        33697, -- 血性狂怒
        54758, -- 工程加速手套
    }
    for _, buffId in ipairs(BuffIDs) do
        if (VF_getBuff("player", buffId, "HELPFUL") or 0) > 0 then
            return true
        end
    end
    return false
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

-- 判断目标是否正在施法且可打断
-- UnitCastingInfo 第8个返回值 notInterruptible: nil/0=可断, 1=钢条
local function TargetIsCasting()
    local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and not notInterruptible then
        return true
    end
    -- 引导技能
    local channelName, _, _, _, _, _, notInterruptible2 = UnitChannelInfo("target")
    if channelName and not notInterruptible2 then
        return true
    end
    return false
end

-- 判断蓝量百分比
local function GetManaPercent()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    if maxMana == 0 then return 100 end
    return (mana / maxMana) * 100
end

-- AoE 目标计数（基于 nameplate + WeakAuras.GetRange 测距）
-- 注意：仅检测玩家→每个目标的距离，无法检测目标之间的距离
local function getAOECount(range)
    local count = 0
    for i = 1, 40 do
        local unitid = "nameplate" .. i
        if UnitExists(unitid) and UnitCanAttack("player", unitid) and not UnitIsDead(unitid) then
            local _, maxRange = WeakAuras.GetRange(unitid)
            if maxRange and maxRange <= range then
                count = count + 1
            end
        end
    end
    return count
end

-- ==========================================
-- 主回调函数
-- ==========================================
local function APLCallback_ElementalShaman()
    local CastWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400) / 1000
    local GCD = VF_getSpellCD(61304)
    local now = GetTime()
    local castingSpellName, _, _, _, endTimeMs = UnitCastingInfo("player")
    if castingSpellName ~= nil then 
        GCD = math.max((endTimeMs/1000 - now), GCD)
    end
    local inCombat = UnitAffectingCombat("player")
    local inBossFight = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
    local flameShockRemain = math.max(0, VF_getDebuff("target", S.FlameShock, "HARMFUL|PLAYER") - GCD)
    local flameShockCD = math.max(0, VF_getSpellCD(S.FlameShock) - GCD)
    local lavaBurstCD = math.max(0, VF_getSpellCD(S.LavaBurst) - GCD)
    local lavaBurstCT = (select(4, GetSpellInfo("熔岩爆裂")) / 1000)
    local chainLightningCD = math.max(0, VF_getSpellCD(S.ChainLightning) - GCD)
    local waterShieldDur = VF_getBuff("player", S.WaterShield, "HELPFUL|PLAYER")
    if castingSpellName == "闪电箭" then
        inCombat = true
    end

    -- 战前准备
    if not inCombat then
        -- 火舌武器
        local hasEnchant, expiration = GetWeaponEnchantInfo()
        if not hasEnchant or (expiration and expiration < 600000) then
            return S.FlametongueWeapon
        end
        -- 水盾
        if waterShieldDur <= 450 then
            return S.WaterShield
        end
        -- 图腾
        if not HasAllTotems() then
            return S.CallOfElements
        end
        -- 预读闪电箭
        return S.LightningBolt
    end

    -- 无效目标
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDeadOrGhost("target") then
        return 6603
    end

    -- 爆发
    if config.auto_burst and inBossFight and inCombat then
        -- 必须熔岩爆裂技能就绪，开了爆发才有东西打
        if lavaBurstCD <= CastWindow and flameShockRemain > 15 then
            local burstReady = false

            -- 元素掌握就绪
            if VF_getSpellCD(S.ElementalMastery) <= CastWindow then
                burstReady = true
            end
            -- 手套饰品就绪
            if VF_getItemCD(10) <= 0 or VF_getItemCD(13) <= 0 or VF_getItemCD(14) <= 0 then
                burstReady = true
            end
            -- 种族技能就绪
            if VF_getSpellCD(S.Berserking) <= CastWindow or VF_getSpellCD(S.BloodFury) <= CastWindow then
                burstReady = true
            end

            if burstReady then
                return S.ElementalMastery -- 爆发宏
            end
        end
    end

    -- 雷霆风暴
    if config.auto_thunderstorm then
        local manaPercent = GetManaPercent()
        if manaPercent < 60 and VF_getSpellCD(S.Thunderstorm) <= CastWindow then
            return S.Thunderstorm
        end
    end

    -- 水盾
    if config.auto_watershield then
        if waterShieldDur == 0 and not InBurstWindow() then
            return S.WaterShield
        end
    end

    -- 打断
    if config.auto_windshear then
        local casting = TargetIsCasting()
        if casting and VF_getSpellCD(S.WindShear) <= CastWindow then
            return S.WindShear
        end
    end

    -- 烈焰震击
    if flameShockRemain <= 0 and flameShockCD <= CastWindow then
        return S.FlameShock
    end

    -- 熔岩爆裂快好了但烈焰震击撑不到
    if lavaBurstCD <= 1 and flameShockRemain < (lavaBurstCD + lavaBurstCT) and flameShockCD <= CastWindow then
        return S.FlameShock
    end

    -- 熔岩爆裂
    if lavaBurstCD <= CastWindow and flameShockRemain > lavaBurstCT then
        return S.LavaBurst
    end

    -- 闪电链
    if config.smart_chainlightning and chainLightningCD <= CastWindow then
        if getAOECount(30) >= 2 then
            return S.ChainLightning
        end
    end

    -- 闪电箭
    return S.LightningBolt
end

-- ==========================================
-- 注册 APL
-- ==========================================
aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_ElementalShaman
aura_env.APLName = "凌小猫粮"


-- ===== actions.init 加载时自定义代码 =====
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
VF_registerAPL(aura_env)