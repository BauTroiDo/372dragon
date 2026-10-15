local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxiaoyao_kuileishiren = class("oxiaoyao_kuileishiren", script_base)
function oxiaoyao_kuileishiren:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Khôi Lỗi Tiêu Dao F-16 đã phục hồi từ một lỗi hệ thống nghiêm trọng.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oxiaoyao_kuileishiren
