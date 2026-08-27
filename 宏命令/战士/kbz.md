# 狂暴战

> 5% 命中
> 26 精准

| 技能    | 怒气 | CD |
|-------|----|----|
| `英勇`  | 12 | -- |
| `顺劈砍` | 20 | -- |
| `猛击`  | 15 | -- |
| `旋风斩` | 25 | 8  |
| `嗜血`  | 20 | 4  |

---

## 姿态 + 武器切换

### 战斗

```text


#showtooltip 战斗姿态
/cast 战斗姿态
/equipslot 16 萨弗拉斯，炎魔拉格纳罗斯之手


```

### 狂暴

```text


#showtooltip 
/cast 狂暴姿态
/equipslot 16 萨弗拉斯，炎魔拉格纳罗斯之手
/equipslot 17 雷霆


```

### 防御


```text

#showtooltip 
/cast 防御姿态
/equipslot 16 雷霆之怒，逐风者的祝福之剑
/equipslot 17 死亡的面孔


```

## 必备

### K嗜血

```text


#showtooltip
/cast 嗜血
/startattack
/cancelaura 保护之手
/use 10


```

### K顺劈

```text


#showtooltip 顺劈斩
/cast 顺劈斩
/startattack
/cancelaura 保护之手
/use 10


```

### K英勇

```text


#showtooltip 英勇打击
/cast 英勇打击
/startattack
/cancelaura 保护之手
/use 10


```

### K旋风

```text


#showtooltip 旋风斩
/cast 旋风斩
/startattack
/cancelaura 保护之手
/use 10


```

### K猛击

```text


#showtooltip 猛击
/cast 猛击
/startattack
/cancelaura 保护之手
/use 10


```

---

### K盾墙

```text


#showtooltip 盾墙
-- 切防御姿态
/cast [nostance:2] 防御姿态
-- 装备单手+盾牌
/equipslot 16 雷霆之怒,逐风者的祝福之剑
/equipslot 17 死亡的面孔
-- 开启盾墙
/cast 盾墙



```


## 爆发

### 爆发

```text


#showtooltip
/cancelaura 保护之手
/cast 死亡之愿
/use 10
/startattack


#showtooltip
/cancelaura 保护之手
/cast 鲁莽
/use 10
/startattack


#showtooltip
/cancelaura 保护之手
/cast 狮心
/use 10
/startattack


```

