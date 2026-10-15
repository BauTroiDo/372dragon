local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxingxiu_dizi_1 = class("oxingxiu_dizi_1", script_base)
function oxingxiu_dizi_1:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Muốn ở Tinh Túc Hải bình an ra vào, không có chút gan dạ là không được. Nếu ngươi Yêu cầu giúp đỡ, xin đến gần đại môn tìm Đệ tử Tri khách giúp đỡ.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oxingxiu_dizi_1
