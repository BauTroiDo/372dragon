local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanhai_4_baby = class("onanhai_4_baby", script_base)

function onanhai_4_baby:OnDefaultEvent(selfId, targetId) end

function onanhai_4_baby:OnDie(selfId, killerId) end

return onanhai_4_baby
