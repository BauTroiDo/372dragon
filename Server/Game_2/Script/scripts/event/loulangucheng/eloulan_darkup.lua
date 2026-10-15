local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eloulan_darkup = class("eloulan_darkup", script_base)
eloulan_darkup.script_id = 260001
eloulan_darkup.g_ObbpszCost = 2000000
eloulan_darkup.g_Mainitem = {10155003, 10155005}

eloulan_darkup.g_Othertem = {30008069, 30008070}

function eloulan_darkup:AnqiConfirm(selfId, nPos, nMaterial)
    self:BeginUICommand()
    self:UICommand_AddInt(nPos)
    self:UICommand_AddInt(nMaterial)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 260001)
end

function eloulan_darkup:Anqi2Shenzhen(selfId, nPos, nMaterial)
    if self:IsPilferLockFlag(selfId) then
        self:NotifyTip(selfId, "#{OR_PILFER_LOCK_FLAG}")
        return
    end
    local nAnqiItemID = self:LuaFnGetItemTableIndexByIndex(selfId, nPos)
    local nMaterialID = self:LuaFnGetItemTableIndexByIndex(selfId, nMaterial)
    if nAnqiItemID ~= 10155003 and nAnqiItemID ~= 10155005 then
        self:NotifyTip(selfId, "#{AQSJ_090709_23}")
        return
    end
    if nMaterialID ~= 30008069 and nMaterialID ~= 30008070 then
        self:NotifyTip(selfId, "#{AQSJ_090709_24}")
        return
    end
    if self:LuaFnGetAvailableItemCount(selfId, nMaterialID) < 1 then
        self:NotifyTip(selfId, "#{AQSJ_090709_24}")
        return
    end
    local nNewBPSZID = 0
    if nAnqiItemID == 10155003 or nAnqiItemID == 10155005 then
        nNewBPSZID = 10155002
    end
    if nNewBPSZID == 0 then
        self:NotifyTip(selfId, "Lỗi không xác định")
        return
    end
    local HumanMoney = self:LuaFnGetMoney(selfId)
    local HumanMoneyJZ = self:GetMoneyJZ(selfId)
    if HumanMoney + HumanMoneyJZ < self.g_ObbpszCost then
        self:NotifyTip(selfId, "#{AQSJ_090709_11}")
        return
    end
    if not self:LuaFnDelAvailableItem(selfId, nMaterialID, 1)then
        self:NotifyTip(selfId, "Khấu Trừ Vật Phẩm Thất Bại")
        return
    end
    self:LuaFnCostMoneyWithPriority(selfId, self.g_ObbpszCost)
    self:LuaFnDarkUpGrade(selfId, nPos, nNewBPSZID)
    self:NotifyTip(selfId, "#{AQSJ_090709_12}")
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 148, 0)
end

function eloulan_darkup:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return eloulan_darkup
