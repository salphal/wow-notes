# 防战

## 必备

### T毁灭

```text

#showtooltip 毁灭打击
-- 没有目标 或 目标死亡 → 自动选最近敌人
/targetenemy [noharm][dead]
-- 优先级: -- 优先级: 鼠标指向 > 焦点 > 当前目标 > 自动最近敌人
/cast [@mouseover,harm,nodead][@focus,harm,nodead][@target,harm,nodead] 毁灭打击                                         
/startattack


```

### T顺劈

```text

#showtooltip 顺劈斩
-- 没有目标 或 目标死亡 → 自动选最近敌人
/targetenemy [noharm][dead]
-- 优先级: -- 优先级: 鼠标指向 > 焦点 > 当前目标 > 自动最近敌人
/cast [@mouseover,harm,nodead][@focus,harm,nodead][@target,harm,nodead] 顺劈斩                                         
/startattack


```

### T盾猛

T盾猛

```text


#showtooltip 盾牌猛击
-- 没有目标 或 目标死亡 → 自动选最近敌人
/targetenemy [noharm][dead]
-- 优先级: -- 优先级: 焦点 > 鼠标指向 > 当前目标 > 自动最近敌人
/cast [@focus,harm,nodead][@mouseover,harm,nodead][@target,harm,nodead] 盾牌猛击                                         
/startattack


```

### T雷挫

```text


#showtooltip
/castsequence reset=6/combat 雷霆一击,挫志怒吼
/startattack


```

### T怒气

```text


/showtooltip
/castsequence reset=10/combat 狂暴之怒,血性狂暴


```

### T投掷

```text


/showtooltip
/castsequence reset=10/combat 英勇投掷,碎裂投掷


```

---

## 冲锋 & 拦截 & 援护

### T援护

```text


#showtooltip 援护
-- 优先级: 鼠标友方 > 鼠标敌人的目标 > 当前友方 > 当前敌人的目标
/cast [@mouseover,help,nodead][@mouseovertarget,help,nodead][@target,help,nodead][@targettarget,help,nodead] 援护


```

### T冲锋

```text


#showtooltip 冲锋
-- 优先级：鼠标指向 > 当前目标
/cast [@mouseover,harm,nodead][@target,harm,nodead] 冲锋
/startattack


```

### T拦截

```text


#showtooltip 拦截
-- 优先级：鼠标指向 > 当前目标
/cast [@mouseover,harm,nodead][@target,harm,nodead] 拦截
/startattack


```

## 群嘲 & 单嘲

### T群嘲

```text

#showtooltip 挑战怒吼
/cast 挑战怒吼
/startattack

```

### T单嘲

```text

#showtooltip 惩戒痛击
-- 优先级: 鼠标指向 > 当前目标
/cast [@mouseover,harm,nodead][@target,harm,nodead] 惩戒痛击
/startattack

```

### T嘲讽

```text


#showtooltip 嘲讽
-- 优先级: 鼠标敌人 > 当前友方的敌方目标 > 当前目标
/cast [@mouseover,harm,nodead][@targettarget,harm,nodead][@target,harm,nodead] 嘲讽
/startattack


```

### T缴械

```text


#showtooltip 缴械
-- 优先级: 鼠标指向 > 当前目标
/cast [@mouseover,harm,nodead][@target,harm,nodead] 缴械
/startattack


```

## 快速释放

### T打断

```text


#showtooltip 盾击
-- 优先级: 焦点 > 鼠标指向 > 当前目标
/cast [@focus,harm,nodead][@mouseover,harm,nodead][@target,harm,nodead] 盾击
/startattack


#showtooltip 震荡猛击
-- 优先级: 焦点 > 鼠标指向 > 当前目标
/cast [@focus,harm,nodead][@mouseover,harm,nodead][@target,harm,nodead] 震荡猛击
/startattack


#showtooltip
/startattack
-- 优先级: 鼠标指向 > 当前目标
/castsequence [@mouseover,harm,exists][] reset=10/combat 盾击, 震荡猛击


```

### T反击

```text


#showtooltip 反击风暴
/stopattack
/cast 战斗姿态
/cast 反击风暴
/cast 防御姿态
/startattack

                                                 

```