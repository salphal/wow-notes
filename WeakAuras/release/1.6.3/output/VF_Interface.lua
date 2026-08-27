--[[
aura id: VF_Interface
aura uid: n7jy9hKFT8X
regionType: empty
从 WeakAuras 导入字符串解码提取
]]

-- ===== actions.init 自定义代码 =====
--严禁修改此文件，各个APL需要的函数请自己在各自APL实现，此文件仅仅为注册和旧接口向前兼容
VF_InterfaceInitFlag = VF_InterfaceInitFlag or false
if (VF_InterfaceInitFlag == true) then return else VF_InterfaceInitFlag = true end

------------对外公共函数列表
---
---
---注册动作列表和APL回调
---APLEnv：APL对应WA的aura_env环境变量，必须是aura_env而不是自定义表项!, 且在注册前要向aura_env中为以下每一个成员做赋值
---aura_env.APLActionList：APL动作列表，格式为{{动作ID（该ID不强求为技能ID号，只要是唯一标识的即可）,动作类型,技能名称/宏字符串/装备槽位}}，例如下：
----{
------{10,"item",10},
------{50334,"spell","狂暴"},
------{6603,"macro","/startattack",GetSpellTexture(6603)} --宏可以指定图标号（不是技能ID号）作为[4]号元素，也可以不写，不写默认为虚空之花图标
------{13,"macro","/use 13",GetInventoryItemTexture("player", 13)}
----}
---aura_env.APLCallback：APL逻辑函数回调，要求每调用一次返回一个动作在aura_env.APLActionList中的动作ID号
---aura_env.APLName:APL逻辑名，方便确认加载APL项, 必须为string格式
---相比于上一代接口，初始化工作请各个APL代码在WA的自定义载入中完成
function VF_registerAPL(APLEnv) if VF_Common then return VF_Common.registerAPL(APLEnv) end end

---获取击杀预估时间
---HPpercent:若填写参数(1~99)，则返回达到对应百分比血量的预估时间
function VF_getTargetDeadTime(HPpercent) if VF_Common then return VF_Common.getTargetDeadTime(HPpercent) end end

---获取技能冷却剩余秒数
function VF_getSpellCD(spellId) if VF_Common then return VF_Common.getSpellCD(spellId) end end

---获取装备冷却剩余秒数
function VF_getItemCD(itemId) if VF_Common then return VF_Common.getItemCD(itemId) end end

---获取buff/debuff信息
---param:
-----unit: 单位标识符
-----buffId: buff/debuff ID
-----filter: 过滤条件
---return:
-----retval1: buff/debuff剩余冷却时间
-----retval2: buff/debuff叠加次数
function VF_getBuff(unit, buffId, filter) if VF_Common then return VF_Common.getBuff(unit, buffId, filter) end end
function VF_getDebuff(unit, buffId, filter) if VF_Common then return VF_Common.getDebuff(unit, buffId, filter) end end