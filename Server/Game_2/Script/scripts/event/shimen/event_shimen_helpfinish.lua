local class = require "class"
local define = require "define"
local script_base = require "script_base"
local event_shimen_helpfinish = class("event_shimen_helpfinish", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
event_shimen_helpfinish.script_id = 229011
function event_shimen_helpfinish:OnDefaultEvent(selfId, targetId, menpaiId, numTextId)
    if numTextId == 1 then
        self:BeginEvent(self.script_id)
        if not self:IsHaveMission(selfId, ScriptGlobal.MENPAI_SHIMEN_MISID[menpaiId + 1]) then
            self:AddText("Ngươi hình như không có tiếp nhận sư môn nhiệm vụ a.")
        else
            local strText =
            "  Quang diệu sư môn, nhân nhân hữu trách! Mỗi ngày tân cần làm sư môn nhiệm vụ của đệ tử, chúng ta sẽ cấp cho phong hậu của phần thưởng, đương nhiên, đối với làm sư môn nhiệm vụ gặp phải khó khăn của đệ tử chúng ta cũng sẽ dốc sức tương trợ.#r Ngươi xác định muốn tiêu hao #G%d điểm#W sư môn cống hiến độ, để Khác đồng môn sư huynh và sư tỷ giúp ngươi hoàn thành đương kim sư môn nhiệm vụ chăng?"
            strText = string.format(strText, self:GetHelpFinishNeed(selfId))
            self:AddText(strText)
            self:AddNumText("Xác nhận", 6, 2)
            self:AddNumText("Rời đi", 8, 3)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif numTextId == 2 then
        self:CallScriptFunction(ScriptGlobal.MENPAI_SHIMEN_SCRIPTID[menpaiId + 1], "HelpFinishOneHuan", selfId, targetId)
    elseif numTextId == 3 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
end

function event_shimen_helpfinish:OnEnumerate(caller, selfId, targetId, arg, index)
    if arg == self:GetMenPai(selfId) then
        caller:AddNumTextWithTarget(self.script_id,"Đồng môn tương trợ", 6, 1)
    end
end

function event_shimen_helpfinish:GetHelpFinishNeed(selfId)
    local level = self:GetLevel(selfId)
    local need = (level - 10) * 0.05 * 20 + 40
    need = need * 0.8
    need = math.floor(need)
    return need
end

function event_shimen_helpfinish:CheckAndDepleteHelpFinishMenPaiPoint(selfId, targetId)
    local needPoint = self:GetHelpFinishNeed(selfId)
    local menpaiPoint = self:GetHumanMenpaiPoint(selfId)
    if menpaiPoint < needPoint then
        self:BeginEvent(self.script_id)
        self:AddText("  Ngươi hình như không có đủ sư môn cống hiến độ, hãy vì sư môn làm nhiều việc thiện, như vậy Khác đồng môn cũng sẽ toàn lực giúp đỡ ngươi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return 0
    else
        self:SetHumanMenpaiPoint(selfId, menpaiPoint - needPoint)
        return 1
    end
end

return event_shimen_helpfinish
