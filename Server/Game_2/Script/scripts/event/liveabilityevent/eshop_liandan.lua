local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eshop_liandan = class("eshop_liandan", script_base)
eshop_liandan.script_id = 701608
eshop_liandan.g_shoptableindex = 54
eshop_liandan.g_ShopName = "Mua công thức Luyện Đan"
function eshop_liandan:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

function eshop_liandan:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetMenPai(selfId) == define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG then
        caller:AddNumTextWithTarget(self.script_id, self.g_ShopName, 7, -1)
    end
    return
end

function eshop_liandan:CheckAccept(selfId)

end

function eshop_liandan:OnAccept(selfId)

end

function eshop_liandan:OnAbandon(selfId)

end

function eshop_liandan:OnContinue(selfId, targetId)

end

function eshop_liandan:CheckSubmit(selfId)

end

function eshop_liandan:OnSubmit(selfId, targetId, selectRadioId)

end

function eshop_liandan:OnKillObject(selfId, objdataId, objId)

end

function eshop_liandan:OnEnterArea(selfId, zoneId)

end

function eshop_liandan:OnItemChanged(selfId, itemdataId)

end

return eshop_liandan
