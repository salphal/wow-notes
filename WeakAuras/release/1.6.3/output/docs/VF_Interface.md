# VF_Interface 输出逻辑文档

> aura id: VF_Interface | uid: n7jy9hKFT8X | regionType: empty
> 角色：虚空之花框架的**公共接口层**（禁止修改此文件）
> 本文档描述其对外暴露的 API，供各职业 APL 调用。

---

## 1. 文件结构

| 代码块 | 作用 |
|--------|------|
| `actions.init 自定义代码` | 注册 VF_InterfaceInitFlag 防重入 + 定义全部公共函数 |

文件头注释明确：**严禁修改此文件**。各 APL 需要的函数请各自实现，此文件仅为注册和旧接口向前兼容。

防重入机制：
```lua
VF_InterfaceInitFlag = VF_InterfaceInitFlag or false
if (VF_InterfaceInitFlag == true) then return else VF_InterfaceInitFlag = true end
```

---

## 2. 公共函数 API（VF_ 前缀全局函数）

| 函数 | 参数 | 返回 | 说明 |
|------|------|------|------|
| `VF_registerAPL(APLEnv)` | APLEnv=aura_env | — | 注册动作列表和 APL 回调（转发到 VF_Common.registerAPL） |
| `VF_getTargetDeadTime(HPpercent)` | HPpercent 可选 1~99 | 击杀预估时间 | 达到对应血量百分比的预估时间；无参数返回默认值 |
| `VF_getSpellCD(spellId)` | 技能ID | 剩余CD秒数 | 技能冷却剩余时间 |
| `VF_getItemCD(itemId)` | 物品ID | 剩余CD秒数 | 装备/物品冷却剩余时间 |
| `VF_getBuff(unit, buffId, filter)` | 单位/buffID/过滤 | retval1: 剩余时间, retval2: 叠加层数 | buff 信息查询 |
| `VF_getDebuff(unit, buffId, filter)` | 单位/debuffID/过滤 | retval1: 剩余时间, retval2: 叠加层数 | debuff 信息查询 |

> 注意：`VF_getBuff`/`VF_getDebuff` 的 filter 常用值：`"HELPFUL"`、`"HARMFUL"`、`"HARMFUL|PLAYER"`（仅自己施加的）。

---

## 3. aura_env 注册契约（APL 必须提供）

各职业 APL 在注册前必须向 aura_env 赋值以下成员：

| 字段 | 类型 | 说明 |
|------|------|------|
| `aura_env.APLActionList` | table | 动作列表：`{{动作ID, 动作类型, 技能名称/宏字符串/装备槽位, [图标]}}` |
| `aura_env.APLCallback` | function | APL 逻辑回调，每次调用返回一个动作在 APLActionList 中的动作ID |
| `aura_env.APLName` | string | APL 逻辑名，方便确认加载的 APL 项 |

**APLActionList 动作类型**：
- `"spell"` — 技能ID
- `"item"` — 装备槽位（如 10=手套, 13=饰品1, 14=饰品2）
- `"macro"` — 宏字符串（如 `/startattack`、`/use 13`），第 [4] 元素可指定图标号

**动作ID 约定**（虚空之花私服协议）：
- 正数 = 技能/法术 ID
- 负数 = 特殊宏（各 APL 自定义，如 -112 工程手套、-300 爆发宏）
- 0 或 6603 = 平砍/兜底

---

## 4. 调用流程

```
VF_registerAPL(aura_env)
  └─> VF_Common.registerAPL(APLEnv)   // 框架注册该 APL

每次帧更新/事件触发：
  VF_Common 调用 aura_env.APLCallback()
    └─> 返回动作ID
  VF_Common 按 ID 在 APLActionList 查找并执行对应宏/技能
```

---

## 5. 修改指引

**此文件禁止修改**。若需要新增公共函数：
1. 在各自 APL 文件内实现（文件头注释明确要求）
2. 或联系框架维护者在 VF_Common 中实现后在此转发

各职业新增技能/宏时，只需要修改自己的 `APLActionList` 和 `APLCallback`，不需要动此文件。
