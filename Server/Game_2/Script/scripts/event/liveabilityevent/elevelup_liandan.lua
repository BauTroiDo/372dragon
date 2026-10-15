local class = require "class"
local define = require "define"
local script_base = require "script_base"
local elevelup_liandan = class("elevelup_liandan", script_base)
elevelup_liandan.script_id = 713578
elevelup_liandan.g_nMaxLevel = 10
elevelup_liandan.g_AbilityID = define.ABILITY_LIANDAN
function elevelup_liandan:OnDefaultEvent(selfId, targetId, num, npc_script_id, bid)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, define.ABILITY_LIANDAN)
    if self:GetMenPai(selfId) ~= define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi không phải là đệ tử bổn phái, ta không thể dạy ngươi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if AbilityLevel < 1 then
        self:BeginEvent(self.script_id)
        local strText = "Ngươi còn chưa học được Kỹ năng Luyện Đan!"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if AbilityLevel >= self.g_nMaxLevel then
        self:BeginEvent(self.script_id)
        local strText = "Ta chỉ có thể dạy ngươi Kỹ năng Luyện Đan cấp 1-10, xin đến bang phái học Luyện Đan Cao cấp hơn."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        local tempAbilityId = define.ABILITY_LIANDAN
        local tempAbilityLevel = AbilityLevel + 1
        local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel =
            self:LuaFnGetAbilityLevelUpConfig(tempAbilityId, tempAbilityLevel)
        if ret then
            self:DispatchAbilityInfo(selfId, targetId, self.script_id, tempAbilityId, demandMoney, demandExp,
                limitAbilityExpShow, limitLevel)
        end
    end
end

function elevelup_liandan:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Thăng cấp Kỹ năng Luyện Đan", 12, 1)
end

function elevelup_liandan:CheckAccept(selfId)

end

return elevelup_liandan
