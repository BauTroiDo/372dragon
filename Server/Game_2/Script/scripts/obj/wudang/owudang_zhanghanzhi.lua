local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_zhanghanzhi = class("owudang_zhanghanzhi", script_base)
function owudang_zhanghanzhi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Xem bộ dạng của ngươi, hình như có chút không vui. Có muốn cùng ta ra ngoài chơi không?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return owudang_zhanghanzhi
