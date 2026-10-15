local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyanbei_1_baby = class("oyanbei_1_baby", script_base)

function oyanbei_1_baby:OnDefaultEvent(selfId, targetId) end

function oyanbei_1_baby:OnDie(selfId, killerId) end

return oyanbei_1_baby
