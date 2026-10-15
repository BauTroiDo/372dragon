local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eshop_shenghuoshu = class("eshop_shenghuoshu", script_base)
eshop_shenghuoshu.script_id = 701607
eshop_shenghuoshu.g_shoptableindex = 53
eshop_shenghuoshu.g_ShopName = "Mua công thức Thánh Hỏa Thuật"
function eshop_shenghuoshu:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

function eshop_shenghuoshu:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetMenPai(selfId) == define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO then
        caller:AddNumTextWithTarget(self.script_id, self.g_ShopName, 7, -1)
    end
    return
end

function eshop_shenghuoshu:CheckAccept(selfId)

end

function eshop_shenghuoshu:OnAccept(selfId)

end

function eshop_shenghuoshu:OnAbandon(selfId)

end

function eshop_shenghuoshu:OnContinue(selfId, targetId)

end

function eshop_shenghuoshu:CheckSubmit(selfId)

end

function eshop_shenghuoshu:OnSubmit(selfId, targetId, selectRadioId)

end

function eshop_shenghuoshu:OnKillObject(selfId, objdataId, objId)

end

function eshop_shenghuoshu:OnEnterArea(selfId, zoneId)

end

function eshop_shenghuoshu:OnItemChanged(selfId, itemdataId)

end

return eshop_shenghuoshu
