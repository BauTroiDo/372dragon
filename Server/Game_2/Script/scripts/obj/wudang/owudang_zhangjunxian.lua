local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_zhangjunxian = class("owudang_zhangjunxian", script_base)
owudang_zhangjunxian.script_id = 012007
function owudang_zhangjunxian:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{QXQS_130106_06}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return owudang_zhangjunxian
