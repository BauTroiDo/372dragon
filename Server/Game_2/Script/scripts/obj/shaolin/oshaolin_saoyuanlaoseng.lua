local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshaolin_saoyuanlaoseng = class("oshaolin_saoyuanlaoseng", script_base)
function oshaolin_saoyuanlaoseng:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Đại danh của thí chủ trên giang hồ, lão nạp đã nghe từ lâu. Hôm nay gặp mặt, quả nhiên danh bất hư truyền.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshaolin_saoyuanlaoseng
