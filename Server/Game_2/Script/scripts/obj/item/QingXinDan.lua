local class = require "class"
local define = require "define"
local script_base = require "script_base"
local QingXinDan = class("QingXinDan", script_base)
QingXinDan.script_id = 330070
function QingXinDan:OnDefaultEvent(selfId, bagIndex)
end

function QingXinDan:IsSkillLikeScript(selfId)
    return 1
end

function QingXinDan:CancelImpacts(selfId)
    return 0
end

function QingXinDan:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local sceneId = self:GetSceneID()
    if not (sceneId == 0 or sceneId == 1 or sceneId == 2 or sceneId == 151) then
        self:notify_tips(selfId,"Thanh Tâm Đan chỉ dùng được ở Đại Lý, Tô Châu, Lạc Dương, nhà lao.")
        return 0
    end
    local pk_value = self:GetPKValue(selfId)
    if pk_value <= 0 then
        self:notify_tips(selfId, "Sát khí lớn hơn 0 mới dùng Thanh Tâm Đan được")
        return 0
    end
    return 1
end

function QingXinDan:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function QingXinDan:OnActivateOnce(selfId)
    local pk_value = self:GetPKValue(selfId)
    if pk_value <= 0 then
        self:notify_tips("Sát khí lớn hơn 0 mới dùng Thanh Tâm Đan được")
        return 0
    end
    self:notify_tips(selfId, "Sát khí hiện giảm 1 điểm")
    self:SetPKValue(selfId, pk_value - 1)
    return 1
end

function QingXinDan:OnActivateEachTick(selfId)
    return 1
end

return QingXinDan
