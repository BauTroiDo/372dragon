local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eshop_niangjiu = class("eshop_niangjiu", script_base)
eshop_niangjiu.script_id = 701606
eshop_niangjiu.g_shoptableindex = 59
eshop_niangjiu.g_ShopName = "Mua công thức nấu rượu"
function eshop_niangjiu:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

function eshop_niangjiu:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetMenPai(selfId) == define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG then
        caller:AddNumTextWithTarget(self.script_id, self.g_ShopName, 7, -1)
    end
    return
end

function eshop_niangjiu:CheckAccept(selfId)

end

function eshop_niangjiu:OnAccept(selfId)

end

function eshop_niangjiu:OnAbandon(selfId)

end

function eshop_niangjiu:OnContinue(selfId, targetId)

end

function eshop_niangjiu:CheckSubmit(selfId)

end

function eshop_niangjiu:OnSubmit(selfId, targetId, selectRadioId)

end

function eshop_niangjiu:OnKillObject(selfId, objdataId, objId)

end

function eshop_niangjiu:OnEnterArea(selfId, zoneId)

end

function eshop_niangjiu:OnItemChanged(selfId, itemdataId)

end

return eshop_niangjiu
