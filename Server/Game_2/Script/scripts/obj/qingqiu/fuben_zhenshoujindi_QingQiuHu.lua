local class = require "class"
local define = require "define"
local script_base = require "script_base"
local fuben_zhenshoujindi_QingQiuHu = class("fuben_zhenshoujindi_QingQiuHu", script_base)
fuben_zhenshoujindi_QingQiuHu.script_id = 893039
fuben_zhenshoujindi_QingQiuHu.g_FuBenScriptId = 893020
fuben_zhenshoujindi_QingQiuHu.IDX_CombatFlag = 1
function fuben_zhenshoujindi_QingQiuHu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{ZSFB_20220105_03}")
    self:AddNumText("#{ZSFB_20220105_42}", 6, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function fuben_zhenshoujindi_QingQiuHu:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        if self:GetName(targetId) ~= "青丘狐" then
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSFB_20220105_43}")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        self:BeginEvent(self.script_id)
        if self:LuaFnGetCopySceneData_Param(10, 0) < 4 then
            self:AddText("#{ZSFB_20220105_45}")
        end
        self:AddNumText("#{ZSFB_20220105_46}", 6, 2)
        self:AddNumText("#{ZSFB_20220105_47}", 6, 3)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 2 then
        self:CallScriptFunction(893020, "LeaveScene", selfId)
        return
    end
    if index == 3 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    end
end

function fuben_zhenshoujindi_QingQiuHu:OnInit(selfId)
end

function fuben_zhenshoujindi_QingQiuHu:OnHeartBeat(selfId, nTick)
    if not self:LuaFnIsCharacterLiving(selfId) then
        return
    end
end

function fuben_zhenshoujindi_QingQiuHu:OnEnterCombat(selfId, enmeyId)
end

function fuben_zhenshoujindi_QingQiuHu:OnLeaveCombat(selfId)
    self:SetHp(selfId, self:GetMaxHp(selfId))
end

function fuben_zhenshoujindi_QingQiuHu:OnKillCharacter(selfId, targetId)
end

function fuben_zhenshoujindi_QingQiuHu:OnDie(selfId, killerId)
end

function fuben_zhenshoujindi_QingQiuHu:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return fuben_zhenshoujindi_QingQiuHu
