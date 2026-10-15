local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owuyi_jianding = class("owuyi_jianding", script_base)
owuyi_jianding.script_id = 032006
owuyi_jianding.g_shoptableindex = 140
function owuyi_jianding:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Ta ở đây có một ít cuốn sách có thể giám định Trang bị, ngươi không xem qua sao?")
   -- self:AddNumText("购买鉴定符", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function owuyi_jianding:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        --self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return owuyi_jianding
