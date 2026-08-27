--[[
decode_wa.lua — 解码 WeakAuras 导入字符串，提取虚空之花各职业代码

双模式:
  [模块模式] local wa = dofile("decode_wa.lua")  → 调用 wa.ParseString(str)
  [CLI模式]  luajit decode_wa.lua <导入字符串文件> [输出目录]
            luajit decode_wa.lua - [输出目录]     # 从 stdin 读取

依赖:
  LibDeflate.lua / LibSerialize.lua（从 WeakAuras 源码搬迁，纯 Lua 零依赖）
]]

-- 使用 debug.getinfo 获取本文件真实路径（兼容被 dofile 调用的模块模式）
local selfPath = arg and arg[0] or ""
if debug and debug.getinfo then
  local src = debug.getinfo(1, "S").source
  if src and src:sub(1, 1) == "@" then
    selfPath = src:sub(2)
  end
end
local scriptDir = selfPath:match("^(.*)[/\\][^/\\]+$") or "."
local LibDeflate = dofile(scriptDir .. "/LibDeflate.lua")
local LibSerialize = dofile(scriptDir .. "/LibSerialize.lua")

if not LibDeflate or not LibSerialize then
  io.stderr:write("错误: 无法加载 LibDeflate/LibSerialize，请确认脚本目录下有这两个文件\n")
  os.exit(1)
end

-- ========== 解码 ==========

--- 解码导入字符串为 Lua 表（对应 WeakAuras Transmission.lua 的 StringToTable）
--- @param input string
--- @return table?, string? data, err
local function StringToTable(input)
  input = input:gsub("^%s+", ""):gsub("%s+$", "")

  -- 格式: !WA:N! + EncodeForPrint(CompressDeflate(SerializeEx(table)))
  local encodeVersion, encoded
  local prefix, rest = input:match("^(!WA:%d+!)(.+)$")
  if prefix then
    encodeVersion = tonumber(prefix:match("%d+"))
    encoded = rest
  else
    -- 旧格式（v0/v1）：可选 "!" 前缀
    encoded = input:gsub("^%!", "")
    encodeVersion = 0
  end

  -- 1. DecodeForPrint: 64字符表(6-bit) → 原始字节
  local decoded = LibDeflate:DecodeForPrint(encoded)
  if not decoded then
    return nil, "DecodeForPrint 失败: 字符串包含非法字符（非 a-zA-Z0-9()）"
  end

  -- 2. DecompressDeflate: 解压
  local decompressed
  if encodeVersion > 0 then
    decompressed = LibDeflate:DecompressDeflate(decoded)
  else
    -- v0 老格式理论上用 LibCompress，但结构相同（deflate），尝试解压
    decompressed = LibDeflate:DecompressDeflate(decoded)
  end
  if not decompressed then
    return nil, "DecompressDeflate 失败: 数据损坏或非 WeakAuras 导入字符串"
  end

  -- 3. LibSerialize:Deserialize: 反序列化
  local ok, deserialized = LibSerialize:Deserialize(decompressed)
  if not ok then
    return nil, "Deserialize 失败: " .. tostring(deserialized)
  end

  return deserialized
end

-- ========== 代码提取 ==========

--- 提取单个 aura 的所有自定义代码
--- @param data table aura 数据
--- @return table result {id, regionType, codes: table[]}
local function ExtractAuraCode(data)
  local result = {
    id = data.id or "(无id)",
    uid = data.uid or "",
    regionType = data.regionType or "?",
    parent = data.parent,
    codes = {},
  }

  -- 1. 触发器代码（custom trigger / untrigger）
  if data.triggers then
    for i, td in ipairs(data.triggers) do
      if td and td.trigger and td.trigger.type == "custom" then
        table.insert(result.codes, {
          name = string.format("trigger %d 自定义触发器", i),
          code = td.trigger.custom or "",
          path = { "triggers", i, "trigger", "custom" },
        })
        if td.untrigger and td.untrigger.custom and td.untrigger.custom ~= "" then
          table.insert(result.codes, {
            name = string.format("trigger %d 自定义取消触发", i),
            code = td.untrigger.custom,
            path = { "triggers", i, "untrigger", "custom" },
          })
        end
        if td.trigger.customDuration and td.trigger.customDuration ~= "" then
          table.insert(result.codes, {
            name = string.format("trigger %d 自定义持续时间", i),
            code = td.trigger.customDuration,
            path = { "triggers", i, "trigger", "customDuration" },
          })
        end
        if td.trigger.customName and td.trigger.customName ~= "" then
          table.insert(result.codes, {
            name = string.format("trigger %d 自定义名称", i),
            code = td.trigger.customName,
            path = { "triggers", i, "trigger", "customName" },
          })
        end
        if td.trigger.customIcon and td.trigger.customIcon ~= "" then
          table.insert(result.codes, {
            name = string.format("trigger %d 自定义图标", i),
            code = td.trigger.customIcon,
            path = { "triggers", i, "trigger", "customIcon" },
          })
        end
      end
    end
  end

  -- 2. 动作代码（init/start/finish 的自定义代码 + 自定义消息）
  if data.actions then
    local actionNames = { "init", "start", "finish" }
    for _, an in ipairs(actionNames) do
      local act = data.actions[an]
      if act then
        if act.do_custom and act.custom and act.custom ~= "" then
          table.insert(result.codes, {
            name = string.format("actions.%s 自定义代码", an),
            code = act.custom,
            path = { "actions", an, "custom" },
          })
        end
        if act.do_message and act.message_custom and act.message_custom ~= "" then
          table.insert(result.codes, {
            name = string.format("actions.%s 自定义消息", an),
            code = act.message_custom,
            path = { "actions", an, "message_custom" },
          })
        end
        if an == "init" then
          if act.do_custom_load and act.customOnLoad and act.customOnLoad ~= "" then
            table.insert(result.codes, {
              name = "actions.init 加载时自定义代码",
              code = act.customOnLoad,
              path = { "actions", "init", "customOnLoad" },
            })
          end
          if act.do_custom_unload and act.customOnUnload and act.customOnUnload ~= "" then
            table.insert(result.codes, {
              name = "actions.init 卸载时自定义代码",
              code = act.customOnUnload,
              path = { "actions", "init", "customOnUnload" },
            })
          end
        end
      end
    end
  end

  -- 3. 自定义文本（displayText 中的 %s 引用函数）
  if data.customTexts then
    for name, ct in pairs(data.customTexts) do
      if type(ct) == "table" and ct.formattedText and ct.formattedText ~= "" then
        table.insert(result.codes, {
          name = string.format("自定义文本 %s", name),
          code = ct.formattedText,
          path = { "customTexts", name, "formattedText" },
        })
      end
    end
  end

  return result
end

--- 序列化代码块为 .lua 文件内容
--- @param aura table ExtractAuraCode 的结果
--- @return string
local function FormatLuaFile(aura)
  local lines = {}
  table.insert(lines, "--[[")
  table.insert(lines, string.format("aura id: %s", aura.id))
  table.insert(lines, string.format("aura uid: %s", aura.uid))
  table.insert(lines, string.format("regionType: %s", aura.regionType))
  if aura.parent then
    table.insert(lines, string.format("parent: %s", aura.parent))
  end
  table.insert(lines, "从 WeakAuras 导入字符串解码提取")
  table.insert(lines, "]]")

  if #aura.codes == 0 then
    table.insert(lines, "-- (此 aura 无自定义代码)")
    return table.concat(lines, "\n")
  end

  for i, c in ipairs(aura.codes) do
    table.insert(lines, "")
    table.insert(lines, string.format("-- ===== %s =====", c.name))
    table.insert(lines, c.code)
  end

  return table.concat(lines, "\n")
end

--- 安全文件名（保留中文/字母/数字，仅替换路径分隔符和危险字符）
--- @param name string
--- @return string
local function SafeFileName(name)
  local safe = name:gsub("[/\\]", "_")
  safe = safe:gsub("[\001-\031\127]", "_")
  safe = safe:gsub("^%s+", ""):gsub("%s+$", "")
  if #safe == 0 then
    safe = "unnamed"
  end
  if #safe > 80 then
    safe = safe:sub(1, 80)
  end
  return safe
end

-- ========== 模块 API ==========

--- 解析导入字符串，返回所有 aura 的提取结果
--- @param input string WA 导入字符串
--- @return table? result, string? err
--- result = { transmit = ..., auras = { {aura=..., data=...}, ... }, summaryLines = {...} }
local function ParseString(input)
  local transmit, err = StringToTable(input)
  if not transmit then
    return nil, err
  end
  if type(transmit) ~= "table" then
    return nil, "解码结果不是表"
  end

  local m = transmit.m
  if m ~= "d" then
    -- 非标准消息类型，尝试直接作为 aura 数据处理
  end

  -- 收集所有 aura（主数据 + children）
  local allAuras = {}
  local mainData = transmit.d or transmit
  if mainData and type(mainData) == "table" then
    table.insert(allAuras, mainData)
  end
  if transmit.c then
    for _, child in ipairs(transmit.c) do
      if child and type(child) == "table" then
        table.insert(allAuras, child)
      end
    end
  end

  local result = {
    transmit = transmit,
    auras = {},
    summaryLines = {},
  }

  for i, data in ipairs(allAuras) do
    local aura = ExtractAuraCode(data)
    table.insert(result.auras, { aura = aura, data = data })
    table.insert(result.summaryLines, string.format("[%d] %s (%s) — %d 个代码块",
      i, aura.id, aura.regionType, #aura.codes))
    for _, c in ipairs(aura.codes) do
      table.insert(result.summaryLines, string.format("      - %s", c.name))
    end
  end

  return result
end
--- 将解析结果写入输出目录
--- @param result table ParseString 的返回值
--- @param outDir string 输出目录
--- @return number writtenFiles 写入的文件数
local function WriteResult(result, outDir)
  os.execute(string.format("mkdir -p %q", outDir))

  -- 保存原始 transmit 快照（二进制，无损），供反向生成字符串使用
  os.execute(string.format("mkdir -p %q", outDir .. "/raw"))
  local rawPath = outDir .. "/raw/transmit.bin"
  local rf = io.open(rawPath, "wb")
  if rf then
    rf:write(LibSerialize:SerializeEx({ errorOnUnserializableType = false }, result.transmit))
    rf:close()
  end

  local summary = {}
  table.insert(summary, string.format("解码成功: 共 %d 个 aura", #result.auras))
  table.insert(summary, string.format("传输版本: %s, WA 版本: %s",
    tostring(result.transmit.v), tostring(result.transmit.s)))
  table.insert(summary, "")

  for _, line in ipairs(result.summaryLines) do
    table.insert(summary, line)
  end

  local writtenFiles = 0
  for _, entry in ipairs(result.auras) do
    local aura = entry.aura
    local filePath = outDir .. "/" .. SafeFileName(aura.id) .. ".lua"
    local f = io.open(filePath, "w")
    if f then
      f:write(FormatLuaFile(aura))
      f:close()
      writtenFiles = writtenFiles + 1
    end
  end

  local summaryPath = outDir .. "/summary.txt"
  local sf = io.open(summaryPath, "w")
  if sf then
    sf:write(table.concat(summary, "\n"))
    sf:close()
  end

  return writtenFiles
end

-- ========== 反向生成 ==========

--- 遍历表中所有 aura 数据（主 + children），对每个调用 fn(data)
--- @param transmit table
--- @param fn fun(data: table)
local function TraverseAuras(transmit, fn)
  local mainData = transmit.d or transmit
  if mainData and type(mainData) == "table" then
    fn(mainData)
  end
  if transmit.c then
    for _, child in ipairs(transmit.c) do
      if child and type(child) == "table" then
        fn(child)
      end
    end
  end
end

--- 按 path 写入 data 中的值
--- @param data table
--- @param path table
--- @param value any
local function SetValueByPath(data, path, value)
  local cur = data
  for i = 1, #path - 1 do
    if type(cur[path[i]]) ~= "table" then
      cur[path[i]] = {}
    end
    cur = cur[path[i]]
  end
  cur[path[#path]] = value
end

--- 解析修改后的代码文件，按 "===== name =====" 分割成 {name = code}
--- @param content string
--- @return table blocks
local function ParseCodeFile(content)
  local blocks = {}
  local currentName, currentLines
  for line in content:gmatch("[^\r\n]+") do
    local name = line:match("^%-%- ===== (.+) =====")
    if name then
      if currentName then
        blocks[currentName] = table.concat(currentLines, "\n")
      end
      currentName = name
      currentLines = {}
    elseif currentName then
      table.insert(currentLines, line)
    end
  end
  if currentName then
    blocks[currentName] = table.concat(currentLines, "\n")
  end
  return blocks
end

--- 从 output 目录重建 WA 导入字符串
--- 以 output/ 目录中的 .lua 文件为准：新增文件自动加入、删除文件自动移除、修改文件回写
--- @param outDir string 解析输出目录（含 raw/transmit.bin 和各职业 .lua）
--- @return string? importString, string? err
local function BuildStringFromOutput(outDir)
  -- 1. 读回原始 transmit
  local rawPath = outDir .. "/raw/transmit.bin"
  local rf = io.open(rawPath, "rb")
  if not rf then
    return nil, "找不到 " .. rawPath .. "，请先运行解析生成 output 目录"
  end
  local bin = rf:read("*a")
  rf:close()

  local ok, transmit = LibSerialize:Deserialize(bin)
  if not ok or type(transmit) ~= "table" then
    return nil, "raw/transmit.bin 损坏，请重新解析"
  end

  -- 2. 收集现有 aura 映射（id → data）与 children 容器
  local auraMap = {}
  local mainData = transmit.d or transmit
  local children = transmit.c or {}
  if mainData and type(mainData) == "table" and mainData.id then
    auraMap[mainData.id] = mainData
  end
  for _, child in ipairs(children) do
    if child and type(child) == "table" and child.id then
      auraMap[child.id] = child
    end
  end

  -- 3. 模板：找第一个 regionType=empty 的现有 aura（新增文件克隆它获得完整默认结构）
  local template
  for _, child in ipairs(children) do
    if child and child.regionType == "empty" then
      template = child
      break
    end
  end
  if not template and mainData and mainData.regionType == "empty" then
    template = mainData
  end

  -- 生成 11 位 base64 uid（与 WeakAuras.GenerateUniqueID 一致）
  local b64chars = {}
  for i = 1, 64 do b64chars[i] = string.char(0) end
  for i = 1, 26 do b64chars[i] = string.char(96 + i) end      -- a-z
  for i = 27, 52 do b64chars[i] = string.char(38 + i) end     -- A-Z
  for i = 53, 62 do b64chars[i] = string.char(47 + i) end     -- 0-9
  b64chars[63] = "("
  b64chars[64] = ")"
  local function GenerateUID()
    local s = {}
    for i = 1, 11 do
      s[i] = b64chars[math.random(1, 64)]
    end
    return table.concat(s)
  end

  -- 深拷贝（新增 aura 从模板克隆）
  local function DeepCopy(v, seen)
    if type(v) ~= "table" then return v end
    seen = seen or {}
    if seen[v] then return seen[v] end
    local out = {}
    seen[v] = out
    for k, val in pairs(v) do
      out[k] = DeepCopy(val, seen)
    end
    return out
  end

  -- 从代码块构建/更新 data 的字段（反向映射：块名 → data 结构）
  local function ApplyBlocksToData(data, blocks)
    for name, code in pairs(blocks) do
      if code == "" then code = nil end
      local n = tonumber(name:match("^trigger (%d+) 自定义触发器$"))
      if n then
        data.triggers = data.triggers or {}
        data.triggers[n] = data.triggers[n] or {}
        data.triggers[n].trigger = data.triggers[n].trigger or {}
        data.triggers[n].trigger.type = "custom"
        data.triggers[n].trigger.custom_type = data.triggers[n].trigger.custom_type or "stateupdate"
        data.triggers[n].trigger.custom = code
      elseif name:match("^trigger %d+ 自定义取消触发$") then
        local tn = tonumber(name:match("^trigger (%d+) 自定义取消触发$"))
        data.triggers = data.triggers or {}
        data.triggers[tn] = data.triggers[tn] or {}
        data.triggers[tn].untrigger = data.triggers[tn].untrigger or {}
        data.triggers[tn].untrigger.custom = code
      elseif name:match("^trigger %d+ 自定义持续时间$") then
        local tn = tonumber(name:match("^trigger (%d+) 自定义持续时间$"))
        data.triggers = data.triggers or {}
        data.triggers[tn] = data.triggers[tn] or {}
        data.triggers[tn].trigger = data.triggers[tn].trigger or {}
        data.triggers[tn].trigger.customDuration = code
      elseif name:match("^trigger %d+ 自定义名称$") then
        local tn = tonumber(name:match("^trigger (%d+) 自定义名称$"))
        data.triggers = data.triggers or {}
        data.triggers[tn] = data.triggers[tn] or {}
        data.triggers[tn].trigger = data.triggers[tn].trigger or {}
        data.triggers[tn].trigger.customName = code
      elseif name:match("^trigger %d+ 自定义图标$") then
        local tn = tonumber(name:match("^trigger (%d+) 自定义图标$"))
        data.triggers = data.triggers or {}
        data.triggers[tn] = data.triggers[tn] or {}
        data.triggers[tn].trigger = data.triggers[tn].trigger or {}
        data.triggers[tn].trigger.customIcon = code
      elseif name:match("^actions%.(init|start|finish) 自定义代码$") then
        local an = name:match("^actions%.(init|start|finish) 自定义代码$")
        data.actions = data.actions or {}
        data.actions[an] = data.actions[an] or {}
        data.actions[an].do_custom = true
        data.actions[an].custom = code
      elseif name:match("^actions%.(init|start|finish) 自定义消息$") then
        local an = name:match("^actions%.(init|start|finish) 自定义消息$")
        data.actions = data.actions or {}
        data.actions[an] = data.actions[an] or {}
        data.actions[an].do_message = true
        data.actions[an].message_custom = code
      elseif name == "actions.init 加载时自定义代码" then
        data.actions = data.actions or {}
        data.actions.init = data.actions.init or {}
        data.actions.init.do_custom_load = true
        data.actions.init.customOnLoad = code
      elseif name == "actions.init 卸载时自定义代码" then
        data.actions = data.actions or {}
        data.actions.init = data.actions.init or {}
        data.actions.init.do_custom_unload = true
        data.actions.init.customOnUnload = code
      elseif name:match("^自定义文本 (.+)$") then
        local tn = name:match("^自定义文本 (.+)$")
        data.customTexts = data.customTexts or {}
        data.customTexts[tn] = data.customTexts[tn] or {}
        data.customTexts[tn].formattedText = code
      end
    end
  end

  -- 4. 以 output/ 文件为准遍历：修改回写 + 新增加入
  local modifiedCount = 0
  local addedCount = 0
  local removedCount = 0
  local seenIds = {}
  local p = io.popen(string.format('ls "%s"/*.lua 2>/dev/null', outDir))
  if p then
    for line in p:lines() do
      local filePath = line:gsub("%s+$", "")
      local fileName = filePath:match("([^/\\]+)%.lua$")
      if fileName then
        local f = io.open(filePath, "rb")
        if not f then return nil, "无法读取 " .. filePath end
        local content = f:read("*a")
        f:close()

        local blocks = ParseCodeFile(content)
        local data = auraMap[fileName]
        if data then
          -- 已有 aura：回写修改
          local aura = ExtractAuraCode(data)
          for _, code in ipairs(aura.codes) do
            local newCode = blocks[code.name]
            if newCode ~= nil and newCode ~= code.code then
              SetValueByPath(data, code.path, newCode)
              modifiedCount = modifiedCount + 1
            end
          end
          seenIds[fileName] = true
        else
          -- 新增 aura：克隆模板 + 按块构建
          local newData = template and DeepCopy(template) or {}
          newData.id = fileName
          newData.uid = GenerateUID()
          if mainData and mainData.id then
            newData.parent = mainData.id
          end
          ApplyBlocksToData(newData, blocks)
          table.insert(children, newData)
          auraMap[fileName] = newData
          addedCount = addedCount + 1
          seenIds[fileName] = true
        end
      end
    end
    p:close()
  end

  -- 5. 删除：现有 aura 在 output/ 中无对应文件 → 从 children 移除
  local keptChildren = {}
  for _, child in ipairs(children) do
    if child and child.id and seenIds[child.id] then
      table.insert(keptChildren, child)
    elseif not (child and child.id) then
      table.insert(keptChildren, child)
    else
      removedCount = removedCount + 1
    end
  end
  if transmit.c then
    transmit.c = keptChildren
  end

  -- 6. 编码回导入字符串
  -- 无任何变化时直接复用快照原始字节（避免 LibSerialize 哈希表遍历顺序导致字节流抖动）
  if modifiedCount == 0 and addedCount == 0 and removedCount == 0 then
    local c0 = LibDeflate:CompressDeflate(bin, { level = 9 })
    local encoded0 = "!WA:2!" .. LibDeflate:EncodeForPrint(c0)
    return encoded0, nil, 0, 0, 0
  end
  local serialized = LibSerialize:SerializeEx({ errorOnUnserializableType = false }, transmit)
  local compressed = LibDeflate:CompressDeflate(serialized, { level = 9 })
  local encoded = "!WA:2!" .. LibDeflate:EncodeForPrint(compressed)

  -- 7. 回写快照：固化新增 aura 的 uid 与结构（下次 build 不再视为新增）
  local wf = io.open(rawPath, "wb")
  if wf then
    wf:write(serialized)
    wf:close()
  end

  return encoded, nil, modifiedCount, addedCount, removedCount
end

local M = {
  StringToTable = StringToTable,
  ExtractAuraCode = ExtractAuraCode,
  FormatLuaFile = FormatLuaFile,
  SafeFileName = SafeFileName,
  ParseString = ParseString,
  WriteResult = WriteResult,
  BuildStringFromOutput = BuildStringFromOutput,
  TraverseAuras = TraverseAuras,
}

-- ========== CLI 模式（仅当直接运行本文件时） ==========

if arg and arg[0] and debug and debug.getinfo then
  local info = debug.getinfo(1, "S")
  local source = info.source or ""
  if source:sub(1, 1) == "@" then
    source = source:sub(2)
  end
  local isMain = (source == arg[0]) or (info.short_src == arg[0])
  if isMain then
  local inputFile = arg[1]
  local outDir = arg[2] or (scriptDir .. "/../output")

  if not inputFile then
    io.stderr:write([[
用法: lua decode_wa.lua <导入字符串文件> [输出目录]
      lua decode_wa.lua - [输出目录]    # 从 stdin 读取

示例: lua decode_wa.lua import.txt ./output
]])
    os.exit(1)
  end

  -- 读取输入
  local input
  if inputFile == "-" then
    input = io.read("*a")
  else
    local f = io.open(inputFile, "rb")
    if not f then
      io.stderr:write(string.format("错误: 无法打开文件 %s\n", inputFile))
      os.exit(1)
    end
    input = f:read("*a")
    f:close()
  end

  -- 解码
  local result, err = ParseString(input)
  if not result then
    io.stderr:write("错误: " .. err .. "\n")
    os.exit(1)
  end

  -- 写入
  local writtenFiles = WriteResult(result, outDir)

  -- 打印结果
  io.write(table.concat(result.summaryLines, "\n"))
  io.write(string.format("\n\n完成: %d 个文件写入 %s\n", writtenFiles, outDir))
  os.exit(0)
  end -- if isMain
end -- if CLI

return M
