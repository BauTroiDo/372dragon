local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_wangxihao = class("ogusu_wangxihao", script_base)

function ogusu_wangxihao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là Vương Tịch Hạo, truyền dạy kỹ năng đời sống. Thiếu hiệp muốn học gì?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogusu_wangxihao
