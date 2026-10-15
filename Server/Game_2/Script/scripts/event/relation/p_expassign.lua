local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local p_expassign = class("p_expassign", script_base)
p_expassign.script_id = 806018
p_expassign.g_AssignExpDateMax = 120000
function p_expassign:OnDefaultEvent(selfId, targetId)
    local nMlevel = self:LuaFnGetmasterLevel(selfId)
    if nMlevel < 1 or nMlevel > 4 then
        self:MsgBox(selfId, targetId, "  Cấp độ Sư Đức sai lệch.")
        return
    end
    if self:LuaGetPrenticeSupplyExp(selfId) == 0 then
        self:MsgBox(selfId, targetId, "  Không có kinh nghiệm có thể lĩnh.")
        return
    end
    local nOldTime = self:GetMissionData(selfId, ScriptGlobal.MD_PEXP_GP_TIME)
    local nOldValue = self:GetMissionData(selfId, ScriptGlobal.MD_PEXP_GP_VALUE)
    local nNewTime = self:GetDayTime()
    if nOldTime == nNewTime and nOldValue >= self.g_AssignExpDateMax then
        self:MsgBox(selfId, targetId, "  Hôm nay ngài dùng cống hiến độ bang phái đổi kinh nghiệm đã đạt giới hạn, xin ngày mai lại đến lĩnh.")
        return
    end
    self:LuaFnExpAssign(selfId, 2)
    self:BeginUICommand()
    self:UICommand_AddInt(targetId)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
end

function p_expassign:OnEnumerate(caller)
    caller:AddNumTextWithTarget(self.script_id, "Ta muốn dùng cống hiến độ bang phái lĩnh kinh nghiệm", 6, -1)
end

function p_expassign:CallBackExpAssignByGuildPoint(selfId, nExp)
    if not self:LuaFnIsCanDoScriptLogic(selfId) then
        return 0
    end
    local nAssignExp = nExp
    local nMlevel = self:LuaFnGetmasterLevel(selfId)
    if nMlevel < 1 or nMlevel > 4 then
        self:MsgTip(selfId, "Cấp độ sư đức sai")
        return 0
    end
    if nAssignExp < 0 or nAssignExp > self:LuaGetPrenticeSupplyExp(selfId) then
        self:MsgTip(selfId, "Lĩnh giá trị kinh nghiệm sai")
        return 0
    end
    if self:IsLocked(selfId, 0) then
        self:MsgTip(selfId, "Cống hiến độ bang phái bị khóa, xin hãy thử lại sau")
        return 0
    end
    local nOldTime = self:GetMissionData(selfId, ScriptGlobal.MD_PEXP_GP_TIME)
    local nOldValue = self:GetMissionData(selfId, ScriptGlobal.MD_PEXP_GP_VALUE)
    local nNewTime = self:GetDayTime()
    if nOldTime == nNewTime and nOldValue >= self.g_AssignExpDateMax then
        self:MsgTip(selfId, "Ngày đó đổi đã đạt giới hạn tối đa")
        return 0
    end
    if nOldTime ~= nNewTime then
        nOldValue = 0
    end
    if nAssignExp + nOldValue > self.g_AssignExpDateMax then
        nAssignExp = self.g_AssignExpDateMax - nOldValue
        self:MsgTip(selfId, "Giới hạn đổi mỗi ngày là" .. self.g_AssignExpDateMax .. "Điểm kinh nghiệm, ngài chỉ còn lại" .. nAssignExp .. "điểm")
    end
    local nBasePoint = 0
    if nMlevel == 1 then
        nBasePoint = 250
    elseif nMlevel == 2 then
        nBasePoint = 300
    elseif nMlevel == 3 then
        nBasePoint = 400
    elseif nMlevel == 4 then
        nBasePoint = 600
    end
    local nGPValue = math.ceil(nAssignExp / nBasePoint)
    if nGPValue > self:CityGetAttr(selfId, ScriptGlobal.GUILD_CONTRIB_POINT) then
        self:MsgTip(selfId, "Không đủ cống hiến độ bang phái")
        return 0
    end
    self:CityChangeAttr(selfId, ScriptGlobal.GUILD_CONTRIB_POINT, -nGPValue)
    self:LuaAddPrenticeProExp(selfId, 0, -nAssignExp)
    self:AddExp(selfId, nAssignExp)
    self:LuaFnAuditMasterExp(selfId, nGPValue, nAssignExp, 2)
    if nOldTime ~= nNewTime then
        self:SetMissionData(selfId, ScriptGlobal.MD_PEXP_GP_TIME, nNewTime)
        self:SetMissionData(selfId, ScriptGlobal.MD_PEXP_GP_VALUE, nAssignExp)
    else
        self:SetMissionData(selfId, ScriptGlobal.MD_PEXP_GP_VALUE, nOldValue + nAssignExp)
    end
end

function p_expassign:MsgBox(selfId, targetId, str)
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function p_expassign:MsgTip(selfId, str)
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return p_expassign
