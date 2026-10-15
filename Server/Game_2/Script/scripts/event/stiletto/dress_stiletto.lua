--时装打孔
--普通
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local dress_stiletto = class("dress_stiletto", script_base)
function dress_stiletto:OnDress_Stiletto(selfId, idBagPos)
    -- print("dress_stiletto:OnDress_Stiletto =", selfId, idBagPos)
	local BagItem = self:GetBagItem(selfId, idBagPos)
    if not BagItem then
        self:notify_tips(selfId, "Đục lỗ thời trang thất bại")
        return
	elseif BagItem:get_index() == -1 or BagItem:get_index() // 10000000 ~= 1 then
        self:notify_tips(selfId, "Đục lỗ thời trang thất bại")
        return
    end
	local base_config =  BagItem:get_base_config()
    -- print("base_config.equip_point =", base_config.equip_point)
    if base_config.equip_point ~= define.HUMAN_EQUIP.HEQUIP_FASHION then
        self:notify_tips(selfId, "#{SZPR_091023_34}")
        return
    end
    local cost_money = 3000
    local nMoneySelf = self:GetMoneyJZ(selfId) + self:GetMoney(selfId)
    if nMoneySelf < cost_money then
        self:notify_tips(selfId, "Xin lỗi, kim tiền trên người ngươi không đủ, không thể tiếp tục")
        return
    end
	local itemcount = self:LuaFnGetAvailableItemCount(selfId, 30503134)
	if itemcount < 1 then
        self:notify_tips(selfId, "#{SZPR_091023_36}")
        return
    end
	local del = self:LuaFnDelAvailableItem(selfId, 30503134, 1)
	if not del then
        self:notify_tips(selfId, "#{SZPR_091023_36}")
        return
    end
    -- local cost_materials = { 30503134 }
    -- local cost_materials_count = 1
    -- if self:LuaFnMtl_GetCostNum(selfId, cost_materials) < cost_materials_count then
        -- self:notify_tips(selfId, "#{SZPR_091023_36}")
        -- return
    -- end
    -- if not self:LuaFnMtl_CostMaterial(selfId, cost_materials_count, cost_materials) then
        -- self:notify_tips(selfId, "#{SZPR_091023_36}")
        -- return
    -- end
    del = self:LuaFnCostMoneyWithPriority(selfId, cost_money)
	if not del then
        self:notify_tips(selfId, "Trừ tiền thất bại")
        return
    end
    local ret = self:AddBagItemSlot(selfId, idBagPos)
    if ret == -3 then
        self:notify_tips(selfId, "#{SZPR_091023_34}")
        return
    end
    if ret == -4 then
        self:notify_tips(selfId, "#{SZPR_091023_35}")
        return
    end
    if ret == 1 then
        self:notify_tips(selfId, "#{SZPR_091023_37}")
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
    end
end

return dress_stiletto