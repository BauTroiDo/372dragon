local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local shuilao = class("shuilao", script_base)
shuilao.script_id = 232000
shuilao.g_EventList = { 232001 }
shuilao.g_MissionId = 1212
shuilao.g_MissionIdNext = 1213
shuilao.g_Name = "呼延豹"
shuilao.g_MissionName = "Giúp bình định phản loạn Thủy Lao"
shuilao.g_MissionInfo = "  Bình định phản loạn Thủy Lao."
shuilao.g_MissionTarget = "  Hô Diên Báo ở Tô Châu #{_INFOAIM244,215,1,Hô Diên Báo} nhờ ngươi giúp hắn hoàn thành nhiệm vụ bình định phản loạn Thủy Lao."
shuilao.g_ContinueInfo = "  Nhiệm vụ đã hoàn thành chưa?"
shuilao.g_MissionComplete = "  Đa tạ các hạ!"
shuilao.g_MaxRound = 1000
shuilao.g_minLevel = 20
function shuilao:OnDefaultEvent(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        return
    end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local misRealScript = self:GetMissionParam(selfId, misIndex, 1)
        self:CallScriptFunction(misRealScript, "OnDefaultEvent", selfId, targetId)
    else
        if self:LuaFnGetLevel(selfId) < self.g_minLevel then
            self:NotifyTip(selfId, "Cấp độ của các hạ còn thấp, phạm nhân so ra khá lợi hại,")
            self:NotifyTip(selfId, "Hay là đợi đến khi ngươi đạt đến" .. self.g_minLevel .. "Đạt cấp rồi hãy đến tìm ta.")
            return 0
        end
        local lstMem = {selfId}
        local numMem = 1
        if self:LuaFnHasTeam(selfId) then
            if self:LuaFnIsTeamLeader(selfId) then
                numMem = self:GetNearTeamCount(selfId)
                for i = 1, numMem do
                    lstMem[i] = self:GetNearTeamMember(selfId, i)
                end
            end
        end
        local rand = self.g_EventList[1]
        for i = 1, numMem do
            self:CallScriptFunction(rand, "OnDefaultEvent", lstMem[i], targetId)
        end
    end
end

function shuilao:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        return
    end
    if self:IsHaveMission(selfId, self.g_MissionId) or self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 4, -1)
    end
end

function shuilao:CheckAccept(selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    local iDayCount = self:GetMissionData(selfId, ScriptGlobal.MD_SHUILAO_ACCEPT_TIME)
    local nMonth = self:LuaFnGetThisMonth()
    local nDay = self:LuaFnGetDayOfThisMonth()
    local nData = (nMonth + 1) * 100 + nDay
    if iDayCount ~= nData then
        self:SetMissionData(selfId, ScriptGlobal.MD_SHUILAO_ACCEPT_COUNT, 0)
    end
    iDayCount = self:GetMissionData(selfId, ScriptGlobal.MD_BAIMASI_DAYCOUNT)
    local iTime = self:GetMissionData(selfId, ScriptGlobal.MD_BAIMASI_DAYTIME)
    local iDayTime = math.floor(iTime / 100)
    local iDayHuan = iDayCount
    local CurTime = self:GetQuarterTime()
    local CurDaytime = math.floor(CurTime / 100)
    if iDayTime ~= CurDaytime then
        iDayHuan = 0
        iDayCount = iDayHuan
        self:SetMissionData(selfId, ScriptGlobal.MD_BAIMASI_DAYTIME, CurTime)
        self:SetMissionData(selfId, ScriptGlobal.MD_BAIMASI_DAYCOUNT, iDayCount)
    end
    if iDayHuan >= self.g_MaxRound then
        self:NotifyTip(selfId, "Nhiệm vụ của hôm nay đã nhận vượt quá số lần quy định")
        return 0
    end
    return 1
end

function shuilao:OnAccept(selfId, targetId, scriptId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        return
    end
    local nMonth = self:LuaFnGetThisMonth()
    local nDay = self:LuaFnGetDayOfThisMonth()
    local nData = (nMonth + 1) * 100 + nDay
    self:SetMissionData(selfId, ScriptGlobal.MD_SHUILAO_ACCEPT_TIME, nData)
    local iDayCount = self:GetMissionData(selfId, ScriptGlobal.MD_SHUILAO_ACCEPT_COUNT)
    if iDayCount >= self.g_MaxRound then
        self:NotifyTip(selfId, "Nhiệm vụ của hôm nay đã nhận vượt quá số lần quy định")
        return
    else
        iDayCount = iDayCount + 1
        self:SetMissionData(selfId, ScriptGlobal.MD_SHUILAO_ACCEPT_COUNT, iDayCount)
    end
    if not self:LuaFnDelAvailableItem(selfId, 20502012, 1) then
        self:NotifyTip(selfId, "Ngươi không có lệnh bài thủy lao")
        self:NotifyTip(selfId, "Lệnh bài thủy lao nhận từ đánh bại Viễn Cổ Kỳ Hồn ở Trân Lung Kỳ Cục.")
        return 0
    end
    self:AddMission(selfId, self.g_MissionId, scriptId, 0, 0, 1)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, scriptId)
    local MissionRound = self:GetMissionData(selfId, ScriptGlobal.MD_BAIMASI_HUAN)
    MissionRound = MissionRound + 1
    if MissionRound > self.g_MaxRound then
        self:SetMissionData(selfId, ScriptGlobal.MD_BAIMASI_HUAN, 1)
    else
        self:SetMissionData(selfId, ScriptGlobal.MD_BAIMASI_HUAN, MissionRound)
    end
end

function shuilao:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
    local iDayCount = self:GetMissionData(selfId, ScriptGlobal.MD_BAIMASI_DAYCOUNT)
    local iDayHuan = iDayCount
    local iTime = self:GetMissionData(selfId, ScriptGlobal.MD_BAIMASI_DAYTIME)
    local iDayTime = math.floor(iTime / 100)
    local CurTime = self:GetQuarterTime()
    local CurDaytime = math.floor(CurTime / 100)
    if iDayTime ~= CurDaytime then
        self:SetMissionData(selfId, ScriptGlobal.MD_SHUILAO_ACCEPT_COUNT, 0)
        iDayHuan = 0
    end
    iDayCount = iDayHuan
    self:SetMissionData(selfId, ScriptGlobal.MD_BAIMASI_DAYTIME, CurTime)
    self:SetMissionData(selfId, ScriptGlobal.MD_BAIMASI_DAYCOUNT, iDayCount)
end

function shuilao:OnContinue(selfId, targetId)
end

function shuilao:CheckSubmit(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, 0) == 1 then
        return 1
    end
    return 0
end

function shuilao:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) ~= 1 then
        return
    end
    if not self:DelMission(selfId, self.g_MissionId) then
        return
    end
    if self:IsHaveMission(selfId, self.g_MissionIdNext) then
        self:DelMission(selfId, self.g_MissionIdNext)
    end
    local Level = self:GetLevel(selfId)
    local iDayCount = self:GetMissionData(selfId, ScriptGlobal.MD_BAIMASI_DAYCOUNT)
    local iTime = self:GetMissionData(selfId, ScriptGlobal.MD_BAIMASI_DAYTIME)
    local iDayTime = math.floor(iTime / 100)
    local iQuarterTime = iTime % 100
    local iDayHuan = iDayCount
    local CurTime = self:GetQuarterTime()
    local CurDaytime = math.floor(CurTime / 100)
    if CurDaytime == iDayTime then
        iDayHuan = iDayHuan + 1
    else
        iDayTime = CurDaytime
        iQuarterTime = 0
        iDayHuan = 1
    end
    iDayCount = iDayHuan
    local newTime = iDayTime * 100 + iQuarterTime
    self:SetMissionData(selfId, ScriptGlobal.MD_BAIMASI_DAYTIME, newTime)
    self:SetMissionData(selfId, ScriptGlobal.MD_BAIMASI_DAYCOUNT, iDayCount)
    local MissionRound = self:GetMissionData(selfId, ScriptGlobal.MD_BAIMASI_HUAN)
    local l_Money = (49 + Level) / (160 + 40 * Level)
    local Round = math.mod(MissionRound, 10)
    if Round == 0 then
        Round = 10
    end
    local Money = 2400 * (Level + 4) * Round * l_Money / 120
    Money = math.floor(Money)
    self:AddMoney(selfId, Money)
    self:BeginEvent(self.script_id)
    self:AddText("  Làm tốt lắm, đây là #{_MONEY" .. Money .. ", xem như là phần thưởng cho ngươi.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
    self:LuaFnAuditShuiLao(selfId)
end

function shuilao:OnKillObject(selfId, objdataId)
end

function shuilao:OnEnterArea(selfId, zoneId)
end

function shuilao:OnItemChanged(selfId, itemdataId)
end

function shuilao:AcceptDialog(selfId, rand, g_Dialog, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(g_Dialog)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function shuilao:SubmitDialog(selfId, rand)
end
function shuilao:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function shuilao:GetEventMissionId(selfId)
    return self.g_MissionId
end

return shuilao
