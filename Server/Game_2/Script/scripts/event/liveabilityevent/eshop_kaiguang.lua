local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eshop_kaiguang = class("eshop_kaiguang", script_base)
eshop_kaiguang.script_id = 701605
eshop_kaiguang.g_shoptableindex = 51
eshop_kaiguang.g_ShopName = "Mua công thức Khai Quang"
function eshop_kaiguang:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

function eshop_kaiguang:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetMenPai(selfId) == define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN then
        caller:AddNumTextWithTarget(self.script_id, self.g_ShopName, 7, -1)
    end
    return
end

function eshop_kaiguang:CheckAccept(selfId)

end

function eshop_kaiguang:OnAccept(selfId)

end

function eshop_kaiguang:OnAbandon(selfId)

end

function eshop_kaiguang:OnContinue(selfId, targetId)

end

function eshop_kaiguang:CheckSubmit(selfId)

end

function eshop_kaiguang:OnSubmit(selfId, targetId, selectRadioId)

end

function eshop_kaiguang:OnKillObject(selfId, objdataId, objId)

end

function eshop_kaiguang:OnEnterArea(selfId, zoneId)

end

function eshop_kaiguang:OnItemChanged(selfId, itemdataId)

end

return eshop_kaiguang
