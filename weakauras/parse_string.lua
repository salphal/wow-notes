--[[
parse_string.lua — 解析 WA 导入字符串为各职业代码

扫描 /Users/alphal/github/wow-notes/WeakAuras/release/ 下的版本目录，
选择某个版本后读取其中的 string.txt（WA 导入字符串），
解析出各职业代码，输出到该版本目录下的 output/。

用法:
  luajit parse_string.lua                 # 交互式选择版本
  luajit parse_string.lua 1.6.3           # 直接指定版本
  luajit parse_string.lua -l              # 列出所有可用版本

依赖:
  source/decode_wa.lua（核心解码/提取，含 LibDeflate / LibSerialize）
  source/wa_cli.lua（版本扫描/选择）
]]

local scriptDir = arg[0]:match("^(.*)[/\\][^/\\]+$") or "."
local releaseDir = scriptDir .. "/release"
local toolDir = scriptDir .. "/source"

local wa = dofile(toolDir .. "/decode_wa.lua")
local cli = dofile(toolDir .. "/wa_cli.lua")

local target, status = cli.SelectVersion(releaseDir, "string.txt", "string.txt", arg)
if status == "list" then os.exit(0) end
if not target then os.exit(1) end
if not target.hasMarker then
  io.stderr:write(string.format("警告: %s 目录下没有 string.txt，跳过\n", target.name))
  os.exit(1)
end

local stringPath = target.dir .. "/string.txt"
local f = io.open(stringPath, "rb")
if not f then
  io.stderr:write(string.format("错误: %s 中没有 string.txt\n", target.name))
  os.exit(1)
end
local input = f:read("*a")
f:close()

if #input == 0 then
  io.stderr:write(string.format("错误: %s/string.txt 是空文件\n", target.name))
  os.exit(1)
end

io.write(string.format("正在解析 %s (%d 字符)...\n", target.name, #input))

local result, err = wa.ParseString(input)
if not result then
  io.stderr:write(string.format("错误: 解析失败: %s\n", err))
  os.exit(1)
end

local outDir = target.dir .. "/output"
local writtenFiles = wa.WriteResult(result, outDir)

io.write(string.format("\n[%s] 共 %d 个 aura, %d 个代码文件已写入 %s\n",
  target.name, #result.auras, writtenFiles, outDir))
io.write("----------------------------------------\n")
for _, line in ipairs(result.summaryLines) do
  io.write(line .. "\n")
end
io.write("----------------------------------------\n")
os.exit(0)
