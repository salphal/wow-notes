--[[
build_string.lua — 根据修改后的 output 目录重新生成 WA 导入字符串

扫描 /Users/alphal/github/wow-notes/WeakAuras/release/ 下的版本目录，
读取某版本 output/ 中用户修改过的职业代码，
结合 output/raw/transmit.bin 原始结构快照，重建导入字符串，
输出到该版本目录下的 output.txt 文件。

用法:
  luajit build_string.lua                 # 交互式选择版本
  luajit build_string.lua 1.6.3           # 直接指定版本
  luajit build_string.lua -l              # 列出所有可用版本

前置条件:
  先运行 parse_string.lua 生成 output/（含 raw/transmit.bin）

依赖:
  source/decode_wa.lua（核心解码/回写/编码，含 LibDeflate / LibSerialize）
  source/wa_cli.lua（版本扫描/选择）
]]

local scriptDir = arg[0]:match("^(.*)[/\\][^/\\]+$") or "."
local releaseDir = scriptDir .. "/release"
local toolDir = scriptDir .. "/source"

local wa = dofile(toolDir .. "/decode_wa.lua")
local cli = dofile(toolDir .. "/wa_cli.lua")

local target, status = cli.SelectVersion(releaseDir, "output/raw/transmit.bin", "output/raw/transmit.bin", arg)
if status == "list" then os.exit(0) end
if not target then os.exit(1) end
if not target.hasMarker then
  io.stderr:write(string.format("错误: %s/output/raw/transmit.bin 不存在，请先运行 parse_string.lua\n", target.name))
  os.exit(1)
end

local outDir = target.dir .. "/output"
local outPath = target.dir .. "/output.txt"

local encoded, err, modifiedCount, addedCount, removedCount = wa.BuildStringFromOutput(outDir)
if not encoded then
  io.stderr:write(string.format("错误: %s\n", err))
  os.exit(1)
end

local f = io.open(outPath, "w")
if not f then
  io.stderr:write(string.format("错误: 无法写入 %s\n", outPath))
  os.exit(1)
end
f:write(encoded)
f:close()

io.write(string.format("已生成 %s (%d 字符)\n", outPath, #encoded))
io.write(string.format("修改: %d 个代码块 | 新增: %d 个 aura | 移除: %d 个 aura\n", modifiedCount, addedCount or 0, removedCount or 0))
os.exit(0)
