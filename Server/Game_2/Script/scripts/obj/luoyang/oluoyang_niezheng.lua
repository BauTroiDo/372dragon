local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local oluoyang_niezheng = class("oluoyang_niezheng", script_base)
oluoyang_niezheng.script_id = 000111
oluoyang_niezheng.g_name = "聂政"
oluoyang_niezheng.g_RelationEventList = {
    806019, 806008, 806009, 806006, 806015, 806018
}

function oluoyang_niezheng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_niezheng:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0030}")
    for i, eventId in pairs(self.g_RelationEventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Ta muốn dùng điểm thiện ác để lĩnh kinh nghiệm", 6, 3)
    self:AddNumText("Xuất Sư", 6, 10)
    self:AddNumText("Sư đồ tửu quán", 11, 4)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_niezheng:OnEventRequest(selfId, targetId, arg, index)
    local strText
    local nMlevel = self:LuaFnGetmasterLevel(selfId)
    if arg == self.script_id then
        if index == 1 then
            self:BeginEvent(self.script_id)
            self:AddText("#{OBJ_luoyang_0032}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        elseif index == 4 then
            self:BeginEvent(self.script_id)
            self:AddText("#{function_help_050}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        elseif index == 2 then
            self:BeginEvent(self.script_id)
            strText = string.format("  Điểm Sư Đức hiện tại: %d",
                                  self:LuaFnGetMasterMoralPoint(selfId))
            self:AddText(strText)
            strText = string.format("  Điểm Sư Đức tích lũy: %d",
                                  self:LuaFnGetMasterMoralPoint(selfId))
            self:AddText(strText)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        elseif index == 10 then
            local HumanLevel = self:LuaFnGetLevel(selfId)
            if HumanLevel < 45 then
                self:MyMsgBox(selfId, targetId, "#{STGZ_20080520_5}")
                return
            end
            if not self:LuaFnHaveMaster(selfId) then
                self:MyMsgBox(selfId, targetId, "#{STGZ_20080520_6}")
                return
            end
            if self:GetMissionFlag(selfId, ScriptGlobal.MF_ShiTu_ChuShi_Flag) == 1 then
                self:MyMsgBox(selfId, targetId, "#{STGZ_20080520_6}")
                return
            end
            self:SetMissionFlag(selfId, ScriptGlobal.MF_ShiTu_ChuShi_Flag, 1)
            self:LuaFnChuShiMail(selfId)
            self:MyMsgBox(selfId, targetId, "#{STGZ_20080520_1}")
            return
        elseif index == 3 then
            if nMlevel < 1 or nMlevel > 4 then
                self:MyMsgBox(selfId, targetId, "  Cấp độ Sư Đức sai lệch.")
                return
            end
            if self:LuaGetPrenticeSupplyExp(selfId) == 0 then
                self:MyMsgBox(selfId, targetId,
                              "  Không có kinh nghiệm có thể lĩnh.")
                return
            end
            self:LuaFnExpAssign(selfId, 1)
            self:BeginUICommand()
            self:UICommand_AddInt(targetId)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 1000)
        elseif index == 123 then
            local HumanLevel = self:LuaFnGetLevel(selfId)
            if HumanLevel < 30 then
                self:MyMsgBox(selfId, targetId, "Đạt cấp 30 trở lên mới có thể lĩnh!")
                return
            end
            local nDayTime = self:GetMissionData(selfId, ScriptGlobal.MD_SHITU_XINLIANXIN)
            local nDay = self:LuaFnGetDayOfThisMonth()
            if nDayTime == nDay then
                self:MyMsgBox(selfId, targetId,
                              "Xin lỗi, hôm nay ngươi đã tham gia hoạt động này rồi, mời ngày mai lại đến!")
                return
            end
            self:BeginAddItem()
            self:AddItem(30008045, 1)
            if self:EndAddItem(selfId) < 1 then return end
            self:AddItemListToHuman(selfId)
            self:MyMsgBox(selfId, targetId,
                          "Ta nơi này có một Đại Lễ Bao Sư Đồ tặng cho ngươi, hãy hảo hảo lợi dụng nó!")
            self:BeginEvent(self.script_id)
            strText = "Ngươi nhận được một Đại Lễ Bao Sư Đồ!"
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:SetMissionData(selfId, ScriptGlobal.MD_SHITU_XINLIANXIN, nDay)
            self:AuditJoinJiaoShiJie(selfId)
        elseif index == 321 then
            self:MyMsgBox(selfId, targetId,
                          "Lễ Nhà Giáo thường niên sắp đến rồi! Tất cả anh hùng trên cấp 30 đều có thể đến chỗ Nhiếp Chính Đại Lý (170,123) để lĩnh Đại Lễ Bao Sư Đồ. Sử dụng đại lễ bao còn có thu hoạch bất ngờ đó!")
            return
        end
        return
    end
    for i, findId in pairs(self.g_RelationEventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, index)
            return
        end
    end
end

function oluoyang_niezheng:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_RelationEventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_niezheng:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_RelationEventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_niezheng:MyMsgBox(selfId, targetId, str)
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_niezheng
