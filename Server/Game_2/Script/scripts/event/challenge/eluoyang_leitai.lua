local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eluoyang_leitai = class("eluoyang_leitai", script_base)
eluoyang_leitai.script_id = 806011
eluoyang_leitai.g_ChallengeScriptId = 806012
function eluoyang_leitai:on_enter_area(scene, obj)
    local selfId = obj:get_obj_id()
    self:SetMissionData(selfId, define.MD_ENUM.MD_TIAOZHAN_SCRIPT, self.g_ChallengeScriptId)
end
function eluoyang_leitai:OnEnterArea(selfId)
    self:SetMissionData(selfId, define.MD_ENUM.MD_TIAOZHAN_SCRIPT, self.g_ChallengeScriptId)
end

function eluoyang_leitai:OnTimer(selfId) return end

function eluoyang_leitai:OnLeaveArea(selfId)
    self:SetMissionData(selfId, define.MD_ENUM.MD_TIAOZHAN_SCRIPT, 0)
end

return eluoyang_leitai
