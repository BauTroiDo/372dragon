local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_gongyekun = class("ogusu_gongyekun", script_base)

function ogusu_gongyekun:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là Công Dã Khôn, phụ trách truyền tống phụ bản. Thiếu hiệp sẵn sàng chưa?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogusu_gongyekun
