local class = require "class"
local define = require "define"
local script_base = require "script_base"
local yipin_04 = class("yipin_04", script_base)
yipin_04.script_id = 200053
yipin_04.g_MissionId = 43
yipin_04.g_PreMissionId = 42
yipin_04.g_Name = "晓蕾"
yipin_04.g_IfMissionElite = 1
yipin_04.g_MissionLevel = 70
yipin_04.g_MissionKind = 49
yipin_04.g_MissionName = "Tửu bãi vấn quân tam ngữ"
yipin_04.g_MissionInfo = "#{Mis_juqing_0043}"
yipin_04.g_MissionTarget = "#{Mis_juqing_Tar_0043}"
yipin_04.g_MissionComplete = "  Ngươi chẳng phải là $N sao? Công chúa của chúng ta cũng thường nhắc đến ngươi đó! Mau mời ngồi, mau mời ngồi."
yipin_04.g_MoneyBonus = 48600
yipin_04.g_exp = 86400
yipin_04.g_RadioItemBonus = 
{ 
{ ["id"] = 10414017, ["num"] = 1 },
{ ["id"] = 10414018, ["num"] = 1 },
{ ["id"] = 10414019, ["num"] = 1 }
}
yipin_04.g_Custom = { { ["id"] = "已找到晓蕾", ["num"] = 1 }
}
function yipin_04:OnDefaultEvent(selfId, targetId)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetName(targetId) == self.g_Name then
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
function yipin_04:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetName(targetId) == self.g_Name then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 2, -1)
        end
    elseif self:CheckAccept(selfId, targetId) > 0 then
        if self:GetName(targetId) == "赫连铁树" then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 1, -1)
        end
    end
end
function yipin_04:CheckAccept(selfId, targetId)
    if not self:IsMissionHaveDone(selfId, self.g_PreMissionId) then
        return 0
    end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return 0
    end
    if self:GetLevel(selfId) < 70 then
        return 0
    end
    return 1
end
function yipin_04:OnAccept(selfId, targetId)
    if self:CheckAccept(selfId, targetId) ~= 1 then
        return 0
    end
    local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if ret <= 0 then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Tửu Bá Vấn Quân Tam Ngữ", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 1)
end
function yipin_04:OnTimer(selfId)
end
function yipin_04:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
end
function yipin_04:OnContinue(selfId, targetId)
end
function yipin_04:CheckSubmit(selfId, selectRadioId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return 0
    end
    if self:GetLevel(selfId) < 70 then
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, 0) ~= 1 then
        return 0
    end
    return 1
end
function yipin_04:OnSubmit(selfId, targetId, selectRadioId)
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    if self:CheckSubmit(selfId, selectRadioId) ~= 1 then
        return
    end
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
    self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Tửu Bá Vấn Quân Tam Ngữ", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:LuaFnSetCopySceneData_Param(8, 1)
    self:LuaFnSetCopySceneData_Param(10, 0)
    self:LuaFnSetCopySceneData_Param(20, selfId)
    self:LuaFnSetCopySceneData_Param(30, 1)
end
function yipin_04:OnKillObject(selfId, objdataId, objId)
end
function yipin_04:OnEnterZone(selfId, zoneId)
end
function yipin_04:OnItemChanged(selfId, itemdataId)
end
return yipin_04