--[[
aura id: 虎呗特_兽王猎
aura uid: dD0l7lEbwAM
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
兽王猎一键逻辑
适配：时光服
作者：虎呗特
]]
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
if APL_BeastMasteryHunter_TITAN then return end; APL_BeastMasteryHunter_TITAN = true
local function splitStr(str, sep)
    local result = {}
    for part in string.gmatch(str, "[^" .. sep .. "]+") do
        table.insert(result, part)
    end
    return result
end
local function IsTargetAnubarak()
    if not UnitExists("target") then
        return false
    end
    
    local anubarakNpcIDs = {
        [34564] = true,   -- 5人副本 艾卓-尼鲁布 最终BOSS
        [34567] = true,   -- 英雄难度 艾卓-尼鲁布
        [25797] = true,   -- 奥杜尔 阿努巴拉克
        [15956] = true    -- 纳克萨玛斯 阿努巴拉克
    }
    
    local npcID = tonumber(UnitCreatureID("target"))
    
    if npcID and anubarakNpcIDs[npcID] then
        return true
    end
    
    local targetName = UnitName("target")
    -- 简体中文 / 英文 都支持
    if targetName == "阿努巴拉克" or targetName == "Anub'arak" then
        return true
    end
    
    return false
end
local function getSpellCDHubert(spellId)
    local start, duration, enabled = GetSpellCooldown(spellId)
    if spellId == 61305 then
        return 999
    end
    if (enabled == 1) then
        if (start and (start ~= 0)) then
            return start + duration - GetTime()
        end
        if not IsSpellKnown(spellId) and spellId ~= 61304 and spellId ~= 1282540 and spellId ~=1284409 then
            return 999
        end
        return 0
    else
        return 999
    end
end
local function getItemCDHubert(itemId)
    local start, duration, useable
    if(itemId <= 30) then
        start, duration, useable = GetInventoryItemCooldown("player", itemId)
    else
        start, duration, useable = C_Container.GetItemCooldown(itemId)
    end
    if (useable == 1) then
        if (start and (start ~= 0)) then
            return start + duration - GetTime()
        end
        return 0
    else
        return 999
    end
end
local function getEquipSlotCD(slotNum)
    if not slotNum or type(slotNum) ~= "number" or slotNum < 0 or slotNum > 19 then
        return 999
    end
    
    local itemLink = GetInventoryItemLink("player", slotNum)
    if not itemLink then
        return 999
    end
    
    local hasUsableSpell = false
    local itemId = tonumber(string.match(itemLink, "item:(%d+)"))
    if itemId then
        local spellName, spellId = GetItemSpell(itemId)
        if spellId then
            hasUsableSpell = true
        end
    end
    
    if not hasUsableSpell then
        return 999
    end
    
    local start, duration, isReady = GetInventoryItemCooldown("player", slotNum)
    start = start or 0
    duration = duration or 0
    isReady = isReady or false
    
    if start > 0 and duration > 0 then
        local remainingCD = start + duration - GetTime()
        return math.max(remainingCD, 0)
    else
        return 0
    end
end
local function getBagItemCD(itemId)
    if not itemId or type(itemId) ~= "number" then
        return 999
    end
    
    local itemFound = false
    local start, duration, isReady = 0, 0, true
    
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local containerItemId = C_Container.GetContainerItemID(bag, slot)
            if containerItemId == itemId then
                itemFound = true 
                start, duration, isReady = C_Container.GetContainerItemCooldown(bag, slot)
                break 
            end
        end
        if itemFound then break end 
    end
    
    if not itemFound then
        return 999 
    elseif isReady then
        if start > 0 then
            local remainingCD = start + duration - GetTime()
            return math.max(remainingCD, 0) 
        end
        return 0 
    else
        return 999 
    end
end
local function getItemCountInBag(itemId)
    local count = GetItemCount(itemId, false, false)
    return count or 0
end
local function getMyBuff(buffId)
    local buffName, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = WA_GetUnitBuff("player", buffId, "HARMFUL")
    if (buffName ~= nil) then
        if((duration == nil) or (duration == 0)) then
            return 999
        else
            return expirationTime - GetTime()
        end
    end
    return 0
end
local function getTargetDebuff(buffId)
    local buffName, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = WA_GetUnitDebuff("target", buffId, "HARMFUL")
    if (buffName ~= nil) then
        if((duration == nil) or (duration == 0)) then
            return 999
        else
            return expirationTime - GetTime()
        end
    end
    return 0
end
local function getMyDebuff(buffId)
    local buffName, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = WA_GetUnitDebuff("player", buffId, "HARMFUL|PLAYER")
    if (buffName ~= nil) then
        if((duration == nil) or (duration == 0)) then
            return 999
        else
            return expirationTime - GetTime()
        end
    end
    return 0
end
local function getFocusDebuffByPlayer(buffId)
    local buffName, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = WA_GetUnitDebuff("focus", buffId, "HARMFUL|PLAYER")
    if (buffName ~= nil) then
        if((duration == nil) or (duration == 0)) then
            return 999
        else
            return expirationTime - GetTime()
        end
    end
    return 0
end
local function getMySourceDebuff(buffId)
    local buffName, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = WA_GetUnitDebuff("target", buffId, "HARMFUL|PLAYER")
    if (buffName ~= nil) then
        if source == "player" then
            if((duration == nil) or (duration == 0)) then
                return 999
            else
                return expirationTime - GetTime()
            end
        end
    end
    return 0
end
local function getPetBuff(buffId)
    local buffName, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = WA_GetUnitBuff("pet", buffId, "HELPFUL")
    if (buffName ~= nil) then
        if((duration == nil) or (duration == 0)) then
            return 999
        else
            return expirationTime - GetTime()
        end
    end
    return 0
end
local function getHPPercent(unit)
    local currentHP = UnitHealth(unit)
    local maxHP = UnitHealthMax(unit)
    if maxHP == 0 then
        return 0
    end
    local hpPercent = (currentHP / maxHP) * 100
    hpPercent = math.floor(hpPercent * 10) / 10 
    return math.max(0, math.min(100, hpPercent))
end
local function getManaPercent()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    return maxMana > 0 and (mana / maxMana) * 100 or 100
end
local function getBuffStacks(buffId)
    local buffName, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = WA_GetUnitBuff("player", buffId, "HARMFUL|PLAYER")
    if (buffName ~= nil) then
        return count or 0
    end
    return 0
end
local function getBuffRankByPlayer(unit, buffname)
    if (WA_GetUnitBuff) then
        local name, _, rank, _, _, _, source = WA_GetUnitBuff(unit, buffname)
        if (name and source == "player") then
            return rank
        end
    end
    return 0
end
local function getDeBuffRankByPlayer(unit, buffname)
    if (WA_GetUnitDebuff) then
        local name, _, rank, _, _, _, source = WA_GetUnitDebuff(unit, buffname)
        if (name and source == "player") then
            return rank
        end
    end
    return 0
end
local function getAOECount(range)
    local count = 0
    for i = 1, 40 do
        local unitid = "nameplate" .. i
        if UnitExists(unitid) then
            local _, maxRange = WeakAuras.GetRange(unitid)
            if maxRange and (maxRange <= range) then
                count = count + 1
            end
        end
    end
    return count
end
local function getFoundTT(TTName)
    local found = false 
    for i = 1, 4 do 
        local _, totemName = GetTotemInfo(i) 
        if totemName and totemName == TTName then 
            found = true 
            break
        end 
    end 
    return found and 1 or 0
end
-- 目标NPC_ID列表
local TARGET_NPC_IDS = {
    -- 测试
    31144,  -- 主城80级木桩
    32546,  -- DK要塞80级木桩
    
    -- 熔火之心
    12142,   -- 鲁西弗隆.烈焰行者守卫
    11661,    -- 基赫纳斯.烈焰行者
    11662,   -- 萨弗隆.烈焰行者祭司
    11664,  -- 埃克索图斯.烈焰行者精英
    11663,   -- 埃克索图斯.烈焰行者医师
    
    -- 毒蛇神殿
    --21865, --鱼斯拉.盘牙伏击者
    21873, --鱼斯拉.盘牙守护者
    21806,   --盲眼.暗心缚法者
    21966,   --深水领主.深水卫士沙克基斯
    21964,   --深水领主.深水卫士卡莉蒂斯
    21965,   --深水领主.深水卫士泰达维斯
    22120,   --深水领主.深水孢子蝠
    -- 21920,   --踏潮.踏潮潜伏者
    --22055,   --瓦斯琪.盘牙精英
    --22056,   --瓦斯琪.盘牙巡逻者
    
    -- 风暴要塞
    18806,   --大星术师.日咎祭司  
    20064,   --凯尔萨斯.亵渎者萨拉德雷
    20063,   --凯尔萨斯.首席技师塔隆尼库斯
    20062,   --凯尔萨斯.星术师卡波妮娅
    20060,   --凯尔萨斯.萨古纳尔男爵 
    21362,     --凯尔萨斯.凤凰
    21364,     --凯尔萨斯.凤凰卵
    21268,     --凯尔萨斯.灵玄长弓
    21269,     --凯尔萨斯.毁灭
    21270,     --凯尔萨斯.宇宙灌注者
    21271,     --凯尔萨斯.无尽之刃
    21272,     --凯尔萨斯.迁跃切割者
    21273,     --凯尔萨斯.相位壁垒
    21274,     --凯尔萨斯.瓦解法杖
    
    -- 永恒之眼
    30249,  --永恒子嗣.玛里苟斯
    30084,  --能量火花.玛里苟斯
    30245,  --魔枢领主.玛里苟斯
    
    -- 黑曜石圣殿
    31218,  --沙德隆的追随者.萨塔里奥
    30643,  --熔岩烈焰.萨塔里奥
    31214,  --萨塔里奥暮光雏龙.萨塔里奥
    
    -- 纳克萨玛斯
    16573,  --地穴卫士.阿努布雷坎
    16505,  --纳克萨玛斯追随者.黑女巫法琳娜
    15930,  --费尔根.塔迪乌斯
    15929,  --斯塔拉格.塔迪乌斯
    
    -- 十字军的试炼
    --34800, --诺森德猛兽.雪地狗头人奴隶
    34780, --加拉克苏斯大王.地狱火山
    34826, --加拉克苏斯大王.痛苦女王
    34825, --加拉克苏斯大王.虚空传送门
    34815, --加拉克苏斯大王.魔焰地狱火
    34607, --阿努巴拉克.蛛魔掘地者
    
    -- 祖尔格拉布
    14965, --高阶祭司耶克里克.疯狂的觅血蝠
    11373, --高阶祭司温诺希斯.拉扎什眼镜蛇
    11388, --高阶祭司玛尔里.枯木部落演讲者
    15041, --高阶祭司玛尔里.玛尔里的爪牙
    14988, --血领主曼多基尔.奥根
    11348, --高阶祭司塞卡尔.狂热者扎斯
    11347, --高阶祭司塞卡尔.狂热者洛卡恩
    166359, --高阶祭司塞卡尔.祖利安猛虎
    --15101, --高阶祭司娅尔罗.祖利安徘徊者
    14826, --妖术师金度.祭品巨魔
    14986, --妖术师金度.金度之影
    11357, --哈卡.哈卡之子
}
local function checkUnit(unit)
    if not UnitExists(unit) then
        return false
    end
    local targetLevel = UnitLevel(unit)
    if targetLevel == -1 then
        return true
    end
    local unitGuid = UnitGUID(unit)
    local guidParts = splitStr(unitGuid, "-")  
    if not guidParts or #guidParts < 6 then
        return false
    end
    local npcId = tonumber(guidParts[6])  
    if not npcId then
        return false
    end
    for _, targetId in ipairs(TARGET_NPC_IDS) do
        if npcId == targetId then
            return true
        end
    end
    return false
end
local function isTargetBossOrInNpcList()
    if checkUnit("target") then
        return true
    end
    if checkUnit("focus") then
        return true
    end
    return false
end
local function isBoss()
    if UnitLevel("target") == -1 then
        return true
    else
        return false
    end
end
local function getAOECountBoss(range)
    local count = 0
    for i = 1, 40 do
        local unitid = "nameplate" .. i
        if UnitExists(unitid) then
            local unitGuid = UnitGUID(unitid)
            local guidParts = unitGuid and splitStr(unitGuid, "-") or nil
            local npcId = guidParts and #guidParts >= 6 and tonumber(guidParts[6]) or nil
            local unitLevel = UnitLevel(unitid) 
            local _, maxRange = WeakAuras.GetRange(unitid)
            
            local isInIdList = false
            if npcId then
                for _, targetId in ipairs(TARGET_NPC_IDS) do
                    if npcId == targetId then
                        isInIdList = true
                        break
                    end
                end
            end
            local isBoss = (unitLevel == -1)  
            local isInRange = (maxRange and maxRange <= range) 
            if (isInIdList or isBoss) and isInRange then
                count = count + 1
            end
        end
    end
    return count
end
local function isFocusInRangeById(spellId)
    local spellName = GetSpellInfo(spellId)
    if spellName then
        return IsSpellInRange(spellName, "focus") == 1
    end
    return false
end
local function getCastingTime()
    local _, _, _, ctime1, ctime2, _, _, _, spellID = CastingInfo()
    if (ctime1 == nil) then
        _, _, _, ctime1, ctime2, _, _, spellID = ChannelInfo()
    end
    if (ctime1 == nil) then
        return 0
    else
        return (ctime2 - GetTime() * 1000) / 100
    end
end
local function isCastingSpell()
    local _, _, _, ctime1, ctime2, _, _, _, spellID = CastingInfo()
    if not ctime1 then
        _, _, _, ctime1, ctime2, _, _, spellID = ChannelInfo()
    end
    return spellID
end
local function findActionIndexByName(actionName)
    return nil
end
local function getWeaponEnchantInfoMain()
    local mainHandItem = GetInventoryItemID("player", 16) 
    if not mainHandItem then
        return 9999
    end
    local _, _, _,mainHandEnchantID, _, _,_, _ = GetWeaponEnchantInfo()
    if mainHandEnchantID then
        return mainHandEnchantID
    else
        return 0
    end
end
local function getWeaponEnchantInfoOff()
    local offHandItem = GetInventoryItemID("player", 17)
    if not offHandItem then
        return 9999 
    end
    local _, _, _, _, _, _, _, offHandEnchantID = GetWeaponEnchantInfo()
    if offHandEnchantID then
        return offHandEnchantID
    else
        return 0
    end
end
local function hasPet()
    local hasUI, isHunterPet = HasPetUI();
    if hasUI and isHunterPet then
        return 2
    elseif hasUI then
        return 1
    else
        return 0
    end
end
local function getRuneCount(targetType)
    local runeCount = 0
    for i = 1, 6 do 
        local runeReady = select(3, GetRuneCooldown(i)) or false
        --获取第i槽的真实符文类型（1血、2邪、3冰、4死亡）
        local realRuneType = GetRuneType(i) or 0
        if runeReady and realRuneType == targetType then
            runeCount = runeCount + 1
        end
    end
    return runeCount
end
local function getWeaponType(itemLink)
    if not itemLink then
        return "空"
    end
    local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
    return itemSubType or "未知类型"
end
local SilenceDebuffIDs = {
    -- [71041] = "地下城逃亡者", 
    [34190] = "奥术宝珠", 
}
local function hasSilenceDebuff()
    for i = 1, 40 do
        local debuffId = select(10, UnitDebuff("player", i))
        if not debuffId then
            break
        end
        if SilenceDebuffIDs[debuffId] then
            return true
        end
    end
    return false
end
local function findActionIndexByID(actionID)
    if (type(actionID) == "number") then
        for index, action in ipairs(ActionList) do
            if ((action[1] == actionID)
                or ((FindBaseSpellByID(actionID) ~= nil) and ((FindBaseSpellByID(action[1])) == (FindBaseSpellByID(actionID))))
                or ((GetSpellInfo(actionID) ~= nil) and ((GetSpellInfo(action[1])) == (GetSpellInfo(actionID))))
            ) then
                return index
            end
        end
    end
    return findActionIndexByName(actionID)
end
local G_SwingMonitor = nil
if not G_SwingMonitor then
    G_SwingMonitor = {
        baseSpeed = 0,        
        lastSwingTimestamp = 0, 
        pauseTotal = 0,       
        isPaused = false,   
        swingInited = false,
        swingFrame = nil
    }
end
local function initSwingMonitor()
    if G_SwingMonitor.swingInited then return end
    
    G_SwingMonitor.baseSpeed = UnitAttackSpeed("player") or 0
    G_SwingMonitor.lastSwingTimestamp = GetTime()
    G_SwingMonitor.pauseTotal = 0
    G_SwingMonitor.isPaused = false
    
    local frame = CreateFrame("Frame", nil)
    G_SwingMonitor.swingFrame = frame
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame:RegisterEvent("UNIT_SPELLCAST_START")
    frame:RegisterEvent("UNIT_SPELLCAST_STOP")
    frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED") 
    
    frame:SetScript("OnUpdate", function(_, elapsed)
            if G_SwingMonitor.isPaused then
                G_SwingMonitor.pauseTotal = G_SwingMonitor.pauseTotal + elapsed
            end
    end)
    
    frame:SetScript("OnEvent", function(_, event, ...)
            local arg1, arg2 = ...
            
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                local _, evtType, _, sourceGUID, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
                local isPlayer = (sourceGUID == UnitGUID("player"))
                local isSwing = (evtType == "SWING_DAMAGE" or evtType == "SWING_MISSED")
                local isHeroic = (evtType == "SPELL_DAMAGE" and spellID == 47450)
                local isCleave = (evtType == "SPELL_DAMAGE" and spellID == 47520)
                
                if isPlayer and (isSwing or isHeroic or isCleave) then
                    G_SwingMonitor.lastSwingTimestamp = GetTime()
                    G_SwingMonitor.pauseTotal = 0
                    G_SwingMonitor.isPaused = false
                end
                
            elseif event == "UNIT_SPELLCAST_START" then
                local unit, spellName = arg1, arg2
                if unit == "player" then
                    G_SwingMonitor.isPaused = true 
                end
                
            elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" then
                local unit = arg1
                if unit == "player" then
                    G_SwingMonitor.isPaused = false
                end
                
            elseif event == "PLAYER_REGEN_ENABLED" then
                G_SwingMonitor.lastSwingTimestamp = GetTime()
                G_SwingMonitor.pauseTotal = 0
                G_SwingMonitor.isPaused = false
            end
    end)
    
    G_SwingMonitor.swingInited = true
end
initSwingMonitor()
local function getAutoAttackRemainingTime()
    G_SwingMonitor.baseSpeed = G_SwingMonitor.baseSpeed or UnitAttackSpeed("player") or 0
    G_SwingMonitor.lastSwingTimestamp = G_SwingMonitor.lastSwingTimestamp or GetTime()
    local theoreticalRemain = G_SwingMonitor.baseSpeed - (GetTime() - G_SwingMonitor.lastSwingTimestamp - G_SwingMonitor.pauseTotal)
    local remain = math.max(0, theoreticalRemain)
    local isPaused = G_SwingMonitor.isPaused
    
    return remain, G_SwingMonitor.baseSpeed, isPaused
end
local WAParam = aura_env
local isFirstBurstDone = false
local TARGET_BOSS_NAMES = WAParam.config.swl_notUseDuochongsheji
local function splitNames(str, sep)
    local result = {}
    if not str or str == "" then return result end
    str = str:lower()
    for part in string.gmatch(str, "[^" .. sep .. "]+") do
        local name = strtrim(part)
        if name ~= "" then
            table.insert(result, name)
        end
    end
    return result
end
local function checkUnitByName(unit)
    if not UnitExists(unit) then
        return false
    end
    
    local unitName = UnitName(unit)
    if not unitName then return false end
    unitName = unitName:lower()
    
    local nameList = splitNames(TARGET_BOSS_NAMES, ",")
    if #nameList == 0 then return false end
    
    for _, name in ipairs(nameList) do
        if unitName == name then
            return true
        end
    end
    return false
end
local function isNotDuochongshejiInNameList()
    if checkUnitByName("target") then
        return true
    end
    if checkUnitByName("focus") then
        return true
    end
    return false
end
lastXYShootTime = 0  -- 上次雄鹰射击时间
currentXYShootTime = 0 -- 本次雄鹰射击时间
local Config = {
    WowVersion = WOW_PROJECT_WRATH_CLASSIC,
    Spells = {
        longyingshouhu = {ID = 61847, Name = "龙鹰守护"},
        kuisheshouhu = {ID = 34074, Name = "蝰蛇守护"},
        zhiliaochongwu = {ID = 48990, Name = "治疗宠物"},
        fuhuochongwu = {ID = 982, Name = "复活宠物"},
        zhaohuanchongwu = {ID = 883, Name = "召唤宠物"},
        shalumingling = {ID = 34026, Name = "杀戮命令"},
        dushedingci = {ID = 49001, Name = "/cast 毒蛇钉刺\\n/petattack [combat]\\n/cast [@pettarget,exists] 巨兽撕咬\\n/cast [@pettarget,exists] 撕咬\\n/petautocastoff 撕咬\\n/petautocastoff 野蛮撕扯\\n/petautocaston 爪击"},
        lierenyinji = {ID = 53338, Name = "猎人印记"},
        shaluosheji = {ID = 61006, Name = "/cast 杀戮射击\\n/petattack [combat]\\n/cast [@pettarget,exists] 巨兽撕咬\\n/cast [@pettarget,exists] 撕咬\\n/petautocastoff 撕咬\\n/petautocastoff 野蛮撕扯\\n/petautocaston 爪击"},
        JDshaluosheji = {ID = 9061006, Name = "/cast [@focus] 杀戮射击"},
        xiongyingsheji = {ID = 1284199, Name = "/cast 雄鹰射击\\n/petattack [combat]\\n/cast [@pettarget,exists] 巨兽撕咬\\n/cast [@pettarget,exists] 撕咬\\n/petautocastoff 撕咬\\n/petautocastoff 野蛮撕扯\\n/petautocaston 爪击"},
        baozhaxianjing = {ID = 425777, Name = "/cast [@cursor] 陷阱发射器：爆炸陷阱\\n/use [@cursor,combat,group:raid] 萨隆邪铁炸弹"},
        haozhuyouer = {ID = 1284198, Name = "/cast [@cursor] 豪猪诱饵"},
        aoshusheji = {ID = 49045, Name = "/cast 奥术射击\\n/petattack [combat]\\n/cast [@pettarget,exists] 巨兽撕咬\\n/cast [@pettarget,exists] 撕咬\\n/petautocastoff 撕咬\\n/petautocastoff 野蛮撕扯\\n/petautocaston 爪击"},
        duochongsheji = {ID = 49048, Name = "/cast 多重射击\\n/petattack [combat]\\n/cast [@pettarget,exists] 巨兽撕咬\\n/cast [@pettarget,exists] 撕咬\\n/petautocastoff 撕咬\\n/petautocastoff 野蛮撕扯\\n/petautocaston 爪击"},
        wengusheji = {ID = 49052, Name = "/cast 稳固射击\\n/petattack [combat]\\n/cast [@pettarget,exists] 巨兽撕咬\\n/cast [@pettarget,exists] 撕咬\\n/petautocastoff 撕咬\\n/petautocastoff 野蛮撕扯\\n/petautocaston 爪击"},
        kuangyenuhuo = {ID = 19574, Name = "狂野怒火"},
        jisusheji = {ID = 3045, Name = "/cast 急速射击\\n/cast 野性呼唤"},
        JDdushedingci = {ID = 9049001, Name = "/cast [@focus] 毒蛇钉刺"},
        yuanchengbaofa = {ID = 9999999, Name = "/cast 狮心(种族特长)\\n/cast 石像形态(种族特长)\\n/cast 狂暴(种族特长)\\n/cast 血性狂怒(种族特长)\\n/use 10\\n/use 13\\n/use 14"},
        GlobalCD = {ID = 61304, Name = "全局冷却"},
    },
    
    ZhongZuSpells = {
        shixin = {ID = 20599, Name = "狮心(种族特长)"},        
        shixiangxingtai = {ID = 20594, Name = "石像形态(种族特长)"}, 
        kuangbao = {ID = 26297, Name = "狂暴(种族特长)"},             
        xuexingkuangnu = {ID = 20572, Name = "血性狂怒(种族特长)"},               
    },
    
    Buffs = {
        longyingshouhu = {ID = 61847, Name = "龙鹰守护"},
        xiongyingsheji = {ID = 1284379, Name = "雄鹰射击"},
        zhiliaochongwu = {ID = 48990, Name = "治疗宠物"},
        kuisheshouhu = {ID = 34074, Name = "蝰蛇守护"},
    },
    
    Debuffs = {
        lierenyinji = {ID = 53338, Name = "猎人印记"},
        baozhasheji4 = {ID = 60053, Name = "爆炸射击"},
        baozhaxianjing = {ID = 49065, Name = "爆炸陷阱效果"},
        dushedingci = {ID = 49001, Name = "毒蛇钉刺"},
    },
    
    Thresholds = {
        castWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
    },
    
    Items = {
        shoutao =  {ID = 10, Name = 10},
        shipin1 =  {ID = 13, Name = 13},
        shipin2 =  {ID = 14, Name = 14},
        jiasuyaoshui = {ID = 40211, Name = "加速药水"},
        salongxietiezhadan = {ID = 41119, Name = "萨隆邪铁炸弹"},
        tongyongzhadan = {ID = 42641, Name = "通用热力工程炸药"},
    },
}
local ActionList = {
    {Config.Spells.wengusheji.ID, "macro", Config.Spells.wengusheji.Name,GetSpellTexture("稳固射击")},
    {Config.Spells.dushedingci.ID, "macro", Config.Spells.dushedingci.Name,GetSpellTexture("毒蛇钉刺")},
    {Config.Spells.shaluosheji.ID, "macro", Config.Spells.shaluosheji.Name,GetSpellTexture("杀戮射击")},
    {Config.Spells.JDshaluosheji.ID, "macro", Config.Spells.JDshaluosheji.Name,GetSpellTexture("杀戮射击")},
    {Config.Spells.xiongyingsheji.ID, "macro", Config.Spells.xiongyingsheji.Name,GetSpellTexture("雄鹰射击")}, 
    {Config.Spells.baozhaxianjing.ID, "macro", Config.Spells.baozhaxianjing.Name,GetSpellTexture("陷阱发射器：爆炸陷阱")},
    {Config.Spells.haozhuyouer.ID, "macro", Config.Spells.haozhuyouer.Name,GetSpellTexture("豪猪诱饵")},
    {Config.Spells.aoshusheji.ID, "macro", Config.Spells.aoshusheji.Name,GetSpellTexture("奥术射击")},
    {Config.Spells.shalumingling.ID, "spell", Config.Spells.shalumingling.Name},
    {Config.Spells.duochongsheji.ID, "macro", Config.Spells.duochongsheji.Name,GetSpellTexture("多重射击")},
    {Config.Spells.kuangyenuhuo.ID, "spell", Config.Spells.kuangyenuhuo.Name},
    {Config.Spells.jisusheji.ID, "macro", Config.Spells.jisusheji.Name,GetSpellTexture("急速射击")},
    {Config.Spells.JDdushedingci.ID, "macro", Config.Spells.JDdushedingci.Name,GetSpellTexture("毒蛇钉刺")},
    {Config.Spells.yuanchengbaofa.ID, "macro", Config.Spells.yuanchengbaofa.Name, 237576},
    --{6603, "macro", "/startattack"},
    { 75, "macro", "/cast !自动射击", GetSpellTexture("自动射击") },
    {Config.Spells.lierenyinji.ID, "spell", Config.Spells.lierenyinji.Name},
    --{Config.Spells.zhiliaochongwu.ID, "spell", Config.Spells.zhiliaochongwu.Name},
    {Config.Spells.fuhuochongwu.ID, "spell", Config.Spells.fuhuochongwu.Name},
    {Config.Spells.zhaohuanchongwu.ID, "spell", Config.Spells.zhaohuanchongwu.Name},
    {Config.Spells.longyingshouhu.ID, "spell", Config.Spells.longyingshouhu.Name},
    {Config.Spells.kuisheshouhu.ID, "spell", Config.Spells.kuisheshouhu.Name},
}
-- 核心输出逻辑
local function APLCallback_BeastMasteryHunterSimple()
    local NextSpellID = 75
    local GCD = VF_getSpellCD(Config.Spells.GlobalCD.ID)
    local ManaPercent = getManaPercent()
    local InCombat = UnitAffectingCombat("player")
    local IsMoving = IsPlayerMoving()              
    local HasFocus = UnitExists("focus")
    local IsPetSummoned = hasPet()
    local IsBossFight = isTargetBossOrInNpcList()
    local TargetHPPercent = getHPPercent("target")
    local JDHPPercent = getHPPercent("focus")
    local PetHPPercent = getHPPercent("pet")
    local IsFocusInRange = isFocusInRangeById(Config.Spells.dushedingci.ID)
    local TargetDeadTime = VF_getTargetDeadTime()
    local HasSilence = hasSilenceDebuff()
    local targetName = UnitName("target")
    
    -- 获取技能CD
    local longyingshouhuCD = math.max(0, VF_getSpellCD(Config.Spells.longyingshouhu.ID) - GCD)
    --local zhiliaochongwuCD = math.max(0, VF_getSpellCD(Config.Spells.zhiliaochongwu.ID) - GCD)
    local fuhuochongwuCD = math.max(0, VF_getSpellCD(Config.Spells.fuhuochongwu.ID) - GCD) 
    local zhaohuanchongwuCD = math.max(0, VF_getSpellCD(Config.Spells.zhaohuanchongwu.ID) - GCD)
    local shaluminglingCD = math.max(0, VF_getSpellCD(Config.Spells.shalumingling.ID) - GCD)
    local dushedingciCD = math.max(0, VF_getSpellCD(Config.Spells.dushedingci.ID) - GCD)
    local lierenyinjiCD = math.max(0, VF_getSpellCD(Config.Spells.lierenyinji.ID) - GCD)
    local shaluoshejiCD = math.max(0, VF_getSpellCD(Config.Spells.shaluosheji.ID) - GCD)
    local xiongyingshejiCD = math.max(0, VF_getSpellCD(Config.Spells.xiongyingsheji.ID) - GCD)
    local baozhaxianjingCD = math.max(0, VF_getSpellCD(Config.Spells.baozhaxianjing.ID) - GCD)
    local haozhuyouerCD = math.max(0, VF_getSpellCD(Config.Spells.haozhuyouer.ID) - GCD)
    local aoshushejiCD = math.max(0, VF_getSpellCD(Config.Spells.aoshusheji.ID) - GCD)
    local duochongshejiCD = math.max(0, VF_getSpellCD(Config.Spells.duochongsheji.ID) - GCD)
    local wengushejiCD = math.max(0, VF_getSpellCD(Config.Spells.wengusheji.ID) - GCD)
    local kuangyenuhuoCD = math.max(0, VF_getSpellCD(Config.Spells.kuangyenuhuo.ID) - GCD)
    local jisushejiCD = math.max(0, VF_getSpellCD(Config.Spells.jisusheji.ID) - GCD) 
    
    local shoutaoCD = VF_getItemCD(Config.Items.shoutao.ID)
    local shipin1CD = VF_getItemCD(Config.Items.shipin1.ID)
    local shipin2CD = VF_getItemCD(Config.Items.shipin2.ID)
    
    local jiasuyaoshuiCD = getBagItemCD(Config.Items.jiasuyaoshui.ID)
    local salongxietiezhadanCD = getBagItemCD(Config.Items.salongxietiezhadan.ID)
    local tongyongzhadanCD = getBagItemCD(Config.Items.tongyongzhadan.ID)
    
    local shixinCD = math.max(0, VF_getSpellCD(Config.ZhongZuSpells.shixin.ID) - GCD)
    local shixiangxingtaiCD = math.max(0, VF_getSpellCD(Config.ZhongZuSpells.shixiangxingtai.ID) - GCD)
    local kuangbaoCD = math.max(0, VF_getSpellCD(Config.ZhongZuSpells.kuangbao.ID) - GCD)
    local xuexingkuangnuCD = math.max(0, VF_getSpellCD(Config.ZhongZuSpells.xuexingkuangnu.ID) - GCD)
    
    -- 获取Buff
    local longyingshouhuBuff = math.max(0, getMyBuff(Config.Buffs.longyingshouhu.ID))
    --local zhiliaochongwuBuff = math.max(0, getPetBuff(Config.Buffs.zhiliaochongwu.ID))
    local xiongyingshejiRank = math.max(0, getBuffRankByPlayer("player",Config.Buffs.xiongyingsheji.ID))
    local kuisheshouhuBuff = math.max(0, getMyBuff(Config.Buffs.kuisheshouhu.ID))
    
    -- 获取Debuff
    local lierenyinjiDebuff = math.max(0, getTargetDebuff(Config.Debuffs.lierenyinji.ID))
    local dushedingciDebuff = math.max(0, getMySourceDebuff(Config.Debuffs.dushedingci.ID))
    local baozhaxianjingDebuff = math.max(0, getMySourceDebuff(Config.Debuffs.baozhaxianjing.ID))
    local JDdushedingciDebuff = math.max(0, getFocusDebuffByPlayer(Config.Debuffs.dushedingci.ID))
    
    -- 兽王猎核心优先级逻辑
    -- 脱战重置爆发
    if not InCombat and isFirstBurstDone then
        isFirstBurstDone = false
    end
    
    -- 召唤宠物
    if IsPetSummoned == 0 and zhaohuanchongwuCD <= Config.Thresholds.castWindow and not InCombat then
        NextSpellID = Config.Spells.zhaohuanchongwu.ID
        return NextSpellID
    end
    
    -- 蝰蛇舞
    if WAParam.config.AutoViper then
        local function PlayerManaPct()
            local mana = UnitPower("player", 0)
            local maxMana = UnitPowerMax("player", 0)
            return maxMana > 0 and (mana / maxMana) * 100 or 100
        end
        if PlayerManaPct() <= 60 and (duochongshejiCD + GCD) >= 9 then-- 60%蓝以下蝰蛇舞
            NextSpellID = Config.Spells.kuisheshouhu.ID
            return NextSpellID
        elseif longyingshouhuBuff == 0 and longyingshouhuCD <= Config.Thresholds.castWindow then
            NextSpellID = Config.Spells.longyingshouhu.ID
            return NextSpellID
        end
    end
    -- 猎人印记
    if IsBossFight then
        if lierenyinjiDebuff <= 0 and lierenyinjiCD <= Config.Thresholds.castWindow and not InCombat then
            NextSpellID = Config.Spells.lierenyinji.ID
            return NextSpellID
        end
    end
    
    -- 复活宠物
    if IsPetSummoned == 2 and not InCombat then
        if PetHPPercent == 0 and fuhuochongwuCD <= Config.Thresholds.castWindow then
            NextSpellID = Config.Spells.fuhuochongwu.ID
            return NextSpellID
        end
    end
    
    -- 治疗宠物
    --[[if IsPetSummoned == 2 then
        if PetHPPercent < 50 and PetHPPercent >= 1 and zhiliaochongwuBuff == 0 and zhiliaochongwuCD <= Config.Thresholds.castWindow then
            NextSpellID = Config.Spells.zhiliaochongwu.ID
            return NextSpellID
        end
    end]]
    
    -- 杀戮命令
    if shaluminglingCD <= Config.Thresholds.castWindow and InCombat and IsBossFight and not HasSilence and IsPetSummoned ~= 0 then
        NextSpellID = Config.Spells.shalumingling.ID
        return NextSpellID
    end
    
    -- 焦点杀戮射击
    if JDHPPercent < 20 and IsFocusInRange and shaluoshejiCD <= Config.Thresholds.castWindow then
        NextSpellID = Config.Spells.JDshaluosheji.ID
        return NextSpellID
    end
    
    -- 狂野怒火
    if kuangyenuhuoCD <= Config.Thresholds.castWindow and InCombat and IsBossFight and IsPetSummoned ~= 0 and WAParam.config.autoKuangyenuhuo then
        NextSpellID = Config.Spells.kuangyenuhuo.ID
        return NextSpellID
    end
    
    -- 急速射击+狂野怒火
    if WAParam.config.autoFirstJisusheji and jisushejiCD <= Config.Thresholds.castWindow and InCombat and IsBossFight and not isFirstBurstDone  then
        NextSpellID = Config.Spells.jisusheji.ID
        return NextSpellID
    end
    
    -- 饰品、加速手套、加速药水、种族技能
    if (shixinCD <= Config.Thresholds.castWindow or shixiangxingtaiCD <= Config.Thresholds.castWindow or kuangbaoCD <= Config.Thresholds.castWindow or xuexingkuangnuCD <= Config.Thresholds.castWindow or shoutaoCD <= Config.Thresholds.castWindow or shipin1CD <= Config.Thresholds.castWindow or shipin2CD <= Config.Thresholds.castWindow) and WAParam.config.autoFirstBurst then
        if IsBossFight and InCombat then
            NextSpellID = Config.Spells.yuanchengbaofa.ID
            return NextSpellID
        end
    end
    
    -- 猎人印记
    if IsBossFight then
        if lierenyinjiDebuff <= 0 and lierenyinjiCD <= Config.Thresholds.castWindow and TargetHPPercent < 90 and not HasSilence then
            NextSpellID = Config.Spells.lierenyinji.ID
            return NextSpellID
        end
    end
    
    -- 杀戮射击
    if TargetHPPercent < 20 and shaluoshejiCD <= Config.Thresholds.castWindow then
        NextSpellID = Config.Spells.shaluosheji.ID
        return NextSpellID
    end
    
    -- 雄鹰射击
    if xiongyingshejiCD <= Config.Thresholds.castWindow then
        if xiongyingshejiRank < 2 then
            NextSpellID = Config.Spells.xiongyingsheji.ID
            return NextSpellID
        elseif lastXYShootTime <= GetTime() - 16.5  then
            NextSpellID = Config.Spells.xiongyingsheji.ID
            return NextSpellID
        end
    end
    
    -- 焦点毒蛇钉刺
    if JDdushedingciDebuff <= 0 and IsFocusInRange and dushedingciCD <= Config.Thresholds.castWindow then
        NextSpellID = Config.Spells.JDdushedingci.ID
        return NextSpellID
    end
    
    -- 目标毒蛇钉刺
    if dushedingciDebuff <= 0 and dushedingciCD <= Config.Thresholds.castWindow and TargetDeadTime > 20 then
        NextSpellID = Config.Spells.dushedingci.ID
        return NextSpellID
    end
    
    -- 爆炸陷阱发射
    if baozhaxianjingCD <= Config.Thresholds.castWindow and WAParam.config.autoTrap then
        NextSpellID = Config.Spells.baozhaxianjing.ID
        return NextSpellID
    end
    
    -- 豪猪诱饵
    if haozhuyouerCD <= Config.Thresholds.castWindow and WAParam.config.autoHaozhu and not isNotDuochongshejiInNameList() then
        NextSpellID = Config.Spells.haozhuyouer.ID
        return NextSpellID
    end
    
    -- 奥术射击
    if aoshushejiCD <= Config.Thresholds.castWindow then
        NextSpellID = Config.Spells.aoshusheji.ID
        return NextSpellID
    end
    
    -- 多重射击
    if duochongshejiCD <= Config.Thresholds.castWindow and not isNotDuochongshejiInNameList() then
        NextSpellID = Config.Spells.duochongsheji.ID
        return NextSpellID
    end
    
    -- 稳固射击
    if wengushejiCD <= Config.Thresholds.castWindow then
        NextSpellID = Config.Spells.wengusheji.ID
        return NextSpellID
    end
end
local function onCLEUEvent()
    local _, subEvent, _, srcGUID, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    
    if (srcGUID == WeakAuras.myGUID 
        and subEvent == "SPELL_CAST_SUCCESS" 
    and spellID == Config.Spells.xiongyingsheji.ID) then 
        lastXYShootTime = currentXYShootTime 
        currentXYShootTime = GetTime() 
    end
    
    if (srcGUID == WeakAuras.myGUID 
        and subEvent == "SPELL_CAST_SUCCESS" 
    and spellID == Config.Spells.jisusheji.ID) then 
        isFirstBurstDone = true
    end
end
local Manager = CreateFrame("Frame","WLKBeastMasteryHunterAPLManager", UIParent)
Manager:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
Manager:SetScript("OnEvent", function(self, e, ...)
        if (e == "COMBAT_LOG_EVENT_UNFILTERED") then
            onCLEUEvent(e)
        end
end)
aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_BeastMasteryHunterSimple
aura_env.APLName = "虎呗特兽王"

-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)