local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogaibang_liuzhuzhuang = class("ogaibang_liuzhuzhuang", script_base)
function ogaibang_liuzhuzhuang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Toàn Đốc Chủ trong bang vị trí thăng tiến rất nhanh, ta cũng phải hướng hắn học tập!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogaibang_liuzhuzhuang
