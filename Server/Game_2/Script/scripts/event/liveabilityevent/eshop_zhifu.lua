local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eshop_zhifu = class("eshop_zhifu", script_base)
eshop_zhifu.script_id = 701609
eshop_zhifu.g_shoptableindex = 55
eshop_zhifu.g_ShopName = "Mua công thức chế phù"
function eshop_zhifu:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

function eshop_zhifu:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetMenPai(selfId) == define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI then
        caller:AddNumTextWithTarget(self.script_id, self.g_ShopName, 7, -1)
    end
    return
end

function eshop_zhifu:CheckAccept(selfId)

end

function eshop_zhifu:OnAccept(selfId)

end

function eshop_zhifu:OnAbandon(selfId)

end

function eshop_zhifu:OnContinue(selfId, targetId)

end

function eshop_zhifu:CheckSubmit(selfId)

end

function eshop_zhifu:OnSubmit(selfId, targetId, selectRadioId)

end

function eshop_zhifu:OnKillObject(selfId, objdataId, objId)

end

function eshop_zhifu:OnEnterArea(selfId, zoneId)

end

function eshop_zhifu:OnItemChanged(selfId, itemdataId)

end

return eshop_zhifu
