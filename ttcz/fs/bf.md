# 冰法

## 必备

### 寒冰箭

```text


#showtooltip 寒冰箭
-- 优先级：鼠标指向 > 焦点 > 当前目标 > 自动选择最近敌人
/cast [@mouseover,harm,nodead][@focus,harm,nodead][harm,nodead] 寒冰箭
/use 10  -- 使用手套（工程学加速器）
/petattack [@mouseover,harm,nodead][@focus,harm,nodead][harm,nodead]


```

### 冰枪术

```text


#showtooltip 冰枪术
-- 优先级：鼠标指向 > 焦点 > 当前目标 > 自动选择最近敌人
/cast [@mouseover,harm,nodead][@focus,harm,nodead][harm,nodead] 冰枪术
/use 10  -- 使用手套（工程学加速器）
/petattack [@mouseover,harm,nodead][@focus,harm,nodead][harm,nodead]


```

### 霜火之箭

```text


#showtooltip 霜火之箭
-- 优先级：鼠标指向 > 焦点 > 当前目标 > 自动选择最近敌人
/cast [@mouseover,harm,nodead][@focus,harm,nodead][harm,nodead] 霜火之箭
/use 10  -- 使用手套（工程学加速器）
/petattack [@mouseover,harm,nodead][@focus,harm,nodead][harm,nodead]


```

### 火焰冲击

```text


#showtooltip 火焰冲击
-- 优先级：鼠标指向 > 焦点 > 当前目标 > 自动选择最近敌人
/cast [@mouseover,harm,nodead][@focus,harm,nodead][harm,nodead] 火焰冲击
/use 10  -- 使用手套（工程学加速器）
/petattack [@mouseover,harm,nodead][@focus,harm,nodead][harm,nodead]


```

---

## 爆发

| 技能     | CD   |
|--------|------|
| `狮心`   | 3m   |
| `冰冷血脉` | 2.4m |
| `急速冷却` | 6m   |
| `镜像`   | 3m   |
| `饰品`   | 1m   |
| `速度药水` | --   |


### 爆发1

```text


#showtooltips 镜像
/stopcasting
/cast 镜像
/cast 狮心
/cast 冰冷血脉
/use 速度药水
/use 10 
/use 13 
/use 14


```

### 爆发2

```text


#showtooltips 急速冷却
/stopcasting
/cast 急速冷却
/cast 镜像
/cast 狮心
/cast 冰冷血脉
/use 速度药水
/use 10 
/use 13 
/use 14


```

### 急速冷却 + 冰冷血脉

```text


#showtooltips 急速冷却
/stopcasting
/use 10
/use 13
/use 14
/cast 急速冷却
/cast 冰冷血脉
/use 速度药水



```

## 快速释放

### 互转专注

```text


#showtooltip 专注魔法
/cast [@mouseover,exists,nodead][@target,exists,nodead] 专注魔法
/run SendChatMessage(UnitName("player").." 为你添加了《专注魔法》互换思密达~", "WHISPER", nil, UnitName("target"))


```

### 打断

```text


#showtooltip 法术反制
-- 优先级: 鼠标指向 > 焦点 > 当前目标
/stopcasting
/cast [@mouseover,harm,nodead][@focus,exists,nodead][@target,harm,nodead] 法术反制


```

### 召唤水元素

```text

#showtooltip 召唤水元素
/cast 冰冻术
/petpassive
/petattack [harm]
/petfollow [noharm]
/stopmacro [target=pet,nodead,exists,nomod]
/cast 召唤水元素


```

### Buff

```text

#showtooltip 熔岩护甲
/castsequence reset=5/combat 熔岩护甲,奥术光辉


```

### 防护火焰结界 + 防护火焰结界

```text

/showtooltip 防护火焰结界
/castsequence reset=30/combat 防护火焰结界,防护火焰结界


```

### 寒冰护体 + 法力护盾

```text


#showtooltip 寒冰护体
/castsequence reset=combat/30 寒冰护体, 法力护盾, cancelaura 法力护盾



```
