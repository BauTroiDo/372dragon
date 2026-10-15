local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanhai_3_baby = class("onanhai_3_baby", script_base)

function onanhai_3_baby:OnDefaultEvent(selfId, targetId) end

function onanhai_3_baby:OnDie(selfId, killerId) end

return onanhai_3_baby
