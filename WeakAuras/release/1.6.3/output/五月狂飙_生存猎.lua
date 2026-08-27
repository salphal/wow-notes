--[[
aura id: 五月狂飙_生存猎
aura uid: t7sSS8mtmkI
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
  生存猎 APL 
  贡献人：五月狂飙
]]
if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_SUR_HUNTER_WLK then return end APL_SUR_HUNTER_WLK = true
local cfg = aura_env.config or {}
local CurrentEncounterID = 0
-- 关闭自动爆发BOSS名单：629诺森德猛兽 637阵营冠军 
local NoAutoBrustlist = {
    [629] = true,
    [637] = true
}
-- 目标剩余血量百分比
local function TargetHpPct(unit)
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
local function PlayerManaPct()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    return maxMana > 0 and (mana / maxMana) * 100 or 100
end
-- 急速射击爆发宏
local BurstMacro = "/cast 狂暴(种族特长)\\n/cast 血性狂怒(种族特长)\\n/cast 石像形态(种族特长)\\n/cast 野性呼唤\\n/use 10\\n/use 13\\n/use 14\\n/use [group:raid]速度药水\\n/cast 急速射击"
-- 434宏
local ExpShotMacro = "/cast 爆炸射击(等级 4)\\n/cast 杀戮命令\\n/use 10\\n/petattack [combat]"
local ExpShotMacro3 = "/cast 爆炸射击(等级 3)\\n/cast 杀戮命令\\n/use 10\\n/petattack [combat]"
-- 陷阱宏
local ExpTrapMacro = "/cast [@cursor] 陷阱发射器：爆炸陷阱\\n/use [@cursor,combat,group:raid] 萨隆邪铁炸弹"
-- 宠物宏
local PetMarco = "/cast [@pet,dead] 复活宠物\\n/castsequence [nopet] reset=2 召唤宠物,复活宠物"
-- 杀戮宏
local KillShotMarco = "/cast 狂暴(种族特长)\\n/cast 血性狂怒(种族特长)\\n/cast 石像形态(种族特长)\\n/cast 杀戮命令\\n/cast 野性呼唤\\n/use 13\\n/use 14\\n/cast 杀戮射击"
local ActionList = {
    {-112, "item", 10},
    { 61847, "spell", "龙鹰守护" },
    { 34074, "spell", "蝰蛇守护" },
    { 49048, "spell", "多重射击" },
    { 49001, "spell", "毒蛇钉刺" },
    { 34026, "spell", "杀戮命令" },
    { 63672, "spell", "黑箭" },
    { 53338, "spell", "猎人印记" },
    { 49052, "spell", "稳固射击" },
    { 61006, "spell", "杀戮射击" },
    { 75, "macro", "/cast !自动射击", GetSpellTexture("自动射击") },
    { 60053, "macro", ExpShotMacro, GetSpellTexture("爆炸射击") },
    { -60053, "macro", ExpShotMacro3, GetSpellTexture("爆炸射击") },
    { 3045, "macro", BurstMacro, GetSpellTexture("急速射击") },
    { 425777, "macro", ExpTrapMacro, GetSpellTexture("爆炸陷阱") },
    { 883, "macro", PetMarco, GetSpellTexture("召唤宠物") },   
    { 9999994, "macro", KillShotMarco, GetSpellTexture("杀戮射击") }, 
}
local function APLCallback_RetHunter()
    --- 读条优先
    local spellId = select(10, UnitCastingInfo("player"))
    if spellId == 49052 then
        return 49052
    end
    local NextSpellID = 75
    -- 施法时间
    local function GetDynamicCastTime(spellId)
        local baseCastTimeMS = select(4, GetSpellInfo(spellId)) or 0  -- 毫秒
        if baseCastTimeMS == 0 then return 0 end
        local haste = UnitSpellHaste("player") or 0  -- 急速百分比（例如 20）
        local dynamicCastTimeMS = baseCastTimeMS / (1 + haste / 100)
        return dynamicCastTimeMS / 1000  -- 转换为秒
    end
    
    for i = 1, 1 do
        local TargetSpeed = GetUnitSpeed("target") or 0
        local inCombat = UnitAffectingCombat("player")
        local gcdRemain = VF_getSpellCD(61304) or 0
        local win = (tonumber(GetCVar("SpellQueueWindow")) or 400) / 1000
        local cd = function(id)
            return math.max(0, (VF_getSpellCD(id) or 999) - gcdRemain)
        end
        -- 判断目标是否为BOSS（骷髅级、世界首领、木桩）
        local isTargetBoss =  ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
        local TarHpPct = TargetHpPct("target") or 100
        local ManaPct = PlayerManaPct() or 100      
        local ExpShotCd = cd(60053)
        local ExpTrapCd = cd(425777)
        local MultiCd = cd(49048)
        local KillShotCd = cd(61006)
        local KillComCd = cd(34026)
        local BlackACd = cd(63672)
        local RapidFCd = cd(3045)
        local GloveCD = VF_getItemCD(10)
        -- 目标陷阱剩余时间
        local targetTrapRem = math.max(0,VF_getDebuff("target", 49065, "HARMFUL|PLAYER")-gcdRemain)
        -- 目标钉刺剩余时间
        local targetStingRem = math.max(0,VF_getDebuff("target", 49001, "HARMFUL|PLAYER")-gcdRemain)
        -- 目标印记剩余时间
        local targetMarkRem = VF_getDebuff("target", 53338, "HARMFUL") or 0
        -- 是否龙鹰守护
        local AtDragonRem = VF_getBuff("player", 61847, "HELPFUL|PLAYER")
        -- 目标4级爆炸DEBUFF剩余时间
        local tarExpDebuff4Rem = math.max(0,VF_getDebuff("target", 60053, "HARMFUL|PLAYER")-gcdRemain)
        
        -- 切龙鹰守护
        if cfg.enableAutoViper and AtDragonRem <= 0 then
            NextSpellID = 61847
            break
        end
        if not inCombat then
            if not UnitExists("pet") then
                NextSpellID = 883
                break
            end
            -- 战前猎人印记（陷阱可不预铺，但印记必须上）
            if targetMarkRem <= 0 then
                NextSpellID = 53338
                break
            end
            -- 战斗前预铺陷阱（陷阱黑箭共冷却，战斗中陷阱优先级在偷黑箭之后）
            if cfg.enablePreTrap and ExpTrapCd <= win then
                NextSpellID = 425777
                break
            end
            -- 倒数2S预读稳固
            NextSpellID = 49052
            break
        else
            -- 偷黑箭
            if targetTrapRem > 15 and BlackACd <= win then
                NextSpellID = 63672
                break
            end
            -- 战斗中猎人印记
            if isTargetBoss and targetMarkRem <= 0 then
                NextSpellID = 53338
                break
            end
            -- 自动爆发
            if isTargetBoss and cfg.enableAutoBurst and not NoAutoBrustlist[CurrentEncounterID] then
                if RapidFCd <= win then
                    NextSpellID = 3045
                    break
                end
                -- 开手套
                if GloveCD <= win then
                    NextSpellID = -112
                    break
                end
            end
            -- 杀戮命令（无GCD，优先开）
            if KillComCd <= win then
                NextSpellID = 34026
                break
            end
            -- 杀戮射击（只对BOSS开爆发）
            if TarHpPct < 20 and KillShotCd <= win then
                if isTargetBoss then
                    NextSpellID = 9999994
                    break
                else
                    NextSpellID = 61006
                    break
                end
            end
            -- 爆炸射击(修改逻辑，当目标有4级DEBUFF时打3级爆炸，这样双目标时可以都打4级爆炸)
            if ExpShotCd <= win then
                if tarExpDebuff4Rem > 0.5 then
                    NextSpellID = -60053
                else
                    NextSpellID = 60053
                end
                break
            end
            -- 爆炸陷阱
            if cfg.enableAutoTrap and (TargetSpeed == 0) and ExpTrapCd <= win then
                NextSpellID = 425777
                break
            end
            -- 多重射击
            if MultiCd <= win and UnitExists("target") and (string.find((cfg.noMultiList or ""),(UnitName("target") or "NoOne"),1,true) == nil) then
                NextSpellID = 49048
                break
            end
            -- 蝰蛇舞
            if cfg.enableAutoViper and ManaPct <= 40 and (MultiCd + gcdRemain) >= 9 then-- 40%蓝以下蝰蛇舞（实战测试结果，基本不缺蓝，当然也和自身暴击率有关，40%蓝以下兜底）
                NextSpellID = 34074
                break
            end
            -- 毒蛇钉刺
            if targetStingRem <= 0 then
                NextSpellID = 49001
                break
            end
            -- 稳固射击
            local SSCastTime = GetDynamicCastTime(49052)
            if ExpTrapCd > SSCastTime and ExpShotCd > SSCastTime and MultiCd > (SSCastTime - 0.2) and targetStingRem > SSCastTime then
                NextSpellID = 49052
                break
            else 
                NextSpellID = 75
                break
            end
        end
    end
    return NextSpellID or 75
end
local Manager = CreateFrame("Frame", "RetHunterAPLManager", UIParent)
Manager:RegisterEvent("ENCOUNTER_START")
Manager:RegisterEvent("ENCOUNTER_END")
Manager:SetScript("OnEvent", function(_, event, ...)
        if event == "ENCOUNTER_START" then
            local encounterID = ...  -- 第一个参数就是 encounterID
            if encounterID and encounterID > 0 then
                CurrentEncounterID = encounterID
            end
        elseif event == "ENCOUNTER_END" then
            CurrentEncounterID = 0
        end
end)
aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_RetHunter
aura_env.APLName = "五月狂飙生存"

-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)