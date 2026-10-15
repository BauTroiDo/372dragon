local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxiaoyao_kuileitongren = class("oxiaoyao_kuileitongren", script_base)
function oxiaoyao_kuileitongren:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Tiêu Dao Khôi Lỗi Nhân F-17173 hiện tại hoạt động bình thường... tốt... ưu tú... kiệt xuất... hoàn mỹ... ồ yeah...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oxiaoyao_kuileitongren
