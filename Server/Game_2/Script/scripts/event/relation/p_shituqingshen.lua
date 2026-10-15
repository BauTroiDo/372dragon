local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_shituqingshen = class("p_shituqingshen", script_base)
p_shituqingshen.script_id = 806019
p_shituqingshen.g_Update = {["id01"] = 15}
p_shituqingshen.g_msg = {["st"] = "Sư Đồ Tình Thâm"}
p_shituqingshen.g_Impact = {
    8010,
    8011,
    8012,
    8013,
    8014,
    8015,
    8016,
    8017,
    8018,
    8019,
    30151,
    30152,
    30153,
    30154,
    30155,
    30156,
    30157,
    30158,
    30159,
    30160
}

function p_shituqingshen:OnDefaultEvent(selfId, targetId, index)
    local key = index
    if key == self.g_Update["id01"] then
        local nMonth = self:LuaFnGetThisMonth()
        local nDay = self:LuaFnGetDayOfThisMonth()
        local nData = (nMonth + 1) * 100 + nDay
        if (nData ~= 0 and nData == 910) then
            self:OnShiTuQingShen(selfId, targetId)
            return 0
        else
            self:MessageBox(selfId, "Xin lỗi, chỉ có ngày 10 tháng 9 Ngày Nhà Giáo mới có thể nhận Khuyên Sư Đồ Tình Thâm.")
            return 0
        end
    end
end

function p_shituqingshen:OnEnumerate(caller)
    local nMonth = self:LuaFnGetThisMonth()
    local nDay = self:LuaFnGetDayOfThisMonth()
    local nData = (nMonth) * 100 + nDay
    if (nData ~= 0 and nData == 910) then
        caller:AddNumTextWithTarget(self.script_id, self.g_msg["st"], 6, self.g_Update["id01"])
    end
end

function p_shituqingshen:CheckAccept(selfId, targetId)
end

function p_shituqingshen:OnAccept(selfId, targetId)
end

function p_shituqingshen:OnSubmit(selfId, targetId, tId)
end

function p_shituqingshen:OnCancel(selfId, targetId)
end

function p_shituqingshen:MessageBox(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function p_shituqingshen:OnShiTuQingShen(selfId, targetId)
    if not self:LuaFnHasTeam(selfId) then
        self:MessageBox(selfId, "Xin lỗi, phải có sư phụ và đệ tử tổ đội mới có thể nhận được Khuyên Sư Đồ Tình Thâm")
        return 0
    end
    if self:LuaFnIsTeamLeader(selfId) then
        self:MessageBox(selfId, "Xin lỗi, phải là đội trưởng mới có thể nhận được Khuyên Sư Đồ Tình Thâm")
        return 0
    end
    if self:LuaFnGetTeamSize(selfId) ~= 2 then
        self:MessageBox(selfId, "Xin lỗi, phải có sư phụ và đệ tử tổ đội mới có thể nhận được Khuyên Sư Đồ Tình Thâm")
        return 0
    end
    local TeamSizeSameScene = self:LuaFnGetTeamSceneMemberCount(selfId)
    if TeamSizeSameScene ~= 1 then
        self:MessageBox(selfId, "Xin lỗi, phải có sư phụ và đệ tử tổ đội mới có thể nhận được Khuyên Sư Đồ Tình Thâm")
        return 0
    end
    local numMem = self:GetNearTeamCount(selfId)
    if numMem ~= self:LuaFnGetTeamSize(selfId) then
        self:MessageBox(selfId, "Xin lỗi, sư phụ và đệ tử của các vị phải ở gần nhau mới có thể nhận được Khuyên Sư Đồ Tình Thâm")
        return 0
    end
    local theID = self:LuaFnGetTeamSceneMember(selfId, 1)
    if self:LuaFnIsMaster(selfId, theID) or self:LuaFnIsMaster(theID, selfId) then
        self:OnAddImpact(selfId, 0)
        self:OnAddImpact(selfId, theID)
    else
        self:MessageBox(selfId, "Xin lỗi, phải có sư phụ và đệ tử tổ đội mới có thể nhận được Khuyên Sư Đồ Tình Thâm")
        return 0
    end
end

function p_shituqingshen:OnAddImpact(selfId, theID)
    local level = 0
    if theID == 0 then
        level = self:GetLevel(selfId)
    elseif theID ~= 0 and selfId ~= 0 then
        level = self:GetLevel(theID)
    end
    local impactID = self.g_Impact[1]
    if level > 190 then
        impactID = self.g_Impact[20]
    elseif level > 180 then
        impactID = self.g_Impact[19]
    elseif level > 170 then
        impactID = self.g_Impact[18]
    elseif level > 160 then
        impactID = self.g_Impact[17]
    elseif level > 150 then
        impactID = self.g_Impact[16]
    elseif level > 140 then
        impactID = self.g_Impact[15]
    elseif level > 130 then
        impactID = self.g_Impact[14]
    elseif level > 120 then
        impactID = self.g_Impact[13]
    elseif level > 110 then
        impactID = self.g_Impact[12]
    elseif level > 100 then
        impactID = self.g_Impact[11]
    elseif level > 90 then
        impactID = self.g_Impact[10]
    elseif level > 80 then
        impactID = self.g_Impact[9]
    elseif level > 70 then
        impactID = self.g_Impact[8]
    elseif level > 60 then
        impactID = self.g_Impact[7]
    elseif level > 50 then
        impactID = self.g_Impact[6]
    elseif level > 40 then
        impactID = self.g_Impact[5]
    elseif level > 30 then
        impactID = self.g_Impact[4]
    elseif level > 20 then
        impactID = self.g_Impact[3]
    elseif level > 10 then
        impactID = self.g_Impact[2]
    else
        impactID = self.g_Impact[1]
    end
    if theID == 0 then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, impactID, 0)
    elseif theID ~= 0 and selfId ~= 0 then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, theID, impactID, 0)
    end
end

return p_shituqingshen
