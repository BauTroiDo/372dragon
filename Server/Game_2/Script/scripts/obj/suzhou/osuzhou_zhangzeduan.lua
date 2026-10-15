local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_zhangzeduan = class("osuzhou_zhangzeduan", script_base)
function osuzhou_zhangzeduan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Vài ngày nữa là tiết Thanh Minh rồi, đến lúc đó bến tàu Tô Châu chắc chắn sẽ náo nhiệt vô so. Nếu có thể đem mỹ cảnh Tô Châu vào trong tranh, thật tốt biết bao!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_zhangzeduan
