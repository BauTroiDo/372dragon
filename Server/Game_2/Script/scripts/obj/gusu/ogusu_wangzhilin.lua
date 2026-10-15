local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_wangzhilin = class("ogusu_wangzhilin", script_base)

function ogusu_wangzhilin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là Vương Chi Lâm, dạy được nghề chế tạo. Thiếu hiệp muốn học gì?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogusu_wangzhilin
