--[[
aura id: 七叔_深血
aura uid: 4N1pwDjwtJy
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
  深血DKT APL - 泰坦重铸时光服
  作者：七叔丿
  单独对BOSS战进行了仇恨优化，普通时间单冰触，BOSS战6冰触。
]]

if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end
if APL_BLOOD_DK_SELFVF then return end APL_BLOOD_DK_SELFVF = true

-- 技能列表
local S = {
    FrostPresence = 48263,     -- 冰霜灵气
    IcyTouch = 49909,          -- 冰冷触摸
    PlagueStrike = 49921,      -- 暗影打击
    HeartStrike = 55262,       -- 心脏打击（血打）
    DeathStrike = 49924,       -- 灵界打击（灵打）
    BloodBoil = 49941,         -- 血液沸腾（血沸）
    DeathAndDecay = 49938,     -- 枯萎凋零
    Pestilence = 50842,        -- 传染
    DeathCoil = 49895,         -- 凋零缠绕
    BloodTap = 45529,          -- 活力分流
    RuneWeapon = 47568,        -- 符文武器增效
    HornOfWinter = 57623,      -- 寒冬号角
    GCDProbe = 61304,
}

-- BUFF/DEBUFF
local FrostFeverID = 55095     -- 冰霜热疫
local BloodPlagueID = 55078    -- 血之疫病
local HornOfWinterBuffID = 57623  -- 寒冬号角BUFF
local CoagulatedBloodID = 1282343  -- 啜血BUFF ID

-- 起手序列状态
local openerStep = 0
local openerDone = false
local openerSQ = {
    S.IcyTouch, S.IcyTouch, S.BloodTap, S.IcyTouch,
    S.PlagueStrike, S.BloodBoil, S.DeathAndDecay, S.RuneWeapon,
    S.IcyTouch
}

-- 辅助函数
local function getDebuffRemain(unit, spellId)
    return math.max(0, VF_getDebuff(unit, spellId, "HARMFUL|PLAYER") or 0)
end

-- 检测啜血BUFF（用ID检测，被动触发用HELPFUL过滤器）
local function hasCoagulatedBlood()
    return (VF_getBuff("player", CoagulatedBloodID, "HELPFUL") or 0) > 0
end

-- AOE计数：周围10码内敌人数量
local function getAOECount()
    local count = 0
    local counted = {}
    for i = 1, 40 do
        local unitid = "nameplate" .. i
        if UnitExists(unitid) and UnitCanAttack("player", unitid) and not UnitIsDead(unitid) then
            if WeakAuras.CheckRange(unitid, 10, "<=") then
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

--确认疾病雕文
local function hasPestilenceGlyph()
    for i = 1, 6 do
        local _, _, _, glyphID = GetGlyphSocketInfo(i)   ----实测第4个值才是ID
        if glyphID == 1287384 then
            return true
        end
    end
    return false
end

-- 战斗日志监听：推进起手序列
local function onCLEUEvent()
    local _, subEvent, _, srcGUID, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    if srcGUID ~= UnitGUID("player") then return end
    if subEvent == "SPELL_CAST_SUCCESS" then
        if not openerDone and openerStep >= 1 then
            if openerStep <= #openerSQ and spellID == openerSQ[openerStep] then
                openerStep = openerStep + 1
                if openerStep > #openerSQ then
                    openerDone = true
                end
            end
        end
    end
end

local Manager = CreateFrame("Frame", "BloodDKAPLManager", UIParent)
Manager:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
Manager:SetScript("OnEvent", function(_, e)
        if e == "COMBAT_LOG_EVENT_UNFILTERED" then
            onCLEUEvent()
        end
end)

-- ActionList（主技能宏绑定符文打击）
local ActionList = {
    --{ S.FrostPresence, "spell", "冰霜灵气" },
    { S.IcyTouch, "macro", "/cast 冰冷触摸\\n/cast !符文打击", GetSpellTexture("冰冷触摸") },
    { S.PlagueStrike, "macro", "/cast 暗影打击\\n/cast !符文打击", GetSpellTexture("暗影打击") },
    { S.HeartStrike, "macro", "/cast 心脏打击\\n/cast !符文打击", GetSpellTexture("心脏打击") },
    { S.DeathStrike, "macro", "/cast 灵界打击\\n/cast !符文打击", GetSpellTexture("灵界打击") },
    { S.BloodBoil, "macro", "/cast 血液沸腾\\n/cast !符文打击", GetSpellTexture("血液沸腾") },
    { S.DeathAndDecay, "macro", "/cast [@player] 枯萎凋零\\n/cast !符文打击", GetSpellTexture("枯萎凋零") },
    { S.Pestilence, "macro", "/cast 传染\\n/cast !符文打击", GetSpellTexture("传染") },
    { S.DeathCoil, "macro", "/cast 凋零缠绕\\n/cast !符文打击", GetSpellTexture("凋零缠绕") },
    { S.BloodTap, "spell", "活力分流" },
    { S.RuneWeapon, "spell", "符文武器增效" },
    { S.HornOfWinter, "macro", "/cast 寒冬号角\\n/cast !符文打击", GetSpellTexture("寒冬号角") },
    { 6603, "macro", "/startattack\\n/cast !符文打击" },
}

local function APLCallback_BloodDK()
    local win = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and not UnitIsDeadOrGhost("target") and UnitCanAttack("player", "target")
    local gcdRemain = VF_getSpellCD(S.GCDProbe) or 0
    local function cd(id)
        return math.max(0, (VF_getSpellCD(id) or 999) - gcdRemain)
    end
    
    -- 脱战固定提示冰冷触摸
    if not inCombat then
        openerStep = 0
        openerDone = false
        if UnitExists("target") and not UnitIsDeadOrGhost("target") and UnitCanAttack("player", "target") then
            return S.IcyTouch
        end
        return 6603
    end
    
    if not hasTarget then return 6603 end
    
    local runicPower = UnitPower("player", 6) or 0
    local isBoss = ((IsEncounterInProgress() or IsResting()) and UnitLevel("target") == -1)
    local aoeCount = getAOECount()
    
    -- 双病剩余
    local ffRem = getDebuffRemain("target", FrostFeverID)
    local bpRem = getDebuffRemain("target", BloodPlagueID)
    local bothDiseases = ffRem > 0 and bpRem > 0
    
    -- 啜血BUFF
    local hasCoagulated = hasCoagulatedBlood()
    
    -- 枯萎凋零CD剩余（真实CD）
    local dndStart, dndDuration = GetSpellCooldown(S.DeathAndDecay)
    local dndRemain = 0
    if dndStart and dndDuration and dndDuration > 0 then
        dndRemain = dndStart + dndDuration - GetTime()
        if dndRemain < 0 then dndRemain = 0 end
    end
    
    -- ===== 一、BOSS起手固定序列（需要冰脸+目标为BOSS）=====
    local isFrostPresence = GetShapeshiftForm() == 2  -- 2 = 冰霜灵气否则直接跳入深血DPS循环
    if isBoss and isFrostPresence and not openerDone then
        if openerStep == 0 then
            openerStep = 1
        end
        if openerStep <= #openerSQ then
            local spellID = openerSQ[openerStep]
            if cd(spellID) <= win then
                return spellID
                end
            openerStep = openerStep + 1
            if openerStep > #openerSQ then
                openerDone = true
            end
        else
            openerDone = true
        end
    end
    
    -- ===== 二、传染 =====
    local needPest = false
    -- AOE场景传染（不受雕文限制）
    if aoeCount >= 2 and bothDiseases then  -- 周围目标数量>=2 且当前目标身上有双病
        for i = 1, 40 do
            local unitid = "nameplate" .. i
            if UnitExists(unitid) and UnitCanAttack("player", unitid) and not UnitIsDead(unitid) then
                if WeakAuras.CheckRange(unitid, 10, "<=") then
                    local ff = getDebuffRemain(unitid, FrostFeverID)
                    local bp = getDebuffRemain(unitid, BloodPlagueID)
                    if ff <= 4 or bp <= 4 then  -- 任一目标疾病<4秒就传染，修正之前判定疾病需要>0的错误条件
                        needPest = true
                        break
                    end
                end
            end
        end
    end
    -- 单体传染（需要疾病雕文）
    if not needPest and bothDiseases and (ffRem < 3 or bpRem < 3) and hasPestilenceGlyph() then
        needPest = true
    end
    if needPest and cd(S.Pestilence) <= win then
        return S.Pestilence
    end
    
    -- ===== 三、枯萎凋零：身上有啜血BUFF + 目标双病齐全 =====
    if hasCoagulated and bothDiseases and cd(S.DeathAndDecay) <= win then
        return S.DeathAndDecay
    end
    
    -- ===== 四、血沸：凋零CD<2秒 + 双病齐全 + 无啜血 → 触发啜血 =====
    if dndRemain >= 0 and dndRemain < 2 and bothDiseases and not hasCoagulated and cd(S.BloodBoil) <= win then
        return S.BloodBoil
    end
    
    -- ===== 五、常规循环 =====
    -- 5.1 补双病（缺失时置顶）
    if not bothDiseases then
        if ffRem <= 0 and cd(S.IcyTouch) <= win then
            return S.IcyTouch
        end
        if bpRem <= 0 and cd(S.PlagueStrike) <= win then
            return S.PlagueStrike
        end
    end
    
    -- 5.2 心打/AOE血沸：双病齐全 + 双病剩余>=4秒 + CD就绪
    if bothDiseases and ffRem >= 4 and bpRem >= 4 then
        if aoeCount >= 3 then
            if cd(S.BloodBoil) <= win then
                return S.BloodBoil
            end
        else
            if cd(S.HeartStrike) <= win then
                return S.HeartStrike
            end
        end
        -- 灵打：心打/血沸CD中 + 冰暗符文可用 + 双病剩余>=4秒
        if cd(S.DeathStrike) <= win and cd(S.IcyTouch) <= win and cd(S.PlagueStrike) <= win then
            return S.DeathStrike
        end
    end
    
    -- 枯萎凋零（常规可用，兜底）
    if cd(S.DeathAndDecay) <= win then
        return S.DeathAndDecay
    end
    
    -- ===== 六、凋零缠绕：枯萎凋零在CD中 + 真实CD>=2秒 + 能量>=80 =====
    if dndRemain > 0--[[ and GetShapeshiftForm() ~= 2 ]]then
        local dndRawStart, dndRawDuration = GetSpellCooldown(S.DeathAndDecay)
        local dndRawRemain = 0
        if dndRawStart and dndRawDuration and dndRawDuration > 0 then
            dndRawRemain = dndRawStart + dndRawDuration - GetTime()
            if dndRawRemain < 0 then dndRawRemain = 0 end
        end
        if dndRawRemain >= 2 and cd(S.DeathCoil) <= win 
                 and ((GetShapeshiftForm() ~= 2 and runicPower >= 60) or (GetShapeshiftForm() == 2 and runicPower >= 80))then
            return S.DeathCoil
        end
    end
    
    -- ===== 七、填充技能 =====
    -- 血沸
    if cd(S.BloodBoil) <= win then
        return S.BloodBoil
    end
    
    -- 寒冬号角：无技能可用时 + CD好 + 无号角BUFF + 双病中任一病剩余>2秒
    local hasHornBuff = (VF_getBuff("player", HornOfWinterBuffID, "HELPFUL|PLAYER") or 0) > 0
    if cd(S.HornOfWinter) <= win and not hasHornBuff and (ffRem > 2 or bpRem > 2) then
        return S.HornOfWinter
    end
    
    return 6603
end

aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_BloodDK
aura_env.APLName = "七叔深血"

-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)