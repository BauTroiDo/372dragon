local class = require "class"
local define = require "define"
local script_base = require "script_base"
local challenge = class("challenge", script_base)
challenge.script_id = 806010
function challenge:HaveChallengeFlag(selfId)
    return (self:GetMissionData(selfId, define.MD_ENUM.MD_TIAOZHAN_SCRIPT) > 0)
end

function challenge:ProcChallenge(selfId, targetId)
    local ChallengeScript = self:GetMissionData(selfId, define.MD_ENUM.MD_TIAOZHAN_SCRIPT)
    if ChallengeScript ~= self:GetMissionData(targetId, define.MD_ENUM.MD_TIAOZHAN_SCRIPT) then
        return
    end
    self:CallScriptFunction(ChallengeScript, "DoChallenge", selfId, targetId)
end

return challenge
