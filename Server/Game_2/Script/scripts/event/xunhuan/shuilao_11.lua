local class = require "class"
local define = require "define"
local script_base = require "script_base"
local shuilao_11 = class("shuilao_11", script_base)
shuilao_11.script_id = 232001
shuilao_11.g_Position_X = 66.5252
shuilao_11.g_Position_Z = 76.7254
shuilao_11.g_SceneID = 4
shuilao_11.g_AccomplishNPC_Name = "呼延庆"
shuilao_11.g_MissionId = 1212
shuilao_11.g_Name = "呼延豹"
shuilao_11.g_MissionKind = 1
shuilao_11.g_MissionLevel = 10000
shuilao_11.g_IfMissionElite = 0
shuilao_11.g_IsMissionOkFail = 0
shuilao_11.g_MissionName = "Giúp bình định phản loạn Thủy Lao"
shuilao_11.g_MissionInfo = "#{event_xunhuan_0005}"
shuilao_11.g_MissionTarget =
    "  Hãy đến thủy trại ở Thái Hồ tìm Hô Diên Khánh#{_INFOAIM67,77,4,Hô Diên Khánh}."
shuilao_11.g_ContinueInfo = "  Thiếu hiệp đã hoàn thành nhiệm vụ Thủy Lao chưa?"
shuilao_11.g_MissionComplete =
    "  Vô cùng cảm tạ sự giúp đỡ của ngài, cuộc bạo động của tù nhân trong Thủy Lao đã được dẹp yên."
shuilao_11.g_ControlScript = 232000
function shuilao_11:OnDefaultEvent(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then return end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_ContinueInfo)
        self:EndEvent()
        local bDone = self:CheckSubmit(selfId)
        self:DispatchMissionDemandInfo(selfId, targetId, self.script_id,self.g_MissionId, bDone)
    elseif self:CheckAccept(selfId) > 0 then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_MissionInfo)
        self:AddText("#{M_MUBIAO}")
        self:AddText(self.g_MissionTarget)
        self:EndEvent()
        self:DispatchMissionInfo(selfId, targetId, self.script_id,self.g_MissionId)
    end
end

function shuilao_11:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:LuaFnGetName(targetId) ~= self.g_Name then return end
    if self:IsHaveMission(selfId, self.g_MissionId) or self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 3, -1)
    end
end

function shuilao_11:CheckAccept(selfId)
    if self:CallScriptFunction(self.g_ControlScript, "CheckAccept", selfId) == 1 then
        return 1
    else
        return 0
    end
end

function shuilao_11:OnAccept(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then return end
    self:CallScriptFunction(self.g_ControlScript, "OnAccept", selfId, targetId, self.script_id)
    if not self:IsHaveMission(selfId, self.g_MissionId) then return end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 6, 1)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionInfo)
    self:AddText("#rNgươi đã tiếp nhận nhiệm vụ: #r  " .. self.g_MissionName)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function shuilao_11:OnAbandon(selfId)
    self:CallScriptFunction(self.g_ControlScript, "OnAbandon", selfId)
end

function shuilao_11:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function shuilao_11:CheckSubmit(selfId)
    return self:CallScriptFunction(self.g_ControlScript, "CheckSubmit", selfId)
end

function shuilao_11:OnSubmit(selfId, targetId, selectRadioId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then return end
    self:CallScriptFunction(self.g_ControlScript, "OnSubmit", selfId, targetId, selectRadioId)
end

function shuilao_11:OnKillObject(selfId, objdataId, objId) end

function shuilao_11:OnEnterArea(selfId, zoneId) end

function shuilao_11:OnItemChanged(selfId, itemdataId) end

return shuilao_11
