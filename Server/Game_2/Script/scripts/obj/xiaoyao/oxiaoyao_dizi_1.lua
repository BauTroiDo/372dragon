local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxiaoyao_dizi_1 = class("oxiaoyao_dizi_1", script_base)
function oxiaoyao_dizi_1:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Cẩn thận, Lăng Ba động trung chỗ chỗ là cơ quan, chớ nên đi vào cấm địa. Nếu như ngươi Yêu cầu trợ giúp, xin đến gần động môn tìm Đệ tử Tri khách giúp đỡ.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oxiaoyao_dizi_1
