local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eshop_xuanbingshu = class("eshop_xuanbingshu", script_base)
eshop_xuanbingshu.script_id = 701612
eshop_xuanbingshu.g_shoptableindex = 58
eshop_xuanbingshu.g_ShopName = "Mua công thức Huyền Băng Thuật"
function eshop_xuanbingshu:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

function eshop_xuanbingshu:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetMenPai(selfId) == define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN then
        caller:AddNumTextWithTarget(self.script_id, self.g_ShopName, 7, -1)
    end
    return
end

function eshop_xuanbingshu:CheckAccept(selfId)

end

function eshop_xuanbingshu:OnAccept(selfId)

end

function eshop_xuanbingshu:OnAbandon(selfId)

end

function eshop_xuanbingshu:OnContinue(selfId, targetId)

end

function eshop_xuanbingshu:CheckSubmit(selfId)

end

function eshop_xuanbingshu:OnSubmit(selfId, targetId, selectRadioId)

end

function eshop_xuanbingshu:OnKillObject(selfId, objdataId, objId)

end

function eshop_xuanbingshu:OnEnterArea(selfId, zoneId)

end

function eshop_xuanbingshu:OnItemChanged(selfId, itemdataId)

end

return eshop_xuanbingshu
