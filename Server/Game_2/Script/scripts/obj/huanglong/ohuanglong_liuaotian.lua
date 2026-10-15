local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ohuanglong_liuaotian = class("ohuanglong_liuaotian", script_base)
function ohuanglong_liuaotian:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Chào bằng hữu, anh hùng Trung Nguyên! Ta tên là Lưu Ngạo Thiên. Ta là hậu duệ Hung Nô, vốn mang họ Loan Đề, ngươi cũng có thể gọi ta là Loan Đề Ngạo Thiên.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ohuanglong_liuaotian
