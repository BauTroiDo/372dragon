local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxihu_xiaofan = class("oxihu_xiaofan", script_base)
oxihu_xiaofan.script_id = 050201
oxihu_xiaofan.g_shoptableindex = 166
function oxihu_xiaofan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Vị đại hiệp này, đến mua một bát chè đậu xanh giải nhiệt đi! Chè đậu xanh ướp lạnh của tiểu điếm ta nổi danh khắp vùng này đó!")
    self:AddNumText("Mua Chè Đậu Xanh", 7, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxihu_xiaofan:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return oxihu_xiaofan
