--[[
aura id: 虎呗特_碎冰法
aura uid: gGjMt1zWljx
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
冰法一键逻辑
作者：虎呗特
优化融合：碎冰之舞
]]

-- 版本和全局表初始化
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
if APL_FrostMage_TITAN then return end; APL_FrostMage_TITAN = true


local function splitStr(str, sep)
    local result = {}
    for part in string.gmatch(str, "[^" .. sep .. "]+") do
        table.insert(result, part)
    end
    return result
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

local function getBuffRankByPlayer(unit, buffname)
    if (WA_GetUnitBuff) then
        local name, _, rank, _, _, _, source = WA_GetUnitBuff(unit, buffname)
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
    --14965, --高阶祭司耶克里克.疯狂的觅血蝠
    --11373, --高阶祭司温诺希斯.拉扎什眼镜蛇
    --11388, --高阶祭司玛尔里.枯木部落演讲者
    --15041, --高阶祭司玛尔里.玛尔里的爪牙
    14988, --血领主曼多基尔.奥根
    11348, --高阶祭司塞卡尔.狂热者扎斯
    11347, --高阶祭司塞卡尔.狂热者洛卡恩
    --166359, --高阶祭司塞卡尔.祖利安猛虎
    --15101, --高阶祭司娅尔罗.祖利安徘徊者
    14826, --妖术师金度.祭品巨魔
    14986, --妖术师金度.金度之影
    --11357, --哈卡.哈卡之子
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

local WAParam = aura_env

local Config = {
    -- 版本控制
    WowVersion = WOW_PROJECT_WRATH_CLASSIC,
    
    Spells = {
        shuanghuozhijian = {ID = 47610, Name = "/cast 霜火之箭\\n/petattack [combat]"},
        bingshuangxinxing = {ID = 42917, Name = "冰霜新星"},
        bingzhuishu = {ID = 42931, Name = "/cast 冰锥术\\n/petattack [combat]"},
        hanbingbaozhu = {ID = 1284421, Name = "寒冰宝珠"},
        hanbingjian = {ID = 42842, Name = "/cast 寒冰箭\\n/petattack [combat]"},
        bingqiangshu = {ID = 42914, Name = "/cast 冰枪术\\n/petattack [combat]"},
        binglengxuemai = {ID = 12472, Name = "/cast 冰冷血脉\\n/petattack [combat]"},
        rongyanhujia = {ID = 43046, Name = "熔岩护甲"},
        shendudongjie = {ID = 44572, Name = "/cast 深度冻结\\n/petattack [combat]"},
        jisulengque = {ID = 11958, Name = "/cast 急速冷却\\n/petattack [combat]\\n/cast 寒冰箭"},
        shuiyuansu = {ID = 31687, Name = "召唤水元素"},
        falixiqu = {ID = 30449, Name = "法力吸取"},
        aoshuzhihui = {ID = 42995, Name = "奥术智慧"},
        dalaranguanghui = {ID = 61316, Name = "达拉然光辉"},
        aoshuguanghui = {ID = 43002, Name = "奥术光辉"},
        jingxiang = {ID = 55342, Name = "镜像"},
        falibaoshi = {ID = 42985, Name = "制造法力宝石"},
        fashibaofa = {ID = 9999997, Name = "/cast 狮心(种族特长)\\n/use 10\\n/use 13\\n/use 14\\n/use 法力青玉"},
        jumofashibaofa = {ID = 9999996, Name = "/cast 狂暴(种族特长)\\n/use 10\\n/use 13\\n/use 14\\n/use 法力青玉"},
        GlobalCD = {ID = 61304, Name = "全局冷却"},
    },
    
    ZhongZuSpells = {
        shixin = {ID = 20599, Name = "狮心(种族特长)"},
        shixiangxingtai = {ID = 20594, Name = "石像形态(种族特长)"}, 
        kuangbao = {ID = 26297, Name = "狂暴(种族特长)"},
        xuexingkuangnu = {ID = 20572, Name = "血性狂怒(种族特长)"},
    },
    
    Buffs = {
        huoqiubuff = {ID = 57761, Name = "火球！"},
        hanbingzhi = {ID = 74396, Name = "寒冰指"},
        rongyanhujia = {ID = 43046, Name = "熔岩护甲"},
        aoshuzhihui = {ID = 42995, Name = "奥术智慧"},
        aoshuguanghui = {ID = 43002, Name = "奥术光辉"},
        binglengxuemai = {ID = 12472, Name = "冰冷血脉"},
        dalaranzhihui = {ID = 61024, Name = "达拉然智慧"},
        dalaranguanghui = {ID = 61316, Name = "达拉然光辉"},
    },
    
    Debuffs = {
        jinpilijin = {ID = 57723, Name = "筋疲力尽"},
        xinmanyizu = {ID = 57724, Name = "心满意足"},
    },
    
    Thresholds = {
        meleerange = 5,
        manapercentmin = 20,
        targetcountaoe = 3,
        castWindow = (tonumber(GetCVar("SpellQueueWindow")) or 400)/1000
    },
    
    Items = {
        faliqingyu= {ID = 33312, Name = "法力青玉"},
        shoutao =  {ID = 10, Name = 10},
        shipin1 =  {ID = 13, Name = 13},
        shipin2 =  {ID = 14, Name = 14},
    },
}

-- 核心技能列表
local ActionList = {
    {Config.Spells.hanbingjian.ID, "macro", Config.Spells.hanbingjian.Name,GetSpellTexture("寒冰箭")},
    {Config.Spells.bingqiangshu.ID, "macro", Config.Spells.bingqiangshu.Name,GetSpellTexture("冰枪术")},
    {Config.Spells.shendudongjie.ID, "macro", Config.Spells.shendudongjie.Name,GetSpellTexture("深度冻结")},
    {Config.Spells.shuanghuozhijian.ID, "macro", Config.Spells.shuanghuozhijian.Name,GetSpellTexture("霜火之箭")},
    {Config.Spells.fashibaofa.ID, "macro", Config.Spells.fashibaofa.Name,GetSpellTexture("制造法力宝石")},
    {Config.Spells.jumofashibaofa.ID, "macro", Config.Spells.jumofashibaofa.Name,GetSpellTexture("狂暴(种族特长)")},
    {Config.Spells.binglengxuemai.ID, "macro", Config.Spells.binglengxuemai.Name,GetSpellTexture("冰冷血脉")},
    {Config.Spells.jingxiang.ID, "spell", Config.Spells.jingxiang.Name},
    {Config.Spells.bingzhuishu.ID, "macro", Config.Spells.bingzhuishu.Name,GetSpellTexture("冰锥术")},
    {Config.Spells.bingshuangxinxing.ID, "spell", Config.Spells.bingshuangxinxing.Name},
    {Config.Spells.jisulengque.ID, "macro", Config.Spells.jisulengque.Name,GetSpellTexture("急速冷却")},
    {Config.Spells.shuiyuansu.ID, "spell", Config.Spells.shuiyuansu.Name},
    {Config.Spells.aoshuzhihui.ID, "spell", Config.Spells.aoshuzhihui.Name},
    {Config.Spells.falibaoshi.ID, "spell", Config.Spells.falibaoshi.Name},
    {Config.Spells.rongyanhujia.ID, "spell", Config.Spells.rongyanhujia.Name},
    {Config.Spells.falixiqu.ID, "spell", Config.Spells.falixiqu.Name},
}


-- 核心输出回调函数
local function APLCallback_FrostMageRotation()
    local NextSpellID = Config.Spells.hanbingjian.ID
    local GCD = VF_getSpellCD(Config.Spells.GlobalCD.ID)
    local ManaPercent = getManaPercent()
    local InCombat = UnitAffectingCombat("player")
    local IsMoving = IsPlayerMoving()          
    local IsPetSummoned = UnitExists("pet")
    local IsBoss = isBoss()
    local IsBossFight = isTargetBossOrInNpcList()
    local AOECount = getAOECount(10)
    local AOECountBoss = getAOECountBoss(8)
    local CastingTime = getCastingTime()
    local TargetHPPercent = getHPPercent("target")
    local faliqingyuCount = getItemCountInBag(Config.Items.faliqingyu.ID)
    local IsInRaid = IsInRaid()
    local _, _, _, _, changqiangCurrPoints = GetTalentInfo(3, 32)
    local _, _, _, _, lengfengCurrPoints = GetTalentInfo(3, 30)
    local _, MaxRange = WeakAuras.GetRange("target")
    MaxRange = MaxRange or 28
    
    -- 技能CD获取
    local hanbingjianCD = math.max(0, VF_getSpellCD(Config.Spells.hanbingjian.ID) - GCD)
    local bingqiangshuCD = math.max(0, VF_getSpellCD(Config.Spells.bingqiangshu.ID) - GCD)
    local shuanghuozhijianCD = math.max(0, VF_getSpellCD(Config.Spells.shuanghuozhijian.ID) - GCD)
    
    local bingshuangxinxingCD = math.max(0, VF_getSpellCD(Config.Spells.bingshuangxinxing.ID) - GCD)
    local bingzhuishuCD = math.max(0, VF_getSpellCD(Config.Spells.bingzhuishu.ID) - GCD)
    local hanbingbaozhuCD = math.max(0, VF_getSpellCD(Config.Spells.hanbingbaozhu.ID) - GCD)
    
    local binglengxuemaiCD = math.max(0, VF_getSpellCD(Config.Spells.binglengxuemai.ID) - GCD)
    local shuiyuansuCD = math.max(0, VF_getSpellCD(Config.Spells.shuiyuansu.ID) - GCD)
    local jisulengqueCD = math.max(0, VF_getSpellCD(Config.Spells.jisulengque.ID) - GCD)
    
    local shendudongjieCD = math.max(0, VF_getSpellCD(Config.Spells.shendudongjie.ID) - GCD)
    
    local rongyanhujiaCD = math.max(0, VF_getSpellCD(Config.Spells.rongyanhujia.ID) - GCD)
    local falixiquCD = math.max(0, VF_getSpellCD(Config.Spells.falixiqu.ID) - GCD)
    local jingxiangCD = math.max(0, VF_getSpellCD(Config.Spells.jingxiang.ID) - GCD)
    local aoshuzhihuiCD = math.max(0, VF_getSpellCD(Config.Spells.aoshuzhihui.ID) - GCD)
    local dalaranguanghuiCD = math.max(0, VF_getSpellCD(Config.Spells.dalaranguanghui.ID) - GCD)
    
    local shixinCD = math.max(0, VF_getSpellCD(Config.ZhongZuSpells.shixin.ID) - GCD)
    local kuangbaoCD = math.max(0, VF_getSpellCD(Config.ZhongZuSpells.kuangbao.ID) - GCD)
    local shoutaoCD = VF_getItemCD(Config.Items.shoutao.ID)
    local shipin1CD = VF_getItemCD(Config.Items.shipin1.ID)
    local shipin2CD = VF_getItemCD(Config.Items.shipin2.ID)
    
    -- Buff获取
    local huoqiubuffBuff = math.max(0, getMyBuff(Config.Buffs.huoqiubuff.ID))
    local rongyanhujiaBuff = math.max(0, getMyBuff(Config.Buffs.rongyanhujia.ID))
    local aoshuzhihuiBuff = math.max(0, getMyBuff(Config.Buffs.aoshuzhihui.ID))
    local aoshuguanghuiBuff = math.max(0, getMyBuff(Config.Buffs.aoshuguanghui.ID))
    local hanbingzhiRank = math.max(0, getBuffRankByPlayer("player",Config.Buffs.hanbingzhi.ID))
    local binglengxuemaiBuff = math.max(0, getMyBuff(Config.Buffs.binglengxuemai.ID))
    local dalaranguanghuiBuff = math.max(0, getMyBuff(Config.Buffs.dalaranguanghui.ID))
    local dalaranzhihuiBuff = math.max(0, getMyBuff(Config.Buffs.dalaranzhihui.ID))
    
    -- DeBuff时长获取
    local jinpilijinDeBuff = math.max(0, getMyDebuff(Config.Debuffs.jinpilijin.ID))
    local xinmanyizuDeBuff = math.max(0, getMyDebuff(Config.Debuffs.xinmanyizu.ID))

    -- 急速和施法时间计算
    --local haste = UnitSpellHaste("player") or 0
    local FrostboltCT = ((select(4, GetSpellInfo("寒冰箭")) or 2.2) / 1000)
    --FrostboltCT = FrostboltCT / (1 + haste / 100)

    -- 法力青玉
    if not InCombat and faliqingyuCount <= 0 then
        NextSpellID = Config.Spells.falibaoshi.ID
        return NextSpellID
    end
    
    -- 召唤水元素
    if not IsPetSummoned and shuiyuansuCD <= Config.Thresholds.castWindow and hanbingzhiRank ~= 1 then
        NextSpellID = Config.Spells.shuiyuansu.ID
        return NextSpellID
    end
    
    -- 补奥术智慧/光辉
    if aoshuzhihuiBuff <= 300 and aoshuguanghuiBuff <= 300 and dalaranguanghuiBuff <= 300 and dalaranzhihuiBuff <= 300 and aoshuzhihuiCD <= Config.Thresholds.castWindow and not InCombat then 
        NextSpellID = Config.Spells.aoshuzhihui.ID
        return NextSpellID
    end
    
    -- 补熔岩护甲
    if InCombat then
        if rongyanhujiaBuff == 0 and rongyanhujiaCD <= Config.Thresholds.castWindow and hanbingzhiRank ~= 1 then 
            NextSpellID = Config.Spells.rongyanhujia.ID
            return NextSpellID
        end
    else
        if rongyanhujiaBuff <= 300 and rongyanhujiaCD <= Config.Thresholds.castWindow then 
            NextSpellID = Config.Spells.rongyanhujia.ID
            return NextSpellID
        end
    end
    
    -- 分身
    if (jinpilijinDeBuff > 0 or xinmanyizuDeBuff > 0) and jingxiangCD <= Config.Thresholds.castWindow and IsBossFight and hanbingzhiRank ~= 1 and WAParam.config.autoJingxiang then 
        NextSpellID = Config.Spells.jingxiang.ID
        return NextSpellID
    end
    
    -- 种族技能
    if binglengxuemaiCD > 0 and TargetHPPercent > 0 and hanbingzhiRank ~= 1 then
        if (IsBossFight or not IsInRaid) then
            if (shixinCD <= Config.Thresholds.castWindow or shoutaoCD <= Config.Thresholds.castWindow or shipin1CD <= Config.Thresholds.castWindow or shipin2CD <= Config.Thresholds.castWindow) and WAParam.config.autoFirstBurst then
                NextSpellID = Config.Spells.fashibaofa.ID
                return NextSpellID
            end
            if kuangbaoCD <= Config.Thresholds.castWindow and xinmanyizuDeBuff > 0 and xinmanyizuDeBuff <= 560 and WAParam.config.autoFirstBurst then
                NextSpellID = Config.Spells.jumofashibaofa.ID
                return NextSpellID
            end
        end
    end
    
    -- 冰冷血脉
    if WAParam.config.autoFirstBurst and binglengxuemaiCD <= Config.Thresholds.castWindow and binglengxuemaiBuff == 0 and InCombat and IsBossFight and hanbingzhiRank ~= 1 and WAParam.config.autoBinglengxuemai then 
        NextSpellID = Config.Spells.binglengxuemai.ID
        return NextSpellID
    end
    
    -- 急速冷却
    if WAParam.config.autoFirstBurst and binglengxuemaiCD > 0 and shendudongjieCD > 10 and jisulengqueCD <= Config.Thresholds.castWindow and IsBoss and hanbingzhiRank ~= 1 and WAParam.config.autoJisulengque then 
        NextSpellID = Config.Spells.jisulengque.ID
        return NextSpellID
    end
    
    -- 寒冰指2层判定逻辑
    if hanbingzhiRank >= 1 and (AOECountBoss >= 2 or FrostboltCT < 1) then 
        if shendudongjieCD <= Config.Thresholds.castWindow then
            NextSpellID = Config.Spells.shendudongjie.ID
            return NextSpellID
        end
    end
    
    -- 吹风多目标
    if lengfengCurrPoints >= 1 and AOECountBoss >= 2 then
        if bingzhuishuCD <= Config.Thresholds.castWindow then
            NextSpellID = Config.Spells.bingzhuishu.ID
            return NextSpellID
        elseif bingshuangxinxingCD <= Config.Thresholds.castWindow then
            NextSpellID = Config.Spells.bingshuangxinxing.ID
            return NextSpellID
        end
    end
    
    -- 寒冰指1层判定逻辑
    if hanbingzhiRank == 1 and CastingTime > 0 then 
        if shendudongjieCD <= Config.Thresholds.castWindow then
            NextSpellID = Config.Spells.shendudongjie.ID
            return NextSpellID
        elseif huoqiubuffBuff > 0 then
            NextSpellID = Config.Spells.shuanghuozhijian.ID
            return NextSpellID
        elseif bingqiangshuCD <= Config.Thresholds.castWindow and MaxRange >= 15 and changqiangCurrPoints >= 1 and FrostboltCT >= 1.2 then
            NextSpellID = Config.Spells.bingqiangshu.ID
            return NextSpellID
        elseif bingzhuishuCD <= Config.Thresholds.castWindow and MaxRange <= 10 and lengfengCurrPoints >= 1 and FrostboltCT >= 1 then
            NextSpellID = Config.Spells.bingzhuishu.ID
            return NextSpellID
        elseif bingshuangxinxingCD <= Config.Thresholds.castWindow and MaxRange <= 10 and lengfengCurrPoints >= 1 and FrostboltCT >= 1 then
            NextSpellID = Config.Spells.bingshuangxinxing.ID
            return NextSpellID
        end
    end
    
    -- 无寒冰指
    if hanbingzhiRank == 0 and CastingTime > 0 then
        -- 霜火之箭
        if huoqiubuffBuff > 0 then
            NextSpellID = Config.Spells.shuanghuozhijian.ID
            return NextSpellID
        end

        -- 急速阈值以下卡CD吹风
        if bingzhuishuCD <= Config.Thresholds.castWindow and MaxRange <= 10 and lengfengCurrPoints >= 1 and FrostboltCT > 1.2 then
            NextSpellID = Config.Spells.bingzhuishu.ID
            return NextSpellID
        end

    end
    -- 兜底寒冰箭
    return NextSpellID
end

aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_FrostMageRotation
aura_env.APLName = "虎呗特冰法"

-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)