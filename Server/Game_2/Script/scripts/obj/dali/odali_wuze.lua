--大理NPC
--武泽
local class = require "class"
local script_base = require "script_base"
local odali_wuze = class("odali_wuze", script_base)
function odali_wuze:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
    self:AddText("   Sư phụ chịu thu ta nhập môn, truyền bí ẩn huyễn hồn, ta phải báo đáp thật tốt.")
    self:AddNumText("Huyễn Hồn kích hoạt",6,1)
    self:AddNumText("Huyễn Hồn Thăng cấp",6,2)
    self:AddNumText("Huyễn Hồn tiến giai",6,3)
    self:AddNumText("Họa Kim Trần hợp thành",6,4)
    self:AddNumText("Về Võ Hồn Huyễn Hồn",11,11)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_wuze:OnEventRequest(selfId, targetId, arg, index)
	if index == 1 then
		self:BeginUICommand()
		    self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId,88880001)
	elseif index == 2 then 
	    self:BeginUICommand()
		    self:UICommand_AddInt(targetId)
            self:UICommand_AddInt(2304600)
        self:EndUICommand()
        self:DispatchUICommand(selfId,88880002)
	elseif index == 3 then
		self:BeginUICommand()
		    self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId,88880003)
	elseif index == 4 then
        self:BeginEvent(self.script_id)
        self:AddText("#{WH_210223_151}")
        self:AddNumText("#{WH_210223_152}", 6, 702)
        self:AddNumText("#{WH_210223_153}", 6, 703)
        self:AddNumText("#{WH_210223_154}", 6, 704)
        self:AddNumText("#{WH_210223_155}", 6, 705)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
	elseif index == 11 then
		self:BeginEvent(self.script_id)
		self:AddText("#{WHXCZL_091026_02}" )
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
    elseif index == 702 then
        self:upgrade_materials(selfId, 1, 2)
    elseif index == 703 then
        self:upgrade_materials(selfId, 10, 2)
    elseif index == 704 then
        self:upgrade_materials(selfId, 1, 3)
    elseif index == 705 then
        self:upgrade_materials(selfId, 10, 3)
    end
end

local UpgradeLevel = {
    [2] = { money = 30000, count = 3, target = 20800015 },
    [3] = { money = 50000, count = 5, target = 20800017 },
}

local cost_materials = { 20800012, 20800013}
function odali_wuze:upgrade_materials(selfId, count, level)
    local config = UpgradeLevel[level]
    local cost_count = count * config.count
	local itemcount1 = self:LuaFnGetAvailableItemCount(selfId, cost_materials[1])
	local itemcount2 = self:LuaFnGetAvailableItemCount(selfId, cost_materials[2])
    -- if self:LuaFnMtl_GetCostNum(selfId, cost_materials) < cost_count then
        -- self:notify_tips(selfId, "绘金尘数量不足")
        -- return
    -- end
    if itemcount1 + itemcount2 < cost_count then
        self:notify_tips(selfId, "Không đủ Hội Kim Trần")
        return
    end
    local cost_money = config.money * count
    local nMoneySelf = self:GetMoneyJZ(selfId) + self:GetMoney(selfId)
    if nMoneySelf < cost_money then
        self:notify_tips(selfId, "Kim tệ không đủ")
        return
    end
	local needitem = {}
	if itemcount1 > 0 then
		table.insert(needitem,cost_materials[1])
	end
	if itemcount2 > 0 then
		table.insert(needitem,cost_materials[2])
	end
	local del = self:LuaFnMtl_CostMaterial(selfId, cost_count, needitem)
	if del then
		del = self:LuaFnCostMoneyWithPriority(selfId, cost_money)
		if del then
			self:TryRecieveItemWithCount(selfId, config.target, count)
			self:notify_tips(selfId,"Hợp thành thành công, xem túi.")
			self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
		else
			self:notify_tips(selfId,"Trừ tiền thất bại.")
		end
	else
		self:notify_tips(selfId,"Trừ nguyên liệu thất bại.")
	end
end

return odali_wuze