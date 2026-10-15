local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ohuanglong_murongtianlang = class("ohuanglong_murongtianlang", script_base)
function ohuanglong_murongtianlang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Tịch Nhan này lai lịch bất minh, không phải giống loài ta, ắt trong lòng có khác! Ta bảo A Văn để ý hành động của nàng, nhưng A Văn mỗi lần đều nói với ta hành vi của nàng không có gì khác thường... Ta nghĩ ta không nhìn lầm người, ắt hẳn có vấn đề gì khác đã xảy ra.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ohuanglong_murongtianlang
