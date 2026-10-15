local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_diaoyu_shanyu = class("gp_diaoyu_shanyu", script_base)
gp_diaoyu_shanyu.g_MainItemId = 20102005
gp_diaoyu_shanyu.g_AbilityId = 9
gp_diaoyu_shanyu.g_AbilityLevel = 5
function gp_diaoyu_shanyu:OnCreate(growPointType, x, y)
    local ItemCount = 0
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, ItemCount)
end

function gp_diaoyu_shanyu:OnOpen(selfId, targetId)
    local AbilityId = self:GetItemBoxRequireAbilityID(targetId)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, AbilityId)
    if AbilityLevel < self.g_AbilityLevel then
        return define.OPERATE_RESULT.OR_NO_LEVEL
    end
    self.g_FishTime = math.random(80000) + 20000
    self:SetAbilityOperaTime(selfId, self.g_FishTime)
    return define.OPERATE_RESULT.OR_OK
end

function gp_diaoyu_shanyu:OnProcOver(selfId, targetId)
    local ret_1 = self:TryRecieveItem(selfId, self.g_MainItemId, define.QUALITY_MUST_BE_CHANGE)
    if ret_1 then
        self:Msg2Player(selfId, "Ngươi đã câu được một con lươn.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        local ABilityID = self:GetItemBoxRequireAbilityID(targetId)
        self:CallScriptFunction(define.ABILITYLOGIC_ID, "GainExperience", selfId, ABilityID, self.g_AbilityLevel)
    elseif ret_1 == -1 then
        self:Msg2Player(selfId, "Hành trang đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
    return 0
end

return gp_diaoyu_shanyu
