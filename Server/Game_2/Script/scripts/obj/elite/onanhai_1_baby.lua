local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanhai_1_baby = class("onanhai_1_baby", script_base)

function onanhai_1_baby:OnDefaultEvent(selfId, targetId) end

function onanhai_1_baby:OnDie(selfId, killerId) end

return onanhai_1_baby
