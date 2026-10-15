local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanhai_5_baby = class("onanhai_5_baby", script_base)

function onanhai_5_baby:OnDefaultEvent(selfId, targetId) end

function onanhai_5_baby:OnDie(selfId, killerId) end

return onanhai_5_baby
