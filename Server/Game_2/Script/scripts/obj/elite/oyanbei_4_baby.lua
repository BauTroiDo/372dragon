local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyanbei_4_baby = class("oyanbei_4_baby", script_base)

function oyanbei_4_baby:OnDefaultEvent(selfId, targetId) end

function oyanbei_4_baby:OnDie(selfId, killerId) end

return oyanbei_4_baby
