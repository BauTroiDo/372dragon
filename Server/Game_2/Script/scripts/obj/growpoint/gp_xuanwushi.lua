local class = require "class"
local define = require "define"
local script_base = require "script_base"
local gp_xuanwushi = class("gp_xuanwushi", script_base)
gp_xuanwushi.g_MainItemId = 30900054
function gp_xuanwushi:OnCreate(growPointType, x, y)
    local targetId = self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
    local rand = math.random(1, 100)
    if rand >= 70 then
        self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
    end
end

function gp_xuanwushi:OnOpen(selfId, targetId)
    if self:CallScriptFunction(402047, "HaveTankBuff", selfId) ~= 0 then
        return define.OPERATE_RESULT.OR_U_CANNT_DO_THIS_RIGHT_NOW
    else
        return define.OPERATE_RESULT.OR_OK
    end
end

function gp_xuanwushi:OnRecycle(selfId, targetId)
    return 1
end

function gp_xuanwushi:OnProcOver(selfId, targetId)
    return 0
end

function gp_xuanwushi:OnTickCreateFinish(growPointType, tickCount)
end

return gp_xuanwushi
