# 刺杀贼

---

### 毁伤

```text


#showtooltip 毁伤
/stopcasting
/use [@player,combat] 10
/cast [@focus,exists,harm,nodead][@mouseover,exists,harm,nodead][harm,nodead] 毁伤
/startattack


```

### 冷血 + 毒伤

```text


#showtooltip 冷血
/stopcasting
/cast 狮心  -- 狮心（人类种族天赋）
/cast [@focus,exists,harm,nodead][@mouseover,exists,harm,nodead][harm,nodead] 冷血
/cast [@focus,exists,harm,nodead][@mouseover,exists,harm,nodead][harm,nodead] 毒伤
/startattack


```

## 血之饥渴 + 切割

```text


#showtooltip 血之饥渴
/cast 血之饥渴
/cast 切割
/startattack


```

## 爆发

```text


#showtooltip
-- 使用工程物品
/use 10  -- 手套
/cast 狮心  -- 狮心（人类种族天赋）
-- 嫁祸逻辑：优先给目标的目标，其次焦点，最后当前目标
/cast [@targettarget, harm, nodead] 嫁祸诀窍; [@focus, harm, nodead] 嫁祸诀窍; 嫁祸诀窍
-- 确保在攻击
/startattack


```