local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_liupinyerenshen = class("gp_renwu_liupinyerenshen", script_base)
function gp_renwu_liupinyerenshen:OnCreate(growPointType, x, y)
    local ItemCount = 1
    local Item0 = 40002097
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, ItemCount, Item0)
end

function gp_renwu_liupinyerenshen:OnOpen(selfId, targetId)
    if self:HaveItem(selfId, 40002097) then
        self:BeginEvent(self.script_id)
        local strText = "Đã lấy được nhân sâm rồi, mau đi giao nhiệm vụ thôi!"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return define.OPERATE_RESULT.OR_MISSION_NOT_FIND
    end
    if self:IsHaveMission(selfId, ScriptGlobal.MISSION_564) then
        return define.OPERATE_RESULT.OR_OK
    else
        return define.OPERATE_RESULT.OR_MISSION_NOT_FIND
    end
end

function gp_renwu_liupinyerenshen:OnRecycle(selfId, targetId)
    return 1
end

function gp_renwu_liupinyerenshen:OnProcOver(selfId, targetId)
    return 0
end

function gp_renwu_liupinyerenshen:OnTickCreateFinish(growPointType, tickCount)
end

return gp_renwu_liupinyerenshen
