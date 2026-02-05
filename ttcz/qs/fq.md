# 防骑

## 96969

### 66

```text


/showtooltip 复仇之怒
/startattack
/castsequence reset=5/combat 正义之锤,正义盾击


```

### 999

```text


/showtooltip 智慧审判
/startattack
/castsequence reset=8/combat 智慧审判,神圣之盾,奉献


```

### 96969

```text

/showtooltip 复仇之怒
/startattack
/castsequence reset=8/combat 神圣之盾,正义盾击,圣光审判,正义之锤,奉献,正义盾击,神圣之盾,正义之锤,圣光审判,正义盾击,奉献,正义之锤


```

---

## 必备

### 神圣恳求 + 圣洁护盾

```text

/showtooltip 圣洁护盾
/castsequence reset=30/combat 神圣恳求,圣洁护盾


```

### 清算之手 + 神圣恳求

```text


#showtooltip 清算之手
/cast [@focus,harm,nodead][@mouseover,harm,nodead][] 清算之手
/cast 神圣恳求


```

### Buff*3

```text

#showtooltip 正义之怒
/castsequence reset=5/combat 正义之怒,命令圣印,强效庇护祝福


```

### 正义防御

```text

#showtooltip 正义防御
/cast [@mouseover,help,exists] 正义防御 -- 优先指向目标
/cast [@targettarget,help] 正义防御 -- 其次指向目标的目标
/cast 正义防御


```

## 快捷释放

### 复仇者之盾

```text


#showtooltip 复仇者之盾
/cast [@focus,harm,nodead][@mouseover,harm,nodead][] 复仇者之盾
/cast 圣洁护盾


```

### 制裁之锤

```text


#showtooltip 制裁之锤
/cast [@focus,harm,nodead][@mouseover,harm,nodead][] 制裁之锤


```

### 自由之手

```text


#showtooltip 自由之手
-- 优先级: 焦点 > 目标 > 自己
/cast [@focus,help,nodead][@target,help,nodead][@player] 自由之手


```

### 圣疗术

```text


#showtooltip 圣疗
-- 优先级: 焦点 > 目标 > 自己
/cast [@focus,help,nodead][@target,help,nodead][@player] 圣疗术


```

### 复仇之怒 + 狮心( 种族天赋 )

```text


#showtooltip 复仇之怒
/cast 复仇之怒
/cast 狮心


```

### 神圣牺牲

```text


#showtooltip 神圣牺牲
/stopcasting
/cast 神圣牺牲
/cancelaura 神圣牺牲


```
