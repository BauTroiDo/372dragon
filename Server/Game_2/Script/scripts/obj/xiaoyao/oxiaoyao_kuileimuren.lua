local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxiaoyao_kuileimuren = class("oxiaoyao_kuileimuren", script_base)
function oxiaoyao_kuileimuren:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Khôi Lỗi Tiêu Dao F-874 đang tiến hành xử lý động tác dữ liệu:#r 10: Đưa cánh tay phải ra.#r 20: Vung sang trái.#r 30: Vung sang phải.#r Trở về 20, bắt đầu tuần Khuyên...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oxiaoyao_kuileimuren
