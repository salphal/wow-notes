# VF_Core4.3 输出逻辑文档

> aura id: VF_Core4.3 | uid: gF7lwQUnDF8 | regionType: icon
> 角色：虚空之花**核心调度器**（事件分发 + 框架初始化）

---

## 1. 文件结构

| 代码块 | 作用 |
|--------|------|
| `trigger 1 自定义触发器` | 监听 `CUSTOM_VOIDFLOWER_EVENT`，转发给 `aura_env.VF_onAPLEvent` |
| `actions.init 自定义代码` | 框架核心逻辑（**代码已混淆/编码**） |
| `actions.init 加载时自定义代码` | 框架加载逻辑（**代码已混淆/编码**） |

---

## 2. 可读部分说明

### trigger 1 自定义触发器（可读）
```lua
function(state, e, ...)
    if ((aura_env.VF_onAPLEvent ~= nil) and (e == "CUSTOM_VOIDFLOWER_EVENT")) then
        return aura_env.VF_onAPLEvent(state)
    end
    return false
end
```
- 监听 WeakAuras 自定义事件 `CUSTOM_VOIDFLOWER_EVENT`
- 事件到达时调用 `aura_env.VF_onAPLEvent(state)` 并返回其结果
- 无事件或无回调时返回 false（不触发显示）

### actions.init / 加载时（混淆）
- 两个代码块均以 `return(function(...)local g={"\109\120\103..."}...end)` 形式呈现
- 内容为**转义序列编码的压缩代码**（`\ddd` 转义 → 二进制 → 解码后可读）
- 从函数签名和结构推断，其职责为：
  - **VF_Common 核心**：`registerAPL`、`getTargetDeadTime`、`getSpellCD`、`getItemCD`、`getBuff`、`getDebuff` 等框架函数的实际实现
  - APL 动作调度、优先级仲裁、事件驱动的技能循环驱动
- **无法直接描述其内部具体逻辑**（代码被作者刻意保护）

---

## 3. 与其它模块的关系

```
VF_Interface（公共接口层，可读）
    ↓ 转发调用
VF_Core4.3（核心实现，混淆）→ 实际执行 registerAPL / 技能查询 / 动作调度
    ↑ 注册
各职业 APL（虎呗特_兽王猎 等，可读）→ 通过 VF_registerAPL 挂载
```

---

## 4. 修改指引

- **此文件代码混淆，不建议直接修改**
- 若需调整框架行为：修改 `VF_Interface.lua`（接口层，仅转发）或各职业 APL（业务逻辑层）
- 若必须修改此文件：需要先解码 `\ddd` 转义字符串（base64），修改后重新编码
- `aura_env.VF_onAPLEvent` 由核心在加载时注入，各 APL 不应覆盖

> ⚠️ 由于核心代码被保护，本文档只能描述其接口角色而非内部实现细节。
