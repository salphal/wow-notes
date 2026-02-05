# 防战

## 必备

### 毁灭打击 + 顺劈砍

T顺劈

```text


#showtooltip 顺劈斩
/startattack
/cast 毁灭打击
/cast 顺劈斩
/startattack


```

### 毁灭打击 + 英勇

T英勇

```text


#showtooltip 英勇打击
/startattack
/cast 毁灭打击
/cast 英勇打击
/startattack


```

### 雷霆一击 + 挫志怒吼

```text


#showtooltip 雷霆一击
/castsequence reset=6/combat 雷霆一击,挫志怒吼
/startattack


```

### 狂暴之怒 + 血性狂暴

```text


/showtooltip 狂暴之怒
/castsequence reset=10/combat 狂暴之怒,血性狂暴


```

### 英勇投掷 + 碎裂投掷

T投掷

```text


/showtooltip 英勇投掷
/castsequence reset=10/combat 英勇投掷,碎裂投掷


```

---

## 冲锋 & 拦截 & 援护

### 援护

T援护

```text


#showtooltip 援护
/cast [@mouseover,help,nodead] 援护
/cast [@mouseover,harm,nodead,@mouseovertarget,help] 援护
/cast [@target,help,nodead] 援护
/cast [@target,harm,nodead,@targettarget,help] 援护



```

### 冲锋

T冲锋

```text


#showtooltip 冲锋
-- 优先级：鼠标指向 > 当前目标
/cast [@mouseover,harm,nodead][@target,harm,nodead] 冲锋
/startattack



```

### 拦截

T拦截

```text


#showtooltip 拦截
-- 优先级：鼠标指向 > 当前目标
/cast [@mouseover,harm,nodead][@target,harm,nodead] 拦截
/startattack


```

## 群嘲 & 单嘲

### 群嘲

T群嘲

```text

#showtooltip 挑战怒吼
/cast 挑战怒吼
/startattack

```

### 单嘲

T单嘲

```text

#showtooltip 惩戒痛击
-- 优先级: 鼠标指向 > 焦点 > 当前目标
/cast [@mouseover,harm,nodead][@focus,harm,nodead][@target,harm,nodead] 惩戒痛击
/startattack

```

### 嘲讽

T嘲讽

```text

#showtooltip 嘲讽
-- 优先级: 鼠标指向 > 焦点 > 当前目标
/cast [@mouseover,harm,nodead][@focus,harm,nodead][@target,harm,nodead] 嘲讽
/startattack

```

### 缴械

T缴械

```text


#showtooltip 缴械
-- 优先级: 鼠标指向 > 焦点 > 当前目标
/cast [@mouseover,harm,nodead][@focus,harm,nodead][@target,harm,nodead] 缴械
/startattack


```

## 快速释放

### 打断

T打断

```text


#showtooltip 盾击
-- 优先级: 焦点 > 鼠标指向 > 当前目标
/cast [@focus,harm,nodead][@mouseover,harm,nodead][@target,harm,nodead] 盾击
/startattack


```

### 盾牌猛击

T盾猛

```text


#showtooltip 盾牌猛击
/cast 盾牌猛击                                             
/startattack


```

### 反击风暴

T反击

```text


#showtooltip 反击风暴
/cast 战斗姿态
/cast 反击风暴
/cast 防御姿态
/startattack

                                                 

```