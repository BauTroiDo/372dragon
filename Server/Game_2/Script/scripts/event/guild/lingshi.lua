local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local lingshi = class("lingshi", script_base)
lingshi.script_id = 600050
lingshi.g_Name = "上官冰"
lingshi.g_Name2 = "上官雪"
lingshi.g_A_LingShiIndex = 2
lingshi.g_B_LingShiIndex = 7
lingshi.g_Human_ResourceNumIndex = 4
lingshi.g_LingShi = {
    "Thanh Long Thạch", "Bạch Hổ Thạch", "Chu Tước Thạch", "Ô Ô Thạch", "Bàn Cổ Thạch"
}
lingshi.g_LingShiID = {30900051, 30900052, 30900053, 30900054, 30900055}
lingshi.g_BangzhanScriptId = 402047
lingshi.g_GuildPoint_LingShi = 1
function lingshi:OnDefaultEvent(selfId, targetId, index)
    local numText = index
    if numText == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_39}")
        self:AddNumText("Xác nhận", 8, 3)
        self:AddNumText("Hủy bỏ", 8, 4)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif numText == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_63}")
        self:AddNumText("Xác nhận", 8, 5)
        self:AddNumText("Hủy bỏ", 8, 6)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif numText == 3 then
        self:AcceptLingshi(selfId, targetId)
    elseif numText == 4 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    elseif numText == 5 then
        self:QueryLingshi(selfId, targetId)
    elseif numText == 6 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
end

function lingshi:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "#{BHXZ_081103_38}", 4, 1)
    caller:AddNumTextWithTarget(self.script_id, "#{BHXZ_081103_62}", 4, 2)
end

function lingshi:QueryLingshi(selfId, targetId)
    local sceneType = self:LuaFnGetSceneType()
    if sceneType ~= 1 then
        self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_78}")
        return
    end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    if fubentype ~= ScriptGlobal.FUBEN_BANGZHAN then
        self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_78}")
        return
    end
    if self:LuaFnGetCopySceneData_Param(7) == 0 then
        self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_157}")
        return
    end
    local name = self:GetName(targetId)
    local humanguildid = self:GetHumanGuildID(selfId)
    if name == self.g_Name then
        local msg = "#{BHXZ_081103_140}"
        for i = 1, #(self.g_LingShi) do
            local num = self:GetGuildIntNum(humanguildid,self.g_A_LingShiIndex + i - 1)
            msg = msg .. "#r" .. self.g_LingShi[i] .. "：" .. num
        end
        self:NotifyFailBox(selfId, targetId, msg)
    elseif name == self.g_Name2 then
        local msg = "#{BHXZ_081103_140}"
        for i = 1, #(self.g_LingShi) do
            local num = self:GetGuildIntNum(humanguildid,  self.g_B_LingShiIndex + i - 1)
            msg = msg .. "#r" .. self.g_LingShi[i] .. "：" .. num
        end
        self:NotifyFailBox(selfId, targetId, msg)
    end
end

function lingshi:AcceptLingshi(selfId, targetId)
    local sceneType = self:LuaFnGetSceneType()
    if sceneType ~= 1 then
        self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_78}")
        return
    end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    if fubentype ~= ScriptGlobal.FUBEN_BANGZHAN then
        self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_78}")
        return
    end
    if self:LuaFnGetCopySceneData_Param(7) == 0 then
        self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_37}")
        return
    end
    local name = self:GetName(targetId)
    local humanguildid = self:GetHumanGuildID(selfId)
    local LingShiPerPoint = self:GetGuildWarPoint(self.g_GuildPoint_LingShi)
    if name == self.g_Name then
        local msg = ""
        local point = 0
        local totalnum = 0
        local NumPerType = {0, 0, 0, 0, 0}
        for i = 1, #(self.g_LingShiID) do
            local num = self:LuaFnGetAvailableItemCount(selfId, self.g_LingShiID[i])
            local alreadynum = self:GetGuildIntNum(humanguildid, self.g_A_LingShiIndex + i - 1)
            if num > 0 and alreadynum ~= -1 then
                if self:LuaFnDelAvailableItem(selfId, self.g_LingShiID[i], num) then
                    point = point + num * LingShiPerPoint
                    totalnum = totalnum + num
                    NumPerType[i] = num
                    self:SetGuildIntNum(humanguildid, self.g_A_LingShiIndex + i - 1, num + alreadynum)
                    msg = msg .. "#r" .. self.g_LingShi[i] .. "：" .. num
                end
            end
        end
        if point > 0 then
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_141}" .. msg)
            self:CallScriptFunction(self.g_BangzhanScriptId, "AddAGuildPoint", selfId, humanguildid, point)
            self:Msg2Player(selfId, "#{BHXZ_081103_142}" .. totalnum .. "#{BHXZ_081103_143}", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)

            self:CallScriptFunction(self.g_BangzhanScriptId, "AddHumanGuildArrayInt", selfId, self.g_Human_ResourceNumIndex, totalnum)
            local guid = self:LuaFnObjId2Guid(selfId)
            local log = string.format(  "qinglong=%d,baihu=%d,zhuque=%d,xuanwu=%d,pangu=%d,total=%d", NumPerType[1], NumPerType[2], NumPerType[3], NumPerType[4], NumPerType[5], totalnum)
            self:ScriptGlobal_AuditGeneralLog(ScriptGlobal.LUAAUDIT_BANGZHAN_RESOURCE, guid, log)
        else
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_144}")
        end
    elseif name == self.g_Name2 then
        local msg = ""
        local point = 0
        local totalnum = 0
        local NumPerType = {0, 0, 0, 0, 0}
        for i = 1, #(self.g_LingShiID) do
            local num = self:LuaFnGetAvailableItemCount(selfId, self.g_LingShiID[i])
            local alreadynum = self:GetGuildIntNum(humanguildid, self.g_B_LingShiIndex + i - 1)
            if num > 0 and alreadynum ~= -1 then
                if self:LuaFnDelAvailableItem(selfId, self.g_LingShiID[i], num) then
                    point = point + num * LingShiPerPoint
                    totalnum = totalnum + num
                    NumPerType[i] = num
                    self:SetGuildIntNum(humanguildid, self.g_B_LingShiIndex + i - 1, num + alreadynum)
                    msg = msg .. "#r" .. self.g_LingShi[i] .. "：" .. num
                end
            end
        end
        if point > 0 then
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_141}" .. msg)
            self:CallScriptFunction(self.g_BangzhanScriptId, "AddBGuildPoint", selfId, humanguildid, point)
            self:Msg2Player(selfId, "#{BHXZ_081103_142}" .. totalnum .. "#{BHXZ_081103_143}", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)

            self:CallScriptFunction(self.g_BangzhanScriptId, "AddHumanGuildArrayInt", selfId, self.g_Human_ResourceNumIndex, totalnum)
            local guid = self:LuaFnObjId2Guid(selfId)
            local log = string.format( "qinglong=%d,baihu=%d,zhuque=%d,xuanwu=%d,pangu=%d,total=%d",NumPerType[1], NumPerType[2], NumPerType[3], NumPerType[4], NumPerType[5], totalnum)
            self:ScriptGlobal_AuditGeneralLog(ScriptGlobal.LUAAUDIT_BANGZHAN_RESOURCE, guid, log)
        else
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_144}")
        end
    end
end

function lingshi:CheckAccept(selfId, targetId) return 1 end

function lingshi:OnAccept(selfId, targetId) end

function lingshi:OnContinue(selfId, targetId) end

function lingshi:OnAbandon(selfId) end

function lingshi:CheckSubmit(selfId) return 1 end

function lingshi:OnSubmit(selfId, targetId, selectRadioId) end

function lingshi:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function lingshi:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return lingshi
