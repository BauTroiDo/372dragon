local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyanbei_5_baby = class("oyanbei_5_baby", script_base)

function oyanbei_5_baby:OnDefaultEvent(selfId, targetId) end

function oyanbei_5_baby:OnDie(selfId, killerId) end

return oyanbei_5_baby
