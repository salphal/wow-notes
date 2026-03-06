# 防骑

## 96969

### T66

```text


/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/stopattack
/castsequence reset=5/combat 正义之锤,正义盾击
/startattack


```

### T999

```text


/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/stopattack
/castsequence reset=8/combat 智慧审判,神圣之盾,奉献
/startattack


```

### 96969

```text


/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/stopattack
/castsequence reset=8/combat 神圣之盾,正义盾击,智慧审判,正义之锤,奉献,正义盾击,神圣之盾,正义之锤,智慧审判,正义盾击,奉献,正义之锤
/startattack


```

---

## 必备

### T恳盾

```text


/showtooltip 圣洁护盾
/stopattack
/castsequence reset=30/combat 神圣恳求,圣洁护盾
/startattack


```

### T单嘲

```text


#showtooltip 清算之手
-- 优先级: 鼠标指向敌对目标 > 焦点敌对目标 > 当前敌对目标
/cast [@mouseover,harm,nodead][@focus,harm,nodead][harm,nodead] 清算之手
/cast 神圣恳求


```

### T群嘲

```text


#showtooltip 正义防御
-- 优先级: 鼠标指向友方 > 焦点友方 > 目标的目标是玩家
/cast [@mouseover,help,nodead,exists][@focus,help,nodead,exists][@targettarget,help,nodead,exists,noharm] 正义防御


```

### Buff

```text


#showtooltip
/stopattack
/castsequence reset=5/combat 正义之怒,命令圣印,强效庇护祝福
/startattack


```

## 快捷释放

### T飞盾

```text


#showtooltip
/stopcasting
/cast [@focus,harm,nodead][@mouseover,harm,nodead][] 复仇者之盾
/startattack


```

### 晕断

```text


#showtooltip
-- 优先级: 鼠标指向敌方 > 焦点敌方 > 当前目标敌方
/stopcasting
/targetenemy [noharm][dead]
/cast [@mouseover,harm,nodead][@focus,harm,nodead][@target,harm,nodead] 制裁之锤
/startattack


```

### 自由

```text


#showtooltip
-- 优先级: 鼠标指向 > 焦点 > 当前友方目标 > 自己
/stopcasting
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead][@player] 自由之手
/startattack


```

### 圣疗

```text


#showtooltip
-- 优先级: 鼠标指向友方 > 焦点友方 > 当前目标友方 > 自己
/stopcasting
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead][@player] 圣疗术
/startattack


```

### 神圣干涉

```text


#showtooltip
-- 优先级: 鼠标指向友方 > 焦点友方 > 当前目标友方
/stopcasting
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead] 神圣干涉
/startattack


```

### 爆发

```text


#showtooltip
/cast 复仇之怒
/cast 狮心
/use 10
-- /use 13 -- FQ 不用开饰品
-- /use 14 -- FQ 不用开饰品


```

### 拯救

```text


#showtooltip
-- 优先级: 鼠标指向友方 > 焦点友方 > 当前目标友方 > 自己
/stopcasting
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead][@player] 拯救之手
/cancelaura 拯救之手


```

### 保护

```text


#showtooltip
-- 优先级: 鼠标指向友方 > 焦点友方 > 当前目标友方 > 自己
/stopcasting
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead][@player] 保护之手
/cancelaura 保护之手


```

### 小牺

```text


#showtooltip 牺牲之手
-- 优先级: 鼠标指向友方 > 焦点友方 > 当前目标友方
/stopcasting
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead] 牺牲之手
/startattack


```

### 大牺

```text


#showtooltip 神圣牺牲
-- 优先级: 鼠标指向友方 > 焦点友方 > 当前目标友方
/stopcasting
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead] 神圣牺牲
/startattack


```

### 圣佑

```text


#showtooltip
-- 按一下开启, 再按一下取消
/stopcasting
/cast 圣佑术
/cancelaura 圣佑术


```

### 无敌

```text


#showtooltip
-- 按一下开启, 再按一下取消
/stopcasting
/cast 圣盾术
/cancelaura 圣盾术


```

### 饰品

```text


#showtooltip
/stopcasting
/use 13
/use 14
/startattack


```

### 驱散


```text


/stopcasting 清洁术
-- 优先级: 鼠标指向友方 > 焦点友方 > 当前目标友方 > 自己
/stopcasting
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead][@player] 清洁术
/startcasting


```


























