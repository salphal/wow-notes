-- strip_shout.lua — 去掉虚空之花中的喊话配置（message_type/message/do_message）
-- 直接修改 raw/transmit.bin，移除所有 aura actions 中的 message 相关字段
local scriptDir = '/Users/alphal/github/wow-notes/WeakAuras/source'
local LibSerialize = dofile(scriptDir .. '/LibSerialize.lua')
local LibDeflate = dofile(scriptDir .. '/LibDeflate.lua')

local outDir = '/Users/alphal/github/wow-notes/WeakAuras/release/1.6.3/output'
local rawPath = outDir .. '/raw/transmit.bin'

local f = io.open(rawPath, 'rb')
local bin = f:read('*a')
f:close()

local ok, transmit = LibSerialize:Deserialize(bin)
if not ok then print('快照损坏'); return end

local removed = 0
local function stripMessages(data)
  if data and data.id and data.actions then
    for an, act in pairs(data.actions) do
      if type(act) == 'table' then
        local changed = false
        for _, key in ipairs({ 'message_type', 'message', 'do_message', 'message_custom' }) do
          if act[key] ~= nil then
            act[key] = nil
            changed = true
          end
        end
        if changed then
          print('清理: ' .. data.id .. '.actions.' .. an)
          removed = removed + 1
        end
      end
    end
  end
  if data.c then
    for _, c in ipairs(data.c) do stripMessages(c) end
  end
end
stripMessages(transmit)

print('共清理 ' .. removed .. ' 个 actions 的消息字段')

-- 重新序列化并回写快照
local serialized = LibSerialize:SerializeEx({ errorOnUnserializableType = false }, transmit)
local wf = io.open(rawPath, 'wb')
wf:write(serialized)
wf:close()
print('快照已更新: ' .. rawPath)

-- 重新生成 output.txt
local encoded = '!WA:2!' .. LibDeflate:EncodeForPrint(LibDeflate:CompressDeflate(serialized, { level = 9 }))
local of = io.open(outDir .. '/../output.txt', 'w')
of:write(encoded)
of:close()
print('output.txt 已重新生成')
