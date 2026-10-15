local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oerhai_jianding = class("oerhai_jianding", script_base)
oerhai_jianding.script_id = 024006
oerhai_jianding.g_shoptableindex = 139
function oerhai_jianding:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Đúng vậy, ta chính là người bán Phù Giám Định, ngươi có muốn không?")
    --self:AddNumText("购买鉴定符", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oerhai_jianding:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        --self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return oerhai_jianding
