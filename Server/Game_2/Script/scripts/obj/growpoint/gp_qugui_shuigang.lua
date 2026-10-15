local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_qugui_shuigang = class("gp_qugui_shuigang", script_base)
function gp_qugui_shuigang:OnCreate(growPointType, x, y)
    local ItemCount = 0
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, ItemCount)
end

function gp_qugui_shuigang:OnProcOver(selfId, targetId)
    local itemBoxX = self:GetItemBoxWorldPosX(targetId)
    local itemBoxZ = self:GetItemBoxWorldPosZ(targetId)
    self:CreateMonsterOnScene(5, itemBoxX, itemBoxZ, 1)
    return define.OPERATE_RESULT.OR_OK
end

function gp_qugui_shuigang:OnTickCreateFinish(growPointType, tickCount)
end

return gp_qugui_shuigang
