# 刺杀贼

---

### 毁伤

```text


#showtooltip 毁伤
-- 切换武器
/equipslot 16 毁灭之刃
/equipslot 17 血腥撕裂者
/cast 毁伤
/startattack  -- 确保攻击


```

### 刀扇

```text


#showtooltip
-- 切换武器
/equipslot 16 泰坦神铁法术之刃
/equipslot 17 恶魔之击
/wait 0.1  -- 装备切换的延迟
/cast 刀扇
/startattack  -- 确保攻击


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