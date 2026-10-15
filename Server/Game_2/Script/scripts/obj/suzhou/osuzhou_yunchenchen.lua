local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_yunchenchen = class("osuzhou_yunchenchen", script_base)
osuzhou_yunchenchen.script_id = 999903

function osuzhou_yunchenchen:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SHRH_20220427_33}")
    self:AddNumText("#{SHRH_20220427_34}", 6, 1)
    self:AddNumText("#{SHRH_20220427_35}", 11, 5)
    self:AddNumText("#{SHRS_230621_6}", 6, 6)
    self:AddNumText("#{SHRS_230621_7}", 11, 7)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_yunchenchen:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_yunchenchen:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 99990301)
        return
    end
    if index == 5 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SHRH_20220427_36}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 6 then
        self:ShowPetSoulRanse(selfId, targetId)
        return
    end
    if index == 7 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SHRS_230621_8}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

function osuzhou_yunchenchen:UnlockExteriorPoss(selfId, id, active)
    if active == 0 then
        self:BeginUICommand()
        self:UICommand_AddInt(id)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 99990302)
    else
        local CostMoney, CostMaterialID, CostMaterialCount = self:GetExteriorPossConfig(id)
        if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < CostMoney then
            self:notify_tips(selfId, "Kim tệ không đủ")
            return
        end
        local item_count = self:LuaFnGetAvailableItemCount(selfId, CostMaterialID)
        if item_count < CostMaterialCount then
            self:notify_tips(selfId, "Không đủ nguyên liệu")
            return
        end
        self:LuaFnCostMoneyWithPriority(selfId, CostMoney)
        self:LuaFnDelAvailableItem(selfId, CostMaterialID, CostMaterialCount)
        self:UnlockPlayerPoss(selfId, id)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    end
end

return osuzhou_yunchenchen
