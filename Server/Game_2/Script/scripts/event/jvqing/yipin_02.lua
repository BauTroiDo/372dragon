local class = require "class"
local define = require "define"
local script_base = require "script_base"
local yipin_02 = class("yipin_02", script_base)
yipin_02.script_id = 200051
yipin_02.g_MissionId = 41
yipin_02.g_PreMissionId = 40
yipin_02.g_Name = "虚竹"
yipin_02.g_IfMissionElite = 1
yipin_02.g_MissionLevel = 70
yipin_02.g_MissionKind = 49
yipin_02.g_MissionName = "一笑人间万事"
yipin_02.g_MissionInfo = "#{Mis_juqing_0041}"
yipin_02.g_MissionTarget = "#{Mis_juqing_Tar_0041}"
yipin_02.g_MissionComplete = "  Chúng ta vẫn là mau chóng rời khỏi nơi này thôi, A di đà Phật, tội quá tội quá..."
yipin_02.g_MoneyBonus = 9000
yipin_02.g_exp = 17280
yipin_02.g_RadioItemBonus = { 
  { ["id"] = 10415013, ["num"] = 1 }, 
  { ["id"] = 10415014, ["num"] = 1 }, 
  { ["id"] = 10415015, ["num"] = 1 }
}
yipin_02.g_Custom = { { ["id"] = "一笑人间万事", ["num"] = 1 }
}
function yipin_02:OnDefaultEvent(selfId, targetId)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        local sceneType = self:LuaFnGetSceneType()
        if sceneType == 1 then
            if self:GetName(targetId) == self.g_Name then
                self:BeginEvent(self.script_id)
                self:AddText(self.g_MissionName)
                self:AddText(self.g_MissionComplete)
                self:AddMoneyBonus(self.g_MoneyBonus)
                self:EndEvent()
                local bDone = self:CheckSubmit(selfId)
                self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
            end
        end
    elseif self:CheckAccept(selfId, targetId) > 0 then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_MissionInfo)
        self:AddText("#{M_MUBIAO}#r")
        self:AddText(self.g_MissionTarget)
        self:AddText("#{M_SHOUHUO}#r")
        self:AddMoneyBonus(self.g_MoneyBonus)
        for i, item in pairs(self.g_RadioItemBonus) do
            self:AddRadioItemBonus(item["id"], item["num"])
        end
        self:EndEvent()
        self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
    end
end
function yipin_02:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetName(targetId) == self.g_Name then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 2, -1)
        end
    elseif self:CheckAccept(selfId, targetId) > 0 then
        caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 1, -1)
    end
end
function yipin_02:CheckAccept(selfId, targetId)
    if not self:IsMissionHaveDone(selfId, self.g_PreMissionId) then
        return 0
    end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return 0
    end
    if self:GetLevel(selfId) < 70 then
        return 0
    end
    if self:GetName(targetId) ~= "天山童姥" then
        return 0
    end
    return 1
end
function yipin_02:OnAccept(selfId, targetId)
    if self:CheckAccept(selfId, targetId) ~= 1 then
        return 0
    end
    local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if ret <= 0 then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Nhất Tiếu Nhân Gian Vạn Sự", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:LuaFnSetCopySceneData_Param(8, 1)
    self:LuaFnSetCopySceneData_Param(10, 0)
    self:LuaFnSetCopySceneData_Param(20, selfId)
end
function yipin_02:OnTimer(selfId)
    if 1 == 1 then
        return
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local bDone = self:GetMissionParam(selfId, misIndex, 0)
    local NowTime = self:LuaFnGetCurrentTime()
    local OldTime = self:GetMissionParam(selfId, misIndex, 1)
    local nSceneId = self:GetMissionParam(selfId, misIndex, 3)
    if nSceneId ~= self.scene:get_id() then
        self:StopMissionTimer(selfId, self.g_MissionId)
        return
    end
    if bDone == 1 then
        self:StopMissionTimer(selfId, self.g_MissionId)
        return
    end
    if NowTime - OldTime > 10 then
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
        self:BeginEvent(self.script_id)
        self:AddText("Nhiệm vụ hoàn thành 1/1")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
end
function yipin_02:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
end
function yipin_02:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    for i, item in pairs(self.g_RadioItemBonus) do
        self:AddRadioItemBonus(item["id"], item["num"])
    end
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function yipin_02:CheckSubmit(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return 0
    end
    if self:GetLevel(selfId) < 70 then
        return 0
    end
    local bDone = self:LuaFnGetCopySceneData_Param(15)
    if bDone ~= 1 then
        return 0
    end
    return 1
end
function yipin_02:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:BeginAddItem()
        for i, item in pairs(self.g_RadioItemBonus) do
            if item["id"] == selectRadioId then
                self:AddItem(item["id"], item["num"])
            end
        end
        local ret = self:EndAddItem(selfId)
        if not ret then
            self:BeginEvent(self.script_id)
            local strText = "Túi đã đầy, không thể hoàn thành nhiệm vụ"
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        self:MissionCom(selfId, self.g_MissionId)
        if not self:DelMission(selfId, self.g_MissionId) then
            return
        end
        self:AddItemListToHuman(selfId)
        self:AddMoney(selfId, self.g_MoneyBonus)
        self:LuaFnAddExp(selfId, self.g_exp)
        self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Nhất Tiếu Nhân Gian Vạn Sự", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction((200052), "OnDefaultEvent", selfId, targetId)
    end
end
function yipin_02:OnKillObject(selfId, objdataId, objId)
end
function yipin_02:OnEnterZone(selfId, zoneId)
end
function yipin_02:OnItemChanged(selfId, itemdataId)
end
return yipin_02