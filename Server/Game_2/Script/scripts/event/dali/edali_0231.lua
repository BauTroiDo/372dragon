local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0231 = class("edali_0231", script_base)
edali_0231.script_id = 210231
edali_0231.g_MissionIdPre = 710
edali_0231.g_MissionId = 711
edali_0231.g_Name = "黄眉僧"
edali_0231.g_MissionKind = 13
edali_0231.g_MissionLevel = 9
edali_0231.g_IfMissionElite = 0
edali_0231.g_IsMissionOkFail = 0
edali_0231.g_DemandKill = {{
    ["id"] = 703,
    ["num"] = 5
}}
edali_0231.g_MissionName = "Tiểu Mộc Nhân Hạng"
edali_0231.g_MissionInfo =
    "  Thí chủ, Tiểu Mộc Nhân Hạng này tuy so không được với Mộc Nhân Hạng Thiếu Lâm Tự, nhưng quái vật bên trong cũng dũng mãnh dị thường. Xin thí chủ Tu luyện khi lượng sức mà hành.#r Thí chủ chỉ cần tiêu diệt 5 Mộc Đầu Nhân, là hoàn thành lần Tu luyện này. Một lần chưa đánh xong cũng không sao, thí chủ có thể nhiều lần ra vào Tiểu Mộc Nhân Hạng, cho đến khi hoàn thành."
edali_0231.g_MissionTarget =
    "Tại #GTiểu Mộc Nhân Hạng#W tiêu diệt 5 #RMộc Đầu Nhân#W, sau đó trở về chỗ #RHoàng Mi Tăng#W#{_INFOAIM275,49,2,Hoàng Mi Tăng} .#b#G(Xin dùng chuột trái chọn tọa độ có gạch dưới, để giúp bạn tìm được NPC này)#l"
edali_0231.g_ContinueInfo = "Ngươi đã tiêu diệt đủ 5 Mộc Đầu Nhân rồi chăng?"
edali_0231.g_MissionComplete = "  Tu luyện của thí chủ rất thành công, mới đó mà võ công đã tinh tiến không ít a."
edali_0231.g_SignPost = {
    ["x"] = 275,
    ["z"] = 50,
    ["tip"] = "黄眉僧"
}
edali_0231.g_MoneyBonus = 1400000
edali_0231.g_DemandTrueKill = {{
    ["name"] = "木头人",
    ["num"] = 5
}}
function edali_0231:OnDefaultEvent(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_ContinueInfo)
        self:AddMoneyBonus(self.g_MoneyBonus)
        self:EndEvent()
        local bDone = self:CheckSubmit(selfId)
        self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
    elseif self:CheckAccept(selfId) > 0 then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_MissionInfo)
        self:AddText("#{M_MUBIAO}")
        self:AddText(self.g_MissionTarget)
        self:AddMoneyBonus(self.g_MoneyBonus)
        self:EndEvent()
        self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
    end
end

function edali_0231:OnEnumerate(caller, selfId, targetId, arg, index)
    if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then
        return
    end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, -1)
    elseif self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, -1)
    end
end

function edali_0231:CheckAccept(selfId)
    if self:GetLevel(selfId) >= 9 then
        return 1
    else
        return 0
    end
end

function edali_0231:OnAccept(selfId)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, 0)
    self:Msg2Player(selfId, "#YTiếp Nhận Nhiệm Vụ: Tiểu Mộc Nhân Hạng", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, 2, self.g_SignPost["x"], self.g_SignPost["z"], self.g_SignPost["tip"])
end

function edali_0231:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "DelSignpost", selfId, self.g_SignPost["tip"])
end

function edali_0231:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_0231:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local num = self:GetMissionParam(selfId, misIndex, 1)
    if num == self.g_DemandTrueKill[1]["num"] then
        return 1
    end
    return 0
end

function edali_0231:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId, selectRadioId) == 1 then
        local ret = 1
        if ret > 0 then
            self:AddMoneyJZ(selfId, self.g_MoneyBonus)
            self:LuaFnAddExp(selfId, 1620)
            ret = self:DelMission(selfId, self.g_MissionId)
            if ret then
                self:MissionCom(selfId, self.g_MissionId)
                self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Tiểu Mộc Nhân Hạng", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                self:CallScriptFunction(210232, "OnDefaultEvent", selfId, targetId)
            end
        else
            self:BeginEvent(self.script_id)
            local strText = "Túi đã đầy, không thể hoàn thành nhiệm vụ"
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    end
end

function edali_0231:OnKillObject(selfId, objdataId, objId)
    if self:GetName(objId) == self.g_DemandTrueKill[1]["name"] then
        local num = self:GetNearHumanCount(objId)
        for j = 1, num do
            local humanObjId = self:GetNearHuman(objId, j)
            if self:IsHaveMission(humanObjId, self.g_MissionId) then
                local misIndex = self:GetMissionIndexByID(humanObjId, self.g_MissionId)
                local nNum = self:GetMissionParam(humanObjId, misIndex, 1)
                if nNum < self.g_DemandTrueKill[1]["num"] then
                    if nNum == self.g_DemandTrueKill[1]["num"] - 1 then
                        self:SetMissionByIndex(humanObjId, misIndex, 0, 1)
                    end
                    self:SetMissionByIndex(humanObjId, misIndex, 1, nNum + 1)
                    self:BeginEvent(self.script_id)
                    local strText = string.format("Đã tiêu diệt Mộc Đầu Nhân %d/5", self:GetMissionParam(humanObjId, misIndex, 1))
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchMissionTips(humanObjId)
                end
            end
        end
    end
end

function edali_0231:OnEnterArea(selfId, zoneId)

end

function edali_0231:OnItemChanged(selfId, itemdataId)

end

return edali_0231