--[[
aura id: VF_HekiliFollower
aura uid: jNBQAxhAyDF
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== trigger 1 自定义触发器 =====
function(state, e, ...)
    if ((aura_env.VF_onHekiliEvent~=nil) and (e == "HEKILI_RECOMMENDATION_UPDATE")) then
        aura_env.VF_onHekiliEvent()
    end
    return true
end

-- ===== actions.init 自定义代码 =====
--[[
通用Hekili跟随逻辑
版本：1.4
作者：哀冬
鸣谢：风雪飘摇 胡里胡涂
]]
if((WOW_PROJECT_ID ~= WOW_PROJECT_MISTS_CLASSIC) and (WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC)) then return end
if APL_HEKILIFOLLOWER then return end; APL_HEKILIFOLLOWER = true
local HekiliActionID = 0
local HekiliWait = 0
local ActionList = {}
local CursorAOESpells = {}
local LagTimestmap = 0

---遍历技能书中的主动技能
if(WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC) then
    local tmp = 1
    local _, _, offset, numSlots = GetSpellTabInfo(2)--直接找到第二页也就是主技能栏槽位信息推测全部技能数
    for j = 1, (offset+numSlots or 0) do
        local spellName, _, spellID = GetSpellBookItemName(j, BOOKTYPE_SPELL)
        if spellID and (not C_Spell.IsSpellPassive(spellID)) then
            ActionList[tmp] = {}
            ActionList[tmp][1] = spellID
            ActionList[tmp][2] = "spell"
            ActionList[tmp][3] = spellName
            tmp = tmp+1
        end
    end
    CursorAOESpells = {
        "英勇飞跃","挑战战旗","挫志战旗",
        "暴风雪","烈焰风暴",
        "群体驱散","真言术：障",
        "火焰之雨","召唤地狱火","暗影之怒",
        "扰乱",
        "视界术","治疗之雨","地震术",
        "飓风","星界风暴","乌索尔旋风",
        "召唤青龙雕像","召唤玄牛雕像",
    }
elseif(WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC) then
    --先遍历通用+三系所有等级主动技能
    local highestSpells = {}
    for i = 1, GetNumSpellTabs() do
        local _, _, offset, numSlots = GetSpellTabInfo(i)
        for j = 1, (numSlots or 0) do
            local spellName, _, spellID = GetSpellBookItemName(offset+j, BOOKTYPE_SPELL)
            if spellID and (not C_Spell.IsSpellPassive(spellID)) then
                local spellLevel = select(4, GetSpellInfo(spellID)) or 0
                -- 如果当前技能等级更高，或者等级相同但ID更大
                if not highestSpells[spellName] or 
                spellLevel > highestSpells[spellName].level or
                (spellLevel == highestSpells[spellName].level and spellID > highestSpells[spellName].id) then
                    highestSpells[spellName] = {id = spellID, level = spellLevel}
                end
            end
        end
    end
    
    -- 添加最高等级技能到ActionList
    local tmp = 1
    for spellName, spellData in pairs(highestSpells) do
        ActionList[tmp] = {}
        ActionList[tmp][1] = spellData.id
        ActionList[tmp][2] = "spell"
        ActionList[tmp][3] = spellName
        tmp = tmp+1
    end
    CursorAOESpells = {
        "乱射","陷阱发射器：爆炸陷阱","豪猪诱饵",
        "暴风雪","烈焰风暴",
        "群体驱散",
        "火焰之雨","地狱火","暗影之怒",
        "扰乱",
        "视界术",
        "飓风","自然之力"
    }
    ---插入工程手套
    table.insert(ActionList, {54758, "item", 10})--新版hekili序号
    ---插入0~-111的药水
    table.insert(ActionList, {-99, "macro", "/use [nochanneling] 速度药水\\n/use [nochanneling] 狂野魔法药水", 236871})
    ---插入-111~-1000的物品
    table.insert(ActionList, {-999, "macro", "/use [nochanneling] 10\\n/use [nochanneling] 13\\n/use [nochanneling] 14", 237576})
    ---插入-1000以上的物品
    table.insert(ActionList, {-9999, "macro", "/use [nochanneling] 通用热力工程炸药\\n/use [@player,nochanneling] 萨隆邪铁炸弹", 133035})
else
    --目前只支持WLK和MOP版本
    
end
---保底0处理
table.insert(ActionList, {0, "macro", "/stopmacro", GetSpellTexture(6603)})

local hasMelee = false
for i, action in ipairs(ActionList) do
    if(action[1] == 6603) then---修改6603攻击技能变成startattack宏
        action[2] = "macro"
        action[3] = "/startattack"
        hasMelee = true
    elseif(select(1, GetSpellInfo(action[1])) == "枯萎凋零") then--DK的凋零改为自身为中心的宏
        action[2] = "macro"
        action[3] = "/cast [@player] 枯萎凋零"
        action[4] = GetSpellTexture("枯萎凋零")
    elseif CursorAOESpells then
        for _, name in ipairs(CursorAOESpells) do
            local spellname = select(1, GetSpellInfo(action[1]))
            if spellname and name == spellname then
                action[2] = "macro"
                action[3] = string.format("/cast [@cursor] %s", spellname)
                action[4] = GetSpellTexture(spellname)
            end
        end
    end
end
if not hasMelee then
    table.insert(ActionList, {6603, "macro", "/startattack"})
end

function aura_env.VF_onHekiliEvent()
    if((HekiliDisplayPrimary~= nil) and 
        (HekiliDisplayPrimary.Recommendations ~= nil) and 
        (HekiliDisplayPrimary.Recommendations[1] ~= nil) and 
        (HekiliDisplayPrimary.Recommendations[1].actionID ~= nil) and 
        (HekiliDisplayPrimary.Recommendations[1].wait ~= nil)
    )then
        HekiliActionID = HekiliDisplayPrimary.Recommendations[1].actionID
        HekiliWait = HekiliDisplayPrimary.Recommendations[1].wait
        LagTimestmap = GetTime()
    end
end

local function APLCallback_HekiliFollower()
    local NextActionID = 6603
    local CastWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
    local GCD = VF_getSpellCD(61304)
    local lag = GetTime() - LagTimestmap
    LagTimestmap = GetTime()
    if UnitChannelInfo("player") then
        NextActionID = 6603
    elseif(HekiliWait-lag-0.9*CastWindow <= GCD) then
        if HekiliActionID > 0  then
            NextActionID = HekiliActionID
        elseif HekiliActionID < 0 and HekiliActionID >= -111 then
            NextActionID = -99
        elseif HekiliActionID < -111 and HekiliActionID >= -1000 then
            NextActionID = -999
        elseif HekiliActionID < -1000 and (GetItemCount(-HekiliActionID) > 0) then
            NextActionID = -9999
        else
            NextActionID = 0
        end
    end
    for _, action in ipairs(ActionList) do
        if(action[1] == NextActionID) then
            return NextActionID
        end
    end
    return NextActionID
end

aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_HekiliFollower
aura_env.APLName = "Hekili"

-- ===== actions.init 加载时自定义代码 =====
if((WOW_PROJECT_ID ~= WOW_PROJECT_MISTS_CLASSIC) and (WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC)) then return end
local WAEnv = aura_env
if C_AddOns.IsAddOnLoaded("Hekili") then
    C_Timer.After(0.1, function() VF_registerAPL(WAEnv) end) --尽量让Hekili晚点注册，免得抢占第一顺位
end