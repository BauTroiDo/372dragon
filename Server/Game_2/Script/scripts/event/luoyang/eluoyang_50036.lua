local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eluoyang_50036 = class("eluoyang_50036", script_base)
eluoyang_50036.script_id = 250036
eluoyang_50036.g_MissionId = 1020
eluoyang_50036.g_TargetNpcName = "喜来乐"
eluoyang_50036.g_MissionKind = 3
eluoyang_50036.g_MissionLevel = 1
eluoyang_50036.g_IfMissionElite = 0
eluoyang_50036.g_MissionLimitTime = 60 * 60 * 1000
eluoyang_50036.g_MissionName = "Diễu hành xe hoa"
eluoyang_50036.g_MissionInfo =
    "Thỉnh đến Lạc Dương [177,94] của Hỷ Lai Lạc để sắp xếp Diễu Hành Hoa Xa."
eluoyang_50036.g_MissionTarget =
    "Hãy tìm Hỷ Lai Lạc ở Lạc Dương#{_INFOAIM177,94,0,Hỷ Lai Lạc} để sắp xếp cuộc diễu hành xe hoa."
eluoyang_50036.g_ContinueInfo1 =
    "Rất tiếc, thời gian ngươi hẹn đã qua, ngươi chỉ có thể từ bỏ mà thôi..."
eluoyang_50036.g_ContinueInfo2 = "Chỗ này cần người lên kế hoạch, đa tạ."
eluoyang_50036.g_MissionComplete = "Vậy hãy bắt đầu thôi."
eluoyang_50036.g_MoneyBonus = 0
eluoyang_50036.g_eventId_begin = 0
eluoyang_50036.g_eventId_start = 1
eluoyang_50036.g_eventId_close = 2
eluoyang_50036.g_busDataIds = {3, 4, 5}
eluoyang_50036.g_busPatrolPathId = 3
function eluoyang_50036:OnDefaultEvent(selfId, targetId, index)
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

function eluoyang_50036:OnEnumerate(caller, selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 6, self.g_eventId_begin)
    end
end

function eluoyang_50036:CheckAccept(selfId) return 1 end
function eluoyang_50036:OnAccept(selfId, marryLevel)
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

function eluoyang_50036:OnAbandon(selfId)
    local checkMission = self:IsHaveMission(selfId, self.g_MissionId)
    if checkMission then
        self:DelMission(selfId, self.g_MissionId)
    end
end

function eluoyang_50036:OnContinue(selfId, targetId) end

function eluoyang_50036:CheckSubmit(selfId) return 0 end

function eluoyang_50036:OnSubmit(selfId, targetId, selectRadioId) end

function eluoyang_50036:OnKillObject(selfId, objdataId, objId) end

function eluoyang_50036:OnEnterArea(selfId, zoneId) end

function eluoyang_50036:OnItemChanged(selfId, itemdataId) end

function eluoyang_50036:OnTimer(selfId)
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

function eluoyang_50036:OnBegin(selfId, targetId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if misIndex and misIndex >= 0 then
        local stateCode = self:GetMissionParam(selfId, misIndex, 0)
        if stateCode and stateCode == 2 then
            self:MessageBox(selfId, targetId,
                            "Các vị đến có phần muộn, kiệu phu ta đã an bài đều đi cả rồi, không thể chuẩn bị hoa xa diễu hành được nữa.")
            self:DelMission(selfId, self.g_MissionId)
        else
            self:BeginEvent(self.script_id)
            self:AddText(
                "Chúc mừng các vị, kiệu phu đã chuẩn bị xong xuôi, mời các vị lập tức bắt đầu diễu hành.")
            self:AddNumText("Giờ bắt đầu diễu hành.", 8, self.g_eventId_start)
            self:AddNumText("Để lát nữa bắt đầu...", 8, self.g_eventId_close)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
end

function eluoyang_50036:OnStart(selfId, targetId)
    local marryLevel
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if misIndex and misIndex >= 0 then
        local stateCode = self:GetMissionParam(selfId, misIndex, 0)
        if stateCode and stateCode == 2 then
            self:MessageBox(selfId, targetId,
                            "Các vị đến có phần muộn, kiệu phu ta đã an bài đều đi cả rồi, không thể chuẩn bị hoa xa diễu hành được nữa.")
            self:DelMission(selfId, self.g_MissionId)
            return 0
        else
            marryLevel = self:GetMissionParam(selfId, misIndex, 2)
        end
    else
        self:MessageBox(selfId, targetId, "Chưa tìm thấy nhiệm vụ hoa xa diễu hành.")
        return 0
    end
    local szMsg =
        "Nếu muốn hoa xa diễu hành, xin hai vị nam nữ kết thành một đội rồi đến tìm ta."
    if not self:LuaFnHasTeam(selfId) then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg =
        "Đội ngũ chỉ được do phu thê hai người tạo thành, trong đội không được có người Khác."
    if self:LuaFnGetTeamSize(selfId) ~= 2 then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Chỉ khi cả hai người đều đến bên cạnh ta mới có thể bắt đầu hoa xa diễu hành."
    local nearNum = self:GetNearTeamCount(selfId)
    if nearNum ~= 2 then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Không phải phu thê thì không thể bắt đầu hoa xa tuần du."
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
    for nearIndex = 1, nearNum do
        local memId = self:GetNearTeamMember(selfId, nearIndex)
        if self:LuaFnIsStalling(memId) then
            self:MessageBox(selfId, targetId, "#{CWHL_081208_1}")
            return 0
        end
    end
    local busIndex
    if marryLevel and marryLevel > -1 and marryLevel < 3 then
        busIndex = marryLevel + 1
    else
        busIndex = 1
    end
    local busObjID = self:LuaFnCreateBusByPatrolPathId(self.g_busDataIds[busIndex], self.g_busPatrolPathId, 0)
    if busObjID and busObjID ~= -1 then
        local succeeded, strText
        succeeded = 0
        local addPassergerRet = self:LuaFnBusAddPassengerList(busObjID,
                                                              targetId, 1, 2,
                                                              maleId, femaleId)
        if addPassergerRet and addPassergerRet == define.OPERATE_RESULT.OR_OK then
            local busStartRet = self:LuaFnBusStart(busObjID)
            if busStartRet then
                self:BeginUICommand()
                self:EndUICommand()
                self:DispatchUICommand(selfId, 1000)
                self:DelMission(selfId, self.g_MissionId)
                self:CallScriptFunction(250037, "OnAccept", selfId, marryLevel)
                succeeded = 1
            else
                strText =
                    "Nội bộ xảy ra lỗi (khởi động thất bại), diễu hành hoa xe không thể khởi động, xin hãy liên hệ với GM."
            end
        end
        if succeeded and succeeded == 1 then
        else
            self:LuaFnBusRemoveAllPassenger(busObjID)
            self:LuaFnDeleteBus(busObjID)
            if strText then
                self:MessageBox(selfId, targetId, strText)
            end
        end
    end
end

function eluoyang_50036:MessageBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return eluoyang_50036
