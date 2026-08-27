# VF_HekiliFollower 输出逻辑文档

> aura id: VF_HekiliFollower | uid: jNBQAxhAyDF | regionType: empty
> 版本：1.4 | 作者：哀冬（鸣谢：风雪飘摇 胡里胡涂）
> 角色：**Hekili 推荐跟随器** —— 读取 Hekili 插件的技能推荐并执行
> 本文档描述其完整输出逻辑。

---

## 1. 文件结构

| 代码块 | 作用 |
|--------|------|
| `trigger 1 自定义触发器` | 监听 `HEKILI_RECOMMENDATION_UPDATE` 事件，调用 `VF_onHekiliEvent` |
| `actions.init 自定义代码` | 扫描技能书构建 ActionList + APLCallback 逻辑 |
| `actions.init 加载时自定义代码` | Hekili 已加载时延迟注册（避免抢占第一顺位） |

版本守卫：`(WOW_PROJECT_ID ~= WOW_PROJECT_MISTS_CLASSIC) and (WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC)` 时退出（仅支持 WLK/MOP）。防重入：`APL_HEKILIFOLLOWER`。

---

## 2. 技能书扫描（ActionList 构建）

### Mists 分支
- 直接取技能书第二页（主技能栏）全部主动技能加入 ActionList
- CursorAOESpells（鼠标指向 AOE）：英勇飞跃、挑战战旗、暴风雪、烈焰风暴、群体驱散、火焰之雨、治疗之雨、地震术、飓风等

### Wrath 分支
- 遍历全部技能页，按技能名保留**最高等级**技能（同等级取更高 ID）
- CursorAOESpells：乱射、爆炸陷阱、豪猪诱饵、暴风雪、群体驱散、火焰之雨、飓风、自然之力等

### 特殊插入（Wrath）
| ID | 类型 | 内容 |
|----|------|------|
| 54758 | item | 工程手套（Hekili 新序号） |
| -99 | macro | 速度药水 + 狂野魔法药水 |
| -999 | macro | /use 10 + 13 + 14（手套+饰品） |
| -9999 | macro | 通用热力工程炸药 + 萨隆邪铁炸弹 |
| 0 | macro | /stopmacro（保底 0 处理） |
| 6603 | macro | /startattack（若扫描到 6603 则替换，无则插入） |

**CursorAOE 处理**：在 CursorAOESpells 名单内的技能改为 `/cast [@cursor] 技能名` 宏。枯萎凋零改为 `/cast [@player] 枯萎凋零`。

---

## 3. 事件处理 VF_onHekiliEvent

读取 `HekiliDisplayPrimary.Recommendations[1]`：
- `actionID` → `HekiliActionID`（记录推荐技能）
- `wait` → `HekiliWait`（记录推荐等待时间）
- 同时记录 `LagTimestmap = GetTime()`（用于延迟修正）

---

## 4. 核心输出逻辑 APLCallback_HekiliFollower

每次回调：
1. **引导中**：`UnitChannelInfo("player")` 存在 → 返回 6603（平砍等待）
2. **否则判断是否可施放**：`HekiliWait - lag - 0.9*CastWindow <= GCD` 时执行推荐：
   - `HekiliActionID > 0` → 直接用该技能 ID
   - `-111 < HekiliActionID < 0` → 返回 -99（药水）
   - `-1000 < HekiliActionID < -111` → 返回 -999（手套/饰品）
   - `HekiliActionID < -1000` 且背包有对应物品 → 返回 -9999（炸弹）
   - 否则 → 0（stopmacro）
3. 在 ActionList 中查找匹配的 ID 返回；未找到则返回原始推荐 ID

**延迟修正**：`lag = GetTime() - LagTimestmap`（每帧更新，补偿网络延迟导致的推荐过期）。

---

## 5. 注册

```lua
aura_env.APLActionList = ActionList
aura_env.APLCallback = APLCallback_HekiliFollower
aura_env.APLName = "Hekili"
```
加载时：若 `C_AddOns.IsAddOnLoaded("Hekili")` 则 `C_Timer.After(0.1, ...)` 延迟 0.1 秒注册（**让 Hekili 晚点注册，免得抢占第一顺位**）。

---

## 6. 修改指引

| 想改什么 | 改哪里 |
|----------|--------|
| 药水/饰品/炸弹宏内容 | §2 特殊插入表中 -99/-999/-9999 的宏字符串 |
| 延迟补偿强度 | §4 中 `0.9*CastWindow` 系数 |
| 支持更多版本 | 版本守卫 + 扫描分支 |
| 鼠标指向 AOE 名单 | `CursorAOESpells` 表 |
