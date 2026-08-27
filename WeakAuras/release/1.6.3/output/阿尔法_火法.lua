--[[
aura id: 阿尔法_火法
aura uid: a1phaFireMage
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--[[
  火法一键 APL - 泰坦重铸时光服
  作者：阿尔法
  核心循环：法术连击瞬发炎爆 > 灼烧debuff保持 > 活动炸弹保持 > 燃烧爆发 > 火球术填充
]]
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
if APL_FIRE_MAGE_ALPHA then return end; APL_FIRE_MAGE_ALPHA = true
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
    21873, --鱼斯拉.盘牙守护者
    21806,   --盲眼.暗心缚法者
    21966,   --深水领主.深水卫士沙克基斯
    21964,   --深水领主.深水卫士卡莉蒂斯
    21965,   --深水领主.深水卫士泰达维斯
    22120,   --深水领主.深水孢子蝠

    -- 风暴要塞
    18806,   --大星术师.日咎祭司
    20064,   --凯尔萨斯.亵渎者萨拉德雷
    20063,   --凯尔萨斯.首席技师塔隆尼库斯
    20062,   --凯尔萨斯.星术师卡波妮娅
    20060,   --凯尔萨斯.萨古纳尔男爵
    21362,     --凯尔萨斯.凤凰
    21364,     --凯尔萨斯.凤凰卵

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
    34780, --加拉克苏斯大王.地狱火山
    34826, --加拉克苏斯大王.痛苦女王
    34825, --加拉克苏斯大王.虚空传送门
    34815, --加拉克苏斯大王.魔焰地狱火
    34607, --阿努巴拉克.蛛魔掘地者

    -- 祖尔格拉布
    14988, --血领主曼多基尔.奥根
    11348, --高阶祭司塞卡尔.狂热者扎斯
    11347, --高阶祭司塞卡尔.狂热者洛卡恩
    14826, --妖术师金度.祭品巨魔
    14986, --妖术师金度.金度之影
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
        huoballshu = {ID = 42891, Name = "/cast 火球术\\n/petattack [combat]"},
        zhuoshao = {ID = 42873, Name = "/cast 灼烧\\n/petattack [combat]"},
        yanbaoshu = {ID = 42833, Name = "/cast 炎爆术\\n/petattack [combat]"},
        huodongzhadan = {ID = 55360, Name = "/cast 活动炸弹\\n/petattack [combat]"},
        ranshao = {ID = 11129, Name = "/cast 燃烧\\n/petattack [combat]"},
        chongjibo = {ID = 42859, Name = "/cast 冲击波\\n/petattack [combat]"},
        longxishu = {ID = 42840, Name = "/cast 龙息术\\n/petattack [combat]"},
        lieyanfengbao = {ID = 42826, Name = "/cast 烈焰风暴\\n/petattack [combat]"},
        jingxiang = {ID = 55342, Name = "镜像"},
        rongyanhujia = {ID = 43046, Name = "熔岩护甲"},
        aoshuzhihui = {ID = 42995, Name = "奥术智慧"},
        falibaoshi = {ID = 42985, Name = "制造法力宝石"},
        fanzhi = {ID = 47528, Name = "法术反制"},
        shanxian = {ID = 1953, Name = "闪现"},
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
        fashulianji = {ID = 48108, Name = "法术连击"},
        rongyanhujia = {ID = 43046, Name = "熔岩护甲"},
        aoshuzhihui = {ID = 42995, Name = "奥术智慧"},
    },

    Debuffs = {
        zhuoshao = {ID = 42873, Name = "灼烧"},
        jinpilijin = {ID = 57723, Name = "筋疲力尽"},
        xinmanyizu = {ID = 57724, Name = "心满意足"},
    },

    Thresholds = {
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
    {Config.Spells.huoballshu.ID, "macro", Config.Spells.huoballshu.Name,GetSpellTexture("火球术")},
    {Config.Spells.zhuoshao.ID, "macro", Config.Spells.zhuoshao.Name,GetSpellTexture("灼烧")},
    {Config.Spells.yanbaoshu.ID, "macro", Config.Spells.yanbaoshu.Name,GetSpellTexture("炎爆术")},
    {Config.Spells.huodongzhadan.ID, "macro", Config.Spells.huodongzhadan.Name,GetSpellTexture("活动炸弹")},
    {Config.Spells.ranshao.ID, "macro", Config.Spells.ranshao.Name,GetSpellTexture("燃烧")},
    {Config.Spells.chongjibo.ID, "macro", Config.Spells.chongjibo.Name,GetSpellTexture("冲击波")},
    {Config.Spells.longxishu.ID, "macro", Config.Spells.longxishu.Name,GetSpellTexture("龙息术")},
    {Config.Spells.lieyanfengbao.ID, "macro", Config.Spells.lieyanfengbao.Name,GetSpellTexture("烈焰风暴")},
    {Config.Spells.jingxiang.ID, "spell", Config.Spells.jingxiang.Name},
    {Config.Spells.rongyanhujia.ID, "spell", Config.Spells.rongyanhujia.Name},
    {Config.Spells.aoshuzhihui.ID, "spell", Config.Spells.aoshuzhihui.Name},
    {Config.Spells.falibaoshi.ID, "spell", Config.Spells.falibaoshi.Name},
    {Config.Spells.fanzhi.ID, "spell", Config.Spells.fanzhi.Name},
    {Config.Spells.shanxian.ID, "spell", Config.Spells.shanxian.Name},
    {Config.Spells.fashibaofa.ID, "macro", Config.Spells.fashibaofa.Name,GetSpellTexture("制造法力宝石")},
    {Config.Spells.jumofashibaofa.ID, "macro", Config.Spells.jumofashibaofa.Name,GetSpellTexture("狂暴(种族特长)")},
    {6603, "macro", "/startattack"},
}
local faction = UnitFactionGroup("player")
-- 核心输出回调函数
local function APLCallback_FireMageRotation()
    local NextSpellID = Config.Spells.huoballshu.ID
    local GCD = VF_getSpellCD(Config.Spells.GlobalCD.ID)
    local ManaPercent = getManaPercent()
    local InCombat = UnitAffectingCombat("player")
    local IsMoving = IsPlayerMoving()
    local IsBoss = isBoss()
    local IsBossFight = isTargetBossOrInNpcList()
    local AOECount = getAOECount(10)
    local CastingTime = getCastingTime()
    local TargetHPPercent = getHPPercent("target")
    local faliqingyuCount = getItemCountInBag(Config.Items.faliqingyu.ID)
    local TargetDeadTime = VF_getTargetDeadTime()

    -- 技能CD获取
    local huoballshuCD = math.max(0, VF_getSpellCD(Config.Spells.huoballshu.ID) - GCD)
    local zhuoshaoCD = math.max(0, VF_getSpellCD(Config.Spells.zhuoshao.ID) - GCD)
    local yanbaoshuCD = math.max(0, VF_getSpellCD(Config.Spells.yanbaoshu.ID) - GCD)
    local huodongzhadanCD = math.max(0, VF_getSpellCD(Config.Spells.huodongzhadan.ID) - GCD)
    local ranshaoCD = math.max(0, VF_getSpellCD(Config.Spells.ranshao.ID) - GCD)
    local chongjiboCD = math.max(0, VF_getSpellCD(Config.Spells.chongjibo.ID) - GCD)
    local longxishuCD = math.max(0, VF_getSpellCD(Config.Spells.longxishu.ID) - GCD)
    local lieyanfengbaoCD = math.max(0, VF_getSpellCD(Config.Spells.lieyanfengbao.ID) - GCD)
    local jingxiangCD = math.max(0, VF_getSpellCD(Config.Spells.jingxiang.ID) - GCD)
    local rongyanhujiaCD = math.max(0, VF_getSpellCD(Config.Spells.rongyanhujia.ID) - GCD)
    local fanzhiCD = math.max(0, VF_getSpellCD(Config.Spells.fanzhi.ID) - GCD)
    local shanxianCD = math.max(0, VF_getSpellCD(Config.Spells.shanxian.ID) - GCD)

    local shixinCD = math.max(0, VF_getSpellCD(Config.ZhongZuSpells.shixin.ID) - GCD)
    local kuangbaoCD = math.max(0, VF_getSpellCD(Config.ZhongZuSpells.kuangbao.ID) - GCD)
    local shoutaoCD = VF_getItemCD(Config.Items.shoutao.ID)
    local shipin1CD = VF_getItemCD(Config.Items.shipin1.ID)
    local shipin2CD = VF_getItemCD(Config.Items.shipin2.ID)

    -- Buff获取
    local fashulianjiBuff = math.max(0, getMyBuff(Config.Buffs.fashulianji.ID))
    local rongyanhujiaBuff = math.max(0, getMyBuff(Config.Buffs.rongyanhujia.ID))
    local aoshuzhihuiBuff = math.max(0, getMyBuff(Config.Buffs.aoshuzhihui.ID))

    -- DeBuff时长获取
    local zhuoshaoDeBuff = math.max(0, VF_getDebuff("target", Config.Debuffs.zhuoshao.ID, "HARMFUL") - GCD)
    local jinpilijinDeBuff = math.max(0, getMyDebuff(Config.Debuffs.jinpilijin.ID))
    local xinmanyizuDeBuff = math.max(0, getMyDebuff(Config.Debuffs.xinmanyizu.ID))

    -- 法力青玉
    if not InCombat and faliqingyuCount <= 0 then
        NextSpellID = Config.Spells.falibaoshi.ID
        return NextSpellID
    end

    -- 补奥术智慧
    if aoshuzhihuiBuff <= 300 and VF_getSpellCD(Config.Spells.aoshuzhihui.ID) <= Config.Thresholds.castWindow and not InCombat then
        NextSpellID = Config.Spells.aoshuzhihui.ID
        return NextSpellID
    end

    -- 补熔岩护甲
    if InCombat then
        if rongyanhujiaBuff == 0 and rongyanhujiaCD <= Config.Thresholds.castWindow then
            NextSpellID = Config.Spells.rongyanhujia.ID
            return NextSpellID
        end
    else
        if rongyanhujiaBuff <= 300 and rongyanhujiaCD <= Config.Thresholds.castWindow then
            NextSpellID = Config.Spells.rongyanhujia.ID
            return NextSpellID
        end
    end

    -- 镜像（BOSS战爆发前）
    if (jinpilijinDeBuff > 0 or xinmanyizuDeBuff > 0) and jingxiangCD <= Config.Thresholds.castWindow and IsBossFight and WAParam.config.autoJingxiang then
        NextSpellID = Config.Spells.jingxiang.ID
        return NextSpellID
    end

    -- 爆发宏（燃烧+种族+饰品）
    if InCombat and IsBossFight then
        if (shixinCD <= Config.Thresholds.castWindow or shoutaoCD <= Config.Thresholds.castWindow or shipin1CD <= Config.Thresholds.castWindow or shipin2CD <= Config.Thresholds.castWindow) and WAParam.config.autoFirstBurst and TargetDeadTime > 20 then
            if ranshaoCD <= Config.Thresholds.castWindow then
                NextSpellID = Config.Spells.fashibaofa.ID
                return NextSpellID
            end
        end
        if kuangbaoCD <= Config.Thresholds.castWindow and xinmanyizuDeBuff > 0 and xinmanyizuDeBuff <= 560 and WAParam.config.autoFirstBurst then
            NextSpellID = Config.Spells.jumofashibaofa.ID
            return NextSpellID
        end
    end

    -- 打断
    if WAParam.config.autoInterrupt and fanzhiCD <= Config.Thresholds.castWindow then
        local _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
        if not notInterruptible then
            local casting = UnitCastingInfo("target")
            if casting then
                NextSpellID = Config.Spells.fanzhi.ID
                return NextSpellID
            end
        end
    end

    -- 法术连击触发 → 瞬发炎爆术（最高优先级）
    if fashulianjiBuff > 0 and yanbaoshuCD <= Config.Thresholds.castWindow and TargetHPPercent > 0 then
        NextSpellID = Config.Spells.yanbaoshu.ID
        return NextSpellID
    end

    -- 保持灼烧debuff（5%暴击）
    if zhuoshaoDeBuff <= 4 and zhuoshaoCD <= Config.Thresholds.castWindow and not IsMoving then
        NextSpellID = Config.Spells.zhuoshao.ID
        return NextSpellID
    end

    -- 活动炸弹（dot保持，AOE或单体）
    if VF_getDebuff("target", Config.Spells.huodongzhadan.ID, "HARMFUL|PLAYER") <= 4 and huodongzhadanCD <= Config.Thresholds.castWindow and TargetHPPercent > 0 and TargetDeadTime > 8 then
        NextSpellID = Config.Spells.huodongzhadan.ID
        return NextSpellID
    end

    -- 多目标活动炸弹：扫描 nameplate，给无炸弹的目标轮流上炸弹（自动切换目标）
    if WAParam.config.autoMultiBomb and AOECount >= 2 and huodongzhadanCD <= Config.Thresholds.castWindow and not IsMoving then
        local bombTargetFound = nil
        for i = 1, 40 do
            local unitid = "nameplate" .. i
            if UnitExists(unitid) and UnitCanAttack("player", unitid) and not UnitIsDead(unitid) then
                if WeakAuras.CheckRange(unitid, 30, "<=") then
                    local bombRemain = math.max(0, VF_getDebuff(unitid, Config.Spells.huodongzhadan.ID, "HARMFUL|PLAYER") - GCD)
                    if bombRemain <= 0 then
                        bombTargetFound = unitid
                        break
                    end
                end
            end
        end
        if bombTargetFound then
            if UnitIsUnit(bombTargetFound, "target") then
                NextSpellID = Config.Spells.huodongzhadan.ID
            else
                TargetUnit(bombTargetFound)
                NextSpellID = Config.Spells.huodongzhadan.ID
            end
            return NextSpellID
        end
    end

    -- AOE：烈焰风暴（3+目标）
    if AOECount >= 3 and lieyanfengbaoCD <= Config.Thresholds.castWindow and not IsMoving and ManaPercent > 30 then
        NextSpellID = Config.Spells.lieyanfengbao.ID
        return NextSpellID
    end

    -- 移动中：冲击波/龙息（瞬发）否则等待
    if IsMoving then
        if chongjiboCD <= Config.Thresholds.castWindow then
            NextSpellID = Config.Spells.chongjibo.ID
            return NextSpellID
        end
        if longxishuCD <= Config.Thresholds.castWindow then
            NextSpellID = Config.Spells.longxishu.ID
            return NextSpellID
        end
        return 6603 -- 无瞬发技能，移动中等待
    end

    -- 火球术填充
    if huoballshuCD <= Config.Thresholds.castWindow and TargetHPPercent > 0 then
        NextSpellID = Config.Spells.huoballshu.ID
        return NextSpellID
    end

    -- 兜底
    return NextSpellID
end
aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_FireMageRotation
aura_env.APLName = "阿尔法火法"

-- ===== actions.init 加载时自定义代码 =====
if(WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC) then return end
VF_registerAPL(aura_env)
