### 六冰触

```text


/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/castsequence reset=2/combat 冰冷触摸,冰冷触摸,活力分流,冰冷触摸,符文武器增效,冰冷触摸,冰冷触摸,冰冷触摸,暗影打击
/cast !符文打击
/startattack


```

### 群拉

```text


/showtooltip
/targetenemy [noharm][dead] -- 没有目标 或 目标死亡 → 自动选最近敌人
/castsequence reset=2/combat 暗影打击,传染,血液沸腾
/cast !符文打击
/startattack


```

### 暗打

```text


#showtooltip
/cast 暗影打击
/cast !符文打击
/startattack


```

### 血打

```text


#showtooltip
/cast 鲜血打击
/cast !符文打击
/startattack


```

### 拉怪

```text


#showtooltip
/stopcasting
/cast [@focus,harm,nodead][@mouseover,harm,nodead][] 死亡之握
/startattack


```

### 单嘲

```text


#showtooltip
/cast [@focus,harm,nodead][@mouseover,harm,nodead][] 黑暗命令
/startattack


```

### 凋零

```text


#showtooltip
/cast [@focus,harm,nodead][@mouseover,harm,nodead][] 枯萎凋零
/startattack


```

### 血沸

```text


#showtooltip
/cast 血液沸腾
/cast !符文打击
/startattack


```

### 冰链

```text


#showtooltip
/targetenemy [noharm][dead]
-- 优先级: 鼠标指向敌方 > 焦点敌方 > 当前目标敌方
/cast [@mouseover,harm,nodead][@focus,harm,nodead][@target,harm,nodead] 寒冰锁链
/startattack


```

### Buff

```text


#showtooltip
/castsequence reset=1/combat 寒冬号角,冰霜灵气


```

### 切换

```text


#showtooltip
/castsequence reset=1/combat 鲜血灵气,冰霜灵气,邪恶灵气


```

### 切换

```text


#showtooltip
/castsequence reset=1/combat 鲜血灵气,冰霜灵气,邪恶灵气


```

### 打断

```text


#showtooltip
/targetenemy [noharm][dead]
-- 优先级: 鼠标指向敌方 > 焦点敌方 > 当前目标敌方
/cast [@mouseover,harm,nodead][@focus,harm,nodead][@target,harm,nodead] 心灵冰冻
/startattack


```

### 打断

```text


冰触

#showtooltip
/cast 冰冷触摸
/cast !符文打击
/startattack


暗打

#showtooltip
/cast 暗影打击
/cast !符文打击
/startattack


血打

#showtooltip
/cast 鲜血打击
/cast !符文打击
/startattack


湮没

#showtooltip 湮没
/cast 湮没
/cast !符文打击
/startattack


冰打

#showtooltip
/cast 冰霜打击
/cast !符文打击
/startattack


凛冲

#showtooltip 凛风冲击
/cast 凛风冲击
/cast !符文打击
/startattack


```





