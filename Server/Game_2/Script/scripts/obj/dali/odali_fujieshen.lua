local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_fujieshen = class("odali_fujieshen", script_base)
odali_fujieshen.script_id = 002107
odali_fujieshen.g_Yinpiao = 40002000
function odali_fujieshen:OnDefaultEvent(selfId, targetId)
    if self:GetItemCount(selfId, self.g_Yinpiao) >= 1 then
        self:BeginEvent(self.script_id)
        self:AddText("  Ngươi đang mang theo Ngân phiếu, đang trong lúc chạy thương! Ta không thể giúp ngươi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:BeginEvent(self.script_id)
    if self:GetLevel(selfId) >= 30 then
        self:AddText("#{TJL_090714_01}")
        self:AddNumText("#{TJL_xml_XX(02)}", 9, 1001)
        self:AddNumText("#{TJL_xml_XX(03)}", 11, 1002)
    else
        self:AddText("#{TJL_090714_07}")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_fujieshen:OnEventRequest(selfId, targetId, arg, index)
    if index == 1002 then
        self:BeginEvent(self.script_id)
        self:AddText("#{TJL_090714_09}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamId(selfId) >= 0 and self:IsTeamFollow(selfId) and self:LuaFnIsTeamLeader(selfId) == 1 then
        local num = self:LuaFnGetFollowedMembersCount(selfId)
        local mems = {}
        for i = 1, num do
            mems[i] = self:GetFollowedMember(selfId, i)
            if mems[i] == -1 then
                return
            end
            if self:IsHaveMission(mems[i], 4021) then
                self:MsgBox(selfId, targetId, "  Trong đội ngũ của ngươi có người có Thương Thuyền Vận Tải trên người, ta không thể đưa các ngươi đến Thiên Kiếp Lâu.")
                return
            end
        end
    end
    if self:IsHaveMission(selfId, 4021) then
        self:MsgBox(selfId, targetId, "  Ngươi có Thương Thuyền Vận Tải trên người, ta không thể đưa ngươi đến Thiên Kiếp Lâu.")
        return
    end
    local mylevel = self:GetLevel(selfId)
    local iniLevel = math.floor(mylevel / 10) * 10
    if index == 1001 then
        if iniLevel == 10 then
            self:CallScriptFunction((400900), "TransferFunc", selfId, 484, 82, 78, 10)
        elseif iniLevel == 20 then
            self:CallScriptFunction((400900), "TransferFunc", selfId, 485, 82, 78, 10)
        elseif iniLevel == 30 then
            self:CallScriptFunction((400900), "TransferFunc", selfId, 486, 82, 78, 10)
        elseif iniLevel == 40 then
            self:CallScriptFunction((400900), "TransferFunc", selfId, 487, 82, 78, 10)
        elseif iniLevel == 50 then
            self:CallScriptFunction((400900), "TransferFunc", selfId, 488, 82, 78, 10)
        elseif iniLevel == 60 then
            self:CallScriptFunction((400900), "TransferFunc", selfId, 489, 82, 78, 10)
        elseif iniLevel >= 70 then
            self:CallScriptFunction((400900), "TransferFunc", selfId, 490, 82, 78, 10)
        end
        return
    end
end

function odali_fujieshen:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_fujieshen
