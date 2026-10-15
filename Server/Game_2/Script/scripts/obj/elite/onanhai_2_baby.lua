local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanhai_2_baby = class("onanhai_2_baby", script_base)

function onanhai_2_baby:OnDefaultEvent(selfId, targetId) end

function onanhai_2_baby:OnDie(selfId, killerId) end

return onanhai_2_baby
