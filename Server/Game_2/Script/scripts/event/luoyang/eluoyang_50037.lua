local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eluoyang_50037 = class("eluoyang_50037", script_base)
eluoyang_50037.script_id = 250037
eluoyang_50037.g_MissionId = 1021
eluoyang_50037.g_TargetNpcName = "喜来乐"
eluoyang_50037.g_MissionKind = 3
eluoyang_50037.g_MissionLevel = 1
eluoyang_50037.g_IfMissionElite = 0
eluoyang_50037.g_MissionLimitTime = 60 * 60 * 1000
eluoyang_50037.g_MissionName = "Bái Thiên Địa"
eluoyang_50037.g_MissionInfo =
    "Xin hãy tìm Hỷ Lai Lạc ở Lạc Dương [177,94] để an bài Bái Thiên Địa."
eluoyang_50037.g_MissionTarget =
    "    Tìm Hỷ Lai Lạc ở Lạc Dương #{_INFOAIM177,94,0,Hỷ Lai Lạc} an bài bái thiên địa."
eluoyang_50037.g_ContinueInfo1 =
    "Các vị đến thật sự quá muộn rồi, giờ lành đã qua, ta cũng hết cách."
eluoyang_50037.g_ContinueInfo2 = "Chỗ này cần người lên kế hoạch, đa tạ."
eluoyang_50037.g_MissionComplete = "Vậy hãy bắt đầu thôi."
eluoyang_50037.g_MoneyBonus = 0
eluoyang_50037.g_eventId_begin = 0
eluoyang_50037.g_eventId_start = 1
eluoyang_50037.g_eventId_close = 2
function eluoyang_50037:OnDefaultEvent(selfId, targetId, index)
    local selectEventId = index
    if self.g_eventId_begin == selectEventId then
        self:OnBegin(selfId, targetId)
    elseif self.g_eventId_start == selectEventId then
        self:OnStart(selfId, targetId)
    elseif self.g_eventId_close == selectEventId then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
end

function eluoyang_50037:OnEnumerate(caller, selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 3, self.g_eventId_begin)
    end
end

function eluoyang_50037:CheckAccept(selfId) return 1 end

function eluoyang_50037:OnAccept(selfId, marryLevel)
    self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if misIndex and misIndex >= 0 then
        self:StartMissionTimer(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
        self:SetMissionByIndex(selfId, misIndex, 7, self.g_MissionLimitTime)
        self:SetMissionByIndex(selfId, misIndex, 2, marryLevel)
        self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ:" .. self.g_MissionName .. "", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
end

function eluoyang_50037:OnAbandon(selfId)
    local checkMission = self:IsHaveMission(selfId, self.g_MissionId)
    if checkMission then
        self:DelMission(selfId, self.g_MissionId)
    end
end

function eluoyang_50037:OnContinue(selfId, targetId) end

function eluoyang_50037:CheckSubmit(selfId) return 0 end

function eluoyang_50037:OnSubmit(selfId, targetId, selectRadioId) end

function eluoyang_50037:OnKillObject(selfId, objdataId, objId) end

function eluoyang_50037:OnEnterArea(selfId, zoneId) end

function eluoyang_50037:OnItemChanged(selfId, itemdataId) end

function eluoyang_50037:OnTimer(selfId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if misIndex and misIndex >= 0 then
        local saveTime = self:GetMissionParam(selfId, misIndex, 7)
        if saveTime and saveTime > 0 then
            saveTime = saveTime - 1000
            if saveTime <= 0 then
                self:StopMissionTimer(selfId, self.g_MissionId)
                self:SetMissionByIndex(selfId, misIndex, 0, 2)
                saveTime = 0
            end
            self:SetMissionByIndex(selfId, misIndex, 7, saveTime)
        end
    end
end

function eluoyang_50037:OnBegin(selfId, targetId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if misIndex and misIndex >= 0 then
        local stateCode = self:GetMissionParam(selfId, misIndex, 0)
        if stateCode and stateCode == 2 then
            self:MessageBox(selfId, targetId, self.g_ContinueInfo1)
            self:DelMission(selfId, self.g_MissionId)
        else
            self:BeginEvent(self.script_id)
            self:AddText(
                "Tuần du cũng náo nhiệt kết thúc rồi, bây giờ nên bắt đầu Bái Thiên Địa thôi.")
            self:AddNumText("Ừ, giờ bắt đầu thôi.", 8, self.g_eventId_start)
            self:AddNumText("Chúng ta còn phải đợi một lát...", 8,
                            self.g_eventId_close)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
end

function eluoyang_50037:OnStart(selfId, targetId)
    local marryLevel
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if misIndex and misIndex >= 0 then
        local stateCode = self:GetMissionParam(selfId, misIndex, 0)
        if stateCode and stateCode == 2 then
            self:MessageBox(selfId, targetId, self.g_ContinueInfo1)
            self:DelMission(selfId, self.g_MissionId)
            return 0
        else
            marryLevel = self:GetMissionParam(selfId, misIndex, 2)
        end
    else
        self:MessageBox(selfId, targetId, "Chưa tìm thấy nhiệm vụ bái thiên địa.")
        return 0
    end
    local szMsg = "Nếu muốn bái thiên địa, xin hai người nam nữ tổ đội rồi đến tìm ta."
    if not self:LuaFnHasTeam(selfId) then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Đội ngũ chỉ được do phu thê hai người tạo thành, trong đội không được có người Khác."
    if self:LuaFnGetTeamSize(selfId) ~= 2 then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Chỉ khi cả hai người đều đến cạnh ta mới có thể bắt đầu bái thiên địa."
    local nearNum = self:GetNearTeamCount(selfId)
    if nearNum ~= 2 then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Không phải phu thê không thể bắt đầu bái thiên địa."
    local maleId = -1
    local femaleId = -1
    for nearIndex = 1, nearNum do
        local memId = self:GetNearTeamMember(selfId, nearIndex)
        local sexType = self:LuaFnGetSex(memId)
        if sexType == 1 then
            maleId = memId
        else
            femaleId = memId
        end
    end
    if maleId == -1 or femaleId == -1 then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    local isSpouses = self:LuaFnIsSpouses(maleId, femaleId)
    if isSpouses then
    else
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    self:DelMission(selfId, self.g_MissionId)
    self:CallScriptFunction(401030, "Create", maleId, femaleId, marryLevel)
end

function eluoyang_50037:MessageBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return eluoyang_50037
