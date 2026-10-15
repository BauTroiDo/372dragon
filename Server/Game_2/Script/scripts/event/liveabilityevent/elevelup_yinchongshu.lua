local class = require "class"
local define = require "define"
local script_base = require "script_base"
local elevelup_yinchongshu = class("elevelup_yinchongshu", script_base)
elevelup_yinchongshu.script_id = 713593
elevelup_yinchongshu.g_nMaxLevel = 100
elevelup_yinchongshu.g_AbilityID = define.ABILITY_YINCHONGSHU
elevelup_yinchongshu.g_AbilityName = "Dẫn Trùng Thuật"
function elevelup_yinchongshu:OnDefaultEvent(selfId, targetId, num, npc_script_id, bid)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, self.g_AbilityID)
    if self:GetMenPai(selfId) ~= define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU then
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
        local strText = "Hiện tại Kỹ năng này chỉ có thể học đến cấp 100"
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

function elevelup_yinchongshu:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Thăng cấp".. self.g_AbilityName.."Kỹ Năng", 12, 1)
end

function elevelup_yinchongshu:CheckAccept(selfId)

end

return elevelup_yinchongshu
