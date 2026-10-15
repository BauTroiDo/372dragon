local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eshop_zhigu = class("eshop_zhigu", script_base)
eshop_zhigu.script_id = 701613
eshop_zhigu.g_shoptableindex = 52
eshop_zhigu.g_ShopName = "Mua công thức chế cổ"
function eshop_zhigu:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

function eshop_zhigu:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetMenPai(selfId) == define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI then
        caller:AddNumTextWithTarget(self.script_id, self.g_ShopName, 7, -1)
    end
    return
end

function eshop_zhigu:CheckAccept(selfId)

end

function eshop_zhigu:OnAccept(selfId)

end

function eshop_zhigu:OnAbandon(selfId)

end

function eshop_zhigu:OnContinue(selfId, targetId)

end

function eshop_zhigu:CheckSubmit(selfId)

end

function eshop_zhigu:OnSubmit(selfId, targetId, selectRadioId)

end

function eshop_zhigu:OnKillObject(selfId, objdataId, objId)

end

function eshop_zhigu:OnEnterArea(selfId, zoneId)

end

function eshop_zhigu:OnItemChanged(selfId, itemdataId)

end

return eshop_zhigu
