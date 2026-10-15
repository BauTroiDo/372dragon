local class = require "class"
local define = require "define"
local script_base = require "script_base"
local yuanlingquan = class("yuanlingquan", script_base)
yuanlingquan.script_id = 300084
yuanlingquan.g_event = 808131
function yuanlingquan:OnDefaultEvent(selfId, bagIndex)
end

function yuanlingquan:IsSkillLikeScript(selfId)
    return 1
end

function yuanlingquan:CancelImpacts(selfId)
    return 0
end

function yuanlingquan:OnConditionCheck(selfId)
    local sceneId = self:GetSceneID()
    if sceneId ~= 4 then
        self:notify_tips(selfId,"Chỉ ước nguyện được ở Thái Hồ!")
        return 0
    end
    local WishesCount = self:GetMissionDataEx(selfId,148)
    if WishesCount >= 5 then
        self:notify_tips(selfId,"Hôm nay đã ước đủ 5 lần.")
        return
    end
    if self:CallScriptFunction(self.g_event, "CheckAccept", selfId) > 0 then
        self:notify_tips(selfId,"Xin nhận nhiệm vụ Một nghìn lẻ một điều ước trước.")
        return
    end
    local treasureX = 157
    local treasureZ = 188
    PlayerX = self:GetHumanWorldX(selfId)
    PlayerZ = self:GetHumanWorldZ(selfId)
    Distance = math.floor(math.sqrt((treasureX - PlayerX) * (treasureX - PlayerX) + (treasureZ - PlayerZ) * (treasureZ - PlayerZ)))
    if Distance > 5 then
        self:notify_tips(selfId,"Xin dùng [Nguyện Linh Tuyền] gần cây ước Thái Hồ (157,188), tọa độ hiện cách cây còn" ..Distance .. "gạo")
        return 0
    end
    return 1
end

function yuanlingquan:OnDeplete(selfId)
    return 1
end

function yuanlingquan:OnActivateOnce(selfId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    self:CallScriptFunction(self.g_event, "OnUseItem", selfId)
    return 1
end

function yuanlingquan:OnActivateEachTick(selfId)
    return 1
end

return yuanlingquan
