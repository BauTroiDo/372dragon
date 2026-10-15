local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eshop_qimendunjia = class("eshop_qimendunjia", script_base)
eshop_qimendunjia.script_id = 701611
eshop_qimendunjia.g_shoptableindex = 57
eshop_qimendunjia.g_ShopName = "Mua công thức Kỳ Môn Độn Giáp"
function eshop_qimendunjia:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

function eshop_qimendunjia:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetMenPai(selfId) == define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO then
        caller:AddNumTextWithTarget(self.script_id, self.g_ShopName, 7, -1)
    end
    return
end

function eshop_qimendunjia:CheckAccept(selfId)

end

function eshop_qimendunjia:OnAccept(selfId)

end

function eshop_qimendunjia:OnAbandon(selfId)

end

function eshop_qimendunjia:OnContinue(selfId, targetId)

end

function eshop_qimendunjia:CheckSubmit(selfId)

end

function eshop_qimendunjia:OnSubmit(selfId, targetId, selectRadioId)

end

function eshop_qimendunjia:OnKillObject(selfId, objdataId, objId)

end

function eshop_qimendunjia:OnEnterArea(selfId, zoneId)

end

function eshop_qimendunjia:OnItemChanged(selfId, itemdataId)

end

return eshop_qimendunjia
