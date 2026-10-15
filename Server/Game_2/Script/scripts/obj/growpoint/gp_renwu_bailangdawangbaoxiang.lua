local class = require "class"
local ScriptGlobal = require "scripts.ScriptGlobal"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_bailangdawangbaoxiang = class("gp_renwu_bailangdawangbaoxiang", script_base)
function gp_renwu_bailangdawangbaoxiang:OnCreate(growPointType, x, y)
    local ItemCount = 1
    local Item0 = 40002066
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, ItemCount, Item0)
end

function gp_renwu_bailangdawangbaoxiang:OnOpen(selfId, targetId)
    if self:HaveItem(selfId, 40002066) then
        self:BeginEvent(self.script_id)
        local strText = "Đã nhận được Khuyên tai, mau đi giao nhiệm vụ thôi!"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return define.OPERATE_RESULT.OR_MISSION_NOT_FIND
    end
    if self:IsHaveMission(selfId, ScriptGlobal.MISSION_546) then
        return define.OPERATE_RESULT.OR_OK
    else
        return define.OPERATE_RESULT.OR_MISSION_NOT_FIND
    end
end

function gp_renwu_bailangdawangbaoxiang:OnRecycle(selfId, targetId)
    return 1
end

function gp_renwu_bailangdawangbaoxiang:OnProcOver(selfId, targetId)
    return 0
end

function gp_renwu_bailangdawangbaoxiang:OnTickCreateFinish(growPointType, tickCount)
end

return gp_renwu_bailangdawangbaoxiang
