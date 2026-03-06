# 狂暴战

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
/equipslot 16 雷霆
/equipslot 17


```

### 狂暴

```text


#showtooltip 狂暴姿态
/cast 狂暴姿态
/equipslot 16 雷霆
/equipslot 17 萨弗拉斯, 炎魔拉格纳罗斯之手


```

### 武器


```text

#showtooltip 防御姿态
/cast 防御姿态
/equipslot 16 勇气红剑
/equipslot 17 钻孔虫之碟


```

## 必备

### 嗜血

K嗜血

```text


#showtooltip 嗜血
/cast 嗜血
/startattack
/cancelaura 保护之手
/use 10


```

### 顺劈

K顺劈

```text


#showtooltip 顺劈斩
/cast 顺劈斩
/startattack
/cancelaura 保护之手
/use 10


```

### 英勇打击

K英勇

```text


#showtooltip 英勇打击
/cast 英勇打击
/startattack
/cancelaura 保护之手
/use 10


```

### 旋风斩

K旋风斩

```text


#showtooltip 旋风斩
/cast 旋风斩
/startattack
/cancelaura 保护之手
/use 10


```

### 猛击

K猛击

```text


#showtooltip 猛击
/cast 猛击
/startattack
/cancelaura 保护之手
/use 10


```

---

### 盾墙

K盾墙

```text


#showtooltip 盾墙
-- 切防御姿态
/cast [nostance:2] 防御姿态
-- 装备单手+盾牌
/equipslot 16 勇气红剑
/equipslot 17 钻孔虫之碟
-- 开启盾墙
/cast 盾墙


```
