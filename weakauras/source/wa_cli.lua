--[[
wa_cli.lua — WeakAuras release 版本扫描/选择共享模块

被 parse_string.lua / build_string.lua 通过 dofile 加载。

API:
  cli.SelectVersion(releaseDir, marker, markerLabel, args) -> version?, status?
    - marker: 版本目录内用于判断可用的文件（相对路径）
    - args:   arg 表（脚本命令行参数）
    - 返回选中版本 {name, dir, hasMarker}；status = "list" 表示已执行 -l 列表
]]

local M = {}

--- 扫描 release 下的版本目录
--- @param releaseDir string
--- @param marker string 存在性检查的相对路径（如 "string.txt"）
--- @return table[] versions {{name, dir, hasMarker}}
local function ScanVersions(releaseDir, marker)
  local versions = {}
  local p = io.popen(string.format('ls -d "%s"/*/ 2>/dev/null', releaseDir))
  if not p then return versions end
  for line in p:lines() do
    local dir = line:gsub("%s+$", "")
    local name = dir:match("([^/\\]+)[/\\]?$")
    if name and name ~= "." and name ~= ".." then
      local f = io.open(dir .. "/" .. marker, "rb")
      local hasMarker = f ~= nil
      if f then f:close() end
      table.insert(versions, { name = name, dir = dir, hasMarker = hasMarker })
    end
  end
  p:close()
  table.sort(versions, function(a, b) return a.name < b.name end)
  return versions
end

--- 列出版本
--- @param versions table[]
--- @param markerLabel string 缺失提示文本
local function ListVersions(versions, markerLabel)
  if #versions == 0 then
    io.write("release 目录下没有版本子目录\n")
    return
  end
  io.write("可用版本:\n")
  for _, v in ipairs(versions) do
    local mark = v.hasMarker and "✓" or ("✗ (无 " .. markerLabel .. ")")
    io.write(string.format("  %-20s %s\n", v.name, mark))
  end
end

--- 选择版本：-l 列表 / 指定版本参数 / 交互输入
--- @param releaseDir string
--- @param marker string
--- @param markerLabel string
--- @param args table 命令行参数（arg）
--- @return table? version, string? status status="list" 时表示已执行 -l 并退出
function M.SelectVersion(releaseDir, marker, markerLabel, args)
  local versions = ScanVersions(releaseDir, marker)

  if args[1] == "-l" or args[1] == "--list" then
    ListVersions(versions, markerLabel)
    return nil, "list"
  end

  if #versions == 0 then
    io.stderr:write("错误: " .. releaseDir .. " 下没有版本子目录\n")
    return nil, "empty"
  end

  local target
  if args[1] then
    for _, v in ipairs(versions) do
      if v.name == args[1] then
        target = v
        break
      end
    end
    if not target then
      io.stderr:write(string.format("错误: 找不到版本 %q\n可用版本:\n", args[1]))
      ListVersions(versions, markerLabel)
      return nil, "notfound"
    end
  else
    io.write("release 目录下的版本:\n")
    for i, v in ipairs(versions) do
      local mark = v.hasMarker and "" or (" [无 " .. markerLabel .. "]")
      io.write(string.format("  [%d] %s%s\n", i, v.name, mark))
    end
    io.write("请选择版本序号 (1-" .. #versions .. "): ")
    io.flush()
    local choice = io.read("*l")
    local idx = tonumber(choice and choice:match("%d+"))
    if not idx or idx < 1 or idx > #versions then
      io.stderr:write("错误: 无效选择\n")
      return nil, "invalid"
    end
    target = versions[idx]
  end

  return target
end

return M
