local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyanbei_3_baby = class("oyanbei_3_baby", script_base)

function oyanbei_3_baby:OnDefaultEvent(selfId, targetId) end

function oyanbei_3_baby:OnDie(selfId, killerId) end

return oyanbei_3_baby
