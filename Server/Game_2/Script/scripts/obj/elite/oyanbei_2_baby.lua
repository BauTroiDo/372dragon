local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyanbei_2_baby = class("oyanbei_2_baby", script_base)

function oyanbei_2_baby:OnDefaultEvent(selfId, targetId) end

function oyanbei_2_baby:OnDie(selfId, killerId) end

return oyanbei_2_baby
