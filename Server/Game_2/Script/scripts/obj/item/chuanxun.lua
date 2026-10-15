local class = require "class"
local define = require "define"
local script_base = require "script_base"
local chuanxun = class("chuanxun", script_base)
chuanxun.script_id = 300009
chuanxun.g_event = 210211
function chuanxun:OnDefaultEvent(selfId, BagIndex)
    self:CallScriptFunction(self.g_event, "OnUseItem", selfId, BagIndex)
    return 0
end

function chuanxun:IsSkillLikeScript(selfId) return 0 end

return chuanxun
