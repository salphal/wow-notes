# 防骑

## 96969

### T66

```text


/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/startattack
/castsequence reset=5/combat 正义之锤,正义盾击
/startattack


```

### T999

```text


/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/startattack
/castsequence reset=8/combat 智慧审判,神圣之盾,奉献
/startattack

/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/startattack
/castsequence reset=8/combat 智慧审判,神圣之盾
/startattack


/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/startattack
/castsequence reset=8/combat 圣光审判,神圣之盾,奉献
/startattack

/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/startattack
/castsequence reset=8/combat 圣光审判,神圣之盾
/startattack


```

### 96969

```text

/castsequence reset=8/combat 神圣之盾,正义盾击,智慧审判,正义之锤,奉献,正义盾击,神圣之盾,正义之锤,智慧审判,正义盾击,奉献,正义之锤

/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/castsequence reset=8/combat 智慧审判,正义盾击,神圣之盾,正义之锤,奉献,智慧审判,神圣之盾,正义之锤,神圣之盾,正义盾击,奉献,正义之锤
/startattack

/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/castsequence reset=8/combat 圣光审判,正义盾击,神圣之盾,正义之锤,奉献,圣光审判,神圣之盾,正义之锤,神圣之盾,正义盾击,奉献,正义之锤
/startattack

/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/castsequence reset=8/combat 神圣之盾,正义盾击,圣光审判,正义之锤,奉献,正义盾击,神圣之盾,正义之锤,圣光审判,正义盾击,奉献,正义之锤
/startattack

/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/castsequence reset=8/combat 智慧审判,正义之锤,神圣之盾,正义盾击,奉献
/startattack

/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/castsequence reset=8/combat 神圣之盾,正义盾击,智慧审判,正义之锤,奉献,正义盾击,神圣之盾,正义之锤,智慧审判,正义盾击,奉献,正义之锤
/startattack


```

---

## 必备

### T恳盾

```text


/showtooltip
/castsequence reset=30/combat 神圣恳求,圣洁护盾
/startattack

/showtooltip
/castsequence reset=30/combat 圣洁护盾,神圣恳求
/startattack

/showtooltip 神圣恳求
/castsequence reset=30/combat 圣洁护盾,/cancelaura 神圣恳求
/startattack

#showtooltip
/castsequence reset=30/combat 圣洁护盾
/cancelaura 神圣恳求
/startattack


```

### 单嘲

```text


#showtooltip 清算之手
-- 优先级: 鼠标指向敌对目标 > 焦点敌对目标 > 当前敌对目标
/cast [@mouseover,harm,nodead][@focus,harm,nodead][harm,nodead] 清算之手
/cast 神圣恳求
/startattack


```

### 反嘲

```text


#showtooltip 正义防御
-- 优先级: 鼠标指向友方 > 焦点友方 > 当前目标的目标
/cast [@mouseover,help,nodead] [@focus,help,nodead] [@targettarget,help,nodead] 正义防御
/startattack


```

### Buff

```text


#showtooltip
/castsequence reset=5/combat 正义之怒,命令圣印,感知亡灵,虔诚光环,强效庇护祝福


```

## 快捷释放

### 飞盾

```text


#showtooltip
/targetenemy [noharm][dead]
-- 优先级: 鼠标指向敌方 > 焦点敌方 > 当前目标敌方
/cast [@mouseover,harm,nodead][@focus,harm,nodead][@target,harm,nodead] 复仇者之盾
/startattack


```

### 愤怒

```text


#showtooltip 愤怒之锤
/targetenemy [noharm][dead]
-- 优先级: 鼠标指向敌方 > 焦点敌方 > 当前目标敌方
/cast [@mouseover,harm,nodead][@focus,harm,nodead][@target,harm,nodead] 愤怒之锤
/startattack


```

### 打断

```text


#showtooltip 制裁之锤
/targetenemy [noharm][dead]
-- 优先级: 鼠标指向敌方 > 焦点敌方 > 当前目标敌方
/cast [@mouseover,harm,nodead][@focus,harm,nodead][@target,harm,nodead] 制裁之锤
/startattack


```

### 自由

```text


#showtooltip
-- 优先级: 鼠标指向 > 焦点 > 当前友方目标 > 自己
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead][@player] 自由之手
/startattack


```

### 圣疗

```text


#showtooltip
-- 优先级: 鼠标指向友方 > 焦点友方 > 当前目标友方 > 自己
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead][@player] 圣疗术
/startattack


```

### 爆发

```text


#showtooltip
/use 13
/use 14
/cast 复仇之怒
/cast 狮心
/use 10


```

### 拯救

```text


#showtooltip
-- 优先级: 鼠标指向友方 > 焦点友方 > 当前目标友方 > 自己
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead][@player] 拯救之手
/cancelaura 拯救之手


```

### 保护

```text


#showtooltip
-- 优先级: 鼠标指向友方 > 焦点友方 > 当前目标友方 > 自己
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead][@player] 保护之手
/cancelaura 保护之手


```

### 小牺

```text


#showtooltip 牺牲之手
-- 优先级: 鼠标指向友方 > 焦点友方 > 当前目标友方
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead] 牺牲之手
/startattack


```

### 大牺

```text


#showtooltip
-- 按一下开启, 再按一下取消
/stopcasting
/cast 神圣牺牲
/cancelaura 神圣牺牲


```

#### 圣佑

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
/use 13
/use 14
/startattack


```

### 驱散

```text


/stopcasting 清洁术
-- 优先级: 鼠标指向友方 > 焦点友方 > 当前目标友方 > 自己
/cast [@mouseover,help,nodead][@focus,help,nodead][@target,help,nodead][@player] 清洁术
/startcasting


```


























