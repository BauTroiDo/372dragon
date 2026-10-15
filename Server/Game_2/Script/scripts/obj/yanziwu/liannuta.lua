local class = require "class"
local define = require "define"
local script_base = require "script_base"
local liannuta = class("liannuta", script_base)
liannuta.script_id = 402247
liannuta.g_eventList = {}

liannuta.g_Item = 40004430
function liannuta:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    if self:LuaFnGetCopySceneData_Param(8) >= 10 then
        local szName = self:GetName(targetId)
        if szName == "前连弩塔" then
            self:AddText("  Liên Nỏ Tháp, có thể tự động Tấn công tất cả mục tiêu địch xung quanh.")
            local nCount = self:LuaFnGetCopySceneData_Param(9)
            if nCount < 5 then
                local str = "Sửa chữa còn Yêu cầu" .. 5 - nCount .. "Gỗ."
                self:AddNumText(str, 10, 1)
            end
        elseif szName == "后连弩塔" then
            self:AddText( "  Liên Nỏ Tháp, có thể tự động Tấn công tất cả mục tiêu địch xung quanh.")
            local nCount = self:LuaFnGetCopySceneData_Param(10)
            if nCount < 5 then
                local str = "Sửa chữa còn Yêu cầu" .. 5 - nCount .. "Gỗ."
                self:AddNumText(str, 10, 2)
            end
        elseif szName == "治疗塔" then
            self:AddText("  Trị Liệu Tháp, có thể tự động hồi phục tất cả máu của mục tiêu đồng đội xung quanh.")
            local nCount = self:LuaFnGetCopySceneData_Param(11)
            if nCount < 10 then
                local str = "Sửa chữa còn Yêu cầu" .. 10 - nCount .. "Gỗ."
                self:AddNumText(str, 10, 3)
            end
        elseif szName == "守御塔" then
            self:AddText( "  Thủ Ngự Tháp, có thể giảm Tấn công của tất cả mục tiêu địch xung quanh.")
            local nCount = self:LuaFnGetCopySceneData_Param(12)
            if nCount < 5 then
                local str = "Sửa chữa còn Yêu cầu" .. 5 - nCount .. "Gỗ."
                self:AddNumText(str, 10, 4)
            end
        end
    end
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function liannuta:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function liannuta:OnEventRequest(selfId, targetId, arg, index)
    local nNumText = index
    if nNumText == 1 then
        local nCount = self:LuaFnGetCopySceneData_Param(9)
        nCount = 5 - nCount
        local nItemCount = self:LuaFnGetAvailableItemCount(selfId, self.g_Item)
        if nItemCount > nCount then nItemCount = nCount end
        local bDelOk = self:LuaFnDelAvailableItem(selfId, self.g_Item,
                                                  nItemCount)
        if bDelOk then
            self:LuaFnSetCopySceneData_Param(9, 5 - (nCount - nItemCount))
        end
        if self:LuaFnGetCopySceneData_Param(9) >= 5 then end
    elseif nNumText == 2 then
        local nCount = self:LuaFnGetCopySceneData_Param(10)
        nCount = 5 - nCount
        local nItemCount = self:LuaFnGetAvailableItemCount(selfId, self.g_Item)
        if nItemCount > nCount then nItemCount = nCount end
        local bDelOk = self:LuaFnDelAvailableItem(selfId, self.g_Item,
                                                  nItemCount)
        if bDelOk then
            self:LuaFnSetCopySceneData_Param(10, 5 - (nCount - nItemCount))
        end
        if self:LuaFnGetCopySceneData_Param(10) >= 5 then end
    elseif nNumText == 3 then
        local nCount = self:LuaFnGetCopySceneData_Param(11)
        nCount = 10 - nCount
        local nItemCount = self:LuaFnGetAvailableItemCount(selfId, self.g_Item)
        if nItemCount > nCount then nItemCount = nCount end
        local bDelOk = self:LuaFnDelAvailableItem(selfId, self.g_Item,
                                                  nItemCount)
        if bDelOk then
            self:LuaFnSetCopySceneData_Param(11, 10 - (nCount - nItemCount))
        end
        if self:LuaFnGetCopySceneData_Param(11) >= 10 then end
    elseif nNumText == 4 then
        local nCount = self:LuaFnGetCopySceneData_Param(12)
        nCount = 5 - nCount
        local nItemCount = self:LuaFnGetAvailableItemCount(selfId, self.g_Item)
        if nItemCount > nCount then nItemCount = nCount end
        local bDelOk = self:LuaFnDelAvailableItem(selfId, self.g_Item,
                                                  nItemCount)
        if bDelOk then
            self:LuaFnSetCopySceneData_Param(12, 5 - (nCount - nItemCount))
        end
        if self:LuaFnGetCopySceneData_Param(12) >= 5 then end
    end
    if nNumText == 1 or nNumText == 2 or nNumText == 3 or nNumText == 4 then
        self:BeginEvent(self.script_id)
        local szName = self:GetName(targetId)
        if szName == "前连弩塔" then
            self:AddText(
                "  Liên Nỏ Tháp, có thể tự động Tấn công tất cả mục tiêu địch xung quanh.")
        elseif szName == "后连弩塔" then
            self:AddText(
                "  Liên Nỏ Tháp, có thể tự động Tấn công tất cả mục tiêu địch xung quanh.")
        elseif szName == "治疗塔" then
            self:AddText(
                "  Trị Liệu Tháp, có thể tự động hồi phục tất cả máu của mục tiêu đồng đội xung quanh.")
        elseif szName == "守御塔" then
            self:AddText(
                "  Thủ Ngự Tháp, có thể giảm Tấn công của tất cả mục tiêu địch xung quanh.")
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function liannuta:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret =self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
            end
            return
        end
    end
end

function liannuta:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function liannuta:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function liannuta:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function liannuta:OnDie(selfId, killerId) end

return liannuta
