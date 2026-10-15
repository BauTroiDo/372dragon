local class = require "class"
local define = require "define"
local script_base = require "script_base"
local elevelup_shenghuoshu = class("elevelup_shenghuoshu", script_base)
elevelup_shenghuoshu.script_id = 713572
elevelup_shenghuoshu.g_nMaxLevel = 10
elevelup_shenghuoshu.g_AbilityID = define.ABILITY_SHENGHUOSHU
elevelup_shenghuoshu.g_AbilityName = "Thánh Hỏa Thuật"
function elevelup_shenghuoshu:OnDefaultEvent(selfId, targetId, num, npc_script_id, bid)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, self.g_AbilityID)
    if self:GetMenPai(selfId) ~= define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi không phải là đệ tử bổn phái, ta không thể dạy ngươi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if AbilityLevel < 1 then
        self:BeginEvent(self.script_id)
        local strText = "Ngươi còn chưa học được".. self.g_AbilityName.."Kỹ năng!"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if AbilityLevel >= self.g_nMaxLevel then
        self:BeginEvent(self.script_id)
        local strText = "Ta chỉ có thể dạy ngươi cấp 1-10 của".. self.g_AbilityName.."Kỹ năng, thỉnh đến bang phái học tập Kỹ năng Cao cấp của".. self.g_AbilityName.."."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        local tempAbilityId =  self.g_AbilityID
        local tempAbilityLevel = AbilityLevel + 1
        local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel =
            self:LuaFnGetAbilityLevelUpConfig(tempAbilityId, tempAbilityLevel)
        if ret then
            self:DispatchAbilityInfo(selfId, targetId, self.script_id, tempAbilityId, demandMoney, demandExp,
                limitAbilityExpShow, limitLevel)
        end
    end
end

function elevelup_shenghuoshu:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Thăng cấp".. self.g_AbilityName.."Kỹ Năng", 12, 1)
end

function elevelup_shenghuoshu:CheckAccept(selfId)

end

return elevelup_shenghuoshu
