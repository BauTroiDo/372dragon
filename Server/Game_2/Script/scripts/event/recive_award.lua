local class = require "class"
local define = require "define"
local script_base = require "script_base"
local recive_award = class("recive_award", script_base)

function recive_award:OnEnumerate(caller, selfId, targetId, bid)
    caller:AddNumTextWithTarget(self.script_id, "#{HSLJ_190919_194}", 6, 1100)
end

return recive_award