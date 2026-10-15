local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omiaojiang_hongtian = class("omiaojiang_hongtian", script_base)
omiaojiang_hongtian.script_id = 029006
omiaojiang_hongtian.g_shoptableindex = 109
function omiaojiang_hongtian:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Xem hàng thì được, đừng hòng dò hỏi nguồn gốc Bảo thạch của ta, mấy huynh đệ ta chỉ có con đường sống này thôi.")
    self:AddNumText("Xem ngươi có hàng tốt gì nào.", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function omiaojiang_hongtian:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if (self:GetLevel(selfId) < 30) then
            self:BeginEvent(self.script_id)
            self:AddText("#{BSSR_20080131_01}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return omiaojiang_hongtian
