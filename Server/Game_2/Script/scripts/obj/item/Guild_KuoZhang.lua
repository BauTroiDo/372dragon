local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Guild_KuoZhang = class("Guild_KuoZhang", script_base)
Guild_KuoZhang.script_id = 990003
function Guild_KuoZhang:OnDefaultEvent(selfId, bagIndex)
end

function Guild_KuoZhang:IsSkillLikeScript(selfId)
    return 1
end

function Guild_KuoZhang:CancelImpacts(selfId)
    return 0
end

function Guild_KuoZhang:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    return 1
end

function Guild_KuoZhang:OnDeplete(selfId)
    local guildid = self:GetHumanGuildID(selfId)
    if not guildid then
        self:ShowNotice(selfId, "Ngươi chưa gia nhập bang phái, tạm thời không thể sử dụng.")
        return 0
    end
    if self:LuaFnDepletingUsedItem(selfId) then
        return 1
    end
    return 0
end

function Guild_KuoZhang:OnActivateOnce(selfId)
    local guildid = self:GetHumanGuildID(selfId)
    if guildid == -1 then
        self:ShowNotice(selfId, "Ngươi chưa gia nhập bang phái, tạm thời không thể sử dụng.")
        return 1
    end
    self:CityChangeAttr(selfId,5,20)
    self:ShowNotice(selfId, "Chúc mừng bạn dùng cuộn tăng mở rộng bang phái, tăng 20 điểm mở rộng.")
    return 1
end

function Guild_KuoZhang:OnActivateEachTick(selfId)
    return 1
end

function Guild_KuoZhang:ShowNotice(selfId, strNotice)
    self:BeginEvent(self.script_id)
    self:AddText(strNotice)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return Guild_KuoZhang
