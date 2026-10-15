local class = require "class"
local define = require "define"
local script_base = require "script_base"
local fuben_zhenshoujindi_Chuansong = class("fuben_zhenshoujindi_Chuansong", script_base)
fuben_zhenshoujindi_Chuansong.script_id = 893021
fuben_zhenshoujindi_Chuansong.g_FuBenScriptId = 893020
fuben_zhenshoujindi_Chuansong.IDX_CombatFlag = 1
function fuben_zhenshoujindi_Chuansong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{ZSFB_20220105_139}")
    self:AddNumText("#{ZSFB_20220105_156}", 6, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function fuben_zhenshoujindi_Chuansong:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        if self:GetName(targetId) ~= "石碑" then
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSFB_20220105_158}")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        if self:GetLevel(selfId) < 65 then
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSFB_20220105_157}")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local nCurPos = self:LuaFnGetCopySceneData_Param(10)
        if nCurPos <= 0 then
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSFB_20220105_160}")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSFB_20220105_159}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        if nCurPos == 1 then
            self:SetPos(selfId, 178, 123)
        end
        if nCurPos == 2 then
            self:SetPos(selfId, 144, 200)
        end
        if nCurPos >= 3 then
            self:SetPos(selfId, 62, 144)
        end
        return
    end
end

function fuben_zhenshoujindi_Chuansong:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return fuben_zhenshoujindi_Chuansong
