local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_huazhong = class("mantuo_huazhong", script_base)
mantuo_huazhong.script_id = 893255
mantuo_huazhong.g_event = 893259
function mantuo_huazhong:OnDefaultEvent(selfId, bagIndex)
end

function mantuo_huazhong:IsSkillLikeScript(selfId)
    return 1
end

function mantuo_huazhong:CancelImpacts(selfId)
    return 0
end

function mantuo_huazhong:OnConditionCheck(selfId)
    return self:CallScriptFunction(self.g_event, "CheckCondition_UseItem", selfId, -1, -1)
end

function mantuo_huazhong:OnDeplete(selfId)
    return 1
end

function mantuo_huazhong:OnActivateOnce(selfId)
    --self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 146, 0)
    self:CallScriptFunction(self.g_event, "Active_UseItem", selfId, -1)
    self:BeginEvent(self.script_id)
    self:AddText("Sử dụng vật phẩm thành công, nhiệm vụ hoàn thành!")
    self:EndEvent()
    self:DispatchMissionTips(selfId)
    self:Msg2Player(selfId, "Sử dụng vật phẩm thành công, nhiệm vụ hoàn thành", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    return 1
end

function mantuo_huazhong:OnActivateEachTick(selfId)
    return 1
end

return mantuo_huazhong
