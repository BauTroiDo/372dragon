local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eshop_zhidu = class("eshop_zhidu", script_base)
eshop_zhidu.script_id = 701610
eshop_zhidu.g_shoptableindex = 56
eshop_zhidu.g_ShopName = "Mua công thức Chế Độc"
function eshop_zhidu:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

function eshop_zhidu:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetMenPai(selfId) == define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU then
        caller:AddNumTextWithTarget(self.script_id, self.g_ShopName, 7, -1)
    end
    return
end

function eshop_zhidu:CheckAccept(selfId)

end

function eshop_zhidu:OnAccept(selfId)

end

function eshop_zhidu:OnAbandon(selfId)

end

function eshop_zhidu:OnContinue(selfId, targetId)

end

function eshop_zhidu:CheckSubmit(selfId)

end

function eshop_zhidu:OnSubmit(selfId, targetId, selectRadioId)

end

function eshop_zhidu:OnKillObject(selfId, objdataId, objId)

end

function eshop_zhidu:OnEnterArea(selfId, zoneId)

end

function eshop_zhidu:OnItemChanged(selfId, itemdataId)

end

return eshop_zhidu
