local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyuxi_ayina = class("oyuxi_ayina", script_base)

function oyuxi_ayina:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  A Ma rốt cuộc khi nào mới có thể tha thứ cho A Ba đây? Nếu như A Ma và A Ba có thể như trước kia ở bên nhau thì tốt biết mấy, vậy thì ta có thể Thiên Thiên gặp được Củ cải ca ca rồi, tốt biết bao! Cũng không biết mấy ngày nay Củ cải ca ca đang bận việc gì, đều không tới chơi cùng ta.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oyuxi_ayina
