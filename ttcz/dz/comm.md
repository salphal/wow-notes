### 切换武器

```text


#showtooltip 毁伤
-- 切换武器
/equipslot 16 毁灭之刃
/equipslot 17 剃心者


#showtooltip 刀扇
-- 切换武器
/equipslot 16 泰坦神铁法术之刃
/equipslot 17 恶魔之击


```

### 刀扇

```text


#showtooltip 刀扇
/targetenemy [noharm][dead]
/startattack
/cast 刀扇



```

### 嫁祸

```text


#showtooltip 嫁祸诀窍
-- 优先级：焦点友方 > 鼠标指向友方 > 当前敌方目标的友方目标 > 当前友方目标
/cast [@focus,help,nodead][@mouseover,help,nodead][@targettarget,help,nodead][help,nodead] 嫁祸诀窍


```

### 佯攻

```text


#showtooltip 佯攻
-- 优先级：焦点敌方 > 鼠标指向敌方 > 当前敌方目标
/cast [@focus,help,nodead][@mouseover,help,nodead][@targettarget,help,nodead][help,nodead] 佯攻


```

### 搜索

```text


#showtooltip
/cleartarget
/targetenemy [noharm][dead]
/cast 搜索


```

### 脚踢

```text


#showtooltip 脚踢
/stopcasting
/cast [@focus,exists,harm,nodead] 脚踢
/cast [@mouseover,exists,harm,nodead] 脚踢
/cast [harm,nodead] 脚踢
/run local t=UnitName("focus") or UnitName("mouseover") or UnitName("target"); if t then print("脚踢已施放在: "..t) end


```

### 血之饥渴 + 切割

```text


/showtooltip
/stopattack
/castsequence reset=2/combat 血之饥渴,切割
/startattack


```

### 毒药

```text


#showtooltip 毁灭之刃
-- 主手: 致命药膏 IX
/use item:43233
/use 16


#showtooltip 毁灭之刃
-- 主手: 速效药膏 IX
/use item:43231
/use 16


#showtooltip 熔火犬牙
-- 副手: 速效药膏 IX
/use item:43231
/use 17


#showtooltip 熔火犬牙
-- 副手: 减速药膏
/use item:43233
/use 17


#showtooltip 熔火犬牙
-- 副手: 麻痹药膏
/use item:43232
/use 17


```
























